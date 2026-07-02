extends Control

var Palette
var SharedLoader

@onready var bg_rect = $Layout/Workspace/CanvasMargin/CanvasContainer/BgRect
@onready var semantic_rect = $Layout/Workspace/CanvasMargin/CanvasContainer/SemanticRect
@onready var virtual_cursor = $Layout/Workspace/CanvasMargin/CanvasContainer/VirtualCursor
@onready var sidebar_vbox = $Layout/Sidebar/Scroll/VBox
@onready var file_dialog = $FileDialog
@onready var canvas_container = $Layout/Workspace/CanvasMargin/CanvasContainer

var current_image_path: String = ""
var semantic_image: Image
var semantic_texture: ImageTexture
var is_painting: bool = false
var brush_size: int = 10
var current_class_id: int = 1
var opacity: float = 0.5
var show_bg: bool = true
var cursor_pos: Vector2 = Vector2()

var cv_params = {
    "preset": "Balanced Semantic",
    "blur": 2,
    "canny_low": 50,
    "canny_high": 150,
    "morph_dilate": 2,
    "min_contour_area": 100,
    "invert_mask": false,
    "walkable_bias": 72,
    "feature_density": 55,
    "hazard_density": 18,
    "pickup_density": 45,
    "platform_bias": 45,
    "tracking_ui_guide": 30
}

var derive_slider_controls := {}
var derive_preset_profiles = {
    "Balanced Semantic": {
        "blur": 2,
        "canny_low": 50,
        "canny_high": 150,
        "morph_dilate": 2,
        "walkable_bias": 72,
        "feature_density": 55,
        "hazard_density": 18
    },
    "Open Flow": {
        "blur": 1,
        "canny_low": 35,
        "canny_high": 115,
        "morph_dilate": 1,
        "walkable_bias": 84,
        "feature_density": 62,
        "hazard_density": 10
    },
    "Vertical Surfaces": {
        "blur": 2,
        "canny_low": 60,
        "canny_high": 170,
        "morph_dilate": 3,
        "walkable_bias": 54,
        "feature_density": 46,
        "hazard_density": 24
    }
}

var derive_thread: Thread
var is_deriving: bool = false
var needs_derive: bool = false

var class_buttons = []
var temp_json_path = "user://temp_author_args.json"
var temp_map_path = "user://temp_semantic_map.png"

# --------------------------------------------------------------------------
# Preview mode (TASK-INT-10)
# --------------------------------------------------------------------------

# Tracks the level directory a Load/Save actually touched, so preview can
# read/write derived/** and level_edit/** in the right place. Empty until a
# level has been loaded or saved at least once in this session.
var current_level_dir: String = ""

const PREVIEW_GAMES = [
    {"id": "pacman", "archetype": "maze", "adapter": "maze", "title": "PAC-MAN"},
    {"id": "tetris", "archetype": "well_fill", "adapter": "well_fill", "title": "TETRIS"},
    {"id": "galaga", "archetype": "arena", "adapter": "arena", "title": "GALAGA"},
    {"id": "frogger", "archetype": "lane", "adapter": "lane", "title": "FROGGER"},
    {"id": "on_track", "archetype": "track", "adapter": "track", "title": "ON TRACK"},
    {"id": "donkey_kong", "archetype": "platform", "adapter": "platform", "title": "DONKEY KONG"},
    {"id": "gta", "archetype": "region", "adapter": "region", "title": "GTA"},
]

# Per-archetype knob registrations, mirroring the subset of each reference
# cartridge's real Tab-menu knobs that actually reach adapter.interpret().
# {id, label, type, default, min, max, step, group}
const PREVIEW_KNOBS = {
    "maze": [
        {"id": "grid_size_scale", "label": "Grid Resolution", "type": "float", "default": 1.0, "min": 0.6, "max": 1.6, "step": 0.05, "group": "Level"},
        {"id": "invert_main_solid", "label": "Invert Main Solid", "type": "bool", "default": false, "group": "Level"},
    ],
    "well_fill": [
        {"id": "bounds_clamp", "label": "Bounds Clamp", "type": "bool", "default": true, "group": "Level"},
        {"id": "invert", "label": "Invert", "type": "bool", "default": false, "group": "Level"},
        {"id": "fill", "label": "Fill Enclosed", "type": "bool", "default": false, "group": "Level"},
        {"id": "grid_scale", "label": "Grid Scale", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "density", "label": "Density", "type": "float", "default": 1.0, "min": 0.1, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "wall_width", "label": "Wall Width", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
    ],
    "arena": [
        {"id": "bounds_clamp", "label": "Bounds Clamp", "type": "bool", "default": true, "group": "Level"},
        {"id": "density", "label": "Wave Density", "type": "float", "default": 1.0, "min": 0.4, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "block_region", "label": "Block Region", "type": "bool", "default": false, "group": "Level"},
        {"id": "invert", "label": "Invert", "type": "bool", "default": false, "group": "Level"},
    ],
    "lane": [
        {"id": "grid_scale", "label": "Grid Scale", "type": "float", "default": 1.0, "min": 0.6, "max": 1.8, "step": 0.05, "group": "Level"},
        {"id": "density", "label": "Traffic Density", "type": "float", "default": 1.0, "min": 0.4, "max": 3.0, "step": 0.1, "group": "Level"},
        {"id": "invert", "label": "Invert Lanes", "type": "bool", "default": false, "group": "Level"},
        {"id": "bounds_clamp", "label": "Bounds Clamp", "type": "bool", "default": true, "group": "Level"},
    ],
    "track": [
        {"id": "track_friction", "label": "Track Friction", "type": "float", "default": 1.0, "min": 0.5, "max": 10.0, "step": 0.1, "group": "Level"},
        {"id": "checkpoint_spacing", "label": "Checkpoint Spacing", "type": "int", "default": 4, "min": 2, "max": 12, "step": 1, "group": "Level"},
        {"id": "wall_forgiveness", "label": "Wall Forgiveness", "type": "float", "default": 1.0, "min": 0.4, "max": 2.5, "step": 0.1, "group": "Level"},
        {"id": "bounds_clamp", "label": "Bounds Clamp", "type": "bool", "default": true, "group": "Level"},
    ],
    "platform": [
        {"id": "jump_height", "label": "Jump Height", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "platform_snap", "label": "Platform Snap", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "add_platforms", "label": "Add Platforms", "type": "bool", "default": true, "group": "Level"},
        {"id": "climb_tolerance", "label": "Climb Tolerance", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "hazard_leniency", "label": "Hazard Leniency", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "bounds_clamp", "label": "Bounds Clamp", "type": "bool", "default": true, "group": "Level"},
    ],
    "region": [
        {"id": "block_size", "label": "Block Size", "type": "float", "default": 1.0, "min": 0.5, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "invert", "label": "Invert", "type": "bool", "default": false, "group": "Level"},
        {"id": "density", "label": "Density", "type": "float", "default": 1.0, "min": 0.1, "max": 2.0, "step": 0.1, "group": "Level"},
        {"id": "bounds_clamp", "label": "Bounds Clamp", "type": "bool", "default": true, "group": "Level"},
        {"id": "smooth", "label": "Smooth", "type": "bool", "default": false, "group": "Level"},
    ],
}

var preview_active: bool = false
var preview_game_idx: int = 0
var preview_layout: Dictionary = {}
var preview_overlay: Control
var preview_tab_menu = null
var preview_level_dir: String = ""   # level_dir actually fed to the adapter (real or scratch)
var preview_scratch_dir: String = "user://preview_scratch"
var preview_status_label: Label
var is_preview_deriving: bool = false
var preview_derive_thread: Thread
var preview_dirty_since_derive: bool = true # true until we've derived at least once for current paint state

func _ready():
    Palette = load(_get_repo_root().path_join("app/shared/palette.gd"))
    SharedLoader = load(_get_repo_root().path_join("app/shared/shared_loader.gd"))
    _build_ui()
    virtual_cursor.size = Vector2(brush_size*2, brush_size*2)
    virtual_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)
    set_process(true)

    file_dialog.file_selected.connect(_on_file_selected)
    _build_preview_overlay()

