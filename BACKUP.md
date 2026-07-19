# Backup

## Project

- Name: KE_ArKade
- Local path: `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade`
- Owner: Kons
- Last verified: 2026-07-19
- Verified by: Codex

## GitHub Remote

- Remote name: `origin`
- URL: `https://github.com/kkoonnss/KE_ArKade.git`
- Default branch: `master`
- Visibility: private expected

## Current Backup Status

- Git repo valid: yes
- Remote configured: yes
- Branch tracks remote: yes, `master` tracks `origin/master`
- Working tree clean: no
- Local commits pushed: yes through `52b5dba`; current migration checkpoint is uncommitted
- Restore test completed: not yet verified

Assessment: `remote-configured-dirty`

The committed branch tip matches the locally known `origin/master`. The active
working state is not backed up until the reviewed migration checkpoint is
committed and pushed.

## What Is Backed Up

Committed content that has been pushed to `origin/master` is backed up on GitHub. Local commits ahead of origin, uncommitted changes, and untracked files are not backed up yet.

Tracked project areas include:

- Godot app code under `app/`
- Cartridge/content files under `content/`
- Design and project notes under `design/`, `Notes/`, and `vault/`
- Governance/docs where tracked by Git

## Current Unpushed / Uncommitted State

As of 2026-07-19, the working tree contains a broad but known working-state
checkpoint across the hub, shared controls, cartridges, calibration, authored
scene data, tasks, and agent receipts. The migration policy is to preserve
plausibly active project work and exclude only clear caches, logs, editor state,
diagnostic probes, and recovery scratch. See the migration receipt under
`vault/40-agent-runs/` for validation status.

## What Is Not Backed Up

The `.gitignore` intentionally excludes local/runtime/generated files such as:

- `.godot/`
- `__pycache__/`, `*.pyc`
- scratch and recovery scripts at repo root
- diagnostic output dumps and logs
- IDE/OS junk such as `.vs/`, `.idea/`, `Thumbs.db`, `.DS_Store`
- packaged builds under `build/`, `dist/`, or `exports/`
- secrets and local environment overrides such as `.env`, private keys, and certificates

The pinned Godot executables are currently tracked through Git LFS to make the
migration checkpoint self-contained. This can be simplified after the K Micro
restore is proven; do not rewrite history to do so.

## Health Check

Run from the project root:

```powershell
git rev-parse --show-toplevel
git remote -v
git status --short --branch
git branch -vv
```

Healthy means:

- Git recognizes `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade` as the project root.
- `origin` points to `https://github.com/kkoonnss/KE_ArKade.git`.
- `master` tracks `origin/master`.
- There are no uncommitted or untracked files that should be backed up.
- The branch is not ahead of origin.

## Safe Push Procedure

Do not push blindly while another developer thread is active.

1. Review changes:
   ```powershell
   git status --short
   git diff --stat
   ```
2. Confirm no secrets, generated junk, or scratch files are staged.
3. Stage only reviewed files:
   ```powershell
   git add <files>
   ```
4. Commit with a specific message:
   ```powershell
   git commit -m "<clear message>"
   ```
5. Confirm the remote URL:
   ```powershell
   git remote -v
   ```
6. Push only after Kons approves:
   ```powershell
   git push origin master
   git push origin --tags
   ```

## Restore Procedure

1. Clone into a fresh folder:
   ```powershell
   git clone https://github.com/kkoonnss/KE_ArKade.git C:\tmp\KE_ArKade_restore_test
   ```
2. Run `git lfs pull` and verify the pinned Godot 4.3 executables are present.
3. Follow `README.md` for the optional Python tools environment.
4. Run the headless hub validation and then launch the hub with the controller.
5. Record the result below.

## Restore Tests

| Date | Tester | Source commit | Result | Notes |
|------|--------|---------------|--------|-------|
| 2026-07-03 | Codex | `160a14c5a57b83d8bbea2881a1bfc49069c8d343` | not run | Backup visibility docs created; restore still needs a clean clone test after push state is resolved. |
| 2026-07-19 | Codex | pending migration checkpoint | partial | Git/LFS integrity passed; Godot 4.3 headless hub import exited 0. Full Python suite awaits OpenCV dependencies. Clean-clone K Micro test pending push. |
