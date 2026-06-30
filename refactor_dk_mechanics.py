import re
with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. reset_game
old_reset = '''    hazards.clear()
    barrels.clear()
    bubbles.clear()
    rocks.clear()
    generators.clear()'''
new_reset = '''    hazards.clear()
    barrels.clear()
    bubbles.clear()
    rocks.clear()
    generators.clear()
    broken_ladders.clear()'''
code = code.replace(old_reset, new_reset)

# 2. Add broken_ladders array definition
old_arrays = '''var current_add_platforms = true
var platforms = []
var ladders = []
var fire_guys = []'''
new_arrays = '''var current_add_platforms = true
var platforms = []
var ladders = []
var broken_ladders = []
var fire_guys = []'''
if old_arrays in code:
    code = code.replace(old_arrays, new_arrays)
else:
    # Let's insert it if old_arrays isn't exact
    if 'var broken_ladders = []' not in code:
        code = code.replace('var ladders = []\nvar fire_guys = []', 'var ladders = []\nvar broken_ladders = []\nvar fire_guys = []')

# 3. Modify _setup_classic_donkey_kong
old_setup_dk = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    fire_guys.clear()
    
    var s = current_slope_angle
    
    # Tier 0 (Bottom - Flat)
    _add_platform(Rect2(map_w * 0.1, map_h * 0.94, map_w * 0.8, 5), map_h * 0.94, map_h * 0.94)
    # Ladder 0->1 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.78, 6, map_h * 0.16))'''
new_setup_dk = '''func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    broken_ladders.clear()
    fire_guys.clear()
    
    var s = current_slope_angle
    
    # Tier 0 (Bottom - Sloped down to left)
    var t0_left = map_h * 0.96 - map_h * 0.03 * s
    var t0_right = map_h * 0.96
    _add_platform(Rect2(map_w * 0.1, min(t0_left, t0_right), map_w * 0.8, 5), t0_left, t0_right)
    # Ladder 0->1 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.78, 6, map_h * 0.16))'''
code = code.replace(old_setup_dk, new_setup_dk)

old_tier3 = '''    var t3_right = map_h * 0.46
    _add_platform(Rect2(map_w * 0.1, min(t3_left, t3_right), map_w * 0.8, 5), t3_left, t3_right)
    # Ladder 3->4 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.28, 6, map_h * 0.16))'''
new_tier3 = '''    var t3_right = map_h * 0.46
    _add_platform(Rect2(map_w * 0.1, min(t3_left, t3_right), map_w * 0.8, 5), t3_left, t3_right)
    # Broken Ladder 2->3 (Middle-ish)
    broken_ladders.append(Rect2(map_w * 0.44, map_h * 0.48, 6, map_h * 0.10))
    # Ladder 3->4 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.28, 6, map_h * 0.16))'''
code = code.replace(old_tier3, new_tier3)

old_tier1 = '''    var t1_right = map_h * 0.80 + map_h * 0.03 * s
    _add_platform(Rect2(map_w * 0.1, min(t1_left, t1_right), map_w * 0.8, 5), t1_left, t1_right)
    # Ladder 1->2 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.62, 6, map_h * 0.15))'''
new_tier1 = '''    var t1_right = map_h * 0.80 + map_h * 0.03 * s
    _add_platform(Rect2(map_w * 0.1, min(t1_left, t1_right), map_w * 0.8, 5), t1_left, t1_right)
    # Ladder 1->2 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.62, 6, map_h * 0.15))
    # Broken Ladder 1->2 (Middle-ish)
    broken_ladders.append(Rect2(map_w * 0.54, map_h * 0.64, 6, map_h * 0.14))'''
code = code.replace(old_tier1, new_tier1)

# 4. Modify _barrel_ladder_x to check both
old_blx = '''func _barrel_ladder_x(pos: Vector2) -> float:
    for l in ladders:
        if abs(pos.x - l.position.x) < 28 and pos.y >= l.position.y - 18 and pos.y <= l.position.y + l.size.y - 30:
            return l.position.x
    return -1.0'''
