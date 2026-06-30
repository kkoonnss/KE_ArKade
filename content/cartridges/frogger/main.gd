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

var traffic_density: float = 1.0
var hazard_speed_mult: float = 1.0
var grid_scale: float = 1.0
var invert_lanes: bool = false
var bounds_clamp: bool = true
var play_bounds := Rect2(0, 0, 1920, 1080)
var stage: int = 1
var difficulty_multiplier: float = 1.0
var show_ui: bool = false
var ui_layer: CanvasLayer = null
var log_panel: Panel = null
var log_label: RichTextLabel = null
var log_lines: Array = []
const LOG_MAX_LINES := 8

# Game State
var graph_nodes = []
var graph_edges = []
var spawn_nodes = []
var goal_nodes = []
var hazards = []
var grid_cells = []
var grid_width: int = 0
var grid_height: int = 0
var grid_cell_size: float = 32.0

var player_pos = Vector2.ZERO
var player_start_pos = Vector2.ZERO
var player_speed = 220.0
var player_radius = 16.0

var score = 0
var lives = 3
var game_over = false
var active_particles = []

# Reference Background
var background_texture: Texture2D = null
var background_opacity: float = 0.15
var show_background: bool = false

# Visual Skin
var current_skin: String = "classic" # "classic" or "neon"

func _ready():
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
            if skin_arg == "Classic Frogger":
                current_skin = "classic"
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
    
    RenderingServer.set_default_clear_color(Color.BLACK)
    send_ipc_message({"type": "ready"})
    setup_ui()
    load_level()
    load_background()
    if screenshot_path != "":
        for _i in range(8):
            await get_tree().process_frame
        var err = get_viewport().get_texture().get_image().save_png(screenshot_path)
        print("Frogger screenshot saved: ", screenshot_path, " err=", err)
        get_tree().quit()

func _input(event):
    if tab_menu and tab_menu.overlay_mode != "":
        return
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_TAB:
            if tab_menu:
                return
            show_ui = !show_ui
            if ui_layer:
                ui_layer.visible = show_ui
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
            if current_skin == "classic":
                current_skin = "neon"
            else:
                current_skin = "classic"
            queue_redraw()

func load_background():
    if level_dir == "": return
    
    var occ_path = level_dir.path_join("derived/occupancy.png")
    if FileAccess.file_exists(occ_path):
        var img = Image.load_from_file(occ_path)
        if img:
            background_texture = ImageTexture.create_from_image(img)
            background_opacity = 0.25
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

func load_level():
    if level_dir == "": return
    graph_nodes.clear()
    graph_edges.clear()
    spawn_nodes.clear()
    goal_nodes.clear()
    hazards.clear()
    grid_cells.clear()
    grid_width = 0
    grid_height = 0
    
    var settings = LevelAdjustments.load_level_settings("frogger", level_dir, {
        "traffic_density": traffic_density,
        "hazard_speed_mult": hazard_speed_mult,
        "grid_scale": grid_scale,
        "invert": invert_lanes,
        "bounds_clamp": bounds_clamp
    }, scene_dir)
    if settings.has("traffic_density"):
        traffic_density = float(settings["traffic_density"])
    if settings.has("hazard_speed_mult"):
        hazard_speed_mult = float(settings["hazard_speed_mult"])
    if settings.has("grid_scale"):
        grid_scale = float(settings["grid_scale"])
    if settings.has("invert"):
        invert_lanes = bool(settings["invert"])
    if settings.has("bounds_clamp"):
        bounds_clamp = bool(settings["bounds_clamp"])
    _apply_settings_from_menu()
    stage = 1
    difficulty_multiplier = 1.0
    
    var grid_path = level_dir + "/derived/grid.json"
    if FileAccess.file_exists(grid_path):
        var g_file = FileAccess.open(grid_path, FileAccess.READ)
        if g_file:
            var p_json = JSON.new()
            if p_json.parse(g_file.get_as_text()) == OK and typeof(p_json.data) == TYPE_DICTIONARY:
                grid_cell_size = float(p_json.data.get("cell_px", 32.0))
                grid_cells = p_json.data.get("cells", [])
                grid_height = grid_cells.size()
                if grid_height > 0 and typeof(grid_cells[0]) == TYPE_ARRAY:
                    grid_width = grid_cells[0].size()
    
    _derive_playfield_from_lane_adapter()
    _log_msg("Derived lane playfield from shared adapter")

