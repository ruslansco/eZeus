extends Camera3D
# Cinematic floating camera with subtle mouse-parallax tracking for the login screen.

@export var float_speed := 0.22
@export var float_range_z := 0.6
@export var float_range_y := 0.24
@export var parallax_pos_scale := Vector2(0.85, 0.45)
@export var parallax_rot_scale := Vector2(0.035, 0.02)
@export var smooth_speed := 3.2

var origin_pos: Vector3
var origin_rot: Vector3
var target_mouse := Vector2.ZERO
var current_mouse := Vector2.ZERO

func _ready() -> void:
	origin_pos = position
	origin_rot = rotation

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp_size := get_viewport().get_visible_rect().size
		if vp_size.x > 0.0 and vp_size.y > 0.0:
			# Normalized coords from center (-1.0 to 1.0)
			var nx: float = (event.position.x / vp_size.x) * 2.0 - 1.0
			var ny: float = (event.position.y / vp_size.y) * 2.0 - 1.0
			target_mouse = Vector2(clamp(nx, -1.0, 1.0), clamp(ny, -1.0, 1.0))

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 * float_speed

	# Continuous smooth floating motion (sinusoidal breathing)
	var float_z := sin(t * 1.0) * float_range_z
	var float_y := sin(t * 1.4 + 0.5) * float_range_y
	var float_roll := sin(t * 0.7) * 0.006

	# Smooth mouse parallax damping
	current_mouse = current_mouse.lerp(target_mouse, clamp(delta * smooth_speed, 0.0, 1.0))

	# Compute target translation and rotation
	var offset_x := current_mouse.x * parallax_pos_scale.x
	var offset_y := -current_mouse.y * parallax_pos_scale.y

	position = origin_pos + Vector3(offset_x, float_y + offset_y, float_z)
	rotation = origin_rot + Vector3(
		-current_mouse.y * parallax_rot_scale.y,
		-current_mouse.x * parallax_rot_scale.x,
		float_roll
	)
