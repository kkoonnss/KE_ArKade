extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()

const NEON_CYAN = Color(0.0, 0.9, 1.0)
const NEON_ORANGE = Color(1.0, 0.48, 0.0)
const NEON_GREEN = Color(0.0, 0.9, 0.46)
const NEON_MAGENTA = Color(1.0, 0.18, 0.77)
const NEON_YELLOW = Color(1.0, 0.83, 0.0)
const NEON_RED = Color(1.0, 0.08, 0.12)
const INK_DIM = Color(0.6, 0.63, 0.65)

var ipc_socket: StreamPeerTCP = null
var ipc_host = "127.0.0.1"
var ipc_port = 0
var scene_dir = ""
var level_dir = ""
var read_buffer = ""
var heartbeat_timer = 0.0
var has_sent_ready = false
var screenshot_path = ""

var game_id = ""
var game_title = ""
var paused = false
var blanked = false
var score = 0
var lives = 3
var game_state = "playing"
var state_timer = 0.0

var map_w = 1280.0
var map_h = 720.0
var scale_factor = 1.0
var offset = Vector2.ZERO
var cell_px = 32.0
var grid_cells = []
var grid_w = 0
var grid_h = 0
var walkable_cells = []
var solid_cells = []
var special_cells = []

var bg_canvas: CanvasLayer
var black_rect: ColorRect
var ui_canvas: CanvasLayer
var tab_menu: ColorRect
var splash_rect: TextureRect
var menu_panel: PanelContainer
var menu_title_label: Label
var menu_subtitle_label: Label
var menu_hint_label: Label
var menu_labels = []
var menu_items = []
var overlay_mode: String = "start"
var selected_menu_index: int = 0
var selected_players = 1
var menu_axis_cooldown: float = 0.0
var tab_menu_shell: BoxContainer
var tab_cover_frame: PanelContainer
var tab_cover_rect: TextureRect
var splash_timer = 1.6
var show_reference = false
var reference_texture: Texture2D = null

var players = []
var enemies = []
var bullets = []
var enemy_bullets = []
var particles = []
var pickups = []
var barriers = []
var explosions = []
var missiles = []
var pads = []
var cities = []
var silos = []
var cubes = []
var ingredients = []
var platforms = []
var ladders = []
var houses = []
var papers = []
var road_markers = []
var centipede = []

var invader_dir = 1
var invader_step_timer = 0.0
var spawn_timer = 0.0
var fire_timer = 0.0
var wave = 1
var dual_ship = false
var lander = {}
var scroll_x = 0.0
var scroll_y = 0.0
var aim_pos = Vector2.ZERO
var cube_player = Vector2i.ZERO

func _ready():
    randomize()
    _derive_identity()
    _parse_args()
    _build_shell()
    _connect_ipc()
    load_level()
    _reset_game()
    _set_overlay_mode("start")
    if screenshot_path != "":
        await get_tree().create_timer(2.2).timeout
        get_viewport().get_texture().get_image().save_png(screenshot_path)
        get_tree().quit()

func _derive_identity():
    var base = ProjectSettings.globalize_path("res://")
    if base.ends_with("/") or base.ends_with("\\"):
        base = base.substr(0, base.length() - 1)
    game_id = base.get_file()
    var titles = {
        "centipede": "Centipede",
        "space_invaders": "Space Invaders",
        "robotron_2084": "Robotron: 2084",
        "burger_time": "BurgerTime",
        "galaga": "Galaga",
        "missile_command": "Missile Command",
        "defender": "Defender",
        "lunar_lander": "Lunar Lander",
        "paperboy": "Paperboy",
        "qbert": "Q*bert"
    }
    game_title = titles.get(game_id, game_id.capitalize())

func _parse_args():
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    var i = 0
    while i < args.size():
        var a = str(args[i])
        if a == "--scene" and i + 1 < args.size():
            scene_dir = str(args[i + 1])
            i += 1
        elif a == "--level" and i + 1 < args.size():
            level_dir = str(args[i + 1])
            i += 1
        elif a == "--level_dir" and i + 1 < args.size():
            level_dir = str(args[i + 1])
            i += 1
        elif a.begins_with("--level_dir="):
            level_dir = a.split("=", true, 1)[1]
        elif a == "--ipc" and i + 1 < args.size():
            _set_ipc(str(args[i + 1]))
            i += 1
        elif a == "--screenshot" and i + 1 < args.size():
            screenshot_path = str(args[i + 1])
            i += 1
        i += 1

func _set_ipc(value: String):
    if ":" in value:
        var parts = value.split(":")
        ipc_host = str(parts[0])
        ipc_port = int(parts[1])
    else:
        ipc_port = int(value)

func _build_shell():
    RenderingServer.set_default_clear_color(Color.BLACK)
    bg_canvas = CanvasLayer.new()
    bg_canvas.layer = -100
    add_child(bg_canvas)
    black_rect = ColorRect.new()
    black_rect.color = Color.BLACK
    black_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg_canvas.add_child(black_rect)

    ui_canvas = CanvasLayer.new()
    ui_canvas.layer = 100
    add_child(ui_canvas)

    splash_rect = TextureRect.new()
    splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path):
        var img = Image.load_from_file(splash_path)
        if img:
            splash_rect.texture = ImageTexture.create_from_image(img)
    ui_canvas.add_child(splash_rect)

    tab_menu = ColorRect.new()
    tab_menu.color = Color(0, 0, 0, 0.18)
    tab_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_menu.visible = true
    ui_canvas.add_child(tab_menu)
    var margin = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 48)
    margin.add_theme_constant_override("margin_top", 48)
    margin.add_theme_constant_override("margin_right", 48)
    margin.add_theme_constant_override("margin_bottom", 48)
    tab_menu.add_child(margin)
    tab_menu_shell = HBoxContainer.new()
    tab_menu_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_menu_shell.alignment = BoxContainer.ALIGNMENT_END
    tab_menu_shell.add_theme_constant_override("separation", 28)
    margin.add_child(tab_menu_shell)
    tab_cover_frame = PanelContainer.new()
    tab_cover_frame.custom_minimum_size = Vector2(420, 640)
    tab_cover_frame.visible = false
    tab_cover_frame.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.95, 0.78, 0.22), Color(0.03, 0.03, 0.06, 0.96)))
    tab_menu_shell.add_child(tab_cover_frame)
    tab_cover_rect = TextureRect.new()
    tab_cover_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_cover_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    tab_cover_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path2 = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path2):
        var img2 = Image.load_from_file(splash_path2)
        if img2:
            tab_cover_rect.texture = ImageTexture.create_from_image(img2)
    tab_cover_frame.add_child(tab_cover_rect)
    menu_panel = PanelContainer.new()
    menu_panel.custom_minimum_size = Vector2(520, 420)
    menu_panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.16, 0.55, 1.0), Color(0.01, 0.01, 0.01, 0.92)))
    tab_menu_shell.add_child(menu_panel)
    var center = MarginContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.add_theme_constant_override("margin_left", 28)
    center.add_theme_constant_override("margin_top", 24)
    center.add_theme_constant_override("margin_right", 28)
    center.add_theme_constant_override("margin_bottom", 24)
    menu_panel.add_child(center)
    var box = VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    center.add_child(box)
    menu_title_label = Label.new()
    menu_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    menu_title_label.add_theme_font_size_override("font_size", 42)
    menu_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.24))
    box.add_child(menu_title_label)
    menu_subtitle_label = Label.new()
    menu_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    menu_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_subtitle_label.add_theme_font_size_override("font_size", 18)
    menu_subtitle_label.add_theme_color_override("font_color", INK_DIM)
    box.add_child(menu_subtitle_label)
    var divider = HSeparator.new()
    box.add_child(divider)
    for i in range(8):
        var label = Label.new()
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        label.add_theme_font_size_override("font_size", 22)
        label.add_theme_color_override("font_color", Color.WHITE)
        menu_labels.append(label)
        box.add_child(label)
    menu_hint_label = Label.new()
    menu_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    menu_hint_label.add_theme_font_size_override("font_size", 16)
    menu_hint_label.add_theme_color_override("font_color", INK_DIM)
    box.add_child(menu_hint_label)
    _set_overlay_mode("start")

func _connect_ipc():
    if ipc_port <= 0:
        return
    ipc_socket = StreamPeerTCP.new()
    ipc_socket.connect_to_host(ipc_host, ipc_port)

func load_level():
    grid_cells.clear()
    walkable_cells.clear()
    solid_cells.clear()
    special_cells.clear()

    var loaded_grid = false
    if level_dir != "":
        var grid_path = level_dir.path_join("derived").path_join("grid.json")
        if FileAccess.file_exists(grid_path):
            var f = FileAccess.open(grid_path, FileAccess.READ)
            if f:
                var json = JSON.new()
                if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
                    var data = json.data
                    cell_px = float(data.get("cell_px", data.get("cell_size", 32.0)))
                    grid_cells = data.get("cells", [])
                    loaded_grid = grid_cells.size() > 0
    if not loaded_grid:
        _load_grid_from_occupancy()
    if grid_cells.size() == 0:
        _build_fallback_grid()

    grid_h = grid_cells.size()
    grid_w = 0
    for row in grid_cells:
        grid_w = max(grid_w, row.size())
    map_w = max(640.0, grid_w * cell_px)
    map_h = max(480.0, grid_h * cell_px)

    if level_dir != "":
        var sem_path = level_dir.path_join("semantic_map.png")
        if FileAccess.file_exists(sem_path):
            var img = Image.load_from_file(sem_path)
            if img:
                map_w = img.get_width()
                map_h = img.get_height()
        _load_reference()

    for y in range(grid_h):
        var row = grid_cells[y]
        for x in range(row.size()):
            var cid = int(row[x])
            var c = Vector2i(x, y)
            if cid == 1:
                solid_cells.append(c)
            else:
                walkable_cells.append(c)
            if cid in [3, 5, 6, 7]:
                special_cells.append(c)
    _update_scale()

