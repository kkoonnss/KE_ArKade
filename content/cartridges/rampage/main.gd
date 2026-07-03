extends Node2D
var SharedLoader = (func(): var p = ProjectSettings.globalize_path("res://").path_join("../../../app/shared/shared_loader.gd").simplify_path(); var s = GDScript.new(); s.source_code = FileAccess.get_file_as_string(p); s.reload(); return s).call()

const C_DIM = Color(0.6, 0.63, 0.65)
const BUILDING_COLLAPSE_TIME := 1.15

const VIEW_SIZE := Vector2(1920, 1080)
const FALLBACK_W := 40
const FALLBACK_H := 23

var scene_dir := ""
var level_dir := ""
var ipc_host := "127.0.0.1"
var ipc_port := 0
var ipc_socket: StreamPeerTCP = null
var read_buffer := ""
var heartbeat_timer := 0.0
var ready_sent := false
var screenshot_path := ""

var grid := []
var grid_w := 0
var grid_h := 0
var cell_px := 32.0
var scale_factor := 1.0
var offset := Vector2.ZERO
var map_px := Vector2.ZERO
var game_scale := 1.0
var show_occupancy_grid := false

var splash_rect: TextureRect = null
var splash_timer := 1.8
var paused := false
var blanked := false
var show_reference := false
var reference_texture: Texture2D = null
var background_opacity := 0.16
var ui_canvas: CanvasLayer = null
var tab_menu = null
var shared_loader_script = null
var region_adapter_script = null
var menu_panel: PanelContainer = null
var menu_title_label: Label = null
var menu_subtitle_label: Label = null
var menu_hint_label: Label = null
var menu_labels = []
var menu_items = []
var selected_players: int = 1
var overlay_mode: String = "start"
var selected_menu_index: int = 0
var menu_axis_cooldown: float = 0.0
var tab_menu_shell: BoxContainer = null
var tab_cover_frame: PanelContainer = null
var tab_cover_rect: TextureRect = null

var player := {
    "pos": Vector2.ZERO,
    "vel": Vector2.ZERO,
    "facing": 1,
    "on_ground": false,
    "climb": false,
    "punch_timer": 0.0,
    "health": 100,
    "score": 0,
    "climb_building": -1,
    "climb_side": "",
    "hang": false
}
var buildings := []
var enemies := []
var vehicles := []
var pickups := []
var humans := []
var debris := []
var particles := []
var spawn_timer := 0.0
var wave := 1
var game_over := false
var headless_validation := false
var attack_was_pressed := false

func _ready():
    print("Rampage boot: _ready enter")
    RenderingServer.set_default_clear_color(Color.BLACK)
    _parse_args()
    shared_loader_script = load(_shared_loader_path())
    if shared_loader_script == null:
        push_error("Rampage could not load app/shared/shared_loader.gd")
    _setup_shared_tab_menu()
    print("Rampage boot: args parsed scene=", scene_dir, " level=", level_dir, " ipc_port=", ipc_port, " screenshot=", screenshot_path)
    headless_validation = DisplayServer.get_name() == "headless" and screenshot_path == "" and ipc_port == 0
    if headless_validation:
        print("Rampage boot: headless validation path")
        load_level()
        print("Rampage headless validation loaded level: " + level_dir)
        get_tree().quit()
        return
    if ipc_port > 0:
        ipc_socket = StreamPeerTCP.new()
        ipc_socket.connect_to_host(ipc_host, ipc_port)
    print("Rampage boot: load_level start")
    load_level()
    print("Rampage boot: load_level done")
    _setup_splash()
    print("Rampage boot: splash setup done")
    if screenshot_path != "":
        for _i in range(8):
            await get_tree().process_frame
        var img = get_viewport().get_texture().get_image()
        if img == null:
            print("Rampage screenshot skipped: viewport image unavailable for this display driver")
        else:
            var err = img.save_png(screenshot_path)
            print("Rampage screenshot saved: ", screenshot_path, " err=", err)
        get_tree().quit()

func _repo_root() -> String:
    var d = ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
    if d.ends_with("/"):
        d = d.substr(0, d.length() - 1)
    for _i in range(10):
        if DirAccess.dir_exists_absolute(d.path_join("app/shared")):
            return d
        var p = d.get_base_dir()
        if p == d or p == "":
            break
        d = p
    return ""

func _shared_loader_path() -> String:
    return _repo_root().path_join("app/shared/shared_loader.gd")

func _setup_shared_tab_menu():
    if shared_loader_script == null:
        return
    var tab_script = shared_loader_script.load_tab_menu_script()
    if tab_script == null:
        push_error("Rampage could not load shared TabMenu")
        return
    tab_menu = tab_script.new()
    add_child(tab_menu)
    tab_menu.register_knob_int("players", "Players", selected_players, 1, 4, 1, "Gameplay")
    tab_menu.register_knob_float("game_scale", "Game Scale", 1.0, 0.75, 1.35, 0.05, "Gameplay")
    tab_menu.register_knob_float("vertical_gaps", "Vertical Gaps", 0.35, 0.0, 1.0, 0.05, "Gameplay")
    tab_menu.register_knob_float("grid_resolution", "Grid Resolution", 1.0, 0.5, 2.0, 0.1, "Map")
    tab_menu.register_knob_float("density", "Density", 1.0, 0.1, 2.0, 0.1, "Map")
    tab_menu.register_knob_bool("invert", "Invert", false, "Map")
    tab_menu.register_knob_bool("bounds_clamp", "Bounds Clamp", true, "Map")
    tab_menu.register_knob_bool("smooth", "Smooth", false, "Map")
    tab_menu.register_knob_bool("show_grid", "Show Occupancy Grid", false, "Preview")
    tab_menu.register_knob_bool("reference", "Reference Overlay", show_reference, "Preview")
    tab_menu.register_knob_float("reference_opacity", "Reference Opacity", background_opacity, 0.0, 1.0, 0.05, "Preview")
    tab_menu.connect("knob_changed", Callable(self, "_on_shared_knob_changed"))
    tab_menu.connect("action_triggered", Callable(self, "_on_shared_menu_action"))
    tab_menu.setup("rampage", level_dir, "RAMPAGE")
    _apply_shared_menu_settings()

func _apply_shared_menu_settings():
    if tab_menu == null:
        return
    selected_players = int(tab_menu.get_knob_value("players"))
    game_scale = float(tab_menu.get_knob_value("game_scale"))
    show_occupancy_grid = bool(tab_menu.get_knob_value("show_grid"))
    show_reference = bool(tab_menu.get_knob_value("reference"))
    background_opacity = float(tab_menu.get_knob_value("reference_opacity"))

func _on_shared_knob_changed(knob_id: String, value):
    _apply_shared_menu_settings()
    if knob_id in ["grid_resolution", "invert", "density", "vertical_gaps", "bounds_clamp", "smooth"]:
        load_level()
    elif knob_id == "game_scale":
        _configure_map()
    queue_redraw()

func _on_shared_menu_action(action_id: String):
    if action_id == "start":
        _dismiss_splash()

func _shared_menu_open() -> bool:
    return tab_menu != null and tab_menu.overlay_mode != ""

func _parse_args():
    var args = OS.get_cmdline_args()
    args.append_array(OS.get_cmdline_user_args())
    var i := 0
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
            var ipc = str(args[i + 1])
            if ":" in ipc:
                var parts = ipc.split(":")
                ipc_host = parts[0]
                ipc_port = int(parts[1])
            else:
                ipc_port = int(ipc)
            i += 1
        elif a in ["--screenshot", "--arkade_screenshot"] and i + 1 < args.size():
            screenshot_path = str(args[i + 1])
            i += 1
        elif a.begins_with("--arkade_screenshot="):
            screenshot_path = a.split("=", true, 1)[1]
        i += 1

func _setup_splash():
    var layer = CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    splash_rect = TextureRect.new()
    splash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    splash_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var splash_path = ProjectSettings.globalize_path("res://").path_join("splash.png")
    if FileAccess.file_exists(splash_path):
        var img = Image.load_from_file(splash_path)
        if img:
            splash_rect.texture = ImageTexture.create_from_image(img)
    layer.add_child(splash_rect)

