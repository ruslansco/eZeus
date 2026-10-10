extends SceneTree
# Frame-rate, transitions, heading and pose blending regressions. No simulation mutation.
const Motion = preload("res://scripts/walker_motion.gd")
const Vat = preload("res://scripts/walker_vat.gd")
const Float = preload("res://scripts/god_float.gd")
var okay := true
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("LOCOMOTION_CHECK ", "PASS " if value else "FAIL ", label)

func entry() -> Dictionary:
	return {"travel":0.0,"idle":0.0,"moving":false,"walk_weight":0.0,"still_time":Motion.GAP_HOLD}

func timeline(fps: int) -> Dictionary:
	var gait := entry()
	var dt := 1.0/fps
	for frame in fps: Motion.advance(gait,dt,Motion.STRIDE*dt)
	for frame in fps/5: Motion.advance(gait,dt,0)
	return gait

func _initialize() -> void:
	call_deferred("run")

# One frame of the city's per-frame code for a god: the node is put back on the surface, then animated (main.gd _process).
func god_frame(city: Node, state: Dictionary, base: Vector3, dt: float, moved: float) -> void:
	state.node.position = base
	city.animate_walker(state, dt, moved)

func god_state(node: Node3D, parts: Array) -> Dictionary:
	var state := entry()
	state.merge({"node":node,"morphs":parts,"human":true,"god":true,"clips":{},"action":1})
	return state

