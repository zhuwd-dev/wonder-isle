#!/usr/bin/env python3
"""Validate the imported M01-A candidate without changing its source frames."""

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1] / "assets/art/incoming/M01-turtle"
manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
failed = False
rows = []

for item in manifest:
    path = ROOT / item["file"]
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    with Image.open(path) as source:
        image = source.convert("RGBA")
        bbox = image.getbbox()
        alpha = image.getchannel("A")
        alpha_values = len(alpha.getcolors(512 * 512) or [])
        row = {
            "file": item["file"],
            "sha256_ok": digest == item["sha256"],
            "size": image.size,
            "mode": source.mode,
            "bbox": bbox,
            "content_size": [bbox[2] - bbox[0], bbox[3] - bbox[1]],
            "bottom_pixel": bbox[3] - 1,
            "alpha_values": alpha_values,
            "side_margin_min": min(bbox[0], 512 - bbox[2]),
            "vertical_margin_min": min(bbox[1], 512 - bbox[3]),
        }
    rows.append(row)
    valid = (
        row["sha256_ok"]
        and row["size"] == (512, 512)
        and row["mode"] == "RGBA"
        and row["bottom_pixel"] == 440
        and row["side_margin_min"] >= 24
        and row["vertical_margin_min"] >= 24
    )
    failed |= not valid
    print(json.dumps(row, ensure_ascii=False))

heights = [row["content_size"][1] for row in rows]
widths = [row["content_size"][0] for row in rows]
print(json.dumps({
    "frames": len(rows),
    "technical_integrity": "FAIL" if failed else "PASS",
    "bbox_height_range": [min(heights), max(heights)],
    "bbox_height_variation_percent": round((max(heights) / min(heights) - 1) * 100, 2),
    "bbox_width_range": [min(widths), max(widths)],
    "bbox_width_variation_percent": round((max(widths) / min(widths) - 1) * 100, 2),
    "antialiased_alpha": any(row["alpha_values"] > 2 for row in rows),
    "directions_present": ["right"],
    "production_ready": False,
}, ensure_ascii=False))
sys.exit(1 if failed else 0)
