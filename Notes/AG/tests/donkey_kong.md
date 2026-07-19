---
tags:
  - arkade/game-test
type: log
status: in-progress
game: Donkey Kong
archetype: Platform / Gravity
solo_status:
  - ✅ Pass
map_status:
  - ✅ Pass
overall_status:
  - ✅ Pass
tested_maps: []
---

# 🟡 Donkey Kong Testing Details

> [!info] Platform / Gravity Archetype
> Donkey Kong reads `platform_edges.json` and `occupancy.png`.

## ⚙️ Universal Checks
- [x] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [x] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [x] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [x] **U4: Control Map** — Joystick/D-pad moves the character correctly.
- [x] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [x] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [x] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [x] **D1: Platform Snapping** — Girder paths map to the horizontal platform structures.
- [x] **D2: Physics & Ladders** — Gravity functions (DK/Mario fall to platforms) and generated ladders can be climbed.
- [x] **D3: Classic/Sub-Modes** — Standard Barrel mode, Breakout mode, and Bubble mode boot and play correctly.
