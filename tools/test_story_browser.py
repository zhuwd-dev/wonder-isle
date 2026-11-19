#!/usr/bin/env python3
"""Play a fresh-save life-island flow using real browser input."""
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
from web_save_namespace import PREVIEW, SAVE_KEY


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
            context = browser.new_context(viewport={"width": 1280, "height": 720}, service_workers="block")
            page = context.new_page()
            nav = Navigator(page, (build / "index.html").read_text(encoding="utf-8"))
            errors = []
            page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
            page.on("pageerror", lambda error: errors.append(str(error)))
            page.goto(f"http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1", wait_until="load")
            try:
                # The Godot canvas exists before WASM/PCK initialization has
                # finished; its status overlay is removed only after startup.
                page.locator("#status").wait_for(state="detached", timeout=60_000)
                initial = nav.position()
            except Exception as error:
                diagnostics = page.evaluate("""() => ({
                    ready: document.readyState,
                    status: document.querySelector('#status-notice')?.textContent,
                    webgl2: !!document.createElement('canvas').getContext('webgl2'),
                    resources: performance.getEntriesByType('resource').slice(-8).map(r => r.name)
                })""")
                raise AssertionError(f"Game startup did not provide telemetry: {diagnostics}; browser errors: {errors}") from error
            sha = os.environ.get("WONDER_ISLE_COMMIT", os.environ.get("GITHUB_SHA", ""))
            expected_revision = (sha.lower() if PREVIEW else sha[:7].lower()) if re.fullmatch(r"[0-9a-fA-F]{40}", sha) else "local"
            if initial.get("build_revision") != expected_revision:
                raise AssertionError(f"Engine build version differs from export: {initial}")

            def saved():
                return page.evaluate("""async key => new Promise((resolve, reject) => {
                    const open = indexedDB.open('/userfs'); open.onerror = () => reject(open.error);
                    open.onsuccess = () => { const tx = open.result.transaction('FILE_DATA', 'readonly');
                        const req = tx.objectStore('FILE_DATA').get(key); let result = null;
                        req.onerror = () => reject(req.error);
                        req.onsuccess = () => { result = req.result ? JSON.parse(new TextDecoder().decode(new Uint8Array(req.result.contents))) : null; };
                        tx.onerror = () => reject(tx.error); tx.oncomplete = () => resolve(result);
                    };
                })""", SAVE_KEY)

            def verify(predicate, label):
                deadline = time.monotonic() + 60
                state = None
                while time.monotonic() < deadline:
                    state = saved()
                    memory = nav.position().get('test_save_data')
                    if state and memory and predicate(state) and predicate(memory):
                        print(f"PASS {label} persisted and in-memory", flush=True)
                        return state
                    page.wait_for_timeout(150)
                raise AssertionError(f"{label}: memory={nav.position().get('test_save_data')} persisted={state}")

            def interact():
                # Exercise the primary interaction control instead of a
                # one-frame key pulse between headless physics ticks.
                page.mouse.click(1214, 662)

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
            previous_instance = nav.position().get("test_instance_id")
            previous_event = nav.state_received_at
            page.reload(wait_until="load")
            try:
                loaded = nav.wait_for_fresh_state(after=previous_event)
            except AssertionError:
                print(f"Browser errors during save refresh: {errors}", flush=True)
                print(f"Browser after failed save refresh: {page.evaluate('''() => ({readyState:document.readyState, href:location.href, canvas:!!document.querySelector('canvas')})''')}", flush=True)
                raise
            if loaded.get("test_instance_id") == previous_instance:
                raise AssertionError("Refresh was not confirmed by a new Godot instance")
            if not loaded.get('q005_completed'):
                raise AssertionError(f"The engine did not restore Q005 completion: {loaded}")
            verify(lambda s: s['q005_completed'] and s['pond_opened'] and s['seed_planted'], "Q001–Q005 save survives refresh")

            # Q006 is completed by ordinary build-mode drags after Q005. The
            # saved state comes only from the preceding real-input tasks.
            if nav.position().get("guide_stage") != "q006_decor":
                raise AssertionError(f"Expected Q006 decoration guidance after Q005: {nav.position()}")
            page.mouse.click(950, 50)
            deadline = time.monotonic() + 10
            while not nav.position().get("build_mode") and time.monotonic() < deadline:
                page.wait_for_timeout(50)
            if not nav.position().get("build_mode"):
                raise AssertionError(f"Q006 build mode did not open from its UI button: {nav.position()}")
            for decor_id, source, target in (
                (0, (951, 634), (978, 559)),
                (1, (1015, 634), (1072, 559)),
                (2, (1079, 634), (1130, 559)),
            ):
                drag(source, target)
                verify(
                    lambda save, i=decor_id: save["q006_decor_placed"][i]
                    and save["q006_decor_positions"][i] == list(target),
                    f"Q006 naturally place decoration {decor_id + 1}/3",
                )
            verify(lambda save: save["q006_completed"] and save["q006_windmill_unlocked"], "Q006 complete free-garden decoration")
            page.screenshot(path=str(artifacts / "web-story-q006-complete.png"))

            # Reach the rabbit and use the highlighted in-game interaction to
            # complete Q012; no task field or completion function is injected.
            nav.go(("y", 340), ("x", 580), ("y", 226))
            state = nav.position()
            if not state.get("ready"):
                nav.move_until_ready("w", "庆祝")
            state = nav.position()
            if not state.get("ready"):
                raise AssertionError(f"Q012 rabbit interaction was not ready: {state}")
            page.screenshot(path=str(artifacts / "web-story-before-q012.png"))
            interact()
            verify(lambda save: save["q012_completed"], "Q012 complete celebration via live interaction")
            page.screenshot(path=str(artifacts / "web-story-q012-complete.png"))
            genuine_q012_save = saved()
            if not genuine_q012_save or not genuine_q012_save.get("q012_completed"):
                raise AssertionError("Could not capture the actual Q012 save produced by real browser input")
            save_path = Path(os.environ.get("WONDER_ISLE_Q012_SAVE", artifacts / "q012-save-from-game.json"))
            save_path.parent.mkdir(parents=True, exist_ok=True)
            save_path.write_text(json.dumps(genuine_q012_save, ensure_ascii=False), encoding="utf-8")
            print(f"PASS actual Q012 save exported from live play: {save_path}", flush=True)
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
