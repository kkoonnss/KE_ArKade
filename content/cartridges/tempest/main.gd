extends Node2D
const SharedLoader = preload("res://../../../app/shared/shared_loader.gd")

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

var map_w = 1280.0
var map_h = 720.0
var cell_px = 32.0
var scale_factor = 1.0
var offset = Vector2.ZERO
var grid = []
var grid_w = 0
var grid_h = 0
var walkable = []
var solids = []
var reference_texture: Texture2D = null
var show_reference = false

var ui_canvas: CanvasLayer
var tab_menu: ColorRect
var splash_rect: TextureRect
var splash_timer = 1.4
var screenshot_path = ""

var score = 0
var lives = 3
var wave = 1
var state = "playing"
var selected_players = 1
var player = {"pos": Vector2.ZERO, "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false}
var enemies = []
var bullets = []
var particles = []
var platforms = []
var ladders = []
var bricks = []
var items = []
var hazards = []
var barrels = []
var bubbles = []
var rocks = []
var generators = []
var customers = []
var drinks = []
var mugs = []
var snake = []
var snake_dir = Vector2i.RIGHT
var next_snake_dir = Vector2i.RIGHT
var snake_timer = 0.0
var food_cell = Vector2i.ZERO
var ball = {"pos": Vector2.ZERO, "vel": Vector2.ZERO}
var paddle_x = 0.0
var marble_vel = Vector2.ZERO
var time_left = 90.0
var tube_lanes = 16
var tube_lane = 0
var tube_enemies = []
var zapper_ready = true
var tube_move_cool = 0.0

func _ready():
    randomize()
    _identity()
    _parse_args()
    RenderingServer.set_default_clear_color(Color.BLACK)
    _build_ui()
    _connect_ipc()
    load_level()
    reset_game()
    state = "start"
    tab_menu.visible = true
    if splash_rect:
        splash_rect.visible = true
        splash_rect.modulate.a = 1.0
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
        "donkey_kong": "Donkey Kong",
        "breakout": "Breakout",
        "bubble_bobble": "Bubble Bobble",
        "dig_dug": "Dig Dug",
        "gauntlet": "Gauntlet",
        "marble_madness": "Marble Madness",
        "joust": "Joust",
        "snake": "Snake",
        "tapper": "Tapper",
        "tempest": "Tempest"
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
    var center = CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_menu.add_child(center)
    var box = VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    center.add_child(box)
    for line in [title, "PRESS ENTER OR SPACE TO START", "H HELP  TAB SETTINGS  P PLAYERS", "WASD/ARROWS MOVE  SPACE/CLICK ACTION", "PLAYERS: 1-4 SELECTABLE BEFORE START", "IPC READY SCORE HEARTBEAT LOAD PAUSE RESUME BLANK QUIT"]:
        var label = Label.new()
        label.text = line
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 22)
        label.add_theme_color_override("font_color", Color.WHITE)
        box.add_child(label)

func _connect_ipc():
    if ipc_port <= 0:
        return
    ipc_socket = StreamPeerTCP.new()
    ipc_socket.connect_to_host(ipc_host, ipc_port)

