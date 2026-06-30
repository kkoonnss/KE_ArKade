import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

old_slope_dir = '''func _barrel_slope_dir(pos: Vector2) -> float:
    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x:
            if abs(pos.y - _platform_y(pos)) < 30:
                var s = p["y_right"] - p["y_left"]
                if s > 0.5: return 1.0
                if s < -0.5: return -1.0
    return 0.0'''

new_slope_dir = '''func _barrel_slope_dir(pos: Vector2) -> float:
    var best_p = {}
    var best_d = 99999.0
    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            var d = abs(pos.y - py)
            if d < best_d:
                best_d = d
                best_p = p
                
    if not best_p.is_empty() and best_d < 30:
        var s = best_p["y_right"] - best_p["y_left"]
        if s > 0.5: return 1.0
        if s < -0.5: return -1.0
    return 0.0'''

code = code.replace(old_slope_dir, new_slope_dir)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
