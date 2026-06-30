extends AdapterBase
class_name LaneAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var grid_data = derived.get("grid", {})
	if grid_data.is_empty():
		grid_data = load_derived_layer(level_dir, "grid")

	var dim = get_map_dimensions(level_dir)
	var layout = {
		"lanes": [],
		"lane_height": 64.0,
		"bounds": Rect2(0, 0, dim.x, dim.y)
	}
	
	if not grid_data.is_empty():
		var cell_size = float(grid_data.get("cell_px", 32.0))
		layout["lane_height"] = cell_size
		var cells = grid_data.get("cells", [])
		for gy in range(cells.size()):
			var row = cells[gy]
			var solid_count = 0
			var hazard_count = 0
			var total = row.size()
			for cid in row:
				if cid == PALETTE_SOLID: solid_count += 1
				elif cid == PALETTE_HAZARD: hazard_count += 1
				
			var ltype = "safe"
			if hazard_count > total * 0.2:
				ltype = "danger"
			elif solid_count < total * 0.8:
				ltype = "traffic"
				
			layout["lanes"].append({
				"y": gy * cell_size + cell_size / 2.0,
				"type": ltype
			})
			
	if layout["lanes"].is_empty():
		return fallback_layout(level_dir, knobs)
		
	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var h = 64.0
	var count = int(dim.y / h)
	var layout = {
		"lanes": [],
		"lane_height": h,
		"bounds": Rect2(0, 0, dim.x, dim.y)
	}
	for i in range(count):
		layout["lanes"].append({
			"y": i * h + h / 2.0,
			"type": "traffic" if (i % 2 == 1) else "safe"
		})
	return layout
