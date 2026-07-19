---
tags:
  - arkade/game-test
type: log
status: pending
game: Rampage
archetype: Platform / Gravity
solo_status:
  - 🟠In Progress
map_status:
  - ❌ Untested
overall_status:
  - ❌ Untested
tested_maps:
---

# 🦖 Rampage Testing Details

> [!info] Platform / Gravity Archetype
> Rampage reads `grid.json` to generate destructible buildings and environments.

## ⚙️ Universal Checks
- [x] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [x] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [ ] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [ ] **U4: Control Map** — Joystick/D-pad moves the monster correctly.
- [ ] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [ ] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [ ] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [ ] **R1: Building Destruction** — Punching buildings breaks segments correctly.
- [ ] **R2: Climbing** — Monster can attach to and climb the sides of buildings.
- [ ] **R3: Falling** — Monster falls properly when building collapses.