func generate_hazards():
    hazards.clear()
    var lane_dirs := {}
    var effective_density = traffic_density * difficulty_multiplier
    var effective_speed = hazard_speed_mult * difficulty_multiplier
    for edge in graph_edges:
        var n1 = _get_node(str(edge.get("source", "")))
        var n2 = _get_node(str(edge.get("target", "")))
        if n1 and n2:
            var p1 = Vector2(n1.get("x", 0), n1.get("y", 0))
            var p2 = Vector2(n2.get("x", 0), n2.get("y", 0))
            var dist = p1.distance_to(p2)
            var lane_key = int(round(p1.y / max(1.0, grid_cell_size)))
            if not lane_dirs.has(lane_key):
                lane_dirs[lane_key] = 1.0 if lane_key % 2 == 0 else -1.0
            
            var num_hazards = floor((dist / 150.0) * effective_density)
            if num_hazards < 1 and dist > 100.0 and randf() < effective_density:
                num_hazards = 1
                
            for i in range(num_hazards):
                hazards.append({
                    "start_pos": p1,
                    "end_pos": p2,
                    "pos": p1,
                    "progress": randf(),
                    "dir": float(lane_dirs[lane_key]),
                    "base_speed": randf_range(80.0, 160.0) * effective_speed,
                    "color": Color(1.0, 0.0, 0.8) # Neon Magenta
                })

func _derive_playfield_from_grid():
    if grid_cells.is_empty():
        return
    var open_rows = []
    for gy in range(grid_height):
        var row = grid_cells[gy]
        var open_xs = []
        for gx in range(min(grid_width, row.size())):
            if int(row[gx]) != 1:
                open_xs.append(gx)
        if open_xs.size() >= 4:
            open_rows.append({"y": gy, "cells": open_xs})
    if open_rows.is_empty():
        return
    var top_lane = open_rows[0]
    var bottom_lane = open_rows[open_rows.size() - 1]
    var spawn_x = int(bottom_lane["cells"][bottom_lane["cells"].size() / 2])
    var spawn_pos = Vector2((float(spawn_x) + 0.5) * grid_cell_size, (float(top_lane["y"]) + 0.5) * 0.0)
    spawn_pos = Vector2((float(spawn_x) + 0.5) * grid_cell_size, (float(bottom_lane["y"]) + 0.5) * grid_cell_size)
    spawn_nodes.append({"id": "spawn_0", "x": spawn_pos.x, "y": spawn_pos.y, "type": "spawn", "tags": ["spawn"]})
    player_start_pos = spawn_pos
    player_pos = spawn_pos

    var goal_fractions = [0.12, 0.32, 0.5, 0.68, 0.88]
    for i in range(goal_fractions.size()):
        var desired_x = int(round(goal_fractions[i] * float(grid_width - 1)))
        var best_x = int(top_lane["cells"][0])
        var best_dist = 999999
        for cell_x in top_lane["cells"]:
            var dist = abs(int(cell_x) - desired_x)
            if dist < best_dist:
                best_dist = dist
                best_x = int(cell_x)
        var goal_pos = Vector2((float(best_x) + 0.5) * grid_cell_size, (float(top_lane["y"]) + 0.5) * grid_cell_size)
        goal_nodes.append({"id": "goal_%d" % i, "x": goal_pos.x, "y": goal_pos.y, "type": "goal", "tags": ["goal"]})

    graph_nodes = []
    graph_edges = []
    var prev_node_id = ""
    for lane_idx in range(open_rows.size()):
        var lane = open_rows[lane_idx]
        var min_x = int(lane["cells"][0])
        var max_x = int(lane["cells"][lane["cells"].size() - 1])
        var left_id = "lane_%d_l" % lane_idx
        var right_id = "lane_%d_r" % lane_idx
        var y = (float(lane["y"]) + 0.5) * grid_cell_size
        graph_nodes.append({"id": left_id, "x": (float(min_x) + 0.5) * grid_cell_size, "y": y})
        graph_nodes.append({"id": right_id, "x": (float(max_x) + 0.5) * grid_cell_size, "y": y})
        graph_edges.append({"source": left_id, "target": right_id})
        if prev_node_id != "":
            graph_edges.append({"source": prev_node_id, "target": left_id})
        prev_node_id = right_id

    hazards.clear()
    for lane_idx in range(1, open_rows.size() - 1):
        var lane = open_rows[lane_idx]
        var min_x = int(lane["cells"][0])
        var max_x = int(lane["cells"][lane["cells"].size() - 1])
        var start_pos = Vector2((float(min_x) + 0.5) * grid_cell_size, (float(lane["y"]) + 0.5) * grid_cell_size)
        var end_pos = Vector2((float(max_x) + 0.5) * grid_cell_size, (float(lane["y"]) + 0.5) * grid_cell_size)
        var lane_count = maxi(2, int(round((float(max_x - min_x) / 9.0) * traffic_density * difficulty_multiplier)))
        for i in range(lane_count):
            hazards.append({
                "start_pos": start_pos,
                "end_pos": end_pos,
                "pos": start_pos.lerp(end_pos, float(i) / float(lane_count)),
                "progress": float(i) / float(lane_count),
                "dir": 1.0 if lane_idx % 2 == 0 else -1.0,
                "base_speed": (90.0 + float((lane_idx % 5) * 18)) * hazard_speed_mult * difficulty_multiplier,
                "color": Color(1.0, 0.45, 0.0) if lane_idx % 2 == 0 else Color(1.0, 0.0, 0.8)
            })

