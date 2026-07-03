extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()
var splash_rect: TextureRect
var splash_timer: float = 2.0

var ipc_socket: StreamPeerTCP = null
var scene_dir: String = ""
var level_dir: String = ""
var ipc_port: int = 0
var ipc_host: String = "127.0.0.1"

var heartbeat_timer: float = 0.0
var read_buffer: String = ""
var prev_keys = {}
var prev_joy_buttons = {}
var prev_joy_axes = {}
var active_particles = []

# Container data
var well_polygon = []
var spawn_lip = Vector2.ZERO
var down_direction = Vector2(0, 1)

# Block Stack Data
var BLOCK_SIZE = 30.0
var grid_width = 0
var grid_height = 0
var grid = [] # 2D array [x][y] storing color or null

# Multiplayer variables
var num_players = 2
var active_pieces = []
var fall_timers = []
var fall_speeds = []
var scores = []

const SHAPES = [
    [Vector2(0,-1), Vector2(0,0), Vector2(0,1), Vector2(0,2)], # I
    [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)], # O
    [Vector2(-1,0), Vector2(0,0), Vector2(1,0), Vector2(0,-1)], # T
    [Vector2(-1,1), Vector2(-1,0), Vector2(0,0), Vector2(1,0)], # J
    [Vector2(1,1), Vector2(-1,0), Vector2(0,0), Vector2(1,0)], # L
    [Vector2(-1,0), Vector2(0,0), Vector2(0,-1), Vector2(1,-1)], # S
    [Vector2(-1,-1), Vector2(0,-1), Vector2(0,0), Vector2(1,0)] # Z
]
const COLORS = [
    Color(0.0, 0.9, 1.0), # Cyan
    Color(1.0, 0.8, 0.0), # Yellow
    Color(0.7, 0.0, 1.0), # Purple
    Color(0.0, 0.3, 1.0), # Blue
    Color(1.0, 0.5, 0.0), # Orange
    Color(0.0, 0.9, 0.2), # Green
    Color(1.0, 0.1, 0.2)  # Red
]

# Reference Background
var reference_texture: Texture2D = null
var photo_texture: Texture2D = null
var semantic_texture: Texture2D = null
var secondary_texture: Texture2D = null
var collision_preview_texture: Texture2D = null
var show_reference: bool = true
var reference_opacity: float = 0.3
var background_view: String = "photo"
var secondary_photo_mix: float = 0.18
var show_debug_grid: bool = true

# Visual Skin
var current_skin: String = "classic" # "classic" or "neon"
var settings = {
    "organic_behavior": "stick",
    "blur_radius": 1,
    "wall_threshold": 0.5,
    "show_outline": true,
    "show_grid": true
}
var tab_menu = null
var screenshot_path: String = ""
var map_w: float = 667.0
var map_h: float = 981.0
var scale_factor: float = 1.0
var offset_x: float = 0.0
var offset_y: float = 0.0

