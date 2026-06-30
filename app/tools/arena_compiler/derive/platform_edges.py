import json
import sys

def extract_platform_edges(semantic_map_path, out_path):
    # Stub for MVP
    out_data = {"edges": []}
    with open(out_path, 'w') as f:
        json.dump(out_data, f, indent=2)

if __name__ == '__main__':
    extract_platform_edges(sys.argv[1], sys.argv[2])
