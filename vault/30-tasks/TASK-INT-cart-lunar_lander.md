---
task_id: TASK-INT-cart-lunar_lander
stage: 6
wave: 2
priority: P2
lane: cartridge
archetype: platform
status: ready
owner_agent: ""
touches: [content/cartridges/lunar_lander]
locks_required: [cart-lunar_lander]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-cart-donkey_kong]
archetype_ref: donkey_kong
acceptance:
  - Reads platform_top edges AND procedurally adds platforms/pads where boundaries/islands make sense (gravity-aware)
  - Player lands/climbs on derived platforms; falls respect gravity and the bounds
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **lunar_lander** onto the shared PLATFORM adapter (platform_top edges + procedurally added platforms; gravity) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **platform** — rollout (Wave 2).

## Knobs to expose
jump_height, platform_snap, add_platforms, climb_tolerance, hazard_leniency, bounds_clamp (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/lunar_lander/`. Read `app/shared/**` + the map read-only. Lock: `cart-lunar_lander`.
- Depends on the family reference `TASK-INT-cart-donkey_kong`; flip to `ready` once that + the foundations are done.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