func _ready():
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    print("Block Stack _ready called. Args: ", args)
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
            if skin_arg == "Classic Tetris":
                current_skin = "classic"
            else:
                current_skin = "neon"
            i += 1
        i += 1

    if ipc_port > 0:
        ipc_socket = StreamPeerTCP.new()
        ipc_socket.connect_to_host(ipc_host, ipc_port)
    
    send_ipc_message({"type": "ready"})
    
    # Detect connected controllers and scale players (2 to 4)
    var connected_joypads = Input.get_connected_joypads()
    num_players = clamp(max(2, connected_joypads.size()), 2, 4)
    
    load_level()
    _load_reference_assets()
    
    # Setup splash screen
    var canvas = CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)
    
    splash_rect = TextureRect.new()
    splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path):
        var img = Image.load_from_file(splash_path)
        if img: splash_rect.texture = ImageTexture.create_from_image(img)
    canvas.add_child(splash_rect)

    var SL = load(_repo_root().path_join("app/shared/shared_loader.gd"))
    tab_menu = SL.load_tab_menu_script().new()
    add_child(tab_menu)
    tab_menu.register_knob_enum("background_view", "Background View", background_view, ["final", "photo", "semantic", "secondary", "collision"], "Preview")
    tab_menu.register_knob_bool("reference", "Background Layer", show_reference, "Preview")
    tab_menu.register_knob_float("reference_opacity", "Background Opacity", reference_opacity, 0.0, 1.0, 0.05, "Preview")
    tab_menu.register_knob_float("secondary_photo_mix", "Secondary Photo Mix", secondary_photo_mix, 0.0, 0.6, 0.05, "Preview")
    tab_menu.register_knob_bool("show_debug_grid", "Scale Grid Overlay", show_debug_grid, "Preview")
    
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true, "Collision")
    
    tab_menu.register_knob_bool("invert", "Invert", false, "Secondary")
    tab_menu.register_knob_bool("fill", "Fill", false, "Secondary")
    tab_menu.register_knob_float("grid_scale", "Grid Scale", 1.0, 0.5, 2.0, 0.1, "Secondary")
    tab_menu.register_knob_float("density", "Density", 1.0, 0.1, 2.0, 0.1, "Secondary")
    tab_menu.register_knob_float("wall_width", "Wall Width", 1.0, 0.5, 2.0, 0.1, "Secondary")
    tab_menu.register_knob_float("group_islands", "Group Islands", 0.0, 0.0, 5.0, 1.0, "Secondary")
    tab_menu.register_knob_float("spawn_clearance", "Spawn Clearance", 0.0, 0.0, 1.0, 0.05, "Secondary")
    
    tab_menu.register_knob_enum("organic_behavior", "Organic Behavior", "stick", ["stick", "slide", "tumble"], "Gameplay")
    tab_menu.register_knob_bool("show_outline", "Show Level Outline", true, "Gameplay")
    tab_menu.register_knob_int("players", "Players", num_players, 1, 4, 1, "Gameplay")
    
    tab_menu.connect("knob_changed", Callable(self, "_on_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_menu_action"))
    
    tab_menu.setup("tetris", level_dir, "TETRIS")
    var old_players = num_players
    _apply_settings_from_menu()
    if num_players != old_players:
        load_level()

    if screenshot_path != "":
        await get_tree().create_timer(2.35).timeout
        var img = get_viewport().get_texture().get_image()
        img.save_png(screenshot_path)
        print("Cartridge screenshot saved to: ", screenshot_path)
        get_tree().quit()

func _apply_settings_from_menu():
    if tab_menu:
        settings["organic_behavior"] = str(tab_menu.get_knob_value("organic_behavior"))
        settings["show_outline"] = bool(tab_menu.get_knob_value("show_outline"))
        num_players = int(tab_menu.get_knob_value("players"))
        show_debug_grid = bool(tab_menu.get_knob_value("show_debug_grid"))
        background_view = str(tab_menu.get_knob_value("background_view"))
        show_reference = bool(tab_menu.get_knob_value("reference"))
        reference_opacity = float(tab_menu.get_knob_value("reference_opacity"))
        secondary_photo_mix = float(tab_menu.get_knob_value("secondary_photo_mix"))
    _apply_classic_level_defaults()

func _is_classic_tetris_level() -> bool:
    return level_dir.get_file() == "classic_tetris"

func _apply_classic_level_defaults():
    if not _is_classic_tetris_level():
        return
    show_reference = false
    show_debug_grid = false
    background_view = "final"
    reference_opacity = 0.0

func _on_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["invert", "fill", "grid_scale", "density", "bounds_clamp", "wall_width", "group_islands", "spawn_clearance", "players"]:
        load_level()
    queue_redraw()

func _on_menu_action(action_id: String):
    pass

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:
            show_reference = not show_reference
            if tab_menu:
                tab_menu.set_knob_value("reference", show_reference, false, false)
            queue_redraw()
        elif event.keycode == KEY_F2:
            if current_skin == "classic":
                current_skin = "neon"
            else:
                current_skin = "classic"
            queue_redraw()

func _load_reference_assets():
    photo_texture = null
    semantic_texture = null
    secondary_texture = null
    if level_dir == "": return
    
    var sem_path = level_dir.path_join("semantic_map.png")
    if FileAccess.file_exists(sem_path):
        var img = Image.load_from_file(sem_path)
        if img:
            semantic_texture = ImageTexture.create_from_image(img)
            
    var yaml_path = level_dir.path_join("level.yaml")
    if FileAccess.file_exists(yaml_path):
        var data = parse_simple_yaml(yaml_path)
        var bg_file = data.get("reference_image", "")
        if bg_file != "":
            var bg_path = level_dir.path_join(bg_file)
            if FileAccess.file_exists(bg_path):
                var img = Image.load_from_file(bg_path)
                if img:
                    photo_texture = ImageTexture.create_from_image(img)
                    
    var sec_path = level_dir.path_join("derived").path_join("secondary.png")
    if FileAccess.file_exists(sec_path):
        var img = Image.load_from_file(sec_path)
        if img:
            secondary_texture = ImageTexture.create_from_image(img)

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
    if splash_rect and splash_timer > 0:
        splash_timer -= delta
        if splash_timer <= 0:
            var parent = splash_rect.get_parent()
            splash_rect.visible = false
            splash_rect.queue_free()
            splash_rect = null
            if parent is CanvasLayer:
                parent.queue_free()
        elif splash_timer < 1.0:
            splash_rect.modulate.a = splash_timer
    _process_ipc(delta)
    if visible and well_polygon.size() > 0:
        if tab_menu == null or tab_menu.overlay_mode == "":
            _process_game(delta)
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
                load_level()
                _load_reference_assets()

