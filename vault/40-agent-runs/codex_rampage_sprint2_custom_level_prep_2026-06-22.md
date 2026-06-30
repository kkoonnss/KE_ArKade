# Codex Run Log - Rampage, Sprint 2, and Custom-Level Prep

Date: 2026-06-22
Agent: Codex
Scope: `rampage`, `on_track`/Sprint 2, `scene_classic_pack`, and all-cartridge custom-level compliance

## Changes

- Added `content/cartridges/rampage/` as a playable Rampage-style cartridge.
- Added `content/scenes/scene_classic_pack/levels/classic_rampage/` as the ideal Rampage tester level.
- Updated `on_track` to display as `Sprint 2`, the Atari-style on-track racing entry.
- Added explicit `track_centerline.json` and navgraph loop data for:
  - `classic_on_track`
  - `classic_on_track`
- Generated new project-local cover/thumbnail art for:
  - `Rampage`
  - `Sprint 2`
- Patched legacy IPC handling in:
  - `tetris`
  - `bomberman`
  - `pacman`
  - `on_track`
  - `frogger`

## Rampage Cartridge Notes

Rampage reads `grid.json` first, falls back to `derived/occupancy.png`, and then falls back to a procedural city grid. It interprets occupied/solid cells as building mass, uses open cells for safe player placement, and includes `_find_nearest_walkable_cell()` BFS spawn safety.

Gameplay loop:
- player movement/climbing
- punching buildings
- destructible building HP
- helicopters/tanks/debris
- health/score
- IPC heartbeat and command handling
- post-splash screenshot support

## Sprint 2 Notes

`on_track` now presents as `Sprint 2`. The `classic_on_track` tester now includes a real loop in `derived/track_centerline.json`, so the racing cartridge starts on an actual track instead of an empty graph.

## Verification

- All 31 real cartridges passed parser checks.
- All 31 real cartridges passed the required headless launch command:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit`
- Rampage custom-level load passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/rampage --quit-after 20 -- --level <classic_rampage>`
- Sprint 2 custom-level load passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/on_track --quit-after 20 -- --level <classic_on_track>`
- Hub manifest test passed and reported 31 cartridges.
- Hub level-sort test passed and mapped `classic_on_track` and `classic_on_track` to `Sprint 2`, plus `classic_rampage` to `Rampage`.
- Custom-level compliance audit passed for 31 cartridges with zero warnings.
- OpenGL screenshots and pixel checks passed for Rampage and Sprint 2.

## Evidence

- Rampage gameplay screenshot:
  `vault/70-qa/rampage_classic_gameplay_2026-06-22.png`
- Sprint 2 gameplay screenshot:
  `vault/70-qa/sprint2_classic_on_track_gameplay_2026-06-22.png`
- Updated classic-pack thumbnail contact sheet:
  `vault/70-qa/classic_pack_thumbnail_sync_contact_sheet_2026-06-22.png`

## Note

Rampage triggered a Godot signal 11 when the headless validation was run with `--log-file`. The same headless custom-level validation without `--log-file` passed, and the OpenGL screenshot/runtime path passed. This appears tied to Godot's logging/headless path rather than cartridge logic.
