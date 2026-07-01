extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()

const C_CYAN = Color(0.0, 0.9, 1.0)
const C_GREEN = Color(0.0, 0.9, 0.46)
const C_MAGENTA = Color(1.0, 0.18, 0.77)
const C_YELLOW = Color(1.0, 0.83, 0.0)
const C_RED = Color(1.0, 0.08, 0.12)
const C_ORANGE = Color(1.0, 0.48, 0.0)
const C_DIM = Color(0.5, 0.55, 0.6)
const C_ROAD = Color(0.18, 0.20, 0.27)
const C_SIDEWALK = Color(0.35, 0.38, 0.38)
const C_BUILDING = Color(0.04, 0.05, 0.07)

const CLASS_EMPTY = 0
const CLASS_SOLID = 1
const CLASS_PATH = 2
const CLASS_SPAWN = 5
const CLASS_GOAL = 6
const CLASS_PICKUP = 7
const CLASS_TRACKING = 8
const CLASS_UI_SAFE = 9

var scene_dir = ""
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
var scale_factor = 1.0
var draw_offset = Vector2.ZERO
var cell_px = 16.0
var grid_w = 80
var grid_h = 45
var grid = []
var road_cells = []
var sidewalk_cells = []
var walkable_cells = []
var solid_cells = []
var phone_points = []
var pickup_points = []
var spawn_points = []

var score = 0
var lives = 3
var cash = 0
var ammo = 12
var wanted = 0
var wanted_heat = 0.0
var game_state = "playing"
var tab_menu = null
var shared_loader_script = null
var region_adapter_script = null
var loaded_level_key = ""

var player = {"pos": Vector2(120, 120), "vel": Vector2.ZERO, "facing": Vector2.RIGHT, "in_car": false, "car": -1, "cool": 0.0}
var pedestrians = []
var cars = []
var cops = []
var bullets = []
var drops = []
var particles = []

var mission_state = "phone"
var active_phone = Vector2.ZERO
var active_pickup = Vector2.ZERO
var active_drop = Vector2.ZERO
var has_package = false
var phone_flash = 0.0
var spawn_timer = 0.0
var cop_timer = 0.0
var action_was_down = false
var shoot_was_down = false

func _ready():
    randomize()
    RenderingServer.set_default_clear_color(Color.BLACK)
    _parse_args()
    shared_loader_script = load(_shared_loader_path())
    if shared_loader_script == null:
        push_error("GTA could not load app/shared/shared_loader.gd")
    _setup_tab_menu()
    _connect_ipc()
    load_level()
    reset_game()
    _update_scale()
    if screenshot_path != "":
        for _i in range(8):
            await get_tree().process_frame
        var img = get_viewport().get_texture().get_image()
        if img == null:
            print("GTA screenshot skipped: viewport image unavailable for this display driver")
        else:
            var err = img.save_png(screenshot_path)
            print("GTA screenshot saved: ", screenshot_path, " err=", err)
        get_tree().quit()

func _shared_loader_path() -> String:
    var root = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir().get_base_dir().get_base_dir()
    return root.path_join("app").path_join("shared").path_join("shared_loader.gd")

func _setup_tab_menu():
    if shared_loader_script == null:
        return
    var tab_script = shared_loader_script.load_tab_menu_script()
    if tab_script == null:
        push_error("GTA could not load shared TabMenu")
        return
    tab_menu = tab_script.new()
    add_child(tab_menu)
    tab_menu.register_knob_float("block_size", "Block Size", 1.0, 0.5, 2.0, 0.1)
    tab_menu.register_knob_bool("invert", "Invert", false)
    tab_menu.register_knob_float("density", "Density", 1.0, 0.1, 2.0, 0.1)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true)
    tab_menu.register_knob_bool("smooth", "Smooth", false)
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    tab_menu.setup("gta", level_dir, "GTA")

func _on_knob_changed(knob_id: String, value):
    load_level()
    queue_redraw()

func _on_menu_action(action_id: String):
    pass

func _notification(what):
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _update_scale()

func _parse_args():
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    var i = 0
    while i < args.size():
        var a = args[i]
        if a == "--scene" and i + 1 < args.size():
            scene_dir = args[i + 1]
            i += 1
        elif a == "--level" and i + 1 < args.size():
            level_dir = args[i + 1]
            i += 1
        elif a == "--ipc" and i + 1 < args.size():
            _parse_ipc(args[i + 1])
            i += 1
        elif a == "--screenshot" and i + 1 < args.size():
            screenshot_path = args[i + 1]
            i += 1
        i += 1

func _parse_ipc(value: String):
    var parts = value.split(":")
    if parts.size() >= 2:
        ipc_host = parts[0]
        ipc_port = int(parts[1])
    elif value.is_valid_int():
        ipc_port = int(value)

