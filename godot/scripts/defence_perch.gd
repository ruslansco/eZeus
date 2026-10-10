extends RefCounted
# Roof presentation only. Native patrol coordinates, lifts and rules remain intact.
# Rebuild the small footprint index only with the existing building-change signal.
const ART = preload("res://data/defence_art.json")
const DIRS := {1: Vector2.LEFT, 2: Vector2.RIGHT, 4: Vector2.UP, 8: Vector2.DOWN}
var cells := {}

func refresh(buildings: Array) -> void:
	cells.clear()
	for building in buildings:
		var asset := str(building.asset)
		if asset != "tower" and not asset.begins_with("wall_"):
			continue
		var roof := {"tower": asset == "tower", "mask": int(asset.trim_prefix("wall_")) if asset.begins_with("wall_") else 0,
			"center": Vector2(float(building.x) + (float(building.w) - 1.0) * .5, float(building.y) + (float(building.h) - 1.0) * .5),
			"altitude": float(building.altitude)}
		for dx in int(building.w):
			for dy in int(building.h):
				cells[Vector2i(int(building.x) + dx, int(building.y) + dy)] = roof

func roof(walker: Dictionary) -> Dictionary:
	# A ground soldier using the same archer model must keep the native ground path.
	if float(walker.get("lift", 0.0)) <= 0.0:
		return {}
	return cells.get(Vector2i(floori(float(walker.x)), floori(float(walker.y))), {})

static func lift(perch: Dictionary, fallback: float) -> float:
	return float(ART.data.tower_platform if perch.tower else ART.data.wall_walk) if not perch.is_empty() else fallback

static func safe_point(point: Vector2, perch: Dictionary) -> Vector2:
	var local: Vector2 = point - perch.center
	if perch.tower:
		var half := float(ART.data.tower_safe_half)
		return perch.center + Vector2(clampf(local.x, -half, half), clampf(local.y, -half, half))
	# Project onto the connected wall walk, including corners/branches. Full-length
	# connected arms meet the adjacent roof; transverse drift stays inside merlons.
	var closest := Vector2.ZERO
	var distance := local.length_squared()
	for bit in DIRS:
		if int(perch.mask) & int(bit):
			var direction: Vector2 = DIRS[bit]
			var candidate := direction * clampf(local.dot(direction), 0.0, .5)
			if local.distance_squared_to(candidate) < distance:
				closest = candidate
				distance = local.distance_squared_to(candidate)
	var sideways := local - closest
	return perch.center + closest + sideways.limit_length(float(ART.data.wall_lane_half))

func position(native_position: Vector3, fallback: Dictionary, city: Node) -> Vector3:
	var point := Vector2(native_position.x + city.origin.x + (city.extent.x - 1) * .5,
		-native_position.z + city.origin.y + (city.extent.y - 1) * .5)
	var perch: Dictionary = cells.get(Vector2i(roundi(point.x), roundi(point.y)), fallback)
	var safe := safe_point(point, perch)
	return city.world_position(safe.x, safe.y, float(perch.altitude)) + Vector3.UP * lift(perch, 0.0)
