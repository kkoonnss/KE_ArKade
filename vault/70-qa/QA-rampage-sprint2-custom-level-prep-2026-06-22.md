# QA - Rampage, Sprint 2, and Custom-Level Prep

Date: 2026-06-22
Agent: Codex

## Result

Pass.

- Rampage cartridge added and playable.
- Sprint 2 on-track racing tester added through `on_track`.
- `classic_rampage` tester level added.
- `classic_on_track` and `classic_on_track` now have explicit track centerline data.
- All 31 real cartridges passed custom-level compliance audit.

## Validation Summary

- Parser checks: 31/31 passed.
- Required headless launch checks: 31/31 passed.
- Rampage custom-level load: passed.
- Sprint 2 custom-level load: passed.
- Hub manifest load test: passed, 31 cartridges.
- Hub level sort/name test: passed.
- Custom-level compliance audit: 31 checked, 0 warnings.
- PNG/thumbnail sync audit: 32 classic-pack level thumbnails checked, 0 errors.

## Visual Evidence

- `vault/70-qa/rampage_classic_gameplay_2026-06-22.png`
- `vault/70-qa/sprint2_classic_on_track_gameplay_2026-06-22.png`
- `vault/70-qa/classic_pack_thumbnail_sync_contact_sheet_2026-06-22.png`

## Caveat

Godot crashed with signal 11 when Rampage was run with the `--log-file` option in headless mode. Running the same headless custom-level validation without `--log-file` passed, and the OpenGL screenshot path passed.
