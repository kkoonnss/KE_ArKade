extends RefCounted
class_name SharedLoader

## Loader for separate-process cartridges.
## Cartridges are standalone Godot projects, so global class_name symbols from
## app/shared are not visible under their res://. Load shared scripts by absolute
## path and normalize adapters so they do not depend on AdapterBase being global.

static func repo_root() -> String:
	var dir = ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	if dir.ends_with("/"):
		dir = dir.substr(0, dir.length() - 1)
	for _i in range(10):
		if DirAccess.dir_exists_absolute(dir.path_join("app").path_join("shared")):
			return dir
		var parent = dir.get_base_dir()
		if parent == dir or parent == "":
			break
		dir = parent
	push_error("SharedLoader could not resolve KE_ArKade repo root from res://")
	return ""

static var _input_config_cache: Dictionary = {}
static var _input_config_loaded: bool = false
static var _input_actions_configured: bool = false
static var _input_actions_bootstrapped: bool = _bootstrap_input_actions()

static func _bootstrap_input_actions() -> bool:
	ensure_input_actions()
	return true

static func get_joy_id(player_idx: int) -> int:
	ensure_input_actions()
	if not _input_config_loaded:
		var path = shared_path("input_config.json")
		if path != "" and FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data = json.data
					if typeof(data) == TYPE_DICTIONARY and data.has("slots"):
						_input_config_cache = data["slots"]
				file.close()
		_input_config_loaded = true
		
	var key = str(player_idx)
	var mapped_device = player_idx
	if _input_config_cache.has(key):
		var mapping = _input_config_cache[key]
		if typeof(mapping) == TYPE_DICTIONARY and mapping.has("device_id"):
			mapped_device = int(mapping["device_id"])
			
	var connected = Input.get_connected_joypads()
	if mapped_device >= 0 and connected.has(mapped_device):
		return mapped_device
	if player_idx >= 0 and player_idx < connected.size():
		return int(connected[player_idx])
	if player_idx == 0 and connected.size() > 0:
		return int(connected[0])
	
	# Fallback to the saved/standard mapping so keyboard-only slots stay inert.
	return mapped_device

static func ensure_input_actions():
	if _input_actions_configured:
		return
	_input_actions_configured = true
	
	_ensure_action_key("ui_left", KEY_LEFT)
	_ensure_action_key("ui_left", KEY_A)
	_ensure_action_key("ui_right", KEY_RIGHT)
	_ensure_action_key("ui_right", KEY_D)
	_ensure_action_key("ui_up", KEY_UP)
	_ensure_action_key("ui_up", KEY_W)
	_ensure_action_key("ui_down", KEY_DOWN)
	_ensure_action_key("ui_down", KEY_S)
	
	_ensure_action_joy_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_action_joy_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_ensure_action_joy_button("ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_action_joy_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	
	_ensure_action_joy_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_action_joy_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_action_joy_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_action_joy_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)

static func _ensure_action(action_name: String):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)

static func _ensure_action_key(action_name: String, keycode: int):
	_ensure_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.keycode == keycode:
			return
	var event = InputEventKey.new()
	event.device = -1
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

static func _ensure_action_joy_button(action_name: String, button_index: int):
	_ensure_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventJoypadButton and existing.button_index == button_index:
			return
	var event = InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

static func _ensure_action_joy_axis(action_name: String, axis: int, axis_value: float):
	_ensure_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventJoypadMotion and existing.axis == axis and sign(existing.axis_value) == sign(axis_value):
			return
	var event = InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)


static func shared_path(relative_path: String) -> String:
	var root = repo_root()
	if root == "":
		return ""
	return root.path_join("app").path_join("shared").path_join(relative_path)

static func load_tab_menu_script():
	return _load_normalized_script("controls/tab_menu.gd", false)

static func load_adapter_script(adapter_name: String):
	var relative_path = adapter_name
	if not relative_path.ends_with(".gd"):
		relative_path += ".gd"
	if not relative_path.begins_with("adapters/"):
		relative_path = "adapters/" + relative_path
	return _load_normalized_script(relative_path, true)

static func _load_normalized_script(relative_path: String, inject_adapter_helpers: bool):
	var path = shared_path(relative_path)
	if path == "":
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SharedLoader could not open shared script: " + path)
		return null
	var source = _normalized_source(file.get_as_text(), inject_adapter_helpers)
	var script = GDScript.new()
	script.source_code = source
	var err = script.reload()
	if err != OK:
		push_error("SharedLoader failed to compile shared script: " + path + " err=" + str(err))
		return null
	return script

static func _normalized_source(source: String, inject_adapter_helpers: bool) -> String:
	var lines = []
	for line in source.split("\n"):
		var stripped = line.strip_edges()
		if stripped.begins_with("class_name "):
			continue
		if inject_adapter_helpers and stripped.begins_with("extends "):
			continue
		lines.append(line)
	if inject_adapter_helpers:
		return _adapter_helpers_source() + "\n" + "\n".join(lines)
	return "\n".join(lines)

static func _adapter_helpers_source() -> String:
	return "\n".join([
		"extends RefCounted",
		"",
		"const PALETTE_EMPTY = 0",
		"const PALETTE_SOLID = 1",
		"const PALETTE_PATH = 2",
		"const PALETTE_PLATFORM = 3",
		"const PALETTE_HAZARD = 4",
		"const PALETTE_SPAWN = 5",
		"const PALETTE_GOAL = 6",
		"const PALETTE_PICKUP = 7",
		"const PALETTE_TRACKING = 8",
		"const PALETTE_UI_SAFE = 9",
		"",
		"func load_derived_layer(level_dir: String, layer_name: String) -> Dictionary:",
		"\tvar path = level_dir.path_join(\"derived\").path_join(layer_name + \".json\")",
		"\tif not FileAccess.file_exists(path):",
		"\t\treturn {}",
		"\tvar file = FileAccess.open(path, FileAccess.READ)",
		"\tif file == null:",
		"\t\treturn {}",
		"\tvar json = JSON.new()",
		"\tif json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:",
		"\t\treturn json.data",
		"\treturn {}",
		"",
		"func get_map_dimensions(level_dir: String) -> Vector2:",
		"\tvar map_path = level_dir.path_join(\"semantic_map.png\")",
		"\tif FileAccess.file_exists(map_path):",
		"\t\tvar img = Image.load_from_file(map_path)",
		"\t\tif img:",
		"\t\t\treturn Vector2(img.get_width(), img.get_height())",
		"\treturn Vector2(1920, 1080)",
		"",
		"func parse_simple_yaml(path: String) -> Dictionary:",
		"\tvar data = {}",
		"\tvar file = FileAccess.open(path, FileAccess.READ)",
		"\tif file == null:",
		"\t\treturn data",
		"\twhile not file.eof_reached():",
		"\t\tvar line = file.get_line().strip_edges()",
		"\t\tif line.begins_with(\"#\") or line == \"\":",
		"\t\t\tcontinue",
		"\t\tif \":\" in line:",
		"\t\t\tvar parts = line.split(\":\", true, 1)",
		"\t\t\tvar key = parts[0].strip_edges()",
		"\t\t\tvar val = parts[1].strip_edges()",
		"\t\t\tif (val.begins_with(\"\\\"\") and val.ends_with(\"\\\"\")) or (val.begins_with(\"'\") and val.ends_with(\"'\")):",
		"\t\t\t\tval = val.substr(1, val.length() - 2)",
		"\t\t\tdata[key] = val",
		"\treturn data",
		""
	])
