extends Node
# One isolated, on-demand viewport; reuses the city's already-loaded models. Only the small
# finished textures are retained (at most one per building design), never a viewport per card.
signal thumbnail_ready(key: String, texture: Texture2D)
var factory: Callable
var cache := {}
var pending: Array[Dictionary] = []
var busy := false
var rendering_asset := ""
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D

static func key(item: Dictionary) -> String:
	# A component mesh is not a building identity: agoras, pyramids and shrines
	# share components but need different pictures. Trade partners share a design.
	return str(item.name).get_slice(":", 0)

func request(item: Dictionary) -> Texture2D:
	var design := key(item)
	if cache.has(design): return cache[design]
	if design != rendering_asset and not pending.any(func(next): return key(next) == design) and DisplayServer.get_name() != "headless":
		pending.append(item.duplicate(true))
		if not busy: _render_next.call_deferred()
	return null

func _setup() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(160, 100)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -30, 0)
	light.light_energy = 1.15
	light.light_color = Color(1.0,.94,.82)
	viewport.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 140, 0)
	fill.light_energy = .4
	fill.light_color = Color(.76,.85,1.0)
	viewport.add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(.75, .83, .89)
	environment.environment.ambient_light_energy = .5
	viewport.add_child(environment)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = .05
	camera.far = 300
	viewport.add_child(camera)

func _bounds(node: Node3D, transform: Transform3D, boxes: Array[AABB]) -> void:
	if not node.visible: return
	var local := transform * node.transform
	if node is MeshInstance3D and node.mesh != null:
		boxes.append(local * node.get_aabb())
	for child in node.get_children():
		if child is Node3D: _bounds(child, local, boxes)

func _render_next() -> void:
	if busy or pending.is_empty() or not factory.is_valid(): return
	busy = true
	if viewport == null: _setup()
	var item: Dictionary = pending.pop_front()
	var asset := key(item)
	rendering_asset = asset
	var model: Node3D = factory.call(item)
	# Roads are terrain, and developer placeholders may have no mesh. Keep their vector icon.
	if model == null:
		cache[asset] = null
		busy = false
		rendering_asset = ""
		if not pending.is_empty(): _render_next.call_deferred()
		return
	stage.add_child(model)
	var boxes: Array[AABB] = []
	_bounds(model, Transform3D.IDENTITY, boxes)
	if boxes.is_empty(): cache[asset] = null
	if not boxes.is_empty():
		var box := boxes[0]
		for next in boxes.slice(1): box = box.merge(next)
		var center := box.get_center()
		var reach := maxf(box.size.length(), .5)
		camera.position = center + Vector3(1.1, .9, 1.3).normalized() * reach * 2
		camera.look_at(center)
		# Fit all eight corners in camera space; keep 12% room around silhouettes.
		var projected := camera.global_transform.affine_inverse() * box
		camera.size = maxf(projected.size.y, projected.size.x / 1.6) * 1.12
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		# New meshes/materials may only enter the render server on the first frame.
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		if image != null:
			cache[asset] = ImageTexture.create_from_image(image)
			thumbnail_ready.emit(asset, cache[asset])
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	model.queue_free()
	busy = false
	rendering_asset = ""
	if not pending.is_empty(): _render_next.call_deferred()
