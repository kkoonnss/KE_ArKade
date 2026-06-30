
with open('content/cartridges/pacman/main.gd', 'r') as f:
    lines = f.read().splitlines()
    
# Remove duplicate variables in helpers
new_lines = []
for line in lines:
    if line.startswith('var show_background '): continue
    if line.startswith('var background_opacity '): continue
    if line.startswith('var background_texture '): continue
    if line.startswith('var classic_wall_width_scale '): continue
    new_lines.append(line)
    
with open('content/cartridges/pacman/main.gd', 'w') as f:
    f.write('\n'.join(new_lines))

