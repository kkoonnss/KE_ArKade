import os

base_dir = "content/cartridges"
for entry in ["galaga", "gta", "on_track", "qbert", "rampage", "robotron_2084"]:
    cart_path = os.path.join(base_dir, entry)
    if not os.path.exists(cart_path):
        print(f"{entry} -> path does not exist")
        continue
    
    t_path = os.path.join(cart_path, "thumbnail.png")
    s_path = os.path.join(cart_path, "splash.png")
    
    t_size = os.path.getsize(t_path) if os.path.exists(t_path) else -1
    s_size = os.path.getsize(s_path) if os.path.exists(s_path) else -1
    
    print(f"{entry} -> Thumbnail size: {t_size} bytes, Splash size: {s_size} bytes")
