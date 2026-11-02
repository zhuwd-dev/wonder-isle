#!/usr/bin/env python3
"""Check camera zoom using real wheel and two-touch browser events."""
import functools
import os
import sys
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from playwright.sync_api import sync_playwright
from browser_navigation import Navigator

class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass

def main():
    build = Path(sys.argv[1]).resolve()
    artifacts = Path(os.environ.get('WEB_TEST_ARTIFACTS', build.parent.parent / 'tests/artifacts'))
    artifacts.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(build)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as p:
            options = {'headless': True}
            if os.environ.get('CHROMIUM_PATH'):
                options['executable_path'] = os.environ['CHROMIUM_PATH']
            browser = p.chromium.launch(**options)
            context = browser.new_context(viewport={'width': 1280, 'height': 720}, has_touch=True)
            page = context.new_page()
            nav = Navigator(page, (build / 'index.html').read_text())
            errors = []
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.goto(f'http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1', wait_until='load')
            assert abs(nav.position()['camera_zoom'] - 1.0) < 0.01
            page.screenshot(path=str(artifacts / 'c-zoom-full.png'))
            page.mouse.move(600, 400)
            page.mouse.wheel(0, -120)
            page.wait_for_timeout(400)
            assert nav.position()['camera_zoom'] > 1.01, f'wheel did not zoom: {nav.position()}'
            page.screenshot(path=str(artifacts / 'c-zoom-wheel.png'))
            page.mouse.click(797, 52)
            page.wait_for_timeout(300)
            assert abs(nav.position()['camera_zoom'] - 1.0) < 0.01, f'full view did not reset: {nav.position()}'
            cdp = context.new_cdp_session(page)
            a = {'x': 400, 'y': 380, 'id': 1}
            b = {'x': 600, 'y': 380, 'id': 2}
            cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [a]})
            cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [a, b]})
            cdp.send('Input.dispatchTouchEvent', {'type': 'touchMove', 'touchPoints': [a, {'x': 680, 'y': 380, 'id': 2}]})
            page.wait_for_timeout(500)
            state = nav.position()
            assert 1.03 < state['camera_zoom'] <= 1.351, f'two-finger zoom failed: {state}'
            page.screenshot(path=str(artifacts / 'c-zoom-pinch.png'))
            cdp.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
            page.wait_for_timeout(200)
            if errors:
                raise AssertionError(f'browser errors: {errors}')
            print('PASS wheel, reset and two-finger zoom', state, flush=True)
            context.close()
            browser.close()
    finally:
        server.shutdown()
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
