with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

for idx in range(540, 650):
    if idx < len(lines):
        print(f"{idx+1}: {lines[idx].strip()}")