func load_level():
    grid.clear()
    walkable.clear()
    solids.clear()
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
            var c = Vector2i(x, y)
            if int(grid[y][x]) == 1:
                solids.append(c)
            else:
                walkable.append(c)
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
    particles.clear()
    platforms.clear()
    ladders.clear()
    bricks.clear()
    items.clear()
    hazards.clear()
    barrels.clear()
    bubbles.clear()
    rocks.clear()
    generators.clear()
    customers.clear()
    drinks.clear()
    mugs.clear()
    snake.clear()
    tube_enemies.clear()
    player = {"pos": _safe_pos(Vector2(map_w * 0.18, map_h * 0.78)), "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false}
    if game_id == "donkey_kong":
        _setup_barrel()
    elif game_id == "breakout":
        _setup_breakout()
    elif game_id == "bubble_bobble":
        _setup_bubble()
    elif game_id == "dig_dug":
        _setup_drill()
    elif game_id == "gauntlet":
        _setup_dungeon()
    elif game_id == "marble_madness":
        _setup_marble()
    elif game_id == "joust":
        _setup_joust()
    elif game_id == "snake":
        _setup_snake()
    elif game_id == "tapper":
        _setup_tapper()
    elif game_id == "tempest":
        _setup_tempest()
    _emit_score()

func _setup_platforms():
    for i in range(5):
        var y = map_h * (0.22 + i * 0.16)
        var x = map_w * (0.12 if i % 2 == 0 else 0.20)
        platforms.append(Rect2(x, y, map_w * 0.72, 5))
    for x in [0.24, 0.44, 0.64, 0.82]:
        ladders.append(Rect2(map_w * x, map_h * 0.22, 6, map_h * 0.66))

func _setup_barrel():
    _setup_platforms()
    player["pos"] = Vector2(map_w * 0.16, map_h * 0.85)
    items.append({"pos": Vector2(map_w * 0.82, map_h * 0.13), "kind": "goal"})

func _setup_breakout():
    paddle_x = map_w * 0.5
    ball = {"pos": Vector2(map_w * 0.5, map_h * 0.68), "vel": Vector2(210, -260)}
    for y in range(6):
        for x in range(12):
            bricks.append({"rect": Rect2(map_w * 0.12 + x * map_w * 0.064, map_h * 0.12 + y * 28, map_w * 0.05, 18), "hp": 2 if y < 2 else 1, "kind": y % 3})

func _setup_bubble():
    _setup_platforms()
    player["pos"] = Vector2(map_w * 0.18, map_h * 0.70)
    for i in range(7):
        enemies.append({"pos": _safe_pos(Vector2(map_w * randf_range(0.25, 0.8), map_h * randf_range(0.25, 0.68))), "vel": Vector2(randf_range(-60, 60), 0), "trapped": false, "trap": 0.0})

func _setup_drill():
    player["pos"] = _safe_pos(Vector2(map_w * 0.5, map_h * 0.5))
    for i in range(8):
        enemies.append({"pos": _spawn_far(player["pos"]), "inflate": 0, "ghost": false})
    for i in range(5):
        rocks.append({"pos": _safe_pos(Vector2(randf() * map_w, randf() * map_h * 0.45)), "fall": false})

func _setup_dungeon():
    player["pos"] = _safe_pos(Vector2(map_w * 0.18, map_h * 0.5))
    player["health"] = 100.0
    for i in range(4):
        generators.append({"pos": _spawn_far(player["pos"]), "hp": 4, "timer": randf()})
    for i in range(5):
        items.append({"pos": _safe_pos(Vector2(randf() * map_w, randf() * map_h)), "kind": "food" if i % 2 == 0 else "key"})

func _setup_marble():
    player["pos"] = _safe_pos(Vector2(map_w * 0.16, map_h * 0.18))
    marble_vel = Vector2.ZERO
    time_left = 75.0
    for i in range(7):
        items.append({"pos": Vector2(map_w * (0.2 + i * 0.1), map_h * (0.25 + sin(i) * 0.22)), "kind": "checkpoint", "hit": false})
    for i in range(10):
        hazards.append({"pos": _safe_pos(Vector2(randf() * map_w, randf() * map_h)), "r": randf_range(13, 28)})

func _setup_joust():
    _setup_platforms()
    player["pos"] = Vector2(map_w * 0.5, map_h * 0.35)
    player["vel"] = Vector2.ZERO
    for i in range(6):
        enemies.append({"pos": Vector2(map_w * randf_range(0.15, 0.85), map_h * randf_range(0.25, 0.6)), "vel": Vector2(randf_range(-80, 80), randf_range(-40, 40)), "egg": false, "timer": 0.0})

func _setup_snake():
    var c = _find_nearest_walkable_cell(Vector2i(grid_w / 2, grid_h / 2))
    snake = [c, c + Vector2i(-1, 0), c + Vector2i(-2, 0)]
    snake_dir = Vector2i.RIGHT
    next_snake_dir = Vector2i.RIGHT
    snake_timer = 0.0
    _spawn_food()

func _setup_tapper():
    for i in range(4):
        var y = map_h * (0.24 + i * 0.17)
        platforms.append(Rect2(map_w * 0.16, y, map_w * 0.68, 5))
        customers.append({"lane": i, "x": map_w * 0.82, "timer": randf_range(0.0, 1.0)})
    player["lane"] = 0
    player["pos"] = Vector2(map_w * 0.2, platforms[0].position.y)

func _setup_tempest():
    tube_lanes = 16
    tube_lane = 0
    zapper_ready = true
    for i in range(8):
        tube_enemies.append({"lane": randi() % tube_lanes, "depth": randf_range(0.05, 0.55), "speed": randf_range(0.08, 0.16)})

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if state == "start":
            if event.keycode in [KEY_ENTER, KEY_SPACE]:
                state = "playing"
                tab_menu.visible = false
                if splash_rect:
                    splash_rect.queue_free()
                    splash_rect = null
                return
            elif event.keycode == KEY_P or event.keycode == KEY_RIGHT or event.keycode == KEY_D:
                selected_players = selected_players % 4 + 1
                return
            elif event.keycode in [KEY_H, KEY_S, KEY_TAB]:
                tab_menu.visible = true
                return
        if event.keycode == KEY_TAB:
            tab_menu.visible = not tab_menu.visible
        elif event.keycode == KEY_F1:
            show_reference = not show_reference
        elif event.keycode == KEY_ENTER and state != "playing":
            reset_game()
        elif event.keycode == KEY_ESCAPE:
            state = "start"
            tab_menu.visible = true
            if splash_rect:
                splash_rect.visible = true
                splash_rect.modulate.a = 1.0
            return
        elif game_id == "snake":
            if event.keycode in [KEY_UP, KEY_W] and snake_dir != Vector2i.DOWN:
                next_snake_dir = Vector2i.UP
            elif event.keycode in [KEY_DOWN, KEY_S] and snake_dir != Vector2i.UP:
                next_snake_dir = Vector2i.DOWN
            elif event.keycode in [KEY_LEFT, KEY_A] and snake_dir != Vector2i.RIGHT:
                next_snake_dir = Vector2i.LEFT
            elif event.keycode in [KEY_RIGHT, KEY_D] and snake_dir != Vector2i.LEFT:
                next_snake_dir = Vector2i.RIGHT

func _process(delta):
    _process_ipc(delta)
    _splash(delta)
    if blanked:
        return
    if paused or state != "playing":
        queue_redraw()
        return
    if game_id == "donkey_kong":
        _tick_barrel(delta)
    elif game_id == "breakout":
        _tick_breakout(delta)
    elif game_id == "bubble_bobble":
        _tick_bubble(delta)
    elif game_id == "dig_dug":
        _tick_drill(delta)
    elif game_id == "gauntlet":
        _tick_dungeon(delta)
    elif game_id == "marble_madness":
        _tick_marble(delta)
    elif game_id == "joust":
        _tick_joust(delta)
    elif game_id == "snake":
        _tick_snake(delta)
    elif game_id == "tapper":
        _tick_tapper(delta)
    elif game_id == "tempest":
        _tick_tempest(delta)
    _tick_bullets(delta)
    _tick_particles(delta)
    queue_redraw()

func _splash(delta):
    if state == "start":
        return
    if splash_rect:
        splash_timer -= delta
        if splash_timer <= 0:
            splash_rect.queue_free()
            splash_rect = null
        elif splash_timer < 0.7:
            splash_rect.modulate.a = splash_timer / 0.7

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

func _tick_barrel(delta):
    _platform_move(delta, true)
    player["cool"] = max(0.0, player["cool"] - delta)
    if barrels.size() < 9 and randf() < delta * (0.9 + wave * 0.1):
        barrels.append({"pos": Vector2(map_w * 0.78, map_h * 0.2), "vel": Vector2(-120, 0), "jumped": false})
    for i in range(barrels.size() - 1, -1, -1):
        var b = barrels[i]
        b["pos"] += b["vel"] * delta
        var py = _platform_y(b["pos"])
        if py > 0:
            b["pos"].y = py - 13
        if randf() < delta * 0.35:
            b["vel"].x *= -1
            b["pos"].y += 65
        if b["pos"].x < 20 or b["pos"].x > map_w - 20 or b["pos"].y > map_h:
            barrels.remove_at(i)
            continue
        var d = b["pos"].distance_to(player["pos"])
        if d < 24 and abs(player["vel"].y) < 60:
            _lose_life()
        elif d < 38 and player["vel"].y < -20 and not b["jumped"]:
            b["jumped"] = true
            score += 100
            _emit_score()
    if player["pos"].distance_to(items[0]["pos"]) < 35:
        _win_wave()

func _tick_breakout(delta):
    var v = _move_vec()
    paddle_x = clamp(paddle_x + v.x * 520 * delta, map_w * 0.08, map_w * 0.92)
    ball["pos"] += ball["vel"] * delta
    if ball["pos"].x < 8 or ball["pos"].x > map_w - 8:
        ball["vel"].x *= -1
    if ball["pos"].y < 8:
        ball["vel"].y *= -1
    var paddle = Rect2(paddle_x - 70, map_h * 0.87, 140, 14)
    if paddle.has_point(ball["pos"]) and ball["vel"].y > 0:
        ball["vel"].y = -abs(ball["vel"].y) - 8
        ball["vel"].x += (ball["pos"].x - paddle_x) * 4
    if ball["pos"].y > map_h:
        _lose_life()
        ball = {"pos": Vector2(map_w * 0.5, map_h * 0.68), "vel": Vector2(210, -260)}
    for i in range(bricks.size() - 1, -1, -1):
        if bricks[i]["rect"].grow(6).has_point(ball["pos"]):
            ball["vel"].y *= -1
            bricks[i]["hp"] -= 1
            if bricks[i]["hp"] <= 0:
                _burst(bricks[i]["rect"].get_center(), C_MAGENTA, 12)
                bricks.remove_at(i)
                score += 50
                _emit_score()
            break
    if bricks.is_empty():
        wave += 1
        _setup_breakout()

func _tick_bubble(delta):
    _platform_move(delta, true)
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        var dir = sign(_move_vec().x)
        if dir == 0:
            dir = 1
        bubbles.append({"pos": player["pos"] + Vector2(20 * dir, -8), "vel": Vector2(170 * dir, -18), "ttl": 2.2, "trapped": -1})
        player["cool"] = 0.35
    for i in range(bubbles.size() - 1, -1, -1):
        var bub = bubbles[i]
        bub["pos"] += bub["vel"] * delta
        bub["vel"].y -= 14 * delta
        bub["ttl"] -= delta
        if bub["ttl"] <= 0:
            bubbles.remove_at(i)
    for ei in range(enemies.size() - 1, -1, -1):
        var e = enemies[ei]
        if e["trapped"]:
            e["pos"].y -= 55 * delta
            if e["pos"].distance_to(player["pos"]) < 26 or e["pos"].y < 20:
                _burst(e["pos"], C_YELLOW, 18)
                enemies.remove_at(ei)
                score += 200
                _emit_score()
            continue
        e["pos"].x += e["vel"].x * delta
        e["pos"].y = _platform_y(e["pos"]) - 18
        if e["pos"].x < 40 or e["pos"].x > map_w - 40:
            e["vel"].x *= -1
        if e["pos"].distance_to(player["pos"]) < 22:
            _lose_life()
        for bub in bubbles:
            if bub["pos"].distance_to(e["pos"]) < 26:
                e["trapped"] = true
    if enemies.is_empty():
        wave += 1
        _setup_bubble()

func _tick_drill(delta):
    var v = _move_vec()
    player["pos"] = _clamp(player["pos"] + v * 180 * delta)
    var cell = _pos_to_cell(player["pos"])
    if cell.y >= 0 and cell.y < grid.size() and cell.x >= 0 and cell.x < grid[cell.y].size():
        grid[cell.y][cell.x] = 2
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        bullets.append({"pos": player["pos"], "vel": _aim_dir() * 270, "ttl": 0.35, "kind": "pump"})
        player["cool"] = 0.3
    for ei in range(enemies.size() - 1, -1, -1):
        var e = enemies[ei]
        var dir = (player["pos"] - e["pos"]).normalized()
        e["pos"] += dir * (85 if e["ghost"] else 55) * delta
        if randf() < delta * 0.12:
            e["ghost"] = not e["ghost"]
        if e["pos"].distance_to(player["pos"]) < 22:
            _lose_life()
        if e["inflate"] >= 3:
            _burst(e["pos"], C_ORANGE, 20)
            enemies.remove_at(ei)
            score += 250
            _emit_score()
    for b in bullets:
        for e in enemies:
            if b["pos"].distance_to(e["pos"]) < 28:
                e["inflate"] += 1
    for r in rocks:
        if r["pos"].distance_to(player["pos"]) < 28:
            _lose_life()

func _tick_dungeon(delta):
    player["pos"] = _safe_pos(player["pos"] + _move_vec() * 230 * delta)
    player["health"] -= delta * 1.4
    if player["health"] <= 0:
        _lose_life()
        player["health"] = 100
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        bullets.append({"pos": player["pos"], "vel": _aim_dir() * 420, "ttl": 1.0, "kind": "hero"})
        player["cool"] = 0.18
    for g in generators:
        g["timer"] -= delta
        if g["timer"] <= 0:
            g["timer"] = 1.3
            enemies.append({"pos": g["pos"] + Vector2(randf_range(-25, 25), randf_range(-25, 25)), "hp": 1})
    for ei in range(enemies.size() - 1, -1, -1):
        var e = enemies[ei]
        e["pos"] = _safe_pos(e["pos"] + (player["pos"] - e["pos"]).normalized() * 95 * delta)
        if e["pos"].distance_to(player["pos"]) < 22:
            player["health"] -= 22 * delta
    for b in bullets:
        for i in range(enemies.size() - 1, -1, -1):
            if b["pos"].distance_to(enemies[i]["pos"]) < 20:
                enemies.remove_at(i)
                b["ttl"] = 0
                score += 25
                _emit_score()
                break
        for g in generators:
            if b["pos"].distance_to(g["pos"]) < 26:
                g["hp"] -= 1
                b["ttl"] = 0
    for i in range(generators.size() - 1, -1, -1):
        if generators[i]["hp"] <= 0:
            _burst(generators[i]["pos"], C_MAGENTA, 20)
            generators.remove_at(i)
            score += 200
            _emit_score()
    for i in range(items.size() - 1, -1, -1):
        if items[i]["pos"].distance_to(player["pos"]) < 24:
            player["health"] = min(100, player["health"] + 30)
            score += 100
            items.remove_at(i)
            _emit_score()

func _tick_marble(delta):
    time_left -= delta
    marble_vel += _move_vec() * 260 * delta
    marble_vel *= 0.985
    player["pos"] = _safe_pos(player["pos"] + marble_vel * delta)
    if time_left <= 0:
        _lose_life()
        time_left = 45
    for h in hazards:
        if h["pos"].distance_to(player["pos"]) < h["r"] + 12:
            _lose_life()
    for item in items:
        if not item["hit"] and item["pos"].distance_to(player["pos"]) < 28:
            item["hit"] = true
            time_left += 10
            score += 150
            _emit_score()
    var all_hit = true
    for item in items:
        if not item["hit"]:
            all_hit = false
    if all_hit:
        _win_wave()

func _tick_joust(delta):
    var v = _move_vec()
    var vel = player["vel"]
    vel.x = lerp(vel.x, v.x * 220, 0.08)
    vel.y += 330 * delta
    if _action():
        vel.y -= 520 * delta
    player["pos"] += vel * delta
    player["pos"].x = wrapf(player["pos"].x, 0, map_w)
    if player["pos"].y > map_h * 0.88:
        _lose_life()
        vel = Vector2.ZERO
    for p in platforms:
        if player["pos"].y < p.position.y and player["pos"].y + 18 > p.position.y and player["pos"].x > p.position.x and player["pos"].x < p.position.x + p.size.x and vel.y > 0:
            player["pos"].y = p.position.y - 18
            vel.y = 0
    player["vel"] = vel
    for ei in range(enemies.size() - 1, -1, -1):
        var e = enemies[ei]
        if e["egg"]:
            e["timer"] -= delta
            if e["pos"].distance_to(player["pos"]) < 24:
                enemies.remove_at(ei)
                score += 250
                _emit_score()
            elif e["timer"] <= 0:
                e["egg"] = false
                e["vel"] = Vector2(randf_range(-90, 90), -70)
            continue
        e["vel"].y += 180 * delta
        e["pos"] += e["vel"] * delta
        e["pos"].x = wrapf(e["pos"].x, 0, map_w)
        if e["pos"].y > map_h * 0.78:
            e["vel"].y = -randf_range(120, 220)
        if e["pos"].distance_to(player["pos"]) < 30:
            if player["pos"].y < e["pos"].y - 6:
                e["egg"] = true
                e["timer"] = 4.0
                e["vel"] = Vector2.ZERO
                score += 100
                _emit_score()
            else:
                _lose_life()

func _tick_snake(delta):
    snake_timer += delta
    if snake_timer < max(0.06, 0.18 - score * 0.0005):
        return
    snake_timer = 0
    snake_dir = next_snake_dir
    var head = snake[0] + snake_dir
    if not _cell_walkable(head) or head in snake:
        _lose_life()
        _setup_snake()
        return
    snake.insert(0, head)
    if head == food_cell:
        score += 50
        _emit_score()
        _spawn_food()
    else:
        snake.pop_back()

func _tick_tapper(delta):
    var lane = int(player.get("lane", 0))
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        lane = max(0, lane - 1)
    elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        lane = min(3, lane + 1)
    player["lane"] = lane
    player["pos"] = Vector2(map_w * 0.2, platforms[lane].position.y)
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        drinks.append({"lane": lane, "x": map_w * 0.23})
        player["cool"] = 0.22
    for d_i in range(drinks.size() - 1, -1, -1):
        drinks[d_i]["x"] += 360 * delta
        if drinks[d_i]["x"] > map_w:
            drinks.remove_at(d_i)
            _lose_life()
    for c in customers:
        c["x"] -= (32 + wave * 5) * delta
        if c["x"] < map_w * 0.2:
            _lose_life()
            c["x"] = map_w * 0.84
        for d_i in range(drinks.size() - 1, -1, -1):
            if drinks[d_i]["lane"] == c["lane"] and abs(drinks[d_i]["x"] - c["x"]) < 24:
                drinks.remove_at(d_i)
                c["x"] = map_w * 0.84
                mugs.append({"lane": c["lane"], "x": map_w * 0.72})
                score += 75
                _emit_score()
    for m_i in range(mugs.size() - 1, -1, -1):
        mugs[m_i]["x"] -= 190 * delta
        if mugs[m_i]["lane"] == lane and abs(mugs[m_i]["x"] - map_w * 0.2) < 28:
            mugs.remove_at(m_i)
            score += 25
            _emit_score()
        elif mugs[m_i]["x"] < 0:
            mugs.remove_at(m_i)
            _lose_life()

func _tick_tempest(delta):
    tube_move_cool = max(0.0, tube_move_cool - delta)
    if tube_move_cool <= 0.0 and (Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)):
        tube_lane = (tube_lane - 1 + tube_lanes) % tube_lanes
        tube_move_cool = 0.12
    if tube_move_cool <= 0.0 and (Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)):
        tube_lane = (tube_lane + 1) % tube_lanes
        tube_move_cool = 0.12
    player["cool"] = max(0.0, player["cool"] - delta)
    if _action() and player["cool"] <= 0:
        bullets.append({"lane": tube_lane, "depth": 1.0, "vel": -1.8, "ttl": 1.0, "kind": "tube"})
        player["cool"] = 0.16
    if Input.is_key_pressed(KEY_SHIFT) and zapper_ready:
        zapper_ready = false
        score += tube_enemies.size() * 50
        tube_enemies.clear()
        _emit_score()
    if tube_enemies.size() < 8 + wave and randf() < delta * 1.5:
        tube_enemies.append({"lane": randi() % tube_lanes, "depth": 0.03, "speed": randf_range(0.1, 0.18)})
    for i in range(tube_enemies.size() - 1, -1, -1):
        tube_enemies[i]["depth"] += tube_enemies[i]["speed"] * delta
        if tube_enemies[i]["depth"] > 0.98 and tube_enemies[i]["lane"] == tube_lane:
            _lose_life()
            tube_enemies.remove_at(i)
    for b in bullets:
        if b["kind"] == "tube":
            b["depth"] += b["vel"] * delta
            b["ttl"] -= delta
            for i in range(tube_enemies.size() - 1, -1, -1):
                if tube_enemies[i]["lane"] == b["lane"] and abs(tube_enemies[i]["depth"] - b["depth"]) < 0.08:
                    tube_enemies.remove_at(i)
                    b["ttl"] = 0
                    score += 80
                    _emit_score()
                    break