func load_level():
    if level_dir == "": return
    
    var semantic_img: Image = null
    var map_path = level_dir.path_join("semantic_map.png")
    if FileAccess.file_exists(map_path):
        semantic_img = Image.load_from_file(map_path)
        if semantic_img:
            map_w = semantic_img.get_width()
            map_h = semantic_img.get_height()

    var classic_empty_well = _is_classic_tetris_level()
    _apply_classic_level_defaults()
            
    # Calculate scale factor and offset to center and fill screen (1920x1080)
    var viewport_size = get_viewport_rect().size
    var scale_x = viewport_size.x / map_w
    var scale_y = viewport_size.y / map_h
    scale_factor = min(scale_x, scale_y)
    offset_x = (viewport_size.x - map_w * scale_factor) / 2.0
    offset_y = (viewport_size.y - map_h * scale_factor) / 2.0
    print("Block Stack Scale: ", scale_factor, " Offset: ", offset_x, ", ", offset_y)

    var SL = load(_repo_root().path_join("app/shared/shared_loader.gd"))
    var adapter = SL.load_adapter_script("well_fill").new()
    var invert_val = tab_menu.get_knob_value("invert") if tab_menu else false
    var fill_val = tab_menu.get_knob_value("fill") if tab_menu else true
    var grid_scale_val = tab_menu.get_knob_value("grid_scale") if tab_menu else 1.0
    var density_val = tab_menu.get_knob_value("density") if tab_menu else 1.0
    var bounds_clamp_val = tab_menu.get_knob_value("bounds_clamp") if tab_menu else true
    var wall_width_val = tab_menu.get_knob_value("wall_width") if tab_menu else 1.0
    var group_islands_val = int(tab_menu.get_knob_value("group_islands")) if tab_menu else 0
    var spawn_clearance_val = tab_menu.get_knob_value("spawn_clearance") if tab_menu else 0.0
    
    BLOCK_SIZE = 30.0 * grid_scale_val
    
    var layout = adapter.interpret(level_dir, {}, {})
    
    well_polygon.clear()
    for p in layout.get("well_polygon", []):
        well_polygon.append(Vector2(p.x * scale_factor + offset_x, p.y * scale_factor + offset_y))
            
    if wall_width_val != 1.0 and well_polygon.size() > 2:
        var offset_px = (wall_width_val - 1.0) * -32.0 * scale_factor
        var offset_polys = Geometry2D.offset_polygon(well_polygon, offset_px)
        if offset_polys.size() > 0:
            var largest = offset_polys[0]
            for i in range(1, offset_polys.size()):
                if offset_polys[i].size() > largest.size():
                    largest = offset_polys[i]
            well_polygon = largest
            
    var well_bounds = Rect2()
    if well_polygon.size() > 0:
        well_bounds.position = well_polygon[0]
        well_bounds.size = Vector2.ZERO
        for p in well_polygon:
            well_bounds = well_bounds.expand(p)
    
    var lip = layout.get("spawn_lip", Vector2(map_w / 2.0, 0))
    spawn_lip = Vector2(lip.x * scale_factor + offset_x, lip.y * scale_factor + offset_y)
    
    down_direction = layout.get("down_direction", Vector2(0, 1))
    
    var grid_cells = layout.get("cells", [])
    var bounds = layout.get("bounds", Rect2(0,0,map_w,map_h))
    
    # Init Grid
    grid_width = int(1920 / BLOCK_SIZE) + 1
    grid_height = int(1080 / BLOCK_SIZE) + 1
    
    grid.resize(grid_width)
    var c_size = layout.get("cell_size", 32.0)
    
    var temp_grid = []
    for x in range(grid_width):
        var col = []
        col.resize(grid_height)
        for y in range(grid_height):
            var center = Vector2(x * BLOCK_SIZE + BLOCK_SIZE/2.0, y * BLOCK_SIZE + BLOCK_SIZE/2.0)
            var inside_well = true
            if well_polygon.size() > 2 and not Geometry2D.is_point_in_polygon(center, well_polygon):
                inside_well = false
                
            var map_center = (center - Vector2(offset_x, offset_y)) / scale_factor
            if bounds_clamp_val and not bounds.has_point(map_center):
                inside_well = false
                
            if not inside_well:
                col[y] = false
                continue
                
            var hits_cell = false
            if classic_empty_well:
                hits_cell = false
            elif semantic_img != null and map_center.x >= 0 and map_center.y >= 0 and map_center.x < semantic_img.get_width() and map_center.y < semantic_img.get_height():
                var px_color = semantic_img.get_pixel(int(map_center.x), int(map_center.y))
                # Cyan (0.0, 0.9, 1.0) is lane/empty space. Other colors are solid.
                var cyan_dist = abs(px_color.r - 0.0) + abs(px_color.g - 0.9) + abs(px_color.b - 1.0)
                if cyan_dist < 0.15:
                    hits_cell = false
                else:
                    hits_cell = true
            else:
                for c in grid_cells:
                    if abs(c.x - map_center.x) < c_size/2.0 and abs(c.y - map_center.y) < c_size/2.0:
                        hits_cell = true
                        break
            col[y] = hits_cell
        temp_grid.append(col)
        
    for pass_idx in range(group_islands_val):
        var dilated = []
        for x in range(grid_width):
            var d_col = []
            d_col.resize(grid_height)
            for y in range(grid_height):
                var blocked = temp_grid[x][y]
                if not blocked:
                    var neighbor_blocked = false
                    for dx in [-1, 0, 1]:
                        for dy in [-1, 0, 1]:
                            if dx == 0 and dy == 0: continue
                            var nx = x + dx
                            var ny = y + dy
                            if nx >= 0 and nx < grid_width and ny >= 0 and ny < grid_height:
                                if temp_grid[nx][ny]:
                                    neighbor_blocked = true
                                    break
                        if neighbor_blocked: break
                    if neighbor_blocked:
                        var center = Vector2(x * BLOCK_SIZE + BLOCK_SIZE/2.0, y * BLOCK_SIZE + BLOCK_SIZE/2.0)
                        if well_polygon.size() <= 2 or Geometry2D.is_point_in_polygon(center, well_polygon):
                            blocked = true
                d_col[y] = blocked
            dilated.append(d_col)
        temp_grid = dilated
        
    var clear_y_max = well_bounds.position.y + well_bounds.size.y * spawn_clearance_val
    for x in range(grid_width):
        for y in range(grid_height):
            var center = Vector2(x * BLOCK_SIZE + BLOCK_SIZE/2.0, y * BLOCK_SIZE + BLOCK_SIZE/2.0)
            var inside_well = true
            if well_polygon.size() > 2 and not Geometry2D.is_point_in_polygon(center, well_polygon):
                inside_well = false
            if not inside_well:
                continue
                
            var hits_cell = temp_grid[x][y]

            if classic_empty_well:
                temp_grid[x][y] = false
                continue
            
            if center.y < clear_y_max:
                hits_cell = false
                
            if invert_val:
                hits_cell = not hits_cell
                
            if hits_cell and density_val < 1.0:
                if randf() > density_val:
                    hits_cell = false
                    
            temp_grid[x][y] = hits_cell
            
    for x in range(grid_width):
        grid[x] = []
        grid[x].resize(grid_height)
                
            if invert_val:
                hits_cell = not hits_cell
                
            if hits_cell and density_val < 1.0:
                if randf() > density_val:
                    hits_cell = false
                    
            temp_grid[x][y] = hits_cell
            
    for x in range(grid_width):
        grid[x] = []
        grid[x].resize(grid_height)
        for y in range(grid_height):
            var center = Vector2(x * BLOCK_SIZE + BLOCK_SIZE/2.0, y * BLOCK_SIZE + BLOCK_SIZE/2.0)
            var inside_well = true
            if well_polygon.size() > 2 and not Geometry2D.is_point_in_polygon(center, well_polygon):
                inside_well = false
            if not inside_well:
                if center.y < well_bounds.position.y:
                    grid[x][y] = null
                else:
                    grid[x][y] = Color(0.0, 0.0, 0.0, 0.0)
                continue
                
            var is_blocked = temp_grid[x][y]
            if not fill_val and is_blocked:
                var surrounded = true
                for dx in [-1, 0, 1]:
                    for dy in [-1, 0, 1]:
                        if dx == 0 and dy == 0: continue
                        var nx = x + dx
                        var ny = y + dy
                        if nx >= 0 and nx < grid_width and ny >= 0 and ny < grid_height:
                            if not temp_grid[nx][ny]:
                                surrounded = false
                                break
                if surrounded:
                    is_blocked = false
            
            if is_blocked:
                grid[x][y] = Color(0.1, 0.1, 0.1, 0.5)
            else:
                grid[x][y] = null
                
    # Resize player arrays
    active_pieces.resize(num_players)
    fall_timers.resize(num_players)
    fall_speeds.resize(num_players)
    scores.resize(num_players)
    for p in range(num_players):
        fall_timers[p] = 0.0
        fall_speeds[p] = 0.5
        scores[p] = 0
        active_pieces[p] = {}
        spawn_piece(p)
        
    _build_collision_preview_texture()