func _derive_playfield_from_lane_adapter():
    var adapter_script = _load_shared_adapter("adapters/lane.gd")
    if not adapter_script:
        _derive_playfield_from_grid()
        return
    var adapter = adapter_script.new()
    var layout = adapter.interpret(level_dir, {}, {
        "grid_scale": grid_scale,
        "density": traffic_density,
        "invert": invert_lanes,
        "bounds_clamp": bounds_clamp
    })
    play_bounds = layout.get("bounds", Rect2(0, 0, 1920, 1080))
    grid_cell_size = max(16.0, float(layout.get("lane_height", grid_cell_size)) * grid_scale)
    var lanes = layout.get("lanes", [])
    if lanes.is_empty():
        _derive_playfield_from_grid()
        return

    graph_nodes.clear()
    graph_edges.clear()
    spawn_nodes.clear()
    goal_nodes.clear()
    hazards.clear()

    var top_y = float(lanes[0].get("y", play_bounds.position.y + grid_cell_size * 0.5))
    var bottom_y = float(lanes[lanes.size() - 1].get("y", play_bounds.position.y + play_bounds.size.y - grid_cell_size * 0.5))
    var left_x = play_bounds.position.x + grid_cell_size
    var right_x = play_bounds.position.x + play_bounds.size.x - grid_cell_size
    var center_x = play_bounds.position.x + play_bounds.size.x * 0.5

    spawn_nodes.append({"id": "spawn_0", "x": center_x, "y": bottom_y, "type": "spawn", "tags": ["spawn"]})
    player_start_pos = Vector2(center_x, bottom_y)
    player_pos = player_start_pos
    _snap_player_to_grid()

    for i in range(5):
        var x = lerp(left_x, right_x, float(i + 1) / 6.0)
        goal_nodes.append({"id": "goal_%d" % i, "x": x, "y": top_y, "type": "goal", "tags": ["goal"], "filled": false})

    var prev_node_id = ""
    for lane_idx in range(lanes.size()):
        var lane = lanes[lane_idx]
        var y = float(lane.get("y", top_y + lane_idx * grid_cell_size))
        var left_id = "lane_%d_l" % lane_idx
        var right_id = "lane_%d_r" % lane_idx
        graph_nodes.append({"id": left_id, "x": left_x, "y": y, "type": lane.get("type", "safe")})
        graph_nodes.append({"id": right_id, "x": right_x, "y": y, "type": lane.get("type", "safe")})
        graph_edges.append({"source": left_id, "target": right_id})
        if prev_node_id != "":
            graph_edges.append({"source": prev_node_id, "target": left_id})
        prev_node_id = right_id

        var lane_type = str(lane.get("type", "safe"))
        if invert_lanes:
            lane_type = "traffic" if lane_type == "safe" else "safe"
        if lane_idx > 0 and lane_idx < lanes.size() - 1 and lane_type != "safe":
            var lane_count = maxi(1, int(round((play_bounds.size.x / 260.0) * traffic_density * difficulty_multiplier)))
            for h_idx in range(lane_count):
                hazards.append({
                    "start_pos": Vector2(left_x, y),
                    "end_pos": Vector2(right_x, y),
                    "pos": Vector2(left_x, y).lerp(Vector2(right_x, y), float(h_idx) / float(lane_count)),
                    "progress": float(h_idx) / float(lane_count),
                    "dir": 1.0 if lane_idx % 2 == 0 else -1.0,
                    "base_speed": (90.0 + float((lane_idx % 5) * 18)) * hazard_speed_mult * difficulty_multiplier,
                    "color": Color(1.0, 0.45, 0.0) if lane_type == "traffic" else Color(1.0, 0.0, 0.8)
                })