func _platform_move(delta, can_jump: bool):
    var v = _move_vec()
    var pos = player["pos"]
    var vel = player["vel"]
    vel.x = v.x * 190
    var on_ladder = _on_ladder(pos)
    if on_ladder and abs(v.y) > 0.1:
        vel.y = v.y * 145
    else:
        vel.y += 520 * delta
        if can_jump and _action() and player["on_ground"]:
            vel.y = -310
    pos += vel * delta
    player["on_ground"] = false
    for p in platforms:
        if pos.y < p.position.y and pos.y + 20 >= p.position.y and pos.x >= p.position.x and pos.x <= p.position.x + p.size.x and vel.y >= 0:
            pos.y = p.position.y - 20
            vel.y = 0
            player["on_ground"] = true
    player["pos"] = _clamp(pos)
    player["vel"] = vel

func _platform_y(pos: Vector2) -> float:
    var best = map_h * 0.9
    var best_d = 99999.0
    for p in platforms:
        if pos.x >= p.position.x - 20 and pos.x <= p.position.x + p.size.x + 20:
            var d = abs(pos.y - p.position.y)
            if d < best_d:
                best_d = d
                best = p.position.y
    return best

func _on_ladder(pos: Vector2) -> bool:
    for l in ladders:
        if l.grow(16).has_point(pos):
            return true
    return false

