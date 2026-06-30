extends AdapterBase
class_name WellFillAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var container_data = derived.get("container", {})
	if container_data.is_empty():
		container_data = load_derived_layer(level_dir, "container")
		
	var grid_data = derived.get("grid", {})
	if grid_data.is_empty():
		grid_data = load_derived_layer(level_dir, "grid")
		
	var dim = get_map_dimensions(level_dir)

	var layout = {
		"bounds": Rect2(0, 0, dim.x, dim.y),
		"cells": [],
		"cell_size": 32.0,
		"well_polygon": [],
		"spawn_lip": Vector2(dim.x / 2.0, 0),
		"down_direction": Vector2(0, 1)
	}
	
	if not container_data.is_empty():
		var b = container_data.get("bounds", [0, 0, dim.x, dim.y])
		if b.size() >= 4:
			layout["bounds"] = Rect2(b[0], b[1], b[2], b[3])
		
		if container_data.has("well_polygon"):
			for p in container_data["well_polygon"]:
				layout["well_polygon"].append(Vector2(p.get("x", 0), p.get("y", 0)))
		if container_data.has("spawn_lip"):
			layout["spawn_lip"] = Vector2(container_data["spawn_lip"].get("x", dim.x / 2.0), container_data["spawn_lip"].get("y", 0))
		if container_data.has("down_direction"):
			layout["down_direction"] = Vector2(container_data["down_direction"].get("x", 0), container_data["down_direction"].get("y", 1))
			
	if not grid_data.is_empty():
		var cell_size = float(grid_data.get("cell_px", 32.0))
		layout["cell_size"] = cell_size
		var cells = grid_data.get("cells", [])
		for gy in range(cells.size()):
			var row = cells[gy]
			for gx in range(row.size()):
				var cid = row[gx]
				if cid == PALETTE_SOLID:
					var px = gx * cell_size + cell_size / 2.0
					var py = gy * cell_size + cell_size / 2.0
					# In a well game, solids inside the container bounds become blocks
					if layout["bounds"].has_point(Vector2(px, py)):
						layout["cells"].append({"x": px, "y": py, "gx": gx, "gy": gy})
						
	if layout["cells"].is_empty():
		return fallback_layout(level_dir, knobs)
		
	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var w = min(dim.x * 0.5, 600.0)
	var h = dim.y * 0.8
	var bx = (dim.x - w) / 2.0
	var by = (dim.y - h) / 2.0
	var cell_size = 32.0
	var layout = {
		"bounds": Rect2(bx, by, w, h),
		"cells": [],
		"cell_size": cell_size
	}
	
	var start_y = by + 64.0
	var end_y = by + h * 0.4
	for y in range(int(start_y), int(end_y), int(cell_size)):
		for x in range(int(bx + cell_size), int(bx + w - cell_size), int(cell_size)):
			layout["cells"].append({"x": float(x), "y": float(y)})
			
	return layout
