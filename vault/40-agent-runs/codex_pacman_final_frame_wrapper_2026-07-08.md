---
run_id: codex_pacman_final_frame_wrapper_2026-07-08
agent: codex
session_start: 2026-07-08T02:19:06-07:00
session_end: 2026-07-08T12:30:00-07:00
task_id: TASK-calibration-runtime-scene-warp
lane: cartridge+shared
lock_held: cart-pacman-final-frame-wrapper; shared-final-output-warp
status: pending_kons_verify
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Replaced the Pac-Man visual-coordinate calibration experiment with the intended
final-frame wrapper path. Pac-Man now boots through `runtime_main.tscn`, renders
the original flat `main.tscn` into a canonical 1920x1080 `SubViewport`, then
draws that finished frame through the scene-level calibration mesh.

Follow-up after Kons reported a black calibrated Pac-Man screen: the runtime
mesh UVs were corrected to match the calibrator's normalized `0..1` UV
convention.

Follow-up after Kons reported the mapped output was too thin on X: Pac-Man's
project stretch aspect was set to `keep` so the 1920x1080 canvas is preserved
with black bars instead of non-uniformly scaling to the window shape.

Follow-up after Kons showed the output still looked too skinny: the shared
runtime warp now honors the saved `input` crop from the scene calibration
profile. Runtime UVs sample the same source crop the calibrator uses instead
of feeding the whole 16:9 game frame into the portrait wall mesh.

## Changes

- `content/cartridges/pacman/main.gd`: removed scene calibration loading and
  point-warped stage drawing; left gameplay and visuals flat inside the
  canonical stage.
- `content/cartridges/pacman/runtime_main.gd`: added readiness guards and logs
  for the final-frame wrapper, and only applies the shared warp when the scene
  profile is loaded.
- `content/cartridges/pacman/project.godot`: changed the launch scene to
  `res://runtime_main.tscn`.
- `app/shared/calibration/final_output_warp.gd`: remains the shared scene
  profile loader and textured mesh drawer.
- `app/shared/calibration/final_output_warp.gd`: changed final-frame triangle
  UVs from texture-pixel coordinates to normalized UVs, matching the
  calibrator's working draw path.
- `content/cartridges/pacman/project.godot`: added
  `window/stretch/aspect="keep"` to prevent X-axis squeezing on non-16:9
  windows.
- `app/shared/calibration/final_output_warp.gd`: added `source_crop` input
  parsing and mirrored the calibrator's input-crop-to-stage math for runtime
  texture UVs.
- `app/shared/calibration/final_output_warp.gd`: changed output coordinate
  conversion to use the saved 0..1919 / 0..1079 stage bounds exactly.

## Verification

- `rg -n "OUTPUT_STAGE_SIZE|calibration_loaded|_load_scene_calibration|_stage_to_screen|_output_stage_view_scale|_calibrated_stage_point|_calibration_key|Pac-Man scene calibration" content\cartridges\pacman\main.gd` returned no matches.
- `rg -n "run/main_scene|final-frame|load_calibration_warp_script|draw_final_output" content\cartridges\pacman app\shared\calibration app\shared\shared_loader.gd` confirmed `runtime_main.tscn` is the launch scene and the wrapper calls the shared final-output warp.
- `git diff --check -- content\cartridges\pacman\main.gd content\cartridges\pacman\runtime_main.gd content\cartridges\pacman\runtime_main.tscn content\cartridges\pacman\project.godot app\shared\calibration\final_output_warp.gd app\shared\shared_loader.gd` passed with only existing LF/CRLF warnings.
- Follow-up `git diff --check -- app\shared\calibration\final_output_warp.gd content\cartridges\pacman\runtime_main.gd content\cartridges\pacman\project.godot content\cartridges\pacman\main.gd` passed with only existing LF/CRLF warnings.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --check --quit` passed after rerunning with elevated permission because the sandboxed run could not write Godot's user log. Output included `Pac-Man final-frame texture ready: (1920, 1080)`.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --quit-after 2 -- --scene "...content\scenes\scene_demo_wall" --level "...levels\rock_wall_260629_173035"` passed. Output included `Pac-Man final-frame scene calibration loaded: ...scene_demo_wall/calibration/current.yaml` and `Pac-Man final-frame texture ready: (1920, 1080)`.
- Follow-up after aspect fix: `git diff --check -- content\cartridges\pacman\project.godot app\shared\calibration\final_output_warp.gd content\cartridges\pacman\runtime_main.gd` passed with only existing LF/CRLF warnings.
- Follow-up after aspect fix: `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --check --quit` passed and printed `Pac-Man final-frame texture ready: (1920, 1080)`.
- Follow-up after aspect fix: calibrated rock-wall headless launch passed and printed both `Pac-Man final-frame scene calibration loaded: ...scene_demo_wall/calibration/current.yaml` and `Pac-Man final-frame texture ready: (1920, 1080)`.
- Follow-up after source-crop fix: `git diff --check -- app\shared\calibration\final_output_warp.gd content\cartridges\pacman\runtime_main.gd content\cartridges\pacman\project.godot` passed with only the existing LF/CRLF warning on `project.godot`.
- Follow-up after source-crop fix: `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --check --quit` passed and printed `Pac-Man final-frame texture ready: (1920, 1080)`.
- Follow-up after source-crop fix: calibrated rock-wall headless launch passed and printed both `Pac-Man final-frame scene calibration loaded: ...scene_demo_wall/calibration/current.yaml` and `Pac-Man final-frame texture ready: (1920, 1080)`.
- Visual confirmation is still required from Kons because the headless run cannot prove the projected pixels.

## Backup Status

- No git commit was made because this repo already has a large unrelated dirty
  working tree. Backup remains pending.

## Open Questions

- None new. The suspected `draw_polygon` UV convention mismatch has been fixed
  to match the calibrator.

## Next Holder Briefing

Launch Pac-Man from the hub on `scene_demo_wall`. Expected behavior: gameplay
still runs flat in the canonical viewport, but the projected output samples the
scene's saved input crop and then displaces it through the output mesh. If the
settings panel or HUD still appears in the projected crop, the next fix should
separate projector-safe game output from operator/settings UI.
