extends RefCounted
# Drag-to-place roads and walls. Pressing the left button in the road tool starts a drag; while it is held the core's
# `preview_road` query draws the path it would lay (the SDL view's own path finder, orthogonal tile steps over
# buildable ground, existing roads reused) with its count and cost; releasing builds it as one undoable step with
# `build_road`. Right click, Escape, or leaving the tool cancels. A press and release on one tile is an ordinary
# single road. The wall tool drags the same way, but as the SDL view does: the outline of the rectangle between the
# press and the release tile (all of it while Shift is held), each piece shown as the model it will become, joined to
# its neighbours (`preview_wall` / `build_wall`). Common housing, elite housing and parks drag over an area (`preview_area` /
# `build_area`): housing in steps of its own size from the pressed tile toward the released one, parks on every tile, each
# plot shown as a footprint and a few as the model they will become; orchards and livestock drag the same way, a tree or an
# animal on each tile that takes one. Columns, avenues and boulevards are dragged along a path like roads (`preview_path` /
# `build_path`, the SDL view's own path rules; an avenue also lays the streets beside it). All rules live in the C++ core:
# this only shows the plan and forwards the command.

const BuildCatalog = preload("res://scripts/build_catalog.gd")
const REFRESH_SECONDS := .25
# The tools dragged over an area, and how many planned pieces are drawn as models (the tinted footprints always show the
# whole plan): a mansion model has tens of thousands of vertices, a wall piece a few hundred.
const AREA_TOOLS := ["house", "elite_house", "park", "vine", "olive_tree", "orange_tree", "goat", "sheep", "cattle"]
# Dragged along a path as roads are.
const PATH_TOOLS := ["doric_column", "ionic_column", "corinthian_column", "avenue", "boulevard"]
const COLUMN_TOOLS := ["doric_column", "ionic_column", "corinthian_column"]
# Livestock are walkers: their plots show as footprints only.
const MODEL_LIMIT := {"wall": 400, "park": 120, "house": 24, "elite_house": 12, "vine": 160, "olive_tree": 160, "orange_tree": 160,
	"doric_column": 200, "ionic_column": 200, "corinthian_column": 200}

var active := false
var tool := "road"
var wall_fill := false
# True in play: a drag also ends when the real left button is no longer held. Tests that inject events turn it off.
var guard := true
var start := Vector2i(99999, 99999)
var last := Vector2i(99999, 99999)
var plan: Dictionary = {}
var key := ""
var age := 0.0
var markers: Array[MeshInstance3D] = []

func begin(city, cell: Vector2i, tool_name := "road") -> void:
	active = true
	tool = tool_name
	start = cell
	last = cell
	plan = {}
	key = ""
	age = REFRESH_SECONDS
	update(city, cell)

# Called every frame while dragging with the tile under the cursor.
func update(city, cell: Vector2i, delta := 0.0) -> void:
	if not active:
		return
	age += delta
	last = cell
	var wanted := "%d,%d,%d" % [cell.x, cell.y, 1 if fill() else 0]
	if wanted == key and age < REFRESH_SECONDS:
		city.footprint_cells.visible = true
		return
	key = wanted
	age = 0.0
	plan = city.core.query(preview_text(start, cell))
	show(city)

# Shift fills the whole rectangle of a wall drag.
func fill() -> bool:
	return tool == "wall" and (wall_fill or Input.is_key_pressed(KEY_SHIFT))

func preview_text(from: Vector2i, to: Vector2i) -> String:
	if tool == "wall":
		return "preview_wall %d %d %d %d %d" % [from.x, from.y, to.x, to.y, 1 if fill() else 0]
	if tool in AREA_TOOLS:
		return "preview_area %s %d %d %d %d" % [tool, from.x, from.y, to.x, to.y]
	if tool in PATH_TOOLS:
		return "preview_path %s %d %d %d %d" % [tool, from.x, from.y, to.x, to.y]
	return "preview_road %d %d %d %d" % [from.x, from.y, to.x, to.y]

func show(city) -> void:
	clear(city)
	city.ghost.visible = false
	city.preview.visible = false
	if plan.is_empty() or plan.has("error"):
		city.hint.text = city.reason_text(plan.get("error", "out_of_map"))
		city.hud.set_placement_feedback(city.hint.text,false)
		return
	var pieces := 0
	var limit: int = MODEL_LIMIT.get(tool, 0)
	var area: bool = tool in AREA_TOOLS
	for cell in plan.tiles:
		var marker := MeshInstance3D.new()
		var good := bool(cell[3])
		if area:
			# One flat plate for the whole plot (building ground is level), above the ground like a footprint marker.
			var plate := BoxMesh.new()
			plate.size = Vector3(int(plan.w) - .08, .04, int(plan.h) - .08)
			marker.mesh = plate
			marker.position = city.world_position(int(cell[0]) + (int(plan.w) - 1) * .5, int(cell[1]) + (int(plan.h) - 1) * .5, cell[2]) + Vector3.UP * .05
		else:
			marker.mesh = city.terrain_geometry.footprint_mesh(Vector2i(int(cell[0]), int(cell[1])), float(cell[2]) * .22)
		var colour := Color(.94, .2, .18, .7)
		if good:
			# A road's (or path's) sixth value says whether the tile already is road; a wall's is its connection mask.
			var existing: bool = (tool == "road" or tool in PATH_TOOLS) and int(cell[5]) == 1
			colour = Color(.55, .72, .95, .5) if existing else Color(.16, .86, .48, .62)
			if pieces < limit and not existing and (area or tool == "wall" or tool in COLUMN_TOOLS):
				pieces += 1
				city.footprint_cells.add_child(area_piece(city, cell) if area else (wall_piece(city, cell) if tool == "wall" else column_piece(city, cell)))
		marker.material_override = city.material(colour, true)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		city.footprint_cells.add_child(marker)
		markers.append(marker)
	city.footprint_cells.visible = true
	city.hint.text = summary(city)
	city.hud.set_placement_feedback(city.hint.text,int(plan.new)>0)

