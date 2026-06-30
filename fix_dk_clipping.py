import re
with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Update player spawn in _setup_barrel
# Wait, player spawn in _setup_barrel or _setup_classic_donkey_kong?
# reset_game() sets player["pos"] initially. Then _setup_barrel() overrides it.
# I previously overrode it to Vector2(map_w * 0.22, map_h * 0.18).
old_spawn = '''barrels.append({"pos": Vector2(map_w * 0.22, map_h * 0.18), "vel": Vector2(120, 0), "jumped": false, "ladder": false, "cooldown": 0.0})'''
new_spawn = '''barrels.append({"pos": Vector2(map_w * 0.22, map_h * 0.18), "vel": Vector2(120, 0), "jumped": false, "ladder": false, "cooldown": 0.0})'''
# Oh wait, player spawn is in _setup_barrel:
old_player_spawn = '''    _setup_platforms()
    player["pos"] = Vector2(map_w * 0.16, map_h * 0.92)'''
new_player_spawn = '''    _setup_platforms()
    player["pos"] = Vector2(map_w * 0.85, map_h * 0.92)'''
code = code.replace(old_player_spawn, new_player_spawn)


# 2. Add dynamic ladder helpers
new_helpers = '''
func _add_dynamic_ladder(x: float):
    var y_top = _platform_y(Vector2(x, map_h * 0.0))
    var y_bot = map_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            # Find the platform directly below y_top
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < map_h * 1.5:
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))

func _add_dynamic_broken_ladder(x: float):
    var y_top = _platform_y(Vector2(x, map_h * 0.0))
    var y_bot = map_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < map_h * 1.5:
        broken_ladders.append(Rect2(x, y_top, 6, y_bot - y_top))

'''

# I will insert the helpers right before _setup_classic_donkey_kong
code = code.replace('func _setup_classic_donkey_kong():', new_helpers + 'func _setup_classic_donkey_kong():')

# Wait, _platform_y uses best_d and finds the CLOSEST platform to pos.y!
# So _platform_y(Vector2(x, 0.0)) will find the HIGHEST platform!
# But we need to find the platform for a specific tier.
# So passing `x` is not enough, we need to pass a `y_approx` so _platform_y finds the right platform!
'''
func _add_dynamic_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = map_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < map_h * 1.5:
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))
'''

# Let's completely replace _setup_classic_donkey_kong
old_setup = code[code.find('func _setup_classic_donkey_kong():'):code.find('func _setup_platforms():')]

