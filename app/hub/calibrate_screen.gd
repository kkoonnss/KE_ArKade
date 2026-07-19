extends Control

signal closed

const PROFILE_SCHEMA := "ke_arkade.calibration_profile"
const PROFILE_VERSION := "1.1.0"
const DEFAULT_SCENE := "scene_demo_wall"
const CANONICAL_SIZE := Vector2(1920, 1080)
const MIN_SUBDIVISION_LEVEL := 1
const MAX_SUBDIVISION_LEVEL := 4

var base_dir: String = ""
var scene_id: String = DEFAULT_SCENE
var mesh_cols: int = 2
var mesh_rows: int = 2
var pins: Array = []
var input_corners: Array = []
var selected_pin: int = -1
var selected_input_corner: int = -1
var hovered_pin: int = -1
var hovered_input_corner: int = -1
var selected_output_edge: Array = []
var hovered_output_edge: Array = []
var selected_input_edge: int = -1
var hovered_input_edge: int = -1
var dragging_pin: bool = false
var dragging_input_corner: bool = false
var dragging_output_edge: bool = false
var dragging_input_edge: bool = false
var preview_rect := Rect2()
var input_image_rect := Rect2()
var status_label: Label
var mesh_label: Label
var edit_mode_label: Label
var scene_label: Label
var save_btn: Button
var side_panel: PanelContainer
var panel_body: VBoxContainer
var collapsed_tab: Button
var title_label: Label
var fullscreen_btn: Button
var input_mode_btn: Button
var output_mode_btn: Button
var input_controls: VBoxContainer
var output_controls: VBoxContainer
var h_subdivision_label: Label
var v_subdivision_label: Label
var scene_select: OptionButton
var scene_options: Array = []
var reference_select: OptionButton
var reference_options: Array = []
var reference_texture: Texture2D = null
var reference_image_size := Vector2.ZERO
var reference_opacity: float = 0.42
var show_controls: bool = true
var active_level_id: String = ""
var panel_dragging: bool = false
var edit_mode: String = "output"

func setup(repo_root: String, active_scene_id: String, active_level_name: String = "") -> void:
	base_dir = repo_root
	scene_id = active_scene_id if active_scene_id != "" else DEFAULT_SCENE
	active_level_id = active_level_name
	_scan_scene_options()
	_load_or_reset_profile()
	_scan_reference_options()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	if pins.is_empty():
		_reset_mesh(2, 2)
	_build_ui()
	_update_status()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if preview_rect.has_point(event.position):
				grab_focus()
				_update_hover_state(event.position)
				if edit_mode == "input":
					selected_input_corner = hovered_input_corner
					dragging_input_corner = selected_input_corner >= 0
					if dragging_input_corner:
						selected_input_edge = -1
						_set_input_corner_from_screen(selected_input_corner, event.position)
						queue_redraw()
					else:
						selected_input_edge = hovered_input_edge
						dragging_input_edge = selected_input_edge >= 0
						if dragging_input_edge:
							selected_input_corner = -1
							queue_redraw()
				else:
					selected_pin = hovered_pin
					dragging_pin = selected_pin >= 0
					if dragging_pin:
						selected_output_edge.clear()
						_set_pin_from_screen(selected_pin, event.position)
						queue_redraw()
					else:
						selected_output_edge = hovered_output_edge.duplicate()
						dragging_output_edge = selected_output_edge.size() == 2
						if dragging_output_edge:
							selected_pin = -1
							queue_redraw()
		else:
			dragging_pin = false
			dragging_input_corner = false
			dragging_output_edge = false
			dragging_input_edge = false
	elif event is InputEventMouseMotion and dragging_input_corner and selected_input_corner >= 0:
		_set_input_corner_from_screen(selected_input_corner, event.position)
		queue_redraw()
	elif event is InputEventMouseMotion and dragging_input_edge and selected_input_edge >= 0:
		_move_input_edge_by_pixel_delta(_screen_delta_to_input_pixels(event.relative))
		queue_redraw()
	elif event is InputEventMouseMotion and dragging_pin and selected_pin >= 0:
		_set_pin_from_screen(selected_pin, event.position)
		queue_redraw()
	elif event is InputEventMouseMotion and dragging_output_edge and selected_output_edge.size() == 2:
		_move_output_edge_by_stage_delta(_screen_delta_to_stage(event.relative))
		queue_redraw()
	elif event is InputEventMouseMotion:
		_update_hover_state(event.position)
	elif event is InputEventKey and event.pressed:
		if _handle_global_key(event):
			return
		var delta := _arrow_delta(event)
		if delta == Vector2.ZERO:
			return
		if edit_mode == "input":
			if selected_input_corner >= 0:
				input_corners[selected_input_corner] = _clamp_input_corner(input_corners[selected_input_corner] + delta)
				queue_redraw()
			elif selected_input_edge >= 0:
				_move_input_edge_by_pixel_delta(delta)
				queue_redraw()
		else:
			if selected_pin >= 0:
				pins[selected_pin]["target"] = _clamp_target(pins[selected_pin]["target"] + delta)
				queue_redraw()
			elif selected_output_edge.size() == 2:
				_move_output_edge_by_stage_delta(delta)
				queue_redraw()

func _arrow_delta(event: InputEventKey) -> Vector2:
	var step := 1.0
	if event.shift_pressed:
		step = 10.0
	var delta := Vector2.ZERO
	if event.keycode == KEY_LEFT:
		delta.x = -step
	elif event.keycode == KEY_RIGHT:
		delta.x = step
	elif event.keycode == KEY_UP:
		delta.y = -step
	elif event.keycode == KEY_DOWN:
		delta.y = step
	return delta

func _update_hover_state(screen_pos: Vector2) -> void:
	var old_hovered_pin := hovered_pin
	var old_hovered_input_corner := hovered_input_corner
	var old_hovered_input_edge := hovered_input_edge
	var old_hovered_output_edge := hovered_output_edge.duplicate()
	hovered_pin = -1
	hovered_input_corner = -1
	hovered_input_edge = -1
	hovered_output_edge.clear()
	if preview_rect.has_point(screen_pos):
		if edit_mode == "input":
			hovered_input_corner = _nearest_input_corner_index(screen_pos)
			if hovered_input_corner < 0:
				hovered_input_edge = _nearest_input_edge_index(screen_pos)
		else:
			hovered_pin = _nearest_pin_index(screen_pos)
			if hovered_pin < 0:
				hovered_output_edge = _nearest_output_edge(screen_pos)
	if old_hovered_pin != hovered_pin or old_hovered_input_corner != hovered_input_corner or old_hovered_input_edge != hovered_input_edge or not _edge_matches(old_hovered_output_edge, hovered_output_edge):
		queue_redraw()

