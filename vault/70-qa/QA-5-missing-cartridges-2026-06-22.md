# QA - 5 Missing Cartridges

Date: 2026-06-22
Runner: Codex
Level used: `content/scenes/scene_demo_wall/levels/demo_level`

## Result
Pass. The five remaining prototype cartridge folders are now playable and validated.

## Evidence
| Cartridge | Runtime log | Screenshot |
|---|---|---|
| Asteroids | `vault/70-qa/asteroids_runtime.log` | `vault/70-qa/asteroids_gameplay.png` |
| Tron | `vault/70-qa/tron_runtime.log` | `vault/70-qa/tron_gameplay.png` |
| Pong | `vault/70-qa/pong_runtime.log` | `vault/70-qa/pong_gameplay.png` |
| Smash TV | `vault/70-qa/smash_tv_runtime.log` | `vault/70-qa/smash_tv_gameplay.png` |
| Battlezone | `vault/70-qa/battlezone_runtime.log` | `vault/70-qa/battlezone_gameplay.png` |

## Checks
- Parser: all five `main.gd` files passed Godot 4.3 `--check-only`.
- Required validation: all five passed `./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cartridge_dir> --quit`.
- Runtime: all five scenes loaded with `--quit-after 20`, exit code `0`.
- Runtime log scan: no `ERROR`, `SCRIPT ERROR`, `Invalid`, `Parse Error`, `Cannot`, or `Failed` matches.
- Visual: all five screenshots are 1920x1080, post-splash, and contain nonblack neon gameplay content.
- Black-base pixel sample: all five screenshots reported `(0, 0, 0)` at all four corners.

## Pixel Sample Summary
| Cartridge | Corner result | Sampled nonblack pixels |
|---|---:|---:|
| Asteroids | black | 105 / 5184 |
| Tron | black | 102 / 5184 |
| Pong | black | 166 / 5184 |
| Smash TV | black | 120 / 5184 |
| Battlezone | black | 95 / 5184 |

## Notes
- Cover art classic-IP text was intentionally preserved per user direction.
- `pong`, `smash_tv`, and `battlezone` cover images were re-encoded as valid PNG files after Godot reported corrupt PNG data.