func _build_menu_shell():
    ui_canvas = CanvasLayer.new()
    ui_canvas.layer = 101
    add_child(ui_canvas)
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
    tab_cover_frame.custom_minimum_size = Vector2(960, 540)
    tab_cover_frame.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.95, 0.78, 0.22), Color(0.03, 0.03, 0.06, 0.96)))
    tab_menu_shell.add_child(tab_cover_frame)
    tab_cover_rect = TextureRect.new()
    tab_cover_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    tab_cover_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tab_cover_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tab_cover_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if splash_rect and splash_rect.texture:
        tab_cover_rect.texture = splash_rect.texture
    tab_cover_frame.add_child(tab_cover_rect)
    menu_panel = PanelContainer.new()
    menu_panel.custom_minimum_size = Vector2(420, 540)
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
    menu_subtitle_label.add_theme_color_override("font_color", C_DIM)
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
    menu_hint_label.add_theme_color_override("font_color", C_DIM)
    box.add_child(menu_hint_label)
    _update_menu_overlay()

func load_level():
    print("Rampage boot: load_level enter level=", level_dir)
    grid = []
    if not _load_region_adapter_grid():
        print("Rampage boot: RegionAdapter missing or invalid, trying legacy grid")
    if grid.is_empty() and not _load_grid_json():
        print("Rampage boot: grid.json missing or invalid, trying occupancy")
        if not _load_occupancy_grid():
            print("Rampage boot: occupancy missing, using fallback grid")
            _make_fallback_grid()
    _carve_vertical_gaps()
    _configure_map()
    _load_reference()
    _make_buildings()
    _reset_player()
    enemies = []
    vehicles = []
    pickups = []
    humans = []
    debris = []
    particles = []
    spawn_timer = 0.6
    game_over = false
    attack_was_pressed = false
    queue_redraw()
    print("Rampage boot: load_level exit grid=", grid_w, "x", grid_h, " buildings=", buildings.size())

func _load_region_adapter_grid() -> bool:
    if shared_loader_script == null:
        return false
    if region_adapter_script == null:
        region_adapter_script = shared_loader_script.load_adapter_script("region")
    if region_adapter_script == null:
        return false
    var adapter = region_adapter_script.new()
    var knobs = {
        "block_size": 1.0,
        "invert": false,
        "density": 1.0,
        "bounds_clamp": true,
        "smooth": false
    }
    if tab_menu != null:
        knobs["block_size"] = tab_menu.get_knob_value("grid_resolution")
        knobs["invert"] = tab_menu.get_knob_value("invert")
        knobs["density"] = tab_menu.get_knob_value("density")
        knobs["bounds_clamp"] = tab_menu.get_knob_value("bounds_clamp")
        knobs["smooth"] = tab_menu.get_knob_value("smooth")
    var layout = adapter.interpret(level_dir, {}, knobs)
    var cells = layout.get("cells", [])
    cell_px = float(layout.get("cell_size", 32.0)) * float(knobs.get("block_size", 1.0))
    if typeof(cells) == TYPE_ARRAY and not cells.is_empty():
        grid = cells
        grid_h = grid.size()
        grid_w = grid[0].size() if grid_h > 0 else 0
    else:
        var regions = layout.get("regions", [])
        if typeof(regions) != TYPE_ARRAY or regions.is_empty():
            return false
        var bounds = layout.get("bounds", Rect2(0, 0, 1280, 720))
        grid_w = max(8, int(ceil(bounds.size.x / cell_px)))
        grid_h = max(8, int(ceil(bounds.size.y / cell_px)))
        grid = []
        for y in range(grid_h):
            var row = []
            for x in range(grid_w):
                row.append(0)
            grid.append(row)
        for region in regions:
            if not (region is Rect2):
                continue
            var start_x = clampi(int(floor(region.position.x / cell_px)), 0, grid_w - 1)
            var end_x = clampi(int(ceil((region.position.x + region.size.x) / cell_px)), 0, grid_w)
            var start_y = clampi(int(floor(region.position.y / cell_px)), 0, grid_h - 1)
            var end_y = clampi(int(ceil((region.position.y + region.size.y) / cell_px)), 0, grid_h)
            for yy in range(start_y, end_y):
                for xx in range(start_x, end_x):
                    grid[yy][xx] = 1
    print("Rampage SharedLoader RegionAdapter level=", level_dir, " grid=", grid_w, "x", grid_h, " cell_px=", cell_px)
    return grid_w > 0 and grid_h > 0

func _load_grid_json() -> bool:
    if level_dir == "":
        return false
    var path = level_dir.path_join("derived").path_join("grid.json")
    if not FileAccess.file_exists(path):
        return false
    var text = FileAccess.get_file_as_string(path)
    var data = JSON.parse_string(text)
    if typeof(data) != TYPE_DICTIONARY or not data.has("cells"):
        return false
    grid_w = int(data.get("width", 0))
    grid_h = int(data.get("height", 0))
    cell_px = float(data.get("cell_px", 32))
    var cells = data["cells"]
    if grid_w <= 0 or grid_h <= 0 or typeof(cells) != TYPE_ARRAY:
        return false
    for y in range(grid_h):
        var row = []
        for x in range(grid_w):
            var v := 0
            if y < cells.size() and typeof(cells[y]) == TYPE_ARRAY and x < cells[y].size():
                v = int(cells[y][x])
            row.append(v)
        grid.append(row)
    return true

func _load_occupancy_grid() -> bool:
    if level_dir == "":
        return false
    var path = level_dir.path_join("derived").path_join("occupancy.png")
    if not FileAccess.file_exists(path):
        return false
    var img = Image.load_from_file(path)
    if img == null:
        return false
    grid_w = FALLBACK_W
    grid_h = FALLBACK_H
    cell_px = max(24.0, float(img.get_width()) / float(grid_w))
    for y in range(grid_h):
        var row = []
        for x in range(grid_w):
            var px = int((float(x) + 0.5) / float(grid_w) * img.get_width())
            var py = int((float(y) + 0.5) / float(grid_h) * img.get_height())
            px = clampi(px, 0, img.get_width() - 1)
            py = clampi(py, 0, img.get_height() - 1)
            var c = img.get_pixel(px, py)
            var solid = 1 if c.get_luminance() < 0.45 else 0
            row.append(solid)
        grid.append(row)
    return true

func _make_fallback_grid():
    grid_w = FALLBACK_W
    grid_h = FALLBACK_H
    cell_px = 32.0
    for y in range(grid_h):
        var row = []
        for x in range(grid_w):
            var v = 1 if x == 0 or y == 0 or x == grid_w - 1 or y == grid_h - 1 else 0
            row.append(v)
        grid.append(row)

func _configure_map():
    map_px = Vector2(float(grid_w) * cell_px, float(grid_h) * cell_px)
    scale_factor = min(VIEW_SIZE.x / map_px.x, VIEW_SIZE.y / map_px.y) * 0.92 * game_scale
    offset = (VIEW_SIZE - map_px * scale_factor) * 0.5

