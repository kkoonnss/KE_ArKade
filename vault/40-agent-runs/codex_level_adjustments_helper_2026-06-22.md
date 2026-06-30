# Codex Run Log - Per-Cartridge Level Adjustments Helper

Date: 2026-06-22
Agent: Codex

## Scope

Implemented the first pass of the per-cartridge, per-level Tab-menu settings pattern.

## Changes

- Added `app/shared/level_adjustments.gd` as the source helper.
- Added cartridge-local helper copies for standalone Godot projects:
  - `content/cartridges/on_track/level_adjustments.gd`
  - `content/cartridges/frogger/level_adjustments.gd`
  - `content/cartridges/bomberman/level_adjustments.gd`
- Migrated `on_track`, `frogger`, and `bomberman` away from writing level-folder `settings.json` directly.
- New writes go to the cartridge's `user://level_adjustments.json`, keyed by `<scene_id>/<level_id>`.
- Existing level-folder `settings.json` is still read as a legacy fallback if no registry entry exists yet.

## Verification

- Confirmed the helper copies match the shared source by file hash.
- Confirmed the migrated main scripts no longer directly reference level-folder `settings.json`.
- Passed Godot headless parser/quit checks for:
  - `on_track`
  - `frogger`
  - `bomberman`
- Passed Godot headless `--quit` checks with classic-pack level arguments for:
  - `on_track` on `classic_on_track`
  - `frogger` on `classic_frogger`
  - `bomberman` on `classic_bomberman`

Godot headless checks required AppData/user-directory access because Godot writes `user://logs` during startup.

Attempted screenshot smoke launches timed out because these cartridges do not
currently expose a bounded `--quit-after` runtime harness; that should be added
separately for richer automated runtime checks.
