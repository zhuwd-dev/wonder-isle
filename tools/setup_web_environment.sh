#!/usr/bin/env bash
set -euo pipefail

install_dir="${GODOT_INSTALL_DIR:-/tmp/wonder-isle-godot-4.7.2}"
xdg_data_home="${XDG_DATA_HOME:-/tmp/wonder-isle-godot-data}"
xdg_config_home="${XDG_CONFIG_HOME:-/tmp/wonder-isle-godot-config}"
xdg_cache_home="${XDG_CACHE_HOME:-/tmp/wonder-isle-godot-cache}"
web_test_venv="${WEB_TEST_VENV:-/tmp/wonder-isle-web-test-venv}"
playwright_browsers_path="${PLAYWRIGHT_BROWSERS_PATH:-/tmp/wonder-isle-playwright-browsers}"

archive_name=Godot_v4.7.2-stable_linux.x86_64.zip
template_archive_name=Godot_v4.7.2-stable_export_templates.tpz
checksum_file="$install_dir/SHA512-SUMS.txt"
archive="$install_dir/$archive_name"
binary="$install_dir/Godot_v4.7.2-stable_linux.x86_64"
template_archive="$install_dir/$template_archive_name"
template_dir="$xdg_data_home/godot/export_templates/4.7.2.stable"

mkdir -p "$install_dir" "$template_dir" "$xdg_config_home" "$xdg_cache_home/fontconfig"
mkdir -p "$playwright_browsers_path" /tmp/wonder-isle-pip-cache
export XDG_DATA_HOME="$xdg_data_home"
export XDG_CONFIG_HOME="$xdg_config_home"
export XDG_CACHE_HOME="$xdg_cache_home"
export PIP_CACHE_DIR=/tmp/wonder-isle-pip-cache
export PLAYWRIGHT_BROWSERS_PATH="$playwright_browsers_path"

curl -fsSL --proto '=https' --tlsv1.2 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt' -o "$checksum_file"

awk -v name="$archive_name" '$2 == name { print; found = 1 } END { if (!found) exit 1 }' "$checksum_file" > "$install_dir/archive.sha512"
if [[ ! -s "$archive" ]]; then
	curl -fL --proto '=https' --tlsv1.2 --retry 2 "https://github.com/godotengine/godot/releases/download/4.7.2-stable/$archive_name" -o "$archive"
fi
(cd "$install_dir" && sha512sum --check archive.sha512)
if [[ ! -x "$binary" ]]; then
	unzip -oq "$archive" -d "$install_dir"
fi
version_output=$("$binary" --version)
[[ "$version_output" == '4.7.2.stable.official.ed1daf0bf' ]]

if [[ ! -s "$template_dir/web_nothreads_release.zip" || ! -s "$template_dir/version.txt" ]]; then
	awk -v name="$template_archive_name" '$2 == name { print; found = 1 } END { if (!found) exit 1 }' "$checksum_file" > "$install_dir/templates.sha512"
	if [[ ! -s "$template_archive" ]]; then
		curl -fL --proto '=https' --tlsv1.2 --retry 2 "https://github.com/godotengine/godot/releases/download/4.7.2-stable/$template_archive_name" -o "$template_archive"
	fi
	(cd "$install_dir" && sha512sum --check templates.sha512)
	unzip -oqj "$template_archive" templates/version.txt templates/icudt_godot.dat templates/web_nothreads_release.zip -d "$template_dir"
	[[ "$(cat "$template_dir/version.txt")" == '4.7.2.stable' ]]
	rm -f "$template_archive"
fi

if [[ ! -x "$web_test_venv/bin/python" ]]; then
	python3 -m venv "$web_test_venv"
fi
"$web_test_venv/bin/python" -m pip install --disable-pip-version-check --requirement "$(dirname -- "${BASH_SOURCE[0]}")/requirements-web-test.txt"
if ! command -v chromium >/dev/null 2>&1 && ! command -v chromium-browser >/dev/null 2>&1; then
	"$web_test_venv/bin/python" -m playwright install chromium
fi

printf 'Godot %s, Web export templates, Python Playwright, and Chromium are ready.\n' "$version_output"
