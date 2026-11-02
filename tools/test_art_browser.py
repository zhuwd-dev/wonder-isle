#!/usr/bin/env python3
"""Verify animation state using real movement without pretending fallback art is animated."""
import json
import functools
import os
import sys
import threading
import time
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
            context_options = {'viewport': {'width': 1280, 'height': 720}, 'has_touch': True}
            if os.environ.get('ART_VIDEO_DIR'):
                context_options['record_video_dir'] = os.environ['ART_VIDEO_DIR']
            context = browser.new_context(**context_options)
            page = context.new_page()
            nav = Navigator(page, (build / 'index.html').read_text())
            errors = []
            page.on('pageerror', lambda error: errors.append(str(error)))
            page.goto(f'http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1', wait_until='load')
            expected = json.loads((build.parent.parent / 'assets/art/production-art.json').read_text())['mouse']['enabled']
            assert nav.position()['official_mouse_frames'] == expected, 'runtime art state differs from the enabled resource contract'
            page.mouse.click(800, 600)

            def wait_animation(expected):
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    state = nav.position()
                    if state['animation'] == expected:
                        return state
                    page.wait_for_timeout(30)
                raise AssertionError(f'Animation {expected} did not follow real input: {nav.position()}')

            for key, facing in [('w', 'up'), ('s', 'down'), ('a', 'left'), ('d', 'right')]:
                # Return by real input to open grass, rather than accumulating
                # displacement toward a bank across all four probes.
                nav.go(('y', 330), ('x', 450))
                page.keyboard.down(key)
                try:
                    wait_animation('walk_' + facing)
                    # Leave a short visible movement segment in the recording.
                    page.wait_for_timeout(250)
                    assert nav.position()['animation'] == 'walk_' + facing, nav.position()
                finally:
                    page.keyboard.up(key)
                wait_animation('idle_' + facing)
                # Never hold movement during slow screenshots; the video is
                # the evidence of movement, these stills show stopped facing.
                page.screenshot(path=str(artifacts / ('art-controller-idle-' + facing + '.png')))
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