func _screen_delta_to_stage(screen_delta: Vector2) -> Vector2:
	if preview_rect.size.x <= 0.0 or preview_rect.size.y <= 0.0:
		return Vector2.ZERO
	return Vector2(
		(screen_delta.x / preview_rect.size.x) * (CANONICAL_SIZE.x - 1.0),
		(screen_delta.y / preview_rect.size.y) * (CANONICAL_SIZE.y - 1.0)
	)

func _screen_delta_to_input_pixels(screen_delta: Vector2) -> Vector2:
	if reference_texture == null:
		return Vector2.ZERO
	var tex_size: Vector2 = reference_texture.get_size()
	var image_rect := input_image_rect
	if image_rect.size.x <= 0.0 or image_rect.size.y <= 0.0:
		image_rect = _reference_fit_rect(preview_rect, tex_size)
	if image_rect.size.x <= 0.0 or image_rect.size.y <= 0.0:
		return Vector2.ZERO
	return Vector2(
		(screen_delta.x / image_rect.size.x) * tex_size.x,
		(screen_delta.y / image_rect.size.y) * tex_size.y
	)

func _move_input_edge_by_pixel_delta(delta: Vector2) -> void:
	var indices := _input_edge_indices(selected_input_edge)
	if indices.size() != 2:
		return
	for index in indices:
		input_corners[index] = _clamp_input_corner(input_corners[index] + delta)

func _move_output_edge_by_stage_delta(delta: Vector2) -> void:
	if selected_output_edge.size() != 2:
		return
	for index in selected_output_edge:
		var pin_index := int(index)
		pins[pin_index]["target"] = _clamp_target(pins[pin_index]["target"] + delta)

func _input_edge_indices(edge_index: int) -> Array:
	if edge_index == 0:
		return [0, 1]
	if edge_index == 1:
		return [1, 2]
	if edge_index == 2:
		return [2, 3]
	if edge_index == 3:
		return [3, 0]
	return []

func _edge_matches(a: Array, b: Array) -> bool:
	if a.size() != 2 or b.size() != 2:
		return a.size() == b.size()
	return (int(a[0]) == int(b[0]) and int(a[1]) == int(b[1])) or (int(a[0]) == int(b[1]) and int(a[1]) == int(b[0]))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, true)
	preview_rect = _stage_view_rect(Rect2(Vector2.ZERO, size))
	if edit_mode == "input":
		_draw_input_view(preview_rect)
	else:
		_draw_reference(preview_rect)
		_draw_test_pattern(preview_rect)
		_draw_mesh(preview_rect)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _build_ui() -> void:
	collapsed_tab = Button.new()
	collapsed_tab.text = "Calibrate"
	collapsed_tab.visible = false
	collapsed_tab.custom_minimum_size = Vector2(160, 44)
	collapsed_tab.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	collapsed_tab.offset_left = -204
	collapsed_tab.offset_top = 34
	collapsed_tab.offset_right = -40
	collapsed_tab.offset_bottom = 78
	collapsed_tab.pressed.connect(func():
		_set_panel_collapsed(false)
	)
	add_child(collapsed_tab)

	side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(324, 0)
	side_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	side_panel.offset_left = -364
	side_panel.offset_top = 34
	side_panel.offset_right = -40
	side_panel.offset_bottom = size.y - 40
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.06, 0.068, 0.92)
	sb.border_color = Color(0.0, 0.9, 1.0, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	side_panel.add_theme_stylebox_override("panel", sb)
	add_child(side_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	side_panel.add_child(margin)

	panel_body = VBoxContainer.new()
	panel_body.add_theme_constant_override("separation", 14)
	panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel_body)

	scene_select = OptionButton.new()
	scene_select.custom_minimum_size = Vector2(0, 44)
	for option in scene_options:
		scene_select.add_item(option["label"])
	scene_select.item_selected.connect(_set_scene_index)
	panel_body.add_child(scene_select)
	_select_current_scene_option()
	_rebuild_reference_select()

	_add_panel_spacer(panel_body)

	var center_controls := VBoxContainer.new()
	center_controls.add_theme_constant_override("separation", 14)
	panel_body.add_child(center_controls)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	center_controls.add_child(mode_row)

	output_mode_btn = Button.new()
	output_mode_btn.text = "Output"
	output_mode_btn.toggle_mode = true
	output_mode_btn.custom_minimum_size = Vector2(120, 44)
	output_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_mode_btn.pressed.connect(func():
		_set_edit_mode("output")
	)
	mode_row.add_child(output_mode_btn)

	input_mode_btn = Button.new()
	input_mode_btn.text = "Input"
	input_mode_btn.toggle_mode = true
	input_mode_btn.custom_minimum_size = Vector2(120, 44)
	input_mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_mode_btn.pressed.connect(func():
		_set_edit_mode("input")
	)
	mode_row.add_child(input_mode_btn)

	output_controls = VBoxContainer.new()
	output_controls.add_theme_constant_override("separation", 10)
	center_controls.add_child(output_controls)

	_add_subdivision_row(output_controls, "H")
	_add_subdivision_row(output_controls, "V")

	_add_panel_button(output_controls, "Match Input", _match_output_to_input)
	_add_panel_button(output_controls, "Match Source", _match_output_to_source)
	_add_panel_button(output_controls, "Match Screen", _match_output_to_screen)

	input_controls = VBoxContainer.new()
	input_controls.add_theme_constant_override("separation", 10)
	center_controls.add_child(input_controls)

	_add_panel_button(input_controls, "Match Source", _match_input_to_source)
	_add_panel_button(input_controls, "Match Output", _match_input_to_output)
	_add_panel_button(input_controls, "Match Screen", _match_input_to_screen)

	_add_panel_spacer(panel_body)

	var bottom_controls := VBoxContainer.new()
	bottom_controls.add_theme_constant_override("separation", 14)
	panel_body.add_child(bottom_controls)

	save_btn = Button.new()
	save_btn.text = "Save To Scene"
	save_btn.custom_minimum_size = Vector2(0, 52)
	save_btn.pressed.connect(_save_current_profile)
	bottom_controls.add_child(save_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 48)
	close_btn.pressed.connect(func():
		closed.emit()
		queue_free()
	)
	bottom_controls.add_child(close_btn)

	save_btn.grab_focus()

func _add_panel_spacer(parent: VBoxContainer) -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	return spacer

func _add_panel_button(parent: VBoxContainer, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _add_subdivision_row(parent: VBoxContainer, axis: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var axis_label := Label.new()
	axis_label.text = axis
	axis_label.custom_minimum_size = Vector2(28, 44)
	axis_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	axis_label.add_theme_font_size_override("font_size", 22)
	axis_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.25))
	row.add_child(axis_label)

	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(56, 44)
	minus_btn.pressed.connect(func():
		_change_subdivision_axis(axis, -1)
	)
	row.add_child(minus_btn)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(56, 44)
	plus_btn.pressed.connect(func():
		_change_subdivision_axis(axis, 1)
	)
	row.add_child(plus_btn)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(42, 44)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.25))
	row.add_child(value_label)
	if axis == "H":
		h_subdivision_label = value_label
	else:
		v_subdivision_label = value_label

