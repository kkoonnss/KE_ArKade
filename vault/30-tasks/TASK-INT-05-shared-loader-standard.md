---
task_id: TASK-INT-05-shared-loader-standard
stage: 6
wave: 0
priority: P0
lane: shared
archetype: n/a
status: done
owner_agent: "KE_ArKade_260626_132556"
touches: [app/shared, content/cartridges/gta]
locks_required: [shared-adapters, cart-gta]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit]
acceptance:
  - "Root cause documented: each cartridge is a SEPARATE Godot project (own project.godot, res:// = its own folder); app/shared is OUTSIDE that res://, so global class_name (RegionAdapter, TabMenu, etc.) does NOT resolve inside a cartridge project. gta currently calls RegionAdapter.new() and will fail to load; Codex's galaga/frogger/on_track work only by copying adapter_base.gd locally."
  - "app/shared/shared_loader.gd added -> SharedLoader with static helpers that resolve the repo root from inside a cartridge (ProjectSettings.globalize_path('res://') walked up to the KE_ArKade root) and load any adapter + the tab_menu by ABSOLUTE path, returning ready-to-instance script resources. Works whether launched by the hub or run directly."
  - "Cross-project inheritance blocker removed -> the 7 adapters no longer depend on a global `extends AdapterBase`; either fold the base helpers in or load AdapterBase by absolute path, so NO cartridge ever needs a local copy of adapter_base.gd."
  - "gta retrofitted as the CANONICAL model -> loads RegionAdapter + TabMenu via SharedLoader (zero reliance on class_name), and ACTUALLY RUNS: launch gta on the classic_gta level and a demo_wall level; screenshot proof it reads the map + the Tab menu opens. This is the copy-me reference for every cartridge."
  - "app/shared/README.md documents the standard + a 3-5 line copyable loader snippet every cartridge pastes; the integration gate becomes: cartridge uses SharedLoader (not class_name) and has NO local adapter_base.gd."
---

## Objective
Bless ONE mechanism for separate-process cartridges to consume the shared library, before 30 cartridges each invent their own. Build a small SharedLoader in app/shared, make the adapters loadable cross-project by absolute path (drop the global-class dependency), and retrofit gta to prove it runs. This converts the fan-out into true copy-paste and prevents the inconsistency already seen (gta = broken class_name; Codex games = local file copies).

## Why this gates the cascade
The 7 archetype adapters (TASK-INT-01) were built assuming `class_name` is globally visible. It isn't, across separate Godot projects. Until there's a working, copyable loader pattern, every cartridge integration is either broken (gta) or duplicative (galaga/frogger/on_track). Fix the seam once.

## Notes
- Owns app/shared + content/cartridges/gta (lock both). One agent, no concurrency in app/shared.
- Codex already wrote a working repo-root loader for galaga (`_load_shared_adapter`, globalize_path walk) — harvest that approach, but eliminate the local adapter_base.gd copy and standardize it in app/shared.
- galaga/frogger/on_track keep their `status: done` (they run); they get a small cleanup pass later to drop their local adapter_base.gd and adopt SharedLoader. Track in OPEN_QUESTIONS.
- After this closes: gta is the canonical model; pacman/tetris/donkey_kong/rampage build against it; THEN the families cascade.
