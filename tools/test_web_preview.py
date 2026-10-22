#!/usr/bin/env python3
"""Serve a Godot Web export and smoke-test it in Chromium with Playwright."""

from __future__ import annotations

import functools
import json
import os
import sys
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from playwright.sync_api import sync_playwright


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, _format: str, *_args: object) -> None:
        pass


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: test_web_preview.py <web-export-directory>", file=sys.stderr)
        return 2

    build_dir = Path(sys.argv[1]).resolve()
    index_file = build_dir / "index.html"
    if not index_file.is_file():
        print(f"Web export not found: {index_file}", file=sys.stderr)
        return 2

    handler = functools.partial(QuietHandler, directory=str(build_dir))
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()

    result: dict[str, object] = {
        "console_errors": [],
        "page_errors": [],
        "request_failures": [],
    }
    default_artifact_dir = build_dir.parent.parent / "tests" / "artifacts"
    artifact_dir = Path(os.environ.get("WEB_TEST_ARTIFACTS", default_artifact_dir)).resolve()
    artifact_dir.mkdir(parents=True, exist_ok=True)
    screenshot_path = artifact_dir / "web-preview.png"

    try:
        with sync_playwright() as playwright:
            launch_options: dict[str, object] = {"headless": True}
            chromium_path = os.environ.get("CHROMIUM_PATH")
            if chromium_path:
                launch_options["executable_path"] = chromium_path
            browser = playwright.chromium.launch(**launch_options)
            try:
                page = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
                page.on(
                    "console",
                    lambda message: result["console_errors"].append(message.text)
                    if message.type == "error"
                    else None,
                )
                page.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                page.on(
                    "requestfailed",
                    lambda request: result["request_failures"].append(
                        {"url": request.url, "failure": request.failure}
                    ),
                )

                response = page.goto(
                    f"http://127.0.0.1:{server.server_port}/index.html",
                    wait_until="load",
                    timeout=60_000,
                )
                if response is None:
                    raise AssertionError("Chromium did not receive an HTTP response")

                page.wait_for_selector("canvas", timeout=60_000)
                page.wait_for_timeout(3_000)
                canvas_box = page.locator("canvas").first.bounding_box()
                if canvas_box is None or canvas_box["width"] < 640 or canvas_box["height"] < 360:
                    raise AssertionError(f"Unexpected game canvas bounds: {canvas_box}")

                result.update(
                    {
                        "http_status": response.status,
                        "title": page.title(),
                        "canvas_count": page.locator("canvas").count(),
                        "canvas_box": canvas_box,
                        "screenshot": str(screenshot_path),
                    }
                )
                page.screenshot(path=str(screenshot_path), full_page=True)
            finally:
                browser.close()
    finally:
        server.shutdown()
        server.server_close()
        server_thread.join(timeout=2)

    print(json.dumps(result, ensure_ascii=False, indent=2))
    if result.get("http_status") != 200:
        raise AssertionError(f"Unexpected HTTP status: {result.get('http_status')}")
    if result.get("title") != "奇趣小岛":
        raise AssertionError(f"Unexpected page title: {result.get('title')}")
    for error_key in ("console_errors", "page_errors", "request_failures"):
        if result[error_key]:
            raise AssertionError(f"Browser reported {error_key}: {result[error_key]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
