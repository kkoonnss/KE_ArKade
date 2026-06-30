extends Node2D
const SharedLoader = preload("res://../../../app/shared/shared_loader.gd")

const LevelAdjustments = preload("res://level_adjustments.gd")

var tab_menu
var splash_rect: TextureRect
var splash_timer: float = 2.0

var ipc_socket: StreamPeerTCP = null
var scene_dir: String = ""
var level_dir: String = ""
var ipc_port: int = 0
var ipc_host: String = "127.0.0.1"
var screenshot_path: String = ""

var heartbeat_timer: float = 0.0
var read_buffer: String = ""

# Track data
var graph_nodes = []
var graph_edges = []
var track_points = []
var checkpoints = [] # List of Vector2 positions in order
var boundary_polygon: PackedVector2Array = []
var max_laps = 3

class Player:
    var id: int = 0
    var active: bool = false
    var color: Color
    var pos: Vector2 = Vector2.ZERO
    var vel: Vector2 = Vector2.ZERO
    var angle: float = 0.0
    var speed: float = 0.0
    var trail: Array = []
    var active_checkpoint_idx: int = 0
    var lap: int = 1
    var race_time: float = 0.0
    var race_finished: bool = false

var players: Array = []

# Car physics
const ACCEL = 300.0
const DECELL = 150.0
const STEER_SPEED = 4.0

# UI & Settings
var ui_layer: CanvasLayer
var settings_panel: PanelContainer
var top_speed_slider: HSlider
var friction_slider: HSlider

# Procedural settings
var param_top_speed: float = 400.0
var param_track_friction: float = 2.0
var checkpoint_spacing: int = 6
var wall_forgiveness: float = 1.0
var bounds_clamp: bool = true
var track_width: float = 120.0

# Visuals
const MAX_TRAIL = 40
var active_particles = []
var prev_keys = {}

# Reference Background
var background_texture: Texture2D = null
var background_opacity: float = 0.15
var show_background: bool = true

# Visual Skin
var current_skin: String = "neon" # the brief demands "skinned to the design system"

func _ready():
    # Initialize 4 players
    for i in range(4):
        var p = Player.new()
        p.id = i
        p.color = [Color(0.0, 0.9, 1.0), Color(1.0, 0.0, 0.5), Color(0.5, 1.0, 0.0), Color(1.0, 0.8, 0.0)][i]
        players.append(p)
    players[0].active = true # P1 always active
    
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
    
    send_ipc_message({"type": "ready"})
    setup_ui()
    _apply_settings_from_menu()
    load_level()
    load_background()
    if screenshot_path != "":
        for _i in range(8):
            await get_tree().process_frame
        var err = get_viewport().get_texture().get_image().save_png(screenshot_path)
        print("On Track screenshot saved: ", screenshot_path, " err=", err)
        get_tree().quit()


