#!/usr/bin/env python3
"""Play Q001–Q005 in a fresh browser using real keyboard and pointer input."""
import functools
import json
import os
import re
import sys
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright
from browser_navigation import Navigator

SAVE_KEY = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass


def main():
    build = Path(sys.argv[1]).resolve()
    artifacts = Path(os.environ.get("WEB_TEST_ARTIFACTS", "/tmp/wonder-story-artifacts"))
    artifacts.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(QuietHandler, directory=str(build)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as playwright:
            options = {"headless": True}
            if os.environ.get("CHROMIUM_PATH"):
                options["executable_path"] = os.environ["CHROMIUM_PATH"]
            browser = playwright.chromium.launch(**options)
            page = browser.new_page(viewport={"width": 1280, "height": 720})
            nav = Navigator(page, (build / "index.html").read_text(encoding="utf-8"))
            errors = []
            page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
            page.on("pageerror", lambda error: errors.append(str(error)))
            page.goto(f"http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1", wait_until="load")
            initial = nav.position()
            sha = os.environ.get("GITHUB_SHA", "")
            expected_revision = sha[:7].lower() if re.fullmatch(r"[0-9a-fA-F]{40}", sha) else "local"
            if initial.get("build_revision") != expected_revision:
                raise AssertionError(f"Engine build version differs from export: {initial}")

            def saved():
                return page.evaluate("""async key => new Promise((resolve, reject) => {
                    const open = indexedDB.open('/userfs'); open.onerror = () => reject(open.error);
                    open.onsuccess = () => { const req = open.result.transaction('FILE_DATA').objectStore('FILE_DATA').get(key);
                        req.onerror = () => reject(req.error);
                        req.onsuccess = () => resolve(req.result ? JSON.parse(new TextDecoder().decode(new Uint8Array(req.result.contents))) : null);
                    };
                })""", SAVE_KEY)

            def verify(predicate, label):
                deadline = time.monotonic() + 12
                state = None
                while time.monotonic() < deadline:
                    state = saved()
                    if state and predicate(state):
                        print(f"PASS {label} at {nav.position()}", flush=True)
                        return state
                    page.wait_for_timeout(150)
                raise AssertionError(f"{label}: position={nav.position()} save={state}")

            def interact():
                page.keyboard.press("e")

            def drag(source, target):
                page.mouse.move(*source)
                page.mouse.down()
                page.mouse.move(*target, steps=12)
                page.mouse.up()

            for index, route in enumerate(((('y', 250), ('x', 350)), (('x', 475), ('y', 500)), (('y', 460), ('x', 625), ('y', 525)))):
                nav.go(*route)
                interact()
                verify(lambda s, i=index: s['collected'][i], f"Q001 board {index + 1}")
            for index, (source, target) in enumerate((((942, 647), (797, 369)), ((1022, 647), (831, 364)), ((1102, 647), (863, 361)))):
                drag(source, target)
                verify(lambda s, i=index: s['placed'][i], f"Q001 repair {index + 1}/3")
            page.screenshot(path=str(artifacts / "web-story-bridge-complete.png"))
            nav.go(('y', 339), ('x', 930), ('y', 400), ('x', 965))
            interact()
            verify(lambda s: s['seed_collected'], "Q002 collect seed after crossing")
            nav.go(('y', 450), ('x', 1030))
            interact()
            verify(lambda s: s['seed_planted'], "Q002 plant seed")
            nav.go(('x', 930), ('y', 339), ('x', 650), ('y', 500), ('x', 620))
            interact()
            verify(lambda s: s['wood_collected'][2], "Q004 collect wood 3")
            nav.go(('y', 400), ('x', 360))
            interact()
            verify(lambda s: s['wood_collected'][1], "Q004 collect wood 2")
            nav.go(('y', 330), ('x', 160))
            interact()
            verify(lambda s: s['wood_collected'][0], "Q004 collect wood 1")
            nav.go(('x', 520), ('y', 430))
            for index in range(3):
                interact()
                verify(lambda s, i=index: s['wood_delivered'][i], f"Q004 deliver {index + 1}/3")
            for index, (source, target) in enumerate((((945, 470), (990, 340)), ((1170, 340), (1040, 353)), ((1170, 520), (1082, 340)))):
                drag(source, target)
                verify(lambda s, i=index: s['pond_stones_placed'][i], f"Q003 pond stone {index + 1}/3")
            nav.go(('y', 339), ('x', 930), ('y', 500), ('x', 975))
            page.screenshot(path=str(artifacts / "web-story-watering-point.png"))
            interact()
            verify(lambda s: s['q005_watered'], "Q005 water garden")
            for index, x in enumerate((1028, 1080, 1132)):
                nav.go(('x', x), ('y', 480))
                interact()
                verify(lambda s, i=index: s['q005_plants_collected'][i], f"Q005 collect flower {index + 1}/3")
            nav.go(('x', 1130), ('y', 320))
            interact()
            verify(lambda s: s['q005_completed'], "Q005 deliver bouquet")
            page.screenshot(path=str(artifacts / "web-story-q005-complete.png"))
            nav.state = None
            page.reload(wait_until="load")
            loaded = nav.position()
            if not loaded.get('q005_completed'):
                raise AssertionError(f"The engine did not restore Q005 completion: {loaded}")
            verify(lambda s: s['q005_completed'] and s['pond_opened'] and s['seed_planted'], "Q001–Q005 save survives refresh")
            page.wait_for_timeout(300)
            if errors:
                raise AssertionError(f"Browser errors: {errors}")
            browser.close()
    finally:
        server.shutdown()
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
