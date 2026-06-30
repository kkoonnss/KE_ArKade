import sys

def patch_pacman(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        if "    var grid_loaded = false" in line and "var grid_layer_path = level_dir + \"/derived/grid.json\"" in lines[i+1]:
            out.append("""    var adapter = MazeAdapter.new()
    var knobs = {
        "grid_size_scale": grid_size_scale,
        "invert_main_solid": invert_main_solid
    }
    var layout = adapter.interpret(level_dir, {}, knobs)
    
    grid_cell_size = layout.get("grid_cell_size", 32.0 * grid_size_scale)
    graph_nodes = layout.get("nodes", [])
    graph_edges = layout.get("edges", [])
    
    players.clear()
    for p in layout.get("players", []):
        players.append(Vector2(p.x, p.y))
        
    enemies.clear()
    for e in layout.get("enemies", []):
        enemies.append(Vector2(e.x, e.y))
        
    pickups.clear()
    for pk in layout.get("pickups", []):
        pickups.append({"pos": Vector2(pk.x, pk.y), "power": pk.get("power", false)})
""")
            # Skip old logic
            while i < len(lines) and "    # Calculate bounds" not in lines[i] and "func _load_level_adjustments():" not in lines[i]:
                if "if not grid_loaded:" in lines[i]:
                    # also skip this block
                    pass
                i += 1
            continue

        out.append(line)
        i += 1

    with open(filepath, 'w') as f:
        f.writelines(out)

patch_pacman("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/cartridges/pacman/main.gd")
