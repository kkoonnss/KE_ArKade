extends Control

@onready var launcher = $Launcher
@onready var scenes_grid = $UI/Content/MainPanel/ScrollContainer/ScenesGrid
@onready var panic_btn = $UI/TopBar/PanicBlackBtn
@onready var restore_btn = $UI/TopBar/RestoreBtn
@onready var panic_overlay = $PanicOverlay

var is_panic = false
var last_known_scene = ""
var last_known_level = ""
var last_known_cartridge = ""

var current_scene = ""
var viewing_levels = false
var last_launch_time = 0.0
var color_black = Color(0, 0, 0, 1)
var color_surface1 = Color(0.04, 0.04, 0.04, 1) # #0A0A0A
var color_surface2 = Color(0.07, 0.08, 0.09, 1) # #111418
var color_ink_white = Color(1, 1, 1, 1)
var color_ink_dim = Color(0.6, 0.63, 0.65, 1) # #9AA0A6
var color_cyan = Color(0.0, 0.9, 1.0, 1) # #00E5FF
var color_panic_red = Color(1.0, 0.18, 0.3, 1)
var color_border_default = Color(1, 1, 1, 0.14)
var style_panel: StyleBoxFlat
var style_btn_normal: StyleBoxFlat
var style_btn_hover: StyleBoxFlat
var style_btn_pressed: StyleBoxFlat
var style_nav_normal: StyleBoxFlat
var style_nav_active: StyleBoxFlat


var launch_dialog: ColorRect
var level_title_label: Label
var cartridge_buttons_container: Container
var selected_level_name = ""
var favorite_cartridges: Array = ["tetris", "pacman", "bomberman", "frogger", "asteroids"]
var sort_favorites_first: bool = true
var current_tab = ""
var tab_header_bar: HBoxContainer
var sort_fav_checkbox: CheckBox
var dialog_sort_fav_checkbox: CheckBox
var selected_skins: Dictionary = {}
var _updating_main_checkbox = false
var _updating_dialog_checkbox = false
var scroll_vbox: VBoxContainer
var active_nav_btn: Button = null
var dialog_scroll_vbox: VBoxContainer

func _ready():
	if scenes_grid is GridContainer: scenes_grid.columns = 3
	
	# Initialize scroll_vbox to wrap ScenesGrid
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	if scroll_container and scenes_grid:
		scroll_container.remove_child(scenes_grid)
		scroll_vbox = VBoxContainer.new()
		scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_theme_constant_override("separation", 24)
		scroll_container.add_child(scroll_vbox)
		scroll_vbox.add_child(scenes_grid)
		
	init_styling()
	load_favorites()
	if launcher: launcher.cartridge_exited.connect(_on_cartridge_exited)
	
	panic_overlay.visible = false
	if panic_btn: panic_btn.pressed.connect(_on_panic_pressed)
	if restore_btn: restore_btn.pressed.connect(_on_restore_pressed)
	
	var nav = $UI/Content/SideNav
	if nav.has_node("ScenesBtn"): nav.get_node("ScenesBtn").pressed.connect(display_scenes)
	if nav.has_node("GamesBtn"): nav.get_node("GamesBtn").pressed.connect(display_games)
	if nav.has_node("LevelsBtn"): nav.get_node("LevelsBtn").pressed.connect(display_levels)
	if nav.has_node("DesignBtn"): nav.get_node("DesignBtn").pressed.connect(_on_design_nav_pressed)
	if nav.has_node("CalibrateBtn"): nav.get_node("CalibrateBtn").pressed.connect(_on_launch_calibration_tool)
	if nav.has_node("TestPatternBtn"): nav.get_node("TestPatternBtn").pressed.connect(_on_test_pattern_pressed)
	
	if nav.has_node("SortFavBtn"): nav.get_node("SortFavBtn").toggled.connect(_on_sort_favorites_toggled)
	
	display_scenes()

func clear_main_panel():
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	if scroll_container:
		scroll_container.visible = true
	for child in $UI/Content/MainPanel.get_children():
		if child != scroll_container:
			child.queue_free()
	for child in scenes_grid.get_children():
		child.queue_free()
	_prepare_scroll_view(true)

func set_active_nav(active_btn: Button):
	active_nav_btn = active_btn

