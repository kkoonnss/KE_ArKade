# QA - 10 Classic Cartridge Buildout

Date: 2026-06-22
Runner: Codex
Level used: `content/scenes/scene_demo_wall/levels/demo_level`

## Result
Pass. All ten cartridges parse, launch for a bounded runtime, render gameplay screenshots, and satisfy the pure-black corner pixel check.

## Evidence
| Cartridge | Runtime log | Screenshot |
|---|---|---|
| Centipede | `vault/70-qa/centipede_runtime.log` | `vault/70-qa/centipede_gameplay.png` |
| Space Invaders | `vault/70-qa/space_invaders_runtime.log` | `vault/70-qa/space_invaders_gameplay.png` |
| Robotron: 2084 | `vault/70-qa/robotron_2084_runtime.log` | `vault/70-qa/robotron_2084_gameplay.png` |
| BurgerTime | `vault/70-qa/burger_time_runtime.log` | `vault/70-qa/burger_time_gameplay.png` |
| Galaga | `vault/70-qa/galaga_runtime.log` | `vault/70-qa/galaga_gameplay.png` |
| Missile Command | `vault/70-qa/missile_command_runtime.log` | `vault/70-qa/missile_command_gameplay.png` |
| Defender | `vault/70-qa/defender_runtime.log` | `vault/70-qa/defender_gameplay.png` |
| Lunar Lander | `vault/70-qa/lunar_lander_runtime.log` | `vault/70-qa/lunar_lander_gameplay.png` |
| Paperboy | `vault/70-qa/paperboy_runtime.log` | `vault/70-qa/paperboy_gameplay.png` |
| Q*bert | `vault/70-qa/qbert_runtime.log` | `vault/70-qa/qbert_gameplay.png` |

## Checks
- Parser: all ten `main.gd` files passed Godot 4.3 `--check-only`.
- Runtime: all ten scenes loaded with `--quit-after 20`, exit code `0`.
- Runtime log scan: no `ERROR`, `SCRIPT ERROR`, `Parse Error`, `Cannot`, or `Failed` matches.
- Black-base pixel sample: all ten screenshots reported `(0, 0, 0)` at all four corners.
- Nonblank visual sample: all ten screenshots contained sampled nonblack neon gameplay pixels.

## Pixel Sample Summary
| Cartridge | Corner result | Sampled nonblack pixels |
|---|---:|---:|
| Centipede | black | 247 / 5184 |
| Space Invaders | black | 255 / 5184 |
| Robotron: 2084 | black | 151 / 5184 |
| BurgerTime | black | 350 / 5184 |
| Galaga | black | 288 / 5184 |
| Missile Command | black | 127 / 5184 |
| Defender | black | 167 / 5184 |
| Lunar Lander | black | 286 / 5184 |
| Paperboy | black | 980 / 5184 |
| Q*bert | black | 249 / 5184 |

## Residual Risk
- These are compact playable arcade loops intended to bring the stubs across the playable/IPC/visual safety threshold. They are not yet deep per-title polish passes.
- No live hub socket integration test was run in this pass; IPC command handling was parse/runtime covered and implemented against the documented NDJSON contract.

