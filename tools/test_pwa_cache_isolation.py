#!/usr/bin/env python3
"""Check actual preview worker against a same-origin legacy cache cleanup."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import sys
import tempfile
import threading

from playwright.sync_api import sync_playwright


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit('Usage: test_pwa_cache_isolation.py <prepared-web-directory>')
    worker = Path(sys.argv[1]) / 'index.service.worker.js'
    if not worker.is_file():
        raise SystemExit('Prepared preview worker is missing')
    html = '''<!doctype html><script>navigator.serviceWorker.register('./index.service.worker.js',{scope:'./'});</script>'''
    # The deployed legacy production worker clears every old wonder-isle-* cache.
    legacy = '''self.addEventListener('install',e=>e.waitUntil(self.skipWaiting()));
self.addEventListener('activate',e=>e.waitUntil((async()=>{for(const k of await caches.keys())if(k.startsWith('wonder-isle-'))await caches.delete(k);await caches.open('wonder-isle-test-production');await self.clients.claim();})()));'''
    with tempfile.TemporaryDirectory(prefix='wonder-pwa-isolation-') as tmp:
        root = Path(tmp)
        for name in ('preview', 'production'):
            (root / name).mkdir()
            (root / name / 'index.html').write_text(html, encoding='utf-8')
        (root / 'preview/index.service.worker.js').write_bytes(worker.read_bytes())
        (root / 'production/index.service.worker.js').write_text(legacy, encoding='utf-8')
        server = ThreadingHTTPServer(('127.0.0.1', 0), partial(SimpleHTTPRequestHandler, directory=tmp))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            with sync_playwright() as p:
                opts = {'headless': True}
                if os.environ.get('CHROMIUM_PATH'):
                    opts['executable_path'] = os.environ['CHROMIUM_PATH']
                browser = p.chromium.launch(**opts)
                context = browser.new_context()
                page = context.new_page()
                base = f'http://127.0.0.1:{server.server_port}'
                page.goto(base + '/preview/index.html', wait_until='load')
                page.evaluate('navigator.serviceWorker.ready')
                page.reload(wait_until='load')
                page.wait_for_function('navigator.serviceWorker.controller !== null')
                page.wait_for_function("caches.keys().then(keys => keys.some(k => k.startsWith('wonder-preview-isle-')))")
                before = set(page.evaluate('caches.keys()'))
                page.goto(base + '/production/index.html', wait_until='load')
                page.evaluate('navigator.serviceWorker.ready')
                page.reload(wait_until='load')
                page.wait_for_function('navigator.serviceWorker.controller !== null')
                after = set(page.evaluate('caches.keys()'))
                preview = {name for name in before if name.startswith('wonder-preview-isle-')}
                if not preview or not preview.issubset(after) or 'wonder-isle-test-production' not in after:
                    raise AssertionError(f'Cache isolation failed: before={before}, after={after}')
                print('PASS same-origin preview cache survives legacy production activation')
                context.close()
                browser.close()
        finally:
            server.shutdown()
            server.server_close()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
