---
tags:
  - arkade/game-test
type: log
status: in-progress
game: Asteroids
archetype: Open Arena
solo_status:
  - ✅ Pass
map_status:
  - ✅ Pass
overall_status:
  - ✅ Pass
tested_maps:
---

# 🟡 Asteroids Testing Details

> [!info] Open Arena Archetype
> Asteroids reads `grid.json` to generate solid collision walls and writes `secondary_map.png`.

## ⚙️ Universal Checks
- [x] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [x] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [x] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [x] **U4: Control Map** — Joystick/D-pad moves the ship correctly.
- [x] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [x] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [x] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [x] **A1: Wall Collision** — Ship bounces off custom solid geometries; bullets disintegrate when they hit walls.
- [x] **A2: Boundary Wrap** — Ship and bullets wrap around dynamically when crossing the outer boundaries.
- [x] **A3: Rotational Control** — Left/Right rotates, and Up (or A button) applies thrusters. 
- [ ]actually a button shoots up is thrust
