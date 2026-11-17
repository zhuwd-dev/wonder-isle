"""Shared save namespace paths for production and isolated preview browser tests."""

from __future__ import annotations

import os


PREVIEW = os.environ.get("WONDER_ISLE_PREVIEW", "").lower() in {"1", "true", "yes"}
SAVE_NAMESPACE = "preview" if PREVIEW else "production"
SAVE_FILE = "qxisland_stage2_save_preview.json" if PREVIEW else "qxisland_stage2_save.json"
SAVE_KEY = f"/userfs/godot/app_userdata/奇趣小岛/{SAVE_FILE}"
MIRROR_KEY = "wonder-isle-save-preview-v2" if PREVIEW else "wonder-isle-save-v1"