func _create_section(title: String, parent: Control, default_open: bool = true) -> VBoxContainer:
    var header = Button.new()
    header.text = ("▼ " if default_open else "▶ ") + title
    header.add_theme_font_size_override("font_size", 18)
    header.add_theme_color_override("font_color", Color(1, 1, 1))
    header.flat = true
    header.alignment = HORIZONTAL_ALIGNMENT_LEFT
    parent.add_child(header)
    
    var content = VBoxContainer.new()
    content.visible = default_open
    parent.add_child(content)
    
    var toggle_func = func():
        content.visible = not content.visible
        header.text = ("▼ " if content.visible else "▶ ") + title
        # Defer focus rebuild to ensure visibility is fully applied
        call_deferred("_rebuild_focus")
        
    header.pressed.connect(toggle_func)
    header.gui_input.connect(func(event: InputEvent):
        if event.is_action_pressed("ui_right") and not content.visible:
            toggle_func.call()
            header.accept_event()
        elif event.is_action_pressed("ui_left") and content.visible:
            toggle_func.call()
            header.accept_event()
    )
    
    return content

func _build_ui():
    var sec_file = _create_section("File", sidebar_vbox, true)
    
    var btn_load = Button.new()
    btn_load.text = "Load Background Image"
    btn_load.pressed.connect(_on_btn_load_pressed)
    sec_file.add_child(btn_load)
    
    var btn_save = Button.new()
    btn_save.text = "Save Level"
    btn_save.pressed.connect(_on_btn_save_pressed)
    sec_file.add_child(btn_save)
    
    var sep1 = HSeparator.new()
    sidebar_vbox.add_child(sep1)
    
    var sec_brush = _create_section("Brush & Palette", sidebar_vbox, true)
    
    var lbl_opacity = Label.new()
    lbl_opacity.text = "Reference Opacity"
    sec_brush.add_child(lbl_opacity)
    var sld_opacity = HSlider.new()
    sld_opacity.min_value = 0.0
    sld_opacity.max_value = 1.0
    sld_opacity.step = 0.05
    sld_opacity.value = opacity
    sld_opacity.value_changed.connect(func(v): opacity = v; _update_opacity())
    sec_brush.add_child(sld_opacity)
    
    var lbl_brush = Label.new()
    lbl_brush.text = "Brush Size"
    sec_brush.add_child(lbl_brush)
    var sld_brush = HSlider.new()
    sld_brush.min_value = 1
    sld_brush.max_value = 100
    sld_brush.value = brush_size
    sld_brush.value_changed.connect(func(v): brush_size = int(v); virtual_cursor.size = Vector2(brush_size*2, brush_size*2))
    sec_brush.add_child(sld_brush)
    
    var lbl_palette = Label.new()
    lbl_palette.text = "Palette"
    sec_brush.add_child(lbl_palette)
    
    var grid_palette = GridContainer.new()
    grid_palette.columns = 2
    sec_brush.add_child(grid_palette)
    
    for cid in Palette.CLASSES.keys():
        var info = Palette.CLASSES[cid]
        var btn = Button.new()
        btn.text = info["name"]
        btn.add_theme_color_override("font_color", Color(info["ui_color"]))
        btn.pressed.connect(func(): _select_class(cid))
        grid_palette.add_child(btn)
        class_buttons.append(btn)
        
    var sep2 = HSeparator.new()
    sidebar_vbox.add_child(sep2)
    
    var sec_derive = _create_section("Auto-Derive", sidebar_vbox, false)
    
    var btn_derive = Button.new()
    btn_derive.text = "Run Auto-Derive"
    btn_derive.pressed.connect(_trigger_derive)
    sec_derive.add_child(btn_derive)

    var lbl_preset = Label.new()
    lbl_preset.text = "Preset"
    sec_derive.add_child(lbl_preset)
    
    var opt_preset = OptionButton.new()
    var presets = _get_backend_presets()
    for p in presets:
        opt_preset.add_item(_preset_display_label(p))
    # Default to "Balanced Semantic" if present, else item 0
    var default_idx = presets.find("Balanced Semantic")
    if default_idx == -1: default_idx = 0
    opt_preset.select(default_idx)
    _apply_preset_profile(presets[default_idx], false)
    
    opt_preset.item_selected.connect(func(idx): 
        _apply_preset_profile(presets[idx], true)
    )
    sec_derive.add_child(opt_preset)

    var lbl_preset_hint = Label.new()
    lbl_preset_hint.text = "Balanced = mixed scenes | Open Flow = maze / tunnel-grid | Vertical Surfaces = climbing / platform-heavy"
    lbl_preset_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl_preset_hint.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78))
    sec_derive.add_child(lbl_preset_hint)

    _add_slider("Blur", "blur", 0, 10, sec_derive)
    _add_slider("Canny Low", "canny_low", 0, 255, sec_derive)
    _add_slider("Canny High", "canny_high", 0, 255, sec_derive)
    _add_slider("Morph Dilate", "morph_dilate", 0, 10, sec_derive)
    _add_slider("Walkable Bias", "walkable_bias", 0, 100, sec_derive)
    _add_slider("Feature Density", "feature_density", 0, 100, sec_derive)
    _add_slider("Hazard Density", "hazard_density", 0, 100, sec_derive)

    var sep3 = HSeparator.new()
    sidebar_vbox.add_child(sep3)

    var sec_preview = _create_section("Preview", sidebar_vbox, true)

    var lbl_preview_hint = Label.new()
    lbl_preview_hint.text = "See how a reference game reads this map. Controller: Y toggles, D-Pad Up/Down cycles games. Keyboard: P toggles, [ / ] cycles."
    lbl_preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl_preview_hint.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78))
    sec_preview.add_child(lbl_preview_hint)

    var btn_preview_toggle = Button.new()
    btn_preview_toggle.name = "PreviewToggleBtn"
    btn_preview_toggle.text = "Enable Preview"
    btn_preview_toggle.pressed.connect(_toggle_preview)
    sec_preview.add_child(btn_preview_toggle)

    var game_row = HBoxContainer.new()
    sec_preview.add_child(game_row)

    var btn_prev_game = Button.new()
    btn_prev_game.text = "< Game"
    btn_prev_game.pressed.connect(func(): _cycle_preview_game(-1))
    game_row.add_child(btn_prev_game)

    var lbl_current_game = Label.new()
    lbl_current_game.name = "PreviewGameLabel"
    lbl_current_game.text = PREVIEW_GAMES[preview_game_idx]["title"]
    lbl_current_game.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
    lbl_current_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lbl_current_game.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_row.add_child(lbl_current_game)

    var btn_next_game = Button.new()
    btn_next_game.text = "Game >"
    btn_next_game.pressed.connect(func(): _cycle_preview_game(1))
    game_row.add_child(btn_next_game)

    var btn_preview_controls = Button.new()
    btn_preview_controls.text = "Game Controls (Start)"
    btn_preview_controls.pressed.connect(_open_preview_controls)
    sec_preview.add_child(btn_preview_controls)

    preview_status_label = Label.new()
    preview_status_label.text = "Preview off"
    preview_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_status_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.8))
    sec_preview.add_child(preview_status_label)

    _select_class(1)

