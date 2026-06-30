---
task_id: TASK-INT-cart-snake
stage: 6
wave: 2
priority: P2
lane: cartridge
archetype: maze
status: ready
owner_agent: ""
touches: [content/cartridges/snake]
locks_required: [cart-snake]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-cart-pacman]
archetype_ref: pacman
acceptance:
  - Reads the level via the shared MAZE adapter -> movement constrained to corridors, solids block
  - Spawns/pickups/enemies seed from map classes (spawn=5, pickup=7, goal=6); player starts on a spawn cell
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **snake** onto the shared MAZE adapter (grid walkable cells -> node graph / corridors) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **maze** — rollout (Wave 2).

## Knobs to expose
grid_scale, wall_width, invert, density, bounds_clamp, reference_opacity (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/snake/`. Read `app/shared/**` + the map read-only. Lock: `cart-snake`.
- Depends on the family reference `TASK-INT-cart-pacman`; flip to `ready` once that + the foundations are done.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