func setup_ui():
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    
    var theme = Theme.new()
    var bg_style = StyleBoxFlat.new()
    bg_style.bg_color = Color(0, 0, 0, 0.85)
    bg_style.border_width_left = 2
    bg_style.border_width_top = 2
    bg_style.border_width_right = 2
    bg_style.border_width_bottom = 2
    bg_style.border_color = Color(0.0, 1.0, 0.8)
    theme.set_stylebox("panel", "PanelContainer", bg_style)
    
    settings_panel = PanelContainer.new()
    settings_panel.theme = theme
    settings_panel.visible = false
    settings_panel.position = Vector2(1920/2.0 - 200, 1080/2.0 - 150)
    settings_panel.size = Vector2(400, 300)
    ui_layer.add_child(settings_panel)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    settings_panel.add_child(margin)
    
    var vbox = VBoxContainer.new()
    margin.add_child(vbox)
    
    var title = Label.new()
    title.text = "SETTINGS (Tab/Start to close)"
    title.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))
    vbox.add_child(title)
    
    var spacer = Control.new()
    spacer.custom_minimum_size = Vector2(0, 20)
    vbox.add_child(spacer)
    
    var speed_lbl = Label.new()
    speed_lbl.text = "Top Speed"
    speed_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
    vbox.add_child(speed_lbl)
    
    top_speed_slider = HSlider.new()
    top_speed_slider.min_value = 200.0
    top_speed_slider.max_value = 1500.0
    top_speed_slider.value = param_top_speed
    top_speed_slider.value_changed.connect(func(v):
        param_top_speed = v
        save_settings()
    )
    vbox.add_child(top_speed_slider)
    
    var spacer2 = Control.new()
    spacer2.custom_minimum_size = Vector2(0, 20)
    vbox.add_child(spacer2)
    
    var fric_lbl = Label.new()
    fric_lbl.text = "Track Friction (Driftiness)"
    fric_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
    vbox.add_child(fric_lbl)
    
    friction_slider = HSlider.new()
    friction_slider.min_value = 0.5
    friction_slider.max_value = 10.0
    friction_slider.step = 0.1
    friction_slider.value = param_track_friction
    friction_slider.value_changed.connect(func(v):
        param_track_friction = v
        save_settings()
    )
    vbox.add_child(friction_slider)
    settings_panel.visible = false

    var menu_script = load(_shared_script_path("controls/tab_menu.gd"))
    if not menu_script:
        return
    tab_menu = menu_script.new()
    add_child(tab_menu)
    tab_menu.register_knob_float("track_friction", "Track Friction", param_track_friction, 0.5, 10.0, 0.1)
    tab_menu.register_knob_float("top_speed", "Top Speed", param_top_speed, 200.0, 1500.0, 25.0)
    tab_menu.register_knob_int("checkpoint_spacing", "Checkpoint Spacing", checkpoint_spacing, 2, 12, 1)
    tab_menu.register_knob_float("wall_forgiveness", "Wall Forgiveness", wall_forgiveness, 0.4, 2.5, 0.1)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", bounds_clamp)
    tab_menu.register_knob_bool("reference", "Reference Overlay", show_background)
    tab_menu.register_knob_float("reference_opacity", "Reference Opacity", background_opacity, 0.0, 1.0, 0.05)
    tab_menu.connect("knob_changed", Callable(self, "_on_tab_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_tab_action"))
    tab_menu.setup("on_track", level_dir, "ON TRACK")

func _apply_settings_from_menu():
    if tab_menu == null:
        return
    param_track_friction = float(tab_menu.get_knob_value("track_friction"))
    param_top_speed = float(tab_menu.get_knob_value("top_speed"))
    checkpoint_spacing = int(tab_menu.get_knob_value("checkpoint_spacing"))
    wall_forgiveness = float(tab_menu.get_knob_value("wall_forgiveness"))
    bounds_clamp = bool(tab_menu.get_knob_value("bounds_clamp"))
    show_background = bool(tab_menu.get_knob_value("reference"))
    background_opacity = float(tab_menu.get_knob_value("reference_opacity"))
    if top_speed_slider:
        top_speed_slider.value = param_top_speed
    if friction_slider:
        friction_slider.value = param_track_friction

func _on_tab_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["checkpoint_spacing", "wall_forgiveness", "bounds_clamp"]:
        load_level()
    save_settings()
    queue_redraw()

func _on_tab_action(action_id: String):
    if action_id == "start":
        for p in players:
            p.race_finished = false

func load_settings():
    if level_dir == "": return
    var data = LevelAdjustments.load_level_settings("on_track", level_dir, {
        "top_speed": param_top_speed,
        "track_friction": param_track_friction,
        "checkpoint_spacing": checkpoint_spacing,
        "wall_forgiveness": wall_forgiveness,
        "bounds_clamp": bounds_clamp
    }, scene_dir)
    if data.has("top_speed"):
        param_top_speed = float(data["top_speed"])
    if data.has("track_friction"):
        param_track_friction = float(data["track_friction"])
    if data.has("checkpoint_spacing"):
        checkpoint_spacing = int(data["checkpoint_spacing"])
    if data.has("wall_forgiveness"):
        wall_forgiveness = float(data["wall_forgiveness"])
    if data.has("bounds_clamp"):
        bounds_clamp = bool(data["bounds_clamp"])
    _apply_settings_from_menu()
    if top_speed_slider:
        top_speed_slider.value = param_top_speed
    if friction_slider:
        friction_slider.value = param_track_friction