func _connect_ipc():
    if ipc_port <= 0:
        return
    ipc_socket = StreamPeerTCP.new()
    ipc_socket.connect_to_host(ipc_host, ipc_port)

func load_level():
    loaded_level_key = level_dir
    if shared_loader_script == null:
        _build_fallback_grid()
        _collect_cells()
        _update_scale()
        return
    if region_adapter_script == null:
        region_adapter_script = shared_loader_script.load_adapter_script("region")
    if region_adapter_script == null:
        _build_fallback_grid()
        _collect_cells()
        _update_scale()
        return
    var adapter = region_adapter_script.new()
    var knobs = {}
    if tab_menu:
        knobs = {
            "block_size": tab_menu.get_knob_value("block_size"),
            "invert": tab_menu.get_knob_value("invert"),
            "density": tab_menu.get_knob_value("density"),
            "bounds_clamp": tab_menu.get_knob_value("bounds_clamp"),
            "smooth": tab_menu.get_knob_value("smooth")
        }
    var layout = adapter.interpret(level_dir, {}, knobs)
    
    cell_px = layout.get("cell_size", 16.0)
    var b = layout.get("bounds", Rect2(0, 0, 1280, 720))
    map_w = b.size.x
    map_h = b.size.y
    grid = layout.get("cells", [])
    var used_fallback = grid.is_empty()
    
    if grid.is_empty():
        _build_fallback_grid()
    else:
        grid_h = grid.size()
        grid_w = grid[0].size() if grid_h > 0 else 0

    print("[GTA] SharedLoader RegionAdapter level=", level_dir, " grid=", grid_w, "x", grid_h, " cell_px=", cell_px, " fallback=", used_fallback)
    _collect_cells()
    _update_scale()
func _update_scale():
    var vp = get_viewport_rect().size
    if map_w <= 0.0 or map_h <= 0.0 or vp.x <= 0.0 or vp.y <= 0.0:
        return
    scale_factor = min(vp.x / map_w, vp.y / map_h)
    draw_offset = Vector2((vp.x - map_w * scale_factor) * 0.5, (vp.y - map_h * scale_factor) * 0.5)

func _build_fallback_grid():
    grid = []
    grid_w = int(map_w / cell_px)
    grid_h = int(map_h / cell_px)
    for y in range(grid_h):
        var row = []
        for x in range(grid_w):
            var v = CLASS_SOLID
            if x % 18 in range(6, 12) or y % 14 in range(5, 9):
                v = CLASS_PATH
            elif x % 18 in range(4, 14) or y % 14 in range(3, 11):
                v = CLASS_TRACKING
            row.append(v)
        grid.append(row)
    grid[6][6] = CLASS_SPAWN
    grid[8][24] = CLASS_GOAL
    grid[30][56] = CLASS_GOAL
    grid[20][42] = CLASS_PICKUP

func _collect_cells():
    road_cells.clear()
    sidewalk_cells.clear()
    walkable_cells.clear()
    solid_cells.clear()
    phone_points.clear()
    pickup_points.clear()
    spawn_points.clear()
    for y in range(grid_h):
        for x in range(grid_w):
            var c = Vector2i(x, y)
            var v = _cell_class(c)
            if v == CLASS_PATH:
                road_cells.append(c)
                walkable_cells.append(c)
            elif v == CLASS_TRACKING or v == CLASS_UI_SAFE:
                sidewalk_cells.append(c)
                walkable_cells.append(c)
            elif v == CLASS_SPAWN:
                spawn_points.append(c)
                sidewalk_cells.append(c)
                walkable_cells.append(c)
            elif v == CLASS_GOAL:
                phone_points.append(_cell_center(c))
                sidewalk_cells.append(c)
                walkable_cells.append(c)
            elif v == CLASS_PICKUP:
                pickup_points.append(_cell_center(c))
                sidewalk_cells.append(c)
                walkable_cells.append(c)
            elif v == CLASS_SOLID:
                solid_cells.append(c)
    if road_cells.is_empty():
        road_cells = walkable_cells.duplicate()
    if sidewalk_cells.is_empty():
        sidewalk_cells = walkable_cells.duplicate()
    if phone_points.is_empty() and not sidewalk_cells.is_empty():
        phone_points.append(_cell_center(sidewalk_cells[0]))
    if pickup_points.is_empty() and sidewalk_cells.size() > 2:
        pickup_points.append(_cell_center(sidewalk_cells[int(sidewalk_cells.size() / 2)]))

