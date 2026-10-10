extends SceneTree

const Appearance := preload("res://scripts/character_appearance.gd")
var checks := 0
var okay := true

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("CHARACTER_CHECK ","PASS " if value else "FAIL ",label)

func collect(node: Node, meshes: Array) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		collect(child, meshes)

# The 35 walking and idle frames, plus (for soldiers, heroes and gods) contiguous combat clips.
func frames_valid(frames: Dictionary) -> bool:
	var base := 0
	var clips := {}
	for frame_name in frames:
		var label := String(frame_name).rsplit("_", true, 1)[0]
		if label in ["walk", "idle"]:
			base += 1
		else:
			clips[label] = int(clips.get(label, 0)) + 1
	var valid := base >= 35 and base <= 36
	for index in range(1, 24):
		valid = valid and frames.has("walk_%02d" % index)
	for index in range(12):
		valid = valid and frames.has("idle_%02d" % index)
	for label in clips:
		# Combat clips, or the authored work clips gathering_motion.gd plays (field work, the townspeople's crews).
		valid = valid and (label in ["fight", "fight2", "die", "bless", "curse", "disappear", "appear"] or preload("res://scripts/gathering_motion.gd").COUNTS.has(label))
		for index in int(clips[label]):
			valid = valid and frames.has("%s_%02d" % [label, index])
	return valid

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var names: Array = []
	for file in DirAccess.get_files_at("res://assets/models"):
		if file.ends_with(".json"):
			var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+file))
			if manifest.has("character"):
				names.append(file.trim_suffix(".json"))
	names.sort()
	check(names.size() == 104,"all 104 human walker assets retain their anatomy adapter; the eight humanoid monsters now use the separately validated monster sculptures (%d)" % names.size())
	var appearance := Appearance.new()
	var bodies := {}
	for asset in names:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % asset))
		var scene: Node3D = load("res://assets/models/%s.glb" % asset).instantiate()
		appearance.apply(scene,asset,manifest)
		var meshes: Array = []
		collect(scene, meshes)
		var finite := true
		var anchored := false
		var lowest := 1000.0
		var semantics := {}
		var skin_colors := {}
		var frames_ok := true
		var movement := 0.0
		var materials_ok := true
		for instance in meshes:
			var mesh: ArrayMesh = instance.mesh
			materials_ok = materials_ok and instance.material_override is ShaderMaterial
			var frames := {}
			for i in mesh.get_blend_shape_count():
				for alias in String(mesh.get_blend_shape_name(i)).split("|"):
					frames[alias] = true
			frames_ok = frames_ok and frames_valid(frames)
			for i in range(1,24):
				frames_ok = frames_ok and frames.has("walk_%02d" % i)
			for i in range(12):
				frames_ok = frames_ok and frames.has("idle_%02d" % i)
			for surface in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(surface)
				var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
				var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
				var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
				finite = finite and points.size() > 0 and normals.size() == points.size() and colors.size() == points.size() and uv.size() == points.size() and uv2.size() == points.size()
				if not finite:continue
				for i in points.size():
					finite = finite and points[i].is_finite() and normals[i].is_finite() and uv[i].is_finite() and uv2[i].is_finite() and normals[i].length() > .98
					anchored = anchored or absf((instance.transform*points[i]).y) < .005
					lowest = minf(lowest, (instance.transform*points[i]).y)
					var kind := roundi(uv2[i].x*8)
					semantics[kind] = true
					if kind == 0:
						skin_colors[colors[i].to_html()] = true
				for shape in mesh.surface_get_blend_shape_arrays(surface):
					var posed: PackedVector3Array = shape[Mesh.ARRAY_VERTEX]
					finite = finite and posed.size() == points.size()
					for i in posed.size():
						finite = finite and posed[i].is_finite()
						var delta: Vector3 = posed[i] if mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE else posed[i]-points[i]
						movement = maxf(movement,delta.length())
		# The harpies fly: their lowest point hovers about half a metre over the ground instead of touching it.
		anchored = anchored or (asset == "walker_harpies" and lowest > .2 and lowest < 1.0)
		# The gods float (god_float.gd, tools/godot_god_float.py): the hover pose lifts the feet a little off the ground.
		anchored = anchored or (preload("res://scripts/god_float.gd").is_god(asset) and lowest > -.005 and lowest < .3)
		check(finite and anchored and frames_ok and movement > .01,"%s: finite geometry, ground anchor and every walk/idle sample survive import" % asset)
		check(materials_ok and semantics.has(0) and semantics.has(2) and semantics.has(3) and skin_colors.size()>20 and meshes.size()<=3 and manifest.vertices <= manifest.character.vertex_budget,"%s: painted skin, fitted hair, eyes, shared finishes and geometry budget" % asset)
		for person in manifest.character.identities:
			bodies[person.name] = person
		scene.free()
		await process_frame
	var family: Dictionary = bodies.get("Settler child",{})
	check(bodies.get("Settler mother",{}).get("sex","") == "female" and family.get("profile",{}).get("age",99)==7 and bodies.get("Settler father",{}).get("body_sha256","") != family.get("body_sha256",""),"settler mother keeps female anatomy and child keeps a separate age-specific body")
	var profiles := {}
	for person in bodies.values():
		profiles[person.body_sha256] = true
	check(profiles.size()>20,"walker roles retain distinct anatomical identities")
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	core.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),"en")
	core.command("pause 1")
	var initial: Dictionary = core.snapshot(true)
	var humans := 0
	for walker in initial.walkers:
		if walker.asset in names:
			humans += 1
	var final: Dictionary = core.snapshot(true)
	var intact: bool = initial.tiles==final.tiles and initial.walkers==final.walkers and initial.buildings==final.buildings and initial.time==final.time and initial.money==final.money
	check(initial.tiles.size()==25992 and initial.walkers.size()==279 and humans>140 and intact,"designated city loads refined pedestrians without changing native state (%d humans)" % humans)
	core.close_city()
	print("CHARACTER_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
