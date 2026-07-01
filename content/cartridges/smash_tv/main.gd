extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()

const C_CYAN = Color(0.0, 0.9, 1.0)
const C_ORANGE = Color(1.0, 0.48, 0.0)
const C_GREEN = Color(0.0, 0.9, 0.46)
const C_MAGENTA = Color(1.0, 0.18, 0.77)
const C_YELLOW = Color(1.0, 0.83, 0.0)
const C_RED = Color(1.0, 0.08, 0.12)
const C_DIM = Color(0.6, 0.63, 0.65)

var game_id = ""
var title = ""
var level_dir = ""
var ipc_host = "127.0.0.1"
var ipc_port = 0
var ipc_socket: StreamPeerTCP = null
var read_buffer = ""
var heartbeat_timer = 0.0
var ready_sent = false
var paused = false
var blanked = false
var screenshot_path = ""

var map_w = 1280.0
var map_h = 720.0
var cell_px = 32.0
var scale_factor = 1.0
var offset = Vector2.ZERO
var grid = []
var grid_w = 0
var grid_h = 0
var walkable = []
var reference_texture: Texture2D = null
var show_reference = false

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
var tab_cover_frame: PanelContainer
var tab_cover_rect: TextureRect
var tab_menu_shell: BoxContainer
var splash_timer = 1.4

var score = 0
var lives = 3
var wave = 1
var state = "playing"
var player = {"pos": Vector2.ZERO, "vel": Vector2.ZERO, "angle": 0.0, "cool": 0.0, "hp": 100.0}
var enemies = []
var bullets = []
var enemy_bullets = []
var particles = []
var rocks = []
var trails = []
var ball = {"pos": Vector2.ZERO, "vel": Vector2.ZERO}
var left_paddle = 0.5
var right_paddle = 0.5
var ai_cool = 0.0
var last_shot_dir = Vector2.UP

func _ready():
    randomize()
    _identity()
    _parse_args()
    RenderingServer.set_default_clear_color(Color.BLACK)
    _build_ui()
    _connect_ipc()
    load_level()
    reset_game()
    _set_overlay_mode("start")
    if screenshot_path != "":
        await get_tree().create_timer(2.0).timeout
        get_viewport().get_texture().get_image().save_png(screenshot_path)
        get_tree().quit()

func _identity():
    var base = ProjectSettings.globalize_path("res://")
    if base.ends_with("/") or base.ends_with("\\"):
        base = base.substr(0, base.length() - 1)
    game_id = base.get_file()
    var names = {
        "asteroids": "Asteroids",
        "tron": "Tron",
        "pong": "Pong",
        "smash_tv": "Smash TV",
        "battlezone": "Battlezone"
    }
    title = names.get(game_id, game_id.capitalize())

func _parse_args():
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    var i = 0
    while i < args.size():
        var a = str(args[i])
        if a == "--level" and i + 1 < args.size():
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

func _build_ui():
    var bg_layer = CanvasLayer.new()
    bg_layer.layer = -100
    add_child(bg_layer)
    var black = ColorRect.new()
    black.color = Color.BLACK
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg_layer.add_child(black)

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
    tab_menu.color = Color(0, 0, 0, 0.88)
    tab_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_menu.visible = false
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
    tab_cover_frame.custom_minimum_size = Vector2(360, 540)
    tab_cover_frame.visible = false
    tab_cover_frame.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.95, 0.78, 0.22), Color(0.03, 0.03, 0.06, 0.96)))
    tab_menu_shell.add_child(tab_cover_frame)
    tab_cover_rect = TextureRect.new()
    tab_cover_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_cover_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    tab_cover_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tab_cover_rect.texture = splash_rect.texture
    tab_cover_frame.add_child(tab_cover_rect)
    var menu_panel = PanelContainer.new()
    menu_panel.custom_minimum_size = Vector2(520, 360)
    menu_panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.16, 0.55, 1.0), Color(0.01, 0.01, 0.01, 0.92)))
    tab_menu_shell.add_child(menu_panel)
    var center = MarginContainer.new()
    center.add_theme_constant_override("margin_left", 28)
    center.add_theme_constant_override("margin_top", 24)
    center.add_theme_constant_override("margin_right", 28)
    center.add_theme_constant_override("margin_bottom", 24)
    menu_panel.add_child(center)
    var box = VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    center.add_child(box)
    for line in [title, "TAB SETTINGS  F1 REFERENCE  ENTER RESTART", "WASD/ARROWS MOVE  SPACE/CLICK ACTION", "IPC READY SCORE HEARTBEAT LOAD PAUSE RESUME BLANK QUIT"]:
        var label = Label.new()
        label.text = line
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.add_theme_font_size_override("font_size", 30 if line == title else 22)
        label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.24) if line == title else Color.WHITE)
        box.add_child(label)

