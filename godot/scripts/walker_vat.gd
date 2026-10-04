extends RefCounted
# Baked-pose walkers and animals (tools/bake_walker_vat.py). A runtime derivative of a model
# (models/runtime/<asset>.glb) has no morph targets; its poses live in one texture and the
# vertex shader displaces each vertex. The derivative is used only while it is newer than
# the source GLB, so a fresh re-export falls back to the source's blend shapes.

const MODELS := "res://assets/models/"
const RUNTIME := "res://assets/models/runtime/"
const INCLUDE_PATH := "res://shaders/walker_vat.gdshaderinc"
const CULL_MARGIN := .5
var include_source := FileAccess.get_file_as_string(INCLUDE_PATH)
var finish_shader: Shader = load("res://shaders/walker_vat.gdshader")
var contracts: Dictionary = {}
var textures: Dictionary = {}
var variants: Dictionary = {}
var variant_materials: Array = []
var reads: Dictionary = {}

# Set EZEUS_NO_BAKED_POSES=1 to ignore baked poses and use the source models' blend shapes.
var disabled := OS.get_environment("EZEUS_NO_BAKED_POSES") != ""

# Path of the runtime derivative when it exists and matches the current source, else "".
func runtime_path(asset: String) -> String:
	if disabled:
		return ""
	if not contracts.has(asset):
		var contract := {}
		var sidecar := RUNTIME + asset + ".vat.json"
		if FileAccess.file_exists(sidecar) and ResourceLoader.exists(RUNTIME + asset + ".glb"):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(sidecar))
			if parsed is Dictionary and parsed.has("source"):
				var source := MODELS + str(parsed.source.file)
				var file := FileAccess.open(source, FileAccess.READ)
				if file != null and file.get_length() == int(parsed.source.bytes) and FileAccess.get_modified_time(source) == int(parsed.source.mtime):
					contract = parsed
		contracts[asset] = contract
	return RUNTIME + asset + ".glb" if not contracts[asset].is_empty() else ""

# Reads pose files on worker threads so city load overlaps them with terrain generation.
func prefetch(assets: Array) -> void:
	for asset in assets:
		if runtime_path(asset).is_empty() or textures.has(asset) or reads.has(asset):
			continue
		var read := {"bytes": PackedByteArray()}
		read.task = WorkerThreadPool.add_task(func(): read.bytes = FileAccess.get_file_as_bytes(RUNTIME + asset + ".vat"))
		reads[asset] = read

func texture_for(asset: String) -> ImageTexture:
	if not textures.has(asset):
		var contract: Dictionary = contracts[asset]
		var bytes: PackedByteArray
		if reads.has(asset):
			WorkerThreadPool.wait_for_task_completion(reads[asset].task)
			bytes = reads[asset].bytes
			reads.erase(asset)
		else:
			bytes = FileAccess.get_file_as_bytes(RUNTIME + asset + ".vat")
		var image := Image.create_from_data(int(contract.width), int(contract.height), false, Image.FORMAT_RGBAH, bytes)
		textures[asset] = ImageTexture.create_from_image(image)
	return textures[asset]

# Their shader plus the pose lookup, or null when it already defines its own vertex().
func variant_shader(base: Shader) -> Shader:
	if not variants.has(base):
		var code := base.code
		var result: Shader = null
		if not code.contains("void vertex(") and not code.contains("vat_apply"):
			var split := code.find("\n", code.find("shader_type"))
			result = Shader.new()
			result.code = code.substr(0, split + 1) + include_source + "\n" + code.substr(split + 1) + "\nvoid vertex() {\n\tVERTEX = vat_apply(VERTEX, CUSTOM0.xy);\n}\n"
		variants[base] = result
	return variants[base]

# Copies a material's shader parameters onto a pose-capable variant of its shader; null when
# the shader cannot take the pose lookup.
func variant_material(existing: ShaderMaterial, texture: ImageTexture) -> ShaderMaterial:
	for entry in variant_materials:
		if entry.existing == existing and entry.texture == texture:
			return entry.material
	var shader := variant_shader(existing.shader)
	if shader == null:
		return null
	var material := ShaderMaterial.new()
	material.shader = shader
	for uniform in existing.shader.get_shader_uniform_list():
		var value = existing.get_shader_parameter(uniform.name)
		if value != null:
			material.set_shader_parameter(uniform.name, value)
	material.set_shader_parameter("vat_poses", texture)
	variant_materials.append({"existing": existing, "texture": texture, "material": material})
	return material

func finish_material(part: MeshInstance3D, texture: ImageTexture) -> ShaderMaterial:
	var source = part.mesh.surface_get_material(0)
	var material := ShaderMaterial.new()
	material.shader = finish_shader
	material.set_shader_parameter("vat_poses", texture)
	if source is BaseMaterial3D:
		material.set_shader_parameter("roughness_value", source.roughness)
		material.set_shader_parameter("metallic_value", source.metallic)
		material.set_shader_parameter("specular_value", source.metallic_specular)
	return material

# Prepares an instantiated runtime model and returns its animated parts as
# {"node", "table", "vat": true}; null when the model's finish cannot use poses (the caller
# then loads the source model instead).
func attach(instance: Node, asset: String) -> Variant:
	if runtime_path(asset).is_empty():
		return null
	var parts: Array = []
	if not collect(instance, contracts[asset], texture_for(asset), parts):
		return null
	return parts

func collect(node: Node, contract: Dictionary, texture: ImageTexture, result: Array) -> bool:
	if node is MeshInstance3D and node.mesh != null and contract.parts.has(str(node.name)):
		var info: Dictionary = contract.parts[str(node.name)]
		var existing = node.material_override
		var material: ShaderMaterial = null
		if existing is ShaderMaterial:
			material = variant_material(existing, texture)
		elif existing == null:
			material = finish_material(node, texture)
		if material == null:
			return false
		node.material_override = material
		node.extra_cull_margin = CULL_MARGIN
		node.set_instance_shader_parameter("vat_layout", Vector2(float(info.row), float(info.rows)))
		node.set_instance_shader_parameter("vat_pose", Vector3(-1.0, -1.0, 0.0))
		result.append({"node": node, "table": info.frames, "vat": true})
	for child in node.get_children():
		if not collect(child, contract, texture, result):
			return false
	return true