func save_settings():
    if level_dir == "": return
    var data = {
        "top_speed": param_top_speed,
        "track_friction": param_track_friction,
        "checkpoint_spacing": checkpoint_spacing,
        "wall_forgiveness": wall_forgiveness,
        "bounds_clamp": bounds_clamp
    }
    LevelAdjustments.save_level_settings("on_track", level_dir, data, scene_dir)

func load_container():
    boundary_polygon.clear()
    if level_dir == "": return
    var path = level_dir.path_join("derived").path_join("container.json")
    if FileAccess.file_exists(path):
        var file = FileAccess.open(path, FileAccess.READ)
        if file:
            var content = file.get_as_text()
            var json = JSON.new()
            if json.parse(content) == OK:
                var data = json.data
                if typeof(data) == TYPE_DICTIONARY and data.has("well_polygon"):
                    for p in data["well_polygon"]:
                        boundary_polygon.append(Vector2(float(p.get("x", 0)), float(p.get("y", 0))))

func _input(event):
    if tab_menu and tab_menu.overlay_mode != "":
        return
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
        if tab_menu:
            return
        if settings_panel:
            settings_panel.visible = not settings_panel.visible
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_TAB:
            if tab_menu:
                return
            if settings_panel:
                settings_panel.visible = not settings_panel.visible
        elif event.keycode == KEY_F1:
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
            current_skin = "neon" if current_skin == "classic" else "classic"
            queue_redraw()

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

func _shared_script_path(relative_path: String) -> String:
    var root = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir().get_base_dir().get_base_dir()
    return root.path_join("app").path_join("shared").path_join(relative_path)

func _load_shared_adapter(relative_path: String):
    var file = FileAccess.open(_shared_script_path(relative_path), FileAccess.READ)
    if file == null:
        return null
    var lines = []
    for line in file.get_as_text().split("\n"):
        var stripped = line.strip_edges()
        if stripped.begins_with("class_name "):
            continue
        if stripped == "extends AdapterBase":
            lines.append("extends \"res://adapter_base.gd\"")
        else:
            lines.append(line)
    var script = GDScript.new()
    script.source_code = "\n".join(lines)
    if script.reload() != OK:
        return null
    return script


func _process(delta):
    if splash_rect and splash_timer > 0:
        splash_timer -= delta
        if splash_timer <= 0:
            splash_rect.visible = false
            splash_rect.queue_free()
            splash_rect = null
        elif splash_timer < 1.0:
            splash_rect.modulate.a = splash_timer
    _process_ipc(delta)
    if tab_menu and tab_menu.overlay_mode != "":
        queue_redraw()
        return
    if visible:
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
                load_background()

func load_level():
    if level_dir == "": return
    
    track_points.clear()
    checkpoints.clear()
    load_container()
    load_settings()

    var adapter_script = _load_shared_adapter("adapters/track.gd")
    if not adapter_script:
        return
    var adapter = adapter_script.new()
    var layout = adapter.interpret(level_dir, {}, {
        "track_friction": param_track_friction,
        "top_speed": param_top_speed,
        "checkpoint_spacing": checkpoint_spacing,
        "wall_forgiveness": wall_forgiveness,
        "bounds_clamp": bounds_clamp
    })
    track_width = float(layout.get("track_width", 120.0)) * wall_forgiveness
    for p in layout.get("centerline_points", []):
        if p is Vector2:
            track_points.append(p)
    var adapter_checkpoints = layout.get("checkpoints", [])
    for p in adapter_checkpoints:
        if p is Vector2:
            checkpoints.append(p)
    if checkpoints.size() < 2 and track_points.size() >= 2:
        checkpoints.clear()
        var spacing = maxi(2, checkpoint_spacing)
        for idx in range(0, track_points.size(), spacing):
            checkpoints.append(track_points[idx])
        if checkpoints.size() < 2:
            checkpoints.append(track_points[int(track_points.size() / 2)])
    if track_points.size() < 2 and checkpoints.size() >= 2:
        track_points = checkpoints.duplicate()

    if checkpoints.size() > 0:
        var start_pos = checkpoints[0]
        var start_angle = 0.0
        if checkpoints.size() > 1:
            start_angle = (checkpoints[1] - checkpoints[0]).angle()
            
        for i in range(players.size()):
            var offset = Vector2(cos(start_angle + PI/2), sin(start_angle + PI/2)) * (i * 20.0 - 30.0)
            players[i].pos = start_pos + offset
            players[i].angle = start_angle
            players[i].vel = Vector2.ZERO
            players[i].speed = 0.0
            players[i].active_checkpoint_idx = 0
            players[i].lap = 1
            players[i].race_time = 0.0
            players[i].race_finished = false

