extends CanvasLayer
class_name TabMenu

signal knob_changed(knob_id, new_value)
signal action_triggered(action_id)
signal menu_closed
signal settings_reset

var splash_rect: TextureRect
var menu_overlay: ColorRect
var overlay_margin: MarginContainer
var menu_shell: BoxContainer
var splash_frame: PanelContainer
var menu_panel: PanelContainer
var menu_title_label: Label
var menu_subtitle_label: Label
var menu_hint_label: Label
var menu_reset_button: Button
var menu_labels = []
var settings_scroll: ScrollContainer
var settings_box: VBoxContainer
var settings_controls = {}
var collapsed_groups = {}

var overlay_mode: String = "start"
var selected_menu_index: int = 0
var menu_axis_cooldown: float = 0.0
var _joy_scroll_state: int = 0
var _joy_scroll_timer: float = 0.0
var _joy_scroll_is_repeating: bool = false
var level_name: String = "GAME"
var cartridge_id: String = "unknown"
var level_dir: String = ""

var registered_knobs = []
var registered_actions = []

func _init():
	layer = 100

func setup(c_id: String, l_dir: String, title: String):
	cartridge_id = c_id
	level_dir = l_dir
	level_name = title
	_build_ui()
	_load_settings()
	_save_settings()
	_set_overlay_mode("start")

func register_action(id: String, label: String, mode: String = "all"):
	registered_actions.append({"id": id, "label": label, "mode": mode})

func register_knob_float(id: String, label: String, default_val: float, min_val: float, max_val: float, step: float, group: String = "General"):
	registered_knobs.append({"id": id, "label": label, "type": "float", "value": default_val, "default": default_val, "min": min_val, "max": max_val, "step": step, "group": group})

func register_knob_int(id: String, label: String, default_val: int, min_val: int, max_val: int, step: int, group: String = "General"):
	registered_knobs.append({"id": id, "label": label, "type": "int", "value": default_val, "default": default_val, "min": min_val, "max": max_val, "step": step, "group": group})

func register_knob_bool(id: String, label: String, default_val: bool, group: String = "General"):
	registered_knobs.append({"id": id, "label": label, "type": "bool", "value": default_val, "default": default_val, "group": group})

func register_knob_enum(id: String, label: String, default_val: String, options: Array, group: String = "General"):
	registered_knobs.append({"id": id, "label": label, "type": "enum", "value": default_val, "default": default_val, "options": options, "group": group})

func get_knob_value(id: String):
	for k in registered_knobs:
		if k.id == id:
			return k.value
	return null

func set_knob_value(id: String, value, persist: bool = true, refresh_controls: bool = true):
	for k in registered_knobs:
		if k.id != id:
			continue
		if k.type == "float":
			k.value = clamp(float(value), float(k.min), float(k.max))
		elif k.type == "int":
			k.value = clamp(int(value), int(k.min), int(k.max))
		elif k.type == "bool":
			k.value = bool(value)
		elif k.type == "enum":
			k.value = str(value)
		if refresh_controls and overlay_mode == "settings":
			_rebuild_settings_controls()
		if persist:
			_save_settings()
		return

func _reset_settings():
	for k in registered_knobs:
		if k.has("default") and k.value != k.default:
			k.value = k.default
			emit_signal("knob_changed", k.id, k.value)
	_save_settings()
	emit_signal("settings_reset")
	if overlay_mode == "settings":
		_rebuild_settings_controls()