func _build_collision_preview_texture():
    collision_preview_texture = null
    if map_w <= 0 or map_h <= 0: return
    var width = max(1, int(map_w))
    var height = max(1, int(map_h))
    var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    
    for x in range(grid_width):
        for y in range(grid_height):
            if grid[x][y] == Color(0.1, 0.1, 0.1, 0.5): # wall
                var px = int(round((x * BLOCK_SIZE - offset_x) / scale_factor))
                var py = int(round((y * BLOCK_SIZE - offset_y) / scale_factor))
                var sz = int(round(BLOCK_SIZE / scale_factor))
                var rect = Rect2i(px, py, sz, sz).intersection(Rect2i(0, 0, int(map_w), int(map_h)))
                if rect.has_area():
                    img.fill_rect(rect, Color(0.0, 0.95, 0.46, 0.18))
                
    collision_preview_texture = ImageTexture.create_from_image(img)

func spawn_piece(p_idx: int):
    var type = randi() % 7
    # Distribute players horizontally from spawn lip
    var offset_x = (p_idx - (num_players - 1) / 2.0) * 4
    var spawn_x = clamp(int(spawn_lip.x / BLOCK_SIZE) + offset_x, 1, grid_width - 2)
    
    active_pieces[p_idx] = {
        "blocks": SHAPES[type].duplicate(),
        "color": COLORS[type],
        "pos": Vector2(spawn_x, int(spawn_lip.y / BLOCK_SIZE))
    }
    
    if not is_valid_pos(active_pieces[p_idx].pos, active_pieces[p_idx].blocks, p_idx):
        # Game Over logic - just clear this player's blocks or the whole grid
        send_ipc_message({"type": "state", "data": {"status": "game_over", "player": p_idx + 1}})
        for x in range(grid_width):
            for y in range(grid_height):
                if grid[x][y] != Color(0.1, 0.1, 0.1, 0.5):
                    grid[x][y] = null
        for p in range(num_players):
            scores[p] = 0
            send_ipc_message({"type": "score", "data": {"player": p + 1, "score": scores[p]}})