func _load_reference():
    reference_texture = null
    if DisplayServer.get_name() == "headless":
        return
    if level_dir == "":
        return
    var yaml = level_dir.path_join("level.yaml")
    if not FileAccess.file_exists(yaml):
        return
    var file = FileAccess.open(yaml, FileAccess.READ)
    if file == null:
        return
    while not file.eof_reached():
        var line = file.get_line().strip_edges()
        if line.begins_with("reference_image:"):
            var ref = line.split(":", true, 1)[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
            var path = level_dir.path_join(ref)
            if FileAccess.file_exists(path):
                var img = Image.load_from_file(path)
                if img:
                    reference_texture = ImageTexture.create_from_image(img)
            return

func _make_buildings():
    buildings = []
    var visited = []
    visited.resize(grid_h)
    for y in range(grid_h):
        visited[y] = []
        visited[y].resize(grid_w)
        visited[y].fill(false)
    for y in range(1, grid_h - 1):
        for x in range(1, grid_w - 1):
            if visited[y][x] or _cell_open(x, y):
                continue
            var max_x = x
            while max_x + 1 < grid_w - 1 and not _cell_open(max_x + 1, y) and not visited[y][max_x + 1]:
                max_x += 1
            var max_y = y
            var can_grow = true
            while can_grow and max_y + 1 < grid_h - 1:
                for xx in range(x, max_x + 1):
                    if _cell_open(xx, max_y + 1) or visited[max_y + 1][xx]:
                        can_grow = false
                        break
                if can_grow:
                    max_y += 1
            for yy in range(y, max_y + 1):
                for xx in range(x, max_x + 1):
                    visited[yy][xx] = true
            _add_building(Rect2(Vector2(x, y), Vector2(max_x - x + 1, max_y - y + 1)))
    if buildings.size() < 6:
        _make_procedural_city()

func _add_building(cell_rect: Rect2):
    if cell_rect.size.x * cell_rect.size.y < 4:
        return
    var px_rect = Rect2(cell_rect.position * cell_px, cell_rect.size * cell_px)
    var color = [Color(0, 0.9, 1), Color(1, 0, 0.75), Color(1, 0.75, 0), Color(0.2, 1, 0.35)][buildings.size() % 4]
    var window_cols = max(2, int(cell_rect.size.x))
    var window_rows = max(2, int(cell_rect.size.y))
    var windows = []
    var total_windows = 0
    for wy in range(window_rows):
        var row = []
        for wx in range(window_cols):
            total_windows += 1
            row.append({
                "broken": false,
                "content": _pick_window_content()
            })
        windows.append(row)
    buildings.append({
        "rect": px_rect,
        "cell_rect": cell_rect,
        "color": color,
        "windows": windows,
        "window_cols": window_cols,
        "window_rows": window_rows,
        "total_windows": total_windows,
        "broken_windows": 0,
        "collapse_at": max(1, int(ceil(float(total_windows) * 0.7))),
        "collapsed": false,
        "collapse_timer": 0.0
    })

func _make_procedural_city():
    buildings = []
    var ground = grid_h - 2
    var x := 3
    while x < grid_w - 4:
        var w = 2 + (x % 3)
        var h = 5 + ((x * 7) % 8)
        var y = max(2, ground - h)
        _add_building(Rect2(Vector2(x, y), Vector2(w, h)))
        x += w + 2

func _reset_player():
    var start = _find_nearest_walkable_cell(grid_w / 2, grid_h - 3)
    player["pos"] = _cell_center(start.x, start.y)
    player["vel"] = Vector2.ZERO
    player["facing"] = 1
    player["health"] = 100
    player["score"] = 0
    player["punch_timer"] = 0.0
    player["climb_building"] = -1
    player["climb_side"] = ""
    player["hang"] = false
    send_ipc_message({"type": "score", "data": {"player": 1, "score": 0}})
    _spawn_humans()

func _spawn_humans():
    humans = []
    for b in buildings:
        if bool(b.get("collapsed", false)):
            continue
        var r: Rect2 = b["rect"]
        var windows: Array = b["windows"]
        if windows.is_empty():
            continue
        for i in range(min(4, windows.size())):
            var row_index = randi() % windows.size()
            var row: Array = windows[row_index]
            if row.is_empty():
                continue
            var col_index = randi() % row.size()
            if bool(row[col_index].get("broken", false)):
                continue
            humans.append({
                "kind": "civilian" if randf() < 0.72 else "soldier",
                "pos": _window_center(r, col_index, row_index),
                "anchor_pos": _window_center(r, col_index, row_index),
                "vel": Vector2.ZERO,
                "alive": true,
                "anchored": true,
                "building_index": buildings.find(b),
                "window_row": row_index,
                "window_col": col_index
            })
    for i in range(8):
        humans.append({
            "kind": "civilian" if randf() < 0.7 else "soldier",
            "pos": Vector2(randf_range(cell_px * 2.0, map_px.x - cell_px * 2.0), float(grid_h - 2) * cell_px),
            "anchor_pos": Vector2.ZERO,
            "vel": Vector2.ZERO,
            "alive": true,
            "anchored": false,
            "building_index": -1,
            "window_row": -1,
            "window_col": -1
        })
    vehicles = []
    for i in range(4):
        vehicles.append({
            "pos": Vector2(randf_range(cell_px * 2.0, map_px.x - cell_px * 2.0), float(grid_h - 2) * cell_px),
            "vel": Vector2(randf_range(-1.0, 1.0) * cell_px * 2.0, 0),
            "alive": true,
            "kind": "car"
        })

func _cell_open(x: int, y: int) -> bool:
    if x < 0 or y < 0 or x >= grid_w or y >= grid_h:
        return false
    return int(grid[y][x]) != 1

func _cell_blocked(x: int, y: int) -> bool:
    if x < 0 or y < 0 or x >= grid_w or y >= grid_h:
        return false
    return int(grid[y][x]) == 1

func _vertical_gap_strength() -> float:
    if tab_menu == null:
        return 0.35
    return float(tab_menu.get_knob_value("vertical_gaps"))

func _carve_vertical_gaps():
    var strength = _vertical_gap_strength()
    if strength <= 0.01 or grid.is_empty():
        return
    var spacing = max(3, int(round(lerp(9.0, 3.0, strength))))
    var phase = int(round(strength * 7.0)) % spacing
    var min_run = max(4, int(round(lerp(8.0, 4.0, strength))))
    for x in range(2, grid_w - 2):
        if ((x + phase) % spacing) != 0:
            continue
        var opened_any = false
        var y = 1
        while y < grid_h - 1:
            if not _cell_blocked(x, y):
                y += 1
                continue
            var run_start = y
            while y < grid_h - 1 and _cell_blocked(x, y):
                y += 1
            var run_end = y - 1
            var run_len = run_end - run_start + 1
            if run_len < min_run:
                continue
            var supported = 0
            for yy in range(run_start, run_end + 1):
                if _cell_blocked(x - 1, yy) or _cell_blocked(x + 1, yy):
                    supported += 1
            if supported < run_len * 0.7:
                continue
            for yy in range(run_start, run_end + 1):
                grid[yy][x] = 0
            opened_any = true
        if opened_any and strength >= 0.7 and x + 1 < grid_w - 2:
            for yy in range(1, grid_h - 1):
                if not _cell_blocked(x, yy) and (_cell_blocked(x + 1, yy - 1) or _cell_blocked(x + 1, yy) or _cell_blocked(x + 1, yy + 1)):
                    grid[yy][x + 1] = 0

func _find_nearest_walkable_cell(start_x: int, start_y: int) -> Vector2i:
    if grid_w <= 0 or grid_h <= 0:
        return Vector2i(1, 1)
    var sx = clampi(start_x, 0, grid_w - 1)
    var sy = clampi(start_y, 0, grid_h - 1)
    if _cell_open(sx, sy):
        return Vector2i(sx, sy)
    var q = [Vector2i(sx, sy)]
    var seen = {}
    seen[str(sx) + "," + str(sy)] = true
    var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
    while q.size() > 0:
        var c = q.pop_front()
        if _cell_open(c.x, c.y):
            return c
        for d in dirs:
            var n = c + d
            var key = str(n.x) + "," + str(n.y)
            if n.x >= 0 and n.y >= 0 and n.x < grid_w and n.y < grid_h and not seen.has(key):
                seen[key] = true
                q.append(n)
    return Vector2i(sx, sy)

func _cell_center(x: int, y: int) -> Vector2:
    return Vector2((float(x) + 0.5) * cell_px, (float(y) + 0.5) * cell_px)

func _process(delta):
    if menu_axis_cooldown > 0.0:
        menu_axis_cooldown = max(0.0, menu_axis_cooldown - delta)
    _process_splash(delta)
    _process_ipc(delta)
    if _shared_menu_open() or paused or blanked:
        queue_redraw()
        return
    if not game_over:
        _update_building_collapse(delta)
        _update_player(delta)
        _update_pickups(delta)
        _check_player_pickups()
        _update_humans(delta)
        _update_vehicles(delta)
        _update_enemies(delta)
        _update_debris(delta)
        _update_particles(delta)
    queue_redraw()

func _process_splash(delta):
    if splash_rect:
        splash_timer -= delta
        if splash_timer <= 0:
            splash_rect.queue_free()
            splash_rect = null
        elif splash_timer < 0.7:
            splash_rect.modulate.a = splash_timer / 0.7

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
    if not tab_menu:
        return
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
    var title_text = "Rampage"
    var subtitle = "Classic cover on the left, clean controls on the right."
    var hint = "A / Start / Enter selects. D-Pad / arrows move. Left/right adjusts."
    var lines = []
    if overlay_mode == "help":
        title_text += " HELP"
        subtitle = "Projection-ready controls, restart flow, and reference overlay live here."
        hint = "A / Start confirms. B / Escape goes back."
        lines = ["Climb, punch, and smash the buildings.", "Press Tab for settings.", "F1 toggles the level reference overlay.", _menu_line(0), _menu_line(1)]
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
        return [{"label": "Players: %d" % selected_players, "action": "players"}, {"label": "Reference Overlay: " + ("On" if show_reference else "Off"), "action": "reference"}, {"label": "Back", "action": "back"}, {"label": "Start Game", "action": "start"}]
    if mode == "help":
        return [{"label": "Back", "action": "back"}, {"label": "Start Game", "action": "start"}]
    if mode == "start":
        return [{"label": "Start Game", "action": "start"}, {"label": "Help", "action": "help"}, {"label": "Settings", "action": "settings"}, {"label": "Players: %d" % selected_players, "action": "players"}, {"label": "Reference", "action": "reference"}]
    return []

func _menu_line(index: int) -> String:
    if index < 0 or index >= menu_items.size():
        return ""
    return ("> " if index == selected_menu_index else "  ") + str(menu_items[index].get("label", ""))

func _handle_menu_input(event) -> bool:
    if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
        if get("game_state") != null and get("game_state") != "playing":
            if has_method("_reset_game"): call("_reset_game")
            elif has_method("reset_game"): call("reset_game")
        elif get("state") != null and get("state") != "playing":
            if has_method("_reset_game"): call("_reset_game")
            elif has_method("reset_game"): call("reset_game")

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
        if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
            _menu_accept()
            return true
        if event.keycode in [KEY_ESCAPE, KEY_BACKSPACE]:
            _menu_back()
            return true
        if event.keycode == KEY_TAB:
            _set_overlay_mode("settings" if overlay_mode != "settings" else "start")
            return true
    if event is InputEventJoypadButton and event.pressed:
        if event.button_index in [JOY_BUTTON_DPAD_UP]:
            _menu_move(-1)
            return true
        if event.button_index in [JOY_BUTTON_DPAD_DOWN]:
            _menu_move(1)
            return true
        if event.button_index in [JOY_BUTTON_DPAD_LEFT]:
            _menu_adjust(-1)
            return true
        if event.button_index in [JOY_BUTTON_DPAD_RIGHT]:
            _menu_adjust(1)
            return true
        if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
            _menu_accept()
            return true
        if event.button_index in [JOY_BUTTON_B, JOY_BUTTON_X]:
            _menu_back()
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
        selected_players = clampi(selected_players + step, 1, 4)
        if tab_menu != null:
            tab_menu.set_knob_value("players", selected_players, false, false)
        _update_menu_overlay()
        return
    if action == "reference":
        show_reference = not show_reference
    _update_menu_overlay()

func _menu_accept():
    if menu_items.is_empty():
        return
    var action = str(menu_items[selected_menu_index].get("action", ""))
    print("Rampage menu accept: ", action)
    if action == "start":
        _dismiss_splash()
        _set_overlay_mode("")
    elif action == "help":
        _set_overlay_mode("help")
    elif action == "settings":
        _set_overlay_mode("settings")
    elif action == "players":
        selected_players = clampi(selected_players + 1, 1, 4)
        if tab_menu != null:
            tab_menu.set_knob_value("players", selected_players, false, false)
        _update_menu_overlay()
    elif action == "back":
        _set_overlay_mode("start")
    elif action == "reference":
        show_reference = not show_reference
        _update_menu_overlay()

func _menu_back():
    print("Rampage menu back from mode: ", overlay_mode)
    if overlay_mode == "":
        _set_overlay_mode("start")
    elif overlay_mode == "start":
        _set_overlay_mode("")
    else:
        _set_overlay_mode("start")

func _dismiss_splash():
    if splash_rect and is_instance_valid(splash_rect):
        splash_rect.queue_free()
    splash_rect = null

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

func _update_player(delta):
    var dir := 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        dir -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        dir += 1.0
    if dir != 0:
        player["facing"] = 1 if dir > 0 else -1
    var vel: Vector2 = player["vel"]
    var climb_up := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    var climb_down := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    var jump_pressed := Input.is_key_pressed(KEY_ALT)
    var jumped := false
    var attack_pressed := Input.is_key_pressed(KEY_SPACE)
    var attack_triggered := attack_pressed and not attack_was_pressed
    attack_was_pressed = attack_pressed
    var attached := {}
    if int(player["climb_building"]) >= 0 and int(player["climb_building"]) < buildings.size():
        var climb_b = buildings[int(player["climb_building"])]
        if not bool(climb_b.get("collapsed", false)):
            attached = {"index": int(player["climb_building"]), "side": str(player["climb_side"])}
    if attached.is_empty() and climb_up:
        attached = _resolve_climb_attachment(player["pos"])
    var can_jump = bool(player["on_ground"]) or int(player["climb_building"]) >= 0 or _resolve_roof_support(player["pos"]).size() > 0
    if jump_pressed and can_jump:
        var launch_dir = 0
        if int(player["climb_building"]) >= 0:
            launch_dir = 1 if player["climb_side"] == "left" else -1
        elif dir != 0:
            launch_dir = 1 if dir > 0 else -1
        player["climb_building"] = -1
        player["climb_side"] = ""
        player["hang"] = false
        player["climb"] = false
        vel.x = launch_dir * cell_px * 4.5
        vel.y = -cell_px * 5.5
        player["on_ground"] = false
        jumped = true
    elif not attached.is_empty() and (climb_up or climb_down or int(player["climb_building"]) >= 0):
        player["climb_building"] = int(attached["index"])
        player["climb_side"] = str(attached["side"])
        player["hang"] = not climb_up and not climb_down
        var climb_b2 = buildings[player["climb_building"]]
        var snapped = _snap_to_building_side(player["pos"], climb_b2, player["climb_side"])
        vel.x = 0
        if climb_up:
            vel.y = -cell_px * 3.2
        elif climb_down:
            vel.y = cell_px * 3.2
        else:
            vel.y = 0
        if _is_at_building_roof(snapped, climb_b2):
            snapped.y = climb_b2["rect"].position.y - cell_px * 0.36
            player["climb_building"] = -1
            player["climb_side"] = ""
            player["hang"] = false
            player["on_ground"] = true
            vel.y = 0
        player["pos"] = snapped
        player["climb"] = true
    else:
        player["climb"] = false
        player["hang"] = false
        player["climb_building"] = -1
        player["climb_side"] = ""
        vel.x = dir * cell_px * 5.0
        vel.y += cell_px * 11.0 * delta
    if not climb_up and not climb_down and int(player["climb_building"]) >= 0:
        player["hang"] = true
    if not climb_up and not climb_down and not jump_pressed and int(player["climb_building"]) >= 0:
        var keep = _resolve_climb_attachment(player["pos"])
        if keep.is_empty():
            player["climb_building"] = -1
            player["climb_side"] = ""
            player["hang"] = false
    if attack_triggered and player["punch_timer"] <= 0.0:
        player["punch_timer"] = 0.28
        _attack()
    player["punch_timer"] = max(0.0, float(player["punch_timer"]) - delta)
    var pos: Vector2 = player["pos"] + vel * delta
    var ground_y = float(grid_h - 2) * cell_px
    if pos.y > ground_y:
        pos.y = ground_y
        vel.y = 0
        player["on_ground"] = true
    else:
        player["on_ground"] = false
    var roof_support = _resolve_roof_support(pos)
    if not jumped and not roof_support.is_empty():
        pos = roof_support["pos"]
        vel.y = 0
        player["on_ground"] = true
        if int(roof_support.get("building_index", -1)) >= 0:
            player["climb_building"] = -1
            player["climb_side"] = ""
    pos.x = clamp(pos.x, cell_px * 0.8, (grid_w - 0.8) * cell_px)
    pos.y = clamp(pos.y, cell_px * 1.2, (grid_h - 1.4) * cell_px)
    if int(player["climb_building"]) >= 0 and int(player["climb_building"]) < buildings.size():
        var clamp_b = buildings[int(player["climb_building"])]
        if not bool(clamp_b.get("collapsed", false)):
            if climb_up or climb_down:
                pos = _snap_to_building_side(pos, clamp_b, str(player["climb_side"]))
            else:
                var keep = _resolve_climb_attachment(pos)
                if keep.is_empty():
                    player["climb_building"] = -1
                    player["climb_side"] = ""
                    player["hang"] = false
    player["pos"] = pos
    player["vel"] = vel

func _near_building(pos: Vector2) -> bool:
    for b in buildings:
        if bool(b.get("collapsed", false)):
            continue
        var r: Rect2 = b["rect"].grow(cell_px * 0.45)
        if r.has_point(pos):
            return true
    return false

func _resolve_climb_attachment(pos: Vector2) -> Dictionary:
    for i in range(buildings.size()):
        var b = buildings[i]
        if bool(b.get("collapsed", false)):
            continue
        var r: Rect2 = b["rect"]
        if pos.y < r.position.y - cell_px * 0.25 or pos.y > r.end.y + cell_px * 0.25:
            continue
        var left_dist = abs(pos.x - r.position.x)
        var right_dist = abs(pos.x - r.end.x)
        if left_dist <= cell_px * 0.6 and left_dist <= right_dist:
            return {"index": i, "side": "left"}
        if right_dist <= cell_px * 0.6:
            return {"index": i, "side": "right"}
    return {}

func _snap_to_building_side(pos: Vector2, b: Dictionary, side: String) -> Vector2:
    var r: Rect2 = b["rect"]
    var snapped = pos
    if side == "left":
        snapped.x = r.position.x - cell_px * 0.32
    else:
        snapped.x = r.end.x + cell_px * 0.32
    snapped.y = clamp(snapped.y, r.position.y + cell_px * 0.2, r.end.y - cell_px * 0.15)
    return snapped

func _is_at_building_roof(pos: Vector2, b: Dictionary) -> bool:
    var r: Rect2 = b["rect"]
    return pos.y <= r.position.y + cell_px * 0.24

func _resolve_roof_support(pos: Vector2) -> Dictionary:
    for i in range(buildings.size()):
        var b = buildings[i]
        if bool(b.get("collapsed", false)):
            continue
        var r: Rect2 = b["rect"]
        if pos.x < r.position.x - cell_px * 0.2 or pos.x > r.end.x + cell_px * 0.2:
            continue
        var roof_y = r.position.y - cell_px * 0.36
        if abs(pos.y - roof_y) <= cell_px * 0.5:
            return {"pos": Vector2(clamp(pos.x, r.position.x, r.end.x), roof_y), "building_index": i}
    return {}

func _attack():
    var pos: Vector2 = player["pos"]
    var facing = int(player["facing"])
    var airborne = not bool(player["on_ground"]) and int(player["climb_building"]) < 0
    var attack_box = Rect2(pos + Vector2(facing * cell_px * 0.35, -cell_px * 0.9), Vector2(facing * cell_px * 1.6, cell_px * 1.8)).abs()
    var scored := false
    if airborne:
        _flying_kick(attack_box)
        return
    for b in buildings:
        if bool(b.get("collapsed", false)):
            continue
        if attack_box.intersects(b["rect"]) and _damage_building_window(b, attack_box.get_center()):
            scored = true
    if _attack_near_pickup(attack_box):
        scored = true
    if _attack_near_vehicle(attack_box):
        scored = true
    if _attack_near_human(attack_box):
        scored = true
    if scored:
        send_ipc_message({"type": "score", "data": {"player": 1, "score": int(player["score"])}})

func _flying_kick(attack_box: Rect2):
    var hit_any = false
    for b in buildings:
        if bool(b.get("collapsed", false)):
            continue
        if attack_box.intersects(b["rect"]):
            _damage_building_window(b, attack_box.get_center())
            hit_any = true
    if _attack_near_pickup(attack_box):
        hit_any = true
    if _attack_near_vehicle(attack_box):
        hit_any = true
    if _attack_near_human(attack_box):
        hit_any = true
    if hit_any:
        player["score"] = int(player["score"]) + 25

func _attack_near_vehicle(attack_box: Rect2) -> bool:
    for v in vehicles:
        if bool(v.get("alive", false)) and attack_box.intersects(Rect2(v["pos"] + Vector2(-cell_px * 0.45, -cell_px * 0.25), Vector2(cell_px * 0.9, cell_px * 0.5))):
            v["vel"].x = -v["vel"].x * 1.4
            player["score"] = int(player["score"]) + 75
            _burst(v["pos"], Color(1.0, 0.8, 0.2))
            return true
    return false

func _attack_near_human(attack_box: Rect2) -> bool:
    for h in humans:
        if not bool(h.get("alive", false)):
            continue
        if bool(h.get("anchored", false)) and not _window_actor_exposed(int(h.get("building_index", -1)), int(h.get("window_row", -1)), int(h.get("window_col", -1))):
            continue
        var hp = h["pos"]
        if attack_box.intersects(Rect2(hp + Vector2(-cell_px * 0.18, -cell_px * 0.35), Vector2(cell_px * 0.36, cell_px * 0.7))):
            _eat_human(h)
            return true
    return false

func _attack_near_pickup(attack_box: Rect2) -> bool:
    for p in pickups:
        if float(p.get("life", 0.0)) <= 0.0:
            continue
        var pp: Vector2 = p["pos"]
        if attack_box.intersects(Rect2(pp + Vector2(-cell_px * 0.22, -cell_px * 0.22), Vector2(cell_px * 0.44, cell_px * 0.44))):
            _apply_pickup_effect(str(p.get("kind", "")))
            p["life"] = 0.0
            return true
    return false

func _pick_window_content() -> String:
    var roll = randf()
    if roll < 0.55:
        return ""
    if roll < 0.72:
        return "food"
    if roll < 0.84:
        return "money"
    if roll < 0.93:
        return "powerup"
    return "bomb"

func _damage_building_window(b: Dictionary, hit_pos: Vector2) -> bool:
    var rect: Rect2 = b["rect"]
    var cols = int(b.get("window_cols", 0))
    var rows = int(b.get("window_rows", 0))
    if cols <= 0 or rows <= 0:
        return false
    var rel_x = clampi(int(floor((hit_pos.x - rect.position.x) / cell_px)), 0, cols - 1)
    var rel_y = clampi(int(floor((hit_pos.y - rect.position.y) / cell_px)), 0, rows - 1)
    var windows: Array = b["windows"]
    if rel_y < 0 or rel_y >= windows.size():
        return false
    var row: Array = windows[rel_y]
    if row.is_empty() or rel_x < 0 or rel_x >= row.size():
        return false
    var step = 1 if int(player.get("facing", 1)) >= 0 else -1
    var target_x = rel_x
    while target_x >= 0 and target_x < row.size():
        var probe: Dictionary = row[target_x]
        if not bool(probe.get("broken", false)):
            break
        target_x += step
    if target_x < 0 or target_x >= row.size():
        return false
    var window: Dictionary = row[target_x]
    window["broken"] = true
    row[target_x] = window
    windows[rel_y] = row
    b["windows"] = windows
    b["broken_windows"] = int(b.get("broken_windows", 0)) + 1
    player["score"] = int(player["score"]) + 25
    var broken_pos = _window_center(rect, target_x, rel_y)
    _burst(broken_pos, Color(1, 0.8, 0))
    var content = str(window.get("content", ""))
    if content != "":
        _spawn_window_pickup(broken_pos, content, buildings.find(b), rel_y, target_x)
    if int(b["broken_windows"]) >= int(b["collapse_at"]):
        _collapse_building(b)
        player["score"] = int(player["score"]) + 300
    return true

func _window_center(rect: Rect2, wx: int, wy: int) -> Vector2:
    return rect.position + Vector2((float(wx) + 0.5) * cell_px, (float(wy) + 0.5) * cell_px)

func _collapse_building(b: Dictionary):
    if bool(b.get("collapsed", false)):
        return
    var building_index = buildings.find(b)
    b["collapsed"] = true
    b["collapse_timer"] = 0.0
    for p in pickups:
        if bool(p.get("anchored", false)) and int(p.get("building_index", -1)) == building_index:
            p["life"] = 0.0
    for h in humans:
        if bool(h.get("anchored", false)) and int(h.get("building_index", -1)) == building_index:
            h["alive"] = false
    _spawn_debris(b["rect"])
    _burst(b["rect"].get_center(), Color(1, 0.45, 0.1))
    _burst(b["rect"].position + Vector2(b["rect"].size.x * 0.25, b["rect"].size.y * 0.7), Color(1, 0.7, 0.2))
    _burst(b["rect"].position + Vector2(b["rect"].size.x * 0.75, b["rect"].size.y * 0.82), Color(0.95, 0.45, 0.12))

func _update_building_collapse(delta):
    for b in buildings:
        if not bool(b.get("collapsed", false)):
            continue
        b["collapse_timer"] = min(BUILDING_COLLAPSE_TIME, float(b.get("collapse_timer", 0.0)) + delta)

func _cell_in_building_footprint(x: int, y: int) -> bool:
    for b in buildings:
        var cell_rect: Rect2 = b.get("cell_rect", Rect2())
        var left = int(cell_rect.position.x)
        var top = int(cell_rect.position.y)
        var right = left + int(cell_rect.size.x)
        var bottom = top + int(cell_rect.size.y)
        if x >= left and x < right and y >= top and y < bottom:
            return true
    return false

func _window_actor_exposed(building_index: int, window_row: int, window_col: int) -> bool:
    if building_index < 0 or building_index >= buildings.size():
        return true
    var windows: Array = buildings[building_index].get("windows", [])
    if window_row < 0 or window_row >= windows.size():
        return true
    var row: Array = windows[window_row]
    if window_col < 0 or window_col >= row.size():
        return true
    return bool(row[window_col].get("broken", false))

func _spawn_window_pickup(pos: Vector2, kind: String, building_index: int, window_row: int, window_col: int):
    pickups.append({
        "pos": pos,
        "anchor_pos": pos,
        "vel": Vector2.ZERO,
        "life": 30.0,
        "kind": kind,
        "anchored": true,
        "building_index": building_index,
        "window_row": window_row,
        "window_col": window_col
    })

func _update_pickups(delta):
    for p in pickups:
        if bool(p.get("anchored", false)):
            p["pos"] = p.get("anchor_pos", p["pos"])
        else:
            p["vel"].y += cell_px * 5.5 * delta
            p["pos"] = p["pos"] + p["vel"] * delta
        p["life"] = float(p["life"]) - delta
    pickups = pickups.filter(func(p): return float(p["life"]) > 0.0 and p["pos"].y < map_px.y + cell_px * 2)

func _update_humans(delta):
    var pos: Vector2 = player["pos"]
    for h in humans:
        if not bool(h.get("alive", false)):
            continue
        if bool(h.get("anchored", false)):
            h["vel"] = Vector2.ZERO
            h["pos"] = h.get("anchor_pos", h["pos"])
            continue
        var kind = str(h.get("kind", "civilian"))
        var target_vel = Vector2.ZERO
        if kind == "soldier":
            target_vel.x = sign(pos.x - h["pos"].x) * cell_px * 1.5
        else:
            target_vel.x = sin(Time.get_ticks_msec() / 900.0 + h["pos"].x * 0.01) * cell_px * 0.5
        h["vel"] = target_vel
        h["pos"] = h["pos"] + h["vel"] * delta
        if h["pos"].distance_to(pos) <= cell_px * 0.72:
            _eat_human(h)
        h["pos"].x = clamp(h["pos"].x, cell_px * 0.8, (grid_w - 0.8) * cell_px)
        h["pos"].y = clamp(h["pos"].y, cell_px * 0.8, (grid_h - 1.3) * cell_px)
    humans = humans.filter(func(h): return bool(h.get("alive", false)))

func _update_vehicles(delta):
    for v in vehicles:
        if not bool(v.get("alive", false)):
            continue
        v["pos"] = v["pos"] + v["vel"] * delta
        if v["pos"].x < cell_px or v["pos"].x > map_px.x - cell_px:
            v["vel"].x = -v["vel"].x
        v["pos"].x = clamp(v["pos"].x, cell_px * 1.0, map_px.x - cell_px * 1.0)
        v["pos"].y = float(grid_h - 2) * cell_px
    vehicles = vehicles.filter(func(v): return bool(v.get("alive", false)))

func _check_player_pickups():
    var pos: Vector2 = player["pos"]
    for p in pickups:
        if bool(p.get("anchored", false)):
            continue
        if p["pos"].distance_to(pos) <= cell_px * 0.55:
            _apply_pickup_effect(str(p.get("kind", "")))
            p["life"] = 0.0

func _apply_pickup_effect(kind: String):
    if kind == "food":
        player["health"] = min(100, int(player["health"]) + 20)
        player["score"] = int(player["score"]) + 50
    elif kind == "money":
        player["score"] = int(player["score"]) + 250
    elif kind == "powerup":
        player["health"] = min(100, int(player["health"]) + 35)
        player["score"] = int(player["score"]) + 500
    elif kind == "bomb":
        player["health"] = max(0, int(player["health"]) - 25)
        if int(player["health"]) <= 0:
            game_over = true
            send_ipc_message({"type": "state", "data": {"state": "game_over"}})
    send_ipc_message({"type": "score", "data": {"player": 1, "score": int(player["score"])}})

func _eat_human(human: Dictionary):
    if not bool(human.get("alive", false)):
        return
    human["alive"] = false
    if str(human.get("kind", "")) == "soldier":
        player["health"] = max(0, int(player["health"]) - 15)
    else:
        player["health"] = min(100, int(player["health"]) + 10)
    player["score"] = int(player["score"]) + 100
    send_ipc_message({"type": "score", "data": {"player": 1, "score": int(player["score"])}})

func _update_enemies(delta):
    spawn_timer -= delta
    if spawn_timer <= 0:
        spawn_timer = max(0.75, 2.2 - wave * 0.12)
        _spawn_enemy()
    var pos: Vector2 = player["pos"]
    for e in enemies:
        e["pos"] = e["pos"] + e["vel"] * delta
        if e["kind"] == "heli":
            e["vel"].x = sin(Time.get_ticks_msec() / 550.0 + e["phase"]) * cell_px * 2.0
            if randf() < 0.006:
                debris.append({"pos": e["pos"], "vel": Vector2(0, cell_px * 4.4), "life": 4.0, "color": Color(1, 0.2, 0.1)})
        else:
            e["vel"].x = sign(pos.x - e["pos"].x) * cell_px * 1.8
        if e["pos"].distance_to(pos) < cell_px * 0.8:
            player["health"] = max(0, int(player["health"]) - 8)
            e["life"] = 0.0
            _burst(pos, Color(1, 0.1, 0.2))
            if int(player["health"]) <= 0:
                game_over = true
                send_ipc_message({"type": "state", "data": {"state": "game_over"}})
        e["life"] = float(e["life"]) - delta
    enemies = enemies.filter(func(e): return float(e["life"]) > 0.0 and e["pos"].x > -cell_px * 2 and e["pos"].x < map_px.x + cell_px * 2)

func _spawn_enemy():
    var side = -1 if randf() < 0.5 else 1
    var kind = "heli" if randf() < 0.55 else "tank"
    var y = cell_px * (3.0 + randf() * 5.0) if kind == "heli" else cell_px * float(grid_h - 2)
    var x = -cell_px if side < 0 else map_px.x + cell_px
    enemies.append({"kind": kind, "pos": Vector2(x, y), "vel": Vector2(side * cell_px * 2.0, 0), "life": 12.0, "phase": randf() * 10.0})

func _spawn_debris(r: Rect2):
    for i in range(18):
        debris.append({
            "pos": r.position + Vector2(randf() * r.size.x, randf() * r.size.y),
            "vel": Vector2(randf_range(-1.2, 1.2) * cell_px * 2.4, randf_range(-4.6, -1.1) * cell_px),
            "life": randf_range(1.1, 2.0),
            "color": Color(1, 0.55, 0)
        })

func _update_debris(delta):
    var pos: Vector2 = player["pos"]
    for d in debris:
        d["vel"].y += cell_px * 7.0 * delta
        d["pos"] = d["pos"] + d["vel"] * delta
        d["life"] = float(d["life"]) - delta
        if d["pos"].distance_to(pos) < cell_px * 0.55:
            player["health"] = max(0, int(player["health"]) - 4)
            d["life"] = 0.0
    debris = debris.filter(func(d): return float(d["life"]) > 0.0 and d["pos"].y < map_px.y + cell_px)

func _burst(pos: Vector2, color: Color):
    for i in range(12):
        particles.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(cell_px * 1.2, cell_px * 4.0), "life": randf_range(0.25, 0.8), "color": color})

