# OPEN QUESTIONS — parked decisions (don't block on these)

The self-orchestration loop logs anything needing a Kons/Opus call here, then
pulls the next ticket. Opus reviews on return.

## Stage 6 — Interpretation + Editor (seeded by PLAN_interpretation-and-editor.md)

- [ ] **Archetype assignments** — confirm the 7-family mapping (PLAN §3), esp. the
  judgment calls: `marble_madness`→Maze (vs Track), `pong`→Well/Fill (vs its own
  versus type), `joust`/`tempest`→Arena, `bubble_bobble`→Platform (vs Maze),
  `centipede`→Well/Fill (vs Arena). Adapters work either way; this only affects
  which one each game pulls.
- [ ] **Editor live-preview depth (Wave 0)** — wire all 7 archetype previews into
  the Design screen up front, or just the 4 reference families (maze/well/arena/
  lane) first and add the rest as their adapters land?
- [ ] **Wave 3 polish ordering** — which games are likeliest "venue hits" (4
  controllers out, social) and deserve first final-tweak? Candidates: Pac-Man,
  Bomberman, Tetris (4p), Frogger.
- [ ] **Raspberry Pi target** — design is Pi-portable now (controller-complete UI,
  swappable Python/OpenCV backend). Confirm we still DEFER Pi performance tuning
  to Phase 3 and don't let it tax this build.
- [ ] **Adapter-contract freeze** — after TASK-INT-01/02 close, lock `app/shared/**`
  adapters like the schemas (changes route through Opus). Confirm the freeze.

## Stage 6 — integration seam (added 2026-06-26)
- [ ] CARTRIDGES ARE SEPARATE GODOT PROJECTS -> app/shared global class_name does NOT resolve inside them. Standard being set in TASK-INT-05 (SharedLoader). Until done, NO cartridge cascade.
- [ ] galaga / frogger / on_track are functional but each copied adapter_base.gd locally + rewrite `extends`. After TASK-INT-05, drop the local copies and adopt SharedLoader (small cleanup pass each).
