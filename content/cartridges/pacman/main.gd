extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()
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
var game_time: float = 0.0
var _debug_drawn_once: bool = false
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
var semantic_texture: Texture2D = null
var background_opacity: float = 0.15
var show_background: bool = false
var reference_opacity_step: float = 0.05
var background_view: String = "final"
var show_debug_grid: bool = false

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
var grid_cols: int = 0
var grid_rows: int = 0
var grid_origin: Vector2 = Vector2.ZERO
var grid_size_scale: float = 1.0
var classic_wall_width_scale: float = 1.0
var tunnel_fill: float = 0.0
var invert_main_solid: bool = false
var level_name: String = "PAC-MAN"
var maze_bounds := Rect2(0, 0, 800, 600)
var walkable_cells := {}
var grid_min := Vector2i.ZERO
var grid_max := Vector2i.ZERO
var play_rect := Rect2(0, 0, 800, 600)
var cached_wall_segments: Array = []
var cached_wall_corners: Array = []
var use_map_space_layout := false
var closed_cells = []
var original_edges = []
var is_tunnel_fill_focused: bool = false
var is_tunnel_fill_preview_active: bool = false

const PACMAN_GHOST_COLORS = [
    Color(1.0, 0.16, 0.2),
    Color(1.0, 0.45, 0.78),
    Color(0.2, 0.92, 1.0),
    Color(1.0, 0.67, 0.18)
]

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
            elif skin_arg.to_lower() == "pac-triot" or skin_arg.to_lower() == "pac_triot":
                current_skin = "pac_triot"
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
    tab_menu.register_knob_int("players", "Players", 1, 1, 4, 1, "Gameplay")
    tab_menu.register_knob_enum("skin", "Skin", current_skin, ["classic", "neon", "pac_triot"], "Gameplay")
    tab_menu.register_knob_enum("background_view", "Background View", "final", ["final", "photo", "semantic", "secondary", "tunnel_fill"], "Preview")
    tab_menu.register_knob_bool("reference", "Background Layer", false, "Preview")
    tab_menu.register_knob_float("reference_opacity", "Background Opacity", 0.15, 0.0, 1.0, 0.05, "Preview")
    tab_menu.register_knob_bool("show_debug_grid", "Scale Grid Overlay", false, "Preview")
    tab_menu.register_knob_float("grid_scale", "Grid Resolution", 1.0, 0.6, 1.6, 0.05, "Level")
    tab_menu.register_knob_float("wall_width", "Wall Width", 1.0, 0.55, 1.65, 0.05, "Level")
    tab_menu.register_knob_float("tunnel_fill", "Tunnel Fill", 0.0, 0.0, 1.0, 0.05, "Level")
    tab_menu.register_knob_bool("invert_main_solid", "Invert Main Solid", false, "Level")
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    tab_menu.connect("menu_closed", Callable(self, "_on_menu_closed"))
    
    tab_menu.setup("pacman", level_dir, level_name)
    _apply_settings_from_menu()
    
    _load_grid_metadata()
    load_background()
    load_level()
    
    if screenshot_path != "":
        await get_tree().create_timer(1.0).timeout
        var img = get_viewport().get_texture().get_image()
        img.save_png(screenshot_path)
        print("Cartridge screenshot saved to: ", screenshot_path)
        get_tree().quit()

func _input(event):
    if game_state in ["game_over", "win"]:
        if (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or \
           (event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_START, JOY_BUTTON_A]):
            _restart_game()
            return
            
    if is_tunnel_fill_focused:
        if (event is InputEventKey and event.pressed and event.keycode == KEY_X) or \
           (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X):
            is_tunnel_fill_preview_active = not is_tunnel_fill_preview_active
            queue_redraw()
            get_viewport().set_input_as_handled()
            
func _apply_settings_from_menu():
    selected_players = tab_menu.get_knob_value("players")
    current_skin = tab_menu.get_knob_value("skin")
    background_view = str(tab_menu.get_knob_value("background_view"))
    show_background = tab_menu.get_knob_value("reference")
    background_opacity = tab_menu.get_knob_value("reference_opacity")
    show_debug_grid = bool(tab_menu.get_knob_value("show_debug_grid"))
    grid_size_scale = tab_menu.get_knob_value("grid_scale")
    classic_wall_width_scale = tab_menu.get_knob_value("wall_width")
    tunnel_fill = float(tab_menu.get_knob_value("tunnel_fill"))
    invert_main_solid = tab_menu.get_knob_value("invert_main_solid")

func _on_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["grid_scale", "invert_main_solid", "tunnel_fill"]:
        load_level()
    if knob_id in ["background_view", "reference", "reference_opacity", "show_debug_grid"]:
        _update_view_transform()
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
    background_texture = null
    semantic_texture = null
    map_w = 800.0
    map_h = 600.0
    if level_dir == "":
        _update_view_transform()
        return
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
                    map_w = img.get_width()
                    map_h = img.get_height()
        var semantic_file = data.get("semantic_map", "")
        if semantic_file != "":
            var semantic_path = level_dir.path_join(semantic_file)
            if FileAccess.file_exists(semantic_path):
                var semantic_img = Image.load_from_file(semantic_path)
                if semantic_img:
                    semantic_texture = ImageTexture.create_from_image(semantic_img)
                    if background_texture == null:
                        map_w = semantic_img.get_width()
                        map_h = semantic_img.get_height()
    _load_grid_metadata()
    _update_view_transform()

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
    var is_overlay_active = false
    if tab_menu and tab_menu.overlay_mode != "":
        is_overlay_active = true

    if game_state == "playing" and not is_overlay_active:
        game_time += delta
    menu_axis_cooldown = max(0.0, menu_axis_cooldown - delta)
    if frightened_timer > 0.0 and not is_overlay_active and game_state == "playing":
        frightened_timer = max(0.0, frightened_timer - delta)
        if frightened_timer <= 0.0:
            frightened_chain_count = 0
    _process_ipc(delta)
    if visible:
        is_tunnel_fill_focused = false
        if tab_menu and tab_menu.overlay_mode == "settings":
            var ctrl_info = tab_menu.settings_controls.get("tunnel_fill")
            if ctrl_info and ctrl_info.get("control") != null:
                var parent_control = ctrl_info["control"]
                var focused = get_viewport().gui_get_focus_owner()
                if focused != null and (focused == parent_control or parent_control.is_ancestor_of(focused)):
                    is_tunnel_fill_focused = true
        if not is_tunnel_fill_focused:
            is_tunnel_fill_preview_active = false
            
        if tab_menu and tab_menu.menu_overlay:
            var target_a = 0.15 if is_tunnel_fill_preview_active else 1.0
            var current_bg_a = tab_menu.menu_overlay.color.a
            tab_menu.menu_overlay.color.a = lerp(current_bg_a, target_a * 0.82, delta * 15.0)
            tab_menu.splash_frame.modulate.a = lerp(tab_menu.splash_frame.modulate.a, target_a, delta * 15.0)
            tab_menu.menu_panel.modulate.a = lerp(tab_menu.menu_panel.modulate.a, target_a, delta * 15.0)
            
        if not is_overlay_active and game_state in ["playing", "respawning"]:
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
    _load_grid_metadata()
    original_player_spawns.clear()
    original_enemy_spawns.clear()
    original_pickups.clear()
    var level_info = parse_simple_yaml(level_dir.path_join("level.yaml"))
    level_name = str(level_info.get("name", "Pac-Man")).to_upper()
        
    var SL = load(_repo_root().path_join("app/shared/shared_loader.gd"))
    var layout = _build_scaled_layout_from_grid()
    if layout.is_empty():
        var adapter = SL.load_adapter_script("maze").new()
        var knobs = {
            "grid_size_scale": grid_size_scale,
            "invert_main_solid": invert_main_solid
        }
        layout = adapter.interpret(level_dir, {}, knobs)
        use_map_space_layout = false
    
    grid_cell_size = layout.get("grid_cell_size", 32.0 * grid_size_scale)
    var resolution_ratio = _resolution_ratio()
    player_speed = 200.0 * resolution_ratio * resolution_ratio
    graph_nodes = layout.get("nodes", [])
    graph_edges = layout.get("edges", [])
    _rebuild_walkable_cells()
    _rebuild_maze_bounds()
    _update_view_transform()
    
    players.clear()
    for p in layout.get("players", []):
        var p_dict = {"x": p["x"], "y": p["y"], "current_node_id": p.get("id", ""), "target_node_id": "", "alive": true}
        players.append(p_dict)
        original_player_spawns.append({"x": p["x"], "y": p["y"], "id": p.get("id", "")})
        
    enemies.clear()
    for e in layout.get("enemies", []):
        var e_dict = {"x": e["x"], "y": e["y"], "current_node_id": e.get("id", ""), "target_node_id": "", "prev_node_id": "", "speed": 140.0 * resolution_ratio * resolution_ratio}
        enemies.append(e_dict)
        original_enemy_spawns.append({"x": e["x"], "y": e["y"], "id": e.get("id", "")})
        
    pickups.clear()
    for pk in layout.get("pickups", []):
        pickups.append({"x": pk["x"], "y": pk["y"], "power": pk.get("power", false)})
    original_pickups = pickups.duplicate(true)
    _rebuild_wall_cache()

