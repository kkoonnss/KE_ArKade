extends Control

const WINDOW_STATE_PATH = "user://hub_window_state.json"
const WINDOW_STATE_SAVE_INTERVAL = 0.75

@onready var launcher = $Launcher
@onready var scenes_grid = $UI/Content/MainPanel/ScrollContainer/ScenesGrid
@onready var restore_btn = $UI/Content/SideNav/RestoreBtn

var last_known_scene = ""
var last_known_level = ""
var last_known_cartridge = ""

var current_scene = ""
var ipc_log_lines = []
var viewing_levels = false
var last_launch_time = 0.0
var color_black = Color(0, 0, 0, 1)
var color_surface1 = Color(0.04, 0.04, 0.04, 1) # #0A0A0A
var color_surface2 = Color(0.07, 0.08, 0.09, 1) # #111418
var color_ink_white = Color(1, 1, 1, 1)
var color_ink_dim = Color(0.6, 0.63, 0.65, 1) # #9AA0A6
var color_cyan = Color(0.0, 0.9, 1.0, 1) # #00E5FF
var color_border_default = Color(1, 1, 1, 0.14)
var style_panel: StyleBoxFlat
var style_btn_normal: StyleBoxFlat
var style_btn_hover: StyleBoxFlat
var style_btn_pressed: StyleBoxFlat
var style_nav_normal: StyleBoxFlat
var style_nav_active: StyleBoxFlat


var launch_dialog: ColorRect
var level_title_label: Label
var cartridge_buttons_container: Container
var selected_level_name = ""
var favorite_cartridges: Array = ["tetris", "pacman", "bomberman", "frogger", "asteroids"]
var sort_favorites_first: bool = true
var current_tab = ""
var tab_header_bar: HBoxContainer
var sort_fav_checkbox: CheckBox
var dialog_sort_fav_checkbox: CheckBox
var selected_skins: Dictionary = {}
var _updating_main_checkbox = false
var _updating_dialog_checkbox = false
var scroll_vbox: VBoxContainer
var active_nav_btn: Button = null
var dialog_scroll_vbox: VBoxContainer
var _in_refresh_card_views: bool = false
var games_overlay: ColorRect = null
var _pending_menu_focus: Control = null
var _game_title_focus_buttons: Array = []
var _last_nav_focus: Control = null
var _last_content_focus: Control = null
var target_columns: int = 4
var hub_card_scale: float = 1.0
var scale_slider: HSlider = null
var _window_state_timer: float = 0.0
var _windowed_position: Vector2i = Vector2i(80, 80)
var _windowed_size: Vector2i = Vector2i(1280, 720)
var _window_fullscreen: bool = false

var _resize_timer: Timer

func _ready():
	set_process_input(true)
	set_process(true)
	_ensure_hub_input_actions()
	_load_window_state()
	if scenes_grid is GridContainer: scenes_grid.columns = _calculate_grid_columns()
	
	_resize_timer = Timer.new()
	_resize_timer.one_shot = true
	_resize_timer.wait_time = 0.1
	_resize_timer.timeout.connect(_update_scale_from_columns)
	add_child(_resize_timer)
	
	get_viewport().size_changed.connect(func(): _resize_timer.start())
	# Initialize scroll_vbox to wrap ScenesGrid
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	if scroll_container and scenes_grid:
		scroll_container.remove_child(scenes_grid)
		var content_margin = MarginContainer.new()
		content_margin.add_theme_constant_override("margin_left", 32)
		content_margin.add_theme_constant_override("margin_right", 32)
		content_margin.add_theme_constant_override("margin_top", 32)
		content_margin.add_theme_constant_override("margin_bottom", 32)
		content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_container.add_child(content_margin)

		scroll_vbox = VBoxContainer.new()
		scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_theme_constant_override("separation", 24)
		content_margin.add_child(scroll_vbox)

		scroll_vbox.add_child(scenes_grid)
		scenes_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scenes_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
	init_styling()
	load_favorites()
	if launcher: 
		launcher.cartridge_exited.connect(_on_cartridge_exited)
		launcher.ipc_log.connect(_on_ipc_log)
	
	if restore_btn: restore_btn.pressed.connect(_on_restore_pressed)
	
	var nav = $UI/Content/SideNav
	if nav.has_node("ScenesBtn"): nav.get_node("ScenesBtn").pressed.connect(display_scenes)
	if nav.has_node("GamesBtn"): nav.get_node("GamesBtn").pressed.connect(display_games)
	if nav.has_node("LevelsBtn"): nav.get_node("LevelsBtn").pressed.connect(display_levels)
	if nav.has_node("DesignBtn"): nav.get_node("DesignBtn").pressed.connect(_on_design_nav_pressed)
	if nav.has_node("CalibrateBtn"): nav.get_node("CalibrateBtn").pressed.connect(_on_launch_calibration_tool)
	if nav.has_node("TestPatternBtn"): nav.get_node("TestPatternBtn").pressed.connect(_on_test_pattern_pressed)
	if nav.has_node("ServiceBtn"): nav.get_node("ServiceBtn").pressed.connect(_on_log_pressed)
	if nav.has_node("HelpBtn"): nav.get_node("HelpBtn").pressed.connect(_on_help_pressed)
	
	if nav.has_node("SettingsBtn"): nav.get_node("SettingsBtn").pressed.connect(display_settings)
	
	if nav.has_node("SortFavBtn"): nav.get_node("SortFavBtn").toggled.connect(_on_sort_favorites_toggled)
	
	var nav_buttons = []
	for btn_name in ["ScenesBtn", "LevelsBtn", "GamesBtn", "DesignBtn", "CalibrateBtn", "SettingsBtn", "HelpBtn"]:
		if nav.has_node(btn_name):
			nav_buttons.append(nav.get_node(btn_name))
	for i in range(nav_buttons.size()):
		var btn = nav_buttons[i]
		if i > 0:
			btn.focus_neighbor_top = btn.get_path_to(nav_buttons[i-1])
		if i < nav_buttons.size() - 1:
			btn.focus_neighbor_bottom = btn.get_path_to(nav_buttons[i+1])
		btn.focus_entered.connect(func(): _last_nav_focus = btn)
	if nav_buttons.size() > 0:
		nav_buttons[0].focus_neighbor_top = nav_buttons[0].get_path_to(nav_buttons[-1])
		nav_buttons[-1].focus_neighbor_bottom = nav_buttons[-1].get_path_to(nav_buttons[0])
	
	_update_scale_from_columns()
	display_scenes()

func _ensure_hub_input_actions():
	_ensure_action_key("ui_left", KEY_LEFT)
	_ensure_action_key("ui_left", KEY_A)
	_ensure_action_key("ui_right", KEY_RIGHT)
	_ensure_action_key("ui_right", KEY_D)
	_ensure_action_key("ui_up", KEY_UP)
	_ensure_action_key("ui_up", KEY_W)
	_ensure_action_key("ui_down", KEY_DOWN)
	_ensure_action_key("ui_down", KEY_S)
	_ensure_action_key("ui_accept", KEY_ENTER)
	_ensure_action_key("ui_accept", KEY_SPACE)
	_ensure_action_key("ui_cancel", KEY_ESCAPE)
	_ensure_action_joy_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_action_joy_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_ensure_action_joy_button("ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_action_joy_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_ensure_action_joy_button("ui_accept", JOY_BUTTON_A)
	_ensure_action_joy_button("ui_cancel", JOY_BUTTON_B)
	_ensure_action_joy_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_action_joy_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_action_joy_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_action_joy_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_window_state()

func _ensure_action(action_name: String):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)

func _ensure_action_key(action_name: String, keycode: int):
	_ensure_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.keycode == keycode:
			return
	var event = InputEventKey.new()
	event.device = -1
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

func _ensure_action_joy_button(action_name: String, button_index: int):
	_ensure_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventJoypadButton and existing.button_index == button_index:
			return
	var event = InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

func _ensure_action_joy_axis(action_name: String, axis: int, axis_value: float):
	_ensure_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventJoypadMotion and existing.axis == axis and sign(existing.axis_value) == sign(axis_value):
			return
	var event = InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)

func clear_main_panel():
	_clear_games_overlay()
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	if scroll_container:
		scroll_container.visible = true
	for child in $UI/Content/MainPanel.get_children():
		if child != scroll_container:
			child.queue_free()
	for child in scenes_grid.get_children():
		child.queue_free()
	_prepare_scroll_view(true)

func set_active_nav(active_btn: Button):
	active_nav_btn = active_btn

func _reset_menu_focus():
	_pending_menu_focus = null

func _remember_menu_focus(control: Control):
	if control == null:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	if _pending_menu_focus == null:
		_pending_menu_focus = control

func _prefer_menu_focus(control: Control):
	if control == null:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	_pending_menu_focus = control

