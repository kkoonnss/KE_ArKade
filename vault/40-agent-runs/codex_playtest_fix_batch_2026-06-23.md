# Codex Run Log - Playtest Fix Batch

Date: 2026-06-23
Agent: Codex

## Scope

Applied the first patch batch from Kons's hands-on playtest notes.

## Fixes Applied

- Changed cartridge splash `TextureRect` behavior from cropped cover fill to aspect-fit centered across all real cartridges.
- Fixed continuous movement for games that were snapping every frame to grid-cell centers:
  - `battlezone` / Battlezone
  - `gauntlet` / Gauntlet
  - `marble_madness` / Marble Madness
  - `dig_dug` / Dig Dug
  - `breakout` / Breakout
  - `donkey_kong` / Donkey Kong
- Added Breakout falling item drops:
  - wide paddle
  - slow ball
  - extra life
  - bonus score
- Improved Dig Dug aiming so pump direction persists after movement stops.
- Improved Defender:
  - ship facing now flips left/right;
  - shots use persistent facing;
  - humans and enemies stay above the terrain band;
  - enemies choose distributed human targets instead of collapsing to one unreachable point.
- Increased Missile Command silo ammo from 12 to 22 in both Defender-family and standalone Missile Command cartridge files.
- Scaled Centipede later waves with more segments and more/durable barriers.

## Deferred

- Universal start/help/settings screen and Escape-to-start behavior still needs a dedicated pass because cartridges currently use several template families.
- More bespoke mechanics remain for Galaga formations, BurgerTime difficulty, Donkey Kong barrel ladder behavior, Joust clarity, Lunar Lander four-player mode, Paperboy throwing logic, and Frogger feel/art polish.

## Verification

- Full real-cartridge headless `--quit` validation passed for all cartridges excluding `loopback`.
