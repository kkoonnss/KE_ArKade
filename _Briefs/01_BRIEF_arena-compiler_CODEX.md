# BRIEF — Arena Compiler & CV  →  CODEX fleet

**You own:** `app/tools/**` only. Language: Python 3 + OpenCV + NumPy.
Everything you build is **headless and unit-testable** (no GUI required for the
core; a thin CLI/preview is fine). Read-only inputs: `vault/50-schemas/**`,
`app/shared/**`. Do not write outside `app/tools/**`.

**Read first, in order:** `_Briefs/00_MASTER_PLAN.md` (context) →
`_Briefs/INTEGRATION_CONTRACT.md` (the rules/seams) →
`vault/50-schemas/semantic-palette-v1.yaml` (the vocabulary) →
`vault/20-architecture/arena-pipeline.md` and `vault/20-architecture/level-authoring.md`.

**MVP target:** wall scene, Profile L. The two MVP games read the SAME untouched
map two different ways — your derived layers are what make that work:
Lumen Maze (Pac-Man-like) consumes `navgraph`; Neon Stack (Tetris-like) consumes
`container`. Awkward auto-derived results are acceptable and expected.

---

## Scope (Phase 1 / MVP)

### A. Arena Compiler — `app/tools/arena_compiler/`
Convert a painted/drawn/photographed source image into a clean indexed
`semantic_map.png` conforming to palette v1.
- Snap each source pixel to the nearest `authoring_color` within
  `match.per_channel_tolerance`; honor `unmatched_pixel_policy`.
- Authoring helpers (CLI flags or functions): `threshold`, `posterize`,
  `flood-fill`, `assign-palette`.
- Validation: report unmatched/ambiguous pixels; fail loudly under `policy=error`.
- CLI: `compile --in source.png --out semantic_map.png [--policy nearest|error]`.

### B. Derived-layer generators — `app/tools/arena_compiler/derive/`
Pure functions (same map in → identical bytes out, so they're golden-testable):
- `occupancy.png` — binary walkable/blocked from `solid` + `path`.
- `navgraph.json` — skeletonized graph from `path` (nodes=junctions,
  edges=corridors). **Lumen Maze** consumes this. REQUIRED for MVP.
- `container.json` — the well/boundary from the `solid` region: bounding
  play-field shape (may be non-rectangular) + spawn lip + a "down" direction
  for wall scenes. **Neon Stack** consumes this. REQUIRED for MVP.
- `platform_edges.json` — top-edge extraction for future platformers. Interface
  only for MVP (stub fine).
- `track_centerline.json` — single-line vector trace → lap + checkpoints for
  **Trace** (racing). Phase 2, interface only for MVP.

### C. Level-authoring tool — `app/tools/level_authoring/`
Make level design intuitive and fun (see `level-authoring.md`):
- **Slider mode:** load a photo ref; live sliders (threshold, posterize,
  hue-bands, edge-detect) drive the compiler to auto-derive semantic zones.
- **Paint mode:** paint palette `authoring_color`s over the photo ref with an
  **opacity slider**; toggle the reference off for play.
- Output is a clean palette-v1 `semantic_map.png` + `level.yaml` — identical to
  the compiler's output. A lightweight standalone GUI (Python) is fine for MVP.

### D. Manual 4-point calibration — `app/tools/calibration/`
- Operator supplies 4 source corners + 4 target corners; compute homography via
  OpenCV `getPerspectiveTransform` / `findHomography`.
- Save to the scene's `calibration/current.yaml` (per scene-schema-v1).
- Produce a before/after preview image. Save must be non-destructive
  (write temp, confirm, swap). ChArUco is **Phase 2 — do not build now.**

## Acceptance criteria
- `compile` produces a palette-valid `semantic_map.png` from a hand-painted test
  image; round-trips with zero unmatched pixels under tolerance.
- `navgraph.json` AND `container.json` from a known test map each match committed
  golden files (byte-stable across runs).
- Level-authoring tool: slider mode + paint mode + reference-opacity toggle both
  produce a valid map from a photo ref.
- 4-point calibration writes a valid `current.yaml` and a correct warped preview.
- Unit tests + at least 3 golden-image fixtures live under `app/tools/tests/`.
- A short `app/tools/README.md` documents the CLI + authoring tool.

## Do NOT
- Do not edit any schema in `vault/50-schemas/` — request changes via a task note.
- Do not build UI for the hub (that's Antigravity) or game logic (cartridges).
- Do not run CV at game time — bake everything into `derived/**` files.
- Do not write outside `app/tools/**`.

## Deliverables
`app/tools/arena_compiler/`, `app/tools/calibration/`, tests + goldens, README.
Finish each task with a QA note in `vault/70-qa/` and a run log in
`vault/40-agent-runs/`.
