---
tags: [arkade/game-test]
type: log
status: in-progress
game: Frogger
archetype: Lane / Flow
solo_status: "❌ Untested"
map_status: "❌ Untested"
overall_status: "❌ Untested"
tested_maps: []
---

# 🟡 Frogger Testing Details

> [!info] Lane / Flow Archetype
> Frogger uses LaneAdapter to read `occupancy.png` horizontal structures.

## ⚙️ Universal Checks
- [ ] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [ ] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [ ] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [ ] **U4: Control Map** — Joystick/D-pad moves the frog correctly.
- [ ] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [ ] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [ ] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [ ] **F1: Lane Generation** — Cars/logs align and move along the horizontal bands detected from the map.
- [ ] **F2: Walkable Safe Zones** — Stepping onto walkable terrain cells is safe (does not trigger a drowning/hazard death).
- [ ] **F3: Goal Detection** — Moving into the goal zones at the top registers a level clear.
