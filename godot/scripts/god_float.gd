extends RefCounted
# The gods float. A god never walks: it hovers a little above the ground, bobs slowly, leans into its direction of travel
# and turns slowly, and its model holds one pose (the held idle) instead of cycling steps. Presentation only: the core's
# positions, routes, clocks and random numbers are not touched, and a god keeps its fight, bless, curse, appear and
# disappear clips (walker_combat.gd), which now play at the same hover height.
# main.gd calls update() from animate_walker() after it has put the node on the surface, and heading() instead of the
# citizens' quick turn; nothing is stored between frames except small numbers in the walker's entry (fl_*).

const GODS := ["aphrodite", "apollo", "ares", "artemis", "athena", "atlas", "demeter", "dionysus", "hades", "hephaestus", "hera", "hermes", "poseidon", "zeus"]
# Heights in tiles; a god is about three and a half tall.
const HOVER := .12                       # standing still (the pose itself lifts the feet a little more)
const HOVER_MOVING := .20                # gliding at full speed
const BOB := .03                         # added up and down
const BOB_HZ := .42
const LEAN := deg_to_rad(8.0)            # forward lean at full speed, about the waist
const PIVOT := 1.7                       # the waist, so the lean does not swing the feet or the head off the spot
const ROLL := deg_to_rad(1.3)            # slow sway side to side
const ROLL_HZ := .27
const SPEED_FULL := .8                   # tiles per second that count as full speed
const SPEED_EASE := 4.0                  # how fast the measured speed settles, per second
const GLIDE_EASE := 2.4                  # and how fast hover and lean follow it: a second smoothing, so a start has no jerk
const TURN_RATE := 2.6                   # citizens turn at 12: a god sweeps round

static func is_god(asset: String) -> bool:
	return asset.begins_with("walker_") and asset.trim_prefix("walker_") in GODS

# The yaw towards a movement, eased slowly; the same short way round as the citizens' turn.
static func heading(current: float, direction: Vector3, dt: float) -> float:
	if Vector2(direction.x, direction.z).length() <= .0000001:
		return current
	return lerp_angle(current, atan2(-direction.x, -direction.z), 1.0 - exp(-TURN_RATE * dt))

# Hover, lean and sway for this frame. `moved` is the planar distance the god covered this frame; the node must already stand
# on the surface (its position is raised, never accumulated).
static func update(entry: Dictionary, dt: float, moved: float) -> void:
	var node: Node3D = entry.node
	if not entry.has("fl_time"):
		# Each god starts at its own point of the bob, so two gods never move in step.
		entry.fl_time = float(node.get_instance_id() % 997) * .01
		entry.fl_speed = 0.0
	entry.fl_time += dt
	var speed: float = moved / maxf(dt, .0001)
	entry.fl_speed = lerpf(entry.fl_speed, speed, 1.0 - exp(-SPEED_EASE * dt))
	var target := clampf(entry.fl_speed / SPEED_FULL, 0.0, 1.0)
	var glide := lerpf(float(entry.get("fl_glide", 0.0)), target, 1.0 - exp(-GLIDE_EASE * dt))
	entry.fl_glide = glide
	var hover := lerpf(HOVER, HOVER_MOVING, glide) + BOB * sin(TAU * BOB_HZ * entry.fl_time)
	var lean := LEAN * glide
	var roll := ROLL * sin(TAU * ROLL_HZ * entry.fl_time) * (.35 + .65 * glide)
	node.rotation.x = -lean
	node.rotation.z = roll
	# Lean and sway about the waist: the head goes forward as much as the feet go back, and the waist stays over the spot.
	var tilt := Basis.from_euler(Vector3(-lean, 0.0, roll), EULER_ORDER_YXZ)
	var waist := Vector3(0.0, PIVOT, 0.0)
	node.position += Vector3.UP * hover + Basis(Vector3.UP, node.rotation.y) * (waist - tilt * waist)
	entry.fl_hover = hover
