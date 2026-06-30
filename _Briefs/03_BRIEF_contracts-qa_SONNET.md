# BRIEF — Contracts, Codegen & QA  →  COWORK/SONNET (under Opus)

**You own:** `vault/**`, `app/shared/**`, and seed data in `content/**`. You are
the integrator/glue lane and the only lane (besides Opus) that reads everything.
You still do not silently edit frozen schemas — schema changes are proposed to
Opus, who owns the freeze.

**Read first:** all of `vault/50-schemas/**`, `_Briefs/00_MASTER_PLAN.md`,
`_Briefs/INTEGRATION_CONTRACT.md`.

---

## Scope (Phase 1 / MVP)

### A. `app/shared/` codegen (the shared truth, as code)
Generate, from the frozen YAML schemas, the constants both other fleets import:
- Palette class IDs + `authoring_color` + `ui_color` as **both** a Python module
  (`app/shared/palette.py`) and a GDScript const (`app/shared/palette.gd`).
- Keep them generated (a small `app/shared/gen.py` that reads
  `semantic-palette-v1.yaml`), so the numbers can never drift between hub and
  compiler. Re-run on any schema bump.

### B. Schema validators — `app/shared/validate/`
- Validators for `scene.yaml`, `level.yaml`, `manifest.yaml` against the v1
  schemas (orientation enum, resolution ints, players 1–4, required fields,
  semantic-class references). Usable in CI and by both fleets.

### C. Golden-image QA harness — `vault/70-qa/`
- A runner that re-derives `navgraph`/`occupancy` from fixture maps and diffs
  against committed goldens (works with Codex's outputs).
- The **venue acceptance script** (power-cycle → restore → optical check →
  launch 3 cartridges → Panic Black → restore) as a checklist note.
- Performance-budget note for Profile L (and a placeholder for Profile P).

### D. Seed content — `content/scenes/`
- One **wall** scene `content/scenes/scene_demo_wall/scene.yaml` (verified-stub).
- One painted level with a hand-made `semantic_map.png` containing `solid`,
  `path`, `spawn`, `pickup`, `goal` — the SINGLE shared map both MVP games read
  (Lumen Maze via `navgraph`, Neon Stack via `container`). Make it deliberately
  imperfect so the "awkward but fun" interpretation is visible.
- Stub `manifest.yaml` for the two MVP cartridges (`pacman` = Lumen Maze,
  `tetris` = Neon Stack) per cartridge-schema-v1.

### E. Design brief upkeep — `vault/20-architecture/design-brief.md`
Maintain the design brief (already drafted) as the shared visual reference. Keep
the palette `ui_color`s in sync with `semantic-palette-v1.yaml` via codegen.
Propose changes via task note; do not redefine brand direction unilaterally.

### F. Vault upkeep
- Maintain `vault/30-tasks/` task notes + `vault/60-bases/tasks.base`.
- Keep `vault/40-agent-runs/` and `vault/70-qa/` current as fleets report.

## Acceptance criteria
- `app/shared/palette.py` and `palette.gd` are byte-derivable from the YAML and
  agree on every class ID + color.
- Validators reject a deliberately broken scene/level/manifest and accept the
  seed content.
- Golden harness passes against Codex's `navgraph` + `container` for the seed map.
- Seed **wall** scene + one shared level + two stub manifests exist and validate.

## Do NOT
- Do not edit frozen schema *meanings* without Opus sign-off (propose via task note).
- Do not write game logic (cartridges) or hub UI or CV algorithms.
- Do not let `app/shared/` be hand-edited — it is generated.

## Deliverables
`app/shared/` (codegen + validators), `vault/70-qa/` harness + scripts, seed
`content/`, maintained task/run/qa notes. This lane is also responsible for
flagging seam drift between Codex and Antigravity to Opus early.
