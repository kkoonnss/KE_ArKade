import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

old_draw_girder = '''func _draw_girder(rect: Rect2, color: Color):
    _glow_line(rect.position, rect.position + Vector2(rect.size.x, 0), color, 2.6)
    var y = rect.position.y + 7
    _glow_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), color, 1.0)
    for x in range(int(rect.position.x), int(rect.position.x + rect.size.x), 42):
        _glow_line(Vector2(x, rect.position.y), Vector2(x + 24, y), color, 0.8)'''

new_draw_girder = '''func _draw_girder(p: Dictionary, color: Color):
    var r = p["rect"]
    var py_left = p["y_left"]
    var py_right = p["y_right"]
    
    var t_l = Vector2(r.position.x, py_left)
    var t_r = Vector2(r.position.x + r.size.x, py_right)
    
    var b_l = t_l + Vector2(0, 7)
    var b_r = t_r + Vector2(0, 7)
    
    _glow_line(t_l, t_r, color, 2.6)
    _glow_line(b_l, b_r, color, 1.0)
    
    for x in range(int(r.position.x), int(r.position.x + r.size.x), 42):
        var t = float(x - r.position.x) / max(1.0, r.size.x)
        var px = x
        var py = lerp(py_left, py_right, t)
        
        var next_x = min(r.position.x + r.size.x, x + 24)
        var next_t = float(next_x - r.position.x) / max(1.0, r.size.x)
        var next_y = lerp(py_left, py_right, next_t) + 7
        
        _glow_line(Vector2(px, py), Vector2(next_x, next_y), color, 0.8)'''

code = code.replace(old_draw_girder, new_draw_girder)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
