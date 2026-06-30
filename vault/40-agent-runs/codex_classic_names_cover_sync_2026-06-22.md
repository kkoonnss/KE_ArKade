# Codex Run Log - Classic Names and Cover Sync

Date: 2026-06-22
Agent: Codex
Scope: cartridge display names, in-game title maps, three missing covers, and `scene_classic_pack` thumbnails

## Changes

- Updated all real cartridge manifests to use classic display names for now.
- Updated copied in-game title maps so HUD/title text also uses classic names.
- Regenerated the three text-only cover cards:
  - `qbert` -> `Q*bert`
  - `robotron_2084` -> `Robotron: 2084`
  - `galaga` -> `Galaga`
- Added `classic_on_track -> on_track` to the hub's classic-level alias mapping.
- Synced every `content/scenes/scene_classic_pack/levels/*/thumbnail.png` from its paired cartridge thumbnail.

## Verification

- 30 cartridge parser checks passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --check-only --script res://main.gd`
- Hub standalone manifest load test passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path app/hub --script res://test_load_cartridges.gd`
- Hub standalone level sort/name test passed:
  `Godot_v4.3-stable_win64_console.exe --headless --path app/hub --script res://test_sort.gd`
- PNG verification passed for cartridge splash/thumbnail assets and classic-pack level thumbnails.
- Thumbnail sync audit passed:
  - `classic_level_thumbnail_pairs=31`
  - `errors=[]`
- Old in-game title-map scan passed:
  - `old_title_map_hits=[]`

## Evidence

- Classic-pack thumbnail contact sheet:
  `vault/70-qa/classic_pack_thumbnail_sync_contact_sheet_2026-06-22.png`
- Hub manifest test output confirmed all 30 classic names, including `Q*bert`, `Robotron: 2084`, and `Galaga`.

## Caveat

Full hub project launch with `--quit-after` crashed inside Godot with signal 11 before script diagnostics, both in headless and Windows/OpenGL modes. The standalone hub data tests passed, and all cartridge parser checks passed, so the data/name/thumbnail changes are verified independently of that engine startup issue.
