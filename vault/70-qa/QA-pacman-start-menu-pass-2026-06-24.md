# QA - Pac-Man + Start Menu Pass - 2026-06-24

## Result
Pass for targeted Godot headless startup/parser validation.

## Covered Reports
- Pac-Man has too many blue lines: classic rails now only draw on tunnel-like edges.
- Big blank areas should use points instead of rails: sparse open-area dots were added.
- Ghosts should be smarter: ghost turn selection now uses chase, ambush, flank, and scatter targets.
- Pac-Man lacks a Tab menu: Pac-Man now has Start, Help, Settings, player count, Tab settings, and Escape-to-title overlay behavior.
- Cartridges should start on splash/title until Start: rolled out to Pac-Man and the 10 generated classic cartridges in this pass.

## Validation Commands
Passed:
- `pacman` with `scene_demo_wall/levels/260624_095010`
- `donkey_kong`
- `breakout`
- `bubble_bobble`
- `dig_dug`
- `gauntlet`
- `marble_madness`
- `joust`
- `snake`
- `tapper`
- `tempest`

## Remaining Risk
Headless validation does not simulate pressing Start/Tab or manually inspecting the Pac-Man open-area dot density. The remaining cartridge families still need the same start-screen treatment in a follow-up pass.