func _load_grid_from_occupancy():
    if level_dir == "":
        return
    var occ_path = level_dir.path_join("derived").path_join("occupancy.png")
    if not FileAccess.file_exists(occ_path):
        return
    var img = Image.load_from_file(occ_path)
    if not img:
        return
    cell_px = 32.0
    var w = max(1, int(img.get_width() / cell_px))
    var h = max(1, int(img.get_height() / cell_px))
    for y in range(h):
        var row = []
        for x in range(w):
            var p = img.get_pixel(min(img.get_width() - 1, int(x * cell_px)), min(img.get_height() - 1, int(y * cell_px)))
            row.append(1 if p.r > 0.5 else 2)
        grid_cells.append(row)

func _build_fallback_grid():
    cell_px = 32.0
    for y in range(22):
        var row = []
        for x in range(36):
            var border = x == 0 or y == 0 or x == 35 or y == 21
            row.append(1 if border else 2)
        grid_cells.append(row)
    grid_cells[19][18] = 5
    grid_cells[2][18] = 6

func _load_reference():
    reference_texture = null
    var yaml_path = level_dir.path_join("level.yaml")
    if not FileAccess.file_exists(yaml_path):
        return
    var f = FileAccess.open(yaml_path, FileAccess.READ)
    if not f:
        return
    while not f.eof_reached():
        var line = f.get_line().strip_edges()
        if line.begins_with("reference_image:"):
            var ref = line.split(":", true, 1)[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
            var path = level_dir.path_join(ref)
            if FileAccess.file_exists(path):
                var img = Image.load_from_file(path)
                if img:
                    reference_texture = ImageTexture.create_from_image(img)

func _update_scale():
    var vp = get_viewport_rect().size
    if map_w <= 0 or map_h <= 0:
        return
    scale_factor = min(vp.x / map_w, vp.y / map_h)
    offset = Vector2((vp.x - map_w * scale_factor) * 0.5, (vp.y - map_h * scale_factor) * 0.5)

func _notification(what):
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _update_scale()

func _reset_game():
    score = 0
    lives = 3
    game_state = "playing"
    state_timer = 0.0
    wave = 1
    dual_ship = false
    players.clear()
    enemies.clear()
    bullets.clear()
    enemy_bullets.clear()
    particles.clear()
    pickups.clear()
    barriers.clear()
    explosions.clear()
    missiles.clear()
    pads.clear()
    cities.clear()
    silos.clear()
    cubes.clear()
    ingredients.clear()
    platforms.clear()
    ladders.clear()
    houses.clear()
    papers.clear()
    road_markers.clear()
    centipede.clear()
    scroll_x = 0.0
    scroll_y = 0.0
    aim_pos = Vector2(map_w * 0.5, map_h * 0.5)
    if game_id == "centipede":
        _setup_centipede()
    elif game_id == "space_invaders" or game_id == "galaga":
        _setup_invaders()
    elif game_id == "robotron_2084":
        _setup_robotron_2084()
    elif game_id == "burger_time":
        _setup_burger()
    elif game_id == "missile_command":
        _setup_missile_command()
    elif game_id == "defender":
        _setup_defender()
    elif game_id == "lunar_lander":
        _setup_lunar()
    elif game_id == "paperboy":
        _setup_paperboy()
    elif game_id == "qbert":
        _setup_qbert()
    _emit_score(1)
    queue_redraw()

func _setup_player(pos: Vector2):
    players.append({"pos": _safe_position(pos), "vel": Vector2.ZERO, "cooldown": 0.0, "alive": true, "color": NEON_CYAN})

func _setup_centipede():
    _setup_player(Vector2(map_w * 0.5, map_h * 0.86))
    for i in range(14):
        centipede.append({"pos": _safe_position(Vector2(map_w * 0.2 + i * cell_px, map_h * 0.12)), "dir": Vector2.RIGHT, "alive": true})
    _seed_barriers(36, [1, 7], 1)

func _setup_invaders():
    _setup_player(Vector2(map_w * 0.5, map_h * 0.88))
    var rows = 5 if game_id == "galaga" else 4
    var cols = 10
    for y in range(rows):
        for x in range(cols):
            enemies.append({"pos": Vector2(map_w * 0.2 + x * 52, map_h * 0.13 + y * 42), "base": Vector2(map_w * 0.2 + x * 52, map_h * 0.13 + y * 42), "kind": "boss" if game_id == "galaga" and y == 0 and x in [4, 5] else "alien", "phase": randf() * TAU, "cooldown": randf_range(1.0, 3.0), "alive": true})
    _seed_barriers(24, [1, 7], 2)

func _setup_robotron_2084():
    _setup_player(Vector2(map_w * 0.5, map_h * 0.5))
    for i in range(14):
        enemies.append({"pos": _spawn_far_from(players[0]["pos"]), "speed": randf_range(65.0, 115.0), "alive": true})
    for i in range(8):
        pickups.append({"pos": _safe_position(Vector2(randf() * map_w, randf() * map_h)), "rescued": false})

func _setup_burger():
    _setup_player(Vector2(map_w * 0.18, map_h * 0.78))
    for y in [0.22, 0.38, 0.54, 0.70, 0.86]:
        platforms.append(Rect2(map_w * 0.12, map_h * y, map_w * 0.76, 4))
    for x in [0.25, 0.43, 0.61, 0.79]:
        ladders.append(Rect2(map_w * x, map_h * 0.22, 5, map_h * 0.64))
    for row_i in range(4):
        var py = map_h * (0.26 + row_i * 0.16)
        for piece in range(4):
            ingredients.append({"rect": Rect2(map_w * (0.25 + piece * 0.13), py, 90, 18), "walk": 0.0, "fall": 0.0, "done": false})
    for i in range(5):
        enemies.append({"pos": Vector2(map_w * (0.25 + i * 0.12), map_h * 0.34), "speed": 72.0 + i * 7.0, "alive": true})

func _setup_missile_command():
    for i in range(6):
        cities.append({"pos": Vector2(map_w * (0.16 + i * 0.135), map_h * 0.9), "alive": true})
    for x in [0.08, 0.5, 0.92]:
        silos.append({"pos": Vector2(map_w * x, map_h * 0.92), "ammo": 12})

func _setup_defender():
    _setup_player(Vector2(map_w * 0.5, map_h * 0.42))
    for i in range(10):
        pickups.append({"pos": Vector2(randf() * map_w, map_h * randf_range(0.58, 0.86)), "rescued": false})
    for i in range(8):
        enemies.append({"pos": Vector2(randf() * map_w, map_h * randf_range(0.1, 0.55)), "speed": randf_range(80, 140), "alive": true, "carry": -1})

func _setup_lunar():
    lander = {"pos": Vector2(map_w * 0.5, map_h * 0.16), "vel": Vector2.ZERO, "angle": 0.0, "fuel": 100.0, "landed": false}
    for x in [0.22, 0.5, 0.78]:
        pads.append(Rect2(map_w * x - 42, map_h * randf_range(0.74, 0.88), 84, 8))

func _setup_paperboy():
    _setup_player(Vector2(map_w * 0.5, map_h * 0.78))
    scroll_y = 0.0
    for i in range(16):
        var side = -1 if i % 2 == 0 else 1
        houses.append({"pos": Vector2(map_w * 0.5 + side * map_w * 0.23, map_h - i * 130.0), "subscriber": i % 3 != 0, "hit": false})
    for i in range(20):
        road_markers.append({"pos": Vector2(map_w * 0.5 + sin(i) * 80.0, map_h - i * 90.0)})

func _setup_qbert():
    cube_player = Vector2i(0, 0)
    var rows = 7
    for r in range(rows):
        for c in range(r + 1):
            cubes.append({"rc": Vector2i(r, c), "lit": false})
    for i in range(3):
        enemies.append({"rc": Vector2i(i + 2, randi() % (i + 3)), "timer": randf_range(0.4, 1.2)})

func _seed_barriers(count: int, classes: Array, hit_points: int):
    for c in solid_cells:
        if barriers.size() >= count:
            break
        if c.y > 1 and c.y < grid_h - 2 and c.x > 1 and c.x < grid_w - 2:
            barriers.append({"cell": c, "pos": _cell_center(c), "hp": hit_points})
    while barriers.size() < count:
        var p = _safe_position(Vector2(randf_range(map_w * 0.12, map_w * 0.88), randf_range(map_h * 0.22, map_h * 0.75)))
        barriers.append({"cell": _pos_to_cell(p), "pos": p, "hp": hit_points})

func _input(event):
    if overlay_mode != "" and _handle_menu_input(event):
        return
	if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
		if "game_state" in self and game_state != "playing":
			if has_method("_reset_game"): _reset_game()
			elif has_method("reset_game"): reset_game()
		elif "state" in self and state != "playing":
			if has_method("_reset_game"): _reset_game()
			elif has_method("reset_game"): reset_game()

	if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_TAB:
            _set_overlay_mode("settings" if overlay_mode != "settings" else "start")
        elif event.keycode == KEY_F1:
            show_reference = not show_reference
            _update_menu_overlay()
        elif event.keycode == KEY_ENTER and game_state != "playing":
            _reset_game()
        elif event.keycode == KEY_ESCAPE:
            _set_overlay_mode("start")
            return
    if event is InputEventMouseMotion:
        aim_pos = _screen_to_world(event.position)
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        aim_pos = _screen_to_world(event.position)
        if game_id == "missile_command":
            _fire_counter_missile(aim_pos)

func _process(delta):
    _process_ipc(delta)
    if menu_axis_cooldown > 0.0:
        menu_axis_cooldown = max(0.0, menu_axis_cooldown - delta)
    if blanked:
        return
    if overlay_mode != "" or paused:
        queue_redraw()
        return
    if game_state == "playing":
        if game_id == "centipede":
            _tick_centipede(delta)
        elif game_id == "space_invaders" or game_id == "galaga":
            _tick_invaders(delta)
        elif game_id == "robotron_2084":
            _tick_robotron_2084(delta)
        elif game_id == "burger_time":
            _tick_burger(delta)
        elif game_id == "missile_command":
            _tick_missile_command(delta)
        elif game_id == "defender":
            _tick_defender(delta)
        elif game_id == "lunar_lander":
            _tick_lunar(delta)
        elif game_id == "paperboy":
            _tick_paperboy(delta)
        elif game_id == "qbert":
            _tick_qbert(delta)
    _tick_particles(delta)
    queue_redraw()

func _set_menu_mode(show_cover: bool):
    if not tab_menu:
        return
    tab_menu.color = Color(0, 0, 0, 0.82) if show_cover else Color(0, 0, 0, 0.18)
    if tab_cover_frame:
        tab_cover_frame.visible = show_cover
    if tab_menu_shell:
        tab_menu_shell.alignment = BoxContainer.ALIGNMENT_CENTER if show_cover else BoxContainer.ALIGNMENT_END

func _set_overlay_mode(mode: String):
    overlay_mode = mode
    selected_menu_index = 0
    tab_menu.visible = overlay_mode != ""
    if overlay_mode == "":
        return
    _set_menu_mode(overlay_mode != "settings")
    if tab_cover_frame:
        tab_cover_frame.visible = overlay_mode in ["start", "help"]
    if menu_panel:
        menu_panel.custom_minimum_size = Vector2(560, 520) if overlay_mode == "settings" else Vector2(520, 520)
    _update_menu_overlay()

func _update_menu_overlay():
    if menu_labels.is_empty():
        return
    menu_items = _menu_items_for_mode(overlay_mode)
    if menu_items.size() > 0:
        selected_menu_index = clamp(selected_menu_index, 0, menu_items.size() - 1)
    var title_text = game_title
    var subtitle = "Classic cover on the left, clean controls on the right."
    var hint = "A / Start / Enter selects. D-Pad / arrows move. Left/right adjusts."
    var lines = []
    if overlay_mode == "help":
        title_text += " HELP"
        subtitle = "Projection-ready controls, restart flow, and reference overlay live here."
        hint = "A / Start confirms. B / Escape goes back."
        lines = ["Move with arrows or WASD.", "Press Tab for settings.", "F1 toggles the level reference overlay.", _menu_line(0), _menu_line(1)]
    elif overlay_mode == "settings":
        title_text += " SETTINGS"
        subtitle = "Keep the game visible while you tune the run-up conditions."
        hint = "Left/right updates values immediately. Back returns to start."
        lines = [_menu_line(0), _menu_line(1), _menu_line(2), _menu_line(3), _menu_line(4)]
    else:
        lines = [_menu_line(0), _menu_line(1), _menu_line(2), _menu_line(3)]
    menu_title_label.text = title_text
    menu_subtitle_label.text = subtitle
    menu_hint_label.text = hint
    for i in range(menu_labels.size()):
        menu_labels[i].text = lines[i] if i < lines.size() else ""
        menu_labels[i].add_theme_color_override("font_color", Color.WHITE)
        if i < lines.size() and lines[i].begins_with(">"):
            menu_labels[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

func _menu_items_for_mode(mode: String) -> Array:
    if mode == "settings":
        return [{"label": "Players: " + str(selected_players), "action": "players"}, {"label": "Reference Overlay: " + ("On" if show_reference else "Off"), "action": "reference"}, {"label": "Back", "action": "back"}, {"label": "Start Game", "action": "start"}]
    if mode == "help":
        return [{"label": "Back", "action": "back"}, {"label": "Start Game", "action": "start"}]
    if mode == "start":
        return [{"label": "Start Game", "action": "start"}, {"label": "Help", "action": "help"}, {"label": "Settings", "action": "settings"}, {"label": "Players: " + str(selected_players), "action": "players"}]
    return []

func _menu_line(index: int) -> String:
    if index < 0 or index >= menu_items.size():
        return ""
    return ("> " if index == selected_menu_index else "  ") + str(menu_items[index].get("label", ""))

func _handle_menu_input(event) -> bool:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_UP, KEY_W]:
            _menu_move(-1)
            return true
        if event.keycode in [KEY_DOWN, KEY_S]:
            _menu_move(1)
            return true
        if event.keycode in [KEY_LEFT, KEY_A]:
            _menu_adjust(-1)
            return true
        if event.keycode in [KEY_RIGHT, KEY_D]:
            _menu_adjust(1)
            return true
        if event.keycode in [KEY_ENTER, KEY_SPACE]:
            _menu_accept()
            return true
        if event.keycode in [KEY_ESCAPE, KEY_BACKSPACE]:
            _menu_back()
            return true
        if event.keycode == KEY_TAB:
            _set_overlay_mode("settings" if overlay_mode != "settings" else "start")
            return true
    return false

func _menu_move(step: int):
    if menu_items.is_empty():
        return
    selected_menu_index = (selected_menu_index + step + menu_items.size()) % menu_items.size()
    _update_menu_overlay()

func _menu_adjust(step: int):
    if menu_items.is_empty():
        return
    var action = str(menu_items[selected_menu_index].get("action", ""))
    if action == "players":
        selected_players += step
        if selected_players < 1:
            selected_players = 4
        elif selected_players > 4:
            selected_players = 1
    elif action == "reference":
        show_reference = not show_reference
    _update_menu_overlay()

func _menu_accept():
    if menu_items.is_empty():
        return
    var action = str(menu_items[selected_menu_index].get("action", ""))
    if action == "start":
        game_state = "playing"
        _set_overlay_mode("")
    elif action == "help":
        _set_overlay_mode("help")
    elif action == "settings":
        _set_overlay_mode("settings")
    elif action == "back":
        _set_overlay_mode("start")
    elif action == "reference":
        show_reference = not show_reference
        _update_menu_overlay()

func _menu_back():
    if overlay_mode == "":
        _set_overlay_mode("start")
    elif overlay_mode == "start":
        _set_overlay_mode("")
    else:
        _set_overlay_mode("start")

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

func _process_ipc(delta):
    if not ipc_socket:
        return
    ipc_socket.poll()
    if ipc_socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
        return
    if not has_sent_ready:
        has_sent_ready = true
        send_ipc_message({"type": "ready"})
    var bytes = ipc_socket.get_available_bytes()
    if bytes > 0:
        read_buffer += ipc_socket.get_string(bytes)
        var lines = read_buffer.split("\n")
        if lines.size() > 1:
            for i in range(lines.size() - 1):
                var line = lines[i].strip_edges()
                if line != "":
                    handle_ipc_message(line)
            read_buffer = lines[lines.size() - 1]
    heartbeat_timer += delta
    if heartbeat_timer >= 1.0:
        heartbeat_timer = 0.0
        send_ipc_message({"type": "heartbeat"})

func handle_ipc_message(msg_str: String):
    var json = JSON.new()
    if json.parse(msg_str) != OK or typeof(json.data) != TYPE_DICTIONARY:
        send_ipc_message({"type": "error", "data": {"message": "invalid json"}})
        return
    var msg = json.data
    var t = str(msg.get("type", msg.get("command", "")))
    if t == "quit":
        get_tree().quit()
    elif t == "pause":
        paused = true
    elif t == "resume":
        paused = false
        blanked = false
        visible = true
    elif t == "blank":
        blanked = true
        visible = false
    elif t == "load":
        visible = true
        blanked = false
        paused = false
        var data = msg.get("data", {})
        if typeof(data) == TYPE_DICTIONARY and data.has("level_dir"):
            level_dir = str(data["level_dir"])
            load_level()
        _reset_game()

func send_ipc_message(msg: Dictionary):
    if ipc_socket and ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        ipc_socket.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())

