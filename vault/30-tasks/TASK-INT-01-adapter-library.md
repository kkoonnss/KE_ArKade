---
task_id: TASK-INT-01-adapter-library
stage: 6
wave: 0
priority: P0
lane: shared
archetype: n/a
status: done
owner_agent: "Antigravity"
touches: [app/shared]
locks_required: [shared-adapters]
depends_on: []
acceptance:
  - app/shared/ gains 7 archetype adapters as reusable GDScript -> maze, well_fill, arena, lane, track, platform, region
  - Each adapter exposes a stable contract -> interpret(level_dir, derived, knobs) -> a normalized "play layout" struct (walkable graph / fill cells / bounds + cover / lanes / centerline / platforms / regions) the cartridge consumes
  - The MAZE adapter is extracted from the working pacman/main.gd grid->graph logic (pacman is the reference implementation) and proven to reproduce pacman's current behavior
  - EVERY adapter has a procedural fallback -> if the map yields too little, it seeds a sensible default inside the bounds so a game NEVER boots to an empty level
  - Adapters are read-only consumers of semantic_map.png + derived/** + palette; they never write level data or mutate the map
  - Documented contract in app/shared/README.md so cartridge agents wire in without reading the adapter internals
  - Verified by a headless harness that runs each adapter on the demo_wall map AND a classic level and prints a non-empty layout for all 7
---

## Objective
The linchpin. Lift Pac-Man's proven map->game pattern into a shared library of 7 archetype adapters (see PLAN §3) so each cartridge becomes a thin "pick adapter + expose knobs" job instead of a bespoke interpreter. This is the critical path: it must finish and FREEZE before cartridge fan-out (Wave 1+) begins.

## Notes
- Owns `app/shared` jointly with TASK-INT-02 — do them in sequence under ONE owner, or finish 01 and freeze before 02 starts. No second agent in `app/shared` concurrently.
- After this closes, treat the adapter contracts like the schemas: changes go through Opus, not ad hoc, because 32 cartridges will depend on them.
- Keep the layout struct engine-agnostic enough that the hub Design-screen live preview (TASK-INT-03) can reuse the exact same adapters.
