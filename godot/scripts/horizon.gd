extends Node3D
# Presentation-only ocean and countryside; never a board extension.
const Surroundings = preload("res://scripts/surroundings.gd")
const MapBorder = preload("res://scripts/map_border.gd")
const SIZE := 6000.0
var ocean := MeshInstance3D.new()
var far_ground := MeshInstance3D.new()
var surroundings := Surroundings.new()
var border := MapBorder.new()
var sea_level := 0.0
var ready_for_review := false

func _init() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE,SIZE)
	for node in [ocean,far_ground]:
		node.mesh=plane
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visible=false
		add_child(node)
	add_child(surroundings)
	add_child(border)

func update(tiles: Dictionary, origin: Vector2i, extent: Vector2i, geometry: RefCounted, style: RefCounted, forest: Node3D) -> void:
	surroundings.update(tiles,origin,extent,geometry,forest)
	border.update(tiles,geometry)
	sea_level=surroundings.sea_level-.002
	ocean.visible=surroundings.has_ocean
	far_ground.visible=not surroundings.has_ocean
	ocean.position.y=sea_level
	var water := ShaderMaterial.new()
	water.shader=preload("res://shaders/ocean.gdshader")
	water.set_shader_parameter("surface_noise",preload("res://assets/terrain/surface_noise.tres"))
	water.set_shader_parameter("terrain_data",style.field_texture)
	water.set_shader_parameter("map_extent",Vector2(extent))
	water.set_shader_parameter("native_mask",surroundings.native_mask)
	water.set_shader_parameter("scenery_data",surroundings.field_texture)
	var corner: Vector3=surroundings.world(Vector2(surroundings.start),0)
	water.set_shader_parameter("scenery_origin",Vector2(corner.x,-corner.z))
	water.set_shader_parameter("scenery_size",float(surroundings.side))
	water.set_shader_parameter("field_width",float(surroundings.field_width))
	ocean.material_override=water
	far_ground.position.y=surroundings.sea_level-.035
	var ground := ShaderMaterial.new()
	ground.shader=preload("res://shaders/surroundings.gdshader")
	ground.set_shader_parameter("surface_noise",preload("res://assets/terrain/surface_noise.tres"))
	ground.set_shader_parameter("ground_normal",preload("res://assets/terrain/ground_normal.tres"))
	ground.set_shader_parameter("sea_level",-100.0)
	ground.set_shader_parameter("vegetation_override",0.0)
	far_ground.material_override=ground
	ready_for_review=true
