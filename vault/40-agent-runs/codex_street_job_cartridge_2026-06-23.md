# Codex GTA Cartridge - 2026-06-23

## Scope
Added a new top-down city crime/action cartridge inspired by early bird's-eye city games, implemented as a neutral ArKade cartridge named `gta` with the display title `GTA`.

## Mechanics Implemented
- Static semantic-map city interpretation:
  - `path` cells become streets for traffic.
  - `tracking` / `ui_safe` / `spawn` / `goal` / `pickup` cells become sidewalks and mission-accessible walk space.
  - `solid` cells become buildings.
- Player can walk around the city with keyboard/controller movement.
- Player can shoot with ammo; bullets can hit pedestrians or cops.
- Nearby cars can be stolen/entered with `E` / `Space`.
- In-car mode drives faster, steers freely, and exits back to nearest safe sidewalk.
- Pedestrians wander sidewalks.
- Traffic cars drive on road cells and turn at road continuity.
- Ringing payphones start missions.
- Missions progress phone -> package pickup -> delivery dropoff -> next phone.
- Cash/ammo drops can spawn when pedestrians are killed.
- Wanted-star escalation:
  - Stealing cars, shooting, hitting pedestrians/cars, and attacking cops raise wanted level.
  - Cops spawn and chase when wanted is active.
  - Hiding far from cops gradually reduces wanted stars.

## Files Added
- `content/cartridges/gta/project.godot`
- `content/cartridges/gta/main.tscn`
- `content/cartridges/gta/main.gd`
- `content/cartridges/gta/manifest.yaml`
- `content/cartridges/gta/splash.png`
- `content/cartridges/gta/thumbnail.png`
- `content/scenes/scene_classic_pack/levels/classic_gta/level.yaml`
- `content/scenes/scene_classic_pack/levels/classic_gta/semantic_map.png`
- `content/scenes/scene_classic_pack/levels/classic_gta/thumb.png`

## Files Updated
- `app/hub/main.gd`
- `app/hub/test_sort.gd`

## Validation
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gta --quit`
- `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/gta --quit -- --scene content/scenes/scene_classic_pack --level content/scenes/scene_classic_pack/levels/classic_gta`
- `./Godot_v4.3-stable_win64_console.exe --headless --path app/hub --quit`

All commands passed startup/parser validation.