func reset_game():
    score = 0
    lives = 3
    cash = 0
    ammo = 12
    wanted = 0
    wanted_heat = 0.0
    game_state = "playing"
    pedestrians.clear()
    cars.clear()
    cops.clear()
    bullets.clear()
    drops.clear()
    particles.clear()
    var spawn_cell = spawn_points[0] if not spawn_points.is_empty() else _find_nearest_walkable_cell(Vector2i(5, 5))
    player = {"pos": _cell_center(spawn_cell), "vel": Vector2.ZERO, "facing": Vector2.RIGHT, "in_car": false, "car": -1, "cool": 0.0}
    for i in range(26):
        _spawn_pedestrian()
    for i in range(16):
        _spawn_car()
    _ring_next_phone()
    _emit_score()

func _process(delta):
    _pump_ipc()
    heartbeat_timer += delta
    if heartbeat_timer >= 1.0:
        heartbeat_timer = 0.0
        _send_ipc({"type": "heartbeat", "data": {"score": score, "wanted": wanted}})
    if paused or blanked or game_state != "playing":
        queue_redraw()
        return
    _tick(delta)
    queue_redraw()

func _tick(delta):
    phone_flash += delta
    player["cool"] = max(0.0, player["cool"] - delta)
    _tick_input(delta)
    _tick_pedestrians(delta)
    _tick_cars(delta)
    _tick_cops(delta)
    _tick_bullets(delta)
    _tick_drops(delta)
    _tick_mission(delta)
    _tick_particles(delta)
    _tick_wanted(delta)

func _tick_input(delta):
    var move = _input_vec()
    var action_down = Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_A)
    var shoot_down = Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_CTRL) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_RIGHT_SHOULDER)
    var action_pressed = action_down and not action_was_down
    var shoot_pressed = shoot_down and not shoot_was_down
    action_was_down = action_down
    shoot_was_down = shoot_down
    if move.length() > 0.05:
        player["facing"] = move.normalized()
    if player["in_car"]:
        _drive_player_car(move, delta)
        if action_pressed:
            _exit_car()
    else:
        var next = player["pos"] + move * 145.0 * delta
        if _walkable_at(next):
            player["pos"] = _clamp_world(next)
        if action_pressed:
            if _try_answer_phone():
                return
            if _try_enter_car():
                return
        if shoot_pressed:
            _shoot()

func _drive_player_car(move: Vector2, delta: float):
    var idx = int(player["car"])
    if idx < 0 or idx >= cars.size():
        player["in_car"] = false
        player["car"] = -1
        return
    var car = cars[idx]
    if move.length() > 0.05:
        car["dir"] = move.normalized()
        car["speed"] = min(380.0, float(car["speed"]) + 520.0 * delta)
    else:
        car["speed"] = max(0.0, float(car["speed"]) - 430.0 * delta)
    var next = car["pos"] + car["dir"] * float(car["speed"]) * delta
    if _solid_at(next):
        car["speed"] = 0.0
        _raise_wanted(1)
        _burst(car["pos"], C_ORANGE, 12)
    else:
        car["pos"] = _clamp_world(next)
    car["angle"] = float(car["dir"].angle())
    cars[idx] = car
    player["pos"] = car["pos"]
    _check_vehicle_collisions(idx)

func _try_enter_car() -> bool:
    var best = -1
    var best_d = 999999.0
    for i in range(cars.size()):
        if bool(cars[i].get("occupied", false)):
            continue
        var d = player["pos"].distance_squared_to(cars[i]["pos"])
        if d < best_d and d < 36.0 * 36.0:
            best = i
            best_d = d
    if best < 0:
        return false
    cars[best]["occupied"] = true
    cars[best]["speed"] = 0.0
    player["in_car"] = true
    player["car"] = best
    player["pos"] = cars[best]["pos"]
    _raise_wanted(1)
    return true

func _exit_car():
    var idx = int(player["car"])
    if idx < 0 or idx >= cars.size():
        player["in_car"] = false
        player["car"] = -1
        return
    var car_pos = cars[idx]["pos"]
    var exit_cell = _find_nearest_sidewalk_cell(_pos_to_cell(car_pos))
    player["pos"] = _cell_center(exit_cell)
    cars[idx]["occupied"] = false
    cars[idx]["speed"] = min(float(cars[idx]["speed"]), 80.0)
    player["in_car"] = false
    player["car"] = -1

func _shoot():
    if ammo <= 0 or player["cool"] > 0.0:
        return
    ammo -= 1
    player["cool"] = 0.18
    var dir = Vector2(player["facing"])
    if dir == Vector2.ZERO:
        dir = Vector2.RIGHT
    bullets.append({"pos": player["pos"] + dir * 18.0, "vel": dir * 520.0, "life": 0.75})
    _raise_wanted(1)