func _tick_bullets(delta):
    for i in range(bullets.size() - 1, -1, -1):
        var b = bullets[i]
        if b.get("kind", "") == "tube":
            if b["ttl"] <= 0:
                bullets.remove_at(i)
            continue
        b["pos"] += b["vel"] * delta
        b["ttl"] -= delta
        if b["ttl"] <= 0 or b["pos"].x < -60 or b["pos"].x > map_w + 60 or b["pos"].y < -60 or b["pos"].y > map_h + 60:
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
    if game_id == "donkey_kong":
        _draw_platform_game(barrels, C_ORANGE)
    elif game_id == "breakout":
        _draw_breakout()
    elif game_id == "bubble_bobble":
        _draw_platform_game(bubbles, C_CYAN)
    elif game_id == "dig_dug":
        _draw_drill()
    elif game_id == "gauntlet":
        _draw_dungeon()
    elif game_id == "marble_madness":
        _draw_marble()
    elif game_id == "joust":
        _draw_platform_game(enemies, C_MAGENTA)
    elif game_id == "snake":
        _draw_snake()
    elif game_id == "tapper":
        _draw_tapper()
    elif game_id == "tempest":
        _draw_tempest()
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

func _draw_platform_game(things, color: Color):
    for p in platforms:
        _draw_girder(p, C_CYAN)
    for l in ladders:
        _draw_ladder(l, C_GREEN)
    for t in things:
        var pos = t.get("pos", Vector2.ZERO)
        if t.has("egg") and t["egg"]:
            _draw_egg(pos, C_YELLOW)
        else:
            _draw_platform_enemy(pos, color)
    for e in enemies:
        if not things.has(e):
            _draw_platform_enemy(e["pos"], C_MAGENTA)
    for bub in bubbles:
        _draw_bubble(bub["pos"], C_CYAN)
    for item in items:
        _draw_pickup(item["pos"], C_YELLOW)
    _draw_little_hero(player["pos"], C_GREEN)

