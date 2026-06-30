import re

with open('main.gd', 'r', encoding='utf-8') as f:
    code = f.read()

# Add new global variables
add_vars = """
var game_state = "playing" # playing, game_over, win, respawning
var lives = 3
var enemies = []
var original_player_spawns = []
var original_enemy_spawns = []
var original_pickups = []
"""
code = code.replace("var score = 0\nvar active_particles = []", "var score = 0\nvar active_particles = []\n" + add_vars)

# In _process
process_old = """func _process(delta):
    _process_ipc(delta)
    if visible:
        _process_player(delta)
        _process_particles(delta)
        queue_redraw()"""

process_new = """func _process(delta):
    _process_ipc(delta)
    if visible:
        if game_state in ["playing", "respawning"]:
            _process_player(delta)
            if game_state == "playing":
                _process_enemies(delta)
        _process_particles(delta)
        queue_redraw()"""
code = code.replace(process_old, process_new)

# In load_level(), update how players/enemies are loaded
load_level_old = """                if is_spawn:
                    if current_node_id == "":
                        current_node_id = node.get("id", "")
                    players.append({"x": node.get("x", 0), "y": node.get("y", 0)})
                if is_pickup:
                    pickups.append({"x": node.get("x", 0), "y": node.get("y", 0)})
                    
    if players.size() == 0 and graph_nodes.size() > 0:
        var n = graph_nodes[0]
        players.append({"x": n.get("x", 0), "y": n.get("y", 0)})
        current_node_id = n.get("id", "")"""

load_level_new = """                if is_spawn:
                    if current_node_id == "":
                        current_node_id = node.get("id", "")
                    var p_dict = {"x": node.get("x", 0), "y": node.get("y", 0), "current_node_id": node.get("id", ""), "target_node_id": "", "alive": true}
                    players.append(p_dict)
                    original_player_spawns.append({"x": node.get("x", 0), "y": node.get("y", 0), "id": node.get("id", "")})
                elif "enemy" in tags or node.get("type") == "enemy" or "enemy_spawn" in tags:
                    var e_dict = {"x": node.get("x", 0), "y": node.get("y", 0), "current_node_id": node.get("id", ""), "target_node_id": "", "prev_node_id": "", "speed": 140.0}
                    enemies.append(e_dict)
                    original_enemy_spawns.append({"x": node.get("x", 0), "y": node.get("y", 0), "id": node.get("id", "")})
                
                if is_pickup:
                    pickups.append({"x": node.get("x", 0), "y": node.get("y", 0)})
                    
    if players.size() == 0 and graph_nodes.size() > 0:
        var n = graph_nodes[0]
        var p_dict = {"x": n.get("x", 0), "y": n.get("y", 0), "current_node_id": n.get("id", ""), "target_node_id": "", "alive": true}
        players.append(p_dict)
        original_player_spawns.append({"x": n.get("x", 0), "y": n.get("y", 0), "id": n.get("id", "")})
        current_node_id = n.get("id", "")
        
    # If no enemies, spawn 4 on random nodes far from player
    if enemies.size() == 0 and graph_nodes.size() > 0:
        for _i in range(4):
            var n = graph_nodes[randi() % graph_nodes.size()]
            var e_dict = {"x": n.get("x", 0), "y": n.get("y", 0), "current_node_id": n.get("id", ""), "target_node_id": "", "prev_node_id": "", "speed": 140.0}
            enemies.append(e_dict)
            original_enemy_spawns.append({"x": n.get("x", 0), "y": n.get("y", 0), "id": n.get("id", "")})
"""
code = code.replace(load_level_old, load_level_new)

# Add copying original pickups at end of load_level
code = code.replace('    print("Pac-Man Scale: ", scale_factor, " Offset: ", offset_x, ", ", offset_y)', '    original_pickups = pickups.duplicate(true)\n    print("Pac-Man Scale: ", scale_factor, " Offset: ", offset_x, ", ", offset_y)')

# Replace _process_player entirely
old_process_player = """func _process_player(delta):
    if players.size() == 0:
        return
        
    var p = players[0]
    var pos = Vector2(p.x, p.y)
    
    if target_node_id == "":
        var dir = Vector2.ZERO
        if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
            dir = Vector2(1, 0)
        elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
            dir = Vector2(-1, 0)
        elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
            dir = Vector2(0, 1)
        elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
            dir = Vector2(0, -1)
        
        if dir != Vector2.ZERO and current_node_id != "":
            var best_neighbor = _get_best_neighbor(current_node_id, dir)
            if best_neighbor != "":
                target_node_id = best_neighbor
                
    if target_node_id != "":
        var target_node = _get_node(target_node_id)
        if target_node:
            var target_pos = Vector2(target_node.get("x", 0), target_node.get("y", 0))
            var move_vec = target_pos - pos
            if move_vec.length() <= player_speed * delta:
                pos = target_pos
                current_node_id = target_node_id
                target_node_id = ""
            else:
                pos += move_vec.normalized() * player_speed * delta
                
    p.x = pos.x
    p.y = pos.y
    
    for i in range(pickups.size() - 1, -1, -1):
        var pickup = pickups[i]
        if pos.distance_to(Vector2(pickup.x, pickup.y)) < 15.0:
            var pickup_pos = Vector2(pickup.x, pickup.y)
            pickups.remove_at(i)
            spawn_particle_burst(pickup_pos, Color.YELLOW, 15)
            score += 100
            send_ipc_message({"type": "score", "data": {"player": 1, "score": score}})"""

