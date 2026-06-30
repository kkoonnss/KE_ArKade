---
task_id: TASK-INT-cart-on_track
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: track
status: done
owner_agent: "KE_ArKade_260626_132556"
touches: [content/cartridges/on_track]
locks_required: [cart-on_track]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit]
archetype_ref: on_track
acceptance:
  - REFERENCE for the track family -> prove the adapter end to end before the rest of the family rolls out
  - Reads track_centerline.json into a lap with checkpoints; 1-4 players
  - Off-track = the bounds; laps + checkpoint logic work on an authored traced line
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **on_track** onto the shared TRACK adapter (track_centerline -> a lap) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **track** — REFERENCE (Wave 1).

## Knobs to expose
track_friction, top_speed, checkpoint_spacing, wall_forgiveness, bounds_clamp (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/on_track/`. Read `app/shared/**` + the map read-only. Lock: `cart-on_track`.
- This validates the `track` adapter. Until it's done, the rest of the track family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate ticket).