func setup_ui():
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    
    splash_rect = TextureRect.new()
    splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path):
        var img = Image.load_from_file(splash_path)
        if img: splash_rect.texture = ImageTexture.create_from_image(img)
    ui_layer.add_child(splash_rect)
    
    var panel = Panel.new()
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -320
    panel.offset_top = 20
    panel.offset_right = -20
    panel.offset_bottom = 220
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0.8)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0, 1, 1, 1) # Neon cyan
    panel.add_theme_stylebox_override("panel", style)
    ui_layer.add_child(panel)
    
    var margin = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)
    
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    margin.add_child(vbox)
    
    var title = Label.new()
    title.text = "PROCEDURAL SETTINGS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", Color(1, 0, 1, 1))
    vbox.add_child(title)
    
    var density_label = Label.new()
    density_label.text = "Traffic Density"
    density_label.add_theme_color_override("font_color", Color(0, 1, 1, 1))
    vbox.add_child(density_label)
    
    var density_slider = HSlider.new()
    density_slider.min_value = 0.5
    density_slider.max_value = 10.0
    density_slider.step = 0.5
    density_slider.value = traffic_density
    density_slider.value_changed.connect(_on_density_changed)
    vbox.add_child(density_slider)
    
    var speed_label = Label.new()
    speed_label.text = "Hazard Speed"
    speed_label.add_theme_color_override("font_color", Color(0, 1, 1, 1))
    vbox.add_child(speed_label)
    
    var speed_slider = HSlider.new()
    speed_slider.min_value = 0.5
    speed_slider.max_value = 5.0
    speed_slider.step = 0.5
    speed_slider.value = hazard_speed_mult
    speed_slider.value_changed.connect(_on_speed_changed)
    vbox.add_child(speed_slider)

    log_panel = Panel.new()
    log_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    log_panel.anchor_left = 1.0
    log_panel.anchor_right = 1.0
    log_panel.anchor_top = 1.0
    log_panel.anchor_bottom = 1.0
    log_panel.offset_left = -360
    log_panel.offset_top = -260
    log_panel.offset_right = -20
    log_panel.offset_bottom = -20
    var log_style = StyleBoxFlat.new()
    log_style.bg_color = Color(0.02, 0.02, 0.02, 0.84)
    log_style.border_width_left = 2
    log_style.border_width_top = 2
    log_style.border_width_right = 2
    log_style.border_width_bottom = 2
    log_style.border_color = Color(0.4, 1.0, 0.8, 1)
    log_panel.add_theme_stylebox_override("panel", log_style)
    ui_layer.add_child(log_panel)

    var log_margin = MarginContainer.new()
    log_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    log_margin.add_theme_constant_override("margin_left", 10)
    log_margin.add_theme_constant_override("margin_right", 10)
    log_margin.add_theme_constant_override("margin_top", 10)
    log_margin.add_theme_constant_override("margin_bottom", 10)
    log_panel.add_child(log_margin)

    var log_box = VBoxContainer.new()
    log_box.add_theme_constant_override("separation", 6)
    log_margin.add_child(log_box)

    var log_title = Label.new()
    log_title.text = "LOGS"
    log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    log_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.8, 1))
    log_box.add_child(log_title)

    log_label = RichTextLabel.new()
    log_label.fit_content = true
    log_label.scroll_active = true
    log_label.bbcode_enabled = false
    log_label.custom_minimum_size = Vector2(320, 180)
    log_label.add_theme_color_override("default_color", Color(1, 1, 1))
    log_box.add_child(log_label)
    _refresh_log_panel()

    ui_layer.visible = show_ui

    var menu_script = load(_shared_script_path("controls/tab_menu.gd"))
    if not menu_script:
        return
    tab_menu = menu_script.new()
    add_child(tab_menu)
    tab_menu.register_knob_float("grid_scale", "Grid Scale", grid_scale, 0.6, 1.8, 0.05)
    tab_menu.register_knob_float("density", "Traffic Density", traffic_density, 0.4, 3.0, 0.1)
    tab_menu.register_knob_bool("invert", "Invert Lanes", invert_lanes)
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", bounds_clamp)
    tab_menu.register_knob_bool("reference", "Reference Overlay", show_background)
    tab_menu.register_knob_float("reference_opacity", "Reference Opacity", background_opacity, 0.0, 1.0, 0.05)
    tab_menu.connect("knob_changed", Callable(self, "_on_tab_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_tab_action"))
    tab_menu.setup("frogger", level_dir, "FROGGER")
    _apply_settings_from_menu()

