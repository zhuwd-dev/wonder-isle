#!/usr/bin/env python3
"""Localize Godot's Web startup failure and explain how to enable WebGL2."""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from pathlib import Path


OLD_LANGUAGE = '<html lang="en">'
NEW_LANGUAGE = '<html lang="zh-CN">'
OLD_NOTICE = (
    "const missingMsg = 'Error\\nThe following features required to run Godot projects on the Web are missing:\\n';\n"
    "\t\t\tdisplayFailureNotice(missingMsg + missing.join('\\n'));"
)
NEW_NOTICE = """const missingWebGL = missing.some((feature) => feature.startsWith('WebGL2'));
\t\t\tconst hasWebGLInterface = typeof window.WebGL2RenderingContext !== 'undefined';
\t\t\tconst webglMessage = hasWebGLInterface
\t\t\t\t? 'WebGL2（浏览器图形加速）本次未能创建图形上下文，可能是显卡资源暂时不可用或图形加速被禁用。'
\t\t\t\t: '当前浏览器不提供 WebGL2（浏览器图形加速）接口，无法运行游戏。';
\t\t\tconst details = missing.filter((feature) => !feature.startsWith('WebGL2')).join('\\n');
\t\t\tdisplayFailureNotice((missingWebGL ? webglMessage + '\\n' : '') + details +
\t\t\t\t'\\n请检查 chrome://gpu 或 edge://gpu；在 chrome://settings/system 或 edge://settings/system 开启“使用图形加速”，然后重启浏览器。');
\t\t\tif (missingWebGL && hasWebGLInterface) {
\t\t\t\tlet attempts = 2;
\t\t\t\ttry { attempts = Number(sessionStorage.getItem('wonder-webgl-retries') || 0); } catch (_) {}
\t\t\t\tif (attempts < 2) {
\t\t\t\t\tconst retry = document.createElement('button');
\t\t\t\t\tretry.textContent = '重新尝试';
\t\t\t\t\tretry.onclick = () => {
\t\t\t\t\t\tretry.disabled = true;
\t\t\t\t\t\ttry { sessionStorage.setItem('wonder-webgl-retries', String(attempts + 1)); } catch (_) { return; }
\t\t\t\t\t\twindow.location.reload();
\t\t\t\t\t};
\t\t\t\t\tstatusNotice.appendChild(retry);
\t\t\t\t}
\t\t\t}"""

PWA_MANIFEST = {
    "id": "./", "name": "奇趣小岛", "short_name": "奇趣小岛",
    "description": "和小老鼠一起探索花园、帮助岛上的朋友。",
    "start_url": "./", "scope": "./", "display": "fullscreen",
    "orientation": "landscape", "background_color": "#bde9ec",
    "theme_color": "#bde9ec",
    "icons": [
        {"src": "./index.192x192.png", "sizes": "192x192", "type": "image/png", "purpose": "any"},
        {"src": "./index.180x180.png", "sizes": "180x180", "type": "image/png", "purpose": "any"},
        {"src": "./index.512x512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable"},
    ],
}

LAUNCH_HTML = '''
<div id="launch-screen" hidden>
  <div class="launch-scene" aria-hidden="true"><span class="launch-sun"></span><span class="launch-island"></span><span class="launch-flower flower-a"></span><span class="launch-flower flower-b"></span></div>
  <section class="launch-card" aria-label="开始游戏"><div class="launch-kicker">绘本式小岛冒险</div><h1>奇趣小岛</h1><p>和小老鼠一起探索花园、帮助岛上的朋友吧。</p><button id="start-game" type="button">开始游戏</button><button id="install-game" type="button" hidden>添加到主屏幕</button><p id="install-hint" hidden></p><small>横屏游玩体验更好</small></section>
</div>
<div id="rotate-screen" hidden><div class="rotate-card"><span aria-hidden="true">↻</span><strong>请将设备横过来</strong><small>横屏后就可以继续探索小岛啦</small></div></div>
'''