func _tick_centipede(delta):
    var p = players[0]
    var move = _input_vector(0)
    p["pos"] = _clamp_world(p["pos"] + move * 280.0 * delta)
    p["pos"].y = clamp(p["pos"].y, map_h * 0.68, map_h - cell_px)
    p["cooldown"] = max(0.0, p["cooldown"] - delta)
    if _shoot_pressed(0) and p["cooldown"] <= 0.0:
        bullets.append({"pos": p["pos"] + Vector2(0, -18), "vel": Vector2(0, -520), "ttl": 1.8})
        p["cooldown"] = 0.18
    _tick_bullets(delta)
    var prev_positions = []
    for seg in centipede:
        prev_positions.append(seg["pos"])
    for i in range(centipede.size()):
        var seg = centipede[i]
        if i == 0:
            var next = seg["pos"] + seg["dir"] * (95.0 + wave * 8.0) * delta
            var hit_side = next.x < cell_px or next.x > map_w - cell_px
            var hit_barrier = _barrier_at(next) != -1
            if hit_side or hit_barrier:
                seg["dir"].x *= -1
                next.y += cell_px * 0.55
            seg["pos"] = _clamp_world(next)
        else:
            seg["pos"] = seg["pos"].lerp(prev_positions[i - 1], min(1.0, delta * 7.0))
        if seg["pos"].distance_to(p["pos"]) < 24.0:
            _lose_life()
    for bi in range(bullets.size() - 1, -1, -1):
        var b = bullets[bi]
        for si in range(centipede.size() - 1, -1, -1):
            if b["pos"].distance_to(centipede[si]["pos"]) < 20.0:
                _burst(centipede[si]["pos"], NEON_MAGENTA, 18)
                centipede.remove_at(si)
                bullets.remove_at(bi)
                score += 100
                _emit_score(1)
                break
        if bi < bullets.size():
            var hit = _barrier_at(b["pos"])
            if hit != -1:
                barriers[hit]["hp"] -= 1
                if barriers[hit]["hp"] <= 0:
                    _burst(barriers[hit]["pos"], NEON_GREEN, 10)
                    barriers.remove_at(hit)
                bullets.remove_at(bi)
                score += 5
    if centipede.is_empty():
        wave += 1
        _setup_centipede()