func _apply_settings_from_menu():
    if tab_menu == null:
        return
    grid_scale = float(tab_menu.get_knob_value("grid_scale"))
    traffic_density = float(tab_menu.get_knob_value("density"))
    invert_lanes = bool(tab_menu.get_knob_value("invert"))
    bounds_clamp = bool(tab_menu.get_knob_value("bounds_clamp"))
    show_background = bool(tab_menu.get_knob_value("reference"))
    background_opacity = float(tab_menu.get_knob_value("reference_opacity"))

func _on_tab_knob_changed(knob_id: String, value):
    _apply_settings_from_menu()
    if knob_id in ["grid_scale", "density", "invert", "bounds_clamp"]:
        load_level()
    save_settings()
    queue_redraw()

func _on_tab_action(action_id: String):
    if action_id == "start" and game_over:
        lives = 3
        score = 0
        game_over = false
        player_pos = player_start_pos
        _snap_player_to_grid()

func _on_density_changed(value: float):
    traffic_density = value
    generate_hazards()
    save_settings()
    _log_msg("Traffic density set to %.1f" % traffic_density)

func _on_speed_changed(value: float):
    hazard_speed_mult = value
    generate_hazards()
    save_settings()
    _log_msg("Hazard speed set to %.1f" % hazard_speed_mult)

func _log_msg(text: String):
    log_lines.append(text)
    while log_lines.size() > LOG_MAX_LINES:
        log_lines.pop_front()
    _refresh_log_panel()
    print("[Frogger] ", text)

func _refresh_log_panel():
    if not log_label:
        return
    log_label.clear()
    log_label.text = "\n".join(log_lines)

func _reset_goals_for_stage():
    for g in goal_nodes:
        g["filled"] = false

func _advance_stage():
    stage += 1
    difficulty_multiplier = 1.0 + float(stage - 1) * 0.18
    _reset_goals_for_stage()
    generate_hazards()
    player_pos = player_start_pos
    _snap_player_to_grid()
    _log_msg("Stage %d" % stage)
    send_ipc_message({"type": "state", "data": {"state": "stage", "stage": stage}})

func _snap_player_to_grid():
    if grid_cell_size <= 0.0:
        return
    player_pos.x = (floor(player_pos.x / grid_cell_size) + 0.5) * grid_cell_size
    player_pos.y = (floor(player_pos.y / grid_cell_size) + 0.5) * grid_cell_size

func save_settings():
    if level_dir == "": return
    var data = {
        "traffic_density": traffic_density,
        "hazard_speed_mult": hazard_speed_mult,
        "grid_scale": grid_scale,
        "invert": invert_lanes,
        "bounds_clamp": bounds_clamp
    }
    LevelAdjustments.save_level_settings("frogger", level_dir, data, scene_dir)

func _get_node(id: String):
    for n in graph_nodes:
        if str(n.get("id", "")) == id:
            return n
    return null


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

