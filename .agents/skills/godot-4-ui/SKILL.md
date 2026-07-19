---
name: godot-4-ui
description: Godot 4 UI development — Control nodes, containers, anchors, themes, focus navigation, responsive HUDs and menus. Use when the user mentions UI, HUD, menu, button, label, container, VBoxContainer, HBoxContainer, MarginContainer, PanelContainer, anchor, theme, theme_override, focus navigation, controller support, pause menu, settings screen, or any Control-based layout in Godot. Do NOT use for gameplay physics or player controllers (use godot-gameplay-prototyping), general project structure (use godot-development), or design questions (use game-design).
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

# Godot 4 UI

## Purpose

Everything Control-node in Godot 4: layout, theming, focus navigation, responsive UI, HUDs, menus. This is the skill for anything the player looks at that isn't the game world itself.

## When to use

- Building menus (main, pause, settings, inventory)
- Building HUDs (health bar, score, minimap overlay)
- Layout questions: anchors, containers, sizing flags
- Theming and consistent visual style
- Focus navigation for controllers/keyboard-only
- Responsive UI across resolutions
- Localization concerns in UI text

## When NOT to use

- Player movement, cameras, physics → `godot-gameplay-prototyping`
- Project structure, GDScript style, autoloads → `godot-development`
- Design/UX decisions ("what should the pause menu offer?") → `game-design`

## Core knowledge

### The Control node family

All UI descends from `Control`. Key children:
- **Container types** (auto-layout): `VBoxContainer`, `HBoxContainer`, `GridContainer`, `MarginContainer`, `PanelContainer`, `CenterContainer`, `AspectRatioContainer`, `TabContainer`
- **Interactive**: `Button`, `TextureButton`, `CheckButton`, `OptionButton`, `LineEdit`, `TextEdit`, `Slider`, `SpinBox`
- **Display**: `Label`, `RichTextLabel`, `TextureRect`, `NinePatchRect`, `ProgressBar`
- **Layout**: `Control` (raw), `Panel`, `PanelContainer`

### Two layout modes

**Anchor mode** (manual): Set anchors and offsets. Good for pinning HUD elements to screen corners. `full_rect` for fullscreen overlays.

**Container mode** (automatic): Parent container drives child layout. Children ignore their own anchors; container decides. Use for menus, lists, forms.

**Rule:** Never mix. If a Control is inside a container, do not set anchors. Set size flags instead.

### Size flags in containers

- `expand`: Take remaining space along the container's axis
- `fill`: Match container's cross-axis size
- `shrink_begin`, `shrink_center`, `shrink_end`: Align within available space when not expanding
- Set via `size_flags_horizontal` and `size_flags_vertical`, or in editor inspector

### The four size properties

- `custom_minimum_size`: Minimum size the Control demands. Container respects this.
- `size`: Current runtime size. Container overwrites this.
- `position`: Runtime position. Container overwrites in container mode.
- `pivot_offset`: Rotation/scale origin. Set to `size / 2` for center pivot.

### Theming

- `Theme` resource (`.tres`) holds default styles for every Control type
- Set on the root Control of your UI; children inherit
- Per-node override: `theme_override_colors/font_color`, `theme_override_fonts/font`, `theme_override_styles/normal`, etc.
- StyleBox types: `StyleBoxFlat` (solid + border + corner radius), `StyleBoxTexture` (nine-patch), `StyleBoxEmpty`

Example StyleBoxFlat for buttons:
- `bg_color`, `border_color`, `border_width_*`, `corner_radius_*`

### Focus navigation (controller/keyboard)

Every focusable Control has `focus_next`, `focus_previous`, `focus_neighbor_left/right/top/bottom`. Set these in the editor (via NodePath) or code to build the navigation graph.

`grab_focus()` on scene entry. Set the first focusable Control in `_ready()`:
```gdscript
$MarginContainer/VBoxContainer/PlayButton.grab_focus()
```

Set `focus_mode = FOCUS_ALL` on Panels or Labels if they should be tabbable (rare).

### Responsive UI

Set **project stretch settings** first (Project Settings → Display → Window → Stretch):
- Mode: `canvas_items` for most 2D games (scales UI + world together)
- Aspect: `expand` for widescreen support, `keep` to letterbox
- Reference resolution: pick the design resolution once, stick with it

Then in UI:
- Prefer `MarginContainer` + `AspectRatioContainer` over hardcoded positions
- Use `custom_minimum_size` sparingly; let content drive size
- Test at 1280×720, 1920×1080, 2560×1440, and ultrawide

### Common patterns

**Pause menu overlay:**
- `CanvasLayer` at layer 10 (above game)
- Full-rect `Control` as background dimmer
- Centered `PanelContainer` with the menu
- `get_tree().paused = true` on show, unpause on hide

**Health bar following an enemy:**
- `Node2D` parent (world-space)
- `Control` child with `custom_minimum_size` for the bar footprint
- Update `position` in `_process()` relative to camera

**Damage numbers:**
- Pool of `Label` nodes on a `CanvasLayer`
- Tween position + modulate.a → free on tween finished
- Never instantiate/free per hit; pool for GC pressure

## Workflow

Typical task: build a settings menu.

1. Create `scenes/ui/settings_menu.tscn` with root `Control`
2. Add `MarginContainer` → `VBoxContainer` → labeled rows
3. Each row: `HBoxContainer` with `Label` (setting name) + control (slider, checkbox, dropdown)
4. Set focus_neighbors so up/down navigates the rows
5. Wire signals to a settings autoload
6. Test at multiple resolutions
7. Add back/apply buttons at the bottom

## Common gotchas

- **Anchors + containers = broken layout.** Container overrides. Remove anchors.
- **`custom_minimum_size` fights containers.** Use only when a control MUST reserve space; otherwise let content size it.
- **Focus lost on scene change.** Call `grab_focus()` on the first focusable Control in `_ready()`.
- **Buttons don't respond to controller.** Check `focus_mode = FOCUS_ALL` and that focus_neighbor paths are set.
- **Text overflows on translations.** Use `MarginContainer` with room to grow, `autowrap_mode = AUTOWRAP_WORD` on Labels.
- **CanvasLayer children ignore camera zoom.** Which is usually what you want for UI — that's the point.
- **Modulate vs self_modulate.** `modulate` cascades to children, `self_modulate` doesn't. Use `self_modulate` to fade a panel without dimming its labels.

## References

- Godot UI docs: https://docs.godotengine.org/en/stable/tutorials/ui/index.html
- Custom themes tutorial: https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html
