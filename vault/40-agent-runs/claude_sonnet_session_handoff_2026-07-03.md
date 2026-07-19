---
run_id: claude_sonnet_session_handoff_2026-07-03
agent: claude_sonnet
session_start: 2026-07-03T14:00:00-07:00
session_end: 2026-07-03T16:10:00-07:00
task_id: multiple (see below)
lane: hub
lock_held: hub-design
status: abandoned
pre_edit_commit: 160a14c (baseline HEAD at session start, no snapshot commit landed — see Backup status)
close_commit: none
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

# Session Handoff — for the next agent (any fleet)

Kons is handing this off to a helper agent for a few hours. This is a
**multi-topic session handoff**, not a single-ticket receipt — I touched
several threads. Read this whole file before doing anything. Nothing here is
committed to git yet — that's the #1 blocker, see "Critical blocker" below.

---

## Critical blocker: git lock contention (deal with this FIRST)

`C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\.git\index.lock` has appeared
**twice** this session. Kons manually deleted it once; it came back the
moment I tried to commit again (a real error from `git commit` itself, not a
stale-file false alarm). This smells like a genuinely concurrent git process
— possibly the other `claude_sonnet` thread that claimed `TASK-INT-cart-tetris`
today (see below), possibly Kons's own tooling, possibly something else.

**Before you commit anything:** check whether another agent/process is
actively working this repo right now (ask Kons, check `AGENT_SYNC.md`, check
if the tetris thread is still live). If it's genuinely stale, delete
`.git\index.lock` and proceed. If not, coordinate first — do not just retry
blindly.

Two full sets of code changes are sitting **uncommitted** in the working tree
right now, described below. Nothing is at risk (files are saved to disk), but
none of it is backed up until a commit + push lands.

---

## Thread 1 — Hub classic-routing ticket (mostly done, needs verification)

`TASK-INT-hub-classic-routing-data-driven` — status `pending_kons_verify`,
owner `claude_sonnet`, lock `hub-design` (held).

The fix (`_classic_level_for_cart()` in `app/hub/main.gd`, ~line 528) is
correct and already in the working tree — a prior Codex session wrote it,
I verified it statically this session. Full detail + the exact commit message
to use:
`vault/40-agent-runs/claude_hub_classic_routing_continuation_2026-07-03.md`
(has an addendum recovered from Codex's original note too).

**Still needed:** Godot parse check, then Kons clicks through snake / breakout
/ qbert / dig_dug / pacman / gta from the hub. Note: **snake showed a gray
screen** when Kons tried it — that's a *different*, already-known issue
(`TASK-INT-hub-wiring-launch-and-nav`, the IPC-heartbeat gray-window bug, or
snake's cartridge just isn't built out yet — its ticket `TASK-INT-cart-snake`
is still `status: ready`). Don't treat that as a regression in this fix.

Three hub tickets are simultaneously `pending_kons_verify` on this same file/
lock — recommend verifying all three in one pass: this one,
`TASK-INT-hub-wiring-launch-and-nav`, `TASK-INT-hub-scene-ordering-classic-first`.

## Thread 2 — Hub UI changes (done, unverified, uncommitted)

Kons annotated a screenshot with four asks, all implemented in
`app/hub/main.gd` + `app/hub/main.tscn` this session:

1. Grid navigation — cards now have explicit up/down/left/right focus
   neighbors (`_wire_vertical_focus_neighbors`) instead of relying on Godot's
   automatic fallback, which was very likely what sent focus to the Help
   button at row edges.
2. Auto-scroll — `_wire_auto_scroll` calls `ScrollContainer.ensure_control_visible()`
   on focus change so the selected card is never clipped.
3. Help + Restore buttons moved from the top bar into the sidebar, bottom
   cluster, order: Help, Test Pattern, Restore.
4. Panic Black button + its blackout overlay fully removed (button, scene
   node, `is_panic` state, `_on_panic_pressed`). **Kept** `_on_restore_pressed()`
   itself — the crash/heartbeat-timeout auto-recovery path in
   `_on_cartridge_exited` calls it directly, independent of any button.

Full detail: `vault/40-agent-runs/claude_hub_ui_nav_and_buttons_2026-07-03.md`.

**Open call for Kons:** whether to keep the Restore button at all (he asked
if it's "necessary" — no overhead either way, moved it to the sidebar
regardless per his "at the very least move it" instruction). Not resolved.

**Still needed:** same as Thread 1 — Godot parse check (never actually
completed by anyone this session — Codex's earlier attempt timed out at ~64s,
mine never ran because of the git lock distraction, not a parse failure) and
a Kons click-through of the new nav/scroll/button-layout behavior.

**When you commit:** scope it to `app/hub/main.gd` + `app/hub/main.tscn`
ONLY. Do not `git add -A` — see Thread 4.

## Thread 3 — Priority context (read this before picking new work)

Kons clarified mid-session that the **real current priority** is not the hub
— it's locking in the "six template" games (his favorites: Asteroids, Donkey
Kong, Pac-Man, Paperboy, Rampage, Tetris) plus the **secondary editor** (the
in-hub Design screen). Full archetype mapping and rationale:
`_Briefs/PLAN_interpretation-and-editor.md`.