func _connect_ipc():
    if ipc_port <= 0:
        return
    ipc_socket = StreamPeerTCP.new()
    ipc_socket.connect_to_host(ipc_host, ipc_port)

func load_level():
    grid.clear()
    walkable.clear()
    var loaded = false
    if level_dir != "":
        var path = level_dir.path_join("derived").path_join("grid.json")
        if FileAccess.file_exists(path):
            var f = FileAccess.open(path, FileAccess.READ)
            var json = JSON.new()
            if f and json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
                cell_px = float(json.data.get("cell_px", 32.0))
                grid = json.data.get("cells", [])
                loaded = grid.size() > 0
    if not loaded:
        _load_occupancy()
    if grid.size() == 0:
        _fallback_grid()

    grid_h = grid.size()
    grid_w = 0
    for row in grid:
        grid_w = max(grid_w, row.size())
    map_w = max(640.0, grid_w * cell_px)
    map_h = max(480.0, grid_h * cell_px)
    if level_dir != "":
        var sem = level_dir.path_join("semantic_map.png")
        if FileAccess.file_exists(sem):
            var img = Image.load_from_file(sem)
            if img:
                map_w = img.get_width()
                map_h = img.get_height()
        _load_reference()
    for y in range(grid_h):
        for x in range(grid[y].size()):
            if int(grid[y][x]) != 1:
                walkable.append(Vector2i(x, y))
    _update_scale()

func _load_occupancy():
    if level_dir == "":
        return
    var path = level_dir.path_join("derived").path_join("occupancy.png")
    if not FileAccess.file_exists(path):
        return
    var img = Image.load_from_file(path)
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
        grid.append(row)

func _fallback_grid():
    cell_px = 32.0
    for y in range(22):
        var row = []
        for x in range(36):
            var border = x == 0 or y == 0 or x == 35 or y == 21
            row.append(1 if border else 2)
        grid.append(row)

