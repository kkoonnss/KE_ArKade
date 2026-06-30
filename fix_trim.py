import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

old_custom_trim = '''        var trim = (max_x - min_x) * current_platform_trim
        min_x += trim
        max_x -= trim
        if max_x <= min_x + 10: continue'''

new_custom_trim = '''        var trim = (max_x - min_x) * current_platform_trim
        if dir == 1:
            max_x -= trim
        else:
            min_x += trim
        if max_x <= min_x + 10: continue'''
        
code = code.replace(old_custom_trim, new_custom_trim)

old_procedural_trim = '''                    var trim = logical_w * current_platform_trim
                    var min_x = trim
                    var max_x = logical_w - trim'''
                    
new_procedural_trim = '''                    var trim = logical_w * current_platform_trim
                    var min_x = 0.0
                    var max_x = logical_w
                    if dir == 1:
                        max_x -= trim
                    else:
                        min_x += trim'''

code = code.replace(old_procedural_trim, new_procedural_trim)

old_bottom_trim = '''                var trim = logical_w * current_platform_trim
                var min_x = trim
                var max_x = logical_w - trim'''

new_bottom_trim = '''                var trim = logical_w * current_platform_trim
                var min_x = 0.0
                var max_x = logical_w
                if dir == 1:
                    max_x -= trim
                else:
                    min_x += trim'''
                    
code = code.replace(old_bottom_trim, new_bottom_trim)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
