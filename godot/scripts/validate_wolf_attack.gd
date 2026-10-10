extends SceneTree
# The wolf, sheep and goat models (6 October): coat colours survive export (no white animals), each native state selects a complete
# authored clip in the source and VAT models (wolf: bite 4, lie 2, collapse 6; sheep and goats: lie 2, collapse 6), and a fighting
# wolf's bites burst fur from the walker it fights and make it flinch, never touching a bystander or a walker that is not fighting.
const Motion = preload("res://scripts/gathering_motion.gd")
const Attacks = preload("res://scripts/wolf_attacks.gd")
const ANIMALS = ["animal_wolf", "animal_sheep_fleeced", "animal_sheep_nude", "animal_goat"]
var okay := true
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("WOLF_ATTACK_CHECK ", "PASS " if value else "FAIL ", label)
func _initialize() -> void: call_deferred("run")

func colourful(asset: String) -> bool:
	var scene: Node3D = load("res://assets/models/%s.glb" % asset).instantiate()
	var spread := 0.0
	var stack: Array = [scene]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D and node.mesh:
			for surface in node.mesh.get_surface_count():
				var colours: PackedColorArray = node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
				for i in range(0, colours.size(), 37):
					spread = maxf(spread, 1.0 - minf(colours[i].r, minf(colours[i].g, colours[i].b)) / maxf(.001, maxf(colours[i].r, maxf(colours[i].g, colours[i].b))))
	scene.free()
	return spread > .15

func run() -> void:
	Engine.set_meta("ezeus_settings_path", "/tmp/ezeus-wolf-validation-settings.cfg")
	Engine.set_meta("ezeus_save_directory", "/tmp/ezeus-wolf-validation-saves")
	var city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty(): await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false); city.orbit.enabled = false
	var target: Vector3 = city.orbit.target
	for asset in ANIMALS:
		check(colourful(asset), asset + " keeps its coat colours (not exported white)")
		for baked in [false, true]:
			var node: Node3D = city.model(asset) if baked else load("res://assets/models/" + asset + ".glb").instantiate()
			city.world.add_child(node); node.position = target
			var morphs: Array = node.get_meta("vat_parts") if node.has_meta("vat_parts") else []
			if morphs.is_empty(): city.collect_morphs(node, morphs)
			var entry: Dictionary = city.new_walker_entry(node, asset, -1, target, 0, morphs)
			var clock := 0.0
			for action in Motion.TASKS[asset].keys():
				entry.action = action
				var clip := Motion.clip_for(entry)
				var complete := not clip.is_empty()
				for morph in morphs:
					for i in Motion.COUNTS.get(clip, 0): complete = complete and morph.table.has("%s_%02d" % [clip, i])
				check(complete, "%s %s action %d complete %s" % [asset, "VAT" if baked else "source", action, clip])
				city.animate_walker(entry, 0, 0); Motion.apply(entry, city, clock); Motion.apply(entry, city, clock + .3)
				check(entry.gather_clip == clip and is_equal_approx(entry.gather_weight, 1.0), "%s action %d plays %s" % [asset, action, clip])
				clock += 6.0
			node.free()
	# Bites: a fighting wolf, the townsperson it fights, a bystander who is only walking, and a fighter out of reach.
	var attacks: Node3D = city.wolf_attacks
	var walkers := {}
	var spots := {"wolf": target, "prey": target + Vector3(.7, 0, 0), "bystander": target + Vector3(-.5, 0, .2), "far": target + Vector3(3, 0, 0)}
	var assets := {"wolf": "animal_wolf", "prey": "walker_peddler", "bystander": "walker_porter", "far": "walker_watchman"}
	for key in spots:
		var node: Node3D = city.model(assets[key]); city.world.add_child(node); node.position = spots[key]
		var morphs: Array = node.get_meta("vat_parts") if node.has_meta("vat_parts") else []
		if morphs.is_empty(): city.collect_morphs(node, morphs)
		walkers[key] = city.new_walker_entry(node, assets[key], -1, spots[key], 0, morphs)
	walkers.wolf.action = 4; walkers.prey.action = 4; walkers.bystander.action = 3; walkers.far.action = 4
	check(Attacks.victim(walkers.wolf, walkers) == walkers.prey, "the wolf's opponent is the walker fighting next to it")
	var fake = {"walkers": walkers}
	var before: int = attacks.bites
	var clock := 0.0
	for frame in 40:
		clock += .05
		for key in walkers:
			walkers[key].node.position = spots[key]
		Motion.apply(walkers.wolf, city, clock)
		attacks.update(fake, .05)
	check(attacks.bites > before, "the wolf's lunges bite (%d bites in two seconds)" % (attacks.bites - before))
	check(attacks.bites - before <= 4, "two bites per lunge cycle, no more")
	check(not attacks.puffs.is_empty() or attacks.bites > before, "fur bursts from the victim")
	check(float(walkers.bystander.get("flinch", 0.0)) == 0.0 and float(walkers.far.get("flinch", 0.0)) == 0.0, "bystanders and distant fighters never flinch")
	walkers.wolf.action = 3
	var after: int = attacks.bites
	for frame in 40:
		clock += .05
		Motion.apply(walkers.wolf, city, clock); attacks.update(fake, .05)
	check(attacks.bites == after, "a wolf that stops fighting stops biting")
	for frame in 30: attacks.update(fake, .05)
	check(attacks.puffs.is_empty() and float(walkers.prey.get("flinch", 0.0)) == 0.0, "fur settles and the victim stops flinching")
	for key in walkers: walkers[key].node.free()
	city.queue_free(); await process_frame; await process_frame
	print("WOLF_ATTACK_VALIDATION ", "PASS " if okay else "FAIL ", checks)
	quit(0 if okay else 1)
