extends SceneTree
func _init():
    var d = ProjectSettings.globalize_path('res://').replace('\\\\','/').simplify_path()
    var sl_path = d.path_join('app/shared/shared_loader.gd')
    var SL = load(sl_path)
    if SL == null:
        print('SharedLoader not found')
        quit()
        return
    var adapter = SL.load_adapter_script('platform').new()
    var level_dir = d.path_join('content/cartridges/donkey_kong/classic')
    var layout = adapter.interpret(level_dir, {}, {})
    print(layout)
    quit()

