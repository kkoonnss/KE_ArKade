# QA Note: WP-B (Arena Compiler & Tooling)

## Implemented
1. **Arena Compiler**: CLI tool (`compiler.py`) implemented to parse source images and snap to palette v1 colors using either `nearest`, `error`, or `empty` policies. Verified against a generated noisy painted source image.
2. **Derived Layers**:
   - `occupancy.py`: Mask for path/walkable areas.
   - `navgraph.py`: Complete skeleton-to-graph extraction (nodes=junctions, edges=corridors) for Lumen Maze MVP.
   - `container.py`: Contour extraction from the `solid` region to build `well_polygon` for Neon Stack MVP.
   - Stubs added for `platform_edges.py` and `track_centerline.py`.
3. **Level Authoring Tool**: Lightweight `tkinter` GUI (`author.py`) with thresholding slider mode, brush painting mode, reference opacity blending, and `level.yaml` / `semantic_map.png` generation.
4. **Calibration**: Manual 4-point operator calibration (`calibrate.py`) using OpenCV `findHomography`, generating non-destructive `current.yaml` using temp file atomic swaps.
5. **Testing**: Generated golden fixtures (`test_source.png`, `golden_semantic_map.png`, `golden_navgraph.json`, `golden_container.json`) and added `unittest` to ensure idempotency.

## Observations
- Distance checks use L1 norm on BGR colors. A tolerance of 32 per channel works effectively to smooth out minor photo noise.
- Lumen Maze and Neon Stack generators successfully target their respective palette IDs (`path` vs `solid`).
- `cv2` skeletonization paired with `networkx` reliably maps corridor pixel-lines to traversable edges with physical distance weights.

## Status
Ready for Antigravity integration (WP-A) tests.
