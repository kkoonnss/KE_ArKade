---
task_id: TASK-INT-cart-rampage
stage: 6
wave: 2
priority: P2
lane: cartridge
archetype: region
status: done
owner_agent: "KE_ArKade_260627_sharedloader_batch"
touches: [content/cartridges/rampage]
locks_required: [cart-rampage]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-cart-gta, TASK-INT-05-shared-loader-standard]
archetype_ref: gta
acceptance:
  - Reads solid contours into discrete blocks/buildings that shape the playfield (streets between blocks)
  - Block layout derives from the source image contours; streets/gaps remain traversable
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **rampage** onto the shared REGION adapter (solid contours -> city blocks / buildings) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **region** — rollout (Wave 2).

## Knobs to expose
block_size, invert, density, bounds_clamp, smooth (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/rampage/`. Read `app/shared/**` + the map read-only. Lock: `cart-rampage`.
- Depends on the family reference `TASK-INT-cart-gta`; flip to `ready` once that + the foundations are done.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).

## PLAYTEST FAIL 2026-06-26 (orchestrator-verified)
Runs but reads the map BESPOKE -> blocks misaligned vs semantic_map + no shared controls. Switch to RegionAdapter via SharedLoader (matches gta's interpretation, fixes alignment) + shared TabMenu.
GATE: copy gta exactly (SharedLoader pattern), then LAUNCH it — no crash, reads the map, shared Tab menu opens. grep must show SharedLoader and NOT XxxAdapter.new().
