import re

with open('app/hub/main.gd', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_content = []
in_create_game = False
in_display_games = False
in_get_cart_list = False
in_ready = False

create_game_new = """func _create_game_card(cart: Dictionary, parent_grid: Container, display_index: int = -1):
	var cart_id = cart.id
	var game_name = cart.game_name.replace("Classic ", "")
	var is_fav = cart.favorite

	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(260, 260)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_panel.add_theme_stylebox_override("panel", style_panel)
	parent_grid.add_child(card_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	card_panel.add_child(vbox)

	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 8)
	top_margin.add_theme_constant_override("margin_top", 8)
	top_margin.add_theme_constant_override("margin_right", 8)
	top_margin.add_theme_constant_override("margin_bottom", 4)
	vbox.add_child(top_margin)

	var img_control = Control.new()
	img_control.custom_minimum_size = Vector2(244, 200)
	top_margin.add_child(img_control)

	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img_control.add_child(tex_rect)

	# Skin loading logic
	var current_skin = _get_selected_skin_name(cart_id, game_name, cart.manifest)
	var default_skin = _get_default_skin_name(cart.manifest, game_name)
	var skins = _get_skin_list(cart.manifest, game_name)
	var thumb_path = cart.thumb_path

	if current_skin != "":
		var skin_suffix = current_skin.to_lower().replace(" ", "_")
		var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
		var skin_thumb_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("thumbnail_" + skin_suffix + ".png")
		if FileAccess.file_exists(skin_thumb_path):
			thumb_path = skin_thumb_path

	if FileAccess.file_exists(thumb_path):
		var img = Image.load_from_file(thumb_path)
		if img: tex_rect.texture = ImageTexture.create_from_image(img)

	# Overlays
	var index_lbl = Label.new()
	index_lbl.text = str(display_index) + "." if display_index > 0 else ""
	index_lbl.add_theme_font_size_override("font_size", 16)
	index_lbl.add_theme_color_override("font_color", color_cyan)
	index_lbl.position = Vector2(8, 8)
	img_control.add_child(index_lbl)

	var fav_btn = Button.new()
	fav_btn.text = "★" if is_fav else "☆"
	fav_btn.custom_minimum_size = Vector2(36, 36)
	fav_btn.add_theme_font_size_override("font_size", 20)
	if is_fav: fav_btn.add_theme_color_override("font_color", color_cyan)
	else: fav_btn.add_theme_color_override("font_color", color_ink_dim)
	var fav_style = StyleBoxEmpty.new()
	fav_btn.add_theme_stylebox_override("normal", fav_style)
	fav_btn.add_theme_stylebox_override("hover", fav_style)
	fav_btn.add_theme_stylebox_override("pressed", fav_style)
	fav_btn.add_theme_stylebox_override("focus", fav_style)
	fav_btn.position = Vector2(244 - 36 - 4, 4)
	fav_btn.pressed.connect(func():
		toggle_favorite(cart_id)
		display_games()
	)
	img_control.add_child(fav_btn)

	var prev_skin_btn = Button.new()
	prev_skin_btn.text = "<"
	prev_skin_btn.custom_minimum_size = Vector2(36, 48)
	prev_skin_btn.add_theme_font_size_override("font_size", 24)
	var arrow_style = StyleBoxFlat.new()
	arrow_style.bg_color = Color(0,0,0, 0.4)
	prev_skin_btn.add_theme_stylebox_override("normal", arrow_style)
	prev_skin_btn.position = Vector2(0, 100 - 24)
	prev_skin_btn.pressed.connect(func():
		_cycle_skin(cart_id, skins, -1)
	)
	img_control.add_child(prev_skin_btn)

	var next_skin_btn = Button.new()
	next_skin_btn.text = ">"
	next_skin_btn.custom_minimum_size = Vector2(36, 48)
	next_skin_btn.add_theme_font_size_override("font_size", 24)
	next_skin_btn.add_theme_stylebox_override("normal", arrow_style)
	next_skin_btn.position = Vector2(244 - 36, 100 - 24)
	next_skin_btn.pressed.connect(func():
		_cycle_skin(cart_id, skins, 1)
	)
	img_control.add_child(next_skin_btn)

	# Title
	var bottom_margin = MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 8)
	bottom_margin.add_theme_constant_override("margin_right", 8)
	bottom_margin.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(bottom_margin)

	var title_btn = Button.new()
	var display_title = game_name
	title_btn.text = display_title
	title_btn.custom_minimum_size = Vector2(0, 36)
	title_btn.add_theme_font_size_override("font_size", 16)
	style_grid_button(title_btn)
	title_btn.pressed.connect(func():
		_launch_game(cart_id)
	)
	bottom_margin.add_child(title_btn)

"""

display_games_new = """func display_games():
	clear_main_panel()
	current_tab = "Games"
	
	# We will dynamically create the GridContainers here inside the scroll_vbox instead of scenes_grid
	# clear scenes_grid
	scenes_grid.visible = false
	
	# Clear previous custom grids from scroll_vbox
	for child in scroll_vbox.get_children():
		if child != scenes_grid:
			child.queue_free()

	var games = get_sorted_cartridges()
	
	if sort_favorites_first:
		var favs = []
		var others = []
		for g in games:
			if g.favorite: favs.append(g)
			else: others.append(g)
		
		if favs.size() > 0:
			var fav_lbl = Label.new()
			fav_lbl.text = "Favorites"
			fav_lbl.add_theme_font_size_override("font_size", 24)
			scroll_vbox.add_child(fav_lbl)
			var fav_grid = GridContainer.new()
			fav_grid.columns = 3
			fav_grid.add_theme_constant_override("h_separation", 16)
			fav_grid.add_theme_constant_override("v_separation", 16)
			scroll_vbox.add_child(fav_grid)
			for game in favs:
				_create_game_card(game, fav_grid, game.absolute_index)
		
		if others.size() > 0:
			var other_lbl = Label.new()
			other_lbl.text = "All Games"
			other_lbl.add_theme_font_size_override("font_size", 24)
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_top", 24)
			margin.add_child(other_lbl)
			scroll_vbox.add_child(margin)
			var other_grid = GridContainer.new()
			other_grid.columns = 3
			other_grid.add_theme_constant_override("h_separation", 16)
			other_grid.add_theme_constant_override("v_separation", 16)
			scroll_vbox.add_child(other_grid)
			for game in others:
				_create_game_card(game, other_grid, game.absolute_index)
				
	else:
		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		scroll_vbox.add_child(grid)
		for game in games:
			_create_game_card(game, grid, game.absolute_index)

"""

i = 0
while i < len(lines):
    l = lines[i]
    if l.startswith("func _create_game_card("):
        new_content.append(create_game_new)
        # Skip until next function
        i += 1
        while i < len(lines) and not lines[i].startswith("func _create_level_card("):
            i += 1
        continue
    
    if l.startswith("func display_games("):
        new_content.append(display_games_new)
        i += 1
        while i < len(lines) and not lines[i].startswith("func _launch_game("):
            i += 1
        continue
    
    if l.startswith("\tlist.sort_custom(func(a, b):"):
        # We need to replace sorting logic inside _get_cartridge_list
        # But wait, it spans multiple lines.
        # We'll detect it and replace it.
        if "order_favorites_first" in lines[i+1]:
            # This is the sorting block
            sort_block = """	list.sort_custom(func(a, b):
		var name_a = _get_cartridge_sort_name(a.game_name)
		var name_b = _get_cartridge_sort_name(b.game_name)
		return name_a < name_b
	)
	for idx in range(list.size()):
		list[idx].absolute_index = idx + 1
	if order_favorites_first:
		list.sort_custom(func(a, b):
			if a.favorite != b.favorite:
				return a.favorite
			var name_a = _get_cartridge_sort_name(a.game_name)
			var name_b = _get_cartridge_sort_name(b.game_name)
			return name_a < name_b
		)
	return list
"""
            new_content.append(sort_block)
            i += 1
            while i < len(lines) and not lines[i].startswith("func _on_sort_favorites_toggled("):
                i += 1
            continue
            
    new_content.append(l)
    i += 1

with open('app/hub/main.gd', 'w', encoding='utf-8') as f:
    f.writelines(new_content)
