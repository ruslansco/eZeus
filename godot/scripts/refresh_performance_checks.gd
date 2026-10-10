extends RefCounted
# Exercise real chart pixels, GPU batch lifecycle and independent shared VAT poses.
# The same checks run with the dummy renderer and in the owned Metal profile.
const Minimap = preload("res://ui/minimap.gd")
const Batches = preload("res://scripts/building_batches.gd")
const Vat = preload("res://scripts/walker_vat.gd")
var okay := true
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("REFRESH_PERFORMANCE_CHECK ", "PASS " if value else "FAIL ", label)

func run(tree: SceneTree) -> void:
	map_checks()
	batch_checks(tree)
	vat_checks(tree)

func colour_matches(actual: Color, expected: Color) -> bool:
	return absf(actual.r-expected.r) < .005 and absf(actual.g-expected.g) < .005 and absf(actual.b-expected.b) < .005

func map_checks() -> void:
	var chart := Minimap.new()
	var tiles := {}
	for x in range(-2, 5):
		for y in range(-3, 4): tiles[Vector2i(x,y)] = [x,y,0,1,0]
	chart.set_map(tiles, Vector2i(-2,-3), Vector2i(7,7))
	var house := {"asset":"common_house_2a","x":-1,"y":-2,"w":2,"h":2}
	var shop := {"asset":"warehouse","x":2,"y":1,"w":3,"h":3}
	var entries := [house, shop, {"asset":"native_marker","x":-2,"y":3,"w":1,"h":1}]
	chart.set_buildings(entries)
	check(chart.building_paints == 1 and chart.building_colours.size() == 13, "native chart paints ordered footprints and excludes marker reservations")
	check(colour_matches(chart.composed.get_pixel(1,5), Minimap.HOUSE_COLOUR), "negative native origin and flipped Y retain exact house pixels")
	var pixels := chart.composed.get_data()
	house.working = true; shop.bays = [{"bay":0,"good":"wheat","count":4}]
	chart.set_buildings(entries)
	check(chart.building_paints == 1 and chart.composed.get_data() == pixels, "inventory/work-only updates leave the chart texture untouched")
	var cell := Vector2i(-1,-2)
	tiles[cell][3] = 4
	chart.paint_tiles(tiles, [cell])
	chart.set_buildings(entries)
	check(chart.building_paints == 1 and chart.composed.get_data() == pixels, "a terrain delta beneath an unchanged building preserves its chart colour")
	chart.set_buildings([shop])
	check(colour_matches(chart.composed.get_pixel(1,5), Minimap.WATER_COLOUR) and chart.building_colours.size() == 9, "demolition reveals the latest terrain and discards removed footprint pixels")
	shop.asset = "elite_house_1"; chart.set_buildings([shop])
	check(colour_matches(chart.composed.get_pixel(4,2), Minimap.HOUSE_COLOUR), "native evolution refreshes the building's chart category")
	shop.x = 3; shop.w = 1; chart.set_buildings([shop])
	check(chart.building_colours.size() == 3 and colour_matches(chart.composed.get_pixel(4,2), Minimap.GRASS_COLOUR), "moving/shrinking a footprint clears its old chart pixels")
	var count: int = chart.building_paints
	shop.asset = "common_house_5a"; chart.set_buildings([shop])
	check(chart.building_paints == count, "same chart category avoids repainting a changed model")
	var overlap := shop.duplicate(); overlap.asset = "warehouse"
	chart.set_buildings([shop, overlap])
	check(colour_matches(chart.composed.get_pixel(5,2), Minimap.BUILDING_COLOUR), "overlapping native records keep their original painting order")
	chart.set_buildings([overlap, shop])
	check(colour_matches(chart.composed.get_pixel(5,2), Minimap.HOUSE_COLOUR), "changing overlap order invalidates the layer")
	chart.set_buildings([])
	check(chart.composed.get_data() == chart.terrain.get_data() and chart.building_colours.is_empty(), "removing the final building restores the entire terrain image")
	chart.set_map(tiles, Vector2i(-2,-3), Vector2i(7,7)); chart.set_buildings([shop])
	check(chart.building_colours.size() == 3, "a new map clears the prior city cache before restoring its buildings")
	chart.free()

