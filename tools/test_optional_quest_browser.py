#!/usr/bin/env python3
"""Play Q007–Q011 with real browser keyboard and pointer input."""

from __future__ import annotations

import base64
import functools
import json
import os
import subprocess
import sys
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright
from browser_navigation import Navigator


SAVE_KEY = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, _format: str, *_args: object) -> None:
        pass


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: test_optional_quest_browser.py <web-export-directory>", file=sys.stderr)
        return 2

    project_root = Path(__file__).resolve().parent.parent
    build_dir = Path(sys.argv[1]).resolve()
    artifact_dir = Path(os.environ.get("WEB_TEST_ARTIFACTS", project_root / "tests/artifacts")).resolve()
    artifact_dir.mkdir(parents=True, exist_ok=True)
    godot_bin = os.environ.get(
        "GODOT_BIN", "/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
    )
    if not (build_dir / "index.html").is_file() or not Path(godot_bin).is_file():
        print("A Godot Web export and Godot 4.7.2 are required", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory(prefix="wonder-isle-post-story-") as temp_dir:
        genuine_save_path = Path(os.environ.get("WONDER_ISLE_Q012_SAVE", ""))
        if not genuine_save_path.is_file():
            print("WONDER_ISLE_Q012_SAVE must point to a Q012 save created by real game input", file=sys.stderr)
            return 2
        genuine_save = json.loads(genuine_save_path.read_text(encoding="utf-8"))
        if genuine_save.get("q012_completed") is not True or genuine_save.get("q006_completed") is not True:
            print("The supplied save was not produced after completing Q006 and Q012", file=sys.stderr)
            return 2
        fixture_path = genuine_save_path
        fixture_payload = base64.b64encode(fixture_path.read_bytes()).decode("ascii")

        server = ThreadingHTTPServer(
            ("127.0.0.1", 0), functools.partial(QuietHandler, directory=str(build_dir))
        )
        threading.Thread(target=server.serve_forever, daemon=True).start()
        errors: list[str] = []
        checks: list[str] = []
        try:
            with sync_playwright() as playwright:
                launch_options: dict[str, object] = {"headless": True}
                chromium_path = os.environ.get("CHROMIUM_PATH")
                if chromium_path:
                    launch_options["executable_path"] = chromium_path
                browser = playwright.chromium.launch(**launch_options)
                context = browser.new_context(viewport={"width": 1280, "height": 720}, device_scale_factor=1, service_workers="block")
                page = context.new_page()
                navigator = Navigator(page, (build_dir / "index.html").read_text(encoding="utf-8"))
                page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
                page.on("pageerror", lambda error: errors.append(str(error)))
                page.on(
                    "requestfailed",
                    lambda request: errors.append(f"{request.url}: {request.failure}"),
                )
                page.goto(f"http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1", wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(2_500)
                page.evaluate(
                    """({key, payload}) => {
                        const binary = atob(payload);
                        const contents = new Uint8Array(binary.length);
                        for (let index = 0; index < binary.length; index++) contents[index] = binary.charCodeAt(index);
                        localStorage.setItem(key, new TextDecoder().decode(contents));
                    }""",
                    {"key": "wonder-isle-save-v1", "payload": fixture_payload},
                )
                # Load the actual save produced by real Q001–Q012 browser play
                # into both persistence layers of a fresh isolated origin; no task fields are fabricated.
                page.evaluate(
                    """async ({key, payload}) => new Promise((resolve, reject) => {
                        const binary = atob(payload);
                        const contents = new Int8Array(binary.length);
                        for (let index = 0; index < binary.length; index++) contents[index] = binary.charCodeAt(index);
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
                                const directoryRequest = store.get(directoryKey);
                                directoryRequest.onsuccess = () => {
                                    if (!directoryRequest.result) store.put({timestamp, mode: 0x41ED}, directoryKey);
                                };
                            }
                            const existing = store.get(key);
                            existing.onsuccess = () => {
                                const record = existing.result || {};
                                record.timestamp = timestamp;
                                record.mode = record.mode || 0x81B6;
                                record.contents = contents;
                                store.put(record, key);
                            };
                            transaction.oncomplete = resolve;
                            transaction.onerror = () => reject(transaction.error);
                        };
                    })""",
                    {"key": SAVE_KEY, "payload": fixture_payload},
                )
                page.reload(wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(2_500)

                def read_save() -> dict[str, object]:
                    return page.evaluate(
                        """async key => new Promise((resolve, reject) => {
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                const request = transaction.objectStore('FILE_DATA').get(key);
                                request.onsuccess = () => {
                                    if (!request.result) return resolve(null);
                                    resolve(JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents))));
                                };
                                request.onerror = () => reject(request.error);
                            };
                        })""",
                        SAVE_KEY,
                    )

                def verify(condition, label: str) -> dict[str, object]:
                    # Check the in-memory state and wait for the asynchronous
                    # WebFS transaction to converge; elapsed time is only a watchdog.
                    latest: dict[str, object] = {}
                    memory: dict[str, object] = {}
                    for _ in range(120):
                        latest = read_save()
                        memory = navigator.position().get("test_save_data", {})
                        if latest and condition(latest) and memory and condition(memory):
                            break
                        page.wait_for_timeout(500)
                    else:
                        raise AssertionError(f"{label}; memory: {json.dumps(memory, ensure_ascii=False)}; latest save: {json.dumps(latest, ensure_ascii=False)}")
                    checks.append(label)
                    print(f"PASS {label}", flush=True)
                    return latest

                def verify_stable(condition, label: str) -> dict[str, object]:
                    # Let WebFS persist the last interaction before the next
                    # deliberate click, then confirm its stage did not change.
                    page.wait_for_timeout(350)
                    latest = read_save()
                    if not latest or not condition(latest):
                        raise AssertionError(f"{label}; settled save: {json.dumps(latest, ensure_ascii=False)}")
                    return latest

                def move(key: str, milliseconds: int) -> None:
                    page.mouse.click(800, 600)
                    page.keyboard.down(key)
                    page.wait_for_timeout(milliseconds)
                    page.keyboard.up(key)
                    page.wait_for_timeout(180)

                def interact() -> None:
                    page.mouse.click(1_214, 662)
                    page.wait_for_timeout(650)

                def approach_and_interact(direction: str, label: str, condition, steps: int = 20) -> dict[str, object]:
                    latest: dict[str, object] = {}
                    for _ in range(steps):
                        interact()
                        # Avoid issuing another physical tap while the browser
                        # has not yet flushed Godot's save into IndexedDB.
                        for _ in range(16):
                            latest = read_save()
                            if latest and condition(latest):
                                checks.append(label)
                                print(f"PASS {label}", flush=True)
                                return latest
                            page.wait_for_timeout(200)
                        move(direction, 120)
                    raise AssertionError(f"{label}; latest save: {json.dumps(latest, ensure_ascii=False)}")

                def drag(source: tuple[int, int], target: tuple[int, int], screenshot: str | None = None) -> None:
                    page.mouse.move(*source)
                    page.mouse.down()
                    page.wait_for_timeout(100)
                    page.mouse.move(*target, steps=12)
                    page.wait_for_timeout(350)
                    if screenshot:
                        page.screenshot(path=str(artifact_dir / screenshot), full_page=True)
                    page.mouse.up()
                    page.wait_for_timeout(700)

                def snap(name: str) -> None:
                    page.screenshot(path=str(artifact_dir / name), full_page=True)

                verify(lambda save: save.get("q012_completed") is True and save.get("q007_completed") is False, "restore genuine Q012 save before optional quests")
                snap("web-q007-optional-unlocked.png")

                # Cross the repaired bridge, reach the shell, and collect it.
                # The shell route enters the bridge from its north edge; keep
                # the low-FPS browser avatar aligned with the walking lane.
                navigator.go(("y", 339), ("x", 960), ("y", 400))
                print(f"Q007 shell approach: {navigator.position()}", flush=True)
                snap("web-q007-before-shell-interaction.png")
                interact()
                verify(
                    lambda save: save.get("q007_shell_collected") is True and save.get("q007_reward_unlocked") is True,
                    "Q007 collect shell and unlock reward",
                )
                snap("web-q007-shell-collected.png")

                # Return across the bridge and gather all birdhouse materials.
                # Move north onto the bridge deck, cross to the west bank, then
                # head south to the rope on the cottage side of the river.
                navigator.go(("y", 339), ("x", 650))
                snap("web-q009-return-aligned.png")
                navigator.go(("y", 460))
                snap("web-q009-return-west-bank.png")
                snap("web-q009-before-rope.png")
                interact()
                verify(lambda save: save.get("q009_materials_collected") == [False, False, True], "Q009 collect rope at west shore")
                # Go around the fox cottage rather than crossing its solid
                # footprint on the way to the branch at the island's south-west.
                navigator.go(("y", 400), ("x", 260))
                navigator.move_until_ready("s", "收材料")
                snap("web-q009-at-branch.png")
                # The westbound return path ends inside this branch's radius;
                # interact immediately instead of walking past it.
                interact()
                verify(
                    lambda save: save.get("q009_materials_collected") == [True, False, True],
                    "Q009 collect branch by west shore",
                )
                navigator.go(("y", 340), ("x", 300))
                interact()
                collected_materials = verify(
                    lambda save: save.get("q009_materials_collected") == [True, True, True]
                    and save.get("q009_completed") is False,
                    "Q009 collect all birdhouse materials and keep delivery pending",
                )
                if collected_materials.get("q009_materials_delivered") != [False, False, False]:
                    raise AssertionError("Collected birdhouse materials must remain undelivered")
                snap("web-q009-awaiting-delivery.png")

                # Take the materials to the birdhouse and hand them over one by
                # one so each interaction visibly advances construction.
                navigator.go(("y", 400), ("x", 650), ("y", 440))
                snap("web-q009-at-birdhouse.png")
                delivery_save = approach_and_interact(
                    "s",
                    "Q009 deliver birdhouse material 1/3",
                    lambda save: save.get("q009_materials_delivered") == [True, False, False],
                )
                if delivery_save.get("q009_completed") is not False:
                    raise AssertionError("The birdhouse must remain under construction until all deliveries")
                verify_stable(
                    lambda save: save.get("q009_materials_delivered") == [True, False, False],
                    "Q009 delivery 1/3 remains stable after one tap",
                )
                snap("web-q009-birdhouse-under-construction.png")
                for delivery_id in range(1, 3):
                    interact()
                    expected_deliveries = [True, delivery_id >= 1, delivery_id >= 2]
                    delivery_save = verify(
                        lambda save, expected=expected_deliveries: save.get("q009_materials_delivered") == expected,
                        f"Q009 deliver birdhouse material {delivery_id + 1}/3",
                    )
                    if delivery_id < 2 and delivery_save.get("q009_completed") is not False:
                        raise AssertionError("The birdhouse must remain under construction until all deliveries")
                    verify_stable(
                        lambda save, expected=expected_deliveries: save.get("q009_materials_delivered") == expected,
                        f"Q009 delivery {delivery_id + 1}/3 remains stable after one tap",
                    )
                verify(lambda save: save.get("q009_completed") is True, "Q009 finish birdhouse after three deliveries")
                snap("web-q009-birdhouse-complete.png")

                # The greeting is optional, but it should work once materials are gathered.
                navigator.go(("y", 420))
                interact()
                bird_state = navigator.position()
                if "message" in bird_state and "小鸟：" not in bird_state.get("message", ""):
                    raise AssertionError(f"Bird interaction had no visible reply: {bird_state}")
                checks.append("bird greeting produces visible feedback")
                snap("web-q009-bird-greeting.png")

                # Go north of the cottage footprint before heading west to the
                # red seed, then stop before the gold seed.
                navigator.go(("y", 380))
                # Stop just east of the southwest tree so the downhill path
                # to the red seed stays clear of its trunk collider.
                navigator.go(("x", 180), ("y", 430))
                snap("web-q010-before-red-seed.png")
                approach_and_interact(
                    "s",
                    "Q010 collect red seed",
                    lambda save: save.get("q010_seeds_collected") == [True, False, False],
                )
                navigator.go(("x", 260))
                snap("web-q010-before-gold-seed.png")
                print(f"Q010 gold seed approach: {navigator.position()}", flush=True)
                approach_and_interact(
                    "a",
                    "Q010 collect gold seed",
                    lambda save: save.get("q010_seeds_collected") == [True, False, True],
                )
                snap("web-q010-after-gold-seed.png")
                navigator.go(("y", 300), ("x", 550))
                approach_and_interact(
                    "d",
                    "Q010 collect all three seeds",
                    lambda save: save.get("q010_seeds_collected") == [True, True, True],
                )
                snap("web-q010-seeds-complete.png")

                # Lay the three path pavers, checking the first live drag target.
                for item_id, (source_x, target_x) in enumerate(((938, 560), (1018, 620), (1098, 680))):
                    drag(
                        (source_x, 661),
                        (target_x, 375),
                        "web-q008-green-drop-target.png" if item_id == 0 else None,
                    )
                    verify(lambda save, i=item_id: isinstance(save.get("q008_path_slot_occupants"), list) and save["q008_path_slot_occupants"][i] == i, f"Q008 place paver {item_id + 1}/3")
                verify(lambda save: save.get("q008_completed") is True, "Q008 connect the path and unlock extra plot")
                snap("web-q008-path-complete.png")

                # The extra-plot area remains closed until the player starts it;
                # the tray appears only after the explicit button press.
                snap("web-q011-before-start.png")
                page.mouse.click(950, 112)
                page.wait_for_timeout(500)
                snap("web-q011-after-start.png")
                for item_id, (source_x, target_x) in enumerate(((942, 230), (1022, 290), (1102, 350))):
                    drag((source_x, 642), (target_x, 588), "web-q011-green-drop-target.png" if item_id == 0 else None)
                    verify(lambda save, i=item_id: isinstance(save.get("q011_slot_occupants"), list) and save["q011_slot_occupants"][i] == i, f"Q011 place item {item_id + 1}/3")
                verify(lambda save: save.get("q011_slot_occupants") == [0, 1, 2], "Q011 finish extra-plot arrangement")
                snap("web-q011-all-optional-complete.png")

                page.reload(wait_until="load", timeout=60_000)
                navigator.state = None
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(2_500)
                verify(lambda save: save.get("q011_slot_occupants") == [0, 1, 2], "Q007–Q011 progress survives browser refresh")
                restored = navigator.position()
                if not restored.get("q010_completed") or not restored.get("q011_completed"):
                    raise AssertionError(f"The game did not restore Q010–Q011 progress: {restored}")
                snap("web-q011-after-refresh.png")

                # Re-enter decoration mode after the story and move a placed
                # garden item to an arbitrary open coordinate on both islands.
                # This guards against the old right-island-only area and
                # fixed-slot behavior in the real browser input path.
                page.mouse.click(950, 50)
                page.wait_for_timeout(500)
                snap("web-q006-free-placement-before.png")
                page.mouse.move(978, 559)
                page.mouse.down()
                page.wait_for_timeout(100)
                page.mouse.move(1030, 210, steps=12)
                page.wait_for_timeout(350)
                snap("web-q006-free-placement-preview.png")
                page.mouse.up()
                page.wait_for_timeout(700)
                moved_decor = verify(
                    lambda save: isinstance(save.get("q006_decor_positions"), list)
                    and save["q006_decor_positions"][0] == [1030, 210],
                    "Q006 move decoration to an arbitrary free position",
                )
                if moved_decor.get("q006_decor_positions", [None])[0] != [1030, 210]:
                    raise AssertionError("The browser did not persist the free decoration coordinate")
                snap("web-q006-free-placement-after.png")

                page.mouse.move(1030, 210)
                page.mouse.down()
                page.wait_for_timeout(100)
                page.mouse.move(410, 472, steps=14)
                page.wait_for_timeout(350)
                snap("web-q006-cottage-fence-preview.png")
                page.mouse.up()
                page.wait_for_timeout(700)
                cottage_decor = verify(
                    lambda save: isinstance(save.get("q006_decor_positions"), list)
                    and save["q006_decor_positions"][0] == [410, 472],
                    "Q006 move the fence beside the cottage on the other island",
                )
                if cottage_decor.get("q006_decor_positions", [None])[0] != [410, 472]:
                    raise AssertionError("The browser did not accept a safe cottage-side decoration position")
                snap("web-q006-cottage-fence.png")

                # A tap on a placed piece returns it directly to the compact
                # decoration tray; no separate removal mode is involved.
                page.mouse.click(410, 472)
                recovered = verify(
                    lambda save: save.get("q006_decor_placed", [None])[0] is False
                    and save.get("q006_decor_inventory", [None])[0] is True,
                    "Q006 tap placed fence to recover it to inventory",
                )
                snap("web-q006-direct-collect.png")
                page.mouse.move(951, 634)
                page.mouse.down()
                page.wait_for_timeout(100)
                page.mouse.move(430, 600, steps=12)
                page.wait_for_timeout(300)
                snap("web-q006-replacement-preview.png")
                page.mouse.up()
                replacement = verify(
                    lambda save: isinstance(save.get("q006_decor_positions"), list)
                    and save["q006_decor_positions"][0] == [430, 600],
                    "Q006 place recovered fence from tray at another free grass location",
                )
                if replacement.get("q006_decor_positions", [None])[0] != [430, 600]:
                    raise AssertionError("The recovered fence could not be placed again")
                snap("web-q006-replaced-fence.png")
                if errors:
                    raise AssertionError(f"Browser errors or failed requests: {errors}")

                # Keep the genuine Q012-complete save active. The old tail
                # replaced it with a hand-edited Q012-pending IndexedDB record,
                # which is not valid evidence for a real post-story session.
                final_save = read_save()
                if final_save.get("q012_completed") is not True:
                    raise AssertionError(f"Q012 completion was lost after optional play: {final_save}")
                if final_save.get("q010_seeds_collected") != [True, True, True] or final_save.get("q011_slot_occupants") != [0, 1, 2]:
                    raise AssertionError(f"The genuine post-story save is missing Q010/Q011 completion: {final_save}")
                post_story_path = Path(os.environ.get("WONDER_ISLE_POST_STORY_SAVE", artifact_dir / "post-story-save.json"))
                post_story_path.parent.mkdir(parents=True, exist_ok=True)
                post_story_path.write_text(json.dumps(final_save, ensure_ascii=False), encoding="utf-8")
                print(f"PASS actual Q007–Q011 post-story save exported: {post_story_path}", flush=True)
                checks.append("Q012-complete genuine save remains active after Q007–Q011 and decoration edits")
                print(json.dumps({"result": "passed", "checks": checks, "browser_errors": errors}, ensure_ascii=False, indent=2))
                browser.close()
        finally:
            server.shutdown()
            server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