func _draw_test_pattern(rect: Rect2) -> void:
	var warped_corners := PackedVector2Array([
		_warp_canonical_to_screen(Vector2(0, 0), rect),
		_warp_canonical_to_screen(Vector2(CANONICAL_SIZE.x - 1.0, 0), rect),
		_warp_canonical_to_screen(Vector2(CANONICAL_SIZE.x - 1.0, CANONICAL_SIZE.y - 1.0), rect),
		_warp_canonical_to_screen(Vector2(0, CANONICAL_SIZE.y - 1.0), rect)
	])
	draw_polyline(warped_corners, Color(0.0, 0.9, 1.0), 2.0, true)
	var cols := 16
	var rows := 9
	for col in range(cols + 1):
		var x := (CANONICAL_SIZE.x - 1.0) * (float(col) / float(cols))
		var color := Color(0.0, 0.9, 1.0, 0.35 if col % 4 == 0 else 0.16)
		draw_line(_warp_canonical_to_screen(Vector2(x, 0), rect), _warp_canonical_to_screen(Vector2(x, CANONICAL_SIZE.y - 1.0), rect), color, 1.0)
	for row in range(rows + 1):
		var y := (CANONICAL_SIZE.y - 1.0) * (float(row) / float(rows))
		var color := Color(1.0, 1.0, 1.0, 0.32 if row % 3 == 0 else 0.13)
		draw_line(_warp_canonical_to_screen(Vector2(0, y), rect), _warp_canonical_to_screen(Vector2(CANONICAL_SIZE.x - 1.0, y), rect), color, 1.0)
	draw_line(_warp_canonical_to_screen(Vector2.ZERO, rect), _warp_canonical_to_screen(CANONICAL_SIZE - Vector2.ONE, rect), Color(1, 0, 0.75, 0.55), 1.5)
	draw_line(_warp_canonical_to_screen(Vector2(CANONICAL_SIZE.x - 1.0, 0), rect), _warp_canonical_to_screen(Vector2(0, CANONICAL_SIZE.y - 1.0), rect), Color(1, 0, 0.75, 0.55), 1.5)

func _draw_reference(rect: Rect2) -> void:
	if reference_texture == null:
		return
	var tex_size: Vector2 = reference_texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	_ensure_input_corners(tex_size)
	var samples_x: int = max(12, mesh_cols * 8)
	var samples_y: int = max(8, mesh_rows * 8)
	var color: Color = Color(1, 1, 1, reference_opacity)
	for row in range(samples_y):
		var v0: float = float(row) / float(samples_y)
		var v1: float = float(row + 1) / float(samples_y)
		for col in range(samples_x):
			var u0: float = float(col) / float(samples_x)
			var u1: float = float(col + 1) / float(samples_x)
			var p00 := Vector2(u0 * (CANONICAL_SIZE.x - 1.0), v0 * (CANONICAL_SIZE.y - 1.0))
			var p10 := Vector2(u1 * (CANONICAL_SIZE.x - 1.0), v0 * (CANONICAL_SIZE.y - 1.0))
			var p11 := Vector2(u1 * (CANONICAL_SIZE.x - 1.0), v1 * (CANONICAL_SIZE.y - 1.0))
			var p01 := Vector2(u0 * (CANONICAL_SIZE.x - 1.0), v1 * (CANONICAL_SIZE.y - 1.0))
			var uv00 := _input_quad_uv(u0, v0, tex_size)
			var uv10 := _input_quad_uv(u1, v0, tex_size)
			var uv11 := _input_quad_uv(u1, v1, tex_size)
			var uv01 := _input_quad_uv(u0, v1, tex_size)
			_draw_textured_triangle(p00, p10, p11, uv00, uv10, uv11, rect, color)
			_draw_textured_triangle(p00, p11, p01, uv00, uv11, uv01, rect, color)

func _draw_textured_triangle(a: Vector2, b: Vector2, c: Vector2, auv: Vector2, buv: Vector2, cuv: Vector2, rect: Rect2, color: Color) -> void:
	draw_polygon(
		PackedVector2Array([_warp_canonical_to_screen(a, rect), _warp_canonical_to_screen(b, rect), _warp_canonical_to_screen(c, rect)]),
		PackedColorArray([color, color, color]),
		PackedVector2Array([auv, buv, cuv]),
		reference_texture
	)