func _tick_invaders(delta):
    var p = players[0]
    var move = _input_vector(0)
    p["pos"].x = clamp(p["pos"].x + move.x * 330.0 * delta, cell_px, map_w - cell_px)
    p["pos"].y = clamp(p["pos"].y, map_h * 0.76, map_h - cell_px)
    p["cooldown"] = max(0.0, p["cooldown"] - delta)
    if _shoot_pressed(0) and p["cooldown"] <= 0.0:
        bullets.append({"pos": p["pos"] + Vector2(0, -22), "vel": Vector2(0, -600), "ttl": 1.6})
        if dual_ship:
            bullets.append({"pos": p["pos"] + Vector2(-24, -18), "vel": Vector2(0, -600), "ttl": 1.6})
            bullets.append({"pos": p["pos"] + Vector2(24, -18), "vel": Vector2(0, -600), "ttl": 1.6})
        p["cooldown"] = 0.22
    invader_step_timer += delta
    var shift = false
    var min_x = map_w
    var max_x = 0.0
    for e in enemies:
        if not e["alive"]:
            continue
        if game_id == "galaga":
            e["phase"] += delta * 2.0
            e["pos"].x += sin(e["phase"]) * 28.0 * delta
            if e["kind"] == "boss" and randf() < delta * 0.08:
                e["pos"].y += 18.0
        min_x = min(min_x, e["pos"].x)
        max_x = max(max_x, e["pos"].x)
    if invader_step_timer > 0.42:
        invader_step_timer = 0.0
        shift = true
    if shift:
        if min_x < cell_px * 2 or max_x > map_w - cell_px * 2:
            invader_dir *= -1
            for e in enemies:
                e["pos"].y += 22
        for e in enemies:
            e["pos"].x += invader_dir * (20 + wave * 2)
            if e["pos"].y > map_h * 0.78:
                _lose_life()
    fire_timer -= delta
    if fire_timer <= 0.0:
        fire_timer = randf_range(0.35, 0.9)
        var live = []
        for e in enemies:
            if e["alive"]:
                live.append(e)
        if live.size() > 0:
            var shooter = live[randi() % live.size()]
            enemy_bullets.append({"pos": shooter["pos"], "vel": Vector2(0, 260 + wave * 12), "ttl": 2.8})
    _tick_bullets(delta)
    _tick_enemy_bullets(delta)
    for bi in range(bullets.size() - 1, -1, -1):
        var b = bullets[bi]
        var consumed = false
        for ei in range(enemies.size() - 1, -1, -1):
            var e = enemies[ei]
            if e["alive"] and b["pos"].distance_to(e["pos"]) < 22.0:
                _burst(e["pos"], NEON_ORANGE if e["kind"] == "boss" else NEON_MAGENTA, 20)
                if e["kind"] == "boss":
                    dual_ship = true
                enemies.remove_at(ei)
                bullets.remove_at(bi)
                score += 220 if e["kind"] == "boss" else 50
                _emit_score(1)
                consumed = true
                break
        if consumed:
            continue
        var hit = _barrier_at(b["pos"])
        if hit != -1:
            barriers.remove_at(hit)
            bullets.remove_at(bi)
    for eb in enemy_bullets:
        if eb["pos"].distance_to(p["pos"]) < 20.0:
            _lose_life()
            break
    if enemies.is_empty():
        wave += 1
        _setup_invaders()

func _tick_robotron_2084(delta):
    var p = players[0]
    var move = _input_vector(0)
    p["pos"] = _safe_position(p["pos"] + move * 300.0 * delta)
    p["cooldown"] = max(0.0, p["cooldown"] - delta)
    var shot = _shoot_vector(0)
    if shot != Vector2.ZERO and p["cooldown"] <= 0.0:
        bullets.append({"pos": p["pos"], "vel": shot.normalized() * 540.0, "ttl": 1.1})
        p["cooldown"] = 0.12
    _tick_bullets(delta)
    for e in enemies:
        var dir = (p["pos"] - e["pos"]).normalized()
        e["pos"] = _safe_position(e["pos"] + dir * e["speed"] * delta)
        if e["pos"].distance_to(p["pos"]) < 23.0:
            _lose_life()
    for bi in range(bullets.size() - 1, -1, -1):
        for ei in range(enemies.size() - 1, -1, -1):
            if bullets[bi]["pos"].distance_to(enemies[ei]["pos"]) < 22.0:
                _burst(enemies[ei]["pos"], NEON_RED, 16)
                enemies.remove_at(ei)
                bullets.remove_at(bi)
                score += 25
                _emit_score(1)
                break
        if bi >= bullets.size():
            continue
    for pi in range(pickups.size() - 1, -1, -1):
        if p["pos"].distance_to(pickups[pi]["pos"]) < 26.0:
            _burst(pickups[pi]["pos"], NEON_GREEN, 12)
            pickups.remove_at(pi)
            score += 100
            _emit_score(1)
    spawn_timer -= delta
    if spawn_timer <= 0.0 and enemies.size() < 18:
        spawn_timer = 1.6
        enemies.append({"pos": _spawn_far_from(p["pos"]), "speed": randf_range(80, 130), "alive": true})

func _tick_burger(delta):
    var p = players[0]
    var move = _input_vector(0)
    p["pos"] += Vector2(move.x * 220.0, move.y * 160.0) * delta
    p["pos"] = _snap_burger_position(p["pos"])
    for ing in ingredients:
        if ing["done"]:
            continue
        if Rect2(ing["rect"].position - Vector2(0, 18), ing["rect"].size + Vector2(0, 36)).has_point(p["pos"]):
            ing["walk"] += delta
            if ing["walk"] > 0.35:
                ing["fall"] = min(140.0, ing["fall"] + 260.0 * delta)
                ing["rect"].position.y += ing["fall"] * delta
                if ing["rect"].position.y > map_h * 0.88:
                    ing["done"] = true
                    score += 150
                    _emit_score(1)
                for ei in range(enemies.size() - 1, -1, -1):
                    if ing["rect"].has_point(enemies[ei]["pos"]):
                        _burst(enemies[ei]["pos"], NEON_ORANGE, 18)
                        enemies.remove_at(ei)
                        score += 200
    for e in enemies:
        var dir = (p["pos"] - e["pos"]).normalized()
        e["pos"] = _snap_burger_position(e["pos"] + dir * e["speed"] * delta)
        if e["pos"].distance_to(p["pos"]) < 22.0:
            _lose_life()
    if enemies.is_empty():
        for i in range(4):
            enemies.append({"pos": Vector2(map_w * randf_range(0.2, 0.8), map_h * 0.3), "speed": 85.0, "alive": true})
    var all_done = true
    for ing in ingredients:
        if not ing["done"]:
            all_done = false
    if all_done:
        _win_round()

