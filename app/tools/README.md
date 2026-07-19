# KE_ArKade Tools

This directory contains the compiler and level authoring tools for KE_ArKade.

## Arena Compiler
`app/tools/arena_compiler/compiler.py`
Converts a painted/photographed source image into a clean indexed `semantic_map.png` conforming to palette v1.

Usage:
`python app/tools/arena_compiler/compiler.py --in source.png --out semantic_map.png --policy nearest`

## Derived Layers
Generators for runtime layers needed by cartridges:
- `occupancy.py`: Walkable/blocked mask
- `navgraph.py`: Skeletonized graph from path for Lumen Maze
- `container.py`: Well boundary from solid for Neon Stack
- `platform_edges.py` / `track_centerline.py`: Stubs for future games

Usage:
`python app/tools/arena_compiler/derive/navgraph.py in_map.png out_navgraph.json`

## Level Authoring
`app/tools/level_authoring/author.py`
Lightweight GUI for slider-based and paint-over-photo level authoring.
Run without arguments to open the GUI.

## Calibration
`app/tools/calibration/calibrate.py`
Manual 4-point homography calibration.
Usage:
`python app/tools/calibration/calibrate.py <source_image> <scene_dir>`

`app/tools/calibration/profile.py`
Create and validate reusable output-mapping profiles. Profiles are the planned
contract for final-frame projector warping: a neutral `2x2` mesh is global
corner pinning, while `3x3` or denser meshes add local refinement pins.

Recommended workflow:
- Calibrate against the live wall and save as a named preset.
- Assign the preset to the active scene by copying or exporting it to
  `content/scenes/<scene_id>/calibration/current.yaml`.
- Keep level/game tuning separate; calibration belongs to the output location,
  not to an individual cartridge or level.

Usage:
`python app/tools/calibration/profile.py new content/scenes/scene_demo_wall/calibration/current.yaml --profile-id studio_wall --label "Studio Wall" --mesh 2x2 --scene-id scene_demo_wall`
`python app/tools/calibration/profile.py validate content/scenes/scene_demo_wall/calibration/current.yaml`