func _chain_horizontal_focus(buttons: Array, columns: int = 4):
	var fallback_nav = get_node_or_null("UI/Content/SideNav/ScenesBtn")
	var target_nav = _last_nav_focus if (_last_nav_focus and is_instance_valid(_last_nav_focus)) else fallback_nav

	for i in range(buttons.size()):
		var button = buttons[i] as Control
		if button == null or not is_instance_valid(button):
			continue
		if i > 0 and (i % columns) != 0:
			var previous = buttons[i - 1] as Control
			if previous != null and is_instance_valid(previous):
				button.focus_neighbor_left = button.get_path_to(previous)
		else:
			if target_nav and is_instance_valid(target_nav):
				button.focus_neighbor_left = button.get_path_to(target_nav)
			else:
				button.focus_neighbor_left = NodePath()
			
		if i < buttons.size() - 1 and ((i + 1) % columns) != 0:
			var next = buttons[i + 1] as Control
			if next != null and is_instance_valid(next):
				button.focus_neighbor_right = button.get_path_to(next)
		else:
			button.focus_neighbor_right = NodePath()

func _wire_vertical_focus_neighbors(buttons: Array, columns: int):
	for i in range(buttons.size()):
		var button = buttons[i] as Control
		if button == null or not is_instance_valid(button):
			continue
		if i - columns >= 0:
			var up = buttons[i - columns] as Control
			if up != null and is_instance_valid(up):
				button.focus_neighbor_top = button.get_path_to(up)
		else:
			var target_idx = i
			while target_idx + columns < buttons.size():
				target_idx += columns
			var bottom_btn = buttons[target_idx] as Control
			if bottom_btn != null and is_instance_valid(bottom_btn):
				button.focus_neighbor_top = button.get_path_to(bottom_btn)
				
		if i + columns < buttons.size():
			var down = buttons[i + columns] as Control
			if down != null and is_instance_valid(down):
				button.focus_neighbor_bottom = button.get_path_to(down)
		else:
			var target_idx = i
			while target_idx - columns >= 0:
				target_idx -= columns
			var top_btn = buttons[target_idx] as Control
			if top_btn != null and is_instance_valid(top_btn):
				button.focus_neighbor_bottom = button.get_path_to(top_btn)

