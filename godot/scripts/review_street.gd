extends RefCounted

# Captures a city's densest block of houses from four sides, to judge building facing (street_facing.gd) on a real
# street. Opened with --street-review=<save>: a COPY of a save in a scratch folder (main.gd opens it with that folder
# as the save directory). The city is paused and nothing is saved. Files: captures/street-<n>-<yaw>.png.
const StreetFacing = preload("res://scripts/street_facing.gd")

func run(city: Node3D) -> void:
	city.core.query("pause 1")
	city.hud.visible = false
	await city.get_tree().create_timer(2.0).timeout
	var houses: Array = city.state.buildings.filter(func(b): return str(b.asset).begins_with("common_house") or str(b.asset).begins_with("elite_house"))
	print("STREET_REVIEW houses ", houses.size())
	# The house with the most houses within six tiles, then a second block away from the first.
	var centres: Array[Vector2i] = []
	for round in 2:
		var best := Vector2i(99999, 99999)
		var crowd := -1
		for house in houses:
			var cell := Vector2i(int(house.x), int(house.y))
			if centres.any(func(c): return Vector2(c).distance_to(Vector2(cell)) < 14):
				continue
			var near := houses.filter(func(o): return Vector2(float(o.x), float(o.y)).distance_to(Vector2(cell)) < 6.0).size()
			if near > crowd:
				crowd = near
				best = cell
		if best.x != 99999:
			centres.append(best)
	var turned := 0
	for house in houses:
		var stored := int(house.get("orientation", 0))
		turned += 1 if StreetFacing.facing(city.tiles, str(house.asset), int(house.x), int(house.y), int(house.w), int(house.h), stored) != stored else 0
	print("STREET_REVIEW turned ", turned, " of ", houses.size())
	city.orbit.enabled = false
	city.orbit.pitch = 49
	for index in centres.size():
		var point: Vector2i = centres[index]
		city.orbit.target = city.world_position(point.x + .5, point.y + .5, city.tiles.get(point, [0, 0, 0])[2])
		city.orbit.distance = 9.0
		for angle in [45, 135, 225, 315]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().create_timer(.6).timeout
			city.capture_path = ProjectSettings.globalize_path("res://captures/street-%d-%d.png" % [index, angle])
			await city.capture()
	print("STREET_REVIEW PASS")
	city.get_tree().quit(0)