func _draw_breakout():
    for br in bricks:
        var col = [C_CYAN, C_MAGENTA, C_YELLOW][br["kind"] % 3]
        draw_rect(br["rect"], Color(col.r, col.g, col.b, 0.22), true)
        draw_rect(br["rect"], col, false, 2)
    _glow_line(Vector2(paddle_x - 70, map_h * 0.87), Vector2(paddle_x + 70, map_h * 0.87), C_CYAN, 5)
    _glow_circle(ball["pos"], 9, C_YELLOW)

func _draw_drill():
    for y in range(grid.size()):
        for x in range(grid[y].size()):
            if int(grid[y][x]) == 1:
                var r = Rect2(x * cell_px, y * cell_px, cell_px, cell_px)
                draw_rect(r, Color(C_ORANGE.r, C_ORANGE.g, C_ORANGE.b, 0.12), true)
                draw_rect(r, Color(1, 1, 1, 0.16), false, 1)
    for r in rocks:
        _draw_rock(r["pos"], C_DIM)
    for e in enemies:
        _draw_drill_enemy(e["pos"], C_MAGENTA if e["ghost"] else C_RED, 13 + e["inflate"] * 4)
    for b in bullets:
        if b.get("kind", "") == "pump":
            _glow_line(player["pos"], b["pos"], C_YELLOW, 2)
    _draw_digger(player["pos"], C_CYAN)

