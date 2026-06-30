import cv2
import numpy as np
import os
import sys

# Ensure palette and compiler are in path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
from app.shared.palette import CLASSES
import app.tools.arena_compiler.compiler as comp
import app.tools.arena_compiler.derive.navgraph as nav
import app.tools.arena_compiler.derive.container as cont

def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (4, 2, 0))

def make_fixtures():
    base_dir = os.path.dirname(__file__)
    goldens_dir = os.path.join(base_dir, 'goldens')
    os.makedirs(goldens_dir, exist_ok=True)
    
    # Create test_source.png
    # 100x100
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    
    # fill with empty
    empty_color = hex_to_bgr(CLASSES[0]['authoring_color'])
    img[:] = empty_color
    
    # draw some solid
    solid_color = hex_to_bgr(CLASSES[1]['authoring_color'])
    # Draw a well-like structure (Neon Stack)
    cv2.rectangle(img, (10, 10), (20, 90), solid_color, -1)
    cv2.rectangle(img, (10, 80), (90, 90), solid_color, -1)
    cv2.rectangle(img, (80, 10), (90, 90), solid_color, -1)
    
    # draw some path (Lumen Maze)
    path_color = hex_to_bgr(CLASSES[2]['authoring_color'])
    cv2.line(img, (50, 20), (50, 70), path_color, 3)
    cv2.line(img, (30, 45), (70, 45), path_color, 3)
    
    # Add noise so it's not EXACTLY the authoring color but within tolerance
    noise = np.random.randint(-10, 10, img.shape, dtype=np.int16)
    noisy_img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    
    source_path = os.path.join(goldens_dir, 'test_source.png')
    cv2.imwrite(source_path, noisy_img)
    
    # Generate golden semantic map
    semantic_path = os.path.join(goldens_dir, 'golden_semantic_map.png')
    comp.compile_map(source_path, semantic_path, policy='nearest', tolerance=32)
    
    # Generate golden derived layers
    navgraph_path = os.path.join(goldens_dir, 'golden_navgraph.json')
    nav.extract_navgraph(semantic_path, navgraph_path)
    
    container_path = os.path.join(goldens_dir, 'golden_container.json')
    cont.extract_container(semantic_path, container_path)

    import app.tools.arena_compiler.derive.grid as grid
    grid_path = os.path.join(goldens_dir, 'golden_grid.json')
    grid.generate_grid(semantic_path, grid_path, cell_px=32)
    
    print("Goldens created successfully.")

if __name__ == '__main__':
    make_fixtures()
