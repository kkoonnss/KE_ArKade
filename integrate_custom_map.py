import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Add `walls` variable
if "var walls = []" not in code:
    code = code.replace(
        "var platforms = []",
        "var platforms = []\nvar walls = []"
    )

# 2. Clear walls in reset_game
if "walls.clear()" not in code:
    code = code.replace(
        "platforms.clear()",
        "platforms.clear()\n    walls.clear()"
    )

# 3. Replace _setup_platforms
old_setup_platforms = '''func _setup_platforms():
    if level_dir.get_file().begins_with("classic") or level_dir.ends_with("classic"):
        _setup_classic_donkey_kong()
        return
    if adapter_platforms.size() > 0:
        for p in adapter_platforms:
            var min_x = min(p["p1"].x, p["p2"].x) * scale_factor + offset.x
            var max_x = max(p["p1"].x, p["p2"].x) * scale_factor + offset.x
            var py = p["p1"].y * scale_factor + offset.y
            _add_platform(Rect2(min_x, py, max_x - min_x, 5), py, py)
        # Ladders for now can remain procedurally added or empty if we don't have ladder definitions yet
        for x in [0.24, 0.44, 0.64, 0.82]:
            ladders.append(Rect2(map_w * x * scale_factor + offset.x, map_h * 0.22 * scale_factor + offset.y, 6, map_h * 0.66 * scale_factor))
    else:
        for i in range(5):
            var y = map_h * (0.22 + i * 0.16)
            var x = map_w * (0.12 if i % 2 == 0 else 0.20)
            _add_platform(Rect2(x, y, map_w * 0.72, 5), y, y)
        for x in [0.24, 0.44, 0.64, 0.82]:
            ladders.append(Rect2(map_w * x, map_h * 0.22, 6, map_h * 0.66))'''

new_setup_platforms = '''func _setup_platforms():
    if level_dir.get_file().begins_with("classic") or level_dir.ends_with("classic"):
        _setup_classic_donkey_kong()
        return
    _setup_custom_donkey_kong()

func _setup_custom_donkey_kong():
    platforms.clear()
    ladders.clear()
    broken_ladders.clear()
    walls.clear()
    fire_guys.clear()
    items.clear()
    
    var rng = RandomNumberGenerator.new()
    if current_level_seed < 0:
        rng.randomize()
    else:
        rng.seed = current_level_seed
        
    var cs = max(0.1, current_level_scale)
    
    # 1. Custom Walls (Islands)
    if grid.size() > 0:
        for y in range(grid.size()):
            var row = grid[y]
            for x in range(row.size()):
                if row[x] == 1: # Solid
                    var wx = (x * cell_px) / cs
                    var wy = (y * cell_px) / cs
                    var ws = cell_px / cs
                    walls.append(Rect2(wx, wy, ws, ws))
    
    # 2. Custom Platforms
    var sorted_platforms = []
    for p in adapter_platforms:
        sorted_platforms.append(p)
    sorted_platforms.sort_custom(func(a, b): return a["p1"].y < b["p1"].y)
    
    var dir = 1
    for p in sorted_platforms:
        var min_x = min(p["p1"].x, p["p2"].x) / cs
        var max_x = max(p["p1"].x, p["p2"].x) / cs
        var py = p["p1"].y / cs
        
        var trim = (max_x - min_x) * current_platform_trim
        min_x += trim
        max_x -= trim
        if max_x <= min_x + 10: continue
        
        var y_left = py
        var y_right = py
        var slope = (current_slope_angle * 10)
        y_left -= dir * slope
        y_right += dir * slope
        
        _add_platform(Rect2(min_x, min(y_left, y_right), max_x - min_x, 5), y_left, y_right)
        dir *= -1
        
    # 3. Dynamic Ladders
    for p in platforms:
        var r = p["rect"]
        var num_ladders = int(r.size.x / (logical_w * current_platform_spacing))
        num_ladders = max(1, num_ladders)
        for i in range(num_ladders):
            var lx = r.position.x + r.size.x * (float(i+1)/(num_ladders+1))
            var y_approx = _platform_y(Vector2(lx, p["y_left"] - 10))
            if rng.randf() < 0.2:
                _add_dynamic_broken_ladder(lx, y_approx)
            else:
                _add_dynamic_ladder(lx, y_approx)
                
    # 4. Spawns
    if platforms.size() > 0:
        var lowest_p = platforms[0]
        var highest_p = platforms[0]
        for p in platforms:
            var cy = (p["y_left"] + p["y_right"]) / 2.0
            var ly = (lowest_p["y_left"] + lowest_p["y_right"]) / 2.0
            var hy = (highest_p["y_left"] + highest_p["y_right"]) / 2.0
            if cy > ly: lowest_p = p
            if cy < hy: highest_p = p
            
        player_spawn = Vector2(lowest_p["rect"].position.x + lowest_p["rect"].size.x * 0.8, lowest_p["y_right"] - 13)
        barrel_spawner = {
            "pos": Vector2(highest_p["rect"].position.x + highest_p["rect"].size.x * 0.2, highest_p["y_left"] - 40),
            "vel_x": 120
        }
        items.append({"pos": Vector2(highest_p["rect"].position.x + highest_p["rect"].size.x * 0.5, highest_p["y_left"] - 25)})
        
        for i in range(current_fire_enemy_count):
            fire_guys.append({"pos": Vector2(lowest_p["rect"].position.x + lowest_p["rect"].size.x * 0.2, lowest_p["y_left"] - 13), "vel_x": 60, "cool": 0})
    else:
        player_spawn = Vector2(logical_w * 0.85, logical_h * 0.92)'''

code = code.replace(old_setup_platforms, new_setup_platforms)

# 4. Block player on walls
old_platform_move = '''    pos += vel * delta
    player["on_ground"] = false'''
new_platform_move = '''    var new_x = pos.x + vel.x * delta
    var hit_wall = false
    for w in walls:
        if w.has_point(Vector2(new_x + sign(vel.x)*12, pos.y - 12)):
            hit_wall = true
            break
    if not hit_wall:
        pos.x = new_x
    pos.y += vel.y * delta
    player["on_ground"] = false'''
code = code.replace(old_platform_move, new_platform_move)

# 5. Bounce barrels on walls
old_tick_barrel = '''        b["pos"] += b["vel"] * delta
        var py = _platform_y(b["pos"])'''
new_tick_barrel = '''        var new_x = b["pos"].x + b["vel"].x * delta
        var hit_wall = false
        for w in walls:
            if w.has_point(Vector2(new_x + sign(b["vel"].x)*12, b["pos"].y - 10)):
                hit_wall = true
                break
        if hit_wall:
            b["vel"].x *= -1
        else:
            b["pos"].x = new_x
        b["pos"].y += b["vel"].y * delta
        var py = _platform_y(b["pos"])'''
code = code.replace(old_tick_barrel, new_tick_barrel)

# 6. Draw walls
if "for w in walls:" not in code:
    old_draw = '''    for t in things:
        var pos = t.get("pos", Vector2.ZERO)
        _draw_thing(pos, C_MAGENTA)'''
    new_draw = '''    for w in walls:
        draw_rect(w, Color(0.2, 0.4, 0.8, 0.5), false, 2)
    for t in things:
        var pos = t.get("pos", Vector2.ZERO)
        _draw_thing(pos, C_MAGENTA)'''
    code = code.replace(old_draw, new_draw)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
