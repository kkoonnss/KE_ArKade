---
task_id: TASK-INT-cart-gta
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: region
status: done
owner_agent: "Antigravity"
touches: [content/cartridges/gta]
locks_required: [cart-gta]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-05-shared-loader-standard]
archetype_ref: gta
acceptance:
  - REFERENCE for the region family -> prove the adapter end to end before the rest of the family rolls out
  - Reads solid contours into discrete blocks/buildings that shape the playfield (streets between blocks)
  - Block layout derives from the source image contours; streets/gaps remain traversable
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **gta** onto the shared REGION adapter (solid contours -> city blocks / buildings) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **region** — REFERENCE (Wave 1).

## Knobs to expose
block_size, invert, density, bounds_clamp, smooth (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/gta/`. Read `app/shared/**` + the map read-only. Lock: `cart-gta`.
- This validates the `region` adapter. Until it's done, the rest of the region family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate