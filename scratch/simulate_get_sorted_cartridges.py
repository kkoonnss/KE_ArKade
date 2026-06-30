import os

def parse_simple_yaml(path):
    data = {}
    if not os.path.exists(path):
        return data
    with open(path, "r", encoding="utf-8") as file:
        current_parent = ""
        for line in file:
            stripped = line.strip()
            if stripped.startswith("#") or stripped == "":
                continue
            
            indent_level = len(line) - len(line.lstrip())
            
            trimmed = stripped
            if trimmed.endswith(":"):
                current_parent = trimmed[:-1].strip()
                if current_parent not in data:
                    data[current_parent] = {}
                continue
            
            if ":" in trimmed:
                parts = trimmed.split(":", 1)
                key = parts[0].strip()
                val = parts[1].strip()
                
                if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                
                parsed_val = val
                if val.startswith("[") and val.endswith("]"):
                    inner = val[1:-1]
                    list_items = []
                    if inner != "":
                        for item in inner.split(","):
                            list_items.append(item.strip())
                    parsed_val = list_items
                
                if indent_level > 0 and current_parent != "":
                    if isinstance(data[current_parent], dict):
                        data[current_parent][key] = parsed_val
                    else:
                        data[key] = parsed_val
                else:
                    data[key] = parsed_val
    return data

carts_dir = "content/cartridges"
list_carts = []
for entry in sorted(os.listdir(carts_dir)):
    cart_path = os.path.join(carts_dir, entry)
    if not os.path.isdir(cart_path) or entry == "loopback":
        continue
    manifest_path = os.path.join(cart_path, "manifest.yaml")
    manifest = parse_simple_yaml(manifest_path)
    game_name = manifest.get("game_name", entry)
    list_carts.append((entry, game_name, manifest))

print(f"Total parsed: {len(list_carts)}")
for entry, name, manifest in list_carts:
    print(f"- {entry}: {name}")