func _tick_missile_command(delta):
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        spawn_timer = max(0.18, 1.1 - wave * 0.05)
        var targets = []
        for c in cities:
            if c["alive"]:
                targets.append(c["pos"])
        for s in silos:
            targets.append(s["pos"])
        if targets.size() > 0:
            var target = targets[randi() % targets.size()]
            missiles.append({"from": Vector2(randf() * map_w, -10), "pos": Vector2(randf() * map_w, -10), "target": target, "speed": randf_range(70, 120) + wave * 4, "enemy": true})
    if _shoot_pressed(0):
        _fire_counter_missile(aim_pos)
    for mi in range(missiles.size() - 1, -1, -1):
        var m = missiles[mi]
        var dir = (m["target"] - m["pos"])
        var step = m["speed"] * delta
        if dir.length() <= step:
            explosions.append({"pos": m["target"], "r": 2.0, "max": 72.0 if m["enemy"] else 96.0, "life": 0.75, "enemy": m["enemy"]})
            missiles.remove_at(mi)
        else:
            m["pos"] += dir.normalized() * step
    for ex in explosions:
        ex["r"] = min(ex["max"], ex["r"] + ex["max"] * 1.7 * delta)
        ex["life"] -= delta
    for i in range(explosions.size() - 1, -1, -1):
        if explosions[i]["life"] <= 0:
            explosions.remove_at(i)
    for ex in explosions:
        if not ex["enemy"]:
            for mi in range(missiles.size() - 1, -1, -1):
                if missiles[mi]["enemy"] and missiles[mi]["pos"].distance_to(ex["pos"]) < ex["r"]:
                    score += 35
                    _emit_score(1)
                    _burst(missiles[mi]["pos"], NEON_YELLOW, 10)
                    missiles.remove_at(mi)
        else:
            for c in cities:
                if c["alive"] and c["pos"].distance_to(ex["pos"]) < ex["r"] * 0.75:
                    c["alive"] = false
                    _burst(c["pos"], NEON_RED, 20)
    var any_city = false
    for c in cities:
        if c["alive"]:
            any_city = true
    if not any_city:
        _game_over()

func _tick_defender(delta):
    var p = players[0]
    var move = _input_vector(0)
    p["pos"] += move * 330.0 * delta
    p["pos"].x = wrapf(p["pos"].x, 0.0, map_w)
    p["pos"].y = clamp(p["pos"].y, cell_px, map_h * 0.72)
    p["cooldown"] = max(0.0, p["cooldown"] - delta)
    if _shoot_pressed(0) and p["cooldown"] <= 0.0:
        var dir = -1.0 if move.x < -0.1 else 1.0
        bullets.append({"pos": p["pos"], "vel": Vector2(620.0 * dir, 0), "ttl": 1.0})
        p["cooldown"] = 0.16
    _tick_bullets(delta, true)
    for e in enemies:
        var target = p["pos"]
        if pickups.size() > 0 and e["carry"] == -1:
            target = pickups[0]["pos"]
        e["pos"] = _wrap_world(e["pos"] + (target - e["pos"]).normalized() * e["speed"] * delta)
        if e["pos"].distance_to(p["pos"]) < 24.0:
            _lose_life()
    for bi in range(bullets.size() - 1, -1, -1):
        for ei in range(enemies.size() - 1, -1, -1):
            if bullets[bi]["pos"].distance_to(enemies[ei]["pos"]) < 24.0:
                _burst(enemies[ei]["pos"], NEON_MAGENTA, 15)
                enemies.remove_at(ei)
                bullets.remove_at(bi)
                score += 80
                _emit_score(1)
                break
        if bi >= bullets.size():
            continue
    for pi in range(pickups.size() - 1, -1, -1):
        if pickups[pi]["pos"].distance_to(p["pos"]) < 28.0:
            pickups.remove_at(pi)
            score += 150
            _emit_score(1)
    if enemies.is_empty():
        wave += 1
        _setup_defender()

func _tick_lunar(delta):
    var thrust = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_A)
    var left = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
    var right = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
    if left:
        lander["angle"] -= 2.6 * delta
    if right:
        lander["angle"] += 2.6 * delta
    lander["vel"].y += 78.0 * delta
    if thrust and lander["fuel"] > 0.0:
        var force = Vector2(sin(lander["angle"]), -cos(lander["angle"])) * 190.0
        lander["vel"] += force * delta
        lander["fuel"] = max(0.0, lander["fuel"] - 18.0 * delta)
        _burst(lander["pos"] + Vector2(0, 16), NEON_ORANGE, 1)
    lander["pos"] += lander["vel"] * delta
    lander["pos"] = _clamp_world(lander["pos"])
    var landed = false
    for pad in pads:
        if pad.grow(14).has_point(lander["pos"] + Vector2(0, 18)):
            landed = true
            if abs(lander["vel"].y) < 55.0 and abs(lander["vel"].x) < 35.0 and abs(lander["angle"]) < 0.35:
                score += int(500 + lander["fuel"] * 5)
                _emit_score(1)
                _win_round()
            else:
                _lose_life()
    if lander["pos"].y >= map_h - 20 and not landed:
        _lose_life()

func _tick_paperboy(delta):
    var p = players[0]
    scroll_y += 155.0 * delta
    var move = _input_vector(0)
    p["pos"].x = clamp(p["pos"].x + move.x * 240.0 * delta, map_w * 0.22, map_w * 0.78)
    p["cooldown"] = max(0.0, p["cooldown"] - delta)
    if _shoot_pressed(0) and p["cooldown"] <= 0.0:
        var dir = -1 if p["pos"].x > map_w * 0.5 else 1
        papers.append({"pos": p["pos"] + Vector2(20 * dir, -8), "vel": Vector2(360 * dir, -120), "ttl": 1.2})
        p["cooldown"] = 0.25
    for pa_i in range(papers.size() - 1, -1, -1):
        papers[pa_i]["pos"] += papers[pa_i]["vel"] * delta
        papers[pa_i]["ttl"] -= delta
        if papers[pa_i]["ttl"] <= 0:
            papers.remove_at(pa_i)
    for h in houses:
        var hp = h["pos"] + Vector2(0, scroll_y)
        if hp.y > map_h + 80:
            h["pos"].y -= 2000.0
            h["hit"] = false
        for pi in range(papers.size() - 1, -1, -1):
            if hp.distance_to(papers[pi]["pos"]) < 45.0:
                if h["subscriber"] and not h["hit"]:
                    score += 100
                    h["hit"] = true
                    _emit_score(1)
                    _burst(hp, NEON_GREEN, 14)
                elif not h["subscriber"]:
                    score = max(0, score - 50)
                    _emit_score(1)
                    _burst(hp, NEON_RED, 10)
                papers.remove_at(pi)
    for m in road_markers:
        var rp = m["pos"] + Vector2(0, scroll_y)
        if rp.y > map_h + 40:
            m["pos"].y -= 1800.0
        if rp.distance_to(p["pos"]) < 22.0:
            _lose_life()

func _tick_qbert(delta):
    state_timer -= delta
    if state_timer <= 0.0:
        var dir = Vector2i.ZERO
        if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
            dir = Vector2i(1, 1)
        elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
            dir = Vector2i(-1, -1)
        elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
            dir = Vector2i(-1, 0)
        elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
            dir = Vector2i(1, 0)
        if dir != Vector2i.ZERO:
            var nr = cube_player.x + dir.x
            var nc = cube_player.y + dir.y
            if _cube_exists(nr, nc):
                cube_player = Vector2i(nr, nc)
                state_timer = 0.16
                for c in cubes:
                    if c["rc"] == cube_player and not c["lit"]:
                        c["lit"] = true
                        score += 25
                        _emit_score(1)
    for e in enemies:
        e["timer"] -= delta
        if e["timer"] <= 0.0:
            e["timer"] = randf_range(0.35, 0.8)
            var rc = e["rc"]
            var opts = [Vector2i(rc.x + 1, rc.y), Vector2i(rc.x + 1, rc.y + 1), Vector2i(rc.x - 1, rc.y), Vector2i(rc.x - 1, rc.y - 1)]
            var valid = []
            for o in opts:
                if _cube_exists(o.x, o.y):
                    valid.append(o)
            if valid.size() > 0:
                e["rc"] = valid[randi() % valid.size()]
        if e["rc"] == cube_player:
            _lose_life()
    var all_lit = true
    for c in cubes:
        if not c["lit"]:
            all_lit = false
    if all_lit:
        _win_round()

func _tick_bullets(delta, wrap := false):
    for i in range(bullets.size() - 1, -1, -1):
        bullets[i]["pos"] += bullets[i]["vel"] * delta
        if wrap:
            bullets[i]["pos"] = _wrap_world(bullets[i]["pos"])
        bullets[i]["ttl"] -= delta
        var out = bullets[i]["pos"].y < -60 or bullets[i]["pos"].y > map_h + 60 or bullets[i]["pos"].x < -80 or bullets[i]["pos"].x > map_w + 80
        if bullets[i]["ttl"] <= 0.0 or (out and not wrap):
            bullets.remove_at(i)

func _tick_enemy_bullets(delta):
    for i in range(enemy_bullets.size() - 1, -1, -1):
        enemy_bullets[i]["pos"] += enemy_bullets[i]["vel"] * delta
        enemy_bullets[i]["ttl"] -= delta
        var hit = _barrier_at(enemy_bullets[i]["pos"])
        if hit != -1:
            barriers.remove_at(hit)
            enemy_bullets.remove_at(i)
        elif enemy_bullets[i]["ttl"] <= 0.0 or enemy_bullets[i]["pos"].y > map_h + 60:
            enemy_bullets.remove_at(i)

func _tick_particles(delta):
    for i in range(particles.size() - 1, -1, -1):
        particles[i]["pos"] += particles[i]["vel"] * delta
        particles[i]["life"] -= delta
        if particles[i]["life"] <= 0.0:
            particles.remove_at(i)

