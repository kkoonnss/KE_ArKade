---
task_id: TASK-cube-hopper
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/qbert]
locks_required: [qbert]
acceptance:
  - Q*bert fully playable logic implemented (hopping on cubes, changing colors, avoiding Qbert-enemies)
  - Reads container.json / grid.json and parses the isometric/grid cubes layout
  - Handled input (controllers/keyboard) and updates score / emits to hub over IPC
  - Visually reskinned to high-contrast neon/vector style compliant with design system
---

# Objective
Flesh out the `qbert` cartridge stub into a fully playable Q*bert clone, utilizing the level container boundaries and grid to render and navigate the isometric pyramid of cubes.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
