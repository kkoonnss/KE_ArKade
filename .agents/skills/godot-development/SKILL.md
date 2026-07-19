---
name: godot-development
description: Godot 4 GDScript development conventions, project structure, and core patterns. Use when the user mentions Godot, GDScript, .gd files, .tscn scenes, .tres resources, autoloads, signals, groups, project.godot, or is working inside a Godot project directory. Also triggers on Godot debug workflow, export presets, and editor plugin questions. Do NOT use for game design questions (use game-design), UI layout specifics (use godot-4-ui), or player controller / physics prototyping (use godot-gameplay-prototyping).
metadata:
  source: custom
  domain: gamedev
  agents: [codex, antigravity, claude, all]
  supersedes: []
  conflicts_with: [godot-4-ui, godot-gameplay-prototyping]
  status: active
  created: 2026-07-02
  last_audit: 2026-07-02
---

# Godot Development

## Purpose

Godot 4.x general development: project structure, GDScript style, scene composition, signals, resources, autoloads, save/load, debug workflow, export. This is the base skill for anything happening inside a Godot project that isn't specifically UI, gameplay physics, or design.

## When to use

- User is editing `.gd`, `.tscn`, `.tres`, `.gdshader`, or `project.godot`
- Questions about project structure, naming, folder conventions
- Signals, autoloads, groups, node lifecycle
- Save/load systems
- Editor plugins, `@tool` scripts
- Debug and export workflow

## When NOT to use

- UI-specific layout (Control nodes, containers, themes) → `godot-4-ui`
- Player controllers, physics, cameras, state machines → `godot-gameplay-prototyping`
- Design questions (core loop, encounter design) → `game-design`
- Playtesting and QC → `game-qc-playtest`

## Core knowledge

### Project structure convention

```
project/
├── project.godot
├── addons/            # editor plugins
├── assets/            # raw content by type
│   ├── audio/
│   ├── fonts/
│   ├── sprites/
│   └── models/
├── scenes/            # .tscn files grouped by feature
├── scripts/           # .gd files (co-located with scenes when tightly coupled)
├── resources/         # .tres data files (configs, stats, item defs)
├── shaders/
├── autoload/          # singletons
└── ui/                # menus, HUDs
```

Co-locate a scene and its script if the script only serves that scene: `scenes/player/player.tscn` + `scenes/player/player.gd`. Move to `scripts/` only if reused.

### GDScript style

- `snake_case` for variables, methods, files
- `PascalCase` for classes, nodes when treated as types, enums
- `SCREAMING_SNAKE_CASE` for constants
- Type hints everywhere: `var speed: float = 200.0`, `func take_damage(amount: int) -> void:`
- Prefer `@export` over exposing raw properties in inspector via legacy syntax
- Use `@onready` for node references: `@onready var sprite: Sprite2D = $Sprite2D`
- Class name only when the script will be instantiated as a type: `class_name Player extends CharacterBody2D`

### Signals

- Declare with typed args: `signal health_changed(new_health: int, max_health: int)`
- Emit with typed args
- Connect in code with Callable: `player.health_changed.connect(_on_player_health_changed)`
- Prefer signals over parent-child polling for cross-node communication
- Avoid signal chains longer than 2 hops — introduce an event bus autoload if you need broadcast

### Resources (.tres) as data

Use custom `Resource` scripts for configuration and content:
```gdscript
class_name EnemyStats extends Resource

@export var max_health: int = 100
@export var move_speed: float = 150.0
@export var damage: int = 10
```

Save as `.tres` files under `resources/`. This lets non-programmers tune values without touching code.

### Autoloads

Set in Project Settings → Autoload. Use for:
- Global event bus
- Save/load manager
- Scene switcher
- Audio manager
- Input mapper (if abstracting)

Don't use autoloads for content or transient game state.

### Groups

`add_to_group("enemies")` then `get_tree().get_nodes_in_group("enemies")` for broadcasts. Cheaper than autoload registries for spatial queries.

### Save/load pattern

Use `FileAccess` with JSON or `ResourceSaver`/`ResourceLoader` for structured saves. Prefer `.tres` for editor-inspectable saves, JSON for text-portable saves.

```gdscript
var save_data := {"level": 3, "hp": 78}
var file := FileAccess.open("user://save.json", FileAccess.WRITE)
file.store_string(JSON.stringify(save_data))
```

`user://` path resolves to per-user save location (varies by OS). Never write to `res://` at runtime.

### Debug workflow

- Print debugging: `print()`, `printerr()`
- Assertions: `assert(condition, "message")` — stripped in release builds
- Breakpoints: click the gutter in the editor
- Remote scene tree: Debug → Remote Scene when running from editor
- Profiler: Debug → Profiler for frame time breakdown
- Log to file for playtest sessions: use a `Logger` autoload writing to `user://logs/`

### Export

- Configure export presets in Project → Export
- Include only the folders needed (exclude `docs/`, `notes/`)
- Custom features per preset for platform-specific code paths
- Test the exported build, not just editor runs — export catches missing resource loads

## Workflow

Typical task: add a new feature to a Godot project.

1. Read `project.godot` for engine version and autoloads
2. Read existing scenes in the affected area to match conventions
3. Create the new scene file at the co-located path
4. Attach the script, add type hints, `@onready` references, signals
5. Wire signals in `_ready()` or via editor if visual
6. Test in isolation via a temporary scene
7. Integrate into main flow
8. Commit with a clear message tied to the feature

## Common gotchas

- **`@onready` before `_ready()`:** if you try to access an `@onready` var in `_init()`, it's null. `_ready()` is when the tree is settled.
- **`get_node()` vs `$`:** both work; `$Node/Path` is nicer for stable paths, `get_node()` for dynamic paths built from strings.
- **Signal disconnect on scene change:** if a node emits to another that's freed, the receiver won't fire but no error. Use `is_instance_valid()` when in doubt.
- **`preload()` vs `load()`:** `preload()` is compile-time, faster but rigid. `load()` is runtime, use for dynamic content.
- **`queue_free()` timing:** the node is freed at end of frame, not immediately. Don't access it after calling.
- **Godot 3 → 4 migration confusion:** if code online uses `yield`, `KinematicBody2D`, or `Sprite`, it's Godot 3. Godot 4 uses `await`, `CharacterBody2D`, `Sprite2D`.

## References

- Godot official docs: https://docs.godotengine.org/en/stable/
- GDScript style guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- Godot 4 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.html
