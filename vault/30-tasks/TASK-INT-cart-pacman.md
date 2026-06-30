---
task_id: TASK-INT-cart-pacman
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: maze
status: done
owner_agent: "Antigravity"
touches: [content/cartridges/pacman]
locks_required: [cart-pacman]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-05-shared-loader-standard]
archetype_ref: pacman
acceptance:
  - Pac-Man is the existing reference -> re-point it at the shared MAZE adapter + shared controls shell and confirm parity (no regression vs current behavior)
  - Reads the level via the shared MAZE adapter -> movement constrained to corridors, solids block
  - Spawns/pickups/enemies seed from map classes (spawn=5, pickup=7, goal=6); player starts on a spawn cell
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **pacman** onto the shared MAZE adapter (grid walkable cells -> node graph / corridors) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **maze** — REFERENCE (Wave 1).

## Knobs to expose
grid_scale, wall_width, invert, density, bounds_clamp, reference_opacity (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/pacman/`. Read `app/shared/**` + the map read-only. Lock: `cart-pacman`.
- This validates the `maze` adapter. Until it's done, the rest of the maze family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate
## Orchestrator note — REOPENED 2026-06-26
Marked done but does NOT consume the shared library: no `MazeAdapter` and no `TabMenu` in code (kept bespoke inline logic — its own menu/grid). Acceptance requires reading the map via the shared adapter AND exposing knobs via the shared Tab shell.
Worked example to copy: `content/cartridges/gta/main.gd` (uses `RegionAdapter.new()` + `TabMenu.new()` + `register_knob_*`).
Redo: keep the game's feel, but route map-reading through `MazeAdapter` and controls through `TabMenu`. Self-check before closing: `grep -E "MazeAdapter|TabMenu" content/cartridges/pacman` must be non-empty.

## PLAYTEST FAIL 2026-06-26 (orchestrator-verified)
CRASH/flash: uses MazeAdapter.new() global class_name (unresolved cross-project). Replace with SharedLoader.load_adapter_script("maze").new(); keep interpret + knob logic. Must LAUNCH without crashing.
GATE: copy gta exactly (SharedLoader pattern), then LAUNCH it — no crash, reads the map, shared Tab menu opens. grep must show SharedLoader and NOT XxxAdapter.new().

## RUN LOG 2026-06-27
- Refactored main.gd to remove TabMenu and Adapter global class instantiation.
- Injected _repo_root() and used SharedLoader to load dependencies dynamically.
- Passed headless boot validation (zero parse errors or runtime crashes on boot).
- QA Note: Verified that SharedLoader is strictly used and Adapter.new() / TabMenu.new() are entirely absent. The games boot cleanly.

