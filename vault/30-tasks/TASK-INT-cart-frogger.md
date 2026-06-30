---
task_id: TASK-INT-cart-frogger
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: lane
status: done
owner_agent: "KE_ArKade_260626_132556"
touches: [content/cartridges/frogger]
locks_required: [cart-frogger]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit]
archetype_ref: frogger
acceptance:
  - REFERENCE for the lane family -> prove the adapter end to end before the rest of the family rolls out
  - Reads grid rows/bands into lanes (hazard/safe/water); player crosses spawn -> goal
  - Lane contents (cars/logs/etc.) seed by density; goal and spawn honored from the map
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **frogger** onto the shared LANE adapter (grid rows/bands -> traffic/water/safe lanes) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **lane** — REFERENCE (Wave 1).

## Knobs to expose
grid_scale, density, invert, bounds_clamp (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/frogger/`. Read `app/shared/**` + the map read-only. Lock: `cart-frogger`.
- This validates the `lane` adapter. Until it's done, the rest of the lane family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