func _draw():
    if blanked:
        return
    draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))
    if show_reference and reference_texture:
        draw_texture_rect(reference_texture, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, 0.15))
    _draw_arena_frame()
    if game_id == "centipede":
        _draw_centipede()
    elif game_id == "space_invaders" or game_id == "galaga":
        _draw_invaders()
    elif game_id == "robotron_2084":
        _draw_robotron_2084()
    elif game_id == "burger_time":
        _draw_burger()
    elif game_id == "missile_command":
        _draw_missile_command()
    elif game_id == "defender":
        _draw_defender()
    elif game_id == "lunar_lander":
        _draw_lunar()
    elif game_id == "paperboy":
        _draw_paperboy()
    elif game_id == "qbert":
        _draw_qbert()
    for p in particles:
        var a = max(0.0, p["life"] / p["max"])
        draw_circle(p["pos"], 3.0 + 8.0 * a, Color(p["color"].r, p["color"].g, p["color"].b, a * 0.65))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_hud()

func _draw_arena_frame():
    var grid_step = cell_px * 2.0
    for x in range(0, int(map_w), int(grid_step)):
        draw_line(Vector2(x, 0), Vector2(x, map_h), Color(1, 1, 1, 0.035), 1.0)
    for y in range(0, int(map_h), int(grid_step)):
        draw_line(Vector2(0, y), Vector2(map_w, y), Color(1, 1, 1, 0.035), 1.0)
    draw_rect(Rect2(0, 0, map_w, map_h), Color(1, 1, 1, 0.55), false, 1.0)

func _draw_centipede():
    for b in barriers:
        _draw_mushroom(b["pos"], NEON_GREEN)
    for b in bullets:
        _glow_line(b["pos"] + Vector2(0, 12), b["pos"] - Vector2(0, 12), NEON_YELLOW, 2.0)
    for i in range(centipede.size()):
        _draw_centipede_segment(centipede[i]["pos"], i == 0)
    _draw_player_ship(players[0]["pos"], NEON_CYAN)

func _draw_invaders():
    for b in barriers:
        draw_rect(Rect2(b["pos"] - Vector2(18, 10), Vector2(36, 20)), Color(0.0, 0.9, 1.0, 0.18), true)
        draw_rect(Rect2(b["pos"] - Vector2(18, 10), Vector2(36, 20)), NEON_CYAN, false, 1.0)
    for e in enemies:
        _draw_alien(e["pos"], NEON_ORANGE if e["kind"] == "boss" else NEON_MAGENTA)
    for b in bullets:
        _glow_line(b["pos"], b["pos"] - Vector2(0, 18), NEON_YELLOW, 2.0)
    for b in enemy_bullets:
        _glow_line(b["pos"], b["pos"] + Vector2(0, 16), NEON_RED, 2.0)
    _draw_player_ship(players[0]["pos"], NEON_CYAN)
    if dual_ship:
        _draw_player_ship(players[0]["pos"] + Vector2(28, 0), NEON_GREEN)

func _draw_robotron_2084():
    for h in pickups:
        _draw_human(h["pos"], NEON_GREEN, 0.72)
    for e in enemies:
        _draw_robot(e["pos"], NEON_RED)
    for b in bullets:
        _glow_circle(b["pos"], 4.0, NEON_YELLOW)
    _draw_twin_stick_hero(players[0]["pos"], NEON_CYAN)

func _draw_burger():
    for p in platforms:
        _glow_line(p.position, p.position + Vector2(p.size.x, 0), NEON_CYAN, 3.0)
    for l in ladders:
        _glow_line(l.position, l.position + Vector2(0, l.size.y), NEON_GREEN, 2.0)
    for ing in ingredients:
        var col = NEON_YELLOW if not ing["done"] else INK_DIM
        _draw_burger_layer(ing["rect"], col)
    for e in enemies:
        _draw_food_enemy(e["pos"], NEON_ORANGE)
    _draw_chef(players[0]["pos"], NEON_CYAN)

func _draw_missile_command():
    for c in cities:
        var col = NEON_GREEN if c["alive"] else INK_DIM
        _draw_city(c["pos"], col)
    for s in silos:
        _draw_triangle(s["pos"] + Vector2(0, -24), 30.0, NEON_CYAN)
    for m in missiles:
        _glow_line(m["from"], m["pos"], NEON_RED if m["enemy"] else NEON_CYAN, 2.0)
    for ex in explosions:
        _glow_circle_outline(ex["pos"], ex["r"], NEON_ORANGE if ex["enemy"] else NEON_YELLOW, 3.0)
    _glow_circle_outline(aim_pos, 16.0, NEON_CYAN, 1.5)

func _draw_defender():
    draw_line(Vector2(0, map_h * 0.82), Vector2(map_w, map_h * 0.82), Color(1, 1, 1, 0.3), 1.0)
    for h in pickups:
        _draw_human(h["pos"], NEON_GREEN, 0.58)
    for e in enemies:
        _draw_alien(e["pos"], NEON_MAGENTA)
    for b in bullets:
        _glow_line(b["pos"] - Vector2(12, 0), b["pos"] + Vector2(12, 0), NEON_YELLOW, 2.0)
    _draw_player_ship(players[0]["pos"], NEON_CYAN, true)
    draw_rect(Rect2(18, 18, map_w * 0.18, 40), Color(1, 1, 1, 0.08), true)
    for e in enemies:
        draw_circle(Vector2(18 + e["pos"].x / map_w * map_w * 0.18, 38), 3, NEON_MAGENTA)
    draw_circle(Vector2(18 + players[0]["pos"].x / map_w * map_w * 0.18, 38), 4, NEON_CYAN)

func _draw_lunar():
    for pad in pads:
        _glow_line(pad.position, pad.position + Vector2(pad.size.x, 0), NEON_GREEN, 4.0)
    for c in solid_cells:
        if c.y > grid_h * 0.65:
            var r = Rect2(_cell_center(c) - Vector2(cell_px * 0.5, cell_px * 0.5), Vector2(cell_px, cell_px))
            draw_rect(r, Color(1, 1, 1, 0.06), true)
            draw_rect(r, Color(1, 1, 1, 0.22), false, 1.0)
    _draw_lander()

func _draw_paperboy():
    var road_x = map_w * 0.5
    draw_polygon(PackedVector2Array([Vector2(road_x - 110, 0), Vector2(road_x + 110, 0), Vector2(road_x + 180, map_h), Vector2(road_x - 180, map_h)]), PackedColorArray([Color(0, 0.9, 1, 0.08)]))
    for h in houses:
        var hp = h["pos"] + Vector2(0, scroll_y)
        if hp.y > -80 and hp.y < map_h + 80:
            var col = NEON_GREEN if h["subscriber"] else INK_DIM
            if h["hit"]:
                col = NEON_YELLOW
            _draw_house(hp, col)
    for m in road_markers:
        var rp = m["pos"] + Vector2(0, scroll_y)
        if rp.y > -20 and rp.y < map_h + 20:
            _glow_circle(rp, 7.0, NEON_ORANGE)
    for p in papers:
        _glow_line(p["pos"] - Vector2(8, 3), p["pos"] + Vector2(8, 3), NEON_YELLOW, 2.0)
    _draw_bicycle_rider(players[0]["pos"], NEON_CYAN)

func _draw_qbert():
    for c in cubes:
        var pos = _cube_screen(c["rc"])
        var col = NEON_YELLOW if c["lit"] else NEON_CYAN
        var pts = PackedVector2Array([pos + Vector2(0, -20), pos + Vector2(34, 0), pos + Vector2(0, 20), pos + Vector2(-34, 0)])
        draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.16))
        for i in range(4):
            _glow_line(pts[i], pts[(i + 1) % 4], col, 1.5)
    _draw_hopper(_cube_screen(cube_player) + Vector2(0, -28), NEON_GREEN)
    for e in enemies:
        _draw_hopper_enemy(_cube_screen(e["rc"]) + Vector2(0, -26), NEON_RED)