func _draw_dungeon():
    for g in generators:
        _draw_generator(g["pos"], C_MAGENTA)
    for item in items:
        _draw_pickup(item["pos"], C_GREEN if item["kind"] == "food" else C_YELLOW)
    for e in enemies:
        _draw_dungeon_enemy(e["pos"], C_RED)
    for b in bullets:
        _glow_circle(b["pos"], 4, C_YELLOW)
    _draw_warrior(player["pos"], C_CYAN)

func _draw_marble():
    var last = null
    for item in items:
        var col = C_GREEN if item["hit"] else C_CYAN
        _glow_circle_outline(item["pos"], 17, col, 2)
        if last != null:
            _glow_line(last, item["pos"], C_CYAN, 1.5)
        last = item["pos"]
    for h in hazards:
        _glow_circle_outline(h["pos"], h["r"], C_RED, 2)
    _draw_marble_ball(player["pos"], C_YELLOW)

func _draw_snake():
    for i in range(snake.size()):
        _glow_circle(_cell_center(snake[i]), cell_px * 0.36, C_GREEN if i == 0 else C_CYAN)
    _glow_circle(_cell_center(food_cell), cell_px * 0.32, C_YELLOW)

func _draw_tapper():
    for i in range(platforms.size()):
        var p = platforms[i]
        _draw_bar_counter(p, C_CYAN)
    for c in customers:
        _draw_customer(Vector2(c["x"], platforms[c["lane"]].position.y - 18), C_MAGENTA)
    for d in drinks:
        _draw_mug(Vector2(d["x"], platforms[d["lane"]].position.y - 8), C_YELLOW)
    for m in mugs:
        _draw_mug(Vector2(m["x"], platforms[m["lane"]].position.y - 10), C_GREEN)
    _draw_bartender(player["pos"] - Vector2(0, 18), C_GREEN)

func _draw_tempest():
    var center = Vector2(map_w * 0.5, map_h * 0.52)
    var outer = min(map_w, map_h) * 0.42
    var inner = outer * 0.16
    for i in range(tube_lanes):
        var a = TAU * i / tube_lanes - PI * 0.5
        var p1 = center + Vector2(cos(a), sin(a)) * inner
        var p2 = center + Vector2(cos(a), sin(a)) * outer
        _glow_line(p1, p2, C_CYAN if i == tube_lane else Color(0.5, 0.7, 0.8), 1.4)
    for e in tube_enemies:
        var a = TAU * e["lane"] / tube_lanes - PI * 0.5
        var r = lerp(inner, outer, e["depth"])
        _draw_tube_claw(center + Vector2(cos(a), sin(a)) * r, a, C_MAGENTA)
    for b in bullets:
        if b.get("kind", "") == "tube":
            var a = TAU * b["lane"] / tube_lanes - PI * 0.5
            var r = lerp(inner, outer, b["depth"])
            _glow_circle(center + Vector2(cos(a), sin(a)) * r, 5, C_YELLOW)
    var pa = TAU * tube_lane / tube_lanes - PI * 0.5
    _draw_tube_ship(center + Vector2(cos(pa), sin(pa)) * outer, pa, C_GREEN)

func _draw_girder(rect: Rect2, color: Color):
    _glow_line(rect.position, rect.position + Vector2(rect.size.x, 0), color, 2.6)
    var y = rect.position.y + 7
    _glow_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), color, 1.0)
    for x in range(int(rect.position.x), int(rect.position.x + rect.size.x), 42):
        _glow_line(Vector2(x, rect.position.y), Vector2(x + 24, y), color, 0.8)

