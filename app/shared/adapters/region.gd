extends AdapterBase
class_name RegionAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var grid_data = derived.get("grid", {})
	if grid_data.is_empty():
		grid_data = load_derived_layer(level_dir, "grid")

	var dim = get_map_dimensions(level_dir)
	var layout = {
		"regions": [],
		"bounds": Rect2(0, 0, dim.x, dim.y),
		"cells": [],
		"cell_size": 32.0
	}
	
	if not grid_data.is_empty():
		var cell_size = float(grid_data.get("cell_px", 32.0))
		var cells = grid_data.get("cells", [])
		layout["cell_size"] = cell_size
		layout["cells"] = cells
		
		# Simple 2D greedy meshing for rectangular regions
		var visited = {}
		for gy in range(cells.size()):
			var row = cells[gy]
			for gx in range(row.size()):
				if visited.has(Vector2(gx, gy)): continue
				var cid = row[gx]
				if cid == PALETTE_SOLID:
					# Find width
					var w = 1
					while gx + w < row.size() and cells[gy][gx + w] == PALETTE_SOLID and not visited.has(Vector2(gx + w, gy)):
						w += 1
					# Find height
					var h = 1
					var can_expand = true
					while gy + h < cells.size() and can_expand:
						for i in range(w):
							if cells[gy + h][gx + i] != PALETTE_SOLID or visited.has(Vector2(gx + i, gy + h)):
								can_expand = false
								break
						if can_expand:
							h += 1
					
					# Mark visited
					for dy in range(h):
						for dx in range(w):
							visited[Vector2(gx + dx, gy + dy)] = true
							
					layout["regions"].append(Rect2(gx * cell_size, gy * cell_size, w * cell_size, h * cell_size))
				
	if layout["regions"].is_empty():
		return fallback_layout(level_dir, knobs)
		
	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var layout = {
		"regions": [],
		"bounds": Rect2(0, 0, dim.x, dim.y)
	}
	var b_w = 200.0
	var b_h = 150.0
	var space = 100.0
	for y in range(int(space), int(dim.y - b_h), int(b_h + space)):
		for x in range(int(space), int(dim.x - b_w), int(b_w + space)):
			layout["regions"].append(Rect2(float(x), float(y), b_w, b_h))
	return layout
