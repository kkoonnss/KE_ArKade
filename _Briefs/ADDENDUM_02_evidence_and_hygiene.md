# ADDENDUM 02 — Evidence refresh + test hygiene (small)

**You are the executing fleet (Antigravity by capacity; agent-agnostic).** Quick
follow-up to close Addendum 01. The substance is verified-good; these three
items just make the evidence trustworthy and the tests reproducible. Small streak.

## 1. Regenerate verification evidence (the current screenshots are stale)
The screenshots in `vault/70-qa/` predate the IP rename — the live cartridge
picker in them still reads "Tetris / Bomberman / Pac-Man," and `lumen_maze_run.png`
is actually a hub-picker shot, not gameplay. Replace them with fresh captures that
reflect the cleaned build:
- Hub cartridge picker showing the **homage names** (Lumen Maze, Neon Stack, …).
- **Actual gameplay** of Lumen Maze and of Neon Stack, each running off the seed map.
- One capture of a cartridge kill → hub auto-restore, and one of Panic Black → recover.
Update `vault/80-builds/BUILD_REPORT.md` to point at the new files and confirm the
done-criteria with real evidence.

## 2. Test hygiene
`app/tools/tests/` writes temp outputs (`out_*.json` / `out_*.png`) directly into
the tests folder and deletes them on teardown — which fails on restricted
filesystems. Point the tests at a `tempfile.TemporaryDirectory()` instead, and
**sweep the stray `out_container.json`, `out_grid.json`, `out_navgraph.json`,
`out_semantic.png`** currently sitting in `app/tools/tests/` (left by an
orchestrator verification run that couldn't delete them). Add an `out_*` ignore
rule so they can't be committed.

## 3. Record the dependency
`arena_compiler/derive/navgraph.py` imports `scikit-image` (skeletonize). Add
`scikit-image` (and any other runtime deps: `opencv-python`, `numpy`, `pyyaml`)
to `app/tools/requirements.txt` so the environment is reproducible.

## Done = updated BUILD_REPORT with fresh evidence + green tests from a clean checkout.
Then signal for Opus review. No new features, no schema changes.