func _build_ui():
	menu_overlay = ColorRect.new()
	menu_overlay.color = Color(0, 0, 0, 0.82)
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_overlay)

	overlay_margin = MarginContainer.new()
	overlay_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_margin.add_theme_constant_override("margin_left", 42)
	overlay_margin.add_theme_constant_override("margin_top", 42)
	overlay_margin.add_theme_constant_override("margin_right", 42)
	overlay_margin.add_theme_constant_override("margin_bottom", 42)
	menu_overlay.add_child(overlay_margin)

	menu_shell = HBoxContainer.new()
	menu_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_shell.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_shell.add_theme_constant_override("separation", 28)
	overlay_margin.add_child(menu_shell)

	splash_frame = PanelContainer.new()
	splash_frame.custom_minimum_size = Vector2(540, 760)
	splash_frame.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.95, 0.78, 0.24), Color(0.03, 0.03, 0.06, 0.96)))
	menu_shell.add_child(splash_frame)

	splash_rect = TextureRect.new()
	splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
	if FileAccess.file_exists(splash_path):
		var img = Image.load_from_file(splash_path)
		if img:
			splash_rect.texture = ImageTexture.create_from_image(img)
	splash_frame.add_child(splash_rect)

	menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(620, 700)
	menu_panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.16, 0.55, 1.0), Color(0.01, 0.01, 0.01, 0.92)))
	menu_shell.add_child(menu_panel)

	var menu_margin = MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 28)
	menu_margin.add_theme_constant_override("margin_top", 24)
	menu_margin.add_theme_constant_override("margin_right", 28)
	menu_margin.add_theme_constant_override("margin_bottom", 24)
	menu_panel.add_child(menu_margin)

	var box = VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	menu_margin.add_child(box)

	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title_row)

	menu_title_label = Label.new()
	menu_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.24))
	menu_title_label.add_theme_font_size_override("font_size", 42)
	menu_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(menu_title_label)
	
	menu_reset_button = Button.new()
	menu_reset_button.text = "Reset Default Settings"
	menu_reset_button.add_theme_font_size_override("font_size", 18)
	menu_reset_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	menu_reset_button.flat = true
	menu_reset_button.focus_mode = Control.FOCUS_ALL
	menu_reset_button.pressed.connect(func(): _reset_settings())
	title_row.add_child(menu_reset_button)

	menu_subtitle_label = Label.new()
	menu_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	menu_subtitle_label.add_theme_font_size_override("font_size", 20)
	box.add_child(menu_subtitle_label)

	var divider = ColorRect.new()
	divider.color = Color(1.0, 0.84, 0.2, 0.55)
	divider.custom_minimum_size = Vector2(0, 2)
	box.add_child(divider)

	settings_scroll = ScrollContainer.new()
	settings_scroll.focus_mode = Control.FOCUS_NONE
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	box.add_child(settings_scroll)

	var settings_margin = MarginContainer.new()
	settings_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_margin.add_theme_constant_override("margin_left", 2)
	settings_margin.add_theme_constant_override("margin_right", 14)
	settings_scroll.add_child(settings_margin)

	settings_box = VBoxContainer.new()
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_theme_constant_override("separation", 14)
	settings_margin.add_child(settings_box)

	for _i in range(12):
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 24)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_wire_menu_label_mouse(label, _i)
		box.add_child(label)
		menu_labels.append(label)

	menu_hint_label = Label.new()
	menu_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_hint_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	menu_hint_label.add_theme_font_size_override("font_size", 18)
	box.add_child(menu_hint_label)

