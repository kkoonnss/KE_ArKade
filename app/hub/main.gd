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
var active_nav_btn: Button = null
var dialog_scroll_vbox: VBoxContainer

func _ready():
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
	
	display_scenes()

func clear_main_panel():
	for child in scenes_grid.get_children():
		child.queue_free()

func set_active_nav(active_btn: Button):
	active_nav_btn = active_btn

func display_scenes():
	clear_main_panel()
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/scenes")
	var dir = DirAccess.open(base_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var btn = Button.new()
				btn.text = file_name.capitalize()
				style_grid_button(btn)
				btn.pressed.connect(func(): _on_scene_selected(file_name))
				scenes_grid.add_child(btn)
			file_name = dir.get_next()


func style_grid_button(btn: Button):
	btn.custom_minimum_size = Vector2(240, 160)
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
	display_levels()

func display_levels():
	clear_main_panel()
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/scenes").path_join(current_scene).path_join("levels")
	var dir = DirAccess.open(base_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var btn = Button.new()
				btn.text = file_name.capitalize()
				style_grid_button(btn)
				btn.pressed.connect(func(): _on_level_selected(file_name))
				scenes_grid.add_child(btn)
			file_name = dir.get_next()

func _on_level_selected(level_name: String):
	selected_level_name = level_name
	display_games()

func display_games():
	clear_main_panel()
	var base_dir = ProjectSettings.globalize_path("res://").path_join("../../content/cartridges")
	var dir = DirAccess.open(base_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				var btn = Button.new()
				btn.text = file_name.capitalize()
				style_grid_button(btn)
				btn.pressed.connect(func(): _launch_game(file_name))
				scenes_grid.add_child(btn)
			file_name = dir.get_next()

func _launch_game(cart_id: String):
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
	pass

func _on_launch_calibration_tool():
	pass

func _on_test_pattern_pressed():
	pass

func parse_simple_yaml(path: String) -> Dictionary:
	return {}

func _get_repo_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../..")
