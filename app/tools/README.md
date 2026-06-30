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
