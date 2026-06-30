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

func get_sorted_cartridges() -> Array:
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
					list.append({
						"id": cart_id,
						"game_name": game_name,
						"manifest": manifest,
					})
			file_name = dir.get_next()
	return list

func _init():
	print("--- Running standalone cartridge load test ---")
	var carts = get_sorted_cartridges()
	print("Loaded " + str(carts.size()) + " cartridges:")
	for cart in carts:
		print(" - " + cart["id"] + " (" + cart["game_name"] + ")")
	quit()
