import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Fix max ladder length
old_ladder = '''    if y_bot < logical_h * 1.5:
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))'''
new_ladder = '''    if y_bot < logical_h * 1.5:
        var length = y_bot - y_top
        if length > current_max_ladder_length:
            broken_ladders.append(Rect2(x, y_top, 6, current_max_ladder_length))
        else:
            ladders.append(Rect2(x, y_top, 6, length))'''
code = code.replace(old_ladder, new_ladder)

old_broken = '''    if y_bot < logical_h * 1.5:
        broken_ladders.append(Rect2(x, y_top, 6, y_bot - y_top))'''
new_broken = '''    if y_bot < logical_h * 1.5:
        var length = y_bot - y_top
        if length > current_max_ladder_length:
            broken_ladders.append(Rect2(x, y_top, 6, current_max_ladder_length))
        else:
            broken_ladders.append(Rect2(x, y_top, 6, length))'''
code = code.replace(old_broken, new_broken)

# 2. Fix barrel collision
old_col = '''            var d = b["pos"].distance_to(p["pos"])
            if d < 24 and abs(p["vel"].y) < 60:
                p["dead"] = true
                _lose_life()
            elif d < 38 and p["vel"].y < -20 and not b["jumped"]:
                b["jumped"] = true'''
new_col = '''            var d = b["pos"].distance_to(p["pos"])
            var p_rect = Rect2(p["pos"].x - 6, p["pos"].y - 12, 12, 12)
            var b_rect = Rect2(b["pos"].x - 6, b["pos"].y - 12, 12, 12)
            if p_rect.intersects(b_rect):
                p["dead"] = true
                _lose_life()
            elif d < 38 and p["vel"].y < -20 and not b["jumped"]:
                b["jumped"] = true'''
code = code.replace(old_col, new_col)

# 3. Fix falling death
old_fall = '''    if not p["on_ground"] and pos.y > logical_h:
        p["dead"] = true
        _lose_life()
        return'''
new_fall = '''    if not p["on_ground"] and pos.y >= logical_h - 1:
        p["dead"] = true
        _lose_life()
        return'''
code = code.replace(old_fall, new_fall)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