func _tick_pedestrians(delta):
    for i in range(pedestrians.size() - 1, -1, -1):
        var p = pedestrians[i]
        p["turn"] = max(0.0, float(p["turn"]) - delta)
        if float(p["turn"]) <= 0.0:
            p["dir"] = _random_sidewalk_dir(p["pos"])
            p["turn"] = randf_range(0.6, 2.0)
        var next = p["pos"] + p["dir"] * float(p["speed"]) * delta
        if _sidewalk_at(next) or _walkable_at(next):
            p["pos"] = next
        else:
            p["turn"] = 0.0
        pedestrians[i] = p

func _tick_cars(delta):
    for i in range(cars.size()):
        if bool(cars[i].get("occupied", false)):
            continue
        var car = cars[i]
        var next = car["pos"] + car["dir"] * float(car["speed"]) * delta
        if not _road_at(next) or randf() < 0.01:
            car["dir"] = _random_road_dir(car["pos"])
            car["speed"] = randf_range(70.0, 150.0)
            next = car["pos"] + car["dir"] * float(car["speed"]) * delta
        if _road_at(next):
            car["pos"] = next
        car["angle"] = float(car["dir"].angle())
        cars[i] = car

func _tick_cops(delta):
    cop_timer -= delta
    if wanted > 0 and cop_timer <= 0.0 and cops.size() < wanted * 3:
        _spawn_cop()
        cop_timer = max(0.6, 2.3 - wanted * 0.28)
    for i in range(cops.size() - 1, -1, -1):
        var c = cops[i]
        var to_player = player["pos"] - c["pos"]
        var dir = to_player.normalized() if to_player.length() > 2 else Vector2.ZERO
        var speed = 100.0 + wanted * 22.0
        var next = c["pos"] + dir * speed * delta
        if _walkable_at(next):
            c["pos"] = next
        cops[i] = c
        if c["pos"].distance_to(player["pos"]) < (24.0 if player["in_car"] else 16.0):
            _lose_life()
            return

func _tick_bullets(delta):
    for i in range(bullets.size() - 1, -1, -1):
        var b = bullets[i]
        b["pos"] += b["vel"] * delta
        b["life"] -= delta
        var hit = false
        for p_i in range(pedestrians.size() - 1, -1, -1):
            if pedestrians[p_i]["pos"].distance_to(b["pos"]) < 13:
                _drop_loot(pedestrians[p_i]["pos"])
                _burst(pedestrians[p_i]["pos"], C_RED, 14)
                pedestrians.remove_at(p_i)
                score += 25
                _raise_wanted(1)
                _emit_score()
                hit = true
                break
        if not hit:
            for c_i in range(cops.size() - 1, -1, -1):
                if cops[c_i]["pos"].distance_to(b["pos"]) < 15:
                    _burst(cops[c_i]["pos"], C_MAGENTA, 18)
                    cops.remove_at(c_i)
                    score += 100
                    _raise_wanted(2)
                    _emit_score()
                    hit = true
                    break
        if hit or b["life"] <= 0.0 or not _walkable_at(b["pos"]):
            bullets.remove_at(i)
        else:
            bullets[i] = b

func _tick_drops(delta):
    for i in range(drops.size() - 1, -1, -1):
        drops[i]["life"] -= delta
        if drops[i]["pos"].distance_to(player["pos"]) < 18:
            if drops[i]["kind"] == "cash":
                cash += int(drops[i]["amount"])
                score += int(drops[i]["amount"])
            else:
                ammo += int(drops[i]["amount"])
            drops.remove_at(i)
            _emit_score()
        elif float(drops[i]["life"]) <= 0.0:
            drops.remove_at(i)

func _tick_mission(_delta):
    if mission_state == "pickup" and player["pos"].distance_to(active_pickup) < 24:
        has_package = true
        mission_state = "deliver"
        score += 100
        _emit_score()
    elif mission_state == "deliver" and player["pos"].distance_to(active_drop) < 28:
        has_package = false
        mission_state = "phone"
        cash += 100 + wanted * 25
        score += 500 + wanted * 100
        wanted = max(0, wanted - 1)
        _emit_score()
        _ring_next_phone()

func _tick_wanted(delta):
    if wanted <= 0:
        return
    wanted_heat = max(0.0, wanted_heat - delta)
    var nearest_cop = 999999.0
    for c in cops:
        nearest_cop = min(nearest_cop, c["pos"].distance_to(player["pos"]))
    if wanted_heat <= 0.0 and nearest_cop > 220.0:
        wanted = max(0, wanted - 1)
        wanted_heat = 7.0

func _tick_particles(delta):
    for i in range(particles.size() - 1, -1, -1):
        particles[i]["pos"] += particles[i]["vel"] * delta
        particles[i]["life"] -= delta
        if float(particles[i]["life"]) <= 0.0:
            particles.remove_at(i)