func _update_particles(delta):
    for p in particles:
        p["pos"] = p["pos"] + p["vel"] * delta
        p["life"] = float(p["life"]) - delta
    particles = particles.filter(func(p): return float(p["life"]) > 0.0)

func _input(event):
    if _shared_menu_open():
        return
    if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
        if get("game_state") != null and get("game_state") != "playing":
            if has_method("_reset_game"): call("_reset_game")
            elif has_method("reset_game"): call("reset_game")
        elif get("state") != null and get("state") != "playing":
            if has_method("_reset_game"): call("_reset_game")
            elif has_method("reset_game"): call("reset_game")

    if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
        if get("game_state") != null and get("game_state") != "playing":
            if has_method("_reset_game"): call("_reset_game")
            elif has_method("reset_game"): call("reset_game")
        elif get("state") != null and get("state") != "playing":
            if has_method("_reset_game"): call("_reset_game")
            elif has_method("reset_game"): call("reset_game")

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F1:
            show_reference = not show_reference
        elif event.keycode == KEY_ENTER:
            load_level()

func _draw():
    draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color.BLACK, true)
    if headless_validation:
        return
    if blanked:
        return
    if show_reference and reference_texture:
        draw_texture_rect(reference_texture, Rect2(offset, map_px * scale_factor), false, Color(1, 1, 1, background_opacity))
    draw_set_transform(offset, 0, Vector2(scale_factor, scale_factor))
    _draw_city()
    _draw_pickups()
    _draw_humans()
    _draw_enemies()
    _draw_debris()
    _draw_player()
    _draw_particles()
    draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
    _draw_hud()

