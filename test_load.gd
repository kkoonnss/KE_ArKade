extends SceneTree
func _init():
    var script = load("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/app/shared/shared_loader.gd")
    if script:
        print("Loaded successfully")
    else:
        print("Failed to load")
    quit()

