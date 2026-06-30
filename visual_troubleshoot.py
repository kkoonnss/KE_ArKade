import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Add texture variables
if "var photo_texture:" not in code:
    code = code.replace(
        "var reference_texture: Texture2D = null\n",
        "var reference_texture: Texture2D = null\nvar photo_texture: Texture2D = null\nvar semantic_texture: Texture2D = null\nvar background_view = \"final\"\n"
    )

# 2. Update _load_reference to populate photo and semantic
if "semantic_map.png" not in code:
    old_load_ref = '''func _load_reference():
    reference_texture = null
    var yaml = level_dir.path_join("level.yaml")
    if not FileAccess.file_exists(yaml):
        return
    var f = FileAccess.open(yaml, FileAccess.READ)
    if not f:
        return
    while not f.eof_reached():
        var line = f.get_line().strip_edges()
        if line.begins_with("reference_image:"):
            var ref = line.split(":", true, 1)[1].strip_edges().trim_prefix("\\"").trim_suffix("\\"")
            var p = level_dir.path_join(ref)
            if FileAccess.file_exists(p):
                var img = Image.load_from_file(p)
                if img:
                    reference_texture = ImageTexture.create_from_image(img)'''

    new_load_ref = '''func _load_reference():
    reference_texture = null
    photo_texture = null
    semantic_texture = null
    
    var sem = level_dir.path_join("semantic_map.png")
    if FileAccess.file_exists(sem):
        var sem_img = Image.load_from_file(sem)
        if sem_img:
            semantic_texture = ImageTexture.create_from_image(sem_img)
            
    var yaml = level_dir.path_join("level.yaml")
    if not FileAccess.file_exists(yaml):
        return
    var f = FileAccess.open(yaml, FileAccess.READ)
    if not f:
        return
    while not f.eof_reached():
        var line = f.get_line().strip_edges()
        if line.begins_with("reference_image:"):
            var ref = line.split(":", true, 1)[1].strip_edges().trim_prefix("\\"").trim_suffix("\\"")
            var p = level_dir.path_join(ref)
            if FileAccess.file_exists(p):
                var img = Image.load_from_file(p)
                if img:
                    photo_texture = ImageTexture.create_from_image(img)
    reference_texture = photo_texture'''
    
    code = code.replace(old_load_ref, new_load_ref)

# 3. Add background_view to register_knobs
if '"background_view"' not in code:
    code = code.replace(
        'tab_menu.register_knob_bool("reference", "Background Layer", show_reference, "Preview")',
        'tab_menu.register_knob_enum("background_view", "Background View", background_view, ["final", "photo", "semantic"], "Preview")\n    tab_menu.register_knob_bool("reference", "Background Layer", show_reference, "Preview")'
    )

# 4. Handle knob changed
if 'elif knob_id == "background_view":' not in code:
    code = code.replace(
        'elif knob_id == "reference": show_reference = bool(value)',
        'elif knob_id == "background_view": background_view = str(value)\n    elif knob_id == "reference": show_reference = bool(value)'
    )

# 5. Add _draw_background_layer
if 'func _draw_background_layer():' not in code:
    code = code.replace(
        'func _draw_grid():',
        '''func _draw_background_layer():
    if not show_reference:
        return
    var tex: Texture2D = null
    if background_view == "photo" or background_view == "final":
        tex = photo_texture
    elif background_view == "semantic":
        tex = semantic_texture
    if tex:
        draw_texture_rect(tex, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, reference_opacity))

func _draw_grid():'''
    )

# 6. Call _draw_background_layer in _draw
code = code.replace(
    '    if show_reference and reference_texture:\n        draw_texture_rect(reference_texture, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, reference_opacity))',
    '    _draw_background_layer()'
)

# 7. Add Jitter to Ladders
if 'var lx = r.position.x + r.size.x' in code and 'jitter' not in code:
    code = code.replace(
        '''        for i in range(num_ladders):
            var lx = r.position.x + r.size.x * (float(i+1)/(num_ladders+1))
            var y_approx = _platform_y(Vector2(lx, p["y_left"] - 10))''',
        '''        for i in range(num_ladders):
            var jitter = rng.randf_range(-40.0, 40.0)
            var lx = r.position.x + r.size.x * (float(i+1)/(num_ladders+1)) + jitter
            var y_approx = _platform_y(Vector2(lx, p["y_left"] - 10))'''
    )

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
