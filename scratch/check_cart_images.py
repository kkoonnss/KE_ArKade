import os

base_dir = "content/cartridges"
for d in sorted(os.listdir(base_dir)):
    cart_path = os.path.join(base_dir, d)
    if not os.path.isdir(cart_path) or d == "loopback":
        continue
    
    manifest_path = os.path.join(cart_path, "manifest.yaml")
    if not os.path.exists(manifest_path):
        continue
        
    thumb = "thumbnail.png"
    splash = "splash.png"
    
    with open(manifest_path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("thumbnail:"):
                thumb = line.split(":", 1)[1].strip()
            elif line.startswith("splash_screen:"):
                splash = line.split(":", 1)[1].strip()
                
    thumb_exists = os.path.exists(os.path.join(cart_path, thumb))
    splash_exists = os.path.exists(os.path.join(cart_path, splash))
    
    print(f"{d} -> Thumbnail: {'OK' if thumb_exists else 'MISSING'}, Splash: {'OK' if splash_exists else 'MISSING'}")
