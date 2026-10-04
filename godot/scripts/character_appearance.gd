extends RefCounted

const FINISH := preload("res://shaders/character.gdshader")
const HadesFire := preload("res://scripts/hades_hem_fire.gd")
var materials: Dictionary = {}

func apply(node: Node, asset: String, contract: Dictionary) -> void:
	if not contract.has("character"):
		return
	if not materials.has(asset):
		var finish := ShaderMaterial.new()
		finish.shader = FINISH
		finish.set_shader_parameter("greek_robe", asset == "philosopher")
		finish.set_shader_parameter("hades_flame", String(contract.character.get("art_direction", "")).begins_with("underworld_lord_"))
		var identities: Array = contract.character.get("identities", [])
		for i in mini(identities.size(),3):
			var color: Array = identities[i].clavi_srgb
			finish.set_shader_parameter("clavi_%d" % i, Color(color[0],color[1],color[2]))
		materials[asset] = finish
	apply_material(node, materials[asset])
	if asset == "walker_hades" and contract.character.get("art_direction", "") == "underworld_lord_v2":
		HadesFire.attach(node)

func apply_material(node: Node, finish: Material) -> void:
	if node.name == "HadesHemFire":
		return
	if node is MeshInstance3D:
		node.material_override = finish
	for child in node.get_children():
		apply_material(child, finish)
