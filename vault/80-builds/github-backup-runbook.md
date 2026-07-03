---
tags: [ke-arkade, backup, github, git, agent-rules]
type: runbook
status: active
connections: [KE_ArKade, 07_GIT_GOVERNANCE]
---

# GitHub Backup Runbook

Canonical contract: `_Briefs/governance/07_GIT_GOVERNANCE.md`.

This note is the Obsidian-facing version for Kons and orchestrators. The
governance file is authoritative for agents.

## Current Remote

- GitHub repo: `https://github.com/kkoonnss/KE_ArKade.git`
- Local repo: `C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade`
- Branch: `master`
- Status until first successful push: `backup_pending`

## Agent Close-Out Rule

Every agent that makes or closes a commit records backup state in its receipt:

- `backup_status: pushed` when `_Briefs/governance/scripts/push_backup.cmd`
  succeeds.
- `backup_status: backup_pending` when auth, network, LFS, or remote setup blocks
  the push.
- `backup_status: not_applicable` only for read-only sessions with no commit.

## Normal Backup Command

From repo root:

```bat
_Briefs\governance\scripts\push_backup.cmd
```

The script pushes:

- `master`
- all tags, including `pre-edit/*`, `daily/*`, and `week/*`

## First Push Blocker

The repo history contains Godot binaries larger than GitHub's normal Git file
limit. Before the first successful GitHub push, the integration agent must run
Git LFS migration with explicit approval:

```bash
git lfs install
git lfs migrate import --include="Godot_v4.3-stable_*.exe,godot.zip"
```

This rewrites local commit hashes. It is safest before GitHub is live.

## Recovery From GitHub

```bash
git clone https://github.com/kkoonnss/KE_ArKade.git C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade
cd C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade
git lfs pull
git tag -l "daily/*"
git checkout daily/<last-good-date>
```

Then run the README install steps and reinstall hooks:

```bat
_Briefs\governance\scripts\install_hooks_2026-07-01.cmd
```

## If Backup Fails

Do not hide it. The receipt says `backup_pending`, includes the error, and names
the next command or decision needed.