func _add_slider(label_text: String, param_name: String, min_val: float, max_val: float, parent: Control):
    var lbl = Label.new()
    lbl.text = label_text
    parent.add_child(lbl)
    var sld = HSlider.new()
    sld.min_value = min_val
    sld.max_value = max_val
    sld.value = cv_params[param_name]
    sld.value_changed.connect(func(v): cv_params[param_name] = int(v))
    parent.add_child(sld)
    derive_slider_controls[param_name] = sld
    
    # We will clamp focus recursively at the very end of _build_ui to handle all new containers
    _rebuild_focus()

func _apply_preset_profile(preset: String, rerun_derive: bool = true) -> void:
    cv_params["preset"] = preset
    var profile: Dictionary = derive_preset_profiles.get(preset, {})
    for key in profile.keys():
        cv_params[key] = profile[key]
        if derive_slider_controls.has(key):
            derive_slider_controls[key].set_value_no_signal(profile[key])
    if rerun_derive:
        _trigger_derive()

func _rebuild_focus():
    var focusable = []
    _gather_focusable(sidebar_vbox, focusable)
    
    for i in range(focusable.size()):
        var node = focusable[i]
        
        var in_grid = (node.get_parent() is GridContainer)
        
        if in_grid:
            var grid = node.get_parent()
            var col = node.get_index() % grid.columns
            
            # Left edge of grid goes to side nav, others use spatial
            if col == 0:
                node.focus_neighbor_left = NodePath("/root/Main/UI/Content/SideNav/DesignBtn")
            else:
                node.focus_neighbor_left = NodePath("")
                
            # Right edge of grid clamps to self, others use spatial
            if col == grid.columns - 1 or node.get_index() == grid.get_child_count() - 1:
                node.focus_neighbor_right = node.get_path()
            else:
                node.focus_neighbor_right = NodePath("")
                
            # Let Godot's flawless spatial nav handle the grid internals and exits
            node.focus_neighbor_top = NodePath("")
            node.focus_neighbor_bottom = NodePath("")
        else:
            node.focus_neighbor_left = NodePath("/root/Main/UI/Content/SideNav/DesignBtn")
            node.focus_neighbor_right = node.get_path()
            
            var prev_node = null
            var next_node = null
            
            # Find closest previous non-grid element
            for j in range(i-1, -1, -1):
                if not focusable[j].get_parent() is GridContainer:
                    prev_node = focusable[j]
                    break
                    
            # Find closest next non-grid element
            for j in range(i+1, focusable.size()):
                if not focusable[j].get_parent() is GridContainer:
                    next_node = focusable[j]
                    break
                    
            if prev_node:
                # If there's a grid directly above us, leave top empty so spatial nav smoothly enters the bottom of the grid
                if i > 0 and focusable[i-1].get_parent() is GridContainer:
                    node.focus_neighbor_top = NodePath("")
                else:
                    node.focus_neighbor_top = prev_node.get_path()
            else:
                node.focus_neighbor_top = node.get_path() # Clamp top
                
            if next_node:
                # If there's a grid directly below us, explicitly point to its first item to prevent sideways spatial jumping
                if i < focusable.size()-1 and focusable[i+1].get_parent() is GridContainer:
                    node.focus_neighbor_bottom = focusable[i+1].get_path()
                else:
                    node.focus_neighbor_bottom = next_node.get_path()
            else:
                node.focus_neighbor_bottom = node.get_path() # Clamp bottom

