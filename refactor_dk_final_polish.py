import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Variables
old_vars = '''var current_level_scale = 1.0'''
new_vars = '''var current_level_scale = 1.0\nvar current_platform_spacing = 0.15\nvar current_barrel_ladder_chance = 0.5'''
code = code.replace(old_vars, new_vars)

# 2. Register Knobs
old_reg = '''    tab_menu.register_knob_float("level_scale", "Level Scale", 1.0, 0.2, 2.0, 0.1, "Secondary")'''
new_reg = '''    tab_menu.register_knob_float("level_scale", "Level Scale", 1.0, 0.2, 2.0, 0.1, "Secondary")\n    tab_menu.register_knob_float("platform_spacing", "Platform Spacing", 0.15, 0.1, 0.3, 0.01, "Secondary")\n    tab_menu.register_knob_float("barrel_ladder_chance", "Barrel Ladder %", 0.5, 0.0, 1.0, 0.05, "Secondary")'''
code = code.replace(old_reg, new_reg)

# 3. Handle Knobs
old_handle = '''    elif knob_id == "level_scale":\n        current_level_scale = float(value)\n        load_level()\n        reset_game()'''
new_handle = '''    elif knob_id == "level_scale":\n        current_level_scale = float(value)\n        load_level()\n        reset_game()\n    elif knob_id == "platform_spacing":\n        current_platform_spacing = float(value)\n        load_level()\n        reset_game()\n    elif knob_id == "barrel_ladder_chance":\n        current_barrel_ladder_chance = float(value)'''
code = code.replace(old_handle, new_handle)

# 4. _setup_classic_donkey_kong
old_setup = code[code.find('func _setup_classic_donkey_kong():'):code.find('func _setup_platforms():')]

new_setup = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    broken_ladders.clear()
    fire_guys.clear()
    items.clear()
    
    var s = current_slope_angle
    var trim = logical_w * current_platform_trim
    
    var rng = RandomNumberGenerator.new()
    if current_level_seed < 0:
        rng.randomize()
    else:
        rng.seed = current_level_seed
        
    var tier_spacing = logical_h * current_platform_spacing
    var num_tiers = int((logical_h * 0.95) / tier_spacing)
    num_tiers = max(3, num_tiers)
    
    # FORCE num_tiers to be ODD so top sloped tier (num_tiers - 1) is EVEN (slopes down to RIGHT)
    if num_tiers % 2 == 0:
        num_tiers -= 1
    
    for i in range(num_tiers):
        var is_even = (i % 2 == 0)
        var y_center = logical_h * 0.94 - i * tier_spacing
        var t_left = y_center
        var t_right = y_center
        
        if is_even:
            t_left -= logical_h * 0.02 * s
            t_right += logical_h * 0.02 * s
        else:
            t_left += logical_h * 0.02 * s
            t_right -= logical_h * 0.02 * s
            
        var p_left = logical_w * 0.1
        var p_right = logical_w * 0.9
        
        if i == 0:
            pass
        else:
            if is_even:
                p_right -= trim
            else:
                p_left += trim
                
        _add_platform(Rect2(p_left, min(t_left, t_right), p_right - p_left, 5), t_left, t_right)
        
        if i < num_tiers - 1:
            var lx = 0.0
            if is_even:
                lx = logical_w * rng.randf_range(0.15, 0.25)
            else:
                lx = logical_w * rng.randf_range(0.75, 0.85)
                
            _add_dynamic_ladder(lx, y_center - 10)
            
            if rng.randf() < 0.6:
                var bx = logical_w * rng.randf_range(0.40, 0.60)
                _add_dynamic_broken_ladder(bx, y_center - 10)
                
            if rng.randf() < 0.5:
                var ex = logical_w * rng.randf_range(0.35, 0.65)
                _add_dynamic_ladder(ex, y_center - 10)
                
    var top_i = num_tiers - 1
    var top_y = logical_h * 0.94 - top_i * tier_spacing
    var goal_y = top_y - tier_spacing
    
    # Top sloped tier (top_i) is EVEN, so it slopes down to RIGHT.
    # Player reaches the LEFT side (high side).
    # DK is on FAR LEFT. Goal is in MIDDLE LEFT.
    
    _add_platform(Rect2(logical_w * 0.10, goal_y, logical_w * 0.15, 5), goal_y, goal_y)
    barrel_spawner = {"pos": Vector2(logical_w * 0.20, goal_y - 20), "vel_x": 120}
    
    _add_platform(Rect2(logical_w * 0.35, goal_y, logical_w * 0.25, 5), goal_y, goal_y)
    items.append({"pos": Vector2(logical_w * 0.45, goal_y - 20), "kind": "goal"})
    
    # Ladder up to goal from the high left side of the top sloped tier
    _add_dynamic_ladder(logical_w * 0.45, goal_y - 5)
    
    var fcount = current_fire_enemy_count
    for i in range(fcount):
        var ftier = rng.randi_range(1, max(1, num_tiers - 1))
        var fy = logical_h * 0.94 - ftier * tier_spacing
        fire_guys.append({"tier": ftier, "pos": Vector2(logical_w * 0.5, fy), "vel": Vector2(100, 0)})
        
    player_spawn = Vector2(logical_w * 0.85, logical_h * 0.92)

'''
code = code.replace(old_setup, new_setup)

# 5. Fix _lose_life
old_lose = '''    else:
        player["pos"] = _safe_pos(Vector2(map_w * 0.18, map_h * 0.78))
        player["vel"] = Vector2.ZERO'''
new_lose = '''    else:
        if game_id == "donkey_kong" and player_spawn != Vector2.ZERO:
            player["pos"] = player_spawn
        else:
            player["pos"] = _safe_pos(Vector2(map_w * 0.18, map_h * 0.78))
        player["vel"] = Vector2.ZERO'''
code = code.replace(old_lose, new_lose)

# 6. Fix flat platform barrel momentum & ladder chance
old_barrel_logic = '''                if dir == 0.0: dir = [-1, 1][randi() % 2]'''
new_barrel_logic = '''                if dir == 0.0: dir = sign(b["vel"].x) if abs(b["vel"].x) > 10 else [-1, 1][randi() % 2]'''
code = code.replace(old_barrel_logic, new_barrel_logic)

code = code.replace('''if randf() < 0.5:\n                    b["ladder"] = true''', '''if randf() < current_barrel_ladder_chance:\n                    b["ladder"] = true''')

# 7. Draw Donkey Kong
old_draw = '''func _draw_platform_game(things, color: Color):'''
new_draw = '''func _draw_donkey_kong(pos: Vector2):
    var pts = PackedVector2Array([
        pos + Vector2(0, -20),
        pos + Vector2(20, 0),
        pos + Vector2(0, 20),
        pos + Vector2(-20, 0)
    ])
    draw_colored_polygon(pts, Color(1, 0, 0, 0.4))
    draw_polyline(pts + PackedVector2Array([pts[0]]), Color.RED, 2.0)

func _draw_platform_game(things, color: Color):
    if not barrel_spawner.is_empty():
        _draw_donkey_kong(barrel_spawner["pos"])'''
code = code.replace(old_draw, new_draw)


with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
