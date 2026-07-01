---
run_id: reconstructed_antigravity_hub_thumbnails_favorites_2026-06-30
kind: reconstructed_receipt
severity: hygiene_gap
agent: antigravity_hub_post_corruption
reconstructed_by: opus_orchestrator
session_start: 2026-06-30 (approx)
session_end: 2026-06-30T~20:30Z (last hub commit before governance pass)
task_id: (informal — hub post-corruption regression fix)
lane: hub
lock_held: hub-design
status: done
closed_at: 2026-06-30
closed_by: opus_orchestrator
kons_confirmation: "2026-06-30 — Kons confirmed tabs load and thumbnails/favorites render in the live hub. Minor layout polish outstanding, deferred to Wave 3 (non-blocking)."
pre_edit_commit: ec63df1 (previous hub-restore commit)
close_commits:
  - c277267 "Tweak Hub UI to fix grid layout and simplify classic labels"
  - 396be42 "Update game card layout to match design and implement favorite sections"
  - c487a70 "Fix UI container visibility logic and initialize scroll_vbox correctly"
escalations: []
---

# RECONSTRUCTED — Antigravity hub thumbnails/favorites recovery

**This receipt is reconstructed retrospectively.** The Antigravity agent that
Kons dispatched on 2026-06-30 to fix the post-corruption thumbnails/favorites
regression made three commits to `app/hub/main.gd` and left a chat summary,
but did NOT write a receipt in `vault/40-agent-runs/`. This file closes that
gap so the vault reflects reality.

Same failure pattern as the Jun 28-30 corruption itself: work happens, no
durable record follows. Governance pack (`_Briefs/governance/06_VAULT_HYGIENE.md`
§6.1) tracks this as a hygiene failure mode. Reconstruction is the fix.

---

## Summary (from AG's own message in chat)

AG rewrote the code that displays the custom Favorites sections in the hub's
Games tab. In the initial rewrite, AG did NOT instantiate the master
scrolling container (`scroll_vbox`) in `_ready()`. Because `scroll_vbox` was
null, clicking the Games tab caused a null-reference error inside the UI
script. The layout process aborted mid-execution, leaving the Games tab
blank AND leaving the Scenes grid visibility locked to `false`, which meant
every other tab also went blank on click.

Kons noticed the regression from the live UI. AG applied a hotfix
(commit `c487a70`) that:

1. Safely initializes `scroll_vbox` on startup.
2. Adds a safeguard that explicitly resets grid visibility on every tab
   switch.

AG reported the fix landed but did not verify the visual result — that
remains `pending_kons_verify`.

## Commits attributed to this session

| Hash | Message |
|---|---|
| `c277267` | Tweak Hub UI to fix grid layout and simplify classic labels |
| `396be42` | Update game card layout to match design and implement favorite sections |
| `c487a70` | Fix UI container visibility logic and initialize scroll_vbox correctly |

`c277267` was the grid/labels pass. `396be42` introduced the Favorites
sections + new game card layout. `c487a70` is the hotfix that resolved the
null-ref regression `396be42` created.

## Verification (what still needs to happen)

Per `_Briefs/governance/02_VERIFICATION_GATES.md` §3 (hub gate):

- [ ] `app/hub/main.gd` parses (no Parse Error). — implied by AG's commit
      succeeding; not independently verified.
- [ ] Hub boots to main screen without grey-screen. — Kons's screenshot
      2026-06-30 shows the hub booting, so YES prior to hotfix.
- [ ] Thumbnails render on scene cards. — screenshot showed cards blank.
      **Verify post-hotfix.**
- [ ] Favorites section renders in Games tab. — introduced by `396be42`.
      **Verify post-hotfix.**
- [ ] Every tab switches without going blank. — the specific regression
      `c487a70` targets. **Verify post-hotfix.**
- [ ] **Kons launch confirmation** — pending.
- [ ] Pre-edit snapshot commit hash named in this receipt. — used
      `ec63df1` (the last known-good hub commit before this session).

Steps 1-5: pending Kons restart + spot-check.

## What was NOT verified

- Whether AG followed the pre-edit snapshot rule (governance pack §1.2).
  Given the pack didn't exist yet during AG's session, this is a
  timing-excused gap. Going forward, the pack applies.
- Whether AG released the `hub-design` lock. **The lock is still present
  at `vault/35-locks/hub-design.md` with content "Working on design screen
  save robust execution".** Either the lock is stale (AG's session ended
  without release) or it's still live (AG is still coordinating INT-08/09).
  Orchestrator to resolve on next sweep.

## Scratch files this session left behind

Discovered post-commit, added to `.gitignore` retroactively:

- `rewrite_hub.py`, `safe_rewrite.py`, `tweak_ui2.py` at repo root
- `app/hub/main_backup.gd`, `app/hub/main_dump.txt`, `app/hub/main_dump2.txt`,
  `app/hub/test_hub.gd`

None are load-bearing. Cleanup script: `_Briefs/governance/scripts/cleanup_2026-06-30_addendum.cmd`.

## Prevention rules

Already codified in the governance pack (landed same day as this
reconstruction, so this session predates the rules):

1. `04_AGENT_HANDOFF_TEMPLATE.md` — every session writes this. Non-negotiable.
2. `06_VAULT_HYGIENE.md` §6.1 — missing handoff is a tracked hygiene
   failure. Orchestrator reconstructs from git + chat + pings agent.
3. `07_GIT_GOVERNANCE.md` §2 — commit cadence + pre-edit snapshot.
4. Dispatch prompt template (`05_ORCHESTRATOR_RUNBOOK.md` §3) makes the
   four mandatory reads part of every agent's cold-start.

## Next holder briefing

If you take the hub lane next:

1. Confirm the `hub-design` lock: is it stale (delete) or held (respect)?
   Message `AGENT_SYNC.md` if uncertain.
2. **Kons has a specific outstanding ask:** the Scenes tab should show the
   Classic pack FIRST, then custom scenes AFTER. Screenshot 2026-06-30
   shows "Pack" and "Scene Demo Wall" side-by-side without a clear
   ordering guarantee. This is a small `_populate_scenes` (or equivalent)
   sort tweak — likely a 5-line change. Ticket to be issued as
   `TASK-INT-hub-scene-ordering-classic-first`.
3. Verify AG's hotfix (`c487a70`) actually restored favorites + all-tab
   switching. If not, that's a Wave-2 fix, not a Wave-3 polish.
4. Do NOT edit `main.gd` without a fresh pre-edit `git tag pre-edit/hub/...`
   snapshot. The rules apply now.

---

*Reconstructed 2026-06-30 by the Opus orchestrator per governance pack
`06_VAULT_HYGIENE.md` §6.1. Original session: Antigravity, 2026-06-30.*
