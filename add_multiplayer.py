import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Add dk_players array
if 'var dk_players = []' not in code:
    code = code.replace(
        'var player = {"pos": Vector2.ZERO, "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false}',
        'var player = {"pos": Vector2.ZERO, "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false}\nvar dk_players = []'
    )

# 2. Add knob
if '"selected_players"' not in code:
    code = code.replace(
        'tab_menu.register_knob_float("jump_height", "Jump Height", current_jump_height, 0.5, 2.0, 0.1)',
        'tab_menu.register_knob_float("jump_height", "Jump Height", current_jump_height, 0.5, 2.0, 0.1)\n    tab_menu.register_knob_int("selected_players", "Players", selected_players, 1, 4, "Gameplay")'
    )
    code = code.replace(
        'elif knob_id == "jump_height": current_jump_height = float(value)',
        'elif knob_id == "jump_height": current_jump_height = float(value)\n    elif knob_id == "selected_players": selected_players = int(value)'
    )

# 3. Update _move_vec and _action
old_move_vec = '''func _move_vec() -> Vector2:
    var v = Vector2.ZERO
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
        v.x -= 1
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
        v.x += 1
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
        v.y -= 1
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
        v.y += 1
    var joy = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
    if joy.length() > 0.25:
        v = joy
    return v.normalized() if v.length() > 1.0 else v

func _action() -> bool:
    return Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)'''

new_move_vec = '''func _move_vec(idx: int = 0) -> Vector2:
    var v = Vector2.ZERO
    if idx == 0:
        if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"): v.x -= 1
        if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"): v.x += 1
        if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"): v.y -= 1
        if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"): v.y += 1
    elif idx == 1:
        if Input.is_key_pressed(KEY_LEFT): v.x -= 1
        if Input.is_key_pressed(KEY_RIGHT): v.x += 1
        if Input.is_key_pressed(KEY_UP): v.y -= 1
        if Input.is_key_pressed(KEY_DOWN): v.y += 1
    var joy = Vector2(Input.get_joy_axis(idx, JOY_AXIS_LEFT_X), Input.get_joy_axis(idx, JOY_AXIS_LEFT_Y))
    if joy.length() > 0.25:
        v = joy
    return v.normalized() if v.length() > 1.0 else v

func _action(idx: int = 0) -> bool:
    var pressed = Input.is_joy_button_pressed(idx, JOY_BUTTON_A) or Input.is_joy_button_pressed(idx, JOY_BUTTON_X)
    if idx == 0:
        pressed = pressed or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    elif idx == 1:
        pressed = pressed or Input.is_key_pressed(KEY_ENTER)
    return pressed'''

code = code.replace(old_move_vec, new_move_vec)

# 4. _dk_platform_move
if 'func _dk_platform_move' not in code:
    dk_move = '''
func _dk_platform_move(p: Dictionary, idx: int, delta: float, can_jump: bool):
    var v = _move_vec(idx)
    var pos = p["pos"]
    var vel = p["vel"]
    vel.x = v.x * 190
    var on_ladder = _on_ladder(pos)
    if on_ladder and abs(v.y) > 0.1:
        vel.y = v.y * 145
    else:
        vel.y += 520 * current_gravity * delta
        if can_jump and _action(idx) and p["on_ground"]:
            vel.y = -310 * current_jump_height
    var new_x = pos.x + vel.x * delta
    var hit_wall = false
    for w in walls:
        if w.has_point(Vector2(new_x + sign(vel.x)*12, pos.y - 12)):
            hit_wall = true
            break
    if not hit_wall:
        pos.x = new_x
    pos.y += vel.y * delta
    p["on_ground"] = false
    var moving_down_ladder = on_ladder and v.y > 0.1
    for plat in platforms:
        var r = plat["rect"]
        if pos.x >= r.position.x and pos.x <= r.position.x + r.size.x and vel.y >= 0:
            var t = clamp((pos.x - r.position.x) / max(1.0, r.size.x), 0.0, 1.0)
            var py = lerp(plat["y_left"], plat["y_right"], t)
            if pos.y < py and pos.y + 20 >= py and not moving_down_ladder:
                pos.y = py - 20
                vel.y = 0
                p["on_ground"] = true
    if not p["on_ground"] and pos.y > logical_h:
        p["dead"] = true
        _lose_life()
        return
    p["pos"] = _clamp(pos)
    p["vel"] = vel
'''
    code = code.replace('func _platform_y', dk_move + '\nfunc _platform_y')