func _draw_hud():
    var font = ThemeDB.fallback_font
    draw_string(font, Vector2(18, 34), game_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(font, Vector2(18, 64), "SCORE " + str(score) + "  LIVES " + str(lives), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, NEON_CYAN)
    if game_id == "lunar_lander":
        draw_string(font, Vector2(18, 94), "FUEL " + str(int(lander.get("fuel", 0))) + "  VEL " + str(int(lander.get("vel", Vector2.ZERO).length())), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, NEON_YELLOW)
    if paused:
        draw_string(font, get_viewport_rect().size * 0.5, "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, -1, 46, Color.WHITE)
    elif game_state == "game_over":
        draw_string(font, get_viewport_rect().size * 0.5, "GAME OVER - ENTER", HORIZONTAL_ALIGNMENT_CENTER, -1, 44, NEON_RED)
    elif game_state == "win":
        draw_string(font, get_viewport_rect().size * 0.5, "ROUND CLEAR - ENTER", HORIZONTAL_ALIGNMENT_CENTER, -1, 44, NEON_GREEN)

func _input_vector(player_idx: int) -> Vector2:
    var v = Vector2.ZERO
    if player_idx == 0:
        v.x = Input.get_axis("ui_left", "ui_right")
        v.y = Input.get_axis("ui_up", "ui_down")
        if Input.is_key_pressed(KEY_A):
            v.x -= 1
        if Input.is_key_pressed(KEY_D):
            v.x += 1
        if Input.is_key_pressed(KEY_W):
            v.y -= 1
        if Input.is_key_pressed(KEY_S):
            v.y += 1
    var joy = Vector2(Input.get_joy_axis(SharedLoader.get_joy_id(player_idx), JOY_AXIS_LEFT_X), Input.get_joy_axis(SharedLoader.get_joy_id(player_idx), JOY_AXIS_LEFT_Y))
    if joy.length() > 0.25:
        v = joy
    return v.normalized() if v.length() > 1.0 else v

func _shoot_vector(player_idx: int) -> Vector2:
    var v = Vector2.ZERO
    if player_idx == 0:
        if Input.is_key_pressed(KEY_J):
            v.x -= 1
        if Input.is_key_pressed(KEY_L):
            v.x += 1
        if Input.is_key_pressed(KEY_I):
            v.y -= 1
        if Input.is_key_pressed(KEY_K):
            v.y += 1
        if v == Vector2.ZERO and _shoot_pressed(0):
            v = Vector2.UP
    var joy = Vector2(Input.get_joy_axis(SharedLoader.get_joy_id(player_idx), JOY_AXIS_RIGHT_X), Input.get_joy_axis(SharedLoader.get_joy_id(player_idx), JOY_AXIS_RIGHT_Y))
    if joy.length() > 0.35:
        v = joy
    return v

func _shoot_pressed(player_idx: int) -> bool:
    return Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(player_idx), JOY_BUTTON_A)

func _safe_position(pos: Vector2) -> Vector2:
    var clamped = _clamp_world(pos)
    if _cell_walkable(_pos_to_cell(clamped)):
        return clamped
    var cell = _find_nearest_walkable_cell(_pos_to_cell(clamped))
    return _cell_center(cell)

func _spawn_far_from(pos: Vector2) -> Vector2:
    var best = pos
    var best_d = -1.0
    for i in range(min(80, walkable_cells.size())):
        var c = walkable_cells[randi() % walkable_cells.size()]
        var p = _cell_center(c)
        var d = p.distance_squared_to(pos)
        if d > best_d:
            best_d = d
            best = p
    return best

func _find_nearest_walkable_cell(start: Vector2i) -> Vector2i:
    if walkable_cells.is_empty():
        return Vector2i(clamp(start.x, 0, max(0, grid_w - 1)), clamp(start.y, 0, max(0, grid_h - 1)))
    var clamped = Vector2i(clamp(start.x, 0, grid_w - 1), clamp(start.y, 0, grid_h - 1))
    if _cell_walkable(clamped):
        return clamped
    var visited = {}
    var queue = [clamped]
    visited[clamped] = true
    var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    while queue.size() > 0:
        var cur = queue.pop_front()
        for d in dirs:
            var nxt = cur + d
            if nxt.x < 0 or nxt.y < 0 or nxt.x >= grid_w or nxt.y >= grid_h or visited.has(nxt):
                continue
            if _cell_walkable(nxt):
                return nxt
            visited[nxt] = true
            queue.append(nxt)
    return walkable_cells[0]

func _cell_walkable(cell: Vector2i) -> bool:
    if cell.y < 0 or cell.y >= grid_cells.size():
        return false
    var row = grid_cells[cell.y]
    if cell.x < 0 or cell.x >= row.size():
        return false
    return int(row[cell.x]) != 1

func _pos_to_cell(pos: Vector2) -> Vector2i:
    return Vector2i(int(pos.x / cell_px), int(pos.y / cell_px))

func _cell_center(cell: Vector2i) -> Vector2:
    return Vector2((cell.x + 0.5) * cell_px, (cell.y + 0.5) * cell_px)

func _clamp_world(pos: Vector2) -> Vector2:
    return Vector2(clamp(pos.x, 0.0, map_w), clamp(pos.y, 0.0, map_h))

func _wrap_world(pos: Vector2) -> Vector2:
    return Vector2(wrapf(pos.x, 0.0, map_w), clamp(pos.y, 0.0, map_h))

func _screen_to_world(pos: Vector2) -> Vector2:
    return (pos - offset) / max(scale_factor, 0.0001)

func _barrier_at(pos: Vector2) -> int:
    for i in range(barriers.size()):
        if barriers[i]["pos"].distance_to(pos) < 22.0:
            return i
    return -1

func _snap_burger_position(pos: Vector2) -> Vector2:
    var on_ladder = false
    for l in ladders:
        if abs(pos.x - l.position.x) < 22 and pos.y >= l.position.y and pos.y <= l.position.y + l.size.y:
            on_ladder = true
            pos.x = l.position.x
    if not on_ladder:
        var best_y = platforms[0].position.y
        var best_d = 99999.0
        for p in platforms:
            var d = abs(pos.y - p.position.y)
            if d < best_d:
                best_d = d
                best_y = p.position.y
        pos.y = best_y
    pos.x = clamp(pos.x, map_w * 0.1, map_w * 0.9)
    pos.y = clamp(pos.y, map_h * 0.18, map_h * 0.9)
    return pos

func _fire_counter_missile(target: Vector2):
    for s in silos:
        if s["ammo"] > 0:
            s["ammo"] -= 1
            missiles.append({"from": s["pos"], "pos": s["pos"], "target": _clamp_world(target), "speed": 420.0, "enemy": false})
            return

func _cube_exists(r: int, c: int) -> bool:
    return r >= 0 and r < 7 and c >= 0 and c <= r

func _cube_screen(rc: Vector2i) -> Vector2:
    var top = Vector2(map_w * 0.5, map_h * 0.16)
    return top + Vector2((rc.y - rc.x * 0.5) * 72.0, rc.x * 44.0)

func _lose_life():
    if game_state != "playing":
        return
    lives -= 1
    _burst(players[0]["pos"] if players.size() > 0 else Vector2(map_w * 0.5, map_h * 0.5), NEON_RED, 26)
    if lives <= 0:
        _game_over()
    else:
        _reset_after_hit()

func _reset_after_hit():
    if players.size() > 0:
        players[0]["pos"] = _safe_position(Vector2(map_w * 0.5, map_h * 0.82))
    if game_id == "lunar_lander":
        lander["pos"] = Vector2(map_w * 0.5, map_h * 0.16)
        lander["vel"] = Vector2.ZERO
        lander["angle"] = 0.0
    send_ipc_message({"type": "state", "data": {"state": "life_lost", "lives": lives}})

func _game_over():
    game_state = "game_over"
    send_ipc_message({"type": "state", "data": {"state": "game_over"}})

func _win_round():
    game_state = "win"
    send_ipc_message({"type": "state", "data": {"state": "win"}})

func _emit_score(player: int):
    send_ipc_message({"type": "score", "data": {"player": player, "score": score}})

func _burst(pos: Vector2, color: Color, count: int):
    for i in range(count):
        var a = randf() * TAU
        var speed = randf_range(40, 230)
        particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * speed, "life": randf_range(0.25, 0.65), "max": 0.65, "color": color})

func _glow_line(a: Vector2, b: Vector2, color: Color, width: float):
    draw_line(a, b, Color(color.r, color.g, color.b, 0.24), width * 5.0)
    draw_line(a, b, Color(color.r, color.g, color.b, 0.72), width * 2.0)
    draw_line(a, b, Color.WHITE, max(1.0, width * 0.45))

func _glow_circle(pos: Vector2, r: float, color: Color):
    draw_circle(pos, r * 2.1, Color(color.r, color.g, color.b, 0.16))
    draw_circle(pos, r * 1.35, Color(color.r, color.g, color.b, 0.42))
    draw_circle(pos, r, Color(color.r, color.g, color.b, 0.95))
    draw_arc(pos, r, 0, TAU, 24, Color.WHITE, 1.1)

func _glow_circle_outline(pos: Vector2, r: float, color: Color, width: float):
    draw_arc(pos, r, 0, TAU, 48, Color(color.r, color.g, color.b, 0.22), width * 5.0)
    draw_arc(pos, r, 0, TAU, 48, Color(color.r, color.g, color.b, 0.75), width * 2.0)
    draw_arc(pos, r, 0, TAU, 48, Color.WHITE, max(1.0, width * 0.45))

func _draw_player_ship(pos: Vector2, color: Color, horizontal := false):
    var pts: PackedVector2Array
    if horizontal:
        pts = PackedVector2Array([pos + Vector2(24, 0), pos + Vector2(-18, -14), pos + Vector2(-9, 0), pos + Vector2(-18, 14)])
    else:
        pts = PackedVector2Array([pos + Vector2(0, -24), pos + Vector2(-16, 18), pos + Vector2(0, 9), pos + Vector2(16, 18)])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.18))
    for i in range(pts.size()):
        _glow_line(pts[i], pts[(i + 1) % pts.size()], color, 1.5)

func _draw_triangle(pos: Vector2, size: float, color: Color):
    var pts = PackedVector2Array([pos + Vector2(0, -size), pos + Vector2(-size * 0.7, size * 0.6), pos + Vector2(size * 0.7, size * 0.6)])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.14))
    for i in range(3):
        _glow_line(pts[i], pts[(i + 1) % 3], color, 1.5)

