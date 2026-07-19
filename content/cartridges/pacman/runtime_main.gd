extends Control

const STAGE_SIZE := Vector2i(1920, 1080)

var SharedLoader = (func():
	var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path()
	var s = GDScript.new()
	s.source_code = FileAccess.get_file_as_string(p)
	s.reload()
	return s
).call()

var stage_viewport: SubViewport = null
var warp = null
var scene_dir: String = ""
var _logged_texture_ready: bool = false

func _ready() -> void:
	_parse_args()
	_setup_stage_viewport()
	_setup_warp()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	print("Pac-Man final-frame wrapper ready. scene=", scene_dir)

func _process(_delta: float) -> void:
	if not _logged_texture_ready and stage_viewport != null:
		var texture := stage_viewport.get_texture()
		if texture != null and texture.get_size().x > 0 and texture.get_size().y > 0:
			_logged_texture_ready = true
			print("Pac-Man final-frame texture ready: ", texture.get_size())
	queue_redraw()

func _input(event: InputEvent) -> void:
	if stage_viewport:
		stage_viewport.push_input(_event_to_stage(event), true)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, get_viewport_rect().size)
	draw_rect(rect, Color.BLACK, true)
	if stage_viewport == null:
		return
	var texture := stage_viewport.get_texture()
	if texture == null or texture.get_size().x <= 0 or texture.get_size().y <= 0:
		return
	var stage_rect := _stage_rect(rect)
	if warp != null and warp.is_loaded:
		warp.draw_final_output(self, texture, stage_rect)
	else:
		draw_texture_rect(texture, stage_rect, false, Color.WHITE)

func _stage_rect(viewport_rect: Rect2) -> Rect2:
	var stage_aspect := float(STAGE_SIZE.x) / float(STAGE_SIZE.y)
	var viewport_aspect: float = viewport_rect.size.x / max(1.0, viewport_rect.size.y)
	var size: Vector2 = viewport_rect.size
	if viewport_aspect > stage_aspect:
		size.x = viewport_rect.size.y * stage_aspect
	else:
		size.y = viewport_rect.size.x / stage_aspect
	var pos := viewport_rect.position + (viewport_rect.size - size) * 0.5
	return Rect2(pos, size)

func _event_to_stage(event: InputEvent) -> InputEvent:
	if not event is InputEventMouse:
		return event
	var mapped := event.duplicate()
	var rect := _stage_rect(Rect2(Vector2.ZERO, get_viewport_rect().size))
	var relative: Vector2 = (event.position - rect.position) / rect.size
	var stage_pos := Vector2(relative.x * STAGE_SIZE.x, relative.y * STAGE_SIZE.y)
	mapped.position = stage_pos
	mapped.global_position = stage_pos
	return mapped

func _setup_stage_viewport() -> void:
	stage_viewport = SubViewport.new()
	stage_viewport.name = "CanonicalStage"
	stage_viewport.size = STAGE_SIZE
	stage_viewport.transparent_bg = false
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage_viewport.handle_input_locally = false
	add_child(stage_viewport)
	var game_scene := load("res://main.tscn")
	if game_scene:
		stage_viewport.add_child(game_scene.instantiate())
	else:
		push_error("Pac-Man final-frame wrapper could not load res://main.tscn")

func _setup_warp() -> void:
	var script = SharedLoader.load_calibration_warp_script()
	if script == null:
		return
	warp = script.new()
	if scene_dir != "":
		if warp.load_scene(scene_dir):
			print("Pac-Man final-frame scene calibration loaded: ", warp.profile_path)
		else:
			print("No scene calibration profile found for: ", scene_dir)

func _parse_args() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	var i := 0
	while i < args.size():
		if args[i] == "--scene" and i + 1 < args.size():
			scene_dir = args[i + 1]
			i += 1
		i += 1
