# Codex Pac-Man + Start Menu Pass - 2026-06-24

## Scope
Applied a focused Pac-Man readability/control pass and began the shared cartridge start-screen rollout.

## Changes
- `pacman`
  - Added a cartridge start overlay that keeps the splash visible until Enter/Space.
  - Added Help and Settings overlay modes with player count selection hints.
  - Added Tab settings behavior and Escape-to-title behavior.
  - Classic Pac-Man maze rails now draw only on tunnel-like path edges instead of every open walkable edge.
  - Large blank/open areas now get sparse collectible dots rather than dense blue corridor rails.
  - Ghost movement is no longer purely random: ghosts now choose turns using chase, ambush, flank, and scatter-style targets.
- 10 generated classic cartridges
  - Added a shared start-state flow using the existing splash + tab overlay layer.
  - Covered: `donkey_kong`, `breakout`, `bubble_bobble`, `dig_dug`, `gauntlet`, `marble_madness`, `joust`, `snake`, `tapper`, `tempest`.
  - Cartridges now begin at a start screen with Start/Help/Settings/Players text and only enter gameplay after Enter/Space.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/pacman --quit -- --level content/scenes/scene_demo_wall/levels/260624_095010`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/donkey_kong --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/breakout --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/bubble_bobble --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/dig_dug --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gauntlet --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/marble_madness --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/joust --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/snake --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/tapper --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/tempest --quit`

All commands passed startup/parser validation.

## Remaining Follow-Up
The earlier generated family and unique cartridges still need the same polished start-screen treatment in a follow-up pass: `centipede`, `space_invaders`, `robotron_2084`, `burger_time`, `galaga`, `missile_command`, `defender`, `lunar_lander`, `paperboy`, `qbert`, plus the older unique carts such as `bomberman`, `tetris`, `rampage`, `gta`, `battlezone`, and the light/paddle/asteroids group.
