---
run_id: codex_black_launch_and_games_hover_fix_2026-07-08
agent: codex
session_start: 2026-07-08T00:00:00-07:00
session_end: 2026-07-08T00:00:00-07:00
task_id: TASK-calibration-runtime-scene-warp
lane: hub+cartridge
lock_held: cart-pacman-black-launch-fix, hub-games-hover-actions
status: pending_kons_verify
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Restored Pac-Man to the direct gameplay scene after the experimental runtime
mapping wrapper showed a black window in the interactive launch path. Fixed the
Games screen skin-title hover state and kept skin cycling inside the game
selection overlay instead of bouncing back to Levels.

## Changes

- `content/cartridges/pacman/project.godot`: changed `run/main_scene` back to
  `res://main.tscn`.
- `app/hub/main.gd`: `_cycle_skin()` now rebuilds `display_games_lightbox()`
  when the game picker overlay is open, so X/Y skin changes stay in game
  selection.
- `app/hub/main.gd`: game title hint text now uses explicit mouse-hover
  booleans for the title/image cover, so `< (X) ... (Y) >` appears immediately
  on mouse hover.
- `app/hub/main.gd`: `display_games_lightbox()` now populates
  `_game_title_focus_buttons`, letting focus return to the selected title after
  an overlay skin refresh.
- `vault/30-tasks/TASK-calibration-runtime-scene-warp.md`: marked the runtime
  warp pass as still in progress because the Pac-Man wrapper is not active.

## Verification

- `git diff --check -- app/hub/main.gd content/cartridges/pacman/project.godot`
  passed, with only the repo's existing LF/CRLF warnings.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path content\cartridges\pacman --check --quit`
  passed.
- A headless Pac-Man launch with `--scene`, `--level`, and `--screenshot`
  reached the gameplay setup/draw logs after restoring `main.tscn`, but the
  existing screenshot branch did not produce a file in headless mode before the
  process timeout. Needs Kons visual confirmation in the normal app window.

## Backup Status

- No git commit was made because this repo already has a large unrelated dirty
  working tree. Backup remains pending.

## Open Questions

- The shared post-process calibration warp needs a safer visual wrapper design
  before it is enabled again for Pac-Man or rolled to other cartridges.

## Next Holder Briefing

Verify from the hub that Pac-Man opens visibly again. On the Games screen and
the level game-picker overlay, hover a title with multiple skins and confirm
the X/Y hints appear immediately; press X/Y or click the left/right title
zones and confirm the picker stays on game selection.