func _gather_focusable(node: Node, arr: Array):
    if not node.visible:
        return
    if node is Control and node.focus_mode != Control.FOCUS_NONE:
        arr.append(node)
    for child in node.get_children():
        _gather_focusable(child, arr)

func _select_class(cid: int):
    current_class_id = cid
    for i in range(class_buttons.size()):
        if i == cid:
            class_buttons[i].add_theme_color_override("font_color", Color(1, 1, 1))
        else:
            var c = Color(Palette.CLASSES[i]["ui_color"])
            class_buttons[i].add_theme_color_override("font_color", c)

func _on_btn_load_pressed():
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    file_dialog.current_dir = _get_repo_root().path_join("content/scenes/")
    file_dialog.popup_centered()

func _on_file_selected(path: String):
    current_image_path = path
    var img = Image.load_from_file(path)
    if img:
        bg_rect.texture = ImageTexture.create_from_image(img)
        semantic_image = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
        semantic_image.fill(Color(0,0,0,0))
        semantic_texture = ImageTexture.create_from_image(semantic_image)
        semantic_rect.texture = semantic_texture
        _update_opacity()
        # New background image invalidates any previously-known level dir and
        # any prior preview derive.
        current_level_dir = ""
        preview_dirty_since_derive = true
        if preview_active:
            _refresh_preview()

func _update_opacity():
    if show_bg:
        bg_rect.modulate.a = opacity
    else:
        bg_rect.modulate.a = 0.0

func _trigger_derive():
    if current_image_path == "" or is_deriving:
        return
    is_deriving = true
    
    cv_params["source_img_path"] = current_image_path
    cv_params["output_map_path"] = ProjectSettings.globalize_path(temp_map_path)
    
    var f = FileAccess.open(temp_json_path, FileAccess.WRITE)
    f.store_string(JSON.stringify(cv_params))
    f.close()
    
    if derive_thread:
        derive_thread.wait_to_finish()
    derive_thread = Thread.new()
    derive_thread.start(_run_derive_process)

func _run_derive_process():
    var py_script = _get_repo_root().path_join("app/tools/level_authoring/author_backend.py")
    var output = []
    # Use python3 if on unix, python on windows, let's just use python
    OS.execute("python", [py_script, ProjectSettings.globalize_path(temp_json_path)], output, true)
    call_deferred("_on_derive_finished", output)

func _on_derive_finished(output: Array):
    is_deriving = false
    if FileAccess.file_exists(temp_map_path):
        var img = Image.load_from_file(temp_map_path)
        if img:
            semantic_image = img
            semantic_image.convert(Image.FORMAT_RGBA8)
            semantic_texture.update(semantic_image)

func _input(event):
    # Preview toggle / game-cycle is always reachable, controller + keyboard,
    # even while the secondary-controls overlay is open (it forwards to
    # tab_menu itself for its own grammar).
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_P:
            _toggle_preview()
            return
        if preview_active and preview_tab_menu == null:
            if event.keycode == KEY_BRACKETLEFT:
                _cycle_preview_game(-1)
                return
            if event.keycode == KEY_BRACKETRIGHT:
                _cycle_preview_game(1)
                return
    elif event is InputEventJoypadButton and event.pressed:
        if event.button_index == JOY_BUTTON_Y:
            _toggle_preview()
            return
        if preview_active and preview_tab_menu == null:
            if event.button_index == JOY_BUTTON_DPAD_UP:
                _cycle_preview_game(-1)
                return
            if event.button_index == JOY_BUTTON_DPAD_DOWN:
                _cycle_preview_game(1)
                return
            if event.button_index == JOY_BUTTON_START:
                _open_preview_controls()
                return

    # While preview's secondary-controls overlay owns input, don't paint.
    if preview_tab_menu != null:
        return

    if event is InputEventMouseMotion:
        cursor_pos = semantic_rect.get_local_mouse_position()
        if is_painting:
            _paint_at_cursor()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                # Only start painting if the click originated on the canvas
                if semantic_rect.get_global_rect().has_point(event.global_position):
                    is_painting = true
                    cursor_pos = semantic_rect.get_local_mouse_position()
                    _paint_at_cursor()
            else:
                is_painting = false

    elif event is InputEventJoypadMotion:
        if event.axis == JOY_AXIS_LEFT_X:
            if abs(event.axis_value) > 0.2:
                cursor_pos.x += event.axis_value * 15.0
        elif event.axis == JOY_AXIS_LEFT_Y:
            if abs(event.axis_value) > 0.2:
                cursor_pos.y += event.axis_value * 15.0
    elif event is InputEventJoypadButton:
        if event.button_index == JOY_BUTTON_A:
            is_painting = event.pressed
            if is_painting:
                _paint_at_cursor()
        elif event.button_index == JOY_BUTTON_B:
            if event.pressed:
                var prev_class = current_class_id
                _select_class(0) # Eraser / empty
                _paint_at_cursor()
                _select_class(prev_class)
        elif event.button_index == JOY_BUTTON_DPAD_RIGHT and event.pressed:
            _select_class((current_class_id + 1) % Palette.CLASSES.size())
        elif event.button_index == JOY_BUTTON_DPAD_LEFT and event.pressed:
            _select_class((current_class_id - 1 + Palette.CLASSES.size()) % Palette.CLASSES.size())
        elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER and event.pressed:
            brush_size = min(100, brush_size + 5)
            virtual_cursor.size = Vector2(brush_size*2, brush_size*2)
        elif event.button_index == JOY_BUTTON_LEFT_SHOULDER and event.pressed:
            brush_size = max(1, brush_size - 5)
            virtual_cursor.size = Vector2(brush_size*2, brush_size*2)
        elif event.button_index == JOY_BUTTON_BACK and event.pressed: # Select
            show_bg = !show_bg
            _update_opacity()

