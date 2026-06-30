# Build Instructions & Seam Hardening (Fleet Reference)

This document hardens the development rules, level interpretation nuances, and integration contracts for the autonomous build-out of all ArKade cartridges.

---

## 1. The Core Philosophy: Arena Abstraction

ArKade is an **arena abstraction platform**, not a projector-mapping tool. 
- **The Scene/Level is the Model:** A physical venue is painted once (`semantic_map.png`) and compiled into derived layers (`derived/occupancy.png`, `grid.json`, `navgraph.json`, etc.).
- **The Cartridge is the Logic:** Games interpret the compiled layers dynamically.
- **Independence:** Game logic and level mapping are kept strictly separate. The cartridge must adapt to whatever semantic map it receives.

---

## 2. The Classic Map Principle (Reasoning & Adaptation)

Every classic game cartridge has a native "classic" layout (e.g., the rectilinear corridors of Pac-Man, the 10x20 well of Tetris, the 2D grid of Bomberman). When adapting these games to arbitrary, custom-painted physical spaces, follow this hierarchy of reasoning:

### A. Establish the Ideal Template
- Internally model the game's classic layout rules as constraints (e.g., Pac-Man path widths, Tetris well boundaries).

### B. Adapt Dynamically to Mapped Elements
- **Path-Following Games (Pac-Man, Frogger):** Do not assume a hardcoded navigation path. Construct the navigation graph dynamically from `grid.json` path cells or the compiled `navgraph.json` nodes. Ensure movements align strictly to orthogonal axes and grid centers.
- **Container-Bound Games (Tetris, Q*bert):** Read `container.json` bounds or parse the `occupancy.png` boundaries to define the playable "well" area. If a custom room is non-rectangular, the block matrix must adapt its collision bounds dynamically to the custom boundary outline.
- **Grid-Based Games (Bomberman, Sokoban):** Quantize the map using the level's cell size. Map walkable areas (`0`), indestructible boundaries (`1`), and destructible elements (`2`).

### C. Graceful Fallbacks & Safety Defaults
- **Never Trap Entities:** When spawning players, enemies, or key pickups, always run a BFS search (`_find_nearest_walkable_cell()`) to move spawn coordinates to the nearest valid walkable cell.
- **Bounds Clamping:** Keep all entity coordinates clamped within the map's boundary polygon.

---

## 3. Level Compilation & Custom Settings

A level directory contains:
```
levels/<level_id>/
  level.yaml              # Metadata (orientation, semantic classes)
  semantic_map.png        # Painted PNG snapping to semantic-palette-v1
  settings.json           # Real-time cartridge settings override
  derived/                # Compiled OpenCV outputs
    occupancy.png
    grid.json
    navgraph.json
    container.json
    track_centerline.json
```

### Nuance: Real-Time Filter Adjustment
- The Hub and Cartridges must support real-time quantization tweaks (e.g., **Blur Radius** and **Wall Threshold**) via a Tab settings menu.
- Moving settings sliders must instantly trigger a reload (`load_level()`) or dynamically re-compile grid occupancy on-the-fly, allowing operator adjustment without re-authoring the source semantic map.

---

## 4. Visual Standards (The Neon Law)

All cartridges must match the visual style of the design mockups (`design/frames/arkade_design_v1.html`):
- **Pure Black Base:** The backdrop must be pure `#000000` to avoid project light leakage.
- **Neon Vectors:** Render obstacles, paths, and borders as thin glowing lines (use semi-transparent colored outlines + white cores).
- **Translucent Fills:** Use high-contrast, low-opacity fills (e.g. 15% to 35% alpha) for solid elements (like Tetris blocks or Bomberman brick houses) so they stay vibrant on black without masking underlying details.
- **Reference Backgrounds:** Load the reference image (if provided) at a low opacity (e.g. 15%) and allow toggling its visibility (e.g. via `F1` or a Tab menu setting) for calibration purposes.

---

## 5. The IPC Seam (Hub ↔ Cartridge)

Cartridges are launched as separate processes by the Godot Hub. To maintain crash isolation:
- **Transmitting Heartbeats:** Cartridges must emit a `heartbeat` message every **1000 ms** over the TCP socket. The Hub will force-terminate any process that misses 3 heartbeats.
- **Command Handling:** Cartridges must immediately process incoming socket commands:
  - `load`: Reset state and load settings/level.
  - `pause`: Halt gameplay processes and timers.
  - `resume`: Unpause gameplay.
  - `blank`: Toggle rendering layers to emit pure black.
  - `quit`: Terminate the process cleanly.
- **Score Broadcasting:** Emit score updates (`{"type": "score", "data": {"player": P_ID, "score": VAL}}`) dynamically so the Hub can track stats in real-time.
