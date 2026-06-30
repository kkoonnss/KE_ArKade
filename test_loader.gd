extends SceneTree
func _init():
    var SL = load("res://app/shared/shared_loader.gd")
    var script = SL.load_tab_menu_script()
    if script:
        var inst = script.new()
        print("Success!")
    quit()