func _process(delta):
    # While the preview overlay owns the screen, freeze paint input entirely.
    if preview_tab_menu != null:
        if virtual_cursor:
            virtual_cursor.visible = false
        return

    if virtual_cursor:
        virtual_cursor.visible = not preview_active
        virtual_cursor.position = cursor_pos - Vector2(brush_size, brush_size)
        virtual_cursor.color = Color(Palette.CLASSES[current_class_id]["authoring_color"])
        virtual_cursor.color.a = 0.5

    if not preview_active and (Input.is_joy_button_pressed(0, JOY_BUTTON_A) or is_painting):
        _paint_at_cursor()

    # Clamp cursor
    if semantic_rect.texture:
        cursor_pos.x = clamp(cursor_pos.x, 0, semantic_rect.size.x)
        cursor_pos.y = clamp(cursor_pos.y, 0, semantic_rect.size.y)

func _paint_at_cursor():
    if not semantic_image or not semantic_rect.texture: return
    
    # Map control coordinates to image coordinates considering KEEP_ASPECT_CENTERED
    var img_w = semantic_image.get_width()
    var img_h = semantic_image.get_height()
    var rect_w = semantic_rect.size.x
    var rect_h = semantic_rect.size.y
    
    var scale: float
    var offset_x = 0.0
    var offset_y = 0.0
    
    if img_w / float(img_h) > rect_w / float(rect_h):
        var new_h = rect_w * (img_h / float(img_w))
        offset_y = (rect_h - new_h) / 2.0
        scale = img_w / float(rect_w)
    else:
        var new_w = rect_h * (img_w / float(img_h))
        offset_x = (rect_w - new_w) / 2.0
        scale = img_h / float(rect_h)
        
    var ix = int((cursor_pos.x - offset_x) * scale)
    var iy = int((cursor_pos.y - offset_y) * scale)
    
    if ix < 0 or ix >= img_w or iy < 0 or iy >= img_h:
        return
        
    var r = int(brush_size * scale)
    
    var col = Color(Palette.CLASSES[current_class_id]["authoring_color"])
    col.a = 1.0 # Force full opacity on paint
    
    var painted = false
    for y in range(max(0, iy - r), min(img_h, iy + r + 1)):
        for x in range(max(0, ix - r), min(img_w, ix + r + 1)):
            if (x - ix) * (x - ix) + (y - iy) * (y - iy) <= r * r:
                if semantic_image.get_pixel(x, y) != col:
                    semantic_image.set_pixel(x, y, col)
                    painted = true
                
    if painted:
        semantic_texture.update(semantic_image)

func _on_btn_save_pressed():
    if not semantic_image: return
    
    file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    file_dialog.current_dir = _get_repo_root().path_join("content/scenes/")
    file_dialog.disconnect("file_selected", _on_file_selected)
    if not file_dialog.is_connected("dir_selected", _on_dir_selected):
        file_dialog.dir_selected.connect(_on_dir_selected)
    file_dialog.popup_centered()

func _on_dir_selected(dir_path: String):
    var map_path = dir_path + "/semantic_map.png"
    semantic_image.save_png(map_path)
    
    var scene_id = "scene_demo_wall"
    var parts = dir_path.split("/")
    if parts.size() >= 3 and parts[parts.size()-2] == "levels":
        scene_id = parts[parts.size()-3]
        
    var level_yaml_path = dir_path + "/level.yaml"
    var level_data = {
        "schema": "level",
        "version": "1.0.0",
        "level_id": dir_path.get_file(),
        "scene_id": scene_id,
        "name": "Authored Level",
        "semantic_map": "semantic_map.png",
        "palette_schema": "../../../../vault/50-schemas/semantic-palette-v1.yaml",
        "status": "playable",
        "derived": {
            "occupancy": "derived/occupancy.png",
            "navgraph": "derived/navgraph.json",
            "container": "derived/container.json",
            "grid": "derived/grid.json",
            "platform_edges": "derived/platform_edges.json",
            "track_centerline": "derived/track_centerline.json"
        }
    }
    
    # Save background image if loaded
    if current_image_path != "":
        var ext = current_image_path.get_extension()
        var new_bg_path = dir_path + "/background." + ext
        if current_image_path != new_bg_path:
            var d = DirAccess.open(current_image_path.get_base_dir())
            d.copy(current_image_path, new_bg_path)
        level_data["reference_image"] = "background." + ext
        
    var yml_str = "schema: %s\nversion: %s\nlevel_id: %s\nscene_id: %s\nname: %s\nsemantic_map: %s\npalette_schema: %s\nstatus: %s\n" % [
        level_data.schema, level_data.version, level_data.level_id, level_data.scene_id, level_data.name, level_data.semantic_map, level_data.palette_schema, level_data.status
    ]
    if level_data.has("reference_image"):
        yml_str += "reference_image: %s\n" % level_data.reference_image
        
    var f = FileAccess.open(level_yaml_path, FileAccess.WRITE)
    f.store_string(yml_str)
    f.close()
    
    # Trigger compile_level.py
    var py_script = _get_repo_root().path_join("app/tools/arena_compiler/compile_level.py")
    var target_dir = ProjectSettings.globalize_path(dir_path)
    var cmds = [
        {"cmd": "python", "args": [py_script, target_dir]},
        {"cmd": "py", "args": ["-3", py_script, target_dir]},
        {"cmd": "python3", "args": [py_script, target_dir]}
    ]
    
    var exit_code = -1
    var output = []
    var ran_cmd = ""
    var full_output = ""
    
    for c in cmds:
        output.clear()
        exit_code = OS.execute(c.cmd, c.args, output, true)
        var out_str = output[0] if output.size() > 0 else ""
        if exit_code == 0 or out_str.find("Traceback") != -1 or out_str.find("Error") != -1:
            if out_str.find("is not recognized") == -1 and out_str.find("not found") == -1:
                ran_cmd = c.cmd
                full_output = out_str
                break
                
    var grid_path = target_dir.path_join("derived").path_join("grid.json")
    var success = (exit_code == 0) and FileAccess.file_exists(grid_path)
    
    var main_node = get_tree().root.get_node_or_null("Main")
    if success:
        print("Derived layers generated for ", dir_path, " using '", ran_cmd, "'")
        if main_node and main_node.has_method("_show_placeholder"):
            main_node._show_placeholder("SAVE SUCCESS\nLevel compiled successfully.")
        # A saved-and-compiled level has real derived/** on disk — preview can
        # read it directly from now on instead of a scratch dir.
        current_level_dir = target_dir
        preview_dirty_since_derive = true
        if preview_active:
            _refresh_preview()
    else:
        printerr("Failed to compile level. Exit code: ", exit_code)
        if full_output != "":
            printerr("Output:\n", full_output)
        if main_node and main_node.has_method("_show_placeholder"):
            main_node._show_placeholder("SAVE FAILED\nCompilation failed or missing Python dependencies (opencv-python, numpy). Check logs.")
    
    # Restore file_dialog connections
    file_dialog.disconnect("dir_selected", _on_dir_selected)
    file_dialog.file_selected.connect(_on_file_selected)

