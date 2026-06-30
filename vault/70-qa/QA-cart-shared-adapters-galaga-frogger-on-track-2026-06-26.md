# QA - Shared Adapter Cartridges

Date: 2026-06-26
Agent: KE_ArKade_260626_132556

Pass.

Validated Galaga, Frogger, and On Track on both:
- `content/scenes/scene_demo_wall/levels/demo_level`
- Their matching `content/scenes/scene_classic_pack/levels/classic_*` level

Evidence:
- `vault/70-qa/galaga_demo_wall_shared_arena_2026-06-26.png`
- `vault/70-qa/galaga_classic_shared_arena_2026-06-26.png`
- `vault/70-qa/frogger_demo_wall_shared_lane_2026-06-26.png`
- `vault/70-qa/frogger_classic_shared_lane_2026-06-26.png`
- `vault/70-qa/on_track_demo_wall_shared_track_2026-06-26.png`
- `vault/70-qa/on_track_classic_shared_track_2026-06-26.png`

Checks:
- Standalone headless parser/startup passed for all three cartridges.
- Windows/OpenGL screenshots saved with `err=0`.
- Screenshots are 1920x1080, nonblank, and show shared Tab/start menu overlay over live cartridge content.
- Map-backed playfields are nonempty on demo wall and classic levels.
- Shared adapter source is consumed from `app/shared/adapters/**`; local `adapter_base.gd` bridge exists only to let standalone cartridge projects compile the shared adapter scripts.

Residual note:
- Godot headless dummy rendering cannot produce viewport texture screenshots, so visual screenshots use the real OpenGL render path.
