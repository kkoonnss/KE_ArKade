import re
with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Variables
old_vars = '''var current_bounds_clamp = true'''
new_vars = '''var current_bounds_clamp = true\nvar current_level_seed = -1\nvar current_platform_trim = 0.08'''
code = code.replace(old_vars, new_vars)

# 2. Register Knobs
old_reg = '''    tab_menu.register_knob_float("slope_angle", "Slope Angle", 1.0, 0.0, 3.0, 0.1, "Secondary")
    tab_menu.register_knob_int("fire_enemy_count", "Fire Enemies", 1, 0, 4, 1, "Secondary")'''
new_reg = '''    tab_menu.register_knob_float("slope_angle", "Slope Angle", 1.0, 0.0, 3.0, 0.1, "Secondary")
    tab_menu.register_knob_int("fire_enemy_count", "Fire Enemies", 1, 0, 4, 1, "Secondary")
    tab_menu.register_knob_int("level_seed", "Level Seed (-1 = Random)", -1, -1, 9999, 1, "Secondary")
    tab_menu.register_knob_float("platform_trim", "Platform Trim", 0.08, 0.0, 0.25, 0.01, "Secondary")'''
code = code.replace(old_reg, new_reg)

# 3. Handle Knobs
old_handle = '''    elif knob_id == "slope_angle": current_slope_angle = float(value)
    elif knob_id == "fire_enemy_count": current_fire_enemy_count = int(value)'''
new_handle = '''    elif knob_id == "slope_angle":
        current_slope_angle = float(value)
        load_level()
    elif knob_id == "fire_enemy_count":
        current_fire_enemy_count = int(value)
        load_level()
    elif knob_id == "level_seed":
        current_level_seed = int(value)
        load_level()
    elif knob_id == "platform_trim":
        current_platform_trim = float(value)
        load_level()'''
code = code.replace(old_handle, new_handle)

# 4. _setup_classic_donkey_kong
old_setup = code[code.find('func _setup_classic_donkey_kong():'):code.find('func _setup_platforms():')]

new_setup = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    broken_ladders.clear()
    fire_guys.clear()
    
    var s = current_slope_angle
    var trim = map_w * current_platform_trim
    
    var rng = RandomNumberGenerator.new()
    if current_level_seed < 0:
        rng.randomize()
    else:
        rng.seed = current_level_seed
    
    # Tier 0 (Bottom - Slopes down to right) - Stays full width so barrels don't fall off too early
    var t0_left = map_h * 0.93 - map_h * 0.02 * s
    var t0_right = map_h * 0.96
    _add_platform(Rect2(map_w * 0.1, min(t0_left, t0_right), map_w * 0.8, 5), t0_left, t0_right)
    
    # Tier 1 (Slopes down to left) - Cut short on the left
    var t1_left = map_h * 0.80 + map_h * 0.02 * s
    var t1_right = map_h * 0.76
    _add_platform(Rect2(map_w * 0.1 + trim, min(t1_left, t1_right), map_w * 0.8 - trim, 5), t1_left, t1_right)
    
    # Tier 2 (Slopes down to right) - Cut short on the right
    var t2_left = map_h * 0.57 - map_h * 0.02 * s
    var t2_right = map_h * 0.61
    _add_platform(Rect2(map_w * 0.1, min(t2_left, t2_right), map_w * 0.8 - trim, 5), t2_left, t2_right)
    
    # Tier 3 (Slopes down to left) - Cut short on the left
    var t3_left = map_h * 0.49 + map_h * 0.02 * s
    var t3_right = map_h * 0.45
    _add_platform(Rect2(map_w * 0.1 + trim, min(t3_left, t3_right), map_w * 0.8 - trim, 5), t3_left, t3_right)
    
    # Tier 4 (Slopes down to right) - Cut short on the right
    var t4_left = map_h * 0.26 - map_h * 0.02 * s
    var t4_right = map_h * 0.30
    _add_platform(Rect2(map_w * 0.1, min(t4_left, t4_right), map_w * 0.8 - trim, 5), t4_left, t4_right)
    
    # Tier 5 (Top - Pauline and DK - Flat)
    _add_platform(Rect2(map_w * 0.35, map_h * 0.14, map_w * 0.35, 5), map_h * 0.14, map_h * 0.14)
    
    # Donkey Kong platform (Top Left - Flat)
    _add_platform(Rect2(map_w * 0.2, map_h * 0.20, map_w * 0.15, 5), map_h * 0.20, map_h * 0.20)
    
    # Now dynamically compute the ladders using RNG
    _add_dynamic_ladder(map_w * rng.randf_range(0.75, 0.85), map_h * 0.76) # Ladder 0->1 (Right)
    
    _add_dynamic_ladder(map_w * rng.randf_range(0.15, 0.25), map_h * 0.61) # Ladder 1->2 (Left)
    if rng.randf() < 0.6:
        _add_dynamic_broken_ladder(map_w * rng.randf_range(0.40, 0.70), map_h * 0.61) # Broken Ladder 1->2
    
    _add_dynamic_ladder(map_w * rng.randf_range(0.75, 0.85), map_h * 0.45) # Ladder 2->3 (Right)
    if rng.randf() < 0.6:
        _add_dynamic_broken_ladder(map_w * rng.randf_range(0.40, 0.70), map_h * 0.45) # Broken Ladder 2->3
    
    _add_dynamic_ladder(map_w * rng.randf_range(0.15, 0.25), map_h * 0.30) # Ladder 3->4 (Left)
    if rng.randf() < 0.6:
        _add_dynamic_broken_ladder(map_w * rng.randf_range(0.40, 0.70), map_h * 0.30) # Broken Ladder 3->4
    
    _add_dynamic_ladder(map_w * rng.randf_range(0.50, 0.65), map_h * 0.14)  # Ladder 4->5 (Middle Right)
    
    # Extra ladders for classic feel
    ladders.append(Rect2(map_w * 0.3, map_h * 0.20, 6, map_h * 0.08)) # Ladder from DK down to Tier 4
    if rng.randf() < 0.5:
        _add_dynamic_ladder(map_w * rng.randf_range(0.40, 0.60), map_h * 0.76) # Middle ladder Tier 0->1
    if rng.randf() < 0.5:
        _add_dynamic_ladder(map_w * rng.randf_range(0.40, 0.60), map_h * 0.45) # Middle ladder Tier 2->3
    
    # Items (Goal)
    items.clear()
    items.append({"pos": Vector2(map_w * 0.45, map_h * 0.09), "kind": "goal"})
    
    # Spawn fire guys based on knob
    var fcount = current_fire_enemy_count
    var ftiers = [0, 1, 2, 3]
    for i in range(min(fcount, 4)):
        fire_guys.append({"tier": ftiers[i], "pos": Vector2(map_w * 0.5, map_h * 0.5), "vel": Vector2(100, 0)})

'''

code = code.replace(old_setup, new_setup)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
