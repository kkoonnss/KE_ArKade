# Codex Pac-Man Rail Trim - 2026-06-25

## Scope
Trimmed the classic Pac-Man maze rails so the line endpoints no longer overrun junctions and leave visible tail stubs.

## Changes
- `content/cartridges/pacman/main.gd`
  - Shortened classic rail draw segments before rendering the blue outer line and black inner line.
  - This keeps the maze edges inside the tunnel geometry and removes the protruding tail effect at corners and dead ends.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit -- --level content/scenes/scene_demo_wall/levels/260624_095010`

Both commands passed startup/parser validation.