func _rebuild_walkable_cells():
    walkable_cells.clear()
    var first = true
    for n in graph_nodes:
        if not n.has("gx") or not n.has("gy"):
            continue
        var gx = int(n.get("gx", 0))
        var gy = int(n.get("gy", 0))
        walkable_cells["%d:%d" % [gx, gy]] = true
        if first:
            grid_min = Vector2i(gx, gy)
            grid_max = Vector2i(gx, gy)
            first = false
        else:
            grid_min.x = min(grid_min.x, gx)
            grid_min.y = min(grid_min.y, gy)
            grid_max.x = max(grid_max.x, gx)
            grid_max.y = max(grid_max.y, gy)

func _rebuild_wall_cache():
    cached_wall_segments = _collect_merged_wall_segments()
    var corners = {}
    for seg in cached_wall_segments:
        var a_key = "%0.2f:%0.2f" % [seg["a"].x, seg["a"].y]
        var b_key = "%0.2f:%0.2f" % [seg["b"].x, seg["b"].y]
        corners[a_key] = seg["a"]
        corners[b_key] = seg["b"]
    cached_wall_corners = corners.values()

func _rebuild_maze_bounds():
    if graph_nodes.is_empty():
        maze_bounds = Rect2(0, 0, 800, 600)
        return
    var min_x = INF
    var min_y = INF
    var max_x = -INF
    var max_y = -INF
    for n in graph_nodes:
        var px = float(n.get("x", 0.0))
        var py = float(n.get("y", 0.0))
        min_x = min(min_x, px)
        min_y = min(min_y, py)
        max_x = max(max_x, px)
        max_y = max(max_y, py)
    var pad = max(32.0, grid_cell_size * 1.25)
    maze_bounds = Rect2(min_x - pad, min_y - pad, (max_x - min_x) + pad * 2.0, (max_y - min_y) + pad * 2.0)

func _load_grid_metadata():
    grid_cols = 0
    grid_rows = 0
    grid_cell_size_base = 32.0
    grid_cells = []
    play_rect = Rect2(0, 0, map_w, map_h)
    if level_dir == "":
        return
    var grid_path = level_dir.path_join("derived").path_join("grid.json")
    if not FileAccess.file_exists(grid_path):
        return
    var file = FileAccess.open(grid_path, FileAccess.READ)
    if file == null:
        return
    var json = JSON.new()
    if json.parse(file.get_as_text()) != OK:
        return
    var data = json.data
    if typeof(data) != TYPE_DICTIONARY:
        return
    grid_cell_size_base = float(data.get("cell_px", 32.0))
    grid_cells = data.get("cells", [])
    grid_rows = grid_cells.size()
    if grid_rows > 0:
        grid_cols = grid_cells[0].size()
        
    if grid_cols > 0 and grid_rows > 0:
        var expected_w = float(grid_cols) * grid_cell_size_base
        var expected_h = float(grid_rows) * grid_cell_size_base
        if map_w < 100.0 or map_h < 100.0:
            map_w = expected_w
            map_h = expected_h
            
    print("PHASE 1 DEBUG - _load_grid_metadata: grid_rows=", grid_rows, " grid_cols=", grid_cols, " grid_cell_size_base=", grid_cell_size_base, " cell_px=", data.get("cell_px", 32.0))

func _build_scaled_layout_from_grid() -> Dictionary:
    if grid_rows <= 0 or grid_cols <= 0 or grid_cells.is_empty():
        return {}
    use_map_space_layout = true
    var target_cols = max(4, int(round(float(grid_cols) / max(0.2, grid_size_scale))))
    var target_rows = max(4, int(round(float(grid_rows) / max(0.2, grid_size_scale))))
    var frame_rect = _map_rect()
    var cell_px = min(frame_rect.size.x / float(target_cols), frame_rect.size.y / float(target_rows))
    var total_w = cell_px * float(target_cols)
    var total_h = cell_px * float(target_rows)
    grid_origin = frame_rect.position + Vector2((frame_rect.size.x - total_w) * 0.5, (frame_rect.size.y - total_h) * 0.5)
    var layout = {
        "nodes": [],
        "edges": [],
        "players": [],
        "enemies": [],
        "pickups": [],
        "grid_cell_size": cell_px
    }
    var source_spawn := Vector2i(-1, -1)
    for sy in range(grid_rows):
        for sx in range(grid_cols):
            if int(grid_cells[sy][sx]) == 5:
                source_spawn = Vector2i(sx, sy)
                break
        if source_spawn.x >= 0:
            break
    var node_map = {}
    for gy in range(target_rows):
        var sy = clampi(int(floor((float(gy) + 0.5) * float(grid_rows) / float(target_rows))), 0, grid_rows - 1)
        for gx in range(target_cols):
            var sx = clampi(int(floor((float(gx) + 0.5) * float(grid_cols) / float(target_cols))), 0, grid_cols - 1)
            var cid = int(grid_cells[sy][sx])
            var is_solid = cid == 1
            if invert_main_solid:
                is_solid = not (cid in [2, 3, 5, 6, 7]) and cid != 1
            if is_solid:
                continue
            var px = grid_origin.x + gx * cell_px + cell_px * 0.5
            var py = grid_origin.y + gy * cell_px + cell_px * 0.5
            var node_id = "%d_%d" % [gx, gy]
            var node = {
                "id": node_id,
                "x": px,
                "y": py,
                "gx": gx,
                "gy": gy,
                "class_id": cid,
                "type": "path"
            }
            layout["nodes"].append(node)
            node_map["%d:%d" % [gx, gy]] = node
            if cid in [2, 7] or (cid in [0, 8, 9] and gx % 2 == 0 and gy % 2 == 0):
                layout["pickups"].append({"x": px, "y": py})
    var spawn_gx = -1
    var spawn_gy = -1
    if source_spawn.x >= 0:
        spawn_gx = clampi(int(round((float(source_spawn.x) + 0.5) * float(target_cols) / float(grid_cols) - 0.5)), 0, target_cols - 1)
        spawn_gy = clampi(int(round((float(source_spawn.y) + 0.5) * float(target_rows) / float(grid_rows) - 0.5)), 0, target_rows - 1)
    _apply_tunnel_fill_mask(layout, node_map, target_cols, target_rows, spawn_gx if source_spawn.x >= 0 else -1, spawn_gy if source_spawn.x >= 0 else -1)
    print("PHASE 1 DEBUG - after _apply_tunnel_fill_mask: pickups.size()=", layout["pickups"].size())
    node_map.clear()
    for n in layout["nodes"]:
        node_map["%d:%d" % [int(n["gx"]), int(n["gy"])]] = n
    if source_spawn.x >= 0:
        var remap_spawn_key = "%d:%d" % [spawn_gx, spawn_gy]
        if node_map.has(remap_spawn_key):
            var spawn_node = node_map[remap_spawn_key]
            layout["players"].append({"x": spawn_node["x"], "y": spawn_node["y"], "id": spawn_node["id"]})
    if layout["players"].is_empty() and not layout["nodes"].is_empty():
        var first = layout["nodes"][0]
        layout["players"].append({"x": first["x"], "y": first["y"], "id": first["id"]})
    layout["edges"].clear()
    for gy in range(target_rows):
        for gx in range(target_cols):
            var key = "%d:%d" % [gx, gy]
            if not node_map.has(key):
                continue
            for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
                var other_key = "%d:%d" % [gx + dir.x, gy + dir.y]
                if node_map.has(other_key):
                    layout["edges"].append({
                        "source": node_map[key]["id"],
                        "target": node_map[other_key]["id"],
                        "weight": cell_px
                    })
    if not layout["nodes"].is_empty():
        var player_pos = Vector2(layout["players"][0]["x"], layout["players"][0]["y"])
        var far_nodes = []
        for n in layout["nodes"]:
            if Vector2(n["x"], n["y"]).distance_to(player_pos) > cell_px * 6.0:
                far_nodes.append(n)
        if far_nodes.is_empty():
            far_nodes = layout["nodes"]
        for i in range(4):
            var n = far_nodes[(i * max(1, far_nodes.size() / 4)) % far_nodes.size()]
            layout["enemies"].append({"x": n["x"], "y": n["y"], "id": n["id"]})
    _assign_power_pellets(layout)
    print("PHASE 1 DEBUG - end of _build_scaled_layout_from_grid: nodes=", layout["nodes"].size(), " pickups=", layout["pickups"].size(), " players=", layout["players"].size(), " grid_cell_size=", grid_cell_size)
    return layout

