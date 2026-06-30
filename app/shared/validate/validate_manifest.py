import yaml
import sys
import os

def validate_manifest(file_path):
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)

    errors = []

    required = ["cartridge_id", "game_name", "version", "engine", "process_model", "entry", "requires"]
    for req in required:
        if req not in data:
            errors.append(f"Missing required field: {req}")

    if data.get("process_model") != "separate_process":
        errors.append("process_model must be separate_process")

    if errors:
        print(f"Validation failed for {file_path}:")
        for err in errors:
            print(f" - {err}")
        sys.exit(1)
    else:
        print(f"{file_path} is valid.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate_manifest.py <manifest.yaml>")
        sys.exit(1)
    validate_manifest(sys.argv[1])
