extends Node3D
# A wolf's bite (6 October). The engine fights a wolf with whoever it attacks (a townsperson, a shepherd, a sheep or goat): both get
# the native fight action, and the wolf plays its authored lunging bites (gathering_motion.gd, "animalattack"). Its opponent is the
# nearest other walker that is fighting next to it (the engine does not publish fight pairs; both sides of one fight stand within
# a tile). At each snap of the jaws (the clip's two bite peaks) dust is kicked up where they grapple, wool or hair tears loose from
# an animal victim, and the victim flinches away from the wolf for a moment. The wolf's attack and hit sounds are the engine's own. Purely presentation: damage,
# targets and timing stay the engine's; a paused city pauses the clip, so no new bites come.

const MAX_PUFFS := 96
const REACH := 1.6                    # tiles between a wolf and the walker it fights
const BITES := [.125, .625]           # the lunge clip's two snaps (art/characters/animals/species.py, _wolf lunge)
const FLINCH_SECONDS := .28

var puffs: Array = []                 # {position, velocity, age, life, size, colour}
var tufts: MultiMesh
var bites := 0                        # bites shown so far (validators)

func _init() -> void:
	name = "WolfAttacks"
	# Soft round sprites facing the camera (a radial fade), so dust reads as dust and hair as loose tufts.
	var soft := Gradient.new()
	soft.set_color(0, Color(1, 1, 1, 1))
	soft.set_color(1, Color(1, 1, 1, 0))
	soft.add_point(.45, Color(1, 1, 1, .75))
	var fade := GradientTexture2D.new()
	fade.gradient = soft
	fade.fill = GradientTexture2D.FILL_RADIAL
	fade.fill_from = Vector2(.5, .5)
	fade.fill_to = Vector2(1, .5)
	fade.width = 64
	fade.height = 64
	var blob := QuadMesh.new()
	var finish := StandardMaterial3D.new()
	finish.albedo_texture = fade
	finish.vertex_color_use_as_albedo = true
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	finish.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	finish.billboard_keep_scale = true
	finish.disable_receive_shadows = true
	blob.material = finish
	tufts = MultiMesh.new()
	tufts.transform_format = MultiMesh.TRANSFORM_3D
	tufts.use_colors = true
	tufts.mesh = blob
	tufts.instance_count = MAX_PUFFS
	tufts.visible_instance_count = 0
	tufts.custom_aabb = AABB(Vector3(-400, -40, -400), Vector3(800, 120, 800))
	var node := MultiMeshInstance3D.new()
	node.name = "Tufts"
	node.multimesh = tufts
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

static func fighting(entry: Dictionary) -> bool:
	return int(entry.get("action", 1)) in [4, 5]

# The walker a fighting wolf is biting, or {}.
static func victim(wolf: Dictionary, walkers: Dictionary) -> Dictionary:
	var best := {}
	var nearest := REACH
	for other in walkers.values():
		if other == wolf or other.asset == "animal_wolf" or not fighting(other):
			continue
		var gap: float = Vector2(other.native_position.x - wolf.native_position.x, other.native_position.z - wolf.native_position.z).length()
		if gap < nearest:
			nearest = gap
			best = other
	return best

static func crossed(before: float, after: float, mark: float) -> bool:
	if after >= before:
		return before < mark and mark <= after
	return mark > before or mark <= after       # the phase wrapped round

func update(city, dt: float) -> void:
	for wolf in city.walkers.values():
		if wolf.asset != "animal_wolf":
			continue
		var biting: bool = fighting(wolf) and str(wolf.get("gather_clip", "")) == "animalattack" and float(wolf.get("gather_weight", 0.0)) > .5
		var phase := float(wolf.get("gather_phase", 0.0))
		var before := float(wolf.get("bite_phase", phase))
		wolf.bite_phase = phase
		if not biting:
			continue
		for mark in BITES:
			if crossed(before, phase, mark):
				var prey := victim(wolf, city.walkers)
				if not prey.is_empty():
					bite(wolf, prey)
	for entry in city.walkers.values():
		var flinch := float(entry.get("flinch", 0.0))
		if flinch <= 0.0:
			continue
		# Recoil away from the jaws and settle back (positions are set afresh every frame, so nothing accumulates).
		var k := sin(flinch / FLINCH_SECONDS * PI)
		entry.node.position += entry.flinch_away * .12 * k + Vector3.UP * .03 * k
		entry.flinch = maxf(0.0, flinch - dt)
	advance(dt)

func bite(wolf: Dictionary, prey: Dictionary) -> void:
	bites += 1
	var away: Vector3 = prey.native_position - wolf.native_position
	away.y = 0
	away = away.normalized() if away.length() > .001 else Vector3.FORWARD
	prey.flinch = FLINCH_SECONDS
	prey.flinch_away = away
	var animal: bool = str(prey.asset).begins_with("animal_")
	var body: Vector3 = prey.node.global_position + Vector3.UP * (.30 if animal else .45) - away * .10
	if animal:
		# A sheep's wool or a goat's hair torn loose.
		var fur := Color(.80, .78, .72) if str(prey.asset).begins_with("animal_sheep") else Color(.34, .22, .13)
		for i in 12:
			var spray := Vector3(randf_range(-.7, .7), randf_range(.6, 1.5), randf_range(-.7, .7)) + away * .8
			spawn(body, spray * .6, .7, randf_range(.04, .07), fur.lerp(Color(.55, .50, .44), randf() * .3))
	# Dust kicked up where they grapple, for a person or an animal.
	var feet: Vector3 = prey.node.global_position.lerp(wolf.node.global_position, .4) + Vector3.UP * .06
	for i in 6:
		spawn(feet, Vector3(randf_range(-.45, .45), randf_range(.15, .4), randf_range(-.45, .45)), .9, randf_range(.12, .2), Color(.50, .43, .32, .55))
	# A jolt where the jaws close: a few bright flecks of dust and torn cloth or hair.
	for i in 5:
		spawn(body, (Vector3(randf_range(-.5, .5), randf_range(.3, .9), randf_range(-.5, .5)) + away) * .7, .45, randf_range(.025, .04), Color(.62, .56, .46, .8) if not animal else Color(.58, .53, .46, .8))

func spawn(at: Vector3, velocity: Vector3, life: float, size: float, colour: Color) -> void:
	if puffs.size() >= MAX_PUFFS:
		puffs.pop_front()
	puffs.append({"position": at, "velocity": velocity, "age": 0.0, "life": life, "size": size, "colour": colour})

func advance(dt: float) -> void:
	var kept: Array = []
	for puff in puffs:
		puff.age += dt
		if puff.age >= puff.life:
			continue
		puff.velocity += Vector3.DOWN * .9 * dt
		puff.velocity *= 1.0 - 2.2 * dt
		puff.position += puff.velocity * dt
		kept.append(puff)
	puffs = kept
	tufts.visible_instance_count = puffs.size()
	for i in puffs.size():
		var puff: Dictionary = puffs[i]
		var t: float = puff.age / puff.life
		var size: float = puff.size * (1.0 + t)
		tufts.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(size, size, size)), puff.position))
		var colour: Color = puff.colour
		colour.a *= 1.0 - t * t
		tufts.set_instance_color(i, colour)