func _get_node(id: String):
    for n in graph_nodes:
        if str(n.get("id", "")) == id:
            return n
    return null

func get_player_input(player_idx: int) -> Dictionary:
    var steer = 0.0
    var accel = 0.0
    var a_pressed = false
    
    if player_idx == 0:
        # Keyboard + Joypad 0
        if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.get_joy_axis(SharedLoader.get_joy_id(0), JOY_AXIS_LEFT_X) < -0.2:
            steer = -1.0
        elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.get_joy_axis(SharedLoader.get_joy_id(0), JOY_AXIS_LEFT_X) > 0.2:
            steer = 1.0
            
        if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_A):
            accel = 1.0
            a_pressed = true
        elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_B):
            accel = -0.5
    else:
        # Joypads 1, 2, 3
        var joy_id = player_idx
        if Input.get_joy_axis(SharedLoader.get_joy_id(joy_id), JOY_AXIS_LEFT_X) < -0.2:
            steer = -1.0
        elif Input.get_joy_axis(SharedLoader.get_joy_id(joy_id), JOY_AXIS_LEFT_X) > 0.2:
            steer = 1.0
            
        if Input.is_joy_button_pressed(SharedLoader.get_joy_id(joy_id), JOY_BUTTON_A):
            accel = 1.0
            a_pressed = true
        elif Input.is_joy_button_pressed(SharedLoader.get_joy_id(joy_id), JOY_BUTTON_B):
            accel = -0.5
            
    return {"steer": steer, "accel": accel, "a_pressed": a_pressed}

func _process_game(delta):
    for i in range(players.size()):
        var p = players[i]
        if p.race_finished:
            continue
            
        var input_state = get_player_input(i)
        
        # Drop-in multiplayer
        if not p.active and input_state.a_pressed:
            p.active = true
            
        if not p.active:
            continue
            
        p.race_time += delta
        p.angle += input_state.steer * STEER_SPEED * delta
        
        if input_state.accel > 0:
            p.speed = move_toward(p.speed, param_top_speed, ACCEL * delta)
        elif input_state.accel < 0:
            p.speed = move_toward(p.speed, -param_top_speed * 0.4, DECELL * delta)
        else:
            p.speed = move_toward(p.speed, 0, DECELL * 0.5 * delta)
            
        var forward = Vector2(cos(p.angle), sin(p.angle))
        var target_vel = forward * p.speed
        p.vel = p.vel.lerp(target_vel, param_track_friction * delta)
        
        if p.vel.length() > param_top_speed:
            p.vel = p.vel.normalized() * param_top_speed
            
        var prev_pos = p.pos
        p.pos += p.vel * delta
        
        if bounds_clamp and boundary_polygon.size() > 2:
            if not Geometry2D.is_point_in_polygon(p.pos, boundary_polygon):
                p.pos = prev_pos
                p.vel = -p.vel * 0.5
                p.speed *= 0.5
        if _distance_to_track(p.pos) > track_width * 0.5:
            p.pos = prev_pos
            p.vel = p.vel * 0.45
            p.speed *= 0.55
        
        p.trail.append(p.pos)
        if p.trail.size() > MAX_TRAIL:
            p.trail.remove_at(0)
            
        if checkpoints.size() > 0:
            var target_pos = checkpoints[p.active_checkpoint_idx]
            if p.pos.distance_to(target_pos) < 60.0:
                spawn_particle_burst(target_pos, p.color, 12)
                p.active_checkpoint_idx += 1
                if p.active_checkpoint_idx >= checkpoints.size():
                    p.active_checkpoint_idx = 0
                    p.lap += 1
                    send_ipc_message({"type": "score", "data": {"player": i, "lap": p.lap, "time": p.race_time}})
                    if p.lap > max_laps:
                        p.race_finished = true
                        send_ipc_message({"type": "finished", "player": i, "time": p.race_time})