func _check_vehicle_collisions(car_idx: int):
    var pos = cars[car_idx]["pos"]
    var speed = float(cars[car_idx]["speed"])
    if speed < 120.0:
        return
    for i in range(pedestrians.size() - 1, -1, -1):
        if pedestrians[i]["pos"].distance_to(pos) < 22.0:
            _drop_loot(pedestrians[i]["pos"])
            _burst(pedestrians[i]["pos"], C_RED, 16)
            pedestrians.remove_at(i)
            _raise_wanted(1)
            score += 20
            _emit_score()
    for i in range(cars.size()):
        if i == car_idx or bool(cars[i].get("occupied", false)):
            continue
        if cars[i]["pos"].distance_to(pos) < 30.0:
            _burst(cars[i]["pos"], C_ORANGE, 14)
            cars[i]["dir"] = -cars[i]["dir"]
            cars[car_idx]["speed"] *= 0.45
            _raise_wanted(1)

func _try_answer_phone() -> bool:
    if mission_state != "phone":
        return false
    if player["pos"].distance_to(active_phone) > 32.0:
        return false
    mission_state = "pickup"
    active_pickup = _pick_far_point(pickup_points, active_phone)
    active_drop = _pick_far_point(phone_points, active_pickup)
    has_package = false
    score += 50
    _emit_score()
    return true

func _ring_next_phone():
    mission_state = "phone"
    active_phone = _pick_far_point(phone_points, player["pos"])
    active_pickup = _pick_far_point(pickup_points, active_phone)
    active_drop = _pick_far_point(phone_points, active_pickup)
    has_package = false

func _raise_wanted(amount: int):
    wanted = clamp(wanted + amount, 0, 5)
    wanted_heat = 9.0 + wanted * 3.0

func _lose_life():
    lives -= 1
    _burst(player["pos"], C_RED, 28)
    if lives <= 0:
        game_state = "game_over"
        _send_ipc({"type": "state", "data": {"state": "game_over"}})
        return
    wanted = max(0, wanted - 1)
    cops.clear()
    if player["in_car"]:
        _exit_car()
    player["pos"] = _cell_center(_find_nearest_walkable_cell(_pos_to_cell(player["pos"])))
    _send_ipc({"type": "state", "data": {"state": "life_lost", "lives": lives}})

func _drop_loot(pos: Vector2):
    if randf() < 0.65:
        drops.append({"pos": pos, "kind": "cash", "amount": randi_range(5, 35), "life": 8.0})
    elif randf() < 0.35:
        drops.append({"pos": pos, "kind": "ammo", "amount": randi_range(2, 6), "life": 8.0})

func _spawn_pedestrian():
    if sidewalk_cells.is_empty():
        return
    var c = sidewalk_cells[randi() % sidewalk_cells.size()]
    pedestrians.append({"pos": _cell_center(c), "dir": Vector2.RIGHT.rotated(randf() * TAU), "speed": randf_range(25.0, 55.0), "turn": randf_range(0.2, 1.4), "color": [C_GREEN, C_YELLOW, C_CYAN, C_MAGENTA][randi() % 4]})

func _spawn_car():
    if road_cells.is_empty():
        return
    var c = road_cells[randi() % road_cells.size()]
    var dir = _random_road_dir(_cell_center(c))
    cars.append({"pos": _cell_center(c), "dir": dir, "angle": dir.angle(), "speed": randf_range(70.0, 150.0), "occupied": false, "color": [C_CYAN, C_GREEN, C_YELLOW, C_MAGENTA, C_ORANGE][randi() % 5]})

func _spawn_cop():
    if road_cells.is_empty():
        return
    var best = road_cells[randi() % road_cells.size()]
    var best_d = -1.0
    for i in range(min(100, road_cells.size())):
        var c = road_cells[randi() % road_cells.size()]
        var d = _cell_center(c).distance_squared_to(player["pos"])
        if d > best_d:
            best_d = d
            best = c
    cops.append({"pos": _cell_center(best), "dir": Vector2.ZERO})

func _input_vec() -> Vector2:
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

func _random_sidewalk_dir(pos: Vector2) -> Vector2:
    return _random_dir_for(pos, true)

func _random_road_dir(pos: Vector2) -> Vector2:
    return _random_dir_for(pos, false)

func _random_dir_for(pos: Vector2, sidewalk: bool) -> Vector2:
    var cell = _pos_to_cell(pos)
    var dirs = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
    dirs.shuffle()
    for d in dirs:
        var p = _cell_center(cell + d)
        if sidewalk and (_sidewalk_at(p) or _walkable_at(p)):
            return Vector2(d)
        if not sidewalk and _road_at(p):
            return Vector2(d)
    return Vector2.RIGHT.rotated(randf() * TAU).normalized()

