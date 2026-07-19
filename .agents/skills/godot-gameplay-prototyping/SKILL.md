---
name: godot-gameplay-prototyping
description: Godot 4 gameplay prototyping — player controllers, physics, cameras, state machines, input handling, feel tuning. Use when the user mentions player controller, character movement, jump, dash, input map, CharacterBody2D, CharacterBody3D, RigidBody, CollisionShape, physics layers, camera follow, camera shake, state machine, tween, animation player, hit-stop, coyote time, jump buffer, or any gameplay-loop mechanic. Do NOT use for UI (use godot-4-ui), general project structure (use godot-development), or design questions like "should this game have a jump" (use game-design).
metadata:
  source: custom
  domain: gamedev
  agents: [codex, antigravity, claude, all]
  supersedes: []
  conflicts_with: [godot-development]
  status: active
  created: 2026-07-02
  last_audit: 2026-07-02
---

# Godot Gameplay Prototyping

## Purpose

Everything that makes the game feel like a game: player controllers, physics, cameras, state machines, input, feel-tuning. Prototype-first mindset: make it playable, then make it clean.

## When to use

- Player movement (walk, run, jump, dash, wall-slide, glide)
- Physics (CharacterBody, RigidBody, Area detection)
- Input mapping and rebinding
- Camera control (follow, look-ahead, screen-shake, zones)
- State machines for actors
- Feel touches (coyote time, jump buffer, hit-stop, screen shake)
- Enemy AI prototypes (patrol, chase, attack states)

## When NOT to use

- Menus, HUDs, buttons → `godot-4-ui`
- Project structure, autoloads, save systems → `godot-development`
- Design decisions ("what verbs should the player have") → `game-design`
- Playtest checklists → `game-qc-playtest`

## Core knowledge

### Input map

Set input actions in Project Settings → Input Map. Reference by string:
```gdscript
if Input.is_action_pressed("move_right"):
    velocity.x = speed
if Input.is_action_just_pressed("jump"):
    velocity.y = jump_velocity
```

Use `is_action_just_pressed` for one-shot (jump, attack), `is_action_pressed` for held (move, aim).

For rebinding, use `InputEvent` objects and modify the action's events at runtime. Persist to `user://input.cfg`.

### CharacterBody2D player template

```gdscript
class_name Player extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 1500.0
@export var friction: float = 2000.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
    # Gravity
    if not is_on_floor():
        velocity.y += gravity * delta

    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    # Horizontal
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, friction * delta)

    move_and_slide()
```

Always use `_physics_process`, not `_process`, for movement. Delta is fixed.

### Feel touches

**Coyote time** (jump forgiveness after leaving ledge):
```gdscript
var coyote_time: float = 0.1
var coyote_timer: float = 0.0

func _physics_process(delta):
    if is_on_floor():
        coyote_timer = coyote_time
    else:
        coyote_timer -= delta

    if Input.is_action_just_pressed("jump") and coyote_timer > 0:
        velocity.y = jump_velocity
        coyote_timer = 0
```

**Jump buffer** (register jump input before landing):
```gdscript
var jump_buffer_time: float = 0.1
var jump_buffer: float = 0.0

func _physics_process(delta):
    if Input.is_action_just_pressed("jump"):
        jump_buffer = jump_buffer_time
    jump_buffer -= delta

    if is_on_floor() and jump_buffer > 0:
        velocity.y = jump_velocity
        jump_buffer = 0
```

**Hit-stop** (freeze frames on impact for weight):
```gdscript
Engine.time_scale = 0.05
await get_tree().create_timer(0.05, true, false, true).timeout
Engine.time_scale = 1.0
```

**Screen shake:**
```gdscript
# Camera2D subclass
var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func shake(intensity: float) -> void:
    shake_intensity = intensity

func _process(delta):
    if shake_intensity > 0:
        offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
        shake_intensity = max(0, shake_intensity - shake_decay * delta)
    else:
        offset = Vector2.ZERO
```

### State machine pattern

For anything more than 2 states (idle/walk), use a state machine. Options:

**Enum + match** (simple):
```gdscript
enum State { IDLE, WALK, JUMP, ATTACK }
var state: State = State.IDLE

func _physics_process(delta):
    match state:
        State.IDLE: _process_idle(delta)
        State.WALK: _process_walk(delta)
        # etc
```

**Node-based** (scales better): one Node per state, an FSM Node coordinates. Godot has community FSM addons; roll your own for simple cases.

### Camera follow with look-ahead

```gdscript
# Camera2D
@export var target: Node2D
@export var look_ahead: float = 100.0
@export var smoothing: float = 5.0

func _physics_process(delta):
    if not target: return
    var target_pos := target.global_position
    if target is CharacterBody2D:
        target_pos += target.velocity.normalized() * look_ahead
    global_position = global_position.lerp(target_pos, delta * smoothing)
```

### Physics layers

Set up early. Standard convention:
- Layer 1: World
- Layer 2: Player
- Layer 3: Enemies
- Layer 4: Player projectiles
- Layer 5: Enemy projectiles
- Layer 6: Pickups
- Layer 7: Triggers

Configure in Project Settings → Layer Names → 2D Physics. Every CollisionShape must know its layer and mask.

### Areas vs bodies

- **Body** (CharacterBody, RigidBody, StaticBody): physical, moves, collides
- **Area** (Area2D/3D): non-physical, detects overlap
- Use Areas for triggers, pickups, damage zones, sensor cones
- Use bodies for anything that occupies space

## Workflow

Typical task: prototype a new player ability (e.g. dash).

1. Add to input map: `Input Map → dash → key/button`
2. Add `@export var dash_speed`, `@export var dash_duration` to player script
3. Add a `dashing` state to the state machine (or a bool flag if simple)
4. On `Input.is_action_just_pressed("dash")`: set velocity, enter dash state
5. During dash: constant velocity, ignore input
6. After duration: exit state, resume normal
7. Add visual/audio feedback (trail, sound, screen shake)
8. Playtest for feel — adjust duration, distance, cooldown
9. Only after it feels right: add cooldown UI, ammo, restrictions

## Common gotchas

- **`_process` vs `_physics_process`:** movement in `_process` gives inconsistent feel at varying framerates. Always `_physics_process`.
- **`is_on_floor()` needs `up_direction` set.** Default is Vector2.UP which is usually right.
- **Reset velocity between states.** A dash that ends with residual velocity feels floaty.
- **Delta in state timers.** Multiply by delta, not by frame count.
- **Ceiling stick.** `velocity.y = 0` when `is_on_ceiling()` during upward motion.
- **Camera jitter on subpixel positions.** Round `global_position` if using pixel-art rendering, or use SubViewport with integer scaling.
- **Input.get_axis returns -1 to 1.** Multiply by speed, don't add speed.
- **Overwriting `velocity` after `move_and_slide()`** doesn't do anything useful; it recalculates from collision.

## References

- CharacterBody2D docs: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
- Input docs: https://docs.godotengine.org/en/stable/tutorials/inputs/index.html
- Feel tuning inspiration: search "game feel juice" — GDC talks
