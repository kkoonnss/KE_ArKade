# KE_ArKade Agent Instructions

Read `CONTEXT.md` first. Before editing, read
`_Briefs/governance/00_README.md` and the governance documents required for
your role. The current directive and source of truth are identified there.

## Product and architecture

- KE_ArKade is a local-first projected arena platform built with Godot 4.3.
- Scene, semantic Level, and Cartridge logic are separate contracts.
- The hub launches cartridges as separate processes; preserve crash isolation.
- GitHub `origin/master` is the shared source of truth. K Main remains the
  recovery anchor; K Micro may be the active development checkout.
- Runtime target is Windows 11 at 1920x1080 with an XInput controller.

## Editing rules

- Preserve lane ownership from `_Briefs/governance/01_LANES.md`.
- Do not edit frozen schemas under `vault/50-schemas/` without orchestrator
  authority.
- Do not use global `class_name` references across separate Godot projects;
  use the established `SharedLoader` seam.
- Before editing a file over 200 lines, follow the pre-edit snapshot rule in
  `_Briefs/governance/03_RECOVERY_PROTOCOL.md`.
- Keep runtime writes under `user://`; never write generated runtime data to
  `res://`.
- Preserve user changes and active loose ends. Do not clean, relocate, or
  rewrite unrelated work while completing a scoped task.
- Never rewrite Git history or force-push. Confirm the private remote before
  any push and follow `_Briefs/governance/07_GIT_GOVERNANCE.md`.

## Two-computer Git workflow

- Agents own Git synchronization; do not rely on Kons to remember commands.
- Before work, report branch, HEAD, working-tree state, and ahead/behind state.
- If the tree is dirty, preserve and explain it. Never discard, clean, stash,
  switch, pull, or overwrite uncertain work without explicit approval.
- Begin new work from an up-to-date clean `master`, then use a short-lived
  topic branch. Never develop directly on `master`.
- Before switching computers, validate, show the diff, commit intentionally,
  and push the topic branch. Merge through review, then fast-forward `master`
  and run `git lfs pull` on the other computer before continuing.
- Never work on both computers with uncommitted changes at the same time.
- Treat runtime-generated tracked files as changes requiring classification;
  separate authored calibration/tuning from caches and line-ending noise.
- Give Kons concise status reminders: current branch, whether work is backed
  up to GitHub, and the single next action needed.

## Required validation

Use the repository-root Godot 4.3 console executable.

Hub parse/import check:

```powershell
.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --editor --quit
```

Python tools test suite, after restoring `app/tools/requirements.txt` into a
local `venv`:

```powershell
.\venv\Scripts\python.exe -m unittest discover -s app\tools\tests -p "test_*.py"
```

For cartridge work, also perform the cartridge gate in
`_Briefs/governance/02_VERIFICATION_GATES.md`. Interactive or visual changes
remain `pending_kons_verify` until Kons confirms them on a real launch.

## Completion receipt

Every completed ticket needs real command output, artifact paths, lock release,
ticket status, and a handoff receipt under `vault/40-agent-runs/`. Record GitHub
backup status honestly; uncommitted and unpushed work is not backed up.