func _reference_fit_rect(rect: Rect2, tex_size: Vector2) -> Rect2:
	var scale: float = min(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size: Vector2 = tex_size * scale
	var draw_pos: Vector2 = rect.position + (rect.size - draw_size) * 0.5
	return Rect2(draw_pos, draw_size)

func _stage_view_rect(bounds: Rect2) -> Rect2:
	return _aspect_fit_rect(bounds.position, bounds.size, CANONICAL_SIZE.x / CANONICAL_SIZE.y)

func _draw_input_view(rect: Rect2) -> void:
	if reference_texture == null:
		return
	var tex_size: Vector2 = reference_texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	_ensure_input_corners(tex_size)
	input_image_rect = _reference_fit_rect(rect, tex_size)
	draw_texture_rect(reference_texture, input_image_rect, false, Color(1, 1, 1, 0.92))
	_draw_input_crop_overlay(input_image_rect, tex_size)

func _draw_input_crop_overlay(image_rect: Rect2, tex_size: Vector2) -> void:
	if input_corners.size() != 4:
		return
	var color := Color(0.25, 1.0, 0.15, 0.92)
	for edge_index in range(4):
		var indices := _input_edge_indices(edge_index)
		var a := _input_pixel_to_view(input_corners[indices[0]], image_rect, tex_size)
		var b := _input_pixel_to_view(input_corners[indices[1]], image_rect, tex_size)
		var edge_color := color
		var width := 2.0
		if edge_index == selected_input_edge:
			edge_color = Color(1.0, 0.9, 0.12, 1.0)
			width = 4.0
		elif edge_index == hovered_input_edge:
			edge_color = Color(0.85, 1.0, 0.85, 1.0)
			width = 3.0
		draw_line(a, b, edge_color, width)
	for i in range(input_corners.size()):
		var pos: Vector2 = _input_pixel_to_view(input_corners[i], image_rect, tex_size)
		var radius := 6.0
		if i == selected_input_corner:
			radius = 9.0
		elif i == hovered_input_corner:
			radius = 8.0
		var point_color := color
		if i == selected_input_corner:
			point_color = Color(1.0, 0.9, 0.12, 1.0)
		elif i == hovered_input_corner:
			point_color = Color(0.85, 1.0, 0.85, 1.0)
		draw_circle(pos, radius + 3.0, Color.BLACK)
		draw_circle(pos, radius, point_color)

func _draw_mesh(rect: Rect2) -> void:
	for row in range(mesh_rows):
		for col in range(mesh_cols - 1):
			var a_idx := row * mesh_cols + col
			var b_idx := row * mesh_cols + col + 1
			var a := _screen_from_target(_pin_at(col, row)["target"], rect)
			var b := _screen_from_target(_pin_at(col + 1, row)["target"], rect)
			_draw_output_edge_line(a, b, [a_idx, b_idx])
	for col in range(mesh_cols):
		for row in range(mesh_rows - 1):
			var a_idx := row * mesh_cols + col
			var b_idx := (row + 1) * mesh_cols + col
			var a := _screen_from_target(_pin_at(col, row)["target"], rect)
			var b := _screen_from_target(_pin_at(col, row + 1)["target"], rect)
			_draw_output_edge_line(a, b, [a_idx, b_idx])
	for i in range(pins.size()):
		var pos := _screen_from_target(pins[i]["target"], rect)
		var radius := 7.0
		if i == selected_pin:
			radius = 10.0
		elif i == hovered_pin:
			radius = 9.0
		var color := Color(1.0, 0.85, 0.12) if pins[i]["role"] == "corner" else Color(0.0, 0.9, 1.0)
		if pins[i]["role"] == "interior":
			color = Color(1.0, 0.2, 0.8)
		if i == selected_pin:
			color = Color(1.0, 0.9, 0.12, 1.0)
		elif i == hovered_pin:
			color = Color(0.9, 1.0, 1.0, 1.0)
		draw_circle(pos, radius + 3.0, Color(0, 0, 0, 0.75))
		draw_circle(pos, radius, color)

func _draw_output_edge_line(a: Vector2, b: Vector2, edge: Array) -> void:
	var edge_color := Color(0.0, 0.9, 1.0, 0.8)
	var width := 2.0
	if _edge_matches(edge, selected_output_edge):
		edge_color = Color(1.0, 0.9, 0.12, 1.0)
		width = 4.0
	elif _edge_matches(edge, hovered_output_edge):
		edge_color = Color(0.9, 1.0, 1.0, 1.0)
		width = 3.0
	draw_line(a, b, edge_color, width)

func _reset_mesh(cols: int, rows: int) -> void:
	mesh_cols = cols
	mesh_rows = rows
	selected_pin = -1
	hovered_pin = -1
	selected_output_edge.clear()
	hovered_output_edge.clear()
	pins.clear()
	for row in range(rows):
		for col in range(cols):
			pins.append(_make_pin(col, row, cols, rows, _grid_point(col, row, cols, rows)))

func _resample_mesh(cols: int, rows: int) -> void:
	if pins.is_empty() or mesh_cols < 2 or mesh_rows < 2:
		_reset_mesh(cols, rows)
		return
	var old_pins: Array = pins.duplicate(true)
	var old_cols := mesh_cols
	var old_rows := mesh_rows
	mesh_cols = cols
	mesh_rows = rows
	selected_pin = -1
	hovered_pin = -1
	selected_output_edge.clear()
	hovered_output_edge.clear()
	pins.clear()
	for row in range(rows):
		for col in range(cols):
			var source := _grid_point(col, row, cols, rows)
			var target := _warp_target_from_grid(source, old_pins, old_cols, old_rows)
			pins.append(_make_pin(col, row, cols, rows, target))

func _make_pin(col: int, row: int, cols: int, rows: int, target: Vector2) -> Dictionary:
	var source := _grid_point(col, row, cols, rows)
	var edge := row == 0 or col == 0 or row == rows - 1 or col == cols - 1
	var corner := (row == 0 or row == rows - 1) and (col == 0 or col == cols - 1)
	return {
		"id": "r%d_c%d" % [row, col],
		"row": row,
		"col": col,
		"source": source,
		"target": _clamp_target(target),
		"role": "corner" if corner else "edge" if edge else "interior"
	}

func _grid_point(col: int, row: int, cols: int, rows: int) -> Vector2:
	return Vector2(
		(CANONICAL_SIZE.x - 1.0) * (float(col) / float(cols - 1)),
		(CANONICAL_SIZE.y - 1.0) * (float(row) / float(rows - 1))
	)

func _points_for_subdivision_level(level: int) -> int:
	return int(pow(2.0, float(level - 1))) + 1

func _subdivision_level_for_points(points: int) -> int:
	var best_level: int = MIN_SUBDIVISION_LEVEL
	var best_delta: int = 999
	for level in range(MIN_SUBDIVISION_LEVEL, MAX_SUBDIVISION_LEVEL + 1):
		var delta: int = abs(points - _points_for_subdivision_level(level))
		if delta < best_delta:
			best_delta = delta
			best_level = level
	return best_level

func _change_subdivision_axis(axis: String, delta: int) -> void:
	var current_level := _subdivision_level_for_points(mesh_cols if axis == "H" else mesh_rows)
	var next_level: int = int(clamp(current_level + delta, MIN_SUBDIVISION_LEVEL, MAX_SUBDIVISION_LEVEL))
	if next_level == current_level:
		return
	var target_cols := mesh_cols
	var target_rows := mesh_rows
	if axis == "H":
		target_cols = _points_for_subdivision_level(next_level)
	else:
		target_rows = _points_for_subdivision_level(next_level)
	_resample_mesh(target_cols, target_rows)
	_update_status()
	queue_redraw()

func _load_or_reset_profile() -> void:
	input_corners.clear()
	var path := _current_calibration_path()
	if not FileAccess.file_exists(path):
		_reset_mesh(2, 2)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_reset_mesh(2, 2)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("schema", "") != PROFILE_SCHEMA:
		_reset_mesh(2, 2)
		return
	var warp = parsed.get("warp", {})
	if typeof(warp) != TYPE_DICTIONARY:
		_reset_mesh(2, 2)
		return
	var mesh_size = warp.get("mesh_size", [2, 2])
	var loaded_pins = warp.get("pins", [])
	if typeof(mesh_size) != TYPE_ARRAY or mesh_size.size() != 2 or typeof(loaded_pins) != TYPE_ARRAY:
		_reset_mesh(2, 2)
		return
	mesh_cols = int(mesh_size[0])
	mesh_rows = int(mesh_size[1])
	pins.clear()
	for pin in loaded_pins:
		if typeof(pin) != TYPE_DICTIONARY:
			continue
		pins.append({
			"id": str(pin.get("id", "")),
			"row": int(pin.get("row", 0)),
			"col": int(pin.get("col", 0)),
			"source": _point_from_array(pin.get("source", [0, 0])),
			"target": _point_from_array(pin.get("target", [0, 0])),
			"role": str(pin.get("role", "interior"))
		})
	if pins.size() != mesh_cols * mesh_rows:
		_reset_mesh(2, 2)
	var input = parsed.get("input", {})
	if typeof(input) == TYPE_DICTIONARY:
		var input_mode := str(input.get("mode", ""))
		var loaded_input_corners = input.get("corners", [])
		if input_mode == "source_crop" and typeof(loaded_input_corners) == TYPE_ARRAY and loaded_input_corners.size() == 4:
			input_corners.clear()
			for corner in loaded_input_corners:
				input_corners.append(_point_from_array(corner))
		reference_opacity = float(input.get("reference_opacity", reference_opacity))

func _save_current_profile() -> void:
	if input_corners.is_empty() and reference_texture != null:
		_ensure_input_corners(reference_texture.get_size())
	var path := _current_calibration_path()
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var profile := {
		"schema": PROFILE_SCHEMA,
		"version": PROFILE_VERSION,
		"profile_id": scene_id + "_current",
		"label": scene_id + " Current",
		"scope": "scene_current",
		"scene_id": scene_id,
		"updated_at_unix": int(Time.get_unix_time_from_system()),
		"source_space": {"name": "canonical_frame", "width": int(CANONICAL_SIZE.x), "height": int(CANONICAL_SIZE.y)},
		"input": {"mode": "source_crop", "space": "image_pixels", "image_size": [int(reference_image_size.x), int(reference_image_size.y)], "corners": _input_corners_for_save(), "reference_opacity": reference_opacity},
		"output": {"display_index": 0, "native_resolution": [int(CANONICAL_SIZE.x), int(CANONICAL_SIZE.y)]},
		"workflow": {"apply_to": "final_output_frame", "operator_view": "fullscreen_overlay"},
		"warp": {"mode": "mesh", "mesh_size": [mesh_cols, mesh_rows], "interpolation": "piecewise_bilinear", "pins": _pins_for_save()}
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_set_status("Save failed: " + path)
		return
	file.store_string(JSON.stringify(profile, "\t"))
	file.close()
	_set_status("Saved " + scene_id + " calibration/current.yaml")

func _pins_for_save() -> Array:
	var out := []
	for pin in pins:
		out.append({
			"id": pin["id"],
			"row": pin["row"],
			"col": pin["col"],
			"source": [round(pin["source"].x * 1000.0) / 1000.0, round(pin["source"].y * 1000.0) / 1000.0],
			"target": [round(pin["target"].x * 1000.0) / 1000.0, round(pin["target"].y * 1000.0) / 1000.0],
			"role": pin["role"]
		})
	return out

func _input_corners_for_save() -> Array:
	var out := []
	for corner in input_corners:
		out.append([round(corner.x * 1000.0) / 1000.0, round(corner.y * 1000.0) / 1000.0])
	return out

func _current_calibration_path() -> String:
	var root := base_dir
	if root == "":
		root = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	return root.path_join("content/scenes").path_join(scene_id).path_join("calibration/current.yaml")

func _nearest_pin_index(screen_pos: Vector2) -> int:
	var best := -1
	var best_d := 999999.0
	for i in range(pins.size()):
		var pos := _screen_from_target(pins[i]["target"], preview_rect)
		var d := pos.distance_squared_to(screen_pos)
		if d < best_d:
			best_d = d
			best = i
	return best if best_d <= 1600.0 else -1

func _nearest_output_edge(screen_pos: Vector2) -> Array:
	var best: Array = []
	var best_d := 999999.0
	for row in range(mesh_rows):
		for col in range(mesh_cols - 1):
			var a_idx := row * mesh_cols + col
			var b_idx := row * mesh_cols + col + 1
			var a := _screen_from_target(pins[a_idx]["target"], preview_rect)
			var b := _screen_from_target(pins[b_idx]["target"], preview_rect)
			var d := _distance_to_segment_squared(screen_pos, a, b)
			if d < best_d:
				best_d = d
				best = [a_idx, b_idx]
	for col in range(mesh_cols):
		for row in range(mesh_rows - 1):
			var a_idx := row * mesh_cols + col
			var b_idx := (row + 1) * mesh_cols + col
			var a := _screen_from_target(pins[a_idx]["target"], preview_rect)
			var b := _screen_from_target(pins[b_idx]["target"], preview_rect)
			var d := _distance_to_segment_squared(screen_pos, a, b)
			if d < best_d:
				best_d = d
				best = [a_idx, b_idx]
	return best if best_d <= 196.0 else []

func _set_pin_from_screen(pin_index: int, screen_pos: Vector2) -> void:
	var local := (screen_pos - preview_rect.position) / preview_rect.size
	var target := Vector2(local.x * (CANONICAL_SIZE.x - 1.0), local.y * (CANONICAL_SIZE.y - 1.0))
	pins[pin_index]["target"] = _clamp_target(target)

func _set_input_corner_from_screen(corner_index: int, screen_pos: Vector2) -> void:
	if reference_texture == null:
		return
	var tex_size: Vector2 = reference_texture.get_size()
	var image_rect := input_image_rect
	if image_rect.size.x <= 0.0 or image_rect.size.y <= 0.0:
		image_rect = _reference_fit_rect(preview_rect, tex_size)
	var local := (screen_pos - image_rect.position) / image_rect.size
	var target := Vector2(local.x * tex_size.x, local.y * tex_size.y)
	input_corners[corner_index] = _clamp_input_corner(target)

func _screen_from_target(target: Vector2, rect: Rect2) -> Vector2:
	return rect.position + Vector2(
		(target.x / (CANONICAL_SIZE.x - 1.0)) * rect.size.x,
		(target.y / (CANONICAL_SIZE.y - 1.0)) * rect.size.y
	)

func _warp_canonical_to_screen(canonical: Vector2, rect: Rect2) -> Vector2:
	return _screen_from_target(_warp_target_from_grid(canonical, pins, mesh_cols, mesh_rows), rect)

func _warp_target_from_grid(canonical: Vector2, grid_pins: Array, cols: int, rows: int) -> Vector2:
	if grid_pins.size() != cols * rows or cols < 2 or rows < 2:
		return _clamp_target(canonical)
	var nx: float = clamp(canonical.x / (CANONICAL_SIZE.x - 1.0), 0.0, 1.0)
	var ny: float = clamp(canonical.y / (CANONICAL_SIZE.y - 1.0), 0.0, 1.0)
	var fx: float = nx * float(cols - 1)
	var fy: float = ny * float(rows - 1)
	var col: int = min(cols - 2, max(0, int(floor(fx))))
	var row: int = min(rows - 2, max(0, int(floor(fy))))
	var tx: float = fx - float(col)
	var ty: float = fy - float(row)
	var p00: Vector2 = grid_pins[row * cols + col]["target"]
	var p10: Vector2 = grid_pins[row * cols + col + 1]["target"]
	var p01: Vector2 = grid_pins[(row + 1) * cols + col]["target"]
	var p11: Vector2 = grid_pins[(row + 1) * cols + col + 1]["target"]
	var top: Vector2 = p00.lerp(p10, tx)
	var bottom: Vector2 = p01.lerp(p11, tx)
	return top.lerp(bottom, ty)

func _pin_at(col: int, row: int) -> Dictionary:
	return pins[row * mesh_cols + col]

func _point_from_array(value) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO

func _clamp_target(value: Vector2) -> Vector2:
	return Vector2(clamp(value.x, 0.0, CANONICAL_SIZE.x - 1.0), clamp(value.y, 0.0, CANONICAL_SIZE.y - 1.0))

func _clamp_input_corner(value: Vector2) -> Vector2:
	if reference_image_size.x <= 0.0 or reference_image_size.y <= 0.0:
		return value
	return Vector2(clamp(value.x, 0.0, reference_image_size.x), clamp(value.y, 0.0, reference_image_size.y))

func _update_status() -> void:
	if mesh_label:
		mesh_label.text = "Grid: %dx%d pins" % [mesh_cols, mesh_rows]
	if h_subdivision_label:
		h_subdivision_label.text = str(_subdivision_level_for_points(mesh_cols))
	if v_subdivision_label:
		v_subdivision_label.text = str(_subdivision_level_for_points(mesh_rows))
	if edit_mode_label:
		edit_mode_label.text = "View: " + ("Input crop" if edit_mode == "input" else "Output mapping")
	if scene_label:
		scene_label.text = "Scene: " + scene_id
	if input_controls:
		input_controls.visible = edit_mode == "input"
	if output_controls:
		output_controls.visible = edit_mode == "output"
	_update_mode_buttons()
	_set_status("%d pins ready" % pins.size())

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _update_mode_buttons() -> void:
	_style_mode_button(input_mode_btn, edit_mode == "input")
	_style_mode_button(output_mode_btn, edit_mode == "output")

func _style_mode_button(button: Button, active: bool) -> void:
	if button == null:
		return
	button.button_pressed = active
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.55, 0.65, 0.95) if active else Color(0.08, 0.085, 0.095, 0.92)
	style.border_color = Color(0.0, 0.95, 1.0, 0.95) if active else Color(0.0, 0.45, 0.55, 0.55)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_color_override("font_color", Color.WHITE if active else Color(0.82, 0.86, 0.88))

func _handle_global_key(event: InputEventKey) -> bool:
	if event.keycode == KEY_F11:
		_toggle_calibration_fullscreen()
		return true
	if event.keycode == KEY_H:
		if side_panel:
			_set_panel_collapsed(side_panel.visible)
		queue_redraw()
		return true
	return false

func _is_fullscreen_mode() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func _fullscreen_button_text() -> String:
	return "Exit Full Screen (F11)" if _is_fullscreen_mode() else "Full Screen (F11)"

func _toggle_calibration_fullscreen() -> void:
	if _is_fullscreen_mode():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if fullscreen_btn:
		fullscreen_btn.text = _fullscreen_button_text()
	queue_redraw()

func _set_controls_visible(value: bool) -> void:
	show_controls = value
	if side_panel:
		side_panel.visible = show_controls
	if title_label:
		title_label.visible = show_controls
	if collapsed_tab:
		collapsed_tab.visible = false

func _set_panel_collapsed(value: bool) -> void:
	if side_panel:
		side_panel.visible = not value
	if collapsed_tab:
		collapsed_tab.visible = value
	if title_label:
		title_label.visible = not value
	show_controls = not value

func _on_panel_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		panel_dragging = event.pressed
	elif event is InputEventMouseMotion and panel_dragging and side_panel:
		side_panel.offset_left += event.relative.x
		side_panel.offset_right += event.relative.x
		side_panel.offset_top += event.relative.y
		side_panel.offset_bottom += event.relative.y

func _scan_reference_options() -> void:
	reference_options.clear()
	reference_options.append({"label": "Test Pattern Only", "path": ""})
	var scene_dir: String = _scene_dir()
	var scene_label_text: String = _scene_display_label(scene_id)
	if _add_reference_option(scene_label_text + " calibration reference", scene_dir.path_join("calibration/reference.png")):
		return
	for name in ["background.png", "reference.png", "photo.png", "thumbnail.png"]:
		if _add_reference_option(scene_label_text + " reference", scene_dir.path_join(name)):
			return
	var scene_yaml_ref := _read_simple_yaml_value(scene_dir.path_join("scene.yaml"), "reference_image")
	if scene_yaml_ref != "":
		if _add_reference_option(scene_label_text + " reference", scene_dir.path_join(scene_yaml_ref)):
			return
	var levels_dir := scene_dir.path_join("levels")
	if not DirAccess.dir_exists_absolute(levels_dir):
		return
	var dir := DirAccess.open(levels_dir)
	if not dir:
		return
	var level_names := []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			level_names.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	level_names.sort()
	if active_level_id != "" and level_names.has(active_level_id):
		level_names.erase(active_level_id)
		level_names.push_front(active_level_id)
	for level_name in level_names:
		var level_dir := levels_dir.path_join(level_name)
		var yaml_path := level_dir.path_join("level.yaml")
		var ref_name := _read_simple_yaml_value(yaml_path, "reference_image")
		if ref_name != "":
			if _add_reference_option(scene_label_text + " reference", level_dir.path_join(ref_name)):
				return
		if _add_reference_option(scene_label_text + " reference", level_dir.path_join("background.png")):
			return
	if level_names.size() > 0:
		var semantic_dir := levels_dir.path_join(str(level_names[0]))
		_add_reference_option(scene_label_text + " semantic map", semantic_dir.path_join("semantic_map.png"))

func _add_reference_option(label: String, path: String) -> bool:
	if path == "" or not FileAccess.file_exists(path):
		return false
	for option in reference_options:
		if option["path"] == path:
			return false
	reference_options.append({"label": label, "path": path})
	return true

func _set_reference_index(idx: int) -> void:
	reference_texture = null
	reference_image_size = Vector2.ZERO
	if idx < 0 or idx >= reference_options.size():
		queue_redraw()
		return
	var path := str(reference_options[idx]["path"])
	if path == "":
		_set_status("%d pins ready" % pins.size())
		queue_redraw()
		return
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		_set_status("Reference failed: " + path.get_file())
		queue_redraw()
		return
	reference_texture = ImageTexture.create_from_image(image)
	reference_image_size = reference_texture.get_size()
	_ensure_input_corners(reference_texture.get_size())
	_set_status("Reference: " + path.get_file())
	queue_redraw()

func _set_edit_mode(mode: String) -> void:
	edit_mode = mode
	selected_pin = -1
	selected_input_corner = -1
	hovered_pin = -1
	hovered_input_corner = -1
	selected_output_edge.clear()
	hovered_output_edge.clear()
	selected_input_edge = -1
	hovered_input_edge = -1
	dragging_pin = false
	dragging_input_corner = false
	dragging_output_edge = false
	dragging_input_edge = false
	_update_status()
	queue_redraw()

func _ensure_input_corners(tex_size: Vector2) -> void:
	reference_image_size = tex_size
	if input_corners.size() == 4:
		for i in range(input_corners.size()):
			input_corners[i] = _clamp_input_corner(input_corners[i])
		return
	input_corners = [
		Vector2.ZERO,
		Vector2(tex_size.x, 0),
		tex_size,
		Vector2(0, tex_size.y)
	]

func _reset_input_mask() -> void:
	input_corners.clear()
	if reference_texture != null:
		_ensure_input_corners(reference_texture.get_size())
	else:
		input_corners = []
	selected_input_corner = -1
	hovered_input_corner = -1
	selected_input_edge = -1
	hovered_input_edge = -1
	_set_status("Input crop reset")

func _match_input_to_source() -> void:
	_reset_input_mask()
	queue_redraw()

func _match_input_to_screen() -> void:
	_set_input_to_center_aspect(CANONICAL_SIZE.x / CANONICAL_SIZE.y)

func _match_input_to_output() -> void:
	if reference_texture == null or pins.size() != mesh_cols * mesh_rows or mesh_cols < 2 or mesh_rows < 2:
		return
	input_corners = [
		_stage_to_image_pixel(_pin_at(0, 0)["target"]),
		_stage_to_image_pixel(_pin_at(mesh_cols - 1, 0)["target"]),
		_stage_to_image_pixel(_pin_at(mesh_cols - 1, mesh_rows - 1)["target"]),
		_stage_to_image_pixel(_pin_at(0, mesh_rows - 1)["target"])
	]
	selected_input_corner = -1
	selected_input_edge = -1
	_update_status()
	queue_redraw()

func _match_output_to_input() -> void:
	if input_corners.size() != 4 or reference_image_size.x <= 0.0 or reference_image_size.y <= 0.0:
		_match_output_to_source()
		return
	if pins.is_empty():
		_reset_mesh(2, 2)
	for i in range(pins.size()):
		var source: Vector2 = pins[i]["source"]
		var u: float = clamp(source.x / (CANONICAL_SIZE.x - 1.0), 0.0, 1.0)
		var v: float = clamp(source.y / (CANONICAL_SIZE.y - 1.0), 0.0, 1.0)
		pins[i]["target"] = _clamp_target(_input_crop_stage_point(u, v))
	selected_pin = -1
	selected_output_edge.clear()
	_update_status()
	queue_redraw()

func _match_output_to_source() -> void:
	if reference_image_size.x <= 0.0 or reference_image_size.y <= 0.0:
		_match_output_to_screen()
		return
	_set_output_to_rect(_source_stage_rect())

func _match_output_to_screen() -> void:
	_set_output_to_rect(Rect2(Vector2.ZERO, _stage_bounds_size()))

func _set_input_to_center_aspect(aspect: float) -> void:
	if reference_texture == null:
		return
	var size: Vector2 = reference_texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0 or aspect <= 0.0:
		return
	reference_image_size = size
	var rect := _aspect_fit_rect(Vector2.ZERO, size, aspect)
	input_corners = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	]
	selected_input_corner = -1
	_update_status()
	queue_redraw()