func _get_repo_root() -> String:
    var dir = ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
    if dir.ends_with("/"):
        dir = dir.substr(0, dir.length() - 1)
    for _i in range(10):
        if DirAccess.dir_exists_absolute(dir.path_join("app").path_join("shared")):
            return dir
        var parent = dir.get_base_dir()
        if parent == dir or parent == "":
            break
        dir = parent
    return ""

func _get_backend_presets() -> Array:
    var presets = []
    var py_script = _get_repo_root().path_join("app/tools/level_authoring/author_backend.py")
    if FileAccess.file_exists(py_script):
        var f = FileAccess.open(py_script, FileAccess.READ)
        var content = f.get_as_text()
        
        var regex = RegEx.new()
        regex.compile("get\\(\"preset\"\\s*,\\s*[\"']([^\"']+)[\"']\\)")
        var result = regex.search(content)
        if result:
            var p = result.get_string(1)
            if not presets.has(p): presets.append(p)
                
        regex.compile("preset\\s*==\\s*[\"']([^\"']+)[\"']")
        for r in regex.search_all(content):
            var p = r.get_string(1)
            if not presets.has(p): presets.append(p)
    
    if presets.is_empty():
        presets = ["Balanced Semantic", "Open Flow", "Vertical Surfaces"]
    return presets

func _preset_display_label(preset: String) -> String:
    match preset:
        "Balanced Semantic":
            return "Balanced Semantic (general mixed map)"
        "Open Flow":
            return "Open Flow (maze / tunnel-grid)"
        "Vertical Surfaces":
            return "Vertical Surfaces (climb / platform)"
        _:
            return preset

# ==========================================================================
# Preview mode (TASK-INT-10) — renders a reference game's interpreted
# layout as a neon overlay on top of the painted map. Reuses the shared
# adapters (app/shared/adapters/*.gd) via SharedLoader exactly as the real
# cartridges do. No interpretation logic lives here — only generic drawing
# of the normalized layout Dictionary each adapter returns.
# ==========================================================================

func _build_preview_overlay():
    preview_overlay = Control.new()
    preview_overlay.name = "PreviewOverlay"
    preview_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    preview_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview_overlay.visible = false
    preview_overlay.draw.connect(_draw_preview_overlay)
    canvas_container.add_child(preview_overlay)
    # Keep it above the paint layer and virtual cursor.
    canvas_container.move_child(preview_overlay, canvas_container.get_child_count() - 1)

func _toggle_preview():
    if preview_active:
        _stop_preview()
    else:
        _start_preview()

func _start_preview():
    if not semantic_image:
        var main_node = get_tree().root.get_node_or_null("Main")
        if main_node and main_node.has_method("_show_placeholder"):
            main_node._show_placeholder("PREVIEW UNAVAILABLE\nLoad or paint a map first.")
        return
    preview_active = true
    preview_overlay.visible = true
    _set_preview_toggle_label("Disable Preview")
    _refresh_preview()

func _stop_preview():
    preview_active = false
    preview_overlay.visible = false
    preview_status_label.text = "Preview off"
    _set_preview_toggle_label("Enable Preview")
    if preview_tab_menu != null:
        preview_tab_menu.queue_free()
        preview_tab_menu = null

func _set_preview_toggle_label(text: String):
    var btn = sidebar_vbox.find_child("PreviewToggleBtn", true, false)
    if btn:
        btn.text = text

func _cycle_preview_game(direction: int):
    preview_game_idx = (preview_game_idx + direction + PREVIEW_GAMES.size()) % PREVIEW_GAMES.size()
    var lbl = sidebar_vbox.find_child("PreviewGameLabel", true, false)
    if lbl:
        lbl.text = PREVIEW_GAMES[preview_game_idx]["title"]
    if preview_active:
        # Switching games while the controls overlay is open: rebuild it
        # against the new game's knob set.
        if preview_tab_menu != null:
            _open_preview_controls()
        else:
            _refresh_preview()

## Resolves the level_dir preview should feed to the adapter, ensuring
## derived/** exists for it. Data-source choice (documented in the run log):
## - If the current canvas matches an already-saved level (current_level_dir
##   set by Save), reuse that real level_dir — its derived/** is genuine
##   compiler output, and any knob edits persist to the exact file the real
##   cartridge will read at boot.
## - Otherwise (unsaved paint, or no image loaded via Load), write the
##   in-memory semantic_image to a scratch level dir under user:// and run
##   the SAME compile_level.py step Save uses, so the adapter always reads a
##   real derived/** rather than a hand-rolled substitute. This keeps "no new
##   interpretation code in the hub" honest — the only new code is plumbing.
func _resolve_preview_level_dir() -> String:
    if current_level_dir != "" and DirAccess.dir_exists_absolute(current_level_dir):
        var grid_path = current_level_dir.path_join("derived").path_join("grid.json")
        if FileAccess.file_exists(grid_path) and not preview_dirty_since_derive:
            return current_level_dir
        elif FileAccess.file_exists(grid_path) and preview_dirty_since_derive:
            # Saved level, but flagged dirty (e.g. reloaded) — still valid,
            # derived/** was written at save time. Nothing further to do.
            preview_dirty_since_derive = false
            return current_level_dir
    return _derive_preview_scratch_dir()

