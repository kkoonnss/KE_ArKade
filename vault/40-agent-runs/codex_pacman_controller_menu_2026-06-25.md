# Codex Pac-Man Controller Menu - 2026-06-25

## Scope
Updated Pac-Man's start/help/settings overlay so it can be operated without a mouse or keyboard shortcuts, matching the arcade/controller-first direction.

## Changes
- `content/cartridges/pacman/main.gd`
  - Added selected menu rows for Start, Help, Settings, and Players.
  - Added selected settings rows for Players, Skin, Reference overlay, Back, and Start Game.
  - Added controller navigation:
    - D-pad or left stick up/down moves the selected row.
    - D-pad or left stick left/right adjusts the selected setting.
    - A / Start accepts.
    - B / Back returns to the title menu.
  - Added keyboard parity for troubleshooting:
    - Arrows/WASD navigate and adjust.
    - Enter/Space accepts.
    - Escape/Backspace returns.
  - Kept mouse/keyboard debugging paths available, but the menu now has a controller-style focus model.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit -- --level content/scenes/scene_demo_wall/levels/260624_095010`

Both commands passed startup/parser validation.
