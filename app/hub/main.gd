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

var debug_logs: Array[String] = []
var debug_panel: VBoxContainer = null
var log_refresh_timer: float = 0.0
@onready var main_panel = $UI/Content/MainPanel
var splash_overlay: ColorRect
var design_screen_scene = preload("res://design_screen.tscn")
var content_vbox: VBoxContainer
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
		display_games()
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
