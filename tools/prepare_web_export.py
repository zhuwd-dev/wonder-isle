#!/usr/bin/env python3
"""Localize Godot's Web startup failure and explain how to enable WebGL2."""

from __future__ import annotations

import sys
from pathlib import Path


OLD_LANGUAGE = '<html lang="en">'
NEW_LANGUAGE = '<html lang="zh-CN">'
OLD_NOTICE = (
    "const missingMsg = 'Error\\nThe following features required to run Godot projects on the Web are missing:\\n';\n"
    "\t\t\tdisplayFailureNotice(missingMsg + missing.join('\\n'));"
)
NEW_NOTICE = """const missingMsg = '启动失败：当前浏览器环境缺少运行游戏所需的功能：\\n';
\t\t\tdisplayFailureNotice(missingMsg + missing.map((feature) =>
\t\t\t\tfeature.startsWith('WebGL2') ? 'WebGL2（浏览器图形加速）' : feature
\t\t\t).join('\\n') + '\\n\\n请使用最新版 Chrome 或 Edge。\\n' +
\t\t\t'Chrome：chrome://settings/system；Edge：edge://settings/system\\n' +
\t\t\t'开启“使用图形加速（如果可用）”后完全重启浏览器。\\n' +
\t\t\t'仍无法启动时，请在 chrome://gpu 或 edge://gpu 中检查 WebGL2 状态。');"""


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: prepare_web_export.py <web-export-directory>", file=sys.stderr)
        return 2

    index_file = Path(sys.argv[1]) / "index.html"
    if not index_file.is_file():
        print(f"Web export not found: {index_file}", file=sys.stderr)
        return 2

    html = index_file.read_text(encoding="utf-8")
    if NEW_NOTICE in html and NEW_LANGUAGE in html:
        return 0
    if OLD_NOTICE not in html or OLD_LANGUAGE not in html:
        print("Godot Web startup template changed; cannot safely localize its fallback.", file=sys.stderr)
        return 1

    html = html.replace(OLD_LANGUAGE, NEW_LANGUAGE, 1)
    html = html.replace(OLD_NOTICE, NEW_NOTICE, 1)
    index_file.write_text(html, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