func display_scenes():
	clear_main_panel()
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/scenes")
	var dir = DirAccess.open(base_dir)
	var scenes = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."): 
				scenes.append(file_name)
			file_name = dir.get_next()
			
	scenes.sort_custom(func(a, b):
		var a_is_classic = (a == "scene_classic_pack" or "classic" in a.to_lower())
		var b_is_classic = (b == "scene_classic_pack" or "classic" in b.to_lower())
		if a_is_classic and not b_is_classic:
			return true
		if b_is_classic and not a_is_classic:
			return false
		return a < b
	)
	
	for i in range(scenes.size()):
		_create_level_card(scenes[i], base_dir, scenes_grid, i, true)
func style_grid_button(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 4
	style.border_color = Color(0.1, 0.1, 0.1, 1.0)
	btn.add_theme_stylebox_override("normal", style)
	
	var hover = style.duplicate()
	hover.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = style.duplicate()
	pressed.bg_color = Color(0.1, 0.1, 0.12, 1.0)
	pressed.border_width_bottom = 0
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_font_size_override("font_size", 24)

func _on_scene_selected(scene_name: String):
	current_scene = scene_name
	if scene_name == "scene_classic_pack":
		display_games()
	else:
		display_levels()

func display_levels():
	clear_main_panel()
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/scenes").path_join(current_scene).path_join("levels")
	var dir = DirAccess.open(base_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var index = 0
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."): 
				_create_level_card(file_name, base_dir, scenes_grid, index)
				index += 1
			file_name = dir.get_next()
func _on_level_selected(level_name: String):
	selected_level_name = level_name
	display_games()

func display_games():
	clear_main_panel()
	current_tab = "Games"
	
	scenes_grid.visible = false
	
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

func _launch_game(cart_id: String):
	if current_scene == "" or current_scene == "scene_classic_pack":
		if cart_id in ["tetris", "pacman", "bomberman", "frogger", "asteroids", "tron", "on_track", "rampage", "gta"]:
			current_scene = "scene_classic_pack"
			selected_level_name = "classic_" + cart_id
		
	if current_scene == "" or selected_level_name == "":
		current_scene = "scene_demo_wall"
		selected_level_name = "demo_level"
		
	last_known_level = selected_level_name
	last_known_cartridge = cart_id
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../..")
	var scene_dir = base_dir.path_join("content/scenes").path_join(current_scene)
	var level_dir = scene_dir.path_join("levels").path_join(selected_level_name)
	var cart_dir = base_dir.path_join("content/cartridges").path_join(cart_id)
	
	var launch_cmd = "Godot_v4.3-stable_win64.exe"
	var args_template = "--path \"" + cart_dir + "\" --scene \"" + scene_dir + "\" --level \"" + level_dir + "\""
	
	if launcher:
		launcher.launch(launch_cmd, args_template, scene_dir, level_dir)

func log_debug(msg: String):
	print(msg)

func _on_panic_pressed():
	is_panic = not is_panic
	panic_overlay.visible = is_panic
	if is_panic and launcher:
		launcher.kill_cartridge()

func _on_restore_pressed():
	if last_known_cartridge != "":
		_launch_game(last_known_cartridge)

func _on_design_nav_pressed():
	current_tab = "Design"
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	if scroll_container:
		scroll_container.visible = false
		
	for child in $UI/Content/MainPanel.get_children():
		if child != scroll_container:
			child.queue_free()
			
	var design = load("res://design_screen.tscn").instantiate()
	$UI/Content/MainPanel.add_child(design)

func _on_launch_calibration_tool():
	pass

func _on_test_pattern_pressed():
	pass

func parse_simple_yaml(path: String) -> Dictionary:
	return {}

func _get_repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../..")
func _create_game_card(cart: Dictionary, parent_grid: Container, display_index: int = -1):
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
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_control.add_child(tex_rect)
	
	var cover_btn = Button.new()
	cover_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var empty_style = StyleBoxEmpty.new()
	cover_btn.add_theme_stylebox_override("normal", empty_style)
	cover_btn.add_theme_stylebox_override("hover", empty_style)
	cover_btn.add_theme_stylebox_override("pressed", empty_style)
	cover_btn.add_theme_stylebox_override("focus", empty_style)
	cover_btn.pressed.connect(func(): _launch_game(cart_id))
	img_control.add_child(cover_btn)

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
	fav_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fav_btn.offset_left = -40
	fav_btn.offset_right = -4
	fav_btn.offset_top = 4
	fav_btn.offset_bottom = 40
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
	prev_skin_btn.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	prev_skin_btn.offset_left = 0
	prev_skin_btn.offset_right = 36
	prev_skin_btn.pressed.connect(func():
		_cycle_skin(cart_id, skins, -1)
	)
	img_control.add_child(prev_skin_btn)

	var next_skin_btn = Button.new()
	next_skin_btn.text = ">"
	next_skin_btn.custom_minimum_size = Vector2(36, 48)
	next_skin_btn.add_theme_font_size_override("font_size", 24)
	next_skin_btn.add_theme_stylebox_override("normal", arrow_style)
	next_skin_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	next_skin_btn.offset_left = -36
	next_skin_btn.offset_right = 0
	next_skin_btn.pressed.connect(func():
		_cycle_skin(cart_id, skins, 1)
	)
	img_control.add_child(next_skin_btn)

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
	title_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.16, 0.18)
	style_normal.set_corner_radius_all(4)
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.22, 0.25)
	style_hover.border_width_bottom = 2
	style_hover.border_color = color_cyan
	style_hover.set_corner_radius_all(4)
	
	title_btn.add_theme_stylebox_override("normal", style_normal)
	title_btn.add_theme_stylebox_override("hover", style_hover)
	title_btn.add_theme_stylebox_override("pressed", style_hover)
	title_btn.add_theme_stylebox_override("focus", style_hover)
	title_btn.pressed.connect(func():
		_launch_game(cart_id)
	)
	bottom_margin.add_child(title_btn)

