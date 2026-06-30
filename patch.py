import sys

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Replace variables at top
        if "var splash_rect: TextureRect" in line:
            out.append("var tab_menu: TabMenu\n")
            while i < len(lines) and ("var level_adjustments_loaded" not in lines[i]):
                i += 1
            i += 1
            continue
            
        # Replace _ready up to canvas.layer
        if "func _ready():" in line:
            out.append(line)
            i += 1
            while i < len(lines) and "load_level()" not in lines[i]:
                out.append(lines[i])
                i += 1
            # found load_level()
            while i < len(lines) and ("if screenshot_path != \"\":" not in lines[i]):
                i += 1
            out.append("""    tab_menu = TabMenu.new()
    add_child(tab_menu)
    tab_menu.register_knob_int("players", "Players", 1, 1, 4, 1)
    tab_menu.register_knob_enum("skin", "Skin", "classic", ["classic", "neon"])
    tab_menu.register_knob_bool("reference", "Reference Overlay", false)
    tab_menu.register_knob_float("reference_opacity", "Reference Opacity", 0.15, 0.0, 1.0, 0.05)
    tab_menu.register_knob_float("grid_scale", "Grid Size", 1.0, 0.6, 1.6, 0.05)
    tab_menu.register_knob_float("wall_width", "Wall Width", 1.0, 0.55, 1.65, 0.05)
    tab_menu.register_knob_bool("invert_main_solid", "Invert Main Solid", false)
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    tab_menu.connect("menu_closed", Callable(self, "_on_menu_closed"))
    
    tab_menu.setup("pacman", level_dir, level_name)
    _apply_settings_from_menu()
    
    load_level()
    load_background()
    
""")
            continue
            
        # Replace _input
        if "func _input(event):" in line:
            out.append(line)
            out.append("""    if game_state in ["game_over", "win"]:
        if (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or \\
           (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
            _restart_game()
            return
            
""")
            while i < len(lines) and ("func _build_menu_overlay" not in lines[i]):
                i += 1
            continue
            
        # Delete menu functions
        if "func _build_menu_overlay(" in line:
            while i < len(lines) and ("func load_background()" not in lines[i]):
                i += 1
            out.append("""func _apply_settings_from_menu():
    selected_players = tab_menu.get_knob_value("players")
    current_skin = tab_menu.get_knob_value("skin")
    show_background = tab_menu.get_knob_value("reference")
    background_opacity = tab_menu.get_knob_value("reference_opacity")
    grid_size_scale = tab_menu.get_knob_value("grid_scale")
    classic_wall_width_scale = tab_menu.get_knob_value("wall_width")
    invert_main_solid = tab_menu.get_knob_value("invert_main_solid")

func _on_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["grid_scale", "invert_main_solid"]:
        load_level()
    queue_redraw()

func _on_menu_action(action_id: String):
    if action_id == "start":
        if game_state in ["game_over", "win"]:
            _restart_game()
        else:
            game_state = "playing"

func _on_menu_closed():
    pass

""")
            continue
            
        if "grid_cell_size = grid_cell_size_base * grid_size_scale" in line:
            out.append('                grid_cell_size = MapFitOps.grid_scale(grid_cell_size_base, grid_size_scale)\n')
            # Add fill invert
            # Wait, this happens in two places!
            out.append('                var raw_cells = grid_data.get("cells", [])\n')
            out.append('                grid_cells = MapFitOps.fill_invert(raw_cells, invert_main_solid)\n')
            i += 2 # skip `grid_cells = grid_data.get("cells", [])`
            continue
            
        if "if not _effective_is_solid_class(cid):" in line:
            out.append("                        if cid != 1:\n")
            i += 1
            continue
            
        if "func _effective_is_solid_class(cid: int) -> bool:" in line:
            out.append(line)
            out.append("    return cid == 1\n")
            i += 6 # skip the 6 lines of old function
            continue
            
        if "var wall_w = max(6.0, grid_cell_size * 0.34 * classic_wall_width_scale)" in line:
            out.append("        var wall_w = MapFitOps.wall_width(max(6.0, grid_cell_size * 0.34), classic_wall_width_scale)\n")
            i += 1
            continue

        if "if overlay_mode == \"\" and game_state in [\"playing\", \"respawning\"]:" in line:
            out.append("        if tab_menu.overlay_mode == \"\" and game_state in [\"playing\", \"respawning\"]:\n")
            i += 1
            continue

        out.append(line)
        i += 1

    with open(filepath, 'w') as f:
        f.writelines(out)

process_file("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/cartridges/pacman/main.gd")
