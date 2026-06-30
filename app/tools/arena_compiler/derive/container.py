import cv2
import numpy as np
import json
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

def extract_container(semantic_map_path, out_path):
    img = cv2.imread(semantic_map_path)
    if img is None:
        raise ValueError(f"Could not load image at {semantic_map_path}")

    solid_color = None
    for cid, info in CLASSES.items():
        if info['name'] == 'solid':
            solid_color = hex_to_bgr(info['authoring_color'])
            break
            
    diff = np.abs(img.astype(np.int32) - np.array(solid_color))
    mask = (np.max(diff, axis=2) == 0).astype(np.uint8) * 255
    
    play_area = cv2.bitwise_not(mask)
    # Smooth the play area mask to remove 1-pixel jagged edges
    play_area = cv2.GaussianBlur(play_area, (5, 5), 0)
    _, play_area = cv2.threshold(play_area, 127, 255, cv2.THRESH_BINARY)
    
    contours, _ = cv2.findContours(play_area, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    points = []
    if contours:
        largest = max(contours, key=cv2.contourArea)
        # Simplify contour aggressively for block collision (epsilon 0.02)
        epsilon = 0.02 * cv2.arcLength(largest, True)
        approx = cv2.approxPolyDP(largest, epsilon, True)
        points = [{"x": int(pt[0][0]), "y": int(pt[0][1])} for pt in approx]

    out_data = {
        "well_polygon": points,
        "spawn_lip": {"x": int(img.shape[1]/2), "y": 0},
        "down_direction": {"x": 0, "y": 1}
    }
    
    with open(out_path, 'w') as f:
        json.dump(out_data, f, indent=2)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python container.py <in_semantic_map> <out_container>")
        sys.exit(1)
    extract_container(sys.argv[1], sys.argv[2])
