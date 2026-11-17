#!/usr/bin/env python3
"""Verify repeatable plant and fishing cycles from a real post-story save."""

from __future__ import annotations

import base64
import functools
import json
import os
import sys
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright
from browser_navigation import Navigator
from web_save_namespace import MIRROR_KEY, SAVE_KEY


PLANT_POSITIONS = ((1028, 480), (1080, 480), (1132, 480))


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, _format: str, *_args: object) -> None:
        pass


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: test_free_life_browser.py <web-export-directory>", file=sys.stderr)
        return 2
    build_dir = Path(sys.argv[1]).resolve()
    save_path = Path(os.environ.get("WONDER_ISLE_POST_STORY_SAVE", ""))
    if not (build_dir / "index.html").is_file() or not save_path.is_file():
        print("A Web export and genuine Q012/Q010/Q011 post-story save are required", file=sys.stderr)
        return 2
    initial_save = json.loads(save_path.read_text(encoding="utf-8"))
    if initial_save.get("q012_completed") is not True or initial_save.get("q010_seeds_collected") != [True, True, True] or initial_save.get("q011_slot_occupants") != [0, 1, 2]:
        print("The supplied save must come from real Q001–Q012 and Q007–Q011 gameplay", file=sys.stderr)
        return 2
    artifact_dir = Path(os.environ.get("WEB_TEST_ARTIFACTS", build_dir / "test-artifacts")).resolve()
    artifact_dir.mkdir(parents=True, exist_ok=True)
    binary_payload = base64.b64encode(save_path.read_bytes()).decode("ascii")

    with ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(QuietHandler, directory=str(build_dir))) as server:
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            with sync_playwright() as playwright:
                launch: dict[str, object] = {"headless": True}
                chromium_path = os.environ.get("CHROMIUM_PATH")
                if chromium_path:
                    launch["executable_path"] = chromium_path
                browser = playwright.chromium.launch(**launch)
                context = browser.new_context(viewport={"width": 1280, "height": 720}, device_scale_factor=1, service_workers="block")
                page = context.new_page()
                navigator = Navigator(page, (build_dir / "index.html").read_text(encoding="utf-8"))
                page.on("pageerror", lambda error: print(f"BROWSER PAGE ERROR: {error}", flush=True))
                page.on("console", lambda message: print(f"BROWSER CONSOLE ERROR: {message.text}", flush=True) if message.type == "error" else None)
                page.goto(f"http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1", wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(1_500)
                page.evaluate(
                    """({key, payload}) => {
                        const binary = atob(payload);
                        const bytes = new Uint8Array(binary.length);
                        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
                        localStorage.setItem(key, new TextDecoder().decode(bytes));
                    }""",
                    {"key": MIRROR_KEY, "payload": binary_payload},
                )
                page.evaluate(
                    """({key, payload}) => new Promise((resolve, reject) => {
                        const binary = atob(payload);
                        const contents = new Int8Array(binary.length);
                        for (let i = 0; i < binary.length; i++) contents[i] = binary.charCodeAt(i);
                        const opening = indexedDB.open('/userfs');
                        opening.onerror = () => reject(opening.error);
                        opening.onsuccess = () => {
                            const tx = opening.result.transaction('FILE_DATA', 'readwrite');
                            const store = tx.objectStore('FILE_DATA');
                            const timestamp = new Date();
                            const segments = key.split('/').filter(Boolean);
                            let parent = '';
                            for (const segment of segments.slice(0, -1)) {
                                parent += '/' + segment;
                                const directoryKey = parent;
                                const directoryRequest = store.get(directoryKey);
                                directoryRequest.onsuccess = () => {
                                    if (!directoryRequest.result) store.put({timestamp, mode: 0x41ED}, directoryKey);
                                };
                            }
                            const request = store.get(key);
                            request.onsuccess = () => {
                                const record = request.result || {};
                                record.timestamp = timestamp;
                                record.mode = record.mode || 0x81B6;
                                record.contents = contents;
                                store.put(record, key);
                            };
                            tx.oncomplete = resolve;
                            tx.onerror = () => reject(tx.error);
                        };
                    })""",
                    {"key": SAVE_KEY, "payload": binary_payload},
                )
                before_reload = navigator.state_received_at
                page.reload(wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                restored = navigator.wait_for_fresh_state(after=before_reload)
                if restored.get("test_save_data", {}).get("q012_completed") is not True:
                    raise AssertionError(f"The genuine post-story save did not load: {restored}")

                def read_db() -> dict[str, object] | None:
                    return page.evaluate(
                        """key => new Promise((resolve, reject) => {
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const request = opening.result.transaction('FILE_DATA', 'readonly').objectStore('FILE_DATA').get(key);
                                request.onerror = () => reject(request.error);
                                request.onsuccess = () => resolve(request.result ? JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))) : null);
                            };
                        })""",
                        SAVE_KEY,
                    )

                def wait_for_save(predicate, label: str, timeout: float = 60.0) -> dict[str, object]:
                    deadline = time.monotonic() + timeout
                    last_db: dict[str, object] | None = None
                    last_memory: dict[str, object] = {}
                    while time.monotonic() < deadline:
                        last_memory = navigator.position().get("test_save_data", {})
                        last_db = read_db()
                        mirror = page.evaluate("key => JSON.parse(localStorage.getItem(key) || 'null')", MIRROR_KEY)
                        if mirror and mirror.get("format") == "wonder-isle-save-mirror-v2":
                            mirror = mirror.get("payload")
                        if last_db and mirror and predicate(last_memory) and predicate(mirror) and predicate(last_db):
                            print(f"PASS {label}", flush=True)
                            return last_db
                        page.wait_for_timeout(300)
                    raise AssertionError(f"{label}: memory={last_memory}; IDB={last_db}")

                def wait_for_mirror(predicate, label: str, timeout: float = 3.0) -> dict[str, object]:
                    deadline = time.monotonic() + timeout
                    while time.monotonic() < deadline:
                        memory = navigator.position().get("test_save_data", {})
                        mirror = page.evaluate("key => JSON.parse(localStorage.getItem(key) || 'null')", MIRROR_KEY)
                        if mirror and mirror.get("format") == "wonder-isle-save-mirror-v2":
                            mirror = mirror.get("payload")
                        if mirror and predicate(memory) and predicate(mirror):
                            print(f"PASS {label} in memory and sync mirror", flush=True)
                            return mirror
                        page.wait_for_timeout(50)
                    raise AssertionError(f"{label}: memory={navigator.position().get('test_save_data')} mirror={page.evaluate('key => localStorage.getItem(key)', MIRROR_KEY)}")

                def interact() -> None:
                    if not navigator.position().get("ready"):
                        raise AssertionError(f"Interaction is not ready: {navigator.position()}")
                    page.mouse.click(1_214, 662)
                    page.wait_for_timeout(120)

                def check_animal_reply(expected: str, label: str) -> None:
                    state = navigator.position()
                    if not state.get("ready"):
                        raise AssertionError(f"{label} action is not ready: {state}")
                    page.screenshot(path=str(artifact_dir / f"{label.replace(' ', '-')}-before-click.png"))
                    interact()
                    deadline = time.monotonic() + 3.0
                    while time.monotonic() < deadline:
                        state = navigator.position()
                        if expected in state.get("message", ""):
                            print(f"PASS {label}", flush=True)
                            return
                        page.wait_for_timeout(50)
                    raise AssertionError(f"{label} button produced no visible reply: {state}")

                def move_to_plant(plant_id: int) -> None:
                    state = navigator.position()
                    phase = state.get("test_save_data", {}).get("free_plant_phase", [0, 0, 0])[plant_id]
                    expected_action = ("种" + ("红花种子", "蓝花种子", "金色种子")[plant_id]) if phase == 0 else {1: "浇水", 2: "照料中", 3: "收获"}[phase]
                    if state.get("ready") and state.get("action") == expected_action:
                        return
                    # The default decor piece sits just south of the third
                    # bed. Approach that bed from its north edge so the decor
                    # does not turn a normal southern route into a dead end.
                    if plant_id == 2:
                        # A previous plant interaction can leave the player on
                        # the pond island. Reach the bridge deck before moving
                        # west; attempting x=400 at y=500 asks the avatar to
                        # walk through the river instead of using the bridge.
                        if state.get("x", 0) > 900 and state.get("y", 0) > 390:
                            navigator.go(("y", 339))
                        navigator.go(("x", 400), ("y", 339), ("x", 1160), ("y", 450))
                    elif state.get("x", 0) < 900:
                        navigator.go(("y", 339), ("x", 960), ("y", 500))
                    state = navigator.position()
                    if not state.get("ready") or state.get("action") != expected_action:
                        navigator.move_until_ready("d", expected_action)
                    page.wait_for_timeout(150)
                    state = navigator.position()
                    if not state.get("ready") or state.get("action") != expected_action:
                        raise AssertionError(f"Free plant {plant_id + 1} has no ready planting action at its bed: {state}")
                    page.screenshot(path=str(artifact_dir / f"free-plant-{plant_id + 1}-ready.png"))

                checks: list[str] = ["restore actual Q012/Q010/Q011 completed save in isolated localStorage and IndexedDB"]
                if os.environ.get("WONDER_ISLE_SKIP_ANIMALS") != "1":
                    navigator.go(("x", 400), ("y", 500))
                    if navigator.position().get("action") != "打招呼":
                        raise AssertionError(f"Fox greeting button is missing near its cottage: {navigator.position()}")
                    check_animal_reply("狐狸：", "fox greeting reply")
                    checks.append("fox interaction has a ready action and visible feedback")
                    navigator.go(("y", 339), ("x", 1150), ("y", 280))
                    if navigator.position().get("action") != "问乌龟":
                        raise AssertionError(f"Turtle interaction button is missing by the pond: {navigator.position()}")
                    check_animal_reply("乌龟：", "turtle greeting reply")
                    checks.append("turtle interaction has a ready action and visible feedback")
                    navigator.go(("y", 339), ("x", 650))
                    navigator.move_until_ready("s", "打招呼")
                    if navigator.position().get("action") != "打招呼":
                        raise AssertionError(f"Bird greeting button is missing by the birdhouse: {navigator.position()}")
                    check_animal_reply("小鸟：", "bird greeting reply")
                    checks.append("bird interaction has a ready action and visible feedback")
                    navigator.go(("y", 339), ("x", 430), ("y", 195))
                    if navigator.position().get("action") != "问兔子":
                        raise AssertionError(f"Rabbit interaction button is missing after the ending: {navigator.position()}")
                    check_animal_reply("兔子", "rabbit greeting reply")
                    checks.append("rabbit interaction has a ready action and visible feedback after Q012")
                configured_plant_ids = os.environ.get("WONDER_ISLE_PLANT_IDS", "0,1,2")
                plant_ids = [int(value) for value in configured_plant_ids.split(",") if value.strip()]
                if any(plant_id not in range(3) for plant_id in plant_ids):
                    raise ValueError(f"Invalid plant IDs: {configured_plant_ids}")
                for plant_id in plant_ids:
                    move_to_plant(plant_id)
                    interact()
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 1, f"plant species {plant_id + 1}")
                    interact()
                    wait_for_mirror(lambda s, i=plant_id: s["free_plant_phase"][i] == 2, f"water species {plant_id + 1}")
                    checks.append(f"species {plant_id + 1}: plant and water")

                    # Reload during growth, prove the persisted stage, and let
                    # the fresh instance finish its normal growth timer.
                    previous_id = navigator.position().get("test_instance_id")
                    previous_event = navigator.state_received_at
                    page.reload(wait_until="load", timeout=60_000)
                    page.wait_for_selector("canvas", timeout=60_000)
                    reloaded = navigator.wait_for_fresh_state(after=previous_event)
                    if reloaded.get("test_instance_id") == previous_id or reloaded.get("test_save_data", {}).get("free_plant_phase", [])[plant_id] != 2:
                        raise AssertionError(f"Plant growth state was not restored after refresh: {reloaded}")
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 2, f"growth stage {plant_id + 1} survives refresh")
                    deadline = time.monotonic() + 60
                    next_growth_report = time.monotonic() + 5
                    while time.monotonic() < deadline:
                        data = navigator.position().get("test_save_data", {})
                        if data.get("free_plant_phase", [])[plant_id] == 3:
                            break
                        if time.monotonic() >= next_growth_report:
                            print(f"WAIT species {plant_id + 1} growth: phase={data.get('free_plant_phase')} position={navigator.position().get('x')},{navigator.position().get('y')}", flush=True)
                            next_growth_report = time.monotonic() + 5
                        page.wait_for_timeout(200)
                    else:
                        raise AssertionError(f"Species {plant_id + 1} did not mature: {navigator.position()}")
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 3, f"mature species {plant_id + 1}")
                    move_to_plant(plant_id)
                    interact()
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 0 and s["free_plant_harvests"][i] == 1, f"harvest species {plant_id + 1} first cycle")
                    interact()
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 1, f"replant species {plant_id + 1}")
                    interact()
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 2, f"rewater species {plant_id + 1}")
                    deadline = time.monotonic() + 60
                    while time.monotonic() < deadline:
                        if navigator.position().get("test_save_data", {}).get("free_plant_phase", [])[plant_id] == 3:
                            break
                        page.wait_for_timeout(200)
                    else:
                        raise AssertionError(f"Species {plant_id + 1} did not mature for its repeat harvest")
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 3, f"mature species {plant_id + 1} repeat cycle")
                    move_to_plant(plant_id)
                    interact()
                    wait_for_save(lambda s, i=plant_id: s["free_plant_phase"][i] == 0 and s["free_plant_harvests"][i] == 2, f"harvest species {plant_id + 1} second cycle")
                    checks.append(f"species {plant_id + 1}: two complete persisted growth and harvest cycles")

                # The north edge of the pond is solid. Walk south along the
                # shore first, then approach the overlapping flower bed from
                # safe grass so the test does not ask the avatar to enter water.
                navigator.go(("y", 339), ("x", 930), ("y", 340), ("x", 960))
                navigator.axis("y", 440, tolerance=3)
                navigator.axis("x", 1040, tolerance=3)
                overlap = navigator.position()
                if overlap.get("action") != "种红花种子":
                    raise AssertionError(f"The closer flower-bed target was not selected in the pond overlap: {overlap}")
                print("PASS pond/garden overlap selects the closer flower bed", flush=True)
                navigator.move_until_ready("w", "开始钓鱼")
                if navigator.position().get("action") != "开始钓鱼":
                    navigator.move_until_ready("w", "开始钓鱼")
                interact()
                wait_for_mirror(lambda s: s["fishing_phase"] == 1, "cast fishing line")
                interact()
                wait_for_save(lambda s: s["fishing_phase"] == 0 and s["fish_count"] == 0, "cancel fishing without losing progress")
                interact()
                wait_for_mirror(lambda s: s["fishing_phase"] == 1, "cast fishing line again")
                wait_for_save(lambda s: s["fishing_phase"] == 2, "fish bites after float animation")
                interact()
                wait_for_save(lambda s: s["fishing_phase"] == 0 and s["fish_count"] == 1, "reel first fish")
                interact()
                wait_for_mirror(lambda s: s["fishing_phase"] == 1, "cast second fishing cycle")
                wait_for_save(lambda s: s["fishing_phase"] == 2, "second fish bites")
                interact()
                wait_for_save(lambda s: s["fishing_phase"] == 0 and s["fish_count"] == 2, "reel second fish")
                checks.append("fishing: cast, cancel, catch twice")

                # Moving away during a cast exits fishing cleanly.
                interact()
                wait_for_mirror(lambda s: s["fishing_phase"] == 1, "start fishing before walking away")
                navigator.go(("y", 500))
                wait_for_save(lambda s: s["fishing_phase"] == 0 and s["fish_count"] == 2, "walking away cancels fishing")
                previous_event = navigator.state_received_at
                page.reload(wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                restored = navigator.wait_for_fresh_state(after=previous_event)
                final = wait_for_save(
                    lambda s: s.get("q012_completed") is True
                    and s.get("free_plant_harvests") == [2 if i in plant_ids else 0 for i in range(3)]
                    and s.get("free_plant_phase") == [0, 0, 0]
                    and s.get("fish_count") == 2
                    and s.get("fishing_phase") == 0,
                    "all repeatable free-life progress survives reload",
                )
                if restored.get("test_save_data", {}).get("q012_completed") is not True:
                    raise AssertionError(f"Post-story save failed to reload: {restored}")
                checks.append("post-story save reload preserves all three plant cycles and fishing count")
                page.screenshot(path=str(artifact_dir / "free-life-final.png"))
                print(json.dumps({"result": "passed", "checks": checks, "final_save": final}, ensure_ascii=False, indent=2))
                browser.close()
        finally:
            server.shutdown()
            server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