func _load_reference():
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
            var ref = line.split(":", true, 1)[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
            var p = level_dir.path_join(ref)
            if FileAccess.file_exists(p):
                var img = Image.load_from_file(p)
                if img:
                    reference_texture = ImageTexture.create_from_image(img)

func _update_scale():
    var vp = get_viewport_rect().size
    scale_factor = min(vp.x / map_w, vp.y / map_h)
    offset = Vector2((vp.x - map_w * scale_factor) * 0.5, (vp.y - map_h * scale_factor) * 0.5)

func _notification(what):
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _update_scale()

func reset_game():
    score = 0
    lives = 3
    wave = 1
    state = "playing"
    enemies.clear()
    bullets.clear()
    enemy_bullets.clear()
    particles.clear()
    rocks.clear()
    trails.clear()
    player = {"pos": _safe_pos(Vector2(map_w * 0.5, map_h * 0.5)), "vel": Vector2.ZERO, "angle": -PI * 0.5, "cool": 0.0, "hp": 100.0}
    if game_id == "asteroids":
        _setup_asteroids()
    elif game_id == "tron":
        _setup_tron()
    elif game_id == "pong":
        _setup_pong()
    elif game_id == "smash_tv":
        _setup_smash()
    elif game_id == "battlezone":
        _setup_tank()
    _emit_score()

func _setup_asteroids():
    for i in range(6):
        rocks.append(_make_rock(_spawn_far(player["pos"]), 3))

func _make_rock(pos: Vector2, size: int) -> Dictionary:
    var poly = PackedVector2Array()
    var r = 16.0 + size * 14.0
    for i in range(10):
        var a = TAU * float(i) / 10.0
        poly.append(Vector2(cos(a), sin(a)) * r * randf_range(0.75, 1.2))
    return {"pos": pos, "vel": Vector2.RIGHT.rotated(randf() * TAU) * randf_range(35, 110), "size": size, "r": r, "rot": randf() * TAU, "spin": randf_range(-1.4, 1.4), "poly": poly}

func _setup_tron():
    var c = _find_nearest_walkable_cell(Vector2i(grid_w / 2, grid_h / 2))
    player["cell"] = c
    player["pos"] = _cell_center(c)
    player["dir"] = Vector2i.RIGHT
    player["next"] = Vector2i.RIGHT
    player["step"] = 0.0
    trails.append({"cells": [c], "color": C_CYAN, "alive": true})
    var ecell = _find_nearest_walkable_cell(Vector2i(grid_w / 2, grid_h / 2 + 4))
    enemies.append({"cell": ecell, "pos": _cell_center(ecell), "dir": Vector2i.LEFT, "step": 0.0, "trail": [ecell]})

func _setup_pong():
    ball = {"pos": Vector2(map_w * 0.5, map_h * 0.5), "vel": Vector2(340, 160)}
    left_paddle = 0.5
    right_paddle = 0.5

func _setup_smash():
    player["pos"] = _safe_pos(Vector2(map_w * 0.5, map_h * 0.5))
    for i in range(12):
        enemies.append({"pos": _spawn_far(player["pos"]), "speed": randf_range(80, 135), "kind": "grunt"})
    for i in range(4):
        enemies.append({"pos": _spawn_far(player["pos"]), "speed": 0.0, "kind": "spawner", "timer": randf_range(0.2, 1.2), "hp": 5})

func _setup_tank():
    player["pos"] = _safe_pos(Vector2(map_w * 0.5, map_h * 0.78))
    player["angle"] = -PI * 0.5
    for i in range(6):
        enemies.append({"pos": _spawn_far(player["pos"]), "angle": randf() * TAU, "cool": randf_range(0.5, 2.0), "hp": 2})

func _input(event):
    if overlay_mode != "" and _handle_menu_input(event):
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_TAB:
            _set_overlay_mode("settings" if overlay_mode != "settings" else "start")
        elif event.keycode == KEY_F1:
            show_reference = not show_reference
            _update_menu_overlay()
        elif event.keycode == KEY_ENTER and state != "playing":
            reset_game()
        elif event.keycode == KEY_ESCAPE:
            _set_overlay_mode("start")
            return
        elif overlay_mode == "" and game_id == "tron":
            if event.keycode in [KEY_UP, KEY_W] and player.get("dir", Vector2i.RIGHT) != Vector2i.DOWN:
                player["next"] = Vector2i.UP
            elif event.keycode in [KEY_DOWN, KEY_S] and player.get("dir", Vector2i.RIGHT) != Vector2i.UP:
                player["next"] = Vector2i.DOWN
            elif event.keycode in [KEY_LEFT, KEY_A] and player.get("dir", Vector2i.RIGHT) != Vector2i.RIGHT:
                player["next"] = Vector2i.LEFT
            elif event.keycode in [KEY_RIGHT, KEY_D] and player.get("dir", Vector2i.RIGHT) != Vector2i.LEFT:
                player["next"] = Vector2i.RIGHT

func _process(delta):
    _process_ipc(delta)
    if menu_axis_cooldown > 0.0:
        menu_axis_cooldown = max(0.0, menu_axis_cooldown - delta)
    if blanked:
        return
    if overlay_mode != "" or paused or state != "playing":
        queue_redraw()
        return
    if game_id == "asteroids":
        _tick_asteroids(delta)
    elif game_id == "tron":
        _tick_tron(delta)
    elif game_id == "pong":
        _tick_pong(delta)
    elif game_id == "smash_tv":
        _tick_smash(delta)
    elif game_id == "battlezone":
        _tick_tank(delta)
    _tick_bullets(delta)
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
    var title_text = title
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
        state = "playing"
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
    if not ready_sent:
        ready_sent = true
        send_ipc_message({"type": "ready"})
    var available = ipc_socket.get_available_bytes()
    if available > 0:
        read_buffer += ipc_socket.get_string(available)
        var lines = read_buffer.split("\n")
        if lines.size() > 1:
            for i in range(lines.size() - 1):
                var line = lines[i].strip_edges()
                if line != "":
                    _handle_ipc(line)
            read_buffer = lines[lines.size() - 1]
    heartbeat_timer += delta
    if heartbeat_timer >= 1.0:
        heartbeat_timer = 0.0
        send_ipc_message({"type": "heartbeat"})

func _handle_ipc(line: String):
    var json = JSON.new()
    if json.parse(line) != OK or typeof(json.data) != TYPE_DICTIONARY:
        send_ipc_message({"type": "error", "data": {"message": "bad json"}})
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
        reset_game()

func send_ipc_message(msg: Dictionary):
    if ipc_socket and ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        ipc_socket.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())

