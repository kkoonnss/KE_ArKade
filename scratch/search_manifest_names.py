import os

base_dir = "content/cartridges"
for d in os.listdir(base_dir):
    p = os.path.join(base_dir, d, "manifest.yaml")
    if os.path.exists(p):
        with open(p, "r", encoding="utf-8") as f:
            content = f.read().lower()
            if any(name in content for name in ["galaga", "gta", "track", "q*bert", "qbert", "rampage", "robotron"]):
                print(f"Match found in folder '{d}':")
                print(content)
                print("-" * 40)
