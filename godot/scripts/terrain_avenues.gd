extends "res://scripts/terrain_forest.gd"
# Street trees, presentation only: olives down an avenue's median and cypresses down a
# boulevard's, every second tile. The road kind is snapshot column 8.
const Presentation = preload("res://scripts/terrain_presentation.gd")

func signature(tile: Array) -> Array:
	return super(tile) + [tile[8] if tile.size() >= 9 else 0]

func kind_at(cell: Vector2i) -> int:
	return Presentation.road_kind(tiles.get(cell, []))

func run(cell: Vector2i, step: Vector2i) -> int:
	var count := 0
	for direction in [step, -step]:
		var probe: Vector2i = cell + direction
		while count < 8 and kind_at(probe) >= 2:
			count += 1
			probe += direction
	return count

func layout(cell: Vector2i) -> Array:
	# Avenue and boulevard tiles are medians: one tree in the bed every second tile along
	# the strip, a clipped olive on an avenue, a cypress on a boulevard.
	var kind := kind_at(cell)
	if kind < 2:
		return []
	var along := cell.x if run(cell, Vector2i.RIGHT) >= run(cell, Vector2i.DOWN) else cell.y
	if posmod(along, 2) != 0:
		return []
	if kind == 3:
		return [placement(cell, "cypress", 61, Vector2.ZERO, Vector3(.62, .72, .62))]
	return [placement(cell, "olive", 62, Vector2.ZERO, Vector3(.55, .62, .55))]
