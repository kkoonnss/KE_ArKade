---
tags: [arkade/game-test]
type: log
status: in-progress
game: Tetris
archetype: Well / Fill
solo_status: "❌ Untested"
map_status: "❌ Untested"
overall_status: "❌ Untested"
tested_maps: []
---

# 🟡 Tetris Testing Details

> [!info] Well / Fill Archetype
> Tetris reads `container.json` for the customized bucket/well outline.

## ⚙️ Universal Checks
- [x] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [ ] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [ ] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [ ] **U4: Control Map** — Joystick/D-pad moves pieces correctly.
- [ ] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [ ] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [ ] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [ ] **T1: Well Alignment** — Tetris pieces fall strictly inside the custom `well_polygon` (not a generic rectangle).
- [ ] **T2: Rotation & Wall Clamping** — Rotating pieces near custom walls pushes them inward safely without clipping out.
- [ ] **T3: Line Clears** — Filling a horizontal row of cells inside the custom shape clears it.