func draw_glow_line(from: Vector2, to: Vector2, color: Color, width: float):
    draw_line(from, to, Color(color.r, color.g, color.b, 0.12), width * 4.0)
    draw_line(from, to, Color(color.r, color.g, color.b, 0.35), width * 2.0)
    draw_line(from, to, Color.WHITE, width * 0.7)

func draw_glow_circle(center: Vector2, radius: float, color: Color):
    draw_circle(center, radius * 2.0, Color(color.r, color.g, color.b, 0.12))
    draw_circle(center, radius * 1.4, Color(color.r, color.g, color.b, 0.35))
    draw_circle(center, radius, Color.WHITE)

func draw_background_grid():
    var grid_spacing = 80.0
    var line_color = Color(0.08, 0.08, 0.12, 0.4)
    for x in range(0, 1920, int(grid_spacing)):
        draw_line(Vector2(x, 0), Vector2(x, 1080), line_color, 1.0)
    for y in range(0, 1080, int(grid_spacing)):
        draw_line(Vector2(0, y), Vector2(1920, y), line_color, 1.0)

func _distance_to_track(pos: Vector2) -> float:
    if track_points.size() < 2:
        return 0.0
    var best = INF
    for idx in range(track_points.size()):
        var a = track_points[idx]
        var b = track_points[(idx + 1) % track_points.size()]
        var ab = b - a
        var t = 0.0
        if ab.length_squared() > 0.001:
            t = clamp((pos - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
        best = min(best, pos.distance_to(a + ab * t))
    return best

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

func _draw():
    # Pure black base background
    draw_rect(Rect2(0, 0, 1920, 1080), Color.BLACK)
    
    if show_background and background_texture:
        draw_texture_rect(background_texture, Rect2(0, 0, 1920, 1080), false, Color(1, 1, 1, background_opacity))
    draw_background_grid()
    
    if current_skin == "neon":
        # Draw Track Outline
        if track_points.size() > 0:
            for idx in range(track_points.size() - 1):
                var segment_a = track_points[idx]
                var segment_b = track_points[idx + 1]
                var segment_normal = (segment_b - segment_a).normalized().orthogonal() * 26.0
                draw_line(segment_a + segment_normal, segment_b + segment_normal, Color(0.0, 0.5, 1.0, 0.35), 5.0)
                draw_line(segment_a - segment_normal, segment_b - segment_normal, Color(0.0, 0.5, 1.0, 0.35), 5.0)
                draw_line(segment_a, segment_b, Color(0.12, 0.15, 0.22, 0.2), 18.0)
            # connect back to start
            var close_a = track_points[track_points.size() - 1]
            var close_b = track_points[0]
            var close_normal = (close_b - close_a).normalized().orthogonal() * 26.0
            draw_line(close_a + close_normal, close_b + close_normal, Color(0.0, 0.5, 1.0, 0.35), 5.0)
            draw_line(close_a - close_normal, close_b - close_normal, Color(0.0, 0.5, 1.0, 0.35), 5.0)
            draw_line(close_a, close_b, Color(0.12, 0.15, 0.22, 0.2), 18.0)
                
        # Draw Checkpoints
        for idx in range(checkpoints.size()):
            var is_active = false
            for p in players:
                if p.active and p.active_checkpoint_idx == idx:
                    is_active = true
            
            var color = Color(0.0, 0.9, 1.0) if is_active else Color(1.0, 0.0, 1.0, 0.3)
            var size = 15.0 if is_active else 8.0
            draw_glow_circle(checkpoints[idx], size, color)
            
        # Draw Players
        for p in players:
            if not p.active: continue
            
            # Trail
            if p.trail.size() > 1:
                for idx in range(p.trail.size() - 1):
                    var alpha = float(idx) / p.trail.size()
                    draw_line(p.trail[idx], p.trail[idx+1], Color(p.color.r, p.color.g, p.color.b, alpha * 0.45), 6.0 * alpha)
                    
            # Player Car (Glowing Neon Vector Triangle)
            var points = PackedVector2Array([
                p.pos + Vector2(cos(p.angle), sin(p.angle)) * 20.0,
                p.pos + Vector2(cos(p.angle + PI * 0.8), sin(p.angle + PI * 0.8)) * 12.0,
                p.pos + Vector2(cos(p.angle - PI * 0.8), sin(p.angle - PI * 0.8)) * 12.0,
            ])
            draw_colored_polygon(points, Color(p.color.r, p.color.g, p.color.b, 0.85))
            var glow_points = PackedVector2Array(points)
            glow_points.append(points[0])
            draw_polyline(glow_points, Color.WHITE, 1.5)
            
    else: # CLASSIC RETRO SKIN
        # Draw flat track
        if track_points.size() > 0:
            for idx in range(track_points.size() - 1):
                var classic_a = track_points[idx]
                var classic_b = track_points[idx + 1]
                var classic_normal = (classic_b - classic_a).normalized().orthogonal() * 24.0
                draw_line(classic_a + classic_normal, classic_b + classic_normal, Color.LIGHT_GRAY, 3.0)
                draw_line(classic_a - classic_normal, classic_b - classic_normal, Color.LIGHT_GRAY, 3.0)
                draw_line(classic_a, classic_b, Color(0.18, 0.18, 0.18, 0.45), 16.0)
            var classic_close_a = track_points[track_points.size() - 1]
            var classic_close_b = track_points[0]
            var classic_close_normal = (classic_close_b - classic_close_a).normalized().orthogonal() * 24.0
            draw_line(classic_close_a + classic_close_normal, classic_close_b + classic_close_normal, Color.LIGHT_GRAY, 3.0)
            draw_line(classic_close_a - classic_close_normal, classic_close_b - classic_close_normal, Color.LIGHT_GRAY, 3.0)
            draw_line(classic_close_a, classic_close_b, Color(0.18, 0.18, 0.18, 0.45), 16.0)
                
        # Draw Checkpoints as simple white/grey blocks
        for idx in range(checkpoints.size()):
            var is_active = false
            for p in players:
                if p.active and p.active_checkpoint_idx == idx:
                    is_active = true
                    
            var color = Color.WHITE if is_active else Color(0.4, 0.4, 0.4)
            var size = 12.0 if is_active else 6.0
            draw_rect(Rect2(checkpoints[idx] - Vector2(size/2.0, size/2.0), Vector2(size, size)), color)
            
        # Draw Player Car
        for p in players:
            if not p.active: continue
            var points = PackedVector2Array([
                p.pos + Vector2(cos(p.angle), sin(p.angle)) * 16.0,
                p.pos + Vector2(cos(p.angle + PI * 0.8), sin(p.angle + PI * 0.8)) * 10.0,
                p.pos + Vector2(cos(p.angle - PI * 0.8), sin(p.angle - PI * 0.8)) * 10.0,
            ])
            draw_colored_polygon(points, p.color)
            var outline_points = PackedVector2Array(points)
            outline_points.append(points[0])
            draw_polyline(outline_points, Color.BLACK, 1.5)
    
    # Draw particles
    for p in active_particles:
        var alpha = p.life / p.max_life
        var col = Color(p.color.r, p.color.g, p.color.b, alpha)
        draw_circle(p.pos, 3.5 * alpha, col)
        
    # Draw HUD
    var y_offset = 40
    for i in range(players.size()):
        var p = players[i]
        if not p.active: continue
        
        var hud_text = "P%d LAP: %d/%d" % [i+1, clamp(p.lap, 1, max_laps), max_laps]
        if p.race_finished:
            hud_text = "P%d FINISHED! (%.2fs)" % [i+1, p.race_time]
        else:
            hud_text += "  TIME: %.2fs" % p.race_time
            
        draw_string(ThemeDB.fallback_font, Vector2(20, y_offset), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, p.color)
        y_offset += 40