func _pick_far_point(points: Array, from: Vector2) -> Vector2:
    if points.is_empty():
        return _cell_center(_find_nearest_walkable_cell(_pos_to_cell(from)))
    var best = points[0]
    var best_d = -1.0
    for p in points:
        var d = p.distance_squared_to(from)
        if d > best_d:
            best_d = d
            best = p
    return best

func _walkable_at(pos: Vector2) -> bool:
    return _cell_walkable(_pos_to_cell(pos))

func _road_at(pos: Vector2) -> bool:
    return _cell_class(_pos_to_cell(pos)) == CLASS_PATH

func _sidewalk_at(pos: Vector2) -> bool:
    var v = _cell_class(_pos_to_cell(pos))
    return v == CLASS_TRACKING or v == CLASS_UI_SAFE or v == CLASS_SPAWN or v == CLASS_GOAL or v == CLASS_PICKUP

func _solid_at(pos: Vector2) -> bool:
    return _cell_class(_pos_to_cell(pos)) == CLASS_SOLID or not _in_bounds_cell(_pos_to_cell(pos))

func _cell_walkable(c: Vector2i) -> bool:
    var v = _cell_class(c)
    return v != CLASS_SOLID and _in_bounds_cell(c)

func _cell_class(c: Vector2i) -> int:
    if not _in_bounds_cell(c):
        return CLASS_SOLID
    return int(grid[c.y][c.x])

func _in_bounds_cell(c: Vector2i) -> bool:
    return c.x >= 0 and c.y >= 0 and c.x < grid_w and c.y < grid_h

func _pos_to_cell(pos: Vector2) -> Vector2i:
    return Vector2i(int(pos.x / cell_px), int(pos.y / cell_px))

func _cell_center(c: Vector2i) -> Vector2:
    return Vector2((c.x + 0.5) * cell_px, (c.y + 0.5) * cell_px)

func _clamp_world(pos: Vector2) -> Vector2:
    return Vector2(clamp(pos.x, 0.0, map_w), clamp(pos.y, 0.0, map_h))

func _find_nearest_walkable_cell(start: Vector2i) -> Vector2i:
    return _find_nearest_cell(start, "walk")

func _find_nearest_sidewalk_cell(start: Vector2i) -> Vector2i:
    return _find_nearest_cell(start, "sidewalk")

func _find_nearest_cell(start: Vector2i, kind: String) -> Vector2i:
    var s = Vector2i(clamp(start.x, 0, max(0, grid_w - 1)), clamp(start.y, 0, max(0, grid_h - 1)))
    if (kind == "sidewalk" and _sidewalk_at(_cell_center(s))) or (kind != "sidewalk" and _cell_walkable(s)):
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
            if not _in_bounds_cell(n) or visited.has(n):
                continue
            if (kind == "sidewalk" and _sidewalk_at(_cell_center(n))) or (kind != "sidewalk" and _cell_walkable(n)):
                return n
            visited[n] = true
            q.append(n)
    if not walkable_cells.is_empty():
        return walkable_cells[0]
    return s

func _draw():
    draw_rect(get_viewport_rect(), Color.BLACK, true)
    draw_set_transform(draw_offset, 0.0, Vector2(scale_factor, scale_factor))
    draw_rect(Rect2(0, 0, map_w, map_h), Color.BLACK, true)
    if blanked:
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        return
    _draw_city_map()
    _draw_mission_markers()
    for d in drops:
        _draw_drop(d)
    for c in cars:
        _draw_car(c)
    for p in pedestrians:
        _draw_pedestrian(p["pos"], p["color"])
    for c in cops:
        _draw_cop(c["pos"])
    for b in bullets:
        _glow_line(b["pos"] - b["vel"].normalized() * 8.0, b["pos"], C_YELLOW, 1.6)
    if not player["in_car"]:
        _draw_player(player["pos"], player["facing"])
    for p in particles:
        var alpha = max(0.0, float(p["life"]) / float(p["max"]))
        draw_circle(p["pos"], 3.5 * alpha, Color(p["color"].r, p["color"].g, p["color"].b, alpha))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_hud()

