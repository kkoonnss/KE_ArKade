import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Update _add_dynamic_ladder to restrict y_bot to only platforms that span x
old_ladder = '''func _add_dynamic_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = logical_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < logical_h * 1.5:
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))

func _add_dynamic_broken_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = logical_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < logical_h * 1.5:
        broken_ladders.append(Rect2(x, y_top, 6, (y_bot - y_top) * 0.45))'''

new_ladder = '''func _add_dynamic_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = logical_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < logical_h * 1.05:
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))

func _add_dynamic_broken_ladder(x: float, y_approx: float):
    var y_top = _platform_y(Vector2(x, y_approx))
    var y_bot = logical_h * 1.5
    for p in platforms:
        var r = p["rect"]
        if x >= r.position.x and x <= r.position.x + r.size.x:
            var t = clamp((x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > y_top + 10 and py < y_bot:
                y_bot = py
    if y_bot < logical_h * 1.05:
        broken_ladders.append(Rect2(x, y_top, 6, (y_bot - y_top) * 0.45))'''

code = code.replace(old_ladder, new_ladder)

# 2. Update ladder clamping and density
old_ladder_loop = '''    # 3. Dynamic Ladders
    for p in platforms:
        var r = p["rect"]
        var num_ladders = int(r.size.x / (logical_w * current_platform_spacing))
        num_ladders = max(1, num_ladders)
        for i in range(num_ladders):
            var jitter = rng.randf_range(-40.0, 40.0)
            var lx = r.position.x + r.size.x * (float(i+1)/(num_ladders+1)) + jitter
            var y_approx = _platform_y(Vector2(lx, p["y_left"] - 10))
            if rng.randf() < 0.2:
                _add_dynamic_broken_ladder(lx, y_approx)
            else:
                _add_dynamic_ladder(lx, y_approx)'''

new_ladder_loop = '''    # 3. Dynamic Ladders
    for p in platforms:
        var r = p["rect"]
        var num_ladders = int(r.size.x / (map_w * current_platform_spacing * 2.0))
        num_ladders = max(0, num_ladders - 1)
        for i in range(num_ladders):
            var jitter = rng.randf_range(-60.0, 60.0)
            var lx = r.position.x + r.size.x * (float(i+1)/(num_ladders+1)) + jitter
            lx = clamp(lx, r.position.x + 10, r.position.x + r.size.x - 10)
            var t = clamp((lx - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            var y_approx = py - 10
            if rng.randf() < current_barrel_ladder_chance:
                _add_dynamic_broken_ladder(lx, y_approx)
            else:
                _add_dynamic_ladder(lx, y_approx)'''

code = code.replace(old_ladder_loop, new_ladder_loop)

# 3. Update load_reference to use occupancy.png
if 'level_dir.path_join("semantic_map.png")' in code:
    code = code.replace(
        'var sem = level_dir.path_join("semantic_map.png")',
        'var sem = level_dir.path_join("derived").path_join("occupancy.png")'
    )

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
