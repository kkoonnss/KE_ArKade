import cv2
import numpy as np
import json
import os
import sys

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))
try:
    from app.shared.palette import CLASSES
except ImportError:
    CLASSES = {0: {'name': 'empty', 'authoring_color': '#000000'}, 1: {'name': 'solid', 'authoring_color': '#FFFFFF'}}

def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (4, 2, 0))

def generate_grid(semantic_map_path, out_json_path, cell_px=32, verbose=True):
    img = cv2.imread(semantic_map_path)
    if img is None:
        raise ValueError(f"Could not load image {semantic_map_path}")
        
    h, w = img.shape[:2]
    
    # Build BGR to class ID map
    palette = {}
    for cid, info in CLASSES.items():
        palette[hex_to_bgr(info['authoring_color'])] = cid
        
    cols = int(np.ceil(w / float(cell_px)))
    rows = int(np.ceil(h / float(cell_px)))
    
    cells = []
    for r in range(rows):
        row_cells = []
        y_start = r * cell_px
        y_end = min(y_start + cell_px, h)
        
        for c in range(cols):
            x_start = c * cell_px
            x_end = min(x_start + cell_px, w)
            
            crop = img[y_start:y_end, x_start:x_end]
            pixels = crop.reshape(-1, 3)
            
            # Find majority color
            colors, counts = np.unique(pixels, axis=0, return_counts=True)
            majority_color = colors[np.argmax(counts)]
            
            # Match majority color to nearest palette class ID
            best_cid = 0
            min_dist = float('inf')
            for pal_color, cid in palette.items():
                dist = np.sum((np.array(pal_color) - majority_color) ** 2)
                if dist < min_dist:
                    min_dist = dist
                    best_cid = cid
            row_cells.append(best_cid)
        cells.append(row_cells)
        
    grid_data = {
        "cell_px": cell_px,
        "width": cols,
        "height": rows,
        "cells": cells
    }
    
    with open(out_json_path, 'w') as f:
        json.dump(grid_data, f, indent=2)
    if verbose:
        print(f"Generated grid layer saved to {out_json_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python grid.py <in_semantic_map> <out_grid_json> [cell_px]")
        sys.exit(1)
    cell_px = 32
    if len(sys.argv) >= 4:
        cell_px = int(sys.argv[3])
    generate_grid(sys.argv[1], sys.argv[2], cell_px)
