import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

old_custom_setup = '''    # 1. Custom Walls (Islands)
    if grid.size() > 0:
        for y in range(grid.size()):
            var row = grid[y]
            for x in range(row.size()):
                if row[x] == 1: # Solid
                    var wx = (x * cell_px) / cs
                    var wy = (y * cell_px) / cs
                    var ws = cell_px / cs
                    walls.append(Rect2(wx, wy, ws, ws))
    
    # 2. Custom Platforms
    var sorted_platforms = []
    for p in adapter_platforms:
        sorted_platforms.append(p)
    sorted_platforms.sort_custom(func(a, b): return a["p1"].y < b["p1"].y)
    
    var dir = 1
    for p in sorted_platforms:
        var min_x = min(p["p1"].x, p["p2"].x) / cs
        var max_x = max(p["p1"].x, p["p2"].x) / cs
        var py = p["p1"].y / cs
        
        var trim = (max_x - min_x) * current_platform_trim
        min_x += trim
        max_x -= trim
        if max_x <= min_x + 10: continue
        
        var y_left = py
        var y_right = py
        var slope = (current_slope_angle * 10)
        y_left -= dir * slope
        y_right += dir * slope
        
        _add_platform(Rect2(min_x, min(y_left, y_right), max_x - min_x, 5), y_left, y_right)
        dir *= -1'''

new_custom_setup = '''    var tiles_x = max(1, int(ceil(logical_w / map_w)))
    var tiles_y = max(1, int(ceil(logical_h / map_h)))
    
    # 1. Custom Walls (Islands)
    if grid.size() > 0:
        for ty in range(tiles_y):
            for tx in range(tiles_x):
                var ox = tx * map_w
                var oy = ty * map_h
                for y in range(grid.size()):
                    var row = grid[y]
                    for x in range(row.size()):
                        if row[x] == 1: # Solid
                            var wx = x * cell_px + ox
                            var wy = y * cell_px + oy
                            walls.append(Rect2(wx, wy, cell_px, cell_px))
    
    # 2. Custom Platforms
    var sorted_platforms = []
    for p in adapter_platforms:
        sorted_platforms.append(p)
    sorted_platforms.sort_custom(func(a, b): return a["p1"].y < b["p1"].y)
    
    var dir = 1
    for ty in range(tiles_y):
        for tx in range(tiles_x):
            var ox = tx * map_w
            var oy = ty * map_h
            for p in sorted_platforms:
                var min_x = min(p["p1"].x, p["p2"].x) + ox
                var max_x = max(p["p1"].x, p["p2"].x) + ox
                var py = p["p1"].y + oy
                
                var trim = (max_x - min_x) * current_platform_trim
                min_x += trim
                max_x -= trim
                if max_x <= min_x + 10: continue
                
                var y_left = py
                var y_right = py
                var slope = (current_slope_angle * 10)
                y_left -= dir * slope
                y_right += dir * slope
                
                _add_platform(Rect2(min_x, min(y_left, y_right), max_x - min_x, 5), y_left, y_right)
                dir *= -1'''

code = code.replace(old_custom_setup, new_custom_setup)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
