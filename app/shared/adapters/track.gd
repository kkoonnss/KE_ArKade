extends AdapterBase
class_name TrackAdapter

func interpret(level_dir: String, derived: Dictionary, knobs: Dictionary) -> Dictionary:
	var track_data = derived.get("track_centerline", {})
	if track_data.is_empty():
		track_data = load_derived_layer(level_dir, "track_centerline")

	var layout = {
		"centerline_points": [],
		"checkpoints": [],
		"track_width": 120.0
	}
	
	if not track_data.is_empty():
		var pts = track_data.get("points", [])
		for p in pts:
			if typeof(p) == TYPE_ARRAY and p.size() >= 2:
				layout["centerline_points"].append(Vector2(p[0], p[1]))
			elif typeof(p) == TYPE_DICTIONARY:
				layout["centerline_points"].append(Vector2(p.get("x", 0.0), p.get("y", 0.0)))
		
		var cp = track_data.get("checkpoints", [])
		for p in cp:
			if typeof(p) == TYPE_ARRAY and p.size() >= 2:
				layout["checkpoints"].append(Vector2(p[0], p[1]))
			elif typeof(p) == TYPE_DICTIONARY:
				layout["checkpoints"].append(Vector2(p.get("x", 0.0), p.get("y", 0.0)))
				
	if layout["centerline_points"].is_empty():
		return fallback_layout(level_dir, knobs)
		
	# Fallback checkpoints if none exist
	if layout["checkpoints"].is_empty() and layout["centerline_points"].size() > 4:
		var n = layout["centerline_points"].size()
		layout["checkpoints"].append(layout["centerline_points"][0])
		layout["checkpoints"].append(layout["centerline_points"][int(n/3)])
		layout["checkpoints"].append(layout["centerline_points"][int(n*2/3)])
		
	return layout

func fallback_layout(level_dir: String, knobs: Dictionary) -> Dictionary:
	var dim = get_map_dimensions(level_dir)
	var cx = dim.x / 2.0
	var cy = dim.y / 2.0
	var rx = dim.x * 0.35
	var ry = dim.y * 0.35
	var layout = {
		"centerline_points": [],
		"checkpoints": [],
		"track_width": 120.0
	}
	var steps = 32
	for i in range(steps):
		var a = (float(i) / steps) * PI * 2.0
		layout["centerline_points"].append(Vector2(cx + cos(a)*rx, cy + sin(a)*ry))
		if i % 8 == 0:
			layout["checkpoints"].append(Vector2(cx + cos(a)*rx, cy + sin(a)*ry))
	return layout
