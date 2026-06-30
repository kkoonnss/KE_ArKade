extends SceneTree
func _init():
    var SL = load("app/shared/shared_loader.gd")
    var adapter = SL.load_adapter_script("maze").new()
    var layout = adapter.interpret("content/scenes/scene_demo_wall/levels/gallery_260627_010703", {}, {})
    print("Layout: ", layout)
    quit()

