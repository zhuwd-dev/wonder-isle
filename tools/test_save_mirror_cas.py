#!/usr/bin/env python3
"""Browser-level regression for the synchronous mirror's cross-tab CAS rule."""

from __future__ import annotations

import os
import asyncio
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

from playwright.async_api import async_playwright


class QuietHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        body = b"<!doctype html><meta charset=utf-8><title>mirror test</title>"
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        pass


CAS = """({key, expected, revision, payload = {}}) => new Promise(resolve => {
  let failure = 'unavailable', settled = false, tx;
  const finish = status => { if (!settled) { settled = true; resolve(status); } };
  try {
    const opening = indexedDB.open('wonder-isle-save-mirror-ledger', 1);
    opening.onupgradeneeded = () => { if (!opening.result.objectStoreNames.contains('mirrors')) opening.result.createObjectStore('mirrors'); };
    opening.onerror = () => finish('unavailable');
    opening.onsuccess = () => {
      try {
        tx = opening.result.transaction('mirrors', 'readwrite');
        tx.oncomplete = () => finish('saved');
        tx.onabort = () => finish(failure);
        tx.onerror = () => { failure = 'unavailable'; };
        const store = tx.objectStore('mirrors'), get = store.get(key);
        get.onerror = () => { try { tx.abort(); } catch (_) {} };
        get.onsuccess = () => {
          try {
            const currentText = localStorage.getItem(key) || '';
            let localRevision = -1;
            if (currentText) {
              const current = JSON.parse(currentText);
              if (current && current.format === 'wonder-isle-save-mirror-v2') {
                localRevision = Number.isSafeInteger(current.revision) && current.revision >= 0 ? current.revision : -2;
              } else if (current && Object.prototype.hasOwnProperty.call(current, '_save_revision')) {
                localRevision = Number.isSafeInteger(current._save_revision) && current._save_revision >= 0 ? current._save_revision : -2;
              } else localRevision = 0;
            }
            const ledger = get.result;
            let actual = localRevision;
            if (ledger) {
              if (ledger.revision > localRevision || (ledger.revision === localRevision && ledger.envelope !== currentText)) {
                localStorage.setItem(key, ledger.envelope); failure = 'conflict'; tx.abort(); return;
              }
              actual = Math.max(actual, ledger.revision);
            }
            if (actual !== expected) { failure = 'conflict'; tx.abort(); return; }
            const envelope = JSON.stringify({format:'wonder-isle-save-mirror-v2', namespace:key, revision, payload});
            localStorage.setItem(key, envelope);
            store.put({revision, envelope}, key);
          } catch (_) { failure = 'unavailable'; try { tx.abort(); } catch (_) {} }
        };
      } catch (_) { finish('unavailable'); }
    };
  } catch (_) { finish('unavailable'); }
})"""


async def main() -> int:
    server = ThreadingHTTPServer(("127.0.0.1", 0), QuietHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        options: dict[str, object] = {"headless": True}
        if os.environ.get("CHROMIUM_PATH"):
            options["executable_path"] = os.environ["CHROMIUM_PATH"]
        async with async_playwright() as playwright:
            browser = await playwright.chromium.launch(**options)
            context = await browser.new_context()
            first, stale = await context.new_page(), await context.new_page()
            url = f"http://127.0.0.1:{server.server_port}/"
            await asyncio.gather(first.goto(url), stale.goto(url))
            await first.evaluate("localStorage.setItem('preview', JSON.stringify({format:'wonder-isle-save-mirror-v2',revision:4}))")
            stale_revision = await stale.evaluate("JSON.parse(localStorage.getItem('preview')).revision")
            result = await first.evaluate(CAS, {"key": "preview", "expected": 4, "revision": 5})
            assert result == "saved", result
            result = await stale.evaluate(CAS, {"key": "preview", "expected": stale_revision, "revision": 5})
            assert result == "conflict", result
            current = await first.evaluate("JSON.parse(localStorage.getItem('preview')).revision")
            assert current == 5, current
            result = await stale.evaluate(CAS, {"key": "production", "expected": -1, "revision": 1})
            assert result == "saved", result
            assert await first.evaluate("localStorage.getItem('preview') !== localStorage.getItem('production')")
            await first.evaluate("localStorage.setItem('legacy', JSON.stringify({_save_revision:26, quest_completed:true}))")
            result = await first.evaluate(CAS, {"key": "legacy", "expected": 26, "revision": 27})
            assert result == "saved", result
            assert await first.evaluate("JSON.parse(localStorage.getItem('legacy')).revision") == 27
            await first.evaluate("localStorage.setItem('invalid-revision', JSON.stringify({_save_revision:'26'}))")
            result = await first.evaluate(CAS, {"key": "invalid-revision", "expected": 0, "revision": 1})
            assert result == "conflict", result
            await stale.evaluate("localStorage.setItem('corrupt', '{broken')")
            result = await stale.evaluate(CAS, {"key": "corrupt", "expected": -1, "revision": 1})
            assert result == "unavailable", result
            for revision in range(10, 60):
                key = f"concurrent-{revision}"
                await first.evaluate(
                    "({key, revision}) => localStorage.setItem(key, JSON.stringify({format:'wonder-isle-save-mirror-v2',revision,payload:{}}))",
                    {"key": key, "revision": revision},
                )
                one, two = await asyncio.gather(
                    first.evaluate(CAS, {"key": key, "expected": revision, "revision": revision + 1, "payload": {"tab": "first"}}),
                    stale.evaluate(CAS, {"key": key, "expected": revision, "revision": revision + 1, "payload": {"tab": "stale"}}),
                )
                assert sorted((one, two)) == ["conflict", "saved"], (key, one, two)
                concurrent = await first.evaluate("key => JSON.parse(localStorage.getItem(key))", key)
                assert concurrent["revision"] == revision + 1 and concurrent["payload"]["tab"] in ("first", "stale"), concurrent
            await stale.evaluate("() => { Storage.prototype.setItem = () => { throw new DOMException('quota', 'QuotaExceededError') }; return true; }")
            result = await stale.evaluate(CAS, {"key": "quota", "expected": -1, "revision": 1})
            assert result == "unavailable", result
            print("PASS atomic cross-tab IndexedDB revision ledger, stale-tab conflict, namespace separation, legacy revision, corrupt mirror and quota fail-closed")
            await browser.close()
    finally:
        server.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
