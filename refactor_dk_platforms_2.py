import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Update platforms.append in all setup functions
# We need to replace: platforms.append(Rect2(min_x, py, max_x - min_x, 5))
code = code.replace(
    'platforms.append(Rect2(min_x, py, max_x - min_x, 5))',
    '_add_platform(Rect2(min_x, py, max_x - min_x, 5), py, py)'
)
code = code.replace(
    'platforms.append(Rect2(x, y, map_w * 0.72, 5))',
    '_add_platform(Rect2(x, y, map_w * 0.72, 5), y, y)'
)
code = code.replace(
    'platforms.append(Rect2(map_w * 0.16, y, map_w * 0.68, 5))',
    '_add_platform(Rect2(map_w * 0.16, y, map_w * 0.68, 5), y, y)'
)

# 2. Update Tapper drawing and setup references
code = code.replace(
    'player["pos"] = Vector2(map_w * 0.2, platforms[0].position.y)',
    'player["pos"] = Vector2(map_w * 0.2, platforms[0]["rect"].position.y)'
)
code = code.replace(
    'player["pos"] = Vector2(map_w * 0.2, platforms[lane].position.y)',
    'player["pos"] = Vector2(map_w * 0.2, platforms[lane]["rect"].position.y)'
)
code = code.replace(
    '_draw_customer(Vector2(c["x"], platforms[c["lane"]].position.y - 18), C_MAGENTA)',
    '_draw_customer(Vector2(c["x"], platforms[c["lane"]]["rect"].position.y - 18), C_MAGENTA)'
)
code = code.replace(
    '_draw_mug(Vector2(d["x"], platforms[d["lane"]].position.y - 8), C_YELLOW)',
    '_draw_mug(Vector2(d["x"], platforms[d["lane"]]["rect"].position.y - 8), C_YELLOW)'
)
code = code.replace(
    '_draw_mug(Vector2(m["x"], platforms[m["lane"]].position.y - 10), C_GREEN)',
    '_draw_mug(Vector2(m["x"], platforms[m["lane"]]["rect"].position.y - 10), C_GREEN)'
)

