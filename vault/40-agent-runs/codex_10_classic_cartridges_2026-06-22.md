# Codex Run Log - 10 Classic Cartridge Buildout

Date: 2026-06-22
Agent: Codex
Scope: `TASK-cyber-centipede`, `TASK-neon-invaders`, `TASK-robo-swarm`, `TASK-cyber-burger`, `TASK-star-fighter`, `TASK-missile-defense`, `TASK-neon-defender`, `TASK-lunar-lander`, `TASK-cyber-paperboy`, `TASK-cube-hopper`

## Claimed
- Set all ten task frontmatter statuses from `ready` to `in_progress`.
- Built only in the assigned cartridge directories plus task/run/QA notes.

## Implementation
- Replaced the ten preview stubs with a self-contained Godot `Node2D` arcade cartridge core in each owned cartridge directory.
- The core derives its mode from the cartridge folder name, keeping each directory independent while enforcing the same safety and IPC behavior.
- Added/implemented:
  - NDJSON IPC handling: `load`, `pause`, `resume`, `blank`, `quit`, `ready`, `score`, `heartbeat`, plus state/error messages.
  - Pure black base layer and post-splash gameplay screenshot hook.
  - Level ingestion from `derived/grid.json`, fallback from `derived/occupancy.png`, and final procedural fallback grid.
  - BFS nearest-walkable spawn safety, bounds clamping, and map-scale-to-viewport rendering.
  - Neon vector rendering: cyan/green/magenta/yellow/orange accents, thin white structure, glow outlines, no gray play backdrop.
  - Keyboard/controller movement and fire hooks.

## Cartridge Behaviors
- `centipede`: lower-zone player movement, upward shots, centipede chain motion, destructible mushroom barriers, scoring/waves.
- `space_invaders`: player cannon, alien grid advance/drop, barricades, alien fire, scoring/waves.
- `robotron_2084`: twin-stick/top-down shooter loop, chasing enemies, rescue targets, spawn safety.
- `burger_time`: dynamic platforms/ladders, burger ingredient walk/drop/crush loop, chasing enemies.
- `galaga`: bottom shooter with formation enemies, boss targets, dual-ship rescue reward.
- `missile_command`: cities/silos, incoming missiles, counter-missile explosions, ammo/score/city loss.
- `defender`: wrapping side-scroller, radar, ship fire, humanoid rescue targets, landers.
- `lunar_lander`: gravity/thruster physics, fuel HUD, landing pads, safe/unsafe landing states.
- `paperboy`: auto-scrolling route, paper throws, subscriber/non-subscriber targets, hazards.
- `qbert`: isometric cube pyramid, tile color-change scoring, hopping enemies.

## Manifest Hygiene
- Updated all ten manifests from original arcade names to KE homage names.
- Set all ten manifest statuses to `playable`.

## Verification
- Godot parser check, all ten passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --check-only --script res://main.gd`
- Bounded runtime scene load, all ten passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit-after 20 --log-file vault/70-qa/<cart>_runtime.log -- --level <demo_level>`
- Runtime logs scanned for `ERROR|SCRIPT ERROR|Invalid|Parse Error|Cannot|Failed`; no matches found.
- Visual screenshots captured after splash via OpenGL renderer:
  `Godot_v4.3-stable_win64_console.exe --display-driver windows --rendering-driver opengl3 --path content/cartridges/<cart> -- --level <demo_level> --screenshot vault/70-qa/<cart>_gameplay.png`
- Pixel sampling confirmed all four screenshot corners are `(0, 0, 0)` for every cartridge.
- Sparse image sampling confirmed each screenshot contains nonblack gameplay content.

## Notes
- Headless Movie Maker capture crashed inside Godot's dummy renderer (`texture_2d_get` null texture). Non-headless OpenGL screenshot capture worked and produced the final QA evidence.
- No schemas or `app/shared` files were edited.

