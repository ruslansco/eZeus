extends RefCounted
# The fight, fight2, die, bless, curse, disappear and appear clips of soldier, hero and god models. The core says what each walker is
# doing (`action`: 4 fight, 5 fight2, 6 die, 15 appear, 16 disappear, 17 bless, 18 curse); a model whose baked poses include
# <clip>_NN frames (tools/export_godot_pilot.py, COMBAT) plays that clip instead of walking or standing. Fighting walkers face the
# direction the core gives them. Fight, bless and curse loop; die and disappear play once and hold their last frame (the core removes the
# corpse or the god); appear is the model's own clip or, failing that, its disappear clip backwards. Models without clips keep their
# normal animation.

const FIGHT_FPS := 10.0
const DIE_SECONDS := 1.0
const TURN_RATE := 12.0
const ACTIONS := {4: "fight", 5: "fight2", 6: "die", 15: "appear", 16: "disappear", 17: "bless", 18: "curse"}
const LABELS := ["fight", "fight2", "die", "bless", "curse", "disappear", "appear"]
const ONCE := ["die", "disappear", "appear"]

# The frame names of each clip a model has, read from its first part's pose table.
static func clips(morphs: Array) -> Dictionary:
	var result := {}
	if morphs.is_empty():
		return result
	var table: Dictionary = morphs[0].table
	for label in LABELS:
		var names: Array = []
		while table.has("%s_%02d" % [label, names.size()]):
			names.append("%s_%02d" % [label, names.size()])
		if not names.is_empty():
			result[label] = names
	return result

# The clip to play for the walker's current action, or "" for the normal walk and stand animation.
static func clip_for(entry: Dictionary) -> String:
	var available: Dictionary = entry.get("clips", {})
	if available.is_empty():
		return ""
	var wanted: String = ACTIONS.get(int(entry.get("action", 1)), "")
	if wanted == "":
		return ""
	if available.has(wanted):
		return wanted
	if wanted == "fight2" and available.has("fight"):
		return "fight"
	# A god without an appear clip comes back by playing its disappearance backwards.
	if wanted == "appear" and available.has("disappear"):
		return "appear"
	return ""

static func fighting(entry: Dictionary) -> bool:
	return clip_for(entry) in ["fight", "fight2"]

# The yaw the core's orientation (eight directions, 45 degrees apart) means for a model.
static func facing_angle(orientation: int) -> float:
	return deg_to_rad(-180.0 + orientation * 45.0)

static func face(entry: Dictionary, dt: float) -> void:
	var node: Node3D = entry.node
	node.rotation.y = lerp_angle(node.rotation.y, facing_angle(int(entry.get("facing", 0))), 1.0 - exp(-TURN_RATE * dt))

# Applies the clip's pose for this frame; false when the walker is not in a clip (the caller animates it as usual).
static func animate(entry: Dictionary, dt: float) -> bool:
	var clip := clip_for(entry)
	if clip == "":
		if str(entry.get("clip", "")) != "":
			# Leaving a clip: the normal animation sets its own blend again.
			entry.clip = ""
			for morph in entry.morphs:
				morph.erase("blend")
		return false
	if str(entry.get("clip", "")) != clip:
		entry.clip = clip
		entry.clip_time = 0.0
	entry.clip_time = float(entry.clip_time) + dt
	var reverse: bool = clip == "appear" and not entry.clips.has("appear")
	var names: Array = entry.clips["disappear" if reverse else clip]
	var count := names.size()
	var position: float
	var first: int
	var second: int
	if clip in ONCE:
		var seconds: float = DIE_SECONDS if clip == "die" else maxf(1.2, count / 12.0)
		position = minf(float(entry.clip_time) / seconds, 1.0) * (count - 1)
		if reverse:
			position = (count - 1) - position
		first = clampi(int(floorf(position)), 0, count - 1)
		second = mini(first + 1, count - 1)
	else:
		position = fposmod(float(entry.clip_time) * FIGHT_FPS, count)
		first = int(floorf(position))
		second = (first + 1) % count
	var blend := position - floorf(position)
	for morph in entry.morphs:
		var table: Dictionary = morph.table
		var a := int(table.get(names[first], -1))
		var b := int(table.get(names[second], -1))
		var node: MeshInstance3D = morph.node
		if morph.has("vat"):
			node.set_instance_shader_parameter("vat_pose", Vector3(a, b, blend))
			if morph.get("blend", -1.0) != 1.0:
				node.set_instance_shader_parameter("vat_walk_blend", 1.0)
				morph.blend = 1.0
		else:
			for index in morph.lit:
				node.set_blend_shape_value(index, 0.0)
			morph.lit.clear()
			var weights := {}
			for item in [[a, 1.0 - blend], [b, blend]]:
				if item[0] >= 0 and item[1] > 0:
					weights[item[0]] = weights.get(item[0], 0.0) + item[1]
			for index in weights:
				node.set_blend_shape_value(index, weights[index])
				morph.lit.append(index)
	return true
