extends RefCounted
# Presentation only: distance comes from the interpolated native route, never from a gait.
const STRIDE := .64
const GAP_HOLD := .08
const START_TIME := .055
const STOP_TIME := .09
const TURN_RATE := 12.0

static func advance(entry: Dictionary, dt: float, moved: float) -> void:
	entry.travel += moved
	entry.idle += dt
	var old_still: float = entry.get("still_time", GAP_HOLD)
	var walking := moved > maxf(.0000001, dt * .002)
	entry.still_time = 0.0 if walking else old_still + dt
	entry.moving = walking or entry.still_time < GAP_HOLD
	var weight: float = entry.get("walk_weight", 0.0)
	if walking:
		weight = 1.0 - (1.0 - weight) * exp(-dt / START_TIME)
	else:
		# Integrate only the part of this frame after the short snapshot-gap grace period.
		var fade_dt := maxf(0, entry.still_time - GAP_HOLD) - maxf(0, old_still - GAP_HOLD)
		weight *= exp(-fade_dt / STOP_TIME)
	entry.walk_weight = 1.0 if weight > .9995 else (0.0 if weight < .0005 else weight)

static func planar_distance(delta: Vector3) -> float:
	# Terrain-height corrections and bridge deck changes must not manufacture footsteps.
	return Vector2(delta.x, delta.z).length()

static func heading(current: float, direction: Vector3, dt: float) -> float:
	if planar_distance(direction) <= .0000001:
		return current
	return lerp_angle(current, atan2(-direction.x, -direction.z), 1.0 - exp(-TURN_RATE * dt))
