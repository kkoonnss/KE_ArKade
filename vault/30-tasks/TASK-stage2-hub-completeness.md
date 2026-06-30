---
task_id: TASK-stage2-hub-completeness
stage: 2
status: done
owner_agent: Antigravity-Orchestrator
touches: [app/hub]
locks_required: [hub]
acceptance:
  - Scenes gallery and level swiper dynamically scan and work
  - Devices screen maps controller slots 1-4
  - Calibrate screen wires manual 4-point flow to the calibration tool and saves to scene
  - Service screen works (LKG restore, blank, log view)
  - override.cfg support + compatibility gate enforced
---

## Objective
Complete the Hub UI to full Kiosk readiness. It must handle controller slot assignment natively, launch tools correctly, and enforce schema compatibility before launching a game.
