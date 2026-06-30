---
run_id: codex_cart_asteroids_sharedloader_2026-06-27
task_id: TASK-INT-cart-asteroids
agent: KE_ArKade_260627_sharedloader_batch
status: done
---

# Asteroids SharedLoader Integration

## Changes
- Added SharedLoader-loaded `arena` adapter interpretation for bounds and cover blocks.
- Replaced the old in-cartridge Players/Reference overlay with the shared Tab menu.
- Exposed arena knobs: `bounds_clamp`, `density`, `block_region`, `invert`, `reference_opacity`, `reference`.

## Verification
- Gate grep: `SharedLoader` present; `Adapter.new()` and `TabMenu.new()` absent.
- Classic launch: `Asteroids SharedLoader ArenaAdapter ... grid=60x34 cover=1200`.
- Demo wall launch: `Asteroids SharedLoader ArenaAdapter ... grid=60x34 cover=0`.
- Screenshots:
  - `vault/70-qa/asteroids_classic_sharedloader_2026-06-27.png`
  - `vault/70-qa/asteroids_demo_wall_sharedloader_2026-06-27.png`

