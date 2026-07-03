extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()

const LevelAdjustments = preload("res://level_adjustments.gd")

var splash_rect: TextureRect
var menu_overlay: ColorRect
var overlay_margin: MarginContainer
var menu_shell: BoxContainer
var splash_frame: PanelContainer
var menu_panel: PanelContainer
var menu_title_label: Label
var menu_subtitle_label: Label
var menu_hint_label: Label
var menu_labels = []
var menu_items = []
var overlay_mode: String = "start"
var selected_menu_index: int = 0
var selected_players: int = 1

var ipc_socket: StreamPeerTCP = null
var scene_dir: String = ""
var level_dir: String = ""
var ipc_port: int = 0
var ipc_host: String = "127.0.0.1"
var screenshot_path: String = ""

var heartbeat_timer: float = 0.0
var read_buffer: String = ""

# Map
var grid_cells = [] # 2D array: 0=empty, 1=indestructible, 2=destructible
var cell_px = 32.0
var grid_w = 0
var grid_h = 0
var map_w = 0.0
var map_h = 0.0

var scale_factor: float = 1.0
var offset_x: float = 0.0
var offset_y: float = 0.0

var players = []
var bombs = []
var explosions = []
var active_particles = []

var game_state = "menu"

var current_skin: String = "classic"
var background_texture: Texture2D = null
var background_opacity: float = 0.15
var show_background: bool = false
var destructible_fill_pct: float = 0.5
var blur_radius: int = 0
var wall_threshold: float = 0.05
var ui_layer: CanvasLayer
var ui_control: Control

var player_colors = [
    Color(0.0, 0.9, 1.0), # Cyan
    Color(1.0, 0.0, 0.8), # Magenta
    Color(0.0, 1.0, 0.0), # Green
    Color(1.0, 0.8, 0.0)  # Yellow
]

var player_speed_scale: float = 2.8125

func _find_nearest_walkable_cell(start_x: int, start_y: int) -> Vector2i:
    if grid_w <= 0 or grid_h <= 0 or grid_cells.size() == 0:
        return Vector2i(start_x, start_y)
    
    var sx = clampi(start_x, 0, grid_w - 1)
    var sy = clampi(start_y, 0, grid_h - 1)
    
    if grid_cells[sy][sx] == 0:
        return Vector2i(sx, sy)
        
    var queue = [Vector2i(sx, sy)]
    var visited = []
    visited.resize(grid_h)
    for y in range(grid_h):
        visited[y] = []
        visited[y].resize(grid_w)
        visited[y].fill(false)
        
    visited[sy][sx] = true
    
    var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    
    while queue.size() > 0:
        var curr = queue.pop_front()
        if grid_cells[curr.y][curr.x] == 0:
            return curr
            
        for dir in directions:
            var next = curr + dir
            if next.x >= 0 and next.x < grid_w and next.y >= 0 and next.y < grid_h:
                if not visited[next.y][next.x]:
                    visited[next.y][next.x] = true
                    queue.append(next)
                    
    return Vector2i(sx, sy)

func _ready():
    RenderingServer.set_default_clear_color(Color.BLACK)
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    var i = 0
    while i < args.size():
        if args[i] == "--scene" and i + 1 < args.size():
            scene_dir = args[i+1]
            i += 1
        elif args[i] == "--level" and i + 1 < args.size():
            level_dir = args[i+1]
            i += 1
        elif args[i] == "--skin" and i + 1 < args.size():
            var skin_arg = args[i+1]
            if skin_arg == "Classic Bomber Man":
                current_skin = "classic"
            elif skin_arg == "Boomer Man":
                current_skin = "boomer"
            else:
                current_skin = "neon"
            i += 1
        elif args[i] == "--ipc" and i + 1 < args.size():
            var ipc_str = args[i+1]
            if ":" in ipc_str:
                var parts = ipc_str.split(":")
                ipc_host = parts[0]
                ipc_port = parts[1].to_int()
            else:
                ipc_port = ipc_str.to_int()
            i += 1
        elif args[i] == "--screenshot" and i + 1 < args.size():
            screenshot_path = args[i+1]
            i += 1
        i += 1

    if ipc_port > 0:
        ipc_socket = StreamPeerTCP.new()
        ipc_socket.connect_to_host(ipc_host, ipc_port)
    
    _setup_ui()
    send_ipc_message({"type": "ready"})
    load_level()
    load_background()
    _set_overlay_mode("start")
    if screenshot_path != "":
        await get_tree().create_timer(2.35).timeout
        get_viewport().get_texture().get_image().save_png(screenshot_path)
        get_tree().quit()

