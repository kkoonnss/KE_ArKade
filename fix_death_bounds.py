import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# Fix _platform_move death check
code = code.replace(
    'if not player["on_ground"] and pos.y > map_h and game_id in ["donkey_kong", "bubble_bobble", "joust"]:',
    'if not player["on_ground"] and pos.y > logical_h and game_id in ["donkey_kong", "bubble_bobble", "joust"]:'
)

# Fix _clamp to use logical bounds
code = code.replace(
    'return Vector2(clamp(pos.x, 0, map_w), clamp(pos.y, 0, map_h))',
    'return Vector2(clamp(pos.x, 0, logical_w), clamp(pos.y, 0, logical_h))'
)

# Fix _platform_y default
code = code.replace(
    'var best = map_h * 0.9',
    'var best = logical_h * 0.9'
)

# Fix _spawn_far
code = code.replace(
    'return _clamp(Vector2(randf() * map_w, randf() * map_h))',
    'return _clamp(Vector2(randf() * logical_w, randf() * logical_h))'
)

# Fix _lose_life player reset
code = code.replace(
    'player["pos"] = _safe_pos(Vector2(map_w * 0.18, map_h * 0.78))',
    'player["pos"] = _safe_pos(Vector2(logical_w * 0.18, logical_h * 0.78))'
)

# Fix _lose_life burst
code = code.replace(
    '_burst(player.get("pos", Vector2(map_w * 0.5, map_h * 0.5)), C_RED, 24)',
    '_burst(player.get("pos", Vector2(logical_w * 0.5, logical_h * 0.5)), C_RED, 24)'
)

# Fix reset_game
code = code.replace(
    'player = {"pos": _safe_pos(Vector2(map_w * 0.18, map_h * 0.78)), "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false}',
    'player = {"pos": _safe_pos(Vector2(logical_w * 0.18, logical_h * 0.78)), "vel": Vector2.ZERO, "cool": 0.0, "on_ground": false}'
)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
