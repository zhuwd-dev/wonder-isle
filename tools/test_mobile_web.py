#!/usr/bin/env python3
"""Browser-level checks for responsive Web canvas, launch flow, and PWA paths."""

from __future__ import annotations

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
        print("Usage: test_mobile_web.py <web-export-directory>", file=sys.stderr)
        return 2
    build_dir = Path(sys.argv[1]).resolve()
    if not (build_dir / "index.html").is_file():
        raise FileNotFoundError(build_dir / "index.html")
    output_dir = Path(os.environ.get("WEB_TEST_ARTIFACTS", "/tmp/wonder-isle-mobile-test"))
    output_dir.mkdir(parents=True, exist_ok=True)
    site_root = output_dir / "site"
    site_root.mkdir(exist_ok=True)
    project_mount = site_root / "wonder-isle"
    if project_mount.is_symlink() or project_mount.exists():
        project_mount.unlink()
    project_mount.symlink_to(build_dir, target_is_directory=True)
    server = ThreadingHTTPServer(("127.0.0.1", 0), lambda *a, **kw: QuietHandler(*a, directory=str(site_root), **kw))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    result: dict[str, object] = {"page_errors": [], "console_errors": []}
    try:
        with sync_playwright() as playwright:
            launch: dict[str, object] = {"headless": True}
            if chromium := os.environ.get("CHROMIUM_PATH"):
                launch["executable_path"] = chromium
            browser = playwright.chromium.launch(**launch)
            try:
                desktop = browser.new_page(viewport={"width": 1280, "height": 720}, device_scale_factor=1)
                desktop.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                desktop.on("console", lambda message: result["console_errors"].append(message.text) if message.type == "error" else None)
                desktop.goto(f"http://127.0.0.1:{server.server_port}/wonder-isle/", wait_until="load", timeout=60_000)
                desktop.wait_for_timeout(5_000)
                desktop_box = desktop.locator("canvas").bounding_box()
                desktop.set_viewport_size({"width": 1630, "height": 870})
                desktop.wait_for_timeout(500)
                wide_box = desktop.locator("canvas").bounding_box()
                desktop.screenshot(path=str(output_dir / "mobile-adapt-wide.png"), full_page=True)
                result["desktop_canvas"] = desktop_box
                result["wide_canvas"] = wide_box
                if not wide_box or wide_box["x"] != 0 or wide_box["y"] != 0 or wide_box["width"] < 1628 or wide_box["height"] < 868:
                    raise AssertionError(f"canvas does not occupy the ultrawide viewport: {wide_box}")

                mobile_context = browser.new_context(viewport={"width": 844, "height": 390}, device_scale_factor=1, is_mobile=True, has_touch=True)
                mobile = mobile_context.new_page()
                mobile.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                mobile.on("console", lambda message: result["console_errors"].append(message.text) if message.type == "error" else None)
                mobile.goto(f"http://127.0.0.1:{server.server_port}/wonder-isle/", wait_until="load", timeout=60_000)
                mobile.wait_for_timeout(5_000)
                gate_visible = is_visible(mobile, "#launch-screen")
                rotate_visible = is_visible(mobile, "#rotate-screen")
                if not gate_visible or rotate_visible:
                    raise AssertionError(f"landscape mobile launch UI is incorrect: gate={gate_visible}, rotate={rotate_visible}")
                mobile.screenshot(path=str(output_dir / "mobile-adapt-start-screen.png"), full_page=True)
                mobile.evaluate("""() => { window.__installPromptCount=0; const e=new Event('beforeinstallprompt'); e.prompt=()=>{window.__installPromptCount++;return Promise.resolve()}; e.userChoice=Promise.resolve({outcome:'accepted'}); dispatchEvent(e); }""")
                if not is_visible(mobile, "#install-game"):
                    raise AssertionError("Android add-to-home-screen button was not exposed after install eligibility")
                mobile.locator("#install-game").click()
                mobile.wait_for_function("window.__installPromptCount === 1")
                mobile.get_by_role("button", name="开始游戏").click()
                mobile.wait_for_function("document.querySelector('#launch-screen').hidden", timeout=60_000)
                mobile.wait_for_timeout(500)
                mobile_box = mobile.locator("canvas").bounding_box()
                mobile.screenshot(path=str(output_dir / "mobile-adapt-landscape.png"), full_page=True)
                if not mobile_box or mobile_box["x"] != 0 or mobile_box["y"] != 0 or mobile_box["width"] < 842 or mobile_box["height"] < 388:
                    raise AssertionError(f"canvas does not occupy the landscape phone viewport: {mobile_box}")
                result["mobile_canvas"] = mobile_box
                result["start_button_fullscreen"] = bool(mobile.evaluate("!!document.fullscreenElement"))
                if mobile.evaluate("!!document.fullscreenElement"):
                    mobile.evaluate("document.exitFullscreen()")
                    mobile.wait_for_function("!document.fullscreenElement", timeout=5_000)
                    resized_box = mobile.locator("canvas").bounding_box()
                    if not resized_box or resized_box["width"] < 842 or resized_box["height"] < 388:
                        raise AssertionError(f"canvas did not recover after exiting fullscreen: {resized_box}")
                    result["fullscreen_exit_canvas"] = resized_box
                mobile.set_viewport_size({"width": 390, "height": 844})
                mobile.wait_for_timeout(250)
                portrait_rotate = is_visible(mobile, "#rotate-screen")
                mobile.screenshot(path=str(output_dir / "mobile-adapt-portrait-rotate-prompt.png"), full_page=True)
                if not portrait_rotate:
                    raise AssertionError("portrait orientation did not show the rotate prompt")
                mobile.set_viewport_size({"width": 844, "height": 390})
                mobile.wait_for_timeout(250)
                if is_visible(mobile, "#rotate-screen"):
                    raise AssertionError("rotate prompt remained after returning to landscape")

                manifest = mobile.evaluate("async () => await (await fetch('./index.manifest.json')).json()")
                if manifest.get("name") != "奇趣小岛" or manifest.get("short_name") != "奇趣小岛" or manifest.get("orientation") != "landscape" or manifest.get("display") != "fullscreen":
                    raise AssertionError(f"unexpected PWA manifest: {manifest}")
                result["manifest"] = manifest
                mobile.wait_for_function("navigator.serviceWorker && navigator.serviceWorker.controller", timeout=15_000)
                registration = mobile.evaluate("async () => { const r=await navigator.serviceWorker.ready; return {scope:r.scope, active:!!r.active}; }")
                result["service_worker"] = registration
                if not registration["active"] or not registration["scope"].endswith("/wonder-isle/"):
                    raise AssertionError(f"PWA worker did not activate for the project path: {registration}")
                mobile_context.close()

                ios_context = browser.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1, is_mobile=True, has_touch=True, user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1")
                ios = ios_context.new_page()
                ios.add_init_script("Object.defineProperty(navigator,'platform',{get:()=> 'iPhone'}); HTMLElement.prototype.requestFullscreen=undefined; HTMLElement.prototype.webkitRequestFullscreen=undefined;")
                ios.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                ios.goto(f"http://127.0.0.1:{server.server_port}/wonder-isle/", wait_until="load", timeout=60_000)
                ios.wait_for_timeout(500)
                if not is_visible(ios, "#rotate-screen") or not is_visible(ios, "#install-game"):
                    raise AssertionError("iOS portrait orientation or add-to-home-screen guidance is missing")
                ios.set_viewport_size({"width": 844, "height": 390})
                ios.wait_for_timeout(200)
                ios.locator("#install-game").click()
                if not is_visible(ios, "#install-hint"):
                    raise AssertionError("iOS Safari install instructions did not appear")
                ios.get_by_role("button", name="开始游戏").click()
                ios.wait_for_function("document.querySelector('#launch-screen').hidden", timeout=60_000)
                if ios.evaluate("!!document.fullscreenElement"):
                    raise AssertionError("the iOS fullscreen fallback test unexpectedly entered fullscreen")
                result["ios_fullscreen_fallback"] = "passed"
                ios_context.close()

                wechat_context = browser.new_context(viewport={"width": 844, "height": 390}, device_scale_factor=1, is_mobile=True, has_touch=True, user_agent="Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 Chrome/130.0.0.0 Mobile Safari/537.36 MicroMessenger/8.0.55")
                wechat = wechat_context.new_page()
                wechat.add_init_script("HTMLElement.prototype.requestFullscreen=undefined; HTMLElement.prototype.webkitRequestFullscreen=undefined;")
                wechat.on("pageerror", lambda error: result["page_errors"].append(str(error)))
                wechat.goto(f"http://127.0.0.1:{server.server_port}/wonder-isle/", wait_until="load", timeout=60_000)
                if not is_visible(wechat, "#launch-screen") or not is_visible(wechat, "#install-game"):
                    raise AssertionError("WeChat browser instructions were not offered on the mobile launch screen")
                wechat.locator("#install-game").click()
                if not is_visible(wechat, "#install-hint") or "在浏览器中打开" not in wechat.locator("#install-hint").inner_text():
                    raise AssertionError("WeChat browser guidance did not explain how to open the game externally")
                wechat.get_by_role("button", name="开始游戏").click()
                wechat.wait_for_function("document.querySelector('#launch-screen').hidden", timeout=60_000)
                if wechat.evaluate("!!document.fullscreenElement"):
                    raise AssertionError("WeChat fullscreen fallback unexpectedly entered fullscreen")
                result["wechat_fullscreen_fallback"] = "passed"
                wechat_context.close()
                desktop.close()
            finally:
                browser.close()
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)
    if result["page_errors"] or result["console_errors"]:
        raise AssertionError(json.dumps(result, ensure_ascii=False))
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


def is_visible(page, selector: str) -> bool:
    return bool(page.locator(selector).evaluate("element => !element.hidden"))


if __name__ == "__main__":
    raise SystemExit(main())
