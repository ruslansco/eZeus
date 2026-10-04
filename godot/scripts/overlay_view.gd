extends Node3D
# Draws the active city overlay. The core decides what each overlay shows (see scripts/overlays.gd and the `overlay`
# query); this node asks for it while an overlay is on, then draws the three parts that are not model visibility: value
# columns and supply markers floating over houses and buildings (one MultiMesh each), and for the appeal view a Decal
# over the whole map coloured by each place's rating. Building and walker filtering is applied by main.gd through
# `building_visible` and `walker_visible`, so the batches and the walker nodes stay the single owners of their meshes.

const Overlays = preload("res://scripts/overlays.gd")
const POLL_SECONDS := 1.0
const APPEAL_POLL_SECONDS := 3.0
const COLUMN_BASE := .08
const COLUMN_STEP := .17
const COLUMN_WIDTH := .34
signal observations_changed(data: Dictionary)

var city: Node3D
var mode := "normal"
var data: Dictionary = {}
var visible_ids: Dictionary = {}
var walker_kinds: Dictionary = {}
# Changes whenever the set of visible buildings or walker kinds does, so main.gd rebuilds only then.
var visibility_signature := 0
var age := 0.0
var columns: MultiMeshInstance3D
var markers: MultiMeshInstance3D
var decal: Decal
var appeal_texture: ImageTexture
var appeal_hash := 0
var column_count := 0
var marker_count := 0

func _ready() -> void:
	columns = _instance(BoxMesh.new())
	columns.name = "Columns"
	markers = _instance(BoxMesh.new())
	markers.name = "Markers"

func _instance(mesh: Mesh) -> MultiMeshInstance3D:
	var item := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	item.multimesh = multi
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo = true
	paint.roughness = .55
	paint.emission_enabled = true
	paint.emission = Color(.18, .18, .18)
	item.material_override = paint
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	item.visible = false
	add_child(item)
	return item

func active() -> bool:
	return mode != "normal"

func poll_interval() -> float:
	return APPEAL_POLL_SECONDS if mode == "appeal" else POLL_SECONDS

# Chooses the overlay. Returns true when the mode changed.
func set_mode(core: Node, value: String) -> bool:
	if value == mode:
		return false
	mode = value
	data = {}
	visible_ids = {}
	walker_kinds = {}
	visibility_signature = 0
	appeal_hash = 0
	age = poll_interval()
	clear_drawing()
	if mode != "normal":
		refresh(core)
	return true

func clear_drawing() -> void:
	columns.visible = false
	markers.visible = false
	column_count = 0
	marker_count = 0
	if decal != null:
		decal.visible = false

# Asks the core for the overlay and applies it. Returns true when which buildings or walkers are visible changed.
func refresh(core: Node) -> bool:
	age = 0.0
	if not active() or core.simulation == null:
		return false
	var answer: Dictionary = core.query("overlay " + mode)
	if answer.has("error") or str(answer.get("mode", "")) != mode:
		return false
	data = answer
	visible_ids.clear()
	for id in answer.visible:
		visible_ids[int(id)] = true
	walker_kinds.clear()
	for kind in answer.walker_types:
		walker_kinds[int(kind)] = true
	var signature := hash([answer.visible, answer.walker_types])
	var changed := signature != visibility_signature
	visibility_signature = signature
	redraw()
	observations_changed.emit(answer)
	return changed

func tick(dt: float, core: Node) -> bool:
	if not active():
		return false
	age += dt
	if age < poll_interval():
		return false
	return refresh(core)

func building_visible(building: Dictionary) -> bool:
	return not active() or visible_ids.has(int(building.id))

func walker_visible(kind: int) -> bool:
	return not active() or walker_kinds.has(kind)

# Height of the roof of a building in world units, where a column or a row of markers starts.
func roof(building: Dictionary) -> float:
	var contract: Dictionary = city.model_contract(str(building.asset))
	var top := 1.2
	if not contract.is_empty() and contract.has("bounds_blender"):
		top = float(contract.bounds_blender[1][2])
	return top + .25