LAUNCH_CSS = '''
html, body { width:100%; height:100%; min-width:100%; min-height:100%; margin:0; overflow:hidden; overscroll-behavior:none; }
body { position:fixed; inset:0; color:#294438; background:#bde9ec; touch-action:none; }
#canvas { display:block; max-width:100vw; max-height:100dvh; }
#launch-screen, #rotate-screen { position:fixed; inset:0; z-index:30; box-sizing:border-box; display:grid; place-items:center; padding:max(18px,env(safe-area-inset-top)) max(22px,env(safe-area-inset-right)) max(18px,env(safe-area-inset-bottom)) max(22px,env(safe-area-inset-left)); overflow:hidden; background:linear-gradient(180deg,#bce8ed 0%,#e8f5df 68%,#b5d995 100%); }
#launch-screen[hidden], #rotate-screen[hidden] { display:none; }
.launch-scene { position:absolute; inset:0; overflow:hidden; pointer-events:none; }
.launch-sun { position:absolute; width:min(24vw,180px); aspect-ratio:1; top:8%; right:12%; border-radius:50%; background:#ffe09b; box-shadow:0 0 70px #fff2bf99; }
.launch-island { position:absolute; width:130vw; height:36vh; left:-15vw; bottom:-21vh; border:10px solid #9bc879; border-radius:50% 50% 0 0; background:linear-gradient(180deg,#8bce7c,#6ebd79); box-shadow:0 -24px 45px #ffffff55; }
.launch-flower { position:absolute; width:20px; height:20px; border-radius:50%; background:#fff4cf; box-shadow:13px 0 #f6a9ad,-13px 0 #d8eff0,0 13px #f6a9ad,0 -13px #f6a9ad,0 0 0 5px #ffd873; }
.flower-a { left:17%; bottom:17%; }.flower-b { right:18%; bottom:25%; transform:scale(.75); }
.launch-card { position:relative; width:min(440px,86vw); box-sizing:border-box; padding:30px clamp(20px,5vw,42px); border:2px solid #d4bb7e; border-radius:28px; background:#fff9edee; box-shadow:0 18px 55px #49694c33; text-align:center; }
.launch-kicker { color:#78936b; font-size:14px; letter-spacing:.14em; }.launch-card h1 { margin:7px 0 8px; font-size:clamp(29px,7vw,42px); line-height:1.15; color:#28483a; }
.launch-card p { margin:0 auto 20px; max-width:28em; font-size:clamp(14px,3.2vw,18px); line-height:1.55; color:#536d58; }
.launch-card button { display:block; width:100%; min-height:52px; margin:10px 0 0; border:1px solid #8eaa75; border-radius:17px; color:#244632; background:linear-gradient(#d9efc8,#b9dfa6); box-shadow:0 4px 0 #8eb479; font:700 19px system-ui,sans-serif; }
.launch-card button:active { transform:translateY(2px); box-shadow:0 2px 0 #8eb479; }.launch-card button[hidden] { display:none; }
.launch-card small { display:block; margin-top:16px; color:#71866d; font-size:12px; }#install-hint { margin:12px 0 0; padding:10px; border-radius:12px; background:#edf3df; font-size:14px; }
.rotate-card { display:grid; justify-items:center; gap:10px; padding:26px; border:1px solid #d5bd83; border-radius:22px; background:#fff9ed; box-shadow:0 12px 40px #49694c33; text-align:center; }
.rotate-card span { font-size:48px; color:#719d64; }.rotate-card strong { font-size:21px; }.rotate-card small { color:#637a65; }
@media (prefers-reduced-motion:no-preference) { .launch-sun { animation:sun-breathe 5s ease-in-out infinite alternate; } @keyframes sun-breathe { to { transform:translateY(7px); } } }
'''

