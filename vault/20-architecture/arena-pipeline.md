# Arena Pipeline (the actual invention)

This is the translation layer that makes KE_ArKade more than a projection-game
launcher. Owner lane: **Codex** (Python + OpenCV, headless, unit-tested).

```
Physical space
   ↓  (paint with brush / draw in tool / photograph a painted canvas)
Source image
   ↓  Arena Compiler  (snap pixels -> palette v1 classes)
Semantic map  (indexed, canonical "meaning of space")
   ↓  Derived-layer generators
occupancy.png · navgraph.json · platform_edges.json
   ↓  Calibration transform (arena-space -> projector-space)
Projector output  +  Game adapters read the SAME map
```

The point: **author the meaning of the space once; many games read it.**

## Stage 1 — Arena Compiler

Input: a painted/drawn/photographed source image of the arena.
Output: a clean indexed `semantic_map.png` conforming to palette v1.

- Snap each source pixel to the nearest `authoring_color` within tolerance
  (palette v1 `match.per_channel_tolerance`). Apply `unmatched_pixel_policy`.
- Provide authoring helpers: threshold, posterize, flood-fill, palette-assign
  (so an operator can convert a photo or a rough paint-up into clean classes).
- Validate: fail loudly on ambiguous/unmatched pixels when policy=error.

## Stage 2 — Derived layers (no CV at play time)

Bake everything a game needs into static files so the runtime never runs CV:
- **occupancy.png** — binary walkable/blocked from `solid`/`path`.
- **navgraph.json** — skeletonized graph from `path` (junctions, edges). The
  layer **Lumen Maze** (Pac-Man-like) consumes.
- **container.json** — the well/boundary derived from the `solid` region: the
  bounding play-field shape (possibly non-rectangular) + a spawn lip. The layer
  **Neon Stack** (Tetris-like) consumes — pieces fall toward wall-down inside
  this shape. This is how two dissimilar games read ONE map differently.
- **platform_edges.json** — top-edge extraction for future platformers
  (meaningful only on gravity-relevant `wall` scenes). Interface only for MVP.
- **track_centerline.json** — single-line vector trace for **Trace** (racing,
  Phase 2): skeletonize a hand-drawn/traced line into a lap with checkpoints.
- **grid.json** — *v1.1 additive, ratified 2026-06-19.* A discrete cell matrix
  (2D array of class IDs) at `procedural.grid.cell_px` resolution, majority-voted
  from the semantic map. This is the natural substrate for 8-bit/cell games
  (maze, falling-block) — they consume `grid.json` instead of rasterizing the
  vector layers themselves. **Vector layers (`navgraph`/`container`) remain the
  truth for projection alignment; `grid` is a baked convenience derived from the
  same map.** A cartridge may override `cell_px`. Compiler-side, golden-tested,
  zero runtime CV — consistent with the rest of the pipeline.

Each derived generator is a pure function: same map in => same bytes out. That
makes them golden-image testable (QA lane).

## Stage 3 — Calibration (arena-space ↔ projector-space)

Strict placement hierarchy: **optical placement first, software mapping second,
in-projector keystone last.** Calibration roadmap:
1. **Manual 4-point homography** — MVP. Operator drags 4 corners; OpenCV
   `getPerspectiveTransform` / `findHomography`. Saves to `calibration/current.yaml`.
2. **Camera-assisted ChArUco** — Phase 2. Sub-pixel auto-align via a printed
   board. Wizard with preview + save-confirm + per-scene history.
3. **Structured light** — late R&D, only if multi-projector/non-planar demands it.

## Authoring is part of this pipeline

The semantic map can be produced by the compiler OR by the level-authoring tool
(slider mode = derive zones from a photo; paint mode = paint over a photo with
an opacity toggle). Same output, same downstream derive step. See
`level-authoring.md`. Awkward auto-derived results are acceptable and fun.

## The MVP proof (wall-first)

The thesis is NOT "a game can read a map." It is "**dissimilar games adapt to
one untouched map with zero re-authoring.**" MVP = **two structurally different
cartridges off the same `semantic_map.png` on a WALL scene**: Lumen Maze reads
`path` as a nav graph; Neon Stack reads `solid` as a falling-block well. One game
proves nothing; two is the smallest honest test. Wall first because it's the
easiest to test (vertical screens + a wall + a projector); floor/trackers are
deliberately deferred so they don't tax the MVP.
