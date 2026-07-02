# Tetris Map Alignment & Mask Tracing Ticket

**Target Agent:** Tetris & Map Generation Specialist
**Status:** OPEN

## Context
We've been iterating on how the Tetris grid blocks align with the generated semantic maps, specifically focusing on maps generated from custom photo masks (like the rock climbing wall). The user interrupted this troubleshooting session to deal with a Godot Hub UI bug, but this ticket captures the state of the Tetris alignment issues so work can resume immediately.

## Current Issues Reported by User:
1. **Grid Alignment / Orientation:** The underlying map generation is visually misaligned with the visual bounds. The grid that is generated in Tetris seems either reversed, offset, or slanted (for example, the top line is slanted the wrong way).
2. **Outer Path Tracing:** The "outer path" of the semantic map mask isn't aligning to anything meaningful. The density of points on the outer mask edges isn't outlining the level bounds correctly as expected, even though the internal "blue islands" match up conceptually.
3. **Background Views:** The secondary and collision background views are currently not updating or changing from the original photo.

## Objectives for Next Agent:
- **Investigate Map Ingestion:** Look into the Tetris map interpretation scripts (likely in `content/cartridges/tetris/` or the shared semantic map parser).
- **Fix Alignment:** Correct the offset/slant alignment issue between the physical Tetris grid blocks and the semantic map coordinates so they map 1:1.
- **Outer Bounds Tracing:** Ensure the block placement correctly traces the outer edges of complex masks.
- **Fix Background Views:** Hook up or fix the background view layers (secondary/collision) so they properly update to reflect the current map state instead of remaining static.

*Please review the codebase, apply the alignment fixes, and provide a walkthrough of your solution once complete!*