# Gods float instead of walking: no step cycle, a hover with a slow bob, a lean about the waist and a slow turn.
func god_float_checks(city: Node, vat: RefCounted) -> void:
	var gods := ["aphrodite","apollo","ares","artemis","athena","atlas","demeter","dionysus","hades","hephaestus","hera","hermes","poseidon","zeus"]
	var all_gods := true
	for god in gods:
		all_gods = all_gods and Float.is_god("walker_"+god) and ResourceLoader.exists("res://assets/models/walker_%s.glb"%god)
	check(all_gods, "all fourteen gods are recognised and have their models")
	var others := true
	for asset in ["walker_achilles","walker_archerposeidon","walker_chariotposeidon","walker_hopliteposeidon","walker_cerberus","walker_priestess","philosopher","walker_grower","sanctuary_statue_zeus"]:
		others = others and not Float.is_god(asset)
	check(others, "heroes, soldiers, monsters, citizens and statues do not float")
	var baked: Node3D=load(vat.runtime_path("walker_zeus")).instantiate()
	root.add_child(baked)
	var parts: Array=vat.attach(baked,"walker_zeus")
	var god := god_state(baked, parts)
	var base := Vector3(5, 2, -3)
	baked.rotation.y = deg_to_rad(90)
	# Gliding at full speed for two seconds at 60 FPS.
	var lowest := 99.0; var highest := -99.0; var lean_max := 0.0; var roll_max := 0.0
	var worst_step := 0.0; var worst_turn := 0.0
	var last_y := 0.0; var last_lean := 0.0
	for frame in 120:
		god_frame(city, god, base, 1.0/60.0, Float.SPEED_FULL/60.0)
		var y: float = baked.position.y - base.y
		if frame > 0:
			worst_step = maxf(worst_step, absf(y - last_y)); worst_turn = maxf(worst_turn, absf(baked.rotation.x - last_lean))
		last_y = y; last_lean = baked.rotation.x
		if frame > 60:
			lowest = minf(lowest, y); highest = maxf(highest, y)
		lean_max = maxf(lean_max, -baked.rotation.x); roll_max = maxf(roll_max, absf(baked.rotation.z))
	check(god.travel == 0.0 and god.walk_weight == 0.0 and parts[0].node.get_instance_shader_parameter("vat_walk_blend") == 0, "a travelling god takes no steps: no gait phase, the held idle pose")
	check(god.fl_glide > .85 and lowest >= Float.HOVER - Float.BOB - .001 and highest <= Float.HOVER_MOVING + Float.BOB + .03 and lowest > .05, "a gliding god hovers %.2f to %.2f tiles up (glide %.2f)"%[lowest,highest,god.fl_glide])
	check(lean_max > Float.LEAN * .8 and lean_max <= Float.LEAN + .0001 and roll_max <= Float.ROLL + .0001, "it leans into the glide (%.1f degrees) and sways only a little"%rad_to_deg(lean_max))
	check(worst_step < .01 and worst_turn < .01, "hover and lean change smoothly from frame to frame (%.4f tiles, %.4f rad)"%[worst_step,worst_turn])
	# The lean is about the waist: the waist stays over the same spot, the head goes forward.
	var waist: Vector3 = baked.transform * Vector3(0, Float.PIVOT, 0)
	var feet: Vector3 = baked.transform * Vector3.ZERO
	var head: Vector3 = baked.transform * Vector3(0, 3.0, 0)
	var forward: Vector3 = Basis(Vector3.UP, baked.rotation.y) * Vector3(0, 0, -1)   # the heading, level
	var off := Vector2(waist.x - base.x, waist.z - base.z).length()
	check(off < .01 and (head - waist).dot(forward) > 0 and (feet - waist).dot(forward) < 0, "the lean pivots about the waist, head forward and feet back (waist off by %.4f, head %.3f, feet %.3f)"%[off,(head - waist).dot(forward),(feet - waist).dot(forward)])
	# Stopping settles to a low hover with no lean, and starting from rest eases in.
	for frame in 240:
		god_frame(city, god, base, 1.0/60.0, 0.0)
	var rest: float = baked.position.y - base.y
	check(absf(baked.rotation.x) < .001 and rest >= Float.HOVER - Float.BOB - .001 and rest <= Float.HOVER + Float.BOB + .001, "a god at rest still hovers (%.2f tiles) and stands upright"%rest)
	var before_start: float = -baked.rotation.x
	god_frame(city, god, base, 1.0/60.0, Float.SPEED_FULL/60.0)
	check(-baked.rotation.x - before_start < .01, "starting to glide eases the lean in")
	# Frame-rate independence of the settled lean.
	var leans := []
	for fps in [30, 60, 120]:
		var other := god_state(baked, parts)
		for frame in fps:
			god_frame(city, other, base, 1.0/fps, Float.SPEED_FULL/fps)
		leans.append(-baked.rotation.x)
	check(absf(leans[0]-leans[1]) < .004 and absf(leans[1]-leans[2]) < .004, "the lean after one second is the same at 30, 60 and 120 FPS")
	# Presentation only: the entry's own native track is never written.
	var native := Vector3(1, 2, 3)
	var tracked := god_state(baked, parts)
	tracked.merge({"native_position":native,"from":native,"to":native})
	for frame in 30:
		god_frame(city, tracked, base, 1.0/60.0, .01)
	check(tracked.native_position == native and tracked.from == native and tracked.to == native, "floating never changes the core's position track")
	# Two gods are never in step, and a citizen is not lifted.
	var second_node := Node3D.new(); root.add_child(second_node)
	var first_bob := god_state(baked, parts); var second_bob := god_state(second_node, [])
	god_frame(city, first_bob, base, .016, 0.0); god_frame(city, second_bob, base, .016, 0.0)
	check(first_bob.fl_time != second_bob.fl_time, "each god starts at its own point of the bob")
	var citizen := entry(); citizen.merge({"node":second_node,"morphs":[],"human":true,"clips":{},"action":1})
	second_node.position = base
	city.animate_walker(citizen, .016, .01)
	check(second_node.position == base and second_node.rotation.x == 0.0, "a citizen is neither lifted nor tilted")
	second_node.free()
	# The turn is a slow sweep, shorter than a citizen's, by the short way round.
	var turn_god := 0.0; var turn_human := 0.0
	for frame in 12:
		turn_god = Float.heading(turn_god, Vector3.LEFT, 1.0/60.0); turn_human = Motion.heading(turn_human, Vector3.LEFT, 1.0/60.0)
	check(absf(turn_god) < absf(turn_human) * .5 and absf(turn_god) > 0, "a god turns more slowly than a citizen")
	var wrapped: float = Float.heading(deg_to_rad(179), Vector3(sin(deg_to_rad(179)), 0, -cos(deg_to_rad(179))), .05)
	check(absf(angle_difference(deg_to_rad(179), wrapped)) < deg_to_rad(2), "a god's turn crosses the angle wrap by the short route")
	baked.free()

