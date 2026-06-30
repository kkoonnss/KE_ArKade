import os

# Levels in classic pack
levels_dir = "content/scenes/scene_classic_pack/levels"
levels = [d for d in os.listdir(levels_dir) if os.path.isdir(os.path.join(levels_dir, d)) and d != "derived"]

# Mappings in main.gd (hardcoded or fallback)
mappings = {
    "classic_tetris": "tetris",
    "classic_pacman": "pacman",
    "classic_bomberman": "bomberman",
    "classic_frogger": "frogger",
    "classic_asteroids": "asteroids",
    "classic_tron": "tron",
    "classic_on_track": "on_track",
    "classic_rampage": "rampage",
    "classic_gta": "gta"
}

# Cartridges available
carts_dir = "content/cartridges"
carts = [d for d in os.listdir(carts_dir) if os.path.isdir(os.path.join(carts_dir, d)) and d != "loopback"]

print("Levels to check:")
for lvl in sorted(levels):
    cart_id = mappings.get(lvl, "")
    if cart_id == "":
        cart_id = lvl.replace("classic_", "")
    
    exists = cart_id in carts
    print(f"- {lvl} -> resolves to cartridge: '{cart_id}' (Exists: {exists})")
