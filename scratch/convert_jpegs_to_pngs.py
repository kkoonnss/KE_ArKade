from PIL import Image
import os

base_dir = "content/cartridges"
targets = ["galaga", "gta", "on_track", "qbert", "rampage", "robotron_2084"]

for entry in targets:
    cart_path = os.path.join(base_dir, entry)
    if not os.path.exists(cart_path):
        continue
    
    for filename in ["thumbnail.png", "splash.png"]:
        filepath = os.path.join(cart_path, filename)
        if os.path.exists(filepath):
            # Check format first
            with Image.open(filepath) as img:
                fmt = img.format
            
            if fmt == "JPEG":
                print(f"Converting {filepath} (JPEG -> PNG)...")
                # Open, convert to RGB, and save as true PNG
                img = Image.open(filepath)
                # Save as temporary file, then overwrite
                temp_path = filepath + ".tmp"
                img.save(temp_path, "PNG")
                img.close()
                os.remove(filepath)
                os.rename(temp_path, filepath)
                print(f"Successfully converted {filepath} to true PNG!")
