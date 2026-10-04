extends Node
const WalkerMotion = preload("res://scripts/walker_motion.gd")
# Single-citizen skeletal benchmark; C++ remains the only movement authority.
const MODEL := "res://assets/characters/physician_v2/physician.glb"
# Travelled distance of one walk cycle. Seek by cycle fraction so every LOD shares the
# native stride, including old imported clips with an exporter-added initial hold.
const STRIDE := 0.64
const IDLE_PERIOD := 3.0
var player: AnimationPlayer
var skeleton: Skeleton3D
var tree: AnimationTree
var faces: Array[MeshInstance3D] = []
var elapsed := 0.0
var travel := 0.0
var walk_weight := 0.0
var detail_elapsed := 0.0
var phase_offset := 0.0
var ready_to_sample := false
var walk_length := STRIDE
var motion := {"travel":0.0,"idle":0.0,"walk_weight":0.0,"still_time":WalkerMotion.GAP_HOLD}

func find_parts(node: Node) -> void:
	if node is AnimationPlayer:
		player = node
	if node is Skeleton3D:
		skeleton = node
	if node is MeshInstance3D and node.mesh != null and node.find_blend_shape_by_name("Blink_L") >= 0:
		faces.append(node)
	for child in node.get_children():
		find_parts(child)

func _ready() -> void:
	find_parts(get_parent())
	if player == null or not player.has_animation("Idle") or not player.has_animation("Walk"):
		push_error("Skeletal citizen is missing Idle/Walk clips")
		return
	player.stop()
	walk_length = player.get_animation("Walk").length
	for clip in ["Idle", "Walk"]:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	tree = AnimationTree.new()
	tree.name = "CitizenAnimationTree"
	add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var blend := AnimationNodeBlendTree.new()
	for clip in ["Idle", "Walk"]:
		var anim := AnimationNodeAnimation.new()
		anim.animation = clip
		blend.add_node(clip, anim)
		blend.add_node(clip + "Seek", AnimationNodeTimeSeek.new())
		blend.connect_node(clip + "Seek", 0, clip)
	blend.add_node("Locomotion", AnimationNodeBlend2.new())
	blend.connect_node("Locomotion", 0, "IdleSeek")
	blend.connect_node("Locomotion", 1, "WalkSeek")
	blend.connect_node("output", 0, "Locomotion")
	tree.tree_root = blend
	tree.active = true
	ready_to_sample = true
	sample(0.0, 0.0, 0.0)

# Clip time of the walk pose after the given travelled distance; one stride is one full loop.
func walk_time(distance: float) -> float:
	return fposmod(distance / STRIDE, 1.0) * walk_length

func sample(dt: float, moved: float, camera_distance := 0.0, gait_weight := -1.0) -> void:
	if not ready_to_sample:
		return
	elapsed += dt
	travel += moved
	if gait_weight >= 0.0:
		walk_weight = gait_weight
	else:
		motion.walk_weight = walk_weight
		WalkerMotion.advance(motion, dt, moved)
		walk_weight = motion.walk_weight
	detail_elapsed += dt
	# Keep travel exact but reduce skeleton evaluation for distant crowds.
	var interval := 0.0 if camera_distance < 14.0 else (1.0/20.0 if camera_distance < 35.0 else 1.0/10.0)
	if interval > 0 and detail_elapsed < interval:
		return
	detail_elapsed = 0.0
	tree.set("parameters/IdleSeek/seek_request", fposmod(elapsed + phase_offset, IDLE_PERIOD))
	tree.set("parameters/WalkSeek/seek_request", walk_time(travel))
	tree.set("parameters/Locomotion/blend_amount", walk_weight)
	# Absolute seeks: don't let the animation clock change the traveled distance.
	tree.advance(0.0)
	var blink := 0.0
	if camera_distance < 14.0:
		var phase := fposmod(elapsed + phase_offset, 4.7)
		if phase > 3.9 and phase < 4.12:
			blink = sin((phase-3.9)/.22*PI)
	for face in faces:
		face.set_blend_shape_value(face.find_blend_shape_by_name("Blink_L"), blink)
		face.set_blend_shape_value(face.find_blend_shape_by_name("Blink_R"), blink)
