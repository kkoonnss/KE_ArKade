import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Inject new drawing and physics functions
new_funcs = '''
func _barrel_slope_dir(pos: Vector2) -> float:
    for p in platforms:
        var r = p["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x:
            if abs(pos.y - _platform_y(pos)) < 30:
                var s = p["y_right"] - p["y_left"]
                if s > 0.5: return 1.0
                if s < -0.5: return -1.0
    return 0.0

func _tick_fire_guy(delta):
    for i in range(fire_guys.size() - 1, -1, -1):
        var fg = fire_guys[i]
        fg["pos"] += fg["vel"] * delta
        var py = _platform_y(fg["pos"])
        fg["pos"].y = py - 16
        
        var hit_edge = true
        for p in platforms:
            var r = p["rect"]
            if fg["pos"].x >= r.position.x and fg["pos"].x <= r.position.x + r.size.x:
                if abs(py - _platform_y(fg["pos"])) < 10:
                    if fg["pos"].x < r.position.x + 10 or fg["pos"].x > r.position.x + r.size.x - 10:
                        hit_edge = true
                    else:
                        hit_edge = false
        if hit_edge:
            fg["vel"].x *= -1
            fg["pos"].x += fg["vel"].x * delta
            
        var d = fg["pos"].distance_to(player["pos"])
        if d < 22 and abs(player["vel"].y) < 60:
            _lose_life()
            break

func _draw_barrel(pos: Vector2, color: Color):
    draw_circle(pos, 12, Color(color.r, color.g, color.b, 0.4))
    draw_arc(pos, 12, 0, TAU, 16, color, 2.0)
    _glow_line(pos + Vector2(-8, -8), pos + Vector2(8, 8), color, 1.5)
    _glow_line(pos + Vector2(-8, 8), pos + Vector2(8, -8), color, 1.5)

func _draw_fire_guy(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 14, color, 2)
    draw_circle(pos + Vector2(-5, -2), 3, Color.YELLOW)
    draw_circle(pos + Vector2(5, -2), 3, Color.YELLOW)
    _glow_line(pos + Vector2(-8, -14), pos + Vector2(0, -26), Color.YELLOW, 1.5)
    _glow_line(pos + Vector2(8, -14), pos + Vector2(0, -26), Color.YELLOW, 1.5)
'''
code = code.replace('func _tick_barrel(delta):', new_funcs + '\nfunc _tick_barrel(delta):')

# 2. Add _tick_fire_guy to _process
code = code.replace(
'''    if game_id == "donkey_kong":
        _tick_barrel(delta)''',
'''    if game_id == "donkey_kong":
        _tick_barrel(delta)
        _tick_fire_guy(delta)'''
)

# 3. Update _tick_barrel
old_barrel_logic = '''        if b.get("ladder", false):
            var below = _platform_below(b["pos"])
            if below > 0.0 and b["pos"].y >= below - 14:
                b["pos"].y = below - 13
                b["vel"] = Vector2([-1, 1][randi() % 2] * (120 + wave * 5), 0)
                b["ladder"] = false
        elif py > 0:
            b["pos"].y = py - 13
        if not b.get("ladder", false) and randf() < delta * 0.18:
            b["vel"].x *= -1'''

new_barrel_logic = '''        if b.get("ladder", false):
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
                b["vel"].x = dir * abs(b["vel"].x)'''
code = code.replace(old_barrel_logic, new_barrel_logic)

# 4. Use _draw_barrel instead of _draw_platform_enemy for barrels in _draw_platform_game
old_draw_plat2 = '''    for t in things:
        var pos = t.get("pos", Vector2.ZERO)
        if t.has("egg") and t["egg"]:
            _draw_egg(pos, C_YELLOW)
        else:
            _draw_platform_enemy(pos, color)'''

new_draw_plat2 = '''    for t in things:
        var pos = t.get("pos", Vector2.ZERO)
        if t.has("egg") and t["egg"]:
            _draw_egg(pos, C_YELLOW)
        elif t.has("jumped"):
            _draw_barrel(pos, color)
        else:
            _draw_platform_enemy(pos, color)'''
code = code.replace(old_draw_plat2, new_draw_plat2)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
