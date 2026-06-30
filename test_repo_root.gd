extends SceneTree
func _init():
    var d = "C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/cartridges/tetris"
    for _i in range(10):
        if DirAccess.dir_exists_absolute(d.path_join("app/shared")): 
            print("FOUND: ", d)
            quit()
        var p = d.get_base_dir()
        if p == d or p == "": 
            print("STOPPED AT: ", d)
            break
        d = p
    print("RETURN EMPTY")
    quit()

