---
task_id: TASK-stage3-content-depth
stage: 3
status: done
owner_agent: Antigravity-Orchestrator
touches: [app/tools/level_authoring, content/scenes/scene_demo_wall]
locks_required: [tools, scenes]
acceptance:
  - Level authoring tool is polished (slider + paint modes) and emits valid schemas
  - Second level authored in scene_demo_wall
  - Level-swap verified at <10s with same cartridges reading different maps
---

## Objective
Prove the content thesis again. Fix up the level authoring tool, paint a brand new level, compile it, and prove the Hub can swap levels fast while games just consume the new map seamlessly.