func _set_output_to_aspect(aspect: float) -> void:
	if aspect <= 0.0:
		_match_output_to_screen()
		return
	_set_output_to_rect(_aspect_fit_rect(Vector2.ZERO, _stage_bounds_size(), aspect))

func _set_output_to_rect(rect: Rect2) -> void:
	if pins.is_empty():
		_reset_mesh(2, 2)
	for i in range(pins.size()):
		var source: Vector2 = pins[i]["source"]
		var nx: float = source.x / (CANONICAL_SIZE.x - 1.0)
		var ny: float = source.y / (CANONICAL_SIZE.y - 1.0)
		pins[i]["target"] = _clamp_target(rect.position + Vector2(rect.size.x * nx, rect.size.y * ny))
	selected_pin = -1
	selected_output_edge.clear()
	_update_status()
	queue_redraw()

func _aspect_fit_rect(origin: Vector2, bounds: Vector2, aspect: float) -> Rect2:
	if bounds.x <= 0.0 or bounds.y <= 0.0 or aspect <= 0.0:
		return Rect2(origin, bounds)
	var draw_size := bounds
	if draw_size.x / draw_size.y > aspect:
		draw_size.x = draw_size.y * aspect
	else:
		draw_size.y = draw_size.x / aspect
	return Rect2(origin + (bounds - draw_size) * 0.5, draw_size)

