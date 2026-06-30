
with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    lines = f.readlines()

new_lines = []
skip = False
funcs_found = 0
for line in lines:
    if line.startswith('func _setup_classic_donkey_kong():'):
        funcs_found += 1
        if funcs_found == 2:
            skip = True
    elif line.startswith('func _setup_platforms():'):
        skip = False
    
    if not skip:
        new_lines.append(line)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.writelines(new_lines)

