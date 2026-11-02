#!/usr/bin/env python3
"""Exercise bridge approaches using actual keyboard input and an isolated save."""
import functools
import os
import subprocess
import sys
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright
from browser_navigation import Navigator
from test_web_preview import inject_save_fixture

ROOT = Path(__file__).resolve().parent.parent
SAVE_KEY = '/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json'

class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass

def main():
    build = Path(sys.argv[1]).resolve()
    godot = os.environ.get('GODOT_BIN', '/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64')
    artifacts = Path(os.environ.get('WEB_TEST_ARTIFACTS', ROOT / 'tests/artifacts'))
    artifacts.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='wonder-bridge-fixture-') as tmp:
        subprocess.run([godot, '--headless', '--path', str(ROOT), '--script', 'tests/create_q001_visual_saves.gd', '--', tmp], check=True, stdout=subprocess.DEVNULL)
        server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(build)))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            with sync_playwright() as p:
                options = {'headless': True}
                if os.environ.get('CHROMIUM_PATH'):
                    options['executable_path'] = os.environ['CHROMIUM_PATH']
                browser = p.chromium.launch(**options)
                page_options = {'viewport': {'width': 1280, 'height': 720}}
                if os.environ.get('BRIDGE_VIDEO_DIR'):
                    page_options['record_video_dir'] = os.environ['BRIDGE_VIDEO_DIR']
                page = browser.new_page(**page_options)
                nav = Navigator(page, (build / 'index.html').read_text())
                errors = []
                page.on('pageerror', lambda error: errors.append(str(error)))
                page.goto(f'http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1', wait_until='load')
                assert not nav.position()['bridge']
                nav.axis('y', 360)
                nav.axis('x', 680)
                page.keyboard.down('d'); page.wait_for_timeout(1300); page.keyboard.up('d'); page.wait_for_timeout(200)
                before = nav.position()
                assert not before['bridge'] and before['x'] < 715, f'unrepaired river crossing: {before}'
                print('PASS unrepaired bridge blocks real input', before, flush=True)
                # Create the isolated filesystem entry before replacing its contents.
                page.mouse.click(1216, 44); page.wait_for_timeout(300)
                page.mouse.click(1216, 124); page.wait_for_timeout(500)
                page.mouse.click(775, 392); page.wait_for_timeout(4500)
                inject_save_fixture(page, SAVE_KEY, Path(tmp) / 'q001-bridge-3.json')
                nav.state = None
                assert nav.position()['bridge'], 'repaired fixture did not load'
                nav.axis('y', 360, tolerance=8)
                nav.axis('x', 680)
                # Different heights exercise both sides of both entrance seams.
                for crossing in range(20):
                    lane = (320, 339, 360, 380, 390)[crossing % 5]
                    nav.axis('y', lane, tolerance=8)
                    if crossing < 5 and lane >= 380:
                        page.screenshot(path=str(artifacts / f'bridge-lower-left-{lane}.png'))
                    if crossing == 0:
                        nav.axis('x', 820)
                        page.wait_for_timeout(400)
                        page.screenshot(path=str(artifacts / 'bridge-middle-keyboard.png'))
                    nav.axis('x', 930, tolerance=7)
                    right = nav.position()
                    assert right['x'] >= 923 and right['bridge'], f'left to right failed: {right}'
                    page.screenshot(path=str(artifacts / f'bridge-right-{crossing % 5}.png')) if crossing < 5 else None
                    nav.axis('y', lane, tolerance=8)
                    if crossing < 5 and lane >= 380:
                        page.screenshot(path=str(artifacts / f'bridge-lower-right-{lane}.png'))
                    nav.axis('x', 680, tolerance=8)
                    left = nav.position()
                    assert left['x'] <= 688 and left['bridge'], f'right to left failed: {left}'
                    print(f'PASS round trip {crossing + 1} lane {lane}: left={left}', flush=True)
                nav.axis('y', 390, tolerance=8)
                page.mouse.move(96, 622); page.mouse.down(); page.mouse.move(150, 622, steps=5)
                import time
                deadline = time.monotonic() + 20
                while nav.position()['x'] < 923 and time.monotonic() < deadline:
                    page.wait_for_timeout(50)
                page.mouse.up()
                assert nav.position()['x'] >= 923, f'lower entrance with joystick failed: {nav.position()}'
                print('PASS lower entrance using the round joystick', nav.position(), flush=True)
                page.reload(wait_until='load')
                nav.state = None
                assert nav.position()['bridge'], 'bridge was not restored after reload'
                nav.axis('y', 339, tolerance=8); nav.axis('x', 820, tolerance=7)
                page.keyboard.down('w'); page.wait_for_timeout(1000); page.keyboard.up('w'); page.wait_for_timeout(150)
                upper = nav.position()
                assert upper['y'] >= 300 and abs(upper['x'] - 820) < 20, f'crossed upper railing: {upper}'
                page.keyboard.down('s'); page.wait_for_timeout(1000); page.keyboard.up('s'); page.wait_for_timeout(150)
                lower = nav.position()
                assert lower['y'] <= 375 and abs(lower['x'] - 820) < 20, f'crossed lower railing: {lower}'
                page.keyboard.down('w'); page.keyboard.down('d'); page.wait_for_timeout(350)
                page.keyboard.up('w'); page.keyboard.up('d'); page.wait_for_timeout(150)
                diagonal = nav.position()
                assert diagonal['x'] > lower['x'] and diagonal['y'] >= 300, f'diagonal input failed: {diagonal}'
                print('PASS bridge railings and diagonal input', upper, lower, diagonal, flush=True)
                nav.axis('y', 339, tolerance=8); nav.axis('x', 930, tolerance=7)
                print('PASS bridge traversal after save reload', nav.position(), flush=True)
                if errors:
                    raise AssertionError(f'browser errors: {errors}')
                page.close()
                browser.close()
        finally:
            server.shutdown()
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
