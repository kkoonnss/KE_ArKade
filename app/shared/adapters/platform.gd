extends AdapterBase
class_name PlatformAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var edges_data = derived.get("platform_edges", {})
	if edges_data.is_empty():
		edges_data = load_derived_layer(level_dir, "platform_edges")
		
	var grid_data = derived.get("grid", {})
	if grid_data.is_empty():
		grid_data = load_derived_layer(level_dir, "grid")

	var layout = {
		"platforms": [],
		"spawns": []
	}
	
	if not edges_data.is_empty():
		var segments = edges_data.get("segments", [])
		for seg in segments:
			if typeof(seg) == TYPE_ARRAY and seg.size() >= 4:
				layout["platforms"].append({
					"p1": Vector2(seg[0], seg[1]),
					"p2": Vector2(seg[2], seg[3])
				})
			elif typeof(seg) == TYPE_DICTIONARY:
				layout["platforms"].append({
					"p1": Vector2(seg.get("x1", 0), seg.get("y1", 0)),
					"p2": Vector2(seg.get("x2", 0), seg.get("y2", 0))
				})
				
	if layout["platforms"].is_empty() and not grid_data.is_empty():
		var cell_size = float(grid_data.get("cell_px", 32.0))
		var cells = grid_data.get("cells", [])
		for gy in range(cells.size()):
			var row = cells[gy]
			var start_x = -1
			for gx in range(row.size()):
				var cid = row[gx]
				if cid == PALETTE_PLATFORM or (cid == PALETTE_SOLID and gy > 0 and cells[gy-1][gx] == PALETTE_EMPTY):
					if start_x == -1:
						start_x = gx
				else:
					if start_x != -1:
						layout["platforms"].append({
							"p1": Vector2(start_x * cell_size, gy * cell_size),
							"p2": Vector2(gx * cell_size, gy * cell_size)
						})
						start_x = -1
			if start_x != -1:
				layout["platforms"].append({
					"p1": Vector2(start_x * cell_size, gy * cell_size),
					"p2": Vector2(row.size() * cell_size, gy * cell_size)
				})
				
	if layout["platforms"].is_empty():
		return fallback_layout(level_dir, knobs)
		
	# Procedural spawns on platforms if empty
	if layout["spawns"].is_empty():
		for p in layout["platforms"]:
			var mid_x = (p.p1.x + p.p2.x) / 2.0
			layout["spawns"].append(Vector2(mid_x, p.p1.y - 40.0))
			break
			
	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var layout = {
		"platforms": [],
		"spawns": []
	}
	# Floor
	layout["platforms"].append({"p1": Vector2(0, dim.y - 100), "p2": Vector2(dim.x, dim.y - 100)})
	# Floating
	layout["platforms"].append({"p1": Vector2(dim.x*0.2, dim.y*0.6), "p2": Vector2(dim.x*0.4, dim.y*0.6)})
	layout["platforms"].append({"p1": Vector2(dim.x*0.6, dim.y*0.4), "p2": Vector2(dim.x*0.8, dim.y*0.4)})
	
	layout["spawns"].append(Vector2(dim.x*0.3, dim.y*0.6 - 40))
	return layout
