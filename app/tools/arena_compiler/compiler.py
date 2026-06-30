import cv2
import numpy as np
import sys
import os
import argparse

# Add app to path to import shared palette
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
try:
    from app.shared.palette import CLASSES
except ImportError:
    print("Warning: Could not import app.shared.palette")
    CLASSES = {}

def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (4, 2, 0)) # BGR

def get_palette_bgr():
    palette = {}
    for class_id, class_info in CLASSES.items():
        palette[class_id] = hex_to_bgr(class_info['authoring_color'])
    return palette

def compile_map(source_path, out_path, policy='nearest', tolerance=32):
    img = cv2.imread(source_path)
    if img is None:
        raise ValueError(f"Could not load image at {source_path}")

    palette = get_palette_bgr()
    if not palette:
        raise ValueError("Palette is empty")

    h, w, c = img.shape
    out_img = np.zeros((h, w, 3), dtype=np.uint8)
    
    # Simple nearest neighbor matching
    # Convert palette to array for vectorized operations
    ids = list(palette.keys())
    colors = np.array([palette[i] for i in ids]) # Shape: (N, 3)

    # Flatten img to (H*W, 3)
    img_flat = img.reshape(-1, 3).astype(np.int32)
    
    # For each pixel, find nearest color
    # Distance: L1 or L2? Schema says "within tolerance (per-channel, 0-255)", so maybe L_inf distance or L1?
    # "within tolerance (per-channel_tolerance: 32)" means we check absolute diff per channel.
    
    unmatched_count = 0
    
    for i in range(len(ids)):
        color = colors[i]
        # Check if within tolerance
        diff = np.abs(img_flat - color)
        mask = np.max(diff, axis=1) <= tolerance
        
        # Or if nearest policy, find the actual nearest
    
    if policy == 'nearest':
        # Find nearest L2 distance
        # To avoid massive memory for large images, iterate
        chunk_size = 100000
        for i in range(0, len(img_flat), chunk_size):
            chunk = img_flat[i:i+chunk_size]
            # dists: (chunk_size, N)
            dists = np.sum((chunk[:, np.newaxis, :] - colors[np.newaxis, :, :])**2, axis=2)
            best_idx = np.argmin(dists, axis=1)
            min_dists = np.min(dists, axis=1)
            
            # Unmatched if min_dist is completely wild? For 'nearest', we just assign.
            # But the spec says "within tolerance" for nearest too? "Snap each source pixel to the nearest authoring_color within match.per_channel_tolerance; honor unmatched_pixel_policy."
            # So if nearest is > tolerance, apply policy.
            best_colors = colors[best_idx]
            diff_from_best = np.abs(chunk - best_colors)
            out_of_tol = np.max(diff_from_best, axis=1) > tolerance
            
            if out_of_tol.any():
                unmatched_count += np.sum(out_of_tol)
                
            chunk_out = best_colors.copy()
            if policy == 'error' and out_of_tol.any():
                raise ValueError("Found pixels outside tolerance with policy=error")
            elif policy == 'empty':
                empty_color = np.array(hex_to_bgr(CLASSES[0]['authoring_color']))
                chunk_out[out_of_tol] = empty_color
            
            out_img.reshape(-1, 3)[i:i+chunk_size] = chunk_out
            
    elif policy == 'error':
        # Same as nearest but strict
        chunk_size = 100000
        for i in range(0, len(img_flat), chunk_size):
            chunk = img_flat[i:i+chunk_size]
            dists = np.sum((chunk[:, np.newaxis, :] - colors[np.newaxis, :, :])**2, axis=2)
            best_idx = np.argmin(dists, axis=1)
            
            best_colors = colors[best_idx]
            diff_from_best = np.abs(chunk - best_colors)
            out_of_tol = np.max(diff_from_best, axis=1) > tolerance
            
            if out_of_tol.any():
                raise ValueError("Found pixels outside tolerance with policy=error")
                
            out_img.reshape(-1, 3)[i:i+chunk_size] = best_colors
    else: # empty
        chunk_size = 100000
        empty_color = np.array(hex_to_bgr(CLASSES[0]['authoring_color']))
        for i in range(0, len(img_flat), chunk_size):
            chunk = img_flat[i:i+chunk_size]
            dists = np.sum((chunk[:, np.newaxis, :] - colors[np.newaxis, :, :])**2, axis=2)
            best_idx = np.argmin(dists, axis=1)
            
            best_colors = colors[best_idx]
            diff_from_best = np.abs(chunk - best_colors)
            out_of_tol = np.max(diff_from_best, axis=1) > tolerance
            
            chunk_out = best_colors.copy()
            chunk_out[out_of_tol] = empty_color
            out_img.reshape(-1, 3)[i:i+chunk_size] = chunk_out

    if unmatched_count > 0:
        print(f"Warning: {unmatched_count} pixels were outside tolerance.")

    cv2.imwrite(out_path, out_img)
    print(f"Saved {out_path}")

def main():
    parser = argparse.ArgumentParser(description="Arena Compiler")
    parser.add_argument('--in', dest='input', required=True, help='Source image path')
    parser.add_argument('--out', dest='output', required=True, help='Output semantic map path')
    parser.add_argument('--policy', choices=['nearest', 'error', 'empty'], default='nearest', help='Unmatched pixel policy')
    parser.add_argument('--tolerance', type=int, default=32, help='Per-channel tolerance')
    
    args = parser.parse_args()
    compile_map(args.input, args.output, args.policy, args.tolerance)

if __name__ == '__main__':
    main()
