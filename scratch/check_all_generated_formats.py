from PIL import Image
import os

base_dir = "content/cartridges"
for entry in sorted(os.listdir(base_dir)):
    cart_path = os.path.join(base_dir, entry)
    if not os.path.isdir(cart_path) or entry == "loopback":
        continue
    
    t_path = os.path.join(cart_path, "thumbnail.png")
    if os.path.exists(t_path):
        try:
            with Image.open(t_path) as img:
                print(f"{entry} -> Format: {img.format}, Size: {img.size}")
        except Exception as e:
            print(f"{entry} -> Error: {e}")
