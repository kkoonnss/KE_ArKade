import os

for c in ["star_fighter", "galaga"]:
    p = f"content/cartridges/{c}"
    if os.path.exists(p):
        print(f"=== {c} ===")
        m_path = os.path.join(p, "manifest.yaml")
        if os.path.exists(m_path):
            with open(m_path, "r", encoding="utf-8") as f:
                print(f.read())
        t_path = os.path.join(p, "thumbnail.png")
        print(f"Thumbnail exists: {os.path.exists(t_path)}")
        if os.path.exists(t_path):
            print(f"Thumbnail size: {os.path.getsize(t_path)} bytes")
