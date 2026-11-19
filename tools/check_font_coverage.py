#!/usr/bin/env python3
"""Check printable game text against the font used by the Godot UI."""
from collections import defaultdict
import csv
import io
from pathlib import Path
import re
import sys

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets/fonts/NotoSansCJKsc-Regular.otf"
SUFFIXES = {".gd", ".tscn", ".tres", ".json", ".csv", ".translation", ".po"}
ROOTS = (ROOT / "scripts", ROOT / "scenes", ROOT / "assets", ROOT / "data", ROOT / "localization")
EXTRA_FILES = (ROOT / "project.godot", ROOT / "tools/prepare_web_export.py")
# Capture quoted strings, excluding comments and identifiers. Dynamic text is
# covered by the individual literal fragments plus this runtime character set.
STRING = re.compile(r'''(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')''')
DYNAMIC = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz :.,!?%+-/()[]"


def main() -> int:
    font = TTFont(FONT)
    cmap = font.getBestCmap()
    missing = defaultdict(set)
    for char in DYNAMIC:
        if ord(char) not in cmap:
            missing[char].add("dynamic character list")
    paths = [path for root in ROOTS if root.exists() for path in root.rglob("*")
             if path.is_file() and path.suffix in SUFFIXES]
    paths.extend(path for path in EXTRA_FILES if path.is_file())
    for path in paths:
        try:
            source = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        if path.suffix == ".csv":
            reader = csv.reader(io.StringIO(source))
            for row in reader:
                for field in row:
                    for char in field:
                        if ord(char) > 0x7e and not char.isspace() and ord(char) not in cmap:
                            missing[char].add(f"{path.relative_to(ROOT)}:{reader.line_num}")
            continue
        for match in STRING.finditer(source):
            number = source.count("\n", 0, match.start()) + 1
            for char in match.group()[1:-1]:
                if char == "\n":
                    number += 1
                cp = ord(char)
                # CJK, kana, punctuation, and visible symbols; ASCII
                # is checked above. Paths and code syntax are ignored.
                if cp > 0x7e and not char.isspace() and cp not in cmap:
                    missing[char].add(f"{path.relative_to(ROOT)}:{number}")
    if missing:
        for char, locations in sorted(missing.items(), key=lambda item: ord(item[0])):
            print(f"{char} U+{ord(char):04X} missing from {FONT.relative_to(ROOT)}: {', '.join(sorted(locations))}")
        return 1
    print(f"Font coverage passed: {FONT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
