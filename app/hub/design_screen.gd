extends Control

var Palette

@onready var bg_rect = $Layout/Workspace/CanvasMargin/CanvasContainer/BgRect
@onready var semantic_rect = $Layout/Workspace/CanvasMargin/CanvasContainer/SemanticRect
@onready var virtual_cursor = $Layout/Workspace/CanvasMargin/CanvasContainer/VirtualCursor
@onready var sidebar_vbox = $Layout/Sidebar/Scroll/VBox
@onready var file_dialog = $FileDialog

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

func _ready():
    Palette = load(_get_repo_root().path_join("app/shared/palette.gd"))
    _build_ui()
    virtual_cursor.size = Vector2(brush_size*2, brush_size*2)
    virtual_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)
    set_process(true)
    
    file_dialog.file_selected.connect(_on_file_selected)

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
    if virtual_cursor:
        virtual_cursor.visible = true
        virtual_cursor.position = cursor_pos - Vector2(brush_size, brush_size)
        virtual_cursor.color = Color(Palette.CLASSES[current_class_id]["authoring_color"])
        virtual_cursor.color.a = 0.5
        
    if Input.is_joy_button_pressed(0, JOY_BUTTON_A) or is_painting:
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