func is_key_just_pressed(key: int) -> bool:
    var pressed = Input.is_key_pressed(key)
    var was_pressed = prev_keys.get(key, false)
    prev_keys[key] = pressed
    return pressed and not was_pressed

func is_joy_button_just_pressed(device: int, button: int) -> bool:
    var joy_id = SharedLoader.get_joy_id(device)
    if joy_id < 0:
        return false
    var pressed = Input.is_joy_button_pressed(joy_id, button)
    var key = "%d_%d" % [device, button]
    var was_pressed = prev_joy_buttons.get(key, false)
    prev_joy_buttons[key] = pressed
    return pressed and not was_pressed

func is_joy_button_pressed(device: int, button: int) -> bool:
    var joy_id = SharedLoader.get_joy_id(device)
    if joy_id < 0:
        return false
    return Input.is_joy_button_pressed(joy_id, button)

func is_joy_axis_just_pressed(device: int, axis: int, direction: float, threshold: float = 0.55) -> bool:
    var joy_id = SharedLoader.get_joy_id(device)
    if joy_id < 0:
        return false
    var pressed = Input.get_joy_axis(joy_id, axis) * direction > threshold
    var key = "%d_%d_%d" % [device, axis, int(sign(direction))]
    var was_pressed = prev_joy_axes.get(key, false)
    prev_joy_axes[key] = pressed
    return pressed and not was_pressed

func is_joy_axis_pressed(device: int, axis: int, direction: float, threshold: float = 0.55) -> bool:
    var joy_id = SharedLoader.get_joy_id(device)
    if joy_id < 0:
        return false
    return Input.get_joy_axis(joy_id, axis) * direction > threshold

