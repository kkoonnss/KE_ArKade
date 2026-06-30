import sys

def patch_gta(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        if "var ui_canvas: CanvasLayer" in line:
            out.append("var tab_menu: TabMenu\n")
            out.append(line)
            i += 1
            continue
            
        if "var loaded_level_key = \"\"" in line:
            out.append("var tab_menu: TabMenu\n")
            out.append(line)
            i += 1
            continue
            
        if "func _ready():" in line:
            out.append(line)
            out.append("    tab_menu = TabMenu.new()\n")
            out.append("    add_child(tab_menu)\n")
            out.append("    tab_menu.register_knob_float(\"block_size\", \"Block Size\", 1.0, 0.5, 2.0, 0.1)\n")
            out.append("    tab_menu.register_knob_bool(\"invert\", \"Invert\", false)\n")
            out.append("    tab_menu.register_knob_float(\"density\", \"Density\", 1.0, 0.1, 2.0, 0.1)\n")
            out.append("    tab_menu.register_knob_bool(\"bounds_clamp\", \"Bounds Clamp\", true)\n")
            out.append("    tab_menu.register_knob_bool(\"smooth\", \"Smooth\", false)\n")
            out.append("    tab_menu.connect(\"knob_changed\", Callable(self, \"_on_knob_changed\"))\n")
            out.append("    tab_menu.connect(\"action_triggered\", Callable(self, \"_on_menu_action\"))\n")
            out.append("    tab_menu.setup(\"gta\", level_dir, \"GTA\")\n")
            i += 1
            continue
            
        if "func _notification(what):" in line:
            out.append("""func _on_knob_changed(knob_id: String, value):
    load_level()
    queue_redraw()

func _on_menu_action(action_id: String):
    pass

""")
            out.append(line)
            i += 1
            continue
            
        if "func load_level():" in line:
            out.append("""func load_level():
    loaded_level_key = level_dir
    var adapter = RegionAdapter.new()
    var knobs = {}
    if tab_menu:
        knobs = {
            "block_size": tab_menu.get_knob_value("block_size"),
            "invert": tab_menu.get_knob_value("invert"),
            "density": tab_menu.get_knob_value("density"),
            "bounds_clamp": tab_menu.get_knob_value("bounds_clamp"),
            "smooth": tab_menu.get_knob_value("smooth")
        }
    var layout = adapter.interpret(level_dir, {}, knobs)
    
    cell_px = layout.get("cell_size", 16.0)
    var b = layout.get("bounds", Rect2(0, 0, 1280, 720))
    map_w = b.size.x
    map_h = b.size.y
    grid = layout.get("cells", [])
    
    if grid.is_empty():
        _build_fallback_grid()
    else:
        grid_h = grid.size()
        grid_w = grid[0].size() if grid_h > 0 else 0
        
    _collect_cells()
    _update_scale()
""")
            # Skip old load_level
            i += 1
            while i < len(lines) and "func _update_scale():" not in lines[i]:
                i += 1
            continue
            
        # Optional: Skip _load_semantic_map and _class_from_color
        if "func _load_semantic_map(path: String):" in line:
            while i < len(lines) and "func _collect_cells():" not in lines[i]:
                i += 1
            continue

        out.append(line)
        i += 1

    with open(filepath, 'w') as f:
        f.writelines(out)

patch_gta("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/cartridges/gta/main.gd")
