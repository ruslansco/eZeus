extends Node3D
# Cosmetic only: one indexed mesh, 18 embers and one small shadowless light.
# Native positions/actions/RNG are never queried or changed. The model's own
# disappearance pose controls the effect's scale/lift in VAT and morph fallback.
const FIRE := preload("res://shaders/hades_hem_fire.gdshader")
const TONGUES := 24
const EMBERS := 18
var pose_part: Dictionary = {}
var shrink_by_pose: Dictionary = {}
var embers: GPUParticles3D
var glow: OmniLight3D

static func attach(model: Node) -> void:
	if model.has_node("HadesHemFire"):
		return
	var effect := load("res://scripts/hades_hem_fire.gd").new() as Node3D
	effect.name = "HadesHemFire"
	model.add_child(effect)

func _ready() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in TONGUES:
		var a := TAU*float(i)/TONGUES
		var radius := 1.0+.075*sin(float(i)*2.17)
		var center := Vector3(sin(a)*.66*radius,.018,cos(a)*.60*radius)
		var height := .24+.19*(.5+.5*sin(float(i)*2.39))
		var width := .23+.09*(.5+.5*cos(float(i)*1.71))
		for turn in [0.0,PI*.5]:
			var tangent := Vector3(cos(a+turn),0,-sin(a+turn))*width*.5
			var corners := [center-tangent,center+tangent,center+tangent+Vector3.UP*height,center-tangent+Vector3.UP*height]
			var uvs := [Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)]
			for index in [0,1,2,0,2,3]:
				surface.set_normal(Vector3(0,0,1))
				surface.set_color(Color(float(i)/TONGUES,1,1))
				surface.set_uv(uvs[index])
				surface.add_vertex(corners[index])
	surface.index()
	var flames := MeshInstance3D.new()
	flames.name = "CapeFlames"
	flames.mesh = surface.commit()
	var finish := ShaderMaterial.new()
	finish.shader = FIRE
	flames.material_override = finish
	flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flames.extra_cull_margin = .05
	add_child(flames)
	embers = GPUParticles3D.new()
	embers.name = "CapeEmbers"
	embers.amount = EMBERS
	embers.lifetime = 1.6
	embers.preprocess = 1.6
	embers.local_coords = true
	embers.visibility_aabb = AABB(Vector3(-1,-.1,-1),Vector3(2,1.5,2))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process.emission_ring_axis = Vector3.UP
	process.emission_ring_radius = .75
	process.emission_ring_inner_radius = .57
	process.emission_ring_height = .04
	process.direction = Vector3.UP
	process.spread = 18.0
	process.initial_velocity_min = .22
	process.initial_velocity_max = .48
	process.gravity = Vector3(0,.05,0)
	process.scale_min = .7
	process.scale_max = 1.3
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,.15,.65,1])
	gradient.colors = PackedColorArray([Color(1,.06,.01,0),Color(1,.3,.025,.8),Color(.9,.035,.002,.6),Color(.5,.01,0,0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	embers.process_material = process
	var spark := QuadMesh.new()
	spark.size = Vector2(.018,.032)
	var spark_finish := StandardMaterial3D.new()
	spark_finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_finish.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_finish.vertex_color_use_as_albedo = true
	spark_finish.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	spark.material = spark_finish
	embers.draw_pass_1 = spark
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(embers)
	glow = OmniLight3D.new()
	glow.name = "CapeFirelight"
	glow.position.y = .3
	glow.light_color = Color(1,.16,.02)
	glow.light_energy = .7
	glow.omni_range = 2.4
	glow.shadow_enabled = false
	add_child(glow)
	var parts: Array = get_parent().get_meta("vat_parts", [])
	if parts.is_empty():
		_collect_morphs(get_parent(),parts)
	# Select a body part whose disappearance actually changes, avoiding the
	# staff's held-pose aliases. Reused early frames all have shrink = zero.
	var most_distinct := 0
	for part in parts:
		var distinct := {}
		for i in 32:
			var frame: int = part.table.get("disappear_%02d"%i,-1)
			if frame >= 0:
				distinct[frame] = true
		if distinct.size() > most_distinct:
			most_distinct = distinct.size()
			pose_part = part
	if not pose_part.is_empty():
		for i in 32:
			var q := clampf((float(i)/31.0-.35)/.55,0,1)
			var shrink := q*q*(3.0-2.0*q)
			var frame: int = pose_part.table.get("disappear_%02d"%i,-1)
			if frame >= 0:
				shrink_by_pose[frame] = shrink

func _collect_morphs(node: Node, parts: Array) -> void:
	if node == self:
		return
	if node is MeshInstance3D and node.mesh is ArrayMesh and node.mesh.get_blend_shape_count()>0:
		var table := {}
		for index in node.mesh.get_blend_shape_count():
			for alias in String(node.mesh.get_blend_shape_name(index)).split("|"):
				table[alias] = index
		parts.append({"node":node,"table":table})
	for child in node.get_children():
		_collect_morphs(child,parts)

func _process(_delta: float) -> void:
	var shrink := 0.0
	if not pose_part.is_empty():
		var mesh: MeshInstance3D = pose_part.node
		if pose_part.get("vat",false):
			var pose: Vector3 = mesh.get_instance_shader_parameter("vat_pose")
			shrink = lerpf(float(shrink_by_pose.get(int(pose.x),0)),float(shrink_by_pose.get(int(pose.y),0)),pose.z)
		else:
			for index in shrink_by_pose:
				shrink += float(shrink_by_pose[index])*mesh.get_blend_shape_value(index)
	var size := 1.0-.97*shrink
	scale = Vector3.ONE*size
	position.y = .75*shrink
	visible = size>.04
	embers.emitting = visible
	glow.light_energy = .7*size