func _tick_asteroids(delta):
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        player["angle"] -= 4.2 * delta
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        player["angle"] += 4.2 * delta
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        player["vel"] += Vector2(cos(player["angle"]), sin(player["angle"])) * 420 * delta
    player["vel"] *= 0.992
    player["pos"] = _wrap(player["pos"] + player["vel"] * delta)
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        bullets.append({"pos": player["pos"], "vel": Vector2(cos(player["angle"]), sin(player["angle"])) * 620 + player["vel"] * 0.25, "ttl": 1.2, "kind": "hero"})
        player["cool"] = 0.18
    for r in rocks:
        r["pos"] = _wrap(r["pos"] + r["vel"] * delta)
        r["rot"] += r["spin"] * delta
        if r["pos"].distance_to(player["pos"]) < r["r"] + 15:
            _lose_life()
    for bi in range(bullets.size() - 1, -1, -1):
        var b = bullets[bi]
        if b.get("kind", "") != "hero":
            continue
        for ri in range(rocks.size() - 1, -1, -1):
            var r = rocks[ri]
            if b["pos"].distance_to(r["pos"]) < r["r"]:
                _burst(r["pos"], C_GREEN, 18)
                if r["size"] > 1:
                    rocks.append(_make_rock(r["pos"], r["size"] - 1))
                    rocks.append(_make_rock(r["pos"], r["size"] - 1))
                rocks.remove_at(ri)
                bullets.remove_at(bi)
                score += 50
                _emit_score()
                break
        if bi >= bullets.size():
            continue
    if rocks.is_empty():
        wave += 1
        _setup_asteroids()

func _tick_tron(delta):
    player["step"] += delta * 8.0
    if player["step"] >= 1.0:
        player["step"] = 0.0
        player["dir"] = player["next"]
        var n = player["cell"] + player["dir"]
        if not _cell_walkable(n) or _trail_has(n):
            _game_over()
            return
        player["cell"] = n
        player["pos"] = _cell_center(n)
        trails[0]["cells"].append(n)
        score += 1
    if enemies.size() > 0:
        var e = enemies[0]
        e["step"] += delta * 7.2
        if e["step"] >= 1.0:
            e["step"] = 0.0
            var options = [e["dir"], Vector2i(e["dir"].y, -e["dir"].x), Vector2i(-e["dir"].y, e["dir"].x)]
            options.shuffle()
            for d in options:
                var n2 = e["cell"] + d
                if _cell_walkable(n2) and not _trail_has(n2):
                    e["dir"] = d
                    e["cell"] = n2
                    e["pos"] = _cell_center(n2)
                    e["trail"].append(n2)
                    break
            if e["cell"] == player["cell"]:
                _game_over()
    _emit_score()

func _tick_pong(delta):
    var mv = _move_vec()
    left_paddle = clamp(left_paddle + mv.y * delta, 0.12, 0.88)
    right_paddle = lerp(right_paddle, clamp(ball["pos"].y / map_h, 0.12, 0.88), 0.055)
    ball["pos"] += ball["vel"] * delta
    if ball["pos"].y < 12 or ball["pos"].y > map_h - 12:
        ball["vel"].y *= -1
    var lp = Rect2(42, left_paddle * map_h - 60, 16, 120)
    var rp = Rect2(map_w - 58, right_paddle * map_h - 60, 16, 120)
    if lp.has_point(ball["pos"]) and ball["vel"].x < 0:
        ball["vel"].x = abs(ball["vel"].x) + 20
        ball["vel"].y += (ball["pos"].y - lp.get_center().y) * 3.0
    if rp.has_point(ball["pos"]) and ball["vel"].x > 0:
        ball["vel"].x = -abs(ball["vel"].x) - 20
        ball["vel"].y += (ball["pos"].y - rp.get_center().y) * 3.0
    if ball["pos"].x < 0:
        lives -= 1
        _reset_ball(-1)
        if lives <= 0:
            _game_over()
    elif ball["pos"].x > map_w:
        score += 1
        _emit_score()
        _reset_ball(1)

func _reset_ball(dir: int):
    ball = {"pos": Vector2(map_w * 0.5, map_h * 0.5), "vel": Vector2(340 * dir, randf_range(-180, 180))}

func _tick_smash(delta):
    player["pos"] = _safe_pos(player["pos"] + _move_vec() * 285 * delta)
    player["cool"] = max(0.0, player["cool"] - delta)
    var shot = _shoot_vec()
    if shot != Vector2.ZERO:
        last_shot_dir = shot.normalized()
    if player["cool"] <= 0 and (_action() or shot != Vector2.ZERO):
        bullets.append({"pos": player["pos"], "vel": last_shot_dir * 520, "ttl": 0.9, "kind": "hero"})
        player["cool"] = 0.12
    for e in enemies:
        if e["kind"] == "spawner":
            e["timer"] -= delta
            if e["timer"] <= 0:
                e["timer"] = 1.5
                enemies.append({"pos": e["pos"] + Vector2(randf_range(-24, 24), randf_range(-24, 24)), "speed": randf_range(80, 140), "kind": "grunt"})
            continue
        e["pos"] = _safe_pos(e["pos"] + (player["pos"] - e["pos"]).normalized() * e["speed"] * delta)
        if e["pos"].distance_to(player["pos"]) < 22:
            _lose_life()
    _bullet_hits_enemies()

