---
task_id: TASK-INT-cart-centipede
stage: 6
wave: 2
priority: P2
lane: cartridge
archetype: well_fill
status: ready
owner_agent: ""
touches: [content/cartridges/centipede]
locks_required: [cart-centipede]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-cart-tetris]
archetype_ref: tetris
acceptance:
  - Reads the solid region / container as the play shape and fills it with game objects (blocks/bricks/mushrooms)
  - Honors the non-rectangular boundary -> objects stay inside the authored shape
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **centipede** onto the shared WELL/FILL adapter (solid region + container boundary -> a fillable shape) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **well_fill** — rollout (Wave 2).

## Knobs to expose
invert, fill, grid_scale, density, bounds_clamp, wall_width (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/centipede/`. Read `app/shared/**` + the map read-only. Lock: `cart-centipede`.
- Depends on the family reference `TASK-INT-cart-tetris`; flip to `ready` once that + the foundations are done.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