func _source_stage_rect() -> Rect2:
	if reference_image_size.x <= 0.0 or reference_image_size.y <= 0.0:
		return Rect2(Vector2.ZERO, _stage_bounds_size())
	if preview_rect.size.x > 0.0 and preview_rect.size.y > 0.0:
		var fitted_view_rect := _reference_fit_rect(preview_rect, reference_image_size)
		return _screen_rect_to_stage(fitted_view_rect, preview_rect)
	return _aspect_fit_rect(Vector2.ZERO, _stage_bounds_size(), reference_image_size.x / reference_image_size.y)

func _stage_bounds_size() -> Vector2:
	return CANONICAL_SIZE - Vector2.ONE

func _screen_rect_to_stage(screen_rect: Rect2, containing_rect: Rect2) -> Rect2:
	var top_left := _screen_point_to_stage(screen_rect.position, containing_rect)
	var bottom_right := _screen_point_to_stage(screen_rect.position + screen_rect.size, containing_rect)
	return Rect2(top_left, bottom_right - top_left)

func _screen_point_to_stage(screen_point: Vector2, containing_rect: Rect2) -> Vector2:
	if containing_rect.size.x <= 0.0 or containing_rect.size.y <= 0.0:
		return Vector2.ZERO
	var local := (screen_point - containing_rect.position) / containing_rect.size
	return Vector2(local.x * (CANONICAL_SIZE.x - 1.0), local.y * (CANONICAL_SIZE.y - 1.0))

