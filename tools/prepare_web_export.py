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
