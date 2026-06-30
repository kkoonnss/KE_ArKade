import sys

def patch_donkey_kong(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        if "var tab_menu: ColorRect" in line:
            out.append("var tab_menu: TabMenu\n")
            i += 1
            continue
            
        if "var tab_menu_shell: BoxContainer" in line or "var tab_cover_frame: PanelContainer" in line or "var tab_cover_rect: TextureRect" in line:
            i += 1
            continue
            
        if "    tab_menu.visible = true" in line or "    _set_menu_mode(true)" in line:
            i += 1
            continue
            
        if "func _build_ui():" in line:
            out.append("""func _build_ui():
    var bg_layer = CanvasLayer.new()
    bg_layer.layer = -100
    add_child(bg_layer)
    var black = ColorRect.new()
    black.color = Color.BLACK
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg_layer.add_child(black)

    ui_canvas = CanvasLayer.new()
    ui_canvas.layer = 100
    add_child(ui_canvas)
    splash_rect = TextureRect.new()
    splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path):
        var img = Image.load_from_file(splash_path)
        if img:
            splash_rect.texture = ImageTexture.create_from_image(img)
    ui_canvas.add_child(splash_rect)

    tab_menu = TabMenu.new()
    ui_canvas.add_child(tab_menu)
    tab_menu.register_knob_float("jump_height", "Jump Height", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_float("platform_snap", "Platform Snap", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_bool("add_platforms", "Add Platforms", true)
    tab_menu.register_knob_float("climb_tolerance", "Climb Tolerance", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_float("hazard_leniency", "Hazard Leniency", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true)
    
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    
    tab_menu.setup("donkey_kong", level_dir, "DONKEY KONG")
""")
            # Skip old _build_ui
            i += 1
            while i < len(lines) and "func _menu_panel_style" not in lines[i]:
                i += 1
            continue
            
        if "func _menu_panel_style" in line:
            # skip this and _set_menu_mode
            while i < len(lines) and "func _connect_ipc" not in lines[i]:
                i += 1
            
            # add our handlers before _connect_ipc
            out.append("""func _on_knob_changed(knob_id: String, value):
    pass

func _on_menu_action(action_id: String):
    pass

""")
            continue
            
        if "func load_level():" in line:
            out.append("""var adapter_platforms = []
var adapter_spawns = []

func load_level():
    grid.clear()
    walkable.clear()
    solids.clear()
    var loaded = false
    
    var adapter = PlatformAdapter.new()
    var knobs = {}
    if tab_menu:
        knobs = {
            "jump_height": tab_menu.get_knob_value("jump_height"),
            "platform_snap": tab_menu.get_knob_value("platform_snap"),
            "add_platforms": tab_menu.get_knob_value("add_platforms"),
            "climb_tolerance": tab_menu.get_knob_value("climb_tolerance"),
            "hazard_leniency": tab_menu.get_knob_value("hazard_leniency"),
            "bounds_clamp": tab_menu.get_knob_value("bounds_clamp")
        }
    var layout = adapter.interpret(level_dir, {}, knobs)
    adapter_platforms = layout.get("platforms", [])
    adapter_spawns = layout.get("spawns", [])
    
    if level_dir != "":
        var sem = level_dir.path_join("semantic_map.png")
        if FileAccess.file_exists(sem):
            var img = Image.load_from_file(sem)
            if img:
                map_w = img.get_width()
                map_h = img.get_height()
        _load_reference()
    _update_scale()
""")
            i += 1
            while i < len(lines) and "func _load_occupancy():" not in lines[i]:
                i += 1
            continue

        if "func _setup_platforms():" in line:
            out.append("""func _setup_platforms():
    if adapter_platforms.size() > 0:
        for p in adapter_platforms:
            var min_x = min(p.p1.x, p.p2.x) * scale_factor + offset.x
            var max_x = max(p.p1.x, p.p2.x) * scale_factor + offset.x
            var py = p.p1.y * scale_factor + offset.y
            platforms.append(Rect2(min_x, py, max_x - min_x, 5))
        # Ladders for now can remain procedurally added or empty if we don't have ladder definitions yet
        for x in [0.24, 0.44, 0.64, 0.82]:
            ladders.append(Rect2(map_w * x * scale_factor + offset.x, map_h * 0.22 * scale_factor + offset.y, 6, map_h * 0.66 * scale_factor))
    else:
""")
            out.append("        for i in range(5):\n")
            out.append("            var y = map_h * (0.22 + i * 0.16)\n")
            out.append("            var x = map_w * (0.12 if i % 2 == 0 else 0.20)\n")
            out.append("            platforms.append(Rect2(x, y, map_w * 0.72, 5))\n")
            out.append("        for x in [0.24, 0.44, 0.64, 0.82]:\n")
            out.append("            ladders.append(Rect2(map_w * x, map_h * 0.22, 6, map_h * 0.66))\n")
            
            i += 1
            while i < len(lines) and "func _setup_barrel():" not in lines[i]:
                i += 1
            continue

        out.append(line)
        i += 1

    with open(filepath, 'w') as f:
        f.writelines(out)

patch_donkey_kong("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/cartridges/donkey_kong/main.gd")
