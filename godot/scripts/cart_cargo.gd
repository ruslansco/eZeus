extends RefCounted
# The load on a cart. The core sends a cart's good and its loads ("cargo" / "cargo_count" on the walker, only while it
# carries something); the same stacked-goods models that fill storage bays (good_<name>.glb) are fitted into the bed and
# grow with the loads (a cart takes up to four, a sculpture one). An ox cart's load (marble, black marble, timber,
# sculptures) rides its trailer, so the core sends it on the trailer walker. Each bed is measured from its GLB (Godot
# axes: the cart trails its handler toward -z, the trailer's tongue points toward -z).

# Where the load sits, by walker asset: the middle of the bed's floor and the room above it.
const BEDS := {
	# The transporter's deep plank box (5 October): planks top at .30, flared sides up to .50, .41 wide and .62 long inside.
	"transporter": {"floor": Vector3(0.0, 0.33, -0.72), "size": Vector3(0.40, 0.26, 0.56)},
	"trailer": {"floor": Vector3(0.0, 0.43, 0.09), "size": Vector3(0.56, 0.30, 0.42)},
}
const NODE_NAME := "Cargo"

# Fitted loads by bed and good: {"scale": uniform scale that fills the bed, "offset": where the model's centre-bottom sits}.
static var fits := {}

# Draws (or clears, or updates) the load on a cart walker entry from the core's walker record; `main` supplies the models.
static func update(main: Node, entry: Dictionary, walker: Dictionary) -> void:
	var key := ""
	if walker.has("cargo"):
		key = "%s:%d" % [walker.cargo, clampi(int(walker.get("cargo_count", 1)), 1, 4)]
	if str(entry.get("cargo_key", "")) == key:
		return
	entry.cargo_key = key
	var cart: Node3D = entry.node
	var old := cart.get_node_or_null(NODE_NAME)
	if old != null:
		cart.remove_child(old)
		old.queue_free()
	if key.is_empty():
		return
	var load := build(main, str(entry.asset), str(walker.cargo), int(walker.get("cargo_count", 1)))
	if load != null:
		cart.add_child(load)

# A load of `count` loads (1-4) of one good, sitting in the bed of the `bed` model; null when the good has no model.
static func build(main: Node, bed: String, good: String, count: int) -> Node3D:
	var asset := "good_" + good
	if not BEDS.has(bed) or not main.model_file_exists(asset):
		return null
	var model: Node3D = main.model(asset)
	if model == null:
		return null
	var fit := fit_of(bed, good, model)
	var fill := 0.45 + 0.55 * float(clampi(count, 1, 4) - 1) / 3.0
	var holder := Node3D.new()
	holder.name = NODE_NAME
	holder.position = BEDS[bed].floor
	model.scale = Vector3.ONE * float(fit.scale) * fill
	model.position = Vector3(fit.offset) * float(fit.scale) * fill
	holder.add_child(model)
	return holder

# The scale that makes a good's model fill the bed's footprint (and no more than its height), and the offset that puts its
# footprint centre on the bed's middle and its lowest point on the floor. Measured once per bed and good.
static func fit_of(bed: String, good: String, model: Node3D) -> Dictionary:
	var key := bed + ":" + good
	if not fits.has(key):
		var size: Vector3 = BEDS[bed].size
		var bounds := bounds_of(model, Transform3D.IDENTITY)
		if bounds.size.x <= 0.0001 or bounds.size.z <= 0.0001:
			fits[key] = {"scale": 1.0, "offset": Vector3.ZERO}
		else:
			var scale := minf(size.x / bounds.size.x, minf(size.z / bounds.size.z, size.y / maxf(bounds.size.y, 0.0001)))
			var centre := bounds.get_center()
			fits[key] = {"scale": scale, "offset": Vector3(-centre.x, -bounds.position.y, -centre.z)}
	return fits[key]

# The box around every mesh below `node`, in the space of the node the walk started from.
static func bounds_of(node: Node3D, to_root: Transform3D) -> AABB:
	var result := AABB()
	var found := false
	var here := to_root * node.transform if node.get_parent() != null else to_root
	if node is MeshInstance3D and node.mesh != null:
		result = here * node.mesh.get_aabb()
		found = true
	for child in node.get_children():
		if child is Node3D:
			var inner := bounds_of(child, here)
			if inner.size != Vector3.ZERO or inner.position != Vector3.ZERO:
				result = inner if not found else result.merge(inner)
				found = true
	return result
