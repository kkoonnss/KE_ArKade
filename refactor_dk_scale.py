import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Variables
old_vars = '''var current_level_seed = -1\nvar current_platform_trim = 0.08'''
new_vars = '''var current_level_seed = -1\nvar current_platform_trim = 0.08\nvar current_level_scale = 1.0\nvar logical_w = 1920.0\nvar logical_h = 1080.0\nvar barrel_spawner = {}\nvar player_spawn = Vector2.ZERO'''
code = code.replace(old_vars, new_vars)

# 2. Register Knobs
old_reg = '''    tab_menu.register_knob_float("platform_trim", "Platform Trim", 0.08, 0.0, 0.25, 0.01, "Secondary")'''
new_reg = '''    tab_menu.register_knob_float("platform_trim", "Platform Trim", 0.08, 0.0, 0.25, 0.01, "Secondary")\n    tab_menu.register_knob_float("level_scale", "Level Scale", 1.0, 0.2, 2.0, 0.1, "Secondary")'''
code = code.replace(old_reg, new_reg)

# 3. Handle Knobs
old_handle = '''    elif knob_id == "platform_trim":\n        current_platform_trim = float(value)\n        load_level()'''
new_handle = '''    elif knob_id == "platform_trim":\n        current_platform_trim = float(value)\n        load_level()\n        reset_game()\n    elif knob_id == "level_scale":\n        current_level_scale = float(value)\n        load_level()\n        reset_game()'''
# And we also need to add reset_game() to other knobs for live updating
code = code.replace('''    elif knob_id == "slope_angle":\n        current_slope_angle = float(value)\n        load_level()''', '''    elif knob_id == "slope_angle":\n        current_slope_angle = float(value)\n        load_level()\n        reset_game()''')
code = code.replace('''    elif knob_id == "fire_enemy_count":\n        current_fire_enemy_count = int(value)\n        load_level()''', '''    elif knob_id == "fire_enemy_count":\n        current_fire_enemy_count = int(value)\n        load_level()\n        reset_game()''')
code = code.replace('''    elif knob_id == "level_seed":\n        current_level_seed = int(value)\n        load_level()''', '''    elif knob_id == "level_seed":\n        current_level_seed = int(value)\n        load_level()\n        reset_game()''')
code = code.replace(old_handle, new_handle)

# 4. load_level
old_load_level = '''func load_level():\n    grid.clear()'''
new_load_level = '''func load_level():\n    if game_id == "donkey_kong":\n        logical_w = map_w / max(0.1, current_level_scale)\n        logical_h = map_h / max(0.1, current_level_scale)\n    else:\n        logical_w = map_w\n        logical_h = map_h\n    grid.clear()'''
code = code.replace(old_load_level, new_load_level)

# 5. _setup_classic_donkey_kong
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
        
    var tier_spacing = logical_h * 0.15
    var num_tiers = int((logical_h * 0.95) / tier_spacing)
    num_tiers = max(3, num_tiers)
    
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
        elif i == num_tiers - 1:
            t_left = y_center
            t_right = y_center
            p_left = logical_w * 0.15
            p_right = logical_w * 0.85
        else:
            if is_even:
                p_right -= trim
            else:
                p_left += trim
                
        _add_platform(Rect2(p_left, min(t_left, t_right), p_right - p_left, 5), t_left, t_right)
        
        if i < num_tiers - 1:
            var lx = logical_w * rng.randf_range(0.75, 0.85) if is_even else logical_w * rng.randf_range(0.15, 0.25)
            _add_dynamic_ladder(lx, y_center - 10)
            
            if rng.randf() < 0.6:
                var bx = logical_w * rng.randf_range(0.40, 0.60)
                _add_dynamic_broken_ladder(bx, y_center - 10)
                
            if rng.randf() < 0.5:
                var ex = logical_w * rng.randf_range(0.35, 0.65)
                _add_dynamic_ladder(ex, y_center - 10)
                
    var top_y = logical_h * 0.94 - (num_tiers - 1) * tier_spacing
    var dk_x = logical_w * 0.85 if (num_tiers - 2) % 2 == 0 else logical_w * 0.15
    var barrel_spawn_x = logical_w * 0.78 if (num_tiers - 2) % 2 == 0 else logical_w * 0.22
    var barrel_vel_x = -120 if (num_tiers - 2) % 2 == 0 else 120
    
    _add_platform(Rect2(dk_x - logical_w * 0.1, top_y, logical_w * 0.2, 5), top_y, top_y)
    
    items.append({"pos": Vector2(logical_w * 0.5, top_y - logical_h * 0.05), "kind": "goal"})
    
    var fcount = current_fire_enemy_count
    for i in range(min(fcount, num_tiers - 1)):
        fire_guys.append({"tier": i, "pos": Vector2(logical_w * 0.5, logical_h * 0.94 - i * tier_spacing), "vel": Vector2(100, 0)})
        
    barrel_spawner = {"pos": Vector2(barrel_spawn_x, top_y - 20), "vel_x": barrel_vel_x}
    player_spawn = Vector2(logical_w * 0.85, logical_h * 0.92)

'''
code = code.replace(old_setup, new_setup)

# 6. _setup_barrel
old_barrel = '''func _setup_barrel():
    _setup_platforms()
    player["pos"] = Vector2(map_w * 0.85, map_h * 0.92)
    items.append({"pos": Vector2(map_w * 0.82, map_h * 0.13), "kind": "goal"})'''
new_barrel = '''func _setup_barrel():
    _setup_platforms()
    if player_spawn != Vector2.ZERO:
        player["pos"] = player_spawn'''
code = code.replace(old_barrel, new_barrel)

# 7. Map bounds in Donkey Kong logic
code = code.replace('''if b["pos"].x < -60 or b["pos"].x > map_w + 60 or b["pos"].y > map_h:''', '''if b["pos"].x < -60 or b["pos"].x > logical_w + 60 or b["pos"].y > logical_h:''')
code = code.replace('''barrels.append({"pos": Vector2(map_w * 0.22, map_h * 0.18), "vel": Vector2(120, 0), "jumped": false, "ladder": false, "cooldown": 0.0})''', '''if not barrel_spawner.is_empty():\n            barrels.append({"pos": barrel_spawner["pos"], "vel": Vector2(barrel_spawner["vel_x"], 0), "jumped": false, "ladder": false, "cooldown": 0.0})''')
code = code.replace('''var y_bot = map_h * 1.5''', '''var y_bot = logical_h * 1.5''')
code = code.replace('''if y_bot < map_h * 1.5:''', '''if y_bot < logical_h * 1.5:''')

# 8. Transform scaling in _draw()
old_draw = '''    if game_id == "donkey_kong":
        _draw_platform_game(barrels, C_ORANGE)'''
new_draw = '''    if game_id == "donkey_kong":
        draw_set_transform(offset, 0.0, Vector2(scale_factor * current_level_scale, scale_factor * current_level_scale))
        _draw_platform_game(barrels, C_ORANGE)
        draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))'''
code = code.replace(old_draw, new_draw)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