func _tick_tank(delta):
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        player["angle"] -= 2.5 * delta
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        player["angle"] += 2.5 * delta
    var dir = Vector2(cos(player["angle"]), sin(player["angle"]))
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        player["pos"] = _safe_pos(player["pos"] + dir * 150 * delta)
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        player["pos"] = _safe_pos(player["pos"] - dir * 100 * delta)
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        bullets.append({"pos": player["pos"] + dir * 22, "vel": dir * 430, "ttl": 1.6, "kind": "hero"})
        player["cool"] = 0.55
    for e in enemies:
        var to_p = player["pos"] - e["pos"]
        e["angle"] = lerp_angle(e["angle"], to_p.angle(), 0.025)
        e["pos"] = _safe_pos(e["pos"] + Vector2(cos(e["angle"]), sin(e["angle"])) * 55 * delta)
        e["cool"] -= delta
        if e["cool"] <= 0:
            e["cool"] = randf_range(1.2, 2.4)
            enemy_bullets.append({"pos": e["pos"], "vel": Vector2(cos(e["angle"]), sin(e["angle"])) * 300, "ttl": 1.9, "kind": "enemy"})
        if e["pos"].distance_to(player["pos"]) < 24:
            _lose_life()
    _bullet_hits_enemies()
    for i in range(enemy_bullets.size() - 1, -1, -1):
        var b = enemy_bullets[i]
        b["pos"] += b["vel"] * delta
        b["ttl"] -= delta
        if b["pos"].distance_to(player["pos"]) < 16:
            enemy_bullets.remove_at(i)
            _lose_life()
        elif b["ttl"] <= 0 or not _cell_walkable(_pos_to_cell(b["pos"])):
            enemy_bullets.remove_at(i)

func _bullet_hits_enemies():
    for bi in range(bullets.size() - 1, -1, -1):
        var b = bullets[bi]
        if b.get("kind", "") != "hero":
            continue
        for ei in range(enemies.size() - 1, -1, -1):
            var e = enemies[ei]
            if b["pos"].distance_to(e["pos"]) < (24 if e["kind"] == "spawner" else 18):
                e["hp"] = e.get("hp", 1) - 1
                bullets.remove_at(bi)
                if e["hp"] <= 0:
                    _burst(e["pos"], C_MAGENTA, 18)
                    enemies.remove_at(ei)
                    score += 100 if e.get("kind", "") == "spawner" else 25
                    _emit_score()
                break
        if bi >= bullets.size():
            continue
    if enemies.is_empty():
        wave += 1
        if game_id == "smash_tv":
            _setup_smash()
        elif game_id == "battlezone":
            _setup_tank()

func _tick_bullets(delta):
    for i in range(bullets.size() - 1, -1, -1):
        bullets[i]["pos"] += bullets[i]["vel"] * delta
        bullets[i]["ttl"] -= delta
        if bullets[i]["ttl"] <= 0 or bullets[i]["pos"].x < -60 or bullets[i]["pos"].x > map_w + 60 or bullets[i]["pos"].y < -60 or bullets[i]["pos"].y > map_h + 60 or not _cell_walkable(_pos_to_cell(bullets[i]["pos"])):
            bullets.remove_at(i)

func _tick_particles(delta):
    for i in range(particles.size() - 1, -1, -1):
        particles[i]["pos"] += particles[i]["vel"] * delta
        particles[i]["life"] -= delta
        if particles[i]["life"] <= 0:
            particles.remove_at(i)

func _draw():
    if blanked:
        return
    draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))
    if show_reference and reference_texture:
        draw_texture_rect(reference_texture, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, 0.15))
    _draw_grid()
    if game_id == "asteroids":
        _draw_asteroids()
    elif game_id == "tron":
        _draw_tron()
    elif game_id == "pong":
        _draw_pong()
    elif game_id == "smash_tv":
        _draw_smash()
    elif game_id == "battlezone":
        _draw_tank()
    for p in particles:
        var a = p["life"] / p["max"]
        draw_circle(p["pos"], 8 * a, Color(p["color"].r, p["color"].g, p["color"].b, a))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_hud()

