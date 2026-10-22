#!/usr/bin/env python3
"""Serve a Godot Web export and smoke-test it in Chromium with Playwright."""

from __future__ import annotations

import base64
import functools
import json
import os
import subprocess
import sys
import tempfile
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
    index_html = index_file.read_text(encoding="utf-8")
    if '<html lang="zh-CN">' not in index_html or "chrome://gpu" not in index_html:
        raise AssertionError("Web export is missing the Chinese WebGL2 troubleshooting notice")

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
    seed_planted_screenshot_path = artifact_dir / "web-q002-seed-planted.png"
    ending_screenshot_path = artifact_dir / "web-q012-ending.png"
    completed_screenshot_path = artifact_dir / "web-q012-complete.png"
    final_island_screenshot_path = artifact_dir / "web-q011-all-tasks-complete.png"
    godot_bin = os.environ.get(
        "GODOT_BIN", "/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
    )

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

                webgl2_available = page.evaluate(
                    "() => !!document.createElement('canvas').getContext('webgl2')"
                )
                game_canvas_uses_webgl2 = page.locator("canvas").first.evaluate(
                    "canvas => !!canvas.getContext('webgl2')"
                )
                if not webgl2_available or not game_canvas_uses_webgl2:
                    raise AssertionError(
                        "Chromium did not initialize the game's WebGL2 rendering context"
                    )

                result.update(
                    {
                        "http_status": response.status,
                        "title": page.title(),
                        "canvas_count": page.locator("canvas").count(),
                        "canvas_box": canvas_box,
                        "webgl2_available": webgl2_available,
                        "game_canvas_uses_webgl2": game_canvas_uses_webgl2,
                        "screenshot": str(screenshot_path),
                    }
                )
                page.screenshot(path=str(screenshot_path), full_page=True)

                with tempfile.TemporaryDirectory(prefix="wonder-isle-seed-planted-") as temp_dir:
                    fixture_path = Path(temp_dir) / "seed-planted-save.json"
                    subprocess.run(
                        [
                            godot_bin,
                            "--headless",
                            "--path",
                            str(Path(__file__).resolve().parent.parent),
                            "--script",
                            "tests/create_seed_planted_web_save.gd",
                            "--",
                            str(fixture_path),
                        ],
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    fixture_base64 = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
                    save_key = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"
                    page.mouse.click(1150, 50)
                    page.wait_for_timeout(700)
                    page.evaluate(
                        """async ({key, payload}) => new Promise((resolve, reject) => {
                            const binary = atob(payload);
                            const contents = new Int8Array(binary.length);
                            for (let index = 0; index < binary.length; index++) {
                                contents[index] = binary.charCodeAt(index);
                            }
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                                const store = transaction.objectStore('FILE_DATA');
                                const existing = store.get(key);
                                existing.onsuccess = () => {
                                    const record = existing.result || {};
                                    record.timestamp = new Date();
                                    record.contents = contents;
                                    store.put(record, key);
                                };
                                transaction.oncomplete = resolve;
                                transaction.onerror = () => reject(transaction.error);
                            };
                        })""",
                        {"key": save_key, "payload": fixture_base64},
                    )
                    page.reload(wait_until="load", timeout=60_000)
                    page.wait_for_selector("canvas", timeout=60_000)
                    page.wait_for_timeout(3_000)
                    seed_stage_save = page.evaluate(
                        """async key => new Promise((resolve, reject) => {
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                const request = transaction.objectStore('FILE_DATA').get(key);
                                request.onsuccess = () => {
                                    const bytes = new Uint8Array(request.result.contents);
                                    resolve(JSON.parse(new TextDecoder().decode(bytes)));
                                };
                                request.onerror = () => reject(request.error);
                            };
                        })""",
                        save_key,
                    )
                    if seed_stage_save.get("seed_planted") is not True:
                        raise AssertionError("The browser did not load the seed-planted stage fixture")
                    page.screenshot(path=str(seed_planted_screenshot_path), full_page=True)
                    result["q002_seed_planted_screenshot"] = str(seed_planted_screenshot_path)
                    page.mouse.click(1150, 50)
                    page.wait_for_timeout(1_000)

                with tempfile.TemporaryDirectory(prefix="wonder-isle-q012-") as temp_dir:
                    fixture_path = Path(temp_dir) / "q012-ending-save.json"
                    subprocess.run(
                        [
                            godot_bin,
                            "--headless",
                            "--path",
                            str(Path(__file__).resolve().parent.parent),
                            "--script",
                            "tests/create_q012_web_save.gd",
                            "--",
                            str(fixture_path),
                        ],
                        check=True,
                        capture_output=True,
                        text=True,
                    )
                    fixture_base64 = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
                    save_key = "/userfs/godot/app_userdata/奇趣小岛/qxisland_stage2_save.json"
                    page.mouse.click(800, 600)
                    page.keyboard.down("d")
                    page.wait_for_timeout(900)
                    page.keyboard.up("d")
                    page.keyboard.press("e")
                    page.wait_for_timeout(1_000)
                    page.evaluate(
                        """async ({key, payload}) => new Promise((resolve, reject) => {
                            const binary = atob(payload);
                            const contents = new Int8Array(binary.length);
                            for (let index = 0; index < binary.length; index++) {
                                contents[index] = binary.charCodeAt(index);
                            }
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                                const store = transaction.objectStore('FILE_DATA');
                                const existing = store.get(key);
                                existing.onsuccess = () => {
                                    if (!existing.result) {
                                        reject(new Error('The game did not create its save file'));
                                        return;
                                    }
                                    existing.result.timestamp = new Date();
                                    existing.result.contents = contents;
                                    store.put(existing.result, key);
                                };
                                transaction.oncomplete = resolve;
                                transaction.onerror = () => reject(transaction.error);
                            };
                        })""",
                        {"key": save_key, "payload": fixture_base64},
                    )
                    page.reload(wait_until="load", timeout=60_000)
                    page.wait_for_selector("canvas", timeout=60_000)
                    page.wait_for_timeout(3_000)
                    page.screenshot(path=str(ending_screenshot_path), full_page=True)

                    page.mouse.click(800, 600)
                    for key, duration_ms in (("w", 750), ("d", 1_150), ("s", 280)):
                        page.keyboard.down(key)
                        page.wait_for_timeout(duration_ms)
                        page.keyboard.up(key)
                    page.keyboard.down("w")
                    page.wait_for_timeout(450)
                    page.keyboard.up("w")
                    page.screenshot(path=str(artifact_dir / "web-q012-at-rabbit.png"), full_page=True)
                    page.keyboard.press("e")
                    page.wait_for_timeout(1_500)
                    page.screenshot(path=str(artifact_dir / "web-q012-after-interact.png"), full_page=True)
                    page.wait_for_timeout(6_000)
                    page.reload(wait_until="load", timeout=60_000)
                    page.wait_for_selector("canvas", timeout=60_000)
                    page.wait_for_timeout(3_000)
                    page.screenshot(path=str(artifact_dir / "web-q012-after-refresh.png"), full_page=True)
                    saved_ending = page.evaluate(
                        """async key => new Promise((resolve, reject) => {
                            const opening = indexedDB.open('/userfs');
                            opening.onerror = () => reject(opening.error);
                            opening.onsuccess = () => {
                                const transaction = opening.result.transaction('FILE_DATA', 'readonly');
                                const request = transaction.objectStore('FILE_DATA').get(key);
                                request.onsuccess = () => {
                                    const bytes = new Uint8Array(request.result.contents);
                                    resolve(JSON.parse(new TextDecoder().decode(bytes)));
                                };
                                request.onerror = () => reject(request.error);
                            };
                        })""",
                        save_key,
                    )
                    if saved_ending.get("q012_completed") is not True:
                        raise AssertionError(
                            "The browser did not persist Q012: "
                            f"{saved_ending.get('q012_completed')}; console errors: {result['console_errors']}"
                        )
                    result["q012_browser_flow"] = "passed"
                    page.screenshot(path=str(completed_screenshot_path), full_page=True)
                    result["q012_ending_screenshot"] = str(ending_screenshot_path)
                    result["q012_complete_screenshot"] = str(completed_screenshot_path)

                    with tempfile.TemporaryDirectory(prefix="wonder-isle-q011-complete-") as temp_dir:
                        fixture_path = Path(temp_dir) / "q011-complete-save.json"
                        subprocess.run(
                            [
                                godot_bin,
                                "--headless",
                                "--path",
                                str(Path(__file__).resolve().parent.parent),
                                "--script",
                                "tests/create_q011_complete_web_save.gd",
                                "--",
                                str(fixture_path),
                            ],
                            check=True,
                            capture_output=True,
                            text=True,
                        )
                        complete_fixture = base64.b64encode(fixture_path.read_bytes()).decode("ascii")
                        page.evaluate(
                            """async ({key, payload}) => new Promise((resolve, reject) => {
                                const binary = atob(payload);
                                const contents = new Int8Array(binary.length);
                                for (let index = 0; index < binary.length; index++) {
                                    contents[index] = binary.charCodeAt(index);
                                }
                                const opening = indexedDB.open('/userfs');
                                opening.onerror = () => reject(opening.error);
                                opening.onsuccess = () => {
                                    const transaction = opening.result.transaction('FILE_DATA', 'readwrite');
                                    const store = transaction.objectStore('FILE_DATA');
                                    const request = store.get(key);
                                    request.onsuccess = () => {
                                        const record = request.result || {};
                                        record.timestamp = new Date();
                                        record.contents = contents;
                                        store.put(record, key);
                                    };
                                    transaction.oncomplete = resolve;
                                    transaction.onerror = () => reject(transaction.error);
                                };
                            })""",
                            {"key": save_key, "payload": complete_fixture},
                        )
                        page.reload(wait_until="load", timeout=60_000)
                        page.wait_for_selector("canvas", timeout=60_000)
                        page.wait_for_timeout(3_000)
                        page.screenshot(path=str(final_island_screenshot_path), full_page=True)
                        result["q011_all_tasks_complete_screenshot"] = str(final_island_screenshot_path)

                failure_page = browser.new_page()
                failure_page.add_init_script(
                    """(() => {
                        Object.defineProperty(window, 'Engine', {
                            configurable: true,
                            get() { return undefined; },
                            set(engineClass) {
                                Object.defineProperty(window, 'Engine', {
                                    configurable: true,
                                    writable: true,
                                    value: engineClass,
                                });
                                engineClass.getMissingFeatures = () => [
                                    'WebGL2 - Check web browser configuration and hardware support',
                                ];
                            },
                        });
                    })();"""
                )
                failure_page.goto(
                    f"http://127.0.0.1:{server.server_port}/index.html",
                    wait_until="load",
                    timeout=60_000,
                )
                failure_page.locator("#status-notice").wait_for(state="visible", timeout=10_000)
                failure_notice = failure_page.locator("#status-notice").inner_text()
                expected_failure_help = (
                    "WebGL2（浏览器图形加速）",
                    "chrome://settings/system",
                    "chrome://gpu",
                    "使用图形加速",
                )
                if any(fragment not in failure_notice for fragment in expected_failure_help):
                    raise AssertionError(
                        f"WebGL2 failure notice lacks clear Chinese troubleshooting steps: {failure_notice}"
                    )
                notice_dimensions = failure_page.locator("#status-notice").evaluate(
                    "element => ({height: element.clientHeight, scrollHeight: element.scrollHeight, width: element.clientWidth, scrollWidth: element.scrollWidth})"
                )
                if (
                    notice_dimensions["scrollHeight"] > notice_dimensions["height"] + 1
                    or notice_dimensions["scrollWidth"] > notice_dimensions["width"] + 1
                ):
                    raise AssertionError(
                        f"WebGL2 troubleshooting text is clipped: {notice_dimensions}"
                    )
                result["webgl2_failure_notice_test"] = "passed"
                result["webgl2_failure_notice_dimensions"] = notice_dimensions
                fallback_screenshot = artifact_dir / "webgl2-fallback.png"
                failure_page.screenshot(path=str(fallback_screenshot), full_page=True)
                result["webgl2_fallback_screenshot"] = str(fallback_screenshot)
                failure_page.close()
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