func _apply_tunnel_fill_mask(layout: Dictionary, node_map: Dictionary, target_cols: int, target_rows: int, spawn_gx: int, spawn_gy: int):
    closed_cells.clear()
    original_edges.clear()
    
    # Collect all original edges from the full node_map
    for key in node_map.keys():
        var cell = _key_to_cell(key)
        for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
            var other_key = "%d:%d" % [cell.x + dir.x, cell.y + dir.y]
            if node_map.has(other_key):
                var a_node = node_map[key]
                var b_node = node_map[other_key]
                original_edges.append({
                    "a": Vector2(float(a_node.get("x", 0.0)), float(a_node.get("y", 0.0))),
                    "b": Vector2(float(b_node.get("x", 0.0)), float(b_node.get("y", 0.0))),
                    "a_key": key,
                    "b_key": other_key
                })
                
    if tunnel_fill <= 0.01:
        return
    var keep = _build_tunnel_fill_keep(node_map, target_cols, target_rows, spawn_gx, spawn_gy)
    if keep.is_empty():
        return
    var filtered_nodes = []
    for n in layout["nodes"]:
        var key = "%d:%d" % [int(n["gx"]), int(n["gy"])]
        if keep.has(key):
            filtered_nodes.append(n)
        else:
            closed_cells.append(Vector2(float(n["x"]), float(n["y"])))
    layout["nodes"] = filtered_nodes
    var filtered_pickups = []
    for p in layout["pickups"]:
        var best_key = _nearest_layout_key(float(p["x"]), float(p["y"]), node_map)
        if best_key != "" and keep.has(best_key):
            filtered_pickups.append(p)
    layout["pickups"] = filtered_pickups

func _build_tunnel_fill_keep(node_map: Dictionary, target_cols: int, target_rows: int, spawn_gx: int, spawn_gy: int) -> Dictionary:
    var protected := {}
    
    # Protect a 3x3 area around player spawn
    if spawn_gx >= 0 and spawn_gy >= 0:
        for oy in range(-1, 2):
            for ox in range(-1, 2):
                protected["%d:%d" % [spawn_gx + ox, spawn_gy + oy]] = true
                
    var keep := node_map.duplicate()
    var extra_cells := []
    
    var blocks_found = true
    while blocks_found:
        blocks_found = false
        var candidate_blocks = []
        
        for key in keep.keys():
            var parts = key.split(":")
            var cx = int(parts[0])
            var cy = int(parts[1])
            var k_r = "%d:%d" % [cx + 1, cy]
            var k_b = "%d:%d" % [cx, cy + 1]
            var k_br = "%d:%d" % [cx + 1, cy + 1]
            
            if keep.has(k_r) and keep.has(k_b) and keep.has(k_br):
                var removable = []
                for k in [key, k_r, k_b, k_br]:
                    if not protected.has(k):
                        removable.append(k)
                if not removable.is_empty():
                    candidate_blocks.append(removable)
                    
        if not candidate_blocks.is_empty():
            candidate_blocks.shuffle()
            for block in candidate_blocks:
                var still_valid = true
                for cell in block:
                    if not keep.has(cell):
                        still_valid = false
                        break
                
                if still_valid:
                    block.shuffle()
                    for cell in block:
                        if _can_remove_cell(keep, cell):
                            keep.erase(cell)
                            extra_cells.append(cell)
                            blocks_found = true
                            break
                            
    extra_cells.shuffle()
    
    # tunnel_fill represents percentage of double lanes to close.
    # At 1.0, we keep none of the extra cells (all 2x2s are broken).
    # At 0.0, we keep all extra cells.
    var num_to_put_back = int(round((1.0 - tunnel_fill) * float(extra_cells.size())))
    for i in range(num_to_put_back):
        keep[extra_cells[i]] = true
        
    return keep

func _can_remove_cell(keep: Dictionary, cell_to_remove: String) -> bool:
    keep.erase(cell_to_remove)
    
    var parts = cell_to_remove.split(":")
    var cx = int(parts[0])
    var cy = int(parts[1])
    
    var neighbors = []
    for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
        var nk = "%d:%d" % [cx + dir.x, cy + dir.y]
        if keep.has(nk):
            neighbors.append(nk)
            
    if neighbors.size() <= 1:
        keep[cell_to_remove] = true
        return true
        
    var target_neighbors = {}
    for i in range(1, neighbors.size()):
        target_neighbors[neighbors[i]] = true
        
    var start = neighbors[0]
    var visited = {start: true}
    var queue = [start]
    var q_idx = 0
    var targets_found = 0
    var targets_needed = target_neighbors.size()
    
    while q_idx < queue.size():
        var curr = queue[q_idx]
        q_idx += 1
        
        if target_neighbors.has(curr):
            targets_found += 1
            if targets_found == targets_needed:
                break
                
        var c_parts = curr.split(":")
        var ccx = int(c_parts[0])
        var ccy = int(c_parts[1])
        
        for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
            var nk = "%d:%d" % [ccx + dir.x, ccy + dir.y]
            if keep.has(nk) and not visited.has(nk):
                visited[nk] = true
                queue.append(nk)
                
    keep[cell_to_remove] = true
    return targets_found == targets_needed

func _nearest_layout_key(px: float, py: float, node_map: Dictionary) -> String:
    var best_key = ""
    var best_d = INF
    for key in node_map.keys():
        var n = node_map[key]
        var d = Vector2(float(n["x"]), float(n["y"])).distance_squared_to(Vector2(px, py))
        if d < best_d:
            best_d = d
            best_key = str(key)
    return best_key

