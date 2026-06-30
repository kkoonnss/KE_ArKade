extends AdapterBase
class_name ArenaAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var container_data = derived.get("container", {})
	if container_data.is_empty():
		container_data = load_derived_layer(level_dir, "container")
		
	var grid_data = derived.get("grid", {})
	if grid_data.is_empty():
		grid_data = load_derived_layer(level_dir, "grid")

	var layout = {
		"bounds": Rect2(0, 0, 1920, 1080),
		"cover_blocks": [],
		"spawns": []
	}
	
	var dim = get_map_dimensions(level_dir)
	layout["bounds"] = Rect2(0, 0, dim.x, dim.y)
	
	if not container_data.is_empty():
		var b = container_data.get("bounds", [0, 0, dim.x, dim.y])
		if b.size() >= 4:
			layout["bounds"] = Rect2(b[0], b[1], b[2], b[3])
			
	if not grid_data.is_empty():
		var cell_size = float(grid_data.get("cell_px", 32.0))
		var cells = grid_data.get("cells", [])
		for gy in range(cells.size()):
			var row = cells[gy]
			for gx in range(row.size()):
				var cid = row[gx]
				var px = gx * cell_size
				var py = gy * cell_size
				var rect = Rect2(px, py, cell_size, cell_size)
				
				if layout["bounds"].intersects(rect):
					if cid == PALETTE_SOLID:
						layout["cover_blocks"].append(rect)
					elif cid == PALETTE_SPAWN:
						layout["spawns"].append(Vector2(px + cell_size/2.0, py + cell_size/2.0))
						
	# Procedural fallback for spawns
	if layout["spawns"].is_empty():
		var cx = layout["bounds"].position.x + layout["bounds"].size.x / 2.0
		var cy = layout["bounds"].position.y + layout["bounds"].size.y / 2.0
		layout["spawns"].append(Vector2(cx, cy))
		
	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var margin = 100.0
	var layout = {
		"bounds": Rect2(margin, margin, dim.x - margin*2.0, dim.y - margin*2.0),
		"cover_blocks": [],
		"spawns": [Vector2(dim.x / 2.0, dim.y / 2.0)]
	}
	return layout
