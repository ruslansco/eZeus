extends RefCounted
# Walker route editing, as the SDL route editor (eGameWidget::setPatrolBuilding): the inspector's "Walker route" button on a
# walker building of the player's (a vendor or an agora space edits its agora's walkers) begins it. Each left click on a road
# adds the next guide and a click on a guide takes it away (`route_toggle`); the bar clears the route, restores the guides it
# had, makes the walkers walk it one way or both ways, or closes the editor (also Escape or a right click). The walk the engine
# finds through the guides is drawn in gold, the way back in pale blue, the guides as numbered posts. The path finder runs on
# the board's threads, so the editor reads the route again a moment after each change.

const REFRESH_SECONDS := .3
const PATH_COLOR := Color(1.0, .78, .25, .78)
const REVERSE_COLOR := Color(.55, .80, 1.0, .70)

var city
var active := false
var value: Dictionary = {}
var age := 0.0
var signature := ""
var markers: Node3D
var bar: PanelContainer
var caption: Label
var buttons: Dictionary = {}

func attach(main) -> void:
	city = main
	markers = Node3D.new()
	markers.name = "RouteMarkers"
	markers.visible = false
	city.world.add_child(markers)
	bar = PanelContainer.new()
	bar.name = "RouteEditor"
	bar.visible = false
	# At the top of the map, where the bottom bar and the hint line stay clear.
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.position = Vector2(-330, 64)
	bar.custom_minimum_size = Vector2(660, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	bar.add_child(column)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for id in ["clear", "restore", "both", "close"]:
		var button := Button.new()
		button.name = "Route" + id.capitalize()
		button.focus_mode = Control.FOCUS_NONE
		if id == "close":
			button.theme_type_variation = "Primary"
		button.pressed.connect(press.bind(id))
		row.add_child(button)
		buttons[id] = button
	city.hud.add_child(bar)

# The inspector's button: edit the route of the inspected building's walkers.
func begin(inspection: Dictionary) -> bool:
	return city.core.send("route_begin %d %d %d" % [int(inspection.x), int(inspection.y), int(inspection.target_token)])

func toggle(cell: Vector2i) -> bool:
	return city.core.send("route_toggle %d %d" % [cell.x, cell.y])

func press(id: String) -> void:
	match id:
		"clear":
			city.core.send("route_clear")
		"restore":
			city.core.send("route_restore")
		"both":
			city.core.send("route_both")
		"close":
			end()

func end() -> void:
	if active:
		city.core.send("route_end")
	apply({"active": false})

# A `route` answer (from any route command, or the editor's own reading).
func apply(answer: Dictionary) -> void:
	value = answer
	active = bool(answer.get("active", false))
	bar.visible = active
	markers.visible = active
	if not active:
		signature = ""
		clear_markers()
		return
	var labels: Dictionary = answer.get("labels", {})
	buttons.clear.text = str(labels.get("clear", "Clear"))
	buttons.restore.text = str(labels.get("restore", "Restore"))
	# As the SDL button: it names the way the walkers walk now; pressing it changes to the other.
	buttons.both.text = str(labels.get("both" if bool(answer.get("both", false)) else "one", ""))
	buttons.close.text = str(labels.get("close", "Close"))
	var guides: Array = answer.get("guides", [])
	caption.text = (city.tr("%s: click roads to lead its walkers; click a post to take it away.") % str(answer.get("name", ""))) + "  " + \
		(city.tr("Guides: %d") % guides.size() if not guides.is_empty() else city.tr("No guides: the walkers roam freely."))
	var key := JSON.stringify([guides, answer.get("path", []), answer.get("reverse", [])])
	if key != signature:
		signature = key
		draw()

func update(dt: float) -> void:
	if not active:
		return
	age += dt
	if age < REFRESH_SECONDS or city.core.simulation == null:
		return
	age = 0.0
	var answer: Dictionary = city.core.query("route")
	if answer.get("kind", "") == "route":
		apply(answer)

func clear_markers() -> void:
	for child in markers.get_children():
		markers.remove_child(child)
		child.queue_free()

func ground(cell: Vector2) -> Vector3:
	var point: Vector3 = city.world_position(cell.x, cell.y, 0)
	point.y = city.terrain_height_world(point.x, point.z)
	return point

func material(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	return paint

# The tiles of a walk as flat plates, one multimesh for the walk.
func plates(cells: Array, color: Color, lift: float, size: float) -> void:
	if cells.is_empty():
		return
	var plate := BoxMesh.new()
	plate.size = Vector3(size, .03, size)
	plate.material = material(color)
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = plate
	many.instance_count = cells.size()
	for index in cells.size():
		var cell: Array = cells[index]
		many.set_instance_transform(index, Transform3D(Basis(), ground(Vector2(float(cell[0]), float(cell[1]))) + Vector3.UP * lift))
	var shown := MultiMeshInstance3D.new()
	shown.multimesh = many
	shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markers.add_child(shown)

func draw() -> void:
	clear_markers()
	plates(value.get("path", []), PATH_COLOR, .09, .62)
	plates(value.get("reverse", []), REVERSE_COLOR, .07, .82)
	var guides: Array = value.get("guides", [])
	for index in guides.size():
		var at := ground(Vector2(float(guides[index][0]), float(guides[index][1])))
		var post := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = .2
		cylinder.bottom_radius = .26
		cylinder.height = 1.6
		cylinder.material = material(Color(1.0, .84, .32))
		post.mesh = cylinder
		post.position = at + Vector3.UP * .8
		post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		markers.add_child(post)
		var number := Label3D.new()
		number.text = str(index + 1)
		number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number.no_depth_test = true
		number.font_size = 96
		number.pixel_size = .014
		number.outline_size = 18
		number.modulate = Color(1, .95, .8)
		number.position = at + Vector3.UP * 2.1
		markers.add_child(number)
	# The building whose walkers these are.
	if value.has("footprint"):
		var r: Array = value.footprint
		var ring := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(float(r[2]) + .2, .04, float(r[3]) + .2)
		box.material = material(Color(1.0, .78, .25, .45))
		ring.mesh = box
		ring.position = ground(Vector2(float(r[0]) + (float(r[2]) - 1) * .5, float(r[1]) + (float(r[3]) - 1) * .5)) + Vector3.UP * .1
		markers.add_child(ring)