func redraw() -> void:
	var index: Dictionary = city.building_index
	# Columns.
	var rows: Array = data.get("columns", [])
	var shown: Array = []
	for row in rows:
		if index.has(int(row[0])):
			shown.append(row)
	var multi := columns.multimesh
	multi.instance_count = 0
	multi.instance_count = shown.size()
	for i in shown.size():
		var building: Dictionary = index[int(shown[i][0])]
		var n := int(shown[i][1])
		var tone := int(shown[i][2])
		# A tax column is green when paid; unpaid it is a short red stub so the problem is visible.
		if mode == "taxes" and n == 0:
			tone = 4
		var height := COLUMN_BASE + n * COLUMN_STEP
		var centre: Vector3 = city.world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
		centre.y += roof(building) + height * .5
		multi.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(COLUMN_WIDTH, height, COLUMN_WIDTH)), centre))
		multi.set_instance_color(i, Overlays.SHORT if mode=="water" and n==0 else Overlays.TONES.get(tone, Color.WHITE))
	column_count = shown.size()
	columns.visible = column_count > 0
	# Supply markers: one small block per good, coloured when stocked and red when short.
	var supply_rows: Array = data.get("supplies", [])
	var blocks := 0
	for row in supply_rows:
		if index.has(int(row[0])):
			blocks += int(row[2])
	var marker_multi := markers.multimesh
	marker_multi.instance_count = 0
	marker_multi.instance_count = blocks
	var slot := 0
	for row in supply_rows:
		if not index.has(int(row[0])):
			continue
		var building: Dictionary = index[int(row[0])]
		var count := int(row[2])
		var has := int(row[1])
		var centre: Vector3 = city.world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
		centre.y += roof(building) + .12
		for good in count:
			var offset := Vector3((good - (count - 1) * .5) * .26, 0, 0)
			marker_multi.set_instance_transform(slot, Transform3D(Basis.from_scale(Vector3(.2, .2, .2)), centre + offset))
			marker_multi.set_instance_color(slot, Overlays.SUPPLY_COLORS[good] if (has >> good) & 1 else Overlays.SHORT)
			slot += 1
	marker_count = blocks
	markers.visible = blocks > 0
	draw_appeal()

# The appeal view: the core's grid (one character per tile, '.' for none, '0'..'9' for a rating, 'a'..'j' on houses)
# becomes a texture on a Decal over the map. Each tile is a block of texture pixels so edges stay crisp.
func draw_appeal() -> void:
	if mode != "appeal" or not data.has("appeal"):
		if decal != null:
			decal.visible = false
		return
	var info: Dictionary = data.appeal
	var grid: String = info.grid
	var signature := grid.hash()
	var extent := Vector2i(int(info.extent[0]), int(info.extent[1]))
	if decal == null:
		decal = Decal.new()
		decal.name = "AppealDecal"
		decal.cull_mask = 1
		add_child(decal)
	if signature != appeal_hash:
		appeal_hash = signature
		var scale := clampi(2048 / maxi(extent.x, extent.y), 1, 8)
		var small := Image.create(extent.x, extent.y, false, Image.FORMAT_RGBA8)
		small.fill(Color(0, 0, 0, 0))
		for row in extent.y:
			for column in extent.x:
				var symbol := grid.unicode_at(row * extent.x + column)
				if symbol == 46:
					continue
				var house := symbol >= 97
				var rating := clampi(symbol - (97 if house else 48), 0, 9)
				var color: Color = Overlays.APPEAL[rating]
				color.a = .72 if house else .5
				# Row 0 of the texture is the far (negative Z) edge, which is the highest tile row.
				small.set_pixel(column, extent.y - 1 - row, color)
		small.resize(extent.x * scale, extent.y * scale, Image.INTERPOLATE_NEAREST)
		appeal_texture = ImageTexture.create_from_image(small)
		decal.texture_albedo = appeal_texture
	decal.size = Vector3(extent.x, 80, extent.y)
	decal.position = Vector3(0, 30, 0)
	decal.albedo_mix = 1.0
	decal.visible = true
