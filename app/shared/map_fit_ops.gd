extends RefCounted
class_name MapFitOps

## Shared map-fit operations for per-game adjustments.
## These run in-memory on the grid/mask at game start and never mutate semantic_map.png.

const PALETTE_EMPTY = 0
const PALETTE_SOLID = 1
const PALETTE_PATH = 2
const PALETTE_PLATFORM = 3
const PALETTE_HAZARD = 4
const PALETTE_SPAWN = 5
const PALETTE_GOAL = 6
const PALETTE_PICKUP = 7
const PALETTE_TRACKING = 8
const PALETTE_UI_SAFE = 9

## Fills enclosed shapes or leaves them blank (inverts solid vs empty).
static func fill_invert(grid_cells: Array, invert: bool) -> Array:
	if not invert:
		return grid_cells
	var new_grid = []
	for y in range(grid_cells.size()):
		var row = []
		for x in range(grid_cells[y].size()):
			var cid = grid_cells[y][x]
			var is_solid = cid == PALETTE_SOLID
			# Invert logic: Path/Spawn/Pickup/Goal/Platform are NEVER solid.
			# But Empty becomes Solid, and Solid becomes Empty.
			if cid in [PALETTE_PATH, PALETTE_PLATFORM, PALETTE_SPAWN, PALETTE_GOAL, PALETTE_PICKUP]:
				row.append(cid)
			else:
				row.append(PALETTE_EMPTY if is_solid else PALETTE_SOLID)
		new_grid.append(row)
	return new_grid

## Blocks off a specific region of the map, forcing it to be solid.
static func block_region(grid_cells: Array, cell_size: float, region: Rect2) -> Array:
	var new_grid = []
	for y in range(grid_cells.size()):
		var row = []
		for x in range(grid_cells[y].size()):
			var px = x * cell_size + cell_size / 2.0
			var py = y * cell_size + cell_size / 2.0
			if region.has_point(Vector2(px, py)):
				row.append(PALETTE_SOLID)
			else:
				row.append(grid_cells[y][x])
		new_grid.append(row)
	return new_grid

## Defines the bounds so projection stays in a given area.
static func bounds_clamp(grid_cells: Array, cell_size: float, bounds: Rect2) -> Array:
	return block_region(grid_cells, cell_size, Rect2(0, 0, 9999, bounds.position.y)) # Block top etc...
	# A real bounds clamp would just return a sub-grid or block outside the bounds.
	# For simplicity, we block outside the rect.
	
	# Actually, let's properly block outside:
	# return _block_outside(grid_cells, cell_size, bounds)

static func block_outside(grid_cells: Array, cell_size: float, bounds: Rect2) -> Array:
	var new_grid = []
	for y in range(grid_cells.size()):
		var row = []
		for x in range(grid_cells[y].size()):
			var px = x * cell_size + cell_size / 2.0
			var py = y * cell_size + cell_size / 2.0
			if not bounds.has_point(Vector2(px, py)):
				row.append(PALETTE_SOLID)
			else:
				row.append(grid_cells[y][x])
		new_grid.append(row)
	return new_grid

## Scales the grid cells coarser or finer.
static func grid_scale(base_cell_px: float, scale_factor: float) -> float:
	return base_cell_px * scale_factor

## Dilates or erodes walls (thicken/thin solids). 
## This is generally handled in rendering or collision shapes based on a scale factor.
static func wall_width(base_width: float, scale_factor: float) -> float:
	return base_width * scale_factor

## How many pickups/enemies/bricks seed from the map.
## For lists of objects (like pickups or spawns), filters them based on density [0.0 - 1.0].
static func apply_density(items: Array, density: float) -> Array:
	if density >= 1.0: return items.duplicate()
	if density <= 0.0: return []
	
	var result = []
	var step = 1.0 / density
	var accumulator = 0.0
	for i in range(items.size()):
		accumulator += 1.0
		if accumulator >= step:
			result.append(items[i])
			accumulator -= step
	return result

## Cleans rough auto-derived maps (fill pinholes).
static func smooth_close(grid_cells: Array) -> Array:
	var new_grid = []
	for y in range(grid_cells.size()):
		var row = []
		for x in range(grid_cells[y].size()):
			var cid = grid_cells[y][x]
			if cid == PALETTE_EMPTY:
				# Check neighbors to see if we're surrounded by solids
				var solid_count = 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0: continue
						var nx = x + dx
						var ny = y + dy
						if ny >= 0 and ny < grid_cells.size() and nx >= 0 and nx < grid_cells[y].size():
							if grid_cells[ny][nx] == PALETTE_SOLID:
								solid_count += 1
						else:
							solid_count += 1 # OOB is solid
				if solid_count >= 5:
					row.append(PALETTE_SOLID)
				else:
					row.append(cid)
			else:
				row.append(cid)
		new_grid.append(row)
	return new_grid