func _setup_ui():
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)

    menu_overlay = ColorRect.new()
    menu_overlay.color = Color(0, 0, 0, 0.82)
    menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_layer.add_child(menu_overlay)

    overlay_margin = MarginContainer.new()
    overlay_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_margin.add_theme_constant_override("margin_left", 42)
    overlay_margin.add_theme_constant_override("margin_top", 42)
    overlay_margin.add_theme_constant_override("margin_right", 42)
    overlay_margin.add_theme_constant_override("margin_bottom", 42)
    menu_overlay.add_child(overlay_margin)

    menu_shell = HBoxContainer.new()
    menu_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_shell.alignment = BoxContainer.ALIGNMENT_CENTER
    menu_shell.add_theme_constant_override("separation", 28)
    overlay_margin.add_child(menu_shell)

    splash_frame = PanelContainer.new()
    splash_frame.custom_minimum_size = Vector2(540, 760)
    splash_frame.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.95, 0.78, 0.24), Color(0.03, 0.03, 0.06, 0.96)))
    menu_shell.add_child(splash_frame)

    splash_rect = TextureRect.new()
    splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path):
        var img = Image.load_from_file(splash_path)
        if img:
            splash_rect.texture = ImageTexture.create_from_image(img)
    splash_frame.add_child(splash_rect)

    menu_panel = PanelContainer.new()
    menu_panel.custom_minimum_size = Vector2(520, 560)
    menu_panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.16, 0.55, 1.0), Color(0.01, 0.01, 0.01, 0.92)))
    menu_shell.add_child(menu_panel)

    var menu_margin = MarginContainer.new()
    menu_margin.add_theme_constant_override("margin_left", 28)
    menu_margin.add_theme_constant_override("margin_top", 24)
    menu_margin.add_theme_constant_override("margin_right", 28)
    menu_margin.add_theme_constant_override("margin_bottom", 24)
    menu_panel.add_child(menu_margin)

    ui_control = Control.new()
    ui_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_margin.add_child(ui_control)

    var vbox = VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 10)
    ui_control.add_child(vbox)

    menu_title_label = Label.new()
    menu_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    menu_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.24))
    menu_title_label.add_theme_font_size_override("font_size", 42)
    vbox.add_child(menu_title_label)

    menu_subtitle_label = Label.new()
    menu_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    menu_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
    menu_subtitle_label.add_theme_font_size_override("font_size", 20)
    vbox.add_child(menu_subtitle_label)

    var divider = ColorRect.new()
    divider.color = Color(1.0, 0.84, 0.2, 0.55)
    divider.custom_minimum_size = Vector2(0, 2)
    vbox.add_child(divider)

    for i in range(6):
        var menu_label = Label.new()
        menu_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        menu_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        menu_label.add_theme_color_override("font_color", Color.WHITE)
        menu_label.add_theme_font_size_override("font_size", 28 if i == 0 else 24)
        vbox.add_child(menu_label)
        menu_labels.append(menu_label)

    var settings_title = Label.new()
    settings_title.name = "SettingsTitle"
    settings_title.text = "Secondary Map Settings"
    settings_title.visible = false
    settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    settings_title.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
    settings_title.add_theme_font_size_override("font_size", 22)
    vbox.add_child(settings_title)

    var label = Label.new()
    label.name = "FillLabel"
    label.text = "Destructible Fill %: " + str(int(destructible_fill_pct * 100)) + "%"
    label.visible = false
    vbox.add_child(label)

    var slider = HSlider.new()
    slider.name = "FillSlider"
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 0.05
    slider.value = destructible_fill_pct
    slider.custom_minimum_size = Vector2(200, 30)
    slider.visible = false
    slider.value_changed.connect(_on_fill_pct_changed.bind(label))
    vbox.add_child(slider)

    var cs_label = Label.new()
    cs_label.name = "CellSizeLabel"
    cs_label.text = "Cell Size: " + str(int(cell_px))
    cs_label.visible = false
    vbox.add_child(cs_label)

    var cs_slider = HSlider.new()
    cs_slider.name = "CellSizeSlider"
    cs_slider.min_value = 16.0
    cs_slider.max_value = 128.0
    cs_slider.step = 16.0
    cs_slider.value = cell_px
    cs_slider.custom_minimum_size = Vector2(200, 30)
    cs_slider.visible = false
    cs_slider.value_changed.connect(_on_cell_size_changed.bind(cs_label))
    vbox.add_child(cs_slider)

    var speed_label = Label.new()
    speed_label.name = "SpeedLabel"
    speed_label.text = "Player Speed Scale: " + str(player_speed_scale)
    speed_label.visible = false
    vbox.add_child(speed_label)

    var speed_slider = HSlider.new()
    speed_slider.name = "SpeedSlider"
    speed_slider.min_value = 1.0
    speed_slider.max_value = 6.0
    speed_slider.step = 0.1
    speed_slider.value = player_speed_scale
    speed_slider.custom_minimum_size = Vector2(200, 30)
    speed_slider.visible = false
    speed_slider.value_changed.connect(_on_speed_changed.bind(speed_label))
    vbox.add_child(speed_slider)

    var blur_label = Label.new()
    blur_label.name = "BlurLabel"
    blur_label.text = "Blur Radius: " + str(blur_radius)
    blur_label.visible = false
    vbox.add_child(blur_label)

    var blur_slider = HSlider.new()
    blur_slider.name = "BlurSlider"
    blur_slider.min_value = 0.0
    blur_slider.max_value = 5.0
    blur_slider.step = 1.0
    blur_slider.value = blur_radius
    blur_slider.custom_minimum_size = Vector2(200, 30)
    blur_slider.visible = false
    blur_slider.value_changed.connect(_on_blur_changed.bind(blur_label))
    vbox.add_child(blur_slider)

    var thresh_label = Label.new()
    thresh_label.name = "ThreshLabel"
    thresh_label.text = "Wall Threshold: " + str(int(wall_threshold * 100)) + "%"
    thresh_label.visible = false
    vbox.add_child(thresh_label)

    var thresh_slider = HSlider.new()
    thresh_slider.name = "ThreshSlider"
    thresh_slider.min_value = 0.01
    thresh_slider.max_value = 0.5
    thresh_slider.step = 0.01
    thresh_slider.value = wall_threshold
    thresh_slider.custom_minimum_size = Vector2(200, 30)
    thresh_slider.visible = false
    thresh_slider.value_changed.connect(_on_thresh_changed.bind(thresh_label))
    vbox.add_child(thresh_slider)

    var spacer = Control.new()
    spacer.name = "SettingsSpacer"
    spacer.custom_minimum_size = Vector2(0, 10)
    spacer.visible = false
    vbox.add_child(spacer)

    var restart_btn = Button.new()
    restart_btn.name = "RestartButton"
    restart_btn.text = "Restart Game"
    restart_btn.custom_minimum_size = Vector2(200, 40)
    restart_btn.visible = false
    restart_btn.pressed.connect(_on_restart_pressed)
    vbox.add_child(restart_btn)

    menu_hint_label = Label.new()
    menu_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    menu_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_hint_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
    menu_hint_label.add_theme_font_size_override("font_size", 18)
    vbox.add_child(menu_hint_label)

func _menu_panel_style(border_color: Color, fill_color: Color) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = fill_color
    style.border_color = border_color
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_left = 18
    style.corner_radius_bottom_right = 18
    style.shadow_color = Color(0, 0, 0, 0.35)
    style.shadow_size = 16
    return style

