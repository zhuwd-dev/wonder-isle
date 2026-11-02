#!/usr/bin/env python3
"""Verify animation state using real movement without pretending fallback art is animated."""
import json
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
            expected = json.loads((build.parent.parent / 'assets/art/production-art.json').read_text())['mouse']['enabled']
            assert nav.position()['official_mouse_frames'] == expected, 'runtime art state differs from the enabled resource contract'
            page.mouse.click(800, 600)
            for key, facing in [('w', 'up'), ('s', 'down'), ('a', 'left'), ('d', 'right')]:
                page.keyboard.down(key)
                page.wait_for_timeout(350)
                state = nav.position()
                assert state['animation'] == 'walk_' + facing, state
                page.screenshot(path=str(artifacts / ('art-controller-walk-' + facing + '.png')))
                page.keyboard.up(key)
                page.wait_for_timeout(250)
                assert nav.position()['animation'] == 'idle_' + facing, nav.position()
            if errors:
                raise AssertionError(errors)
            print('PASS four-direction controller and safe fallback through real keyboard input', flush=True)
            context.close()
            browser.close()
    finally:
        server.shutdown()
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