func run() -> void:
	var reference := timeline(120)
	for fps in [30,60,120]:
		var result := timeline(fps)
		check(absf(result.travel-Motion.STRIDE)<.000001 and absf(result.walk_weight-reference.walk_weight)<.000001, "same distance and stopping blend at %d FPS"%fps)
	var gait := entry()
	Motion.advance(gait,.1,.064)
	check(gait.walk_weight>0 and gait.walk_weight<1, "walking begins with a blended pose")
	var weight: float=gait.walk_weight;var travel: float=gait.travel
	Motion.advance(gait,.04,0)
	check(gait.moving and gait.walk_weight == weight and gait.travel == travel, "brief snapshot gaps hold the gait without manufacturing steps")
	Motion.advance(gait,1,0)
	check(not gait.moving and gait.walk_weight == 0 and gait.travel == travel, "a stopped citizen settles to idle with unchanged phase")
	check(Motion.planar_distance(Vector3(0,4,0)) == 0 and is_equal_approx(Motion.planar_distance(Vector3(3,9,4)),5), "terrain/deck height changes do not advance a step")
	var heading: float=Motion.heading(deg_to_rad(179),Vector3(sin(deg_to_rad(179)),0,-cos(deg_to_rad(179))),.05)
	check(absf(angle_difference(deg_to_rad(179),heading))<deg_to_rad(2), "heading interpolation crosses the angle wrap by the short route")
	for fps in [30,60,120]:
		var turn:=0.0
		for frame in fps/5:turn=Motion.heading(turn,Vector3.LEFT,1.0/fps)
		check(absf(turn-(PI/2*(1-exp(-Motion.TURN_RATE*.2))))<.000001, "corner turn is smooth and frame-rate independent at %d FPS"%fps)

	# Exercise the actual runtime animator with optimized morph aliases and a fresh VAT.
	# Loaded here, not preloaded: main.gd names the GameAudio autoload, which does not exist while this script is compiled.
	var City: GDScript = load("res://scripts/main.gd")
	var city = City.new() # Remains outside the tree: no native city is opened by this gate.
	var weights := {}
	city.add_pose_weights(weights,Vector3(2,2,.6),.4)
	city.add_pose_weights(weights,Vector3(2,3,.5),.6)
	check(is_equal_approx(weights[2],.7) and is_equal_approx(weights[3],.3), "shared aliases add across both clips with normalized weights")
	for asset in ["philosopher","physician_crowd"]:
		var model: Node3D=load("res://assets/models/%s.glb"%asset).instantiate()
		root.add_child(model)
		var morphs: Array=[];city.collect_morphs(model,morphs)
		var state:=entry();state.merge({"node":model,"morphs":morphs,"human":true})
		city.animate_walker(state,.05,.02)
		var normalized := true
		for part in morphs:
			var total:=0.0
			for index in part.lit: total+=part.node.get_blend_shape_value(index)
			normalized = normalized and total<=1.00001 and total>=0
		check(not morphs.is_empty() and normalized, "%s fallback shapes blend without over-weighting aliases"%asset)
		city.animate_walker(state,1,0)
		var settled:=true
		for part in morphs:
			for index in part.lit:
				settled=settled and "idle_" in str(part.node.mesh.get_blend_shape_name(index))
		check(settled, "%s fallback clears previous walking weights when stopped"%asset)
		model.free()
	var vat := Vat.new()
	var baked: Node3D=load(vat.runtime_path("physician_crowd")).instantiate()
	root.add_child(baked)
	var parts: Array=vat.attach(baked,"physician_crowd")
	var state:=entry();state.merge({"node":baked,"morphs":parts,"human":true})
	city.animate_walker(state,.05,.02)
	check(parts.size()>0 and parts[0].node.get_instance_shader_parameter("vat_walk_blend") == state.walk_weight and parts[0].node.get_instance_shader_parameter("vat_idle_pose") is Vector3, "VAT receives both clips and the same intermediate gait weight")
	city.animate_walker(state,1,0)
	check(parts[0].node.get_instance_shader_parameter("vat_walk_blend") == 0, "VAT settles to the idle branch")
	baked.free()
	var animal: Node3D=load(vat.runtime_path("animal_sheep_nude")).instantiate()
	root.add_child(animal)
	var animal_parts: Array=vat.attach(animal,"animal_sheep_nude")
	var animal_state:=entry();animal_state.merge({"node":animal,"morphs":animal_parts,"human":false})
	city.animate_walker(animal_state,.05,.02)
	check(animal_parts[0].node.get_instance_shader_parameter("vat_walk_blend") == 1.0, "animal motion keeps its existing walk clip without the human transition")
	city.animate_walker(animal_state,.01,0)
	check(animal_parts[0].node.get_instance_shader_parameter("vat_walk_blend") == 0 and is_equal_approx(animal_state.travel,.02), "stopped animals retain their idle behavior and travelled phase")
	animal.free()
	await god_float_checks(city, vat)
	# This city was deliberately never readied; take ownership of its pre-created nodes.
	city.add_child(city.walker_streets.ring)
	city.add_child(city.army_view.root)
	city.world_flight.overlay.add_child(city.world_flight.veil)
	city.add_child(city.world_flight.overlay)
	city.orbit.add_child(city.orbit.camera)
	for property in city.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value=city.get(property.name)
			if value is Node and value.get_parent() == null: city.add_child(value)
	city.free()
	await process_frame
	print("LOCOMOTION_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
