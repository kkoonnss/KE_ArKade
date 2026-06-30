import sys

with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.startswith("var test_pattern_scene = preload"):
        new_lines.append(line)
        new_lines.append('var design_screen_scene = preload("res://app/hub/design_screen.tscn")\n')
    elif line.startswith("func _on_test_pattern_pressed():"):
        new_lines.append('func _on_design_nav_pressed():\n')
        new_lines.append('\tprint("Design screen selected")\n')
        new_lines.append('\tset_active_nav($UI/Content/SideNav/DesignBtn)\n')
        new_lines.append('\tclear_main_panel()\n')
        new_lines.append('\tvar design_inst = design_screen_scene.instantiate()\n')
        new_lines.append('\tdesign_inst.size_flags_horizontal = Control.SIZE_EXPAND_FILL\n')
        new_lines.append('\tdesign_inst.size_flags_vertical = Control.SIZE_EXPAND_FILL\n')
        new_lines.append('\tmain_panel.add_child(design_inst)\n\n')
        new_lines.append(line)
    else:
        new_lines.append(line)

with open("app/hub/main.gd", "w", encoding="utf-8") as f:
    f.writelines(new_lines)
