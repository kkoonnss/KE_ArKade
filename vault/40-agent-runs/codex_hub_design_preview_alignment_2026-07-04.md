---
run_id: codex_hub_design_preview_alignment_2026-07-04
agent: codex
session_start: 2026-07-04T00:00:00-07:00
session_end: 2026-07-04T00:12:00-07:00
task_id: TASK-INT-10-design-live-preview
lane: hub
lock_held: hub-design
status: pending_kons_verify
pre_edit_commit: 7b11dc0
close_commit: 6aa518b
backup_status: pushed
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations:
  - vault/40-agent-runs/OPEN_QUESTIONS.md#2026-07-04-additions-codex-hub-design-takeover
tags:
  - hub
  - live-preview
  - github
  - backup
---

# Codex Hub Design Preview Alignment - 2026-07-04

## Summary

Took over the timed-out hub-design/live-preview work per Kons approval and preserved the prior Antigravity/Claude state through the `hub-design` lock. Fixed the Design screen preview path so stale scratch-derived files cannot survive across map changes or failed preview compiles, which matched the screenshot symptom where Pac-Man overlays were drawn from an old grid onto the current map. Also hotfixed the local Git post-commit hook after it popped `C:/Program Files/Git/min`; the tracked hook template remains routed through the infra/governance ticket.

## Changes

- `app/hub/design_screen.gd`: added `preview_last_derive_ok`, dirty-source invalidation, and scratch `derived/` cleanup before every preview compile.
- `app/hub/design_screen.gd`: auto-derive and manual paint now invalidate the saved-level preview source; preview refreshes from current scratch data instead of old level data.
- `app/hub/design_screen.gd`: Preview now owns the canvas while active, preventing accidental paint writes under the overlay.
- `.git/hooks/post-commit`: local-only hotfix to set `MSYS2_ARG_CONV_EXCL='*'` so `cmd.exe start "" /min ...` does not become `C:/Program Files/Git/min`.
- `vault/35-locks/hub-design.md`: annotated Codex takeover.
- `vault/35-locks/hub-design.md`: released after code commit; status remains `pending_kons_verify`.
- `vault/40-agent-runs/OPEN_QUESTIONS.md`: added the tracked hook-template follow-up for `TASK-INFRA-github-remote-and-backup`.

## Verification

Hub gate evidence:

- Pre-edit snapshot: `7b11dc0` (`snap: pre-edit hub design preview takeover`) plus tag `pre-edit/hub/design-preview-7b11dc0`.
- `Godot_v4.3-stable_win64_console.exe --headless --path app\hub --quit-after 2` exited `0`; only observed warning was unrelated corrupt `content/scenes/scene_classic_pack/thumbnail.png`.
- `Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://design_screen.tscn --quit-after 2` exited `0`.
- Visual confirmation: pending Kons. Needs Design screen preview toggle on the wall-art map, then Pac-Man/Tetris cycle check to confirm overlays stay inside the visible semantic map.

## Backup Status

- Remote: `origin -> https://github.com/kkoonnss/KE_ArKade.git`.
- Branch before close commit: `master...origin/master [ahead 16]`.
- Local hook was hotfixed before the close commit.
- Post-commit hook result: `SUCCESS: pushed master and tags.`
- Evidence from `_Briefs/governance/scripts/logs/push_backup.log`: `02422b3..6aa518b master -> master`; tag `pre-edit/hub/design-preview-7b11dc0` pushed.

## Open Questions

- Tracked `_Briefs/governance/scripts/post-commit.template` still has the MSYS `/min` bug. It should be handled by `TASK-INFRA-github-remote-and-backup` / governance owner so hook reinstalls do not regress.

## Next Holder Briefing

First thing to verify visually: load the Design screen, run Auto-Derive, enable Preview, and cycle Pac-Man/Tetris/Galaga. If a preview compile fails, the status should say `fallback` and the overlay should use adapter fallback rather than an old scratch grid. Do not edit `_Briefs/governance/scripts/post-commit.template` casually; the local hook is fixed, but the tracked template belongs to the infra/governance backup ticket.
