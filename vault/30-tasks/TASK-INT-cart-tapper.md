---
task_id: TASK-INT-cart-tapper
stage: 6
wave: 2
priority: P2
lane: cartridge
archetype: lane
status: ready
owner_agent: ""
touches: [content/cartridges/tapper]
locks_required: [cart-tapper]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-cart-frogger]
archetype_ref: frogger
acceptance:
  - Reads grid rows/bands into lanes (hazard/safe/water); player crosses spawn -> goal
  - Lane contents (cars/logs/etc.) seed by density; goal and spawn honored from the map
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **tapper** onto the shared LANE adapter (grid rows/bands -> traffic/water/safe lanes) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **lane** — rollout (Wave 2).

## Knobs to expose
grid_scale, density, invert, bounds_clamp (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/tapper/`. Read `app/shared/**` + the map read-only. Lock: `cart-tapper`.
- Depends on the family reference `TASK-INT-cart-frogger`; flip to `ready` once that + the foundations are done.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
