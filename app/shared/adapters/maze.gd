extends AdapterBase
class_name MazeAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var grid_data = derived.get("grid", {})
	if grid_data.is_empty():
		grid_data = load_derived_layer(level_dir, "grid")
		
	var navgraph_data = derived.get("navgraph", {})
	if navgraph_data.is_empty():
		navgraph_data = load_derived_layer(level_dir, "navgraph")
	
	var invert_main_solid = knobs.get("invert_main_solid", false)
	var grid_size_scale = knobs.get("grid_size_scale", 1.0)
	
	var layout = {
		"nodes": [],
		"edges": [],
		"players": [],
		"enemies": [],
		"pickups": [],
		"grid_cell_size": 32.0 * grid_size_scale
	}
	
	var grid_loaded = false
	
	if not grid_data.is_empty():
		var grid_cell_size_base = float(grid_data.get("cell_px", 32.0))
		var grid_cell_size = grid_cell_size_base * grid_size_scale
		layout["grid_cell_size"] = grid_cell_size
		var grid_cells = grid_data.get("cells", [])
		
		var node_map = {}
		for gy in range(grid_cells.size()):
			var row = grid_cells[gy]
			for gx in range(row.size()):
				var cid = row[gx]
				var is_solid = cid == PALETTE_SOLID
				if invert_main_solid:
					is_solid = not (cid in [PALETTE_PATH, PALETTE_PLATFORM, PALETTE_SPAWN, PALETTE_GOAL, PALETTE_PICKUP]) and cid != PALETTE_SOLID
				
				if not is_solid:
					var px = gx * grid_cell_size + grid_cell_size / 2.0
					var py = gy * grid_cell_size + grid_cell_size / 2.0
					var node_id = "%d_%d" % [gx, gy]
					var node = {
						"id": node_id,
						"x": px,
						"y": py,
						"gx": gx,
						"gy": gy,
						"class_id": cid,
						"type": "path"
					}
					
					if cid == PALETTE_SPAWN:
						node["type"] = "spawn"
						node["tags"] = ["spawn"]
						layout["players"].append({"x": px, "y": py, "id": node_id})
					
					layout["nodes"].append(node)
					node_map[Vector2(gx, gy)] = node
					
					# Add pickups
					if (cid == PALETTE_PATH or cid == PALETTE_PICKUP) and cid != PALETTE_SPAWN:
						layout["pickups"].append({"x": px, "y": py})
					elif cid in [PALETTE_EMPTY, PALETTE_UI_SAFE] and gx % 2 == 0 and gy % 2 == 0:
						var has_room = true
						for dy in range(-1, 2):
							for dx in range(-1, 2):
								if dx == 0 and dy == 0: continue
								var ny = gy + dy
								var nx = gx + dx
								if ny >= 0 and ny < grid_cells.size() and nx >= 0 and nx < grid_cells[ny].size():
									var ncid = grid_cells[ny][nx]
									var nis_solid = ncid == PALETTE_SOLID
									if invert_main_solid:
										nis_solid = not (ncid in [PALETTE_PATH, PALETTE_PLATFORM, PALETTE_SPAWN, PALETTE_GOAL, PALETTE_PICKUP]) and ncid != PALETTE_SOLID
									if nis_solid:
										has_room = false
								else:
									has_room = false
						if has_room:
							layout["pickups"].append({"x": px, "y": py, "open": true})
							
		# Edges
		for gy in range(grid_cells.size()):
			var row = grid_cells[gy]
			for gx in range(row.size()):
				var u = node_map.get(Vector2(gx, gy))
				if u:
					for dir in [Vector2(1, 0), Vector2(0, 1)]:
						var nx = gx + dir.x
						var ny = gy + dir.y
						var v = node_map.get(Vector2(nx, ny))
						if v:
							layout["edges"].append({
								"source": u.id,
								"target": v.id,
								"weight": grid_cell_size
							})
							
		if layout["nodes"].size() > 0:
			grid_loaded = true
			
	if not grid_loaded and not navgraph_data.is_empty():
		var nodes = navgraph_data.get("nodes", [])
		layout["nodes"] = nodes
		layout["edges"] = navgraph_data.get("edges", [])
		
		for node in nodes:
			var tags = node.get("tags", [])
			var is_spawn = "spawn" in tags or node.get("type") == "spawn"
			var is_pickup = "pickup" in tags or node.get("type") == "pickup"
			if tags.is_empty() and not node.has("type"):
				is_pickup = true
				
			if is_spawn:
				layout["players"].append({"x": node.get("x", 0), "y": node.get("y", 0), "id": node.get("id", "")})
			elif "enemy" in tags or node.get("type") == "enemy" or "enemy_spawn" in tags:
				layout["enemies"].append({"x": node.get("x", 0), "y": node.get("y", 0), "id": node.get("id", "")})
				
			if is_pickup:
				layout["pickups"].append({"x": node.get("x", 0), "y": node.get("y", 0)})
				
		# Add extra pickups from grid if it exists but graph building failed
		if not grid_data.is_empty():
			var grid_cell_size_base = float(grid_data.get("cell_px", 32.0))
			var grid_cell_size = grid_cell_size_base * grid_size_scale
			var grid_cells = grid_data.get("cells", [])
			for gy in range(grid_cells.size()):
				var row = grid_cells[gy]
				for gx in range(row.size()):
					if row[gx] == PALETTE_PICKUP:
						var px = gx * grid_cell_size + grid_cell_size / 2.0
						var py = gy * grid_cell_size + grid_cell_size / 2.0
						var pos = Vector2(px, py)
						var too_close = false
						for existing in layout["pickups"]:
							if pos.distance_to(Vector2(existing.x, existing.y)) < 16.0:
								too_close = true
								break
						if not too_close:
							layout["pickups"].append({"x": px, "y": py})

	if layout["nodes"].is_empty():
		return fallback_layout(level_dir, knobs)
		
	# Fallback spawns/enemies
	if layout["players"].is_empty():
		var n = layout["nodes"][0]
		layout["players"].append({"x": n.get("x", 0), "y": n.get("y", 0), "id": n.get("id", "")})
		
	if layout["enemies"].is_empty():
		var p0 = Vector2(layout["players"][0].x, layout["players"][0].y) if not layout["players"].is_empty() else Vector2.ZERO
		var far = []
		for n in layout["nodes"]:
			if Vector2(n.get("x", 0), n.get("y", 0)).distance_to(p0) > 400.0:
				far.append(n)
		if far.is_empty():
			far = layout["nodes"]
		for i in range(4):
			var n = far[i % far.size()]
			layout["enemies"].append({"x": n.get("x", 0), "y": n.get("y", 0), "id": n.get("id", "")})
			
	# Assign power pellets (4 corners)
	if not layout["pickups"].is_empty():
		var min_x = INF
		var min_y = INF
		var max_x = -INF
		var max_y = -INF
		for p in layout["pickups"]:
			min_x = min(min_x, p.x)
			min_y = min(min_y, p.y)
			max_x = max(max_x, p.x)
			max_y = max(max_y, p.y)
		var corners = [Vector2(min_x, min_y), Vector2(max_x, min_y), Vector2(min_x, max_y), Vector2(max_x, max_y)]
		var used = {}
		for corner in corners:
			var best = -1
			var best_d = INF
			for idx in range(layout["pickups"].size()):
				if used.has(idx) or layout["pickups"][idx].get("open", false): continue
				var d = Vector2(layout["pickups"][idx].x, layout["pickups"][idx].y).distance_squared_to(corner)
				if d < best_d:
					best_d = d
					best = idx
			if best != -1:
				layout["pickups"][best]["power"] = true
				used[best] = true

	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var layout = {
		"nodes": [],
		"edges": [],
		"players": [],
		"enemies": [],
		"pickups": [],
		"grid_cell_size": 32.0
	}
	
	var margin = 64.0
	var nx = int((dim.x - margin*2) / 64.0)
	var ny = int((dim.y - margin*2) / 64.0)
	
	var node_map = {}
	for y in range(ny):
		for x in range(nx):
			var px = margin + x * 64.0
			var py = margin + y * 64.0
			var nid = "%d_%d" % [x, y]
			layout["nodes"].append({"id": nid, "x": px, "y": py})
			layout["pickups"].append({"x": px, "y": py})
			node_map[Vector2(x, y)] = nid
			
	for y in range(ny):
		for x in range(nx):
			var u = node_map.get(Vector2(x, y))
			if u:
				if x + 1 < nx:
					layout["edges"].append({"source": u, "target": node_map[Vector2(x + 1, y)], "weight": 64.0})
				if y + 1 < ny:
					layout["edges"].append({"source": u, "target": node_map[Vector2(x, y + 1)], "weight": 64.0})
					
	if layout["nodes"].size() > 0:
		layout["players"].append({"x": layout["nodes"][0].x, "y": layout["nodes"][0].y, "id": layout["nodes"][0].id})
		layout["enemies"].append({"x": layout["nodes"][-1].x, "y": layout["nodes"][-1].y, "id": layout["nodes"][-1].id})
		
	return layout