func _draw_city():
    if show_occupancy_grid:
        for y in range(grid_h):
            for x in range(grid_w):
                if not _cell_open(x, y) and not _cell_in_building_footprint(x, y):
                    var r = Rect2(Vector2(x, y) * cell_px, Vector2(cell_px, cell_px))
                    draw_rect(r.grow(-1), Color(0.0, 0.35, 0.5, 0.07), true)
                    draw_rect(r, Color(0.0, 0.9, 1.0, 0.14), false, 1.0)
    for b in buildings:
        var r: Rect2 = b["rect"]
        var c: Color = b["color"]
        if bool(b.get("collapsed", false)):
            var collapse_t = min(1.0, float(b.get("collapse_timer", 0.0)) / BUILDING_COLLAPSE_TIME)
            var fall_t = ease(collapse_t, 0.55)
            var slice_count = max(3, int(ceil(r.size.y / max(1.0, cell_px))))
            var slice_h = r.size.y / float(slice_count)
            for i in range(slice_count):
                var slice_t = float(i) / float(max(1, slice_count - 1))
                var local_t = clamp((collapse_t - slice_t * 0.08) / max(0.24, 1.0 - slice_t * 0.35), 0.0, 1.0)
                var remaining = 1.0 - local_t
                if remaining <= 0.02:
                    continue
                var wobble = sin(float(i) * 1.7 + r.position.x * 0.015) * cell_px * 0.08 * local_t
                var drop = lerp(0.0, cell_px * (0.8 + slice_t * 2.6), fall_t) + local_t * r.size.y * 0.14
                var slice_rect = Rect2(
                    Vector2(r.position.x + wobble, r.position.y + slice_h * float(i) + drop),
                    Vector2(r.size.x, max(2.0, slice_h * remaining))
                )
                draw_rect(slice_rect, Color(0.10, 0.10, 0.12, 0.88 * remaining), true)
                if remaining > 0.16:
                    draw_rect(slice_rect.grow(-2), Color(c.r, c.g, c.b, 0.12 * remaining), true)
            for i in range(4):
                var band_t = (float(i) + 1.0) / 5.0
                var dust_y = lerp(r.position.y + r.size.y * 0.30, r.end.y - cell_px * 0.10, band_t)
                var dust_w = lerp(r.size.x * 0.46, r.size.x, band_t)
                var dust_h = max(2.0, cell_px * 0.16 * (1.0 - collapse_t * 0.35))
                var dust_x = lerp(r.position.x, r.end.x - dust_w, 0.5 - band_t * 0.12)
                draw_rect(
                    Rect2(Vector2(dust_x, dust_y + fall_t * cell_px * 0.8), Vector2(dust_w, dust_h)),
                    Color(c.r, c.g, c.b, 0.11 * (1.0 - collapse_t)),
                    true
                )
            continue
        draw_rect(r, Color(c.r, c.g, c.b, 0.08), true)
        draw_rect(r, Color(c.r, c.g, c.b, 0.4), false, 2.0)
        var windows: Array = b["windows"]
        for wy in range(windows.size()):
            var row: Array = windows[wy]
            for wx in range(row.size()):
                var window: Dictionary = row[wx]
                var wr = Rect2(r.position + Vector2(wx * cell_px + 4, wy * cell_px + 4), Vector2(cell_px - 8, cell_px - 8))
                if bool(window.get("broken", false)):
                    draw_rect(wr, Color(0.03, 0.03, 0.04, 0.95), true)
                    draw_rect(wr, Color(0.16, 0.16, 0.18, 0.5), false, 1.0)
                else:
                    var glow = Color(1, 0.85, 0.1, 0.45)
                    var content = str(window.get("content", ""))
                    if content == "food":
                        glow = Color(0.2, 1.0, 0.35, 0.55)
                    elif content == "money":
                        glow = Color(1.0, 0.85, 0.15, 0.55)
                    elif content == "powerup":
                        glow = Color(0.3, 0.95, 1.0, 0.6)
                    elif content == "bomb":
                        glow = Color(1.0, 0.25, 0.35, 0.6)
                    draw_rect(wr, Color(c.r, c.g, c.b, 0.12), true)
                    draw_rect(wr.grow(-2), glow, true)
                    draw_rect(wr, Color(1, 1, 1, 0.12), false, 1.0)
        for i in range(3):
            draw_rect(r.grow(i * 2), Color(c.r, c.g, c.b, 0.18 / float(i + 1)), false, 2.0)

