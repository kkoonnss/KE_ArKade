---
run_id: codex_cart_rampage_sharedloader_2026-06-27
task_id: TASK-INT-cart-rampage
agent: KE_ArKade_260627_sharedloader_batch
status: done
---

# Rampage SharedLoader Integration

## Changes
- Replaced bespoke map parsing with SharedLoader-loaded `region` adapter interpretation.
- Added shared Tab menu with region knobs: `block_size`, `density`, `smooth`, `invert`, `bounds_clamp`, `reference`.
- Kept fallback rasterization so sparse or region-only adapter output never boots empty.

## Verification
- Gate grep: `SharedLoader` present; `Adapter.new()` and `TabMenu.new()` absent.
- Classic launch: `Rampage SharedLoader RegionAdapter ... grid=30x18 cell_px=32`.
- Demo wall launch: `Rampage SharedLoader RegionAdapter ... grid=60x34 cell_px=32`.
- Screenshots:
  - `vault/70-qa/rampage_classic_sharedloader_2026-06-27.png`
  - `vault/70-qa/rampage_demo_wall_sharedloader_2026-06-27.png`