func get_player_inputs(p_idx: int) -> Dictionary:
    var inputs = {"left": false, "right": false, "rotate_left": false, "rotate_right": false, "down": false, "hard_drop": false}
    if p_idx == 0:
        inputs.left = is_key_just_pressed(KEY_A) or is_joy_button_just_pressed(0, JOY_BUTTON_DPAD_LEFT) or is_joy_axis_just_pressed(0, JOY_AXIS_LEFT_X, -1.0)
        inputs.right = is_key_just_pressed(KEY_D) or is_joy_button_just_pressed(0, JOY_BUTTON_DPAD_RIGHT) or is_joy_axis_just_pressed(0, JOY_AXIS_LEFT_X, 1.0)
        inputs.rotate_left = is_key_just_pressed(KEY_Q) or is_key_just_pressed(KEY_Z) or is_joy_button_just_pressed(0, JOY_BUTTON_LEFT_SHOULDER) or is_joy_button_just_pressed(0, JOY_BUTTON_X)
        inputs.rotate_right = is_key_just_pressed(KEY_W) or is_key_just_pressed(KEY_E) or is_joy_button_just_pressed(0, JOY_BUTTON_DPAD_UP) or is_joy_button_just_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or is_joy_button_just_pressed(0, JOY_BUTTON_A)
        inputs.down = Input.is_key_pressed(KEY_S) or is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN) or is_joy_axis_pressed(0, JOY_AXIS_LEFT_Y, 1.0)
        inputs.hard_drop = is_key_just_pressed(KEY_SPACE) or is_joy_button_just_pressed(0, JOY_BUTTON_B)
    elif p_idx == 1:
        inputs.left = is_key_just_pressed(KEY_LEFT) or is_joy_button_just_pressed(1, JOY_BUTTON_DPAD_LEFT) or is_joy_axis_just_pressed(1, JOY_AXIS_LEFT_X, -1.0)
        inputs.right = is_key_just_pressed(KEY_RIGHT) or is_joy_button_just_pressed(1, JOY_BUTTON_DPAD_RIGHT) or is_joy_axis_just_pressed(1, JOY_AXIS_LEFT_X, 1.0)
        inputs.rotate_left = is_key_just_pressed(KEY_COMMA) or is_joy_button_just_pressed(1, JOY_BUTTON_LEFT_SHOULDER) or is_joy_button_just_pressed(1, JOY_BUTTON_X)
        inputs.rotate_right = is_key_just_pressed(KEY_UP) or is_key_just_pressed(KEY_PERIOD) or is_joy_button_just_pressed(1, JOY_BUTTON_DPAD_UP) or is_joy_button_just_pressed(1, JOY_BUTTON_RIGHT_SHOULDER) or is_joy_button_just_pressed(1, JOY_BUTTON_A)
        inputs.down = Input.is_key_pressed(KEY_DOWN) or is_joy_button_pressed(1, JOY_BUTTON_DPAD_DOWN) or is_joy_axis_pressed(1, JOY_AXIS_LEFT_Y, 1.0)
        inputs.hard_drop = is_key_just_pressed(KEY_ENTER) or is_joy_button_just_pressed(1, JOY_BUTTON_B)
    elif p_idx == 2:
        inputs.left = is_joy_button_just_pressed(2, JOY_BUTTON_DPAD_LEFT) or is_joy_axis_just_pressed(2, JOY_AXIS_LEFT_X, -1.0)
        inputs.right = is_joy_button_just_pressed(2, JOY_BUTTON_DPAD_RIGHT) or is_joy_axis_just_pressed(2, JOY_AXIS_LEFT_X, 1.0)
        inputs.rotate_left = is_joy_button_just_pressed(2, JOY_BUTTON_LEFT_SHOULDER) or is_joy_button_just_pressed(2, JOY_BUTTON_X)
        inputs.rotate_right = is_joy_button_just_pressed(2, JOY_BUTTON_DPAD_UP) or is_joy_button_just_pressed(2, JOY_BUTTON_RIGHT_SHOULDER) or is_joy_button_just_pressed(2, JOY_BUTTON_A)
        inputs.down = is_joy_button_pressed(2, JOY_BUTTON_DPAD_DOWN) or is_joy_axis_pressed(2, JOY_AXIS_LEFT_Y, 1.0)
        inputs.hard_drop = is_joy_button_just_pressed(2, JOY_BUTTON_B)
    elif p_idx == 3:
        inputs.left = is_joy_button_just_pressed(3, JOY_BUTTON_DPAD_LEFT) or is_joy_axis_just_pressed(3, JOY_AXIS_LEFT_X, -1.0)
        inputs.right = is_joy_button_just_pressed(3, JOY_BUTTON_DPAD_RIGHT) or is_joy_axis_just_pressed(3, JOY_AXIS_LEFT_X, 1.0)
        inputs.rotate_left = is_joy_button_just_pressed(3, JOY_BUTTON_LEFT_SHOULDER) or is_joy_button_just_pressed(3, JOY_BUTTON_X)
        inputs.rotate_right = is_joy_button_just_pressed(3, JOY_BUTTON_DPAD_UP) or is_joy_button_just_pressed(3, JOY_BUTTON_RIGHT_SHOULDER) or is_joy_button_just_pressed(3, JOY_BUTTON_A)
        inputs.down = is_joy_button_pressed(3, JOY_BUTTON_DPAD_DOWN) or is_joy_axis_pressed(3, JOY_AXIS_LEFT_Y, 1.0)
        inputs.hard_drop = is_joy_button_just_pressed(3, JOY_BUTTON_B)
    return inputs