func batch_checks(tree: SceneTree) -> void:
	var batches := Batches.new(); tree.root.add_child(batches)
	var key := "warehouse|refresh"
	var placements := [{"transform":Transform3D.IDENTITY,"working":true,"animation_offset":3}, {"transform":Transform3D(Basis.IDENTITY,Vector3(4,0,0)),"working":false,"animation_offset":6}]
	batches.rebuild({key:placements})
	var nodes: Array = batches.group_nodes[key].duplicate()
	var animated: Array = nodes.filter(func(node): return node.multimesh.use_custom_data)
	var buffers: Array = nodes.map(func(node): return node.multimesh)
	check(not animated.is_empty() and batches.last_activity_updates == animated.size()*2, "each new animated batch receives both native work/phase settings")
	batches.rebuild({key:placements})
	check(batches.last_rebuilt == 0 and batches.last_activity_updates == 0, "an unchanged snapshot uploads neither geometry nor animation data")
	placements[0].working = false; batches.rebuild({key:placements})
	check(batches.last_rebuilt == 0 and batches.last_activity_updates == animated.size(), "staffing changes upload only the affected instance's work flag")
	placements[1].animation_offset = 7; batches.rebuild({key:placements})
	check(batches.last_activity_updates == animated.size(), "a native phase change uploads only the affected instance")
	placements[0].transform.origin.x = 1; batches.rebuild({key:placements})
	check(nodes == batches.group_nodes[key] and buffers == nodes.map(func(node): return node.multimesh) and batches.last_rebuilt == 1 and batches.last_activity_updates == 0, "moving instances reuses nodes/buffers and retains independent activity data")
	placements.append({"transform":Transform3D(Basis.IDENTITY,Vector3(8,0,0)),"working":true,"animation_offset":2})
	batches.rebuild({key:placements})
	check(nodes == batches.group_nodes[key] and buffers == nodes.map(func(node): return node.multimesh) and batches.last_activity_updates == animated.size()*3, "growing a batch reuses GPU objects and restores all activity after allocation")
	check(nodes.all(func(node): return node.multimesh.instance_count == 3), "new native building instances immediately resize every template piece")
	if DisplayServer.get_name() != "headless":
		var pieces: Array = batches.template("warehouse")
		var exact := true
		for p in pieces.size():
			for i in placements.size():
				exact = exact and nodes[p].multimesh.get_instance_transform(i).is_equal_approx(placements[i].transform * pieces[p].transform)
		for node in animated:
			exact = exact and node.multimesh.get_instance_custom_data(2).is_equal_approx(Color(1,2,0,0)) and node.multimesh.get_instance_custom_data(1).is_equal_approx(Color(0,7,0,0))
		check(exact, "Metal readback retains exact template transforms and independent work flags after reuse")
	placements.remove_at(1); batches.rebuild({key:placements})
	check(nodes == batches.group_nodes[key] and nodes.all(func(node): return node.multimesh.instance_count == 2) and batches.last_activity_updates == animated.size()*2, "removal/compaction retains GPU objects and restores reordered activity")
	batches.rebuild({key:placements})
	check(batches.last_activity_updates == 0 and batches.last_rebuilt == 0, "resized batches settle without repeated uploads")
	batches.rebuild({})
	check(batches.group_nodes.is_empty() and nodes.all(func(node): return not is_instance_valid(node)), "removing the final group releases every owned node")
	batches.free()

func vat_checks(tree: SceneTree) -> void:
	var vat := Vat.new()
	var models := []
	var parts := []
	for i in 2:
		var model: Node = load(vat.runtime_path("animal_goat")).instantiate()
		tree.root.add_child(model); models.append(model)
		parts.append(vat.attach(model, "animal_goat"))
	check(not parts[0].is_empty() and parts[0].size() == parts[1].size(), "fresh goat runtime models retain all animated parts")
	var shared := true
	for p in parts[0].size(): shared = shared and parts[0][p].node.material_override == parts[1][p].node.material_override
	check(shared, "new animals share identical cached palette/VAT finishes")
	parts[0][0].node.set_instance_shader_parameter("vat_pose", Vector3(1,2,.3))
	parts[1][0].node.set_instance_shader_parameter("vat_pose", Vector3(3,4,.6))
	check(parts[0][0].node.get_instance_shader_parameter("vat_pose") == Vector3(1,2,.3) and parts[1][0].node.get_instance_shader_parameter("vat_pose") == Vector3(3,4,.6), "shared finishes leave each animal's pose independent")
	var mesh := BoxMesh.new(); var source := StandardMaterial3D.new()
	mesh.material = source
	var part := MeshInstance3D.new(); part.mesh = mesh
	var texture: ImageTexture = vat.texture_for("animal_goat")
	var original := vat.finish_material(part, texture)
	source.roughness = .21; source.metallic = .7; source.metallic_specular = .34
	var changed := vat.finish_material(part, texture)
	check(changed != original and is_equal_approx(changed.get_shader_parameter("roughness_value"), .21) and is_equal_approx(changed.get_shader_parameter("metallic_value"), .7), "different imported finishes keep their original roughness/metal settings")
	var other := ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_RGBA8))
	check(vat.finish_material(part, other) != changed, "different pose textures never share a finish")
	check(vat.finish_material(part, texture) == changed, "repeat spawning reuses the cached immutable finish")
	part.free()
	for model in models: model.free()
