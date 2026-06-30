import re

with open('content/cartridges/pacman/main.gd', 'r') as f:
    lines = f.read().splitlines()

stub_idx = 0
for i, line in enumerate(lines):
    if 'func _restart_game(): pass' in line:
        stub_idx = i
        break

base_code = '\n'.join(lines[:stub_idx])

with open('content/cartridges/pacman/update_main.py', 'r') as f:
    updater = f.read()

def get_str(var_name):
    match = re.search(f'{var_name} = \\"\\"\\"(.*?)\\"\\"\\"', updater, re.DOTALL)
    if match: return match.group(1)
    return ''

new_process_player = get_str('new_process_player')
new_methods = get_str('new_methods')

helpers = '''
var show_background = true
var background_opacity = 0.5
var background_texture = null
var classic_wall_width_scale = 1.0

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
    pass

func _draw():
    if show_background and background_texture:
        draw_texture_rect(background_texture, Rect2(0, 0, background_texture.get_width(), background_texture.get_height()), false, Color(1, 1, 1, background_opacity))
        
    for edge in graph_edges:
        var src = _get_node(str(edge.get("source", "")))
        var tgt = _get_node(str(edge.get("target", "")))
        if src and tgt:
            draw_line(Vector2(src.get("x",0), src.get("y",0)), Vector2(tgt.get("x",0), tgt.get("y",0)), Color(0, 0, 1, 0.5), 4.0 * classic_wall_width_scale)
            
    for pk in pickups:
        draw_circle(Vector2(pk.x, pk.y), 6.0 if pk.get("power", false) else 3.0, Color.YELLOW)
        
    for e in enemies:
        draw_rect(Rect2(Vector2(e.x, e.y) - Vector2(12, 12), Vector2(24, 24)), Color.RED)
        
    for p in players:
        if p.get("alive", true):
            draw_circle(Vector2(p.x, p.y), 14.0, Color.CYAN)
            
    draw_string(ThemeDB.fallback_font, Vector2(20, 40), "SCORE: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(20, 80), "LIVES: " + str(lives), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
    if game_state == "game_over":
        draw_string(ThemeDB.fallback_font, Vector2(200, 200), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.RED)
    elif game_state == "win":
        draw_string(ThemeDB.fallback_font, Vector2(200, 200), "YOU WIN!", HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.GREEN)

'''

full_code = base_code + '\n' + helpers + '\n' + new_process_player + '\n' + new_methods

with open('content/cartridges/pacman/main.gd', 'w') as f:
    f.write(full_code)