func _draw_ladder(rect: Rect2, color: Color):
    var x1 = rect.position.x - 6
    var x2 = rect.position.x + 6
    _glow_line(Vector2(x1, rect.position.y), Vector2(x1, rect.position.y + rect.size.y), color, 1.1)
    _glow_line(Vector2(x2, rect.position.y), Vector2(x2, rect.position.y + rect.size.y), color, 1.1)
    for y in range(int(rect.position.y), int(rect.position.y + rect.size.y), 20):
        _glow_line(Vector2(x1, y), Vector2(x2, y), color, 0.8)

func _draw_little_hero(pos: Vector2, color: Color):
    _glow_circle(pos + Vector2(0, -12), 7, color)
    draw_rect(Rect2(pos + Vector2(-9, -4), Vector2(18, 22)), Color(color.r, color.g, color.b, 0.16), true)
    draw_rect(Rect2(pos + Vector2(-9, -4), Vector2(18, 22)), color, false, 1.3)
    _glow_line(pos + Vector2(-10, 2), pos + Vector2(-18, 11), color, 1.0)
    _glow_line(pos + Vector2(10, 2), pos + Vector2(18, 11), color, 1.0)
    _glow_line(pos + Vector2(-4, 18), pos + Vector2(-10, 28), color, 1.0)
    _glow_line(pos + Vector2(4, 18), pos + Vector2(10, 28), color, 1.0)
    draw_circle(pos + Vector2(-3, -13), 1.8, Color.WHITE)
    draw_circle(pos + Vector2(3, -13), 1.8, Color.WHITE)

func _draw_platform_enemy(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 13, color, 2)
    _glow_line(pos + Vector2(-11, 8), pos + Vector2(-19, 16), color, 1.0)
    _glow_line(pos + Vector2(11, 8), pos + Vector2(19, 16), color, 1.0)
    draw_circle(pos + Vector2(-4, -3), 2.0, Color.WHITE)
    draw_circle(pos + Vector2(4, -3), 2.0, Color.WHITE)

func _draw_egg(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 11, color, 2)
    draw_arc(pos + Vector2(0, -2), 7, PI * 0.15, PI * 0.85, 12, Color.WHITE, 1.0)

func _draw_bubble(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 17, color, 2)
    draw_arc(pos + Vector2(-4, -5), 7, PI, TAU * 0.88, 12, Color.WHITE, 1.1)

func _draw_pickup(pos: Vector2, color: Color):
    var pts = PackedVector2Array([pos + Vector2(0, -14), pos + Vector2(13, 0), pos + Vector2(0, 14), pos + Vector2(-13, 0)])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.18))
    for i in range(4):
        _glow_line(pts[i], pts[(i + 1) % 4], color, 1.1)

func _draw_rock(pos: Vector2, color: Color):
    var pts = PackedVector2Array([pos + Vector2(-15, -5), pos + Vector2(-6, -17), pos + Vector2(13, -11), pos + Vector2(17, 8), pos + Vector2(0, 17), pos + Vector2(-17, 9)])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.15))
    for i in range(pts.size()):
        _glow_line(pts[i], pts[(i + 1) % pts.size()], color, 1.1)

func _draw_drill_enemy(pos: Vector2, color: Color, radius: float):
    _glow_circle_outline(pos, radius, color, 2)
    draw_circle(pos + Vector2(-5, -3), 2.0, Color.WHITE)
    draw_circle(pos + Vector2(5, -3), 2.0, Color.WHITE)
    _glow_line(pos + Vector2(-radius * 0.6, 8), pos + Vector2(-radius, 18), color, 1.0)
    _glow_line(pos + Vector2(radius * 0.6, 8), pos + Vector2(radius, 18), color, 1.0)

func _draw_digger(pos: Vector2, color: Color):
    _draw_little_hero(pos, color)
    var drill = PackedVector2Array([pos + Vector2(13, -5), pos + Vector2(31, 0), pos + Vector2(13, 5)])
    draw_colored_polygon(drill, Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.22))
    for i in range(3):
        _glow_line(drill[i], drill[(i + 1) % 3], C_YELLOW, 0.9)

func _draw_generator(pos: Vector2, color: Color):
    _glow_circle_outline(pos, 22, color, 3)
    for a in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
        _glow_line(pos, pos + Vector2(cos(a), sin(a)) * 22, color, 1.0)

func _draw_dungeon_enemy(pos: Vector2, color: Color):
    var pts = PackedVector2Array([pos + Vector2(0, -14), pos + Vector2(-14, 2), pos + Vector2(-8, 16), pos + Vector2(8, 16), pos + Vector2(14, 2)])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.16))
    for i in range(pts.size()):
        _glow_line(pts[i], pts[(i + 1) % pts.size()], color, 1.1)
    draw_circle(pos + Vector2(-4, 0), 2.0, Color.WHITE)
    draw_circle(pos + Vector2(4, 0), 2.0, Color.WHITE)

func _draw_warrior(pos: Vector2, color: Color):
    _draw_little_hero(pos, color)
    _glow_line(pos + Vector2(14, -6), pos + Vector2(28, -20), C_YELLOW, 1.2)
    _glow_circle_outline(pos + Vector2(-17, 0), 8, C_MAGENTA, 1.4)

func _draw_marble_ball(pos: Vector2, color: Color):
    _glow_circle(pos, 15, color)
    draw_arc(pos, 10, -PI * 0.2, PI * 0.7, 20, Color.WHITE, 1.2)
    draw_arc(pos, 6, PI * 0.8, PI * 1.6, 16, Color(1, 1, 1, 0.6), 1.0)

