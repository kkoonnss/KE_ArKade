with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if "sort_custom" in line:
        print(f"{idx+1}: {line.strip()}")
