# Hub Thumbnail Conventions

This document outlines the conventions for thumbnails and card images in KE_ArKade's hub UI.

## Image Search Priority for Scene Cards
1. `thumbnail.png`
2. `background.png`
3. `reference.png`
4. `photo.png`
5. `image.png`

## Image Search Priority for Level Cards
1. `semantic_map.png`
2. `thumbnail.png`
3. `background.png`
4. `reference.png`

*(Fallback: cartridge `thumbnail.png` if it exists)*

## Cartridges
- All cartridges should have a `thumbnail.png` in their root directory.
- Skin thumbnails use the format: `thumbnail_{skin_suffix}.png` (e.g., `thumbnail_retro_mode.png`).

## Naming and Location
- Always use the exact name `thumbnail.png` for explicit thumbnails.
- Location: Place the image in the scene/level root directory or within the `level_edit/` subdirectory.
- Currently, thumbnails are full resolution (copies of splash screens, typically 1-2.5MB). There is a future optimization opportunity to downscale these for the hub UI to save memory.
