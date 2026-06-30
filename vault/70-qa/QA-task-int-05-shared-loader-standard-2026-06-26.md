# QA - TASK-INT-05 Shared Loader Standard

Date: 2026-06-26
Agent: KE_ArKade_260626_132556

Pass.

Verified GTA as the canonical separate-process cartridge consumer of shared code.

Evidence:
- `vault/70-qa/gta_classic_shared_loader_2026-06-26.png`
- `vault/70-qa/gta_demo_wall_shared_loader_2026-06-26.png`

Runtime proof:
- `classic_gta` launched through GTA and loaded the shared Region adapter with `grid=40x23`, `fallback=false`.
- `scene_demo_wall/levels/demo_level` launched through GTA and loaded the shared Region adapter with `grid=21x31`, `fallback=false`.
- Shared Tab menu was visible in screenshot evidence.
- Both screenshots saved through Windows/OpenGL with `err=0`.
- Pixel audit confirmed both screenshots are 1920x1080 and nonblank.

Standard proof:
- `app/shared/shared_loader.gd` resolves repo root from cartridge `res://`.
- GTA uses `SharedLoader`, not `RegionAdapter.new()` or typed `TabMenu`.
- GTA does not carry a local `adapter_base.gd`.
