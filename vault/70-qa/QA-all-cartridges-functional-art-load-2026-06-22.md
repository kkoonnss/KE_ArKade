# QA - All Cartridges Functional, Art, and Load Pass

Date: 2026-06-22
Agent: Codex
Target: 30 cartridges in `content/cartridges/`, excluding `loopback`

## Result

Pass. All 30 real cartridges launch, load the demo wall level path where supported, render gameplay after their splash/cover, and produce valid nonblank screenshots.

## Checks Performed

- Godot parser checks for patched scripts.
- Required headless launch command for every cartridge.
- Bounded headless runtime load for every cartridge.
- Error scan across full QC runtime logs.
- Strict PNG validation/re-encode for cartridge splash and thumbnail assets.
- OpenGL screenshot capture for every cartridge after splash.
- Pixel-level validation of screenshot dimensions, nonblack content, bright gameplay detail, and dark projection corners.

## Pixel Audit

- Screenshots checked: 30
- Warnings: 0
- Failures: 0
- Resolution observed: 1920x1080 for every gameplay screenshot

Audit artifact:
`vault/70-qa/all_cartridge_gameplay_pixel_audit_2026-06-22.csv`

## Visual Evidence

- Gameplay contact sheet:
  `vault/70-qa/all_cartridge_gameplay_contact_sheet_2026-06-22.png`
- Splash/cover contact sheet:
  `vault/70-qa/all_cartridge_splash_contact_sheet_2026-06-22.png`
- Individual gameplay screenshots:
  `vault/70-qa/<cartridge>_full_qc_gameplay.png`

## Notes

- `tetris` initially captured cover art during screenshot QA because its capture delay was shorter than its splash duration. The hook now waits until after splash fade, and the recaptured frame passes.
- `bomberman`, `on_track`, and `frogger` now support the same post-splash screenshot workflow used by the other cartridges.
- `on_track` and `frogger` now honor Godot user args passed after `--`.
