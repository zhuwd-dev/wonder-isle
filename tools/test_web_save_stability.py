#!/usr/bin/env python3
"""Exercise five isolated Q001 save/reload cycles with real game input."""
from __future__ import annotations

import functools
import json
import os
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys

from playwright.sync_api import sync_playwright
from browser_navigation import Navigator

SAVE_KEY = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"
READ_IDB = """async key => await new Promise((resolve, reject) => {
  const opening = indexedDB.open('/userfs');
  opening.onerror = () => reject(opening.error);
  opening.onsuccess = () => {
    const tx = opening.result.transaction('FILE_DATA', 'readonly');
    const request = tx.objectStore('FILE_DATA').get(key);
    let value = null;
    request.onerror = () => reject(request.error);
    request.onsuccess = () => {
      if (request.result) value = JSON.parse(new TextDecoder().decode(new Uint8Array(request.result.contents)));
    };
    tx.onerror = () => reject(tx.error);
    tx.oncomplete = () => resolve(value);
  };
})"""


def matches_q001(save: dict | None, *, board_count: int | None = None, repaired: bool = False) -> bool:
    if not save:
        return False
    collected = save.get("collected", [])
    placed = save.get("placed", [])
    if board_count is not None and sum(bool(value) for value in collected) < board_count:
        return False
    if repaired and not (placed == [True, True, True] and save.get("bridge_repaired") is True and save.get("area_unlocked") is True):
        return False
    return True


def main() -> int:
    build = Path(sys.argv[1]).resolve()
    artifacts = Path(os.environ.get("WEB_TEST_ARTIFACTS", "/tmp/wonder-isle-save-stability"))
    artifacts.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(SimpleHTTPRequestHandler, directory=str(build)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    failures: list[str] = []
    try:
        with sync_playwright() as playwright:
            options = {"headless": True}
            if os.environ.get("CHROMIUM_PATH"):
                options["executable_path"] = os.environ["CHROMIUM_PATH"]
            browser = playwright.chromium.launch(**options)
            try:
                for round_index in range(5):
                    context = browser.new_context(viewport={"width": 1280, "height": 720}, service_workers="block")
                    try:
                        page = context.new_page()
                        nav = Navigator(page, (build / "index.html").read_text(encoding="utf-8"))
                        page.on("pageerror", lambda error: print(f"BROWSER PAGE ERROR: {error}", flush=True))
                        page.on("console", lambda message: print(f"BROWSER CONSOLE ERROR: {message.text}", flush=True) if message.type == "error" else None)
                        page.goto(f"http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1", wait_until="load")

                        def read_local() -> dict | None:
                            raw = page.evaluate("() => { try { return localStorage.getItem('wonder-isle-save-v1'); } catch (_) { return null; } }")
                            return json.loads(raw) if raw else None

                        def read_idb() -> dict | None:
                            return page.evaluate(READ_IDB, SAVE_KEY)

                        def wait_memory_and_local(predicate, label: str) -> dict:
                            deadline = time.monotonic() + 15
                            while time.monotonic() < deadline:
                                memory = nav.position().get("test_save_data")
                                local = read_local()
                                if memory and local and predicate(memory) and predicate(local):
                                    print(f"PASS round {round_index + 1}: {label}; memory and sync mirror match", flush=True)
                                    return memory
                                page.wait_for_timeout(40)
                            raise AssertionError(
                                f"round {round_index + 1}: {label}; memory={nav.position().get('test_save_data')} local={read_local()}"
                            )

                        def wait_indexeddb(predicate, label: str) -> dict:
                            # The condition, not elapsed time, defines success. The deadline is a diagnostic watchdog.
                            deadline = time.monotonic() + 90
                            latest = None
                            while time.monotonic() < deadline:
                                latest = read_idb()
                                if latest and predicate(latest):
                                    print(f"PASS round {round_index + 1}: {label}; IndexedDB transaction completed", flush=True)
                                    return latest
                                page.wait_for_timeout(250)
                            raise AssertionError(f"round {round_index + 1}: {label}; latest IndexedDB snapshot={latest}")

                        def reload_and_verify(predicate, label: str) -> dict:
                            previous = nav.position().get("test_instance_id")
                            old_event = nav.state_received_at
                            started = time.monotonic()
                            page.reload(wait_until="load")
                            fresh = nav.wait_for_fresh_state(after=old_event, timeout=45)
                            loaded = fresh.get("test_save_data")
                            local = read_local()
                            if fresh.get("test_instance_id") == previous or not loaded or not predicate(loaded) or not local or not predicate(local):
                                raise AssertionError(f"round {round_index + 1}: {label}; old_instance={previous} fresh={fresh} local={local}")
                            print(f"PASS round {round_index + 1}: {label}; new_instance={fresh['test_instance_id']} reload_s={time.monotonic()-started:.2f}", flush=True)
                            return loaded

                        # The first pickup is followed by a real immediate reload. This intentionally
                        # occurs before waiting for IndexedDB; localStorage mirrors the synchronous save.
                        nav.go(("y", 250), ("x", 350))
                        page.mouse.click(1214, 662)
                        first = wait_memory_and_local(lambda data: data.get("collected", [False])[0], "collect first plank")
                        reload_and_verify(lambda data: data.get("collected", [False])[0], "immediate reload restores first plank")

                        nav.go(("x", 475), ("y", 500))
                        page.mouse.click(1214, 662)
                        wait_memory_and_local(lambda data: data.get("collected", [False, False])[1], "collect second plank")
                        nav.go(("y", 460), ("x", 625), ("y", 525))
                        page.mouse.click(1214, 662)
                        wait_memory_and_local(lambda data: data.get("collected", [False, False, False])[2], "collect third plank")

                        for item_id, source, target in (
                            (2, (1102, 647), (797, 369)),
                            (0, (942, 647), (863, 361)),
                            (1, (1022, 647), (831, 364)),
                        ):
                            page.mouse.move(*source)
                            page.mouse.down()
                            page.mouse.move(*target, steps=12)
                            page.mouse.up()
                            predicate = (lambda data, i=item_id: data.get("placed", [False] * 3)[i])
                            wait_memory_and_local(predicate, f"deliver plank {item_id + 1}")

                        complete = lambda data: matches_q001(data, board_count=3, repaired=True)
                        wait_memory_and_local(complete, "bridge repair is complete")
                        if round_index % 2 == 1:
                            wait_indexeddb(complete, "delayed refresh precondition")
                        reload_and_verify(complete, "bridge state survives reload")
                        wait_indexeddb(complete, "restored bridge state converges to IndexedDB")
                    except Exception as error:
                        failures.append(f"round {round_index + 1}: {error}")
                        print(f"FAIL round {round_index + 1}: {error}", flush=True)
                        if isinstance(error, AssertionError):
                            break
                    finally:
                        context.close()
                browser.close()
            finally:
                if browser.is_connected():
                    browser.close()
    finally:
        server.shutdown()
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print("PASS 5/5 independent Q001 collect/deliver/reload cycles", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