func _draw_grid():
    for x in range(0, int(map_w), int(cell_px * 2)):
        draw_line(Vector2(x, 0), Vector2(x, map_h), Color(1, 1, 1, 0.035), 1)
    for y in range(0, int(map_h), int(cell_px * 2)):
        draw_line(Vector2(0, y), Vector2(map_w, y), Color(1, 1, 1, 0.035), 1)
    draw_rect(Rect2(0, 0, map_w, map_h), Color(1, 1, 1, 0.55), false, 1)

func _draw_asteroids():
    for r in rocks:
        var pts = PackedVector2Array()
        for p in r["poly"]:
            pts.append(r["pos"] + p.rotated(r["rot"]))
        pts.append(pts[0])
        draw_colored_polygon(pts, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.08))
        draw_polyline(pts, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.25), 5)
        draw_polyline(pts, C_GREEN, 1.5)
        for p in pts:
            draw_circle(p, 2.0, Color.WHITE)
    for b in bullets:
        _glow_line(b["pos"] - b["vel"].normalized() * 10, b["pos"], C_MAGENTA, 2)
    _draw_ship(player["pos"], player["angle"], C_CYAN)

func _draw_tron():
    for t in trails:
        var pts = PackedVector2Array()
        for c in t["cells"]:
            pts.append(_cell_center(c))
        if pts.size() > 1:
            draw_polyline(pts, Color(t["color"].r, t["color"].g, t["color"].b, 0.28), 11)
            draw_polyline(pts, t["color"], 3)
    if enemies.size() > 0:
        var epts = PackedVector2Array()
        for c in enemies[0]["trail"]:
            epts.append(_cell_center(c))
        if epts.size() > 1:
            draw_polyline(epts, Color(C_ORANGE.r, C_ORANGE.g, C_ORANGE.b, 0.28), 11)
            draw_polyline(epts, C_ORANGE, 3)
        _draw_cycle(enemies[0]["pos"], C_ORANGE)
    _draw_cycle(player["pos"], C_CYAN)

func _draw_pong():
    _glow_line(Vector2(map_w * 0.5, 0), Vector2(map_w * 0.5, map_h), Color(1, 1, 1), 1.4)
    _draw_paddle(Vector2(50, left_paddle * map_h), C_CYAN)
    _draw_paddle(Vector2(map_w - 50, right_paddle * map_h), C_MAGENTA)
    _glow_circle(ball["pos"], 10, C_YELLOW)

func _draw_smash():
    for e in enemies:
        _draw_spawner(e["pos"], C_MAGENTA) if e["kind"] == "spawner" else _draw_robot(e["pos"], C_RED)
    for b in bullets:
        _glow_circle(b["pos"], 4, C_YELLOW)
    _draw_twin_hero(player["pos"], C_CYAN)

func _draw_tank():
    for e in enemies:
        _draw_tank_shape(e["pos"], e["angle"], C_ORANGE)
    for b in bullets:
        _glow_circle(b["pos"], 4, C_YELLOW)
    for b in enemy_bullets:
        _glow_circle(b["pos"], 4, C_RED)
    _draw_tank_shape(player["pos"], player["angle"], C_CYAN)

