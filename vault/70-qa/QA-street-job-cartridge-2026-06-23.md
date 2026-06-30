# QA - GTA Cartridge - 2026-06-23

## Result
Pass for Godot headless startup/parser validation.

## Verified
- New cartridge folder exists with manifest, Godot project, main scene, script, splash, and thumbnail.
- New `classic_gta` level exists in `scene_classic_pack` with `level.yaml`, `semantic_map.png`, and `thumb.png`.
- Hub classic-level mapping includes `classic_gta -> gta`.
- Standalone cartridge loads headless.
- Cartridge loads headless with the classic level path supplied.
- Hub loads headless after mapping changes.

## Remaining Risk
Headless validation does not simulate gameplay input. Manual playtest should verify:
- Enter/exit car feel.
- Car collision/wanted-star tuning.
- Cops' pursuit pressure.
- Payphone/package/dropoff readability.
- Whether traffic and pedestrian density should become Tab-menu settings.
