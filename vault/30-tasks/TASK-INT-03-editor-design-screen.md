---
task_id: TASK-INT-03-editor-design-screen
stage: 6
wave: 0
priority: P0
lane: hub
archetype: n/a
status: done
owner_agent: "Antigravity"
touches: [app/hub]
locks_required: [hub-design]
depends_on: []
acceptance:
  - A "Design" screen exists in the hub (app/hub/**), styled to the design system (black base, thin white structure, cyan-led neon)
  - Slider mode (photo -> zones) and paint mode (paint semantic classes over a photo, opacity toggle) both work and write a clean semantic_map.png + level.yaml
  - Heavy photo->map auto-derive is delegated to the swappable Python/OpenCV backend (calls TASK-INT-00's compile_level / authoring derive), NOT reimplemented in GDScript -> keeps it Pi-portable
  - On save, triggers the compile-all-derived step so the new level has a full derived/ set
  - LIVE PREVIEW -> reuses the shared archetype adapters (TASK-INT-01) to show "how would Pac-Man / Tetris / Frogger fill this map" in place; wire this once INT-01 is frozen
  - Output is schema-conformant; verified by authoring a fresh level and launching two different cartridges on it unchanged
---

## Objective
Move the level editor off the dated standalone Tkinter tool and into the hub as a controller-ready Design screen (its planned Phase-2 home). Keep the editor's job identical — produce a clean neutral map + derived layers — but unify it with the arcade, dress it to the design system, and add a live preview that runs the real game adapters so authoring becomes the fun "watch the games populate the space" ritual.

## Notes
- `app/hub` tree — coordinate with TASK-INT-04 (same lane): one owner at a time, or do 03 then 04.
- Heavy CV stays in Python (`tools` lane backend) so this screen runs on a Raspberry Pi later; design for Pi, do not optimize Pi perf now.
- Live-preview wiring depends on INT-01; the scaffold/slider/paint/save can land first.