func _set_settings_controls_visible(visible: bool):
    for node_name in ["SettingsTitle", "FillLabel", "FillSlider", "CellSizeLabel", "CellSizeSlider", "SpeedLabel", "SpeedSlider", "BlurLabel", "BlurSlider", "ThreshLabel", "ThreshSlider", "SettingsSpacer", "RestartButton"]:
        var node = ui_control.find_child(node_name, true, false)
        if node:
            node.visible = visible

func _set_overlay_mode(mode: String):
    overlay_mode = mode
    if not menu_overlay:
        return
    if mode == "":
        menu_overlay.visible = false
        return
    menu_overlay.visible = true
    splash_frame.visible = mode == "start" or mode == "help"
    _set_settings_controls_visible(mode == "settings")
    if mode == "start":
        menu_title_label.text = "BOMBERMAN"
        menu_subtitle_label.text = "Start here, pick players, then drop into the arena."
        menu_items = [
            "Start Game",
            "Help",
            "Settings",
            "Players: %d" % selected_players
        ]
        selected_menu_index = clampi(selected_menu_index, 0, menu_items.size() - 1)
        menu_hint_label.text = "Up/Down selects. Left/Right adjusts players. Enter starts. Tab opens settings. Esc returns here."
    elif mode == "help":
        menu_title_label.text = "How To Play"
        menu_subtitle_label.text = "Bomb walls, avoid blast lines, and be the last player standing."
        menu_items = [
            "Move with arrows/WASD or controller.",
            "Drop bombs with Space/Enter or controller face button.",
            "Use the map settings to tune density, speed, and cell sizing per level.",
            "Press Esc to return to the start screen."
        ]
        selected_menu_index = 0
        menu_hint_label.text = "Enter or Esc returns to the start screen."
    else:
        menu_title_label.text = "Bomberman Settings"
        menu_subtitle_label.text = "Secondary map tuning for this level."
        menu_items = [
            "Adjust density, cell size, speed, blur, and wall threshold below.",
            "Restart Game reloads the level with the updated tuning."
        ]
        selected_menu_index = 0
        menu_hint_label.text = "Tab or Esc returns to the start screen. Sliders still work with mouse for now."

    for i in range(menu_labels.size()):
        if i < menu_items.size():
            menu_labels[i].visible = true
            var prefix = ""
            if mode == "start" and i == selected_menu_index:
                prefix = "> "
            menu_labels[i].text = prefix + menu_items[i]
            var is_selected = mode == "start" and i == selected_menu_index
            menu_labels[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.24) if is_selected else Color.WHITE)
        else:
            menu_labels[i].visible = false

func _activate_menu_item():
    if overlay_mode != "start":
        return
    match selected_menu_index:
        0:
            game_state = "playing"
            _set_overlay_mode("")
        1:
            _set_overlay_mode("help")
        2:
            _set_overlay_mode("settings")

func _handle_overlay_input(event) -> bool:
    if overlay_mode == "":
        return false
	if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
		if "game_state" in self and game_state != "playing":
			if has_method("_reset_game"): _reset_game()
			elif has_method("reset_game"): reset_game()
		elif "state" in self and state != "playing":
			if has_method("_reset_game"): _reset_game()
			elif has_method("reset_game"): reset_game()

	if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            if overlay_mode == "start":
                return true
            _set_overlay_mode("start")
            return true
        if event.keycode == KEY_TAB:
            _set_overlay_mode("settings" if overlay_mode != "settings" else "start")
            return true
        if overlay_mode == "start":
            if event.keycode == KEY_UP:
                selected_menu_index = wrapi(selected_menu_index - 1, 0, menu_items.size())
                _set_overlay_mode("start")
                return true
            if event.keycode == KEY_DOWN:
                selected_menu_index = wrapi(selected_menu_index + 1, 0, menu_items.size())
                _set_overlay_mode("start")
                return true
            if event.keycode == KEY_LEFT and selected_menu_index == 3:
                selected_players = max(1, selected_players - 1)
                _set_overlay_mode("start")
                return true
            if event.keycode == KEY_RIGHT and selected_menu_index == 3:
                selected_players = min(4, selected_players + 1)
                _set_overlay_mode("start")
                return true
            if event.keycode == KEY_ENTER:
                _activate_menu_item()
                return true
        elif overlay_mode == "help":
            if event.keycode == KEY_ENTER:
                _set_overlay_mode("start")
                return true
    if event is InputEventJoypadButton and event.pressed:
        if event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_A:
            if overlay_mode == "start":
                _activate_menu_item()
            else:
                _set_overlay_mode("start")
            return true
    return false

func _on_restart_pressed():
    game_state = "playing"
    load_level()
    _set_overlay_mode("")

func _on_speed_changed(value: float, label: Label):
    player_speed_scale = value
    label.text = "Player Speed Scale: " + str(value)
    _save_settings()
    for p in players:
        p.speed = cell_px * player_speed_scale

func _on_fill_pct_changed(value: float, label: Label):
    destructible_fill_pct = value
    label.text = "Destructible Fill %: " + str(int(value * 100)) + "%"
    _save_settings()
    if game_state == "playing":
        load_level()


func _on_blur_changed(value: float, label: Label):
    blur_radius = int(value)
    label.text = "Blur Radius: " + str(blur_radius)
    _save_settings()
    if game_state == "playing": load_level()

func _on_thresh_changed(value: float, label: Label):
    wall_threshold = value
    label.text = "Wall Threshold: " + str(int(value*100)) + "%"
    _save_settings()
    if game_state == "playing": load_level()


func _on_cell_size_changed(value: float, label: Label):
    cell_px = value
    label.text = "Cell Size: " + str(int(value))
    _save_settings()
    if game_state == "playing":
        load_level()

func _save_settings():
    if level_dir == "": return
    var data = {
        "destructible_fill_pct": destructible_fill_pct,
        "cell_px": cell_px,
        "blur_radius": blur_radius,
        "wall_threshold": wall_threshold,
        "player_speed_scale": player_speed_scale
    }
    LevelAdjustments.save_level_settings("bomberman", level_dir, data, scene_dir)