func _wire_auto_scroll(buttons: Array, scroll_container: ScrollContainer):
	if scroll_container == null:
		return
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	for b in buttons:
		var button = b as Control
		if button == null or not is_instance_valid(button):
			continue
		button.focus_entered.connect(func():
			_last_content_focus = button
			if _in_refresh_card_views:
				return
			if is_instance_valid(button) and is_instance_valid(scroll_container):
				var offset = (button.global_position.y + button.size.y / 2.0) - (scroll_container.global_position.y + scroll_container.size.y / 2.0)
				var target_scroll = scroll_container.scroll_vertical + offset
				var max_scroll = scroll_container.get_v_scroll_bar().max_value - scroll_container.size.y
				target_scroll = clamp(target_scroll, 0, max_scroll)
				if target_scroll < 0: target_scroll = 0
				
				var tween = scroll_container.create_tween()
				tween.tween_property(scroll_container, "scroll_vertical", target_scroll, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)

func _focus_current_menu():
	call_deferred("_grab_current_menu_focus")

func _grab_current_menu_focus():
	if _grab_focus_if_valid(_pending_menu_focus):
		return
	if games_overlay != null and is_instance_valid(games_overlay):
		if _grab_first_focusable(games_overlay):
			return
	var main_panel = get_node_or_null("UI/Content/MainPanel")
	if main_panel and _grab_first_focusable(main_panel):
		return
	var nav = get_node_or_null("UI/Content/SideNav")
	if nav:
		_grab_first_focusable(nav)

func _grab_focus_if_valid(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		return false
	if control.focus_mode == Control.FOCUS_NONE:
		return false
	control.grab_focus()
	return true

func _grab_first_focusable(node: Node) -> bool:
	if _grab_first_focusable_button(node):
		return true
	return _grab_first_focusable_control(node)

func _grab_first_focusable_button(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node is Control:
		var control := node as Control
		if control is BaseButton and control.is_inside_tree() and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
			control.grab_focus()
			return true
	for child in node.get_children():
		if _grab_first_focusable_button(child):
			return true
	return false

func _grab_first_focusable_control(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node is Control:
		var control := node as Control
		if control.is_inside_tree() and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
			control.grab_focus()
			return true
	for child in node.get_children():
		if _grab_first_focusable_control(child):
			return true
	return false

func _process(delta):
	_poll_window_state(delta)
	if launcher and launcher.running:
		return
	var scroll_container = get_node_or_null("UI/Content/MainPanel/ScrollContainer")
	if scroll_container:
		var right_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if abs(right_y) > 0.2:
			scroll_container.scroll_vertical += int(right_y * 1000 * delta)

func _is_focus_recovery_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")

func _is_fullscreen_toggle_event(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return false
	return event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed)

func _input(event: InputEvent):
	if _is_fullscreen_toggle_event(event):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return

	if launcher and launcher.running:
		return
	
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_RIGHT_Y:
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		_handle_hub_cancel()
		get_viewport().set_input_as_handled()
		return

	var owner = get_viewport().gui_get_focus_owner()
	var in_sidenav = owner != null and owner.get_parent() != null and owner.get_parent().name == "SideNav"

	if event.is_action_pressed("ui_right") and in_sidenav:
		if _last_content_focus and is_instance_valid(_last_content_focus) and _last_content_focus.is_inside_tree() and _last_content_focus.is_visible_in_tree():
			_last_content_focus.grab_focus()
		else:
			var main_panel = get_node_or_null("UI/Content/MainPanel")
			if main_panel: _grab_first_focusable(main_panel)
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("ui_accept") and in_sidenav:
		if owner is Button:
			owner.pressed.emit()
		if _last_content_focus and is_instance_valid(_last_content_focus) and _last_content_focus.is_inside_tree() and _last_content_focus.is_visible_in_tree():
			_last_content_focus.grab_focus()
		else:
			var main_panel = get_node_or_null("UI/Content/MainPanel")
			if main_panel: _grab_first_focusable(main_panel)
		get_viewport().set_input_as_handled()
		return

	if not _is_focus_recovery_event(event):
		return
	if owner == null or not is_instance_valid(owner) or not owner.is_visible_in_tree():
		_focus_current_menu()

func _is_fullscreen_mode() -> bool:
	var mode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _load_window_state():
	if not FileAccess.file_exists(WINDOW_STATE_PATH):
		_capture_window_state()
		return
	var file = FileAccess.open(WINDOW_STATE_PATH, FileAccess.READ)
	if not file:
		_capture_window_state()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_capture_window_state()
		return
	_windowed_position = Vector2i(int(parsed.get("x", _windowed_position.x)), int(parsed.get("y", _windowed_position.y)))
	_windowed_size = Vector2i(max(320, int(parsed.get("w", _windowed_size.x))), max(240, int(parsed.get("h", _windowed_size.y))))
	_window_fullscreen = bool(parsed.get("fullscreen", false))
	_apply_window_state()

func _apply_window_state():
	if _window_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(_windowed_size)
	DisplayServer.window_set_position(_windowed_position)

func _capture_window_state():
	_window_fullscreen = _is_fullscreen_mode()
	if _window_fullscreen:
		return
	var size = DisplayServer.window_get_size()
	var pos = DisplayServer.window_get_position()
	if size.x >= 320 and size.y >= 240:
		_windowed_size = size
		_windowed_position = pos

func _poll_window_state(delta: float):
	_window_state_timer += delta
	if _window_state_timer < WINDOW_STATE_SAVE_INTERVAL:
		return
	_window_state_timer = 0.0
	var old_pos = _windowed_position
	var old_size = _windowed_size
	var old_fullscreen = _window_fullscreen
	_capture_window_state()
	if old_pos != _windowed_position or old_size != _windowed_size or old_fullscreen != _window_fullscreen:
		_save_window_state()

func _save_window_state():
	_capture_window_state()
	var data = {
		"version": 1,
		"fullscreen": _window_fullscreen,
		"x": _windowed_position.x,
		"y": _windowed_position.y,
		"w": _windowed_size.x,
		"h": _windowed_size.y
	}
	var file = FileAccess.open(WINDOW_STATE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))

func _toggle_fullscreen():
	if _is_fullscreen_mode():
		_window_fullscreen = false
		_apply_window_state()
	else:
		_capture_window_state()
		_window_fullscreen = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_save_window_state()

func _fullscreen_button_text() -> String:
	return "Exit Full Screen (F11)" if _is_fullscreen_mode() else "Full Screen (F11)"

func _game_window_launch_args() -> String:
	_capture_window_state()
	_save_window_state()
	if _window_fullscreen:
		return "--fullscreen"
	return "--windowed --position %d,%d --resolution %dx%d" % [_windowed_position.x, _windowed_position.y, _windowed_size.x, _windowed_size.y]

func _handle_hub_cancel():
	if games_overlay != null and is_instance_valid(games_overlay):
		_clear_games_overlay()
		_reset_menu_focus()
		_focus_current_menu()
		return
	if current_tab == "levels":
		display_scenes()
		return
	if current_tab == "games":
		if current_scene != "" and current_scene != "scene_classic_pack":
			display_levels(current_scene)
		else:
			display_scenes()
		return
	if current_tab == "scenes":
		var nav = get_node_or_null("UI/Content/SideNav")
		if _last_nav_focus and is_instance_valid(_last_nav_focus) and _last_nav_focus.is_inside_tree() and _last_nav_focus.is_visible_in_tree():
			_last_nav_focus.grab_focus()
		elif nav:
			_grab_first_focusable(nav)
		return
	_focus_current_menu()

func _calculate_grid_columns() -> int:
	return target_columns

func _update_scale_from_columns():
	var vp_width = get_viewport_rect().size.x
	var vp_height = get_viewport_rect().size.y
	# Fixed width: SideNav(300) + UI margins(128) + HBox separation(8) + Panel margins(16) + padding(8) = 460
	var available_width = vp_width - 460
	var card_width = float(available_width) / float(target_columns)
	hub_card_scale = (card_width - 16.0) / 260.0
	
	# Clamp scale to prevent cards from being taller than the available ScrollContainer height
	var max_scale = (vp_height - 186.0) / 380.0
	if hub_card_scale > max_scale:
		hub_card_scale = max_scale
		
	if hub_card_scale < 0.2: hub_card_scale = 0.2
	_refresh_card_views()

func display_settings():
	current_tab = "settings"
	viewing_levels = false
	_reset_menu_focus()
	clear_main_panel()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_child(vbox)
	
	var title = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", color_cyan)
	vbox.add_child(title)
	
	var focus_buttons = []
	
	var cols_btn = Button.new()
	cols_btn.text = "< (" + str(target_columns) + ") Columns >"
	cols_btn.custom_minimum_size = Vector2(400, 64)
	cols_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_grid_button(cols_btn)
	cols_btn.gui_input.connect(func(event):
		var go_left = false
		var go_right = false
		if event.is_action_pressed("ui_left", false, true):
			if not (event is InputEventJoypadMotion) or Input.is_action_just_pressed("ui_left"):
				go_left = true
		elif event.is_action_pressed("ui_right", false, true):
			if not (event is InputEventJoypadMotion) or Input.is_action_just_pressed("ui_right"):
				go_right = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if event.position.x < cols_btn.size.x * 0.3:
				go_left = true
				cols_btn.accept_event()
			elif event.position.x > cols_btn.size.x * 0.7:
				go_right = true
				cols_btn.accept_event()
				
		if go_left and target_columns > 1:
			target_columns -= 1
			cols_btn.text = "< (" + str(target_columns) + ") Columns >"
			_update_scale_from_columns()
			cols_btn.accept_event()
		elif go_right and target_columns < 6:
			target_columns += 1
			cols_btn.text = "< (" + str(target_columns) + ") Columns >"
			_update_scale_from_columns()
			cols_btn.accept_event()
	)
	vbox.add_child(cols_btn)
	focus_buttons.append(cols_btn)
	
	var fullscreen_btn = Button.new()
	fullscreen_btn.text = _fullscreen_button_text()
	fullscreen_btn.custom_minimum_size = Vector2(400, 64)
	fullscreen_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_grid_button(fullscreen_btn)
	fullscreen_btn.pressed.connect(func():
		_toggle_fullscreen()
		fullscreen_btn.text = _fullscreen_button_text()
	)
	vbox.add_child(fullscreen_btn)
	focus_buttons.append(fullscreen_btn)

	var log_btn = Button.new()
	log_btn.text = "View Log"
	log_btn.custom_minimum_size = Vector2(400, 64)
	log_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_grid_button(log_btn)
	log_btn.pressed.connect(_on_log_pressed)
	vbox.add_child(log_btn)
	focus_buttons.append(log_btn)
	
	var tp_btn = Button.new()
	tp_btn.text = "Test Pattern"
	tp_btn.custom_minimum_size = Vector2(400, 64)
	tp_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_grid_button(tp_btn)
	tp_btn.pressed.connect(_on_test_pattern_pressed)
	vbox.add_child(tp_btn)
	focus_buttons.append(tp_btn)
	
	var rest_btn = Button.new()
	rest_btn.text = "Restore Default Scene"
	rest_btn.custom_minimum_size = Vector2(400, 64)
	rest_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	style_grid_button(rest_btn)
	rest_btn.pressed.connect(_on_restore_pressed)
	vbox.add_child(rest_btn)
	focus_buttons.append(rest_btn)
	
	_chain_horizontal_focus(focus_buttons, 1)
	_wire_vertical_focus_neighbors(focus_buttons, 1)
	_wire_auto_scroll(focus_buttons, $UI/Content/MainPanel/ScrollContainer)
	_focus_current_menu()

func display_scenes():
	current_tab = "scenes"
	viewing_levels = false
	selected_level_name = ""
	_reset_menu_focus()
	clear_main_panel()
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/scenes")
	var dir = DirAccess.open(base_dir)
	var scenes = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."): 
				scenes.append(file_name)
			file_name = dir.get_next()
			
	scenes.sort_custom(func(a, b):
		var a_is_classic = (a == "scene_classic_pack" or "classic" in a.to_lower())
		var b_is_classic = (b == "scene_classic_pack" or "classic" in b.to_lower())
		if a_is_classic and not b_is_classic:
			return true
		if b_is_classic and not a_is_classic:
			return false
		return a < b
	)
	if scenes_grid: scenes_grid.columns = _calculate_grid_columns()
	var focus_buttons = []
	for i in range(scenes.size()):
		var prefer_focus = (scenes[i] == current_scene)
		focus_buttons.append(_create_level_card(scenes[i], base_dir, scenes_grid, i, true, prefer_focus))
	var cols = scenes_grid.columns if scenes_grid else 4
	_chain_horizontal_focus(focus_buttons, cols)
	_wire_vertical_focus_neighbors(focus_buttons, cols)
	_wire_auto_scroll(focus_buttons, $UI/Content/MainPanel/ScrollContainer)
	_focus_current_menu()
func style_grid_button(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 4
	style.border_color = Color(0.1, 0.1, 0.1, 1.0)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.1, 0.1, 0.12, 1.0)
	pressed.border_width_bottom = 0
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_font_size_override("font_size", 24)

func _on_scene_selected(scene_name: String):
	current_scene = scene_name
	if scene_name == "scene_classic_pack":
		selected_level_name = ""
		display_games()
	else:
		display_levels(scene_name)

func display_levels(specific_scene_name: String = ""):
	current_tab = "levels"
	viewing_levels = true
	_reset_menu_focus()
	clear_main_panel()
	if scenes_grid:
		scenes_grid.visible = false
	
	var scenes_dir_path = ProjectSettings.globalize_path("res://").path_join("../../content/scenes")
	var scenes_dir = DirAccess.open(scenes_dir_path)
	if not scenes_dir:
		return
		
	var scenes = []
	scenes_dir.list_dir_begin()
	var s_name = scenes_dir.get_next()
	while s_name != "":
		if scenes_dir.current_is_dir() and not s_name.begins_with("."):
			scenes.append(s_name)
		s_name = scenes_dir.get_next()
		
	scenes.sort()
	scenes.sort_custom(func(a, b):
		var a_is_classic = (a == "scene_classic_pack" or "classic" in a.to_lower())
		var b_is_classic = (b == "scene_classic_pack" or "classic" in b.to_lower())
		if a_is_classic and not b_is_classic:
			return true
		if b_is_classic and not a_is_classic:
			return false
		return a < b
	)
	
	var all_focus_buttons = []
	var first_header = null
	
	for scene_name in scenes:
		if specific_scene_name != "" and scene_name != specific_scene_name:
			continue
		var scene_dir_path = scenes_dir_path.path_join(scene_name)
		var nested_levels_dir_path = scene_dir_path.path_join("levels")
		var levels_dir_path = nested_levels_dir_path
		var l_dir = DirAccess.open(levels_dir_path)
		var use_root_level = l_dir == null and FileAccess.file_exists(scene_dir_path.path_join("level.yaml"))
		if use_root_level:
			levels_dir_path = scenes_dir_path
		
		var grid: GridContainer = null
		
		if specific_scene_name == "":
			# Build scene header for all-levels accordion view
			var header_btn = Button.new()
			var pretty_name = scene_name.replace("scene_", "").replace("_", " ").capitalize()
			header_btn.text = "▶ " + pretty_name
			header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			header_btn.add_theme_font_size_override("font_size", 28)
			header_btn.add_theme_color_override("font_color", color_cyan)
			header_btn.focus_mode = Control.FOCUS_ALL
			header_btn.custom_minimum_size = Vector2(0, 60)
			style_grid_button(header_btn)
			
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_top", 12)
			margin.add_theme_constant_override("margin_bottom", 12)
			margin.add_child(header_btn)
			scroll_vbox.add_child(margin)
			
			all_focus_buttons.append(header_btn)
			if first_header == null:
				first_header = header_btn
			
			grid = GridContainer.new()
			grid.columns = _calculate_grid_columns()
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 16)
			grid.visible = false
			scroll_vbox.add_child(grid)
			
			header_btn.pressed.connect(func():
				grid.visible = not grid.visible
				if grid.visible:
					header_btn.text = "▼ " + pretty_name
				else:
					header_btn.text = "▶ " + pretty_name
				_rebuild_levels_focus()
			)
		else:
			grid = GridContainer.new()
			grid.columns = _calculate_grid_columns()
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 16)
			grid.visible = true
			scroll_vbox.add_child(grid)

		
		var index = 0
		var level_buttons = []
		
		var raw_levels = []
		if use_root_level:
			raw_levels.append(scene_name)
		elif l_dir != null:
			l_dir.list_dir_begin()
			var file_name = l_dir.get_next()
			while file_name != "":
				if l_dir.current_is_dir() and not file_name.begins_with("."):
					raw_levels.append(file_name)
				file_name = l_dir.get_next()
			
		var process_levels = []
		if scene_name == "scene_classic_pack":
			var favs = []
			var others = []
			var all_carts = get_sorted_cartridges()
			var cart_map = {}
			for c in all_carts:
				cart_map[c.id] = c
				
			for lf in raw_levels:
				var cid = _cart_id_for_classic_level(lf)
				if cart_map.has(cid):
					var cart = cart_map[cid]
					if cart.favorite:
						favs.append({"file": lf, "cart": cart})
					else:
						others.append({"file": lf, "cart": cart})
				else:
					others.append({"file": lf, "cart": null})
			
			favs.sort_custom(func(a,b): return _get_cartridge_sort_name(a.cart.game_name) < _get_cartridge_sort_name(b.cart.game_name))
			others.sort_custom(func(a,b): 
				var name_a = a.file
				if a.cart: name_a = _get_cartridge_sort_name(a.cart.game_name)
				var name_b = b.file
				if b.cart: name_b = _get_cartridge_sort_name(b.cart.game_name)
				return name_a < name_b
			)
			
			for f in favs: process_levels.append({"file": f.file, "idx": f.cart.absolute_index})
			if favs.size() > 0 and others.size() > 0:
				var rem = favs.size() % grid.columns
				if rem > 0:
					for i in range(grid.columns - rem):
						process_levels.append({"file": "", "idx": -1})
			for o in others: process_levels.append({"file": o.file, "idx": o.cart.absolute_index if o.cart else -1})
		else:
			raw_levels.sort()
			for lf in raw_levels:
				process_levels.append({"file": lf, "idx": index})
				index += 1
		
		if process_levels.is_empty():
			var empty_lbl = Label.new()
			empty_lbl.text = "No levels yet"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_lbl.custom_minimum_size = Vector2(256 * hub_card_scale, 96 * hub_card_scale)
			empty_lbl.add_theme_font_size_override("font_size", int(16 * hub_card_scale))
			empty_lbl.add_theme_color_override("font_color", color_ink_dim)
			grid.add_child(empty_lbl)
				
		for item in process_levels:
			var fname = item.file
			if fname == "":
				var pad = Control.new()
				grid.add_child(pad)
				continue
				
			var prefer_focus = fname == selected_level_name or (selected_level_name == "" and fname == last_known_level)
			var btn = _create_level_card(fname, levels_dir_path, grid, item.idx, false, prefer_focus, scene_name)
			level_buttons.append(btn)
			all_focus_buttons.append(btn)
			if prefer_focus:
				_pending_menu_focus = btn
			
		var cols = grid.columns
		_chain_horizontal_focus(level_buttons, cols)
		_wire_vertical_focus_neighbors(level_buttons, cols)
		
	if _pending_menu_focus == null and first_header != null:
		_pending_menu_focus = first_header
		
	# Vertical focus logic for headers
	if specific_scene_name == "":
		_rebuild_levels_focus()
	_wire_auto_scroll(all_focus_buttons, $UI/Content/MainPanel/ScrollContainer)
	_focus_current_menu()
func _on_level_selected(level_name: String):
	selected_level_name = level_name
	display_games_lightbox()

func display_games_lightbox():
	_reset_menu_focus()
	_clear_games_overlay()
		
	games_overlay = ColorRect.new()
	games_overlay.color = Color(0, 0, 0, 0.85)
	games_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(games_overlay)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	games_overlay.add_child(margin)
	
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style_panel)
	margin.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var header = MarginContainer.new()
	header.add_theme_constant_override("margin_left", 20)
	header.add_theme_constant_override("margin_top", 20)
	header.add_theme_constant_override("margin_right", 20)
	header.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(header)
	
	var hbox = HBoxContainer.new()
	header.add_child(hbox)
	
	var title = Label.new()
	var pretty_level = selected_level_name.replace("_", " ").to_upper()
	title.text = "SELECT A GAME TO PLAY IN " + pretty_level
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", color_cyan)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 18)
	var overlay_ref = games_overlay
	close_btn.pressed.connect(func():
		if is_instance_valid(overlay_ref):
			overlay_ref.queue_free()
		if games_overlay == overlay_ref:
			games_overlay = null
		_reset_menu_focus()
		_focus_current_menu()
	)
	hbox.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll_margin = MarginContainer.new()
	scroll_margin.add_theme_constant_override("margin_left", 20)
	scroll_margin.add_theme_constant_override("margin_bottom", 20)
	scroll_margin.add_theme_constant_override("margin_right", 20)
	scroll.add_child(scroll_margin)
	vbox.add_child(scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 14)
	scroll_margin.add_child(scroll_vbox)
	
	var games = get_sorted_cartridges()
	var focus_buttons = []
	var columns = _calculate_grid_columns()
	
	if sort_favorites_first:
		var favs = []
		var others = []
		for g in games:
			if g.favorite: favs.append(g)
			else: others.append(g)
		favs.sort_custom(func(a,b): return _get_cartridge_sort_name(a.game_name) < _get_cartridge_sort_name(b.game_name))
		others.sort_custom(func(a,b): return _get_cartridge_sort_name(a.game_name) < _get_cartridge_sort_name(b.game_name))
		
		if favs.size() > 0:
			var fav_lbl = Label.new()
			fav_lbl.text = "Favorites"
			fav_lbl.add_theme_font_size_override("font_size", 24)
			scroll_vbox.add_child(fav_lbl)

			var fav_grid = GridContainer.new()
			fav_grid.columns = columns
			fav_grid.add_theme_constant_override("h_separation", 16)
			fav_grid.add_theme_constant_override("v_separation", 16)
			scroll_vbox.add_child(fav_grid)

			var fav_buttons = []
			for g in favs:
				var card_btn = _create_game_card(g, fav_grid, g.absolute_index)
				fav_buttons.append(card_btn)
				focus_buttons.append(card_btn)
			_wire_vertical_focus_neighbors(fav_buttons, fav_grid.columns)

		if others.size() > 0:
			var other_lbl = Label.new()
			other_lbl.text = "All Games"
			other_lbl.add_theme_font_size_override("font_size", 24)

			var other_margin = MarginContainer.new()
			other_margin.add_theme_constant_override("margin_top", 24)
			other_margin.add_child(other_lbl)
			scroll_vbox.add_child(other_margin)

			var other_grid = GridContainer.new()
			other_grid.columns = columns
			other_grid.add_theme_constant_override("h_separation", 16)
			other_grid.add_theme_constant_override("v_separation", 16)
			scroll_vbox.add_child(other_grid)

			var other_buttons = []
			for g in others:
				var card_btn = _create_game_card(g, other_grid, g.absolute_index)
				other_buttons.append(card_btn)
				focus_buttons.append(card_btn)
			_wire_vertical_focus_neighbors(other_buttons, other_grid.columns)
	else:
		var grid = GridContainer.new()
		grid.columns = columns
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		scroll_vbox.add_child(grid)

		for g in games:
			var card_btn = _create_game_card(g, grid, g.absolute_index)
			focus_buttons.append(card_btn)
		_wire_vertical_focus_neighbors(focus_buttons, grid.columns)

	_chain_horizontal_focus(focus_buttons, columns)
	_wire_auto_scroll(focus_buttons, scroll)
	if _pending_menu_focus == null:
		_remember_menu_focus(close_btn)
	_focus_current_menu()

