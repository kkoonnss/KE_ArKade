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

## 2026-07-01 additions (Kons + orchestrator, morning-of session)

- [x] **Launch chain fully unblocked** — hub can now spawn cart Godot processes end-to-end. Root cause was the `res://../../../app/shared/shared_loader.gd` preload anti-pattern across 31 carts (fixed in commit `52a4081`), NOT the hub launch args (though those fixes remain valid improvements). Retrospective receipt at `vault/40-agent-runs/reconstructed_cartridge_sharedloader_preload_fix_2026-07-01.md`.
- [ ] **Semantic maps for 25 classic levels — Kons is generating them now.** Of the 32 `classic_<game>` levels in `scene_classic_pack/levels/`, only 7 have a `semantic_map.png` (bomberman, frogger, gta, on_track, pacman, rampage, tetris). Kons is actively converting the other 25 from their "figured-out working" levels into proper semantic maps. Build process should not treat missing semantic_map.png as fatal — carts should render gracefully (empty level + procedural fallback per the adapter contract) while this content work continues.
- [ ] **Hub classic-routing was hardcoded to 9 games only.** Ticket `TASK-INT-hub-classic-routing-data-driven` dispatched to AG — replaces the hardcoded array with a `DirAccess.dir_exists_absolute(classic_<id>)` check so all 32 carts (and future carts) route to their classic level automatically.
- [ ] **Cart-side rendering + gameplay bugs surfaced after launch chain unblocked.** Symptoms: pacman renders as blue blob + instant WIN. Tetris opens but blacks out. Others "die instantly." These are per-cart Wave-3 polish tickets, tracked individually. First one is `TASK-INT-cart-pacman-map-render-and-win` (with debug instrumentation to reveal actual data flow).
- [ ] **GitHub remote not yet configured.** `git remote -v` is empty. Backup relies entirely on local `.git`. Codex was assigned this work — reopen as a P1 ticket if it doesn't land in the next 48h. Governance-defined pattern in `_Briefs/governance/07_GIT_GOVERNANCE.md` §7.
- [ ] **Daily / weekly tag cadence not automated.** Orchestrator has been tagging manually via cleanup scripts. Consider a scheduled task or a git hook that tags `daily/<YYYY-MM-DD>` on the first commit of the day. Currently: only `daily/2026-06-30` exists; `daily/2026-07-01` and `week/2026-W27` will be added by `_Briefs/governance/scripts/backup_audit_2026-07-01.cmd` when Kons runs it.
- [ ] **Working tree has ~60 uncommitted files** as of 2026-07-01 morning. Backup audit script commits them under a single governance snapshot so nothing is lost if the machine crashes. Going forward: commit-per-ticket-close per `_Briefs/governance/07_GIT_GOVERNANCE.md` §2.2 (the discipline is not sticking; needs enforcement, possibly a pre-commit hook).
- [ ] **The vault IS the cross-provider agent abstraction.** Confirmed with Kons 2026-07-01. Every agent (Antigravity, Codex, Sonnet, any Claude thread, any future provider) reads the same tickets from `vault/30-tasks/`, writes the same receipts to `vault/40-agent-runs/`, holds the same locks from `vault/35-locks/`. Governance pack docs `01_LANES.md` §6 + `04_AGENT_HANDOFF_TEMPLATE.md` + `06_VAULT_HYGIENE.md` codify this. No new work — just reaffirming.

## 2026-07-03 additions (claude_sonnet, hub-ticket continuation session)
- [ ] **Dirty working tree has grown past housekeeping-viable.** As of this session, `git status` shows ~155 modified files (nearly every cartridge + `app/shared/` + several vault task files) and ~20 untracked scratch files at repo root (`joypad_patch*.py`, `err.txt`, `out.txt`, `remove_bad_blocks.py`, `tetris_reconstructed.gd`, `find_enter.py`, `tetris_diff.txt`) that `07_GIT_GOVERNANCE.md` §2.3 says should never be committed. The `.gitignore` patch referenced in that doc's §4 does not appear to actually be catching these. This is the same standing item logged 2026-07-01 ("~60 uncommitted files") — it has roughly doubled+ since. Needs a dedicated `lane: tools` or `governance` housekeeping ticket: verify/apply the `.gitignore` patch, one snapshot commit for the legitimate cartridge work, `git rm` the confirmed scratch. Full detail in `vault/40-agent-runs/claude_hub_classic_routing_continuation_2026-07-03.md`.
- [ ] **TASK-INT-hub-classic-routing-data-driven picked back up.** The fix was already correct and present (uncommitted) in the live working tree from a prior Codex session that hit a usage-limit block before it could commit/verify. No new code written; ticket flipped to `pending_kons_verify`, `hub-design` lock re-claimed and held pending Kons's Godot parse check + visual confirm + the scoped commit. See the receipt above for the exact commands.

## 2026-07-03 additions (claude_opus, asteroids audit continuation)
- [x] **`level_id: levels` metadata drift confirmed.** `content/scenes/scene_demo_wall/levels/rock_wall_open_260630_004352/level.yaml` is the only `level.yaml` in the repo whose `level_id` doesn't match its own folder name (every other level, classic and demo, matches exactly). Recommended one-line fix: `level_id: levels` -> `level_id: rock_wall_open_260630_004352`. Not applied — safe for any agent/Kons to make, no lock conflict.
- [ ] **Root cause of the standing "dirty tree" item found: CRLF vs LF, not real edits.** Following up on the 2026-07-01 and 2026-07-03 (claude_sonnet) entries above — `git diff -b` (ignore-whitespace) on a spot-check sample (asteroids/main.gd, .gitattributes, battlezone/main.gd, app/shared/palette.gd) comes back empty; only `app/hub/main.gd` has real content changes (already covered by the claude_sonnet hub-routing receipt). Confirmed via hex dump: HEAD blobs are LF, working tree is CRLF. This means most of the "~145-172 modified files" is Windows line-ending noise, not uncommitted work — the housekeeping ticket already called for above should renormalize line endings (pick LF or CRLF as canonical) as part of the same pass, not just sweep scratch files. This is a repo-wide, all-lanes-at-once change -> orchestrator-only, single-threaded, per `01_LANES.md`. Full evidence + a caveat about count-drift on a live-mounted repo: `vault/40-agent-runs/claude_opus_asteroids_audit_continuation_2026-07-03.md`.
- [ ] **Asteroids `rock_wall_open_260630_004352` smoke test still outstanding.** Evidence (full `derived/` pipeline output, mtime sequence right after `rock_wall_260630_003120`, now getting Asteroids adjustments too) points to a real in-progress level, not scratch, but Codex's original recommendation to manually launch and visually confirm both `scene_demo_wall` rock_wall levels non-headless before staging the untracked `asteroids.adjustments.json` / `asteroids.secondary_map.png` pair still stands. Needs Kons on his machine.

## 2026-07-04 additions (codex, hub-design takeover)

- [ ] **Git backup hook template has MSYS `/min` path-conversion bug.** Local `.git/hooks/post-commit` was hotfixed during the hub preview takeover by prefixing the `cmd.exe start "" /min ...` call with `MSYS2_ARG_CONV_EXCL='*'`. The tracked template at `_Briefs/governance/scripts/post-commit.template` still contains the old form, so reinstalling hooks will reintroduce the popup: `Windows cannot find C:/Program Files/Git/min`. Route this through `TASK-INFRA-github-remote-and-backup` / governance owner before editing the template.
