# QA - Per-Cartridge Level Adjustments Helper

Date: 2026-06-22
Agent: Codex

## Result

Pass.

## Checks

- `on_track` headless `--quit`: pass.
- `frogger` headless `--quit`: pass.
- `bomberman` headless `--quit`: pass.
- `on_track` headless `--quit` with `classic_on_track` level args: pass.
- `frogger` headless `--quit` with `classic_frogger` level args: pass.
- `bomberman` headless `--quit` with `classic_bomberman` level args: pass.
- Helper file hash consistency: pass.
- Direct `settings.json` writes removed from migrated main scripts: pass.

## Notes

Each migrated cartridge now owns a `user://level_adjustments.json` registry. The helper keeps old level-folder `settings.json` readable as a migration fallback, but new Tab-menu saves use the registry pattern.

Screenshot runtime smoke launches timed out because these cartridges do not yet
share a bounded runtime quit harness.
