param(
    [int]$Width = 1280,
    [int]$Height = 720,
    [string]$OutputPath,
    [string]$SavePath,
    [int]$WaitMilliseconds = 5000,
    [string]$GodotPath = "C:\Users\zhuwd\Tools\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64.exe"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectFile = Join-Path $projectRoot "project.godot"
$projectNameMatch = Select-String -LiteralPath $projectFile -Pattern '^config/name="([^"]+)"$' | Select-Object -First 1
if (-not $projectNameMatch) {
    throw "Could not read config/name from: $projectFile"
}
$projectName = $projectNameMatch.Matches[0].Groups[1].Value
$formalSavePath = Join-Path $env:APPDATA ("Godot\app_userdata\{0}\qxisland_stage2_save.json" -f $projectName)

if (-not [string]::IsNullOrWhiteSpace($SavePath)) {
    $normalizedSavePath = [System.IO.Path]::GetFullPath($SavePath)
    $normalizedFormalSavePath = [System.IO.Path]::GetFullPath($formalSavePath)
    if ([System.StringComparer]::OrdinalIgnoreCase.Equals($normalizedSavePath, $normalizedFormalSavePath)) {
        throw "Refusing to run a window capture against the formal save: $formalSavePath"
    }
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    throw "OutputPath is required"
}
if (-not (Test-Path -LiteralPath $GodotPath)) {
    throw "Godot executable not found: $GodotPath"
}
if ($Width -le 0 -or $Height -le 0) {
    throw "Width and Height must be positive"
}
if (Test-Path -LiteralPath $OutputPath) {
    throw "Refusing to overwrite existing screenshot: $OutputPath"
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

if ([string]::IsNullOrWhiteSpace($SavePath)) {
    $SavePath = Join-Path $outputDirectory "window-test-save.json"
}

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class QXIslandWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

function Quote-Argument([string]$Value) {
    return '"' + $Value.Replace('"', '\"') + '"'
}

$argumentParts = @(
    "--path", (Quote-Argument $projectRoot),
    "--windowed", "--resolution", "${Width}x${Height}",
    "--position", "0,0"
)
if (-not [string]::IsNullOrWhiteSpace($SavePath)) {
    $argumentParts += @("--", "--test-save-path", (Quote-Argument $SavePath))
}
$argumentString = $argumentParts -join " "

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $GodotPath
$startInfo.Arguments = $argumentString
$startInfo.UseShellExecute = $false
$startInfo.WorkingDirectory = $projectRoot
$process = [System.Diagnostics.Process]::Start($startInfo)

try {
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 100
        $process.Refresh()
        $windowHandle = $process.MainWindowHandle
    } while ($windowHandle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline -and -not $process.HasExited)

    if ($windowHandle -eq [IntPtr]::Zero) {
        throw "Godot window was not found for PID $($process.Id)"
    }

    Start-Sleep -Milliseconds $WaitMilliseconds
    $process.Refresh()
    if ($process.HasExited) {
        throw "Godot exited before capture, exit code $($process.ExitCode)"
    }

    $oldDpiContext = [QXIslandWindowCapture]::SetThreadDpiAwarenessContext([IntPtr](-4))
    try {
        $clientRect = New-Object QXIslandWindowCapture+RECT
        if (-not [QXIslandWindowCapture]::GetClientRect($windowHandle, [ref]$clientRect)) {
            throw "GetClientRect failed for PID $($process.Id)"
        }
        $clientWidth = $clientRect.Right - $clientRect.Left
        $clientHeight = $clientRect.Bottom - $clientRect.Top
        if ($clientWidth -le 0 -or $clientHeight -le 0) {
            throw "Invalid client size ${clientWidth}x${clientHeight}"
        }

        [QXIslandWindowCapture]::ShowWindow($windowHandle, 5) | Out-Null
        [QXIslandWindowCapture]::SetForegroundWindow($windowHandle) | Out-Null
        Start-Sleep -Milliseconds 250
        if ([QXIslandWindowCapture]::GetForegroundWindow() -ne $windowHandle) {
            throw "Godot window did not become the foreground window; refusing screen capture"
        }

        $bitmap = New-Object System.Drawing.Bitmap($clientWidth, $clientHeight, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb))
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $hdc = $graphics.GetHdc()
                try {
                    $printWindowResult = [QXIslandWindowCapture]::PrintWindow($windowHandle, $hdc, 1)
                } finally {
                    $graphics.ReleaseHdc($hdc)
                }
            } finally {
                $graphics.Dispose()
            }
            if (-not $printWindowResult) {
                throw "PrintWindow failed for PID $($process.Id)"
            }

            $clientOrigin = New-Object QXIslandWindowCapture+POINT
            if (-not [QXIslandWindowCapture]::ClientToScreen($windowHandle, [ref]$clientOrigin)) {
                throw "ClientToScreen failed for PID $($process.Id)"
            }
            $screenGraphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $screenGraphics.CopyFromScreen(
                    $clientOrigin.X,
                    $clientOrigin.Y,
                    0,
                    0,
                    (New-Object System.Drawing.Size($clientWidth, $clientHeight)),
                    [System.Drawing.CopyPixelOperation]::SourceCopy
                )
            } finally {
                $screenGraphics.Dispose()
            }
            $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $bitmap.Dispose()
        }
    } finally {
        [QXIslandWindowCapture]::SetThreadDpiAwarenessContext($oldDpiContext) | Out-Null
    }

    Write-Output "PID=$($process.Id)"
    Write-Output "WINDOW_HANDLE=$windowHandle"
    Write-Output "REQUESTED_SIZE=${Width}x${Height}"
    Write-Output "CLIENT_SIZE=${clientWidth}x${clientHeight}"
    Write-Output "DPI_CONTEXT=PER_MONITOR_AWARE_V2"
    Write-Output "PRINTWINDOW_SUCCESS=$printWindowResult"
    Write-Output "CAPTURE_METHOD=SCREEN_CLIENT_COPY_AFTER_FOREGROUND"
    Write-Output "OUTPUT_PATH=$OutputPath"
    Write-Output "OUTPUT_BYTES=$((Get-Item -LiteralPath $OutputPath).Length)"
} finally {
    if (-not $process.HasExited) {
        $process.Kill()
        $process.WaitForExit(5000) | Out-Null
    }
    $process.Dispose()
}