func _key_to_cell(key: String) -> Vector2i:
    var parts = key.split(":")
    if parts.size() != 2:
        return Vector2i.ZERO
    return Vector2i(int(parts[0]), int(parts[1]))

func _assign_power_pellets(layout: Dictionary):
    var all_pickups = layout.get("pickups", [])
    if all_pickups.is_empty():
        return
    var min_x = INF
    var min_y = INF
    var max_x = -INF
    var max_y = -INF
    for p in all_pickups:
        min_x = min(min_x, float(p["x"]))
        min_y = min(min_y, float(p["y"]))
        max_x = max(max_x, float(p["x"]))
        max_y = max(max_y, float(p["y"]))
    var corners = [Vector2(min_x, min_y), Vector2(max_x, min_y), Vector2(min_x, max_y), Vector2(max_x, max_y)]
    var used = {}
    for corner in corners:
        var best = -1
        var best_d = INF
        for idx in range(all_pickups.size()):
            if used.has(idx):
                continue
            var d = Vector2(float(all_pickups[idx]["x"]), float(all_pickups[idx]["y"])).distance_squared_to(corner)
            if d < best_d:
                best_d = d
                best = idx
        if best != -1:
            all_pickups[best]["power"] = true
            used[best] = true

func _map_rect() -> Rect2:
    return Rect2(0, 0, map_w, map_h)

func _content_rect() -> Rect2:
    if background_texture != null or semantic_texture != null:
        return _map_rect()
    return maze_bounds

func _update_view_transform():
    var viewport = get_viewport_rect().size
    if viewport.x <= 0.0 or viewport.y <= 0.0:
        scale_factor = 1.0
        offset_x = 0.0
        offset_y = 0.0
        return
    var content = _content_rect()
    var pad = 56.0
    var fit_w = max(1.0, viewport.x - pad * 2.0)
    var fit_h = max(1.0, viewport.y - pad * 2.0)
    var content_w = max(1.0, content.size.x)
    var content_h = max(1.0, content.size.y)
    scale_factor = min(fit_w / content_w, fit_h / content_h)
    offset_x = pad + (fit_w - content_w * scale_factor) * 0.5 - content.position.x * scale_factor
    offset_y = pad + (fit_h - content_h * scale_factor) * 0.5 - content.position.y * scale_factor

func _world_to_map(pos: Vector2) -> Vector2:
    if use_map_space_layout:
        return pos
    if grid_cols > 0 and grid_rows > 0 and map_w > 0.0 and map_h > 0.0 and grid_cell_size > 0.0:
        var total_w = float(grid_cols) * grid_cell_size
        var total_h = float(grid_rows) * grid_cell_size
        if total_w > 0.0 and total_h > 0.0:
            return Vector2((pos.x / total_w) * map_w, (pos.y / total_h) * map_h)
    return pos

func _map_to_screen(pos: Vector2) -> Vector2:
    return Vector2(pos.x * scale_factor + offset_x, pos.y * scale_factor + offset_y)

func _world_to_screen(pos: Vector2) -> Vector2:
    return _map_to_screen(_world_to_map(pos))

func _map_rect_to_screen(rect: Rect2) -> Rect2:
    return Rect2(_map_to_screen(rect.position), rect.size * scale_factor)

func _world_rect_to_screen(rect: Rect2) -> Rect2:
    var mapped_pos = _world_to_map(rect.position)
    var mapped_size = rect.size
    if grid_cols > 0 and grid_rows > 0 and map_w > 0.0 and map_h > 0.0 and grid_cell_size > 0.0:
        var total_w = float(grid_cols) * grid_cell_size
        var total_h = float(grid_rows) * grid_cell_size
        if total_w > 0.0 and total_h > 0.0:
            mapped_size = Vector2((rect.size.x / total_w) * map_w, (rect.size.y / total_h) * map_h)
    return Rect2(_map_to_screen(mapped_pos), mapped_size * scale_factor)

func _scaled_radius(radius: float) -> float:
    return max(1.0, radius * scale_factor)

func _scaled_width(width: float) -> float:
    return max(1.0, width * scale_factor)

func _resolution_ratio() -> float:
    return grid_cell_size / max(1.0, grid_cell_size_base)

func _active_background_texture() -> Texture2D:
    if background_view == "semantic" and semantic_texture != null:
        return semantic_texture
    if background_view == "secondary" and semantic_texture != null:
        return semantic_texture
    if background_view == "photo" and background_texture != null:
        return background_texture
    if background_view == "tunnel_fill" and semantic_texture != null:
        return semantic_texture
    return background_texture if background_texture != null else semantic_texture

func _draw_alignment_grid():
    var content = _content_rect()
    var grid_color = Color(0.6, 0.68, 0.74, 0.14)
    var step = max(16.0, map_w / max(1, grid_cols)) if grid_cols > 0 and map_w > 0.0 else max(32.0, grid_cell_size)
    var start_x = floor(content.position.x / step) * step
    var end_x = content.position.x + content.size.x
    var start_y = floor(content.position.y / step) * step
    var end_y = content.position.y + content.size.y
    var x = start_x
    while x <= end_x:
        var a = _map_to_screen(Vector2(x, content.position.y)) if content == _map_rect() else _world_to_screen(Vector2(x, content.position.y))
        var b = _map_to_screen(Vector2(x, end_y)) if content == _map_rect() else _world_to_screen(Vector2(x, end_y))
        draw_line(a, b, grid_color, 1.0, true)
        x += step
    var y = start_y
    while y <= end_y:
        var c = _map_to_screen(Vector2(content.position.x, y)) if content == _map_rect() else _world_to_screen(Vector2(content.position.x, y))
        var d = _map_to_screen(Vector2(end_x, y)) if content == _map_rect() else _world_to_screen(Vector2(end_x, y))
        draw_line(c, d, grid_color, 1.0, true)
        y += step

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



func _get_node(node_id: String):
    for n in graph_nodes:
        if str(n.get("id", "")) == str(node_id):
            return n
    return null

func _get_best_neighbor(node_id: String, dir: Vector2) -> String:
    var best_id = ""
    var best_dot = -1.0
    for edge in graph_edges:
        var other_id = ""
        if str(edge.get("source", "")) == str(node_id):
            other_id = str(edge.get("target", ""))
        elif str(edge.get("target", "")) == str(node_id):
            other_id = str(edge.get("source", ""))
            
        if other_id != "":
            var other_node = _get_node(other_id)
            var current_node = _get_node(node_id)
            if other_node and current_node:
                var npos = Vector2(other_node.get("x", 0), other_node.get("y", 0))
                var mpos = Vector2(current_node.get("x", 0), current_node.get("y", 0))
                var to_node = (npos - mpos).normalized()
                var d = to_node.dot(dir)
                if d > best_dot and d > 0.5:
                    best_dot = d
                    best_id = other_id
    return best_id

func spawn_particle_burst(pos: Vector2, color: Color, count: int):
    for i in range(count):
        active_particles.append({
            "pos": pos,
            "vel": Vector2.RIGHT.rotated(randf() * TAU) * randf_range(24.0, 110.0),
            "life": randf_range(0.25, 0.55),
            "max_life": 0.55,
            "color": color,
            "radius": randf_range(1.5, 4.0)
        })