func _process_game(delta):
    if game_over:
        if Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(SharedLoader.get_joy_id(0), JOY_BUTTON_START):
            # Restart
            lives = 3
            score = 0
            game_over = false
            player_pos = player_start_pos
            _snap_player_to_grid()
            send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})
            _log_msg("Restarted run")
        return
        
    # Player Movement (grid step)
    var move_dir = Vector2.ZERO
    if Input.is_action_just_pressed("ui_left"):
        move_dir.x = -1
    elif Input.is_action_just_pressed("ui_right"):
        move_dir.x = 1
    elif Input.is_action_just_pressed("ui_up"):
        move_dir.y = -1
    elif Input.is_action_just_pressed("ui_down"):
        move_dir.y = 1

    if move_dir != Vector2.ZERO:
        player_pos += move_dir * grid_cell_size
        _snap_player_to_grid()
        _log_msg("Step to %d,%d" % [int(round(player_pos.x / grid_cell_size)), int(round(player_pos.y / grid_cell_size))])
        
    # Keep on screen
    var clamp_rect = play_bounds if bounds_clamp else Rect2(0, 0, 1920, 1080)
    player_pos.x = clamp(player_pos.x, clamp_rect.position.x + player_radius, clamp_rect.position.x + clamp_rect.size.x - player_radius)
    player_pos.y = clamp(player_pos.y, clamp_rect.position.y + player_radius, clamp_rect.position.y + clamp_rect.size.y - player_radius)
    
    # Update Hazards & Collisions
    for h in hazards:
        var path_len = h.start_pos.distance_to(h.end_pos)
        if path_len > 0:
            var current_speed = h.base_speed
            h.progress += h.dir * (current_speed * delta / path_len)
            if h.progress >= 1.0:
                h.progress = 1.0
                h.dir = -1.0
            elif h.progress <= 0.0:
                h.progress = 0.0
                h.dir = 1.0
            h.pos = h.start_pos.lerp(h.end_pos, h.progress)
            
        # Check collision with player
        if player_pos.distance_to(h.pos) < (player_radius + 15.0):
            # Collision!
            spawn_particle_burst(player_pos, Color(1.0, 0.0, 0.8), 20)
            lives -= 1
            player_pos = player_start_pos
            _snap_player_to_grid()
            _log_msg("Hit by traffic, lives=%d" % lives)
            if lives <= 0:
                game_over = true
                send_ipc_message({"type": "finished", "score": score})
            else:
                score = max(0, score - 100)
                send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})
            break
            
    # Check collision with Goal Nodes
    for g in goal_nodes:
        if bool(g.get("filled", false)):
            continue
        var g_pos = Vector2(g.get("x", 0), g.get("y", 0))
        if player_pos.distance_to(g_pos) < 35.0:
            # Reached goal!
            spawn_particle_burst(g_pos, Color(0.0, 1.0, 1.0), 25)
            score += 500
            send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})
            g["filled"] = true
            player_pos = player_start_pos
            _snap_player_to_grid()
            _log_msg("Goal reached, score=%d" % score)
            var all_filled = true
            for other_goal in goal_nodes:
                if not bool(other_goal.get("filled", false)):
                    all_filled = false
                    break
            if all_filled:
                _advance_stage()
            break

func spawn_particle_burst(position: Vector2, color: Color, count: int = 15):
    for j in range(count):
        var angle = randf() * PI * 2.0
        var speed = randf_range(60.0, 260.0)
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

