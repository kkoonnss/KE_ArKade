# KE_ArKade Agent Instructions

Read `CONTEXT.md` first. Before editing, read
`_Briefs/governance/00_README.md` and the governance documents required for
your role. The current directive and source of truth are identified there.

## Product and architecture

- KE_ArKade is a local-first projected arena platform built with Godot 4.3.
- Scene, semantic Level, and Cartridge logic are separate contracts.
- The hub launches cartridges as separate processes; preserve crash isolation.
- The K Main checkout is the development source of truth. K Micro is a test
  mirror and must not become an independent source branch.
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
