with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

found = False
for idx, line in enumerate(lines):
    if "func parse_simple_yaml" in line:
        found = True
    if found:
        print(f"{idx+1}: {line.strip()}")
        if "func " in line and "func parse_simple_yaml" not in line:
            break
