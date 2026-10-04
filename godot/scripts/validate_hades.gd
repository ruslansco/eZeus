extends SceneTree
# Focused behavior gate for the cape fire in both GPU and morph-pose paths.
const Appearance := preload("res://scripts/character_appearance.gd")
const Vat := preload("res://scripts/walker_vat.gd")
var checks := 0
var okay := true

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("HADES_CHECK ","PASS " if value else "FAIL ",label)

func _initialize() -> void:
	call_deferred("run")

func collect(node: Node, parts: Array) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh and node.mesh.get_blend_shape_count()>0:
		var table := {}
		for index in node.mesh.get_blend_shape_count():
			for name in String(node.mesh.get_blend_shape_name(index)).split("|"):
				table[name] = index
		parts.append({"node":node,"table":table})
	for child in node.get_children():
		collect(child,parts)

func pose(parts: Array, name: String) -> void:
	for part in parts:
		var index: int = part.table.get(name,-1)
		var mesh: MeshInstance3D = part.node
		if part.get("vat",false):
			mesh.set_instance_shader_parameter("vat_pose",Vector3(index,-1,0))
		else:
			for i in mesh.mesh.get_blend_shape_count():
				mesh.set_blend_shape_value(i,float(i==index))

func authority_free(node: Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D or node is NavigationLink3D:
		return false
	for child in node.get_children():
		if not authority_free(child):
			return false
	return true

func run() -> void:
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/walker_hades.json"))
	var identity: Dictionary = contract.character.identities[0].profile
	check(identity.age>=65 and identity.grey>.8 and identity.beard_length>.03,"older Hades identity and full gray beard")
	var vat := Vat.new()
	var runtime: String = vat.runtime_path("walker_hades")
	check(not runtime.is_empty(),"current GPU pose derivative is fresh")
	for backend in ["vat","morph"]:
		var source: String = runtime if backend=="vat" else "res://assets/models/walker_hades.glb"
		var model: Node3D = load(source).instantiate()
		Appearance.new().apply(model,"walker_hades",contract)
		var parts: Array = []
		if backend=="vat":
			parts = vat.attach(model,"walker_hades")
			model.set_meta("vat_parts",parts)
		else:
			collect(model,parts)
		root.add_child(model)
		await process_frame
		var effect: Node3D = model.get_node("HadesHemFire")
		var flames: MeshInstance3D = effect.get_node("CapeFlames")
		var embers: GPUParticles3D = effect.get_node("CapeEmbers")
		var light: OmniLight3D = effect.get_node("CapeFirelight")
		check(flames.mesh.get_faces().size()/3==96 and embers.amount==18 and not light.shadow_enabled and light.omni_range<=2.5 and authority_free(effect),backend+" bounded fire geometry/particles/light have no simulation authority")
		check(flames.material_override.shader.code.contains("blend_add") and parts[0].node.material_override.shader.code.contains("hades_flame") and not parts[0].node.material_override.shader.code.contains("ALPHA"),backend+" flame overlay preserves the opaque character finish")
		pose(parts,"idle_00")
		await process_frame
		await process_frame
		check(effect.visible and absf(effect.scale.x-1)<.001 and absf(effect.position.y)<.001,backend+" idle fire sits under the cape")
		model.position = Vector3(3,0,4)
		model.rotation.y = .7
		pose(parts,"walk_06")
		await process_frame
		await process_frame
		check(effect.visible and effect.scale.x>.99 and (effect.global_position-model.global_position).length()<.001,backend+" fire follows native walker movement and facing")
		pose(parts,"disappear_31")
		await process_frame
		await process_frame
		check(not effect.visible and effect.scale.x<.04 and absf(effect.position.y-.75)<.001,backend+" fire shrinks/lifts and vanishes with Hades")
		pose(parts,"disappear_15")
		await process_frame
		await process_frame
		check(effect.visible and effect.scale.x>.04 and effect.scale.x<1 and effect.position.y>0,backend+" reverse-arrival fire follows the partial native pose")
		# The presentation blends sampled native frames; the fire must carry the
		# same weight in GPU and fallback paths, rather than snapping at a switch.
		for part in parts:
			var idle: int = part.table.get("idle_00",-1)
			var vanish: int = part.table.get("disappear_31",-1)
			if part.get("vat",false):
				part.node.set_instance_shader_parameter("vat_pose",Vector3(idle,vanish,.45))
			else:
				for i in part.node.mesh.get_blend_shape_count():
					part.node.set_blend_shape_value(i,0)
				if idle==vanish:
					part.node.set_blend_shape_value(idle,1)
				else:
					part.node.set_blend_shape_value(idle,.55)
					part.node.set_blend_shape_value(vanish,.45)
		await process_frame
		await process_frame
		check(effect.visible and absf(effect.scale.x-(1-.97*.45))<.001 and absf(effect.position.y-.75*.45)<.001,backend+" fire carries the exact native frame blend weight")
		pose(parts,"disappear_00")
		await process_frame
		await process_frame
		check(effect.visible and absf(effect.scale.x-1)<.001 and absf(effect.position.y)<.001,backend+" arrival restores full cape fire")
		model.free()
	print("HADES_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
