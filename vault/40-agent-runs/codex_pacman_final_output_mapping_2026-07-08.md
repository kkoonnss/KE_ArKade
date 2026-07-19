---
run_id: codex_pacman_final_output_mapping_2026-07-08
agent: codex
session_start: 2026-07-08T00:00:00-07:00
session_end: 2026-07-08T00:00:00-07:00
task_id: TASK-calibration-runtime-scene-warp
lane: cartridge
lock_held: cart-pacman-final-output-mapping
status: pending_kons_verify
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Pac-Man now loads the selected scene's `calibration/current.yaml` and applies
the saved output mesh to its visual stage coordinates during drawing. This
keeps gameplay, collision, and map interpretation flat while making the drawn
maze/player/pickup positions follow the scene mapping. The previous offscreen
wrapper remains inactive because it opened black in the normal window path.

## Changes

- `content/cartridges/pacman/main.gd`: added scene calibration loading from
  `scene_dir/calibration/current.yaml`.
- `content/cartridges/pacman/main.gd`: changed the view transform to compute
  Pac-Man drawing in a fixed 1920x1080 output stage before fitting that stage
  into the current window.
- `content/cartridges/pacman/main.gd`: added piecewise bilinear mapping from
  canonical stage coordinates into the saved calibration mesh targets.
- `content/cartridges/pacman/main.gd`: fixed rectangle sizing to map both
  corners through the stage mapper, avoiding the oversized/cropped rectangle
  behavior from old top-left-plus-size math.
- `content/cartridges/pacman/main.gd`: routes HUD text placement through the
  output stage mapper.

## Verification

- `git diff --check -- content/cartridges/pacman/main.gd` passed, with only
  the repo's existing LF/CRLF warning.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --check --quit` passed.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --quit-after 2 -- --scene "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall" --level "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall\levels\rock_wall_260629_173035"` passed and printed `Pac-Man scene calibration loaded: ...scene_demo_wall/calibration/current.yaml`.
- `rg -n "SharedLoader" content\cartridges\pacman` returned hits.
- `rg -n "Adapter\.new\(\)|TabMenu\.new\(" content\cartridges\pacman` returned no matches.
- `Test-Path -LiteralPath content\cartridges\pacman\adapter_base.gd` returned `False`.

## Backup Status

- No git commit was made because this repo already has a large unrelated dirty
  working tree. Backup remains pending.

## Open Questions

- This is not yet a universal offscreen post-process for every pixel of every
  cartridge. It is a Pac-Man visual-coordinate mapping pass that should make
  the output mapping visible now without the black-window wrapper risk.
- Background/reference texture rectangles are now fitted through mapped
  corners, but they are not subdivided/warped as textures yet.

## Next Holder Briefing

Kons should launch Pac-Man from the hub on `scene_demo_wall` and confirm the
maze visibly follows the saved calibration shape. If the geometry maps but the
photo/background still feels too rectangular, the next pass should subdivide
texture drawing or return to a safer offscreen final-frame post-process.
