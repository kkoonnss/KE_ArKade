---
task_id: TASK-INT-hub-scene-ordering-classic-first
stage: 6
wave: 2
priority: P2
lane: hub
status: ready
owner_agent: null
touches: [app/hub/main.gd]
locks_required: [hub-design]
depends_on: []
kind: fix
issued_by: opus_orchestrator
issued_at: 2026-06-30
acceptance:
  - Scenes tab shows the classic pack FIRST, custom scenes AFTER
  - Ordering is stable across hub restart
  - Any user-defined ordering preference (if such state exists) still overrides
  - Kons visual confirmation via one screenshot
---

## Objective

The Scenes tab in the KE_ArKade hub currently shows scenes in an order that
does not prioritize the classic pack. Kons's ask (2026-06-30): the
**classic pack must be the FIRST card**, and custom / user-created scenes
follow after.

## Context

Screenshot 2026-06-30 showed two scene cards side-by-side: "Pack" and
"Scene Demo Wall". Order was not deterministic-classic-first.

## Expected shape of the fix

Likely in `app/hub/main.gd` in whatever function populates the Scenes grid
(look for a `_populate_scenes` or equivalent). The sort key becomes:

1. Classic pack always first (detect by manifest / folder name / a flag).
2. Everything else alphabetical or by mtime (agent's judgment — pick the
   simpler rule).

If the hub already keeps scene metadata, prefer sorting on a `is_classic:
true` field over string matching on the pack name.

## Rules

- Write ONLY inside `app/hub/**`. Everything else read-only. Never edit
  frozen schemas.
- Claim: set `owner_agent` + `status: in_progress`; lock note at
  `vault/35-locks/hub-design.md` (or extend the existing one — verify it's
  not held by another agent first).
- **Pre-edit git commit + tag** required per
  `_Briefs/governance/03_RECOVERY_PROTOCOL.md` §1.2. `main.gd` is > 1000
  lines. Non-negotiable.
- Verify via hub gate (`_Briefs/governance/02_VERIFICATION_GATES.md` §3).
  Restart hub, confirm classic pack shows first, screenshot to
  `vault/70-qa/<agent>_scene_ordering_2026-06-30.png`.
- Close with a receipt per
  `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`. Release the lock.

## Cold-start reads (mandatory before touching main.gd)

1. `_Briefs/governance/01_LANES.md`
2. `_Briefs/governance/02_VERIFICATION_GATES.md`
3. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
4. `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`
5. This ticket.

Also read: `vault/40-agent-runs/reconstructed_antigravity_hub_thumbnails_favorites_2026-06-30.md`
for the prior state of `main.gd`.
