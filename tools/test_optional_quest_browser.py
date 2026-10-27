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
        fixture_path = Path(temp_dir) / "post-story-save.json"
        subprocess.run(
            [godot_bin, "--headless", "--path", str(project_root), "--script", "tests/create_post_story_web_save.gd", "--", str(fixture_path)],
            check=True,
            capture_output=True,
            text=True,
        )
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
                page = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
                page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
                page.on("pageerror", lambda error: errors.append(str(error)))
                page.on(
                    "requestfailed",
                    lambda request: errors.append(f"{request.url}: {request.failure}"),
                )
                page.goto(f"http://127.0.0.1:{server.server_port}/index.html", wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(2_500)
                # Create the WebFS save record in the running engine before replacing it.
                page.mouse.click(1_150, 50)
                page.wait_for_timeout(700)

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
                    # Godot WebFS commits save writes asynchronously to IndexedDB.
                    latest: dict[str, object] = {}
                    for _ in range(10):
                        latest = read_save()
                        if latest and condition(latest):
                            break
                        page.wait_for_timeout(500)
                    else:
                        raise AssertionError(f"{label}; latest save: {json.dumps(latest, ensure_ascii=False)}")
                    checks.append(label)
                    print(f"PASS {label}", flush=True)
                    return latest

                def move(key: str, milliseconds: int) -> None:
                    page.mouse.click(800, 600)
                    page.keyboard.down(key)
                    page.wait_for_timeout(milliseconds)
                    page.keyboard.up(key)
                    page.wait_for_timeout(180)

                def interact() -> None:
                    page.mouse.click(1_240, 681)
                    page.wait_for_timeout(650)

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

                verify(lambda save: save.get("q012_completed") is True and save.get("q007_completed") is False, "load post-story fixture before optional quests")
                snap("web-q007-optional-unlocked.png")

                # Cross the repaired bridge, reach the shell, and collect it.
                move("w", 480)
                move("d", 1_700)
                move("d", 900)
                move("s", 211)
                interact()
                verify(lambda save: save.get("q007_shell_collected") is True and save.get("q007_reward_unlocked") is True, "Q007 collect shell and unlock reward")
                snap("web-q007-shell-collected.png")

                # Return across the bridge and gather all birdhouse materials.
                move("w", 211)
                move("a", 946)
                move("s", 788)
                interact()
                verify(lambda save: save.get("q009_materials_collected") == [False, False, True], "Q009 collect rope at west shore")
                move("a", 1_692)
                interact()
                verify(lambda save: save.get("q009_materials_collected") == [True, False, True], "Q009 collect branch by west shore")
                move("w", 1_077)
                move("d", 230)
                interact()
                verify(lambda save: save.get("q009_materials_collected") == [True, True, True] and save.get("q009_completed") is True, "Q009 collect all birdhouse materials")
                snap("web-q009-birdhouse-complete.png")

                # The greeting is optional, but it should work once materials are gathered.
                move("d", 1_346)
                move("s", 635)
                interact()
                snap("web-q009-bird-greeting.png")

                # Collect the three visible seeds across the west island.
                move("a", 1_808)
                interact()
                verify(lambda save: save.get("q010_seeds_collected") == [True, False, False], "Q010 collect red seed")
                move("d", 308)
                interact()
                verify(lambda save: save.get("q010_seeds_collected") == [True, False, True], "Q010 collect gold seed")
                move("w", 500)
                move("d", 1_115)
                interact()
                verify(lambda save: save.get("q010_seeds_collected") == [True, True, True], "Q010 collect all three seeds")
                snap("web-q010-seeds-complete.png")

                # Lay the three path pavers, checking the first live drag target.
                for item_id, (source_x, target_x) in enumerate(((971, 560), (1067, 620), (1163, 680))):
                    drag(
                        (source_x, 661),
                        (target_x, 375),
                        "web-q008-green-drop-target.png" if item_id == 0 else None,
                    )
                    verify(lambda save, i=item_id: isinstance(save.get("q008_path_slot_occupants"), list) and save["q008_path_slot_occupants"][i] == i, f"Q008 place paver {item_id + 1}/3")
                verify(lambda save: save.get("q008_completed") is True, "Q008 connect the path and unlock extra plot")
                snap("web-q008-path-complete.png")

                # Enter the extra-plot mode and place each item in an empty slot.
                page.mouse.click(950, 112)
                page.wait_for_timeout(500)
                for item_id, (source_x, target_x) in enumerate(((971, 230), (1067, 290), (1163, 350))):
                    drag((source_x, 642), (target_x, 588), "web-q011-green-drop-target.png" if item_id == 0 else None)
                    verify(lambda save, i=item_id: isinstance(save.get("q011_slot_occupants"), list) and save["q011_slot_occupants"][i] == i, f"Q011 place item {item_id + 1}/3")
                verify(lambda save: save.get("q011_slot_occupants") == [0, 1, 2], "Q011 finish extra-plot arrangement")
                snap("web-q011-all-optional-complete.png")

                page.reload(wait_until="load", timeout=60_000)
                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(2_500)
                verify(lambda save: save.get("q011_slot_occupants") == [0, 1, 2], "Q007–Q011 progress survives browser refresh")
                snap("web-q011-after-refresh.png")
                if errors:
                    raise AssertionError(f"Browser errors or failed requests: {errors}")
                print(json.dumps({"result": "passed", "checks": checks, "browser_errors": errors}, ensure_ascii=False, indent=2))
                browser.close()
        finally:
            server.shutdown()
            server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
