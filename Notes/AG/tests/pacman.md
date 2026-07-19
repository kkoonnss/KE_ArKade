---
tags:
  - arkade/game-test
type: log
status: in-progress
game: Pacman
archetype: Maze
solo_status:
  - 🟠In Progress
map_status: ❌ Untested
overall_status: ❌ Untested
tested_maps: []
---

# 🟡 Pacman Testing Details

> [!info] Maze Archetype
> Pacman reads `grid.json` to build its own internal navgraph. It does NOT read `navgraph.json`.

## ⚙️ Universal Checks
- [x] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [ ] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [ ] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [ ] **U4: Control Map** — Joystick/D-pad moves Pacman correctly.
- [ ] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [ ] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [ ] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [ ] **P1: Dot Spawning** — Dots populate only inside open path cells (never inside solid walls).
- [ ] **P2: Ghost AI Pathing** — Ghosts track along the generated corridors smoothly without clipping.
- [ ] **P3: Power Pellets** — Large pellets successfully turn ghosts blue, allowing them to be eaten.
- [ ] **P4: Win Condition** — Eating all dots resets the maze and increases the wave counter.
