# KE_ArKade Shared Module

This directory contains shared palette definitions and validators generated from schemas in the vault.

## Adapters Library (Wave 0)

The `adapters/` subdirectory contains the 7 reusable archetype adapters required for cartridges to interpret map data.

### Available Adapters:
- `MazeAdapter`: Grid-to-graph logic (for Pac-Man). Returns nodes, edges, spawns, and pickups.
- `WellFillAdapter`: Reads solid regions and container boundary to fill a shape (for Tetris, Breakout). Returns bounding box and fillable cells.
- `ArenaAdapter`: Defines playfield edges and solid block cover (for Galaga, Asteroids). Returns bounds, cover blocks, and spawns.
- `LaneAdapter`: Defines horizontal traffic/water/safe lanes (for Frogger). Returns lane heights and types.
- `TrackAdapter`: Defines racing lap data and checkpoints (for On-Track). Returns centerline points and checkpoints.
- `PlatformAdapter`: Defines horizontal platforms and gravity (for Donkey Kong). Returns platform segments and spawns.
- `RegionAdapter`: Defines 2D rectangular city blocks/buildings (for GTA). Returns a list of block regions.

### Usage Contract
Every adapter provides the `interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:` function, which guarantees a non-empty play layout, falling back to a procedural minimum if the map data is insufficient.

## Separate-Project Loader Standard

Each cartridge is its own Godot project, so its `res://` points at `content/cartridges/<game>/`, not the repo root. Do not instantiate shared `class_name` globals such as `RegionAdapter.new()` or `TabMenu.new()` from a cartridge. Load `app/shared/shared_loader.gd` by absolute path, then ask it for shared scripts.

Copyable cartridge snippet:

```gdscript
var root = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir().get_base_dir().get_base_dir()
var SharedLoader = load(root.path_join("app/shared/shared_loader.gd"))
var tab_menu = SharedLoader.load_tab_menu_script().new()
var adapter = SharedLoader.load_adapter_script("region").new()
var layout = adapter.interpret(level_dir, {}, knobs)
```

Integration gate: cartridges use `SharedLoader`, not cross-project `class_name` symbols, and they do not carry local copies of `adapter_base.gd`.

## Secondary Level UI Standard

For cartridges that expose live map-fitting or secondary interpretation controls, follow:

- [SECONDARY_LEVEL_UI_STANDARD.md](C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/app/shared/SECONDARY_LEVEL_UI_STANDARD.md)

This standard defines:

- required settings group order
- standard control names
- when to use scale/reference overlays
- which secondary tuning families fit each archetype
- interaction rules for mouse, keyboard, and controller consistency

## Regeneration Build Step
To regenerate the python and Godot palette files from the frozen schema, run:

```bash
python app/shared/gen.py
```

This will automatically update:
- `app/shared/palette.py`
- `app/shared/palette.gd`
- `app/hub/shared/palette.gd` (Godot autoload copy)
