#!/usr/bin/env python3
"""Exercise repeated Web starts and the honest WebGL failure messages."""
import functools
import json
import os
import sys
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from playwright.sync_api import sync_playwright

class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass

def main():
    build = Path(sys.argv[1]).resolve()
    server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(build)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f'http://127.0.0.1:{server.server_port}/index.html'
    try:
        with sync_playwright() as p:
            options = {'headless': True}
            if os.environ.get('CHROMIUM_PATH'):
                options['executable_path'] = os.environ['CHROMIUM_PATH']
            browser = p.chromium.launch(**options)
            page = browser.new_page(viewport={'width': 1280, 'height': 720})
            errors = []
            page.add_init_script('''window.__gl = {calls:0, failed:0, lost:0};
                const original = HTMLCanvasElement.prototype.getContext;
                HTMLCanvasElement.prototype.getContext = function(type,...args) {
                    const context = original.call(this,type,...args);
                    if(type === 'webgl2') { window.__gl.calls++; if(!context) window.__gl.failed++;
                        this.addEventListener('webglcontextlost',()=>window.__gl.lost++); }
                    return context;
                };''')
            page.on('pageerror', lambda e: errors.append(str(e)))
            page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
            page.on('requestfailed', lambda r: errors.append(f'{r.url}: {r.failure}'))
            page.on('response', lambda r: errors.append(f'{r.status}: {r.url}') if r.status >= 400 else None)
            for iteration in range(21):
                if iteration == 0:
                    page.goto(url, wait_until='load', timeout=90000)
                elif iteration == 15:
                    # Bypass the document URL cache without mixing content-hashed payloads.
                    page.goto(url + '?reload_probe=' + str(time.time_ns()), wait_until='load', timeout=90000)
                else:
                    page.reload(wait_until='load', timeout=90000)
                page.wait_for_function("!document.getElementById('status') || getComputedStyle(document.getElementById('status-notice')).display !== 'none'", timeout=90000)
                state = page.evaluate("() => ({gl:window.__gl, notice:document.getElementById('status-notice')?.innerText||'', canvases:document.querySelectorAll('canvas').length})")
                print(json.dumps({'iteration': iteration, 'state': state, 'errors': errors}, ensure_ascii=False), flush=True)
                if state['notice'] or state['canvases'] != 1 or state['gl']['failed'] or state['gl']['lost'] or errors:
                    raise AssertionError(f'Web start {iteration} failed: {state}; {errors}')
                if iteration in (0, 10):
                    page.keyboard.down('d'); page.wait_for_timeout(800); page.keyboard.up('d'); page.wait_for_timeout(1000)
            page.close()
            for unsupported in (False, True):
                failure = browser.new_page()
                failure.add_init_script("""(() => {
                    if (UNSUPPORTED) Object.defineProperty(window, 'WebGL2RenderingContext', {value: undefined, configurable: true});
                    Object.defineProperty(window,'Engine',{configurable:true,get(){return undefined},set(engine){
                        Object.defineProperty(window,'Engine',{configurable:true,writable:true,value:engine});
                        engine.getMissingFeatures=()=>['WebGL2 - Check web browser configuration and hardware support'];
                    }});
                })();""".replace('UNSUPPORTED', 'true' if unsupported else 'false'))
                failure.goto(url, wait_until='load')
                failure.locator('#status-notice').wait_for(state='visible')
                notice = failure.locator('#status-notice').inner_text()
                if unsupported:
                    assert '不提供 WebGL2' in notice and failure.get_by_role('button', name='重新尝试').count() == 0, notice
                else:
                    assert '本次未能创建' in notice and failure.get_by_role('button', name='重新尝试').count() == 1, notice
                    for attempt in (1, 2):
                        with failure.expect_navigation(wait_until='load'):
                            failure.get_by_role('button', name='重新尝试').click()
                        failure.locator('#status-notice').wait_for(state='visible')
                        assert failure.evaluate("sessionStorage.getItem('wonder-webgl-retries')") == str(attempt)
                    assert failure.get_by_role('button', name='重新尝试').count() == 0
                    print('PASS WebGL retries capped at two', flush=True)
                print('PASS WebGL unsupported' if unsupported else 'PASS WebGL context creation failure', flush=True)
                failure.close()
            browser.close()
    finally:
        server.shutdown()
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