# The model a planned plot of an area drag will become, as the placement ghost draws a building.
func area_piece(city, cell: Array) -> Node3D:
	var asset: String = plan.asset
	var width := int(plan.w)
	var depth := int(plan.h)
	var piece := Node3D.new()
	for part in city.static_batches.template(asset):
		var mesh := MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.material_override = part.material
		mesh.transform = part.transform
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.transparency = .35
		piece.add_child(mesh)
	var centre: Vector3 = city.world_position(int(cell[0]) + (width - 1) * .5, int(cell[1]) + (depth - 1) * .5, cell[2])
	var facing: int = city.StreetFacing.facing(city.tiles, asset, int(cell[0]), int(cell[1]), width, depth, city.orientation)
	piece.transform = Transform3D(city.model_basis(asset, width, depth, facing), centre + Vector3.UP * .02)
	return piece

# The model a planned wall tile will become: the piece for its connection mask, as the placement ghost draws a building.
func wall_piece(city, cell: Array) -> Node3D:
	var asset := "wall_%d" % int(cell[5])
	var piece := Node3D.new()
	for part in city.static_batches.template(asset):
		var mesh := MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.material_override = part.material
		mesh.transform = part.transform
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.transparency = .3
		piece.add_child(mesh)
	piece.transform = Transform3D(city.model_basis(asset, 1, 1, 0), city.world_position(int(cell[0]), int(cell[1]), cell[2]) + Vector3.UP * .02)
	return piece

# A column the path will raise, as the placement ghost draws a building.
func column_piece(city, cell: Array) -> Node3D:
	var asset: String = plan.get("asset", "")
	var piece := Node3D.new()
	for part in city.static_batches.template(asset):
		var mesh := MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.material_override = part.material
		mesh.transform = part.transform
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.transparency = .3
		piece.add_child(mesh)
	piece.transform = Transform3D(city.model_basis(asset, 1, 1, 0), city.world_position(int(cell[0]), int(cell[1]), cell[2]) + Vector3.UP * .02)
	return piece

func summary(city) -> String:
	if int(plan.new) == 0:
		return city.reason_text(plan.reason) if plan.reason != "" else ""
	var text: String = city.tr("Road: %d new tiles  •  Cost: %d") % [int(plan.new), int(plan.cost)]
	if tool == "wall":
		text = city.tr("Wall: %d pieces  •  Cost: %d") % [int(plan.new), int(plan.cost)]
	elif tool in AREA_TOOLS or tool in PATH_TOOLS:
		text = city.tr("%s: %d  •  Cost: %d") % [city.tr(BuildCatalog.NAMES.get(tool, tool)), int(plan.new), int(plan.cost)]
		if tool in PATH_TOOLS and int(plan.existing) > 0:
			text += "  •  " + city.tr("%d existing") % int(plan.existing)
	elif int(plan.existing) > 0:
		text += "  •  " + city.tr("%d existing") % int(plan.existing)
	if not plan.complete:
		text += "  •  " + city.reason_text(plan.reason)
	return text

# Removes every footprint marker, including those the ordinary single-tile preview left behind.
func clear(city) -> void:
	for child in city.footprint_cells.get_children():
		child.free()
	markers.clear()

func cancel(city) -> void:
	if active:
		active = false
		clear(city)
		plan = {}
		city.footprint_cells.visible = false

# Builds the dragged road (or a single tile for a click). Returns true when a command was sent.
func finish(city, cell: Vector2i) -> bool:
	if not active:
		return false
	active = false
	clear(city)
	city.footprint_cells.visible = false
	var end := cell if cell.x != 99999 else last
	var final: Dictionary = city.core.query(preview_text(start, end))
	var filled := fill()
	plan = {}
	if final.has("error") or not final.get("valid", false):
		city.hint.text = city.reason_text(final.get("reason", final.get("error", "native_placement_rejected")))
		return false
	if tool == "wall":
		return city.core.send("build_wall %d %d %d %d %d" % [start.x, start.y, end.x, end.y, 1 if filled else 0])
	if tool in AREA_TOOLS:
		return city.core.send("build_area %s %d %d %d %d %d" % [tool, start.x, start.y, end.x, end.y, city.orientation])
	if tool in PATH_TOOLS:
		return city.core.send("build_path %s %d %d %d %d" % [tool, start.x, start.y, end.x, end.y])
	if start == end:
		return city.core.send("build road %d %d %d" % [start.x, start.y, city.orientation])
	return city.core.send("build_road %d %d %d %d" % [start.x, start.y, end.x, end.y])