LAUNCH_SCRIPT = '''
<script>
(() => {
  const launch=document.getElementById('launch-screen'), rotate=document.getElementById('rotate-screen');
  const start=document.getElementById('start-game'), install=document.getElementById('install-game'), hint=document.getElementById('install-hint');
  const standalone=()=>matchMedia('(display-mode: standalone)').matches||matchMedia('(display-mode: fullscreen)').matches||navigator.standalone===true;
  const mobile=navigator.maxTouchPoints>0||matchMedia('(pointer: coarse)').matches;
  const compactMobile=mobile&&Math.min(innerWidth,innerHeight)<1100;
  const gated=compactMobile&&!standalone();
  let release; window.wonderLaunchReady=new Promise(resolve=>release=resolve); if(!gated) release(); else launch.hidden=false;
  const orientation=()=>{rotate.hidden=!(compactMobile&&innerHeight>innerWidth);};
  const notifyViewport=()=>{orientation();dispatchEvent(new Event('resize'));};
  orientation(); addEventListener('resize',orientation,{passive:true}); addEventListener('orientationchange',notifyViewport,{passive:true});
  if(visualViewport) visualViewport.addEventListener('resize',notifyViewport,{passive:true}); document.addEventListener('fullscreenchange',notifyViewport);
  start.addEventListener('click',()=>{start.disabled=true;start.textContent='正在进入小岛…';try{const el=document.documentElement,request=el.requestFullscreen||el.webkitRequestFullscreen;if(request&&!standalone())Promise.resolve(request.call(el)).catch(()=>{});}catch(_){} release();notifyViewport();},{once:true});
  let installPrompt=null; addEventListener('beforeinstallprompt',event=>{event.preventDefault();installPrompt=event;install.hidden=false;});
  const ios=/iPad|iPhone|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1); const wechat=/MicroMessenger/i.test(navigator.userAgent); if(gated&&(ios||wechat))install.hidden=false;
  install.addEventListener('click',async()=>{if(installPrompt){installPrompt.prompt();await installPrompt.userChoice;installPrompt=null;install.hidden=true;}else if(ios){hint.textContent='在 Safari 点“分享”按钮，再选“添加到主屏幕”。微信内置浏览器请先用 Safari 打开。';hint.hidden=false;}else if(wechat){hint.textContent='微信内置浏览器可能不支持全屏或安装。请点右上角“…”选择在浏览器中打开，再使用浏览器的“添加到主屏幕”。';hint.hidden=false;}});
  window.wonderGameReady=()=>{launch.hidden=true;notifyViewport();}; window.wonderGameFailed=()=>{launch.hidden=true;};
  if('serviceWorker'in navigator&&(location.protocol==='https:'||location.hostname==='localhost'||location.hostname==='127.0.0.1')) addEventListener('load',()=>navigator.serviceWorker.register('./index.service.worker.js',{scope:'./'}).catch(error=>console.warn('PWA 离线缓存暂不可用',error)),{once:true});
})();
</script>
'''