func _draw():
    _update_view_transform()
    draw_rect(get_viewport_rect(), Color.BLACK, true)
    var content_rect = _map_rect_to_screen(_content_rect()) if _content_rect() == _map_rect() else _world_rect_to_screen(_content_rect())
    draw_rect(content_rect, Color(0.01, 0.01, 0.02, 1.0), true)
    var preview_texture = _active_background_texture()
    if background_view != "final" and preview_texture != null:
        draw_texture_rect(preview_texture, _map_rect_to_screen(_map_rect()), false, Color.WHITE)
    elif show_background and preview_texture != null:
        draw_texture_rect(preview_texture, _map_rect_to_screen(_map_rect()), false, Color(1, 1, 1, background_opacity))
    if show_debug_grid:
        _draw_alignment_grid()
    _draw_maze_skin()
    _draw_pickups()
    _draw_enemies()
    _draw_players()
    _draw_particles()
    _draw_hud()
    _draw_tunnel_fill_visualization()

func _draw_tunnel_fill_visualization():
    if not is_tunnel_fill_preview_active and background_view != "tunnel_fill":
        return
        
    # Draw all original/skeleton lines in grey first
    for edge in original_edges:
        var sa = _world_to_screen(edge["a"])
        var sb = _world_to_screen(edge["b"])
        draw_line(sa, sb, Color(0.35, 0.35, 0.35, 0.45), 2.0)
        
    # Draw open (green) and closed (red) tunnel lines
    for edge in original_edges:
        var sa = _world_to_screen(edge["a"])
        var sb = _world_to_screen(edge["b"])
        var is_closed = not walkable_cells.has(edge["a_key"]) or not walkable_cells.has(edge["b_key"])
        if is_closed:
            draw_line(sa, sb, Color(1.0, 0.22, 0.22, 0.8), 4.0)
        else:
            draw_line(sa, sb, Color(0.0, 1.0, 0.3, 0.85), 5.0)
            
    # Draw red blocks over closed cells
    if not closed_cells.is_empty():
        var cell_size = grid_cell_size * scale_factor
        var rect_size = Vector2(cell_size * 0.88, cell_size * 0.88)
        for pos in closed_cells:
            var screen_pos = _world_to_screen(pos)
            var rect = Rect2(screen_pos - rect_size * 0.5, rect_size)
            draw_rect(rect, Color(1.0, 0.12, 0.12, 0.35), true)
            draw_rect(rect, Color(1.0, 0.22, 0.22, 0.65), false, 2.0)

func _draw_maze_skin():
    if cached_wall_segments.is_empty():
        return
    var wall_color = Color(0.04, 0.2, 1.0)
    var edge_color = Color(0.22, 0.5, 1.0)
    var resolution_ratio = _resolution_ratio()
    var outer_width = 7.0 * classic_wall_width_scale
    if not _debug_drawn_once:
        print("PHASE 1 DEBUG - _draw_maze_skin: outer_width=", outer_width, " scale_factor=", scale_factor, " resolution_ratio=", resolution_ratio, " classic_wall_width_scale=", classic_wall_width_scale)
        _debug_drawn_once = true
    var inner_width = 2.2 * classic_wall_width_scale * resolution_ratio
    
    for seg in cached_wall_segments:
        _draw_wall_segment(seg["a"], seg["b"], wall_color, edge_color, outer_width, inner_width)
        
    for corner in cached_wall_corners:
        _draw_wall_corner(corner, min(outer_width * 0.5, grid_cell_size * 0.15), wall_color, edge_color)

func _has_walkable_cell(gx: int, gy: int) -> bool:
    return walkable_cells.has("%d:%d" % [gx, gy])

func _collect_merged_wall_segments() -> Array:
    var horizontal = {}
    var vertical = {}
    for key in walkable_cells.keys():
        var parts = str(key).split(":")
        var gx = int(parts[0])
        var gy = int(parts[1])
        if not _has_walkable_cell(gx, gy - 1):
            _add_unit_segment(horizontal, gy, gx, gx + 1)
        if not _has_walkable_cell(gx, gy + 1):
            _add_unit_segment(horizontal, gy + 1, gx, gx + 1)
        if not _has_walkable_cell(gx - 1, gy):
            _add_unit_segment(vertical, gx, gy, gy + 1)
        if not _has_walkable_cell(gx + 1, gy):
            _add_unit_segment(vertical, gx + 1, gy, gy + 1)
    var merged = []
    for y_key in horizontal.keys():
        var runs = horizontal[y_key]
        runs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
        var cur_start = int(runs[0][0])
        var cur_end = int(runs[0][1])
        for i in range(1, runs.size()):
            var run = runs[i]
            if int(run[0]) <= cur_end:
                cur_end = max(cur_end, int(run[1]))
            else:
                var ay = grid_origin.y + int(y_key) * grid_cell_size if use_map_space_layout else int(y_key) * grid_cell_size
                var ax = grid_origin.x + cur_start * grid_cell_size if use_map_space_layout else cur_start * grid_cell_size
                var bx = grid_origin.x + cur_end * grid_cell_size if use_map_space_layout else cur_end * grid_cell_size
                merged.append({"a": Vector2(ax, ay), "b": Vector2(bx, ay)})
                cur_start = int(run[0])
                cur_end = int(run[1])
        var end_ay = grid_origin.y + int(y_key) * grid_cell_size if use_map_space_layout else int(y_key) * grid_cell_size
        var end_ax = grid_origin.x + cur_start * grid_cell_size if use_map_space_layout else cur_start * grid_cell_size
        var end_bx = grid_origin.x + cur_end * grid_cell_size if use_map_space_layout else cur_end * grid_cell_size
        merged.append({"a": Vector2(end_ax, end_ay), "b": Vector2(end_bx, end_ay)})
    for x_key in vertical.keys():
        var runs_v = vertical[x_key]
        runs_v.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
        var cur_v_start = int(runs_v[0][0])
        var cur_v_end = int(runs_v[0][1])
        for i in range(1, runs_v.size()):
            var run_v = runs_v[i]
            if int(run_v[0]) <= cur_v_end:
                cur_v_end = max(cur_v_end, int(run_v[1]))
            else:
                var vx = grid_origin.x + int(x_key) * grid_cell_size if use_map_space_layout else int(x_key) * grid_cell_size
                var va = grid_origin.y + cur_v_start * grid_cell_size if use_map_space_layout else cur_v_start * grid_cell_size
                var vb = grid_origin.y + cur_v_end * grid_cell_size if use_map_space_layout else cur_v_end * grid_cell_size
                merged.append({"a": Vector2(vx, va), "b": Vector2(vx, vb)})
                cur_v_start = int(run_v[0])
                cur_v_end = int(run_v[1])
        var end_vx = grid_origin.x + int(x_key) * grid_cell_size if use_map_space_layout else int(x_key) * grid_cell_size
        var end_va = grid_origin.y + cur_v_start * grid_cell_size if use_map_space_layout else cur_v_start * grid_cell_size
        var end_vb = grid_origin.y + cur_v_end * grid_cell_size if use_map_space_layout else cur_v_end * grid_cell_size
        merged.append({"a": Vector2(end_vx, end_va), "b": Vector2(end_vx, end_vb)})
    return merged

func _add_unit_segment(bucket: Dictionary, axis: int, start_val: int, end_val: int):
    if not bucket.has(axis):
        bucket[axis] = []
    bucket[axis].append([start_val, end_val])

func _draw_wall_segment(a: Vector2, b: Vector2, wall_color: Color, edge_color: Color, outer_width: float, inner_width: float):
    if current_skin == "pac_triot":
        draw_line(_world_to_screen(a), _world_to_screen(b), Color(0.85, 0.12, 0.12), _scaled_width(outer_width), true)
        draw_line(_world_to_screen(a), _world_to_screen(b), Color(1.0, 1.0, 1.0), _scaled_width(outer_width * 0.6), true)
        draw_line(_world_to_screen(a), _world_to_screen(b), Color(0.12, 0.25, 0.85), _scaled_width(outer_width * 0.22), true)
    else:
        draw_line(_world_to_screen(a), _world_to_screen(b), wall_color, _scaled_width(outer_width), true)
        draw_line(_world_to_screen(a), _world_to_screen(b), edge_color, _scaled_width(inner_width), true)

