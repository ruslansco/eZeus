extends RefCounted
# Read-only street topology. Every native road-kind tile is a walking surface,
# including the strip the original avenue tool calls its median.
const SIDES := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const EDGE := .40
const CLEAR_HALF_WIDTH := .20 # .10 body + .09 prop half-width + .01 separation at edge .40.

static func kind(tiles: Dictionary, cell: Vector2i) -> int:
	var tile: Array = tiles.get(cell, [])
	if tile.size() < 5 or not int(tile[4]): return 0
	return int(tile[8]) if tile.size() >= 9 else 1

static func axis(tiles: Dictionary, cell: Vector2i) -> Vector2i:
	# Only dress straight interiors. Ends, bends, crossings and isolated clicks
	# stay completely clear, rather than guessing a direction from a distant run.
	if kind(tiles, cell) < 2: return Vector2i.ZERO
	var horizontal := kind(tiles, cell + Vector2i.LEFT) >= 2 and kind(tiles, cell + Vector2i.RIGHT) >= 2
	var vertical := kind(tiles, cell + Vector2i.UP) >= 2 and kind(tiles, cell + Vector2i.DOWN) >= 2
	if horizontal == vertical: return Vector2i.ZERO
	var along := Vector2i.RIGHT if horizontal else Vector2i.DOWN
	var across := Vector2i(-along.y, along.x)
	if kind(tiles, cell + across) >= 2 or kind(tiles, cell - across) >= 2: return Vector2i.ZERO
	return along

static func edges(tiles: Dictionary, cell: Vector2i) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var along := axis(tiles, cell)
	if along == Vector2i.ZERO: return result
	var across := Vector2i(-along.y, along.x)
	for side in [across, -across]:
		var owner := cell
		# Follow the native flank, without expanding a two/three-cell road.
		if kind(tiles, owner + side) == 1: owner += side
		if kind(tiles, owner + side) != 0: continue
		var outside: Array = tiles.get(owner + side, [])
		if outside.size() < 8 or int(outside[6]) & 8 or int(outside[3]) & (4 | 2048 | 32768): continue
		# A road across the outside/adjacent row is an intersection or entrance.
		if kind(tiles, owner + side + along) or kind(tiles, owner + side - along): continue
		if not kind(tiles, owner + along) or not kind(tiles, owner - along): continue
		result.append(Vector2(owner - cell) + Vector2(side) * EDGE)
	return result

static func wide(tiles: Dictionary, cell: Vector2i) -> bool:
	if kind(tiles,cell) == 0: return false
	if kind(tiles, cell) >= 2: return true
	for offset in SIDES:
		if kind(tiles, cell + offset) >= 2: return true
	return false
