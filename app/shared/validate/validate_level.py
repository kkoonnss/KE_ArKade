import yaml
import sys
import os

def validate_level(file_path, raise_on_error=False):
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)

    errors = []

    required = ["level_id", "scene_id", "semantic_map", "palette_schema", "status"]
    for req in required:
        if req not in data:
            errors.append(f"Missing required field: {req}")

    # Check if scene_id is referenced
    scene_id = data.get("scene_id")
    if scene_id:
        scene_path = os.path.abspath(os.path.join(os.path.dirname(file_path), "..", "..", "scene.yaml"))
        if not os.path.exists(scene_path):
            errors.append(f"scene_id must reference an existing scene (could not find {scene_path})")

    if errors:
        msg = f"Validation failed for {file_path}:\n" + "\n".join([f" - {err}" for err in errors])
        print(msg)
        if raise_on_error:
            raise ValueError(msg)
        sys.exit(1)
    else:
        print(f"{file_path} is valid.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate_level.py <level.yaml>")
        sys.exit(1)
    validate_level(sys.argv[1])