func _menu_panel_style(border_color: Color, fill_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 16
	return style

func _wire_menu_label_mouse(label: Label, index: int):
	label.mouse_entered.connect(func():
		_on_menu_label_mouse_entered(index)
	)
	label.gui_input.connect(func(event):
		_on_menu_label_gui_input(event, index)
	)

func _on_menu_label_mouse_entered(index: int):
	if not _menu_label_accepts_mouse(index):
		return
	if selected_menu_index == index:
		return
	selected_menu_index = index
	_update_menu_overlay()

func _on_menu_label_gui_input(event: InputEvent, index: int):
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if not _menu_label_accepts_mouse(index):
		return
	selected_menu_index = index
	_update_menu_overlay()
	if index >= 0 and index < menu_labels.size():
		var label = menu_labels[index] as Control
		if label:
			label.accept_event()
	_menu_accept()

func _menu_label_accepts_mouse(index: int) -> bool:
	if overlay_mode == "settings":
		return false
	var items = _get_current_items()
	return index >= 0 and index < items.size()

func _set_overlay_mode(mode: String):
	overlay_mode = mode
	selected_menu_index = 0
	if menu_overlay:
		menu_overlay.visible = overlay_mode != ""
		menu_overlay.color = Color(0, 0, 0, 0.16) if overlay_mode == "settings" else Color(0, 0, 0, 0.82)
	if splash_rect:
		splash_rect.visible = overlay_mode in ["start", "help"]
		splash_rect.modulate.a = 1.0
	if splash_frame:
		splash_frame.visible = overlay_mode in ["start", "help"]
	if menu_shell:
		menu_shell.alignment = BoxContainer.ALIGNMENT_BEGIN if overlay_mode == "settings" else BoxContainer.ALIGNMENT_CENTER
	if menu_panel:
		menu_panel.custom_minimum_size = Vector2(680, 820) if overlay_mode == "settings" else Vector2(620, 700)
	if menu_reset_button:
		menu_reset_button.visible = overlay_mode == "settings"
	if settings_scroll:
		settings_scroll.visible = overlay_mode == "settings"
	if mode == "":
		emit_signal("menu_closed")
	else:
		if overlay_mode == "settings":
			_rebuild_settings_controls()
			_focus_first_settings_control()
		_update_menu_overlay()

func _input(event):
	if overlay_mode == "":
		var open_menu = false
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
				open_menu = true
		elif event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_START:
				open_menu = true
				
		if open_menu:
			_set_overlay_mode("settings")
			get_viewport().set_input_as_handled()
		return
	if _handle_menu_input(event):
		get_viewport().set_input_as_handled()

func _process(delta):
	menu_axis_cooldown = max(0.0, menu_axis_cooldown - delta)

	if overlay_mode == "settings":
		var joy_id = 0
		var parent = get_parent()
		if parent and "SharedLoader" in parent and parent.SharedLoader:
			joy_id = parent.SharedLoader.get_joy_id(0)
		var y_val = Input.get_joy_axis(joy_id, JOY_AXIS_LEFT_Y)
		var dir = 0
		if y_val < -0.6:
			dir = -1
		elif y_val > 0.6:
			dir = 1

		if dir != 0:
			if _joy_scroll_state != dir:
				if _joy_scroll_state != 0:
					var ev_up = InputEventAction.new()
					ev_up.action = "ui_up"
					ev_up.pressed = false
					Input.parse_input_event(ev_up)
					var ev_down = InputEventAction.new()
					ev_down.action = "ui_down"
					ev_down.pressed = false
					Input.parse_input_event(ev_down)
				_joy_scroll_state = dir
				_joy_scroll_timer = 0.4
				_joy_scroll_is_repeating = false
			else:
				_joy_scroll_timer -= delta
				if _joy_scroll_timer <= 0.0:
					_joy_scroll_is_repeating = true
					_joy_scroll_timer = 0.12

					var ev = InputEventAction.new()
					ev.action = "ui_down" if dir == 1 else "ui_up"
					ev.pressed = true
					Input.parse_input_event(ev)
		else:
			if _joy_scroll_state != 0:
				var ev_up = InputEventAction.new()
				ev_up.action = "ui_up"
				ev_up.pressed = false
				Input.parse_input_event(ev_up)
				var ev_down = InputEventAction.new()
				ev_down.action = "ui_down"
				ev_down.pressed = false
				Input.parse_input_event(ev_down)
			_joy_scroll_state = 0
			_joy_scroll_is_repeating = false

func _handle_menu_input(event) -> bool:
	if overlay_mode == "settings":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE:
				_menu_back()
				return true
			if event.keycode == KEY_TAB:
				_set_overlay_mode("start")
				return true
		elif event is InputEventJoypadButton and event.pressed:
			if event.button_index in [JOY_BUTTON_B, JOY_BUTTON_BACK]:
				_menu_back()
				return true
			if event.button_index == JOY_BUTTON_START:
				_set_overlay_mode("")
				emit_signal("action_triggered", "start")
				return true
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP, KEY_W]:
			_menu_move(-1)
			return true
		if event.keycode in [KEY_DOWN, KEY_S]:
			_menu_move(1)
			return true
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			_menu_accept()
			return true
		if event.keycode in [KEY_ESCAPE, KEY_BACKSPACE]:
			_menu_back()
			return true
		if event.keycode == KEY_TAB:
			_set_overlay_mode("settings" if overlay_mode != "settings" else "start")
			return true
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_UP:
			_menu_move(-1)
			return true
		if event.button_index == JOY_BUTTON_DPAD_DOWN:
			_menu_move(1)
			return true
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
			_menu_accept()
			return true
		if event.button_index in [JOY_BUTTON_B, JOY_BUTTON_BACK]:
			_menu_back()
			return true
	elif event is InputEventJoypadMotion and menu_axis_cooldown <= 0.0:
		if event.axis == JOY_AXIS_LEFT_Y and abs(event.axis_value) > 0.65:
			_menu_move(1 if event.axis_value > 0.0 else -1)
			menu_axis_cooldown = 0.18
			return true
		if event.axis == JOY_AXIS_RIGHT_Y and abs(event.axis_value) > 0.2:
			if overlay_mode == "settings" and settings_scroll and settings_scroll.visible:
				settings_scroll.scroll_vertical += int(event.axis_value * 40)
			return true
	return false