func display_games():
	_reset_menu_focus()
	_game_title_focus_buttons.clear()
	clear_main_panel()
	current_tab = "games"
	viewing_levels = false
	
	scenes_grid.visible = false
	
	for child in scroll_vbox.get_children():
		if child != scenes_grid:
			child.queue_free()

	var games = get_sorted_cartridges()
	
	if sort_favorites_first:
		var favs = []
		var others = []
		for g in games:
			if g.favorite: favs.append(g)
			else: others.append(g)
		
		if favs.size() > 0:
			var fav_lbl = Label.new()
			fav_lbl.text = "Favorites"
			fav_lbl.add_theme_font_size_override("font_size", 24)
			scroll_vbox.add_child(fav_lbl)
			var fav_grid = GridContainer.new()
			fav_grid.columns = _calculate_grid_columns()
			fav_grid.add_theme_constant_override("h_separation", 16)
			fav_grid.add_theme_constant_override("v_separation", 16)
			scroll_vbox.add_child(fav_grid)
			var fav_buttons = []
			for game in favs:
				var card_btn = _create_game_card(game, fav_grid, game.absolute_index)
				fav_buttons.append(card_btn)
				_game_title_focus_buttons.append(card_btn)
			_wire_vertical_focus_neighbors(fav_buttons, fav_grid.columns)

		if others.size() > 0:
			var other_lbl = Label.new()
			other_lbl.text = "All Games"
			other_lbl.add_theme_font_size_override("font_size", 24)
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_top", 24)
			margin.add_child(other_lbl)
			scroll_vbox.add_child(margin)
			var other_grid = GridContainer.new()
			other_grid.columns = _calculate_grid_columns()
			other_grid.add_theme_constant_override("h_separation", 16)
			other_grid.add_theme_constant_override("v_separation", 16)
			scroll_vbox.add_child(other_grid)
			var other_buttons = []
			for game in others:
				var card_btn = _create_game_card(game, other_grid, game.absolute_index)
				other_buttons.append(card_btn)
				_game_title_focus_buttons.append(card_btn)
			_wire_vertical_focus_neighbors(other_buttons, other_grid.columns)

	else:
		var grid = GridContainer.new()
		grid.columns = _calculate_grid_columns()
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		scroll_vbox.add_child(grid)
		for game in games:
			_game_title_focus_buttons.append(_create_game_card(game, grid, game.absolute_index))
		_wire_vertical_focus_neighbors(_game_title_focus_buttons, grid.columns)
	
	if sort_favorites_first:
		# If separated into favs and others, we just do them independently or together?
		# Actually, _chain_horizontal_focus expects a single linear array. 
		# `_game_title_focus_buttons` has them all. 
		# To avoid wrapping focus incorrectly from favorites to all games,
		# we should just let Godot natively navigate horizontally between rows!
		# But since we use _chain_horizontal_focus to point left to SideNav, we apply it.
		var all_cols = _calculate_grid_columns()
		_chain_horizontal_focus(_game_title_focus_buttons, all_cols)
	else:
		_chain_horizontal_focus(_game_title_focus_buttons, _calculate_grid_columns())
	_wire_auto_scroll(_game_title_focus_buttons, $UI/Content/MainPanel/ScrollContainer)
	_focus_current_menu()

