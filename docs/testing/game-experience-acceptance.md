# Game experience acceptance

Baseline checked on 2026-11-04 before Batch A changes.

| ID | Problem | Current behavior | Root cause found in current source/assets | Target | Evidence required | Status |
|---|---|---|---|---|---|---|
| P01 | Mouse movement animation | The player now faces the correct cardinal direction while moving and after stopping; motion still has no real step cycle. | Four approved idle views now load from `mouse-idle-frames.tres`; the full animation switch stays disabled because all 24 walk frames are absent. `player_animation.gd` falls back from a missing walk cycle to the matching idle view. | Four correct idle directions and actual four-direction steps, with unchanged feet/collision anchor. | Batch B screenshots prove direction/ground anchor; actual step-cycle and bridge-walk footage still requires the 24 walk frames. | PARTIAL / IDLE_VISUAL_PASS / WALK_ASSET_REQUIRED |
| P02 | Turtle movement and grounded pose | Turtle stays at one habitat point, in the existing upright planted pose. | `scripts/boot/main.gd::_keep_turtle_at_habitat` deliberately prevents sliding; only `assets/art/characters/turtle.png` exists. `docs/art/turtle-animation-status.md` requires a new grounded idle and crawl set. | Grounded natural idle, crawl/turn cycle, pause and face player for Q005 handoff. | Idle image, crawl/turn/handoff video, save reload. | PARTIAL / ASSET_REQUIRED |
| P03 | Reposition Q006 decorations | Existing items could move in build mode, but after Q006 completed the build button was hidden and `_toggle_build_mode` rejected entry until Q012 completed. Tap-vs-drag used an 8 world-unit threshold. | `scripts/boot/main.gd::_refresh_build_controls`, `_toggle_build_mode`, and pointer motion branch. Completion disabled editing; threshold changed with zoom instead of screen pixels. | Place, move, recover, replace, refresh, then move again. Invalid drops preserve their saved position. | Batch A browser checks and two recordings below verify mouse flow, including Q006 complete/Q012 pending and refresh. Touch device is still untested. | FUNCTION_PASS / VISUAL_PASS (mouse); touch NOT TESTED |
| P04 | Rabbit yellow pulse ring | A large animated yellow ring and star appeared when Q012 could start. | `scripts/boot/main.gd::_draw_rabbit_area`, gated by `game_state.can_start_q012()`. The right action button and task prompt already provide the celebration instruction. | Natural idle; let the named right-side action and task prompt guide the player without a permanent ring. | `web-q006-adjust-before-celebration.png` and `web-q006-after-refresh-drag.png` show Q012 pending with no rabbit ring. | VISUAL_PASS for Q012 pending; other task phases NOT TESTED in this batch |
| P05 | Fox after house completion | Fox stayed outside the completed cottage indefinitely. | `_draw_q004_area` always drew the fox after Q004 completion; Q009 uses birdhouse/material state and does not need the fox. | Show a brief move-in greeting, then indicate the fox is home; greet again when the player visits the cottage and appear during the ending celebration. | Browser asserts far/near state and captures `web-fox-at-home-away-from-player.png` and `web-fox-greets-at-cottage.png`; isolated Q004 and Q009 regression passed. | FUNCTION_PASS / VISUAL_PASS |
| P06 | Living map | Some tiny ambient motion already exists: petals drift, grass/leaves sway, river glints and pond lines animate. The backdrop remains a single JPEG; no cloud-shadow pass or convincing masked water flow is present. | `_draw_background`, `_draw_grass`, `_draw_leaf_cluster`, and pond drawing in `scripts/boot/main.gd`; no dynamic environment layer/resource. | Add a restrained, bounded water/pond/leaf/cloud effect layer without moving the background or altering collisions. | Real game clips for water, pond, leaves and cloud shadow with effects on/off. | PARTIAL |
| P07 | WebGL stability | A previous 30-minute idle/13-minute active SwiftShader run did not lose context, but memory was high and active phase ended early. Windows hardware-GPU issue remains unresolved. | `docs/testing/webgl-stability.md`: JS heap peaked around 1.08 GiB and browser process tree around 2.40 GiB; no hardware GPU available. | Compare static/dynamic and effects-off/on memory, frame time, context loss and reload; hardware-specific status must remain honest. | Timed logs, FPS/frame-time, context events, reload evidence; Windows Chrome if available. | PARTIAL / BLOCKED |