def write_pwa_files(build_dir: Path, build_id: str) -> None:
    manifest_path = build_dir / "index.manifest.json"
    worker_path = build_dir / "index.service.worker.js"
    if not manifest_path.is_file() or not worker_path.is_file():
        raise FileNotFoundError("Godot Web PWA export is incomplete; check that progressive_web_app/enabled is true")
    icon_source = Path(__file__).resolve().parents[1] / "assets" / "art" / "pwa" / "icon-192.png"
    if not icon_source.is_file():
        raise FileNotFoundError(f"PWA Android icon resource is missing: {icon_source}")
    (build_dir / "index.192x192.png").write_bytes(icon_source.read_bytes())
    manifest = dict(PWA_MANIFEST)
    manifest["start_url"] = "./index.html"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    worker = f'''const CACHE_NAME="wonder-isle-{build_id}"; const CACHE_PREFIX="wonder-isle-";
const INDEX_URL=new URL("./index.html",self.registration.scope).href;
self.addEventListener("install",event=>event.waitUntil(self.skipWaiting()));
self.addEventListener("activate",event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith(CACHE_PREFIX)&&key!==CACHE_NAME).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",event=>{{
 const request=event.request; if(request.method!=="GET"||new URL(request.url).origin!==self.location.origin)return;
 if(new URL(request.url).searchParams.has("test_telemetry"))return;
 if(request.mode==="navigate"){{event.respondWith(fetch(request).then(response=>{{if(response.ok)caches.open(CACHE_NAME).then(cache=>cache.put(INDEX_URL,response.clone())).catch(()=>{{}});return response;}}).catch(async()=>await caches.match(request)||await caches.match(INDEX_URL)||Response.error()));return;}}
 const name=new URL(request.url).pathname.split("/").pop();
 if(!/^index-[a-f0-9]{{12}}\\.(?:js|wasm|pck|audio\\.worklet\\.js|audio\\.position\\.worklet\\.js)$/.test(name))return;
 event.respondWith(caches.match(request).then(cached=>cached||fetch(request).then(response=>{{if(response.ok)caches.open(CACHE_NAME).then(cache=>cache.put(request,response.clone())).catch(()=>{{}});return response;}})));
}});
'''
    worker_path.write_text(worker, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: prepare_web_export.py <web-export-directory>", file=sys.stderr)
        return 2

    index_file = Path(sys.argv[1]) / "index.html"
    if not index_file.is_file():
        print(f"Web export not found: {index_file}", file=sys.stderr)
        return 2

    build_dir = index_file.parent
    export_files = [
        build_dir / "index.js",
        build_dir / "index.wasm",
        build_dir / "index.pck",
        build_dir / "index.audio.worklet.js",
        build_dir / "index.audio.position.worklet.js",
    ]
    missing_exports = [str(path.name) for path in export_files if not path.is_file()]
    if missing_exports:
        print(f"Godot Web export is missing files: {', '.join(missing_exports)}", file=sys.stderr)
        return 1

    pck_file = build_dir / "index.pck"
    maximum_pck_size = 64 * 1024 * 1024
    if pck_file.stat().st_size > maximum_pck_size:
        print(
            f"Godot Web resource pack is {pck_file.stat().st_size} bytes; "
            f"the 64 MiB safety limit was exceeded. Check export exclusions "
            "for tests, screenshots, recordings, and unused source assets.",
            file=sys.stderr,
        )
        return 1

    # A query string on index.html does not change the URLs Godot uses for its
    # JavaScript, WASM, and PCK. Give those payloads content-addressed names so
    # an older cached game can never survive a Pages update.
    digest = hashlib.sha256()
    for path in export_files:
        with path.open("rb") as exported_file:
            while chunk := exported_file.read(1024 * 1024):
                digest.update(chunk)
    build_id = digest.hexdigest()[:12]
    executable = f"index-{build_id}"
    renamed_files = {path: build_dir / f"{executable}{path.name.removeprefix('index')}" for path in export_files}
    for source, destination in renamed_files.items():
        destination.unlink(missing_ok=True)
        source.replace(destination)

    html = index_file.read_text(encoding="utf-8")
    html = html.replace('src="index.js"', f'src="{executable}.js"', 1)
    viewport_meta = '<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">'
    responsive_meta = '<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">'
    if viewport_meta not in html:
        print("Godot Web viewport meta changed; cannot safely configure mobile viewport.", file=sys.stderr)
        return 1
    html = html.replace(viewport_meta, responsive_meta, 1)
    html = html.replace('<link rel="apple-touch-icon" href="index.apple-touch-icon.png"/>', '<link rel="apple-touch-icon" sizes="180x180" href="./index.180x180.png"/>', 1)
    html = html.replace("\t\t<style>\n", '\t\t<meta name="theme-color" content="#bde9ec">\n\t\t<meta name="apple-mobile-web-app-capable" content="yes">\n\t\t<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">\n\t\t<meta name="mobile-web-app-capable" content="yes">\n\t\t<style>\n', 1)
    html = html.replace("\t\t</style>", LAUNCH_CSS + "\n\t\t</style>", 1)
    html = html.replace('\t\t<canvas id="canvas">', LAUNCH_HTML + '\n\t\t<canvas id="canvas">', 1)
    html = html.replace('\t\t<script src="' + executable + '.js"></script>', LAUNCH_SCRIPT + '\n\t\t<script src="' + executable + '.js"></script>', 1)
    html = html.replace('const engine = new Engine(GODOT_CONFIG);', 'const engine = new Engine(GODOT_CONFIG);', 1)
    html = html.replace('function displayFailureNotice(err) {\n\t\tconsole.error(err);', 'function displayFailureNotice(err) {\n\t\tif (window.wonderGameFailed) window.wonderGameFailed();\n\t\tconsole.error(err);', 1)
    old_start = "\t\tengine.startGame({\n\t\t\t'onProgress': function (current, total) {"
    new_start = "\t\twindow.wonderLaunchReady.then(() => engine.startGame({\n\t\t\t'onProgress': function (current, total) {"
    if old_start not in html:
        print("Godot Web startup changed; cannot safely add the mobile start gesture.", file=sys.stderr)
        return 1
    html = html.replace(old_start, new_start, 1)
    close_start = "\t\t}).then(() => {\n\t\t\tsetStatusMode('hidden');"
    open_close = "\t\t})).then(() => {\n\t\t\tif (window.wonderGameReady) window.wonderGameReady();\n\t\t\tsetStatusMode('hidden');"
    if close_start not in html:
        print("Godot Web startup changed; cannot safely connect mobile launch readiness.", file=sys.stderr)
        return 1
    html = html.replace(close_start, open_close, 1)
    # Clear the bounded retry counter only after a successful engine startup.
    html = html.replace("setStatusMode('hidden');", "try { sessionStorage.removeItem('wonder-webgl-retries'); } catch (_) {}\n\t\t\tsetStatusMode('hidden');", 1)
    config_prefix = "const GODOT_CONFIG = "
    config_start = html.find(config_prefix)
    config_end = html.find(";", config_start)
    if config_start < 0 or config_end < 0:
        print("Godot Web startup template changed; cannot version its exported payloads.", file=sys.stderr)
        return 1
    config_text = html[config_start + len(config_prefix):config_end]
    try:
        config = json.loads(config_text)
    except json.JSONDecodeError:
        print("Godot Web startup configuration is not valid JSON.", file=sys.stderr)
        return 1
    commit = os.environ.get("GITHUB_SHA", "")
    version = commit[:7].lower() if re.fullmatch(r"[0-9a-fA-F]{40}", commit) else "local"
    config["args"] = ["--", f"--build-revision={version}"]
    config["executable"] = executable
    config["fileSizes"] = {
        f"{executable}.{extension}": config["fileSizes"][f"index.{extension}"]
        for extension in ("pck", "wasm")
    }
    html = html[:config_start + len(config_prefix)] + json.dumps(config, separators=(",", ":")) + html[config_end:]

    if NEW_NOTICE not in html or NEW_LANGUAGE not in html:
        if OLD_NOTICE not in html or OLD_LANGUAGE not in html:
            print("Godot Web startup template changed; cannot safely localize its fallback.", file=sys.stderr)
            return 1
        html = html.replace(OLD_LANGUAGE, NEW_LANGUAGE, 1)
        html = html.replace(OLD_NOTICE, NEW_NOTICE, 1)
    write_pwa_files(build_dir, build_id)
    version_badge = (f'<div id="build-version" aria-label="游戏版本" '
                     f'style="position:fixed;top:2px;left:50%;transform:translateX(-50%);'
                     f'z-index:10;pointer-events:none;font:11px sans-serif;color:#36574a;'
                     f'background:rgba(255,249,237,.85);border-radius:5px;padding:1px 6px">'
                     f'版本 {version}</div>')
    html = html.replace("</body>", version_badge + "\n</body>", 1)
    index_file.write_text(html, encoding="utf-8")

    # Remove payloads from earlier exports in a reused local build directory.
    for stale_file in build_dir.glob("index-*"):
        if stale_file.suffix in {".js", ".wasm", ".pck"}:
            if stale_file.name not in {path.name for path in renamed_files.values()}:
                stale_file.unlink()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
