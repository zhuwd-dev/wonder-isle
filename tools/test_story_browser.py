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

            def capture_sizes(label):
                for width, height in ((1630, 870), (844, 390)):
                    page.set_viewport_size({'width': width, 'height': height})
                    page.wait_for_timeout(300)
                    page.screenshot(path=str(artifacts / f'{label}-{width}x{height}.png'))
                page.set_viewport_size({'width': 1280, 'height': 720})
                page.wait_for_timeout(300)

            def drag(source, target):
                page.mouse.move(*source)
                page.mouse.down()
                page.mouse.move(*target, steps=12)
                page.mouse.up()

            for index, route in enumerate(((('y', 250), ('x', 350)), (('x', 475), ('y', 500)), (('y', 460), ('x', 625), ('y', 525)))):
                nav.go(*route)
                interact()
                verify(lambda s, i=index: s['collected'][i], f"Q001 board {index + 1}")
            page.screenshot(path=str(artifacts / "p0-bridge-0.png"))
            page.mouse.move(1102, 647)
            page.mouse.down()
            page.mouse.move(700, 480, steps=12)
            page.screenshot(path=str(artifacts / "p0-board-drag-outside.png"))
            page.mouse.up()
            verify(lambda s: not s['placed'][2], "Q001 invalid release preserves board")
            page.screenshot(path=str(artifacts / "p0-board-invalid-release.png"))
            # Deliver in a different inventory order to freely chosen points
            # across the same bridge opening, rather than matching slot IDs.
            for index, source, target in ((2, (1102, 647), (797, 369)), (0, (942, 647), (863, 361)), (1, (1022, 647), (831, 364))):
                page.mouse.move(*source)
                page.mouse.down()
                page.mouse.move(*target, steps=12)
                if index == 2:
                    page.screenshot(path=str(artifacts / "p0-board-drag-valid.png"))
                page.mouse.up()
                verify(lambda s, i=index: s['placed'][i], f"Q001 repair {index + 1}/3")
                page.screenshot(path=str(artifacts / f"p0-bridge-{sum(bool(x) for x in saved()['placed'])}.png"))
            page.screenshot(path=str(artifacts / "web-story-bridge-complete.png"))
            page.screenshot(path=str(artifacts / "b-seed-and-garden-before.png"))
            nav.go(('y', 339), ('x', 960), ('y', 385), ('x', 995))
            interact()
            verify(lambda s: s['seed_collected'], "Q002 collect seed after crossing")
            page.wait_for_timeout(200)
            assert not nav.position()['planting_hint'], 'distant garden must not glow after collection'
            nav.go(('y', 430), ('x', 995))
            page.wait_for_timeout(500)
            assert 0.2 < nav.position()['garden_focus'] < 0.7, nav.position()
            page.screenshot(path=str(artifacts / 'experience-garden-approach.png'))
            nav.go(('y', 465), ('x', 1045))
            page.wait_for_timeout(500)
            assert nav.position()['planting_hint'], f"nearby planting hint missing: {nav.position()}"
            assert nav.position()['garden_focus'] > 0.8, nav.position()
            page.screenshot(path=str(artifacts / "b-garden-ready.png"))
            capture_sizes('experience-garden-ready')
            interact()
            verify(lambda s: s['seed_planted'], "Q002 plant seed")
            page.wait_for_timeout(500)
            assert not nav.position()['planting_hint'], 'planted garden must stop offering the old hint'
            assert nav.position()['garden_focus'] < 0.02 and not nav.position()['house_delivery'], nav.position()
            page.screenshot(path=str(artifacts / "b-garden-planted.png"))
            nav.go(('x', 960), ('y', 339), ('x', 650), ('y', 260), ('x', 440), ('y', 220))
            page.mouse.click(430, 195)
            page.wait_for_timeout(300)
            assert nav.position()['guide_stage'] == 'q004_collect', nav.position()
            page.screenshot(path=str(artifacts / 'experience-rabbit-find-wood.png'))
            page.mouse.click(430, 195)
            nav.go(('y', 339), ('x', 650), ('y', 500), ('x', 620))
            interact()
            verify(lambda s: s['wood_collected'][2], "Q004 collect wood 3")
            nav.go(('y', 400), ('x', 360))
            interact()
            verify(lambda s: s['wood_collected'][1], "Q004 collect wood 2")
            nav.go(('y', 330), ('x', 160))
            interact()
            verify(lambda s: s['wood_collected'][0], "Q004 collect wood 1")
            nav.go(('y', 260), ('x', 440), ('y', 220))
            page.mouse.click(430, 195)
            page.wait_for_timeout(500)
            assert nav.position()['guide_stage'] == 'q004_deliver' and nav.position()['house_delivery'], nav.position()
            page.screenshot(path=str(artifacts / 'experience-rabbit-deliver-wood.png'))
            capture_sizes('experience-rabbit-deliver')
            page.mouse.click(430, 195)
            nav.go(('x', 520), ('y', 430))
            page.wait_for_timeout(500)
            assert nav.position()['house_focus'] > 0.8, nav.position()
            page.screenshot(path=str(artifacts / 'experience-house-ready.png'))
            capture_sizes('experience-house-ready')
            for index in range(3):
                interact()
                verify(lambda s, i=index: s['wood_delivered'][i], f"Q004 deliver {index + 1}/3")
                page.wait_for_timeout(400)
                page.screenshot(path=str(artifacts / f'experience-house-delivery-{index + 1}.png'))
            assert not nav.position()['house_delivery'] and nav.position()['house_focus'] < 0.02, nav.position()
            pond_progress = lambda: sum(bool(placed) for placed in saved()["pond_stones_placed"])
            page.screenshot(path=str(artifacts / "web-q003-pond-0-of-3.png"))
            # A release on the shore is rejected without consuming the stone.
            page.mouse.move(945, 470)
            page.mouse.down()
            page.mouse.move(900, 450, steps=12)
            page.mouse.up()
            page.wait_for_timeout(250)
            if pond_progress() != 0:
                raise AssertionError("Q003 must reject a stone released outside the water")
            page.screenshot(path=str(artifacts / "web-q003-invalid-release.png"))

            # Use a non-slot order and land on different points inside the
            # water. The release coordinate is intentionally independent of
            # the stone ID and the final scenic installation position.
            pond_drags = (
                (2, (1170, 520), (1027, 332)),
                (0, (945, 470), (1072, 348)),
                (1, (1170, 340), (970, 333)),
            )
            for progress, (stone_id, source, target) in enumerate(pond_drags, start=1):
                page.mouse.move(*source)
                page.mouse.down()
                page.mouse.move(*target, steps=12)
                if progress == 1:
                    page.screenshot(path=str(artifacts / "web-q003-drop-preview.png"))
                page.mouse.up()
                verify(lambda s, i=stone_id: s["pond_stones_placed"][i], f"Q003 arbitrary stone {progress}/3")
                page.screenshot(path=str(artifacts / f"web-q003-pond-{progress}-of-3.png"))
            nav.go(('y', 339), ('x', 960), ('y', 500), ('x', 975))
            page.screenshot(path=str(artifacts / "web-story-watering-point.png"))
            interact()
            verify(lambda s: s['q005_watered'], "Q005 water garden")
            for index, x in enumerate((1028, 1080, 1132)):
                # Use the open southern approach, then the real action-ready
                # feedback rather than a waypoint beside the eastern rocks.
                nav.go(('y', 520), ('x', x))
                nav.move_until_ready('w', '采花')
                interact()
                verify(lambda s, i=index: s['q005_plants_collected'][i], f"Q005 collect flower {index + 1}/3")
            nav.go(('x', 1090), ('y', 420))
            nav.pursue_turtle()
            interact()
            verify(lambda s: s['q005_completed'], "Q005 deliver bouquet")
            page.screenshot(path=str(artifacts / "web-story-q005-complete.png"))
            page.reload(wait_until="load")
            nav.state = None
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
