extends RefCounted
# Variety within a job (5 October): every townsperson gets a stable per-walker value for character.gdshader's
# citizen_variant, which shifts tunic shade and hue, hair colour and skin tone a little, so two water carriers side by side
# are not clones while each job keeps its colour code. Gods, heroes, monsters, soldiers and the priestess keep their
# authored look (uniforms and identities); the value comes from the core's walker id, so a walker keeps its look while it lives.
const TOWNSPEOPLE := ["transporter", "physician", "settlers1", "walker_waterdistributor", "walker_peddler", "walker_watchman",
	"walker_taxcollector", "walker_firefighter", "walker_trader", "walker_porter", "walker_actor", "walker_competitor",
	"walker_gymnast", "walker_scholar", "walker_astronomer", "walker_inventor", "walker_curator", "walker_homeless",
	"walker_disgruntled", "walker_elitecitizen", "walker_sick", "walker_lumberjack", "walker_bronzeminer", "walker_silverminer",
	"walker_orichalcminer", "walker_marbleminer", "walker_artisan", "walker_oxhandler", "walker_grower", "walker_shepherd",
	"walker_goatherd", "walker_hunter", "walker_deerhunter", "walker_orangetender", "walker_rancher", "walker_urchin"]

# Face variants (other people in the same job, exported as <asset>_v2 / _v3 by export_godot_pilot.py): the commonest
# walkers. The walker keeps its base asset name everywhere else (cargo beds, work clips, contracts); only its model differs.
const FACES := {"transporter": 3, "walker_waterdistributor": 3, "walker_peddler": 3}

static func model_name(asset: String, id: int) -> String:
	var count: int = FACES.get(asset, 1)
	var pick := posmod(hash(id * 7919 + 13), count)
	if pick == 0:
		return asset
	var variant := "%s_v%d" % [asset, pick + 1]
	return variant if ResourceLoader.exists("res://assets/models/%s.glb" % variant) else asset

static func value(id: int) -> float:
	# A stable value in (0, 1]: 0 is reserved for "authored look".
	return float(posmod(hash(id) , 997) + 1) / 997.0

static func apply(node: Node, asset: String, id: int) -> void:
	if asset not in TOWNSPEOPLE:
		return
	set_variant(node, value(id))

static func set_variant(node: Node, variant: float) -> void:
	if node is GeometryInstance3D:
		node.set_instance_shader_parameter("citizen_variant", variant)
	for child in node.get_children():
		set_variant(child, variant)
