extends SceneTree
# Read-only asset checks and disposable native-city staffing/clock checks.
const Activity = preload("res://scripts/building_activity.gd")
const Batches = preload("res://scripts/building_batches.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("BUILDING_ACTIVITY_CHECK ","PASS " if value else "FAIL ",message)

func _initialize() -> void:
	call_deferred("run")

func collect(node: Node, parts: Dictionary) -> void:
	if node is MeshInstance3D:parts[str(node.name)] = node
	for child in node.get_children():collect(child,parts)

func find(state: Dictionary, id: int) -> Dictionary:
	for building in state.get("buildings",[]):
		if int(building.id) == id:return building
	return {}

func run() -> void:
	var activity := Activity.new()
	var names: Array = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://..").path_join("tools/building_activity_assets.json")))
	var partial := "--partial" in OS.get_cmdline_user_args()
	var verified := 0
	var texture_bytes := 0
	var working_instances := 0
	for asset in names:
		if partial and not FileAccess.file_exists(Activity.ROOT+"runtime/"+asset+".vat.json"):continue
		var info: Dictionary = activity.contract(asset)
		check(not info.is_empty(),asset+" complete derivative matches original model")
		if info.is_empty():continue
		verified += 1
		var scene: Node = load(activity.model_path(asset)).instantiate()
		var parts := {};collect(scene,parts)
		activity.apply(scene,asset)
		var good: bool = not info.layout.parts.is_empty()
		var samples := true
		var addresses := true
		var motion := false
		var bitmap: Image = activity.texture_for(asset).get_image()
		texture_bytes += bitmap.get_data().size()
		for part_name in info.layout.parts:
			var part: Dictionary = info.layout.parts[part_name]
			if not parts.has(part_name):good=false;continue
			var node: MeshInstance3D = parts[part_name]
			var mesh: ArrayMesh = node.mesh
			good = good and node.has_meta("building_activity") and node.material_override is ShaderMaterial and mesh.get_blend_shape_count() == 0
			var arrays := mesh.surface_get_arrays(0)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var address = arrays[Mesh.ARRAY_CUSTOM0]
			addresses = addresses and address != null and address.size() == points.size()*2
			samples = samples and part.frames.has("inactive") and float(part.max_error) < .002
			for frame in range(8):samples = samples and part.frames.has("work_%02d"%frame)
			if address == null:continue
			var seen := {}
			for i in points.size():
				var column := int(address[2*i]);var row := int(address[2*i+1])
				var index := column+1024*row
				addresses = addresses and index >= 0 and index < points.size() and not seen.has(index)
				seen[index]=true
				for frame in ["work_02","work_04","inactive"]:
					var pose := int(part.frames.get(frame,-1))
					if pose >= 0:
						var delta := bitmap.get_pixel(column,int(part.row)+pose*int(part.rows)+row)
						if frame != "inactive" and Vector3(delta.r,delta.g,delta.b).length() > .01:motion=true
		check(good,asset+" GPU work materials bind every animated part, with no runtime morphs")
		check(addresses,asset+" imported vertex addresses survive Godot mesh reordering")
		check(samples and motion,asset+" work cycle moves and includes inactive state within precision limit")
		scene.free()
		await process_frame
	check(verified == names.size() or partial, "%d / %d supported work loops available"%[verified,names.size()])
	check(activity.model_path("common_house_1") == "res://assets/models/common_house_1.glb","buildings without activity keep their original model")
	# Two placements share geometry, but get different work flags and phase offsets.
	var batches := Batches.new();root.add_child(batches)
	var group := "warehouse|test"
	var placements := [{"transform":Transform3D.IDENTITY,"working":true,"animation_offset":3},{"transform":Transform3D(Basis.IDENTITY,Vector3(4,0,0)),"working":false,"animation_offset":6}]
	batches.rebuild({group:placements})
	var nodes: Array = batches.group_nodes[group].duplicate()
	var independent := false
	for node in nodes:
		if node.multimesh.use_custom_data:
			# The headless dummy renderer does not retain MultiMesh instance buffers.
			# The windowed reviewer separately reads back the actual GPU instance data.
			independent = true
	check(independent,"shared geometry supports per-instance work data (GPU values checked in visible review)")
	placements[0].working=false;batches.rebuild({group:placements})
	check(batches.last_rebuilt == 0 and nodes == batches.group_nodes[group],"staffing changes update instance data without rebuilding geometry")
	batches.rebuild({})
	check(batches.group_nodes.is_empty(),"demolition removes animated batches")
	batches.free()
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	for lang in ["en","ru"]:
		var initial: Dictionary = core.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),lang)
		check(initial.has("protocol"),lang+" designated native test city loads")
		var processor := {};var staffing := true;var offsets := true;var inactive := 0
		for building in initial.buildings:
			offsets = offsets and int(building.animation_offset) >= 0 and int(building.animation_offset) < 8
			if building.asset in names:
				if building.working:working_instances += 1
				# Palace/baths are native decorative buildings, without employment.
				if int(building.workers) == 0 and building.asset not in ["palace","baths"]:
					inactive += 1;staffing = staffing and not building.working
			if building.asset == "olive_press" and building.working:processor=building
		check(staffing,lang+" empty buildings never show workers at work")
		check(offsets,lang+" native randomized offsets are stable cycle indices")
		activity.receive(initial);activity.advance(1.0)
		var phase := activity.phase
		core.advance(.25);activity.receive(core.snapshot(false));activity.advance(1)
		check(activity.phase == phase,lang+" pause freezes work clock")
		check(not core.snapshot(false).get("buildings_changed",true),lang+" unchanged work state keeps delta snapshots compact")
		check(not processor.is_empty(),lang+" staffed producer with native inputs available")
		if not processor.is_empty():
			var info: Dictionary = core.command("inspect %d %d"%[processor.x,processor.y])
			core.command("industry %d %d %d 2048 1"%[info.x,info.y,info.target_token])
			var stopped: Dictionary = core.snapshot(true)
			var building := find(stopped,int(processor.id))
			check(not building.working and int(building.workers) == 0,lang+" native industry shutdown stops work")
			info=core.command("inspect %d %d"%[processor.x,processor.y])
			core.command("industry %d %d %d 2048 0"%[info.x,info.y,info.target_token])
			building=find(core.snapshot(true),int(processor.id))
			check(building.working and int(building.workers)>0,lang+" native industry resume restores work")
		var clock: int = initial.time
		for speed in range(4):
			core.command("speed %d"%speed);core.command("pause 0")
			for step in 4:core.advance(.05)
			var state: Dictionary = core.snapshot(false)
			activity.receive(state);activity.advance(.1)
			check(is_equal_approx(activity.phase-float(clock)/30.0,float([24,60,120,1200][speed])/30.0),"%s work motion follows native speed %d"%[lang,speed])
			clock=state.time;core.command("pause 1")
		core.command("speed 3");core.command("pause 0")
		for step in 40:core.advance(.05)
		var blocked: Dictionary=core.snapshot(false);activity.receive(blocked);phase=activity.phase
		core.advance(.25);activity.receive(core.snapshot(false));activity.advance(1)
		check(blocked.blocked and activity.phase == phase,lang+" pending decision freezes motion without choosing an outcome")
		core.close_city()
	print("BUILDING_ACTIVITY_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks," assets=",verified," vat_bytes=",texture_bytes," working_instances_across_languages=",working_instances)
	quit(0 if okay else 1)
