extends SceneTree

func _init():
	var scene = load("res://main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	# Let it run for 1 idle frame to process _ready
	await root.get_tree().process_frame
	
	print("Hub initialized successfully!")
	quit()
