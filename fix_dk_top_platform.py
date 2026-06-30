import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

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
    
    # Generate Sloped Tiers
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
        
        # Ladders connecting UP to the next tier
        if i < num_tiers - 1:
            var lx = 0.0
            if is_even:
                # Slopes down to right. Left is High. Player walks UP slope to Left. Ladder UP is on Left.
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
                
    # Top elements: DK Platform and Goal
    var top_i = num_tiers - 1
    var top_y = logical_h * 0.94 - top_i * tier_spacing
    var top_is_even = (top_i % 2 == 0)
    var goal_y = top_y - tier_spacing
    
    if top_is_even:
        # Top sloped tier slopes down to right. Player arrives on Left.
        # DK Platform on far left
        _add_platform(Rect2(logical_w * 0.1, goal_y, logical_w * 0.15, 5), goal_y, goal_y)
        barrel_spawner = {"pos": Vector2(logical_w * 0.18, goal_y - 20), "vel_x": 120} # Rolls right
        # Goal Platform in middle-left
        _add_platform(Rect2(logical_w * 0.35, goal_y, logical_w * 0.25, 5), goal_y, goal_y)
        items.append({"pos": Vector2(logical_w * 0.45, goal_y - 20), "kind": "goal"})
        _add_dynamic_ladder(logical_w * 0.45, goal_y - 5)
    else:
        # Top sloped tier slopes down to left. Player arrives on Right.
        # DK Platform on far right
        _add_platform(Rect2(logical_w * 0.75, goal_y, logical_w * 0.15, 5), goal_y, goal_y)
        barrel_spawner = {"pos": Vector2(logical_w * 0.82, goal_y - 20), "vel_x": -120} # Rolls left
        # Goal Platform in middle-right
        _add_platform(Rect2(logical_w * 0.40, goal_y, logical_w * 0.25, 5), goal_y, goal_y)
        items.append({"pos": Vector2(logical_w * 0.55, goal_y - 20), "kind": "goal"})
        _add_dynamic_ladder(logical_w * 0.55, goal_y - 5)
    
    # Fire guys (spawn on random tiers > 0)
    var fcount = current_fire_enemy_count
    for i in range(fcount):
        var ftier = rng.randi_range(1, max(1, num_tiers - 1))
        var fy = logical_h * 0.94 - ftier * tier_spacing
        fire_guys.append({"tier": ftier, "pos": Vector2(logical_w * 0.5, fy), "vel": Vector2(100, 0)})
        
    player_spawn = Vector2(logical_w * 0.85, logical_h * 0.92)

'''

code = code.replace(old_setup, new_setup)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