Concretely:
- 6 of 7 archetype **reference** games are `done` (galaga, frogger, on_track,
  gta, pacman, donkey_kong). **Tetris (Well/Fill reference) is `in_progress`**
  — claimed by a `claude_sonnet` thread today ("took over from Antigravity
  2026-07-03"), per `TASK-INT-cart-tetris` frontmatter. **Do not touch
  `content/cartridges/tetris/` — that lock may still be held.** Check
  `vault/35-locks/cart-tetris.md` before going anywhere near it.
- Pac-Man and Donkey Kong are `done` but flagged for a later SharedLoader
  retrofit (Wave-3 cleanup, not blocking).
- The secondary editor gate is three tickets, all `pending_kons_verify`:
  `TASK-INT-08-design-save-compile-derived`, `TASK-INT-09-design-preset-selector`,
  `TASK-INT-10-design-live-preview`. **If Kons wants forward progress on the
  real priority (not hub polish), this is where to point him** — ask him to
  open the Design screen, paint something, hit Save, confirm a preset works,
  confirm live preview updates.
- Hub work (Threads 1 & 2 above) is real but secondary — Kons asked for it
  directly this session, it's not scope creep, just don't let it eat the
  whole few hours if he'd rather see editor verification.

## Thread 4 — Known standing issues (not this session's job to fix, but real)

- **Working tree is very dirty**: ~155 modified files + ~20 root-level
  scratch files (`joypad_patch*.py`, `err.txt`, `tetris_reconstructed.gd`,
  etc.) that `07_GIT_GOVERNANCE.md` §2.3 says should be gitignored and aren't.
  Logged in `OPEN_QUESTIONS.md` under "2026-07-03 additions." Needs a
  dedicated housekeeping ticket — don't try to clean this yourself mid-session,
  too easy to sweep up someone else's in-flight work by accident.
- **GitHub branch protection is not configured** on `master` (confirmed via
  the GitHub settings page this session). `TASK-INFRA-github-remote-and-backup`
  is otherwise done (remote pushed, LFS migrated). This is a straightforward
  GitHub Settings → Branches change if Kons wants it done — needs his
  explicit yes since it's an account-settings change, not a code change.
- **`_Briefs/HANDOFF.md`** (the orchestrator's living status doc, different
  from this file) is stale — last updated 2026-06-30. Kons knows and said
  not to spend time refreshing it right now. Leave it alone unless he asks.
- **Root `CONTEXT.md`** exists and is decent but also date-stamped June 2026.
  Same deal — known, deprioritized, don't touch unless asked.

## Rules that apply regardless of which fleet picks this up

Read `_Briefs/governance/01_LANES.md`, `02_VERIFICATION_GATES.md`,
`03_RECOVERY_PROTOCOL.md`, `04_AGENT_HANDOFF_TEMPLATE.md` if you haven't —
every agent on this project reads these on cold start. Key ones that bit
people before: never `git add -A` on this repo right now (dirty tree, see
Thread 4), never use range/line-based multi-file-edit tools on `main.gd`
without reading the full file first (this is the file that got corrupted
Jun 28-30), and write your own receipt in `vault/40-agent-runs/` before you
stop, even if the session ends messily.

## Next holder briefing

Start here, in order: (1) resolve the git lock — coordinate, don't guess;
(2) once clear, commit Thread 1 + Thread 2 changes as two separate scoped
commits (both touch the same two files but are logically distinct — your
call whether Kons wants them split or squashed, ask if unsure); (3) run the
Godot parse check that's been deferred all session; (4) get Kons's
click-through verification for both threads; (5) if there's time left and
Kons agrees, point him at the three `pending_kons_verify` editor tickets in
Thread 3 — that's the actual current priority, not more hub work.