func _image_pixel_to_stage(pixel: Vector2) -> Vector2:
	if reference_image_size.x <= 0.0 or reference_image_size.y <= 0.0:
		return Vector2.ZERO
	var rect := _source_stage_rect()
	return rect.position + Vector2(
		(pixel.x / reference_image_size.x) * rect.size.x,
		(pixel.y / reference_image_size.y) * rect.size.y
	)

func _stage_to_image_pixel(point: Vector2) -> Vector2:
	if reference_image_size.x <= 0.0 or reference_image_size.y <= 0.0:
		return Vector2.ZERO
	var rect := _source_stage_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2.ZERO
	var local := Vector2(
		(point.x - rect.position.x) / rect.size.x,
		(point.y - rect.position.y) / rect.size.y
	)
	return _clamp_input_corner(Vector2(local.x * reference_image_size.x, local.y * reference_image_size.y))

func _input_crop_stage_point(u: float, v: float) -> Vector2:
	return _image_pixel_to_stage(_input_quad_point(u, v))

func _input_crop_aspect() -> float:
	if input_corners.size() != 4:
		if reference_image_size.y > 0.0:
			return reference_image_size.x / reference_image_size.y
		return CANONICAL_SIZE.x / CANONICAL_SIZE.y
	var top_width: float = input_corners[0].distance_to(input_corners[1])
	var bottom_width: float = input_corners[3].distance_to(input_corners[2])
	var left_height: float = input_corners[0].distance_to(input_corners[3])
	var right_height: float = input_corners[1].distance_to(input_corners[2])
	var avg_width: float = max(1.0, (top_width + bottom_width) * 0.5)
	var avg_height: float = max(1.0, (left_height + right_height) * 0.5)
	return avg_width / avg_height