func _menu_move(step: int):
	var items = _get_current_items()
	if items.is_empty():
		return
	selected_menu_index = (selected_menu_index + step + items.size()) % items.size()
	_update_menu_overlay()

func _menu_accept():
	var items = _get_current_items()
	if items.is_empty():
		return
	var item = items[selected_menu_index]
	if not item.has("action"):
		return
	var a = item.action
	if a == "start":
		_save_settings()
		_set_overlay_mode("")
		emit_signal("action_triggered", "start")
	elif a == "exit_hub":
		_exit_to_hub()
	elif a == "help":
		_set_overlay_mode("help")
	elif a == "settings":
		_set_overlay_mode("settings")
	elif a == "back":
		_menu_back()
	else:
		emit_signal("action_triggered", a)

func _menu_back():
	if overlay_mode == "start":
		return
	_set_overlay_mode("start")

func _get_current_items() -> Array:
	var items = []
	if overlay_mode == "help":
		items.append({"label": "Back", "action": "back"})
		items.append({"label": "Start Game", "action": "start"})
	elif overlay_mode == "start":
		items.append({"label": "Start Game", "action": "start"})
		items.append({"label": "Help", "action": "help"})
		items.append({"label": "Settings", "action": "settings"})
		items.append({"label": "Back to Hub", "action": "exit_hub"})
		for a in registered_actions:
			if a.mode == "start" or a.mode == "all":
				items.append({"label": a.label, "action": a.id})
	return items

func _update_menu_overlay():
	var items = _get_current_items()
	if items.size() > 0:
		selected_menu_index = clamp(selected_menu_index, 0, items.size() - 1)
	var title = level_name
	var subtitle = "Projection-ready play with per-level tuning."
	var hint = "Click or A / Start / Enter selects. D-Pad / arrows move."
	var lines = []
	if overlay_mode == "settings":
		title = level_name + " SETTINGS"
		subtitle = "Mouse, controller, or keyboard. Changes apply live."
		hint = "Drag sliders or click toggles. Esc or Tab returns."
	elif overlay_mode == "help":
		title = level_name + " HELP"
		subtitle = "Adjust your setup and controls."
		hint = "Click or A / Start confirms. B / Escape goes back."
		for i in range(items.size()):
			lines.append(_menu_line(items, i))
	else:
		for i in range(items.size()):
			lines.append(_menu_line(items, i))
	var scene_level_line = _scene_level_subtitle()
	if scene_level_line != "":
		subtitle = scene_level_line + "\n" + subtitle
	menu_title_label.text = title
	menu_subtitle_label.text = subtitle
	menu_hint_label.text = hint
	for i in range(menu_labels.size()):
		var label = menu_labels[i] as Label
		var has_menu_item = overlay_mode != "settings" and i < lines.size()
		label.visible = overlay_mode != "settings"
		label.text = lines[i] if has_menu_item else ""
		label.mouse_filter = Control.MOUSE_FILTER_STOP if has_menu_item else Control.MOUSE_FILTER_IGNORE
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_menu_item else Control.CURSOR_ARROW
		label.add_theme_color_override("font_color", Color.WHITE)
		if i < lines.size() and lines[i].begins_with(">"):
			label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

func _menu_line(items: Array, index: int) -> String:
	var prefix = "> " if index == selected_menu_index else "  "
	return prefix + str(items[index].get("label", ""))

func _rebuild_settings_controls():
	if settings_box == null:
		return
	settings_controls.clear()
	for child in settings_box.get_children():
		child.queue_free()
	var current_group = ""
	var current_body: VBoxContainer = null
	for knob in registered_knobs:
		var group = str(knob.get("group", "General"))
		if group != current_group:
			current_group = group
			var section = _build_group_section(group)
			settings_box.add_child(section)
			current_body = section.get_meta("body")
		if current_body != null:
			current_body.add_child(_build_knob_row(knob))
	settings_box.add_child(_action_button("Start Game", "start"))
	settings_box.add_child(_action_button("Back to Hub", "exit_hub"))
	settings_box.add_child(_action_button("Back", "back"))
	_chain_settings_focus()

