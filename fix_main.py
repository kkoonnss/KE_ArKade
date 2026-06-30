import os

with open('app/hub/main.gd', 'r') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if line.startswith('func set_active_nav'):
        new_lines.append("""func set_active_nav(active_btn: Button):
	active_nav_btn = active_btn
	var nav_buttons = [
		$UI/Content/SideNav/ScenesBtn,
		$UI/Content/SideNav/LevelsBtn,
		$UI/Content/SideNav/GamesBtn,
		$UI/Content/SideNav/DesignBtn,
		$UI/Content/SideNav/CalibrateBtn,
		$UI/Content/SideNav/ServiceBtn,
		$UI/Content/SideNav/TestPatternBtn
	]
	
	for btn in nav_buttons:
		if btn == active_btn:
			btn.add_theme_stylebox_override("normal", style_nav_active)
			btn.add_theme_stylebox_override("hover", style_nav_active)
			btn.add_theme_stylebox_override("pressed", style_nav_active)
			btn.add_theme_color_override("font_color", color_cyan)
			btn.add_theme_color_override("font_hover_color", color_cyan)
			btn.add_theme_color_override("font_pressed_color", color_cyan)
		else:
			btn.add_theme_stylebox_override("normal", style_nav_normal)
			btn.add_theme_stylebox_override("hover", style_btn_hover)
			btn.add_theme_stylebox_override("pressed", style_btn_pressed)
			btn.add_theme_color_override("font_color", color_ink_dim)
			btn.add_theme_color_override("font_hover_color", color_ink_white)
			btn.add_theme_color_override("font_pressed_color", color_black)
			
	call_deferred("_do_focus_clamp")

func _do_focus_clamp():
	if is_instance_valid(scenes_grid):
		_clamp_left_to_nav(scenes_grid)
	if is_instance_valid(scroll_vbox):
		_clamp_left_to_nav(scroll_vbox)

func _clamp_left_to_nav(container: Control):
	if active_nav_btn == null: return
	var first_focusable_in_hbox = null
	for child in container.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			if container is GridContainer:
				if child.get_index() % container.columns == 0:
					child.focus_neighbor_left = child.get_path_to(active_nav_btn)
			elif container is HBoxContainer:
				if first_focusable_in_hbox == null:
					first_focusable_in_hbox = child
					child.focus_neighbor_left = child.get_path_to(active_nav_btn)
			else:
				child.focus_neighbor_left = child.get_path_to(active_nav_btn)
		if child.get_child_count() > 0:
			_clamp_left_to_nav(child)

func setup_launch_dialog():
	launch_dialog = ColorRect.new()
	launch_dialog.color = Color(0, 0, 0, 0.75)
	launch_dialog.visible = false
	add_child(launch_dialog)
	launch_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var center_container = CenterContainer.new()
	launch_dialog.add_child(center_container)
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 600)
	center_container.add_child(panel)
	panel.add_theme_stylebox_override("panel", style_panel)
\n""")
        skip = True
    elif skip and line.strip().startswith('var margin = MarginContainer.new()'):
        skip = False
        new_lines.append(line)
    elif not skip:
        new_lines.append(line)

with open('app/hub/main.gd', 'w') as f:
    f.writelines(new_lines)
