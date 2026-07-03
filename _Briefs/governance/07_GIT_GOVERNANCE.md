---
doc_id: governance-07-git-governance
audience: [orchestrators, codex, antigravity, sonnet, claude_threads]
authority: contract
last_revised: 2026-06-30
notes: A Codex agent is currently solving for GitHub backup + versioning integration. This doc captures the conventions that integration must satisfy; the integration's output should refine this doc, not replace it.
---

# 07 — Git Governance

**Git is the backup, the time machine, and the receipt-of-last-resort.** The
Jun 28-30 corruption recovery would have been a 30-second `git checkout` if
the snapshots had been in place. This document is how we make sure they
always are.

---

## 1. Repo state (as of 2026-06-30)

- Local git repo exists at `C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/.git`.
- 4 commits exist:
  - `7546982` Initial commit of current state (with broken main.gd)
  - `445aa61` Fix Hub UI crashes by simplifying main.gd
  - `cd38c22` Fix Donkey Kong mechanics: barrels kill, fall death, max ladder
  - `ec63df1` Restore Hub graphical cards and favorites logic
- Working tree has heavy uncommitted modifications across hub, shared, and
  many cartridges (recovery aftermath).
- Remote backup (GitHub) is **in progress** — a Codex agent is solving for it.

## 2. Commit conventions

### 2.1 Commit message format

```
<scope>: <short imperative>

<optional body — link to ticket, what & why, what gate it passes>

Ticket: TASK-INT-<slug>
Receipt: vault/40-agent-runs/<filename>.md
```

Examples:

```
cart/pacman: SharedLoader integration + Tab menu

Re-pointed pacman to shared MAZE adapter via SharedLoader.
Removed local class_name reach. Tab menu wired with maze knobs.
Gate: 02_VERIFICATION_GATES.md §2 — passes 1-4, pending Kons launch.

Ticket: TASK-INT-cart-pacman
Receipt: vault/40-agent-runs/antigravity_cart_pacman_2026-06-30.md
```

```
hub/main.gd: restore favorites + thumbnails

Hub UI rebuild after Jun 28 corruption. Favorites array + thumbnail
loading restored; pre-edit snapshot at <hash>.

Ticket: TASK-INT-08-design-save-compile-derived
Receipt: vault/40-agent-runs/antigravity_hub_restore_2026-06-30.md
```

### 2.2 Commit cadence (the snapshot rule)

Per `03_RECOVERY_PROTOCOL.md` §2:

1. **Pre-ticket-claim:** commit current working tree before any edits.
   ```
   git add -A && git commit -m "snap: pre-claim TASK-INT-<slug>"
   ```
2. **Pre-edit (file > 200 lines):** commit before opening the file for
   range-based edits.
   ```
   git add -A && git commit -m "snap: pre-edit <file>"
   git tag pre-edit/<lane>/<topic>/$(git rev-parse --short HEAD)
   ```
3. **Logical-change commits:** one commit per logical change. Fine-grained
   is fine; the bigger the commit, the harder the bisect on a regression.
4. **Per-ticket-close:** final commit captures the closed state.
   ```
   git add -A && git commit -m "<scope>: <change>  (close TASK-INT-<slug>)"
   ```
5. **Daily snapshot tag (orchestrator):**
   ```
   git tag daily/$(date +%Y-%m-%d) HEAD
   ```

### 2.3 What never gets committed

Maintained in `.gitignore` (see §4):

- Throwaway recovery scripts: `fix_*.py`, `patch_*.py`, `recover*.py`,
  `stitch*.py`, `port_hub*.py`, `add_*.py`, `rebuild_*.py`, `refactor_*.py`,
  `implement_*.py`, `integrate_*.py`, `tile_*.py`, `gap_fill.py`,
  `gen_seed.py`, `clean_*.py`, `smart_*.py`, `visual_*.py`,
  `find_main_gd_history.py`, `debug_runner.py`.
- Diagnostic output dumps: `*_err*.txt`, `*_out*.txt`, `*_err.log`,
  `*_out.log`, `*_qc.{err,out}.log`, `godot_log.txt`, `run_test.txt`,
  `syntax_err*.txt`, `syntax_out*.txt`.
- Recovery artifacts: `recovered_*.gd`, `stitched_*.gd`, `main_backup.gd`,
  `main_dump*.txt`, `extracted_funcs.txt`, `recover_log.txt`.
- Test scaffolds at repo root: `test_*.gd`, `test_load.gd`, `test_loader.gd`,
  `test_repo_root.gd`, `test_crash.gd`, `test_pacman_gal.gd`,
  `test_sort.gd` (if confirmed scratch), `test_dk_classic.gd`.
- Binaries: `godot.zip`, `Godot_v4.3-stable_*.exe` (these stay at repo
  root for now but should NOT be in git history — see §5).
- IDE artifacts: `.vs/`, `.idea/`, `*.iml`.
- OS junk: `Thumbs.db`, `.DS_Store`.

## 3. Branch strategy

For now: **single `main` branch**, no feature branches. The lane system
(`01_LANES.md` §1) provides the collision-free guarantee that branches
would otherwise enforce. Cross-lane PRs are not a thing — every agent
commits directly to `main` on its own folder.

When the Codex GitHub integration lands, we may revisit:

- A `release/<date>` tag pattern for milestones.
- A short-lived `recovery/<topic>` branch for in-flight repairs that
  shouldn't pollute `main` until verified.

Either is additive; the single-`main` default stays the baseline.

## 4. The `.gitignore` patch