func _draw_pickups():
    for p in pickups:
        var c = Color(1, 0.8, 0.1)
        var kind = str(p.get("kind", ""))
        if kind == "food":
            c = Color(0.2, 1.0, 0.35)
        elif kind == "money":
            c = Color(1.0, 0.85, 0.15)
        elif kind == "powerup":
            c = Color(0.3, 0.95, 1.0)
        elif kind == "bomb":
            c = Color(1.0, 0.25, 0.35)
        draw_circle(p["pos"], cell_px * 0.18, Color(c.r, c.g, c.b, 0.75))
        draw_circle(p["pos"], cell_px * 0.09, Color(1, 1, 1, 0.9))

func _draw_humans():
    for h in humans:
        if not bool(h.get("alive", false)):
            continue
        if bool(h.get("anchored", false)) and not _window_actor_exposed(int(h.get("building_index", -1)), int(h.get("window_row", -1)), int(h.get("window_col", -1))):
            continue
        var p: Vector2 = h["pos"]
        var kind = str(h.get("kind", "civilian"))
        var body = Color(1.0, 0.95, 0.65) if kind == "civilian" else Color(1.0, 0.3, 0.35)
        draw_circle(p + Vector2(0, -cell_px * 0.24), cell_px * 0.17, Color(1, 1, 1, 0.95))
        draw_rect(Rect2(p + Vector2(-cell_px * 0.17, -cell_px * 0.10), Vector2(cell_px * 0.34, cell_px * 0.56)), body, true)
        draw_rect(Rect2(p + Vector2(-cell_px * 0.17, -cell_px * 0.10), Vector2(cell_px * 0.34, cell_px * 0.56)), Color(0, 0, 0, 0.42), false, 1.5)
        draw_line(p + Vector2(-cell_px * 0.11, cell_px * 0.12), p + Vector2(-cell_px * 0.18, cell_px * 0.32), Color(0.1, 0.1, 0.1), 3.0)
        draw_line(p + Vector2(cell_px * 0.11, cell_px * 0.12), p + Vector2(cell_px * 0.18, cell_px * 0.32), Color(0.1, 0.1, 0.1), 3.0)
        draw_line(p + Vector2(-cell_px * 0.10, cell_px * 0.02), p + Vector2(-cell_px * 0.22, cell_px * 0.14), Color(0.1, 0.1, 0.1), 2.0)
        draw_line(p + Vector2(cell_px * 0.10, cell_px * 0.02), p + Vector2(cell_px * 0.22, cell_px * 0.14), Color(0.1, 0.1, 0.1), 2.0)

