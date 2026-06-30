import cv2
import numpy as np
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))
try:
    from app.shared.palette import CLASSES
except ImportError:
    CLASSES = {}

def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (4, 2, 0))

def generate_occupancy(semantic_map_path, out_path):
    img = cv2.imread(semantic_map_path)
    if img is None:
        raise ValueError(f"Could not load image at {semantic_map_path}")

    h, w, c = img.shape
    occupancy = np.zeros((h, w), dtype=np.uint8)

    # find path color
    path_color = None
    for cid, info in CLASSES.items():
        if info['name'] == 'path':
            path_color = hex_to_bgr(info['authoring_color'])
            break
            
    if path_color is None:
        raise ValueError("Palette has no 'path' class")

    path_color_arr = np.array(path_color)
    
    # 255 where it's exactly path color
    diff = np.abs(img.astype(np.int32) - path_color_arr)
    mask = np.max(diff, axis=2) == 0
    occupancy[mask] = 255
    
    cv2.imwrite(out_path, occupancy)
    return out_path

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python occupancy.py <in_semantic_map> <out_occupancy>")
        sys.exit(1)
    generate_occupancy(sys.argv[1], sys.argv[2])
