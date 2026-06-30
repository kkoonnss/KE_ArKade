with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

found = False
for idx, line in enumerate(lines):
    if "classic_level_to_cartridge =" in line:
        found = True
    if found:
        print(f"{idx+1}: {line.strip()}")
        if "}" in line:
            found = False