func _derive_preview_scratch_dir() -> String:
    var scratch_abs = ProjectSettings.globalize_path(preview_scratch_dir)
    DirAccess.make_dir_recursive_absolute(scratch_abs)
    var map_path = scratch_abs.path_join("semantic_map.png")
    semantic_image.save_png(map_path)

    var level_yaml_path = scratch_abs.path_join("level.yaml")
    var yml_str = "schema: level\nversion: 1.0.0\nlevel_id: preview_scratch\nscene_id: scene_preview_scratch\nname: Preview Scratch\nsemantic_map: semantic_map.png\nstatus: draft\n"
    var f = FileAccess.open(level_yaml_path, FileAccess.WRITE)
    f.store_string(yml_str)
    f.close()

    var py_script = _get_repo_root().path_join("app/tools/arena_compiler/compile_level.py")
    var cmds = [
        {"cmd": "python", "args": [py_script, scratch_abs]},
        {"cmd": "py", "args": ["-3", py_script, scratch_abs]},
        {"cmd": "python3", "args": [py_script, scratch_abs]}
    ]
    var exit_code = -1
    for c in cmds:
        var output = []
        exit_code = OS.execute(c.cmd, c.args, output, true)
        var out_str = output[0] if output.size() > 0 else ""
        if out_str.find("is not recognized") != -1 or out_str.find("not found") != -1:
            continue
        break

    preview_dirty_since_derive = false
    return scratch_abs

func _refresh_preview():
    if not preview_active or not semantic_image:
        return
    preview_level_dir = _resolve_preview_level_dir()
    var game = PREVIEW_GAMES[preview_game_idx]

    var derived = {}
    var adapter_script = SharedLoader.load_adapter_script(game["adapter"])
    if adapter_script == null:
        preview_status_label.text = "Adapter load failed for " + game["title"]
        preview_layout = {}
        preview_overlay.queue_redraw()
        return
    var adapter = adapter_script.new()

    var knobs = _current_preview_knobs(game["archetype"])
    preview_layout = adapter.interpret(preview_level_dir, derived, knobs)
    if preview_layout == null or preview_layout.is_empty():
        # Contract: adapters must never return empty (procedural fallback).
        # Call fallback_layout explicitly as a defensive last resort so
        # Preview itself never renders nothing even if that contract slips.
        preview_layout = adapter.fallback_layout(preview_level_dir, knobs)

    var src = "saved level" if preview_level_dir == current_level_dir else "unsaved paint (scratch derive)"
    preview_status_label.text = "Previewing %s — %s" % [game["title"], src]
    preview_overlay.queue_redraw()

func _current_preview_knobs(archetype: String) -> Dictionary:
    var knobs = {}
    var defs = PREVIEW_KNOBS.get(archetype, [])
    for d in defs:
        knobs[d["id"]] = d["default"]
    # If a live TabMenu is open for this archetype, its current values win.
    if preview_tab_menu != null:
        for d in defs:
            var v = preview_tab_menu.get_knob_value(d["id"])
            if v != null:
                knobs[d["id"]] = v
    return knobs

func _open_preview_controls():
    if not preview_active:
        return
    if preview_tab_menu != null:
        preview_tab_menu.queue_free()
        preview_tab_menu = null

    var game = PREVIEW_GAMES[preview_game_idx]
    var menu_script = SharedLoader.load_tab_menu_script()
    if menu_script == null:
        return
    preview_tab_menu = menu_script.new()
    add_child(preview_tab_menu)

    for d in PREVIEW_KNOBS.get(game["archetype"], []):
        match d["type"]:
            "float":
                preview_tab_menu.register_knob_float(d["id"], d["label"], d["default"], d["min"], d["max"], d["step"], d["group"])
            "int":
                preview_tab_menu.register_knob_int(d["id"], d["label"], d["default"], d["min"], d["max"], d["step"], d["group"])
            "bool":
                preview_tab_menu.register_knob_bool(d["id"], d["label"], d["default"], d["group"])
            "enum":
                preview_tab_menu.register_knob_enum(d["id"], d["label"], d["default"], d["options"], d["group"])

    preview_tab_menu.knob_changed.connect(_on_preview_knob_changed)
    preview_tab_menu.menu_closed.connect(_on_preview_controls_closed)

    # setup() loads any previously persisted values for this cartridge_id +
    # level key (level.yaml under preview_level_dir) via TabMenu's own
    # persistence — the SAME file the real cartridge reads at boot. This is
    # what makes editor knob edits become that game's default secondary
    # controls for this map.
    preview_tab_menu.setup(game["id"], preview_level_dir, game["title"] + " — LIVE PREVIEW")
    preview_tab_menu._set_overlay_mode("settings")
    _refresh_preview()

func _on_preview_knob_changed(_knob_id, _new_value):
    _refresh_preview()

func _on_preview_controls_closed():
    if preview_tab_menu != null:
        preview_tab_menu.queue_free()
        preview_tab_menu = null
    _refresh_preview()

func _draw_preview_overlay():
    if not preview_active or preview_layout.is_empty():
        return
    var xform = _preview_map_to_canvas_xform()
    var neon = Color(0.0, 0.9, 1.0, 0.85)      # cyan-led neon, design-system accent
    var neon_dim = Color(0.0, 0.9, 1.0, 0.35)
    var accent = Color(1.0, 0.85, 0.2, 0.9)    # spawn/goal markers

    if preview_layout.has("nodes") and preview_layout.has("edges"):
        _draw_maze_layout(xform, neon, neon_dim, accent)
    elif preview_layout.has("bounds") and preview_layout.has("cover_blocks"):
        _draw_arena_layout(xform, neon, neon_dim, accent)
    elif preview_layout.has("lanes"):
        _draw_lane_layout(xform, neon, neon_dim, accent)
    elif preview_layout.has("centerline_points"):
        _draw_track_layout(xform, neon, neon_dim, accent)
    elif preview_layout.has("platforms"):
        _draw_platform_layout(xform, neon, neon_dim, accent)
    elif preview_layout.has("regions"):
        _draw_region_layout(xform, neon, neon_dim, accent)
    elif preview_layout.has("well_polygon") or preview_layout.has("cells"):
        _draw_well_fill_layout(xform, neon, neon_dim, accent)

## Maps semantic-map pixel space to the SemanticRect's on-screen rect,
## honoring the same KEEP_ASPECT_CENTERED math used by _paint_at_cursor().
func _preview_map_to_canvas_xform() -> Dictionary:
    var img_w = 1920.0
    var img_h = 1080.0
    if semantic_image:
        img_w = semantic_image.get_width()
        img_h = semantic_image.get_height()
    var rect_w = semantic_rect.size.x
    var rect_h = semantic_rect.size.y

    var scale: float
    var offset_x = 0.0
    var offset_y = 0.0
    if img_w / max(img_h, 0.001) > rect_w / max(rect_h, 0.001):
        var new_h = rect_w * (img_h / img_w)
        offset_y = (rect_h - new_h) / 2.0
        scale = rect_w / img_w
    else:
        var new_w = rect_h * (img_w / img_h)
        offset_x = (rect_w - new_w) / 2.0
        scale = rect_h / img_h

    var origin = semantic_rect.position
    return {"scale": scale, "offset": Vector2(offset_x, offset_y) + origin}

