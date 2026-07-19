---
run_id: claude_hub_classic_routing_continuation_2026-07-03
agent: claude_sonnet
session_start: 2026-07-03T14:36:00-07:00
session_end: 2026-07-03T15:10:00-07:00
task_id: TASK-INT-hub-classic-routing-data-driven
lane: hub
lock_held: hub-design
status: pending_kons_verify
pre_edit_commit: not-applicable (no new edits made this session)
close_commit: pending
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Picked up this ticket after a Codex session (working in a separate
`arkade-hub-work` / `arkade-staging` checkout outside this repo's mount) reported
it had removed the hardcoded classic-game list from `app/hub/main.gd` and
replaced it with a data-driven filesystem check, but hit a usage-limit block
before it could commit, push, or write its receipt into this vault. I verified
the live working tree at `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade` already
carries that fix — no new code changes made this session. What's outstanding is
the Godot parse check and Kons's visual confirmation, both of which require the
Windows Godot binary and are outside what this session can run.

## Verified state

`app/hub/main.gd` (lines ~527-544), current working-tree content:

```gdscript
func _classic_level_for_cart(cart_id: String) -> String:
    var base_dir = ProjectSettings.globalize_path("res://").path_join("../..").simplify_path()
    var candidate = "classic_" + cart_id
    var level_path = base_dir.path_join("content/scenes/scene_classic_pack/levels").path_join(candidate)
    if DirAccess.dir_exists_absolute(level_path):
        return candidate
    return ""
```

`_launch_game()` (line 541) calls `_classic_level_for_cart(cart_id)` — confirmed
via grep, no remaining `cart_id in ["tetris", "pacman", ...]` hardcoded array
anywhere in the file. This matches the ticket's acceptance criteria exactly:
data-driven off the filesystem, no hardcoded classic-game list, fallback to
`scene_demo_wall/demo_level` only when no `classic_<id>` level exists.

- `grep -n "classic_level_to_cartridge"` on `app/hub/main.gd` → 0 hits (old hardcoded map fully removed).
- `grep -n "dir_exists_absolute|_launch_game"` on `app/hub/main.gd` → confirms the shape above.

## Verification (outstanding — needs Kons, on his machine)

Two things this session could not do because they require the Windows Godot
binary and/or eyes-on confirmation, neither of which this sandbox has:

1. **Godot parse check** (required before any commit per the ticket):
   ```
   "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\Godot_v4.3-stable_win64_console.exe" --headless --path "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\app\hub" --check-only --script res://main.gd
   ```
2. **Kons visual confirmation** — launch 3-4 previously-broken carts (snake,
   breakout, qbert, dig_dug) from the hub and confirm they now load their
   `classic_<id>` level instead of falling through to `demo_wall`. Screenshot
   each to `vault/70-qa/claude_routing_<cart>_2026-07-03.png` per the ticket's
   verify step.

## Backup status

- Remote: `origin -> https://github.com/kkoonnss/KE_ArKade.git`
- `git status --short --branch` at session start: `master...origin/master [ahead 5]`,
  working tree has ~155 modified files + ~20 untracked files repo-wide (not just
  this ticket's change — see Open questions below).
- This session made no commits. `app/hub/main.gd` is the only file this ticket
  should touch; it stays uncommitted pending the parse check above.
- Result: `backup_pending`. Next command once the parse check passes:
  ```
  cd /d "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade"
  git add app/hub/main.gd
  git commit -m "hub: data-driven classic-level routing (close TASK-INT-hub-classic-routing-data-driven)

Replaces the 9-game hardcoded array in _launch_game with _classic_level_for_cart(),
a DirAccess.dir_exists_absolute check against scene_classic_pack/levels/classic_<id>.
All 32 carts now route to their classic level automatically; fallback to demo_wall
is unchanged for carts with no classic level.

Ticket: TASK-INT-hub-classic-routing-data-driven
Receipt: vault/40-agent-runs/claude_hub_classic_routing_continuation_2026-07-03.md"
  _Briefs\governance\scripts\push_backup.cmd
  ```
  This is a **scoped commit of only `app/hub/main.gd`** — it deliberately does
  NOT run `git add -A`, because the rest of the working tree carries ~155 other
  modified files and ~20 untracked scratch files unrelated to this ticket (see
  Open questions). Bundling them into this commit would violate the governance
  pack's logical-commit convention (`07_GIT_GOVERNANCE.md` §2.2) and make a
  future bisect useless.

## Open questions

- **Working tree is far dirtier than one ticket's worth of change.** `git status`
  shows ~155 modified files across nearly every cartridge, `app/shared/`, and
  several vault task files, plus ~20 untracked files at repo root that look like
  scratch/debug output that should already be gitignored per `07_GIT_GOVERNANCE.md`
  §2.3 (`joypad_patch*.py`, `err.txt`, `out.txt`, `remove_bad_blocks.py`,
  `tetris_reconstructed.gd`, `find_enter.py`, `tetris_diff.txt`). Either the
  `.gitignore` patch referenced in §4 of that doc was never actually applied, or
  these predate it. This is the same standing issue already logged in
  `OPEN_QUESTIONS.md` ("Working tree has ~60 uncommitted files as of 2026-07-01")
  — it has grown to ~155+20 since. Recommend a dedicated housekeeping ticket
  (`lane: tools` or `governance`) to (a) actually apply/verify the `.gitignore`
  patch, (b) do one governance snapshot commit for the legitimate cartridge work
  mixed in there, (c) `git rm` the confirmed-scratch files. Not fixed here —
  out of the `hub` lane and out of this ticket's scope.
- **Codex's uncopied handoff.** Codex's own session note describing this same
  fix (`arkade-staging/vault/40-agent-runs/codex_hub_classic_routing_2026-07-03.md`)
  lives in a separate checkout (`C:\Users\Kons\Documents\Claude\arkade-staging`)
  that this session has no mount access to, so it could not be copied into this
  repo's `vault/40-agent-runs/`. This receipt supersedes it for this repo's
  record; if the original has detail worth preserving (e.g. exact diff stats
  from Codex's own working copy), Kons can paste it in or grant folder access
  in a future session.
- **`hub-design` lock is currently held by this session**, not released, because
  the ticket is not actually closed yet (parse check + visual confirm pending).
  Whoever runs the commands above should release `vault/35-locks/hub-design.md`
  and flip the ticket's `status` to `done` once Kons confirms.

## Addendum — Codex's original handoff recovered

Got read access to `C:\Users\Kons\Documents\Claude\arkade-staging` this session and
recovered Codex's original note (`arkade-staging/vault/40-agent-runs/codex_hub_classic_routing_2026-07-03.md`).
Key details it adds beyond what's in this receipt:

- Codex's own diff was narrower than the working tree suggests: it added
  `_cart_id_for_classic_level()` and replaced **three** hardcoded
  `classic_level_to_cartridge` dictionaries (level-card/favorite/name-helper
  paths), on top of `_classic_level_for_cart()` / `_launch_game()` routing that
  was **already** data-driven before Codex touched it (i.e. someone — likely
  antigravity, same session as `TASK-INT-hub-wiring-launch-and-nav` — did that
  part). Codex explicitly warns: "most of the file diff predates this session,"
  matching my own finding that `app/hub/main.gd`'s 1127/1062-line diff is not
  attributable to one ticket.
- Codex also attempted the Godot parse check and it **timed out at ~64s**
  without a pass/fail result — not a failure, just inconclusive. Worth giving
  the local run more time before assuming a hang.
- Codex flagged a live parallel constraint at the time: an "Asteroids developer
  thread" was active and hub work should not touch Asteroids-owned content.
  No `cart-asteroids` lock exists in `vault/35-locks/` as of this session, so
  that constraint appears to have cleared.
- Codex raised an open question worth resolving here: **three** hub-lane
  tickets are simultaneously `pending_kons_verify` on the same file and the
  same `hub-design` lock: this one, `TASK-INT-hub-wiring-launch-and-nav`
  (gray-window / IPC handshake fix, owner: antigravity), and
  `TASK-INT-hub-scene-ordering-classic-first`. Recommend Kons do **one**
  verification pass in the hub that covers all three at once (launch pacman +
  gta to confirm they boot past gray/IPC-heartbeat, launch snake/breakout/
  qbert/dig_dug to confirm classic routing, confirm scene ordering shows
  classic pack first) rather than three separate sessions — they're all
  touching the same lock anyway. Commits can still be split by ticket if
  Kons wants clean history; verification does not have to be.

## Next holder briefing

If you're picking this up: the code fix is already correct and already in the
working tree — do not re-implement it. Your only job is (1) run the Godot parse
check, (2) if clean, run the scoped commit above, (3) have Kons launch snake /
breakout / qbert / dig_dug from the hub and confirm they load their classic
level, (4) screenshot those launches to `vault/70-qa/`, (5) flip this ticket's
`status` to `done` and delete `vault/35-locks/hub-design.md`. Do not run
`git add -A` — the dirty tree has unrelated work mixed in (see Open questions).