func _create_level_card(level_name: String, levels_dir: String, container: Control, display_index: int = -1, is_scene: bool = false):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(256, 284)
	btn.pressed.connect(func(): _on_level_selected(level_name))
	container.add_child(btn)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	

	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")

	var classic_level_to_cartridge = {

		"classic_tetris": "tetris",

		"classic_pacman": "pacman",

		"classic_bomberman": "bomberman",

		"classic_frogger": "frogger",

		"classic_asteroids": "asteroids",

		"classic_tron": "tron",

		"classic_on_track": "on_track",

		"classic_rampage": "rampage",

		"classic_gta": "gta"

	}

	var cart_id = classic_level_to_cartridge.get(level_name, "")

	if cart_id == "":

		cart_id = level_name.replace("classic_", "")



	# Determine classic name

	var classic_name = get_level_classic_name(level_name)

	var active_skin_name = ""

	var is_classic_skin = true

	

	if cart_id != "":

		var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")

		if FileAccess.file_exists(manifest_path):

			var manifest = parse_simple_yaml(manifest_path)

			var skins = manifest.get("skins", [])

			var selected_skin = selected_skins.get(cart_id, "")

			

			var default_skin = ""

			if typeof(skins) == TYPE_ARRAY and skins.size() > 0:

				default_skin = str(skins[0])

			else:

				default_skin = "Classic " + classic_name

			

			if selected_skin != "" and selected_skin != default_skin:

				active_skin_name = selected_skin

				is_classic_skin = false



	# Load dynamic/skin-specific cover art if available

	var thumb_path = ""

	if not is_classic_skin and active_skin_name != "":

		var skin_suffix = active_skin_name.to_lower().replace(" ", "_")

		var skin_thumb_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("thumbnail_" + skin_suffix + ".png")

		if FileAccess.file_exists(skin_thumb_path):

			thumb_path = skin_thumb_path

			

	if thumb_path == "":

		var lvl_thumb = levels_dir.path_join(level_name).path_join("thumbnail.png")

		if FileAccess.file_exists(lvl_thumb):

			thumb_path = lvl_thumb

		elif cart_id != "":

			var cart_thumb = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("thumbnail.png")

			if FileAccess.file_exists(cart_thumb):

				thumb_path = cart_thumb



	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(232, 176)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if FileAccess.file_exists(thumb_path):
		var img = Image.load_from_file(thumb_path)
		if img: tex_rect.texture = ImageTexture.create_from_image(img)
		
	if display_index >= 0:
		var number_lbl = Label.new()
		number_lbl.text = str(display_index + 1) + "."
		number_lbl.add_theme_font_size_override("font_size", 22)
		number_lbl.add_theme_color_override("font_color", Color(0, 0.9, 1.0))
		number_lbl.position = Vector2(8, 8)
		tex_rect.add_child(number_lbl)
		
	vbox.add_child(tex_rect)
	
	# Text layout
	var text_container = VBoxContainer.new()
	text_container.custom_minimum_size = Vector2(0, 68)
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_container.alignment = BoxContainer.ALIGNMENT_CENTER
	text_container.add_theme_constant_override("separation", 6)
	text_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(text_container)

	var top_text_spacer = Control.new()
	top_text_spacer.custom_minimum_size = Vector2(0, 2)
	top_text_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(top_text_spacer)
	
	var title_lbl = Label.new()
	if is_scene or not level_name.begins_with("classic_"):
		title_lbl.text = level_name
	else:
		title_lbl.text = classic_name.replace("Classic ", "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(title_lbl)
	
	

	var bottom_text_spacer = Control.new()
	bottom_text_spacer.custom_minimum_size = Vector2(0, 4)
	bottom_text_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(bottom_text_spacer)
	

	style_grid_button(btn)




func init_styling():

	style_panel = StyleBoxFlat.new()

	style_panel.bg_color = color_surface1

	style_panel.set_border_width_all(1)

	style_panel.border_color = color_border_default

	style_panel.corner_detail = 1

	

	style_btn_normal = StyleBoxFlat.new()

	style_btn_normal.bg_color = color_black

	style_btn_normal.set_border_width_all(1)

	style_btn_normal.border_color = Color(1, 1, 1, 0.16)

	style_btn_normal.corner_detail = 1

	

	style_btn_hover = StyleBoxFlat.new()

	style_btn_hover.bg_color = color_black

	style_btn_hover.set_border_width_all(1)

	style_btn_hover.border_color = color_cyan

	style_btn_hover.corner_detail = 1

	

	style_btn_pressed = StyleBoxFlat.new()

	style_btn_pressed.bg_color = color_cyan

	style_btn_pressed.set_border_width_all(1)

	style_btn_pressed.border_color = color_cyan

	style_btn_pressed.corner_detail = 1

	

	style_nav_normal = StyleBoxFlat.new()

	style_nav_normal.bg_color = color_black

	style_nav_normal.set_border_width_all(0)

	style_nav_normal.corner_detail = 1

	

	style_nav_active = StyleBoxFlat.new()

	style_nav_active.bg_color = Color(0.0, 0.9, 1.0, 0.08)

	style_nav_active.set_border_width_all(0)

	style_nav_active.border_width_left = 3

	style_nav_active.border_color = color_cyan

	style_nav_active.corner_detail = 1




func toggle_favorite(cart_id: String):
	if cart_id in favorite_cartridges:
		favorite_cartridges.erase(cart_id)
	else:
		favorite_cartridges.append(cart_id)
	save_favorites()


func save_favorites():

	var file = FileAccess.open("user://favorites.json", FileAccess.WRITE)

	if file:

		var data = {

			"favorites": favorite_cartridges,

			"sort_favorites_first": sort_favorites_first,

			"selected_skins": selected_skins

		}

		file.store_string(JSON.stringify(data))




func load_favorites():

	var path = "user://favorites.json"

	if FileAccess.file_exists(path):

		var file = FileAccess.open(path, FileAccess.READ)

		if file:

			var json = JSON.new()

			if json.parse(file.get_as_text()) == OK:

				var data = json.data

				if typeof(data) == TYPE_ARRAY:

					favorite_cartridges = []

					for item in data:

						favorite_cartridges.append(str(item))

					sort_favorites_first = true

				elif typeof(data) == TYPE_DICTIONARY:

					if "favorites" in data and typeof(data["favorites"]) == TYPE_ARRAY:

						favorite_cartridges = []

						for item in data["favorites"]:

							favorite_cartridges.append(str(item))

					if "sort_favorites_first" in data:

						sort_favorites_first = bool(data["sort_favorites_first"])

					if "selected_skins" in data and typeof(data["selected_skins"]) == TYPE_DICTIONARY:

						selected_skins = data["selected_skins"]




func _get_cartridge_sort_name(game_name: String) -> String:
	var normalized = game_name.to_lower()
	if normalized.begins_with("classic "):
		normalized = normalized.trim_prefix("classic ")
	return normalized


func get_sorted_cartridges() -> Array:
	return _get_cartridge_list(sort_favorites_first)


func _get_skin_list(manifest: Dictionary, game_name: String) -> Array:
	var skins = manifest.get("skins", [])

	if typeof(skins) == TYPE_ARRAY and skins.size() > 0:

		var list = []

		for skin in skins:

			list.append(str(skin))

		return list

	return ["Classic " + game_name, "Synthwave", "8-Bit Retro"]




func _cycle_skin(cart_id: String, skin_names: Array, step: int):

	if skin_names.is_empty():

		return

	var current = str(selected_skins.get(cart_id, skin_names[0]))

	var idx = skin_names.find(current)

	if idx < 0:

		idx = 0

	idx = (idx + step + skin_names.size()) % skin_names.size()

	selected_skins[cart_id] = str(skin_names[idx])

	save_favorites()

	_refresh_card_views()




func _prepare_scroll_view(show_default_grid: bool):
	if scenes_grid:
		scenes_grid.visible = show_default_grid
	if scroll_vbox:
		for child in scroll_vbox.get_children():

			if child != scenes_grid:

				child.queue_free()




func is_level_favorited(level_name: String) -> bool:

	var classic_level_to_cartridge = {

		"classic_tetris": "tetris",

		"classic_pacman": "pacman",

		"classic_bomberman": "bomberman",

		"classic_frogger": "frogger",

		"classic_asteroids": "asteroids",

		"classic_tron": "tron",

		"classic_on_track": "on_track",

		"classic_rampage": "rampage",

		"classic_gta": "gta"

	}

	var cart_id = classic_level_to_cartridge.get(level_name, "")

	if cart_id == "":

		cart_id = level_name.replace("classic_", "")

	if cart_id != "" and cart_id in favorite_cartridges:

		return true

	return false




func get_level_classic_name(level_name: String) -> String:

	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")

	var classic_level_to_cartridge = {

		"classic_tetris": "tetris",

		"classic_pacman": "pacman",

		"classic_bomberman": "bomberman",

		"classic_frogger": "frogger",

		"classic_asteroids": "asteroids",

		"classic_tron": "tron",

		"classic_on_track": "on_track",

		"classic_rampage": "rampage",

		"classic_gta": "gta"

	}

	var cart_id = classic_level_to_cartridge.get(level_name, "")

	if cart_id == "":

		cart_id = level_name.replace("classic_", "")

	

	var display_name = level_name.replace("classic_", "").capitalize().replace("Classic ", "")
	if level_name == "scene_classic_pack":
		display_name = "Classic Pack"

	if cart_id != "":

		var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")

		if FileAccess.file_exists(manifest_path):

			var manifest = parse_simple_yaml(manifest_path)

			var manifest_game_name = manifest.get("game_name", "")

			if manifest_game_name != "":

				display_name = manifest_game_name

	return display_name




func _get_cartridge_list(order_favorites_first: bool) -> Array:
	var list = []
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
	var carts_dir = base_dir.path_join("content/cartridges")
	var dir = DirAccess.open(carts_dir)
	if dir:
		dir.list_dir_begin()

		var file_name = dir.get_next()

		while file_name != "":

			if dir.current_is_dir() and not file_name.begins_with("."):

				if file_name != "loopback":

					var cart_id = file_name

					var manifest_path = carts_dir.path_join(cart_id).path_join("manifest.yaml")

					var manifest = parse_simple_yaml(manifest_path)

					var game_name = manifest.get("game_name", cart_id)

					var is_fav = cart_id in favorite_cartridges

					list.append({
						"id": cart_id,
						"game_name": game_name,
						"favorite": is_fav,
						"manifest": manifest,
						"thumb_path": carts_dir.path_join(cart_id).path_join("thumbnail.png")

					})

			file_name = dir.get_next()
			
	list.sort_custom(func(a, b):
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

func _on_sort_favorites_toggled(pressed: bool):

	if _updating_main_checkbox:

		return

	sort_favorites_first = pressed

	save_favorites()

	if dialog_sort_fav_checkbox:

		_updating_dialog_checkbox = true

		dialog_sort_fav_checkbox.button_pressed = pressed

		_updating_dialog_checkbox = false

	if current_tab == "games":

		display_games()





func _get_selected_skin_name(cart_id: String, game_name: String, manifest: Dictionary) -> String:

	var default_skin = _get_default_skin_name(manifest, game_name)

	var selected_skin_name = str(selected_skins.get(cart_id, ""))

	if selected_skin_name == "":

		return default_skin

	return selected_skin_name




func _get_default_skin_name(manifest: Dictionary, game_name: String) -> String:

	var skins = _get_skin_list(manifest, game_name)

	return str(skins[0]) if skins.size() > 0 else "Classic " + game_name




func _refresh_card_views():

	if current_tab == "games":

		display_games()

	elif current_tab == "levels" and launch_dialog and launch_dialog.visible and selected_level_name != "":

		_on_level_selected(selected_level_name)

	elif viewing_levels and current_scene != "":

		_on_scene_selected(current_scene)




func _on_cartridge_exited(clean: bool):

	print("Cartridge exited clean: ", clean)

	if not clean and not is_panic:

		var running_duration = (Time.get_ticks_msec() / 1000.0) - last_launch_time

		if running_duration < 2.0:

			log_debug("Cartridge crashed immediately on startup (run time: %.2fs). Auto-restore disabled to prevent infinite loops." % running_duration)

		else:

			log_debug("Crash/timeout detected after %.2fs, restoring last known good..." % running_duration)

			_on_restore_pressed()