func _draw_city_map():
    for y in range(grid_h):
        for x in range(grid_w):
            var c = Vector2i(x, y)
            var v = _cell_class(c)
            var r = Rect2(x * cell_px, y * cell_px, cell_px, cell_px)
            if v == CLASS_SOLID:
                draw_rect(r, C_BUILDING, true)
                draw_rect(r, Color(1, 1, 1, 0.08), false, 1.0)
            elif v == CLASS_PATH:
                draw_rect(r, C_ROAD, true)
            elif v == CLASS_TRACKING or v == CLASS_UI_SAFE:
                draw_rect(r, Color(C_SIDEWALK.r, C_SIDEWALK.g, C_SIDEWALK.b, 0.65), true)
            elif v == CLASS_GOAL:
                draw_rect(r, Color(C_MAGENTA.r, C_MAGENTA.g, C_MAGENTA.b, 0.10), true)
            elif v == CLASS_PICKUP:
                draw_rect(r, Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.10), true)
            elif v == CLASS_SPAWN:
                draw_rect(r, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.10), true)
    for c in road_cells:
        if c.x % 5 == 0 and _road_at(_cell_center(c)):
            draw_line(Vector2(c.x * cell_px + cell_px * 0.5, c.y * cell_px + 4), Vector2(c.x * cell_px + cell_px * 0.5, c.y * cell_px + cell_px - 4), Color(1, 0.9, 0.2, 0.20), 1.0)
        if c.y % 5 == 0 and _road_at(_cell_center(c)):
            draw_line(Vector2(c.x * cell_px + 4, c.y * cell_px + cell_px * 0.5), Vector2(c.x * cell_px + cell_px - 4, c.y * cell_px + cell_px * 0.5), Color(1, 0.9, 0.2, 0.20), 1.0)

func _draw_mission_markers():
    if mission_state == "phone":
        _draw_payphone(active_phone, abs(sin(phone_flash * 5.0)) > 0.25)
    elif mission_state == "pickup":
        _draw_package(active_pickup, C_YELLOW)
    elif mission_state == "deliver":
        _draw_package(active_drop, C_MAGENTA)

func _draw_payphone(pos: Vector2, lit: bool):
    var col = C_MAGENTA if lit else Color(C_MAGENTA.r, C_MAGENTA.g, C_MAGENTA.b, 0.35)
    draw_rect(Rect2(pos + Vector2(-8, -18), Vector2(16, 32)), Color(col.r, col.g, col.b, 0.18), true)
    draw_rect(Rect2(pos + Vector2(-8, -18), Vector2(16, 32)), col, false, 1.5)
    _glow_line(pos + Vector2(-5, -10), pos + Vector2(5, -10), col, 0.8)
    _glow_circle_outline(pos + Vector2(0, -27), 8.0, col, 1.2)

func _draw_package(pos: Vector2, col: Color):
    var pts = PackedVector2Array([pos + Vector2(0, -15), pos + Vector2(15, 0), pos + Vector2(0, 15), pos + Vector2(-15, 0)])
    draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.18))
    for i in range(4):
        _glow_line(pts[i], pts[(i + 1) % 4], col, 1.2)

func _draw_car(car):
    var pos = car["pos"]
    var dir = Vector2(cos(float(car["angle"])), sin(float(car["angle"])))
    var side = dir.orthogonal()
    var col = car["color"]
    var pts = PackedVector2Array([pos + dir * 24 + side * 11, pos + dir * 24 - side * 11, pos - dir * 24 - side * 13, pos - dir * 24 + side * 13])
    draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.20))
    for i in range(pts.size()):
        _glow_line(pts[i], pts[(i + 1) % pts.size()], col, 1.2)
    draw_rect(Rect2(pos - dir * 3 - side * 7, Vector2(14, 14)), Color(1, 1, 1, 0.22), true)
    _glow_line(pos + dir * 18 + side * 7, pos + dir * 18 - side * 7, Color.WHITE, 0.7)
    if bool(car.get("occupied", false)):
        _glow_circle_outline(pos, 27, C_YELLOW, 1.0)

func _draw_pedestrian(pos: Vector2, col: Color):
    _glow_circle(pos + Vector2(0, -8), 4.0, col)
    _glow_line(pos + Vector2(0, -4), pos + Vector2(0, 9), col, 1.0)
    _glow_line(pos + Vector2(-7, 0), pos + Vector2(7, 0), col, 0.8)
    _glow_line(pos + Vector2(0, 9), pos + Vector2(-5, 16), col, 0.8)
    _glow_line(pos + Vector2(0, 9), pos + Vector2(5, 16), col, 0.8)

func _draw_cop(pos: Vector2):
    _draw_pedestrian(pos, C_CYAN)
    _glow_line(pos + Vector2(-8, -16), pos + Vector2(8, -16), C_RED, 1.1)
    _glow_circle_outline(pos, 16, C_RED, 1.0)

func _draw_player(pos: Vector2, facing: Vector2):
    var dir = facing.normalized() if facing.length() > 0.1 else Vector2.RIGHT
    var side = dir.orthogonal()
    _glow_circle(pos - dir * 4, 7.0, C_GREEN)
    _glow_line(pos, pos + dir * 15, C_GREEN, 1.4)
    _glow_line(pos + side * 7, pos - side * 7, C_GREEN, 1.0)
    _glow_line(pos + dir * 10, pos + dir * 23, C_YELLOW, 1.3)
    draw_circle(pos + dir * 2 + side * 3, 1.8, Color.WHITE)
    draw_circle(pos + dir * 2 - side * 3, 1.8, Color.WHITE)

