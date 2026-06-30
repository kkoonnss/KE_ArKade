with open("app/hub/main.gd", "r", encoding="utf-8") as f:
    lines = f.readlines()

keywords = ["level", "favorite", "sort", "classic", "skin"]
for idx, line in enumerate(lines):
    line_lower = line.lower()
    found = [kw for kw in keywords if kw in line_lower]
    if found:
        # print first few occurrences or interesting parts
        if "func " in line or "class_name" in line or "const " in line or "var " in line or "sort" in line or "fav" in line:
            print(f"{idx+1}: {line.strip()}")