new_blx = '''func _barrel_ladder_x(pos: Vector2) -> float:
    for l in ladders:
        if abs(pos.x - l.position.x) < 28 and pos.y >= l.position.y - 18 and pos.y <= l.position.y + l.size.y - 30:
            return l.position.x
    for bl in broken_ladders:
        if abs(pos.x - bl.position.x) < 28 and pos.y >= bl.position.y - 18 and pos.y <= bl.position.y + bl.size.y - 30:
            return bl.position.x
    return -1.0'''
code = code.replace(old_blx, new_blx)


# 5. Modify _platform_move to allow climb down
old_pm = '''    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x and vel.y >= 0:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if pos.y < py and pos.y + 20 >= py:
                pos.y = py - 20
                vel.y = 0
                player["on_ground"] = true'''
new_pm = '''    var moving_down_ladder = on_ladder and v.y > 0.1
    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x and vel.y >= 0:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if pos.y < py and pos.y + 20 >= py and not moving_down_ladder:
                pos.y = py - 20
                vel.y = 0
                player["on_ground"] = true'''
code = code.replace(old_pm, new_pm)


# 6. Update _tick_barrel for simulated physics
old_tick = '''func _tick_barrel(delta):
    _platform_move(delta, true)
    player["cool"] = max(0.0, player["cool"] - delta)
    if barrels.size() < 9 and randf() < delta * (0.9 + wave * 0.1):
        barrels.append({"pos": Vector2(map_w * 0.78, map_h * 0.2), "vel": Vector2(-120, 0), "jumped": false, "ladder": false})
    for i in range(barrels.size() - 1, -1, -1):
        var b = barrels[i]
        if not b.get("ladder", false) and _barrel_ladder_x(b["pos"]) >= 0.0 and randf() < delta * 0.85:
            b["ladder"] = true
            b["pos"].x = _barrel_ladder_x(b["pos"])
            b["vel"] = Vector2(0, 150 + wave * 8)
        b["pos"] += b["vel"] * delta
        var py = _platform_y(b["pos"])
        if b.get("ladder", false):
            b["vel"].x = 0
            var below = _platform_below(b["pos"])
            if below > 0.0 and b["pos"].y >= below - 14:
                b["pos"].y = below - 13
                var dir = _barrel_slope_dir(b["pos"])
                if dir == 0.0: dir = [-1, 1][randi() % 2]
                b["vel"] = Vector2(dir * (120 + wave * 5), 0)
                b["ladder"] = false
        elif py > 0:
            b["pos"].y = py - 13
            var dir = _barrel_slope_dir(b["pos"])
            if dir != 0.0:
                b["vel"].x = dir * abs(b["vel"].x)
        if b["pos"].x < 20 or b["pos"].x > map_w - 20 or b["pos"].y > map_h:
            barrels.remove_at(i)
            continue
        var d = b["pos"].distance_to(player["pos"])'''
new_tick = '''func _tick_barrel(delta):
    _platform_move(delta, true)
    player["cool"] = max(0.0, player["cool"] - delta)
    if barrels.size() < 9 and randf() < delta * (0.9 + wave * 0.1):
        barrels.append({"pos": Vector2(map_w * 0.78, map_h * 0.2), "vel": Vector2(-120, 0), "jumped": false, "ladder": false, "cooldown": 0.0})
    for i in range(barrels.size() - 1, -1, -1):
        var b = barrels[i]
        b["cooldown"] = max(0.0, b.get("cooldown", 0.0) - delta)
        
        # Roll down ladders randomly (50% chance when passing over)
        if not b.get("ladder", false) and b["cooldown"] <= 0.0:
            var lx = _barrel_ladder_x(b["pos"])
            if lx >= 0.0 and abs(b["pos"].x - lx) < 8.0:
                b["cooldown"] = 1.0 # Prevent re-triggering on same ladder
                if randf() < 0.5:
                    b["ladder"] = true
                    b["pos"].x = lx
                    b["vel"] = Vector2(0, 150 + wave * 8)
        
        # Gravity
        if not b.get("ladder", false):
            b["vel"].y += 500 * delta
        
        b["pos"] += b["vel"] * delta
        var py = _platform_y(b["pos"])
        
        if b.get("ladder", false):
            b["vel"].x = 0
            var below = _platform_below(b["pos"])
            if below > 0.0 and b["pos"].y >= below - 14:
                b["pos"].y = below - 13
                var dir = _barrel_slope_dir(b["pos"])
                if dir == 0.0: dir = [-1, 1][randi() % 2]
                b["vel"] = Vector2(dir * (120 + wave * 5), 0)
                b["ladder"] = false
        else:
            if py > 0 and b["vel"].y >= 0 and b["pos"].y > py - 16 and b["pos"].y < py + 16:
                b["pos"].y = py - 13
                b["vel"].y = 0
                var dir = _barrel_slope_dir(b["pos"])
                if dir != 0.0:
                    b["vel"].x = dir * max(100.0, abs(b["vel"].x))
        if b["pos"].x < 20 or b["pos"].x > map_w - 20 or b["pos"].y > map_h:
            barrels.remove_at(i)
            continue
        var d = b["pos"].distance_to(player["pos"])'''
