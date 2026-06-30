with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    content = f.read()

for line in content.splitlines():
    if "status" in line.lower() or "playable" in line.lower() or "prototype" in line.lower():
        print(line.strip())