func _draw_player():
    var p: Vector2 = player["pos"]
    var s = cell_px * 0.95
    var body = Color(0.2, 1.0, 0.35)
    var facing = int(player["facing"])
    var leg_phase = sin(Time.get_ticks_msec() / 120.0) * (0.24 if abs(float(player["vel"].x)) > 1.0 else 0.06)
    var torso = Rect2(p + Vector2(-s * 0.34, -s * 0.78), Vector2(s * 0.72, s * 0.92))
    draw_rect(torso, Color(body.r, body.g, body.b, 0.22), true)
    draw_rect(torso, body, false, 3.0)
    draw_rect(Rect2(p + Vector2(-s * 0.22, -s * 1.02), Vector2(s * 0.44, s * 0.20)), body, true)
    draw_rect(Rect2(p + Vector2(-s * 0.22, -s * 1.02), Vector2(s * 0.44, s * 0.20)), Color(0.05, 0.05, 0.05, 0.35), false, 2.0)
    draw_line(p + Vector2(-s * 0.18, s * 0.14), p + Vector2(-s * 0.2 + leg_phase * s * 0.18, s * 0.62), Color(0.05, 0.05, 0.05), 5.0)
    draw_line(p + Vector2(s * 0.18, s * 0.14), p + Vector2(s * 0.2 - leg_phase * s * 0.18, s * 0.62), Color(0.05, 0.05, 0.05), 5.0)
    draw_circle(p + Vector2(-s * 0.10, -s * 0.82), s * 0.06, Color(1, 1, 1))
    draw_circle(p + Vector2(s * 0.10, -s * 0.82), s * 0.06, Color(1, 1, 1))
    if not bool(player["on_ground"]) and int(player["climb_building"]) < 0 and float(player["punch_timer"]) > 0.0:
        var kick_dir = 1 if facing >= 0 else -1
        draw_line(p + Vector2(-s * 0.18 * kick_dir, s * 0.02), p + Vector2(s * 0.68 * kick_dir, -s * 0.18), Color(1, 0.9, 0.1), 5.0)
        draw_line(p + Vector2(s * 0.16 * kick_dir, s * 0.18), p + Vector2(s * 0.78 * kick_dir, s * 0.04), Color(1, 0.9, 0.1), 5.0)
    else:
        var arm_y = p.y - s * 0.38
        var fist = p + Vector2(facing * s * (0.9 if float(player["punch_timer"]) > 0.0 else 0.55), -s * 0.38)
        draw_line(Vector2(p.x, arm_y), fist, Color(1, 1, 1), 4.0)
        draw_circle(fist, s * 0.16, Color(1, 0.75, 0.0, 0.9))