func _load_settings():
    if level_dir == "": return
    var data = LevelAdjustments.load_level_settings("bomberman", level_dir, {
        "destructible_fill_pct": destructible_fill_pct,
        "cell_px": cell_px,
        "blur_radius": blur_radius,
        "wall_threshold": wall_threshold,
        "player_speed_scale": player_speed_scale
    }, scene_dir)
    if data.has("destructible_fill_pct"):
        destructible_fill_pct = float(data.get("destructible_fill_pct"))
        _sync_slider("FillSlider", destructible_fill_pct, "Destructible Fill %: " + str(int(destructible_fill_pct * 100)) + "%")
    if data.has("cell_px"):
        cell_px = float(data.get("cell_px"))
        _sync_slider("CellSizeSlider", cell_px, "Cell Size: " + str(int(cell_px)))
    if data.has("player_speed_scale"):
        player_speed_scale = float(data.get("player_speed_scale"))
        _sync_slider("SpeedSlider", player_speed_scale, "Player Speed Scale: " + str(player_speed_scale))
    if data.has("blur_radius"):
        blur_radius = int(data.get("blur_radius"))
        _sync_slider("BlurSlider", blur_radius, "Blur Radius: " + str(blur_radius))
    if data.has("wall_threshold"):
        wall_threshold = float(data.get("wall_threshold"))
        _sync_slider("ThreshSlider", wall_threshold, "Wall Threshold: " + str(int(wall_threshold * 100)) + "%")

func _sync_slider(slider_name: String, value: float, label_text: String):
    if not ui_control:
        return
    var slider = ui_control.find_child(slider_name, true, false)
    if slider and slider is Slider:
        slider.set_block_signals(true)
        slider.value = value
        slider.set_block_signals(false)
        var label = slider.get_parent().get_child(slider.get_index() - 1)
        if label and label is Label:
            label.text = label_text

func parse_simple_yaml(path: String) -> Dictionary:
    var data = {}
    var file = FileAccess.open(path, FileAccess.READ)
    if not file: return data
    while not file.eof_reached():
        var line = file.get_line().strip_edges()
        if line.begins_with("#") or line == "": continue
        if ":" in line:
            var parts = line.split(":", true, 1)
            var key = parts[0].strip_edges()
            var val = parts[1].strip_edges()
            if (val.begins_with("\"") and val.ends_with("\"")) or (val.begins_with("'") and val.ends_with("'")):
                val = val.substr(1, val.length() - 2)
            data[key] = val
    return data

func load_background():
    if level_dir == "": return
    var yaml_path = level_dir.path_join("level.yaml")
    if FileAccess.file_exists(yaml_path):
        var data = parse_simple_yaml(yaml_path)
        var bg_file = data.get("reference_image", "")
        if bg_file != "":
            var bg_path = level_dir.path_join(bg_file)
            if FileAccess.file_exists(bg_path):
                var img = Image.load_from_file(bg_path)
                if img: background_texture = ImageTexture.create_from_image(img)

func load_level():
    if level_dir == "": return
    
    _load_settings()
    
    var occ_path = level_dir + "/derived/occupancy.png"
    var occ_img: Image = null
    if FileAccess.file_exists(occ_path):
        occ_img = Image.load_from_file(occ_path)
        
    if occ_img:
        grid_w = int(occ_img.get_width() / cell_px)
        grid_h = int(occ_img.get_height() / cell_px)
    else:
        grid_w = 20
        grid_h = 15

    var density_grid = []
    density_grid.resize(grid_h)
    for y in range(grid_h):
        density_grid[y] = []
        density_grid[y].resize(grid_w)
        for x in range(grid_w):
            density_grid[y][x] = 0.0
            if occ_img:
                var wall_pixels = 0
                var total_pixels = 0
                var start_px = int(x * cell_px)
                var start_py = int(y * cell_px)
                var end_px = min(start_px + int(cell_px), occ_img.get_width())
                var end_py = min(start_py + int(cell_px), occ_img.get_height())
                
                for py in range(start_py, end_py):
                    for px in range(start_px, end_px):
                        total_pixels += 1
                        if occ_img.get_pixel(px, py).r > 0.5:
                            wall_pixels += 1
                            
                if total_pixels > 0:
                    density_grid[y][x] = float(wall_pixels) / float(total_pixels)
                    
    if blur_radius > 0:
        var blurred_grid = []
        blurred_grid.resize(grid_h)
        for y in range(grid_h):
            blurred_grid[y] = []
            blurred_grid[y].resize(grid_w)
            for x in range(grid_w):
                var sum_d = 0.0
                var count = 0
                for dy in range(-blur_radius, blur_radius + 1):
                    for dx in range(-blur_radius, blur_radius + 1):
                        var ny = y + dy
                        var nx = x + dx
                        if ny >= 0 and ny < grid_h and nx >= 0 and nx < grid_w:
                            sum_d += density_grid[ny][nx]
                            count += 1
                blurred_grid[y][x] = sum_d / float(count)
        density_grid = blurred_grid
        
    grid_cells.resize(grid_h)
    for y in range(grid_h):
        grid_cells[y] = []
        grid_cells[y].resize(grid_w)
        for x in range(grid_w):
            grid_cells[y][x] = 1 if density_grid[y][x] >= wall_threshold else 0

    map_w = grid_w * cell_px
    map_h = grid_h * cell_px
    
    var viewport_size = get_viewport_rect().size
    var scale_x = viewport_size.x / map_w if map_w > 0 else 1.0
    var scale_y = viewport_size.y / map_h if map_h > 0 else 1.0
    scale_factor = min(scale_x, scale_y)
    offset_x = (viewport_size.x - map_w * scale_factor) / 2.0
    offset_y = (viewport_size.y - map_h * scale_factor) / 2.0
        
    var nav_path = level_dir + "/derived/navgraph.json"
    var spawn_pts = []
    if FileAccess.file_exists(nav_path):
        var f = FileAccess.open(nav_path, FileAccess.READ)
        var json = JSON.new()
        if json.parse(f.get_as_text()) == OK:
            for n in json.data.get("nodes", []):
                if "spawn" in n.get("tags", []) or n.get("type") == "spawn":
                    var px = float(n.get("x", 0))
                    var py = float(n.get("y", 0))
                    spawn_pts.append(Vector2(px, py))
                    
    var temp_spawns = []
    if spawn_pts.size() > 0:
        for pt in spawn_pts:
            var gx = int(pt.x / cell_px)
            var gy = int(pt.y / cell_px)
            temp_spawns.append(Vector2i(gx, gy))
    else:
        temp_spawns = [
            Vector2i(1, 1),
            Vector2i(grid_w - 2, 1),
            Vector2i(1, grid_h - 2),
            Vector2i(grid_w - 2, grid_h - 2)
        ]
        
    var player_spawn_cells = []
    for sp in temp_spawns:
        var safe_pt = _find_nearest_walkable_cell(sp.x, sp.y)
        player_spawn_cells.append({"gx": safe_pt.x, "gy": safe_pt.y})
        
    var num_players = min(selected_players, player_spawn_cells.size())
    players.clear()
    bombs.clear()
    explosions.clear()
    
    for i in range(num_players):
        var sp = player_spawn_cells[i]
        players.append({
            "id": i,
            "gx": sp.gx, "gy": sp.gy,
            "tgx": sp.gx, "tgy": sp.gy,
            "pos": Vector2(sp.gx * cell_px + cell_px*0.5, sp.gy * cell_px + cell_px*0.5),
            "alive": true,
            "speed": cell_px * player_speed_scale,
            "score": 0,
            "bomb_cd": 0.0,
            "bomb_max": 2,
            "bombs_placed": 0,
            "bomb_range": 3,
            "color": player_colors[i]
        })
        
    for y in range(grid_h):
        for x in range(grid_w):
            if grid_cells[y][x] == 1: continue
            
            var is_safe = false
            for p in players:
                if abs(p.gx - x) + abs(p.gy - y) <= 2:
                    is_safe = true
                    break
            
            if is_safe: continue
            
            if randf() < destructible_fill_pct:
                grid_cells[y][x] = 2