func _p2c(xform: Dictionary, pt: Vector2) -> Vector2:
    return pt * xform["scale"] + xform["offset"]

func _draw_maze_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    var nodes_by_id = {}
    for n in preview_layout.get("nodes", []):
        nodes_by_id[n.get("id")] = n
    for e in preview_layout.get("edges", []):
        var a = nodes_by_id.get(e.get("source"))
        var b = nodes_by_id.get(e.get("target"))
        if a and b:
            preview_overlay.draw_line(_p2c(xform, Vector2(a.x, a.y)), _p2c(xform, Vector2(b.x, b.y)), neon_dim, 2.0)
    for n in preview_layout.get("nodes", []):
        preview_overlay.draw_circle(_p2c(xform, Vector2(n.x, n.y)), 3.0, neon)
    for p in preview_layout.get("pickups", []):
        preview_overlay.draw_circle(_p2c(xform, Vector2(p.x, p.y)), 4.0, accent)
    for p in preview_layout.get("players", []):
        preview_overlay.draw_circle(_p2c(xform, Vector2(p.x, p.y)), 7.0, Color(0.0, 1.0, 0.5, 0.95))
    for e in preview_layout.get("enemies", []):
        preview_overlay.draw_circle(_p2c(xform, Vector2(e.x, e.y)), 7.0, Color(1.0, 0.2, 0.4, 0.95))

func _draw_arena_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    var b = preview_layout.get("bounds")
    if b is Rect2:
        _draw_rect_outline(xform, b, neon, 2.5)
    for block in preview_layout.get("cover_blocks", []):
        if block is Rect2:
            _draw_rect_outline(xform, block, neon_dim, 1.5)
    for s in preview_layout.get("spawns", []):
        var pos = s if s is Vector2 else Vector2(s.x, s.y)
        preview_overlay.draw_circle(_p2c(xform, pos), 6.0, accent)

func _draw_lane_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    var b = preview_layout.get("bounds")
    var width = semantic_image.get_width() if semantic_image else 1920.0
    if b is Rect2:
        width = b.size.x
    for lane in preview_layout.get("lanes", []):
        var y = float(lane.get("y", 0.0))
        var lane_type = str(lane.get("type", "safe"))
        var col = neon
        if lane_type == "danger":
            col = Color(1.0, 0.25, 0.35, 0.75)
        elif lane_type == "traffic":
            col = Color(1.0, 0.7, 0.1, 0.7)
        var p1 = _p2c(xform, Vector2(0, y))
        var p2 = _p2c(xform, Vector2(width, y))
        preview_overlay.draw_line(p1, p2, col, 2.0)

func _draw_track_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    var pts = preview_layout.get("centerline_points", [])
    for i in range(pts.size()):
        var a = pts[i]
        var b = pts[(i + 1) % pts.size()]
        preview_overlay.draw_line(_p2c(xform, Vector2(a.x, a.y)), _p2c(xform, Vector2(b.x, b.y)), neon, 2.5)
    for c in preview_layout.get("checkpoints", []):
        preview_overlay.draw_circle(_p2c(xform, Vector2(c.x, c.y)), 5.0, accent)

func _draw_platform_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    for plat in preview_layout.get("platforms", []):
        var p1 = plat.get("p1")
        var p2 = plat.get("p2")
        if p1 and p2:
            preview_overlay.draw_line(_p2c(xform, Vector2(p1.x, p1.y)), _p2c(xform, Vector2(p2.x, p2.y)), neon, 4.0)
    for s in preview_layout.get("spawns", []):
        var pos = s if s is Vector2 else Vector2(s.x, s.y)
        preview_overlay.draw_circle(_p2c(xform, pos), 6.0, accent)

func _draw_region_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    var b = preview_layout.get("bounds")
    if b is Rect2:
        _draw_rect_outline(xform, b, neon_dim, 1.5)
    for r in preview_layout.get("regions", []):
        if r is Rect2:
            _draw_rect_outline(xform, r, neon, 2.0)

func _draw_well_fill_layout(xform: Dictionary, neon: Color, neon_dim: Color, accent: Color):
    var b = preview_layout.get("bounds")
    if b is Rect2:
        _draw_rect_outline(xform, b, neon, 2.5)
    var cell_size = float(preview_layout.get("cell_size", 16.0))
    var half = Vector2(cell_size, cell_size) * xform["scale"] * 0.5
    for cell in preview_layout.get("cells", []):
        var center = _p2c(xform, Vector2(cell.x, cell.y))
        preview_overlay.draw_rect(Rect2(center - half, half * 2.0), neon_dim, true)
    var poly = preview_layout.get("well_polygon", [])
    if poly.size() > 1:
        for i in range(poly.size()):
            var a = poly[i]
            var b2 = poly[(i + 1) % poly.size()]
            preview_overlay.draw_line(_p2c(xform, Vector2(a.x, a.y)), _p2c(xform, Vector2(b2.x, b2.y)), neon, 2.5)
    if preview_layout.has("spawn_lip"):
        var lip = preview_layout["spawn_lip"]
        preview_overlay.draw_circle(_p2c(xform, Vector2(lip.x, lip.y)), 6.0, accent)

func _draw_rect_outline(xform: Dictionary, rect: Rect2, color: Color, width: float):
    var p0 = _p2c(xform, rect.position)
    var p1 = _p2c(xform, rect.position + Vector2(rect.size.x, 0))
    var p2 = _p2c(xform, rect.position + rect.size)
    var p3 = _p2c(xform, rect.position + Vector2(0, rect.size.y))
    preview_overlay.draw_line(p0, p1, color, width)
    preview_overlay.draw_line(p1, p2, color, width)
    preview_overlay.draw_line(p2, p3, color, width)
    preview_overlay.draw_line(p3, p0, color, width)
