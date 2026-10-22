$ErrorActionPreference = "Stop"

$project_root = Split-Path -Parent $PSScriptRoot
$godot_path = "C:\Users\zhuwd\Tools\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe"
$app_userdata_root = Join-Path $env:APPDATA "Godot\app_userdata"
$project_config_path = Join-Path $project_root "project.godot"
$project_config_text = [System.IO.File]::ReadAllText($project_config_path, [System.Text.UTF8Encoding]::new($false))
$project_name_match = [regex]::Match($project_config_text, 'config/name="([^"]+)"')
if (-not $project_name_match.Success) {
	throw "Could not read project name from project.godot"
}
$project_name = $project_name_match.Groups[1].Value
$formal_save_path = Join-Path (Join-Path $app_userdata_root $project_name) "qxisland_stage2_save.json"

if (-not (Test-Path -LiteralPath $godot_path)) {
	throw "Godot executable not found: $godot_path"
}
if (-not (Test-Path -LiteralPath $formal_save_path)) {
	throw "Formal save not found: $formal_save_path"
}

$test_root = Join-Path $env:TEMP ("QXIsland-isolated-tests-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $test_root | Out-Null
$test_save_path = Join-Path $test_root "qxisland_stage2_save.json"
$formal_hash_before = (Get-FileHash -Algorithm SHA256 -LiteralPath $formal_save_path).Hash

function Invoke-IsolatedGodotTest {
	param(
		[string]$Label,
		[string[]]$Arguments
	)

	$out_path = Join-Path $test_root ($Label + ".out.log")
	$err_path = Join-Path $test_root ($Label + ".err.log")
	$process = Start-Process `
		-FilePath $godot_path `
		-ArgumentList $Arguments `
		-Wait `
		-PassThru `
		-RedirectStandardOutput $out_path `
		-RedirectStandardError $err_path

	Write-Output ("--- {0} EXIT_CODE={1} ---" -f $Label, $process.ExitCode)
	if (Test-Path -LiteralPath $out_path) {
		Get-Content -LiteralPath $out_path
	}
	if (Test-Path -LiteralPath $err_path) {
		Get-Content -LiteralPath $err_path
	}
	if ($process.ExitCode -ne 0) {
		throw "$Label failed with exit code $($process.ExitCode)"
	}
}

$base_arguments = @("--headless", "--path", $project_root)

Invoke-IsolatedGodotTest "save-path" ($base_arguments + @(
	"--script", "res://tests/test_save_path_isolation.gd",
	"--", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "gamestate" ($base_arguments + @(
	"--script", "res://tests/test_game_state.gd"
))

Invoke-IsolatedGodotTest "graybox" ($base_arguments + @(
	"--script", "res://tests/test_graybox_collision.gd",
	"--", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "runtime-flow" ($base_arguments + @(
	"--script", "res://tests/test_runtime_flow.gd",
	"--", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "q004-state" ($base_arguments + @(
	"--script", "res://tests/test_q004_state.gd"
))

Invoke-IsolatedGodotTest "q004-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q004_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "q005-state" ($base_arguments + @(
	"--script", "res://tests/test_q005_state.gd"
))

Invoke-IsolatedGodotTest "q005-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q005_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "q006-state" ($base_arguments + @(
	"--script", "res://tests/test_q006_state.gd"
))

Invoke-IsolatedGodotTest "q006-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q006_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

foreach ($q006Mode in @("write-partial", "read-partial", "write-complete", "read-complete", "write-moved", "read-moved", "write-removed", "read-removed", "read-reset")) {
	Invoke-IsolatedGodotTest ("q006-disk-" + $q006Mode) ($base_arguments + @(
		"--script", "res://tests/test_q006_disk_cycle.gd",
		"--", $q006Mode, "--test-save-path", $test_save_path
	))
}

Invoke-IsolatedGodotTest "q007-state" ($base_arguments + @(
	"--script", "res://tests/test_q007_state.gd"
))

Invoke-IsolatedGodotTest "q007-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q007_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

foreach ($q007Mode in @("write-unlocked", "read-unlocked", "write-complete", "read-complete", "read-reset")) {
	Invoke-IsolatedGodotTest ("q007-disk-" + $q007Mode) ($base_arguments + @(
		"--script", "res://tests/test_q007_disk_cycle.gd",
		"--", $q007Mode, "--test-save-path", $test_save_path
	))
}

Invoke-IsolatedGodotTest "q008-state" ($base_arguments + @(
	"--script", "res://tests/test_q008_state.gd"
))

Invoke-IsolatedGodotTest "q008-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q008_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

foreach ($q008Mode in @("write-partial", "read-partial", "write-complete", "read-complete", "read-reset")) {
	Invoke-IsolatedGodotTest ("q008-disk-" + $q008Mode) ($base_arguments + @(
		"--script", "res://tests/test_q008_disk_cycle.gd",
		"--", $q008Mode, "--test-save-path", $test_save_path
	))
}

Invoke-IsolatedGodotTest "q009-state" ($base_arguments + @(
	"--script", "res://tests/test_q009_state.gd"
))

Invoke-IsolatedGodotTest "q009-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q009_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

foreach ($q009Mode in @("write-partial", "read-partial", "write-complete", "read-complete", "read-reset")) {
	Invoke-IsolatedGodotTest ("q009-disk-" + $q009Mode) ($base_arguments + @(
		"--script", "res://tests/test_q009_disk_cycle.gd",
		"--", $q009Mode, "--test-save-path", $test_save_path
	))
}

Invoke-IsolatedGodotTest "q010-state" ($base_arguments + @(
	"--script", "res://tests/test_q010_state.gd"
))

Invoke-IsolatedGodotTest "q010-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q010_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

foreach ($q010Mode in @("write-partial", "read-partial", "read-partial-two", "read-complete", "read-reset")) {
	Invoke-IsolatedGodotTest ("q010-disk-" + $q010Mode) ($base_arguments + @(
		"--script", "res://tests/test_q010_disk_cycle.gd",
		"--", $q010Mode, "--test-save-path", $test_save_path
	))
}

Invoke-IsolatedGodotTest "q011-state" ($base_arguments + @(
	"--script", "res://tests/test_q011_state.gd"
))

Invoke-IsolatedGodotTest "q011-runtime" ($base_arguments + @(
	"--script", "res://tests/test_q011_runtime.gd",
	"--", "--test-save-path", $test_save_path
))

foreach ($q011Mode in @("write-partial", "read-partial", "read-partial-two", "read-complete", "read-reset")) {
	Invoke-IsolatedGodotTest ("q011-disk-" + $q011Mode) ($base_arguments + @(
		"--script", "res://tests/test_q011_disk_cycle.gd",
		"--", $q011Mode, "--test-save-path", $test_save_path
	))
}

foreach ($q005Mode in @("write-watered", "read-watered", "write-partial", "read-partial", "write-complete", "read-complete", "read-reset")) {
	Invoke-IsolatedGodotTest ("q005-disk-" + $q005Mode) ($base_arguments + @(
		"--script", "res://tests/test_q005_disk_cycle.gd",
		"--", $q005Mode, "--test-save-path", $test_save_path
	))
}

Invoke-IsolatedGodotTest "disk-pond-progress-write" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "write-pond-progress", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-pond-progress-read" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "read-pond-progress", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-q004-progress-write" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "write-q004-progress", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-q004-progress-read" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "read-q004-progress", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-q004-complete-write" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "write-q004-complete", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-q004-complete-read" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "read-q004-complete", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-all-complete-write" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "write-all-complete", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-write" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "write", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-read" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "read", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-final-read" ($base_arguments + @(
	"--script", "res://tests/test_disk_save_cycle.gd",
	"--", "final-read", "--test-save-path", $test_save_path
))

Invoke-IsolatedGodotTest "disk-probe" ($base_arguments + @(
	"--script", "res://tests/probe_disk_load.gd",
	"--", "--test-save-path", $test_save_path
))

if (-not (Test-Path -LiteralPath $test_save_path)) {
	throw "Isolated test save was not created: $test_save_path"
}

$formal_hash_after = (Get-FileHash -Algorithm SHA256 -LiteralPath $formal_save_path).Hash
Write-Output ("TEST_ROOT={0}" -f $test_root)
Write-Output ("TEST_SAVE_PATH={0}" -f $test_save_path)
Write-Output ("FORMAL_SAVE_BEFORE={0}" -f $formal_hash_before)
Write-Output ("FORMAL_SAVE_AFTER={0}" -f $formal_hash_after)
Write-Output ("TEST_SAVE_SHA256={0}" -f (Get-FileHash -Algorithm SHA256 -LiteralPath $test_save_path).Hash)

if ($formal_hash_before -ne $formal_hash_after) {
	throw "Formal save changed during isolated tests"
}

Write-Output "ISOLATED_TESTS_PASS"
