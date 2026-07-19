---
run_id: codex_calibration_runtime_scene_warp_2026-07-08
agent: codex
session_start: 2026-07-08T00:00:00-07:00
session_end: 2026-07-08T00:00:00-07:00
task_id: TASK-calibration-runtime-scene-warp
lane: shared+cartridge
lock_held: shared-scene-calibration-runtime, cart-pacman-scene-calibration-runtime
status: pending_kons_verify
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Added the first runtime path for scene calibration: games can now render into a
canonical 1920x1080 offscreen stage and have that final frame visually warped
through the saved scene profile. This keeps gameplay and interpretation
unwarped while applying the projector correction at the output edge.

## Changes

- `app/shared/shared_loader.gd`: added `load_calibration_warp_script()`.
- `app/shared/calibration/final_output_warp.gd`: added JSON profile loading
  for `content/scenes/<scene_id>/calibration/current.yaml` and mesh drawing of
  a final output texture.
- `content/cartridges/pacman/runtime_main.gd`: added a wrapper that hosts the
  existing Pac-Man scene in a canonical SubViewport, maps mouse input back into
  that stage, aspect-fits the output, and draws through the shared warp.
- `content/cartridges/pacman/runtime_main.tscn`: new runtime wrapper scene.
- `content/cartridges/pacman/project.godot`: main scene now points at the
  runtime wrapper instead of the raw gameplay scene.

## Verification

- `git diff --check -- app/shared/shared_loader.gd app/shared/calibration/final_output_warp.gd content/cartridges/pacman/project.godot content/cartridges/pacman/runtime_main.gd content/cartridges/pacman/runtime_main.tscn` passed, with only the repo's existing LF/CRLF warnings.
- `rg -n "SharedLoader" content\cartridges\pacman` returned hits in
  `main.gd` and `runtime_main.gd`.
- `rg -n "Adapter\.new\(\)|TabMenu\.new\(" content\cartridges\pacman`
  returned no matches.
- `Test-Path -LiteralPath content\cartridges\pacman\adapter_base.gd` returned
  `False`.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --check --quit` passed after fixing two strict typing warnings.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --quit-after 2 -- --scene "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall" --level "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall\levels\rock_wall_260629_173035"` launched and printed `Scene calibration loaded: ...scene_demo_wall/calibration/current.yaml`.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit` passed after the additive SharedLoader change.

## Backup Status

- No git commit was made because this repo already has a large unrelated dirty
  working tree. Backup remains pending.

## Open Questions

- This needs a Kons visual pass in Pac-Man to confirm the projected output is
  warped while gameplay still feels normal.
- After confirmation, roll the same runtime wrapper pattern across the other
  cartridges. The profile loader and mesh renderer are shared; the per-cart
  work should only be swapping the entry point to the wrapper.

## Next Holder Briefing

Launch Pac-Man from the hub on a scene with a visibly non-identity calibration
profile. The game should play in the same flattened coordinate system, but the
projected final frame should follow the scene output pins. If the output looks
right, propagate `runtime_main.gd`/`runtime_main.tscn` as the shared cartridge
entry wrapper pattern for the remaining games.
