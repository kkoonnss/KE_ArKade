import re

with open('app/hub/main.gd', 'r') as f:
    content = f.read()

# 1. Enforce grid columns in _ready to prevent horizontal overflow
if 'scenes_grid.columns = ' not in content:
    content = content.replace('func _ready():\n', 'func _ready():\n\tif scenes_grid is GridContainer: scenes_grid.columns = 3\n')

# 2. Remove skin cycling buttons from game cards
# Remove prev_skin_btn
content = re.sub(r'var prev_skin_btn = Button\.new\(\).*?row\.add_child\(prev_skin_btn\)\s*style_grid_button\(prev_skin_btn\)', '', content, flags=re.DOTALL)
# Remove next_skin_btn
content = re.sub(r'var next_skin_btn = Button\.new\(\).*?row\.add_child\(next_skin_btn\)\s*style_grid_button\(next_skin_btn\)', '', content, flags=re.DOTALL)

# 3. Simplify game labels (strip "Classic " if present)
content = content.replace('var display_title = current_skin if current_skin != "" and current_skin != default_skin else game_name', 'var display_title = game_name.replace("Classic ", "")')
# Do the same for level cards
content = content.replace('var display_name = level_name.replace("classic_", "").capitalize()', 'var display_name = level_name.replace("classic_", "").capitalize().replace("Classic ", "")\n\tif display_name == "Scene Pack": display_name = "Classic Pack"\n\tif level_name.to_lower() == "scene_pack": display_name = "Classic Pack"')
content = content.replace('title_lbl.text = classic_name if is_classic_skin else active_skin_name', 'title_lbl.text = classic_name.replace("Classic ", "")')

# Remove sub label (the one in parentheses)
content = re.sub(r'if not is_classic_skin:.*?text_container\.add_child\(sub_lbl\)', '', content, flags=re.DOTALL)

with open('app/hub/main.gd', 'w') as f:
    f.write(content)
