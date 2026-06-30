# Codex Pac-Man Reference Opacity Settings - 2026-06-25

## Scope
Added controller-friendly Pac-Man level-adjustment settings for overlaying the original reference image while evaluating generated gameplay maps.

## Changes
- `content/cartridges/pacman/main.gd`
  - Added a selectable `Reference Opacity` settings row with a 10-step text bar and percentage.
  - Left/right or D-pad/left-stick adjusts opacity in 5% increments.
  - Adjusting opacity automatically enables the reference overlay.
  - `Reference Overlay` remains a selectable on/off row.
  - Settings are saved per level to `user://level_adjustments.json`.
  - Saved fields: players, skin, reference enabled, reference opacity.
  - IPC `load` now reloads Pac-Man's per-level adjustments for the incoming level.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit -- --level content/scenes/scene_demo_wall/levels/260624_095010`

Both commands passed startup/parser validation.
