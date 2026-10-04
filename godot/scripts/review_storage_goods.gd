extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	for frame in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("Captured: ", path)

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	var city: Node3D = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80:
		await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.orbit.enabled = false
	city.set_process_unhandled_input(false)
	city.hud.inspector.hide()
	city.hud.set_goals_expanded(false)
	
	# 1. Warehouse cluster (Wine, Sculptures, Fleece, Marble)
	city.orbit.target = city.world_position(150.0, -53.0, 0)
	city.orbit.distance = 28.0
	city.orbit.pitch = 38.0
	city.orbit.yaw = 40.0
	city.orbit.refresh()
	await capture("res://captures/storage-goods-warehouses.png")
	
	# 2. Granaries (Meat, Oranges)
	city.orbit.target = city.world_position(96.0, -51.0, 0)
	city.orbit.distance = 22.0
	city.orbit.pitch = 42.0
	city.orbit.yaw = 45.0
	city.orbit.refresh()
	await capture("res://captures/storage-goods-granary.png")
	
	# 3. Trade Post (15 bays of Wine)
	city.orbit.target = city.world_position(147.0, -30.0, 0)
	city.orbit.distance = 24.0
	city.orbit.pitch = 38.0
	city.orbit.yaw = 45.0
	city.orbit.refresh()
	await capture("res://captures/storage-goods-tradepost.png")
	
	print("All storage goods captures completed successfully!")
	quit()
