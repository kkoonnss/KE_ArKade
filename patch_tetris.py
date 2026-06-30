import sys

def patch_tetris(filepath):
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
            
        if "var settings_container: VBoxContainer" in line:
            i += 1
            continue
            
        if "    # Tab Menu" in line:
            while i < len(lines) and "if screenshot_path !=" not in lines[i]:
                i += 1
            out.append("""    tab_menu = TabMenu.new()
    add_child(tab_menu)
    tab_menu.register_knob_bool("invert", "Invert", false)
    tab_menu.register_knob_bool("fill", "Fill", false)
    tab_menu.register_knob_float("grid_scale", "Grid Scale", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_float("density", "Density", 1.0, 0.1, 2.0, 0.1)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true)
    tab_menu.register_knob_float("wall_width", "Wall Width", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_enum("organic_behavior", "Organic Behavior", "stick", ["stick", "slide", "tumble"])
    tab_menu.register_knob_bool("show_outline", "Show Level Outline", true)
    tab_menu.register_knob_bool("show_grid", "Show Grid", true)
    
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    
    tab_menu.setup("tetris", level_dir, "TETRIS")
    _apply_settings_from_menu()

""")
            continue
            
        if "func _input(event):" in line:
            out.append("""func _apply_settings_from_menu():
    if tab_menu:
        settings["organic_behavior"] = tab_menu.get_knob_value("organic_behavior")
        settings["show_outline"] = tab_menu.get_knob_value("show_outline")
        settings["show_grid"] = tab_menu.get_knob_value("show_grid")

func _on_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["invert", "fill", "grid_scale", "density", "bounds_clamp", "wall_width"]:
        load_level()
    queue_redraw()

func _on_menu_action(action_id: String):
    pass

""")
            out.append(line)
            i += 1
            # Skip the old tab_menu visibility toggle
            while i < len(lines) and "if event is InputEventKey and event.pressed:" not in lines[i]:
                i += 1
            continue
            
        if "var path = level_dir + \"/derived/container.json\"" in line:
            while i < len(lines) and "grid_width = int(1920 / BLOCK_SIZE) + 1" not in lines[i]:
                i += 1
            out.append("""    var adapter = WellFillAdapter.new()
    var knobs = {}
    if tab_menu:
        knobs = {
            "invert": tab_menu.get_knob_value("invert"),
            "fill": tab_menu.get_knob_value("fill"),
            "grid_scale": tab_menu.get_knob_value("grid_scale"),
            "density": tab_menu.get_knob_value("density"),
            "bounds_clamp": tab_menu.get_knob_value("bounds_clamp"),
            "wall_width": tab_menu.get_knob_value("wall_width")
        }
    var layout = adapter.interpret(level_dir, {}, knobs)
    
    well_polygon.clear()
    for p in layout.get("well_polygon", []):
        well_polygon.append(Vector2(p.x * scale_factor + offset_x, p.y * scale_factor + offset_y))
    
    var lip = layout.get("spawn_lip", Vector2(map_w / 2.0, 0))
    spawn_lip = Vector2(lip.x * scale_factor + offset_x, lip.y * scale_factor + offset_y)
    
    down_direction = layout.get("down_direction", Vector2(0, 1))
    
    var grid_cells = layout.get("cells", [])
    
    # Init Grid
""")
            continue
            
        if "# Convenience check using grid.json if available" in line:
            out.append("            # Convenience check using adapter cells\n")
            out.append("            var map_center = (center - Vector2(offset_x, offset_y)) / scale_factor\n")
            out.append("            var c_size = layout.get(\"cell_size\", 32.0)\n")
            out.append("            for c in grid_cells:\n")
            out.append("                if abs(c.x - map_center.x) < c_size/2.0 and abs(c.y - map_center.y) < c_size/2.0:\n")
            out.append("                    is_blocked = true\n")
            out.append("                    break\n")
            i += 1
            while i < len(lines) and "if is_blocked:" not in lines[i]:
                i += 1
            continue

        out.append(line)
        i += 1

    with open(filepath, 'w') as f:
        f.writelines(out)

patch_tetris("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/cartridges/tetris/main.gd")