func _draw_enemies():
    for e in enemies:
        var p: Vector2 = e["pos"]
        if e["kind"] == "heli":
            draw_line(p + Vector2(-cell_px * 0.6, -cell_px * 0.25), p + Vector2(cell_px * 0.6, -cell_px * 0.25), Color(1, 0, 0.8), 3.0)
            draw_rect(Rect2(p + Vector2(-cell_px * 0.38, -cell_px * 0.12), Vector2(cell_px * 0.76, cell_px * 0.32)), Color(1, 0, 0.8, 0.25), true)
            draw_rect(Rect2(p + Vector2(-cell_px * 0.38, -cell_px * 0.12), Vector2(cell_px * 0.76, cell_px * 0.32)), Color(1, 0, 0.8), false, 2.0)
        else:
            draw_rect(Rect2(p + Vector2(-cell_px * 0.42, -cell_px * 0.22), Vector2(cell_px * 0.84, cell_px * 0.38)), Color(1, 0.25, 0.05, 0.22), true)
            draw_rect(Rect2(p + Vector2(-cell_px * 0.42, -cell_px * 0.22), Vector2(cell_px * 0.84, cell_px * 0.38)), Color(1, 0.25, 0.05), false, 2.0)
            draw_line(p, p + Vector2(sign(player["pos"].x - p.x) * cell_px * 0.7, -cell_px * 0.08), Color(1, 0.8, 0.2), 3.0)

func _draw_debris():
    for d in debris:
        draw_circle(d["pos"], cell_px * 0.12, d["color"])

func _draw_particles():
    for p in particles:
        var c: Color = p["color"]
        draw_circle(p["pos"], cell_px * 0.08, Color(c.r, c.g, c.b, clamp(float(p["life"]), 0.0, 1.0)))

func _draw_hud():
    var font = ThemeDB.fallback_font
    draw_string(font, Vector2(24, 38), "RAMPAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.0, 1.0, 0.8))
    draw_string(font, Vector2(24, 72), "SCORE " + str(int(player["score"])) + "   HEALTH " + str(int(player["health"])) + "   SPACE ATTACK  ALT JUMP  F1 REF", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1))
    if game_over:
        draw_string(font, Vector2(VIEW_SIZE.x * 0.5 - 120, VIEW_SIZE.y * 0.5), "GAME OVER - ENTER RESTART", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.2, 0.2))

func _process_ipc(delta):
    heartbeat_timer += delta
    if ipc_socket:
        ipc_socket.poll()
        if ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
            if not ready_sent:
                ready_sent = true
                send_ipc_message({"type": "ready"})
            var bytes = ipc_socket.get_available_bytes()
            if bytes > 0:
                read_buffer += ipc_socket.get_utf8_string(bytes)
                var lines = read_buffer.split("\n")
                read_buffer = lines.pop_back()
                for line in lines:
                    _handle_ipc(line)
            if heartbeat_timer >= 1.0:
                send_ipc_message({"type": "heartbeat"})
                heartbeat_timer = 0.0

func _handle_ipc(line: String):
    var msg = JSON.parse_string(line.strip_edges())
    if typeof(msg) != TYPE_DICTIONARY:
        return
    var t = str(msg.get("type", ""))
    if t == "quit":
        get_tree().quit()
    elif t == "pause":
        paused = true
    elif t == "resume":
        paused = false
    elif t == "blank":
        blanked = true
    elif t == "load":
        blanked = false
        paused = false
        var data = msg.get("data", {})
        if typeof(data) == TYPE_DICTIONARY and data.has("level_dir"):
            level_dir = str(data["level_dir"])
        load_level()

func send_ipc_message(msg: Dictionary):
    if ipc_socket and ipc_socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
        ipc_socket.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())
