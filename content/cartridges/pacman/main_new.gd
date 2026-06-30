extends Node2D

var tab_menu = null

var ipc_socket: StreamPeerTCP = null
var scene_dir: String = ""
var level_dir: String = ""
var ipc_port: int = 0
var ipc_host: String = "127.0.0.1"

var heartbeat_timer: float = 0.0
var read_buffer: String = ""

# Navgraph data
var graph_nodes = []
var graph_edges = []
var players = []
var pickups = []

var current_node_id = ""
var target_node_id = ""
var player_speed = 200.0
var score = 0
var active_particles = []

var game_state = "playing" # playing, game_over, win, respawning
var lives = 3
var enemies = []
var original_player_spawns = []
var original_enemy_spawns = []
var original_pickups = []


var game_state = "playing" # playing, game_over, win, respawning
var lives = 3
var enemies = []
var original_player_spawns = []
var original_enemy_spawns = []
var original_pickups = []
var player_last_dir = Vector2.RIGHT
var frightened_timer: float = 0.0
var frightened_duration: float = 7.5
var frightened_flash_window: float = 2.0
var frightened_chain_count: int = 0


# Reference Background
var background_texture: Texture2D = null
var background_opacity: float = 0.15
var show_background: bool = false
var reference_opacity_step: float = 0.05

# Visual Skin
var current_skin: String = "classic" # "classic" or "neon"
var has_sent_ready: bool = false
var screenshot_path: String = ""
var map_w: float = 800.0
var map_h: float = 600.0
var scale_factor: float = 1.0
var offset_x: float = 0.0
var offset_y: float = 0.0
var grid_cells = []
var grid_cell_size_base: float = 32.0
var grid_cell_size: float = 32.0
var grid_size_scale: float = 1.0
var classic_wall_width_scale: float = 1.0
var invert_main_solid: bool = false
var level_name: String = "PAC-MAN"

func _ready():
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    print("Cartridge _ready called. Args: ", args)
    var i = 0
    while i < args.size():
        if args[i] == "--scene" and i + 1 < args.size():
            scene_dir = args[i+1]
            i += 1
        elif args[i] == "--level" and i + 1 < args.size():
            level_dir = args[i+1]
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
        elif args[i] == "--skin" and i + 1 < args.size():
            var skin_arg = args[i+1]
            if skin_arg == "Classic Pac-Man":
                current_skin = "classic"
            else:
                current_skin = "neon"
            i += 1
        i += 1

    print("Parsed level_dir: ", level_dir, " ipc_port: ", ipc_port, " screenshot_path: ", screenshot_path)

    if ipc_port > 0:
        ipc_socket = StreamPeerTCP.new()
        ipc_socket.connect_to_host(ipc_host, ipc_port)
    
    send_ipc_message({"type": "ready"})
    var SL = load(_repo_root().path_join("app/shared/shared_loader.gd"))
    tab_menu = SL.load_tab_menu_script().new()
    add_child(tab_menu)
    tab_menu.register_knob_int("players", "Players", 1, 1, 4, 1)
    tab_menu.register_knob_enum("skin", "Skin", "classic", ["classic", "neon"])
    tab_menu.register_knob_bool("reference", "Reference Overlay", false)
    tab_menu.register_knob_float("reference_opacity", "Reference Opacity", 0.15, 0.0, 1.0, 0.05)
    tab_menu.register_knob_float("grid_scale", "Grid Size", 1.0, 0.6, 1.6, 0.05)
    tab_menu.register_knob_float("wall_width", "Wall Width", 1.0, 0.55, 1.65, 0.05)
    tab_menu.register_knob_bool("invert_main_solid", "Invert Main Solid", false)
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    tab_menu.connect("menu_closed", Callable(self, "_on_menu_closed"))
    
    tab_menu.setup("pacman", level_dir, level_name)
    _apply_settings_from_menu()
    
    load_level()
    load_background()
    
    if screenshot_path != "":
        await get_tree().create_timer(1.0).timeout
        var img = get_viewport().get_texture().get_image()
        img.save_png(screenshot_path)
        print("Cartridge screenshot saved to: ", screenshot_path)
        get_tree().quit()

