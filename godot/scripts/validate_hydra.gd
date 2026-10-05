extends SceneTree
# Imported Hydra geometry, runtime finish/pose compatibility, and mouth sockets.
const Vat = preload("res://scripts/walker_vat.gd")
const Appearance = preload("res://scripts/character_appearance.gd")
const Combat = preload("res://scripts/walker_combat.gd")
const Effects = preload("res://scripts/monster_effects.gd")
var okay := true
var checks := 0

class CityProbe:
	extends RefCounted
	var walkers: Dictionary = {}
	var contract: Dictionary = {}
	func model_contract(_asset: String) -> Dictionary: return contract

func _initialize() -> void: call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1;okay = okay and value
	print("HYDRA_CHECK ","PASS " if value else "FAIL ",description)

func collect(node: Node, parts: Array) -> void:
	if node is MeshInstance3D: parts.append(node)
	for child in node.get_children(): collect(child,parts)

func geometry(node: Node) -> Dictionary:
	var parts: Array = [];collect(node,parts)
	var stats := {"verts":0,"tris":0,"lods":0,"last_lod_tris":0}
	for part in parts:
		for surface in part.mesh.get_surface_count():
			var info: Dictionary = RenderingServer.mesh_get_surface(part.mesh.get_rid(),surface)
			var stride := 4 if int(info.vertex_count)>65535 else 2
			var triangles: int = info.index_data.size()/stride/3
			var lods: Array = info.get("lods",[])
			stats.verts+=int(info.vertex_count);stats.tris+=triangles;stats.lods+=lods.size()
			stats.last_lod_tris+=lods[-1].index_data.size()/stride/3 if not lods.is_empty() else triangles
	return stats

func run() -> void:
	var asset := "walker_hydra"
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/walker_hydra.json"))
	var source: Node = load("res://assets/models/walker_hydra.glb").instantiate()
	var stats := geometry(source);source.free()
	check(stats.verts <= 32000 and stats.tris <= 30000,"imported geometry stays in its allocation")
	check(stats.lods >= 2 and stats.last_lod_tris < stats.tris * .3,"reduced LOD ladder stays below 30% of full geometry")
	var vat := Vat.new()
	check(not vat.runtime_path(asset).is_empty(),"runtime derivative is fresh")
	var node: Node3D = load(vat.runtime_path(asset)).instantiate()
	root.add_child(node)
	var appearance := Appearance.new();appearance.apply(node,asset,contract)
	var morphs: Array = vat.attach(node,asset)
	check(morphs.size() == 2,"two animated draw surfaces retain the custom Hydra finish")
	var clips := Combat.clips(morphs)
	check(clips.get("fight",[]).size() == 24 and clips.get("fight2",[]).size() == 24 and clips.get("die",[]).size() == 30,"native combat actions resolve complete authored clips")
	for morph in morphs:
		check(morph.node.mesh.get_blend_shape_count() == 0,"runtime geometry has no dense morph buffers")
		check(morph.node.material_override.shader.code.contains("vat_apply") and morph.node.material_override.shader.code.contains("EMISSION=color"),"pose lookup retains the Hydra eye and skin finish")
	var twin: Node3D = load(vat.runtime_path(asset)).instantiate();root.add_child(twin)
	appearance.apply(twin,asset,contract)
	var twin_morphs: Array = vat.attach(twin,asset)
	check(twin_morphs[0].node.material_override == morphs[0].node.material_override,"two Hydras share cached material and pose texture")
	var entry := {"node":node,"asset":asset,"action":5,"clips":clips,"morphs":morphs,"clip":"fight2","clip_time":1.25}
	node.position=Vector3(4,.6,-3);node.rotation.y=.75
	var city := CityProbe.new();city.contract=contract;city.walkers[1]=entry
	var fx := Effects.new();root.add_child(fx)
	for head in 3:
		var a: Array = contract.monster.pose_probes.fight2_12.mouths[head]
		var b: Array = contract.monster.pose_probes.fight2_13.mouths[head]
		var expected: Vector3 = node.global_transform * Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),.5)
		check(fx.head_origin(city,asset,node.global_position,head,Vector3.ZERO).distance_to(expected)<.00001,"head %d venom follows interpolated mouth, native height and facing" % head)
	check(fx.head_origin(city,asset,Vector3(30,0,30),0,Vector3.ONE)==Vector3.ONE,"missing nearby model retains the safe emission fallback")
	entry.clip_time=0;Combat.animate(entry,0)
	check(entry.clip_time == 0,"paused combat sampling holds its phase")
	Combat.animate(entry,.1)
	check(is_equal_approx(entry.clip_time,.1),"combat progresses with supplied gameplay time")
	entry.action=6;Combat.animate(entry,5)
	var last: int = morphs[0].table.die_29
	check(morphs[0].node.get_instance_shader_parameter("vat_pose")==Vector3(last,last,0),"death holds the final collapsed pose")
	if okay and "--update-hydra-baseline" in OS.get_cmdline_user_args():
		var path := "res://data/geometry_baseline.json"
		var baseline := FileAccess.get_file_as_string(path)
		var pattern := RegEx.new();pattern.compile('"walker_hydra"\\s*:\\s*\\{[^}]*\\}')
		var replacement := '"walker_hydra": {\n\t\t\t"tris": %d,\n\t\t\t"verts": %d\n\t\t}' % [stats.tris,stats.verts]
		var file:=FileAccess.open(path,FileAccess.WRITE)
		file.store_string(pattern.sub(baseline,replacement));file.close()
		print("HYDRA_BASELINE updated only walker_hydra")
	var output:=FileAccess.open("res://captures/hydra-runtime-validation.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"okay":okay,"checks":checks,"geometry":stats},"\t"));output.close()
	node.free();twin.free();fx.free()
	print("HYDRA_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
