import os

base_dir = "content/cartridges"
for d in os.listdir(base_dir):
    p = os.path.join(base_dir, d, "manifest.yaml")
    if os.path.exists(p):
        status = "unknown"
        game_name = d
        with open(p, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("status:"):
                    status = line.split(":", 1)[1].strip()
                elif line.startswith("game_name:"):
                    game_name = line.split(":", 1)[1].strip()
        print(f"{d} ({game_name}): {status}")
