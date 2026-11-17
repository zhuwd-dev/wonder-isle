#!/usr/bin/env python3
"""Browser-level regression for the synchronous mirror's cross-tab CAS rule."""

from __future__ import annotations

import os
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

from playwright.sync_api import sync_playwright


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


CAS = """({key, expected, revision}) => {
  try {
    const current = localStorage.getItem(key);
    let actual = -1;
    if (current) {
      const parsed = JSON.parse(current);
      actual = parsed && parsed.format === 'wonder-isle-save-mirror-v2' && Number.isSafeInteger(parsed.revision)
        ? parsed.revision : 0;
    }
    if (actual !== expected) return 'conflict';
    localStorage.setItem(key, JSON.stringify({format:'wonder-isle-save-mirror-v2', namespace:key, revision, payload:{}}));
    return 'saved';
  } catch (_) { return 'unavailable'; }
}"""


def main() -> int:
    server = ThreadingHTTPServer(("127.0.0.1", 0), QuietHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        options: dict[str, object] = {"headless": True}
        if os.environ.get("CHROMIUM_PATH"):
            options["executable_path"] = os.environ["CHROMIUM_PATH"]
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(**options)
            context = browser.new_context()
            first, stale = context.new_page(), context.new_page()
            url = f"http://127.0.0.1:{server.server_port}/"
            first.goto(url)
            stale.goto(url)
            first.evaluate("localStorage.setItem('preview', JSON.stringify({format:'wonder-isle-save-mirror-v2',revision:4}))")
            stale_revision = stale.evaluate("JSON.parse(localStorage.getItem('preview')).revision")
            result = first.evaluate(f"{CAS}", {"key": "preview", "expected": 4, "revision": 5})
            assert result == "saved", result
            result = stale.evaluate(f"{CAS}", {"key": "preview", "expected": stale_revision, "revision": 5})
            assert result == "conflict", result
            current = first.evaluate("JSON.parse(localStorage.getItem('preview')).revision")
            assert current == 5, current
            result = stale.evaluate(f"{CAS}", {"key": "production", "expected": -1, "revision": 1})
            assert result == "saved", result
            assert first.evaluate("localStorage.getItem('preview') !== localStorage.getItem('production')")
            stale.evaluate("localStorage.setItem('corrupt', '{broken')")
            result = stale.evaluate(f"{CAS}", {"key": "corrupt", "expected": -1, "revision": 1})
            assert result == "unavailable", result
            stale.evaluate("() => { Storage.prototype.setItem = () => { throw new DOMException('quota', 'QuotaExceededError') }; return true; }")
            result = stale.evaluate(f"{CAS}", {"key": "quota", "expected": -1, "revision": 1})
            assert result == "unavailable", result
            print("PASS stale-tab conflict, preview/production separation, corrupt mirror and quota fail-closed")
            browser.close()
    finally:
        server.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
