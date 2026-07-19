---
tags:
  - arkade/game-test
type: log
status: pending
game: Paperboy
archetype: Lane / Flow
solo_status:
  - 🟠In Progress
map_status:
  - ❌ Untested
overall_status:
  - ❌ Untested
tested_maps:
---

# 📰 Paperboy Testing Details

> [!info] Lane / Flow Archetype
> Paperboy reads `grid.json` to generate paths and obstacles.

## ⚙️ Universal Checks
- [ ] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [ ] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [ ] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [ ] **U4: Control Map** — Joystick/D-pad moves the bike correctly.
- [ ] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [ ] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [ ] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [ ] **P1: Path Alignment** — Bike correctly follows the generated path.
- [ ] **P2: Obstacle Collision** — Hitting obstacles triggers crash.
- [ ] **P3: Newspaper Delivery** — Throwing papers lands on targets.
