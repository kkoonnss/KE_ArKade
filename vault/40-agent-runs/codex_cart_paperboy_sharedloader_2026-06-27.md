---
run_id: codex_cart_paperboy_sharedloader_2026-06-27
task_id: TASK-INT-cart-paperboy
agent: KE_ArKade_260627_sharedloader_batch
status: done
---

# Paperboy SharedLoader Integration

## Changes
- Added SharedLoader-loaded `lane` adapter interpretation and lane-to-gameplay grid conversion.
- Added the shared Tab menu with lane knobs: `grid_scale`, `density`, `invert`, `bounds_clamp`, `reference`.
- Dismissed the cover layer on Start so gameplay remains visible after the player starts.

## Verification
- Gate grep: `SharedLoader` present; `Adapter.new()` and `TabMenu.new()` absent.
- Classic launch: `Paperboy SharedLoader LaneAdapter ... grid=60x30 lanes=30`.
- Demo wall launch: `Paperboy SharedLoader LaneAdapter ... grid=30x16 lanes=16`.
- Screenshots:
  - `vault/70-qa/paperboy_classic_sharedloader_2026-06-27.png`
  - `vault/70-qa/paperboy_demo_wall_sharedloader_2026-06-27.png`
  - `vault/70-qa/paperboy_classic_after_start_sharedloader_2026-06-27.png`

