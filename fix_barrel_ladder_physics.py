import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

old_physics = '''        if b.get("ladder", false):
            b["vel"].x = 0
            if py > 0 and b["pos"].y >= py - 16:
                b["pos"].y = py - 13
                var dir = _barrel_slope_dir(b["pos"])
                if dir == 0.0: dir = sign(b["vel"].x) if abs(b["vel"].x) > 10 else [-1, 1][randi() % 2]
                b["vel"] = Vector2(dir * (120 + wave * 5), 0)
                b["ladder"] = false
        else:
            if py > 0 and b["vel"].y >= 0 and b["pos"].y > py - 16 and b["pos"].y < py + 16:
                b["pos"].y = py - 13
                b["vel"].y = 0
                var dir = _barrel_slope_dir(b["pos"])
                if dir != 0.0:
                    b["vel"].x = dir * max(100.0, abs(b["vel"].x))
        if b["pos"].x < 20 or b["pos"].x > map_w - 20 or b["pos"].y > map_h:'''

new_physics = '''        if b.get("ladder", false):
            b["vel"].x = 0
            if _barrel_ladder_x(b["pos"]) < 0.0:
                b["ladder"] = false
        else:
            if py > 0 and b["vel"].y >= 0 and b["pos"].y > py - 16 and b["pos"].y < py + 16:
                b["pos"].y = py - 13
                b["vel"].y = 0
                var dir = _barrel_slope_dir(b["pos"])
                var current_vx = abs(b["vel"].x)
                if current_vx < 10:
                    current_vx = 120 + wave * 5
                if dir != 0.0:
                    b["vel"].x = dir * max(current_vx, 100.0)
                elif abs(b["vel"].x) < 10:
                    b["vel"].x = [-1, 1][randi() % 2] * current_vx
        if b["pos"].x < -100 or b["pos"].x > logical_w + 100 or b["pos"].y > logical_h + 100:'''

code = code.replace(old_physics, new_physics)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