# 5. Populate dk_players in _setup_barrel
if 'dk_players.clear()' not in code:
    code = code.replace(
        '''func _setup_barrel():
    _setup_platforms()
    if player_spawn != Vector2.ZERO:
        player["pos"] = player_spawn''',
        '''func _setup_barrel():
    _setup_platforms()
    if player_spawn != Vector2.ZERO:
        player["pos"] = player_spawn
        dk_players.clear()
        for i in range(selected_players):
            dk_players.append({"pos": player_spawn, "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false, "dead": false})'''
    )

# 6. Update _tick_barrel to use dk_players
old_tick_barrel_start = '''func _tick_barrel(delta):
    _platform_move(delta, true)
    player["cool"] = max(0.0, player["cool"] - delta)'''

new_tick_barrel_start = '''func _tick_barrel(delta):
    for i in range(dk_players.size()):
        var p = dk_players[i]
        if p.get("dead", false): continue
        _dk_platform_move(p, i, delta, true)
        p["cool"] = max(0.0, p["cool"] - delta)
        if p["pos"].distance_to(items[0]["pos"]) < 35:
            _win_wave()'''
            
code = code.replace(old_tick_barrel_start, new_tick_barrel_start)

# 7. Update _tick_barrel collisions and _tick_fire_guy collisions
if 'var d = fg["pos"].distance_to(player["pos"])' in code:
    code = code.replace(
        '''        var d = fg["pos"].distance_to(player["pos"])
        if d < 22 and abs(player["vel"].y) < 60:
            _lose_life()
            break''',
        '''        for p in dk_players:
            if p.get("dead", false): continue
            var d = fg["pos"].distance_to(p["pos"])
            if d < 22 and abs(p["vel"].y) < 60:
                p["dead"] = true
                _lose_life()
                break'''
    )
if 'var d = b["pos"].distance_to(player["pos"])' in code:
    code = code.replace(
        '''        var d = b["pos"].distance_to(player["pos"])
        if d < 24 and abs(player["vel"].y) < 60:
            _lose_life()
        elif d < 38 and player["vel"].y < -20 and not b["jumped"]:''',
        '''        for p in dk_players:
            if p.get("dead", false): continue
            var d = b["pos"].distance_to(p["pos"])
            if d < 24 and abs(p["vel"].y) < 60:
                p["dead"] = true
                _lose_life()
            elif d < 38 and p["vel"].y < -20 and not b["jumped"]:'''
    )

# 8. Remove the old _win_wave check at the end of _tick_barrel
if '    if player["pos"].distance_to(items[0]["pos"]) < 35:\n        _win_wave()' in code:
    code = code.replace(
        '    if player["pos"].distance_to(items[0]["pos"]) < 35:\n        _win_wave()',
        ''
    )

# 9. Update _draw_platform_game to loop over dk_players
if '    _draw_little_hero(player["pos"], C_GREEN)' in code:
    code = code.replace(
        '    _draw_little_hero(player["pos"], C_GREEN)',
        '''    var colors = [C_GREEN, Color.CORNFLOWER_BLUE, Color.HOT_PINK, Color.YELLOW]
    if game_id == "donkey_kong" and dk_players.size() > 0:
        for i in range(dk_players.size()):
            var p = dk_players[i]
            if not p.get("dead", false):
                _draw_little_hero(p["pos"], colors[i % colors.size()])
    else:
        _draw_little_hero(player["pos"], C_GREEN)'''
    )

# 10. Update _lose_life to respawn players
if '    if game_id == "donkey_kong" and player_spawn != Vector2.ZERO:\n        player["pos"] = player_spawn\n    else:' in code:
    code = code.replace(
        '''    if game_id == "donkey_kong" and player_spawn != Vector2.ZERO:
        player["pos"] = player_spawn
    else:''',
        '''    if game_id == "donkey_kong" and player_spawn != Vector2.ZERO:
        player["pos"] = player_spawn
        for p in dk_players:
            p["pos"] = player_spawn
            p["vel"] = Vector2.ZERO
            p["dead"] = false
    else:'''
    )
    
with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
