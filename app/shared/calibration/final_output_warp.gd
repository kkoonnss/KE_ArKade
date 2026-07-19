extends RefCounted

const PROFILE_SCHEMA := "ke_arkade.calibration_profile"
const DEFAULT_STAGE_SIZE := Vector2(1920.0, 1080.0)

var profile: Dictionary = {}
var profile_path: String = ""
var stage_size: Vector2 = DEFAULT_STAGE_SIZE
var mesh_cols: int = 2
var mesh_rows: int = 2
var pin_grid: Dictionary = {}
var input_image_size: Vector2 = Vector2.ZERO
var input_corners: Array = []
var source_crop_enabled: bool = false
var is_loaded: bool = false

func load_scene(scene_dir: String) -> bool:
	profile = {}
	profile_path = ""
	stage_size = DEFAULT_STAGE_SIZE
	mesh_cols = 2
	mesh_rows = 2
	pin_grid = {}
	input_image_size = Vector2.ZERO
	input_corners = []
	source_crop_enabled = false
	is_loaded = false
	if scene_dir == "":
		return false
	var path := scene_dir.path_join("calibration").path_join("current.yaml")
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("Calibration profile is not valid JSON: " + path)
		return false
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if str(data.get("schema", "")) != PROFILE_SCHEMA:
		push_warning("Calibration profile has unexpected schema: " + path)
		return false
	profile = data
	profile_path = path
	_apply_profile_metadata()
	is_loaded = pin_grid.size() >= 4
	return is_loaded

func draw_final_output(canvas: CanvasItem, texture: Texture2D, output_rect: Rect2) -> void:
	if texture == null:
		return
	if not is_loaded:
		canvas.draw_texture_rect(texture, output_rect, false, Color.WHITE)
		return
	for row in range(mesh_rows - 1):
		for col in range(mesh_cols - 1):
			var p00 := _pin(row, col)
			var p10 := _pin(row, col + 1)
			var p01 := _pin(row + 1, col)
			var p11 := _pin(row + 1, col + 1)
			if p00.is_empty() or p10.is_empty() or p01.is_empty() or p11.is_empty():
				continue
			_draw_triangle(canvas, texture, output_rect, p00, p10, p11)
			_draw_triangle(canvas, texture, output_rect, p00, p11, p01)

func _apply_profile_metadata() -> void:
	var source_space = profile.get("source_space", {})
	if typeof(source_space) == TYPE_DICTIONARY:
		stage_size = Vector2(
			max(1.0, float(source_space.get("width", DEFAULT_STAGE_SIZE.x))),
			max(1.0, float(source_space.get("height", DEFAULT_STAGE_SIZE.y)))
		)
	_apply_input_crop()
	var warp = profile.get("warp", {})
	if typeof(warp) != TYPE_DICTIONARY:
		return
	var mesh_size = warp.get("mesh_size", [2, 2])
	if typeof(mesh_size) == TYPE_ARRAY and mesh_size.size() >= 2:
		mesh_cols = max(2, int(mesh_size[0]))
		mesh_rows = max(2, int(mesh_size[1]))
	var pins = warp.get("pins", [])
	if typeof(pins) != TYPE_ARRAY:
		return
	for pin in pins:
		if typeof(pin) != TYPE_DICTIONARY:
			continue
		var row := int(pin.get("row", -1))
		var col := int(pin.get("col", -1))
		if row < 0 or col < 0:
			continue
		var source := _vector_from_array(pin.get("source", []))
		var target := _vector_from_array(pin.get("target", []))
		pin_grid[_pin_key(row, col)] = {
			"source": source,
			"target": target
		}

func _draw_triangle(canvas: CanvasItem, texture: Texture2D, output_rect: Rect2, a: Dictionary, b: Dictionary, c: Dictionary) -> void:
	var points := PackedVector2Array([
		_stage_to_output(Vector2(a["target"]), output_rect),
		_stage_to_output(Vector2(b["target"]), output_rect),
		_stage_to_output(Vector2(c["target"]), output_rect)
	])
	var uvs := PackedVector2Array([
		_stage_to_texture_uv(Vector2(a["source"])),
		_stage_to_texture_uv(Vector2(b["source"])),
		_stage_to_texture_uv(Vector2(c["source"]))
	])
	canvas.draw_polygon(points, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE]), uvs, texture)

