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
var dialog_scroll_vbox: VBoxContainer

var debug_logs: Array[String] = []
var debug_panel: VBoxContainer = null
var last_launch_time: float = 0.0

# Styling Theme
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
var picker_desc_label: Label
var status_label_ref: Label

func _ready():
	load_favorites()
	init_styling()
	
	# Dynamically modify the tree to add the TabHeaderBar above the ScrollContainer
	var scroll_container = $UI/Content/MainPanel/ScrollContainer
	var main_panel = $UI/Content/MainPanel
	main_panel.remove_child(scroll_container)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(content_vbox)
	
	tab_header_bar = HBoxContainer.new()
	tab_header_bar.name = "TabHeaderBar"
	tab_header_bar.custom_minimum_size = Vector2(0, 50)
	tab_header_bar.visible = false
	content_vbox.add_child(tab_header_bar)
	
	var tab_title = Label.new()
	tab_title.name = "TabTitle"
	tab_title.text = "CARTRIDGES LIBRARY"
	tab_title.add_theme_font_size_override("font_size", 24)
	tab_title.add_theme_color_override("font_color", color_ink_white)
	tab_header_bar.add_child(tab_title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_header_bar.add_child(spacer)
	
	sort_fav_checkbox = CheckBox.new()
	sort_fav_checkbox.name = "SortFavCheckbox"
	sort_fav_checkbox.text = "Sort Favorites First"
	sort_fav_checkbox.button_pressed = sort_favorites_first
	sort_fav_checkbox.add_theme_font_size_override("font_size", 16)
	sort_fav_checkbox.add_theme_color_override("font_color", color_ink_white)
	sort_fav_checkbox.toggled.connect(_on_sort_favorites_toggled)
	tab_header_bar.add_child(sort_fav_checkbox)
	
	content_vbox.add_child(scroll_container)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scenes_grid = scroll_container.get_node("ScenesGrid")
	
	scroll_container.remove_child(scenes_grid)
	scroll_vbox = VBoxContainer.new()
	scroll_vbox.name = "ScrollVBox"
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_vbox.add_theme_constant_override("separation", 20)
	scroll_vbox.add_child(scenes_grid)
	scroll_container.add_child(scroll_vbox)
	
	# Apply basic styling
	$Background.color = color_black
	$PanicOverlay.color = color_black
	$PanicOverlay/Label.visible = false # Hide label completely to project zero light during panic
	
	$UI/Content/MainPanel.add_theme_stylebox_override("panel", style_panel)
	
	# Title styling
	var title_lbl = $UI/TopBar/Title
	title_lbl.text = "KE_ArKade"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", color_ink_white)
	
	# Panic Button styling
	var panic_style_normal = StyleBoxFlat.new()
	panic_style_normal.bg_color = color_black
	panic_style_normal.set_border_width_all(1)
	panic_style_normal.border_color = color_panic_red
	panic_style_normal.corner_detail = 1
	var splash_overlay = ColorRect.new()
	splash_overlay.color = color_black
	splash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(splash_overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_overlay.add_child(center)
	
	var tex = load("res://assets/logo.png")
	if tex:
		var t_rect = TextureRect.new()
		t_rect.texture = tex
		center.add_child(t_rect)
		
	var tween = create_tween()
	tween.tween_property(splash_overlay, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(splash_overlay.queue_free)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_panic_pressed()

func log_debug(msg: String):
	var time = Time.get_time_string_from_system()
	var formatted = "[%s] %s" % [time, msg]
	debug_logs.append(formatted)
	if debug_logs.size() > 100:
		debug_logs.remove_at(0)
	
	print(formatted)
	_refresh_debug_panel()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_panic_pressed()

func log_debug(msg: String):
	var time = Time.get_time_string_from_system()
	var formatted = "[%s] %s" % [time, msg]
	debug_logs.append(formatted)
	if debug_logs.size() > 100:
		debug_logs.remove_at(0)
	
	print(formatted)
	_refresh_debug_panel()

func init_styling():
	style_panel = StyleBoxFlat.new()
	style_panel.bg_color = color_surface1
	style_panel.set_border_width_all(1)
	style_panel.border_color = color_border_default
	style_panel.corner_detail = 1
	
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_overlay.add_child(center)
	
	var tex = load("res://assets/logo.png")
	if tex:
		var t_rect = TextureRect.new()
		t_rect.texture = tex
		center.add_child(t_rect)
		
	var tween = create_tween()
	tween.tween_property(splash_overlay, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(splash_overlay.queue_free)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_panic_pressed()

func log_debug(msg: String):
	var time = Time.get_time_string_from_system()
	var formatted = "[%s] %s" % [time, msg]
	debug_logs.append(formatted)
	if debug_logs.size() > 100:
		debug_logs.remove_at(0)
	
	print(formatted)
	_refresh_debug_panel()

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

func set_active_nav(active_btn: Button):
	var nav_buttons = [
		$UI/Content/SideNav/ScenesBtn,
		$UI/Content/SideNav/GamesBtn,
		$UI/Content/SideNav/LevelsBtn,
		$UI/Content/SideNav/CalibrateBtn,
		$UI/Content/SideNav/DevicesBtn,
		$UI/Content/SideNav/ServiceBtn,
		$UI/Content/SideNav/TestPatternBtn
	]
	
	for btn in nav_buttons:
		if btn == active_btn:
			btn.add_theme_stylebox_override("normal", style_nav_active)
			btn.add_theme_stylebox_override("hover", style_nav_active)
			btn.add_theme_stylebox_override("pressed", style_nav_active)
			btn.add_theme_color_override("font_color", color_cyan)
			btn.add_theme_color_override("font_hover_color", color_cyan)
			btn.add_theme_color_override("font_pressed_color", color_cyan)
		else:
			btn.add_theme_stylebox_override("normal", style_nav_normal)
			btn.add_theme_stylebox_override("hover", style_btn_hover)
			btn.add_theme_stylebox_override("pressed", style_btn_pressed)
			btn.add_theme_color_override("font_color", color_ink_dim)
			btn.add_theme_color_override("font_hover_color", color_ink_white)
			btn.add_theme_color_override("font_pressed_color", color_black)

func style_grid_button(btn: Button):
	btn.add_theme_stylebox_override("normal", style_btn_normal)
	btn.add_theme_stylebox_override("hover", style_btn_hover)
	btn.add_theme_stylebox_override("pressed", style_btn_pressed)
	btn.add_theme_color_override("font_color", color_ink_dim)
	btn.add_theme_color_override("font_hover_color", color_ink_white)
	btn.add_theme_color_override("font_pressed_color", color_black)

func setup_launch_dialog():
	launch_dialog = ColorRect.new()
	launch_dialog.color = Color(0, 0, 0, 0.75)
	launch_dialog.visible = false
	add_child(launch_dialog)
	launch_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var center_container = CenterContainer.new()
	launch_dialog.add_child(center_container)
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 600)
	center_container.add_child(panel)
	panel.add_theme_stylebox_override("panel", style_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	level_title_label = Label.new()
	level_title_label.text = "SELECT CARTRIDGE"
	level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_title_label.add_theme_font_size_override("font_size", 22)
	level_title_label.add_theme_color_override("font_color", color_ink_white)
	vbox.add_child(level_title_label)
	
	picker_desc_label = Label.new()
	picker_desc_label.text = "SELECT A CARTRIDGE - COMPATIBLE WITH THIS WALL ARENA"
	picker_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker_desc_label.add_theme_font_size_override("font_size", 12)
	picker_desc_label.add_theme_color_override("font_color", color_ink_dim)
	vbox.add_child(picker_desc_label)
	
	dialog_sort_fav_checkbox = CheckBox.new()
	dialog_sort_fav_checkbox.name = "DialogSortFavCheckbox"
	dialog_sort_fav_checkbox.text = "Sort Favorites First"
	dialog_sort_fav_checkbox.button_pressed = sort_favorites_first
	dialog_sort_fav_checkbox.add_theme_font_size_override("font_size", 14)
	dialog_sort_fav_checkbox.add_theme_color_override("font_color", color_ink_white)
	dialog_sort_fav_checkbox.toggled.connect(func(pressed):
		if _updating_dialog_checkbox:
			return
		sort_favorites_first = pressed
		save_favorites()
		if sort_fav_checkbox:
			_updating_main_checkbox = true
			sort_fav_checkbox.button_pressed = pressed
			_updating_main_checkbox = false
		_on_level_selected(selected_level_name)
	)
	
	var chk_hbox = HBoxContainer.new()
	chk_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	chk_hbox.add_child(dialog_sort_fav_checkbox)
	vbox.add_child(chk_hbox)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 350)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	dialog_scroll_vbox = VBoxContainer.new()
	dialog_scroll_vbox.name = "DialogScrollVBox"
	dialog_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_scroll_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dialog_scroll_vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(dialog_scroll_vbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(150, 44)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.pressed.connect(func(): launch_dialog.visible = false)
	style_grid_button(cancel_btn)
	
	var center_box = HBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_child(cancel_btn)
	vbox.add_child(center_box)

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

func save_favorites():
	var file = FileAccess.open("user://favorites.json", FileAccess.WRITE)
	if file:
		var data = {
			"favorites": favorite_cartridges,
			"sort_favorites_first": sort_favorites_first,
			"selected_skins": selected_skins
		}
		file.store_string(JSON.stringify(data))

func toggle_favorite(cart_id: String):
	if cart_id in favorite_cartridges:
		favorite_cartridges.erase(cart_id)
	else:
		favorite_cartridges.append(cart_id)
	save_favorites()

func _get_cartridge_sort_name(game_name: String) -> String:
	var normalized = game_name.to_lower()
	if normalized.begins_with("classic "):
		normalized = normalized.trim_prefix("classic ")
	return normalized

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
		if order_favorites_first:
			if a.favorite != b.favorite:
				return a.favorite
		var name_a = _get_cartridge_sort_name(a.game_name)
		var name_b = _get_cartridge_sort_name(b.game_name)
		return name_a < name_b
	)
	return list

func get_sorted_cartridges() -> Array:
	return _get_cartridge_list(sort_favorites_first)

func get_catalog_cartridge_indices() -> Dictionary:
	var catalog = _get_cartridge_list(false)
	var indices: Dictionary = {}
	for i in range(catalog.size()):
		indices[catalog[i].id] = i + 1
	return indices

func _prepare_scroll_view(show_default_grid: bool):
	if scenes_grid:
		scenes_grid.visible = show_default_grid
	if scroll_vbox:
		for child in scroll_vbox.get_children():
			if child != scenes_grid:
				child.queue_free()

func display_games():
	set_active_nav($UI/Content/SideNav/GamesBtn)
	
	current_tab = "games"
	if tab_header_bar:
		tab_header_bar.visible = true
		_updating_main_checkbox = true
		sort_fav_checkbox.button_pressed = sort_favorites_first
		_updating_main_checkbox = false
	
	viewing_levels = false
	debug_panel = null
	
	_prepare_scroll_view(false)
	
	var sorted_carts = get_sorted_cartridges()
	var catalog_indices = get_catalog_cartridge_indices()
	
	# Split into favorites and others
	var fav_carts = []
	var other_carts = []
	for cart in sorted_carts:
		if cart.favorite:
			fav_carts.append(cart)
		else:
			other_carts.append(cart)
			
	if sort_favorites_first and fav_carts.size() > 0:
		# Add Favorites Section Title
		var fav_header = Label.new()
		fav_header.text = "* FAVORITES"
		fav_header.add_theme_font_size_override("font_size", 20)
		fav_header.add_theme_color_override("font_color", color_cyan)
		scroll_vbox.add_child(fav_header)
		
		var fav_grid = GridContainer.new()
		fav_grid.columns = 3
		fav_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_child(fav_grid)
		
		for idx in range(sorted_carts.size()):
			var cart = sorted_carts[idx]
			if cart.favorite:
				_create_game_card(cart, fav_grid, int(catalog_indices.get(cart.id, -1)))
			
		# Add Separator Line
		var sep = ColorRect.new()
		sep.custom_minimum_size = Vector2(0, 2)
		sep.color = Color(1, 1, 1, 0.1)
		scroll_vbox.add_child(sep)
		
		# Add Other Games Section Title
		var other_header = Label.new()
		other_header.text = "OTHER CARTRIDGES"
		other_header.add_theme_font_size_override("font_size", 20)
		other_header.add_theme_color_override("font_color", color_ink_dim)
		scroll_vbox.add_child(other_header)
		
		var other_grid = GridContainer.new()
		other_grid.columns = 3
		other_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_child(other_grid)
		
		for idx in range(sorted_carts.size()):
			var cart = sorted_carts[idx]
			if not cart.favorite:
				_create_game_card(cart, other_grid, int(catalog_indices.get(cart.id, -1)))
	else:
		# Just one grid with everything
		var all_grid = GridContainer.new()
		all_grid.columns = 3
		all_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_child(all_grid)
		
		for idx in range(sorted_carts.size()):
			var cart = sorted_carts[idx]
			_create_game_card(cart, all_grid, int(catalog_indices.get(cart.id, -1)))



func _create_game_card(cart: Dictionary, parent_grid: Container, display_index: int = -1):
	var cart_id = cart.id
	var game_name = cart.game_name
	var is_fav = cart.favorite

	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(280, 280)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_panel.add_theme_stylebox_override("panel", style_panel)
	parent_grid.add_child(card_panel)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 8)
	card_margin.add_theme_constant_override("margin_top", 8)
	card_margin.add_theme_constant_override("margin_right", 8)
	card_margin.add_theme_constant_override("margin_bottom", 8)
	card_panel.add_child(card_margin)

	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_margin.add_child(card)

	var top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.add_theme_constant_override("separation", 8)
	card.add_child(top_row)

	var index_lbl = Label.new()
	index_lbl.text = str(display_index) + "." if display_index > 0 else ""
	index_lbl.add_theme_font_size_override("font_size", 16)
	index_lbl.add_theme_color_override("font_color", color_cyan)
	top_row.add_child(index_lbl)

	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)

	var fav_btn = Button.new()
	fav_btn.text = "★" if is_fav else "☆"
	fav_btn.custom_minimum_size = Vector2(32, 32)
	fav_btn.add_theme_font_size_override("font_size", 16)
	if is_fav:
		fav_btn.add_theme_color_override("font_color", color_cyan)
	else:
		fav_btn.add_theme_color_override("font_color", color_ink_dim)
	style_grid_button(fav_btn)
	fav_btn.pressed.connect(func():
		toggle_favorite(cart_id)
		display_games()
	)
	top_row.add_child(fav_btn)

	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(240, 180)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Load dynamic/skin-specific cover art if available
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
		if img:
			tex_rect.texture = ImageTexture.create_from_image(img)
	card.add_child(tex_rect)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var skin_names = _get_skin_list(cart.manifest, game_name)
	var display_title = current_skin if current_skin != "" and current_skin != default_skin else game_name

	var prev_skin_btn = Button.new()
	prev_skin_btn.text = "<"
	prev_skin_btn.custom_minimum_size = Vector2(36, 36)
	prev_skin_btn.pressed.connect(func():
		_cycle_skin(cart_id, skin_names, -1)
	)
	row.add_child(prev_skin_btn)
	style_grid_button(prev_skin_btn)

	var title_btn = Button.new()
	title_btn.text = display_title
	title_btn.custom_minimum_size = Vector2(140, 36)
	title_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_btn.add_theme_font_size_override("font_size", 18)
	title_btn.pressed.connect(func():
		_launch_game(cart_id)
	)
	row.add_child(title_btn)
	style_grid_button(title_btn)

	var next_skin_btn = Button.new()
	next_skin_btn.text = ">"
	next_skin_btn.custom_minimum_size = Vector2(36, 36)
	next_skin_btn.pressed.connect(func():
		_cycle_skin(cart_id, skin_names, 1)
	)
	row.add_child(next_skin_btn)
	style_grid_button(next_skin_btn)

func _get_skin_list(manifest: Dictionary, game_name: String) -> Array:
	var skins = manifest.get("skins", [])
	if typeof(skins) == TYPE_ARRAY and skins.size() > 0:
		var list = []
		for skin in skins:
			list.append(str(skin))
		return list
	return ["Classic " + game_name, "Synthwave", "8-Bit Retro"]

func _get_default_skin_name(manifest: Dictionary, game_name: String) -> String:
	var skins = _get_skin_list(manifest, game_name)
	return str(skins[0]) if skins.size() > 0 else "Classic " + game_name

func _get_selected_skin_name(cart_id: String, game_name: String, manifest: Dictionary) -> String:
	var default_skin = _get_default_skin_name(manifest, game_name)
	var selected_skin_name = str(selected_skins.get(cart_id, ""))
	if selected_skin_name == "":
		return default_skin
	return selected_skin_name

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

func _refresh_card_views():
	if current_tab == "games":
		display_games()
	elif current_tab == "levels" and launch_dialog and launch_dialog.visible and selected_level_name != "":
		_on_level_selected(selected_level_name)
	elif viewing_levels and current_scene != "":
		_on_scene_selected(current_scene)

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

func display_scenes():
	set_active_nav($UI/Content/SideNav/ScenesBtn)
	current_tab = "scenes"
	if tab_header_bar:
		tab_header_bar.visible = false
	viewing_levels = false
	debug_panel = null
	
	_prepare_scroll_view(true)
	
	# Clear the grid
	for child in scenes_grid.get_children():
		child.queue_free()
		
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/scenes")
	var dir = DirAccess.open(base_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var scene_name = file_name
				var btn = Button.new()
				btn.text = scene_name
				btn.custom_minimum_size = Vector2(300, 200)
				btn.add_theme_font_size_override("font_size", 28)
				btn.pressed.connect(func(): _on_scene_selected(scene_name))
				scenes_grid.add_child(btn)
				style_grid_button(btn)
			file_name = dir.get_next()
	else:
		print("Failed to open scenes dir: ", base_dir)

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
	
	var display_name = level_name.replace("classic_", "").capitalize()
	if cart_id != "":
		var manifest_path = base_dir.path_join("content/cartridges").path_join(cart_id).path_join("manifest.yaml")
		if FileAccess.file_exists(manifest_path):
			var manifest = parse_simple_yaml(manifest_path)
			var manifest_game_name = manifest.get("game_name", "")
			if manifest_game_name != "":
				display_name = manifest_game_name
	return display_name

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

func _create_level_card(level_name: String, levels_dir: String, container: Control, display_index: int = -1):
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
	if display_index > 0:
		var number_row = HBoxContainer.new()
		number_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var number_lbl = Label.new()
		number_lbl.text = str(display_index)
		number_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		number_lbl.add_theme_font_size_override("font_size", 22)
		number_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		number_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number_row.add_child(number_lbl)
		var number_spacer = Control.new()
		number_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		number_row.add_child(number_spacer)
		vbox.add_child(number_row)
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
	title_lbl.text = classic_name if is_classic_skin else active_skin_name
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(title_lbl)
	
	if not is_classic_skin:
		var sub_lbl = Label.new()
		sub_lbl.text = "(" + classic_name + ")"
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_lbl.add_theme_font_size_override("font_size", 14)
		sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_container.add_child(sub_lbl)

	var bottom_text_spacer = Control.new()
	bottom_text_spacer.custom_minimum_size = Vector2(0, 4)
	bottom_text_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(bottom_text_spacer)
	
	style_grid_button(btn)

func _on_scene_selected(scene_name: String):
	print("Selected scene: ", scene_name)
	set_active_nav($UI/Content/SideNav/LevelsBtn)
	current_tab = "levels"
	if tab_header_bar:
		tab_header_bar.visible = false
	current_scene = scene_name
	viewing_levels = true
	debug_panel = null
	
	# Scan all levels first
	var all_levels = []
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../")
	var levels_dir = base_dir.path_join("content/scenes").path_join(scene_name).path_join("levels")
	var dir = DirAccess.open(levels_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with(".") and file_name != "derived":
				all_levels.append(file_name)
			file_name = dir.get_next()
	else:
		print("Failed to open levels dir: ", levels_dir)
		return
		
	# Sort levels alphabetically by classic name (stripping 'classic ' prefix)
	all_levels.sort_custom(func(a, b):
		var name_a = get_level_classic_name(a).to_lower()
		var name_b = get_level_classic_name(b).to_lower()
		if name_a.begins_with("classic "):
			name_a = name_a.trim_prefix("classic ")
		if name_b.begins_with("classic "):
			name_b = name_b.trim_prefix("classic ")
		return name_a < name_b
	)
	var level_numbers = {}
	for idx in range(all_levels.size()):
		level_numbers[all_levels[idx]] = idx + 1
	
	var fav_levels = []
	var other_levels = []
	
	if scene_name == "scene_classic_pack":
		for lvl in all_levels:
			if is_level_favorited(lvl):
				fav_levels.append(lvl)
			else:
				other_levels.append(lvl)
	else:
		other_levels = all_levels
		
	if sort_favorites_first and fav_levels.size() > 0:
		_prepare_scroll_view(false)
		
		# Add back button
		var back_btn = Button.new()
		back_btn.text = "< Back to Scenes"
		back_btn.custom_minimum_size = Vector2(300, 80)
		back_btn.add_theme_font_size_override("font_size", 24)
		back_btn.pressed.connect(display_scenes)
		scroll_vbox.add_child(back_btn)
		scroll_vbox.move_child(back_btn, 0)

















































			_create_level_card(lvl, levels_dir, other_grid, int(level_numbers.get(lvl, -1)))
	else:
		_prepare_scroll_view(true)
		
		# Add back button above the grid so the first level can stay in slot one
		var back_btn = Button.new()
		back_btn.text = "< Back to Scenes"
		back_btn.custom_minimum_size = Vector2(300, 80)
		back_btn.add_theme_font_size_override("font_size", 24)
		back_btn.pressed.connect(display_scenes)
		scroll_vbox.add_child(back_btn)
		scroll_vbox.move_child(back_btn, 0)
		style_grid_button(back_btn)
		
		# Add all levels
		for child in scenes_grid.get_children():
			child.queue_free()
		for lvl in all_levels:
			_create_level_card(lvl, levels_dir, scenes_grid, int(level_numbers.get(lvl, -1)))

func _on_levels_nav_pressed():
	if current_scene != "":
		_on_scene_selected(current_scene)
	else:
		_show_placeholder("LEVELS DIRECTORY\nPlease select a physical Scene first to scan its semantic levels.")

func _on_level_selected(level_name: String):
	print("Selected level: ", level_name)
	selected_level_name = level_name
	
	level_title_label.text = "PLAY ON: " + level_name.to_upper()
	
	# Read level info for orientation if possible
	var orientation_str = "WALL"
	var base_dir = _get_repo_root()
	var level_dir = base_dir.path_join("content/scenes").path_join(current_scene).path_join("levels").path_join(level_name)
	var level_yaml_path = level_dir.path_join("level.yaml")
	if FileAccess.file_exists(level_yaml_path):
		var level_info = parse_simple_yaml(level_yaml_path)
		orientation_str = level_info.get("orientation", "wall").to_upper()
	picker_desc_label.text = "SELECT A CARTRIDGE - COMPATIBLE WITH THIS " + orientation_str + " ARENA"
	
	if dialog_sort_fav_checkbox:
		_updating_dialog_checkbox = true
		dialog_sort_fav_checkbox.button_pressed = sort_favorites_first
		_updating_dialog_checkbox = false
	
	# Clear previous contents of dialog_scroll_vbox
	for child in dialog_scroll_vbox.get_children():
		child.queue_free()
		



























































































































































































































	style_grid_button(next_skin_btn)
func _launch_game(cart_id: String):
	last_known_level = selected_level_name
	last_known_cartridge = cart_id
	
	var base_dir = _get_repo_root()
	var scene_dir = base_dir.path_join("content/scenes").path_join(current_scene)
	var level_dir = scene_dir.path_join("levels").path_join(selected_level_name)
	var cart_dir = base_dir.path_join("content/cartridges").path_join(cart_id)
	
	# Read cartridge manifest for compatibility validation
	var manifest_path = cart_dir.path_join("manifest.yaml")
	var manifest = parse_simple_yaml(manifest_path)
	
	# Read level.yaml if it exists
	var level_yaml_path = level_dir.path_join("level.yaml")
	var level_info = parse_simple_yaml(level_yaml_path)
	
	# Prepare compatibility info
	var reqs = manifest.get("requires", {"orientation": ["wall"], "semantic_classes": []})
	var prov = {









		if typeof(skins) == TYPE_ARRAY and skins.size() > 0:
			skin_name = str(skins[0])
	if skin_name != "":
		args_template += " --skin \"" + skin_name + "\""
	
	log_debug("Launching game: " + cart_id + " on level " + selected_level_name)
	last_launch_time = Time.get_ticks_msec() / 1000.0
	launcher.launch(launch_cmd, args_template, scene_dir, level_dir)

func _on_panic_pressed():
	is_panic = not is_panic
	panic_overlay.visible = is_panic
	if is_panic:
		launcher.send_message("blank")
		launcher.kill_cartridge()
		
func _on_restore_pressed():
	if last_known_cartridge != "":
		_launch_game(last_known_cartridge)
		
func _on_design_nav_pressed():
	print("Design screen selected")
	set_active_nav($UI/Content/SideNav/DesignBtn)
	clear_main_panel()
	var design_inst = design_screen_scene.instantiate()
	design_inst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	design_inst.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(design_inst)

func _on_test_pattern_pressed():
	_show_placeholder("DISPLAY TEST PATTERN\nDisplay alignment grid placeholder.")

func _on_cartridge_exited(clean: bool):
	print("Cartridge exited clean: ", clean)
	if not clean and not is_panic:
		var running_duration = (Time.get_ticks_msec() / 1000.0) - last_launch_time
		if running_duration < 2.0:
			log_debug("Cartridge crashed immediately on startup (run time: %.2fs). Auto-restore disabled to prevent infinite loops." % running_duration)
		else:
			log_debug("Crash/timeout detected after %.2fs, restoring last known good..." % running_duration)
			_on_restore_pressed()
	log_debug("Launching game: " + cart_id + " on level " + selected_level_name)
	last_launch_time = Time.get_ticks_msec() / 1000.0
	launcher.launch(launch_cmd, args_template, scene_dir, level_dir)

func _on_panic_pressed():
	is_panic = not is_panic
	panic_overlay.visible = is_panic
	if is_panic:
		launcher.send_message("blank")
		launcher.kill_cartridge()
		
func _on_restore_pressed():
	if last_known_cartridge != "":
		_launch_game(last_known_cartridge)
		
func clear_main_panel():
	if content_vbox:
		content_vbox.visible = false
	if main_panel:
		for child in main_panel.get_children():
			if child != content_vbox:
				child.queue_free()

func _on_design_nav_pressed():
	print("Design screen selected")
	set_active_nav($UI/Content/SideNav/DesignBtn)
	clear_main_panel()
	var design_inst = design_screen_scene.instantiate()
	design_inst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	design_inst.size_flags_vertical = Control.SIZE_EXPAND_FILL














































































































































































































































	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)
	

	
	var cal_btn = Button.new()
	cal_btn.text = "Launch 4-Point Calibration"
	cal_btn.custom_minimum_size = Vector2(300, 120)
	cal_btn.add_theme_font_size_override("font_size", 24)
	cal_btn.pressed.connect(_on_launch_calibration_tool)
	hbox.add_child(cal_btn)
	style_grid_button(cal_btn)

	var devices_btn = Button.new()
	devices_btn.text = "Device Settings"
	devices_btn.custom_minimum_size = Vector2(300, 120)
	devices_btn.add_theme_font_size_override("font_size", 24)
	devices_btn.pressed.connect(display_devices_panel)
	hbox.add_child(devices_btn)
	style_grid_button(devices_btn)


func _on_launch_calibration_tool():
	if current_scene == "":
		_show_placeholder("CALIBRATION\nPlease select a physical Scene first from the Scenes tab before calibrating.")
		return
		
	var python_exe = "python"
	var base_dir = _get_repo_root()
	var script_path = base_dir.path_join("app/tools/calibration/calibrate.py")





























	vbox.add_child(title)
	
	for i in range(4):
		var slot_data = InputManager.slots[i]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		vbox.add_child(hbox)
		
		var slot_lbl = Label.new()
		slot_lbl.text = "Player " + str(i + 1) + ":"
		slot_lbl.custom_minimum_size = Vector2(150, 0)
		slot_lbl.add_theme_font_size_override("font_size", 24)
		slot_lbl.add_theme_color_override("font_color", color_ink_dim)
		hbox.add_child(slot_lbl)
		
		var dev_lbl = Label.new()
		var type_str = slot_data["type"].to_upper()
		if type_str == "NONE":
			dev_lbl.text = "NOT ASSIGNED"
			dev_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			var dev_name = "Keyboard" if type_str == "KEYBOARD" else Input.get_joy_name(slot_data["device_id"])
			dev_lbl.text = type_str + " (" + dev_name + ")"
			dev_lbl.add_theme_color_override("font_color", color_cyan)
		dev_lbl.add_theme_font_size_override("font_size", 24)
		hbox.add_child(dev_lbl)
		
		var reassign_btn = Button.new()
		reassign_btn.text = " Reassign "
		reassign_btn.add_theme_font_size_override("font_size", 20)
		style_grid_button(reassign_btn)
		hbox.add_child(reassign_btn)

func _run_auto_screenshot_flow(mode: String, path: String):
	# Wait for layout to settle
	await get_tree().create_timer(1.0).timeout
	
	if mode == "games":
		display_games()
		await get_tree().create_timer(1.0).timeout

			dev_lbl.text = type_str + " (" + dev_name + ")"
			dev_lbl.add_theme_color_override("font_color", color_cyan)
		dev_lbl.add_theme_font_size_override("font_size", 24)
		hbox.add_child(dev_lbl)
		
		var reassign_btn = Button.new()
		reassign_btn.text = " Reassign "
		reassign_btn.add_theme_font_size_override("font_size", 20)
		style_grid_button(reassign_btn)
		hbox.add_child(reassign_btn)

func _run_auto_screenshot_flow(mode: String, path: String):
	# Wait for layout to settle
	await get_tree().create_timer(1.0).timeout
	
	if mode == "games":
		await get_tree().create_timer(1.0).timeout

	elif mode == "nav":
		await get_tree().create_timer(2.0).timeout
		
	elif mode == "picker":
		# Select first scene
		_on_scene_selected("scene_demo_wall")
		await get_tree().create_timer(0.5).timeout
		# Select first level
		_on_level_selected("demo_level")
		await get_tree().create_timer(1.0).timeout
		
	elif mode == "panic":
		# Trigger panic black
		_on_panic_pressed()
		await get_tree().create_timer(0.5).timeout
		
	elif mode == "service" or mode == "log":
		# Navigate to Log tab
		display_service_panel()
		await get_tree().create_timer(2.0).timeout
		
	elif mode == "restore":
		# Populate log with simulated crash & restore logs
		log_debug("Launching game: pacman on level demo_level")
		log_debug("Cartridge connected to socket")
		log_debug("Received: {\"type\":\"heartbeat\"}")
		log_debug("Process exited externally (abnormal exit)")
		log_debug("Crash/timeout detected after 5.42s, restoring last known good...")
		log_debug("Launching game: pacman on level demo_level")
		display_service_panel()
		await get_tree().create_timer(0.5).timeout

	# Capture and save
	var img = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("Auto screenshot (", mode, ") saved to: ", path)
	get_tree().quit()



func style_grid_button(btn: Button):
	btn.add_theme_stylebox_override("normal", style_btn_normal)
	btn.add_theme_stylebox_override("hover", style_btn_hover)
	btn.add_theme_stylebox_override("pressed", style_btn_pressed)
	btn.add_theme_color_override("font_color", color_ink_dim)
	btn.add_theme_color_override("font_hover_color", color_ink_white)
	btn.add_theme_color_override("font_pressed_color", color_black)