# 3. Replace Classic Donkey Kong Level
old_classic = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    
    # Tier 0 (Bottom)
    platforms.append(Rect2(map_w * 0.1, map_h * 0.90, map_w * 0.8, 5))
    # Ladder 0->1 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.76, 6, map_h * 0.14))
    
    # Tier 1
    platforms.append(Rect2(map_w * 0.1, map_h * 0.76, map_w * 0.8, 5))
    # Ladder 1->2 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.62, 6, map_h * 0.14))
    
    # Tier 2
    platforms.append(Rect2(map_w * 0.1, map_h * 0.62, map_w * 0.8, 5))
    # Ladder 2->3 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.48, 6, map_h * 0.14))
    
    # Tier 3
    platforms.append(Rect2(map_w * 0.1, map_h * 0.48, map_w * 0.8, 5))
    # Ladder 3->4 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.34, 6, map_h * 0.14))
    
    # Tier 4
    platforms.append(Rect2(map_w * 0.1, map_h * 0.34, map_w * 0.8, 5))
    # Ladder 4->5 (Middle Right)
    ladders.append(Rect2(map_w * 0.6, map_h * 0.20, 6, map_h * 0.14))
    
    # Tier 5 (Top - Pauline and DK)
    platforms.append(Rect2(map_w * 0.35, map_h * 0.20, map_w * 0.35, 5))
    
    # Donkey Kong platform (Top Left)
    platforms.append(Rect2(map_w * 0.2, map_h * 0.25, map_w * 0.15, 5))
    
    # Extra ladders for classic feel
    ladders.append(Rect2(map_w * 0.3, map_h * 0.25, 6, map_h * 0.09)) # Ladder from DK down to Tier 4
    ladders.append(Rect2(map_w * 0.45, map_h * 0.76, 6, map_h * 0.14)) # Middle ladder Tier 0->1
    ladders.append(Rect2(map_w * 0.55, map_h * 0.48, 6, map_h * 0.14)) # Middle ladder Tier 2->3
    
    # Items (Goal)
    items.clear()
    items.append({"pos": Vector2(map_w * 0.45, map_h * 0.15), "kind": "goal"})
    
    # Start pos
    player["pos"] = Vector2(map_w * 0.15, map_h * 0.88)'''

new_classic = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    fire_guys.clear()
    
    var s = current_slope_angle
    
    # Tier 0 (Bottom - Flat)
    _add_platform(Rect2(map_w * 0.1, map_h * 0.94, map_w * 0.8, 5), map_h * 0.94, map_h * 0.94)
    # Ladder 0->1 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.78, 6, map_h * 0.16))
    
    # Tier 1 (Sloped up to right)
    _add_platform(Rect2(map_w * 0.1, map_h * 0.76, map_w * 0.8, 5), map_h * 0.76, map_h * 0.80)
    # Ladder 1->2 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.62, 6, map_h * 0.15))
    
    # Tier 2 (Sloped down to right)
    _add_platform(Rect2(map_w * 0.1, map_h * 0.61, map_w * 0.8, 5), map_h * 0.61, map_h * 0.57)
    # Ladder 2->3 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.44, 6, map_h * 0.14))
    
    # Tier 3 (Sloped up to right)
    _add_platform(Rect2(map_w * 0.1, map_h * 0.45, map_w * 0.8, 5), map_h * 0.45, map_h * 0.49)
    # Ladder 3->4 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.31, 6, map_h * 0.15))
    
    # Tier 4 (Sloped down to right)
    _add_platform(Rect2(map_w * 0.1, map_h * 0.30, map_w * 0.8, 5), map_h * 0.30, map_h * 0.26)
    # Ladder 4->5 (Middle Right)
    ladders.append(Rect2(map_w * 0.6, map_h * 0.14, 6, map_h * 0.13))
    
    # Tier 5 (Top - Pauline and DK - Flat)
    _add_platform(Rect2(map_w * 0.35, map_h * 0.14, map_w * 0.35, 5), map_h * 0.14, map_h * 0.14)
    
    # Donkey Kong platform (Top Left - Flat)
    _add_platform(Rect2(map_w * 0.2, map_h * 0.20, map_w * 0.15, 5), map_h * 0.20, map_h * 0.20)
    
    # Extra ladders for classic feel
    ladders.append(Rect2(map_w * 0.3, map_h * 0.20, 6, map_h * 0.08)) # Ladder from DK down to Tier 4
    ladders.append(Rect2(map_w * 0.45, map_h * 0.78, 6, map_h * 0.16)) # Middle ladder Tier 0->1
    ladders.append(Rect2(map_w * 0.55, map_h * 0.47, 6, map_h * 0.12)) # Middle ladder Tier 2->3
    
    # Items (Goal)
    items.clear()
    items.append({"pos": Vector2(map_w * 0.45, map_h * 0.09), "kind": "goal"})
    
    # Spawn fire guys based on knob
    var fcount = current_fire_enemy_count
    var ftiers = [0, 1, 2, 3]
    for i in range(min(fcount, 4)):
        fire_guys.append({"tier": ftiers[i], "pos": Vector2(map_w * 0.5, map_h * 0.5), "vel": Vector2(100, 0)})
    
    # Start pos
    player["pos"] = Vector2(map_w * 0.15, map_h * 0.92)'''

code = code.replace(old_classic, new_classic)

# Fix player physics jump height
code = code.replace(
    'if can_jump and _action() and player["on_ground"]:\n            vel.y = -310',
    'if can_jump and _action() and player["on_ground"]:\n            vel.y = -310 * current_jump_height'
)

# Fix landing physics using _platform_y!
old_land = '''    for p in platforms:
        if player["pos"].y < p.position.y and player["pos"].y + 18 > p.position.y and player["pos"].x > p.position.x and player["pos"].x < p.position.x + p.size.x and vel.y > 0:
            player["pos"].y = p.position.y - 18
            vel.y = 0'''

new_land = '''    for p in platforms:
        var r = p["rect"]
        if player["pos"].x > r.position.x and player["pos"].x < r.position.x + r.size.x and vel.y > 0:
            var t = clamp((player["pos"].x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if player["pos"].y < py and player["pos"].y + 18 > py:
                player["pos"].y = py - 18
                vel.y = 0'''
code = code.replace(old_land, new_land)

old_land_enemy = '''    for p in platforms:
        if pos.y < p.position.y and pos.y + 20 >= p.position.y and pos.x >= p.position.x and pos.x <= p.position.x + p.size.x and vel.y >= 0:
            pos.y = p.position.y - 20
            vel.y = 0
            player["on_ground"] = true'''

new_land_enemy = '''    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x and vel.y >= 0:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if pos.y < py and pos.y + 20 >= py:
                pos.y = py - 20
                vel.y = 0
                player["on_ground"] = true'''
code = code.replace(old_land_enemy, new_land_enemy)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
