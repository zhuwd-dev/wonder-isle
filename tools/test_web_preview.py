#!/usr/bin/env python3
"""Serve a Godot Web export and smoke-test it in Chromium with Playwright."""

from __future__ import annotations

import base64
import functools
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright
from browser_navigation import Navigator


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, _format: str, *_args: object) -> None:
        pass


def inject_save_fixture(page, save_key: str, fixture_path: Path) -> None:
    fixture_base64 = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
    page.evaluate(
        """async ({key, payload}) => new Promise((resolve, reject) => {
            const binary = atob(payload);
            const contents = new Int8Array(binary.length);
            for (let index = 0; index < binary.length; index++) {
                contents[index] = binary.charCodeAt(index);
            }
            const opening = indexedDB.open('/userfs');
            opening.onerror = () => reject(opening.error);
            opening.onsuccess = () => {
                const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                const store = transaction.objectStore('FILE_DATA');
                const timestamp = new Date();
                const segments = key.split('/').filter(Boolean);
                let parent = '';
                for (const segment of segments.slice(0, -1)) {
                    parent += '/' + segment;
                    const directoryKey = parent;
                    const existingDirectory = store.get(directoryKey);
                    existingDirectory.onsuccess = () => {
                        if (!existingDirectory.result) {
                            store.put({ timestamp, mode: 0x41ED }, directoryKey);
                        }
                    };
                }
                const existing = store.get(key);
                existing.onsuccess = () => {
                    const record = existing.result || {};
                    record.timestamp = timestamp;
                    // IDBFS needs the POSIX mode to recreate the entry
                    // during its next populate sync. A JSON record with no
                    // mode is readable from IndexedDB but is not a file to
                    // Godot's virtual filesystem.
                    record.mode = record.mode || 0x81B6; // regular file, 0666
                    record.contents = contents;
                    store.put(record, key);
                };
                transaction.oncomplete = resolve;
                transaction.onerror = () => reject(transaction.error);
            };
        })""",
        {"key": save_key, "payload": fixture_base64},
    )
    page.reload(wait_until="load", timeout=60_000)
    page.wait_for_selector("canvas", timeout=60_000)
    page.wait_for_timeout(4_500)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: test_web_preview.py <web-export-directory>", file=sys.stderr)
        return 2

    build_dir = Path(sys.argv[1]).resolve()
    index_file = build_dir / "index.html"
    if not index_file.is_file():
        print(f"Web export not found: {index_file}", file=sys.stderr)
        return 2
    index_html = index_file.read_text(encoding="utf-8")
    if '<html lang="zh-CN">' not in index_html or "chrome://gpu" not in index_html:
        raise AssertionError("Web export is missing the Chinese WebGL2 troubleshooting notice")

    handler = functools.partial(QuietHandler, directory=str(build_dir))
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()

    result: dict[str, object] = {
        "console_errors": [],
        "page_errors": [],
        "request_failures": [],
    }
    default_artifact_dir = build_dir.parent.parent / "tests" / "artifacts"
    artifact_dir = Path(os.environ.get("WEB_TEST_ARTIFACTS", default_artifact_dir)).resolve()
    artifact_dir.mkdir(parents=True, exist_ok=True)
    screenshot_path = artifact_dir / "web-preview.png"
    q001_initial_screenshot_path = artifact_dir / "web-q001-initial.png"
    q001_collected_screenshot_path = artifact_dir / "web-q001-collected-1.png"
    q001_bridge_1_screenshot_path = artifact_dir / "web-q001-bridge-1-of-3.png"
    q001_bridge_2_screenshot_path = artifact_dir / "web-q001-bridge-2-of-3.png"
    q001_bridge_3_screenshot_path = artifact_dir / "web-q001-bridge-3-of-3.png"
    q001_task_details_screenshot_path = artifact_dir / "web-q001-task-details.png"
    q001_restart_confirmation_screenshot_path = artifact_dir / "web-q001-restart-confirmation.png"
    seed_planted_screenshot_path = artifact_dir / "web-q002-seed-planted.png"
    turtle_garden_screenshot_path = artifact_dir / "web-q005-turtle-garden.png"
    turtle_growth_screenshot_path = artifact_dir / "web-q005-watered-growth.png"
    turtle_collection_screenshot_path = artifact_dir / "web-q005-plant-collected.png"
    turtle_bouquet_screenshot_path = artifact_dir / "web-q005-bouquet-ready.png"
    turtle_delivery_screenshot_path = artifact_dir / "web-q005-bouquet-delivered.png"
    ending_screenshot_path = artifact_dir / "web-q012-ending.png"
    completed_screenshot_path = artifact_dir / "web-q012-complete.png"
    final_island_screenshot_path = artifact_dir / "web-q011-all-tasks-complete.png"
    build_adjustment_screenshot_path = artifact_dir / "web-q011-build-adjustment.png"
    godot_bin = os.environ.get(
        "GODOT_BIN", "/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
    )

    try:
        with sync_playwright() as playwright:
            launch_options: dict[str, object] = {"headless": True}
            chromium_path = os.environ.get("CHROMIUM_PATH")
            if chromium_path:
                launch_options["executable_path"] = chromium_path
            browser = playwright.chromium.launch(**launch_options)
            try:
                page = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
                page.on(
                    "console",
                    lambda message: result["console_errors"].append(message.text)
                    if message.type == "error"
                    else None,
                )
                page.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                page.on(
                    "requestfailed",
                    lambda request: result["request_failures"].append(
                        {"url": request.url, "failure": request.failure}
                    ),
                )

                response = page.goto(
                    f"http://127.0.0.1:{server.server_port}/index.html",
                    wait_until="load",
                    timeout=60_000,
                )
                if response is None:
                    raise AssertionError("Chromium did not receive an HTTP response")

                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(3_000)
                godot_config_match = re.search(r"const GODOT_CONFIG = (\{[^;]+\});", index_html)
                if godot_config_match is None:
                    raise AssertionError("Web export has no Godot startup configuration")
                godot_config = json.loads(godot_config_match.group(1))
                executable = godot_config.get("executable", "")
                if not re.fullmatch(r"index-[a-f0-9]{12}", executable):
                    raise AssertionError(f"Web game payloads are not cache-busted: {executable!r}")
                for suffix in (".js", ".wasm", ".pck", ".audio.worklet.js", ".audio.position.worklet.js"):
                    payload = build_dir / f"{executable}{suffix}"
                    if not payload.is_file():
                        raise AssertionError(f"Cache-busted game payload is missing: {payload.name}")

                canvas_box = page.locator("canvas").first.bounding_box()
                if canvas_box is None or canvas_box["width"] < 640 or canvas_box["height"] < 360:
                    raise AssertionError(f"Unexpected game canvas bounds: {canvas_box}")

                webgl2_available = page.evaluate(
                    "() => !!document.createElement('canvas').getContext('webgl2')"
                )
                game_canvas_uses_webgl2 = page.locator("canvas").first.evaluate(
                    "canvas => !!canvas.getContext('webgl2')"
                )
                if not webgl2_available or not game_canvas_uses_webgl2:
                    raise AssertionError(
                        "Chromium did not initialize the game's WebGL2 rendering context"
                    )

                result.update(
                    {
                        "http_status": response.status,
                        "title": page.title(),
                        "canvas_count": page.locator("canvas").count(),
                        "canvas_box": canvas_box,
                        "webgl2_available": webgl2_available,
                        "game_canvas_uses_webgl2": game_canvas_uses_webgl2,
                        "screenshot": str(screenshot_path),
                    }
                )
                page.screenshot(path=str(screenshot_path), full_page=True)

                # Capture an actual moving frame so the player walk animation is
                # checked in the browser, not only by inspecting its draw code.
                page.keyboard.down("d")
                page.wait_for_timeout(450)
                page.screenshot(path=str(artifact_dir / "web-player-walking.png"), full_page=True)
                page.keyboard.up("d")

                # Check the actual canvas zoom controls and drag-pan path. The
                # full-map control must restore the default framing afterward.
                page.mouse.click(726, 52)
                page.wait_for_timeout(300)
                page.screenshot(path=str(artifact_dir / "web-map-zoomed.png"), full_page=True)
                page.mouse.click(726, 52)
                page.wait_for_timeout(300)
                page.screenshot(path=str(artifact_dir / "c-map-zoom-max.png"), full_page=True)
                page.mouse.move(600, 420)
                page.mouse.down()
                page.mouse.move(660, 450, steps=5)
                page.mouse.up()
                page.wait_for_timeout(250)
                page.screenshot(path=str(artifact_dir / "web-map-panned.png"), full_page=True)
                page.mouse.click(797, 52)
                page.wait_for_timeout(250)
                page.screenshot(path=str(artifact_dir / "web-map-full-view-reset.png"), full_page=True)

                # Exercise the virtual joystick and landscape touch layout before the
                # story walkthrough, then restart the browser page at its desktop size.
                page.mouse.move(96, 622)
                page.mouse.down()
                page.mouse.move(138, 622, steps=5)
                page.wait_for_timeout(250)
                page.screenshot(path=str(artifact_dir / "web-virtual-joystick-active.png"), full_page=True)
                page.mouse.up()
                page.set_viewport_size({"width": 1630, "height": 870})
                page.wait_for_timeout(750)
                wide_canvas_box = page.locator("canvas").first.bounding_box()
                if wide_canvas_box is None or wide_canvas_box["width"] < 1_500 or wide_canvas_box["height"] < 800:
                    raise AssertionError(f"Unexpected wide-screen canvas bounds: {wide_canvas_box}")
                page.screenshot(path=str(artifact_dir / "web-wide-1630x870.png"), full_page=True)
                result["wide_canvas_box"] = wide_canvas_box
                page.set_viewport_size({"width": 844, "height": 390})
                page.wait_for_timeout(750)
                touch_canvas_box = page.locator("canvas").first.bounding_box()
                if touch_canvas_box is None or touch_canvas_box["width"] < 640 or touch_canvas_box["height"] < 360:
                    raise AssertionError(f"Unexpected landscape touch canvas bounds: {touch_canvas_box}")
                page.screenshot(path=str(artifact_dir / "web-touch-landscape.png"), full_page=True)
                result["touch_landscape_canvas_box"] = touch_canvas_box
                page.close()

                # Use a fresh engine instance at desktop size for deterministic game input.
                page = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
                navigator = Navigator(page, index_html)
                page.on(
                    "console",
                    lambda message: result["console_errors"].append(message.text)
                    if message.type == "error"
                    else None,
                )
                page.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                page.on(
                    "requestfailed",
                    lambda request: result["request_failures"].append(
                        {"url": request.url, "failure": request.failure}
                    ),
                )
                page.goto(
                    f"http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1",
                    wait_until="load",
                    timeout=60_000,
                )
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(3_000)

                # Build isolated Q001 fixtures to verify each visual state in the
                # current Web export without touching a real browser save.
                with tempfile.TemporaryDirectory(prefix="wonder-isle-q001-visual-") as temp_dir:
                    fixture_directory = Path(temp_dir)
                    subprocess.run(
                        [
                            godot_bin,
                            "--headless",
                            "--path",
                            str(Path(__file__).resolve().parent.parent),
                            "--script",
                            "tests/create_q001_visual_saves.gd",
                            "--",
                            str(fixture_directory),
                        ],
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    save_key = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"
                    fixture_paths = {
                        stage: fixture_directory / f"q001-{stage}.json"
                        for stage in ("initial", "collected-1", "bridge-1", "bridge-2", "bridge-3")
                    }
                    # Capture the real fresh opening state before creating an isolated
                    # IndexedDB save; the restart confirmation also initializes the
                    # browser filesystem entry that later fixture reloads replace.
                    page.screenshot(path=str(q001_initial_screenshot_path), full_page=True)
                    page.mouse.click(180, 45)
                    page.wait_for_timeout(250)
                    page.screenshot(path=str(q001_task_details_screenshot_path), full_page=True)
                    page.mouse.click(180, 45)
                    page.wait_for_timeout(250)
                    page.mouse.click(1216, 44)
                    page.wait_for_timeout(300)
                    page.mouse.click(1216, 124)
                    page.wait_for_timeout(500)
                    page.screenshot(path=str(q001_restart_confirmation_screenshot_path), full_page=True)
                    page.mouse.click(775, 392)
                    page.wait_for_timeout(4_500)

                    for stage in ("collected-1", "bridge-1", "bridge-2", "bridge-3"):
                        inject_save_fixture(page, save_key, fixture_paths[stage])
                        if stage == "collected-1":
                            page.screenshot(path=str(q001_collected_screenshot_path), full_page=True)
                        elif stage == "bridge-1":
                            page.screenshot(path=str(q001_bridge_1_screenshot_path), full_page=True)
                        elif stage == "bridge-2":
                            page.screenshot(path=str(q001_bridge_2_screenshot_path), full_page=True)
                        else:
                            page.screenshot(path=str(q001_bridge_3_screenshot_path), full_page=True)
                    result.update(
                        {
                            "q001_initial_screenshot": str(q001_initial_screenshot_path),
                            "q001_collected_screenshot": str(q001_collected_screenshot_path),
                            "q001_bridge_1_screenshot": str(q001_bridge_1_screenshot_path),
                            "q001_bridge_2_screenshot": str(q001_bridge_2_screenshot_path),
                            "q001_bridge_3_screenshot": str(q001_bridge_3_screenshot_path),
                            "q001_task_details_screenshot": str(q001_task_details_screenshot_path),
                            "q001_restart_confirmation_screenshot": str(q001_restart_confirmation_screenshot_path),
                        }
                    )

                    # V2.0 browser loop: unlock the gate from the Q001 fixture,
                    # enter the hub, start R01, follow the marked track, replay,
                    # and return to the original life-island instance.
                    page.set_viewport_size({"width": 844, "height": 390})
                    page.wait_for_timeout(300)
                    navigator.move_until_ready("a", "去竞技岛")
                    page.screenshot(path=str(artifact_dir / "web-v20-life-island-gate-mobile.png"), full_page=True)
                    page.keyboard.press("e")

                    def wait_competition_screen(expected_screen, timeout=12):
                        deadline = time.monotonic() + timeout
                        while time.monotonic() < deadline:
                            state = navigator.competition_position()
                            if state["screen"] == expected_screen:
                                return state
                            page.wait_for_timeout(50)
                        raise AssertionError(f"Competition screen {expected_screen} not reached: {navigator.competition_position()}")

                    state = wait_competition_screen(0)
                    page.screenshot(path=str(artifact_dir / "web-v20-competition-hub-mobile.png"), full_page=True)
                    # Use Chromium's touch input path for the mobile competition
                    # walkthrough rather than keyboard input. The origin is the
                    # on-screen joystick's default center at 844x390.
                    touch = page.context.new_cdp_session(page)
                    touch.send("Emulation.setTouchEmulationEnabled", {"enabled": True, "maxTouchPoints": 1})
                    stick_origin = (68, page.viewport_size["height"] - 83)
                    stick_point = stick_origin
                    jump_point = None

                    def touch_stick_start():
                        nonlocal stick_point
                        stick_point = stick_origin
                        touch.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": stick_origin[0], "y": stick_origin[1], "id": 1, "radiusX": 8, "radiusY": 8, "force": 1}]})

                    def touch_stick_direction(dx, dy):
                        nonlocal stick_point
                        length = max((dx * dx + dy * dy) ** 0.5, 1.0)
                        x = stick_origin[0] + round(dx / length * 48)
                        y = stick_origin[1] + round(dy / length * 48)
                        stick_point = (x, y)
                        points = [{"x": x, "y": y, "id": 1, "radiusX": 8, "radiusY": 8, "force": 1}]
                        if jump_point is not None:
                            points.append({"x": jump_point[0], "y": jump_point[1], "id": 2, "radiusX": 8, "radiusY": 8, "force": 1})
                        touch.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": points})

                    def touch_jump_start():
                        nonlocal jump_point
                        race_state = navigator.competition_position()
                        jump_point = (
                            round(race_state["action_position"][0] + race_state["action_size"][0] * 0.5),
                            round(race_state["action_position"][1] + race_state["action_size"][1] * 0.5),
                        )
                        touch.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [
                            {"x": stick_point[0], "y": stick_point[1], "id": 1, "radiusX": 8, "radiusY": 8, "force": 1},
                            {"x": jump_point[0], "y": jump_point[1], "id": 2, "radiusX": 8, "radiusY": 8, "force": 1},
                        ]})

                    def touch_stick_end():
                        nonlocal jump_point
                        touch.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
                        jump_point = None

                    def touch_walk_to(target, timeout=12, jump=False):
                        deadline = time.monotonic() + timeout
                        last_position = None
                        last_progress = time.monotonic()
                        touch_stick_start()
                        if jump:
                            touch_jump_start()
                        previous_position = None
                        moved_while_airborne = False
                        peak_jump_height = 0.0
                        reached_target = False
                        try:
                            while time.monotonic() < deadline:
                                state = navigator.competition_position()
                                if state["screen"] == 3:
                                    return state
                                dx = target[0] - state["x"]
                                dy = target[1] - state["y"]
                                if abs(dx) <= 18 and abs(dy) <= 18:
                                    reached_target = True
                                    break
                                touch_stick_direction(dx, dy)
                                position = (state["x"], state["y"])
                                peak_jump_height = max(peak_jump_height, state["jump_height"])
                                if previous_position is not None and state["jump_active"] and abs(position[0] - previous_position[0]) + abs(position[1] - previous_position[1]) > 0.5:
                                    moved_while_airborne = True
                                previous_position = position
                                if last_position is None or abs(position[0] - last_position[0]) + abs(position[1] - last_position[1]) > 1:
                                    last_position = position
                                    last_progress = time.monotonic()
                                elif time.monotonic() - last_progress > 2.0:
                                    raise AssertionError(f"Mobile touch movement blocked near target {target}: {state}")
                                page.wait_for_timeout(80)
                        finally:
                            touch_stick_end()
                        if reached_target and jump:
                            if not moved_while_airborne:
                                raise AssertionError("Joystick did not move while the second touch pressed jump")
                            if peak_jump_height < 18.0:
                                raise AssertionError(f"Jump did not reach the hurdle clearance: peak={peak_jump_height}")
                        if reached_target:
                            return navigator.competition_position()
                        raise AssertionError(f"Timed out using mobile joystick to reach {target}: {navigator.competition_position()}")

                    touch_walk_to((state["x"], 270))
                    state = navigator.competition_position()
                    if state["screen"] != 0 or state["y"] > 300:
                        raise AssertionError(f"Could not walk to R01 entrance: {state}")
                    page.mouse.click(page.viewport_size["width"] - 54, page.viewport_size["height"] - 30)
                    wait_competition_screen(1)
                    page.screenshot(path=str(artifact_dir / "web-v21-r01-briefing-mobile.png"), full_page=True)
                    state = navigator.competition_position()
                    page.mouse.click(
                        round(state["action_position"][0] + state["action_size"][0] * 0.5),
                        round(state["action_position"][1] + state["action_size"][1] * 0.5),
                    )
                    state = wait_competition_screen(2)
                    if state["clock_running"] is not True:
                        raise AssertionError(f"Race clock did not start from the briefing: {state}")
                    page.screenshot(path=str(artifact_dir / "web-v21-r01-start-mobile.png"), full_page=True)

                    def walk_competition_to(target, timeout=12):
                        deadline = time.monotonic() + timeout
                        last_progress = time.monotonic()
                        last_position = None
                        while time.monotonic() < deadline:
                            state = navigator.competition_position()
                            if state["screen"] == 3:
                                return state
                            dx = target[0] - state["x"]
                            dy = target[1] - state["y"]
                            if abs(dx) <= 18 and abs(dy) <= 18:
                                return state
                            position = (state["x"], state["y"])
                            if last_position is None or abs(position[0] - last_position[0]) + abs(position[1] - last_position[1]) > 1:
                                last_position = position
                                last_progress = time.monotonic()
                            elif time.monotonic() - last_progress > 2.0:
                                raise AssertionError(f"R01 movement blocked near target {target}: {state}")
                            touch_walk_to(target, timeout=max(1, deadline - time.monotonic()))
                            page.wait_for_timeout(60)
                        state = navigator.competition_position()
                        raise AssertionError(f"Timed out walking R01 waypoint {target}: {state}")

                    center_x = state["world_width"] * 0.5
                    for waypoint in ((center_x - 320, 446), (center_x - 245, 388), (center_x - 150, 320), (center_x - 15, 270)):
                        state = walk_competition_to(waypoint)
                    if state["checkpoint_index"] < 1:
                        raise AssertionError(f"Middle checkpoint did not activate: {state}")
                    race_checkpoint = tuple(state["race_checkpoint"])
                    touch_walk_to((race_checkpoint[0] + 30, race_checkpoint[1]))
                    state = navigator.competition_position()
                    checkpoint_x = state["checkpoint_position"][0] + state["checkpoint_size"][0] * 0.5
                    checkpoint_y = state["checkpoint_position"][1] + state["checkpoint_size"][1] * 0.5
                    race_time_before_recovery = state["race_time"]
                    page.mouse.click(round(checkpoint_x), round(checkpoint_y))
                    page.wait_for_timeout(100)
                    state = navigator.competition_position()
                    if abs(state["x"] - race_checkpoint[0]) > 2 or state["race_time"] < race_time_before_recovery:
                        raise AssertionError(f"Checkpoint recovery failed to preserve race state: {state}")
                    for width, height, label in ((1280, 720, "1280x720"), (1630, 870, "1630x870")):
                        page.set_viewport_size({"width": width, "height": height})
                        page.wait_for_timeout(400)
                        resized_state = navigator.competition_position()
                        checkpoint_rect = (*resized_state["checkpoint_position"], *resized_state["checkpoint_size"])
                        jump_rect = (*resized_state["action_position"], *resized_state["action_size"])
                        back_rect = (*resized_state["back_position"], *resized_state["back_size"])
                        for name, rect in (("checkpoint", checkpoint_rect), ("jump", jump_rect)):
                            x, y, rect_width, rect_height = rect
                            if x < 0 or y < 0 or x + rect_width > width or y + rect_height > height:
                                raise AssertionError(f"R01 {name} control is clipped at {label}: {rect}")
                        if checkpoint_rect[1] < back_rect[1] + back_rect[3] + 2:
                            raise AssertionError(f"R01 back/checkpoint controls overlap at {label}: back={back_rect}, checkpoint={checkpoint_rect}")
                        if checkpoint_rect[1] + checkpoint_rect[3] >= jump_rect[1]:
                            raise AssertionError(f"R01 checkpoint and jump controls overlap at {label}")
                        page.screenshot(path=str(artifact_dir / f"web-v21-r01-checkpoint-{label}.png"), full_page=True)
                    page.set_viewport_size({"width": 844, "height": 390})
                    page.wait_for_timeout(400)
                    state = navigator.competition_position()
                    state = walk_competition_to((center_x + 115, 276))
                    state = touch_walk_to((center_x + 250, 285), jump=True)
                    page.screenshot(path=str(artifact_dir / "web-v21-r01-obstacle-mobile.png"), full_page=True)
                    for waypoint in ((center_x + 250, 330), (center_x + 300, 340), (center_x + 360, 320), (center_x + 385, 225), (center_x + 410, 150)):
                        state = walk_competition_to(waypoint)
                    state = wait_competition_screen(3)
                    if state["clock_running"] is not False or state["race_time"] <= 0.0:
                        raise AssertionError(f"Finish did not stop the clock and report elapsed time: {state}")
                    page.screenshot(path=str(artifact_dir / "web-v21-r01-finish-mobile.png"), full_page=True)
                    page.mouse.click(int(page.viewport_size["width"] * 0.5 - 104), int(page.viewport_size["height"] * 0.63 + 35))
                    state = wait_competition_screen(2)
                    if state["checkpoint_index"] != 0 or state["race_time"] > 0.3 or state["clock_running"] is not True:
                        raise AssertionError(f"Replay did not reset current race state: {state}")
                    page.screenshot(path=str(artifact_dir / "web-v21-r01-replay-mobile.png"), full_page=True)
                    page.mouse.click(page.viewport_size["width"] - 54, 24)
                    wait_competition_screen(0)
                    page.screenshot(path=str(artifact_dir / "web-v20-competition-hub-mobile-return.png"), full_page=True)
                    page.set_viewport_size({"width": 1280, "height": 720})
                    page.wait_for_timeout(500)
                    page.screenshot(path=str(artifact_dir / "web-v20-competition-hub-1280x720.png"), full_page=True)
                    page.set_viewport_size({"width": 1630, "height": 870})
                    page.wait_for_timeout(500)
                    page.screenshot(path=str(artifact_dir / "web-v20-competition-hub-1630x870.png"), full_page=True)
                    page.set_viewport_size({"width": 1280, "height": 720})
                    page.wait_for_timeout(300)
                    return_started_at = time.monotonic()
                    page.mouse.click(page.viewport_size["width"] - 70, 46)
                    page.wait_for_timeout(750)
                    while time.monotonic() < return_started_at + 3 and navigator.state_received_at <= return_started_at:
                        page.wait_for_timeout(50)
                    if navigator.position()["bridge"] is not True:
                        raise AssertionError("Returning from the competition did not restore Q001 state")
                    touch.send("Emulation.setTouchEmulationEnabled", {"enabled": False})
                    touch.detach()
                    page.set_viewport_size({"width": 1280, "height": 720})
                    competition_screenshots = {
                        "competition_gate_mobile": str(artifact_dir / "web-v20-life-island-gate-mobile.png"),
                        "competition_hub_mobile": str(artifact_dir / "web-v20-competition-hub-mobile.png"),
                        "r01_briefing_mobile": str(artifact_dir / "web-v21-r01-briefing-mobile.png"),
                        "r01_start_mobile": str(artifact_dir / "web-v21-r01-start-mobile.png"),
                        "r01_obstacle_mobile": str(artifact_dir / "web-v21-r01-obstacle-mobile.png"),
                        "r01_finish_mobile": str(artifact_dir / "web-v21-r01-finish-mobile.png"),
                        "r01_replay_mobile": str(artifact_dir / "web-v21-r01-replay-mobile.png"),
                        "competition_hub_after_return_mobile": str(artifact_dir / "web-v20-competition-hub-mobile-return.png"),
                        "competition_hub_1280x720": str(artifact_dir / "web-v20-competition-hub-1280x720.png"),
                        "competition_hub_1630x870": str(artifact_dir / "web-v20-competition-hub-1630x870.png"),
                    }
                    result.update(competition_screenshots)

                with tempfile.TemporaryDirectory(prefix="wonder-isle-seed-planted-") as temp_dir:
                    fixture_path = Path(temp_dir) / "seed-planted-save.json"
                    subprocess.run(
                        [
                            godot_bin,
                            "--headless",
                            "--path",
                            str(Path(__file__).resolve().parent.parent),
                            "--script",
                            "tests/create_seed_planted_web_save.gd",
                            "--",
                            str(fixture_path),
                        ],
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    inject_save_fixture(page, save_key, fixture_path)
                    seed_stage_save = page.evaluate(
                        """async key => new Promise((resolve, reject) => {
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                const request = transaction.objectStore('FILE_DATA').get(key);
                                request.onsuccess = () => {
                                    const bytes = new Uint8Array(request.result.contents);
                                    resolve(JSON.parse(new TextDecoder().decode(bytes)));
                                };
                                request.onerror = () => reject(request.error);
                            };
                        })""",
                        save_key,
                    )
                    if seed_stage_save.get("seed_planted") is not True:
                        raise AssertionError("The browser did not load the seed-planted stage fixture")
                    page.screenshot(path=str(seed_planted_screenshot_path), full_page=True)
                    result["q002_seed_planted_screenshot"] = str(seed_planted_screenshot_path)

                    with tempfile.TemporaryDirectory(prefix="wonder-isle-q005-") as temp_dir:
                        fixture_path = Path(temp_dir) / "q005-turtle-garden-save.json"
                        subprocess.run(
                            [
                                godot_bin,
                                "--headless",
                                "--path",
                                str(Path(__file__).resolve().parent.parent),
                                "--script",
                                "tests/create_q005_web_save.gd",
                                "--",
                                str(fixture_path),
                            ],
                            check=True,
                            capture_output=True,
                            text=True,
                        )
                        turtle_fixture = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
                        page.evaluate(
                            """async ({key, payload}) => new Promise((resolve, reject) => {
                                const binary = atob(payload);
                                const contents = new Int8Array(binary.length);
                                for (let index = 0; index < binary.length; index++) {
                                    contents[index] = binary.charCodeAt(index);
                                }
                                const opening = indexedDB.open('/userfs');
                                opening.onerror = () => reject(opening.error);
                                opening.onsuccess = () => {
                                    const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                                    const store = transaction.objectStore('FILE_DATA');
                                    const existing = store.get(key);
                                    existing.onsuccess = () => {
                                        const record = existing.result || {};
                                        record.timestamp = new Date();
                                        record.contents = contents;
                                        store.put(record, key);
                                    };
                                    transaction.oncomplete = resolve;
                                    transaction.onerror = () => reject(transaction.error);
                                };
                            })""",
                            {"key": save_key, "payload": turtle_fixture},
                        )
                        page.reload(wait_until="load", timeout=60_000)
                        page.wait_for_selector("canvas", timeout=60_000)
                        page.wait_for_timeout(3_000)
                        turtle_save = page.evaluate(
                            """async key => new Promise((resolve, reject) => {
                                const opening = indexedDB.open('/userfs');
                                opening.onerror = () => reject(opening.error);
                                opening.onsuccess = () => {
                                    const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                    const request = transaction.objectStore('FILE_DATA').get(key);
                                    request.onsuccess = () => {
                                        const bytes = new Uint8Array(request.result.contents);
                                        resolve(JSON.parse(new TextDecoder().decode(bytes)));
                                    };
                                    request.onerror = () => reject(request.error);
                                };
                            })""",
                            save_key,
                        )
                        if turtle_save.get("q005_watered") is not False or turtle_save.get("pond_opened") is not True:
                            raise AssertionError("The browser did not load the Q005 turtle-garden fixture")
                        page.screenshot(path=str(turtle_garden_screenshot_path), full_page=True)
                        result["q005_turtle_garden_screenshot"] = str(turtle_garden_screenshot_path)

                        # Play the complete Q005 interaction in the browser: water,
                        # collect all three blooms without a redundant tray drag, then
                        # carry the bouquet to the turtle and deliver it.
                        # Cross at the center of the bridge, then approach the
                        # watering point from the south with timing margin for WebGL.
                        print(f"Q005 start: {navigator.position()}", flush=True)
                        navigator.go(("y", 339), ("x", 960), ("y", 500), ("x", 975))
                        print(f"Q005 watering point: {navigator.position()}", flush=True)
                        page.screenshot(path=str(artifact_dir / "web-q005-at-watering-point.png"), full_page=True)
                        page.mouse.click(1_214, 662)
                        page.wait_for_timeout(180)
                        page.screenshot(path=str(turtle_growth_screenshot_path), full_page=True)
                        # Godot WebFS commits writes to IndexedDB asynchronously.
                        watered_save = {}
                        for _ in range(24):
                            watered_save = page.evaluate(
                                """async key => new Promise((resolve, reject) => {
                                    const opening = indexedDB.open('/userfs');
                                    opening.onerror = () => reject(opening.error);
                                    opening.onsuccess = () => {
                                        const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                        const request = transaction.objectStore('FILE_DATA').get(key);
                                        request.onsuccess = () => resolve(JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))));
                                        request.onerror = () => reject(request.error);
                                    };
                                })""",
                                save_key,
                            )
                            if watered_save.get("q005_watered") is True:
                                break
                            page.wait_for_timeout(500)
                        if watered_save.get("q005_watered") is not True:
                            raise AssertionError("The bottom-right control did not water the Q005 garden")
                        # Approach the first bloom from the south-west, then
                        # walk east from flower to flower. Keep each pickup a
                        # separate right-thumb action so the test matches play.
                        navigator.go(("x", 1028), ("y", 480))
                        page.mouse.click(1_214, 662)
                        page.wait_for_timeout(180)
                        page.screenshot(path=str(turtle_collection_screenshot_path), full_page=True)
                        collected_save = {}
                        for _ in range(24):
                            collected_save = page.evaluate(
                                """async key => new Promise((resolve, reject) => {
                                    const opening = indexedDB.open('/userfs');
                                    opening.onerror = () => reject(opening.error);
                                    opening.onsuccess = () => {
                                        const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                        const request = transaction.objectStore('FILE_DATA').get(key);
                                        request.onsuccess = () => resolve(JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))));
                                        request.onerror = () => reject(request.error);
                                    };
                                })""",
                                save_key,
                            )
                            plant_flags = collected_save.get("q005_plants_collected", [])
                            if isinstance(plant_flags, list) and sum(bool(flag) for flag in plant_flags) == 1:
                                break
                            page.wait_for_timeout(500)
                        plant_flags = collected_save.get("q005_plants_collected", [])
                        if not isinstance(plant_flags, list) or sum(bool(flag) for flag in plant_flags) != 1:
                            raise AssertionError("The Q005 plant was not collected after watering through the browser")
                        if collected_save.get("q005_plant_slots") != plant_flags or collected_save.get("q005_completed") is True:
                            raise AssertionError("Harvesting must leave the flower in its bed and wait for bouquet delivery")

                        for harvest_step in range(1, 3):
                            expected_count = harvest_step + 1
                            # Walk to the next uncollected flower with real keys;
                            # the saved flags choose the target, not elapsed time.
                            remaining_id = next(
                                index for index, collected in enumerate(plant_flags) if not collected
                            )
                            # A ready interaction is a single action. Retrying the
                            # click while IndexedDB is still committing can harvest
                            # the neighboring flower too and advance the live quest
                            # before the test observes the saved count.
                            navigator.go(("y", 520), ("x", (1028, 1080, 1132)[remaining_id]))
                            navigator.move_until_ready("w", "采花")
                            page.mouse.click(1_214, 662)
                            harvested_save = {}
                            for _ in range(24):
                                harvested_save = page.evaluate(
                                    """async key => new Promise((resolve, reject) => {
                                        const opening = indexedDB.open('/userfs');
                                        opening.onerror = () => reject(opening.error);
                                        opening.onsuccess = () => {
                                            const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                            const request = transaction.objectStore('FILE_DATA').get(key);
                                            request.onsuccess = () => resolve(JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))));
                                            request.onerror = () => reject(request.error);
                                        };
                                    })""",
                                    save_key,
                                )
                                plant_flags = harvested_save.get("q005_plants_collected", [])
                                if isinstance(plant_flags, list) and sum(bool(flag) for flag in plant_flags) >= expected_count:
                                    break
                                page.wait_for_timeout(500)
                            page.screenshot(
                                path=str(artifact_dir / f"web-q005-harvest-{harvest_step + 1}.png"),
                                full_page=True,
                            )
                            plant_flags = harvested_save.get("q005_plants_collected", [])
                            if not isinstance(plant_flags, list) or sum(bool(flag) for flag in plant_flags) < expected_count:
                                raise AssertionError(f"The browser must collect flower {expected_count}/3; latest save: " + json.dumps(harvested_save, ensure_ascii=False))
                        harvested_save = {}
                        for _ in range(24):
                            harvested_save = page.evaluate(
                                """async key => new Promise((resolve, reject) => {
                                    const opening = indexedDB.open('/userfs');
                                    opening.onerror = () => reject(opening.error);
                                    opening.onsuccess = () => {
                                        const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                        const request = transaction.objectStore('FILE_DATA').get(key);
                                        request.onsuccess = () => resolve(JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))));
                                        request.onerror = () => reject(request.error);
                                    };
                                })""",
                                save_key,
                            )
                            if harvested_save.get("q005_plants_collected") == [True, True, True]:
                                break
                            page.wait_for_timeout(500)
                        if harvested_save.get("q005_plants_collected") != [True, True, True]:
                            raise AssertionError(
                                "The browser must allow the full three-flower harvest; latest save: "
                                + json.dumps(harvested_save, ensure_ascii=False)
                            )
                        if harvested_save.get("q005_harvest_delivered") is True or harvested_save.get("q005_completed") is True:
                            raise AssertionError("A full harvest must still wait for the turtle delivery interaction")
                        page.screenshot(path=str(turtle_bouquet_screenshot_path), full_page=True)

                        # The turtle walks a patrol while flowers are collected.
                        # Chase its current position with ordinary WASD input;
                        # a stale fixed coordinate can leave the player outside
                        # the interaction radius even after completing the loop.
                        # Leave the eastern rock from its open western side
                        # before chasing the patrolling NPC.
                        navigator.go(("x", 1090), ("y", 420))
                        navigator.pursue_turtle()
                        page.screenshot(path=str(artifact_dir / "web-q005-at-turtle.png"), full_page=True)
                        page.mouse.click(1_214, 662)
                        page.wait_for_timeout(180)
                        delivered_save = {}
                        for _ in range(12):
                            delivered_save = page.evaluate(
                                """async key => new Promise((resolve, reject) => {
                                    const opening = indexedDB.open('/userfs');
                                    opening.onerror = () => reject(opening.error);
                                    opening.onsuccess = () => {
                                        const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                        const request = transaction.objectStore('FILE_DATA').get(key);
                                        request.onsuccess = () => resolve(JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))));
                                        request.onerror = () => reject(request.error);
                                    };
                                })""",
                                save_key,
                            )
                            if delivered_save.get("q005_harvest_delivered") is True:
                                break
                            page.wait_for_timeout(500)
                        if delivered_save.get("q005_harvest_delivered") is not True or delivered_save.get("q005_completed") is not True:
                            raise AssertionError("Interacting with the turtle must deliver the bouquet and complete Q005")
                        page.screenshot(path=str(turtle_delivery_screenshot_path), full_page=True)
                        result["q005_watered_browser_flow"] = "passed"
                        result["q005_growth_screenshot"] = str(turtle_growth_screenshot_path)
                        result["q005_collection_screenshot"] = str(turtle_collection_screenshot_path)
                        result["q005_bouquet_screenshot"] = str(turtle_bouquet_screenshot_path)
                        result["q005_delivery_screenshot"] = str(turtle_delivery_screenshot_path)

                with tempfile.TemporaryDirectory(prefix="wonder-isle-q012-") as temp_dir:
                    fixture_path = Path(temp_dir) / "q012-ending-save.json"
                    subprocess.run(
                        [
                            godot_bin,
                            "--headless",
                            "--path",
                            str(Path(__file__).resolve().parent.parent),
                            "--script",
                            "tests/create_q012_web_save.gd",
                            "--",
                            str(fixture_path),
                        ],
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    fixture_base64 = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
                    save_key = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"
                    page.mouse.click(800, 600)
                    # Use the right-thumb interaction control for the final
                    # celebration, matching the intended touch-friendly action.
                    page.mouse.click(1_214, 662)
                    page.wait_for_timeout(1_000)
                    page.evaluate(
                        """async ({key, payload}) => new Promise((resolve, reject) => {
                            const binary = atob(payload);
                            const contents = new Int8Array(binary.length);
                            for (let index = 0; index < binary.length; index++) {
                                contents[index] = binary.charCodeAt(index);
                            }
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                                const store = transaction.objectStore('FILE_DATA');
                                const existing = store.get(key);
                                existing.onsuccess = () => {
                                    if (!existing.result) {
                                        reject(new Error('The game did not create its save file'));
                                        return;
                                    }
                                    existing.result.timestamp = new Date();
                                    existing.result.contents = contents;
                                    store.put(existing.result, key);
                                };
                                transaction.oncomplete = resolve;
                                transaction.onerror = () => reject(transaction.error);
                            };
                        })""",
                        {"key": save_key, "payload": fixture_base64},
                    )
                    page.reload(wait_until="load", timeout=60_000)
                    page.wait_for_selector("canvas", timeout=60_000)
                    page.wait_for_timeout(3_000)
                    page.screenshot(path=str(ending_screenshot_path), full_page=True)

                    page.mouse.click(800, 600)
                    # Walk around the cottage on the left island, then approach
                    # the rabbit from the north. The former eastward sweep
                    # relied on crossing the river directly, which the
                    # production collision map correctly prevents.
                    for key, duration_ms in (("w", 380), ("d", 1_300), ("w", 650)):
                        page.keyboard.down(key)
                        page.wait_for_timeout(duration_ms)
                        page.keyboard.up(key)
                    # Retry the right-thumb interaction in place to tolerate
                    # small browser frame-rate differences without walking
                    # away from the target.
                    for _ in range(6):
                        page.mouse.click(1_214, 662)
                        page.wait_for_timeout(350)
                    page.screenshot(path=str(artifact_dir / "web-q012-at-rabbit.png"), full_page=True)
                    page.wait_for_timeout(1_500)
                    page.screenshot(path=str(artifact_dir / "web-q012-after-interact.png"), full_page=True)
                    page.wait_for_timeout(6_000)
                    page.reload(wait_until="load", timeout=60_000)
                    page.wait_for_selector("canvas", timeout=60_000)
                    page.wait_for_timeout(3_000)
                    page.screenshot(path=str(artifact_dir / "web-q012-after-refresh.png"), full_page=True)
                    saved_ending = page.evaluate(
                        """async key => new Promise((resolve, reject) => {
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                const request = transaction.objectStore('FILE_DATA').get(key);
                                request.onsuccess = () => {
                                    const bytes = new Uint8Array(request.result.contents);
                                    resolve(JSON.parse(new TextDecoder().decode(bytes)));
                                };
                                request.onerror = () => reject(request.error);
                            };
                        })""",
                        save_key,
                    )
                    if saved_ending.get("q012_completed") is not True:
                        raise AssertionError(
                            "The browser did not persist Q012: "
                            f"{saved_ending.get('q012_completed')}; console errors: {result['console_errors']}"
                        )
                    result["q012_browser_flow"] = "passed"
                    page.screenshot(path=str(completed_screenshot_path), full_page=True)
                    result["q012_ending_screenshot"] = str(ending_screenshot_path)
                    result["q012_complete_screenshot"] = str(completed_screenshot_path)

                    with tempfile.TemporaryDirectory(prefix="wonder-isle-q011-complete-") as temp_dir:
                        fixture_path = Path(temp_dir) / "q011-complete-save.json"
                        subprocess.run(
                            [
                                godot_bin,
                                "--headless",
                                "--path",
                                str(Path(__file__).resolve().parent.parent),
                                "--script",
                                "tests/create_q011_complete_web_save.gd",
                                "--",
                                str(fixture_path),
                            ],
                            check=True,
                            capture_output=True,
                            text=True,
                        )
                        complete_fixture = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
                        page.evaluate(
                            """async ({key, payload}) => new Promise((resolve, reject) => {
                                const binary = atob(payload);
                                const contents = new Int8Array(binary.length);
                                for (let index = 0; index < binary.length; index++) {
                                    contents[index] = binary.charCodeAt(index);
                                }
                                const opening = indexedDB.open('/userfs');
                                opening.onerror = () => reject(opening.error);
                                opening.onsuccess = () => {
                                    const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                                    const store = transaction.objectStore('FILE_DATA');
                                    const request = store.get(key);
                                    request.onsuccess = () => {
                                        const record = request.result || {};
                                        record.timestamp = new Date();
                                        record.contents = contents;
                                        store.put(record, key);
                                    };
                                    transaction.oncomplete = resolve;
                                    transaction.onerror = () => reject(transaction.error);
                                };
                            })""",
                            {"key": save_key, "payload": complete_fixture},
                        )
                        page.reload(wait_until="load", timeout=60_000)
                        page.wait_for_selector("canvas", timeout=60_000)
                        page.wait_for_timeout(3_000)
                        page.screenshot(path=str(final_island_screenshot_path), full_page=True)
                        result["q011_all_tasks_complete_screenshot"] = str(final_island_screenshot_path)
                        page.mouse.click(950, 50)
                        page.wait_for_timeout(500)
                        page.screenshot(path=str(build_adjustment_screenshot_path), full_page=True)
                        result["q011_build_adjustment_screenshot"] = str(build_adjustment_screenshot_path)

                failure_page = browser.new_page()
                failure_page.add_init_script(
                    """(() => {
                        try { delete Navigator.prototype.serviceWorker; } catch (_) {}
                        try { delete navigator.serviceWorker; } catch (_) {}
                        Object.defineProperty(window, 'Engine', {
                            configurable: true,
                            get() { return undefined; },
                            set(engineClass) {
                                Object.defineProperty(window, 'Engine', {
                                    configurable: true,
                                    writable: true,
                                    value: engineClass,
                                });
                                engineClass.getMissingFeatures = () => [
                                    'WebGL2 - Check web browser configuration and hardware support',
                                ];
                            },
                        });
                    })();"""
                )
                failure_page.goto(
                    f"http://127.0.0.1:{server.server_port}/index.html",
                    wait_until="load",
                    timeout=60_000,
                )
                failure_page.locator("#status-notice").wait_for(state="visible", timeout=10_000)
                failure_notice = failure_page.locator("#status-notice").inner_text()
                expected_failure_help = (
                    "WebGL2（浏览器图形加速）",
                    "chrome://settings/system",
                    "chrome://gpu",
                    "使用图形加速",
                )
                if any(fragment not in failure_notice for fragment in expected_failure_help):
                    raise AssertionError(
                        f"WebGL2 failure notice lacks clear Chinese troubleshooting steps: {failure_notice}"
                    )
                notice_dimensions = failure_page.locator("#status-notice").evaluate(
                    "element => ({height: element.clientHeight, scrollHeight: element.scrollHeight, width: element.clientWidth, scrollWidth: element.scrollWidth})"
                )
                if (
                    notice_dimensions["scrollHeight"] > notice_dimensions["height"] + 1
                    or notice_dimensions["scrollWidth"] > notice_dimensions["width"] + 1
                ):
                    raise AssertionError(
                        f"WebGL2 troubleshooting text is clipped: {notice_dimensions}"
                    )
                result["webgl2_failure_notice_test"] = "passed"
                result["webgl2_failure_notice_dimensions"] = notice_dimensions
                fallback_screenshot = artifact_dir / "webgl2-fallback.png"
                failure_page.screenshot(path=str(fallback_screenshot), full_page=True)
                result["webgl2_fallback_screenshot"] = str(fallback_screenshot)
                failure_page.close()
            finally:
                browser.close()
    finally:
        server.shutdown()
        server.server_close()
        server_thread.join(timeout=2)

    print(json.dumps(result, ensure_ascii=False, indent=2))
    if result.get("http_status") != 200:
        raise AssertionError(f"Unexpected HTTP status: {result.get('http_status')}")
    if result.get("title") != "奇趣小岛":
        raise AssertionError(f"Unexpected page title: {result.get('title')}")
    for error_key in ("console_errors", "page_errors", "request_failures"):
        if result[error_key]:
            raise AssertionError(f"Browser reported {error_key}: {result[error_key]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
