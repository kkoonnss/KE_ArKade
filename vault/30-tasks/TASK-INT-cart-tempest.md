---
task_id: TASK-INT-cart-tempest
stage: 6
wave: 2
priority: P2
lane: cartridge
archetype: arena
status: ready
owner_agent: ""
touches: [content/cartridges/tempest]
locks_required: [cart-tempest]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-cart-galaga]
archetype_ref: galaga
acceptance:
  - Reads the container boundary as the playfield edge; waves/enemies spawn inside it
  - Solid regions act as cover/obstacles; player + projectiles respect the bounds
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **tempest** onto the shared ARENA adapter (container boundary = playfield edge; solid blocks = cover) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **arena** — rollout (Wave 2).

## Knobs to expose
bounds_clamp, density, block_region, invert, reference_opacity (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/tempest/`. Read `app/shared/**` + the map read-only. Lock: `cart-tempest`.
- Depends on the family reference `TASK-INT-cart-galaga`; flip to `ready` once that + the foundations are done.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