new_process_player = """func _process_player(delta):
    for i in range(players.size()):
        var p = players[i]
        if not p.get("alive", true):
            continue
            
        var pos = Vector2(p.x, p.y)
        var p_target_node_id = p.get("target_node_id", "")
        var p_current_node_id = p.get("current_node_id", "")
        
        if p_target_node_id == "":
            var dir = Vector2.ZERO
            
            # Controller
            var jx = Input.get_joy_axis(i, JOY_AXIS_LEFT_X)
            var jy = Input.get_joy_axis(i, JOY_AXIS_LEFT_Y)
            if abs(jx) > 0.5: dir = Vector2(sign(jx), 0)
            elif abs(jy) > 0.5: dir = Vector2(0, sign(jy))
            
            # DPAD Controller fallback
            if dir == Vector2.ZERO:
                if Input.is_joy_button_pressed(i, JOY_BUTTON_DPAD_RIGHT): dir = Vector2(1, 0)
                elif Input.is_joy_button_pressed(i, JOY_BUTTON_DPAD_LEFT): dir = Vector2(-1, 0)
                elif Input.is_joy_button_pressed(i, JOY_BUTTON_DPAD_DOWN): dir = Vector2(0, 1)
                elif Input.is_joy_button_pressed(i, JOY_BUTTON_DPAD_UP): dir = Vector2(0, -1)
            
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
                var best_neighbor = _get_best_neighbor(p_current_node_id, dir)
                if best_neighbor != "":
                    p.target_node_id = best_neighbor
                    p_target_node_id = best_neighbor
                    
        if p_target_node_id != "":
            var target_node = _get_node(p_target_node_id)
            if target_node:
                var target_pos = Vector2(target_node.get("x", 0), target_node.get("y", 0))
                var move_vec = target_pos - pos
                if move_vec.length() <= player_speed * delta:
                    pos = target_pos
                    p.current_node_id = p_target_node_id
                    p.target_node_id = ""
                else:
                    pos += move_vec.normalized() * player_speed * delta
                    
        p.x = pos.x
        p.y = pos.y
        
        # Check Pickups
        for j in range(pickups.size() - 1, -1, -1):
            var pickup = pickups[j]
            if pos.distance_to(Vector2(pickup.x, pickup.y)) < 15.0:
                var pickup_pos = Vector2(pickup.x, pickup.y)
                pickups.remove_at(j)
                spawn_particle_burst(pickup_pos, Color.YELLOW, 15)
                score += 10
                send_ipc_message({"type": "score", "data": {"player": i + 1, "score": score}})
                
                if pickups.size() == 0:
                    game_state = "win"
                    send_ipc_message({"type": "state", "data": {"state": "win"}})"""
code = code.replace(old_process_player, new_process_player)

# In _input, add restart logic
old_input = """func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:"""

new_input = """func _input(event):
    if game_state in ["game_over", "win"]:
        if (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or \\
           (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
            _restart_game()
            return

    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F1:"""
code = code.replace(old_input, new_input)

# Add enemies process, restart, respawn logic at the end
new_methods = """
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
"""

code += new_methods

# In _draw, we need to draw enemies and lives/game_state text
# Search for: # Draw Score
old_draw_score = """    # Draw Score
    draw_string(ThemeDB.fallback_font, Vector2(20, 40), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)"""

new_draw_score = """    # Draw Score & Lives
    draw_string(ThemeDB.fallback_font, Vector2(20, 40), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(20, 80), "LIVES: " + str(lives), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    
    if game_state == "game_over":
        draw_string(ThemeDB.fallback_font, Vector2(map_w/2 * scale_factor, map_h/2 * scale_factor), "GAME OVER - PRESS START", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.RED)
    elif game_state == "win":
        draw_string(ThemeDB.fallback_font, Vector2(map_w/2 * scale_factor, map_h/2 * scale_factor), "YOU WIN! - PRESS START", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.GREEN)"""
code = code.replace(old_draw_score, new_draw_score)

# We also need to draw enemies in _draw() for both skins
old_neon_players = """        # Draw players (cyan outlines)
        for p in players:
            draw_glow_circle_outline(Vector2(p.x, p.y), 12.0, Color(0.0, 0.9, 1.0), 2.5)"""

new_neon_players = """        # Draw enemies (red)
        for e in enemies:
            draw_glow_circle(Vector2(e.x, e.y), 12.0, Color(1.0, 0.0, 0.0))
            
        # Draw players (cyan outlines)
        for p in players:
            if p.get("alive", true):
                draw_glow_circle_outline(Vector2(p.x, p.y), 12.0, Color(0.0, 0.9, 1.0), 2.5)"""
code = code.replace(old_neon_players, new_neon_players)

old_classic_players = """        # Draw animated player shapes
        for p in players:"""

new_classic_players = """        # Draw enemies
        for e in enemies:
            draw_rect(Rect2(Vector2(e.x, e.y) - Vector2(10, 10), Vector2(20, 20)), Color(1.0, 0.0, 0.0))
            
        # Draw animated player shapes
        for p in players:
            if not p.get("alive", true): continue"""
code = code.replace(old_classic_players, new_classic_players)

# Fix classic player angle calculation (using p.target_node_id instead of target_node_id)
code = code.replace('            if target_node_id != "":\n                var target_node = _get_node(target_node_id)', '            if p.get("target_node_id", "") != "":\n                var target_node = _get_node(p.target_node_id)')
code = code.replace('            if target_node_id == "":', '            if p.get("target_node_id", "") == "":')

with open('main_new.gd', 'w', encoding='utf-8') as f:
    f.write(code)

print("Done generating main_new.gd")
