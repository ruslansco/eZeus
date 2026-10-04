extends RefCounted
# The navy's orders, as in the SDL view: a left click on one of the player's triremes (those the core marks `selectable`: at
# home, their wharf working) selects it, a gold ring shows which, and a right click on the water sends it there
# (`trireme_move`, the engine's eTrireme::sPlace). Escape, a click elsewhere or the trireme leaving the list lets it go.

const PICK_RADIUS := 1.6
var selected := -1
var ring: MeshInstance3D
# More triremes chosen together by a box (scripts/unit_selection.gd), each with its ring; `selected` is the first of them.
var group: Array = []
var rings: Array = []

# The selectable trireme nearest to the clicked tile, within reach of a click; -1 for none.
func trireme_at(city, cell: Vector2i) -> int:
	var best := -1
	var best_distance := PICK_RADIUS
	for id in city.walkers:
		var entry: Dictionary = city.walkers[id]
		if entry.asset != "trireme" or not entry.get("selectable", false):
			continue
		# The walker's position is in world space; the click is a tile.
		var distance: float = city.tile_coordinates(entry.native_position).distance_to(Vector2(cell.x, cell.y))
		if distance < best_distance:
			best_distance = distance
			best = int(id)
	return best

func select(city, id: int) -> void:
	clear()
	if id < 0 or not city.walkers.has(id):
		return
	selected = id
	group = [id]
	ring = make_ring(city, id)
	rings = [ring]

func select_many(city, ids: Array) -> void:
	clear()
	for id in ids:
		if city.walkers.has(int(id)):
			group.append(int(id))
			rings.append(make_ring(city, int(id)))
	selected = group[0] if not group.is_empty() else -1
	ring = rings[0] if not rings.is_empty() else null

func make_ring(city, id: int) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .9
	torus.outer_radius = 1.05
	ring.mesh = torus
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(.95, .76, .26)
	gold.emission_enabled = true
	gold.emission = Color(.95, .7, .2)
	gold.emission_energy_multiplier = .8
	gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = gold
	ring.position = Vector3(0, .05, 0)
	city.walkers[id].node.add_child(ring)
	return ring

func clear() -> void:
	selected = -1
	for each in rings:
		if each != null and is_instance_valid(each):
			each.queue_free()
	rings.clear()
	group.clear()
	ring = null

# Called after each snapshot: a trireme that left, or may no longer be ordered, is let go.
func refresh(city) -> void:
	var kept := group.filter(func(id): return city.walkers.has(id) and city.walkers[id].get("selectable", false))
	if kept.size() != group.size():
		if kept.is_empty():
			clear()
		else:
			select_many(city, kept)

func order(city, cell: Vector2i) -> bool:
	if group.is_empty():
		return false
	return city.core.send("trireme_move %d %d %s" % [cell.x, cell.y, " ".join(group.map(func(id): return str(id)))])