func _output_target_aspect() -> float:
	if pins.size() != mesh_cols * mesh_rows or mesh_cols < 2 or mesh_rows < 2:
		return CANONICAL_SIZE.x / CANONICAL_SIZE.y
	var top_left: Vector2 = _pin_at(0, 0)["target"]
	var top_right: Vector2 = _pin_at(mesh_cols - 1, 0)["target"]
	var bottom_right: Vector2 = _pin_at(mesh_cols - 1, mesh_rows - 1)["target"]
	var bottom_left: Vector2 = _pin_at(0, mesh_rows - 1)["target"]
	var avg_width: float = max(1.0, (top_left.distance_to(top_right) + bottom_left.distance_to(bottom_right)) * 0.5)
	var avg_height: float = max(1.0, (top_left.distance_to(bottom_left) + top_right.distance_to(bottom_right)) * 0.5)
	return avg_width / avg_height

func _input_quad_point(u: float, v: float) -> Vector2:
	if input_corners.size() != 4:
		return Vector2.ZERO
	var top: Vector2 = input_corners[0].lerp(input_corners[1], u)
	var bottom: Vector2 = input_corners[3].lerp(input_corners[2], u)
	return top.lerp(bottom, v)

func _input_quad_uv(u: float, v: float, tex_size: Vector2) -> Vector2:
	var pixel := _input_quad_point(u, v)
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Vector2.ZERO
	return Vector2(clamp(pixel.x / tex_size.x, 0.0, 1.0), clamp(pixel.y / tex_size.y, 0.0, 1.0))

func _nearest_input_corner_index(screen_pos: Vector2) -> int:
	if input_corners.size() != 4 or reference_texture == null:
		return -1
	var tex_size: Vector2 = reference_texture.get_size()
	var image_rect := input_image_rect
	if image_rect.size.x <= 0.0 or image_rect.size.y <= 0.0:
		image_rect = _reference_fit_rect(preview_rect, tex_size)
	var best := -1
	var best_d := 999999.0
	for i in range(input_corners.size()):
		var pos := _input_pixel_to_view(input_corners[i], image_rect, tex_size)
		var d := pos.distance_squared_to(screen_pos)
		if d < best_d:
			best_d = d
			best = i
	return best if best_d <= 1600.0 else -1

func _nearest_input_edge_index(screen_pos: Vector2) -> int:
	if input_corners.size() != 4 or reference_texture == null:
		return -1
	var tex_size: Vector2 = reference_texture.get_size()
	var image_rect := input_image_rect
	if image_rect.size.x <= 0.0 or image_rect.size.y <= 0.0:
		image_rect = _reference_fit_rect(preview_rect, tex_size)
	var best := -1
	var best_d := 999999.0
	for edge_index in range(4):
		var indices := _input_edge_indices(edge_index)
		var a := _input_pixel_to_view(input_corners[indices[0]], image_rect, tex_size)
		var b := _input_pixel_to_view(input_corners[indices[1]], image_rect, tex_size)
		var d := _distance_to_segment_squared(screen_pos, a, b)
		if d < best_d:
			best_d = d
			best = edge_index
	return best if best_d <= 196.0 else -1

func _distance_to_segment_squared(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(a)
	var t: float = clamp((point - a).dot(ab) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(a + ab * t)

func _input_pixel_to_view(pixel: Vector2, image_rect: Rect2, tex_size: Vector2) -> Vector2:
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return image_rect.position
	return image_rect.position + Vector2((pixel.x / tex_size.x) * image_rect.size.x, (pixel.y / tex_size.y) * image_rect.size.y)

func _read_simple_yaml_value(path: String, key: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with(key + ":"):
			return line.substr(key.length() + 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
	return ""

func _scene_dir() -> String:
	var root := base_dir
	if root == "":
		root = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	return root.path_join("content/scenes").path_join(scene_id)

func _scenes_root() -> String:
	var root := base_dir
	if root == "":
		root = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
	return root.path_join("content/scenes")

func _scan_scene_options() -> void:
	scene_options.clear()
	var scenes_root := _scenes_root()
	var dir := DirAccess.open(scenes_root)
	if not dir:
		scene_options.append({"id": scene_id, "label": scene_id})
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			var yaml_path := scenes_root.path_join(entry).path_join("scene.yaml")
			var label := _read_simple_yaml_value(yaml_path, "venue_name")
			if label == "":
				label = entry
			scene_options.append({"id": entry, "label": label})
		entry = dir.get_next()
	dir.list_dir_end()
	scene_options.sort_custom(func(a, b): return str(a["label"]).naturalnocasecmp_to(str(b["label"])) < 0)
	if scene_options.is_empty():
		scene_options.append({"id": scene_id, "label": scene_id})

func _select_current_scene_option() -> void:
	if scene_select == null:
		return
	for i in range(scene_options.size()):
		if scene_options[i]["id"] == scene_id:
			scene_select.select(i)
			return

func _set_scene_index(idx: int) -> void:
	if idx < 0 or idx >= scene_options.size():
		return
	scene_id = str(scene_options[idx]["id"])
	active_level_id = ""
	_load_or_reset_profile()
	_scan_reference_options()
	_rebuild_reference_select()
	_update_status()
	queue_redraw()

func _rebuild_reference_select() -> void:
	var default_idx := 1 if reference_options.size() > 1 else 0
	if reference_select == null:
		if reference_options.size() > 0:
			_set_reference_index(default_idx)
		return
	reference_select.clear()
	for option in reference_options:
		reference_select.add_item(option["label"])
	if reference_options.size() > 0:
		reference_select.select(default_idx)
		_set_reference_index(default_idx)

func _scene_display_label(id: String) -> String:
	for option in scene_options:
		if option["id"] == id:
			return str(option["label"])
	return id
