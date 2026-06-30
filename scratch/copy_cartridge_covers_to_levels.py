import os
import shutil

base_dir = "content/cartridges"
levels_dir = "content/scenes/scene_classic_pack/levels"

carts = [d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d)) and d != "loopback"]

for cart_id in carts:
    cart_thumb = os.path.join(base_dir, cart_id, "thumbnail.png")
    if not os.path.exists(cart_thumb):
        continue
    
    level_folder = f"classic_{cart_id}"
    target_level_dir = os.path.join(levels_dir, level_folder)
    
    if os.path.exists(target_level_dir):
        target_thumb = os.path.join(target_level_dir, "thumbnail.png")
        print(f"Copying cover art from cartridge '{cart_id}' to level '{level_folder}'...")
        shutil.copy2(cart_thumb, target_thumb)
        print(f"Updated: {target_thumb}")
