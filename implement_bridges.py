import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Add variables
if 'var current_extra_fill' not in code:
    code = code.replace(
        'var current_barrel_ladder_chance = 0.5',
        '''var current_barrel_ladder_chance = 0.5
var current_extra_fill = 0.5
var current_ladder_density = 1.0
var current_max_ladder_length = 300.0'''
    )

# 2. Add knobs
if '"extra_fill"' not in code:
    code = code.replace(
        'tab_menu.register_knob_float("barrel_ladder_chance", "Barrel Ladder %", 0.5, 0.0, 1.0, 0.05, "Secondary")',
        '''tab_menu.register_knob_float("barrel_ladder_chance", "Barrel Ladder %", 0.5, 0.0, 1.0, 0.05, "Secondary")
    tab_menu.register_knob_float("extra_fill", "Extra Fill %", 0.5, 0.0, 1.0, 0.05, "Secondary")
    tab_menu.register_knob_float("ladder_density", "Ladder Density", 1.0, 0.0, 2.0, 0.1, "Secondary")
    tab_menu.register_knob_float("max_ladder_length", "Max Ladder Len", 300.0, 50.0, 800.0, 25.0, "Secondary")'''
    )

# 3. Handle knob changes
if 'knob_id == "extra_fill"' not in code:
    code = code.replace(
        '''    elif knob_id == "barrel_ladder_chance":
        current_barrel_ladder_chance = float(value)''',
        '''    elif knob_id == "barrel_ladder_chance":
        current_barrel_ladder_chance = float(value)
    elif knob_id == "extra_fill":
        current_extra_fill = float(value)
        load_level()
        reset_game()
    elif knob_id == "ladder_density":
        current_ladder_density = float(value)
        load_level()
        reset_game()
    elif knob_id == "max_ladder_length":
        current_max_ladder_length = float(value)
        load_level()
        reset_game()'''
    )

# 4. Extract platforms from grid
old_custom_platforms = '''    # 2. Custom Platforms
    var sorted_platforms = []
    for p in adapter_platforms:
        sorted_platforms.append(p)
    sorted_platforms.sort_custom(func(a, b): return a["p1"].y < b["p1"].y)'''

new_custom_platforms = '''    # 2. Custom Platforms
    var extracted_platforms = []
    if grid.size() > 0:
        for y in range(1, grid.size()):
            var current_platform_start_x = -1
            for x in range(grid[y].size()):
                var is_solid = grid[y][x] == 1
                var is_top_edge = is_solid and grid[y-1][x] != 1
                if is_top_edge:
                    if current_platform_start_x == -1:
                        current_platform_start_x = x
                else:
                    if current_platform_start_x != -1:
                        var px1 = current_platform_start_x * cell_px
                        var px2 = x * cell_px
                        var py = y * cell_px
                        extracted_platforms.append({"p1": Vector2(px1, py), "p2": Vector2(px2, py)})
                        current_platform_start_x = -1
            if current_platform_start_x != -1:
                var px1 = current_platform_start_x * cell_px
                var px2 = grid[y].size() * cell_px
                var py = y * cell_px
                extracted_platforms.append({"p1": Vector2(px1, py), "p2": Vector2(px2, py)})
                
    var sorted_platforms = []
    for p in extracted_platforms:
        sorted_platforms.append(p)
    sorted_platforms.sort_custom(func(a, b): return a["p1"].y < b["p1"].y)'''

code = code.replace(old_custom_platforms, new_custom_platforms)

# 5. Extra Fill for procedural platforms
old_fillers = '''            var num_fillers = int(gap / tier_spacing) - 1'''
new_fillers = '''            var raw_fillers = (gap / tier_spacing) - 1
            var num_fillers = int(max(0.0, raw_fillers) * current_extra_fill)'''
code = code.replace(old_fillers, new_fillers)

old_bot_fillers = '''        var num_bottom_fillers = int(bottom_gap / tier_spacing) - 1'''
new_bot_fillers = '''        var raw_bot_fillers = (bottom_gap / tier_spacing) - 1
        var num_bottom_fillers = int(max(0.0, raw_bot_fillers) * current_extra_fill)'''
code = code.replace(old_bot_fillers, new_bot_fillers)

old_top_fillers = '''        var num_top_fillers = int(top_gap / tier_spacing) - 1'''
new_top_fillers = '''        var raw_top_fillers = (top_gap / tier_spacing) - 1
        var num_top_fillers = int(max(0.0, raw_top_fillers) * current_extra_fill)'''
code = code.replace(old_top_fillers, new_top_fillers)

# 6. Ladder density
old_ladders = '''        var num_ladders = int(r.size.x / (map_w * current_platform_spacing * 2.0))
        num_ladders = max(0, num_ladders - 1)'''
new_ladders = '''        var num_ladders = int((r.size.x / (map_w * current_platform_spacing * 2.0)) * current_ladder_density)
        num_ladders = max(0, num_ladders - 1)'''
code = code.replace(old_ladders, new_ladders)

# 7. Max Ladder Length
old_dynamic_ladder = '''    if y_top < y_bot:
        if y_bot > logical_h * 1.5:
            return
        ladders.append(Rect2(x, y_top, 6, y_bot - y_top))'''
        
new_dynamic_ladder = '''    if y_top < y_bot:
        if y_bot > logical_h * 1.5:
            return
        var length = y_bot - y_top
        if length > current_max_ladder_length:
            broken_ladders.append(Rect2(x, y_top, 6, current_max_ladder_length))
        else:
            ladders.append(Rect2(x, y_top, 6, length))'''

code = code.replace(old_dynamic_ladder, new_dynamic_ladder)

old_dynamic_broken = '''    if y_top < y_bot:
        if y_bot < logical_h * 1.5:
            broken_ladders.append(Rect2(x, y_top, 6, y_bot - y_top))'''
            
new_dynamic_broken = '''    if y_top < y_bot:
        if y_bot < logical_h * 1.5:
            var length = y_bot - y_top
            if length > current_max_ladder_length:
                broken_ladders.append(Rect2(x, y_top, 6, current_max_ladder_length))
            else:
                broken_ladders.append(Rect2(x, y_top, 6, length))'''
                
code = code.replace(old_dynamic_broken, new_dynamic_broken)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
