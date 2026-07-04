---
run_id: codex_hub_levels_scene_propagation_2026-07-04
agent: codex
session_start: 2026-07-04T00:20:00-07:00
session_end: 2026-07-04T00:21:58-07:00
task_id: ad-hoc hub Levels tab scene propagation
lane: hub
lock_held: hub-levels
status: pending_kons_verify
pre_edit_commit: 3608bc7
close_commit: 93e4a51
backup_status: pushed
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
tags:
  - hub
  - levels
  - scene-propagation
---

# Codex Hub Levels Scene Propagation - 2026-07-04

## Summary

Kons reported that new `content/scenes/*` folders appeared in the Scenes tab but did not propagate into the Levels tab scene accordion. Root cause: `display_levels()` skipped any scene folder without a `levels/` subfolder. New authored scene folders like `scene_wallart` currently store `level.yaml`, `semantic_map.png`, and `derived/` at the scene root, while `scene_wallart empty` is an empty scene folder.

## Changes

- `app/hub/main.gd`: `display_levels()` now builds a header for every scene folder, matching the Scenes tab ordering.
- `app/hub/main.gd`: root-level scene maps with `level.yaml` are treated as a selectable level card when no nested `levels/` folder exists.
- `app/hub/main.gd`: empty scene folders now show a `No levels yet` placeholder instead of disappearing.
- `app/hub/main.gd`: `_launch_game()` now falls back to `scene_dir` when the selected level is a root-level scene map.

## Verification

- Pre-edit snapshot: `3608bc7` plus tag `pre-edit/hub/levels-scene-propagation-3608bc7`.
- Hub boot: `Godot_v4.3-stable_win64_console.exe --headless --path app\hub --quit-after 2` exited `0`; only observed warning was the pre-existing corrupt `content/scenes/scene_classic_pack/thumbnail.png`.
- UI smoke script: `Godot_v4.3-stable_win64_console.exe --headless --path app\hub --script C:\tmp\arkade_levels_smoke.gd` exited `0` with:
  - `LEVELS_SMOKE_HEADERS=["▶ Classic Pack","▶ Demo Car","▶ Demo Gallery","▶ Demo Wall","▶ Wallart","▶ Wallart Empty"]`
  - `LEVELS_SMOKE_WALLART_BUTTONS=1`
  - `LEVELS_SMOKE_EMPTY_LABELS=1`
  - `LEVELS_SMOKE passed`

## Backup Status

- Remote: `origin -> https://github.com/kkoonnss/KE_ArKade.git`.
- Post-commit hook pushed `3608bc7..93e4a51 master -> master`.
- Tag pushed: `pre-edit/hub/levels-scene-propagation-3608bc7`.
- Result: `SUCCESS: pushed master and tags.`

## Open Questions

None new.

## Next Holder Briefing

Visual check still needed in the live hub: open Levels and confirm `Wallart` plus `Wallart Empty` appear under the accordion list. Selecting `Wallart` should show a playable level card sourced from the scene root; selecting `Wallart Empty` should show `No levels yet`. `hub-levels` lock released after close.