func _draw():
    if show_background and background_texture:
        draw_texture_rect(background_texture, Rect2(0, 0, 1920, 1080), false, Color(1, 1, 1, background_opacity))
    if current_skin == "neon":
        draw_background_grid()
        
        # Draw graph edges as lane outlines
        for edge in graph_edges:
            var n1 = _get_node(str(edge.get("source", "")))
            var n2 = _get_node(str(edge.get("target", "")))
            if n1 and n2:
                draw_line(Vector2(n1.get("x",0), n1.get("y",0)), Vector2(n2.get("x",0), n2.get("y",0)), Color(0.0, 0.3, 0.6, 0.35), 18.0)
                
        # Draw Goal Zones (Cyan)
        for g in goal_nodes:
            var g_pos = Vector2(g.get("x", 0), g.get("y", 0))
            draw_glow_circle(g_pos, 22.0, Color(0.0, 1.0, 1.0))
            
        # Draw Spawn Zones (Cyan)
        for s in spawn_nodes:
            var s_pos = Vector2(s.get("x", 0), s.get("y", 0))
            draw_glow_circle(s_pos, 20.0, Color(0.0, 1.0, 1.0))
            
        # Draw Moving Hazards (Neon Orange Capsules)
        for h in hazards:
            draw_glow_circle(h.pos, 14.0, h.color)
            
        # Draw Player (Glowing Cyan Circle)
        if not game_over:
            draw_glow_circle(player_pos, player_radius, Color(0.0, 0.9, 1.0))
    else: # CLASSIC RETRO SKIN
        # Draw flat highway lanes
        for edge in graph_edges:
            var n1 = _get_node(str(edge.get("source", "")))
            var n2 = _get_node(str(edge.get("target", "")))
            if n1 and n2:
                var p1 = Vector2(n1.get("x", 0), n1.get("y", 0))
                var p2 = Vector2(n2.get("x", 0), n2.get("y", 0))
                draw_line(p1, p2, Color(0.15, 0.15, 0.18), 24.0)
                
        # Draw Spawn Zones (Solid Green Rect)
        for s in spawn_nodes:
            var s_pos = Vector2(s.get("x", 0), s.get("y", 0))
            draw_rect(Rect2(s_pos - Vector2(16, 16), Vector2(32, 32)), Color(0.0, 0.7, 0.1))
            draw_rect(Rect2(s_pos - Vector2(16, 16), Vector2(32, 32)), Color.BLACK, false, 1.5)
            
        # Draw Goal Zones (Solid Yellow Rect)
        for g in goal_nodes:
            var g_pos = Vector2(g.get("x", 0), g.get("y", 0))
            draw_rect(Rect2(g_pos - Vector2(18, 18), Vector2(36, 36)), Color(0.9, 0.8, 0.0))
            draw_rect(Rect2(g_pos - Vector2(18, 18), Vector2(36, 36)), Color.BLACK, false, 1.5)
            
        # Draw Hazards as simple red/yellow blocky cars
        for h in hazards:
            draw_rect(Rect2(h.pos - Vector2(16, 10), Vector2(32, 20)), h.color)
            draw_rect(Rect2(h.pos - Vector2(16, 10), Vector2(32, 20)), Color.BLACK, false, 1.5)
            # draw simple wheels
            draw_rect(Rect2(h.pos - Vector2(12, 13), Vector2(6, 3)), Color.DARK_GRAY)
            draw_rect(Rect2(h.pos + Vector2(6, -13), Vector2(6, 3)), Color.DARK_GRAY)
            draw_rect(Rect2(h.pos - Vector2(12, -10), Vector2(6, 3)), Color.DARK_GRAY)
            draw_rect(Rect2(h.pos + Vector2(6, 10), Vector2(6, 3)), Color.DARK_GRAY)
            
        # Draw Player (Green blocky frog)
        if not game_over:
            draw_rect(Rect2(player_pos - Vector2(12, 12), Vector2(24, 24)), Color(0.1, 0.8, 0.1))
            draw_rect(Rect2(player_pos - Vector2(12, 12), Vector2(24, 24)), Color.BLACK, false, 1.5)
            # eyes
            draw_circle(player_pos + Vector2(-6, -6), 3.0, Color.WHITE)
            draw_circle(player_pos + Vector2(6, -6), 3.0, Color.WHITE)
            draw_circle(player_pos + Vector2(-6, -6), 1.5, Color.BLACK)
            draw_circle(player_pos + Vector2(6, -6), 1.5, Color.BLACK)
        
    # Draw Particles
    for p in active_particles:
        var alpha = p.life / p.max_life
        var col = Color(p.color.r, p.color.g, p.color.b, alpha)
        draw_circle(p.pos, 3.5 * alpha, col)
        
    # Draw HUD
    var hud_text = "LIVES: %s   SCORE: %d" % ["I".repeat(lives), score]
    hud_text += "   STAGE: %d" % stage
    if game_over:
        hud_text = "GAME OVER! PRESS SPACE TO RESTART"
    draw_string(ThemeDB.fallback_font, Vector2(20, 40), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