func _draw_alien(pos: Vector2, color: Color):
    var body = PackedVector2Array([
        pos + Vector2(0, -17),
        pos + Vector2(-19, -4),
        pos + Vector2(-12, 14),
        pos + Vector2(12, 14),
        pos + Vector2(19, -4)
    ])
    draw_colored_polygon(body, Color(color.r, color.g, color.b, 0.14))
    for i in range(body.size()):
        _glow_line(body[i], body[(i + 1) % body.size()], color, 1.3)
    _glow_line(pos + Vector2(-24, 5), pos + Vector2(-35, 15), color, 1.0)
    _glow_line(pos + Vector2(24, 5), pos + Vector2(35, 15), color, 1.0)
    draw_circle(pos + Vector2(-6, -2), 2.5, Color.WHITE)
    draw_circle(pos + Vector2(6, -2), 2.5, Color.WHITE)

func _draw_robot(pos: Vector2, color: Color):
    var head = Rect2(pos + Vector2(-10, -20), Vector2(20, 14))
    var body = Rect2(pos + Vector2(-14, -4), Vector2(28, 25))
    draw_rect(head, Color(color.r, color.g, color.b, 0.16), true)
    draw_rect(head, color, false, 1.5)
    draw_rect(body, Color(color.r, color.g, color.b, 0.14), true)
    draw_rect(body, color, false, 2.0)
    _glow_line(pos + Vector2(-18, 2), pos + Vector2(-28, 12), color, 1.4)
    _glow_line(pos + Vector2(18, 2), pos + Vector2(28, 12), color, 1.4)
    _glow_line(pos + Vector2(-7, 21), pos + Vector2(-12, 30), color, 1.4)
    _glow_line(pos + Vector2(7, 21), pos + Vector2(12, 30), color, 1.4)
    draw_circle(pos + Vector2(-5, -13), 2.3, Color.WHITE)
    draw_circle(pos + Vector2(5, -13), 2.3, Color.WHITE)
    _glow_line(pos + Vector2(-3, -22), pos + Vector2(-8, -29), color, 1.0)
    _glow_line(pos + Vector2(3, -22), pos + Vector2(8, -29), color, 1.0)

func _draw_twin_stick_hero(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 17.0, color, 2.0)
    _glow_line(pos + Vector2(-18, -2), pos + Vector2(-29, -12), color, 1.6)
    _glow_line(pos + Vector2(18, -2), pos + Vector2(29, -12), color, 1.6)
    _glow_line(pos + Vector2(-8, 15), pos + Vector2(-14, 29), color, 1.6)
    _glow_line(pos + Vector2(8, 15), pos + Vector2(14, 29), color, 1.6)
    draw_circle(pos + Vector2(-5, -4), 2.4, Color.WHITE)
    draw_circle(pos + Vector2(5, -4), 2.4, Color.WHITE)

func _draw_human(pos: Vector2, color: Color, scale := 1.0):
    _glow_circle(pos + Vector2(0, -10) * scale, 5.0 * scale, color)
    _glow_line(pos + Vector2(0, -4) * scale, pos + Vector2(0, 12) * scale, color, 1.2 * scale)
    _glow_line(pos + Vector2(-9, 2) * scale, pos + Vector2(9, 2) * scale, color, 1.0 * scale)
    _glow_line(pos + Vector2(0, 12) * scale, pos + Vector2(-7, 22) * scale, color, 1.0 * scale)
    _glow_line(pos + Vector2(0, 12) * scale, pos + Vector2(7, 22) * scale, color, 1.0 * scale)

func _draw_mushroom(pos: Vector2, color: Color):
    draw_arc(pos + Vector2(0, 2), 13.0, PI, TAU, 24, color, 3.0)
    draw_rect(Rect2(pos + Vector2(-5, 2), Vector2(10, 16)), Color(color.r, color.g, color.b, 0.16), true)
    draw_rect(Rect2(pos + Vector2(-5, 2), Vector2(10, 16)), color, false, 1.3)

func _draw_centipede_segment(pos: Vector2, is_head: bool):
    var color = NEON_MAGENTA if is_head else NEON_ORANGE
    _glow_circle(pos, 13.0 if is_head else 11.5, color)
    _glow_line(pos + Vector2(-9, 8), pos + Vector2(-18, 15), color, 1.0)
    _glow_line(pos + Vector2(9, 8), pos + Vector2(18, 15), color, 1.0)
    if is_head:
        draw_circle(pos + Vector2(-5, -4), 2.2, Color.WHITE)
        draw_circle(pos + Vector2(5, -4), 2.2, Color.WHITE)
        _glow_line(pos + Vector2(-5, -12), pos + Vector2(-12, -22), color, 1.0)
        _glow_line(pos + Vector2(5, -12), pos + Vector2(12, -22), color, 1.0)

func _draw_burger_layer(rect: Rect2, color: Color):
    draw_rect(rect, Color(color.r, color.g, color.b, 0.16), true)
    draw_rect(rect, color, false, 2.0)
    var y = rect.position.y + rect.size.y * 0.5
    for x in range(int(rect.position.x + 8), int(rect.position.x + rect.size.x - 4), 18):
        _glow_line(Vector2(x, y), Vector2(x + 9, y + sin(float(x)) * 3.0), color, 0.7)

func _draw_food_enemy(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 14.0, color, 2.0)
    _glow_line(pos + Vector2(-12, 12), pos + Vector2(-18, 22), color, 1.0)
    _glow_line(pos + Vector2(12, 12), pos + Vector2(18, 22), color, 1.0)
    draw_circle(pos + Vector2(-5, -4), 2.1, Color.WHITE)
    draw_circle(pos + Vector2(5, -4), 2.1, Color.WHITE)

func _draw_chef(pos: Vector2, color: Color):
    _glow_circle(pos + Vector2(0, -11), 8.0, color)
    draw_rect(Rect2(pos + Vector2(-10, -2), Vector2(20, 24)), Color(color.r, color.g, color.b, 0.14), true)
    draw_rect(Rect2(pos + Vector2(-10, -2), Vector2(20, 24)), color, false, 1.5)
    _glow_circle(pos + Vector2(-8, -20), 5.0, Color.WHITE)
    _glow_circle(pos + Vector2(0, -23), 6.0, Color.WHITE)
    _glow_circle(pos + Vector2(8, -20), 5.0, Color.WHITE)

func _draw_city(pos: Vector2, color: Color):
    var base = pos + Vector2(-24, -20)
    for i in range(3):
        var h = [24.0, 34.0, 20.0][i]
        var r = Rect2(base + Vector2(i * 16, 34 - h), Vector2(14, h))
        draw_rect(r, Color(color.r, color.g, color.b, 0.14), true)
        draw_rect(r, color, false, 1.2)
        draw_circle(r.position + Vector2(7, 8), 1.8, Color.WHITE)

func _draw_house(pos: Vector2, color: Color):
    var body = Rect2(pos - Vector2(28, 12), Vector2(56, 38))
    var roof = PackedVector2Array([pos + Vector2(-34, -12), pos + Vector2(0, -38), pos + Vector2(34, -12)])
    draw_colored_polygon(roof, Color(color.r, color.g, color.b, 0.16))
    for i in range(3):
        _glow_line(roof[i], roof[(i + 1) % 3], color, 1.2)
    draw_rect(body, Color(color.r, color.g, color.b, 0.12), true)
    draw_rect(body, color, false, 1.4)
    draw_rect(Rect2(pos + Vector2(-6, 4), Vector2(12, 22)), Color(color.r, color.g, color.b, 0.22), true)

func _draw_bicycle_rider(pos: Vector2, color: Color):
    _glow_circle_outline(pos + Vector2(-13, 15), 9.0, color, 1.3)
    _glow_circle_outline(pos + Vector2(13, 15), 9.0, color, 1.3)
    _glow_line(pos + Vector2(-13, 15), pos + Vector2(0, -2), color, 1.2)
    _glow_line(pos + Vector2(13, 15), pos + Vector2(0, -2), color, 1.2)
    _glow_line(pos + Vector2(-4, -8), pos + Vector2(8, -8), color, 1.2)
    _draw_human(pos + Vector2(0, -18), color, 0.55)

func _draw_hopper(pos: Vector2, color: Color):
    _glow_circle(pos, 12.0, color)
    _glow_line(pos + Vector2(-8, 7), pos + Vector2(-18, 18), color, 1.2)
    _glow_line(pos + Vector2(8, 7), pos + Vector2(18, 18), color, 1.2)
    draw_circle(pos + Vector2(-4, -4), 2.0, Color.WHITE)
    draw_circle(pos + Vector2(4, -4), 2.0, Color.WHITE)

func _draw_hopper_enemy(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 12.0, color, 2.0)
    _glow_line(pos + Vector2(-12, -8), pos + Vector2(12, 8), color, 1.2)
    _glow_line(pos + Vector2(12, -8), pos + Vector2(-12, 8), color, 1.2)

func _draw_lander():
    var pos = lander.get("pos", Vector2.ZERO)
    var ang = lander.get("angle", 0.0)
    var pts = PackedVector2Array([
        pos + Vector2(0, -18).rotated(ang),
        pos + Vector2(-15, 14).rotated(ang),
        pos + Vector2(15, 14).rotated(ang)
    ])
    draw_colored_polygon(pts, Color(0, 0.9, 1, 0.12))
    for i in range(3):
        _glow_line(pts[i], pts[(i + 1) % 3], NEON_CYAN, 1.4)