func _classic_level_for_cart(cart_id: String) -> String:
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	var candidate = "classic_" + cart_id
	var level_path = base_dir.path_join("content/scenes/scene_classic_pack/levels").path_join(candidate)
	if DirAccess.dir_exists_absolute(level_path):
		return candidate
	return ""

func _cart_id_for_classic_level(level_name: String) -> String:
	if not level_name.begins_with("classic_"):
		return ""
	return level_name.substr("classic_".length())

func _launch_game(cart_id: String):
	if launcher and launcher.running:
		log_debug("Blocked attempt to double-launch cartridge.")
		return
	var launched_from_level_overlay = games_overlay != null and is_instance_valid(games_overlay)
	_clear_games_overlay()
	var classic_level = _classic_level_for_cart(cart_id)
	if classic_level != "" and (current_scene == "" or current_scene == "scene_classic_pack"):
		current_scene = "scene_classic_pack"
		if not launched_from_level_overlay or selected_level_name == "":
			selected_level_name = classic_level
		
	if current_scene == "":
		current_scene = "scene_demo_wall"
	if selected_level_name == "":
		selected_level_name = "rock_wall_260629_173035"
		
	last_known_level = selected_level_name
	last_known_scene = current_scene
	last_known_cartridge = cart_id
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	var scene_dir = base_dir.path_join("content/scenes").path_join(current_scene)
	var level_dir = scene_dir.path_join("levels").path_join(selected_level_name)
	if not DirAccess.dir_exists_absolute(level_dir) and selected_level_name == current_scene and FileAccess.file_exists(scene_dir.path_join("level.yaml")):
		level_dir = scene_dir
	var cart_dir = base_dir.path_join("content/cartridges").path_join(cart_id)
	
	var launch_cmd = base_dir.path_join("Godot_v4.3-stable_win64.exe")
	var args_template = "--path \"" + cart_dir + "\" " + _game_window_launch_args() + " -- --scene \"" + scene_dir + "\" --level \"" + level_dir + "\" --ipc <socket>"
	var launch_skin = _get_launch_skin_name(cart_id)
	if launch_skin != "":
		args_template += " --skin \"" + launch_skin.replace("\"", "") + "\""
	
	if launcher:
		launcher.launch(launch_cmd, args_template, scene_dir, level_dir)
		if launcher.running:
			$UI.process_mode = PROCESS_MODE_DISABLED
			get_viewport().gui_disable_input = true

func log_debug(msg: String):
	print(msg)

func _on_restore_pressed():
	if last_known_cartridge != "":
		_launch_game(last_known_cartridge)

func _on_design_nav_pressed():
	current_tab = "design"
	viewing_levels = false
	_reset_menu_focus()
	_clear_games_overlay()
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	if scroll_container:
		scroll_container.visible = false
		
	for child in $UI/Content/MainPanel.get_children():
		if child != scroll_container:
			child.queue_free()
			
	var design = load("res://design_screen.tscn").instantiate()
	$UI/Content/MainPanel.add_child(design)
	_focus_current_menu()

func _on_ipc_log(msg: String):
	ipc_log_lines.append(msg)
	if ipc_log_lines.size() > 50:
		ipc_log_lines.pop_front()

func _show_placeholder_overlay(title_text: String, content_text: String = "Coming soon"):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color_surface2
	style.border_width_bottom = 2
	style.border_color = color_cyan
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 32
	style.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", color_cyan)
	vbox.add_child(title)
	
	var content = Label.new()
	content.text = content_text
	content.add_theme_font_size_override("font_size", 20)
	vbox.add_child(content)
	
	var close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 48)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		overlay.queue_free()
		_reset_menu_focus()
		_focus_current_menu()
	)
	vbox.add_child(close_btn)
	_reset_menu_focus()
	_remember_menu_focus(close_btn)
	
	panel.add_child(vbox)
	overlay.add_child(panel)
	
	$UI.add_child(overlay)
	_focus_current_menu()

func _on_launch_calibration_tool():
	_show_placeholder_overlay("Calibration", "Calibration tool coming soon.")

func _on_test_pattern_pressed():
	_show_placeholder_overlay("Test Pattern", "Test patterns coming soon.")

func _on_log_pressed():
	var log_text = "\n".join(ipc_log_lines)
	if log_text == "": log_text = "No logs yet."
	_show_placeholder_overlay("IPC Log", log_text)

func _on_help_pressed():
	var help_text = "Nav buttons:\n\n- Scenes: Pick a background scene.\n- Levels: Pick a level variation.\n- Games: Pick a game to launch.\n- Design: Edit palettes/thumbnails.\n- Calibrate: Coming soon.\n- Log: View IPC logs."
	_show_placeholder_overlay("Help", help_text)

