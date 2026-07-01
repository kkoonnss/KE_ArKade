---
run_id: recovery_hub_main_gd_2026-06-28
kind: recovery
severity: P0
agent: reconstructed_by_orchestrator_2026-06-30
session_start: 2026-06-28T~01:30Z (approx — reconstructed from AGENT_SYNC.md timestamps)
session_end: 2026-06-30T~20:00Z (approx — last hub fix commit)
task_id: (no ticket — emergency)
lane: hub
lock_held: hub-design
status: resolved (reconstructed retrospectively)
pre_edit_commit: none (pre-incident git did not exist)
close_commit: ec63df1 ("Restore Hub graphical cards and favorites logic")
escalations:
  - new forbidden pattern added to 01_LANES.md §2.1 (multi_replace_file_content trap)
  - new pre-edit snapshot requirement in 03_RECOVERY_PROTOCOL.md §1.2 and 07_GIT_GOVERNANCE.md §2.2
---

# RECOVERY — Hub `main.gd` corruption + 3-day rebuild

**This receipt is reconstructed retrospectively** by the Opus orchestrator on
2026-06-30, because the original recovery sessions wrote no receipt — the
single largest failure mode this governance pack exists to prevent. The
narrative below is reconstructed from `AGENT_SYNC.md`, `recover_log.txt`,
git history, and the ~100 throwaway scripts left at repo root.

This receipt is therefore lower-fidelity than a live one would have been.
That is the point.

---

## Summary

On 2026-06-28 ~01:30Z an agent (Antigravity, session id ending `5dd8f37c`)
ran `multi_replace_file_content` on `app/hub/main.gd` with a mismatched
`EndLine` and silently deleted lines 51 through 1780. The hub's
`_ready()` styling logic was gone; the hub booted to a grey screen with a
`Parse Error: Unexpected "Indent" in class body` at line 53.

A second agent (session id ending `c1b53563`), working on Hub UI navigation
and Donkey Kong mechanics in a separate tree, noticed the corruption and
opened a real-time channel at `AGENT_SYNC.md` (repo root) to coordinate.
The two agents agreed that `c1b53563` would not touch `main.gd` while
`5dd8f37c` attempted reconstruction.

Reconstruction took roughly three days and ~13 throwaway Python scripts
because (a) the pre-incident state was not in git, (b) the agent's
transcript only contained partial views of `main.gd`, and (c) the
`recover_log.txt` shows large structural gaps (lines ~1100–1700) that had to
be re-derived rather than restored.

The hub was restored over four commits (the entire git history of this
repo as of 2026-06-30):

- `7546982` Initial commit of current state (with broken main.gd)
- `445aa61` Fix Hub UI crashes by simplifying main.gd
- `cd38c22` Fix Donkey Kong mechanics: barrels kill, fall death, max ladder
- `ec63df1` Restore Hub graphical cards and favorites logic

The hub now boots; favorites + thumbnail logic is present in `main.gd`
(1053 lines).

## Root cause

`multi_replace_file_content` was invoked with `EndLine` values that did
not correspond to the agent's mental model of the file. The tool deleted
the range between the supplied `StartLine` and `EndLine` without any
sanity check on bounds.

Contributing factors:

1. No pre-edit git snapshot existed (git was bootstrapped *during* the
   recovery — commit `7546982` literally says "Initial commit of current
   state (with broken main.gd)").
2. No range-bounds sanity check was performed before the multi-replace
   call. The trap is silent: the call returns success and the file is
   smaller by 1730 lines.
3. The agent was not running with full-file context loaded; it had viewed
   snippets and inferred line numbers.

## What was lost

- Roughly 1730 lines of hub `main.gd` (lines 51-1780 in the corrupted file).
- All intermediate state from sessions prior to the incident — there was
  no pre-incident git to compare against.
- Three days of build velocity across hub, Design screen, and the 22-cart
  Wave-2 cascade (which never started).

## What was recovered

- Hub boots, parses, displays cartridge cards.
- Favorites array + thumbnail-loading code present.
- Donkey Kong mechanics (barrels, ladder, death bounds) refactored as part
  of the same firefight (separate concern, opportunistic).
- A working — if minimal — git history for the project.

## What is *not* known

Because there was no pre-incident snapshot:

- We cannot confirm the restored `main.gd` matches the pre-incident behavior
  feature-for-feature. The "Restore Hub graphical cards and favorites
  logic" commit message implies feature parity was the goal but not
  necessarily that it was achieved.
- The Jun 30 report from Kons that thumbnails and favorites were
  "missing" in the live hub UI suggests a downstream regression that may
  or may not be traceable to the reconstruction.

## Prevention rules added

Codified in this governance pass, 2026-06-30:

1. **Forbidden tool pattern** added to `_Briefs/governance/01_LANES.md`
   §2.1: `multi_replace_file_content` requires a §1.1 sanity check.
2. **Pre-edit snapshot mandatory** for any file > 200 lines, per
   `_Briefs/governance/03_RECOVERY_PROTOCOL.md` §1.2 and
   `_Briefs/governance/07_GIT_GOVERNANCE.md` §2.2.
3. **Receipt-during-firefight rule** added to
   `_Briefs/governance/03_RECOVERY_PROTOCOL.md` §4. The corruption was
   not the worst failure; the silent recovery was.
4. **Hub gate** in `_Briefs/governance/02_VERIFICATION_GATES.md` §3 now
   requires a named pre-edit commit hash in the closing receipt.

## Open follow-ons

- Verify in next session whether the "missing thumbnails/favorites"
  report is a live regression in the restored `main.gd` (the agent Kons
  dispatched on 2026-06-30 should produce a real receipt; we'll know
  then). Tracked as `pending_kons_verify` on the post-recovery hub state.
- Move the ~100 throwaway recovery scripts at repo root into
  `scratch/recovery-2026-06-28/` and `.gitignore` the patterns going
  forward. Cleanup script issued: `_Briefs/governance/scripts/cleanup_2026-06-30.cmd`.
- Tag pre-edit and daily snapshots going forward, starting 2026-06-30:
  `git tag daily/2026-06-30 HEAD`.

## Next holder briefing

If you take the hub lane next, the most important inheritance from this
incident is:

1. **The pre-edit snapshot is not optional anymore.** Read
   `_Briefs/governance/03_RECOVERY_PROTOCOL.md` §1-2 in full before any
   edit.
2. **Do not use `multi_replace_file_content`** on `main.gd` without a §1.1
   sanity check. If you can avoid it entirely, do.
3. The hub `main.gd` is structurally OK but may have feature gaps relative
   to pre-incident. Verify the specific feature you are changing actually
   exists before assuming it does.
4. There may be uncommitted modifications in the working tree from the
   recovery work that have not been committed yet (Jun 30 `git status -s`
   showed heavy modifications across hub, shared, and many cartridges).
   Before any new edit, commit or stash the existing state.

---

*This receipt is the durable record of what we learned. The governance pack
at `_Briefs/governance/` is the codified prevention.*
