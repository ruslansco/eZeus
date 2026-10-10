extends RefCounted
# Cached presentation finish; GLB geometry, both UVs, authored palettes and LODs stay intact.
const SHADER=preload("res://shaders/architecture_finish.gdshader")
var materials: Dictionary={}

static func eligible(asset: String) -> bool:
	return asset.begins_with("common_house_") or asset.begins_with("elite_house_") or asset.begins_with("sanctuary_") or asset.begins_with("wall_") or asset in ["wall","gatehouse","tower","fountain","well","maintenance_office","library","museum","theater","gymnasium","podium","college","observatory","agora","grand_agora","granary","warehouse","trade_post","palace","stadium"]

func apply(node: Node, asset: String) -> void:
	if not eligible(asset): return
	if node is MeshInstance3D and node.mesh!=null and node.material_override==null:
		# Exported static parts have one palette surface. Never replace VAT, PBR
		# texture, transparent, emissive or metal finishes with this adapter.
		if node.mesh.get_surface_count()==1:
			var original: Material=node.mesh.surface_get_material(0)
			if preload("res://scripts/building_construction.gd").plain_palette(original) and original.metallic<.01:
				var key: int=original.get_instance_id()
				if not materials.has(key):
					var finish:=ShaderMaterial.new(); finish.shader=SHADER
					finish.set_shader_parameter("surface_roughness",original.roughness)
					finish.set_shader_parameter("base_colour",original.albedo_color)
					finish.set_meta("architecture_source",original)
					materials[key]=finish
				node.material_override=materials[key]
	for child in node.get_children(): apply(child,asset)