func _build_group_section(text: String) -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var header = Button.new()
	header.text = _group_header_text(text)
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.flat = true
	header.focus_mode = Control.FOCUS_ALL
	header.add_theme_color_override("font_color", Color(1.0, 0.86, 0.24))
	header.add_theme_font_size_override("font_size", 18)
	box.add_child(header)
	var divider = ColorRect.new()
	divider.color = Color(1.0, 0.84, 0.2, 0.35)
	divider.custom_minimum_size = Vector2(0, 1)
	box.add_child(divider)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.visible = not bool(collapsed_groups.get(text, false))
	box.add_child(body)
	box.set_meta("body", body)
	header.pressed.connect(func():
		var next_state = not bool(collapsed_groups.get(text, false))
		collapsed_groups[text] = next_state
		body.visible = not next_state
		header.text = _group_header_text(text)
		_chain_settings_focus()
	)
	# Left = collapse, Right = expand via controller / keyboard
	header.gui_input.connect(func(event):
		var want_collapse = false
		var want_expand = false
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_LEFT]:
				want_collapse = true
			elif event.keycode in [KEY_RIGHT]:
				want_expand = true
		elif event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_DPAD_LEFT:
				want_collapse = true
			elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
				want_expand = true
		if want_collapse and not bool(collapsed_groups.get(text, false)):
			collapsed_groups[text] = true
			body.visible = false
			header.text = _group_header_text(text)
			_chain_settings_focus()
			header.accept_event()
		elif want_expand and bool(collapsed_groups.get(text, false)):
			collapsed_groups[text] = false
			body.visible = true
			header.text = _group_header_text(text)
			_chain_settings_focus()
			header.accept_event()
	)
	return box

func _group_header_text(text: String) -> String:
	var collapsed = bool(collapsed_groups.get(text, false))
	return ("> " if collapsed else "v ") + text.to_upper()

func _build_knob_row(knob: Dictionary) -> Control:
	var outer = VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 6)
	var top = HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 12)
	outer.add_child(top)
	var label = Label.new()
	label.text = str(knob.label)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 22)
	top.add_child(label)
	
	if knob.id == "tunnel_fill":
		var indicator = Control.new()
		indicator.custom_minimum_size = Vector2(28, 28)
		indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		indicator.draw.connect(func():
			var center = indicator.size * 0.5
			var r = 10.0
			indicator.draw_circle(center, r, Color(0.16, 0.55, 1.0))
			var offset = 4.0
			indicator.draw_line(center + Vector2(-offset, -offset), center + Vector2(offset, offset), Color.WHITE, 2.0)
			indicator.draw_line(center + Vector2(offset, -offset), center + Vector2(-offset, offset), Color.WHITE, 2.0)
		)
		top.add_child(indicator)
		
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	
	var value_label = Label.new()
	value_label.text = _format_knob(knob)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(160, 0)
	value_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	value_label.add_theme_font_size_override("font_size", 20)
	top.add_child(value_label)
	var control = _build_knob_control(knob, value_label)
	if control != null:
		outer.add_child(control)
	settings_controls[knob.id] = {"value_label": value_label, "control": control}
	return outer

