extends OmniLight3D
# Dynamic light flicker for portal core and fire braziers:
# Casts living, pulsing light across the statues, steps, and columns.

@export var base_energy := 4.5
@export var flicker_intensity := 0.65
@export var speed := 5.0
@export var jitter_distance := 0.08

var initial_position: Vector3
var seed_offset: float = 0.0

func _ready() -> void:
	initial_position = position
	seed_offset = randf() * 100.0

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 * speed + seed_offset
	# Layered multi-frequency pseudo-random harmonics
	var wave := sin(t * 1.0) * 0.45 + sin(t * 2.37) * 0.3 + sin(t * 5.81) * 0.15 + sin(t * 11.23) * 0.1
	light_energy = max(0.2, base_energy + wave * flicker_intensity)
	
	if jitter_distance > 0.0:
		var jx := (sin(t * 3.1) + cos(t * 7.7)) * 0.5 * jitter_distance
		var jy := (cos(t * 2.4) + sin(t * 6.2)) * 0.5 * jitter_distance
		var jz := (sin(t * 4.3) + cos(t * 8.9)) * 0.5 * jitter_distance
		position = initial_position + Vector3(jx, jy, jz)