func _input(event):
    if _handle_overlay_input(event):
        return

    if game_state == "game_over":
        if (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or \
           (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
            game_state = "playing"
            load_level()
            return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:
            if not show_background:
                show_background = true
                background_opacity = 0.15
            elif background_opacity == 0.15:
                background_opacity = 0.4
            elif background_opacity == 0.4:
                background_opacity = 1.0
            else:
                show_background = false
            queue_redraw()
        elif event.keycode == KEY_F2:
            if current_skin == "neon":
                current_skin = "classic"
            elif current_skin == "classic":
                current_skin = "boomer"
            else:
                current_skin = "neon"
            queue_redraw()
        elif event.keycode == KEY_TAB:
            _set_overlay_mode("settings" if overlay_mode != "settings" else "")
        elif event.keycode == KEY_ESCAPE:
            _set_overlay_mode("start")


func _process(delta):
    _process_ipc(delta)
    if visible and game_state == "playing":
        _process_players(delta)
        _process_bombs(delta)
        _process_explosions(delta)
    _process_particles(delta)
    queue_redraw()

func _process_ipc(delta):
    if ipc_socket:
        ipc_socket.poll()
        if ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
            var bytes_available = ipc_socket.get_available_bytes()
            if bytes_available > 0:
                var data = ipc_socket.get_string(bytes_available)
                read_buffer += data
                var lines = read_buffer.split("\n")
                if lines.size() > 1:
                    for j in range(lines.size() - 1):
                        var line = lines[j].strip_edges()
                        if line.length() > 0: handle_ipc_message(line)
                    read_buffer = lines[lines.size() - 1]
            
            heartbeat_timer += delta
            if heartbeat_timer >= 1.0:
                heartbeat_timer = 0.0
                send_ipc_message({"type": "heartbeat"})

func send_ipc_message(msg: Dictionary):
    if ipc_socket and ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        var json_str = JSON.stringify(msg) + "\n"
        ipc_socket.put_data(json_str.to_utf8_buffer())

func handle_ipc_message(msg_str: String):
    var json = JSON.new()
    if json.parse(msg_str) == OK:
        var msg = json.data
        if typeof(msg) == TYPE_DICTIONARY:
            var msg_type = msg.get("type", msg.get("command", ""))
            if msg_type == "quit": get_tree().quit()
            elif msg_type == "blank": visible = false
            elif msg_type == "pause": visible = false
            elif msg_type == "resume": visible = true
            elif msg_type == "load":
                visible = true
                load_level()
                load_background()

func _get_dir_input(pid: int) -> Vector2:
    var dir = Vector2.ZERO
    var jx = Input.get_joy_axis(SharedLoader.get_joy_id(pid), JOY_AXIS_LEFT_X)
    var jy = Input.get_joy_axis(SharedLoader.get_joy_id(pid), JOY_AXIS_LEFT_Y)
    if abs(jx) > 0.5: dir = Vector2(sign(jx), 0)
    elif abs(jy) > 0.5: dir = Vector2(0, sign(jy))
    
    if dir == Vector2.ZERO:
        if Input.is_joy_button_pressed(SharedLoader.get_joy_id(pid), JOY_BUTTON_DPAD_RIGHT): dir = Vector2(1, 0)
        elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(pid), JOY_BUTTON_DPAD_LEFT): dir = Vector2(-1, 0)
        elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(pid), JOY_BUTTON_DPAD_DOWN): dir = Vector2(0, 1)
        elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(pid), JOY_BUTTON_DPAD_UP): dir = Vector2(0, -1)
        
    if pid == 0 and dir == Vector2.ZERO:
        if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir = Vector2(1, 0)
        elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): dir = Vector2(-1, 0)
        elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): dir = Vector2(0, 1)
        elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): dir = Vector2(0, -1)
    
    # Simple WASD/Arrows mapped to player 0, maybe ESDF for p2?
    if pid == 1 and dir == Vector2.ZERO:
        if Input.is_key_pressed(KEY_L): dir = Vector2(1, 0)
        elif Input.is_key_pressed(KEY_J): dir = Vector2(-1, 0)
        elif Input.is_key_pressed(KEY_K): dir = Vector2(0, 1)
        elif Input.is_key_pressed(KEY_I): dir = Vector2(0, -1)
        
    return dir

