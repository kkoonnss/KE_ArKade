with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

classic_func = '''
func _setup_classic_donkey_kong():
    platforms.clear()
    ladders.clear()
    
    # Tier 0 (Bottom)
    platforms.append(Rect2(map_w * 0.1, map_h * 0.90, map_w * 0.8, 5))
    # Ladder 0->1 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.76, 6, map_h * 0.14))
    
    # Tier 1
    platforms.append(Rect2(map_w * 0.1, map_h * 0.76, map_w * 0.8, 5))
    # Ladder 1->2 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.62, 6, map_h * 0.14))
    
    # Tier 2
    platforms.append(Rect2(map_w * 0.1, map_h * 0.62, map_w * 0.8, 5))
    # Ladder 2->3 (Right)
    ladders.append(Rect2(map_w * 0.82, map_h * 0.48, 6, map_h * 0.14))
    
    # Tier 3
    platforms.append(Rect2(map_w * 0.1, map_h * 0.48, map_w * 0.8, 5))
    # Ladder 3->4 (Left)
    ladders.append(Rect2(map_w * 0.18, map_h * 0.34, 6, map_h * 0.14))
    
    # Tier 4
    platforms.append(Rect2(map_w * 0.1, map_h * 0.34, map_w * 0.8, 5))
    # Ladder 4->5 (Middle Right)
    ladders.append(Rect2(map_w * 0.6, map_h * 0.20, 6, map_h * 0.14))
    
    # Tier 5 (Top - Pauline and DK)
    platforms.append(Rect2(map_w * 0.35, map_h * 0.20, map_w * 0.35, 5))
    
    # Donkey Kong platform (Top Left)
    platforms.append(Rect2(map_w * 0.2, map_h * 0.25, map_w * 0.15, 5))
    
    # Extra ladders for classic feel
    ladders.append(Rect2(map_w * 0.3, map_h * 0.25, 6, map_h * 0.09)) # Ladder from DK down to Tier 4
    ladders.append(Rect2(map_w * 0.45, map_h * 0.76, 6, map_h * 0.14)) # Middle ladder Tier 0->1
    ladders.append(Rect2(map_w * 0.55, map_h * 0.48, 6, map_h * 0.14)) # Middle ladder Tier 2->3
    
    # Items (Goal)
    items.clear()
    items.append({"pos": Vector2(map_w * 0.45, map_h * 0.15), "kind": "goal"})
    
    # Start pos
    player["pos"] = Vector2(map_w * 0.15, map_h * 0.88)
'''

# We need to insert classic_func into main.gd.
# Let's insert it right above _setup_platforms
code = code.replace('func _setup_platforms():', classic_func + '\nfunc _setup_platforms():')

# Now inside _setup_platforms, check for classic.
old_setup = '''func _setup_platforms():
    if adapter_platforms.size() > 0:'''

new_setup = '''func _setup_platforms():
    if level_dir.ends_with("classic") or level_dir.ends_with("classic/") or level_dir.ends_with("classic\\\\"):
        _setup_classic_donkey_kong()
        return
    if adapter_platforms.size() > 0:'''

code = code.replace(old_setup, new_setup)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
