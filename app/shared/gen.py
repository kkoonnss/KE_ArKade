import yaml
import os

SCHEMA_PATH = "../../vault/50-schemas/semantic-palette-v1.yaml"
PY_OUT = "palette.py"
GD_OUT = "palette.gd"

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    schema_path = os.path.normpath(os.path.join(script_dir, SCHEMA_PATH))
    
    with open(schema_path, "r") as f:
        data = yaml.safe_load(f)
        
    classes = data.get("classes", [])
    
    # Generate Python
    py_lines = [
        "# GENERATED FILE - DO NOT EDIT",
        "# Source: vault/50-schemas/semantic-palette-v1.yaml",
        "",
        "CLASSES = {"
    ]
    for c in classes:
        py_lines.append(f'    {c["id"]}: {{')
        py_lines.append(f'        "name": "{c["name"]}",')
        py_lines.append(f'        "authoring_color": "{c["authoring_color"]}",')
        py_lines.append(f'        "ui_color": "{c["ui_color"]}"')
        py_lines.append("    },")
    py_lines.append("}")
    py_lines.append("")
    
    py_out_path = os.path.join(script_dir, PY_OUT)
    with open(py_out_path, "w") as f:
        f.write("\n".join(py_lines))
        
    # Generate GDScript
    gd_lines = [
        "# GENERATED FILE - DO NOT EDIT",
        "# Source: vault/50-schemas/semantic-palette-v1.yaml",
        "extends Node",
        "",
        "const CLASSES = {"
    ]
    for c in classes:
        gd_lines.append(f'    {c["id"]}: {{')
        gd_lines.append(f'        "name": "{c["name"]}",')
        gd_lines.append(f'        "authoring_color": "{c["authoring_color"]}",')
        gd_lines.append(f'        "ui_color": "{c["ui_color"]}"')
        gd_lines.append("    },")
    gd_lines.append("}")
    gd_lines.append("")
    
    gd_out_path = os.path.join(script_dir, GD_OUT)
    with open(gd_out_path, "w") as f:
        f.write("\n".join(gd_lines))

    # Also emit the copy to Godot Hub shared directory
    hub_gd_path = os.path.normpath(os.path.join(script_dir, "../hub/shared/palette.gd"))
    os.makedirs(os.path.dirname(hub_gd_path), exist_ok=True)
    with open(hub_gd_path, "w") as f:
        f.write("\n".join(gd_lines))
    print(f"Emitted Godot copy to: {hub_gd_path}")

if __name__ == "__main__":
    main()
