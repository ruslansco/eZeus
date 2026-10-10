extends SceneTree
# Installed sculptures, reduced geometry, baked poses and actual mouth transforms.
const NAMES := ["cyclops","talos","hector","minotaur","satyr","medusa","maenads","harpies","calydonianboar","cerberus","chimera","sphinx","dragon","echidna","scylla","kraken"]
const Vat = preload("res://scripts/walker_vat.gd")
const Appearance = preload("res://scripts/character_appearance.gd")
const Combat = preload("res://scripts/walker_combat.gd")
const Effects = preload("res://scripts/monster_effects.gd")
var okay := true
var checks := 0
var measurements := {}

class CityProbe:
	extends RefCounted
	var walkers: Dictionary = {}
	var contract: Dictionary = {}
	func model_contract(_asset: String) -> Dictionary: return contract

func _initialize() -> void: call_deferred("run")

func check(value: bool, description: String) -> void:
	checks+=1;okay=okay and value
	print("MONSTER_RUNTIME_CHECK ","PASS " if value else "FAIL ",description)

func collect(node: Node, parts: Array) -> void:
	if node is MeshInstance3D: parts.append(node)
	for child in node.get_children(): collect(child,parts)

func geometry(node: Node) -> Dictionary:
	var parts: Array=[];collect(node,parts)
	var stats := {"verts":0,"tris":0,"lods":0,"last_lod_tris":0}
	for part in parts:
		for surface in part.mesh.get_surface_count():
			var info: Dictionary=RenderingServer.mesh_get_surface(part.mesh.get_rid(),surface)
			var stride := 4 if int(info.vertex_count)>65535 else 2
			var triangles: int=info.index_data.size()/stride/3
			var lods: Array=info.get("lods",[])
			stats.verts+=int(info.vertex_count);stats.tris+=triangles;stats.lods+=lods.size()
			stats.last_lod_tris+=lods[-1].index_data.size()/stride/3 if not lods.is_empty() else triangles
	return stats

func run() -> void:
	var appearance := Appearance.new()
	var vat := Vat.new()
	var fx := Effects.new();root.add_child(fx)
	var names: Array = NAMES.duplicate()
	var output_path := "res://captures/monster-reference-runtime.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="): names = Array(argument.trim_prefix("--only=").split(","))
		if argument.begins_with("--output="): output_path = argument.trim_prefix("--output=")
	for name in names:
		if not name in NAMES:
			check(false, "unknown monster " + str(name));continue
		var asset: String="walker_"+name
		var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % asset))
		var source: Node=load("res://assets/models/%s.glb" % asset).instantiate()
		var stats := geometry(source);measurements[asset]=stats;source.free()
		check(stats.verts<=34000 and stats.tris<=34000,asset+" imported sculpture stays in its allocation")
		check(stats.lods>=2 and stats.last_lod_tris<stats.tris*.3,asset+" has reduced LODs below 30 percent")
		check(not contract.has("character") and contract.monster.get("design_revision", "") == "monster_anatomy_v3",asset+" retains v3 anatomical geometry and authored scale without the citizen adapter")
		check(not vat.runtime_path(asset).is_empty(),asset+" baked derivative matches the installed source")
		if vat.runtime_path(asset).is_empty(): continue
		var node: Node3D=load(vat.runtime_path(asset)).instantiate();root.add_child(node)
		appearance.apply(node,asset,contract)
		var morphs: Array=vat.attach(node,asset)
		check(morphs.size()>=2 and morphs.size()<=3,asset+" uses at most three animated draw surfaces")
		var clips := Combat.clips(morphs)
		check(clips.get("fight",[]).size()==24 and clips.get("fight2",[]).size()==24 and clips.get("die",[]).size()==30,asset+" resolves both native attacks and collapse")
		for morph in morphs:
			check(morph.node.mesh.get_blend_shape_count()==0 and morph.node.material_override.shader.code.contains("vat_apply") and morph.node.material_override.shader.code.contains("EMISSION=color"),asset+" keeps baked motion and its skin/eye finish")
		var twin: Node3D=load(vat.runtime_path(asset)).instantiate();root.add_child(twin)
		appearance.apply(twin,asset,contract)
		var twins: Array=vat.attach(twin,asset)
		check(twins[0].node.material_override==morphs[0].node.material_override,asset+" instances share finish and pose texture")
		var entry := {"node":node,"asset":asset,"action":5,"clips":clips,"morphs":morphs,"clip":"fight2","clip_time":1.25}
		node.position=Vector3(4,.6,-3);node.rotation.y=.75
		var city := CityProbe.new();city.contract=contract;city.walkers[1]=entry
		for head in int(contract.monster.heads):
			var a: Array=contract.monster.pose_probes.fight2_12.mouths[head]
			var b: Array=contract.monster.pose_probes.fight2_13.mouths[head]
			var expected: Vector3=node.global_transform*Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),.5)
			check(fx.head_origin(city,asset,node.global_position,head,Vector3.ZERO).distance_to(expected)<.00001,asset+" mouth %d follows interpolated pose, height and facing" % head)
		var held: float=entry.clip_time;Combat.animate(entry,0)
		check(entry.clip_time==held,asset+" freezes combat when gameplay time stops")
		entry.action=6;Combat.animate(entry,5)
		var last: int=morphs[0].table.die_29
		check(morphs[0].node.get_instance_shader_parameter("vat_pose")==Vector3(last,last,0),asset+" holds its grounded corpse pose")
		node.free();twin.free()
		await process_frame
	fx.free()
	if okay and "--update-monster-baselines" in OS.get_cmdline_user_args():
		var path := "res://data/geometry_baseline.json"
		var baseline := FileAccess.get_file_as_string(path)
		for asset in measurements:
			var stats: Dictionary=measurements[asset]
			var pattern := RegEx.new();pattern.compile('"'+asset+'"\\s*:\\s*\\{[^}]*\\}')
			var replacement := '"%s": {\n\t\t\t"tris": %d,\n\t\t\t"verts": %d\n\t\t}' % [asset,stats.tris,stats.verts]
			baseline=pattern.sub(baseline,replacement)
		var file := FileAccess.open(path,FileAccess.WRITE);file.store_string(baseline);file.close()
		print("MONSTER_BASELINES updated only ", measurements.keys())
	var output := FileAccess.open(output_path,FileAccess.WRITE)
	output.store_string(JSON.stringify({"okay":okay,"checks":checks,"geometry":measurements},"\t"));output.close()
	print("MONSTER_REFERENCE_RUNTIME ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
