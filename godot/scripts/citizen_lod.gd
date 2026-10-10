extends RefCounted
# Realistic citizens near the camera, baked crowd poses for everyone else.
#
# A skeletal citizen costs about 0.6 MB of video memory and 20 us of CPU per frame, so a city
# cannot afford one per walker. Every walker of a role listed in ROLES is shown by its crowd
# model (low-poly, colours baked from the textures, poses baked into a texture and driven by
# the walker's travelled distance). The nearest few that come within NEAR of the camera swap
# to a pooled skeletal citizen, which takes over the crowd model's exact phase, so the switch
# neither restarts the gait nor snaps a start/stop blend. Movement stays C++ authoritative: only the
# presentation changes.

const SkeletalCitizen = preload("res://scripts/skeletal_citizen.gd")
# Native asset name -> crowd model asset. Roles not listed here are unaffected.
const ROLES := {"physician": "physician_crowd"}
const MAX_SKELETAL := 24
const NEAR := 9.0
const FAR := 11.5
const PREWARM := 6
const CHECK_FRAMES := 6

var requested := false
var pool: Array = []
var active: Dictionary = {}
var changes := 0

# The model that stands in for a native asset in the crowd, or "" when the role is unchanged.
func crowd_asset(asset: String) -> String:
	if not ROLES.has(asset):
		return ""
	var crowd: String = ROLES[asset]
	return crowd if ResourceLoader.exists("res://assets/models/%s.glb" % crowd) and ResourceLoader.exists(SkeletalCitizen.MODEL) else ""

# Starts loading the skeletal model on a worker thread so the first swap does not hitch.
func prefetch(batches) -> void:
	if not requested and ResourceLoader.exists(SkeletalCitizen.MODEL):
		requested = true
		batches.prefetch_paths([SkeletalCitizen.MODEL])

func instantiate_skeletal(batches, models: Dictionary) -> Node3D:
	if not models.has("skeletal_citizen"):
		models["skeletal_citizen"] = batches.load_model(SkeletalCitizen.MODEL)
	var citizen: Node3D = models["skeletal_citizen"].instantiate()
	var controller := SkeletalCitizen.new()
	controller.name = "SkeletalCitizen"
	citizen.add_child(controller)
	citizen.set_meta("skeletal_citizen", controller)
	return citizen

# Called every few frames with the camera position; assigns the skeletal pool to the nearest
# eligible walkers and releases those that moved away (with hysteresis).
func update(walkers: Dictionary, camera_position: Vector3, batches, models: Dictionary) -> void:
	var near: Array = []
	var any_role := false
	for id in walkers:
		var entry: Dictionary = walkers[id]
		if not entry.get("lod_role", false):
			continue
		any_role = true
		var distance := camera_position.distance_to(entry.node.global_position)
		if distance < (FAR if entry.skeletal != null else NEAR):
			near.append([distance, id])
	if not any_role:
		return
	near.sort()
	var wanted := {}
	for item in near.slice(0, MAX_SKELETAL):
		wanted[item[1]] = true
	for id in active.keys():
		if not wanted.has(id) or not walkers.has(id):
			if walkers.has(id):
				release(walkers[id])
			else:
				active.erase(id)
	for id in wanted:
		if not active.has(id):
			acquire(walkers[id], id, batches, models)
	# Prepare spares only while this detail is in use. A new physician far below a
	# zoomed-out camera must not load/instantiate six unused skeletons during play.
	if not near.is_empty() and pool.size() + active.size() < PREWARM and batches.warmed(SkeletalCitizen.MODEL):
		pool.append(instantiate_skeletal(batches, models))

func acquire(entry: Dictionary, id: int, batches, models: Dictionary) -> void:
	var citizen: Node3D = pool.pop_back() if not pool.is_empty() else instantiate_skeletal(batches, models)
	var controller: Node = citizen.get_meta("skeletal_citizen")
	# Continue exactly where the crowd model is: same walk phase and idle clock.
	controller.travel = entry.travel
	controller.elapsed = entry.idle
	controller.phase_offset = 0.0
	controller.walk_weight = entry.get("walk_weight", 1.0 if entry.get("moving", false) else 0.0)
	controller.detail_elapsed = 1.0
	entry.node.add_child(citizen)
	citizen.position = Vector3.ZERO
	citizen.rotation = Vector3.ZERO
	for part in entry.morphs:
		part.node.visible = false
	entry.skeletal = citizen
	active[id] = entry
	changes += 1

func release(entry: Dictionary) -> void:
	var citizen: Node3D = entry.skeletal
	if citizen == null:
		return
	entry.node.remove_child(citizen)
	pool.append(citizen)
	for part in entry.morphs:
		part.node.visible = true
	entry.skeletal = null
	for id in active.keys():
		if active[id] == entry:
			active.erase(id)
	changes += 1

# Walkers that disappear must hand their skeletal model back before the node is freed.
func drop(entry: Dictionary) -> void:
	if entry.get("skeletal") != null:
		release(entry)
