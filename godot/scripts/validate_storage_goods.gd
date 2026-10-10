extends SceneTree

const Batches = preload("res://scripts/building_batches.gd")

var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("STORAGE_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Validating 3D Stored Goods for Storage Buildings ---")
	
	# 1. Validate all 20 goods and 8 granary food models exist and load
	var goods := ["wheat", "carrots", "onions", "urchin", "cheese", "meat", "fish", "oranges", "wood", "bronze", "marble", "blackMarble", "orichalc", "grapes", "olives", "fleece", "sculpture", "oliveOil", "wine", "armor"]
	var foods := ["wheat", "carrots", "onions", "cheese", "meat", "fish", "urchin", "oranges"]
	
	var all_goods_exist := true
	for g in goods:
		var path := "res://assets/models/good_%s.glb" % g
		var exists := ResourceLoader.exists(path)
		all_goods_exist = all_goods_exist and exists
	check(all_goods_exist, "all 20 warehouse/trade post 3D goods models exist and load")
	
	var all_foods_exist := true
	for f in foods:
		var path := "res://assets/models/granary_food_%s.glb" % f
		var exists := ResourceLoader.exists(path)
		all_foods_exist = all_foods_exist and exists
	check(all_foods_exist, "all 8 granary 3D food models exist and load")
	
	# 2. Check simulation service emits bays for storage buildings
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var state: Dictionary = core.open_city(engine, save, "en")
	check(state.has("protocol"), "test city loads in embedded core")
	
	var granaries := 0
	var warehouses := 0
	var trade_posts := 0
	var total_occupied_bays := 0
	
	for b in state.buildings:
		if b.asset == "granary":
			granaries += 1
			if b.has("bays"):
				total_occupied_bays += b.bays.size()
				for bay in b.bays:
					check(bay.has("bay") and bay.has("good") and bay.has("count"), "granary bay has bay index, good name, and count")
					check(bay.good in foods, "granary stored food '%s' is a valid food" % bay.good)
		elif b.asset == "warehouse":
			warehouses += 1
			if b.has("bays"):
				total_occupied_bays += b.bays.size()
				for bay in b.bays:
					check(bay.has("bay") and bay.has("good") and bay.has("count"), "warehouse bay has bay index, good name, and count")
					check(bay.good in goods, "warehouse stored good '%s' is a valid good" % bay.good)
		elif b.asset == "trade_post":
			trade_posts += 1
			if b.has("bays"):
				total_occupied_bays += b.bays.size()
				for bay in b.bays:
					check(bay.has("bay") and bay.has("good") and bay.has("count"), "trade post bay has bay index, good name, and count")
					check(bay.good in goods, "trade post stored good '%s' is a valid good" % bay.good)
					
	check(granaries > 0 and warehouses > 0 and trade_posts > 0, "test city contains granaries (%d), warehouses (%d), and trade posts (%d)" % [granaries, warehouses, trade_posts])
	check(total_occupied_bays > 0, "storage buildings contain occupied bays (%d total occupied bays)" % total_occupied_bays)
	
	# 3. Test building batches generation
	var batches := Batches.new()
	root.add_child(batches)
	
	# Test template instantiation for goods
	var wheat_template: Array = batches.template("good_wheat")
	check(not wheat_template.is_empty(), "good_wheat template loaded and mesh collected")
	
	var granary_meat_template: Array = batches.template("granary_food_meat")
	check(not granary_meat_template.is_empty(), "granary_food_meat template loaded and mesh collected")
	
	# Test MultiMesh instance creation in batches
	var test_groups := {
		"good_fleece|0:0": [
			{"transform": Transform3D(Basis.IDENTITY, Vector3(10, 0, 10))}
		],
		"granary_food_meat|0:0": [
			{"transform": Transform3D(Basis.IDENTITY, Vector3(20, 0, 20))}
		]
	}
	batches.rebuild(test_groups)
	check(batches.group_nodes.has("good_fleece|0:0"), "batches created MultiMesh instance for good_fleece")
	check(batches.group_nodes.has("granary_food_meat|0:0"), "batches created MultiMesh instance for granary_food_meat")
	
	batches.rebuild({})
	check(batches.group_nodes.is_empty(), "batches clean up when empty")
	batches.free()
	
	print("STORAGE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
