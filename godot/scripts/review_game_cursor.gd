extends SceneTree
# Owned cursor resources and real Control cursor requests, without loading a city.
var checks := 0
var okay := true
var clicks: Array[Vector2] = []

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("CURSOR_CHECK ","PASS " if value else "FAIL ",description)

func frames(count := 5) -> void:
	for i in count: await process_frame

func run() -> void:
	DisplayServer.window_set_title("City Rebuild — Cursor Review")
	DisplayServer.window_set_size(Vector2i(1100,620))
	root.content_scale_size = Vector2i(1100,620)
	var cursor := root.get_node("GameCursor")
	var access := root.get_node("UiAccess")
	var mode := Input.mouse_mode
	check(cursor.registered_shapes.size() == 17,"native window has all 17 cursor roles installed")
	check(not cursor.is_processing() and not cursor.is_processing_input(),"cursor adds no frame or input handler")
	for name in cursor.originals:
		var image: Image = cursor.originals[name]
		var bounds := image.get_used_rect()
		var point: Vector2 = cursor.hotspots[name]
		check(image.get_size() == Vector2i(48,48) and image.detect_alpha() != Image.ALPHA_NONE and bounds.has_area() and bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 48 and bounds.end.y < 48 and Rect2(Vector2.ZERO,Vector2(48,48)).has_point(point),"%s has transparent padding and a valid hotspot" % name)
	for name in ["arrow","point","busy"]:
		var image: Image = cursor.originals[name]
		var point: Vector2 = cursor.hotspots[name]
		check(image.get_pixelv(Vector2i(point)).a > .1 and point.y <= 6,"%s clicks at its visible upper tip" % name)
	var target := Control.new()
	target.position = Vector2(40,40)
	target.size = Vector2(200,100)
	target.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed: clicks.append(event.position))
	root.add_child(target)
	for scale in [100,110,125]:
		access.apply(scale,100)
		await frames()
		check(cursor.cursor_size == roundi(48*scale/100.0) and cursor.cursor_size <= 128,"%d%% interface size fits the hardware cursor budget" % scale)
		var event := InputEventMouseButton.new()
		event.position = target.position + Vector2(4,4)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		root.push_input(event,true)
		event.pressed = false
		root.push_input(event,true)
		check(not clicks.is_empty() and clicks.back().distance_to(Vector2(4,4)) < .01,"%d%% cursor keeps control-edge clicks aligned" % scale)
	var enlarged: Texture2D = cursor.textures.arrow
	access.apply(125,130)
	check(cursor.textures.arrow == enlarged,"text size alone does not resize or recreate the pointer")
	access.apply(100,100)
	access.apply(110,100)
	access.apply(125,100)
	check(cursor.cache.size() == 3 and cursor.textures.arrow == enlarged,"returning to an interface size reuses its cursor textures")
	access.apply(100,100)
	await frames()
	# Godot reports the actual role selected by mouse-over on this native window.
	Input.warp_mouse(target.get_global_rect().get_center())
	await frames()
	for shape in cursor.SHAPES:
		target.mouse_default_cursor_shape = shape
		var motion := InputEventMouseMotion.new()
		motion.position = target.get_global_rect().get_center()
		root.push_input(motion,true)
		await frames(2)
		check(Input.get_current_cursor_shape() == shape,"Control selects custom cursor role %d" % shape)
	check(Input.mouse_mode == mode,"cursor installation preserves mouse capture/visibility mode")
	target.queue_free()
	await frames()
	var sheet := Control.new()
	root.add_child(sheet)
	var title := Label.new()
	title.text = "OLYMPIAN CURSORS  /  actual runtime sizes"
	title.position = Vector2(28,16)
	title.add_theme_font_size_override("font_size",24)
	sheet.add_child(title)
	var names: Array = cursor.originals.keys()
	for row in 4:
		var scale := 100 if row < 2 else 125
		access.apply(scale,100)
		# Sheet positions remain physical pixels: preview the scaled texture directly.
		root.content_scale_factor = 1.0
		var light := row % 2 == 1
		var panel := ColorRect.new()
		panel.color = Color("e9ddc5") if light else Color("111d28")
		panel.position = Vector2(20,66+row*132)
		panel.size = Vector2(1060,124)
		sheet.add_child(panel)
		var label := Label.new()
		label.text = "%d%%" % scale
		label.position = Vector2(8,8)
		label.add_theme_color_override("font_color",Color("172130") if light else Color("e9ddc5"))
		panel.add_child(label)
		for column in names.size():
			var name: String = names[column]
			var texture := TextureRect.new()
			texture.texture = cursor.textures[name]
			texture.position = Vector2(69+column*75,15)
			texture.size = Vector2.ONE*cursor.cursor_size
			texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(texture)
			var caption := Label.new()
			caption.text = {"back_diagonal":"diag ↗","forward_diagonal":"diag ↘"}.get(name,name)
			caption.position = Vector2(64+column*75,82)
			caption.add_theme_font_size_override("font_size",12)
			caption.add_theme_color_override("font_color",Color("172130") if light else Color("e9ddc5"))
			panel.add_child(caption)
	access.apply(100,100)
	DisplayServer.window_move_to_foreground()
	await frames(12)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/game-cursors.png")
	print("CURSOR_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	if OS.get_cmdline_user_args().has("--hold"):
		await create_timer(45).timeout
	quit(0 if okay else 1)
