import os
import yaml
from PIL import Image, ImageDraw

def create_dir(path):
    os.makedirs(path, exist_ok=True)

def write_yaml(path, data):
    with open(path, 'w') as f:
        yaml.dump(data, f, sort_keys=False)

def generate_map(path):
    img = Image.new('RGB', (800, 600), color=(0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw solid border (imperfect)
    draw.rectangle([10, 10, 790, 590], outline=(255, 255, 255), width=20)
    
    # Draw solid blocks
    draw.rectangle([100, 100, 200, 200], fill=(255, 255, 255))
    draw.rectangle([300, 300, 500, 400], fill=(255, 255, 255))
    
    # Draw paths
    draw.rectangle([50, 50, 750, 80], fill=(128, 128, 128))
    draw.rectangle([210, 100, 290, 500], fill=(128, 128, 128))
    
    # Draw spawns
    draw.ellipse([60, 60, 75, 75], fill=(0, 200, 83))
    
    # Draw goals
    draw.rectangle([700, 60, 720, 80], fill=(255, 0, 255))
    
    # Draw pickups
    draw.ellipse([230, 200, 245, 215], fill=(255, 224, 0))
    draw.ellipse([230, 300, 245, 315], fill=(255, 224, 0))
    draw.ellipse([230, 400, 245, 415], fill=(255, 224, 0))
    
    img.save(path)

def main():
    base_dir = "content"
    
    # Scene
    scene_dir = os.path.join(base_dir, "scenes", "scene_demo_wall")
    create_dir(scene_dir)
    
    # create dummy calib file
    create_dir(os.path.join(scene_dir, "calibration"))
    with open(os.path.join(scene_dir, "calibration", "current.yaml"), "w") as f:
        f.write("dummy: calibration")

    scene_data = {
        "schema": "scene",
        "version": "1.0.0",
        "status": "verified",
        "scene_id": "scene_demo_wall",
        "venue_name": "Demo Wall Studio",
        "orientation": "wall",
        "output_profile": {
            "native_resolution": [1920, 1080]
        },
        "current_calibration": {
            "file": "calibration/current.yaml"
        },
        "controller_profile": {
            "max_players": 4
        }
    }
    write_yaml(os.path.join(scene_dir, "scene.yaml"), scene_data)
    
    # Level
    level_dir = os.path.join(scene_dir, "levels", "demo_level")
    create_dir(level_dir)
    
    level_data = {
        "schema": "level",
        "version": "1.0.0",
        "status": "playable",
        "level_id": "demo_level",
        "scene_id": "scene_demo_wall",
        "semantic_map": "semantic_map.png",
        "palette_schema": "../../../../vault/50-schemas/semantic-palette-v1.yaml"
    }
    write_yaml(os.path.join(level_dir, "level.yaml"), level_data)
    
    # Map
    generate_map(os.path.join(level_dir, "semantic_map.png"))
    
    # Cartridges
    maze_dir = os.path.join(base_dir, "cartridges", "pacman")
    create_dir(maze_dir)
    maze_data = {
        "schema": "cartridge",
        "version": "1.0.0",
        "cartridge_id": "pacman",
        "game_name": "Lumen Maze",
        "engine": "godot",
        "process_model": "separate_process",
        "entry": {"launch": "godot"},
        "requires": {"orientation": ["wall"]}
    }
    write_yaml(os.path.join(maze_dir, "manifest.yaml"), maze_data)
    
    block_dir = os.path.join(base_dir, "cartridges", "tetris")
    create_dir(block_dir)
    block_data = {
        "schema": "cartridge",
        "version": "1.0.0",
        "cartridge_id": "tetris",
        "game_name": "Neon Stack",
        "engine": "godot",
        "process_model": "separate_process",
        "entry": {"launch": "godot"},
        "requires": {"orientation": ["wall"]}
    }
    write_yaml(os.path.join(block_dir, "manifest.yaml"), block_data)

if __name__ == "__main__":
    main()
