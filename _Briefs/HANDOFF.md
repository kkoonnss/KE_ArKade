# HANDOFF — KE_ArKade Stage 6 (Universal Level Interpretation + Editor)

**For:** the incoming orchestrator (Opus or another Claude thread). **As of:** 2026-06-30.
**Read these first, in this exact order:**

1. **This file** (current state of the chair).
2. **`_Briefs/governance/00_README.md`** (the governance pack — NEW, landed today).
3. **`_Briefs/governance/05_ORCHESTRATOR_RUNBOOK.md`** §1 cold-start protocol.
4. **`_Briefs/governance/01_LANES.md`** + **`02_VERIFICATION_GATES.md`** + **`03_RECOVERY_PROTOCOL.md`** (the contracts you enforce).
5. **`PLAN_interpretation-and-editor.md`** (Stage 6 strategy — still active).
6. **`DISPATCH.md`** (cartridge kickoff prompts — adapt with the new mandatory governance reads).

**Board:** `vault/60-bases/interpretation.base` (Obsidian Base over `vault/30-tasks/TASK-INT-*`).

---

## What just changed (2026-06-30 governance pass)

The Jun 28-30 hub `main.gd` corruption + 3-day silent recovery exposed a
real gap in the discipline system: it held on the happy path and broke the
moment things went sideways. The pack at `_Briefs/governance/` closes that
gap. It is now the contract every agent and orchestrator reads on cold-start.

**Pack contents (8 docs, all in `_Briefs/governance/`):**

| # | Document | Audience |
|---|---|---|
| 00 | `00_README.md` | Everyone (the index) |
| 01 | `01_LANES.md` | Every agent (where to write, forbidden patterns, escalation, the 6-agent parallel pattern) |
| 02 | `02_VERIFICATION_GATES.md` | Every agent (what "done" means per lane) |
| 03 | `03_RECOVERY_PROTOCOL.md` | Every agent (pre-edit snapshots, the `multi_replace` trap, receipt-during-firefight rule) |
| 04 | `04_AGENT_HANDOFF_TEMPLATE.md` | Every agent (the receipt format, scales to 6 parallel agents) |
| 05 | `05_ORCHESTRATOR_RUNBOOK.md` | Orchestrators (cold-start, sweep, dispatch, chair handoff) |
| 06 | `06_VAULT_HYGIENE.md` | Orchestrators + indirectly all agents (tracked hygiene failures, sweep cadence) |
| 07 | `07_GIT_GOVERNANCE.md` | All agents + the GitHub-integration agent (.gitignore, commit cadence, snapshot rule) |

**Cleanup also done in this pass:**

- `.gitignore` patched to keep ~100 throwaway recovery scripts + dumps out
  of git going forward.
- Recovery receipt reconstructed retrospectively at
  `vault/40-agent-runs/recovery_hub_main_gd_2026-06-28.md`.
- `OPEN_QUESTIONS.md` updated with the corruption RCA + the pacman/tetris/dk
  gate gap + the cleanup-script status.
- Cleanup script issued for Kons (one-shot CMD) at
  `_Briefs/governance/scripts/cleanup_2026-06-30.cmd` — deletes 8 stale
  locks, moves the throwaway scripts to `scratch/recovery-2026-06-28/`,
  commits, tags `daily/2026-06-30`. Sandbox lacks delete permission so
  the orchestrator could not execute it directly.

**What did NOT get touched:** any `.gd`, `.py`, frozen schemas, cartridge
folders, hub code. This was a governance-only pass.

---

## Your role & the fleet model (unchanged from 2026-06-27)

- **You = Opus orchestrator** (or another Claude thread holding the chair).
  Kons keeps Claude credits for orchestration; do NOT spawn Claude
  sub-agents for code work without his green light. You write tickets,
  route work, verify — the build is done by external fleets:
  - **Codex** → Python / `app/tools/**` + script-driven cart fixes + the
    GitHub-integration work currently in flight.
  - **Antigravity** → Godot / GDScript: `app/hub/**`, `app/shared/**`, and
    the cartridges. Currently on the post-corruption thumbnails/favorites
    fix.
- Kons routinely runs **up to 6 parallel agents** on cartridges. The lane
  system supports this by construction (`01_LANES.md` §2b). Six locks,
  six folders, six agents — collision-free.
- Communicate with Kons in plain English, short. Technical detail goes in
  tickets and the governance pack, not chat.

---

## The #1 rule (re-asserted, now codified)

**A ticket marked `done` is NOT proof.** This is now `02_VERIFICATION_GATES.md`
§1. Before any "done" is accepted or cascaded, the gate runs. Real-output
evidence. Grep results. Screenshot paths. Lock release. Status flip with
`closed_at` + `closing_receipt`. No exceptions.

---

## Where we are (state of the build)

### Foundations (INT-00..INT-07) — done

All foundation tickets landed pre-corruption. SharedLoader standard set.

### Hub work (INT-08, INT-09) — `in_progress` per ticket, status drift

Tickets still mark `in_progress` but pre-corruption signals were that
Antigravity was closing them. Reality: the corruption hit
`app/hub/main.gd` during this work, then the recovery campaign took over.
Status is genuinely uncertain. **Verification needed:**

- Launch the Design screen, paint anything, hit Save.
- Confirm `derived/grid.json` is written.
- Confirm preset dropdown is restored.