func parse_simple_yaml(path: String) -> Dictionary:
	var data = {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return data
	
	var current_parent = ""
	while not file.eof_reached():
		var line = file.get_line()
		var trimmed = line.strip_edges()
		if trimmed == "" or trimmed.begins_with("#"):
			continue
		
		var indent_level = 0
		for i in range(line.length()):
			var ch = line.unicode_at(i)
			if ch == 32 or ch == 9:
				indent_level += 1
			else:
				break
		
		if trimmed.ends_with(":"):
			current_parent = trimmed.substr(0, trimmed.length() - 1).strip_edges()
			if not data.has(current_parent):
				data[current_parent] = {}
			continue
		
		if not trimmed.contains(":"):
			continue
		
		var parts = trimmed.split(":", true, 1)
		var key = parts[0].strip_edges()
		var val = parts[1].strip_edges()
		
		if (val.begins_with("\"") and val.ends_with("\"")) or (val.begins_with("'") and val.ends_with("'")):
			val = val.substr(1, val.length() - 2)
		
		var parsed_val: Variant = val
		if val.begins_with("[") and val.ends_with("]"):
			var inner = val.substr(1, val.length() - 2)
			var list_items: Array = []
			if inner != "":
				for item in inner.split(","):
					list_items.append(item.strip_edges())
			parsed_val = list_items
		
		if indent_level > 0 and current_parent != "" and typeof(data.get(current_parent)) == TYPE_DICTIONARY:
			data[current_parent][key] = parsed_val
		else:
			data[key] = parsed_val
	
	return data

func _clear_games_overlay():
	if games_overlay != null and is_instance_valid(games_overlay):
		games_overlay.queue_free()
	games_overlay = null

func _get_repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../..")
func _create_game_card(cart: Dictionary, parent_grid: Container, display_index: int = -1):
	var cart_id = cart.id
	var game_name = cart.game_name.replace("Classic ", "")
	var is_fav = cart.favorite

	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(260 * hub_card_scale, 300 * hub_card_scale)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_panel.add_theme_stylebox_override("panel", style_panel)
	parent_grid.add_child(card_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	card_panel.add_child(vbox)

	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 8)
	top_margin.add_theme_constant_override("margin_top", 8)
	top_margin.add_theme_constant_override("margin_right", 8)
	top_margin.add_theme_constant_override("margin_bottom", 4)
	vbox.add_child(top_margin)

	var img_control = Control.new()
	img_control.custom_minimum_size = Vector2(244 * hub_card_scale, 200 * hub_card_scale)
	top_margin.add_child(img_control)

	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_control.add_child(tex_rect)
	
	var cover_btn = Button.new()
	cover_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover_btn.focus_mode = Control.FOCUS_NONE
	var empty_style = StyleBoxEmpty.new()
	cover_btn.add_theme_stylebox_override("normal", empty_style)
	cover_btn.add_theme_stylebox_override("hover", empty_style)
	cover_btn.add_theme_stylebox_override("pressed", empty_style)
	cover_btn.add_theme_stylebox_override("focus", empty_style)
	cover_btn.pressed.connect(func(): _launch_game(cart_id))
	img_control.add_child(cover_btn)

	var current_skin = _get_selected_skin_name(cart_id, game_name, cart.manifest)
	var default_skin = _get_default_skin_name(cart.manifest, game_name)
	var skins = _get_skin_list(cart.manifest, game_name)
	var thumb_path = cart.thumb_path
	
	var display_title = game_name
	if current_skin != "":
		if current_skin.begins_with("Classic "):
			display_title = current_skin.trim_prefix("Classic ")
		else:
			display_title = current_skin

	if current_skin != "":
		var skin_thumb_path = _find_skin_thumbnail(cart_id, current_skin)
		if FileAccess.file_exists(skin_thumb_path):
			thumb_path = skin_thumb_path

	if FileAccess.file_exists(thumb_path):
		var img = Image.load_from_file(thumb_path)
		if img: tex_rect.texture = ImageTexture.create_from_image(img)

	if display_index > 0:
		var num_bg = Panel.new()
		var num_style = StyleBoxFlat.new()
		num_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		num_style.corner_radius_top_left = 6
		num_style.corner_radius_top_right = 6
		num_style.corner_radius_bottom_left = 6
		num_style.corner_radius_bottom_right = 6
		num_bg.add_theme_stylebox_override("panel", num_style)
		num_bg.custom_minimum_size = Vector2(32, 32)
		num_bg.position = Vector2(8, 8)
		
		var index_lbl = Label.new()
		index_lbl.text = str(display_index) + "."
		index_lbl.add_theme_font_size_override("font_size", 16)
		index_lbl.add_theme_color_override("font_color", color_cyan)
		index_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		index_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		index_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num_bg.add_child(index_lbl)
		img_control.add_child(num_bg)

	var fav_btn = Button.new()
	fav_btn.focus_mode = Control.FOCUS_NONE
	fav_btn.text = "★" if is_fav else "☆"
	fav_btn.custom_minimum_size = Vector2(36, 36)
	fav_btn.add_theme_font_size_override("font_size", 24)
	if is_fav: fav_btn.add_theme_color_override("font_color", color_cyan)
	else: fav_btn.add_theme_color_override("font_color", color_ink_dim)
	var fav_style = StyleBoxEmpty.new()
	fav_btn.add_theme_stylebox_override("normal", fav_style)
	fav_btn.add_theme_stylebox_override("hover", fav_style)
	fav_btn.add_theme_stylebox_override("pressed", fav_style)
	fav_btn.add_theme_stylebox_override("focus", fav_style)
	fav_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fav_btn.offset_left = -40
	fav_btn.offset_right = -4
	fav_btn.offset_top = 4
	fav_btn.offset_bottom = 40
	fav_btn.pressed.connect(func():
		toggle_favorite(cart_id)
		display_games()
	)
	img_control.add_child(fav_btn)

	var bottom_margin = MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 8)
	bottom_margin.add_theme_constant_override("margin_right", 8)
	bottom_margin.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(bottom_margin)
	
	var bottom_vbox = VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 4)
	bottom_margin.add_child(bottom_vbox)

	var title_btn = Button.new()
	title_btn.set_meta("cart_id", cart_id)
	title_btn.custom_minimum_size = Vector2(0, 36 * hub_card_scale)
	title_btn.add_theme_font_size_override("font_size", int(16 * hub_card_scale))
	title_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.16, 0.18)
	style_normal.set_corner_radius_all(4)
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.22, 0.25)
	style_hover.border_width_bottom = 2
	style_hover.border_color = color_cyan
	style_hover.set_corner_radius_all(4)
	
	title_btn.add_theme_stylebox_override("normal", style_normal)
	title_btn.add_theme_stylebox_override("hover", style_hover)
	title_btn.add_theme_stylebox_override("pressed", style_hover)
	title_btn.add_theme_stylebox_override("focus", style_hover)
	title_btn.pressed.connect(func():
		_launch_game(cart_id)
	)
	
	var _update_title = func():
		if skins.size() > 1 and (title_btn.has_focus() or title_btn.is_hovered() or cover_btn.is_hovered()):
			title_btn.text = "< (X)  " + display_title + "  (Y) >"
		else:
			title_btn.text = display_title
			
	if skins.size() > 1:
		title_btn.focus_entered.connect(_update_title)
		title_btn.focus_exited.connect(_update_title)
		title_btn.mouse_entered.connect(_update_title)
		title_btn.mouse_exited.connect(_update_title)
		cover_btn.mouse_entered.connect(_update_title)
		cover_btn.mouse_exited.connect(_update_title)
		
		title_btn.gui_input.connect(func(event):
			var step = 0
			if event is InputEventJoypadButton and event.pressed:
				if event.button_index == JOY_BUTTON_X:
					step = -1
				elif event.button_index == JOY_BUTTON_Y:
					step = 1
			elif event is InputEventKey and event.pressed and not event.echo:
				if event.keycode == KEY_X or event.keycode == KEY_COMMA:
					step = -1
				elif event.keycode == KEY_Y or event.keycode == KEY_PERIOD:
					step = 1
			elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if event.position.x < title_btn.size.x * 0.25:
					step = -1
					title_btn.accept_event()
				elif event.position.x > title_btn.size.x * 0.75:
					step = 1
					title_btn.accept_event()
			if step != 0:
				_cycle_skin(cart_id, skins, step)
				title_btn.accept_event()
		)
		
	_update_title.call()

	bottom_vbox.add_child(title_btn)
	_remember_menu_focus(title_btn)
	
	return title_btn

func _create_level_card(level_name: String, levels_dir: String, container: Control, display_index: int = -1, is_scene: bool = false, prefer_focus: bool = false, override_scene_name: String = ""):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(256 * hub_card_scale, 284 * hub_card_scale)
	btn.focus_mode = Control.FOCUS_ALL
	if is_scene:
		btn.pressed.connect(func(): _on_scene_selected(level_name))
	else:
		btn.pressed.connect(func():
			if override_scene_name != "":
				current_scene = override_scene_name
			_on_level_selected(level_name)
		)
	container.add_child(btn)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	

	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
	var cart_id = _cart_id_for_classic_level(level_name)



	# Determine classic name

	var classic_name = get_level_classic_name(level_name)

	var active_skin_name = ""

	var is_classic_skin = true

	

	if cart_id != "":

		var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")

		if FileAccess.file_exists(manifest_path):

			var manifest = parse_simple_yaml(manifest_path)

			var skins = manifest.get("skins", [])

			var selected_skin = selected_skins.get(cart_id, "")

			

			var default_skin = ""

			if typeof(skins) == TYPE_ARRAY and skins.size() > 0:

				default_skin = str(skins[0])

			else:

				default_skin = "Classic " + classic_name

			

			if selected_skin != "" and selected_skin != default_skin:

				active_skin_name = selected_skin

				is_classic_skin = false



	var thumb_path = _scene_card_thumb_path(levels_dir.path_join(level_name)) if is_scene else _level_card_thumb_path(levels_dir.path_join(level_name), cart_id)



	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(232 * hub_card_scale, 176 * hub_card_scale)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if FileAccess.file_exists(thumb_path):
		var img = Image.load_from_file(thumb_path)
		if img: tex_rect.texture = ImageTexture.create_from_image(img)
	else:
		var placeholder = ColorRect.new()
		placeholder.color = Color(0.1, 0.1, 0.15)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var pl_lbl = Label.new()
		pl_lbl.text = "No Image"
		pl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pl_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		placeholder.add_child(pl_lbl)
		tex_rect.add_child(placeholder)
		
	if display_index >= 0:
		var num_bg = Panel.new()
		var num_style = StyleBoxFlat.new()
		num_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		num_style.corner_radius_top_left = 6
		num_style.corner_radius_top_right = 6
		num_style.corner_radius_bottom_left = 6
		num_style.corner_radius_bottom_right = 6
		num_bg.add_theme_stylebox_override("panel", num_style)
		num_bg.custom_minimum_size = Vector2(32, 32)
		num_bg.position = Vector2(8, 8)
		var number_lbl = Label.new()
		number_lbl.text = str(display_index + 1) + "."
		number_lbl.add_theme_font_size_override("font_size", 18)
		number_lbl.add_theme_color_override("font_color", Color(0, 0.9, 1.0))
		number_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num_bg.add_child(number_lbl)
		tex_rect.add_child(num_bg)
		
	vbox.add_child(tex_rect)
	
	# Text layout
	var text_container = VBoxContainer.new()
	text_container.custom_minimum_size = Vector2(0, 68)
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_container.alignment = BoxContainer.ALIGNMENT_CENTER
	text_container.add_theme_constant_override("separation", 6)
	text_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(text_container)

	var top_text_spacer = Control.new()
	top_text_spacer.custom_minimum_size = Vector2(0, 2)
	top_text_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(top_text_spacer)
	
	var title_lbl = Label.new()
	if is_scene or not level_name.begins_with("classic_"):
		title_lbl.text = level_name
	else:
		title_lbl.text = classic_name.replace("Classic ", "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", int(18 * hub_card_scale))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_container.add_child(title_lbl)
	
	

	var bottom_text_spacer = Control.new()
	bottom_text_spacer.custom_minimum_size = Vector2(0, 4)
	bottom_text_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(bottom_text_spacer)
	

	style_grid_button(btn)
	if prefer_focus:
		_prefer_menu_focus(btn)
	_remember_menu_focus(btn)
	return btn

