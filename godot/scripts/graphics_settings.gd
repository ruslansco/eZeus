extends RefCounted
# Presentation only. The root viewport changes; UI and portrait viewports retain
# their own resolution. Native map/crowd/rules and authored mesh sources stay intact.
const Settings = preload("res://scripts/user_settings.gd")
const Keys = preload("res://scripts/key_bindings.gd")
const DEFAULT := "balanced"
const ORDER := ["balanced", "high"]
const PRESETS := {
	"balanced": {"scale": 1.0, "lod": 3.0, "msaa": Viewport.MSAA_4X, "shadows": true, "shadow_distance": 70.0, "detail_range": 1.0},
	"high": {"scale": 1.0, "lod": 1.5, "msaa": Viewport.MSAA_4X, "shadows": true, "shadow_distance": 100.0, "detail_range": 1.25},
}
static var current := DEFAULT

static func sanitize(value: Variant) -> String:
	return value if value is String and value in PRESETS else DEFAULT

static func load_preference() -> String:
	return sanitize(Settings.get_value("graphics", "preset", DEFAULT)) if Keys.uses_player_settings() else DEFAULT

static func apply(tree: SceneTree, value: Variant) -> void:
	current = sanitize(value)
	var preset: Dictionary = PRESETS[current]
	tree.root.scaling_3d_scale = preset.scale
	tree.root.mesh_lod_threshold = preset.lod
	tree.root.msaa_3d = preset.msaa
	# Two cascades remain the performance contract even at High.
	for city in tree.get_nodes_in_group("ezeus_graphics_city"):
		city.graphics_sun.shadow_enabled = preset.shadows
		city.graphics_sun.directional_shadow_max_distance = preset.shadow_distance
		city.terrain_details.set_detail_range(preset.detail_range)

static func startup(tree: SceneTree) -> void:
	apply(tree, load_preference())

static func commit(value: Variant) -> Error:
	if not Keys.uses_player_settings(): return OK
	var file := ConfigFile.new()
	file.load(Settings.path())
	file.set_value("graphics", "preset", sanitize(value))
	return file.save(Settings.path())
