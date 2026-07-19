---
agent: codex
topic: migration-checkpoint
date: 2026-07-19
status: pending_push
backup_status: pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
---

# K Micro Migration Checkpoint

## Intent

Preserve the current known-working KE_ArKade development state for continuation
on K Micro without turning the migration into a speculative cleanup pass.

Included by policy:

- active hub, shared, tools, and cartridge source;
- authored scenes, calibration profiles, derived level data, and source images;
- task, lock, QA, handoff, and agent-run context;
- project-local agent skills and migration documentation.

Kept local by policy:

- Godot/Python caches, virtual environments, and packaged exports;
- editor and Obsidian application state;
- runtime/backup logs, diagnostic output, temporary probes, and recovery scripts;
- credentials, private keys, certificates, and local environment overrides.

No files were deleted or relocated during preparation.

## Repository verification

- Existing history preserved on `master`.
- `master` and the locally known `origin/master` both pointed to `52b5dba`
  before the checkpoint.
- Remote: `https://github.com/kkoonnss/KE_ArKade.git`.
- Git LFS `3.7.1`; `git lfs fsck` passed.
- Git connectivity check passed; only benign dangling trees were reported.
- Targeted secret-pattern scan found no embedded API token or private-key match.

## Validation

- Godot version: `4.3.stable.official.77dcf97d8`.
- Hub command:
  `Godot_v4.3-stable_win64_console.exe --headless --path app/hub --editor --quit`
- Result: exit code `0`; no project parse/import failure reported. The sandbox
  could not save its per-user Godot editor settings outside the workspace.
- Python calibration-profile subset: four tests completed before discovery.
- Full Python suite: not complete because the available sandbox Python lacks
  `opencv-python` (`cv2`). Restore `app/tools/requirements.txt` and rerun before
  treating the tools gate as fully green.
- Real controller/projector confirmation remains pending on K Micro.

## Portability repair

- Pre-edit checkpoint: `8bfe5ff` (`snap: preserve working state before K Micro portability repair`).
- Normalized only the mixed indentation inside `_input(event)` for 17
  cartridges; input logic and controller mappings were not changed.
- Removed four unused `SharedLoader` preloads that attempted to reach outside
  standalone cartridge `res://` roots.
- Added `*.import` to `.gitignore`; Godot import sidecars remain local.
- Full fresh import/parse sweep: **34 projects checked, 0 failures** (hub plus
  all 33 cartridges).
- K Main pre-repair visual baseline: Kons confirmed the current runtime works.
- K Main post-repair regression confirmation: passed. Kons launched the normal
  BAT/shortcut workflow and confirmed Burger Time, Bomberman, and Pac-Man work.

## Close conditions

1. Commit the portability repair without rewriting history.
2. Push only after Kons approves the private remote operation.
3. Clone on K Micro, run `git lfs pull`, launch the hub, and record the physical
   controller/projector restore test.
