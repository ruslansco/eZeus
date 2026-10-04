extends RefCounted
# Buildings step back from the streets they face, so a one-tile road reads wider between
# facades. Presentation only: footprints, native rules and picking are unchanged. The ground
# shader paves the strip this frees (the pavement band just outside the carriageway).
const SETBACK := .12  # Tiles taken off each side that faces a road.
const CAP := .15      # At most this share of a dimension is taken in total.
const KEEP := ["wall", "tower", "gatehouse", "roadblock", "bridge", "pier", "harbour", "trade_post", "fishery", "shipyard", "hippodrome", "column", "agora", "pyramid_", "sanctuary_", "monument", "shrine"]

static func applies(asset: String) -> bool:
	for part in KEEP:
		if asset.contains(part):
			return false
	return true

static func road(tiles: Dictionary, cell: Vector2i) -> bool:
	var tile: Array = tiles.get(cell, [])
	return not tile.is_empty() and int(tile[4]) != 0

static func side(tiles: Dictionary, start: Vector2i, step: Vector2i, length: int) -> float:
	for index in length:
		if road(tiles, start + step * index):
			return SETBACK
	return 0.0

static func apply(tiles: Dictionary, building: Dictionary, transform: Transform3D) -> Transform3D:
	if not applies(str(building.asset)):
		return transform
	var x := int(building.x)
	var y := int(building.y)
	var w := int(building.w)
	var h := int(building.h)
	var left := side(tiles, Vector2i(x - 1, y), Vector2i.DOWN, h)
	var right := side(tiles, Vector2i(x + w, y), Vector2i.DOWN, h)
	var top := side(tiles, Vector2i(x, y - 1), Vector2i.RIGHT, w)
	var bottom := side(tiles, Vector2i(x, y + h), Vector2i.RIGHT, w)
	var across := left + right
	if across > CAP * w:
		left *= CAP * w / across
		right *= CAP * w / across
	var along := top + bottom
	if along > CAP * h:
		top *= CAP * h / along
		bottom *= CAP * h / along
	if left + right + top + bottom == 0.0:
		return transform
	# World +X is native +X; world +Z is native -Y (top).
	transform.basis = Basis.from_scale(Vector3((w - left - right) / w, 1.0, (h - top - bottom) / h)) * transform.basis
	transform.origin += Vector3((left - right) * .5, 0.0, (bottom - top) * .5)
	return transform