func _build_knob_control(knob: Dictionary, value_label: Label) -> Control:
	if knob.type == "bool":
		var toggle = CheckBox.new()
		toggle.text = "Enabled"
		toggle.button_pressed = bool(knob.value)
		toggle.add_theme_font_size_override("font_size", 20)
		toggle.toggled.connect(func(pressed): _apply_knob_from_control(knob, pressed, value_label))
		return toggle
	if knob.type == "enum":
		var options = OptionButton.new()
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options.add_theme_font_size_override("font_size", 20)
		for item in knob.options:
			options.add_item(str(item))
		var idx = knob.options.find(knob.value)
		options.selected = max(0, idx)
		options.item_selected.connect(func(selected): _apply_knob_from_control(knob, str(knob.options[selected]), value_label))
		return options
	var slider_row = HBoxContainer.new()
	slider_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.add_theme_constant_override("separation", 12)
	var min_label = Label.new()
	min_label.text = str(knob.min)
	min_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.8))
	slider_row.add_child(min_label)
	var slider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = float(knob.min)
	slider.max_value = float(knob.max)
	slider.step = float(knob.step)
	slider.value = float(knob.value)
	var slider_focus_style = StyleBoxFlat.new()
	slider_focus_style.bg_color = Color(0, 0, 0, 0)
	slider_focus_style.border_color = Color(0.16, 0.55, 1.0, 1.0)
	slider_focus_style.border_width_left = 3
	slider_focus_style.border_width_top = 3
	slider_focus_style.border_width_right = 3
	slider_focus_style.border_width_bottom = 3
	slider_focus_style.corner_radius_top_left = 6
	slider_focus_style.corner_radius_top_right = 6
	slider_focus_style.corner_radius_bottom_left = 6
	slider_focus_style.corner_radius_bottom_right = 6
	slider_focus_style.expand_margin_left = 4
	slider_focus_style.expand_margin_top = 6
	slider_focus_style.expand_margin_right = 4
	slider_focus_style.expand_margin_bottom = 6
	slider.add_theme_stylebox_override("focus", slider_focus_style)
	var slider_grabber_area_highlight = StyleBoxFlat.new()
	slider_grabber_area_highlight.bg_color = Color(0.16, 0.55, 1.0, 0.9)
	slider_grabber_area_highlight.corner_radius_top_left = 3
	slider_grabber_area_highlight.corner_radius_top_right = 3
	slider_grabber_area_highlight.corner_radius_bottom_left = 3
	slider_grabber_area_highlight.corner_radius_bottom_right = 3
	var slider_grabber_area_normal = StyleBoxFlat.new()
	slider_grabber_area_normal.bg_color = Color(0.16, 0.55, 1.0, 0.55)
	slider_grabber_area_normal.corner_radius_top_left = 3
	slider_grabber_area_normal.corner_radius_top_right = 3
	slider_grabber_area_normal.corner_radius_bottom_left = 3
	slider_grabber_area_normal.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("grabber_area", slider_grabber_area_normal)
	slider.add_theme_stylebox_override("grabber_area_highlight", slider_grabber_area_highlight)
	slider.focus_entered.connect(func(): slider.add_theme_stylebox_override("grabber_area", slider_grabber_area_highlight))
	slider.focus_exited.connect(func(): slider.add_theme_stylebox_override("grabber_area", slider_grabber_area_normal))
	slider.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			slider.accept_event()
	)
	slider.value_changed.connect(func(v): _apply_knob_from_control(knob, int(round(v)) if knob.type == "int" else v, value_label))
	slider_row.add_child(slider)
	var max_label = Label.new()
	max_label.text = str(knob.max)
	max_label.add_theme_color_override("font_color", Color(0.62, 0.7, 0.8))
	slider_row.add_child(max_label)
	return slider_row

func _action_button(text: String, action_id: String) -> Control:
	var button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): 
		if action_id == "start":
			_save_settings()
			_set_overlay_mode("")
			emit_signal("action_triggered", "start")
		elif action_id == "exit_hub":
			_exit_to_hub()
		elif action_id == "back":
			_menu_back()
		else:
			emit_signal("action_triggered", action_id)
	)
	return button

func _exit_to_hub():
	_save_settings()
	emit_signal("action_triggered", "exit_hub")
	get_tree().quit()

func _apply_knob_from_control(knob: Dictionary, raw_value, value_label: Label):
	if knob.type == "float":
		knob.value = clamp(float(raw_value), float(knob.min), float(knob.max))
	elif knob.type == "int":
		knob.value = clamp(int(raw_value), int(knob.min), int(knob.max))
	elif knob.type == "bool":
		knob.value = bool(raw_value)
	elif knob.type == "enum":
		knob.value = str(raw_value)
	value_label.text = _format_knob(knob)
	_save_settings()
	emit_signal("knob_changed", knob.id, knob.value)

func _format_knob(k: Dictionary) -> String:
	if k.type == "bool":
		return "On" if k.value else "Off"
	elif k.type == "float":
		if k.id.ends_with("_opacity") or k.id.ends_with("_alpha") or k.id.ends_with("_mix") or k.id.ends_with("_scale"):
			return str(int(round(float(k.value) * 100.0))) + "%"
		return str(snapped(float(k.value), 0.01))
	elif k.type == "int":
		return str(k.value)
	elif k.type == "enum":
		return str(k.value)
	return str(k.value)

