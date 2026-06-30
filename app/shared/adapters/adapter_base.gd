extends RefCounted
class_name AdapterBase

## Base class for map interpretation adapters (Wave 0).
## 
## Each archetype adapter implements `interpret(level_dir, derived, knobs)` 
## to return a normalized play layout for a specific game genre.

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

## Override this method in subclasses.
## @param level_dir: Absolute path to the level directory.
## @param derived: Dictionary containing pre-loaded derived layer data (e.g. {"grid": {...}, "navgraph": {...}}).
##                 If a layer is missing, the adapter should attempt to load it using `load_derived_layer()`.
## @param knobs: Dictionary of per-game tweaks from level_adjustments.
## @return: A Dictionary representing the structural play layout.
func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	return fallback_layout(level_dir, knobs)

## Procedural fallback when a map yields too little data to be playable.
## Every adapter MUST return a non-empty layout here.
func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	return {}

# --------------------------------------------------------------------------
# Helpers for loading and parsing data
# --------------------------------------------------------------------------

func load_derived_layer(level_dir: String, layer_name: String) -> Dictionary:
	var path = level_dir.path_join("derived").path_join(layer_name + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var result = json.data
		if typeof(result) == TYPE_DICTIONARY:
			return result
	return {}

func get_map_dimensions(level_dir: String) -> Vector2:
	var map_path = level_dir.path_join("semantic_map.png")
	if FileAccess.file_exists(map_path):
		var img = Image.load_from_file(map_path)
		if img:
			return Vector2(img.get_width(), img.get_height())
	# Fallback if image is missing
	return Vector2(1920, 1080)

func parse_simple_yaml(path: String) -> Dictionary:
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
