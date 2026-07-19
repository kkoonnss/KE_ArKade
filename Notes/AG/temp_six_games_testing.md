---
tags: [experimental, strategy, todo]
type: log
status: in-progress
connections: [qa_checklist]
---

# 🎮 Temp QA Checklist: First 6 Games (Projector Ready)

> [!warning] Temporary Document (Expiration Date: July 10, 2026)
> This is a quick-testing scratchpad for Kons to verify the bare-bones mechanics of the first 6 reference cartridges on the projector setup. Once verified, this file can be safely deleted. Refer to the master checklist in [[qa_checklist]] for full regression details.

---

## ⚙️ Universal Core Checks
Verify these on *all* 6 games using at least 2 custom levels (e.g. `rock_wall`, `gallery`) plus their classic layouts.

- [ ] **Boots Cleanly** — No grey screens, locks, or loading freezes.
- [ ] **Grid Boundaries** — Game occupies *only* the mapped wall region, not the whole viewport window.
- [ ] **Settings Persist** — Adjust a knob (e.g., scale), exit, and re-launch. The value must persist.
- [ ] **Settings are Per-Level** — Altering a setting on Level A does not affect Level B.
- [ ] **Tab/Start Overlay** — Pressing keyboard `Tab` or controller `Start` opens the overlay menu.
- [ ] **Double-Launch Guard** — Verify you cannot start a second cartridge while one is currently running.
- [ ] **Fallback Mode** — Renaming the level's `derived/` folder boots a basic playable default layout.

---

## 👾 Per-Game Mechanical Verification

### 🟡 1. Pacman (Maze)
*Reads `grid.json` to build custom walkable corridors.*
- [ ] **Dot Spawning** — Dots populate only inside open path cells (never inside solid walls).
- [ ] **Ghost AI Pathing** — Ghosts track along the generated corridors smoothly without clipping or getting stuck.
- [ ] **Power Pellets** — Powerups successfully turn ghosts blue, allowing them to be eaten for chain score points.
- [ ] **Clear Board** — Eating all dots resets the maze and increases the wave counter.

### 🟡 2. Asteroids (Arena)
*Reads `grid.json` for solid boundaries and writes `secondary_map.png`.*
- [ ] **Wall Collisions** — Ship bounces off custom solid geometries; bullets disintegrate when they hit walls.
- [ ] **Boundary Wrap** — Ship and bullets wrap around dynamically when crossing the outer boundaries.
- [ ] **Analog Controls** — Joystick/D-Pad rotates, and **A** or **Up** applies thrusters.

### 🟡 3. Tetris (Well/Fill)
*Reads `container.json` for the customized bucket/well outline.*
- [ ] **Well Shape Snapping** — Dropped tetrominoes fall and lock strictly inside the custom well container boundaries.
- [ ] **Rotation Push** — Rotating pieces near custom walls pushes them inward safely without clipping out.
- [ ] **Row Clear** — Completing a horizontal line inside the custom shape clears it.

### 🟡 4. Frogger (Lane/Flow)
*Uses LaneAdapter to read `occupancy.png` horizontal structures.*
- [ ] **Lane Auto-Detect** — Log streams and traffic align perfectly with the auto-detected horizontal bands.
- [ ] **Safe Walkways** — Stepping onto walkable terrain cells is safe (does not trigger a drowning/hazard death).
- [ ] **Goal Detection** — Moving into the goal zones at the top registers a level clear.

### 🟡 5. Donkey Kong (Platform/Gravity)
*Reads `platform_edges.json` and `occupancy.png`.*
- [ ] **Platform Physics** — Character is pulled down by gravity and lands cleanly on custom horizontal platforms.
- [ ] **Ladder Connections** — Vertical ladders generate and allow climbing between platform levels.
- [ ] **Classic/Sub-Modes** — Standard Barrel mode, Breakout mode, and Bubble mode boot and play correctly.

### 🟡 6. Galaga (Arena/Shooter)
*Reads `grid.json` to lock playfield and spawn positions.*
- [ ] **Play Space Restrict** — Player ship movement is strictly clamped within the custom bottom playfield bounds.
- [ ] **Swarm Entrances** — Enemy ships enter from off-screen and assemble themselves inside the custom grid space.
- [ ] **Collisions** — Player bullets hit enemies, and enemy hits destroy player ships.
