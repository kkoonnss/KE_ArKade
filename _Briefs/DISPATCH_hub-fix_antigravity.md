# DISPATCH — Hub Fix (Antigravity, single instance)

You are an autonomous build agent on the **KE_ArKade** project, working the
**hub** lane. Repo root: `C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade`

This project had a 3-day outage on 2026-06-28 when an agent silently deleted
1,730 lines of `app/hub/main.gd` with a bad range-edit and no git snapshot to
restore from. **You are editing that exact file. The backup discipline below
is not optional — it is the whole reason this brief exists.**

---

## 0. READ FIRST (in this order, before any edit)

1. `_Briefs/governance/01_LANES.md`
2. `_Briefs/governance/02_VERIFICATION_GATES.md`
3. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
4. `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`
5. `vault/40-agent-runs/reconstructed_antigravity_hub_thumbnails_favorites_2026-06-30.md` (prior state of `main.gd`)
6. The three tickets you are executing (see §3).

Do not write a single line until you have read all six.

---

## 1. BACKUP PROTOCOL (mandatory — run these git commands yourself)

You have terminal access. Git is healthy on this machine (branch `master`).
Run each snapshot as instructed. Every command below is copy-paste ready.

**A. Snapshot before you claim anything:**
```
cd /d "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade"
git add -A && git commit -m "snap: pre-claim hub-fix (INT-08/09 + scene-ordering)"
```

**B. Snapshot immediately before you open a >200-line file for editing.**
`app/hub/design_screen.gd` and `app/hub/main.gd` are both large — snapshot
before EACH one, with a named tag so restore is a one-liner:
```
git add -A && git commit -m "snap: pre-edit <file>"
git tag pre-edit/hub/<ticket>          (e.g. pre-edit/hub/int-08)
```

**C. One logical change = one commit.** Do not batch unrelated edits.

**D. Close each ticket with a commit** naming the ticket + receipt:
```
git add -A && git commit -m "hub/<file>: <change>  (close TASK-INT-<slug>)"
```

**If corruption happens anyway**, restore instantly and do NOT hand-stitch:
```
git checkout pre-edit/hub/<ticket> -- app/hub/<file>
```
Then open `vault/40-agent-runs/recovery_hub_<date>.md` and log it AS IT
HAPPENS (governance `03_RECOVERY_PROTOCOL.md` §4).

---

## 2. FORBIDDEN (these caused real incidents)

- **NO `multi_replace_file_content`** (or any range/EndLine bulk-edit tool) on
  a file you have not just read end-to-end this session. This is what deleted
  1,730 lines. Prefer single-target find-replace with unique surrounding
  context. If a range tool is unavoidable, first log the start-line content,
  end-line content, and line span, and abort if any disagree with your read.
- **NO global `class_name` reach or `res://` preloads** to shared code —
  cartridges/hub are separate Godot projects. (Not expected in this hub work,
  but the rule stands.)
- **Write ONLY inside `app/hub/**`.** Everything else is read-only. Never
  touch `vault/50-schemas/**` or `_Briefs/governance/**`.

---

## 3. THE WORK — three tickets, ONE instance, strictly sequential

Do NOT run a second hub agent in parallel: all three share the `hub-design`
lock and edit overlapping files. Claim the lock once, do all three, release it.

**Claim now:** create `vault/35-locks/hub-design.md` with your agent id + the
ticket ids + timestamp. Set `owner_agent` + `status: in_progress` on each
ticket as you start it.

### 3.1 — TASK-INT-08-design-save-compile-derived  (P0, do first)
File: `app/hub/design_screen.gd`. Read the ticket at
`vault/30-tasks/TASK-INT-08-design-save-compile-derived.md`.
The real bug: `_on_dir_selected()` prints "Derived layers generated"
unconditionally even when the Python compile produces nothing. Fix:
- Capture the `OS.execute` return code AND output; treat non-zero exit OR a
  missing `derived/grid.json` afterward as FAILURE and surface it in the UI —
  never claim success when nothing was generated.
- Robust Python invocation on Windows: try `python`, then `py -3`, then
  `python3`; log which worked. If none, tell the user the editor needs Python
  with opencv-python + numpy.
- After a successful compile, confirm `derived/grid.json` exists before
  declaring done.
- Set `level_id` to the LEVEL folder name; write under
  `content/scenes/<scene>/levels/<level>/`; no stray `scene.yaml`.

### 3.2 — TASK-INT-09-design-preset-selector  (P2, depends on 08, same file)
Read `vault/30-tasks/TASK-INT-09-design-preset-selector.md`. Add an
OptionButton to the Design auto-derive sidebar listing the presets the backend
supports, read from `app/tools/level_authoring/author_backend.py` so it stays
in sync (Balanced Semantic / Open Flow / Vertical Surfaces; default Balanced
Semantic). Changing it sets `cv_params["preset"]` and re-runs the derive. Keep
the existing CV sliders.

### 3.3 — TASK-INT-hub-scene-ordering-classic-first  (P2)
File: `app/hub/main.gd`. Read
`vault/30-tasks/TASK-INT-hub-scene-ordering-classic-first.md`. In whatever
populates the Scenes grid, sort so the **classic pack is always the first
card**, custom scenes after, stable across restart. Prefer sorting on an
`is_classic` flag over string-matching the pack name.

---

## 4. VERIFY BEFORE YOU CLOSE (hub gate — `02_VERIFICATION_GATES.md` §3)

For each ticket, paste real evidence into your receipt:
1. `app/hub/*.gd` parses — run `godot --headless --check` (or Antigravity's
   equivalent) and paste the result.
2. Hub boots to the main screen (no grey/blank). Screenshot path under
   `vault/70-qa/`.
3. The specific feature works:
   - INT-08: author a level, Save, confirm `derived/grid.json` is written; a
     forced failure shows an error, not false success.
   - INT-09: switching presets changes the auto-derived map.
   - scene-ordering: classic pack shows first after a restart.
4. Name the `pre_edit_commit` hash/tag AND the `close_commit` in the receipt.
5. Anything you cannot visually confirm yourself → mark the ticket
   `pending_kons_verify` (a real, honest status) and list exactly what Kons
   must launch to confirm. Do NOT mark `done` on unverified visual work.

---

## 5. CLOSE-OUT (every ticket)

- Write a receipt: `vault/40-agent-runs/antigravity_hub_fix_<ticket>_<YYYY-MM-DD>.md`
  per `04_AGENT_HANDOFF_TEMPLATE.md` (frontmatter with `pre_edit_commit`,
  `close_commit`, `status`, gate evidence, next-holder briefing).
- Flip ticket frontmatter: `status: done` (or `pending_kons_verify`),
  `closed_at`, `closing_receipt`.
- After ALL THREE are closed, **delete `vault/35-locks/hub-design.md`** in the
  final close commit.

## 6. IF YOU GET BLOCKED

Stop. Do not "fix forward" past a frozen contract or outside `app/hub/**`.
Append the blocker to `vault/40-agent-runs/OPEN_QUESTIONS.md`, note it in your
receipt, release the lock, and hand back. The orchestrator (Opus) resolves it.

## 7. WHAT TO HAND KONS AT THE END

A single message listing exactly what he needs to launch/spot-check to close
any `pending_kons_verify` items — one list, not one ping per ticket.

---

*Lane: hub. Owns `app/hub/**` only. Governance: `_Briefs/governance/`.
Completion plan this fits into: `_Briefs/PLAN_completion-and-workflow.md`
(Phase A — fix the hub). Escalation: Opus orchestrator.*