func _draw_hud():
    var font = ThemeDB.fallback_font
    draw_string(font, Vector2(18, 34), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(font, Vector2(18, 64), "SCORE " + str(score) + "  LIVES " + str(lives) + "  WAVE " + str(wave), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_CYAN)
    if paused:
        draw_string(font, get_viewport_rect().size * 0.5, "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, -1, 46, Color.WHITE)
    elif state == "game_over":
        draw_string(font, get_viewport_rect().size * 0.5, "GAME OVER - ENTER", HORIZONTAL_ALIGNMENT_CENTER, -1, 44, C_RED)

func _move_vec() -> Vector2:
    var v = Vector2.ZERO
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
        v.x -= 1
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
        v.x += 1
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
        v.y -= 1
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
        v.y += 1
    var joy = Vector2(Input.get_joy_axis(SharedLoader.get_joy_id(0), JOY_AXIS_LEFT_X), Input.get_joy_axis(SharedLoader.get_joy_id(0), JOY_AXIS_LEFT_Y))
    if joy.length() > 0.25:
        v = joy
    return v.normalized() if v.length() > 1.0 else v

func _shoot_vec() -> Vector2:
    var v = Vector2.ZERO
    if Input.is_key_pressed(KEY_J):
        v.x -= 1
    if Input.is_key_pressed(KEY_L):
        v.x += 1
    if Input.is_key_pressed(KEY_I):
        v.y -= 1
    if Input.is_key_pressed(KEY_K):
        v.y += 1
    if v == Vector2.ZERO and _action():
        v = Vector2.UP
    return v

func _action() -> bool:
    return Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_A)

func _safe_pos(pos: Vector2) -> Vector2:
    var clamped = _clamp(pos)
    if _cell_walkable(_pos_to_cell(clamped)):
        return clamped
    return _cell_center(_find_nearest_walkable_cell(_pos_to_cell(clamped)))

func _spawn_far(pos: Vector2) -> Vector2:
    if walkable.is_empty():
        return _clamp(Vector2(randf() * map_w, randf() * map_h))
    var best = walkable[0]
    var best_d = -1.0
    for i in range(min(80, walkable.size())):
        var c = walkable[randi() % walkable.size()]
        var d = _cell_center(c).distance_squared_to(pos)
        if d > best_d:
            best_d = d
            best = c
    return _cell_center(best)

func _find_nearest_walkable_cell(start: Vector2i) -> Vector2i:
    if walkable.is_empty():
        return Vector2i(clamp(start.x, 0, max(0, grid_w - 1)), clamp(start.y, 0, max(0, grid_h - 1)))
    var s = Vector2i(clamp(start.x, 0, grid_w - 1), clamp(start.y, 0, grid_h - 1))
    if _cell_walkable(s):
        return s
    var visited = {}
    var q = [s]
    visited[s] = true
    var qi = 0
    while qi < q.size():
        var cur = q[qi]
        qi += 1
        for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
            var n = cur + d
            if n.x < 0 or n.y < 0 or n.x >= grid_w or n.y >= grid_h or visited.has(n):
                continue
            if _cell_walkable(n):
                return n
            visited[n] = true
            q.append(n)
    return walkable[0]

func _cell_walkable(c: Vector2i) -> bool:
    if c.y < 0 or c.y >= grid.size():
        return false
    if c.x < 0 or c.x >= grid[c.y].size():
        return false
    return int(grid[c.y][c.x]) != 1

func _trail_has(c: Vector2i) -> bool:
    for t in trails:
        if t["cells"].has(c):
            return true
    if enemies.size() > 0 and enemies[0].has("trail") and enemies[0]["trail"].has(c):
        return true
    return false

func _pos_to_cell(pos: Vector2) -> Vector2i:
    return Vector2i(int(pos.x / cell_px), int(pos.y / cell_px))

func _cell_center(c: Vector2i) -> Vector2:
    return Vector2((c.x + 0.5) * cell_px, (c.y + 0.5) * cell_px)

func _clamp(pos: Vector2) -> Vector2:
    return Vector2(clamp(pos.x, 0, map_w), clamp(pos.y, 0, map_h))

func _wrap(pos: Vector2) -> Vector2:
    return Vector2(wrapf(pos.x, 0, map_w), wrapf(pos.y, 0, map_h))

func _lose_life():
    lives -= 1
    _burst(player.get("pos", Vector2(map_w * 0.5, map_h * 0.5)), C_RED, 24)
    if lives <= 0:
        _game_over()
    else:
        player["pos"] = _safe_pos(Vector2(map_w * 0.5, map_h * 0.5))
        player["vel"] = Vector2.ZERO
        send_ipc_message({"type": "state", "data": {"state": "life_lost", "lives": lives}})

func _game_over():
    state = "game_over"
    send_ipc_message({"type": "state", "data": {"state": "game_over"}})

func _emit_score():
    send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})

func _burst(pos: Vector2, color: Color, count: int):
    for i in range(count):
        var a = randf() * TAU
        particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(30, 210), "life": randf_range(0.25, 0.65), "max": 0.65, "color": color})

func _glow_line(a: Vector2, b: Vector2, color: Color, width: float):
    draw_line(a, b, Color(color.r, color.g, color.b, 0.22), width * 5)
    draw_line(a, b, Color(color.r, color.g, color.b, 0.75), width * 2)
    draw_line(a, b, Color.WHITE, max(1.0, width * 0.45))

func _glow_circle(pos: Vector2, r: float, color: Color):
    draw_circle(pos, r * 2.0, Color(color.r, color.g, color.b, 0.16))
    draw_circle(pos, r * 1.25, Color(color.r, color.g, color.b, 0.48))
    draw_circle(pos, r, Color(color.r, color.g, color.b, 0.94))
    draw_arc(pos, r, 0, TAU, 28, Color.WHITE, 1.1)

