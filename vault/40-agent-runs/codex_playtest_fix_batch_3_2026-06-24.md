# Codex Playtest Fix Batch 3 - 2026-06-24

## Scope
Applied user playtest fixes across Battlezone, Breakout, Bubble Bobble, Burger Time, Centipede, Defender, Dig Dug, Donkey Kong, and Frogger.

## Changes
- `battlezone`
  - Added bullet/enemy collision inside the bullet tick so Battlezone shots can reliably kill enemies after movement/cleanup.
- `breakout`
  - Converted powerups into timed, obvious effects:
    - `wide`: timed wide paddle.
    - `slow`: timed ball speed cap.
    - `laser`: timed paddle laser shots.
    - `shield`: timed bottom safety rail.
    - `life` and `bonus` remain instant.
  - Added active powerup HUD text and distinct pickup colors.
- `bubble_bobble`
  - Bubble hits now immediately trap enemies, freeze the bubble into a capture state, and attach the enemy to it.
  - Player now snaps to the bottom floor as grounded so they can jump instead of getting stuck at the bottom.
- `burger_time`
  - Added a start/help overlay for Burger Time that waits on Enter/Space before gameplay ticks.
  - Overlay includes objective, controls, Tab settings hint, and pregame player-join placeholder text.
- `centipede`
  - Increased wave scaling: more segments, faster head speed, denser/tougher barriers, and small extra segment spawns on later waves.
- `defender`
  - Increased wave scaling: fewer humans to defend over time, more/faster enemies, and wave-scaled enemy weave.
- `dig_dug`
  - Inverted the Dig Dug playfield so it starts mostly filled with dirt.
  - Carved starter tunnels and intermittent custom-map tunnels.
  - Digging opens walkable cells.
  - Non-ghost enemies now follow existing tunnels; ghosting lets them phase through dirt temporarily.
- `donkey_kong`
  - Barrels now detect ladders, sometimes roll down them, and resume sideways rolling on the next lower platform.
- `frogger`
  - Updated Godot project window title from `Frogger` to `Frogger`.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/battlezone --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/breakout --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/bubble_bobble --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/burger_time --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/centipede --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/defender --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/dig_dug --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/donkey_kong --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/frogger --quit`

All commands passed startup/parser validation.

## Reference Note
Dig Dug's terrain model was adjusted using the classic design premise that the stage begins mostly as underground dirt, with the player digging tunnels and enemies using tunnels unless temporarily ghosting.
