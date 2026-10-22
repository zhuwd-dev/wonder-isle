param(
    [int]$Width = 1280,
    [int]$Height = 720,
    [string]$TestRoot,
    [string]$GodotPath = "C:\Users\zhuwd\Tools\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectFile = Join-Path $projectRoot "project.godot"

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "project.godot not found under: $projectRoot"
}

$projectNameMatch = Select-String -LiteralPath $projectFile -Pattern '^config/name="([^"]+)"$' | Select-Object -First 1
if (-not $projectNameMatch) {
    throw "Could not read config/name from: $projectFile"
}
$projectName = $projectNameMatch.Matches[0].Groups[1].Value
$formalSavePath = Join-Path $env:APPDATA ("Godot\app_userdata\{0}\qxisland_stage2_save.json" -f $projectName)

if (-not (Test-Path -LiteralPath $GodotPath)) {
    throw "Godot executable not found: $GodotPath"
}
if (-not (Test-Path -LiteralPath $formalSavePath)) {
    throw "Formal save not found: $formalSavePath"
}
if ($Width -le 0 -or $Height -le 0) {
    throw "Width and Height must be positive"
}

$existingGodot = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "Godot*" }
if ($existingGodot) {
    $ids = ($existingGodot | Select-Object -ExpandProperty Id) -join ", "
    throw "A Godot process is already running (PID $ids). Close or identify it before manual play."
}

$formalHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $formalSavePath).Hash
if ([string]::IsNullOrWhiteSpace($TestRoot)) {
    $TestRoot = Join-Path $env:TEMP ("QXIsland-manual-play-" + [guid]::NewGuid().ToString("N"))
} elseif (Test-Path -LiteralPath $TestRoot) {
    throw "Refusing to reuse an existing manual-play directory: $TestRoot"
}

New-Item -ItemType Directory -Path $TestRoot | Out-Null
$testSavePath = Join-Path $TestRoot "qxisland_stage2_save.json"
$stdoutPath = Join-Path $TestRoot "godot.stdout.log"
$stderrPath = Join-Path $TestRoot "godot.stderr.log"

function Quote-Argument([string]$Value) {
    return '"' + $Value.Replace('"', '\"') + '"'
}

$argumentParts = @(
    "--path", (Quote-Argument $projectRoot),
    "--windowed", "--resolution", "${Width}x${Height}",
    "--position", "0,0",
    "--", "--test-save-path", (Quote-Argument $testSavePath)
)
$argumentString = $argumentParts -join " "

Write-Output "PROJECT_ROOT=$projectRoot"
Write-Output "GODOT_PATH=$GodotPath"
Write-Output "PROJECT_NAME=$projectName"
Write-Output "REQUESTED_WINDOW=${Width}x${Height}"
Write-Output "FORMAL_SAVE_PATH=$formalSavePath"
Write-Output "FORMAL_SAVE_SHA256_BEFORE=$formalHashBefore"
Write-Output "TEST_ROOT=$TestRoot"
Write-Output "TEST_SAVE_PATH=$testSavePath"
Write-Output "GODOT_STDOUT_LOG=$stdoutPath"
Write-Output "GODOT_STDERR_LOG=$stderrPath"
Write-Output "GODOT_ARGUMENTS=$argumentString"

if ($DryRun) {
    Write-Output "DRY_RUN=TRUE"
    exit 0
}

Write-Output "MANUAL_PLAY_START=Close the Godot window after completing the manual play flow."

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $GodotPath
$startInfo.Arguments = $argumentString
$startInfo.WorkingDirectory = $projectRoot
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.CreateNoWindow = $false

$process = [System.Diagnostics.Process]::Start($startInfo)
try {
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdoutTask.Wait()
    $stderrTask.Wait()
    [System.IO.File]::WriteAllText($stdoutPath, $stdoutTask.Result)
    [System.IO.File]::WriteAllText($stderrPath, $stderrTask.Result)

    Write-Output "GODOT_PID=$($process.Id)"
    Write-Output "GODOT_EXIT_CODE=$($process.ExitCode)"
} finally {
    $process.Dispose()
}

$formalHashAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $formalSavePath).Hash
$testSaveExists = Test-Path -LiteralPath $testSavePath
Write-Output "FORMAL_SAVE_SHA256_AFTER=$formalHashAfter"
Write-Output "TEST_SAVE_EXISTS=$testSaveExists"

if ($formalHashBefore -ne $formalHashAfter) {
    Write-Error "Formal save changed during manual play: $formalSavePath"
    exit 1
}
if (-not $testSaveExists) {
    Write-Error "Manual play did not create an isolated test save: $testSavePath"
    exit 1
}

Write-Output "FORMAL_SAVE_UNCHANGED=TRUE"
Write-Output "MANUAL_PLAY_SESSION_COMPLETE=TRUE"
exit 0