Current `.gitignore` is 116 bytes (minimal). The orchestrator patches it to
cover §2.3. See `_Briefs/governance/scripts/gitignore_patch.txt` if/when
issued as part of the cleanup pass.

The patch is append-only — never remove existing entries without an
orchestrator review.

## 5. Binaries at repo root

`Godot_v4.3-stable_win64.exe` (133 MB), `Godot_v4.3-stable_win64_console.exe`
(198 KB), and `godot.zip` (57 MB) are at repo root. They were committed
historically because the repo was treated as the Godot install. **They
should be replaced with a documented install step** so future clones
don't carry the binaries.

This is an open item for the GitHub integration agent. Until resolved, the
binaries stay where they are (changing them now would invalidate every
agent's `app/hub/launcher/*.gd` references).

## 6. Recovery via git (the §3 of `03_RECOVERY_PROTOCOL.md`, expanded)

When a file is corrupted:

```
# Find the last good state
git log --oneline -20 -- <file>

# Restore that version into the working tree
git checkout <hash> -- <file>

# Or, if multiple files are involved, restore a whole subtree
git checkout <hash> -- app/hub/
```

If a `pre-edit` tag exists (per §2.2):

```
git checkout pre-edit/<lane>/<topic>/<short-hash> -- <file>
```

The recovery is a one-liner. The reason the Jun 28-30 recovery took three
days and 13 scripts is that the pre-edit snapshots did not exist. They
do now (in this doc; once §2.2 is followed in dispatch prompts).

## 7. GitHub remote + offsite backup

This repo now treats GitHub as the off-machine backup target. The local repo
remains the working source of truth, but `origin` is the disaster-recovery
copy that must stay close behind it.

- Remote URL: `PENDING_KONS_PRIVATE_REPO_URL`
- Default branch: `master`
- Manual push script: `_Briefs/governance/scripts/push_backup.cmd`
- Automatic push hook: `.git/hooks/post-commit`

### 7.1 Remote wiring

Once Kons creates the private GitHub repo, wire it with:

```bash
git remote add origin <github-private-url>
git remote -v
```

If `origin` already exists, update it instead of adding a second remote:

```bash
git remote set-url origin <github-private-url>
git remote -v
```

### 7.2 Push cadence

The cadence is now explicit and enforced by tooling:

- After every ticket-close commit: push `master` to `origin`.
- After every daily snapshot tag: push tags to `origin`.
- After every weekly snapshot tag: push tags to `origin`.
- Any time the automatic hook fails because the network is down: the local
  commit still stands; rerun `_Briefs/governance/scripts/push_backup.cmd`
  manually and it will catch up.

`push_backup.cmd` always does:

```bash
git push origin master
git push origin --tags
```

The post-commit hook starts that script in the background so commits do not
wait on the network. If `origin` is not configured yet, the script logs a
warning and exits cleanly.

### 7.3 Branch protection rules

On the GitHub repo, configure branch protection for `master` with:

- Require linear history: enabled.
- Allow force pushes: disabled.
- Allow deletions: disabled.

Tags are treated as immutable backups:

- Do not move or delete `pre-edit/*`, `daily/*`, or `week/*` tags after they
  are pushed.
- If GitHub rulesets are available, add a tag protection/ruleset that blocks
  tag deletion and tag updates for those patterns.

### 7.4 Recovery from remote

If the local checkout is lost or suspect:

```bash
git clone <github-private-url> C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade
cd C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade
git tag -l "daily/*"
git checkout daily/<last-good-date>
```

Then:

1. Reinstall the local-only Godot executables per `README.md`.
2. Reinstall hooks with `_Briefs/governance/scripts/install_hooks_2026-07-01.cmd`.
3. If a working branch tip is needed rather than a snapshot, return to
   `master` after inspection with `git checkout master`.

This is the offsite version of `03_RECOVERY_PROTOCOL.md` §5 Step 3: clone
fresh, inspect the snapshot tags, and restore from the last known good state
before attempting any stitching or manual repair.

## 8. Pre-commit checks (light, conceptual)

Not yet wired (no hooks). Future: a `.git/hooks/pre-commit` that runs:

- No file in repo root matches `fix_*.py`, `patch_*.py`, `recover*.py`,
  `stitch*.py`, `*_err*.txt`, `*_out*.txt`. (Catch the cruft drift.)
- Every `.md` in `vault/30-tasks/` has valid YAML frontmatter.
- Every closed ticket has its `closing_receipt` path valid.

This is a "would be nice" — not blocking on it. The orchestrator sweep
(`05_ORCHESTRATOR_RUNBOOK.md` §2) catches the same drift, just on a longer
cadence.

## 9. The orchestrator's git toolkit

The orchestrator regularly runs:

```
git status -s                                  # what's uncommitted
git log --oneline -10                          # recent commits
git log -- <file>                              # file history
git diff <hash> -- <file>                      # what changed since
git tag -l 'pre-edit/*'                        # find pre-edit snapshots
git tag -l 'daily/*' | sort | tail -7          # last week of daily tags
git checkout <hash> -- <file>                  # restore
```

These do not violate the orchestrator's "no code" rule — they are
inspection and snapshot operations, which are part of holding the chair.

---

*Authority: this document. Companions: [[03_RECOVERY_PROTOCOL]] (when to
restore), [[06_VAULT_HYGIENE]] (the sweep cadence), [[05_ORCHESTRATOR_RUNBOOK]]
(daily-tag obligation). Index: [[00_README]].*