func _process_game(delta):
    for p in range(num_players):
        var piece = active_pieces[p]
        if piece == null or piece.is_empty(): continue
        
        if piece.get("is_simulating", false):
            if settings["organic_behavior"] != "tumble":
                lock_simulating_piece(p)
                continue
            _process_simulating_piece(p, delta)
            continue
            
        var inputs = get_player_inputs(p)
        
        if inputs.hard_drop:
            while try_move(p, Vector2(0, 1)):
                pass
            lock_piece(p)
            continue
            
        if inputs.left:
            try_move(p, Vector2(-1, 0))
        elif inputs.right:
            try_move(p, Vector2(1, 0))
        elif inputs.rotate_left:
            try_rotate(p, -1)
        elif inputs.rotate_right:
            try_rotate(p, 1)
            
        if settings["organic_behavior"] == "tumble" and is_touching_awkward_wall(p):
            start_simulation(p)
            continue
            
        var actual_speed = fall_speeds[p]
        if inputs.down:
            actual_speed = fall_speeds[p] * 0.1
            
        fall_timers[p] += delta
        if fall_timers[p] >= actual_speed:
            fall_timers[p] = 0.0
            if not try_move(p, Vector2(0, 1)):
                if settings["organic_behavior"] == "slide" and can_slide_on_obstacle(p):
                    if not try_move(p, Vector2(-1, 1)):
                        if not try_move(p, Vector2(1, 1)):
                            lock_piece(p)
                elif settings["organic_behavior"] == "tumble" and is_touching_awkward_wall(p):
                    start_simulation(p)
                else:
                    lock_piece(p)

func try_move(p_idx: int, offset: Vector2) -> bool:
    var piece = active_pieces[p_idx]
    if is_valid_pos(piece.pos + offset, piece.blocks, p_idx):
        piece.pos += offset
        return true
    return false
    
func try_rotate(p_idx: int, direction: int = 1):
    var piece = active_pieces[p_idx]
    var new_blocks = []
    for b in piece.blocks:
        if direction < 0:
            new_blocks.append(Vector2(b.y, -b.x))
        else:
            new_blocks.append(Vector2(-b.y, b.x))
    if is_valid_pos(piece.pos, new_blocks, p_idx):
        piece.blocks = new_blocks
    if current_skin == "classic":
        # Flat classic block with solid dark borders
        draw_rect(rect, color)
        draw_rect(rect, Color.BLACK, false, 2.0)
    else:
        # Neon glowing translucent block: saturated translucent fill, 1px neon edge, punchy soft glow
        # Soft glow: drop-shadow (draw a slightly larger rect with low opacity)
        draw_rect(Rect2(rect.position - Vector2(4, 4), rect.size + Vector2(8, 8)), Color(color.r, color.g, color.b, 0.4), false, 4.0)
        # Translucent fill (35% to read its color on black)
        draw_rect(rect, Color(color.r, color.g, color.b, 0.35))
        # 1px neon edge
        draw_rect(rect, color, false, 1.5)

func draw_background_grid():
    var grid_spacing = 80.0
    var line_color = Color(1.0, 1.0, 1.0, 0.08) # thin white lattice
    for x in range(0, 1920, int(grid_spacing)):
        draw_line(Vector2(x, 0), Vector2(x, 1080), line_color, 1.0)
    for y in range(0, 1080, int(grid_spacing)):
        draw_line(Vector2(0, y), Vector2(1920, y), line_color, 1.0)