Only after that does the orchestrator flip status to `done`. Until then,
`pending_kons_verify` is the honest answer.

Additionally: Kons reported on 2026-06-30 that **thumbnails and favorites
appear missing in the live hub UI**, even though `app/hub/main.gd` has the
relevant code (favorites array on line 37, thumbnail loaders around lines
307+ and 502+). An Antigravity thread was dispatched to fix. That session
should produce a real receipt under
`vault/40-agent-runs/antigravity_hub_thumbnails_<date>.md` — verify on
return.

### Cartridges (32 games; loopback excluded)

| Status | Games | Notes |
|---|---|---|
| `done` + SharedLoader gate-clean (verified) | gta, rampage, asteroids, paperboy | SharedLoader present, no class_name reach, no local adapter_base.gd |
| `done` but pre-INT-05 (no SharedLoader) — needs Wave-3 retrofit | pacman, tetris, donkey_kong | HANDOFF previously called these "gate-clean" — incorrect. They predate INT-05 and read maps directly. |
| `done` but BESPOKE — needs Wave-3 retrofit | galaga, frogger, on_track | Each carries a local `adapter_base.gd`. Convert to SharedLoader. |
| `ready` — the 22-game Wave-2 cascade | snake, tron, gauntlet, dig_dug, marble_madness, qbert, breakout, bomberman, centipede, pong, lunar_lander, burger_time, bubble_bobble, space_invaders, robotron_2084, smash_tv, defender, missile_command, battlezone, joust, tempest, tapper | Tickets in `vault/30-tasks/`. Dispatch pending — corruption blocked the cascade. |

The 22-game cascade is the next big dispatch once the hub is verified
clean. Recommended split:

- **Antigravity bundle (13):** snake, tron, gauntlet, dig_dug,
  marble_madness, qbert, breakout, bomberman, centipede, pong,
  lunar_lander, burger_time, bubble_bobble.
- **Codex bundle (9):** space_invaders, robotron_2084, smash_tv, defender,
  missile_command, battlezone, joust, tempest, tapper.

The dispatch prompt template now MUST include the four mandatory
governance reads (per `05_ORCHESTRATOR_RUNBOOK.md` §3). Update
`DISPATCH.md` accordingly before issuing the cascade.

---

## Your immediate moves (in order)

1. **Read the governance pack.** It's the new contract. `_Briefs/governance/00_README.md` first.
2. **Ask Kons to run the cleanup script.** `_Briefs/governance/scripts/cleanup_2026-06-30.cmd`. After it runs, the repo is clean and `daily/2026-06-30` is tagged.
3. **Wait for the hub thumbnails/favorites receipt** from the Antigravity
   thread Kons dispatched. If it doesn't write one, that's a tracked
   hygiene failure — reconstruct from git + ping the agent on `AGENT_SYNC.md`.
4. **Verify INT-08 / INT-09** with Kons (Design save → derived produces
   files, preset dropdown works). Flip status accordingly.
5. **Update `DISPATCH.md`** to make the four governance docs mandatory
   reads in every cart prompt.
6. **Dispatch the 22-game cascade** in two bundles, one per fleet.
7. **Grep-gate every cart return** per `02_VERIFICATION_GATES.md` §2.
8. **Generate Wave-3 retrofit tickets** for pacman, tetris, donkey_kong,
   galaga, frogger, on_track (SharedLoader cleanup) — these were
   incorrectly assumed clean.
9. **Track the GitHub-integration Codex agent** — when its work lands,
   refine `07_GIT_GOVERNANCE.md` with the actual remote URL, push cadence,
   branch protection rules.

---

## Open decisions parked for Kons

In `vault/40-agent-runs/OPEN_QUESTIONS.md`. The new ones:

- INT-08 / INT-09 status drift (resolve via verification, above).
- Hub post-corruption thumbnails/favorites regression (pending receipt).
- Wave-3 polish ordering — which games are venue-hit candidates and get
  first tweak. Old candidates: Pac-Man, Bomberman, 4p Tetris, Frogger.
- Binaries at repo root (Godot .exe, godot.zip) — open follow-on for the
  GitHub-integration agent to design a real install step.

The pre-2026-06-30 entries in `OPEN_QUESTIONS.md` are all still active —
read them too.

---

## Gotchas / norms (re-asserted)

- **Pre-edit snapshot before any edit to a file > 200 lines.** Mandatory.
  See `03_RECOVERY_PROTOCOL.md` §1.2 and `07_GIT_GOVERNANCE.md` §2.2.
- **No `multi_replace_file_content`** without the §1.1 sanity check. This
  is what cost us three days.
- Schemas in `vault/50-schemas/` are FROZEN; only the orchestrator changes
  them.
- Cartridges run as separate processes; hub is the launcher (crash
  isolation is non-negotiable).
- One agent per folder/lock at a time; `app/hub` and `app/shared` work
  share their respective locks.
- Design system is law: black base, thin white structure, cyan-led neon;
  homage names only.
- Six parallel cart agents is the design target, not the exception.
  See `01_LANES.md` §2b.

---

*Index: `_Briefs/governance/00_README.md` · Pack: `_Briefs/governance/` ·
Tickets: `vault/30-tasks/TASK-INT-*.md` · Board:
`vault/60-bases/interpretation.base` · Strategy:
`_Briefs/PLAN_interpretation-and-editor.md`.*