func _is_cell_walkable(gx: int, gy: int) -> bool:
    if gx < 0 or gx >= grid_w or gy < 0 or gy >= grid_h: return false
    if grid_cells[gy][gx] != 0: return false # Solid or destructible wall
    for b in bombs:
        if b.gx == gx and b.gy == gy: return false
    return true

func _place_bomb_input(pid: int) -> bool:
    if Input.is_joy_button_pressed(SharedLoader.get_joy_id(pid), JOY_BUTTON_A) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(pid), JOY_BUTTON_X): return true
    if pid == 0 and (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)): return true
    if pid == 1 and Input.is_key_pressed(KEY_SHIFT): return true
    return false

func _process_players(delta):
    var alive_count = 0
    for p in players:
        if not p.alive: continue
        alive_count += 1
        
        if p.bomb_cd > 0: p.bomb_cd -= delta
        
        if p.gx == p.tgx and p.gy == p.tgy:
            var dir = _get_dir_input(p.id)
            if dir != Vector2.ZERO:
                # Prioritize primary axis of input
                var nx = p.gx
                var ny = p.gy
                if abs(dir.x) > 0: nx += int(sign(dir.x))
                elif abs(dir.y) > 0: ny += int(sign(dir.y))
                
                if _is_cell_walkable(nx, ny):
                    p.tgx = nx
                    p.tgy = ny
                    
        if p.gx != p.tgx or p.gy != p.tgy:
            var target_pos = Vector2(p.tgx * cell_px + cell_px*0.5, p.tgy * cell_px + cell_px*0.5)
            var move_vec = target_pos - p.pos
            if move_vec.length() <= p.speed * delta:
                p.pos = target_pos
                p.gx = p.tgx
                p.gy = p.tgy
            else:
                p.pos += move_vec.normalized() * p.speed * delta
                
        # Check explosions
        for e in explosions:
            var cx = e.gx * cell_px + cell_px/2
            var cy = e.gy * cell_px + cell_px/2
            if abs(p.pos.x - cx) < cell_px*0.45 and abs(p.pos.y - cy) < cell_px*0.45:
                p.alive = false
                spawn_particle_burst(p.pos, Color.RED, 30)
                alive_count -= 1
                break
                
        if not p.alive: continue
                
        # Bomb placement
        if _place_bomb_input(p.id) and p.bomb_cd <= 0 and p.bombs_placed < p.bomb_max:
            # Check if bomb already here
            var has_bomb = false
            for b in bombs:
                if b.gx == p.gx and b.gy == p.gy: has_bomb = true
            if not has_bomb:
                bombs.append({
                    "gx": p.gx, "gy": p.gy,
                    "timer": 3.0,
                    "pid": p.id,
                    "range": p.bomb_range
                })
                p.bombs_placed += 1
                p.bomb_cd = 0.2
                
    if alive_count <= 1 and players.size() > 1:
        game_state = "game_over"
        send_ipc_message({"type": "state", "data": {"state": "game_over"}})
        for p in players:
            if p.alive: send_ipc_message({"type": "score", "data": {"player": p.id + 1, "score": p.score + 1000}})
    elif alive_count == 0:
        game_state = "game_over"

func _process_bombs(delta):
    for i in range(bombs.size()):
        bombs[i].timer -= delta
        
    var exploded_any = true
    while exploded_any:
        exploded_any = false
        for i in range(bombs.size() - 1, -1, -1):
            if bombs[i].timer <= 0:
                _explode_bomb(i)
                exploded_any = true
                break

func _explode_bomb(idx: int):
    var b = bombs[idx]
    bombs.remove_at(idx)
    var p = players[b.pid]
    p.bombs_placed = max(0, p.bombs_placed - 1)
    
    var dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
    _spawn_explosion(b.gx, b.gy)
    
    for d in dirs:
        for r in range(1, b.range + 1):
            var nx = b.gx + int(d.x * r)
            var ny = b.gy + int(d.y * r)
            if nx < 0 or nx >= grid_w or ny < 0 or ny >= grid_h: break
            if grid_cells[ny][nx] == 1: break # Indestructible
            
            _spawn_explosion(nx, ny)
            
            if grid_cells[ny][nx] == 2:
                # Destroy wall
                grid_cells[ny][nx] = 0
                spawn_particle_burst(Vector2(nx * cell_px + cell_px/2, ny * cell_px + cell_px/2), Color.YELLOW, 10)
                players[b.pid].score += 50
                send_ipc_message({"type": "score", "data": {"player": b.pid + 1, "score": players[b.pid].score}})
                break # Stop at destructible
            
            # Chain reaction
            for j in range(bombs.size()):
                if bombs[j].gx == nx and bombs[j].gy == ny:
                    bombs[j].timer = 0.0 # Will be caught in the while loop

func _spawn_explosion(gx: int, gy: int):
    explosions.append({
        "gx": gx, "gy": gy,
        "timer": 0.4
    })
    
    for i in range(players.size()):
        var p = players[i]
        if not p.alive: continue
        var cx = gx * cell_px + cell_px/2
        var cy = gy * cell_px + cell_px/2
        if abs(p.pos.x - cx) < cell_px*0.45 and abs(p.pos.y - cy) < cell_px*0.45:
            p.alive = false
            spawn_particle_burst(p.pos, Color.RED, 30)

func _process_explosions(delta):
    for i in range(explosions.size() - 1, -1, -1):
        explosions[i].timer -= delta
        if explosions[i].timer <= 0:
            explosions.remove_at(i)

func spawn_particle_burst(pos: Vector2, color: Color, count: int):
    for i in range(count):
        var angle = randf() * PI * 2.0
        var speed = randf_range(cell_px * 0.8, cell_px * 3.2)
        active_particles.append({
            "pos": pos,
            "vel": Vector2(cos(angle), sin(angle)) * speed,
            "color": color,
            "life": 0.5, "max_life": 0.5
        })