func _draw_wall_corner(pos: Vector2, radius: float, wall_color: Color, edge_color: Color):
    var screen_pos = _world_to_screen(pos)
    if current_skin == "pac_triot":
        draw_circle(screen_pos, _scaled_radius(radius), Color(0.85, 0.12, 0.12))
        draw_circle(screen_pos, _scaled_radius(radius * 0.6), Color(1.0, 1.0, 1.0))
        draw_circle(screen_pos, _scaled_radius(radius * 0.22), Color(0.12, 0.25, 0.85))
    else:
        draw_circle(screen_pos, _scaled_radius(radius), wall_color)
        draw_circle(screen_pos, _scaled_radius(max(1.0, radius * 0.34)), edge_color)

func _draw_star(center: Vector2, r: float, color: Color):
    var points = PackedVector2Array()
    for i in range(10):
        var angle = i * PI / 5.0 - PI / 2.0
        var dist = r if i % 2 == 0 else r * 0.4
        points.append(center + Vector2(cos(angle), sin(angle)) * dist)
    draw_colored_polygon(points, color)

func _draw_tea_crate(center: Vector2, size: float):
    var rect = Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
    draw_rect(rect, Color(0.55, 0.35, 0.15), true)
    draw_rect(rect, Color(0.3, 0.18, 0.08), false, _scaled_width(2.0))
    draw_line(rect.position, rect.position + rect.size, Color(0.3, 0.18, 0.08), _scaled_width(1.5))
    draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(0, rect.size.y), Color(0.3, 0.18, 0.08), _scaled_width(1.5))

func _draw_pickups():
    var resolution_ratio = _resolution_ratio()
    for pk in pickups:
        var pos = _world_to_screen(Vector2(pk["x"], pk["y"]))
        var is_power = pk.get("power", false)
        if current_skin == "pac_triot":
            if is_power:
                _draw_tea_crate(pos, _scaled_radius(14.0 * resolution_ratio))
            else:
                _draw_star(pos, _scaled_radius(4.5 * resolution_ratio), Color(1.0, 0.85, 0.1))
        else:
            if is_power:
                draw_circle(pos, _scaled_radius(8.0 * resolution_ratio), Color.WHITE)
            else:
                draw_circle(pos, _scaled_radius(2.4 * resolution_ratio), Color.WHITE)

func _draw_enemies():
    for i in range(enemies.size()):
        var e = enemies[i]
        _draw_ghost(_world_to_screen(Vector2(e["x"], e["y"])), PACMAN_GHOST_COLORS[i % PACMAN_GHOST_COLORS.size()], frightened_timer > 0.0)

func _draw_players():
    for p in players:
        if p.get("alive", true):
            _draw_pacman(_world_to_screen(Vector2(p["x"], p["y"])), player_last_dir)

func _draw_pacman(pos: Vector2, dir: Vector2):
    if current_skin == "pac_triot":
        var angle = dir.angle() if dir.length_squared() > 0.0 else 0.0
        var ratio = _resolution_ratio()
        var r = _scaled_radius(14.0 * ratio)
        var back_dir = -dir if dir.length_squared() > 0.1 else Vector2.LEFT
        
        # Cape
        var cape_pts = PackedVector2Array()
        cape_pts.append(pos)
        cape_pts.append(pos + back_dir.rotated(0.35) * r * 1.5)
        cape_pts.append(pos + back_dir.rotated(-0.35) * r * 1.5)
        draw_colored_polygon(cape_pts, Color(0.12, 0.25, 0.85))
        draw_line(pos, pos + back_dir * r * 1.4, Color(0.85, 0.12, 0.12), _scaled_width(4.0 * ratio))
        
        # Barrel
        var barrel_dir = dir if dir.length_squared() > 0.1 else Vector2.RIGHT
        var barrel_end = pos + barrel_dir * r * 1.35
        draw_line(pos, barrel_end, Color(0.2, 0.22, 0.25), _scaled_width(8.0 * ratio))
        draw_circle(barrel_end, _scaled_radius(4.5 * ratio), Color(0.1, 0.11, 0.12))
        
        # Body
        draw_circle(pos, r * 0.85, Color(0.28, 0.3, 0.33))
        
        # Wheel
        var wheel_pos = pos + Vector2.DOWN * r * 0.25
        draw_circle(wheel_pos, r * 0.5, Color(0.45, 0.24, 0.08))
        draw_circle(wheel_pos, r * 0.42, Color(0.15, 0.16, 0.18))
        
        # Hat
        var top_pos = pos + Vector2.UP * r * 0.65
        draw_rect(Rect2(top_pos - Vector2(4.0 * ratio, 6.0 * ratio), Vector2(8.0 * ratio, 8.0 * ratio)), Color(0.85, 0.12, 0.12), true)
        draw_rect(Rect2(top_pos - Vector2(6.0 * ratio, 0.0), Vector2(12.0 * ratio, 2.0 * ratio)), Color(0.12, 0.25, 0.85), true)
        
        # Fuse
        var fuse_end = pos + Vector2(-r * 0.55, -r * 0.55)
        draw_line(pos, fuse_end, Color.WHITE, 1.5)
        draw_circle(fuse_end, _scaled_radius(2.2 * ratio), Color(1.0, 0.9, 0.1))
    else:
        var angle = dir.angle() if dir.length_squared() > 0.0 else 0.0
        var mouth = 0.26 + 0.14 * abs(sin(Time.get_ticks_msec() / 120.0))
        var points = PackedVector2Array()
        points.append(pos)
        var start_angle = angle + mouth
        var end_angle = angle + TAU - mouth
        var radius = _scaled_radius(14.0 * _resolution_ratio())
        var steps = 22
        for i in range(steps + 1):
            var t = lerpf(start_angle, end_angle, float(i) / float(steps))
            points.append(pos + Vector2.RIGHT.rotated(t) * radius)
        draw_colored_polygon(points, Color(1.0, 0.92, 0.08))

