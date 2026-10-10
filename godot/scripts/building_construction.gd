extends RefCounted
# A batched height reveal over original opaque palette meshes. No source geometry
# is edited. Unsupported textured/VAT parts keep the existing native growth path.
const SHADER=preload("res://shaders/building_construction.gdshader")
var materials: Dictionary={}
var compatible: Dictionary={}

static func plain_palette(original: Material) -> bool:
	return original is StandardMaterial3D and original.albedo_texture==null and original.normal_texture==null and original.roughness_texture==null and original.metallic_texture==null and original.ao_texture==null and original.heightmap_texture==null and not original.normal_enabled and not original.ao_enabled and not original.heightmap_enabled and not original.clearcoat_enabled and not original.rim_enabled and original.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not original.emission_enabled and original.vertex_color_use_as_albedo

static func eligible(asset: String) -> bool:
	return (asset.begins_with("sanctuary_") and not asset.begins_with("sanctuary_court_")) or asset.begins_with("pyramid_")

func can_reveal(node: Node) -> bool:
	if node is MeshInstance3D and node.mesh!=null:
		if node.mesh.get_surface_count()!=1 or node.material_override!=null:return false
		var original: Material=node.mesh.surface_get_material(0)
		if not plain_palette(original):return false
	for child in node.get_children():
		if not can_reveal(child):return false
	return true

func apply(node: Node, asset: String) -> void:
	if not eligible(asset):return
	if not compatible.has(asset):compatible[asset]=can_reveal(node)
	if not compatible[asset]:return
	apply_parts(node)

func apply_parts(node: Node) -> void:
	if node is MeshInstance3D and node.mesh!=null:
		var original: StandardMaterial3D=node.mesh.surface_get_material(0)
		var key:=original.get_instance_id()
		if not materials.has(key):
			var finish:=ShaderMaterial.new();finish.shader=SHADER
			finish.set_shader_parameter("surface_roughness",original.roughness)
			finish.set_shader_parameter("surface_metallic",original.metallic)
			finish.set_shader_parameter("base_colour",original.albedo_color)
			materials[key]=finish
		node.material_override=materials[key];node.set_meta("construction_reveal",true)
	for child in node.get_children():apply_parts(child)

func active(building: Dictionary) -> bool:
	return int(building.get("grow",100))<100 and not building.get("stretch",false) and compatible.get(str(building.asset),false)
