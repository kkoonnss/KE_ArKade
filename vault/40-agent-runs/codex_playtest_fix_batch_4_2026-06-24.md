# Codex Playtest Fix Batch 4 - 2026-06-24

## Scope
Applied user playtest fixes across Galaga/Galaga, Gauntlet, Joust, On Track, Paperboy, Rampage, Robotron, Smash TV, and GTA.

## Changes
- `galaga`
  - Reworked the Galaga-style enemy loop so ships fly in from the top/sides, settle into formation, weave, dive at the player, fire during dives, and return to formation.
  - Added a subtle downward starfield scroll to make the ship feel like it is flying forward.
- `gauntlet`
  - Aim direction now persists from the last movement direction, including diagonals.
- `joust`
  - Added wave completion when all enemies are cleared.
  - Added HUD guidance: hit enemies from above and collect eggs.
- `paperboy`
  - Paper throw direction now persists from the last horizontal movement direction instead of flipping based on road position.
- `robotron_2084`
  - Robotron firing direction now persists from the last aim direction.
- `smash_tv`
  - Smash TV firing direction now persists from the last aim direction.
- `gta`
  - Retitled the cartridge to `GTA` in the Godot project, manifest, HUD, thumbnail, and splash art.
  - Removed the extra reset-time ready broadcast to reduce hub flicker/restart behavior.
- `rampage`
  - Added missing classic-level semantic metadata so the hub compatibility gate can recognize the classic Rampage level.
- `app/hub`
  - Removed duplicate `classic_on_track` On Track classic mappings.
  - Removed the duplicate `classic_on_track` level directory, leaving one classic On Track entry.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/galaga --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gauntlet --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/joust --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/paperboy --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/robotron_2084 --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/smash_tv --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gta --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/rampage --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/rampage --quit -- --scene content/scenes/scene_classic_pack --level content/scenes/scene_classic_pack/levels/classic_rampage`
- `./Godot_v4.3-stable_win64_console.exe --headless --path app/hub --quit`

All commands passed startup/parser validation.

## Reference Note
The Galaga behavior was adjusted after checking Galaga enemy behavior: enemies enter from offscreen into formation, then dive toward the player while firing, with later waves becoming more aggressive.
