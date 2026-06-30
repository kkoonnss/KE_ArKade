import yaml
import sys
import os

def validate_scene(file_path):
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)

    errors = []

    required = ["scene_id", "venue_name", "orientation", "output_profile", "current_calibration", "controller_profile", "status"]
    for req in required:
        if req not in data:
            errors.append(f"Missing required field: {req}")

    if data.get("orientation") not in ["floor", "wall", "table"]:
        errors.append("orientation must be one of [floor, wall, table]")

    output_profile = data.get("output_profile", {})
    res = output_profile.get("native_resolution")
    if not isinstance(res, list) or len(res) != 2 or not all(isinstance(x, int) for x in res):
        errors.append("output_profile.native_resolution must be [w, h] ints")

    controller_profile = data.get("controller_profile", {})
    max_players = controller_profile.get("max_players")
    if not isinstance(max_players, int) or not (1 <= max_players <= 4):
        errors.append("controller_profile.max_players must be in 1..4")

    if data.get("status") == "verified":
        calib = data.get("current_calibration", {})
        calib_file = calib.get("file")
        if not calib_file:
            errors.append("status=verified MUST have a current_calibration.file")
        else:
            # Check if file exists relative to scene.yaml
            calib_path = os.path.join(os.path.dirname(file_path), calib_file)
            if not os.path.exists(calib_path):
                errors.append(f"current_calibration.file does not exist: {calib_file}")

    if errors:
        print(f"Validation failed for {file_path}:")
        for err in errors:
            print(f" - {err}")
        sys.exit(1)
    else:
        print(f"{file_path} is valid.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate_scene.py <scene.yaml>")
        sys.exit(1)
    validate_scene(sys.argv[1])