func _parse_simple_yaml(path: String) -> Dictionary:
	var data = {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return data
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("#") or line == "":
			continue
		if ":" in line:
			var parts = line.split(":", true, 1)
			var key = parts[0].strip_edges()
			var val = parts[1].strip_edges()
			if (val.begins_with("\"") and val.ends_with("\"")) or (val.begins_with("'") and val.ends_with("'")):
				val = val.substr(1, val.length() - 2)
			data[key] = val
	return data

func _level_adjustment_key() -> String:
	var info = {}
	if level_dir != "":
		info = _parse_simple_yaml(level_dir.path_join("level.yaml"))
	var scene_id = str(info.get("scene_id", ""))
	var level_id = str(info.get("level_id", ""))
	if scene_id == "":
		scene_id = level_dir.get_base_dir().get_file() if level_dir != "" else "unknown_scene"
	if level_id == "":
		level_id = level_dir.get_file() if level_dir != "" else "unknown_level"
	return scene_id + "/" + level_id

func _scene_level_subtitle() -> String:
	if level_dir == "":
		return ""
	var info = _parse_simple_yaml(level_dir.path_join("level.yaml"))
	var scene_id = str(info.get("scene_id", ""))
	var scene_name = str(info.get("scene_name", ""))
	var level_id = str(info.get("level_id", ""))
	var level_label = str(info.get("name", ""))
	if scene_id == "":
		var level_parent = level_dir.get_base_dir()
		scene_id = level_parent.get_base_dir().get_file() if level_parent.get_file().to_lower() == "levels" else level_parent.get_file()
	if level_id == "":
		level_id = level_dir.get_file()
	if scene_name == "":
		scene_name = _pretty_level_token(scene_id)
	if _is_placeholder_level_name(level_label):
		level_label = _numbered_level_title(level_id)
	elif level_label == "":
		level_label = _numbered_level_title(level_id)
	var res_str = _get_level_bg_res(level_dir)
	var suffix = ""
	if res_str != "":
		suffix = "   RES: " + res_str
	return "Scene: %s   Level: %s%s" % [scene_name, level_label, suffix]

func _get_level_bg_res(dir: String) -> String:
	if dir == "": return ""
	var img_names = ["background.png", "background.jpg", "background.jpeg", "thumbnail.png", "thumbnail.jpg", "thumbnail.jpeg", "reference.png", "reference.jpg", "reference.jpeg", "photo.png", "photo.jpg", "photo.jpeg"]
	for n in img_names:
		var p = dir.path_join(n)
		if FileAccess.file_exists(p):
			var img = Image.load_from_file(p)
			if img: return str(img.get_width()) + "x" + str(img.get_height())

	var parent = dir.get_base_dir()
	var scene_dir = parent.get_base_dir() if parent.get_file().to_lower() == "levels" else parent
	for n in img_names:
		var p = scene_dir.path_join(n)
		if FileAccess.file_exists(p):
			var img = Image.load_from_file(p)
			if img: return str(img.get_width()) + "x" + str(img.get_height())
	return ""

func _pretty_level_token(text: String) -> String:
	var cleaned = text.strip_edges().replace("\\", "/")
	if cleaned.contains("/"):
		cleaned = cleaned.get_file()
	cleaned = cleaned.replace("_", " ").replace("-", " ").strip_edges()
	if cleaned == "":
		return "Unknown"
	var words = cleaned.split(" ", false)
	for i in range(words.size()):
		var w = str(words[i])
		if w == "":
			continue
		words[i] = w.substr(0, 1).to_upper() + w.substr(1)
	return " ".join(words)

func _is_placeholder_level_name(text: String) -> bool:
	var normalized = text.strip_edges().to_lower()
	return normalized == "" or normalized in ["authored level", "untitled", "new level"]

func _numbered_level_title(level_id: String) -> String:
	var title = _pretty_level_token(level_id)
	var number = _level_display_index(level_id)
	if number <= 0:
		return title
	return "%d %s" % [number, title]

func _level_display_index(level_id: String) -> int:
	if level_dir == "":
		return -1
	var levels_root = level_dir.get_base_dir()
	if levels_root == "":
		return -1
	var dir = DirAccess.open(levels_root)
	if dir == null:
		return -1
	var all_levels = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with(".") and file_name != "derived":
			all_levels.append(file_name)
		file_name = dir.get_next()
	all_levels.sort_custom(func(a, b):
		return _pretty_level_token(str(a)).to_lower() < _pretty_level_token(str(b)).to_lower()
	)
	for idx in range(all_levels.size()):
		if str(all_levels[idx]) == level_id:
			return idx + 1
	return -1

func _level_edit_dir() -> String:
	if level_dir == "":
		return ""
	return level_dir.path_join("level_edit")

func _level_adjustments_path() -> String:
	var edit_dir = _level_edit_dir()
	if edit_dir != "":
		DirAccess.make_dir_recursive_absolute(edit_dir)
		return edit_dir.path_join(cartridge_id + ".adjustments.json")
	return "user://level_adjustments.json"

func _load_settings():
	var path = _level_adjustments_path()
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var settings = parsed.get("settings", {})
	if typeof(settings) != TYPE_DICTIONARY:
		var levels = parsed.get("levels", {})
		if typeof(levels) != TYPE_DICTIONARY:
			return
		settings = levels.get(_level_adjustment_key(), {})
	if typeof(settings) != TYPE_DICTIONARY:
		return
	for k in registered_knobs:
		if settings.has(k.id):
			if k.type == "float":
				k.value = float(settings[k.id])
			elif k.type == "int":
				k.value = int(settings[k.id])
			elif k.type == "bool":
				k.value = bool(settings[k.id])
			elif k.type == "enum":
				k.value = str(settings[k.id])
			emit_signal("knob_changed", k.id, k.value)

func _save_settings():
	if level_dir == "":
		return
	var path = _level_adjustments_path()
	var registry = {
		"schema": "cartridge_level_edit_adjustments",
		"version": "1.0.0",
		"cartridge_id": cartridge_id,
		"scene_level": _level_adjustment_key(),
		"settings": {}
	}
	if FileAccess.file_exists(path):
		var read_file = FileAccess.open(path, FileAccess.READ)
		if read_file:
			var parsed = JSON.parse_string(read_file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				registry = parsed
	registry["cartridge_id"] = cartridge_id
	registry["scene_level"] = _level_adjustment_key()
	var settings = {}
	for k in registered_knobs:
		settings[k.id] = k.value
	registry["settings"] = settings
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(registry, "  "))


func _focus_first(node: Node) -> bool:
	if node.is_queued_for_deletion():
		return false
	if node is Control and node.focus_mode == Control.FOCUS_ALL and node.visible:
		node.grab_focus()
		return true
	for child in node.get_children():
		if _focus_first(child):
			return true
	return false

func _focus_first_settings_control():
	if menu_reset_button and menu_reset_button.visible:
		menu_reset_button.grab_focus()
		return
	if settings_box:
		_focus_first(settings_box)

func _chain_settings_focus():
	var focusables = []
	if menu_reset_button and menu_reset_button.visible:
		focusables.append(menu_reset_button)
	if settings_box:
		_collect_settings_focusables(settings_box, focusables)
	if focusables.size() < 2:
		return
	for i in range(focusables.size()):
		var control = focusables[i] as Control
		if control == null or not is_instance_valid(control):
			continue
		var previous = focusables[(i - 1 + focusables.size()) % focusables.size()] as Control
		var next = focusables[(i + 1) % focusables.size()] as Control
		if previous != null and is_instance_valid(previous):
			control.focus_neighbor_top = control.get_path_to(previous)
		if next != null and is_instance_valid(next):
			control.focus_neighbor_bottom = control.get_path_to(next)
		if not control.has_meta("focus_connected"):
			control.focus_entered.connect(func():
				if settings_scroll and is_instance_valid(settings_scroll) and is_instance_valid(control) and settings_scroll.is_ancestor_of(control):
					settings_scroll.ensure_control_visible(control)
			)
			control.set_meta("focus_connected", true)

func _collect_settings_focusables(node: Node, focusables: Array):
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	if node is Control:
		var control = node as Control
		if control.focus_mode == Control.FOCUS_ALL and control.visible and control.is_visible_in_tree():
			focusables.append(control)
	for child in node.get_children():
		_collect_settings_focusables(child, focusables)
