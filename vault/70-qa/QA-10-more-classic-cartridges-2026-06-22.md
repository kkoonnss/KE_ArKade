# QA - 10 More Classic Cartridges

Date: 2026-06-22
Runner: Codex
Level used: `content/scenes/scene_demo_wall/levels/demo_level`

## Result
Pass. All ten cartridges parse, satisfy the requested Godot headless validation command, launch for bounded runtime, and render post-splash gameplay screenshots on pure black.

## Evidence
| Cartridge | Runtime log | Screenshot |
|---|---|---|
| Donkey Kong | `vault/70-qa/donkey_kong_runtime.log` | `vault/70-qa/donkey_kong_gameplay.png` |
| Breakout | `vault/70-qa/breakout_runtime.log` | `vault/70-qa/breakout_gameplay.png` |
| Bubble Bobble | `vault/70-qa/bubble_bobble_runtime.log` | `vault/70-qa/bubble_bobble_gameplay.png` |
| Dig Dug | `vault/70-qa/dig_dug_runtime.log` | `vault/70-qa/dig_dug_gameplay.png` |
| Gauntlet | `vault/70-qa/gauntlet_runtime.log` | `vault/70-qa/gauntlet_gameplay.png` |
| Marble Madness | `vault/70-qa/marble_madness_runtime.log` | `vault/70-qa/marble_madness_gameplay.png` |
| Joust | `vault/70-qa/joust_runtime.log` | `vault/70-qa/joust_gameplay.png` |
| Snake | `vault/70-qa/snake_runtime.log` | `vault/70-qa/snake_gameplay.png` |
| Tapper | `vault/70-qa/tapper_runtime.log` | `vault/70-qa/tapper_gameplay.png` |
| Tempest | `vault/70-qa/tempest_runtime.log` | `vault/70-qa/tempest_gameplay.png` |

## Checks
- Parser: all ten `main.gd` files passed Godot 4.3 `--check-only`.
- Required validation: all ten passed `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cartridge_dir> --quit`.
- Runtime: all ten scenes loaded with `--quit-after 20`, exit code `0`.
- Runtime log scan: no `ERROR`, `SCRIPT ERROR`, `Invalid`, `Parse Error`, `Cannot`, or `Failed` matches.
- Visual: all ten screenshots are 1920x1080, post-splash, and contain nonblack neon gameplay content.
- Black-base pixel sample: all ten screenshots reported `(0, 0, 0)` at all four corners.

## Pixel Sample Summary
| Cartridge | Corner result | Sampled nonblack pixels |
|---|---:|---:|
| Donkey Kong | black | 247 / 5184 |
| Breakout | black | 228 / 5184 |
| Bubble Bobble | black | 269 / 5184 |
| Dig Dug | black | 842 / 5184 |
| Gauntlet | black | 140 / 5184 |
| Marble Madness | black | 169 / 5184 |
| Joust | black | 268 / 5184 |
| Snake | black | 111 / 5184 |
| Tapper | black | 232 / 5184 |
| Tempest | black | 248 / 5184 |

## Residual Risk
- No live hub socket integration test was run in this pass; IPC command handling is implemented and covered by parse/runtime validation.
- Gameplay loops are playable first passes; deeper tuning, sound, and per-title polish remain future polish work.

