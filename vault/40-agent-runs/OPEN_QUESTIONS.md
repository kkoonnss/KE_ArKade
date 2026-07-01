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

## Post-corruption governance (added 2026-06-30 by orchestrator)
- [x] **Governance pack written** — `_Briefs/governance/00_README.md` + 7 supporting docs. Every agent on cold start reads `01_LANES`, `02_VERIFICATION_GATES`, `03_RECOVERY_PROTOCOL`, `04_AGENT_HANDOFF_TEMPLATE`. Orchestrators also read `05_ORCHESTRATOR_RUNBOOK`, `06_VAULT_HYGIENE`, `07_GIT_GOVERNANCE`.
- [x] **Recovery receipt reconstructed** — `vault/40-agent-runs/recovery_hub_main_gd_2026-06-28.md` captures the Jun 28-30 corruption + 3-day rebuild that wrote no receipt at the time.
- [ ] **Pacman / Tetris / Donkey Kong SharedLoader gap** — HANDOFF.md claimed these were "gate-clean" but grep shows 0 SharedLoader hits in each cart folder. They predate INT-05 and read maps with their own bespoke logic. They should be folded into the Wave-3 SharedLoader retrofit batch (same posture as galaga / frogger / on_track). Not blocking the cascade.
- [ ] **INT-08 / INT-09 status drift** — tickets still mark `in_progress` but `_Briefs/HANDOFF.md` and chat suggest both shipped. Verify via Design-screen save → confirm `derived/grid.json` is written + preset dropdown restored. Flip status only after verification.
- [x] **Hub post-corruption regression** — RESOLVED 2026-06-30. AG hotfix `c487a70` (init scroll_vbox + reset grid visibility per tab switch) landed; Kons confirmed tabs load and thumbnails/favorites render in the live hub. Receipt flipped to `done`: `reconstructed_antigravity_hub_thumbnails_favorites_2026-06-30.md`. Minor layout polish deferred to Wave 3 (non-blocking).
- [ ] **GitHub backup integration in progress** — a Codex agent is solving for remote git + versioning. Output should refine `_Briefs/governance/07_GIT_GOVERNANCE.md` once landed (cadence, branch protection, recovery story).
- [ ] **Cleanup script issued** — `_Briefs/governance/scripts/cleanup_2026-06-30.cmd` hard-deletes 8 stale lock files (their tickets are `done`) and moves the ~100 throwaway recovery scripts at repo root into `scratch/recovery-2026-06-28/`. Kons runs it; bash sandbox lacks delete permission so the orchestrator could not execute it directly.
- [ ] **Binaries at repo root** — `Godot_v4.3-stable_win64.exe` (133 MB), `godot.zip` (57 MB), and the console exe should move to a documented install step rather than living in git history. Open follow-on for the GitHub-integration agent.
