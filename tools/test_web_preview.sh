#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/wonder-isle-godot-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/wonder-isle-godot-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/wonder-isle-godot-cache}"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/tmp/wonder-isle-playwright-browsers}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME/fontconfig"

if [[ -z "${GODOT_BIN:-}" ]]; then
	if [[ -x /tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 ]]; then
		GODOT_BIN=/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
	else
		GODOT_BIN="$(command -v godot || command -v godot4 || true)"
	fi
fi

if [[ -z "${GODOT_BIN:-}" || ! -x "$GODOT_BIN" ]]; then
	echo "Godot 4.7.2 is required. Set GODOT_BIN to the Godot 4.7.2 executable." >&2
	exit 2
fi
export GODOT_BIN

godot_version="$("$GODOT_BIN" --version)"
if [[ "$godot_version" != 4.7.2.stable.official.* ]]; then
	echo "Expected Godot 4.7.2; found $godot_version. Set GODOT_BIN to the pinned executable." >&2
	exit 2
fi

build_dir="${WEB_BUILD_DIR:-$project_root/build/web}"
mkdir -p "$build_dir"
"$GODOT_BIN" --headless --path "$project_root" --export-release Web "$build_dir/index.html"
"${PYTHON_BIN:-python3}" "$project_root/tools/prepare_web_export.py" "$build_dir"

python_bin="${PYTHON_BIN:-python3}"
if [[ -x /tmp/wonder-isle-web-test-venv/bin/python && -z "${PYTHON_BIN:-}" ]]; then
	python_bin=/tmp/wonder-isle-web-test-venv/bin/python
fi
if ! "$python_bin" -c 'import playwright.sync_api' >/dev/null 2>&1; then
	echo "Python Playwright is required. Install tools/requirements-web-test.txt into your test environment." >&2
	exit 2
fi

if [[ -z "${CHROMIUM_PATH:-}" ]]; then
	CHROMIUM_PATH="$(command -v chromium || command -v chromium-browser || true)"
fi
if [[ -n "$CHROMIUM_PATH" ]]; then
	export CHROMIUM_PATH
fi

"$python_bin" "$project_root/tools/test_web_preview.py" "$build_dir"