func _draw_ghost(pos: Vector2, color: Color, frightened: bool):
    # Flash white when frightened time is running out
    var flashing = frightened and frightened_timer < frightened_flash_window
    var flash_on = flashing and fmod(frightened_timer, 0.4) < 0.2
    var body: Color
    if not frightened:
        body = Color(0.85, 0.12, 0.12) if current_skin == "pac_triot" else color
    elif flash_on:
        body = Color(1.0, 1.0, 1.0)
    else:
        body = Color(0.22, 0.46, 1.0)
    var ratio = _resolution_ratio()
    var rect = Rect2(pos - Vector2(_scaled_radius(12.5 * ratio), _scaled_radius(11.5 * ratio)), Vector2(_scaled_radius(25 * ratio), _scaled_radius(25 * ratio)))
    draw_rect(Rect2(rect.position + Vector2(0, _scaled_radius(7 * ratio)), Vector2(rect.size.x, rect.size.y - _scaled_radius(7 * ratio))), body, true)
    draw_circle(pos + Vector2(0, _scaled_radius(1 * ratio)), _scaled_radius(12.5 * ratio), body)
    var foot_y = pos.y + _scaled_radius(13.5 * ratio)
    for i in range(4):
        draw_circle(Vector2(pos.x - _scaled_radius(9.0 * ratio) + i * _scaled_radius(6.0 * ratio), foot_y), _scaled_radius(3.0 * ratio), body)
        
    if current_skin == "pac_triot":
        if not frightened:
            # White Crossbelts
            var belt_w = _scaled_width(2.0 * ratio)
            draw_line(pos + Vector2(-8 * ratio, 2 * ratio), pos + Vector2(8 * ratio, 12 * ratio), Color.WHITE, belt_w)
            draw_line(pos + Vector2(8 * ratio, 2 * ratio), pos + Vector2(-8 * ratio, 12 * ratio), Color.WHITE, belt_w)
            
            # Bearskin Hat
            var hat_w = _scaled_radius(11 * ratio)
            var hat_h = _scaled_radius(14 * ratio)
            draw_rect(Rect2(pos.x - hat_w, pos.y - _scaled_radius(22 * ratio), hat_w * 2.0, hat_h), Color(0.1, 0.1, 0.1), true)
            draw_line(pos + Vector2(-hat_w, -_scaled_radius(10 * ratio)), pos + Vector2(hat_w, -_scaled_radius(10 * ratio)), Color(1.0, 0.85, 0.1), 1.5)
            
            # Gentleman Mustache
            draw_circle(pos + Vector2(-2 * ratio, 3 * ratio), _scaled_radius(1.5 * ratio), Color(0.1, 0.1, 0.1))
            draw_circle(pos + Vector2(2 * ratio, 3 * ratio), _scaled_radius(1.5 * ratio), Color(0.1, 0.1, 0.1))
            draw_line(pos + Vector2(-4 * ratio, 3 * ratio), pos + Vector2(4 * ratio, 3 * ratio), Color(0.1, 0.1, 0.1), 2.0)
            
            # Eyes
            var eye_white = Color.WHITE
            var pupil = Color(0.0, 0.16, 0.62)
            draw_circle(pos + Vector2(-_scaled_radius(4.5 * ratio), -_scaled_radius(2.2 * ratio)), _scaled_radius(3.5 * ratio), eye_white)
            draw_circle(pos + Vector2(_scaled_radius(4.5 * ratio), -_scaled_radius(2.2 * ratio)), _scaled_radius(3.5 * ratio), eye_white)
            draw_circle(pos + Vector2(-_scaled_radius(3.5 * ratio), -_scaled_radius(1.1 * ratio)), _scaled_radius(1.4 * ratio), pupil)
            draw_circle(pos + Vector2(_scaled_radius(5.5 * ratio), -_scaled_radius(1.1 * ratio)), _scaled_radius(1.4 * ratio), pupil)
        else:
            # Scared Eyes
            var face_color = Color(1.0, 0.16, 0.2) if flash_on else Color(1.0, 0.72, 0.08)
            draw_circle(pos + Vector2(-_scaled_radius(4.0 * ratio), -_scaled_radius(2.0 * ratio)), _scaled_radius(1.5 * ratio), face_color)
            draw_circle(pos + Vector2(_scaled_radius(4.0 * ratio), -_scaled_radius(2.0 * ratio)), _scaled_radius(1.5 * ratio), face_color)
            
            # Surrender Flag
            var flag_pos = pos + Vector2(10 * ratio, -10 * ratio)
            draw_line(pos + Vector2(6 * ratio, 6 * ratio), flag_pos, Color.WHITE, 1.5)
            var flag_pts = PackedVector2Array()
            flag_pts.append(flag_pos)
            flag_pts.append(flag_pos + Vector2(8 * ratio, -2 * ratio))
            flag_pts.append(flag_pos + Vector2(6 * ratio, 4 * ratio))
            draw_colored_polygon(flag_pts, Color.WHITE)
    else:
        if not frightened:
            var eye_white = Color.WHITE
            var pupil = Color(0.0, 0.16, 0.62)
            draw_circle(pos + Vector2(-_scaled_radius(4.5 * ratio), -_scaled_radius(2.2 * ratio)), _scaled_radius(3.5 * ratio), eye_white)
            draw_circle(pos + Vector2(_scaled_radius(4.5 * ratio), -_scaled_radius(2.2 * ratio)), _scaled_radius(3.5 * ratio), eye_white)
            draw_circle(pos + Vector2(-_scaled_radius(3.5 * ratio), -_scaled_radius(1.1 * ratio)), _scaled_radius(1.4 * ratio), pupil)
            draw_circle(pos + Vector2(_scaled_radius(5.5 * ratio), -_scaled_radius(1.1 * ratio)), _scaled_radius(1.4 * ratio), pupil)
        else:
            var face_color = Color(1.0, 0.16, 0.2) if flash_on else Color(1.0, 0.72, 0.08)
            
            # Eyes
            draw_circle(pos + Vector2(-_scaled_radius(4.0 * ratio), -_scaled_radius(2.0 * ratio)), _scaled_radius(1.5 * ratio), face_color)
            draw_circle(pos + Vector2(_scaled_radius(4.0 * ratio), -_scaled_radius(2.0 * ratio)), _scaled_radius(1.5 * ratio), face_color)
            
            # Wiggly zig-zag mouth
            var mouth_pts = PackedVector2Array()
            mouth_pts.append(pos + Vector2(-_scaled_radius(6.0 * ratio), _scaled_radius(4.0 * ratio)))
            mouth_pts.append(pos + Vector2(-_scaled_radius(4.0 * ratio), _scaled_radius(2.0 * ratio)))
            mouth_pts.append(pos + Vector2(-_scaled_radius(2.0 * ratio), _scaled_radius(4.0 * ratio)))
            mouth_pts.append(pos + Vector2(0.0, _scaled_radius(2.0 * ratio)))
            mouth_pts.append(pos + Vector2(_scaled_radius(2.0 * ratio), _scaled_radius(4.0 * ratio)))
            mouth_pts.append(pos + Vector2(_scaled_radius(4.0 * ratio), _scaled_radius(2.0 * ratio)))
            mouth_pts.append(pos + Vector2(_scaled_radius(6.0 * ratio), _scaled_radius(4.0 * ratio)))
            
            draw_polyline(mouth_pts, face_color, _scaled_width(1.5 * ratio), true)

func _draw_particles():
    for p in active_particles:
        var a = float(p["life"]) / max(0.001, float(p["max_life"]))
        var c = p["color"]
        draw_circle(_world_to_screen(p["pos"]), _scaled_radius(float(p["radius"]) * a), Color(c.r, c.g, c.b, a))

