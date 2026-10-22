#!/usr/bin/env python3
"""Run the project's GDScript regression cases with one isolated temporary save."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PINNED_GODOT = Path("/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64")
ERROR_MARKER = re.compile(r"ERROR:|SCRIPT ERROR|Parse Error")


def regression_cases(save_path: Path) -> list[tuple[str, str, list[str]]]:
    cases: list[tuple[str, str, list[str]]] = []

    def add(label: str, script: str, args: tuple[str, ...] = ()) -> None:
        cases.append((label, script, list(args)))

    def save_test(label: str, script: str, args: tuple[str, ...] = ()) -> None:
        add(label, script, (*args, "--test-save-path", str(save_path)))

    add("save-path", "test_save_path_isolation.gd", ("--", "--test-save-path", str(save_path)))
    add("gamestate", "test_game_state.gd")
    save_test("graybox", "test_graybox_collision.gd", ("--",))
    save_test("runtime-flow", "test_runtime_flow.gd", ("--",))

    for quest, modes in {
        "q004": [],
        "q005": ["write-watered", "read-watered", "write-partial", "read-partial", "write-complete", "read-complete", "read-reset"],
        "q006": ["write-partial", "read-partial", "write-complete", "read-complete", "write-moved", "read-moved", "write-removed", "read-removed", "read-reset"],
        "q007": ["write-unlocked", "read-unlocked", "write-complete", "read-complete", "read-reset"],
        "q008": ["write-partial", "read-partial", "write-complete", "read-complete", "read-reset"],
        "q009": ["write-partial", "read-partial", "write-complete", "read-complete", "read-reset"],
        "q010": ["write-partial", "read-partial", "read-partial-two", "read-complete", "read-reset"],
        "q011": ["write-partial", "read-partial", "read-partial-two", "read-complete", "read-reset"],
    }.items():
        add(f"{quest}-state", f"test_{quest}_state.gd")
        save_test(f"{quest}-runtime", f"test_{quest}_runtime.gd", ("--",))
        for mode in modes:
            save_test(f"{quest}-disk-{mode}", f"test_{quest}_disk_cycle.gd", ("--", mode))

    for label, mode in [
        ("disk-pond-progress-write", "write-pond-progress"),
        ("disk-pond-progress-read", "read-pond-progress"),
        ("disk-q004-progress-write", "write-q004-progress"),
        ("disk-q004-progress-read", "read-q004-progress"),
        ("disk-q004-complete-write", "write-q004-complete"),
        ("disk-q004-complete-read", "read-q004-complete"),
        ("disk-all-complete-write", "write-all-complete"),
        ("disk-write", "write"),
        ("disk-read", "read"),
        ("disk-final-read", "final-read"),
    ]:
        save_test(label, "test_disk_save_cycle.gd", ("--", mode))
    save_test("disk-probe", "probe_disk_load.gd", ("--",))

    if len(cases) != 72:
        raise AssertionError(f"Expected 72 regression cases, found {len(cases)}")
    return cases


def find_godot(explicit_path: str | None) -> Path:
    configured = explicit_path or os.environ.get("GODOT_BIN")
    if configured:
        candidate = Path(configured).expanduser()
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return candidate
        raise SystemExit(f"Godot executable not found or not executable: {candidate}")
    if PINNED_GODOT.is_file() and os.access(PINNED_GODOT, os.X_OK):
        return PINNED_GODOT
    for command in ("godot", "godot4"):
        found = shutil.which(command)
        if found:
            return Path(found)
    raise SystemExit("Godot is required. Set GODOT_BIN to the Godot 4.7.2 executable.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot-bin", help="Godot executable; defaults to GODOT_BIN or the pinned cloud binary")
    options = parser.parse_args()

    godot = find_godot(options.godot_bin)
    version = subprocess.run([str(godot), "--version"], check=True, text=True, capture_output=True).stdout.strip()
    if not version.startswith("4.7.2.stable.official."):
        raise SystemExit(f"Expected Godot 4.7.2; found {version}")

    test_root = Path(tempfile.mkdtemp(prefix="wonder-isle-tests-", dir="/tmp"))
    save_path = test_root / "qxisland_stage2_save.json"
    env = os.environ.copy()
    env.setdefault("XDG_DATA_HOME", "/tmp/wonder-isle-godot-data")
    env.setdefault("XDG_CONFIG_HOME", "/tmp/wonder-isle-godot-config")
    env.setdefault("XDG_CACHE_HOME", "/tmp/wonder-isle-godot-cache")
    Path(env["XDG_DATA_HOME"]).mkdir(parents=True, exist_ok=True)
    Path(env["XDG_CONFIG_HOME"]).mkdir(parents=True, exist_ok=True)
    (Path(env["XDG_CACHE_HOME"]) / "fontconfig").mkdir(parents=True, exist_ok=True)

    failures: list[tuple[str, int, str]] = []
    base_command = [str(godot), "--headless", "--path", str(ROOT)]
    cases = regression_cases(save_path)
    for index, (label, script, args) in enumerate(cases, start=1):
        command = [*base_command, "--script", f"res://tests/{script}", *args]
        completed = subprocess.run(
            command,
            cwd=ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        (test_root / f"{label}.log").write_text(completed.stdout)
        failed = completed.returncode != 0 or ERROR_MARKER.search(completed.stdout) is not None
        print(f"{index:02}/{len(cases)} {label}: {'FAIL' if failed else 'PASS'}")
        if failed:
            failures.append((label, completed.returncode, completed.stdout))

    if not save_path.is_file():
        failures.append(("isolated-save-missing", 1, str(save_path)))

    print(f"Godot={version}")
    print(f"isolated_test_save={save_path}")
    print(f"test_logs={test_root}")
    print(f"passed={len(cases) - len(failures)} failed={len(failures)}")
    if failures:
        for label, exit_code, output in failures:
            print(f"--- {label} exit={exit_code} ---\n{output}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
