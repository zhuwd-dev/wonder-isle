#!/usr/bin/env python3
"""Refresh the project's compact UI font subset from the licensed upstream font."""

from __future__ import annotations

import hashlib
import tempfile
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parent.parent
FONT_PATH = ROOT / "assets/fonts/NotoSansCJKsc-GameSubset.otf"
UPSTREAM_URL = (
    "https://raw.githubusercontent.com/notofonts/noto-cjk/"
    "main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf"
)
UPSTREAM_SHA256 = "2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b"
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".cfg", ".godot"}


def source_codepoints() -> set[int]:
    codepoints = set(range(0x20, 0x7F))
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in TEXT_SUFFIXES:
            continue
        if any(part in {".git", ".godot", "build"} for part in path.parts):
            continue
        codepoints.update(ord(character) for character in path.read_text(errors="ignore"))
    return codepoints


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="wonder-isle-font-") as temp_dir:
        upstream_path = Path(temp_dir) / "NotoSansCJKsc-Regular.otf"
        urllib.request.urlretrieve(UPSTREAM_URL, upstream_path)
        digest = hashlib.sha256(upstream_path.read_bytes()).hexdigest()
        if digest != UPSTREAM_SHA256:
            raise SystemExit(f"Unexpected upstream font checksum: {digest}")

        font = TTFont(upstream_path)
        options = subset.Options()
        options.recommended_glyphs = True
        options.layout_features = ["*"]
        font_subsetter = subset.Subsetter(options=options)
        requested = source_codepoints()
        font_subsetter.populate(unicodes=requested)
        font_subsetter.subset(font)
        font.save(FONT_PATH)
        print(f"Wrote {FONT_PATH.relative_to(ROOT)} ({FONT_PATH.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
