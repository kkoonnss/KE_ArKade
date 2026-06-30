import os

base_dir = "content/cartridges"
for d in sorted(os.listdir(base_dir)):
    cart_path = os.path.join(base_dir, d)
    if not os.path.isdir(cart_path) or d == "loopback":
        continue
    
    t_path = os.path.join(cart_path, "thumbnail.png")
    s_path = os.path.join(cart_path, "splash.png")
    
    t_size = os.path.getsize(t_path) if os.path.exists(t_path) else -1
    s_size = os.path.getsize(s_path) if os.path.exists(s_path) else -1
    
    print(f"{d} -> Thumbnail size: {t_size} bytes, Splash size: {s_size} bytes")