func spawn_particle_burst(position: Vector2, color: Color, count: int = 15):
    for j in range(count):
        var angle = randf() * PI * 2.0
        var speed = randf_range(50.0, 250.0)
        active_particles.append({
            "pos": position,
            "vel": Vector2(cos(angle), sin(angle)) * speed,
            "color": color,
            "life": 0.4,
            "max_life": 0.4
        })

func _process_particles(delta):
    for j in range(active_particles.size() - 1, -1, -1):
        var p = active_particles[j]
        p.pos += p.vel * delta
        p.life -= delta
        if p.life <= 0.0:
            active_particles.remove_at(j)

func _draw_background_layer():
    if not show_reference:
        return
    var tex: Texture2D = null
    if background_view == "photo":
        tex = photo_texture
    elif background_view == "semantic":
        tex = semantic_texture
    elif background_view == "secondary":
        if photo_texture:
            draw_texture_rect(photo_texture, Rect2(offset_x, offset_y, map_w * scale_factor, map_h * scale_factor), false, Color(1, 1, 1, secondary_photo_mix))
        tex = secondary_texture
        if tex == null:
            tex = semantic_texture
    elif background_view == "collision":
        if photo_texture:
            draw_texture_rect(photo_texture, Rect2(offset_x, offset_y, map_w * scale_factor, map_h * scale_factor), false, Color(1, 1, 1, secondary_photo_mix))
        tex = collision_preview_texture
        
    if tex:
        draw_texture_rect(tex, Rect2(offset_x, offset_y, map_w * scale_factor, map_h * scale_factor), false, Color(1, 1, 1, reference_opacity))

func _draw():
    _draw_background_layer()
    
    if show_debug_grid:
        # Draw Background Grid
        draw_background_grid()
        
    # Draw Grid Blocks
    for x in range(grid_width):
        for y in range(grid_height):
            if grid[x][y] != null:
                var rect = Rect2(x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE-2, BLOCK_SIZE-2)
                draw_glow_rect(rect, grid[x][y])
                
    # Draw Active Pieces for all players
    for p in range(num_players):
        if p >= active_pieces.size(): continue
        var piece = active_pieces[p]
        if piece == null or piece.is_empty(): continue
        if piece.get("is_simulating", false):
            draw_set_transform(piece.sim_pos, piece.sim_rot, Vector2.ONE)
            for b in piece.blocks:
                var rect = Rect2(b * BLOCK_SIZE, Vector2(BLOCK_SIZE-2, BLOCK_SIZE-2))
                draw_glow_rect(rect, piece.color)
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        else:
            for b in piece.blocks:
                var nx = piece.pos.x + b.x
                var ny = piece.pos.y + b.y
                var rect = Rect2(nx * BLOCK_SIZE, ny * BLOCK_SIZE, BLOCK_SIZE-2, BLOCK_SIZE-2)
                draw_glow_rect(rect, piece.color)
        
    # Draw Container Bounds
    if settings.get("show_outline", true) and well_polygon.size() > 2:
        var packed = PackedVector2Array(well_polygon)
        packed.append(well_polygon[0])
        if current_skin == "classic":
            # Flat classic border
            draw_polyline(packed, Color.DARK_GRAY, 3.0)
        else:
            # Thin white well with subtle cyan glow
            draw_polyline(packed, Color(0.0, 0.9, 1.0, 0.15), 6.0)
            draw_polyline(packed, Color.WHITE, 1.0)
        
    # Draw particles
    for p in active_particles:
        var alpha = p.life / p.max_life
        var col = Color(p.color.r, p.color.g, p.color.b, alpha)
        draw_circle(p.pos, 3.5 * alpha, col)
        
    # Draw Scores for all active players
    for p in range(num_players):
        if p >= scores.size(): continue
        var col = Color.CYAN if p == 0 else (Color.YELLOW if p == 1 else (Color.PURPLE if p == 2 else Color.GREEN))
        draw_string(ThemeDB.fallback_font, Vector2(20, 40 + p * 40), "P%d SCORE: %d" % [p + 1, scores[p]], HORIZONTAL_ALIGNMENT_LEFT, -1, 32, col)

func _repo_root() -> String:
    var d = ProjectSettings.globalize_path("res://").replace("\\","/").simplify_path()
    for _i in range(10):
        if DirAccess.dir_exists_absolute(d.path_join("app/shared")): return d
        var p = d.get_base_dir()
        if p == d or p == "": break
        d = p
    return ""