func _glow_circle_outline(pos: Vector2, r: float, color: Color, width: float):
    draw_arc(pos, r, 0, TAU, 40, Color(color.r, color.g, color.b, 0.25), width * 5)
    draw_arc(pos, r, 0, TAU, 40, Color(color.r, color.g, color.b, 0.75), width * 2)
    draw_arc(pos, r, 0, TAU, 40, Color.WHITE, max(1.0, width * 0.45))

func _draw_ship(pos: Vector2, angle: float, color: Color):
    var pts = PackedVector2Array([
        pos + Vector2(24, 0).rotated(angle),
        pos + Vector2(-15, -12).rotated(angle),
        pos + Vector2(-8, 0).rotated(angle),
        pos + Vector2(-15, 12).rotated(angle)
    ])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.14))
    for i in range(pts.size()):
        _glow_line(pts[i], pts[(i + 1) % pts.size()], color, 1.4)
    _glow_line(pos + Vector2(-8, 0).rotated(angle), pos + Vector2(-24, 0).rotated(angle), C_MAGENTA, 1.0)
    _glow_line(pos + Vector2(-12, -8).rotated(angle), pos + Vector2(8, -2).rotated(angle), Color.WHITE, 0.6)

func _draw_tank_shape(pos: Vector2, angle: float, color: Color):
    draw_set_transform(offset + pos * scale_factor, angle, Vector2(scale_factor, scale_factor))
    draw_rect(Rect2(-18, -13, 36, 26), Color(color.r, color.g, color.b, 0.16), true)
    draw_rect(Rect2(-18, -13, 36, 26), color, false, 2)
    draw_rect(Rect2(-13, -8, 18, 16), Color(color.r, color.g, color.b, 0.18), true)
    draw_rect(Rect2(-13, -8, 18, 16), Color.WHITE, false, 1)
    for x in [-13, -5, 3, 11]:
        draw_line(Vector2(x, -15), Vector2(x, -11), color, 1.0)
        draw_line(Vector2(x, 11), Vector2(x, 15), color, 1.0)
    _glow_line(Vector2(0, 0), Vector2(26, 0), color, 2)
    draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))

func _draw_cycle(pos: Vector2, color: Color):
    _glow_line(pos + Vector2(-16, 10), pos + Vector2(16, 10), color, 1.3)
    _glow_line(pos + Vector2(-8, 2), pos + Vector2(12, -10), color, 1.3)
    _glow_circle_outline(pos + Vector2(-15, 12), 6, color, 1.1)
    _glow_circle_outline(pos + Vector2(15, 12), 6, color, 1.1)

func _draw_paddle(pos: Vector2, color: Color):
    draw_rect(Rect2(pos + Vector2(-7, -60), Vector2(14, 120)), Color(color.r, color.g, color.b, 0.14), true)
    draw_rect(Rect2(pos + Vector2(-7, -60), Vector2(14, 120)), color, false, 1.8)
    _glow_line(pos + Vector2(0, -60), pos + Vector2(0, 60), color, 4.0)

func _draw_spawner(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 22, color, 3)
    for a in [0.0, TAU / 4.0, TAU / 2.0, TAU * 3.0 / 4.0]:
        _glow_line(pos, pos + Vector2(cos(a), sin(a)) * 22, color, 1.0)

func _draw_robot(pos: Vector2, color: Color):
    draw_rect(Rect2(pos + Vector2(-10, -16), Vector2(20, 13)), Color(color.r, color.g, color.b, 0.16), true)
    draw_rect(Rect2(pos + Vector2(-12, -2), Vector2(24, 21)), Color(color.r, color.g, color.b, 0.14), true)
    draw_rect(Rect2(pos + Vector2(-12, -2), Vector2(24, 21)), color, false, 1.5)
    _glow_line(pos + Vector2(-15, 4), pos + Vector2(-24, 12), color, 1.0)
    _glow_line(pos + Vector2(15, 4), pos + Vector2(24, 12), color, 1.0)
    draw_circle(pos + Vector2(-4, -10), 2.0, Color.WHITE)
    draw_circle(pos + Vector2(4, -10), 2.0, Color.WHITE)

func _draw_twin_hero(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 15, color, 2)
    _glow_line(pos + Vector2(-16, 0), pos + Vector2(-28, -9), color, 1.2)
    _glow_line(pos + Vector2(16, 0), pos + Vector2(28, -9), color, 1.2)
    _glow_line(pos + Vector2(-7, 13), pos + Vector2(-12, 25), color, 1.2)
    _glow_line(pos + Vector2(7, 13), pos + Vector2(12, 25), color, 1.2)
    draw_circle(pos + Vector2(-4, -3), 2.0, Color.WHITE)
    draw_circle(pos + Vector2(4, -3), 2.0, Color.WHITE)
