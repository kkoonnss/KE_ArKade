import os
import yaml # wait, we can just print the raw manifest contents of a few to see their skins

base_dir = "content/cartridges"
for d in os.listdir(base_dir):
    p = os.path.join(base_dir, d, "manifest.yaml")
    if os.path.exists(p):
        print(f"=== {d} ===")
        with open(p, "r", encoding="utf-8") as f:
            print(f.read())
