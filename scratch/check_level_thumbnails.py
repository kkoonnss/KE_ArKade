import os

base_dir = "content/scenes/scene_classic_pack/levels"
for d in sorted(os.listdir(base_dir)):
    p = os.path.join(base_dir, d)
    if os.path.isdir(p) and d != "derived":
        t = os.path.join(p, "thumbnail.png")
        exists = os.path.exists(t)
        size = os.path.getsize(t) if exists else -1
        print(f"{d} -> Thumbnail: {'OK' if exists else 'MISSING'} ({size} bytes)")
