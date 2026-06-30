---
task_id: TASK-INT-cart-galaga
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: arena
status: done
owner_agent: "KE_ArKade_260626_132556"
touches: [content/cartridges/galaga]
locks_required: [cart-galaga]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit]
archetype_ref: galaga
acceptance:
  - REFERENCE for the arena family -> prove the adapter end to end before the rest of the family rolls out
  - Reads the container boundary as the playfield edge; waves/enemies spawn inside it
  - Solid regions act as cover/obstacles; player + projectiles respect the bounds
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **galaga** onto the shared ARENA adapter (container boundary = playfield edge; solid blocks = cover) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **arena** — REFERENCE (Wave 1).

## Knobs to expose
bounds_clamp, density, block_region, invert, reference_opacity (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/galaga/`. Read `app/shared/**` + the map read-only. Lock: `cart-galaga`.
- This validates the `arena` adapter. Until it's done, the rest of the arena family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