func _scene_card_thumb_path(scene_dir: String) -> String:
	var scene_thumb = _first_existing_file(scene_dir, ["thumbnail.png", "background.png", "reference.png", "photo.png", "image.png"])
	if scene_thumb != "":
		return scene_thumb
	var levels_root = scene_dir.path_join("levels")
	var dir = DirAccess.open(levels_root)
	if dir == null:
		return ""
	var level_names = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with(".") and file_name != "derived":
			level_names.append(file_name)
		file_name = dir.get_next()
	level_names.sort()
	for level_name in level_names:
		var level_dir = levels_root.path_join(str(level_name))
		var photo_thumb = _first_existing_file(level_dir, ["background.png", "reference.png", "photo.png", "image.png", "thumbnail.png"])
		if photo_thumb != "":
			return photo_thumb
		photo_thumb = _first_existing_file(level_dir.path_join("level_edit"), ["background.png", "reference.png", "photo.png", "image.png", "thumbnail.png"])
		if photo_thumb != "":
			return photo_thumb
	return ""

func _level_card_thumb_path(level_dir: String, cart_id: String) -> String:
	var level_thumb = _first_existing_file(level_dir, ["semantic_map.png", "thumbnail.png", "background.png", "reference.png"])
	if level_thumb != "":
		return level_thumb
	level_thumb = _first_existing_file(level_dir.path_join("level_edit"), ["semantic_map.png", "thumbnail.png", "background.png", "reference.png"])
	if level_thumb != "":
		return level_thumb
	if cart_id != "":
		var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
		var cart_thumb = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("thumbnail.png")
		if FileAccess.file_exists(cart_thumb):
			return cart_thumb
	return ""

func _first_existing_file(base_dir: String, file_names: Array) -> String:
	for file_name in file_names:
		var path = base_dir.path_join(str(file_name))
		if FileAccess.file_exists(path): return path
		path = base_dir.path_join(str(file_name).replace(".png", ".jpg"))
		if FileAccess.file_exists(path): return path
		path = base_dir.path_join(str(file_name).replace(".png", ".jpeg"))
		if FileAccess.file_exists(path): return path
	return ""
	return ""




func init_styling():

	style_panel = StyleBoxFlat.new()

	style_panel.bg_color = color_surface1

	style_panel.set_border_width_all(1)

	style_panel.border_color = color_border_default

	style_panel.corner_detail = 1

	

	style_btn_normal = StyleBoxFlat.new()

	style_btn_normal.bg_color = color_black

	style_btn_normal.set_border_width_all(1)

	style_btn_normal.border_color = Color(1, 1, 1, 0.16)

	style_btn_normal.corner_detail = 1

	

	style_btn_hover = StyleBoxFlat.new()

	style_btn_hover.bg_color = color_black

	style_btn_hover.set_border_width_all(1)

	style_btn_hover.border_color = color_cyan

	style_btn_hover.corner_detail = 1

	

	style_btn_pressed = StyleBoxFlat.new()

	style_btn_pressed.bg_color = color_cyan

	style_btn_pressed.set_border_width_all(1)

	style_btn_pressed.border_color = color_cyan

	style_btn_pressed.corner_detail = 1

	

	style_nav_normal = StyleBoxFlat.new()
	style_nav_normal.bg_color = color_black
	style_nav_normal.set_border_width_all(0)
	style_nav_normal.content_margin_left = 24
	style_nav_normal.corner_detail = 1
	
	style_nav_active = StyleBoxFlat.new()
	style_nav_active.bg_color = Color(0.0, 0.9, 1.0, 0.08)
	style_nav_active.set_border_width_all(0)
	style_nav_active.border_width_left = 3
	style_nav_active.border_color = color_cyan
	style_nav_active.content_margin_left = 24
	style_nav_active.corner_detail = 1




func toggle_favorite(cart_id: String):
	if cart_id in favorite_cartridges:
		favorite_cartridges.erase(cart_id)
	else:
		favorite_cartridges.append(cart_id)
	save_favorites()


func save_favorites():

	var file = FileAccess.open("user://favorites.json", FileAccess.WRITE)

	if file:

		var data = {

			"favorites": favorite_cartridges,

			"sort_favorites_first": sort_favorites_first,

			"selected_skins": selected_skins

		}

		file.store_string(JSON.stringify(data))




func load_favorites():

	var path = "user://favorites.json"

	if FileAccess.file_exists(path):

		var file = FileAccess.open(path, FileAccess.READ)

		if file:

			var json = JSON.new()

			if json.parse(file.get_as_text()) == OK:

				var data = json.data

				if typeof(data) == TYPE_ARRAY:

					favorite_cartridges = []

					for item in data:

						favorite_cartridges.append(str(item))

					sort_favorites_first = true

				elif typeof(data) == TYPE_DICTIONARY:

					if "favorites" in data and typeof(data["favorites"]) == TYPE_ARRAY:

						favorite_cartridges = []

						for item in data["favorites"]:

							favorite_cartridges.append(str(item))

					if "sort_favorites_first" in data:

						sort_favorites_first = bool(data["sort_favorites_first"])

					if "selected_skins" in data and typeof(data["selected_skins"]) == TYPE_DICTIONARY:

						selected_skins = data["selected_skins"]




func _get_cartridge_sort_name(game_name: String) -> String:
	var normalized = game_name.to_lower()
	if normalized.begins_with("classic "):
		normalized = normalized.trim_prefix("classic ")
	return normalized


func get_sorted_cartridges() -> Array:
	return _get_cartridge_list(sort_favorites_first)


func _get_skin_list(manifest: Dictionary, game_name: String) -> Array:
	var skins = manifest.get("skins", [])

	if typeof(skins) == TYPE_ARRAY and skins.size() > 0:

		var list = []

		for skin in skins:

			list.append(str(skin))

		return list

	return ["Classic " + game_name, "Synthwave", "8-Bit Retro"]




func _cycle_skin(cart_id: String, skin_names: Array, step: int):
	if skin_names.is_empty():
		return

	var current = str(selected_skins.get(cart_id, skin_names[0]))
	var idx = skin_names.find(current)
	if idx < 0:
		idx = 0
	idx = (idx + step + skin_names.size()) % skin_names.size()
	selected_skins[cart_id] = str(skin_names[idx])
	save_favorites()
	_refresh_card_views()

	var btn = _find_game_title_button(cart_id)
	if btn != null:
		_prefer_menu_focus(btn)
		btn.call_deferred("grab_focus")


func _find_game_title_button(cart_id: String) -> Button:
	for item in _game_title_focus_buttons:
		var btn = item as Button
		if btn != null and is_instance_valid(btn) and btn.has_meta("cart_id") and str(btn.get_meta("cart_id")) == cart_id:
			return btn
	return null


func _get_launch_skin_name(cart_id: String) -> String:
	if cart_id == "":
		return ""
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../").simplify_path()
	var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")
	if not FileAccess.file_exists(manifest_path):
		return ""
	var manifest = parse_simple_yaml(manifest_path)
	var game_name = str(manifest.get("game_name", cart_id)).replace("Classic ", "")
	return _get_selected_skin_name(cart_id, game_name, manifest)


