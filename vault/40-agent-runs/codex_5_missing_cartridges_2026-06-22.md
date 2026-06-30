# Codex Run Log - 5 Missing Cartridge Buildout

Date: 2026-06-22
Agent: Codex
Scope: `asteroids`, `tron`, `pong`, `smash_tv`, `battlezone`

## Context
These five cartridge folders existed but still had prototype or preview-level gameplay. The user clarified that classic IP references in cover art are acceptable for this art/projection project, so art text was left intact.

## Implementation
- Replaced/standardized the five remaining prototype `main.gd` files with a self-contained Godot `Node2D` cartridge core.
- The script derives gameplay mode from the cartridge folder name.
- Added:
  - Pure black projection base and black clear color.
  - Level loading from `derived/grid.json`, fallback from `derived/occupancy.png`, final procedural fallback grid.
  - `_find_nearest_walkable_cell()` BFS spawn safety and `_safe_pos()` for entity placement.
  - Full NDJSON IPC handling for `load`, `pause`, `resume`, `blank`, `quit`.
  - `ready`, 1000 ms `heartbeat`, score, state, and error message emission.
  - Neon vector rendering and post-splash screenshot support.

## Cartridge Behaviors
- `asteroids`: thrust/rotate ship, asteroid splitting, laser shots, wraparound playfield, score/waves.
- `tron`: grid-locked light-cycle trails, crash checks against walls/trails, AI rider.
- `pong`: paddle control, AI opponent, ball bounce/scoring/lives.
- `smash_tv`: top-down twin-stick shooter loop, chasing enemies, monster spawners.
- `battlezone`: rotating tank, movement, shells, AI tanks, enemy fire.

## Cover Fix
- Re-encoded `pong`, `smash_tv`, and `battlezone` `splash.png`/`thumbnail.png` files as valid PNGs. They had `.png` filenames but Godot reported invalid PNG data before re-encoding.

## Verification
- Godot parser check, all five passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --check-only --script res://main.gd`
- Required headless launch validation, all five passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit`
- Bounded runtime scene load, all five passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit-after 20 --log-file vault/70-qa/<cart>_runtime.log -- --level <demo_level>`
- Runtime logs scanned for `ERROR|SCRIPT ERROR|Invalid|Parse Error|Cannot|Failed`; no matches found.
- Post-splash screenshots captured:
  `vault/70-qa/<cart>_gameplay.png`
- Pixel sampling confirmed all four screenshot corners are `(0, 0, 0)` for every cartridge, with nonblack gameplay content present.

