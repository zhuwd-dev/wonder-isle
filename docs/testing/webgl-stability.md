# Web stability diagnostic (2026-11-04)

Status: **PARTIAL / P0 unresolved**. This run did not reproduce a page crash or WebGL context loss, but it did show high, fluctuating renderer memory. It cannot establish stability on a user's Windows GPU.

## Environment and run

- Debian 13, Chromium 154.0.8037.57, headless.
- WebGL2 was available through ANGLE / Vulkan SwiftShader software rendering. `/dev/dri` was absent; no hardware GPU path was available.
- One game page plus three ordinary local static tabs, 1280×720.
- Static phase completed 30 minutes. Active phase was interrupted at 13 minutes 6 seconds (target: 20 minutes); it exercised movement input, zoom and menu clicks. Five post-run reloads were therefore not reached.
- During this run the canvas remained present; no `webglcontextlost`/`webglcontextrestored`, console, page, or page-crash events were recorded.

## Memory observations

The browser process-tree RSS ranged from about 1.16 GiB at the first sample to 1.90 GiB at the static-phase peak, then reached 2.40 GiB during active input. JS heap samples were highly variable: 37–612 MiB during the static phase and 418 MiB–1.08 GiB during the active phase. The last sample was about 1.00 GiB JS heap and 2.36 GiB process-tree RSS. Some peaks receded, but the elevated usage and renderer growth remain a risk signal; this run cannot distinguish a leak from Chromium/SwiftShader/Godot allocator high-water behavior.

Raw JSONL: `/tmp/wonder-isle-web-stability-20261104.jsonl` (local diagnostic output). Screenshots: `tests/artifacts/p0-stability-20261104/start.png` and `idle-end.png` (ignored test artifacts).

## Export correction

The Web preset previously exported `all_resources` without excluding `tests/**`; the test artifacts directory contains hundreds of MiB of screenshots and recordings. The resource pack was about 262 MiB before correction. The preset now excludes `tests/**`; the latest PCK was 9,785,072 bytes (about 9.4 MiB), and a 64 MiB guard prevents accidentally packaging test artifacts again. This is a demonstrated export-size correction, not proof that it caused the reported browser-wide failure.

## Remaining work

- Repeat a full 30-minute idle + 20-minute active run and five reloads with the final Web export.
- Compare the same build in hardware-accelerated Chrome/Edge on the user's machine and collect `chrome://version`, `chrome://gpu`, and browser/GPU-process behavior if unrelated tabs blank or reload.
- Do not claim the reported Windows/GPU failure is resolved until that environment is tested or the memory growth is isolated.
