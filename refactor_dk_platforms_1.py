import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Splash screen fix
code = code.replace(
'''func _splash(delta):
    if state == "start":
        return''',
'''func _splash(delta):
    pass'''
)

# 2. Add properties
props = '''var screenshot_path = ""
var current_jump_height = 1.0
var current_platform_snap = 1.0
var current_add_platforms = true
var current_climb_tolerance = 1.0
var current_hazard_leniency = 1.0
var current_bounds_clamp = true
var current_slope_angle = 1.0
var current_fire_enemy_count = 1
var fire_guys = []
'''
code = code.replace('var screenshot_path = ""', props)

# 3. Add _add_platform helper
helper = '''func _add_platform(r: Rect2, y_l: float, y_r: float):
    platforms.append({"rect": r, "y_left": y_l, "y_right": y_r})
'''
code = code.replace('var adapter_platforms = []', helper + '\nvar adapter_platforms = []')

# 4. _platform_y and _platform_below refactors
old_platform_below = '''func _platform_below(pos: Vector2) -> float:
    var best = 0.0
    var best_d = 99999.0
    for p in platforms:
        if pos.x >= p.position.x - 24 and pos.x <= p.position.x + p.size.x + 24 and p.position.y > pos.y + 16:
            var d = p.position.y - pos.y
            if d < best_d:
                best_d = d
                best = p.position.y
    return best'''

new_platform_below = '''func _platform_below(pos: Vector2) -> float:
    var best = 0.0
    var best_d = 99999.0
    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x - 24 and pos.x <= r.position.x + r.size.x + 24:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            if py > pos.y + 16:
                var d = py - pos.y
                if d < best_d:
                    best_d = d
                    best = py
    return best'''
code = code.replace(old_platform_below, new_platform_below)

old_platform_y = '''func _platform_y(pos: Vector2) -> float:
    var best = map_h * 0.9
    var best_d = 99999.0
    for p in platforms:
        if pos.x >= p.position.x - 20 and pos.x <= p.position.x + p.size.x + 20:
            var d = abs(pos.y - p.position.y)
            if d < best_d:
                best_d = d
                best = p.position.y
    return best'''

new_platform_y = '''func _platform_y(pos: Vector2) -> float:
    var best = map_h * 0.9
    var best_d = 99999.0
    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x - 20 and pos.x <= r.position.x + r.size.x + 20:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(p["y_left"], p["y_right"], t)
            var d = abs(pos.y - py)
            if d < best_d:
                best_d = d
                best = py
    return best'''
code = code.replace(old_platform_y, new_platform_y)

# 5. Fix _draw_platform_game and _draw_girder to use new platforms dict
old_draw_plat = '''func _draw_platform_game(things, color: Color):
    for p in platforms:
        _draw_girder(p, C_CYAN)'''
new_draw_plat = '''func _draw_platform_game(things, color: Color):
    for p in platforms:
        _draw_girder(p, C_CYAN)
    for fg in fire_guys:
        _draw_fire_guy(fg["pos"], C_RED)'''
code = code.replace(old_draw_plat, new_draw_plat)

old_draw_girder = '''func _draw_girder(rect: Rect2, color: Color):
    draw_rect(rect, color, false, 1.2)
    for x in range(int(rect.position.x + 4), int(rect.position.x + rect.size.x), 12):
        _glow_line(Vector2(x, rect.position.y), Vector2(x - 6, rect.position.y + rect.size.y), color, 0.8)
        _glow_line(Vector2(x, rect.position.y), Vector2(x + 6, rect.position.y + rect.size.y), color, 0.8)'''

new_draw_girder = '''func _draw_girder(p: Dictionary, color: Color):
    var r = p["rect"]
    var py_left = p["y_left"]
    var py_right = p["y_right"]
    var t_l = Vector2(r.position.x, py_left)
    var t_r = Vector2(r.position.x + r.size.x, py_right)
    var b_l = t_l + Vector2(0, r.size.y)
    var b_r = t_r + Vector2(0, r.size.y)
    
    _glow_line(t_l, t_r, color, 1.2)
    _glow_line(b_l, b_r, color, 1.2)
    _glow_line(t_l, b_l, color, 1.2)
    _glow_line(t_r, b_r, color, 1.2)
    
    var steps = int(r.size.x / 12)
    for i in range(1, steps):
        var x = r.position.x + i * 12
        var t = float(i) / steps
        var py = lerp(py_left, py_right, t)
        _glow_line(Vector2(x, py), Vector2(x - 6, py + r.size.y), color, 0.8)
        _glow_line(Vector2(x, py), Vector2(x + 6, py + r.size.y), color, 0.8)'''
code = code.replace(old_draw_girder, new_draw_girder)

# 6. Tab Settings hookup
old_knob = '''func _on_knob_changed(knob_id: String, value):
    pass'''
new_knob = '''func _on_knob_changed(knob_id: String, value):
    if knob_id == "jump_height": current_jump_height = float(value)
    elif knob_id == "platform_snap": current_platform_snap = float(value)
    elif knob_id == "add_platforms": current_add_platforms = bool(value)
    elif knob_id == "climb_tolerance": current_climb_tolerance = float(value)
    elif knob_id == "hazard_leniency": current_hazard_leniency = float(value)
    elif knob_id == "bounds_clamp": current_bounds_clamp = bool(value)
    elif knob_id == "slope_angle": current_slope_angle = float(value)
    elif knob_id == "fire_enemy_count": current_fire_enemy_count = int(value)'''
code = code.replace(old_knob, new_knob)

old_reg = '''    tab_menu.register_knob_float("hazard_leniency", "Hazard Leniency", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true)'''
new_reg = '''    tab_menu.register_knob_float("hazard_leniency", "Hazard Leniency", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true)
    tab_menu.register_knob_float("slope_angle", "Slope Angle", 1.0, 0.0, 3.0, 0.1, "Secondary")
    tab_menu.register_knob_int("fire_enemy_count", "Fire Enemies", 1, 0, 4, 1, "Secondary")'''
code = code.replace(old_reg, new_reg)

# Write out so far
with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