func _draw_bar_counter(rect: Rect2, color: Color):
    draw_rect(Rect2(rect.position + Vector2(0, -6), Vector2(rect.size.x, 12)), Color(color.r, color.g, color.b, 0.12), true)
    _glow_line(rect.position, rect.position + Vector2(rect.size.x, 0), color, 3)
    for x in range(int(rect.position.x + 24), int(rect.position.x + rect.size.x), 64):
        _glow_line(Vector2(x, rect.position.y - 6), Vector2(x, rect.position.y + 6), color, 0.8)

func _draw_customer(pos: Vector2, color: Color):
    _draw_little_hero(pos, color)
    _glow_line(pos + Vector2(-10, -20), pos + Vector2(10, -20), color, 1.0)

func _draw_mug(pos: Vector2, color: Color):
    draw_rect(Rect2(pos + Vector2(-6, -8), Vector2(12, 16)), Color(color.r, color.g, color.b, 0.18), true)
    draw_rect(Rect2(pos + Vector2(-6, -8), Vector2(12, 16)), color, false, 1.2)
    draw_arc(pos + Vector2(7, 0), 5, -PI * 0.5, PI * 0.5, 10, color, 1.2)
    _glow_line(pos + Vector2(-5, -10), pos + Vector2(5, -10), Color.WHITE, 0.7)

func _draw_bartender(pos: Vector2, color: Color):
    _draw_little_hero(pos, color)
    _glow_line(pos + Vector2(12, 2), pos + Vector2(26, -5), C_YELLOW, 1.2)

func _draw_tube_claw(pos: Vector2, angle: float, color: Color):
    _glow_circle_outline(pos, 10, color, 1.8)
    var n = Vector2(cos(angle), sin(angle))
    var s = n.orthogonal()
    _glow_line(pos, pos - n * 15 + s * 9, color, 1.0)
    _glow_line(pos, pos - n * 15 - s * 9, color, 1.0)

func _draw_tube_ship(pos: Vector2, angle: float, color: Color):
    var n = Vector2(cos(angle), sin(angle))
    var s = n.orthogonal()
    var pts = PackedVector2Array([pos + n * 18, pos - n * 13 + s * 11, pos - n * 6, pos - n * 13 - s * 11])
    draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.16))
    for i in range(pts.size()):
        _glow_line(pts[i], pts[(i + 1) % pts.size()], color, 1.1)

func _draw_hud():
    var font = ThemeDB.fallback_font
    draw_string(font, Vector2(18, 34), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    var extra = ""
    if game_id == "marble_madness":
        extra = " TIME " + str(int(time_left))
    elif game_id == "gauntlet":
        extra = " HP " + str(int(player.get("health", 100)))
    elif game_id == "tempest":
        extra = " ZAP " + ("READY" if zapper_ready else "USED")
    draw_string(font, Vector2(18, 64), "SCORE " + str(score) + "  LIVES " + str(lives) + extra, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C_CYAN)
    if paused:
        draw_string(font, get_viewport_rect().size * 0.5, "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, -1, 46, Color.WHITE)
    elif state == "game_over":
        draw_string(font, get_viewport_rect().size * 0.5, "GAME OVER - ENTER", HORIZONTAL_ALIGNMENT_CENTER, -1, 44, C_RED)
    elif state == "win":
        draw_string(font, get_viewport_rect().size * 0.5, "WAVE CLEAR - ENTER", HORIZONTAL_ALIGNMENT_CENTER, -1, 44, C_GREEN)

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

func _action() -> bool:
    return Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_A)

func _aim_dir() -> Vector2:
    var v = Vector2.ZERO
    if Input.is_key_pressed(KEY_J):
        v.x -= 1
    if Input.is_key_pressed(KEY_L):
        v.x += 1
    if Input.is_key_pressed(KEY_I):
        v.y -= 1
    if Input.is_key_pressed(KEY_K):
        v.y += 1
    if v == Vector2.ZERO:
        v = _move_vec()
    if v == Vector2.ZERO:
        v = Vector2.RIGHT
    return v.normalized()

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

func _pos_to_cell(pos: Vector2) -> Vector2i:
    return Vector2i(int(pos.x / cell_px), int(pos.y / cell_px))

func _cell_center(c: Vector2i) -> Vector2:
    return Vector2((c.x + 0.5) * cell_px, (c.y + 0.5) * cell_px)

func _clamp(pos: Vector2) -> Vector2:
    return Vector2(clamp(pos.x, 0, map_w), clamp(pos.y, 0, map_h))

func _spawn_food():
    var tries = 0
    while tries < 100:
        var c = walkable[randi() % walkable.size()] if not walkable.is_empty() else Vector2i(4, 4)
        if not snake.has(c):
            food_cell = c
            return
        tries += 1
    food_cell = _find_nearest_walkable_cell(Vector2i(2, 2))

func _lose_life():
    lives -= 1
    _burst(player.get("pos", Vector2(map_w * 0.5, map_h * 0.5)), C_RED, 24)
    if lives <= 0:
        state = "game_over"
        send_ipc_message({"type": "state", "data": {"state": "game_over"}})
    else:
        player["pos"] = _safe_pos(Vector2(map_w * 0.18, map_h * 0.78))
        player["vel"] = Vector2.ZERO
        send_ipc_message({"type": "state", "data": {"state": "life_lost", "lives": lives}})

func _win_wave():
    score += 500
    _emit_score()
    state = "win"
    send_ipc_message({"type": "state", "data": {"state": "win"}})

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