func _draw_drop(drop):
    _draw_package(drop["pos"], C_GREEN if drop["kind"] == "cash" else C_YELLOW)

func _draw_hud():
    var font = ThemeDB.fallback_font
    var vp = get_viewport_rect().size
    draw_string(font, Vector2(18, 32), "GTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
    var mode = "CAR" if player["in_car"] else "FOOT"
    draw_string(font, Vector2(18, 60), "SCORE " + str(score) + "  CASH $" + str(cash) + "  AMMO " + str(ammo) + "  LIVES " + str(lives) + "  " + mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_CYAN)
    var stars = ""
    for i in range(5):
        stars += "*" if i < wanted else "-"
    draw_string(font, Vector2(18, 86), "WANTED " + stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_RED if wanted > 0 else C_DIM)
    var objective = "ANSWER THE RINGING PHONE"
    if mission_state == "pickup":
        objective = "PICK UP THE PACKAGE"
    elif mission_state == "deliver":
        objective = "DELIVER THE PACKAGE"
    draw_string(font, Vector2(18, vp.y - 22), objective + "   E/SPACE: PHONE/CAR   F: SHOOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_YELLOW)
    if game_state == "game_over":
        draw_string(font, vp * 0.5, "BUSTED - ENTER", HORIZONTAL_ALIGNMENT_CENTER, -1, 44, C_RED)

func _glow_line(a: Vector2, b: Vector2, color: Color, width: float):
    draw_line(a, b, Color(color.r, color.g, color.b, 0.20), width * 5.0)
    draw_line(a, b, Color(color.r, color.g, color.b, 0.72), width * 2.0)
    draw_line(a, b, Color.WHITE, max(1.0, width * 0.35))

func _glow_circle(pos: Vector2, r: float, color: Color):
    draw_circle(pos, r * 2.0, Color(color.r, color.g, color.b, 0.14))
    draw_circle(pos, r * 1.25, Color(color.r, color.g, color.b, 0.45))
    draw_circle(pos, r, Color(color.r, color.g, color.b, 0.9))
    draw_arc(pos, r, 0, TAU, 24, Color.WHITE, 1.0)

func _glow_circle_outline(pos: Vector2, r: float, color: Color, width: float):
    draw_arc(pos, r, 0, TAU, 36, Color(color.r, color.g, color.b, 0.22), width * 5.0)
    draw_arc(pos, r, 0, TAU, 36, Color(color.r, color.g, color.b, 0.75), width * 2.0)
    draw_arc(pos, r, 0, TAU, 36, Color.WHITE, max(1.0, width * 0.4))

func _burst(pos: Vector2, color: Color, count: int):
    for i in range(count):
        var a = randf() * TAU
        particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(30, 180), "life": randf_range(0.25, 0.7), "max": 0.7, "color": color})

func _pump_ipc():
    if ipc_socket == null:
        return
    ipc_socket.poll()
    if ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        if not ready_sent:
            _send_ipc({"type": "ready", "data": {"cartridge": "gta"}})
            ready_sent = true
        var available = ipc_socket.get_available_bytes()
        if available > 0:
            read_buffer += ipc_socket.get_utf8_string(available)
            while read_buffer.find("\n") >= 0:
                var idx = read_buffer.find("\n")
                var line = read_buffer.substr(0, idx).strip_edges()
                read_buffer = read_buffer.substr(idx + 1)
                if line != "":
                    _handle_ipc(line)

func _handle_ipc(line: String):
    var json = JSON.new()
    if json.parse(line) != OK:
        return
    var msg = json.data
    var cmd = str(msg.get("type", msg.get("cmd", "")))
    if cmd == "load":
        var data = msg.get("data", {})
        var next_level = level_dir
        if typeof(data) == TYPE_DICTIONARY:
            next_level = str(data.get("level_dir", data.get("level", level_dir)))
        if msg.has("level_dir"):
            next_level = str(msg.get("level_dir", level_dir))
        elif msg.has("level"):
            next_level = str(msg.get("level", level_dir))
        if next_level != "" and next_level != level_dir:
            level_dir = next_level
        if level_dir != loaded_level_key:
            load_level()
            reset_game()
        else:
            paused = false
            blanked = false
    elif cmd == "pause":
        paused = true
    elif cmd == "resume":
        paused = false
    elif cmd == "blank":
        blanked = not blanked
    elif cmd == "quit":
        get_tree().quit()

func _send_ipc(msg: Dictionary):
    if ipc_socket == null or ipc_socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
        return
    ipc_socket.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())

func _emit_score():
    _send_ipc({"type": "score", "data": {"player": 1, "score": score}})
