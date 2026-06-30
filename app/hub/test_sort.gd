extends SceneTree

static func parse_simple_yaml(path: String) -> Dictionary:
	var data = {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return data
	
	var current_parent = ""
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges().begins_with("#") or line.strip_edges() == "":
			continue
		
		var indent_level = 0
		for i in range(line.length()):
			if line[i] == ' ' or line[i] == '\t':
				indent_level += 1
			else:
				break
		
		var trimmed = line.strip_edges()
		if trimmed.ends_with(":"):
			current_parent = trimmed.substr(0, trimmed.length() - 1).strip_edges()
			if not current_parent in data:
				data[current_parent] = {}
			continue
		
		if ":" in trimmed:
			var parts = trimmed.split(":", true, 1)
			var key = parts[0].strip_edges()
			var val = parts[1].strip_edges()
			
			if (val.begins_with("\"") and val.ends_with("\"")) or (val.begins_with("'") and val.ends_with("'")):
				val = val.substr(1, val.length() - 2)
			
			var parsed_val = val
			if val.begins_with("[") and val.ends_with("]"):
				var inner = val.substr(1, val.length() - 2)
				var list_items = []
				if inner != "":
					for item in inner.split(","):
						list_items.append(item.strip_edges())
				parsed_val = list_items
			
			if indent_level > 0 and current_parent != "":
				if typeof(data[current_parent]) == TYPE_DICTIONARY:
					data[current_parent][key] = parsed_val
				else:
					data[key] = parsed_val
			else:
				data[key] = parsed_val
	
	return data

func get_level_classic_name(level_name: String) -> String:
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
	var classic_level_to_cartridge = {
		"classic_tetris": "tetris",
		"classic_pacman": "pacman",
		"classic_bomberman": "bomberman",
		"classic_frogger": "frogger",
		"classic_asteroids": "asteroids",
		"classic_tron": "tron",
		"classic_on_track": "on_track",
		"classic_rampage": "rampage",
		"classic_gta": "gta"
	}
	var cart_id = classic_level_to_cartridge.get(level_name, "")
	if cart_id == "":
		cart_id = level_name.replace("classic_", "")
	
	var display_name = level_name.replace("classic_", "").capitalize()
	if cart_id != "":
		var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")
		if FileAccess.file_exists(manifest_path):
			var manifest = parse_simple_yaml(manifest_path)
			var manifest_game_name = manifest.get("game_name", "")
			if manifest_game_name != "":
				display_name = manifest_game_name
	return display_name

func _init():
	print("--- Running Level Sorting Test ---")
	var levels = ["classic_asteroids", "classic_bomberman", "classic_frogger", "classic_pacman", "classic_tetris", "classic_tron", "classic_on_track", "classic_rampage", "classic_gta"]
	for lvl in levels:
		print("Level: " + lvl + " -> Classic Name: " + get_level_classic_name(lvl))
	
	print("\nSorted:")
	levels.sort_custom(func(a, b):
		return get_level_classic_name(a).to_lower() < get_level_classic_name(b).to_lower()
	)
	for lvl in levels:
		print(" - " + lvl + " (" + get_level_classic_name(lvl) + ")")
	quit()
