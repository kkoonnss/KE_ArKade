with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if "scroll" in line.lower() or "container" in line.lower():
        print(f"{idx+1}: {line.strip()}")
