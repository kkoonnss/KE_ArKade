extends RefCounted
class_name AdapterBase
const SharedLoader = preload("res://../../../app/shared/shared_loader.gd")

const PALETTE_EMPTY = 0
const PALETTE_SOLID = 1
const PALETTE_PATH = 2
const PALETTE_PLATFORM = 3
const PALETTE_HAZARD = 4
const PALETTE_SPAWN = 5
const PALETTE_GOAL = 6
const PALETTE_PICKUP = 7
const PALETTE_TRACKING = 8
const PALETTE_UI_SAFE = 9

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	return fallback_layout(level_dir, knobs)

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	return {}

func load_derived_layer(level_dir: String, layer_name: String) -> Dictionary:
	var path = level_dir.path_join("derived").path_join(layer_name + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func get_map_dimensions(level_dir: String) -> Vector2:
	var map_path = level_dir.path_join("semantic_map.png")
	if FileAccess.file_exists(map_path):
		var img = Image.load_from_file(map_path)
		if img:
			return Vector2(img.get_width(), img.get_height())
	return Vector2(1920, 1080)
