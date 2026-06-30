extends SceneTree

func _init():
	print("--- Running QA Harness for Shared Adapters ---")
	
	var adapters = {
		"Maze": MazeAdapter.new(),
		"WellFill": WellFillAdapter.new(),
		"Arena": ArenaAdapter.new(),
		"Lane": LaneAdapter.new(),
		"Track": TrackAdapter.new(),
		"Platform": PlatformAdapter.new(),
		"Region": RegionAdapter.new()
	}
	
	var scenes_to_test = [
		"C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/scenes/demo_wall/levels/current",
		"C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/scenes/classic_pacman/levels/level_01"
	]
	
	var all_passed = true
	
	for scene_dir in scenes_to_test:
		if not DirAccess.dir_exists_absolute(scene_dir):
			print("Warning: Test directory does not exist: ", scene_dir)
			continue
			
		print("\nTesting against: ", scene_dir)
		
		for adapter_name in adapters.keys():
			var adapter = adapters[adapter_name]
			var layout = adapter.interpret(scene_dir, {}, {})
			
			if layout.is_empty():
				print("[FAIL] ", adapter_name, " returned empty layout!")
				all_passed = false
			else:
				var summary = ""
				if adapter_name == "Maze":
					summary = str(layout.get("nodes", []).size()) + " nodes, " + str(layout.get("edges", []).size()) + " edges"
				elif adapter_name == "WellFill":
					summary = str(layout.get("cells", []).size()) + " cells"
				elif adapter_name == "Arena":
					summary = str(layout.get("cover_blocks", []).size()) + " cover blocks"
				elif adapter_name == "Lane":
					summary = str(layout.get("lanes", []).size()) + " lanes"
				elif adapter_name == "Track":
					summary = str(layout.get("centerline_points", []).size()) + " track points"
				elif adapter_name == "Platform":
					summary = str(layout.get("platforms", []).size()) + " platforms"
				elif adapter_name == "Region":
					summary = str(layout.get("regions", []).size()) + " regions"
					
				print("[PASS] ", adapter_name, " -> ", summary)
	
	if all_passed:
		print("\n[QA HARNESS SUCCESS] All adapters returned non-empty layouts.")
	else:
		print("\n[QA HARNESS FAILED] Some adapters returned empty layouts.")
		
	quit()
