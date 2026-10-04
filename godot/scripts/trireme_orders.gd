extends RefCounted
# The navy's orders, as in the SDL view: a left click on one of the player's triremes (those the core marks `selectable`: at
# home, their wharf working) selects it, a gold ring shows which, and a right click on the water sends it there
# (`trireme_move`, the engine's eTrireme::sPlace). Escape, a click elsewhere or the trireme leaving the list lets it go.

const PICK_RADIUS := 1.6
var selected := -1
var ring: MeshInstance3D

# The selectable trireme nearest to the clicked tile, within reach of a click; -1 for none.
func trireme_at(walkers: Dictionary, cell: Vector2i) -> int:
	var best := -1
	var best_distance := PICK_RADIUS
	for id in walkers:
		var entry: Dictionary = walkers[id]
		if entry.asset != "trireme" or not entry.get("selectable", false):
			continue
		var at: Vector3 = entry.native_position
		var distance := Vector2(at.x, at.z).distance_to(Vector2(cell.x, cell.y))
		if distance < best_distance:
			best_distance = distance
			best = int(id)
	return best

func select(city, id: int) -> void:
	clear()
	if id < 0 or not city.walkers.has(id):
		return
	selected = id
	ring = MeshInstance3D.new()
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

func clear() -> void:
	selected = -1
	if ring != null and is_instance_valid(ring):
		ring.queue_free()
	ring = null

# Called after each snapshot: a trireme that left, or may no longer be ordered, is let go.
func refresh(city) -> void:
	if selected >= 0 and (not city.walkers.has(selected) or not city.walkers[selected].get("selectable", false)):
		clear()

func order(city, cell: Vector2i) -> bool:
	if selected < 0:
		return false
	return city.core.send("trireme_move %d %d %d" % [cell.x, cell.y, selected])
