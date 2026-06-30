import re
with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# Fix 1: Remove state = "start" from _ready
old_ready = '''    reset_game()
    state = "start"
    if splash_rect:'''
new_ready = '''    reset_game()
    if splash_rect:'''
code = code.replace(old_ready, new_ready)

# Fix 2: Change barrel spawn location
old_spawn = '''barrels.append({"pos": Vector2(map_w * 0.78, map_h * 0.2), "vel": Vector2(-120, 0),'''
new_spawn = '''barrels.append({"pos": Vector2(map_w * 0.22, map_h * 0.18), "vel": Vector2(120, 0),'''
code = code.replace(old_spawn, new_spawn)

# Fix 3: Rewrite _setup_classic_donkey_kong tiers and broken ladders
old_setup = code[code.find('func _setup_classic_donkey_kong():'):code.find('# Extra ladders for classic feel')]

new_setup = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    broken_ladders.clear()
    fire_guys.clear()
    
    var s = current_slope_angle
    
    # Tier 0 (Bottom - Slopes down to right)
    var t0_left = map_h * 0.93 - map_h * 0.02 * s
    var t0_right = map_h * 0.96
    _add_platform(Rect2(map_w * 0.1, min(t0_left, t0_right), map_w * 0.8, 5), t0_left, t0_right)
    # Ladder 0->1 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.78, 6, map_h * 0.16))
    
    # Tier 1 (Slopes down to left)
    var t1_left = map_h * 0.80 + map_h * 0.02 * s
    var t1_right = map_h * 0.76
    _add_platform(Rect2(map_w * 0.1, min(t1_left, t1_right), map_w * 0.8, 5), t1_left, t1_right)
    # Ladder 1->2 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.62, 6, map_h * 0.15))
    # Broken Ladder 1->2 (Middle Right)
    broken_ladders.append(Rect2(map_w * 0.65, map_h * 0.65, 6, map_h * 0.11))
    
    # Tier 2 (Slopes down to right)
    var t2_left = map_h * 0.57 - map_h * 0.02 * s
    var t2_right = map_h * 0.61
    _add_platform(Rect2(map_w * 0.1, min(t2_left, t2_right), map_w * 0.8, 5), t2_left, t2_right)
    # Ladder 2->3 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.44, 6, map_h * 0.14))
    
    # Tier 3 (Slopes down to left)
    var t3_left = map_h * 0.49 + map_h * 0.02 * s
    var t3_right = map_h * 0.45
    _add_platform(Rect2(map_w * 0.1, min(t3_left, t3_right), map_w * 0.8, 5), t3_left, t3_right)
    # Ladder 3->4 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.31, 6, map_h * 0.15))
    # Broken Ladder 3->4 (Middle Left)
    broken_ladders.append(Rect2(map_w * 0.35, map_h * 0.33, 6, map_h * 0.12))
    
    # Tier 4 (Slopes down to right)
    var t4_left = map_h * 0.26 - map_h * 0.02 * s
    var t4_right = map_h * 0.30
    _add_platform(Rect2(map_w * 0.1, min(t4_left, t4_right), map_w * 0.8, 5), t4_left, t4_right)
    # Ladder 4->5 (Middle Right)
    ladders.append(Rect2(map_w * 0.6, map_h * 0.14, 6, map_h * 0.13))
    
    # Tier 5 (Top - Pauline and DK - Flat)
    _add_platform(Rect2(map_w * 0.35, map_h * 0.14, map_w * 0.35, 5), map_h * 0.14, map_h * 0.14)
    
    # Donkey Kong platform (Top Left - Flat)
    _add_platform(Rect2(map_w * 0.2, map_h * 0.20, map_w * 0.15, 5), map_h * 0.20, map_h * 0.20)
    
    '''

code = code.replace(old_setup, new_setup)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