new_setup = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    broken_ladders.clear()
    fire_guys.clear()
    
    var s = current_slope_angle
    
    # Tier 0 (Bottom - Slopes down to right) - Stays full width so barrels don't fall off too early
    var t0_left = map_h * 0.93 - map_h * 0.02 * s
    var t0_right = map_h * 0.96
    _add_platform(Rect2(map_w * 0.1, min(t0_left, t0_right), map_w * 0.8, 5), t0_left, t0_right)
    
    # Tier 1 (Slopes down to left) - Cut short on the left
    var t1_left = map_h * 0.80 + map_h * 0.02 * s
    var t1_right = map_h * 0.76
    _add_platform(Rect2(map_w * 0.15, min(t1_left, t1_right), map_w * 0.75, 5), t1_left, t1_right)
    
    # Tier 2 (Slopes down to right) - Cut short on the right
    var t2_left = map_h * 0.57 - map_h * 0.02 * s
    var t2_right = map_h * 0.61
    _add_platform(Rect2(map_w * 0.1, min(t2_left, t2_right), map_w * 0.75, 5), t2_left, t2_right)
    
    # Tier 3 (Slopes down to left) - Cut short on the left
    var t3_left = map_h * 0.49 + map_h * 0.02 * s
    var t3_right = map_h * 0.45
    _add_platform(Rect2(map_w * 0.15, min(t3_left, t3_right), map_w * 0.75, 5), t3_left, t3_right)
    
    # Tier 4 (Slopes down to right) - Cut short on the right
    var t4_left = map_h * 0.26 - map_h * 0.02 * s
    var t4_right = map_h * 0.30
    _add_platform(Rect2(map_w * 0.1, min(t4_left, t4_right), map_w * 0.75, 5), t4_left, t4_right)
    
    # Tier 5 (Top - Pauline and DK - Flat)
    _add_platform(Rect2(map_w * 0.35, map_h * 0.14, map_w * 0.35, 5), map_h * 0.14, map_h * 0.14)
    
    # Donkey Kong platform (Top Left - Flat)
    _add_platform(Rect2(map_w * 0.2, map_h * 0.20, map_w * 0.15, 5), map_h * 0.20, map_h * 0.20)
    
    # Now dynamically compute the ladders
    _add_dynamic_ladder(map_w * 0.82, map_h * 0.76) # Ladder 0->1 (Right)
    _add_dynamic_ladder(map_w * 0.18, map_h * 0.61) # Ladder 1->2 (Left)
    _add_dynamic_broken_ladder(map_w * 0.65, map_h * 0.61) # Broken Ladder 1->2 (Middle Right)
    _add_dynamic_ladder(map_w * 0.82, map_h * 0.45) # Ladder 2->3 (Right)
    _add_dynamic_ladder(map_w * 0.18, map_h * 0.30) # Ladder 3->4 (Left)
    _add_dynamic_broken_ladder(map_w * 0.35, map_h * 0.30) # Broken Ladder 3->4 (Middle Left)
    _add_dynamic_ladder(map_w * 0.6, map_h * 0.14)  # Ladder 4->5 (Middle Right)
    
    # Extra ladders for classic feel
    ladders.append(Rect2(map_w * 0.3, map_h * 0.20, 6, map_h * 0.08)) # Ladder from DK down to Tier 4
    _add_dynamic_ladder(map_w * 0.45, map_h * 0.76) # Middle ladder Tier 0->1
    _add_dynamic_ladder(map_w * 0.55, map_h * 0.45) # Middle ladder Tier 2->3
    
    # Items (Goal)
    items.clear()
    items.append({"pos": Vector2(map_w * 0.45, map_h * 0.09), "kind": "goal"})
    
    # Spawn fire guys based on knob
    var fcount = current_fire_enemy_count
    var ftiers = [0, 1, 2, 3]
    for i in range(min(fcount, 4)):
        fire_guys.append({"tier": ftiers[i], "pos": Vector2(map_w * 0.5, map_h * 0.5), "vel": Vector2(100, 0)})

'''

# Wait, _add_dynamic_ladder logic needs to be rewritten properly.
better_helpers = '''
func _add_dynamic_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = map_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < map_h * 1.5:
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))

func _add_dynamic_broken_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = map_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < map_h * 1.5:
        broken_ladders.append(Rect2(x, y_top, 6, y_bot - y_top))

'''

code = code.replace(old_setup, better_helpers + new_setup)


# 4. Fix barrel clipping in _tick_barrel
old_barrel_tick = '''        if b.get("ladder", false):
            b["vel"].x = 0
            var below = _platform_below(b["pos"])
            if below > 0.0 and b["pos"].y >= below - 14:
                b["pos"].y = below - 13
                var dir = _barrel_slope_dir(b["pos"])
                if dir == 0.0: dir = [-1, 1][randi() % 2]
                b["vel"] = Vector2(dir * (120 + wave * 5), 0)
                b["ladder"] = false'''
new_barrel_tick = '''        if b.get("ladder", false):
            b["vel"].x = 0
            if py > 0 and b["pos"].y >= py - 16:
                b["pos"].y = py - 13
                var dir = _barrel_slope_dir(b["pos"])
                if dir == 0.0: dir = [-1, 1][randi() % 2]
                b["vel"] = Vector2(dir * (120 + wave * 5), 0)
                b["ladder"] = false'''
code = code.replace(old_barrel_tick, new_barrel_tick)


with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