func _process_particles(delta):
    for i in range(active_particles.size() - 1, -1, -1):
        var p = active_particles[i]
        p.pos += p.vel * delta
        p.life -= delta
        if p.life <= 0: active_particles.remove_at(i)

func draw_glow_rect(rect: Rect2, color: Color, line_width: float):
    draw_rect(Rect2(rect.position - Vector2(2,2), rect.size + Vector2(4,4)), Color(color.r, color.g, color.b, 0.2), false, line_width * 2.0)
    draw_rect(rect, color, false, line_width)

func _draw():
    draw_set_transform(Vector2(offset_x, offset_y), 0.0, Vector2(scale_factor, scale_factor))

    if show_background and background_texture:
        draw_texture_rect(background_texture, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, background_opacity))

    if current_skin == "neon":
        # Draw background lattice
        for x in range(0, int(map_w), int(cell_px * 2)): draw_line(Vector2(x, 0), Vector2(x, map_h), Color(1,1,1, 0.05), 1.0)
        for y in range(0, int(map_h), int(cell_px * 2)): draw_line(Vector2(0, y), Vector2(map_w, y), Color(1,1,1, 0.05), 1.0)
        
        for y in range(grid_h):
            for x in range(grid_w):
                var r = Rect2(x * cell_px + 1, y * cell_px + 1, cell_px - 2, cell_px - 2)
                if grid_cells[y][x] == 1:
                    draw_glow_rect(r, Color(0.1, 0.4, 0.9), 2.0)
                elif grid_cells[y][x] == 2:
                    draw_glow_rect(r, Color(1.0, 0.7, 0.0), 2.0)
                    draw_rect(r, Color(1.0, 0.7, 0.0, 0.2))

        for b in bombs:
            var pos = Vector2(b.gx * cell_px + cell_px/2, b.gy * cell_px + cell_px/2)
            var pulse = 0.6 + sin(Time.get_ticks_msec() * 0.015) * 0.4
            draw_circle(pos, cell_px * 0.35, Color(1.0, pulse, 0.0))
            draw_circle(pos, cell_px * 0.35, Color.WHITE, false, 2.0)
            
        for e in explosions:
            var pos = Vector2(e.gx * cell_px + cell_px/2, e.gy * cell_px + cell_px/2)
            draw_rect(Rect2(e.gx * cell_px + 2, e.gy * cell_px + 2, cell_px - 4, cell_px - 4), Color(1.0, 0.0, 0.8, 0.8))
            draw_rect(Rect2(e.gx * cell_px + 6, e.gy * cell_px + 6, cell_px - 12, cell_px - 12), Color.WHITE)
            
        for p in players:
            if not p.alive: continue
            draw_circle(p.pos, cell_px * 0.3, p.color)
            draw_circle(p.pos, cell_px * 0.3, Color.WHITE, false, 2.0)
    elif current_skin == "boomer":
        # Draw a retro green/grey grid/background
        for x in range(0, int(map_w), int(cell_px)):
            draw_line(Vector2(x, 0), Vector2(x, map_h), Color(0.2, 0.25, 0.2, 0.1), 1.0)
        for y in range(0, int(map_h), int(cell_px)):
            draw_line(Vector2(0, y), Vector2(map_w, y), Color(0.2, 0.25, 0.2, 0.1), 1.0)

        for y in range(grid_h):
            for x in range(grid_w):
                var r = Rect2(x * cell_px, y * cell_px, cell_px, cell_px)
                if grid_cells[y][x] == 1:
                    # Indestructible wall: corporate tower / skyscraper (grey block with yellow windows)
                    draw_rect(r, Color(0.25, 0.28, 0.3))
                    draw_rect(r, Color(0.15, 0.18, 0.2), false, 2.0)
                    var w_sz = cell_px * 0.15
                    draw_rect(Rect2(x * cell_px + cell_px * 0.2, y * cell_px + cell_px * 0.2, w_sz, w_sz), Color(1.0, 0.9, 0.4))
                    draw_rect(Rect2(x * cell_px + cell_px * 0.6, y * cell_px + cell_px * 0.2, w_sz, w_sz), Color(1.0, 0.9, 0.4))
                    draw_rect(Rect2(x * cell_px + cell_px * 0.2, y * cell_px + cell_px * 0.6, w_sz, w_sz), Color(1.0, 0.9, 0.4))
                    draw_rect(Rect2(x * cell_px + cell_px * 0.6, y * cell_px + cell_px * 0.6, w_sz, w_sz), Color(1.0, 0.9, 0.4))
                elif grid_cells[y][x] == 2:
                    # Destructible wall: cozy brick house (red/brown house with a roof)
                    var house_rect = Rect2(x * cell_px + cell_px * 0.1, y * cell_px + cell_px * 0.4, cell_px * 0.8, cell_px * 0.5)
                    draw_rect(house_rect, Color(0.7, 0.4, 0.3))
                    draw_rect(house_rect, Color(0.4, 0.2, 0.15), false, 1.5)
                    var p1 = Vector2(x * cell_px + cell_px * 0.5, y * cell_px + cell_px * 0.05)
                    var p2 = Vector2(x * cell_px + cell_px * 0.05, y * cell_px + cell_px * 0.4)
                    var p3 = Vector2(x * cell_px + cell_px * 0.95, y * cell_px + cell_px * 0.4)
                    draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(0.8, 0.2, 0.2))
                    draw_rect(Rect2(x * cell_px + cell_px * 0.4, y * cell_px + cell_px * 0.65, cell_px * 0.2, cell_px * 0.25), Color(0.2, 0.5, 0.3))

        for b in bombs:
            # Bomb: Earth globe (blue/green circle) with a burning fuse
            var pos = Vector2(b.gx * cell_px + cell_px/2, b.gy * cell_px + cell_px/2)
            var rad = cell_px * 0.38
            draw_circle(pos, rad, Color(0.2, 0.5, 0.9))
            draw_circle(pos + Vector2(-rad*0.3, -rad*0.2), rad * 0.4, Color(0.3, 0.7, 0.3))
            draw_circle(pos + Vector2(rad*0.3, rad*0.3), rad * 0.35, Color(0.3, 0.7, 0.3))
            draw_circle(pos + Vector2(-rad*0.2, rad*0.4), rad * 0.3, Color(0.3, 0.7, 0.3))
            draw_circle(pos, rad, Color(0.1, 0.2, 0.4), false, 2.0)
            
            var fuse_start = pos - Vector2(0, rad)
            var fuse_end = fuse_start - Vector2(cell_px * 0.15, cell_px * 0.15)
            draw_line(fuse_start, fuse_end, Color(0.5, 0.5, 0.5), 2.0)
            var pulse = 0.8 + sin(Time.get_ticks_msec() * 0.03) * 0.2
            draw_circle(fuse_end, cell_px * 0.1 * pulse, Color(1.0, 0.3, 0.0))
            draw_circle(fuse_end, cell_px * 0.06, Color(1.0, 0.9, 0.1))

        for e in explosions:
            var pos = Vector2(e.gx * cell_px + cell_px/2, e.gy * cell_px + cell_px/2)
            draw_rect(Rect2(e.gx * cell_px + 1, e.gy * cell_px + 1, cell_px - 2, cell_px - 2), Color(0.9, 0.2, 0.1, 0.4))
            draw_circle(pos, cell_px * 0.45, Color(1.0, 0.4, 0.0, 0.7))
            draw_circle(pos, cell_px * 0.25, Color(1.0, 0.8, 0.2))

        for p in players:
            if not p.alive: continue
            # Boomer Player: Peach face, grey hair, and big glasses!
            draw_circle(p.pos, cell_px * 0.32, Color(0.98, 0.85, 0.75))
            draw_circle(p.pos + Vector2(-cell_px*0.28, -cell_px*0.1), cell_px * 0.12, Color(0.75, 0.75, 0.75))
            draw_circle(p.pos + Vector2(cell_px*0.28, -cell_px*0.1), cell_px * 0.12, Color(0.75, 0.75, 0.75))
            draw_circle(p.pos + Vector2(0, -cell_px*0.28), cell_px * 0.1, Color(0.75, 0.75, 0.75))
            
            var eye_left = p.pos + Vector2(-cell_px * 0.12, -cell_px * 0.05)
            var eye_right = p.pos + Vector2(cell_px * 0.12, -cell_px * 0.05)
            var glass_rad = cell_px * 0.11
            
            draw_circle(eye_left, glass_rad, Color.WHITE)
            draw_circle(eye_left, glass_rad, Color.BLACK, false, 1.5)
            draw_circle(eye_left, cell_px * 0.03, Color.BLACK)
            
            draw_circle(eye_right, glass_rad, Color.WHITE)
            draw_circle(eye_right, glass_rad, Color.BLACK, false, 1.5)
            draw_circle(eye_right, cell_px * 0.03, Color.BLACK)
            
            draw_line(eye_left + Vector2(glass_rad, 0), eye_right - Vector2(glass_rad, 0), Color.BLACK, 2.0)
            draw_line(p.pos + Vector2(-cell_px*0.08, cell_px*0.12), p.pos + Vector2(cell_px*0.08, cell_px*0.12), Color(0.4, 0.2, 0.2), 2.0)
    else:
        for y in range(grid_h):
            for x in range(grid_w):
                var r = Rect2(x * cell_px, y * cell_px, cell_px, cell_px)
                if grid_cells[y][x] == 1:
                    draw_rect(r, Color(0.3, 0.3, 0.3))
                    draw_rect(r, Color.BLACK, false, 1.0)
                elif grid_cells[y][x] == 2:
                    draw_rect(r, Color(0.6, 0.4, 0.2))
                    draw_rect(r, Color.BLACK, false, 1.0)
                    
        for b in bombs:
            var pos = Vector2(b.gx * cell_px + cell_px/2, b.gy * cell_px + cell_px/2)
            var flash = (int(b.timer * 8.0) % 2) == 0
            var body_color = Color(0.8, 0.1, 0.1) if flash else Color(0.15, 0.15, 0.2)
            # Draw bomb body
            draw_circle(pos, cell_px * 0.4, body_color)
            draw_circle(pos, cell_px * 0.4, Color.WHITE, false, 1.5)
            # Draw neck
            draw_rect(Rect2(pos.x - cell_px * 0.08, pos.y - cell_px * 0.46, cell_px * 0.16, cell_px * 0.08), body_color)
            draw_rect(Rect2(pos.x - cell_px * 0.08, pos.y - cell_px * 0.46, cell_px * 0.16, cell_px * 0.08), Color.WHITE, false, 1.0)
            # Draw fuse
            var fuse_start = pos + Vector2(0, -cell_px * 0.44)
            var fuse_end = fuse_start + Vector2(cell_px * 0.12, -cell_px * 0.12)
            draw_line(fuse_start, fuse_end, Color(0.8, 0.8, 0.8), 2.0)
            # Draw spark
            var pulse = 0.8 + sin(Time.get_ticks_msec() * 0.03) * 0.2
            draw_circle(fuse_end, cell_px * 0.15 * pulse, Color.RED)
            draw_circle(fuse_end, cell_px * 0.08 * pulse, Color.YELLOW)
            
        for e in explosions:
            draw_rect(Rect2(e.gx * cell_px, e.gy * cell_px, cell_px, cell_px), Color(1.0, 0.5, 0.0))
            
        for p in players:
            if not p.alive: continue
            draw_rect(Rect2(p.pos - Vector2(cell_px*0.3, cell_px*0.3), Vector2(cell_px*0.6, cell_px*0.6)), Color.WHITE)
            draw_rect(Rect2(p.pos - Vector2(cell_px*0.3, cell_px*0.3), Vector2(cell_px*0.6, cell_px*0.6)), Color.BLACK, false, 1.0)

    for p in active_particles:
        draw_circle(p.pos, 3.0 * (p.life/p.max_life), p.color)

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if game_state == "game_over":
        draw_string(ThemeDB.fallback_font, get_viewport_rect().size / 2, "GAME OVER - PRESS START", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.RED)
