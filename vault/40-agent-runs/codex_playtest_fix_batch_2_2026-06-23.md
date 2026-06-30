# Codex Playtest Fix Batch 2 - 2026-06-23

## Scope
- Fixed Rampage classic-pack routing from the hub by mapping `classic_rampage` to the `rampage` cartridge.
- Fixed Robotron (`robotron_2084`) and Smash TV (`smash_tv`) continuous movement by preserving clamped sub-cell positions on walkable cells and snapping only when blocked.
- Improved Snake (`snake`) visuals with a connected body, tapered segments, larger head, eyes, and tongue.
- Changed Tapper (`tapper`) vertical movement to one lane step per tap/short cooldown instead of racing across rows while held.
- Renamed On Track metadata from Sprint 2 to On Track and updated the first skin label.
- Adjusted On Track (`on_track`) track rendering so the vehicle rides between two visible lane rails instead of directly on the rendered line.

## Files Touched
- `app/hub/main.gd`
- `app/hub/test_sort.gd`
- `content/cartridges/robotron_2084/main.gd`
- `content/cartridges/smash_tv/main.gd`
- `content/cartridges/snake/main.gd`
- `content/cartridges/tapper/main.gd`
- `content/cartridges/on_track/main.gd`
- `content/cartridges/on_track/manifest.yaml`

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/robotron_2084 --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/smash_tv --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/snake --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/tapper --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/on_track --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/rampage --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path app/hub --quit`

All commands passed parser/startup validation.
