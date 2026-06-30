# QA - Pac-Man Controller Menu - 2026-06-25

## Result
Pass for targeted Godot headless startup/parser validation.

## Covered Report
- Pac-Man settings need to be selectable by controller, not only shortcut keys or mouse.

## Validation Commands
Passed:
- `pacman` standalone
- `pacman` with `scene_demo_wall/levels/260624_095010`

## Remaining Manual Check
Manual playtest should verify actual USB SNES-style controllers map D-pad/A/B/Start as expected. The code also supports left-stick navigation for cheap modern controllers.
