---
task_id: TASK-stage1-tetris
stage: 1
status: done
owner_agent: Tetris Dev
touches: [content/cartridges/tetris]
locks_required: [tetris]
acceptance:
  - Full falling block rules inside non-rectangular well
  - Scoring and line clears implemented
  - 1-4 player slots supported, sharing the mapped well
  - Controls map to keyboard/gamepads
  - Score and state emitted over IPC
---

## Objective
Make Tetris fully playable as a multiplayer, physics-bounded MVP game. Implement dropping, rotation, soft/hard drop, line clears, and Game Over logic. The twist is 1-4 players share the exact same well.
