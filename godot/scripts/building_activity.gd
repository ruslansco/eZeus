extends RefCounted
# Authored building workers/machinery, animated once per shared GPU material.
# Static geometry stays in ordinary MultiMeshes; native snapshots gate work.
const ROOT := "res://assets/building_activity/"
const SHADER := preload("res://shaders/building_activity.gdshader")
const CLOCK := "building_work_clock"
var contracts: Dictionary = {}
var textures: Dictionary = {}
var materials: Dictionary = {}
var from_phase := 0.0
var to_phase := 0.0
var age := 0.0
var phase := 0.0
var initialized := false
var running := false

func contract(asset: String) -> Dictionary:
	if not contracts.has(asset):
		var manifest := ROOT+"runtime/"+asset+".json"
		var poses := ROOT+"runtime/"+asset+".vat.json"
		var result := {}
		if FileAccess.file_exists(manifest) and FileAccess.file_exists(poses) and ResourceLoader.exists(ROOT+"runtime/"+asset+".glb"):
			var metadata = JSON.parse_string(FileAccess.get_file_as_string(manifest))
			var layout = JSON.parse_string(FileAccess.get_file_as_string(poses))
			if metadata is Dictionary and layout is Dictionary and metadata.has("building_activity") and layout.has("parts"):
				var original := "res://assets/models/"+asset+".glb"
				# Cache freshness once per asset, not per building or frame.
				var texture := ROOT+"runtime/"+asset+".vat"
				var file := FileAccess.open(texture,FileAccess.READ)
				var complete := file != null and file.get_length() == int(layout.width)*int(layout.height)*8
				complete = complete and not layout.parts.is_empty()
				for part in layout.parts.values():
					for frame in 8:complete = complete and part.frames.has("work_%02d"%frame)
					complete = complete and part.frames.has("inactive")
				if complete and metadata.building_activity.get("revision") == "authored_work_v1" and FileAccess.get_sha256(original) == metadata.building_activity.base_sha256:
					result = {"metadata":metadata,"layout":layout}
		contracts[asset] = result
	return contracts[asset]

func model_path(asset: String) -> String:
	return ROOT+"runtime/"+asset+".glb" if not contract(asset).is_empty() else "res://assets/models/"+asset+".glb"

func texture_for(asset: String) -> ImageTexture:
	if not textures.has(asset):
		var info: Dictionary = contract(asset).layout
		var bytes := FileAccess.get_file_as_bytes(ROOT+"runtime/"+asset+".vat")
		var bitmap := Image.create_from_data(int(info.width),int(info.height),false,Image.FORMAT_RGBAH,bytes)
		textures[asset] = ImageTexture.create_from_image(bitmap)
	return textures[asset]

func apply(node: Node, asset: String) -> void:
	var info := contract(asset)
	if info.is_empty():return
	if node is MeshInstance3D and node.mesh is ArrayMesh and info.layout.parts.has(str(node.name)):
		var key := asset+":"+str(node.name)
		if not materials.has(key):
			var part: Dictionary = info.layout.parts[str(node.name)]
			var finish := ShaderMaterial.new();finish.shader=SHADER
			finish.set_shader_parameter("work_poses",texture_for(asset))
			finish.set_shader_parameter("work_layout",Vector2(part.row,part.rows))
			var frames := PackedInt32Array()
			for i in 8:frames.append(int(part.frames.get("work_%02d"%i,-1)))
			finish.set_shader_parameter("work_frames",frames)
			finish.set_shader_parameter("inactive_pose",int(part.frames.get("inactive",-1)))
			finish.set_shader_parameter("smooth_work",true)
			var original: Material = node.mesh.surface_get_material(0)
			if original is StandardMaterial3D:
				finish.set_shader_parameter("surface_roughness",original.roughness)
				finish.set_shader_parameter("surface_metallic",original.metallic)
			materials[key]=finish
		node.material_override=materials[key]
		node.set_meta("building_activity",true)
	for child in node.get_children():apply(child,asset)

func receive(snapshot: Dictionary) -> void:
	var target := float(snapshot.get("time",0))/30.0
	running = bool(snapshot.get("running",false))
	from_phase = phase if initialized and running and target >= to_phase else target
	to_phase = target;age=0.0;initialized=true
	if not running:phase=target
	RenderingServer.global_shader_parameter_set(CLOCK,fposmod(phase,8.0))

func advance(dt: float) -> void:
	if not initialized:return
	age += dt
	phase = lerpf(from_phase,to_phase,clampf(age/.1,0.0,1.0)) if running else to_phase
	RenderingServer.global_shader_parameter_set(CLOCK,fposmod(phase,8.0))
