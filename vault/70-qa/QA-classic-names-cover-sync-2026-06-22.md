# QA - Classic Names and Cover Sync

Date: 2026-06-22
Agent: Codex

## Result

Pass for the requested data/art sync:

- Cartridge picker names now come from classic `game_name` values.
- In-game title maps now use classic names.
- The text-only `Q*bert`, `Robotron: 2084`, and `Galaga` covers were replaced with proper neon cover cards.
- `scene_classic_pack` level thumbnails now match their paired cartridge thumbnails.

## Checks

- Cartridge scripts parsed cleanly: 30/30.
- Hub manifest-loading test listed all 30 classic names correctly.
- Hub classic-level name sorting test passed.
- PNG validation passed.
- Classic-pack thumbnail hash sync passed for 31 level folders.

## Evidence

Contact sheet:
`vault/70-qa/classic_pack_thumbnail_sync_contact_sheet_2026-06-22.png`

Run log:
`vault/40-agent-runs/codex_classic_names_cover_sync_2026-06-22.md`

## Caveat

The full hub launch path crashed in Godot with signal 11 during this run, before useful script output. The standalone hub tests that exercise cartridge manifest loading and classic level naming passed.