func _input(event):
    if game_state in ["game_over", "win"]:
        if (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or \
           (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
            _restart_game()
            return
            
func _apply_settings_from_menu():
    selected_players = tab_menu.get_knob_value("players")
    current_skin = tab_menu.get_knob_value("skin")
    show_background = tab_menu.get_knob_value("reference")
    background_opacity = tab_menu.get_knob_value("reference_opacity")
    grid_size_scale = tab_menu.get_knob_value("grid_scale")
    classic_wall_width_scale = tab_menu.get_knob_value("wall_width")
    invert_main_solid = tab_menu.get_knob_value("invert_main_solid")

func _on_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["grid_scale", "invert_main_solid"]:
        load_level()
    queue_redraw()

func _on_menu_action(action_id: String):
    if action_id == "start":
        if game_state in ["game_over", "win"]:
            _restart_game()
        else:
            game_state = "playing"

func _on_menu_closed():
    pass

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
                if img:
                    background_texture = ImageTexture.create_from_image(img)

func parse_simple_yaml(path: String) -> Dictionary:
    var data = {}
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return data
    while not file.eof_reached():
        var line = file.get_line().strip_edges()
        if line.begins_with("#") or line == "":
            continue
        if ":" in line:
            var parts = line.split(":", true, 1)
            var key = parts[0].strip_edges()
            var val = parts[1].strip_edges()
            if (val.begins_with("\"") and val.ends_with("\"")) or (val.begins_with("'") and val.ends_with("'")):
                val = val.substr(1, val.length() - 2)
            data[key] = val
    return data


func _process(delta):
    menu_axis_cooldown = max(0.0, menu_axis_cooldown - delta)
    if frightened_timer > 0.0:
        frightened_timer = max(0.0, frightened_timer - delta)
        if frightened_timer <= 0.0:
            frightened_chain_count = 0
    _process_ipc(delta)
    if visible:
        if tab_menu.overlay_mode == "" and game_state in ["playing", "respawning"]:
            _process_player(delta)
            if game_state == "playing":
                _process_enemies(delta)
        _process_particles(delta)
        queue_redraw()

func _process_ipc(delta):
    if ipc_socket:
        ipc_socket.poll()
        if ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
            if not has_sent_ready:
                has_sent_ready = true
                send_ipc_message({"type": "ready"})
            var bytes_available = ipc_socket.get_available_bytes()
            if bytes_available > 0:
                var data = ipc_socket.get_string(bytes_available)
                read_buffer += data
                var lines = read_buffer.split("\n")
                if lines.size() > 1:
                    for j in range(lines.size() - 1):
                        var line = lines[j].strip_edges()
                        if line.length() > 0:
                            handle_ipc_message(line)
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
    var err = json.parse(msg_str)
    if err == OK:
        var msg = json.data
        if typeof(msg) == TYPE_DICTIONARY:
            var msg_type = msg.get("type", msg.get("command", ""))
            if msg_type == "quit":
                get_tree().quit()
            elif msg_type == "blank":
                visible = false
            elif msg_type == "pause":
                visible = false
            elif msg_type == "resume":
                visible = true
            elif msg_type == "load":
                visible = true
                level_adjustments_loaded = false
                load_level()
                load_background()
                _load_level_adjustments()
                _update_menu_overlay()

func load_level():
    if level_dir == "":
        return
    original_player_spawns.clear()
    original_enemy_spawns.clear()
    original_pickups.clear()
    var level_info = parse_simple_yaml(level_dir.path_join("level.yaml"))
    level_name = str(level_info.get("name", "Pac-Man")).to_upper()
        
    var SL = load(_repo_root().path_join("app/shared/shared_loader.gd"))
    var adapter = SL.load_adapter_script("maze").new()
    var knobs = {
        "grid_size_scale": grid_size_scale,
        "invert_main_solid": invert_main_solid
    }
    var layout = adapter.interpret(level_dir, {}, knobs)
    
    grid_cell_size = layout.get("grid_cell_size", 32.0 * grid_size_scale)
    graph_nodes = layout.get("nodes", [])
    graph_edges = layout.get("edges", [])
    
    players.clear()
    for p in layout.get("players", []):
        players.append(Vector2(p.x, p.y))
        
    enemies.clear()
    for e in layout.get("enemies", []):
        enemies.append(Vector2(e.x, e.y))
        
    pickups.clear()
    for pk in layout.get("pickups", []):
        pickups.append({"pos": Vector2(pk.x, pk.y), "power": pk.get("power", false)})

func _repo_root() -> String:
    var d = ProjectSettings.globalize_path("res://").replace("\\","/").simplify_path()
    for _i in range(10):
        if DirAccess.dir_exists_absolute(d.path_join("app/shared")): return d
        var p = d.get_base_dir()
        if p == d or p == "": break
        d = p
    return ""

var selected_players = 1
var menu_axis_cooldown = 0.0
var level_adjustments_loaded = false

func _restart_game(): pass
func _process_player(delta): pass
func _process_enemies(delta): pass
func _process_particles(delta): pass
func _load_level_adjustments(): pass
func _update_menu_overlay(): pass


func _get_degree(node_id: String) -> int:
    var deg = 0
    for edge in graph_edges:
        if str(edge.get("source", "")) == node_id or str(edge.get("target", "")) == node_id:
            deg += 1
    return deg

func _process_enemies(delta):
    for i in range(enemies.size()):
        var e = enemies[i]
        var pos = Vector2(e.x, e.y)
        var e_target_node_id = e.get("target_node_id", "")
        var e_current_node_id = e.get("current_node_id", "")
        
        if e_target_node_id == "":
            var possible = []
            var node = _get_node(e_current_node_id)
            if node:
                for edge in graph_edges:
                    var other_id = ""
                    if str(edge.get("source", "")) == e_current_node_id:
                        other_id = str(edge.get("target", ""))
                    elif str(edge.get("target", "")) == e_current_node_id:
                        other_id = str(edge.get("source", ""))
                    if other_id != "":
                        if other_id != e.get("prev_node_id", "") or _get_degree(e_current_node_id) == 1:
                            possible.append(other_id)
            if possible.size() > 0:
                e.target_node_id = possible[randi() % possible.size()]
                e_target_node_id = e.target_node_id
        
        if e_target_node_id != "":
            var target_node = _get_node(e_target_node_id)
            if target_node:
                var target_pos = Vector2(target_node.get("x", 0), target_node.get("y", 0))
                var move_vec = target_pos - pos
                if move_vec.length() <= e.speed * delta:
                    pos = target_pos
                    e.prev_node_id = e_current_node_id
                    e.current_node_id = e_target_node_id
                    e.target_node_id = ""
                else:
                    pos += move_vec.normalized() * e.speed * delta
        
        e.x = pos.x
        e.y = pos.y
        
        # Check collision with players
        for j in range(players.size()):
            var p = players[j]
            if p.get("alive", true):
                if pos.distance_to(Vector2(p.x, p.y)) < 20.0:
                    _on_player_caught(j)

func _on_player_caught(player_idx):
    var p = players[player_idx]
    spawn_particle_burst(Vector2(p.x, p.y), Color.RED, 30)
    p.alive = false
    
    var any_alive = false
    for pl in players:
        if pl.get("alive", true):
            any_alive = true
            
    if not any_alive:
        lives -= 1
        if lives > 0:
            game_state = "respawning"
            var t = get_tree().create_timer(1.5)
            t.connect("timeout", Callable(self, "_respawn_all"))
        else:
            game_state = "game_over"
            send_ipc_message({"type": "state", "data": {"state": "game_over"}})

func _respawn_all():
    if lives <= 0: return
    game_state = "playing"
    
    for i in range(players.size()):
        if i < original_player_spawns.size():
            var sp = original_player_spawns[i]
            players[i].x = sp.x
            players[i].y = sp.y
            players[i].current_node_id = sp.id
            players[i].target_node_id = ""
            players[i].alive = true
            
    for i in range(enemies.size()):
        if i < original_enemy_spawns.size():
            var sp = original_enemy_spawns[i]
            enemies[i].x = sp.x
            enemies[i].y = sp.y
            enemies[i].current_node_id = sp.id
            enemies[i].target_node_id = ""
            enemies[i].prev_node_id = ""

func _restart_game():
    score = 0
    lives = 3
    game_state = "playing"
    send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})
    pickups = original_pickups.duplicate(true)
    _respawn_all()