func _draw_hud():
    var score_txt = "LIBERTY SCORE: " if current_skin == "pac_triot" else "SCORE: "
    var lives_txt = "CONSTITUTIONS: " if current_skin == "pac_triot" else "LIVES: "
    draw_string(ThemeDB.fallback_font, Vector2(20, 40), score_txt + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(20, 80), lives_txt + str(lives), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    if game_state == "game_over":
        var center = _world_to_screen(maze_bounds.position + maze_bounds.size * 0.5)
        var msg = "TEA PARTY CRASHED!\n(TAXATION WITHOUT REPRESENTATION)" if current_skin == "pac_triot" else "GAME OVER"
        draw_string(ThemeDB.fallback_font, center, msg, HORIZONTAL_ALIGNMENT_CENTER, -1, 32 if current_skin == "pac_triot" else 48, Color.RED)
    elif game_state == "win":
        var center_win = _world_to_screen(maze_bounds.position + maze_bounds.size * 0.5)
        var msg = "INDEPENDENCE DECLARED!" if current_skin == "pac_triot" else "YOU WIN!"
        draw_string(ThemeDB.fallback_font, center_win, msg, HORIZONTAL_ALIGNMENT_CENTER, -1, 40 if current_skin == "pac_triot" else 48, Color.GREEN)


func _process_player(delta):
    for i in range(players.size()):
        var p = players[i]
        if not p.get("alive", true):
            continue
            
        var pos = Vector2(p["x"], p["y"])
        var p_target_node_id = p.get("target_node_id", "")
        var p_current_node_id = p.get("current_node_id", "")
        
        if p_target_node_id == "":
            var dir = Vector2.ZERO
            
            # Controller
            var jx = Input.get_joy_axis(SharedLoader.get_joy_id(i), JOY_AXIS_LEFT_X)
            var jy = Input.get_joy_axis(SharedLoader.get_joy_id(i), JOY_AXIS_LEFT_Y)
            if abs(jx) > 0.5: dir = Vector2(sign(jx), 0)
            elif abs(jy) > 0.5: dir = Vector2(0, sign(jy))
            
            # DPAD Controller fallback
            if dir == Vector2.ZERO:
                if Input.is_joy_button_pressed(SharedLoader.get_joy_id(i), JOY_BUTTON_DPAD_RIGHT): dir = Vector2(1, 0)
                elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(i), JOY_BUTTON_DPAD_LEFT): dir = Vector2(-1, 0)
                elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(i), JOY_BUTTON_DPAD_DOWN): dir = Vector2(0, 1)
                elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(i), JOY_BUTTON_DPAD_UP): dir = Vector2(0, -1)
            
            # Keyboard fallback for player 0
            if i == 0 and dir == Vector2.ZERO:
                if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
                    dir = Vector2(1, 0)
                elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
                    dir = Vector2(-1, 0)
                elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
                    dir = Vector2(0, 1)
                elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
                    dir = Vector2(0, -1)
            
            if dir != Vector2.ZERO and p_current_node_id != "":
                player_last_dir = dir
                var best_neighbor = _get_best_neighbor(p_current_node_id, dir)
                if best_neighbor != "":
                    p["target_node_id"] = best_neighbor
                    p_target_node_id = best_neighbor
                    
        if p_target_node_id != "":
            var target_node = _get_node(p_target_node_id)
            if target_node:
                var target_pos = Vector2(target_node.get("x", 0), target_node.get("y", 0))
                var move_vec = target_pos - pos
                if move_vec.length() <= player_speed * delta:
                    pos = target_pos
                    p["current_node_id"] = p_target_node_id
                    p["target_node_id"] = ""
                else:
                    pos += move_vec.normalized() * player_speed * delta
                    
        p["x"] = pos.x
        p["y"] = pos.y
        
        # Check Pickups
        if game_time > 0.5:
            for j in range(pickups.size() - 1, -1, -1):
                var pickup = pickups[j]
                if pos.distance_to(Vector2(pickup["x"], pickup["y"])) < max(12.0, grid_cell_size * 0.35):
                    var pickup_pos = Vector2(pickup["x"], pickup["y"])
                    pickups.remove_at(j)
                    var is_power = pickup.get("power", false)
                    if is_power:
                        frightened_timer = frightened_duration
                        frightened_chain_count = 0
                        spawn_particle_burst(pickup_pos, Color(0.4, 0.6, 1.0), 30)
                        score += 50
                    else:
                        spawn_particle_burst(pickup_pos, Color.YELLOW, 15)
                        score += 10
                    send_ipc_message({"type": "score", "data": {"player": i + 1, "score": score}})
                    
                    if pickups.size() == 0:
                        game_state = "win"
                        send_ipc_message({"type": "state", "data": {"state": "win"}})

func _get_degree(node_id: String) -> int:
    var deg = 0
    for edge in graph_edges:
        if str(edge.get("source", "")) == node_id or str(edge.get("target", "")) == node_id:
            deg += 1
    return deg

func _process_enemies(delta):
    var player_pos = Vector2.ZERO
    var has_living_player = false
    for p in players:
        if p.get("alive", true):
            player_pos = Vector2(p["x"], p["y"])
            has_living_player = true
            break
            
    for i in range(enemies.size()):
        var e = enemies[i]
        if e.get("eaten", false):
            continue
        var pos = Vector2(e["x"], e["y"])
        var e_target_node_id = e.get("target_node_id", "")
        var e_current_node_id = e.get("current_node_id", "")
        var is_frightened = frightened_timer > 0.0
        var e_speed = e["speed"]
        if is_frightened:
            e_speed *= 0.55
        
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
                if is_frightened and has_living_player and possible.size() > 1:
                    # Flee: pick the neighbor FURTHEST from player
                    var best_flee_id = possible[0]
                    var best_flee_dist = -1.0
                    for nid in possible:
                        var nnode = _get_node(nid)
                        if nnode:
                            var nd = Vector2(nnode.get("x", 0.0), nnode.get("y", 0.0)).distance_to(player_pos)
                            if nd > best_flee_dist:
                                best_flee_dist = nd
                                best_flee_id = nid
                    e["target_node_id"] = best_flee_id
                else:
                    e["target_node_id"] = possible[randi() % possible.size()]
                e_target_node_id = e["target_node_id"]
        
        if e_target_node_id != "":
            var target_node = _get_node(e_target_node_id)
            if target_node:
                var target_pos = Vector2(target_node.get("x", 0), target_node.get("y", 0))
                var move_vec = target_pos - pos
                if move_vec.length() <= e_speed * delta:
                    pos = target_pos
                    e["prev_node_id"] = e_current_node_id
                    e["current_node_id"] = e_target_node_id
                    e["target_node_id"] = ""
                else:
                    pos += move_vec.normalized() * e_speed * delta
        
        e["x"] = pos.x
        e["y"] = pos.y
        
        # Check collision with players
        var catch_dist = max(16.0, grid_cell_size * 0.5)
        for j in range(players.size()):
            var p = players[j]
            if p.get("alive", true):
                if pos.distance_to(Vector2(p["x"], p["y"])) < catch_dist:
                    if is_frightened:
                        # Eat the ghost!
                        frightened_chain_count += 1
                        var ghost_score = 200 * int(pow(2, min(frightened_chain_count - 1, 4)))
                        score += ghost_score
                        send_ipc_message({"type": "score", "data": {"player": j + 1, "score": score}})
                        spawn_particle_burst(pos, Color(0.4, 0.6, 1.0), 25)
                        # Respawn ghost at its original spawn
                        if i < original_enemy_spawns.size():
                            var sp = original_enemy_spawns[i]
                            e["x"] = sp["x"]
                            e["y"] = sp["y"]
                            e["current_node_id"] = sp["id"]
                            e["target_node_id"] = ""
                            e["prev_node_id"] = ""
                    else:
                        _on_player_caught(j)

func _on_player_caught(player_idx):
    var p = players[player_idx]
    spawn_particle_burst(Vector2(p["x"], p["y"]), Color.RED, 30)
    p["alive"] = false
    
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
    frightened_timer = 0.0
    frightened_chain_count = 0
    
    for i in range(players.size()):
        if i < original_player_spawns.size():
            var sp = original_player_spawns[i]
            players[i].x = sp["x"]
            players[i].y = sp["y"]
            players[i].current_node_id = sp["id"]
            players[i].target_node_id = ""
            players[i].alive = true
            
    for i in range(enemies.size()):
        if i < original_enemy_spawns.size():
            var sp = original_enemy_spawns[i]
            enemies[i].x = sp["x"]
            enemies[i].y = sp["y"]
            enemies[i].current_node_id = sp["id"]
            enemies[i].target_node_id = ""
            enemies[i].prev_node_id = ""

func _restart_game():
    score = 0
    lives = 3
    game_time = 0.0
    game_state = "playing"
    send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})
    pickups = original_pickups.duplicate(true)
    _respawn_all()
func _process_particles(delta):
    for i in range(active_particles.size() - 1, -1, -1):
        var p = active_particles[i]
        p["life"] = float(p["life"]) - delta
        if float(p["life"]) <= 0.0:
            active_particles.remove_at(i)
            continue
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
        p["vel"] = Vector2(p["vel"]) * 0.92
func _load_level_adjustments(): pass
func _update_menu_overlay(): pass
