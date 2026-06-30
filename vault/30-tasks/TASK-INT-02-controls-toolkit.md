---
task_id: TASK-INT-02-controls-toolkit
stage: 6
wave: 0
priority: P0
lane: shared
archetype: n/a
status: done
owner_agent: "Antigravity"
touches: [app/shared]
locks_required: [shared-adapters]
depends_on: [TASK-INT-01-adapter-library]
acceptance:
  - app/shared gains a map-fit ops module -> fill/invert, block_region, bounds_clamp, grid_scale, wall_width (dilate/erode), density, smooth/close, reference_opacity (PLAN §4)
  - All ops run IN MEMORY on the grid/mask at game start; none mutate semantic_map.png
  - A shared controller-navigable Tab-menu shell -> generalized from pacman's settings overlay; a cartridge registers its relevant knobs and the shell renders + persists them
  - Persistence uses the existing level_adjustments.gd pattern (per cartridge, keyed scene_id/level_id); replaces the per-cartridge copy-paste with one shared shell
  - Tab shell is fully operable on controller (D-pad move, left/right adjust, A select, Start/Tab open-close) AND keyboard/mouse
  - Verified -> pacman re-pointed at the shared shell reproduces its current invert/grid-scale/wall-width/opacity controls with identical results
---

## Objective
Generalize Pac-Man's per-game Tab menu (invert/scale/wall-width/opacity) into a shared, reusable secondary-controls toolkit: the in-memory map-fit ops plus one settings-menu shell every cartridge dresses with its own knobs. This is the "deeper per-game manipulation of the color map" Kons asked for — implemented once, not 33 times.

## Notes
- Same `app/shared` tree as TASK-INT-01 — must run AFTER it (depends_on). One owner in this tree at a time.
- Ops must compose (e.g. invert then fill then bounds-clamp) deterministically.
- Freeze with INT-01 at end of Wave 0; cartridge agents consume read-only.
