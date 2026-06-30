# Codex Run Log - 10 More Classic Cartridge Buildout

Date: 2026-06-22
Agent: Codex
Scope: `TASK-barrel-jumper`, `TASK-brick-breaker`, `TASK-bubble-dragons`, `TASK-drill-dug`, `TASK-dungeon-crawl`, `TASK-marble-run`, `TASK-neon-joust`, `TASK-neon-snake`, `TASK-neon-tapper`, `TASK-neon-tempest`

## Implementation
- Replaced the ten preview stubs with a self-contained Godot `Node2D` arcade core copied into each owned cartridge directory.
- The script derives gameplay mode from the cartridge folder name, so each cartridge remains independently launchable and owns its own code.
- Added common hardening:
  - Pure `#000000` background layer and black clear color.
  - Level loading from `derived/grid.json`, fallback from `derived/occupancy.png`, final procedural fallback grid.
  - `_find_nearest_walkable_cell()` BFS safety and `_safe_pos()` for player/enemy/item spawns.
  - Bounds clamping, grid collision checks, keyboard/controller action paths.
  - Full NDJSON IPC handling for `load`, `pause`, `resume`, `blank`, `quit`; emits `ready`, `heartbeat`, `score`, and state/error messages.
  - Neon vector rendering with translucent fills, glowing outlines, and optional reference toggle.

## Cartridge Behaviors
- `donkey_kong`: platform/ladders, jumping, rolling barrels, jump-over scoring, goal/wave clear.
- `breakout`: paddle, bouncing ball, multi-hit bricks, colored brick layers, score/wave reset.
- `bubble_bobble`: platform movement, bubble shots, trapping enemies, floating/popping enemies for points.
- `dig_dug`: digging cells, pump shots, inflating enemies, ghost enemy movement, rocks.
- `gauntlet`: top-down movement, projectile attacks, monster generators, food/key pickups, health decay.
- `marble_madness`: rolling marble inertia, checkpoints/time bonuses, hazards, course clear.
- `joust`: flap physics, platforms, above/below collision resolution, eggs and hatching.
- `snake`: grid-locked movement, food spawning away from body/walls, growth and collision death.
- `tapper`: multi-lane counters, advancing customers, drink throws, mug collection and penalties.
- `tempest`: radial tube lanes, rim movement, lane shots, crawling enemies, superzapper.

## Manifest Hygiene
- Updated all ten manifests to KE homage names.
- Set all ten manifest statuses to `playable`.

## Verification
- Godot parser check, all ten passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --check-only --script res://main.gd`
- Required validation command, all ten passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit`
- Bounded runtime scene load, all ten passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit-after 20 --log-file vault/70-qa/<cart>_runtime.log -- --level <demo_level>`
- Runtime logs scanned for `ERROR|SCRIPT ERROR|Invalid|Parse Error|Cannot|Failed`; no matches found.
- Post-splash screenshots captured:
  `Godot_v4.3-stable_win64_console.exe --display-driver windows --rendering-driver opengl3 --path content/cartridges/<cart> -- --level <demo_level> --screenshot vault/70-qa/<cart>_gameplay.png`
- Pixel sampling confirmed all four screenshot corners are `(0, 0, 0)` for every cartridge, with nonblack gameplay content present.

## Notes
- No schemas, `app/shared`, hub, or compiler files were edited.
- These are compact playable loops that clear the safety, IPC, visual, and classic-mechanic thresholds. Per-title tuning/polish can deepen difficulty curves later.

