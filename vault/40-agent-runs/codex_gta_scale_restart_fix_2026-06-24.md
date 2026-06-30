# Codex GTA Scale + Restart Fix - 2026-06-24

## Scope
Fixed GTA appearing smaller than the cartridge window/projection area and addressed hub restart behavior.

## Changes
- `content/cartridges/gta/main.gd`
  - Added viewport-fit scaling and centered draw offset so semantic maps of any size fill the cartridge viewport on their long side.
  - Reset drawing transform before HUD rendering so text stays screen-space and does not shrink with the map.
  - Moved bottom objective HUD text to viewport height instead of map height.
  - Fixed IPC connection handling:
    - The cartridge now polls the TCP socket.
    - `ready` is sent only after the socket reaches `STATUS_CONNECTED`.
    - This avoids marking `ready_sent` before the message can actually be transmitted.
  - Hardened `load` IPC handling:
    - Reads level changes from nested `data.level_dir` or top-level `level_dir`.
    - Ignores redundant load messages for the already-loaded level instead of resetting the round.

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gta --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gta --quit -- --scene content/scenes/scene_classic_pack --level content/scenes/scene_classic_pack/levels/classic_gta`

Both commands passed startup/parser validation.

## Remaining Manual Check
Manual hub playtest should verify GTA no longer appears as a smaller inset and that the hub no longer kills/relaunches it due to missing ready/heartbeat timing.
