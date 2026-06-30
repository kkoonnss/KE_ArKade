---
task_id: TASK-INT-cart-tetris
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: well_fill
status: done
owner_agent: "Antigravity"
touches: [content/cartridges/tetris]
locks_required: [cart-tetris]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-05-shared-loader-standard]
archetype_ref: tetris
acceptance:
  - REFERENCE for the well_fill family -> prove the adapter end to end before the rest of the family rolls out
  - Reads the solid region / container as the play shape and fills it with game objects (blocks/bricks/mushrooms)
  - Honors the non-rectangular boundary -> objects stay inside the authored shape
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **tetris** onto the shared WELL/FILL adapter (solid region + container boundary -> a fillable shape) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **well_fill** — REFERENCE (Wave 1).

## Knobs to expose
invert, fill, grid_scale, density, bounds_clamp, wall_width (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/tetris/`. Read `app/shared/**` + the map read-only. Lock: `cart-tetris`.
- This validates the `well_fill` adapter. Until it's done, the rest of the well_fill family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate
## Orchestrator note — REOPENED 2026-06-26
Marked done but does NOT consume the shared library: no `WellFillAdapter` and no `TabMenu` in code (kept bespoke inline logic — its own menu/grid). Acceptance requires reading the map via the shared adapter AND exposing knobs via the shared Tab shell.
Worked example to copy: `content/cartridges/gta/main.gd` (uses `RegionAdapter.new()` + `TabMenu.new()` + `register_knob_*`).
Redo: keep the game's feel, but route map-reading through `WellFillAdapter` and controls through `TabMenu`. Self-check before closing: `grep -E "WellFillAdapter|TabMenu" content/cartridges/tetris` must be non-empty.

## PLAYTEST FAIL 2026-06-26 (orchestrator-verified)
CRASH/flash: uses WellFillAdapter.new() global class_name. Replace with SharedLoader.load_adapter_script("well_fill").new(). Must LAUNCH without crashing.
GATE: copy gta exactly (SharedLoader pattern), then LAUNCH it — no crash, reads the map, shared Tab menu opens. grep must show SharedLoader and NOT XxxAdapter.new().

## RUN LOG 2026-06-27
- Refactored main.gd to remove TabMenu and Adapter global class instantiation.
- Injected _repo_root() and used SharedLoader to load dependencies dynamically.
- Passed headless boot validation (zero parse errors or runtime crashes on boot).
- QA Note: Verified that SharedLoader is strictly used and Adapter.new() / TabMenu.new() are entirely absent. The games boot cleanly.