code = code.replace(old_tick, new_tick)


# 7. Update drawing to draw broken ladders
old_draw = '''func _draw_platform_game(things, color: Color):
    for p in platforms:
        _draw_sloped_girder(p, C_CYAN)
    for fg in fire_guys:
        _draw_fire_guy(fg["pos"], C_RED)
    for l in ladders:
        _draw_ladder(l, C_GREEN)'''
new_draw = '''func _draw_platform_game(things, color: Color):
    for p in platforms:
        _draw_sloped_girder(p, C_CYAN)
    for fg in fire_guys:
        _draw_fire_guy(fg["pos"], C_RED)
    for l in ladders:
        _draw_ladder(l, C_GREEN)
    for bl in broken_ladders:
        _draw_broken_ladder(bl, C_GREEN)'''
code = code.replace(old_draw, new_draw)

# Add _draw_broken_ladder
old_dl = '''func _draw_ladder(rect: Rect2, color: Color):
    var x1 = rect.position.x - 6
    var x2 = rect.position.x + 6
    _glow_line(Vector2(x1, rect.position.y), Vector2(x1, rect.position.y + rect.size.y), color, 1.1)
    _glow_line(Vector2(x2, rect.position.y), Vector2(x2, rect.position.y + rect.size.y), color, 1.1)
    for y in range(int(rect.position.y), int(rect.position.y + rect.size.y), 20):
        _glow_line(Vector2(x1, y), Vector2(x2, y), color, 0.8)'''
new_dl = '''func _draw_ladder(rect: Rect2, color: Color):
    var x1 = rect.position.x - 6
    var x2 = rect.position.x + 6
    _glow_line(Vector2(x1, rect.position.y), Vector2(x1, rect.position.y + rect.size.y), color, 1.1)
    _glow_line(Vector2(x2, rect.position.y), Vector2(x2, rect.position.y + rect.size.y), color, 1.1)
    for y in range(int(rect.position.y), int(rect.position.y + rect.size.y), 20):
        _glow_line(Vector2(x1, y), Vector2(x2, y), color, 0.8)

func _draw_broken_ladder(rect: Rect2, color: Color):
    var x1 = rect.position.x - 6
    var x2 = rect.position.x + 6
    var top_h = rect.size.y * 0.3
    var bot_h = rect.size.y * 0.4
    var bot_y = rect.position.y + rect.size.y - bot_h
    
    _glow_line(Vector2(x1, rect.position.y), Vector2(x1, rect.position.y + top_h), color, 1.1)
    _glow_line(Vector2(x2, rect.position.y), Vector2(x2, rect.position.y + top_h), color, 1.1)
    for y in range(int(rect.position.y), int(rect.position.y + top_h), 20):
        _glow_line(Vector2(x1, y), Vector2(x2, y), color, 0.8)
        
    _glow_line(Vector2(x1, bot_y), Vector2(x1, bot_y + bot_h), color, 1.1)
    _glow_line(Vector2(x2, bot_y), Vector2(x2, bot_y + bot_h), color, 1.1)
    for y in range(int(bot_y), int(bot_y + bot_h), 20):
        _glow_line(Vector2(x1, y), Vector2(x2, y), color, 0.8)'''
code = code.replace(old_dl, new_dl)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
