# QA - Classic ID Normalization

Date: 2026-06-25
Agent: Codex

## Scope

Normalized live cartridge IDs, folder names, classic-pack level IDs, hub mappings, active task filenames, and task lock/touch tags to use classic game names instead of prototype/reskin names.

## Examples

- `barrel_jumper` -> `donkey_kong`
- `brick_breaker` -> `breakout`
- `maze_chase` -> `pacman`
- `block_stack` -> `tetris`
- `boomer_man` -> `bomberman`
- `neon_trace` -> `on_track`
- `tank_zone` -> `battlezone`
- `street_job` -> `gta`

## Validation

- All 32 real cartridge folders under `content/cartridges/` passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<classic_id> --quit`
- Hub smoke passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path app/hub --quit`
- Live ID scan passed for `app`, `content`, `vault/30-tasks`, `vault/40-agent-runs`, `vault/50-schemas`, `vault/70-qa`, `scratch`, and `_Briefs` excluding raw logs and binary assets.

## Notes

- Historical/frozen planning prose still mentions original homage names such as Lumen Maze and Neon Stack where it describes the old MVP plan. Live folders, task tags, manifests, and routing now use classic IDs.
- Secondary skin names such as Neon Stack and Boomer Man were left for the later reskin pass.