func _find_skin_thumbnail(cart_id: String, skin_name: String) -> String:
	if cart_id == "" or skin_name == "":
		return ""
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../").simplify_path()
	var cart_dir = base_dir.path_join("content/cartridges").path_join(cart_id)
	var suffix = _skin_asset_suffix(skin_name)
	var suffixes = [suffix]
	var underscore_suffix = suffix.replace("-", "_")
	if underscore_suffix != suffix:
		suffixes.append(underscore_suffix)
	var dash_suffix = suffix.replace("_", "-")
	if dash_suffix != suffix and not suffixes.has(dash_suffix):
		suffixes.append(dash_suffix)
	for candidate_suffix in suffixes:
		for ext in ["png", "jpg", "jpeg"]:
			var candidate = cart_dir.path_join("thumbnail_" + candidate_suffix + "." + ext)
			if FileAccess.file_exists(candidate):
				return candidate
	return ""


func _skin_asset_suffix(skin_name: String) -> String:
	var suffix = skin_name.strip_edges().to_lower().replace(" ", "_")
	for ch in [":", "/", "\\", "\"", "'", "(", ")", "[", "]"]:
		suffix = suffix.replace(ch, "")
	return suffix




func _prepare_scroll_view(show_default_grid: bool):
	if scenes_grid:
		scenes_grid.visible = show_default_grid
	if scroll_vbox:
		for child in scroll_vbox.get_children():

			if child != scenes_grid:

				child.queue_free()




func is_level_favorited(level_name: String) -> bool:
	var cart_id = _cart_id_for_classic_level(level_name)

	if cart_id != "" and cart_id in favorite_cartridges:

		return true

	return false




func get_level_classic_name(level_name: String) -> String:

	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
	var cart_id = _cart_id_for_classic_level(level_name)

	

	var display_name = level_name.replace("classic_", "").capitalize().replace("Classic ", "")
	if level_name == "scene_classic_pack":
		display_name = "Classic Pack"

	if cart_id != "":

		var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")

		if FileAccess.file_exists(manifest_path):

			var manifest = parse_simple_yaml(manifest_path)

			var manifest_game_name = manifest.get("game_name", "")

			if manifest_game_name != "":

				display_name = manifest_game_name

	return display_name




func _get_cartridge_list(order_favorites_first: bool) -> Array:
	var list = []
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
	var carts_dir = base_dir.path_join("content/cartridges")
	var dir = DirAccess.open(carts_dir)
	if dir:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":

			if dir.current_is_dir() and not file_name.begins_with("."):

				if file_name != "loopback":

					var cart_id = file_name

					var manifest_path = carts_dir.path_join(cart_id).path_join("manifest.yaml")

					var manifest = parse_simple_yaml(manifest_path)

					var game_name = manifest.get("game_name", cart_id)

					var is_fav = cart_id in favorite_cartridges

					list.append({
						"id": cart_id,
						"game_name": game_name,
						"favorite": is_fav,
						"manifest": manifest,
						"thumb_path": carts_dir.path_join(cart_id).path_join("thumbnail.png")

					})

			file_name = dir.get_next()
			
	list.sort_custom(func(a, b):
		var name_a = _get_cartridge_sort_name(a.game_name)
		var name_b = _get_cartridge_sort_name(b.game_name)
		return name_a < name_b
	)
	for idx in range(list.size()):
		list[idx].absolute_index = idx + 1
	if order_favorites_first:
		list.sort_custom(func(a, b):
			if a.favorite != b.favorite:
				return a.favorite
			var name_a = _get_cartridge_sort_name(a.game_name)
			var name_b = _get_cartridge_sort_name(b.game_name)
			return name_a < name_b
		)
	return list

func _on_sort_favorites_toggled(pressed: bool):

	if _updating_main_checkbox:

		return

	sort_favorites_first = pressed

	save_favorites()

	if dialog_sort_fav_checkbox:

		_updating_dialog_checkbox = true

		dialog_sort_fav_checkbox.button_pressed = pressed

		_updating_dialog_checkbox = false

	if current_tab == "games":

		display_games()





func _get_selected_skin_name(cart_id: String, game_name: String, manifest: Dictionary) -> String:

	var default_skin = _get_default_skin_name(manifest, game_name)

	var selected_skin_name = str(selected_skins.get(cart_id, ""))

	if selected_skin_name == "":

		return default_skin

	return selected_skin_name




func _get_default_skin_name(manifest: Dictionary, game_name: String) -> String:

	var skins = _get_skin_list(manifest, game_name)

	return str(skins[0]) if skins.size() > 0 else "Classic " + game_name




func _refresh_card_views():
	var scroll_container = get_node_or_null("UI/Content/MainPanel/ScrollContainer")
	var saved_scroll = 0
	if scroll_container:
		saved_scroll = scroll_container.scroll_vertical
	_in_refresh_card_views = true

	if current_tab == "games":
		display_games()
	elif current_tab == "scenes":
		display_scenes()
	elif current_tab == "levels" and launch_dialog and launch_dialog.visible and selected_level_name != "":
		_on_level_selected(selected_level_name)
	elif viewing_levels and current_scene != "":
		_on_scene_selected(current_scene)

	if scroll_container:
		var tree = get_tree()
		if tree:
			await tree.process_frame
		if is_instance_valid(scroll_container):
			scroll_container.scroll_vertical = saved_scroll
	_in_refresh_card_views = false




func _on_cartridge_exited(clean: bool):
	$UI.process_mode = PROCESS_MODE_INHERIT
	get_viewport().gui_disable_input = false

	print("Cartridge exited clean: ", clean)

	if clean:
		_return_to_last_level_focus()
		return

	if not clean:

		var running_duration = (Time.get_ticks_msec() / 1000.0) - last_launch_time

		if running_duration < 2.0:

			log_debug("Cartridge crashed immediately on startup (run time: %.2fs). Auto-restore disabled to prevent infinite loops." % running_duration)

		else:

			log_debug("Crash/timeout detected after %.2fs, restoring last known good..." % running_duration)

			_on_restore_pressed()

func _return_to_last_level_focus():
	_clear_games_overlay()
	if last_known_scene == "" or last_known_level == "":
		_focus_current_menu()
		return
	current_scene = last_known_scene
	selected_level_name = last_known_level
	if current_scene == "scene_classic_pack":
		display_scenes()
	else:
		display_levels(current_scene)

func _rebuild_levels_focus():
	var headers = []
	var grids = []
	
	for child in scroll_vbox.get_children():
		if child is MarginContainer:
			var btn = child.get_child(0) as Button
			if btn:
				headers.append(btn)
		elif child is GridContainer:
			grids.append(child)
			
	var bottom_target = null
	if headers.size() > 0:
		var last_idx = headers.size() - 1
		bottom_target = headers[last_idx]
		var last_grid = grids[last_idx]
		if last_grid.visible:
			var last_cards = _get_focus_buttons_in_grid(last_grid)
			if last_cards.size() > 0:
				var cols = last_grid.columns
				var last_row_start = (floor((last_cards.size() - 1) / cols)) * cols
				bottom_target = last_cards[last_row_start]

	# We assume headers.size() == grids.size()
	for i in range(headers.size()):
		var header = headers[i]
		var grid = grids[i]
		
		# 1. Wire top neighbor of this header
		if i == 0:
			if bottom_target:
				header.focus_neighbor_top = header.get_path_to(bottom_target)
		else:
			var prev_grid = grids[i - 1]
			if prev_grid.visible:
				var prev_cards = _get_focus_buttons_in_grid(prev_grid)
				if prev_cards.size() > 0:
					var cols = prev_grid.columns
					var last_row_start = (floor((prev_cards.size() - 1) / cols)) * cols
					header.focus_neighbor_top = header.get_path_to(prev_cards[last_row_start])
			else:
				header.focus_neighbor_top = header.get_path_to(headers[i - 1])
				
		# 2. Wire bottom neighbor of this header
		if grid.visible:
			var cards = _get_focus_buttons_in_grid(grid)
			if cards.size() > 0:
				header.focus_neighbor_bottom = header.get_path_to(cards[0])
		else:
			if i + 1 < headers.size():
				header.focus_neighbor_bottom = header.get_path_to(headers[i + 1])
			else:
				header.focus_neighbor_bottom = header.get_path_to(headers[0])
				
		# 3. Wire cards boundaries
		if grid.visible:
			var cards = _get_focus_buttons_in_grid(grid)
			var cols = grid.columns
			if cards.size() > 0:
				# Top row of cards point UP to the header
				for col_idx in range(min(cols, cards.size())):
					cards[col_idx].focus_neighbor_top = cards[col_idx].get_path_to(header)
					
				# Bottom row of cards point DOWN to the next header
				var last_row_start = (floor((cards.size() - 1) / cols)) * cols
				for col_idx in range(last_row_start, cards.size()):
					if i + 1 < headers.size():
						cards[col_idx].focus_neighbor_bottom = cards[col_idx].get_path_to(headers[i + 1])
					else:
						cards[col_idx].focus_neighbor_bottom = cards[col_idx].get_path_to(headers[0])

func _get_focus_buttons_in_grid(grid: GridContainer) -> Array:
	var buttons = []
	for child in grid.get_children():
		if child is Button and child.focus_mode != Control.FOCUS_NONE:
			buttons.append(child)
	return buttons






