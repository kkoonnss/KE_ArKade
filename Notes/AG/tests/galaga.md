---
tags: [arkade/game-test]
type: log
status: in-progress
game: Galaga
archetype: Open Arena
solo_status: "❌ Untested"
map_status: "❌ Untested"
overall_status: "❌ Untested"
tested_maps: []
---

# 🟡 Galaga Testing Details

> [!info] Open Arena Archetype
> Galaga reads `grid.json` to lock playfield and spawn positions.

## ⚙️ Universal Checks
- [ ] **U1: Boots Cleanly** — No grey screens or freezes on startup.
- [ ] **U2: Viewport Fit** — Gameplay is bound to the wall region, not the whole window.
- [ ] **U3: Settings Persist** — Knob changes are saved and restored on reload.
- [ ] **U4: Control Map** — Joystick/D-pad moves the ship correctly.
- [ ] **U5: Tab/Start Overlay** — Menu toggles on Tab or controller Start.
- [ ] **U6: Double-Launch Guard** — Cannot launch another game while running.
- [ ] **U7: Fallback Boot** — Boots default layout if `derived/` is missing.

## 🎯 Game-Specific Checks
- [ ] **G1: Boundary Clamping** — Player ship movement is strictly clamped within the custom bottom playfield bounds.
- [ ] **G2: Swarm Entrances** — Enemy ships enter from off-screen and assemble themselves inside the custom grid space.
- [ ] **G3: Collisions** — Player bullets hit enemies, and enemy hits destroy player ships.
