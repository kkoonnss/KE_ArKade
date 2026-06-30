import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

old_custom_setup = '''    var tiles_x = max(1, int(ceil(logical_w / map_w)))
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

new_custom_setup = '''    # 1. Custom Walls (Islands)
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
        dir *= -1
        
    # 2.5 Procedural Gap Filling
    platforms.sort_custom(func(a, b): return a["rect"].position.y < b["rect"].position.y)
    var procedural_platforms = []
    var tier_spacing = logical_h * current_platform_spacing
    
    if platforms.size() > 0:
        # Fill gaps between custom platforms
        for i in range(platforms.size() - 1):
            var p_top = platforms[i]
            var p_bot = platforms[i+1]
            var gap = p_bot["rect"].position.y - p_top["rect"].position.y
            var num_fillers = int(gap / tier_spacing) - 1
            if num_fillers > 0:
                var filler_spacing = gap / (num_fillers + 1)
                for j in range(num_fillers):
                    var py = p_top["rect"].position.y + filler_spacing * (j + 1)
                    var trim = logical_w * current_platform_trim
                    var min_x = trim
                    var max_x = logical_w - trim
                    var y_left = py
                    var y_right = py
                    var slope = (current_slope_angle * 10)
                    y_left -= dir * slope
                    y_right += dir * slope
                    procedural_platforms.append({"rect": Rect2(min_x, min(y_left, y_right), max_x - min_x, 5), "y_left": y_left, "y_right": y_right})
                    dir *= -1
        
        # Fill gap from last custom platform to floor
        var last_p = platforms[platforms.size() - 1]
        var bottom_gap = (logical_h * 0.95) - last_p["rect"].position.y
        var num_bottom_fillers = int(bottom_gap / tier_spacing) - 1
        if num_bottom_fillers > 0:
            var filler_spacing = bottom_gap / (num_bottom_fillers + 1)
            for j in range(num_bottom_fillers):
                var py = last_p["rect"].position.y + filler_spacing * (j + 1)
                var trim = logical_w * current_platform_trim
                var min_x = trim
                var max_x = logical_w - trim
                var y_left = py
                var y_right = py
                var slope = (current_slope_angle * 10)
                y_left -= dir * slope
                y_right += dir * slope
                procedural_platforms.append({"rect": Rect2(min_x, min(y_left, y_right), max_x - min_x, 5), "y_left": y_left, "y_right": y_right})
                dir *= -1
                
        # Fill gap from ceiling to first custom platform
        var first_p = platforms[0]
        var top_gap = first_p["rect"].position.y - (logical_h * 0.05)
        var num_top_fillers = int(top_gap / tier_spacing) - 1
        if num_top_fillers > 0:
            var filler_spacing = top_gap / (num_top_fillers + 1)
            for j in range(num_top_fillers):
                var py = (logical_h * 0.05) + filler_spacing * (j + 1)
                var trim = logical_w * current_platform_trim
                var min_x = trim
                var max_x = logical_w - trim
                var y_left = py
                var y_right = py
                var slope = (current_slope_angle * 10)
                y_left -= dir * slope
                y_right += dir * slope
                procedural_platforms.append({"rect": Rect2(min_x, min(y_left, y_right), max_x - min_x, 5), "y_left": y_left, "y_right": y_right})
                dir *= -1
                
    for pp in procedural_platforms:
        platforms.append(pp)
        
    platforms.sort_custom(func(a, b): return a["rect"].position.y < b["rect"].position.y)'''

code = code.replace(old_custom_setup, new_custom_setup)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