## Batch A acceptance record

Build tested: fresh local Web export from the current worktree, Godot 4.7.2, Chromium WebGL2/SwiftShader, 1280×720. No browser errors or failed requests.

| Check | Result | Evidence |
|---|---|---|
| Q006 move between islands, recover by tap, replace from tray | PASS | `tests/artifacts/experience-batch-a-20261104/web-q006-cottage-fence.png`, `web-q006-direct-collect.png`, `web-q006-replaced-fence.png` |
| Q006 complete while Q012 is pending: reopen editing and move | PASS | `tests/artifacts/experience-batch-a-20261104/q006-pending-ending-video/q006-pending-ending.webm` |
| Q006 movement persisted across refresh, then moved again | PASS | `tests/artifacts/experience-batch-a-20261104/q006-pending-ending-video/q006-after-refresh.webm`; saved coordinate verified as `[410, 472]`, `q012_completed=false` |
| Tap jitter vs deliberate drag threshold | PASS | Godot `test_q006_runtime.gd`; 10 screen pixels stays a tap, 13 pixels starts drag |
| Fox at home while player is away / greeting when player approaches | PASS | `web-fox-at-home-away-from-player.png`, `web-fox-greets-at-cottage.png`; normal WASD navigation and telemetry state assertion |
| Rabbit Q012 marker | PASS | Q012-pending screenshots show ring/star removed; the visible task card and “庆祝” action remain |
| Full isolated Godot regression | PASS | 74/74, including Q004/Q006 runtime, save, disk cycle, and all quest-state tests |
| Browser optional quest regression | PASS | Q007–Q011 flow, Q006 move/recover/replace, browser refresh, then Q006 editing again before Q012; no console errors |
| `git diff --check` | PASS | Clean |

Mouse drag and browser persistence are visually accepted. Touch uses the same screen-coordinate path in code but was not exercised on a real touch device, so it remains unverified.

## Batch B acceptance record (mouse direction fallback)

This batch connects only the already approved idle views. It deliberately does not claim a walk animation.

| Check | Result | Evidence |
|---|---|---|
| Approved idle assets: 256×256 RGBA, non-empty alpha, 216 px visible height, common bottom anchor y=232 | PASS | PNG metadata and `art_validation.gd`; directions visually reviewed as front/back/left/right |
| Four-direction orientation during real keyboard movement and after stopping | PASS | Fresh Web export in Chromium; `art-controller-idle-down.png`, `art-controller-idle-up.png`, `art-controller-idle-left.png`, `art-controller-idle-right.png` |
| Real four-direction input sequence recording | PASS | `tests/artifacts/experience-batch-b-20261104/mouse-direction-video/page@6910a87ead4b0950340c5fa6c525fb67.webm` |
| Idle-only set is accepted without enabling the full animation contract | PASS | `test_art_pipeline.gd`; `mouse.enabled` remains false and the walk resource continues to require all 24 frames |
| Actual footstep animation, diagonal movement clip, and bridge crossing with walk cycle | ASSET_REQUIRED / NOT TESTED | 24 approved walk frames do not exist; directional idle fallback intentionally displays no fake steps |
| Turtle grounded idle/crawl | ASSET_REQUIRED / NOT TESTED | Existing single planted pose remains; see `docs/art/turtle-animation-status.md` for exact source-art requirements |
| Full isolated Godot regression | PASS | 74/74 tests |
| Four-direction real-browser input | PASS | `tools/test_art_browser.py` on fresh Web export, Chromium/WebGL2 software renderer |
