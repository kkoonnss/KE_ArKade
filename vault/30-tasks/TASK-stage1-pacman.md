---
task_id: TASK-stage1-pacman
stage: 1
status: done
owner_agent: Antigravity
touches: [content/cartridges/pacman]
locks_required: [pacman]
acceptance:
  - Enemies move along navgraph
  - Pickup collection and score logic works
  - Win (all pickups) and lose (caught) states handled, with lives and restart
  - Keyboard and 1-4 controllers supported
  - Score and state emitted over IPC
  - Playable on the provided demo map
---

## Objective
Make Pac-Man fully playable as a proper MVP game. Implement core game loop logic: enemies, lives, win/lose states, and input mapping. Ensure IPC state is sent back to the Hub correctly.