func _stage_to_output(point: Vector2, output_rect: Rect2) -> Vector2:
	var bounds := _stage_bounds_size()
	return output_rect.position + Vector2(
		(point.x / max(1.0, bounds.x)) * output_rect.size.x,
		(point.y / max(1.0, bounds.y)) * output_rect.size.y
	)

func _stage_to_texture_uv(point: Vector2) -> Vector2:
	var sample_point := point
	if source_crop_enabled:
		var bounds := _stage_bounds_size()
		var u: float = clamp(point.x / max(1.0, bounds.x), 0.0, 1.0)
		var v: float = clamp(point.y / max(1.0, bounds.y), 0.0, 1.0)
		sample_point = _input_crop_stage_point(u, v)
	var texture_bounds := _stage_bounds_size()
	return Vector2(
		clamp(sample_point.x / max(1.0, texture_bounds.x), 0.0, 1.0),
		clamp(sample_point.y / max(1.0, texture_bounds.y), 0.0, 1.0)
	)

func _apply_input_crop() -> void:
	input_image_size = Vector2.ZERO
	input_corners = []
	source_crop_enabled = false
	var input = profile.get("input", {})
	if typeof(input) != TYPE_DICTIONARY:
		return
	if str(input.get("mode", "")) != "source_crop":
		return
	var image_size = input.get("image_size", [])
	var corners = input.get("corners", [])
	if typeof(image_size) != TYPE_ARRAY or image_size.size() < 2:
		return
	if typeof(corners) != TYPE_ARRAY or corners.size() != 4:
		return
	input_image_size = Vector2(
		max(1.0, float(image_size[0])),
		max(1.0, float(image_size[1]))
	)
	for corner in corners:
		input_corners.append(_vector_from_array(corner))
	source_crop_enabled = input_corners.size() == 4 and input_image_size.x > 0.0 and input_image_size.y > 0.0

func _input_crop_stage_point(u: float, v: float) -> Vector2:
	return _image_pixel_to_stage(_input_quad_point(u, v))

func _input_quad_point(u: float, v: float) -> Vector2:
	if input_corners.size() != 4:
		return Vector2.ZERO
	var top: Vector2 = input_corners[0].lerp(input_corners[1], u)
	var bottom: Vector2 = input_corners[3].lerp(input_corners[2], u)
	return top.lerp(bottom, v)

func _image_pixel_to_stage(pixel: Vector2) -> Vector2:
	if input_image_size.x <= 0.0 or input_image_size.y <= 0.0:
		return Vector2.ZERO
	var rect := _source_stage_rect()
	return rect.position + Vector2(
		(pixel.x / input_image_size.x) * rect.size.x,
		(pixel.y / input_image_size.y) * rect.size.y
	)

func _source_stage_rect() -> Rect2:
	if input_image_size.x <= 0.0 or input_image_size.y <= 0.0:
		return Rect2(Vector2.ZERO, _stage_bounds_size())
	return _aspect_fit_rect(Vector2.ZERO, _stage_bounds_size(), input_image_size.x / input_image_size.y)

func _stage_bounds_size() -> Vector2:
	return stage_size - Vector2.ONE

func _aspect_fit_rect(origin: Vector2, bounds: Vector2, aspect: float) -> Rect2:
	if bounds.x <= 0.0 or bounds.y <= 0.0 or aspect <= 0.0:
		return Rect2(origin, bounds)
	var draw_size := bounds
	if draw_size.x / draw_size.y > aspect:
		draw_size.x = draw_size.y * aspect
	else:
		draw_size.y = draw_size.x / aspect
	return Rect2(origin + (bounds - draw_size) * 0.5, draw_size)

func _pin(row: int, col: int) -> Dictionary:
	return pin_grid.get(_pin_key(row, col), {})

func _pin_key(row: int, col: int) -> String:
	return str(row) + ":" + str(col)

func _vector_from_array(value) -> Vector2:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
