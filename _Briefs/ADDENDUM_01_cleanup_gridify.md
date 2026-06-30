# ADDENDUM 01 — Cleanup, Gridify & Real Verification

**You are the executing fleet (Antigravity by current capacity; agent-agnostic).**
The first streak was strong — all packages delivered, two games read one map. This
addendum gets us *conformant* and *verified* before we call the MVP done, and adds
the gridification you escalated. Do it in one streak with parallel sub-agents,
honoring folder ownership. **No new games** — the three stubs stay stubs.

**Read first:** `_Briefs/INTEGRATION_CONTRACT.md`, `vault/50-schemas/level-schema-v1.yaml`,
`vault/20-architecture/arena-pipeline.md` (grid.json section).

---

## Punch list

### 1. Make the authored level schema-conformant
`content/scenes/scene_demo_wall/levels/demo_level/level.yaml` currently has
`id: levels`, `map_file:` (should be `semantic_map:`), and is missing `level_id`,
`scene_id`, `palette_schema`, `status`. Fix it to match `level-schema-v1`, AND
fix the authoring tool (`app/tools/level_authoring/author.py`) so every level it
emits is schema-conformant by construction. Run the validators against it and
make a failing level a hard error.

### 2. Clean the derived/ nesting
That level has a doubly-nested `derived/derived/` plus stray copies of
`level.yaml` / `semantic_map.png` / `background.png` sitting inside `derived/`.
`derived/` must contain ONLY generated layers. Remove the duplicates and the
nested folder, and make the hub's level-scanner explicitly ignore `derived/` so
it can never be mistaken for a level.

### 3. De-duplicate app/shared
`app/shared/**` and `app/hub/shared/**` are duplicated and can silently drift.
Keep `app/shared/` as the single generated source of truth. Have `gen.py`
**emit** the Godot copy (`palette.gd` into the hub project) as a build step, so
the in-engine copy is generated, never hand-maintained. Document the one command.

### 4. Gridification — add the `grid.json` derived layer (ratified)
Per `arena-pipeline.md`: compiler bakes a discrete cell matrix (2D array of class
IDs) at `procedural.grid.cell_px` (default 32), majority-voted from the semantic
map. Golden-test it. Wire **Lumen Maze** and **Neon Stack** to consume
`grid.json` where it simplifies them. **Keep `navgraph`/`container` as the
alignment truth** — grid is an added convenience, not a replacement. Allow a
per-cartridge `cell_px` override.

### 5. IP-name hygiene
User-facing names (UI labels, manifests, reports) use the original homage names
(Lumen Maze, Neon Stack, etc.) — never Pac-Man/Tetris/Frogger/Bomberman.

### 6. REAL verification (not self-claimed)
Actually run it and capture evidence:
- Launch the hub in Godot; launch **both** games off the seed map — screenshot each.
- Kill a running cartridge process mid-game → confirm hub survives + restores (capture log).
- Trigger Panic Black mid-game → confirm instant blank + recover.
- Run `app/tools/tests` (pytest) incl. the new `grid` golden → green.
- Note FPS on Profile L.

## Handoff
Update `vault/80-builds/BUILD_REPORT.md` with **real** pass/fail per criterion +
screenshot/log paths (replace self-claimed "Pass" with evidence). Run logs in
`vault/40-agent-runs/`, QA in `vault/70-qa/`. Then signal ready for Opus review.

## Coordination note (visual track runs in parallel)
A separate visual-direction pass is happening in Claude Design (see
`DESIGN_PILOT.md`). **Do the game re-skin LATER**, once a locked design-system
lands in the repo — don't invest in game art now beyond what gridification needs.
Hub structure/layout is fine to keep; final skinning waits for the design lock.
