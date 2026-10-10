extends Node3D

const Link = preload("res://scripts/core_link.gd")
const Batches = preload("res://scripts/building_batches.gd")
const Orbit = preload("res://scripts/orbit_camera.gd")
const BuildingInspector = preload("res://scripts/building_inspector.gd")
const TerrainPresentation = preload("res://scripts/terrain_presentation.gd")
const TerrainGeometry = preload("res://scripts/terrain_geometry.gd")
const TerrainDetails = preload("res://scripts/terrain_details.gd")
const TerrainForest = preload("res://scripts/terrain_forest.gd")
const TerrainAvenues = preload("res://scripts/terrain_avenues.gd")
const StreetSetback = preload("res://scripts/street_setback.gd")
const StreetFacing = preload("res://scripts/street_facing.gd")
const TerrainBridges = preload("res://scripts/terrain_bridges.gd")
const SkeletalCitizen = preload("res://scripts/skeletal_citizen.gd")
const CitizenLod = preload("res://scripts/citizen_lod.gd")
const CharacterAppearance = preload("res://scripts/character_appearance.gd")
const WalkerVat = preload("res://scripts/walker_vat.gd")
const WalkerMotion = preload("res://scripts/walker_motion.gd")
const WalkerCombat = preload("res://scripts/walker_combat.gd")
const WalkerStreets = preload("res://scripts/walker_streets.gd")
const DefencePerch = preload("res://scripts/defence_perch.gd")
const CartCargo = preload("res://scripts/cart_cargo.gd")
const AltarRite = preload("res://scripts/altar_rite.gd")
const GodFloat = preload("res://scripts/god_float.gd")
const Horizon = preload("res://scripts/horizon.gd")
const UiText = preload("res://scripts/ui_text.gd")
const LoadingScreen = preload("res://ui/loading_screen.gd")
const HudScene = preload("res://ui/hud.tscn")
const RoadDrag = preload("res://scripts/road_drag.gd")
# Buildings the core turns itself (a pier or fishery faces its water, a stadium its length, a roadblock across its street).
const CORE_FACING := ["pier", "gatehouse", "fishery", "urchin_quay", "trireme_wharf", "stadium", "roadblock", "hippodrome"]
const SHORE_TOOLS := ["pier", "fishery", "urchin_quay", "trireme_wharf"]
const WAREHOUSE_BAYS: Array[Vector3] = [
	Vector3(-1.0, 0.03,  0.0),
	Vector3(-1.0, 0.03, -1.0),
	Vector3( 0.0, 0.03,  1.0),
	Vector3( 0.0, 0.03,  0.0),
	Vector3( 0.0, 0.03, -1.0),
	Vector3( 1.0, 0.03,  1.0),
	Vector3( 1.0, 0.03,  0.0),
	Vector3( 1.0, 0.03, -1.0),
]
const TRADE_POST_BAYS: Array[Vector3] = [
	Vector3(-1.5, 0.03,  0.5),
	Vector3(-1.5, 0.03, -0.5),
	Vector3(-1.5, 0.03, -1.5),
	Vector3(-0.5, 0.03,  1.5),
	Vector3(-0.5, 0.03,  0.5),
	Vector3(-0.5, 0.03, -0.5),
	Vector3(-0.5, 0.03, -1.5),
	Vector3( 0.5, 0.03,  1.5),
	Vector3( 0.5, 0.03,  0.5),
	Vector3( 0.5, 0.03, -0.5),
	Vector3( 0.5, 0.03, -1.5),
	Vector3( 1.5, 0.03,  1.5),
	Vector3( 1.5, 0.03,  0.5),
	Vector3( 1.5, 0.03, -0.5),
	Vector3( 1.5, 0.03, -1.5),
]
const GRANARY_DRUM_CENTER := Vector3(-0.62, 1.40, 0.55)
const MessageLog = preload("res://scripts/message_log.gd")
const NotificationPolicy = preload("res://scripts/notification_policy.gd")
var pending_info_ack := {}
const BuildCatalog = preload("res://scripts/build_catalog.gd")
const BuildingPreview = preload("res://scripts/building_preview.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const KeyBindings = preload("res://scripts/key_bindings.gd")
const PlaySettings = preload("res://scripts/play_settings.gd")
const ControlsDialog = preload("res://ui/controls_dialog.gd")
const EscapeMenu = preload("res://ui/escape_menu.gd")
const GameSettingsDialog = preload("res://ui/game_settings_dialog.gd")
const SaveFiles = preload("res://scripts/save_files.gd")
const OverlayView = preload("res://scripts/overlay_view.gd")
const Overlays = preload("res://scripts/overlays.gd")
const SoundDialog = preload("res://ui/sound_dialog.gd")
const TradeDialog = preload("res://ui/trade_dialog.gd")
const EpisodeOverlayScene = preload("res://ui/episode_overlay.tscn")
const WorldMapScene = preload("res://ui/world_map.tscn")
const WorldFlight = preload("res://scripts/world_flight.gd")
const ArmyView = preload("res://scripts/army_view.gd")
const MythologyDialog = preload("res://ui/mythology_dialog.gd")
const CityDialog = preload("res://ui/city_dialog.gd")
const TriremeOrders = preload("res://scripts/trireme_orders.gd")
const CitySwitch = preload("res://ui/city_switch.gd")
const UnitSelection = preload("res://scripts/unit_selection.gd")
const RouteEditor = preload("res://scripts/route_editor.gd")
const EditorPanel = preload("res://ui/editor_panel.gd")
const HouseCard = preload("res://ui/house_card.gd")
const BuildingFires = preload("res://scripts/building_fires.gd")
const BuildingAuras = preload("res://scripts/building_auras.gd")
const DisasterEffects = preload("res://scripts/disaster_effects.gd")
const ThrownShots = preload("res://scripts/thrown_shots.gd")
const WolfAttacks = preload("res://scripts/wolf_attacks.gd")
const WaterLife = preload("res://scripts/water_life.gd")
const CitizenVariety = preload("res://scripts/citizen_variety.gd")
const MonsterEffects = preload("res://scripts/monster_effects.gd")
const Leaders = preload("res://scripts/leaders.gd")
const ArmyPanelScene = preload("res://ui/army_panel.tscn")
const InvasionBanner = preload("res://ui/invasion_banner.gd")
const MonsterCard = preload("res://ui/monster_card.gd")
const HazardRail = preload("res://ui/hazard_rail.gd")
const EnlistDialog = preload("res://ui/enlist_dialog.gd")
const CharacterPanel = preload("res://ui/character_panel.gd")
const START_MENU := "res://ui/start_menu.tscn"
# Autosave: every few minutes of running play, into rotating slots in the per-user save directory.
const AUTOSAVE_SECONDS := 300.0
const AUTOSAVE_SLOTS := 3
var core = Link.new()
var orbit = Orbit.new()
var state: Dictionary = {}
var graphics_sun: DirectionalLight3D
var origin := Vector2i.ZERO
var tiles: Dictionary = {}
var buildings: Dictionary = {}
var walkers: Dictionary = {}
var models: Dictionary = {}
var character_appearance = CharacterAppearance.new()
var walker_vat = WalkerVat.new()
var walker_contact=preload("res://scripts/walker_ground_contact.gd").new()
var citizen_lod = CitizenLod.new()
var road_drag = RoadDrag.new()
var message_log = MessageLog.new()
var autosave_age := 0.0
var autosave_interval := AUTOSAVE_SECONDS
var autosave_slots := AUTOSAVE_SLOTS
var horizon = Horizon.new()
# Per-asset manifest contracts and file existence never change while the game runs.
var model_contracts: Dictionary = {}
# Tiles per side of a building batch. A MultiMesh picks its mesh LOD and is culled as one
# unit, so smaller cells let distant instances drop to lower LODs at the cost of more draws.
var batch_cells := 24
var model_files: Dictionary = {}
# Frame name -> shape index per mesh, shared by every walker of a type.
var morph_tables: Dictionary = {}
const WALK_FRAMES := ["walk_00", "walk_01", "walk_02", "walk_03", "walk_04", "walk_05", "walk_06", "walk_07", "walk_08", "walk_09", "walk_10", "walk_11", "walk_12", "walk_13", "walk_14", "walk_15", "walk_16", "walk_17", "walk_18", "walk_19", "walk_20", "walk_21", "walk_22", "walk_23"]
const IDLE_FRAMES := ["idle_00", "idle_01", "idle_02", "idle_03", "idle_04", "idle_05", "idle_06", "idle_07", "idle_08", "idle_09", "idle_10", "idle_11"]
var world := Node3D.new()
var terrain := Node3D.new()
var terrain_style = TerrainPresentation.new()
var terrain_geometry = TerrainGeometry.new()
var terrain_details = TerrainDetails.new()
var static_batches = Batches.new()
var building_sites = preload("res://scripts/building_sites.gd").new()
var farm_crops = preload("res://scripts/farm_crops.gd").new()
var forest_batches = TerrainForest.new()
# Clear paved avenues/boulevards with trees and sculpture at their outside edges.
var street_trees = TerrainAvenues.new()
var terrain_bridges = TerrainBridges.new()
var trireme_orders = TriremeOrders.new()
var city_switch = CitySwitch.new()
var unit_selection = UnitSelection.new()
var route_editor = RouteEditor.new()
# The adventure editor (ui/editor_panel.gd), when the start menu opened an adventure for editing.
var editor_panel = null
var house_card = HouseCard.new()
# Flames and smoke over the burning buildings (the snapshot's `fires`).
var building_fires = BuildingFires.new()
# The plague over sick houses, and blessed and cursed buildings (the snapshot's `auras`).
var building_auras = BuildingAuras.new()
# Tidal waves, lava, earthquakes and landslides, drawn from the terrain changes they make (scripts/disaster_effects.gd).
var disaster_effects = DisasterEffects.new()
# Arrows, spears and rocks in flight (the snapshot's `shots`).
var thrown_shots = ThrownShots.new()
var wolf_attacks = WolfAttacks.new()
var view_box_sent := ""
var water_life = WaterLife.new()
var monster_effects = MonsterEffects.new()
var extent := Vector2i(32, 32)
var chunks: Dictionary = {}
var terrain_levels: Dictionary = {}
var building_signature := 0
# The interface is ui/hud.tscn (see ui/hud.gd); these aliases keep the controls reachable for validators and reviews.
var hud: Control
var events_panel: VBoxContainer
var event_signature := ""
var decision_reply_pending := -1
var selection := MeshInstance3D.new()
var preview := MeshInstance3D.new()
# Bigger people, road lanes and the hover ring (walker_streets.gd).
var walker_streets = WalkerStreets.new()
var defence_perch = DefencePerch.new()
var ghost := Node3D.new()
var footprint_cells := Node3D.new()
# Empty agora spaces: paved squares drawn by the presentation (the native building has no geometry of its own).
var plazas := Node3D.new()
var plaza_nodes := {}
# The braziers of the finished altars burn as animated flames, higher while a rite is on the altar (altar_rite.gd).
var altar_fires := AltarRite.Fires.new()
# City overlays (view modes): the core says what each shows, overlay_view draws it, update_buildings and the walker
# nodes apply its filters. `building_index` maps a snapshot building id to its record for the overlay.
var overlay_view := OverlayView.new()
var episode_overlay
# The world map screen over the city; the city is paused while it is open and resumes if it was running.
var world_map
var world_resume := false
var escape_menu: Control
var menu_resume := false
var menu_held_before := false
var character_panel: Control
var city_help: Control
var save_load_busy:=false
# Render-only: where scripts/render_portraits.gd keeps the portrait models (never set in the game).
var character_portrait_source := ""
var character_resume := false
var character_held_before := false
var world_render_state:Dictionary={}
var world_flight = WorldFlight.new()
# The army: the companies the core listed last (a snapshot carries them only when they changed), their flags on the map,
# the army panel, and the company waiting to be placed by the next click.
var banners: Array = []
var per_banner := 8
var army_view := ArmyView.new()
var army_panel
var placing_banner := -1
# The enlisting of a troop request, over the city (a raid's lives in the world map).
var enlist_dialog
# The red notice while an enemy force is in the city (the snapshot carries `invaders` only then).
var invasion_banner
var monster_card
# One rail button for each kind of hazard alert (ui/hazard_rail.gd).
var hazard_rail
var monster_card_age := 0.0
var building_index: Dictionary = {}
# Where each placed building stands ("x,y" -> its asset and transform), for effects that follow a building's own meshes (soot on a burning one).
var building_placements: Dictionary = {}
# The partner city of the trade post or pier being placed (its number in the core's list), or -1.
var trade_partner := -1
# The tile the current placement preview was made for: the pointer tile, or a nearby fitting shore tile for a pier.
var placement_cell := Vector2i.ZERO
var trade_buildings := 0
var buildable_revision := 0
var plaza_material: StandardMaterial3D
var placement_result: Dictionary = {}
var placement_key := ""
var placement_age := 0.0
var ghost_asset := ""
# The pieces of a pyramid are authored at the SDL game's proportions (a level is 30 px, 0.408 of a tile), while this view raises the ground
# .22 of a tile for each step the engine raises a tile (a pyramid raises it a step for each of the four stages of a level): the models are
# lowered by the ratio so that a ramp ends exactly at the ground of the next ring.
const PYRAMID_RISE := .22 / (30.0 / 73.48)
var sanctuary_ghost := Node3D.new()
var sanctuary_ghost_key := ""
var inspected := Vector2i(99999, 99999)
var inspection_age := 0.0
var inspector: PanelContainer
var inspector_text: Label
var inspector_controls: VBoxContainer
var build_menu: MenuButton
var undo_button: Button
var demolition_dialog: ConfirmationDialog
var demolition_request := ""
var demolition_spare_request := ""
var demolition_was_running := false
var hint: Label
var details: Label
var pause_button: Button
var language := "en"
var language_chosen := false
# Only a session reached through the start menu writes the player's language back to their settings.
var persist_language := false
var goals_age := 0.0
var goals_met := -1
var episode_reported := false
var mode := "select"
var orientation := 0
var picked := Vector2i(99999, 99999)
var terrain_signature := ""
var asset_count := 0
# Microseconds spent in each stage of the last receive_state(), for profiling.
var receive_timing: Dictionary = {}
var surface_revision := 0
var placement_revision := 0
var geometry_revision := 0
var building_draw_cache := {}
var building_render_key: Array = []
var building_render_updates := 0
var footprint_key: Array = []
var footprint_cache := PackedVector2Array()
# The same stages for the very first snapshot (city load), plus the core open time.
var startup_timing: Dictionary = {}
var capture_path := ""
var validation_save_directory := ""
var validate := false
var checks_started := false
var frame_count := 0
var selected_id := -1
var ui_layer: CanvasLayer
var started_at := Time.get_ticks_msec()
var tool_buttons: Dictionary = {}
var captured := false
var asset_review := false
var terrain_review := ""
var view_review := ""
var garden_review := ""
var sanctuary_review := ""
var pyramid_review := ""
var menu_rest_review := ""
var controls_review := ""
var objectives_review := ""
# A copy of a save to photograph its streets (review_street.gd); its folder is the save directory.
var street_review := ""
var attack_review := ""
var rite_review := ""
var character_review := ""
var character_subjects: Array = []

func _ready() -> void:
	# The root loading surface has already drawn. Hold city input and native ticks
	# through initial geometry/UI construction and the first complete city frame.
	if LoadingScreen.current(get_tree()) != null:
		process_mode = Node.PROCESS_MODE_DISABLED
	var port := 0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--bridge-port="):
			port = int(argument.get_slice("=", 1))
		if argument.begins_with("--lang="):
			language = argument.get_slice("=", 1)
			language_chosen = true
		if argument == "--validate":
			validate = true
		if argument == "--asset-review":
			asset_review = true
		if argument.begins_with("--terrain-review="):
			terrain_review = argument.trim_prefix("--terrain-review=")
		if argument.begins_with("--view-review="):
			view_review = argument.trim_prefix("--view-review=")
		if argument.begins_with("--garden-review="):
			garden_review = argument.trim_prefix("--garden-review=")
		if argument.begins_with("--sanctuary-review="):
			sanctuary_review = argument.trim_prefix("--sanctuary-review=")
		if argument.begins_with("--pyramid-review="):
			pyramid_review = argument.trim_prefix("--pyramid-review=")
		if argument.begins_with("--menu-rest-review="):
			menu_rest_review = argument.trim_prefix("--menu-rest-review=")
		if argument.begins_with("--controls-review="):
			controls_review = argument.trim_prefix("--controls-review=")
		if argument.begins_with("--objectives-review="):
			objectives_review = argument.trim_prefix("--objectives-review=")
		if argument.begins_with("--street-review="):
			street_review = argument.trim_prefix("--street-review=")
		if argument.begins_with("--attack-review="):
			attack_review = argument.trim_prefix("--attack-review=")
		if argument.begins_with("--rite-review="):
			rite_review = argument.trim_prefix("--rite-review=")
		if argument.begins_with("--character-review="):
			character_review = argument.trim_prefix("--character-review=")
		if argument.begins_with("--character-subjects="):
			character_subjects = Array(argument.trim_prefix("--character-subjects=").split(","))
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
	# The held camera keys are the player's own (the defaults in automation), and so are the autosave rhythm and the window.
	KeyBindings.apply_input_map()
	autosave_interval = PlaySettings.autosave_seconds() if KeyBindings.uses_player_settings() else AUTOSAVE_SECONDS
	autosave_slots = PlaySettings.autosave_slots() if KeyBindings.uses_player_settings() else AUTOSAVE_SLOTS
	if Engine.has_meta("ezeus_language"):
		language = str(Engine.get_meta("ezeus_language"))
	persist_language = Engine.has_meta("ezeus_from_start")
	language = UiText.set_language(language)
	add_child(world)
	world.add_child(terrain)
	world.add_child(static_batches)
	world.add_child(building_sites)
	world.add_child(farm_crops)
	world.add_child(forest_batches)
	world.add_child(street_trees)
	world.add_child(terrain_bridges)
	world.add_child(terrain_details)
	world.add_child(walker_streets.ring)
	add_child(horizon)
	add_child(orbit)
	orbit.ground_height = terrain_height_world
	setup_lighting()
	setup_ui()
	for marker in [selection, preview]:
		var box := BoxMesh.new()
		box.size = Vector3(.98, .04, .98)
		marker.mesh = box
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marker.visible = false
		world.add_child(marker)
	world.add_child(ghost)
	world.add_child(sanctuary_ghost)
	world.add_child(footprint_cells)
	world.add_child(plazas)
	world.add_child(altar_fires)
	world.add_child(building_fires)
	world.add_child(building_auras)
	world.add_child(disaster_effects)
	world.add_child(thrown_shots)
	world.add_child(wolf_attacks)
	world.add_child(monster_effects)
	world.add_child(water_life)
	world.add_child(army_view.root)
	overlay_view.city = self
	world.add_child(overlay_view)
	overlay_view.observations_changed.connect(hud.set_overlay_data)
	selection.material_override = material(Color(1.0, .77, .27, .5), true)
	preview.material_override = material(Color(.22, .85, .54, .55), true)
	add_child(core)
	core.snapshot_received.connect(receive_state)
	core.command_completed.connect(command_finished)
	core.status_changed.connect(func(message):
		if message.begins_with("Connected"):
			update_hint()
		else:
			hint.text = message)
	if port:
		core.start(port)
	else:
		var engine := str(Engine.get_meta("ezeus_engine_directory", ProjectSettings.globalize_path("res://..").simplify_path()))
		var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
		var to_open := designated
		if Engine.has_meta("ezeus_load"):
			to_open = str(Engine.get_meta("ezeus_load"))
			Engine.remove_meta("ezeus_load")
		if not street_review.is_empty():
			to_open = street_review
		DirAccess.make_dir_recursive_absolute(save_directory())
		var core_language := language if language in ["en", "ru"] else "en"
		var editing := Engine.has_meta("ezeus_editor")
		Engine.remove_meta("ezeus_editor")
		if Engine.has_meta("ezeus_simulation"):
			# The start menu already opened a new game's adventure; take it over instead of reading it again.
			var adopted: RefCounted = Engine.get_meta("ezeus_simulation")
			Engine.remove_meta("ezeus_simulation")
			core.adopt(adopted, save_directory())
		else:
			var verified: Dictionary=Engine.get_meta("ezeus_verified_save",{})
			var read_directory: String=to_open.get_base_dir() if not verified.is_empty() else save_directory()
			core.start_embedded(engine, to_open, core_language, read_directory)
			if core.simulation!=null:core.simulation.set_save_directory(save_directory())
			if not verified.is_empty():
				Engine.remove_meta("ezeus_verified_save")
				preload("res://scripts/save_loader.gd").clean(verified)
				if verified.get("recovered",false) and core.simulation!=null:hint.text=tr("Recovery copy loaded. The original save was kept.")
		# The leader's name, which the city's messages address (validation keeps the designated save's own).
		if core.simulation != null and not validate and not Leaders.current().is_empty():
			core.query("player_name " + Leaders.current())
		city_switch.attach(self)
		route_editor.attach(self)
		house_card.attach(self)
		if editing and core.simulation != null:
			editor_panel = EditorPanel.new()
			editor_panel.attach(self)
		# What the city may build is the core's answer, so the menu is filled once the city is open.
		refresh_catalog()
		if core.simulation != null and state.get("paused", true):
			world_map.prewarm(core)
	if LoadingScreen.current(get_tree()) != null:
		finish_city_loading.call_deferred()
	elif Engine.has_meta("ezeus_offer_settlement_guide"):
		offer_settlement_guide.call_deferred()

func finish_city_loading() -> void:
	var loading := LoadingScreen.current(get_tree())
	if loading == null:
		return
	if core.simulation == null or state.is_empty():
		loading.fail(return_to_start)
		return
	loading.set_status(tr("Entering the city…"))
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(loading):
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	if not is_inside_tree() or not is_instance_valid(loading):
		return
	loading.dismiss()
	process_mode = Node.PROCESS_MODE_INHERIT
	offer_settlement_guide()

func offer_settlement_guide() -> void:
	var requested: bool=bool(Engine.get_meta("ezeus_offer_settlement_guide",false))
	Engine.remove_meta("ezeus_offer_settlement_guide")
	if requested and not UserSettings.get_value("interface","settlement_guide_finished",false) and int(state.get("housing",{}).get("people",0))==0 and editor_panel==null:
		open_city_help("guide")

func material(color: Color, transparent := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = .85
	if transparent:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return result

func setup_lighting() -> void:
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	# The sky, continuous sea and cosmetic countryside extend beyond the playable
	# footprint; fog blends their distant silhouettes into the horizon.
	sky.background_mode = Environment.BG_SKY
	# Metallic roofs and gold figures need sky reflections as well as diffuse sunlight.
	var daylight := ProceduralSkyMaterial.new()
	daylight.sky_top_color = Color(.30, .48, .66)
	daylight.sky_horizon_color = Color(.70, .79, .84)
	daylight.sky_curve = .22
	daylight.ground_bottom_color = Color(.05, .13, .18)
	daylight.ground_horizon_color = Color(.70, .79, .84)
	daylight.ground_curve = .05
	var reflections := Sky.new()
	reflections.sky_material = daylight
	sky.sky = reflections
	sky.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(.72, .8, .87)
	sky.ambient_light_energy = .32
	sky.fog_enabled = true
	sky.fog_light_color = Color(.70, .79, .84)
	sky.fog_density = .0007
	sky.fog_sky_affect = 0.0
	# Filmic and ACES were compared on the designated city: both wash the sand out and lower the contrast
	# between roads and ground, so the linear mapping the terrain colours were tuned for stays.
	sky.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = sky
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	sun.light_color = Color(1.0, .9, .76)
	sun.light_energy = .9
	sun.shadow_enabled = true
	# Two cascades instead of Godot's default four: every building is re-rendered once per
	# cascade, and offscreen measurement showed this halves frame time at gameplay distances
	# with no visible change. The mesh LOD threshold lives in project.godot.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 70
	add_child(sun)
	graphics_sun = sun
	add_to_group("ezeus_graphics_city")
	preload("res://scripts/graphics_settings.gd").apply(get_tree(), preload("res://scripts/graphics_settings.gd").current)

# The quick tools. Inspecting is the city's resting mode, not a button: a right click, Escape or the tool card's close button
# returns to it (as the SDL game's right click drops the building tool).
const TOOLS := [["select", "Inspect"], ["house", "Housing"], ["road", "Road"], ["roadblock", "Road Block"], ["demolish", "Demolish"]]

func setup_ui() -> void:
	var layer := CanvasLayer.new()
	ui_layer = layer
	add_child(layer)
	hud = HudScene.instantiate()
	layer.add_child(hud)
	events_panel = hud.events_panel
	inspector = hud.inspector
	inspector_text = hud.inspector_text
	inspector_controls = hud.inspector_controls
	build_menu = hud.build_menu
	undo_button = hud.undo_button
	demolition_dialog = hud.demolition_dialog
	hint = hud.hint
	details = hud.details
	pause_button = hud.pause_button
	tool_buttons = hud.tool_buttons
	hud.set_tools(TOOLS)
	hud.set_model_factory(building_preview_model)
	hud.tool_selected.connect(set_tool)
	hud.toolbar_focus_changed.connect(func(blocked):
		orbit.toolbar_input_blocked = blocked
		if blocked: orbit.dragging = false)
	hud.decision_visibility_changed.connect(func(expanded):
		orbit.modal_input_blocked = expanded
		if expanded: orbit.dragging = false)
	hud.placement_turn_requested.connect(turn_placement)
	hud.wall_fill_changed.connect(func(filled): road_drag.wall_fill=filled;road_drag.key="")
	hud.inspector_closed.connect(close_inspection)
	var help_button:=Button.new(); help_button.name="CityHelpButton";help_button.text="?"; help_button.theme_type_variation="HeaderAction"
	help_button.custom_minimum_size=Vector2(28,28);help_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	help_button.tooltip_text="City attention and settlement guide"
	help_button.pressed.connect(func():open_city_help("attention"))
	hud.get_node("%StatsRow").add_child(help_button)
	hud.pause_pressed.connect(func(): core.send("pause %d" % (0 if state.get("paused", true) else 1)))
	hud.speed_selected.connect(func(index): core.send("speed %d" % index))
	hud.undo_pressed.connect(func(): core.send("undo"))
	hud.demolition_confirmed.connect(func():
		core.send(demolition_request)
		finish_demolition_dialog())
	hud.demolition_canceled.connect(finish_demolition_dialog)
	hud.demolition_spared.connect(func():
		core.send(demolition_spare_request)
		finish_demolition_dialog())
	hud.message_dismissed.connect(func(id):
		if id >= 0:
			pending_info_ack[id] = true
			flush_info_ack())
	hud.minimap.jump_requested.connect(jump_to_cell)
	hud.main_menu_confirmed.connect(return_to_start)
	hud.overlay_selected.connect(func(id): set_overlay(id, true))
	hud.set_aside_requested.connect(set_aside)
	episode_overlay = EpisodeOverlayScene.instantiate()
	episode_overlay.core = core
	add_child(episode_overlay)
	episode_overlay.main_menu_requested.connect(return_to_start)
	episode_overlay.restart_requested.connect(load_game)
	episode_overlay.session_started.connect(switch_session)
	world_map = WorldMapScene.instantiate()
	add_child(world_map)
	world_map.closed.connect(close_world)
	world_map.close_requested.connect(world_flight.begin_close)
	world_flight.city = self
	add_child(world_flight)
	world_flight.arrived.connect(func():
		world.visible = false
		horizon.visible = false)
	world_flight.returned.connect(world_map.finish_close)
	orbit.world_zoom_requested.connect(open_world)
	army_panel = ArmyPanelScene.instantiate()
	hud.add_child(army_panel)
	army_panel.order.connect(army_order)
	army_panel.selection_changed.connect(army_view.select)
	army_panel.go_to.connect(func(cell): jump_to_cell(Vector2(cell)))
	army_panel.place_requested.connect(begin_banner_placement)
	invasion_banner = InvasionBanner.new()
	hud.add_child(invasion_banner)
	invasion_banner.show_requested.connect(func(cell): jump_to_cell(Vector2(cell)))
	# The monsters at large: a button in the rail under the journal and the card it opens (ui/monster_card.gd).
	monster_card = MonsterCard.new()
	hud.add_child(monster_card)
	monster_card.attach(hud.get_node("%AlertList"), hud.icon("close"), hud.toolbar_icon("notice_monster"))
	hazard_rail = HazardRail.new()
	hud.add_child(hazard_rail)
	hazard_rail.attach(hud.get_node("%AlertList"), func(name): return hud.toolbar_icon("notice_"+name.trim_prefix("alert_")))
	hud.decision_visibility_changed.connect(func(expanded): hazard_rail.suspended=expanded)
	hazard_rail.go_requested.connect(func(cell): jump_to_cell(Vector2(cell)))
	hazard_rail.changed.connect(func():
		hud._layout_panels.call_deferred()
		place_monster_card.call_deferred())
	monster_card.opened.connect(func():
		hud.set_messages_open(false)
		hud.set_goals_expanded(false)
		refresh_monster_card())
	monster_card.visibility_changed.connect(place_monster_card)
	monster_card.go_requested.connect(func(cell): jump_to_cell(Vector2(cell)))
	monster_card.build_hall_requested.connect(func(tool_name):
		monster_card.set_open(false)
		close_inspection()
		hud.open_category("Heroes' halls")
		set_tool(tool_name))
	monster_card.show_hall_requested.connect(func(cell):
		monster_card.set_open(false)
		set_tool("select")
		inspected = cell
		refresh_inspection()
		jump_to_cell(Vector2(cell)))
	army_panel.closed.connect(func():
		army_view.select(-1)
		placing_banner = -1
		update_hint())
	hud.save_requested.connect(save_game)
	hud.load_requested.connect(load_game)
	hud.messages_toggled.connect(func(open):
		if open:
			monster_card.set_open(false)
			message_log.mark_read()
			hud.set_unread(0)
			hud.set_messages(message_log.entries)
			inspector.hide()
		else: refresh_inspection())
	hud.goals_toggled.connect(func(open):
		if open:
			monster_card.set_open(false)
			army_panel.close()
		refresh_inspection())
	inspector_controls.action_requested.connect(func(command):
		if not core.send(command):
			inspector_controls.command_done(command, false)
			hint.text = reason_text("command_queue_full"))
	hud.set_undo_available(state.get("undo_available", false))
	event_signature = ""
	set_tool(mode)
	refresh_inspection()

# Cycles the interface language. Controls are not rebuilt: texts are re-applied from the translations, and the
# parts that show live data are refreshed. The core's own language (messages, names) is chosen when the city opens.
func change_language() -> void:
	language = UiText.set_language(UiText.next_language(language))
	if persist_language:
		UserSettings.set_language(language)
	Engine.set_meta("ezeus_language", language)
	hud.retranslate()
	army_panel.retranslate()
	invasion_banner.retranslate()
	monster_card.retranslate()
	hazard_rail.retranslate()
	placement_key = ""
	update_hint()
	if not state.is_empty():
		update_status()
	event_signature = ""
	if not state.is_empty():
		update_events()
	refresh_inspection()
	update_details()

func update_status() -> void:
	hud.set_paused(state.paused)
	hud.set_speed(int(state.speed))
	hud.set_undo_available(state.get("undo_available", false))
	hud.set_status(state.date, int(state.money), int(state.population))
	hud.set_city_header(state.get("city_header", {}))

func update_hint() -> void:
	if mode == "wall":
		hint.text = tr("Drag to wall a rectangle's outline  •  hold Shift to fill it")
		return
	if mode in RoadDrag.AREA_TOOLS:
		hint.text = tr("Drag to fill an area  •  each plot is built where it fits")
		return
	if mode in RoadDrag.PATH_TOOLS:
		hint.text = tr("Drag to lay a row along a path")
		return
	if mode == "demolish":
		hint.text = tr("Click a building to demolish it  •  or drag over an area to demolish all of it")
		return
	if mode in ["goat", "sheep", "cattle"]:
		hint.text = tr("Click on fertile pasture to place livestock  •  click repeatedly to add more")
		return
	hint.text = KeyBindings.idle_hint()

func set_tool(value: String) -> void:
	road_drag.cancel(self)
	if route_editor.active and value != "select":
		route_editor.end()
	# A tool of a trade partner is "pier:3" or "trade_post:3": the building, then the partner city's number.
	trade_partner = int(value.get_slice(":", 1)) if value.contains(":") else -1
	mode = value.get_slice(":", 0)
	if mode != "hippodrome":
		orientation = posmod(orientation, 4)
	placement_key = ""
	placement_result.clear()
	ghost.visible = false
	sanctuary_ghost.visible = false
	footprint_cells.visible = false
	preview.visible = false
	hud.select_tool(value)
	update_hint()
	if mode == "goat":
		walker_vat.prefetch(["animal_goat"])
	elif mode == "sheep":
		walker_vat.prefetch(["animal_sheep_fleeced", "animal_sheep_nude"])
	elif mode == "cattle":
		walker_vat.prefetch(["animal_cattle"])

func turn_placement(direction: int) -> void:
	# The hippodrome's turn steps through up to eight plates (the core picks among those that fit); the rest turn four ways.
	orientation=posmod(orientation+direction,8 if mode=="hippodrome" else 4)
	placement_key=""
	hud.set_facing(orientation%4)

func finish_demolition_dialog() -> void:
	if demolition_was_running:
		core.send("pause 0")
	demolition_was_running = false
	demolition_request = ""
	demolition_spare_request = ""

func reason_text(code: String) -> String:
	var messages := {
		"save_failed": "The file could not be written",
		"save_backup_failed": "The recovery copy could not be secured. The previous save was kept.",
		"save_in_progress": "Another save operation is using this name. Try again shortly.",
		"save_checksum_failed": "The save failed its integrity check.",
		"invalid_save": "The saved file is damaged or incomplete.",
		"invalid_save_metadata": "The save contains unsupported presentation data.",
		"incompatible_save": "This save needs a newer game version.",
		"invalid_save_name": "Choose a different name",
		"save_directory_required": "No save folder is configured",
		"no_path": "No road can reach that tile",
		"nothing_to_build": "A road is already there",
		"out_of_map": "Outside the city map",
		"not_owned": "Another city's land",
		"other_district": "The footprint crosses a city boundary",
		"occupied": "Space is occupied",
		"max_sanctuaries": "The city may not found another sanctuary.",
		"need_marble": "The city's storehouses hold too little marble.",
		"no_monument": "There is no monument there.",
		"already_finished": "It is built already.",
		"not_finished": "The sanctuary is not finished yet.",
		"no_hall": "No hero's hall is there.",
		"already_summoned": "The hero has been summoned already.",
		"requirements_not_met": "The hero's requirements are not all met.",
		"hero_not_ready": "The hero has not arrived yet.",
		"unknown_quest": "That quest is no longer asked for.",
		"no_agora_site": "An agora needs six tiles of road with free ground beside them",
		"needs_agora_space": "Place this on an empty agora space",
		"vendor_exists": "This agora already has that vendor",
		"needs_flat_ground": "Level ground is needed",
		"blocked_terrain": "Terrain, a citizen or a banner blocks this space",
		"insufficient_funds": "The city's credit limit has been reached",
		"building_not_available": "This building is unavailable in this city",
		"pending_decision": "Resolve the city's pending decision first",
		"on_fire": "A burning building cannot be demolished",
		"nothing_to_demolish": "There is nothing to demolish here",
		"undo_unavailable": "There is no recent construction to undo",
		"demolition_target_changed": "The target changed. Inspect it again",
		"inspection_target_changed": "The selected building changed. Inspect it again",
		"invalid_storage_order": "Choose a valid stock limit",
		"unsupported_resource": "This store cannot handle those goods",
		"unsupported_industry": "This building does not control that industry",
		"building_on_fire": "A burning building cannot be managed",
		"not_enough_goods": "There are not enough goods in store yet",
		"trade_partner_unavailable": "That trade partner cannot get a post now",
		"not_on_shore": "A pier needs a shore with water beside it",
		"needs_shore": "This needs a shore with water beside it",
		"palace_exists": "The city has a palace already",
		"stadium_exists": "The city has a stadium already",
		"enemy_near": "Too close to the enemy",
		"no_bridge_site": "A bridge starts on a shore and crosses straight to the other",
		"needs_road": "Place this on a street",
		"roadblock_exists": "There is a roadblock here already",
		"no_hippodrome_fit": "No hippodrome piece fits beside the others here",
		"needs_hippodrome_straight": "Place this on a straight piece of the hippodrome",
		"animal_limit": "Build more sheds, dairies or corrals for more animals",
		"invalid_city_setting": "That setting is not one the city offers",
		"not_for_sale": "That city is not for sale",
		"route_needs_road": "A route goes along roads: click a road",
		"no_route": "This building's walkers have no route to edit",
		"no_trireme": "That trireme cannot be given orders now",
		"invalid_trireme_order": "Choose a trireme, then the water to send it to",
		"invalid_switch": "This building has no such switch",
		"no_sea_access": "This water does not lead to the sea",
		"nothing_to_set_aside": "Nothing needs to be set aside here",
		"command_queue_full": "Wait for the current actions to finish, then apply again",
		"unknown_banner": "That company is no longer in the army",
		"banner_abroad": "That company is abroad",
		"no_room": "There is no free ground for the company there",
		"military_unavailable": "That cannot be done now",
		"native_placement_rejected": "This footprint is blocked",
		"embedded_query_required": "These tools need the embedded simulation"}
	# The core's shore verdict is worded for the building being placed.
	if code == "not_on_shore" and mode != "pier":
		code = "needs_shore"
	return tr(messages.get(code, "The action could not be completed"))

func model_contract(asset: String) -> Dictionary:
	if not model_contracts.has(asset):
		var path := "res://assets/models/%s.json" % asset
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		model_contracts[asset] = parsed if parsed is Dictionary else {}
	return model_contracts[asset]

func model_file_exists(asset: String) -> bool:
	if not model_files.has(asset):
		model_files[asset] = ResourceLoader.exists("res://assets/models/%s.glb" % asset)
	return model_files[asset]

func model_basis(asset: String, width: float, depth: float, facing: int) -> Basis:
	var scale := 1.0
	var contract := model_contract(asset)
	if not contract.is_empty():
		var model_width: float = contract.bounds_blender[1][0] - contract.bounds_blender[0][0]
		var model_depth: float = contract.bounds_blender[1][1] - contract.bounds_blender[0][1]
		if facing % 2 == 1:
			var swap := model_width
			model_width = model_depth
			model_depth = swap
		if model_width > width * 1.2 or model_depth > depth * 1.2:
			scale = minf(width / model_width, depth / model_depth)
	return Basis(Vector3.UP, facing * PI / 2.0).scaled(Vector3.ONE * scale)

# What the city may build, from the core: the buildings and, for trade, one entry per partner city that can still get a post.
func refresh_catalog() -> void:
	var listed: Array = core.query("buildable").get("buildings", [])
	var partners: Array = core.query("trade_partners").get("partners", [])
	hud.set_catalog(BuildCatalog.groups(listed, BuildCatalog.placeholders_wanted(), partners))
	if hud.current_tool not in ["select", "demolish"] and not hud.build_entries.has(hud.current_tool):
		set_tool("select")

func building_preview_layout(tool: String) -> Dictionary:
	# One read-only query per uncached composite design, using the native city focus
	# so scenario-specific pyramid marble levels belong to the player's city.
	# The native layout is returned even when that cell cannot accept construction.
	var focus: Array = state.get("focus", [])
	if focus.size() >= 2 and tiles.has(Vector2i(int(focus[0]), int(focus[1]))):
		return core.query("preview %s %d %d 0" % [tool, int(focus[0]), int(focus[1])])
	for cell in tiles:
		return core.query("preview %s %d %d 0" % [tool, cell.x, cell.y])
	return {}

func building_preview_model(item: Dictionary) -> Node3D:
	return BuildingPreview.create(item, model, model_basis, building_preview_layout, PYRAMID_RISE)

# The trade partner a trade post or pier command carries.
func partner_suffix() -> String:
	return " %d" % trade_partner if trade_partner >= 0 and mode in ["trade_post", "pier"] else ""

func refresh_placement() -> void:
	var key := "%s:%d:%d:%d:%d" % [mode, picked.x, picked.y, orientation, trade_partner]
	if key != placement_key or placement_age >= .1:
		placement_key = key
		placement_age = 0
		placement_result = core.query("preview %s %d %d %d%s" % [mode, picked.x, picked.y, orientation, partner_suffix()])
		placement_cell = picked
		# Few shore tiles take a pier (or a fishery, urchin quay, wharf), so the pointer is helped: within two tiles the nearest spot
		# that fits is shown instead.
		if mode in SHORE_TOOLS and not placement_result.get("valid", false) and placement_result.get("reason", "") == "not_on_shore":
			var offsets: Array = []
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					offsets.append(Vector2i(dx, dy))
			offsets.sort_custom(func(a, b): return a.length_squared() < b.length_squared())
			for offset in offsets:
				var near: Dictionary = core.query("preview %s %d %d %d%s" % [mode, picked.x + offset.x, picked.y + offset.y, orientation, partner_suffix()])
				if near.get("valid", false):
					placement_result = near
					placement_cell = picked + offset
					break
		for child in footprint_cells.get_children():
			child.free()
		if placement_result.has("error"):
			hint.text = reason_text(placement_result.error)
			hud.set_placement_feedback(hint.text,false)
			return
		for cell in placement_result.tiles:
			var marker := MeshInstance3D.new()
			marker.mesh = terrain_geometry.footprint_mesh(Vector2i(int(cell[0]),int(cell[1])),float(cell[2])*.22)
			marker.material_override = material(Color(.16, .86, .48, .62) if cell[3] else Color(.94, .2, .18, .7), true)
			marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			footprint_cells.add_child(marker)
	if placement_result.has("error") or placement_result.is_empty():
		return
	var valid: bool = placement_result.valid
	if placement_result.has("pieces"):
		show_sanctuary_ghost(valid)
		return
	sanctuary_ghost.visible = false
	var center := world_position(placement_result.x + (placement_result.w - 1) * .5, placement_result.y + (placement_result.h - 1) * .5, placement_result.altitude)
	if mode == "road":
		center.y = terrain_geometry.height_at(placement_result.x,placement_result.y)
	footprint_cells.visible = true
	preview.visible = mode == "demolish"
	if preview.visible:
		preview.mesh.size = Vector3(placement_result.w - .02, .04, placement_result.h - .02)
		preview.position = center + Vector3.UP * .06
		preview.rotation = Vector3.ZERO
		preview.material_override.albedo_color = Color(.95, .32, .17, .5)
	var asset: String = placement_result.asset
	# Bridges and crosswalks are streets laid over water or a hippodrome: their tiles are the whole preview.
	if asset == "":
		ghost.visible = false
		hint.text = tr("Cost: %d  •  %s") % [int(placement_result.cost), tr("Ready to place") if valid else reason_text(placement_result.reason)]
		if mode == "demolish" and valid:
			hint.text = tr("Demolition: %d  •  Click to remove; demolition cannot be undone") % int(placement_result.cost)
		hud.set_placement_feedback(hint.text,valid)
		return
	if ghost_asset != asset:
		for child in ghost.get_children():
			child.free()
		ghost_asset = asset
		# Use exactly the same imported mesh transforms and fitting as the live batch.
		for piece in static_batches.template(asset):
			var mesh := MeshInstance3D.new()
			mesh.mesh = piece.mesh
			mesh.material_override = piece.material
			mesh.transform = piece.transform
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ghost.add_child(mesh)
		if asset == "road":
			var road := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(.92, .035, .92)
			road.mesh = box
			road.position.y = .025
			road.material_override = material(Color(.69, .63, .49))
			ghost.add_child(road)
	# A pier faces the water the core found, not the key-turned facing.
	var facing: int = int(placement_result.orientation) if mode in CORE_FACING else StreetFacing.facing(tiles, asset, int(placement_result.x), int(placement_result.y), int(placement_result.w), int(placement_result.h), orientation)
	ghost.transform = Transform3D(model_basis(asset, placement_result.w, placement_result.h, facing), center + Vector3.UP * .02)
	if mode not in ["road", "demolish"]:
		ghost.transform = StreetSetback.apply(tiles, placement_result, ghost.transform)
	if asset == "road":
		var normal := terrain_geometry.normal_at(terrain_geometry.profile(picked),.5,.5)
		ghost.basis = Basis(Quaternion(Vector3.UP,normal)) * ghost.basis
	ghost.visible = mode != "demolish"
	for child in ghost.get_children():
		child.transparency = .25 if valid else .55
	hint.text = tr("Cost: %d  •  %s") % [int(placement_result.cost), tr("Ready to place") if valid else reason_text(placement_result.reason)]
	if mode == "demolish" and valid:
		hint.text = tr("Demolition: %d  •  Click to remove; demolition cannot be undone") % int(placement_result.cost)
	hud.set_placement_feedback(hint.text,valid)

# A sanctuary about to be founded: its layout's pieces (temple, court, statues, monument, altar) as translucent models over the footprint,
# which the core lists in `pieces`; the footprint tiles show whether the ground takes it.
func show_sanctuary_ghost(valid: bool) -> void:
	ghost.visible = false
	sanctuary_ghost.visible = false
	var pieces: Array = placement_result.pieces
	var heights := {}
	for cell in placement_result.tiles:
		heights[Vector2i(int(cell[0]), int(cell[1]))] = float(cell[2])
	var key := "%s:%d" % [mode, pieces.size()]
	for piece in pieces:
		key += ":" + str(piece.asset)
	if key != sanctuary_ghost_key:
		sanctuary_ghost_key = key
		for child in sanctuary_ghost.get_children():
			child.free()
		for piece in pieces:
			var holder := Node3D.new()
			for part in static_batches.template(str(piece.asset)):
				var mesh := MeshInstance3D.new()
				mesh.mesh = part.mesh
				mesh.material_override = part.material
				mesh.transform = part.transform
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				holder.add_child(mesh)
			sanctuary_ghost.add_child(holder)
	var index := 0
	for piece in pieces:
		var holder: Node3D = sanctuary_ghost.get_child(index)
		# A piece of a pyramid stands on the ground its level will have raised (`lift`, in the steps of the native altitude).
		var altitude: float = heights.get(Vector2i(int(piece.x), int(piece.y)), float(placement_result.altitude)) + float(piece.get("lift", 0))
		var piece_basis := model_basis(str(piece.asset), int(piece.w), int(piece.h), int(piece.get("orientation", 0)))
		if str(piece.asset).begins_with("pyramid_"):
			piece_basis = piece_basis * Basis.from_scale(Vector3(1.0, PYRAMID_RISE, 1.0))
		holder.transform = Transform3D(piece_basis, world_position(int(piece.x) + (int(piece.w) - 1) * .5, int(piece.y) + (int(piece.h) - 1) * .5, altitude) + Vector3.UP * .02)
		for mesh in holder.get_children():
			mesh.transparency = .3 if valid else .6
		index += 1
	sanctuary_ghost.visible = true
	footprint_cells.visible = true
	if int(placement_result.marble) > 0:
		hint.text = tr("Cost: %d  •  %d marble  •  %s") % [int(placement_result.cost), int(placement_result.marble), tr("Ready to place") if valid else reason_text(placement_result.reason)]
	else:
		hint.text = tr("Cost: %d  •  %s") % [int(placement_result.cost), tr("Ready to place") if valid else reason_text(placement_result.reason)]
	hud.set_placement_feedback(hint.text,valid)

func close_inspection() -> void:
	inspected = Vector2i(99999, 99999)
	inspector.visible = false
	selection.visible = false

func refresh_inspection() -> void:
	inspection_age = 0
	if inspector == null or not tiles.has(inspected) or core.simulation == null:
		return
	var value: Dictionary = core.query("inspect %d %d" % [inspected.x, inspected.y])
	if value.has("error"):
		close_inspection()
		return
	if not value.has("footprint"):
		var kind: String = terrain_details.resource(tiles[inspected]) if tiles.has(inspected) else ""
		var labels := {"stone":"Stone","tall_stone":"Rock outcrop","copper":"Copper","silver":"Silver","marble":"Marble","black_marble":"Black marble","orichalcum":"Orichalcum"}
		if not labels.has(kind):
			close_inspection()
			return
		value["name"] = labels[kind]
	inspector.visible = not hud.message_panel.visible and not hud.goals_list.visible
	hud.set_inspection_header(value)
	var lines: Array[String] = []
	if value.has("footprint"):
		var r: Array = value.footprint
		selection.visible = true
		selection.mesh.size = Vector3(r[2], .04, r[3])
		selection.position = world_position(r[0] + (r[2] - 1) * .5, r[1] + (r[3] - 1) * .5, value.altitude) + Vector3.UP * .08
		lines.append(tr("Road access: %s  •  Maintenance: %d%%") % [tr("yes") if value.road_access else tr("no"), int(value.maintenance)])
		if value.has("employees"):
			lines.append(tr("Workers: %d / %d") % [int(value.employees), int(value.max_employees)])
		if value.has("residents"):
			lines.append(tr("Residents: %d / %d  •  Level: %d") % [int(value.residents), int(value.capacity), int(value.level)])
			var needs := ["Food", "Water", "Fleece", "Olive oil", "Arms", "Wine", "Horses", "Culture / science", "Appeal"]
			var missing: Array[String] = []
			for need in value.missing:
				missing.append(tr(needs[int(need)]))
			lines.append(tr("Missing for level %d: %s") % [int(value.target_level), ", ".join(missing) if not missing.is_empty() else tr("needs are met")])
	else:
		selection.visible = false
		lines.append(tr("Tile %d, %d  •  Height %d") % [inspected.x, inspected.y, int(value.altitude)])
		var kind: String = terrain_details.resource(tiles[inspected])
		var labels := {"stone":"Stone","tall_stone":"Rock outcrop","copper":"Copper","silver":"Silver","marble":"Marble","black_marble":"Black marble","orichalcum":"Orichalcum"}
		if labels.has(kind):
			lines.append(tr("Terrain: %s") % tr(labels[kind]))
	inspector_text.text = "\n\n".join(lines)
	inspector_controls.show_inspection(value)

func command_finished(command: String, result: Dictionary) -> void:
	placement_key = ""
	if command.begins_with("event ") and int(command.get_slice(" ", 1)) == decision_reply_pending:
		decision_reply_pending = -1
		if result.has("error"):
			event_signature = ""
			update_events()
	if result.has("error"):
		hint.text = reason_text(result.error)
	elif command.begins_with("build"):
		hint.text = tr("Built. Undo is available for the last construction.")
	elif command == "undo":
		hint.text = tr("Construction undone and its cost refunded.")
	elif command.begins_with("demolish"):
		hint.text = tr("Demolished using the city's rules.")
	elif command.begins_with("storage"):
		hint.text = tr("Storage orders updated. Carts will follow the new orders.")
	elif command.begins_with("industry"):
		hint.text = tr("The city's industry and workforce have been updated.")
	elif command.begins_with("trade "):
		hint.text = tr("Trade orders updated. Traders will follow them.")
	elif command.begins_with("buy_city"):
		city_switch.bought(result)
	elif command.begins_with("banners_move"):
		hint.text = tr("The companies march there.") if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("trireme_move"):
		hint.text = tr("The trireme sails there.") if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("route"):
		if result.get("kind", "") == "route":
			route_editor.apply(result)
			if command.begins_with("route_begin") and route_editor.active:
				close_inspection()
				hint.text = tr("Click roads to lead the walkers  •  Escape or a right click closes the route")
			elif command == "route_end":
				update_hint()
		else:
			hint.text = reason_text(str(result.get("error", "")))
	elif command.begins_with("building_switch"):
		hint.text = (tr("The wharf builds triremes again.") if command.ends_with(" 1") else tr("The wharf is shut down.")) if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("set_tax"):
		hint.text = tr("The tax rate is set.") if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("set_wage"):
		hint.text = tr("The wage rate is set.") if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("set_priority"):
		hint.text = tr("The workers are shared out again.") if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("man_towers"):
		hint.text = (tr("The towers are manned.") if command.ends_with(" 1") else tr("The towers' guards go home.")) if not result.has("error") else reason_text(str(result.error))
	elif command == "army_call":
		hint.text = tr("The companies are called out to their banners.")
	elif command == "army_home":
		hint.text = tr("The companies return to the palace.")
	elif command.begins_with("banner_call"):
		hint.text = tr("The company is called out to its banner.")
	elif command.begins_with("banner_home"):
		hint.text = tr("The company returns to the palace.")
	elif command.begins_with("banner_move"):
		hint.text = tr("The banner is moved.")
	elif command.begins_with("hero_summon"):
		hint.text = tr("The hero is summoned.") if not result.has("error") else reason_text(str(result.error))
	elif command.begins_with("monument_halt"):
		hint.text = tr("The work on the monument is halted.") if command.ends_with(" 1") else tr("The work on the monument goes on.")
	elif command.begins_with("sanctuary_help") and result.has("help") and result.help != null:
		hint.text = str(result.help.text)
		inspector_controls.show_help_answer(result.help)
	elif command.begins_with("sanctuary_attack") and result.has("attack_answer") and result.attack_answer != null:
		hint.text = str(result.attack_answer.text)
		inspector_controls.show_attack_answer(result.attack_answer)
	if command.begins_with("demolish_ruin") or command.begins_with("storage") or command.begins_with("industry") or command.begins_with("building_switch") or command.begins_with("trade ") or command.begins_with("hero_summon") or command.begins_with("monument_halt") or command.begins_with("sanctuary_help") or command.begins_with("sanctuary_attack"):
		inspector_controls.command_done(command, not result.has("error"))
	refresh_inspection()

# Terrain surface height under a world x/z position, for the camera's orbit centre and zoom anchor.
# ---- saving and loading -----------------------------------------------------------------------------------
# Saves live in the per-user data directory (never in the repository or next to the original game), in the
# native .ez format. Loading restarts the scene around the chosen file: every piece of presentation state is
# rebuilt from the first snapshot exactly as at launch.
func save_directory() -> String:
	if not street_review.is_empty():
		return street_review.get_base_dir()
	if validate:
		if validation_save_directory.is_empty():
			validation_save_directory = ProjectSettings.globalize_path("res://captures/validation-saves-%s-%d"%[language,Time.get_ticks_usec()])
		return validation_save_directory
	return SaveFiles.directory()

func default_save_name() -> String:
	if state.is_empty():
		return "city"
	var date: Array = state.date
	return "%d %s %d" % [absi(int(date[2])), "BC" if int(date[2]) < 0 else "AD", int(date[0])] + " " + hud.MONTHS[clampi(int(date[1]) - 1, 0, 11)]

# Letters (any alphabet), digits, space, dot, dash and underscore survive; the rest become dashes.
func sanitize_save_name(text: String) -> String:
	var expression := RegEx.new()
	expression.compile("[^\\p{L}\\p{N} _.\\-]")
	var clean := expression.sub(text, "-", true).strip_edges()
	while clean.begins_with("."):
		clean = clean.substr(1)
	while clean.to_utf8_buffer().size()>64:clean=clean.left(clean.length()-1)
	return clean.strip_edges()

func save_game(save_name: String) -> bool:
	var clean := sanitize_save_name(save_name)
	if clean.is_empty():
		hint.text = tr("Enter a name for the save")
		return false
	var result: Dictionary = core.simulation.save_city(clean,save_view()) if core.simulation != null else {"error": "city_not_loaded"}
	if result.has("saved"):
		hint.text = tr("Game saved as “%s”") % clean if result.get("durability_confirmed",true) else tr("The save was written, but disk durability could not be confirmed. Keep another copy.")
		return true
	hint.text = tr("The game could not be saved: %s") % reason_text(str(result.get("error", "save_failed")))
	return false

func save_view() -> Dictionary:
	var point:=tile_coordinates(orbit.target)
	return {"x":point.x,"y":point.y,"yaw":orbit.yaw,"pitch":orbit.pitch,"distance":orbit.distance}

# Saved games, newest first, with a one-line description for the load dialog.
func list_saves() -> Array:
	return SaveFiles.list(save_directory()) if validate or not street_review.is_empty() else SaveFiles.list()

func load_game(path: String) -> void:
	if save_load_busy or core.simulation==null:return
	save_load_busy=true
	var held: bool=core.commands_held
	var observed: Dictionary=core.simulation.snapshot(false)
	core.snapshot_received.emit(observed)
	var resume: bool=not observed.paused
	core.commands_held=true
	if resume:core.snapshot_received.emit(core.query("pause 1"))
	if is_instance_valid(escape_menu):escape_menu.suspend()
	var checked: Dictionary=await preload("res://scripts/save_loader.gd").choose_city(hud,path,language)
	save_load_busy=false
	if not checked.get("ok",false):
		core.commands_held=held
		if resume:core.snapshot_received.emit(core.query("pause 0"))
		if is_instance_valid(escape_menu):escape_menu.restore()
		hint.text=tr("Loading cancelled. Your current city is unchanged.")
		return
	Engine.set_meta("ezeus_load", checked.stage)
	Engine.set_meta("ezeus_verified_save",checked)
	SaveFiles.activate(str(checked.get("episode",{}).get("campaign_ref","")))
	Engine.set_meta("ezeus_language", language)
	hint.text = tr("Loading…")
	get_tree().reload_current_scene.call_deferred()

# The world map: the city is held while it is open, and runs on again afterwards if it was running.
func open_world() -> void:
	if core.simulation == null or world_map.visible or episode_overlay.visible or world_flight.busy() or road_drag.active or placing_banner >= 0 or enlist_dialog != null or demolition_dialog.visible:
		return
	if get_tree().root.get_node("UiAccess").dialog_open:
		return
	# Read the authoritative pause state (a queued UI snapshot may lag a click).
	var observed: Dictionary = core.simulation.snapshot(false)
	core.snapshot_received.emit(observed) # Deliver consumed deltas through the normal presentation path.
	world_resume = not observed.get("paused", true)
	core.commands_held = true
	# Hold synchronously before the initial relief build; a slow first frame
	# must not become native catch-up ticks before a queued pause is consumed.
	if world_resume:
		core.snapshot_received.emit(core.query("pause 1"))
	if not world_map.open(core):
		hint.text = tr("The world map is not available")
		if world_resume: core.query("pause 0")
		world_resume=false
		core.commands_held=false
		return
	world_render_state={"world":world.visible,"horizon":horizon.visible,"orbit":orbit.enabled}
	world_flight.begin_open()

func close_world() -> void:
	if not world_render_state.is_empty():
		world.visible=world_render_state.world
		horizon.visible=world_render_state.horizon
		orbit.enabled=world_render_state.orbit
		world_render_state.clear()
	if world_resume:
		core.snapshot_received.emit(core.query("pause 0"))
	world_resume = false
	core.commands_held = false

# The army panel takes the inspector's place on the right; opening it again closes it.
func open_army() -> void:
	if core.simulation == null or world_map.visible or episode_overlay.visible:
		return
	if army_panel.visible:
		army_panel.close()
		return
	close_inspection()
	per_banner = int(core.query("army").get("per_banner", per_banner))
	army_panel.set_banners(banners, per_banner)
	army_panel.open()

# A city asked for troops: the same enlisting as a raid's, answered over the city (the request waits until the troops are sent).
func open_troop_enlist(event_id: int) -> void:
	if enlist_dialog != null:
		return
	var session: Dictionary = core.query("event %d -2" % event_id)
	if session.has("error"):
		hint.text = reason_text(str(session.error))
		return
	var sent := func(_answer: Dictionary):
		hint.text = tr("The troops set out to help.")
		event_signature = ""
		update_events()
	var dismissed := func(): enlist_dialog = null
	enlist_dialog = EnlistDialog.open(ui_layer, core, session, sent, dismissed)

func army_order(command: String) -> void:
	if not core.send(command):
		hint.text = reason_text("command_queue_full")

func begin_banner_placement(id: int) -> void:
	placing_banner = id
	army_panel.set_placing(true)
	hint.text = tr("Click where the company should stand  •  Escape cancels")

func end_banner_placement() -> void:
	placing_banner = -1
	army_panel.set_placing(false)
	update_hint()

func place_banner(cell: Vector2i) -> void:
	var id := placing_banner
	end_banner_placement()
	if id >= 0 and tiles.has(cell):
		army_order("banner_move %d %d %d" % [id, cell.x, cell.y])

func game_action(action: String) -> void:
	match action:
		"attention", "guide":
			open_city_help(action)
		"main_menu":
			hud.confirm_main_menu()
		"sound":
			SoundDialog.open(hud)
		"display":
			preload("res://ui/display_dialog.gd").open(hud)
		"interface":
			preload("res://ui/interface_dialog.gd").open(hud)
		"controls":
			var controls: Window = ControlsDialog.open(hud)
			controls.changed.connect(hud.retranslate)
		"settings":
			var settings: Window = GameSettingsDialog.open(hud)
			settings.changed.connect(apply_play_settings)
		"trade":
			TradeDialog.open(hud, core)
		"world":
			open_world()
		"army":
			open_army()
		"mythology":
			MythologyDialog.open(hud, core, func(cell): jump_to_cell(Vector2(cell)))
		"city":
			CityDialog.open(hud, core, func(id): set_overlay(id), func(cell): jump_to_cell(Vector2(cell)))
		"save":
			hud.open_save_dialog(default_save_name())
		"load":
			hud.open_load_dialog(list_saves())
		"quick_save":
			save_game("quicksave")
		"quick_load":
			var path := save_directory().path_join("quicksave.ez")
			if FileAccess.file_exists(path):
				load_game(path)
			else:
				hint.text = tr("There is no quick save yet")

# The autosave rhythm the player chose (Game settings) takes effect at once.
func apply_play_settings() -> void:
	hud.retranslate()
	if KeyBindings.uses_player_settings():
		autosave_interval = PlaySettings.autosave_seconds()
		autosave_slots = PlaySettings.autosave_slots()
		autosave_age = 0.0

# Rotates the autosave slots (1 newest) and writes the city into slot 1.
func autosave() -> bool:
	autosave_age = 0.0
	var directory := save_directory()
	for slot in range(autosave_slots, 1, -1):
		var older := directory.path_join("autosave %d.ez" % (slot - 1))
		if FileAccess.file_exists(older):
			DirAccess.rename_absolute(older, directory.path_join("autosave %d.ez" % slot))
	var saved: bool = core.simulation != null and core.simulation.save_city("autosave 1",save_view()).has("saved")
	if saved:
		hint.text = tr("Autosaved")
	return saved

# Moves the camera to a tile (the minimap's click): the orbit centre lands on that ground.
# The core's words on the monsters at large (ui/monster_card.gd).
func refresh_monster_card() -> void:
	monster_card_age = 0.0
	if core.simulation == null:
		return
	var answer: Dictionary = core.query("monster_info")
	if answer.has("monsters"):
		monster_card.set_monsters(answer.monsters)
		place_monster_card()

# The card hangs under the right-hand rail, as the journal does, no taller than the screen allows.
func place_monster_card() -> void:
	if monster_card == null or not monster_card.visible:
		return
	var rail: Control = hud.get_node("%EventRail")
	var top: float = maxf(hud.get_node("%ResourceRibbon").get_global_rect().end.y+12,hud.get_node("%ObjectivesButton").get_global_rect().end.y+8)
	var wanted: float = monster_card.list.get_combined_minimum_size().y + 80
	var room: float = maxf(0,hud.get_node("%BottomBar").position.y-top-8)
	monster_card.offset_right = rail.position.x-8-hud.size.x
	monster_card.offset_left = monster_card.offset_right-minf(maxf(400,monster_card.get_combined_minimum_size().x),hud.size.x-100)
	monster_card.offset_top = top
	monster_card.offset_bottom = top + minf(wanted, room)

func jump_to_cell(cell: Vector2) -> void:
	orbit.cancel_wheel_zoom()
	orbit.target = world_position(cell.x, cell.y, 0)
	orbit.clamp_target()
	orbit.snap_to_ground()

func open_city_help(which: String) -> void:
	if not is_instance_valid(city_help):
		city_help=preload("res://ui/city_help_panel.gd").new()
		city_help.city=self; hud.add_child(city_help)
	city_help.open(which)

func focus_attention(item: Dictionary) -> void:
	# A warning must not select a demolished/replaced building at the same address.
	var current: Dictionary=building_index.get(int(item.id),{})
	var target:=Vector2i(int(item.x),int(item.y))
	if current.is_empty() or not Rect2i(Vector2i(int(current.x),int(current.y)),Vector2i(int(current.w),int(current.h))).has_point(target):
		if is_instance_valid(city_help):city_help.refresh()
		return
	set_tool("select")
	hud.set_goals_expanded(false);hud.set_messages_open(false)
	jump_to_cell(Vector2(float(current.x)+(float(current.w)-1)*.5,float(current.y)+(float(current.h)-1)*.5))
	orbit.distance=minf(orbit.distance,maxf(14.0,maxf(float(current.w),float(current.h))*2.5))
	orbit.refresh()
	# Pyramid pieces are registered at their far native corner while their
	# presentation footprint extends back from it. Inspect the reported native tile.
	inspected=target; refresh_inspection()

# Tile coordinates of a world point (x right, y up in the minimap).
func tile_coordinates(point: Vector3) -> Vector2:
	return Vector2(point.x + origin.x + (extent.x - 1) * .5, -point.z + origin.y + (extent.y - 1) * .5)

# The camera's footprint on the ground, as tile coordinates for the minimap outline.
func view_footprint() -> PackedVector2Array:
	var rect := get_viewport().get_visible_rect()
	var key := [orbit.camera.global_transform, orbit.camera.projection, orbit.camera.fov,
		orbit.camera.size, orbit.camera.keep_aspect, orbit.camera.h_offset, orbit.camera.v_offset,
		orbit.camera.near, orbit.camera.far, orbit.camera.frustum_offset,
		rect, origin, extent, geometry_revision]
	if key == footprint_key: return footprint_cache
	var polygon := PackedVector2Array()
	for corner in [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]:
		var hit = orbit.terrain_point(corner)
		if hit == null:
			hit = orbit.ground_point(corner)
		if hit != null:
			polygon.append(tile_coordinates(hit))
	footprint_key = key
	footprint_cache = polygon
	return polygon

# Tells the core which tiles the camera shows, so the sounds the native game plays only for what is on screen (a fire's crackle, gods,
# monsters, archers, builders) play for what the player sees. Sent only when the box changes.
func send_view_box() -> void:
	if core.simulation == null or tiles.is_empty():
		return
	var polygon := view_footprint()
	if polygon.is_empty():
		return
	var low := polygon[0]
	var high := polygon[0]
	for corner in polygon:
		low = low.min(corner)
		high = high.max(corner)
	var box := "view_box %d %d %d %d" % [floori(low.x), floori(low.y), ceili(high.x), ceili(high.y)]
	if box != view_box_sent:
		view_box_sent = box
		core.query(box)

func terrain_height_world(x: float, z: float) -> float:
	if tiles.is_empty():
		return 0.0
	var nx := x + origin.x + (extent.x - 1) * .5
	var ny := -z + origin.y + (extent.y - 1) * .5
	if not tiles.has(Vector2i(roundi(nx),roundi(ny))) and horizon.surroundings.field != null:
		return horizon.surroundings.height(Vector2(nx+.5,ny+.5))
	return terrain_geometry.height_at(nx,ny)

func world_position(x: float, y: float, height: float) -> Vector3:
	return Vector3(x - origin.x - (extent.x - 1) * .5, height * .22, -(y - origin.y - (extent.y - 1) * .5))

func receive_state(value: Dictionary) -> void:
	if value.get("protocol", 0) != 1:
		return
	var receive_started := Time.get_ticks_usec()
	var initial := state.is_empty()
	state = value
	# What the native rules asked to be heard since the last snapshot, and whether the music should be a battle's.
	GameAudio.play_native(value.get("sounds", []))
	GameAudio.play_music("battle" if str(value.get("music", "city")) == "battle" else "city")
	# The player's own invasion or god attack of a city on the map: the view goes to it, as the SDL view does.
	if value.has("view_tile") and not initial:
		jump_to_cell(Vector2(int(value.view_tile[0]), int(value.view_tile[1])))
	static_batches.activity.receive(state)
	if initial:
		# Model files are the largest share of city load; read them on worker threads
		# while the terrain below is generated.
		var wanted := {}
		for entry in state.get("buildings", []):
			wanted[entry.asset] = true
			if entry.has("bays"):
				for b in entry.bays:
					if entry.asset == "granary":
						wanted["granary_food_" + str(b.good)] = true
					else:
						wanted["good_" + str(b.good)] = true
		static_batches.prefetch(wanted.keys())
		var paths := {}
		for entry in state.get("walkers", []):
			var runtime := walker_vat.runtime_path(entry.asset)
			paths[runtime if not runtime.is_empty() else "res://assets/models/%s.glb" % entry.asset] = true
		static_batches.prefetch_paths(paths.keys())
		var walker_assets := {}
		for entry in state.get("walkers", []):
			walker_assets[entry.asset] = true
		walker_vat.prefetch(walker_assets.keys())
		for asset in walker_assets:
			if not citizen_lod.crowd_asset(asset).is_empty():
				citizen_lod.prefetch(static_batches)
				break
	origin = Vector2i(int(state.origin[0]), int(state.origin[1]))
	var dimensions: Array = state.get("extent", [32, 32])
	extent = Vector2i(int(dimensions[0]), int(dimensions[1]))
	orbit.configure_map(extent)
	if initial:
		var focus: Array = state.get("focus", [origin.x + 15.5, origin.y + 15.5])
		if Engine.has_meta("ezeus_new_game_focus"):
			focus = Engine.get_meta("ezeus_new_game_focus")
			Engine.remove_meta("ezeus_new_game_focus")
		var saved_view: Array=state.get("saved_camera",[])
		if saved_view.size()==5:
			focus=[saved_view[0],saved_view[1]]
			orbit.yaw=float(saved_view[2]);orbit.pitch=clampf(float(saved_view[3]),25,75);orbit.distance=clampf(float(saved_view[4]),orbit.MINIMUM_DISTANCE,orbit.maximum_distance)
		orbit.target = world_position(focus[0], focus[1], 0)
		orbit.clamp_target();orbit.snap_to_ground()
	var dirty := {}
	var changed: Array[Vector2i] = []
	var geometry_changes: Array[Vector2i] = []
	var street_changes: Array[Vector2i] = []
	if initial and state.has("tiles"):
		tiles.clear()
	for tile in state.get("tiles", state.get("tile_changes", [])):
		var key := Vector2i(int(tile[0]), int(tile[1]))
		var old: Array = tiles.get(key, [])
		changed.append(key)
		var coast_changed: bool = old.is_empty() or (int(old[3]) & 4) != (int(tile[3]) & 4)
		var height_changed: bool = not old.is_empty() and old[2] != tile[2]
		var old_geometry := int(old[6]) if old.size() >= 8 else 0
		var new_geometry := int(tile[6]) if tile.size() >= 8 else 0
		var geometry_changed := old.is_empty() or height_changed or coast_changed or bool((old_geometry ^ new_geometry) & 3) or (bool((old_geometry | new_geometry) & 1) and bool((old_geometry ^ new_geometry) & 8))
		var street_changed: bool = old.is_empty() or old[4] != tile[4] or (old.size() >= 9 and tile.size() >= 9 and old[8] != tile[8])
		if street_changed: street_changes.append(key)
		if geometry_changed:
			geometry_changes.append(key)
			dirty[Vector2i(floori(float(key.x - origin.x) / 32), floori(float(key.y - origin.y) / 32))] = true
		if not initial and geometry_changed:
			# Shared slope corners, cliff joins and water aprons cross section borders.
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var neighbor := key + Vector2i(dx, dy)
					if neighbor.x >= origin.x and neighbor.y >= origin.y and neighbor.x < origin.x + extent.x and neighbor.y < origin.y + extent.y:
						dirty[Vector2i(floori(float(neighbor.x - origin.x) / 32), floori(float(neighbor.y - origin.y) / 32))] = true
		# A road appearing or going changes which buildings step back from it (street_setback.gd).
		if not initial and old.size() > 4 and int(old[4]) != int(tile[4]):
			building_signature = 0
		if not initial:
			disaster_effects.note(key, old, tile)
		tiles[key] = tile
		terrain_levels[int(tile[2])] = true
	if not changed.is_empty(): surface_revision += 1
	if not geometry_changes.is_empty(): geometry_revision += 1
	if not geometry_changes.is_empty() or not street_changes.is_empty():
		placement_revision += 1
		building_signature = 0
	if initial or not street_changes.is_empty():
		walker_streets.update_tiles(tiles, street_changes, initial)
	var stamp := Time.get_ticks_usec()
	var timing := {"tiles": stamp - receive_started}
	# Lambdas capture locals by value, so the running stamp lives in a dictionary.
	var clock := {"last": stamp}
	var lap := func(label: String) -> void:
		var now := Time.get_ticks_usec()
		timing[label] = now - clock.last
		clock.last = now
	if not changed.is_empty():
		terrain_style.update(tiles, origin, extent, changed)
	lap.call("style")
	terrain_geometry.update(tiles,origin,extent,geometry_changes)
	if initial:
		orbit.snap_to_ground()
		horizon.update(tiles, origin, extent, terrain_geometry, terrain_style, forest_batches)
		hud.minimap.set_map(tiles, origin, extent)
	elif not changed.is_empty():
		hud.minimap.paint_tiles(tiles, changed)
	lap.call("geometry")
	for chunk in dirty:
		build_chunk(chunk)
	lap.call("chunks")
	disaster_effects.flush(self)
	if not changed.is_empty():
		forest_batches.update(tiles,origin,extent,terrain_geometry,changed)
		lap.call("forest")
		terrain_bridges.update(tiles,origin,extent,terrain_geometry,changed)
		lap.call("bridges")
		terrain_details.update(tiles,origin,extent,terrain_geometry,changed)
		lap.call("details")
		street_trees.update(tiles,origin,extent,terrain_geometry,changed)
		lap.call("street_trees")
	water_life.update_tiles(self, changed, initial)
	water_life.receive(value)
	update_buildings()
	farm_crops.refresh(state.get("farm_crops",[]),self)
	if value.has("fires"):
		building_fires.update(value.fires, self)
	if value.has("auras"):
		building_auras.update(value.auras, self)
	lap.call("buildings")
	update_walkers()
	monster_effects.receive(value, self)
	thrown_shots.receive(value, self)
	update_events()
	# What the city may build changes while it is played (a monster unlocks its slayer's hall, an event allows a building):
	# the core counts those changes and the Build menu asks again.
	var revision := int(value.get("buildable_revision", buildable_revision))
	if revision != buildable_revision:
		buildable_revision = revision
		if not initial and core.simulation != null:
			refresh_catalog()
	var invader_at: Array = value.get("invader_at", [0, 0])
	var monster_at: Array = value.get("monster_at", [0, 0])
	# Invaders keep the notice at the top of the city; monsters have their own button and card beside the journal.
	invasion_banner.set_invaders(int(value.get("invaders", 0)), Vector2i(int(invader_at[0]), int(invader_at[1])))
	if hazard_rail != null and value.has("alerts"):
		hazard_rail.observe(value.alerts)
	for alert in value.get("alerts", []):
		disaster_effects.note_alert(int(alert.id), str(alert.kind))
	if hazard_rail != null and value.has("fires"):
		# The fire and plague buttons stay while the hazard lasts (smouldering ruins do not count).
		var burning := 0
		var burning_at = null
		for fire in value.fires:
			if int(fire[5]) == 0:
				burning += 1
				if burning_at == null: burning_at = Vector2i(int(fire[0]), int(fire[1]))
		hazard_rail.set_persistent("fire", burning, burning_at)
	if hazard_rail != null and value.has("plague"):
		var sick: Dictionary = value.plague
		hazard_rail.set_persistent("plague", int(sick.houses), Vector2i(int(sick.at[0]), int(sick.at[1])) if int(sick.at[0]) >= 0 else null)
	var monsters_now := int(value.get("monsters", 0))
	if monster_card != null and monsters_now != monster_card.count:
		monster_card.set_count(monsters_now)
		hud._layout_panels()
		place_monster_card()
		if monsters_now > 0:
			refresh_monster_card()
	if value.has("banners"):
		banners = value.banners
		army_view.update(self, banners)
		army_panel.set_banners(banners, per_banner)
	lap.call("walkers")
	receive_timing = timing
	if initial:
		startup_timing = timing.duplicate()
	placement_age = .1
	update_status()

# Retain news before acknowledging it; a full command queue retries on the next observation.
func flush_info_ack() -> void:
	for id in pending_info_ack.keys():
		# Leave room for player commands during a burst of quiet news.
		if core.commands.size() >= 4: break
		if core.send("event %d -1" % id): pending_info_ack.erase(id)
		else: break

# Routine events quietly enter the journal. Unknown/urgent news gets one alert; decisions keep their native choices.
func update_events() -> void:
	flush_info_ack()
	var events: Array = state.get("events", [])
	var signature := str(events.hash())
	if signature == event_signature:
		return
	event_signature = signature
	var decision: Dictionary = {}
	for entry in events:
		var informational: bool = MessageLog.is_informational(entry)
		if message_log.record(entry, hud.date_label.text, not informational) and informational:
			if NotificationPolicy.delivery(entry) == "journal":
				pending_info_ack[int(entry.id)] = true
			else:
				hud.show_toast(int(entry.id), MessageLog.sentence(str(entry.title)), str(entry.text), str(entry.get("kind","")))
		if not informational and decision.is_empty():
			decision = entry
	if decision_reply_pending != int(decision.get("id", -1)):
		decision_reply_pending = -1
	if hud.message_panel.visible:
		message_log.mark_read()
		hud.set_messages(message_log.entries)
	hud.set_unread(message_log.unread)
	flush_info_ack()
	for child in events_panel.get_children() + hud.get_node("%EventActions").get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	hud.set_decision(decision, events.filter(func(event): return not MessageLog.is_informational(event)).size())
	if decision.is_empty():
		return
	var body := Label.new()
	body.text = str(decision.text)
	body.theme_type_variation = "EnvoyBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 0
	events_panel.add_child(body)
	for action in hud.decision_actions(decision):
		var button := Button.new()
		button.text = str(action.label)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.theme_type_variation = hud.decision_action_style(decision, int(action.choice))
		button.custom_minimum_size = Vector2(120, 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("choice", int(action.choice))
		button.disabled = decision_reply_pending == int(decision.id)
		# "Send troops" (-2) asks the core for the forces that may go; the other choices answer the decision.
		button.pressed.connect(func(): reply_to_decision(int(decision.id), int(action.choice)))
		hud.get_node("%EventActions").add_child(button)
	hud._update_decision_focus.call_deferred()
	hud._layout_panels.call_deferred()

func reply_to_decision(event_id: int, choice: int) -> bool:
	var current: Array = state.get("events", []).filter(func(entry): return int(entry.id) == event_id)
	if current.is_empty() or not current[0].get("actions", []).any(func(action): return int(action.choice) == choice):
		return false
	if decision_reply_pending == event_id:
		return true
	if choice == -2:
		open_troop_enlist(event_id)
		return true
	if not core.send("event %d %d" % [event_id, choice]):
		return false
	decision_reply_pending = event_id
	for button in hud.get_node("%EventActions").get_children():
		button.disabled = true
	return true

# A right-click is the offered native Postpone action, including its scheduling
# and pause behavior. Invasions' choice 1 is Bribe and must never take this path.
func postpone_decision() -> bool:
	for entry in state.get("events", []):
		if int(entry.id) == hud.decision_id and hud.decision_can_postpone(entry):
			reply_to_decision(int(entry.id), 1)
			# A full command queue keeps the panel open so the action can be retried.
			return true
	return false

func build_chunk(key: Vector2i) -> void:
	if chunks.has(key):
		chunks[key].free()
	var node := Node3D.new()
	terrain.add_child(node)
	chunks[key] = node
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wet := SurfaceTool.new()
	wet.begin(Mesh.PRIMITIVE_TRIANGLES)
	var water_count := 0
	var count := 0
	var side_count := 0
	var top_vertices := 0
	for y in range(origin.y + key.y * 32, origin.y + (key.y + 1) * 32):
		for x in range(origin.x + key.x * 32, origin.x + (key.x + 1) * 32):
			var cell := Vector2i(x, y)
			if not tiles.has(cell):
				continue
			var tile: Array = tiles[cell]
			count += 1
			top_vertices += terrain_geometry.add_top(surface,cell)
			side_count += terrain_geometry.add_sides(surface,cell)
			var water_height = terrain_style.water_height(tiles, cell)
			if water_height != null:
				add_tile(wet, world_position(x, y, water_height) + Vector3.UP * .025, Color.WHITE, .5)
				water_count += 1
	if count == 0:
		return
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	ground.material_override = terrain_style.ground_material
	ground.set_meta("tile_count",count)
	ground.set_meta("top_vertices",top_vertices)
	ground.set_meta("side_faces",side_count)
	node.add_child(ground)
	ground.create_trimesh_collision()
	if water_count:
		var water := MeshInstance3D.new()
		water.mesh = wet.commit()
		water.material_override = terrain_style.water_material
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(water)

func add_tile(surface: SurfaceTool, center: Vector3, color: Color, radius: float, native_water := false) -> void:
	var corners := [Vector3(-radius, 0, -radius), Vector3(radius, 0, -radius), Vector3(radius, 0, radius), Vector3(-radius, 0, radius)]
	for index in [0, 1, 2, 0, 2, 3]:
		surface.set_color(color)
		surface.set_normal(Vector3.UP)
		surface.set_uv(Vector2((center.x + corners[index].x) / 12, (center.z + corners[index].z) / 12))
		surface.set_uv2(Vector2(1 if native_water else 0, 0))
		surface.add_vertex(center + corners[index])

func model(name: String) -> Node3D:
	# Roles with a realistic citizen are shown by their low-poly crowd model; citizen_lod
	# swaps a skeletal citizen in for the few walkers nearest the camera.
	var crowd := citizen_lod.crowd_asset(name)
	if not crowd.is_empty():
		name = crowd
	# A baked-pose derivative (no morph targets) is used while it matches its source; its
	# animated parts are remembered for animate_walker. Otherwise the source model with
	# blend shapes is used.
	var runtime := walker_vat.runtime_path(name)
	if not runtime.is_empty():
		var key := "runtime:" + name
		if not models.has(key):
			models[key] = static_batches.load_model(runtime)
		var baked: Node3D = models[key].instantiate()
		character_appearance.apply(baked, name, model_contract(name))
		var parts = walker_vat.attach(baked, name)
		if parts != null:
			baked.set_meta("vat_parts", parts)
			return baked
		baked.free()
	var path := "res://assets/models/%s.glb" % name
	if not models.has(name) and ResourceLoader.exists(path):
		models[name] = static_batches.load_model(path)
	if models.has(name):
		var instance: Node3D = models[name].instantiate()
		character_appearance.apply(instance, name, model_contract(name))
		static_batches.finish.apply(instance,name)
		return instance
	return null

func update_buildings() -> void:
	# The embedded core flags an unchanged building list, so steady snapshots cost nothing.
	# Other sources (the legacy bridge) carry no flag and fall back to hashing the list.
	var forced := building_signature == 0
	var signature: int
	if state.has("buildings_changed"):
		if not state.buildings_changed and building_signature != 0:
			return
		signature = 1
	else:
		signature = state.buildings.hash()
		if signature == building_signature:
			return
	building_signature = signature
	# Inspector records remain current even when stock/staffing metadata changes
	# without changing any rendered geometry, work flags or occupied goods bays.
	building_index.clear()
	var rows: Array = []
	for building in state.buildings:
		building_index[int(building.id)] = building
		var bays: Array = []
		for bay in building.get("bays", []):
			bays.append([int(bay.get("bay", -1)), str(bay.get("good", ""))])
		rows.append([building.id, building.asset, building.x, building.y, building.w, building.h,
			building.altitude, building.get("orientation", 0), building.get("stretch", false),
			building.get("grow", 100), building.get("working", building.get("active", false)),
			building.get("animation_offset", 0), bays])
	var render_key := [rows, placement_revision, origin, extent, overlay_view.mode, overlay_view.visibility_signature]
	if not forced and render_key == building_render_key:
		if overlay_view.active(): overlay_view.redraw()
		return
	building_render_key = render_key
	building_render_updates += 1
	defence_perch.refresh(state.buildings)
	hud.minimap.set_buildings(state.buildings)
	var groups := {}
	var placeholders: Array = []
	var altars: Array = []
	var alive := {}
	var wanted_plazas := {}
	asset_count = 0
	building_placements.clear()
	var trade_now := 0
	for building in state.buildings:
		alive[int(building.id)] = true
		trade_now += 1 if building.asset in ["trade_post", "harbour"] else 0
		if building.asset in ["native_marker", "terrain_road"]:
			asset_count += 1
			continue
		if building.asset == "agora_space":
			wanted_plazas[int(building.id)] = true
			add_plaza(building)
			asset_count += 1
			continue
		var center := world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
		var transform := Transform3D(Basis.IDENTITY, center)
		if not overlay_view.building_visible(building):
			# An overlay shows what it is about; everything else lies flat on its footprint.
			transform.basis = Basis.from_scale(Vector3(building.w * .9, .05, building.h * .9))
			placeholders.append(transform)
			continue
		if not model_file_exists(building.asset):
			transform.basis = Basis.from_scale(Vector3(building.w * .88, .28, building.h * .88))
			placeholders.append(transform)
			continue
		asset_count += 1
		transform = building_draw_transform(building)
		if building.asset == "sanctuary_altar" and not bool(building.get("stretch", false)) and int(building.get("grow", 100)) >= 100:
			altars.append({"id": int(building.id), "transform": transform, "key": rite_key(float(building.x) + building.w * .5, float(building.y) + building.h * .5)})
		var group := "%s|%d:%d" % [building.asset, floori(float(building.x) / batch_cells), floori(float(building.y) / batch_cells)]
		if not groups.has(group):
			groups[group] = []
		var constructing: bool=static_batches.construction.active(building)
		var construction_top:=0.0
		if constructing:
			var shape: Dictionary=building_sites.shape(building.asset,static_batches)
			construction_top=transform.origin.y+(float(shape.low)+float(shape.height)*float(building.get("grow",100))*.01)*transform.basis.y.length()
		groups[group].append({"transform":transform,"working":building.get("working",building.get("active",false)),"animation_offset":building.get("animation_offset",0),"constructing":constructing,"construction_top":construction_top})
		building_placements["%d,%d" % [int(building.x), int(building.y)]] = {"asset": str(building.asset), "transform": transform}
		if building.has("bays") and overlay_view.building_visible(building):
			var cell_x := floori(float(building.x) / batch_cells)
			var cell_y := floori(float(building.y) / batch_cells)
			for bay in building.bays:
				var bay_idx: int = int(bay.get("bay", -1))
				var good_name: String = str(bay.get("good", ""))
				if bay_idx < 0 or good_name.is_empty():
					continue
				var bay_model := ""
				var local_tf := Transform3D.IDENTITY
				if building.asset == "granary":
					bay_model = "granary_food_" + good_name
					local_tf = Transform3D(Basis(Vector3.UP, bay_idx * PI / 4.0), GRANARY_DRUM_CENTER)
				elif building.asset == "warehouse":
					if bay_idx < WAREHOUSE_BAYS.size():
						bay_model = "good_" + good_name
						local_tf = Transform3D(Basis.IDENTITY, WAREHOUSE_BAYS[bay_idx])
				elif building.asset == "trade_post":
					if bay_idx < TRADE_POST_BAYS.size():
						bay_model = "good_" + good_name
						local_tf = Transform3D(Basis.IDENTITY, TRADE_POST_BAYS[bay_idx])
				if not bay_model.is_empty() and model_file_exists(bay_model):
					var bay_tf := transform * local_tf
					var good_group := "%s|%d:%d" % [bay_model, cell_x, cell_y]
					if not groups.has(good_group):
						groups[good_group] = []
					groups[good_group].append({"transform": bay_tf})
	groups["__footprint"] = placeholders
	for id in plaza_nodes.keys():
		if not wanted_plazas.has(id):
			plaza_nodes[id].free()
			plaza_nodes.erase(id)
	for id in building_draw_cache.keys():
		if not alive.has(id): building_draw_cache.erase(id)
	static_batches.rebuild(groups)
	building_sites.refresh(state.buildings,self)
	altar_fires.refresh(altars)
	if overlay_view.active():
		overlay_view.redraw()
	# A trade post uses up its partner (and removing one frees it): the menu follows.
	if trade_now != trade_buildings:
		trade_buildings = trade_now
		if hud.build_menu != null and core.simulation != null:
			refresh_catalog()
			# A removed post leaves the map at once but frees its partner on the next simulation step: ask again.
			get_tree().create_timer(1.5).timeout.connect(refresh_catalog)

# Inventory/work changes retain the exact placement. Geometry, growth, facing,
# road edits and elevation invalidate it before rebuilding the existing batches.
func building_draw_transform(building: Dictionary) -> Transform3D:
	if int(building.get("grow",100))<100 and static_batches.construction.eligible(str(building.asset)):
		static_batches.template(str(building.asset))
	var id := int(building.id)
	var key := [building.asset, building.x, building.y, building.w, building.h,
		building.altitude, building.get("orientation", 0), building.get("stretch", false),
		building.get("grow", 100), placement_revision, origin, extent]
	var cached: Dictionary = building_draw_cache.get(id, {})
	if cached.get("key") == key: return cached.transform
	var center := world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
	var facing := StreetFacing.facing(tiles, str(building.asset), int(building.x), int(building.y), int(building.w), int(building.h), int(building.get("orientation", 0)))
	var transform := Transform3D(model_basis(building.asset, building.w, building.h, facing), center)
	if str(building.asset).begins_with("sanctuary_court_"):
		transform.origin.y = flat_floor_height(building, transform.origin.y)
	if str(building.asset).begins_with("pyramid_"):
		transform.basis = transform.basis * Basis.from_scale(Vector3(1.0, PYRAMID_RISE, 1.0))
	if bool(building.get("stretch", false)):
		transform.basis = transform.basis * Basis.from_scale(Vector3(building.w, 1.0, building.h))
	elif int(building.get("grow", 100)) < 100 and not static_batches.construction.active(building):
		transform.basis = transform.basis * Basis.from_scale(Vector3(1.0, maxf(float(building.grow) * .01, .12), 1.0))
	if not bool(building.get("stretch", false)):
		transform = StreetSetback.apply(tiles, building, transform)
	building_draw_cache[id] = {"key": key, "transform": transform}
	return transform

const FLAT_FLOOR_LIFT := .015

# The height for a flat floor piece: its own, or the highest terrain under its corners and centre if that is higher, plus a little.
func flat_floor_height(building: Dictionary, own: float) -> float:
	var top := own
	var x0 := float(building.x) - .45
	var y0 := float(building.y) - .45
	var x1 := float(building.x) + float(building.w) - .55
	var y1 := float(building.y) + float(building.h) - .55
	for point in [Vector2(x0, y0), Vector2(x1, y0), Vector2(x0, y1), Vector2(x1, y1), Vector2((x0 + x1) * .5, (y0 + y1) * .5)]:
		if tiles.has(Vector2i(roundi(point.x), roundi(point.y))):
			top = maxf(top, terrain_geometry.height_at(point.x, point.y))
	return top + FLAT_FLOOR_LIFT

# An empty vendor space is a pale paved square a little above the ground, following the terrain like a footprint.
func add_plaza(building: Dictionary) -> void:
	if plaza_material == null:
		plaza_material = material(Color(.80, .72, .56))
		plaza_material.roughness = .95
	var id := int(building.id)
	var slab: MeshInstance3D = plaza_nodes.get(id)
	if slab == null:
		slab = MeshInstance3D.new()
		slab.mesh = BoxMesh.new()
		slab.material_override = plaza_material
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plazas.add_child(slab)
		plaza_nodes[id] = slab
	var size := Vector3(building.w - .06, .06, building.h - .06)
	if slab.mesh.size != size: slab.mesh.size = size
	var position := world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude) + Vector3.UP * .03
	if slab.position != position: slab.position = position

func update_walkers() -> void:
	var alive := {}
	var rites := {}
	for walker in state.walkers:
		var id := int(walker.id)
		alive[id] = true
		var target := walker_world_position(walker)
		var cell := Vector2i(floori(walker.x),floori(walker.y))
		var native_tile: Array = tiles.get(cell,[])
		var offset := (float(walker.altitude)-float(native_tile[2]))*.22 if not native_tile.is_empty() else 0.0
		var perch: Dictionary = defence_perch.roof(walker)
		# Use the Godot model's roof instead of the retained SDL sprite height.
		offset += DefencePerch.lift(perch, float(walker.get("lift", 0.0)))
		# The parts of a rite on an altar stand around its centre, on the ground or on the table (altar_rite.gd).
		if walker.has("scene"):
			target += AltarRite.offset(walker)
			offset += AltarRite.lift(walker)
			if str(walker.role) == "priestess":
				rites[rite_key(float(walker.x), float(walker.y))] = true
		if walkers.has(id) and walkers[id].asset != walker.asset:
			# Wool growth and native role changes keep the entity ID, but change its model.
			citizen_lod.drop(walkers[id])
			walkers[id].node.queue_free()
			walkers.erase(id)
		if not walkers.has(id):
			var node := AltarRite.goods_node() if str(walker.asset) == "sacrifice_goods" else model(CitizenVariety.model_name(str(walker.asset), id))
			if node == null:
				node = MeshInstance3D.new()
				var marker := SphereMesh.new()
				marker.radius = .08; marker.height = .16
				node.mesh = marker
				node.material_override = material(Color(.88, .68, .38))
			world.add_child(node)
			node.position = target
			node.rotation.y = deg_to_rad(-180.0 + int(walker.get("orientation", 0)) * 45.0)
			var morphs: Array = node.get_meta("vat_parts") if node.has_meta("vat_parts") else []
			if morphs.is_empty():
				collect_morphs(node, morphs)
			walkers[id] = new_walker_entry(node, str(walker.asset), int(walker.get("type", -1)), target, offset, morphs)
			CitizenVariety.apply(node, str(walker.asset), int(id))
			walkers[id].action = int(walker.get("action", 1))
			walkers[id].facing = int(walker.get("orientation", 0))
			if walker.has("scene"):
				walkers[id].roll = AltarRite.roll(walker)
				AltarRite.dress(node, walker)
			walker_streets.dress(walkers[id])
		var entry: Dictionary = walkers[id]
		entry.perch = perch
		# What the core says the walker is doing (fight and die clips) and which way it faces.
		entry.action = int(walker.get("action", 1))
		entry.facing = int(walker.get("orientation", 0))
		entry.field_load = int(walker.get("field_load", 0))
		entry.field_task = str(walker.get("field_task", ""))
		entry.selectable = bool(walker.get("selectable", false))
		# A cart, or an ox cart's trailer, shows its load (cart_cargo.gd).
		if CartCargo.BEDS.has(entry.asset):
			CartCargo.update(self, entry, walker)
		var shown: bool = overlay_view.walker_visible(entry.type)
		if entry.node.visible != shown:
			entry.node.visible = shown
		entry.from = entry.native_position
		entry.to = target
		entry.from_offset = entry.offset
		entry.to_offset = offset
		entry.age = 0.0
	for id in walkers.keys():
		if not alive.has(id):
			citizen_lod.drop(walkers[id])
			walkers[id].node.queue_free()
			walkers.erase(id)
	altar_fires.burn(rites)
	trireme_orders.refresh(self)

# The record of a drawn walker: where it is going, its pose state and what kind of figure it is. The character
# window (ui/character_panel.gd) makes one for its portrait so the same idle pose and god float apply there.
func new_walker_entry(node: Node3D, asset: String, type: int, target: Vector3, offset: float, morphs: Array) -> Dictionary:
	return {"node": node, "from": target, "to": target, "native_position":target,"from_offset":offset,"to_offset":offset,"offset":offset,"age": 0.0, "travel": 0.0, "idle": 0.0, "morphs": morphs, "asset": asset, "waterborne":asset in ["fishing_boat","trade_ship","trireme","enemy_boat"], "type": type, "human": model_contract(asset).has("character"), "lod_role": not citizen_lod.crowd_asset(asset).is_empty(), "skeletal": null, "god": GodFloat.is_god(asset), "moving": false, "walk_weight":0.0, "still_time":WalkerMotion.GAP_HOLD, "clips": WalkerCombat.clips(morphs), "action": 1, "facing": 0}

# Which altar a rite is on: the altar's centre (a corner tile plus half its size) in half tiles, as the building's and the scene's records give it.
func rite_key(x: float, y: float) -> Vector2i:
	return Vector2i(roundi(x * 2.0), roundi(y * 2.0))

func collect_morphs(node: Node, result: Array) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh and node.mesh.get_blend_shape_count() > 0:
		# "lit" remembers which shapes carry a weight so the next frame can clear them.
		result.append({"node": node, "table": morph_table(node.mesh), "lit": []})
	for child in node.get_children():
		collect_morphs(child, result)

# Maps every frame name of a mesh to its stored shape. The GLB optimizer merges identical
# poses into one shape named "idle_00|idle_01|...", so one shape can answer several frames.
func morph_table(mesh: ArrayMesh) -> Dictionary:
	if not morph_tables.has(mesh):
		var table := {}
		for index in mesh.get_blend_shape_count():
			for alias in String(mesh.get_blend_shape_name(index)).split("|"):
				table[alias] = index
		morph_tables[mesh] = table
	return morph_tables[mesh]

func animate_walker(entry: Dictionary, dt: float, moved: float) -> void:
	if entry.get("god", false):
		# A god floats instead of walking (god_float.gd): it hovers, leans and sways, and holds its idle pose however far it travels.
		GodFloat.update(entry, dt, moved)
		moved = 0.0
	if WalkerCombat.animate(entry, dt):
		return
	if entry.get("human",false) or entry.get("lod_role",false):
		WalkerMotion.advance(entry, dt, moved)
	else:
		entry.travel += moved
		entry.idle += dt
		entry.moving = moved > .00001
	if entry.get("skeletal") != null:
		entry.skeletal.get_meta("skeletal_citizen").sample(dt, moved, orbit.camera.global_position.distance_to(entry.node.global_position), entry.walk_weight)
		# Keep the hidden crowd pose current too: releasing a pooled skeleton must not show a stale frame.
	if entry.morphs.is_empty():
		return
	var blend: float = entry.walk_weight if entry.get("human", false) or entry.get("lod_role", false) else (1.0 if moved > .00001 else 0.0)
	var walk_phase: float = fposmod(entry.travel / WalkerMotion.STRIDE * 24.0, 24.0)
	var idle_phase: float = fposmod(entry.idle / 3.0 * 12.0, 12.0)
	for morph in entry.morphs:
		var node: MeshInstance3D = morph.node
		var walk := pose_pair(morph.table, WALK_FRAMES, walk_phase) if blend > 0 else Vector3(-1,-1,0)
		var idle := pose_pair(morph.table, IDLE_FRAMES, idle_phase) if blend < 1 else Vector3(-1,-1,0)
		if morph.has("vat"):
			# No per-instance meshes: the GPU blends both clips during acceleration and stopping.
			if blend > 0.0 and morph.get("pose") != walk:
				node.set_instance_shader_parameter("vat_pose", walk)
				morph.pose = walk
			if blend < 1.0 and morph.get("idle_pose") != idle:
				node.set_instance_shader_parameter("vat_idle_pose", idle)
				morph.idle_pose = idle
			if morph.get("blend", -1.0) != blend:
				node.set_instance_shader_parameter("vat_walk_blend", blend)
				morph.blend = blend
			continue
		for index in morph.lit:
			node.set_blend_shape_value(index, 0.0)
		morph.lit.clear()
		# Accumulate shared aliases across both clips before assigning normalized weights.
		var weights := {}
		add_pose_weights(weights, walk, blend)
		add_pose_weights(weights, idle, 1.0-blend)
		for index in weights:
			node.set_blend_shape_value(index, weights[index])
			morph.lit.append(index)

func pose_pair(table: Dictionary, frames: Array, phase: float) -> Vector3:
	var first := int(floorf(phase))
	var a := int(table.get(frames[first], -1))
	var b := int(table.get(frames[(first+1)%frames.size()], -1))
	return Vector3(a, b, 0.0 if a == b else fposmod(phase, 1.0))

func add_pose_weights(weights: Dictionary, pair: Vector3, blend: float) -> void:
	for item in [[int(pair.x), (1.0-pair.z)*blend], [int(pair.y), pair.z*blend]]:
		if item[0] >= 0 and item[1] > 0:
			weights[item[0]] = weights.get(item[0], 0.0) + item[1]

func walker_heading(direction: Vector3) -> float:
	# Blender +Y forward becomes Godot -Z in the Y-up GLB export.
	return atan2(-direction.x, -direction.z)

# The tile in the middle of the view: where the ambient sound is drawn from (a little scatter is added there).
func ambient_tile() -> Vector2i:
	var point := tile_coordinates(orbit.target)
	return Vector2i(roundi(point.x), roundi(point.y))

# Chooses a city overlay ("normal" for none): the core is asked what it shows, buildings outside it lie flat, walkers
# outside it are hidden, and the HUD names it. Choosing the active one again goes back to the normal view (the SDL toggle).
func set_overlay(id: String, toggle := false) -> void:
	if not Overlays.MODES.has(id):
		return
	if toggle and id == overlay_view.mode:
		id = "normal"
	if not overlay_view.set_mode(core, id):
		return
	apply_overlay_visibility()
	hud.set_overlay(id)
	hint.text = tr(Overlays.MODES[id][0]) if id != "normal" else tr("Normal view")

# Re-applies the overlay's filters to the buildings (a rebuild of the batches) and to every walker.
func apply_overlay_visibility() -> void:
	building_signature = 0
	update_buildings()
	farm_crops.refresh(state.get("farm_crops",[]),self)
	for entry in walkers.values():
		entry.node.visible = overlay_view.walker_visible(entry.type)

# The episode's objectives are read from the core every couple of seconds; a finished episode shows its result once.
func update_goals(dt: float) -> void:
	if world_map.visible or world_flight.busy(): return
	goals_age += dt
	if goals_age < 2.0 or core.simulation == null:
		return
	goals_age = 0.0
	var episode: Dictionary = core.query("episode")
	if episode.has("error"):
		return
	hud.set_goals(episode)
	var met := int(episode.get("met", 0))
	if met > goals_met and goals_met >= 0 and not episode.get("finished", false):
		message_log.record({"id": -100000-met, "kind": "objectiveComplete", "title": tr("Objective complete"), "text": str(episode.goals[met-1].text) if met<=episode.goals.size() else ""}, hud.date_label.text, false)
		if hud.message_panel.visible:
			message_log.mark_read(); hud.set_messages(message_log.entries)
		hud.set_unread(message_log.unread)
	goals_met = met
	if episode.get("finished", false) and not episode_reported:
		# The campaign screens take over: the result, then what the campaign offers next (episode_overlay.gd).
		episode_reported = true
		episode_overlay.show_result(episode)

# Reserves the goods of a "set aside" objective (the SDL goals window's button) and refreshes the panel.
func set_aside(index: int) -> void:
	var answer: Dictionary = core.query("set_aside %d" % index)
	if answer.has("error"):
		hint.text = reason_text(str(answer.error))
		return
	# Rebuilt after the button's own signal has finished (the button is one of the lines being replaced).
	hud.set_goals.call_deferred(answer)
	hint.text = tr("The goods are set aside")

# The campaign moved to another episode (perhaps another city): the scene restarts and takes the session over.
func switch_session() -> void:
	Engine.set_meta("ezeus_simulation", core.simulation)
	Engine.set_meta("ezeus_language", language)
	core.simulation = null
	core.connected = false
	get_tree().reload_current_scene.call_deferred()

func current_scene_is_city() -> bool:
	return is_inside_tree() and get_tree().current_scene == self

# Leaves the city for the start menu. The core closes with the scene; saving first is the player's choice.
func return_to_start() -> void:
	var loading := LoadingScreen.current(get_tree())
	if loading != null:
		loading.dismiss()
	Engine.set_meta("ezeus_language", language)
	get_tree().change_scene_to_file.call_deferred(START_MENU)

func _process(dt: float) -> void:
	update_goals(dt)
	# An open monster card follows the monsters (where they are) and the hero (hall built, summoned, arrived).
	if monster_card != null and monster_card.visible:
		monster_card_age += dt
		if monster_card_age >= 1.0:
			refresh_monster_card()
	army_view.process(dt)
	GameAudio.ambient_tick(dt, core, ambient_tile())
	if overlay_view.tick(dt, core):
		apply_overlay_visibility()
	static_batches.activity.advance(dt)
	monster_effects.advance(dt)
	thrown_shots.advance(dt)
	water_life.advance(dt)
	frame_count += 1
	if frame_count == 300:
		print("GODOT_PERFORMANCE fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " frame=", frame_count)
	if validate and state.is_empty() and Time.get_ticks_msec() - started_at > 20000:
		print("GODOT_VALIDATION FAIL no live core snapshot within 20 seconds")
		get_tree().quit(1)
	for entry in walkers.values():
		entry.age += dt
		var before: Vector3 = entry.native_position
		var shown_before: Vector3 = entry.node.position
		var weight := clampf(entry.age/.1,0,1)
		entry.native_position = entry.from.lerp(entry.to,weight)
		entry.offset = lerpf(entry.from_offset,entry.to_offset,weight)
		var delta: Vector3 = entry.native_position - before
		var lane: Vector3 = walker_streets.lane(entry, delta, dt, self)
		if not entry.get("perch", {}).is_empty():
			entry.node.position = defence_perch.position(entry.native_position, entry.perch, self)
		else:
			entry.node.position = walker_draw_position(entry, lane)
		if delta.length_squared() > .00000001:
			if entry.get("god", false):
				entry.node.rotation.y = GodFloat.heading(entry.node.rotation.y, delta, dt)
			elif entry.get("human", false) or entry.get("lod_role", false):
				# On wide roads face the actual bounded lane motion rather than sliding
				# sideways while turning. Native route distance still drives the gait.
				var shown_delta: Vector3 = entry.node.position-shown_before if entry.get("wide_road", false) else delta
				entry.node.rotation.y = WalkerMotion.heading(entry.node.rotation.y, shown_delta, dt)
			else:
				entry.node.rotation.y = walker_heading(delta)
		elif WalkerCombat.fighting(entry):
			WalkerCombat.face(entry, dt)
		if entry.has("roll"):
			entry.node.rotation.z = entry.roll
		animate_walker(entry, dt, WalkerMotion.planar_distance(delta))
		water_life.animate_gatherer(entry, self)
	water_life.update_workers(self)
	wolf_attacks.update(self, dt)
	walker_streets.hover(self)
	if frame_count % CitizenLod.CHECK_FRAMES == 0 and not walkers.is_empty():
		citizen_lod.update(walkers, orbit.camera.global_position, static_batches, models)
	if not state.is_empty():
		if not world_map.visible and city_switch.city != null:
			city_switch.update(dt)
		if route_editor.city != null:
			route_editor.update(dt)
		if house_card.city != null:
			house_card.update(dt)
		placement_age += dt
		inspection_age += dt
		if inspection_age >= .5:
			refresh_inspection()
		if state.get("running", false):
			autosave_age += dt
			if autosave_interval > 0.0 and autosave_age >= autosave_interval:
				autosave()
		if road_drag.active:
			road_drag.age += dt
			# A release over the interface never reaches _unhandled_input, so the held button is checked too.
			if road_drag.guard and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				road_drag.finish(self, picked if tiles.has(picked) else Vector2i(99999, 99999))
		# While a test drives a drag (guard off), the pointer is the test's own: the real mouse must not move the drag's end.
		if get_viewport().gui_get_hovered_control() == null and (road_drag.guard or not road_drag.active):
			pick_tile(get_viewport().get_mouse_position())
		else:
			preview.visible = false
			ghost.visible = false
			sanctuary_ghost.visible = false
			footprint_cells.visible = false
		if frame_count % 6 == 0 and hud.minimap.is_visible_in_tree():
			hud.minimap.set_view(view_footprint())
			hud.minimap.set_camera(tile_coordinates(orbit.target), orbit.yaw)
		if frame_count % 12 == 0:
			send_view_box()
		if frame_count % 30 == 0:
			update_details()
		if validate and not checks_started and frame_count > 40:
			checks_started = true
			run_checks()
		elif not view_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_view_bounds.gd").new().run(self, view_review)
		elif not terrain_review.is_empty() and not captured and frame_count > 80:
			captured = true
			var reviewer := preload("res://scripts/review_terrain.gd").new()
			await reviewer.run(self, terrain_review)
		elif not garden_review.is_empty() and not captured and frame_count > 80:
			captured = true
			var reviewer := preload("res://scripts/review_gardens.gd").new()
			await reviewer.run(self, garden_review)
		elif not sanctuary_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_sanctuaries.gd").new().run(self, sanctuary_review)
		elif not controls_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_controls.gd").new().run(self, controls_review)
		elif not objectives_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_objectives.gd").new().run(self, objectives_review)
		elif not street_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_street.gd").new().run(self)
		elif not attack_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_attack.gd").new().run(self, attack_review)
		elif not rite_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_rites.gd").new().run(self, rite_review)
		elif not pyramid_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_pyramids.gd").new().run(self, pyramid_review)
		elif Engine.has_meta("ezeus_cities_review") and not captured and frame_count > 120:
			captured = true
			Engine.remove_meta("ezeus_cities_review")
			await preload("res://scripts/review_menu_rest.gd").new().run(self, "cities")
		elif not menu_rest_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_menu_rest.gd").new().run(self, menu_rest_review)
		elif not character_review.is_empty() and not captured and frame_count > 80:
			captured = true
			await preload("res://scripts/review_characters.gd").new().run(self, character_review, character_subjects)
		elif asset_review and not captured and frame_count > 180:
			captured = true
			review_city_models()
		elif not capture_path.is_empty() and not validate and not captured and frame_count > 180 and Time.get_ticks_msec() - started_at > 2500:
			captured = true
			capture()

# The developer overlay (F3): frame rate, camera and model coverage. Players do not see it.
func update_details() -> void:
	if hud == null or not hud.debug_panel.visible or state.is_empty():
		return
	details.text = tr("%d° orbit  •  %d FPS  •  %d / %d city objects covered  •  %d tiles") % [roundi(orbit.yaw), Engine.get_frames_per_second(), asset_count, state.buildings.size(), tiles.size()]

func walker_world_position(walker: Dictionary) -> Vector3:
	# Native local positions range 0..1; Godot integer tile coordinates are centers.
	return world_position(float(walker.x)-.5,float(walker.y)-.5,walker.altitude)

func walker_surface_position(native_position: Vector3, native_offset: float, uses_bridge := true) -> Vector3:
	var result := native_position
	var x := native_position.x+origin.x+(extent.x-1)*.5
	var y := -native_position.z+origin.y+(extent.y-1)*.5
	if tiles.has(Vector2i(roundi(x),roundi(y))):
		result.y = (terrain_bridges.height_at(x,y) if uses_bridge else terrain_geometry.height_at(x,y))+native_offset
	return result

func walker_draw_position(entry: Dictionary, lane: Vector3) -> Vector3:
	var track: Vector3 = entry.native_position + lane
	if entry.get("surface_track") != track or entry.get("surface_offset") != entry.offset or entry.get("surface_revision", -1) != surface_revision:
		entry.surface_position = walker_surface_position(track, entry.offset, not entry.waterborne)
		entry.surface_track = track
		entry.surface_offset = entry.offset
		entry.surface_revision = surface_revision
	var supported: Vector3=entry.surface_position
	supported.y+=walker_contact.lift(entry,supported,self)
	return supported

func review_city_models() -> void:
	# Explicit verification mode only; ordinary launches retain player camera controls.
	core.query("pause 1")
	orbit.enabled = false
	for subject in ["overview", "palace", "museum", "common_house_6a", "sanctuary_temple_0", "transporter", "fishing_boat", "animal_sheep_nude"]:
		var moving_subject: bool = subject in ["transporter", "fishing_boat", "animal_sheep_nude"]
		if subject == "overview":
			orbit.target = Vector3.ZERO
			orbit.distance = maxf(extent.x, extent.y) * .95
		elif moving_subject:
			for walker in state.walkers:
				if walker.asset == subject:
					orbit.target = walker_world_position(walker)
					orbit.distance = 6.0
					break
			core.query("pause 0")
		else:
			for building in state.buildings:
				if building.asset == subject:
					orbit.target = world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
					orbit.distance = 22.0 if subject != "common_house_6a" else 12.0
					break
		for angle in [45, 135, 225, 315]:
			orbit.yaw = angle
			orbit.refresh()
			await get_tree().create_timer(.6).timeout
			await RenderingServer.frame_post_draw
			var path := "res://captures/models-%s-%d.png" % [subject, angle]
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print("MODEL_REVIEW ", subject, " yaw=", angle, " fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		core.query("pause 1")
	get_tree().quit()

func pick_tile(screen: Vector2) -> void:
	var query := PhysicsRayQueryParameters3D.create(orbit.camera.project_ray_origin(screen), orbit.camera.project_ray_origin(screen) + orbit.camera.project_ray_normal(screen) * 2000)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		# A tiny screen offset resolves shared triangle edges on curved ramps.
		for offset in [Vector2(.04,.02),Vector2(-.04,-.02)]:
			var point: Vector2 = screen+offset
			query.from = orbit.camera.project_ray_origin(point)
			query.to = query.from+orbit.camera.project_ray_normal(point)*2000
			hit = get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty():
				break
	preview.visible = false
	ghost.visible = false
	sanctuary_ghost.visible = false
	footprint_cells.visible = road_drag.active
	var position: Vector3
	if hit.is_empty():
		# Concave triangle rays can miss a shared edge at exact tile centers.
		# The conservative plane fallback is for level native ground only.
		var best := INF
		var found := false
		for height in terrain_levels:
			var point = orbit.ground_point(screen, float(height) * .22)
			if point == null:
				continue
			var cell := Vector2i(roundi(point.x + origin.x + (extent.x - 1) * .5), roundi(-point.z + origin.y + (extent.y - 1) * .5))
			if not tiles.has(cell) or int(tiles[cell][2]) != int(height) or terrain_geometry.sloped(cell):
				continue
			var distance: float = orbit.camera.global_position.distance_squared_to(point)
			if distance < best:
				best = distance
				position = point
				found = true
		if not found:
			picked = Vector2i(99999, 99999)
			hud.set_placement_feedback("",false,false)
			return
	else:
		position = hit.position
	picked = Vector2i(roundi(position.x + origin.x + (extent.x - 1) * .5), roundi(-position.z + origin.y + (extent.y - 1) * .5))
	if road_drag.active and tiles.has(picked):
		road_drag.update(self, picked)
		return
	if not tiles.has(picked) or mode == "select" or demolition_dialog.visible:
		hud.set_placement_feedback("",false,false)
		ghost.visible = false
		sanctuary_ghost.visible = false
		footprint_cells.visible = false
		return
	refresh_placement()

func _unhandled_input(event: InputEvent) -> void:
	# The centered request owns city input; its Escape/fold controls never submit a reply.
	if hud.decision_expanded: return
	if world_flight.busy(): return
	if editor_panel != null and editor_panel.input(event):
		get_viewport().set_input_as_handled()
		return
	# The atlas owns the city keys; audio's existing shortcut remains available.
	if world_map.visible and not (event is InputEventKey and event.physical_keycode == KEY_M): return
	if get_tree().root.get_node("UiAccess").dialog_open:return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if not is_instance_valid(escape_menu) and not episode_overlay.visible:
			for action in KeyBindings.DOCK_ACTIONS:
				if KeyBindings.matches(event,action):
					hud.activate_dock_action(action)
					get_viewport().set_input_as_handled()
					return
		# The keys the player may rebind (scripts/key_bindings.gd); Escape, Delete and the mouse stay as they are.
		if KeyBindings.matches(event, "pause"):
			core.send("pause %d" % (0 if state.get("paused", true) else 1))
		if KeyBindings.matches(event, "quick_save"):
			game_action("quick_save")
		if KeyBindings.matches(event, "quick_load"):
			game_action("quick_load")
		if KeyBindings.matches(event, "mute"):
			GameAudio.set_muted(not GameAudio.muted())
			hint.text = tr("Sound off") if GameAudio.muted() else tr("Sound on")
		if KeyBindings.matches(event, "world_map"):
			game_action("world")
		if KeyBindings.matches(event, "details"):
			hud.debug_panel.visible = not hud.debug_panel.visible
			update_details()
		if KeyBindings.matches(event, "army"):
			game_action("army")
		if KeyBindings.matches(event, "mythology"):
			game_action("mythology")
		if KeyBindings.matches(event, "city"):
			game_action("city")
		if KeyBindings.matches(event, "camera_home") and not (hud._header_has_focus() or hud.toolbar_has_focus()):
			orbit.overview(extent)
		if KeyBindings.matches(event, "turn_placement"):
			turn_placement(1)
		if KeyBindings.matches(event, "demolish") or event.physical_keycode == KEY_DELETE:
			set_tool("demolish")
		if KeyBindings.matches(event, "undo"):
			core.send("undo")
		if KeyBindings.matches(event, "fullscreen"):
			PlaySettings.set_fullscreen(not PlaySettings.is_fullscreen())
		var overlay: String = KeyBindings.overlay_for(event)
		if overlay != "":
			set_overlay(overlay, true)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and road_drag.active:
		road_drag.cancel(self)
		update_hint()
		return
	# The selection box: dragging with the selection tool, finished on release.
	if event is InputEventMouseMotion and unit_selection.pressing and mode == "select":
		unit_selection.drag(self, event.position)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and unit_selection.pressing:
		if unit_selection.release(self, event.position):
			return
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and road_drag.active:
		pick_tile(event.position)
		road_drag.finish(self, picked if tiles.has(picked) else Vector2i(99999, 99999))
		return
	# Route editing takes the map's clicks: a left click on a road adds a guide (or takes one away), the right button closes it.
	if route_editor.active and event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and mode == "select":
		if event.button_index == MOUSE_BUTTON_RIGHT:
			route_editor.end()
			update_hint()
		else:
			pick_tile(event.position)
			if tiles.has(picked) and not route_editor.toggle(picked):
				hint.text = reason_text("command_queue_full")
		get_viewport().set_input_as_handled()
		return
	# A group chosen with a box goes there together (the SDL view's right click on a selection).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and mode == "select" and unit_selection.has_group(self):
		pick_tile(event.position)
		if tiles.has(picked):
			hint.text = tr("The chosen units are on their way.") if unit_selection.order(self, picked) else reason_text("command_queue_full")
		return
	# A selected trireme sails to the water under the pointer (the SDL view's right click).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and mode == "select" and trireme_orders.selected >= 0:
		pick_tile(event.position)
		if tiles.has(picked):
			if trireme_orders.order(self, picked):
				hint.text = tr("The trireme sails there.")
			else:
				hint.text = reason_text("command_queue_full")
		return
	# As in the SDL view, the right button sends the selected company's banner to the tile under the pointer.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and mode == "select" and army_panel.visible and army_panel.selected_id >= 0:
		pick_tile(event.position)
		if tiles.has(picked):
			army_order("banner_move %d %d %d" % [army_panel.selected_id, picked.x, picked.y])
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Raycast at click time, not the previous frame's cursor tile.
		pick_tile(event.position)
		if not tiles.has(picked):
			return
		if (mode == "road" or mode == "wall" or mode == "demolish" or mode in RoadDrag.AREA_TOOLS or mode in RoadDrag.PATH_TOOLS) and not demolition_dialog.visible:
			road_drag.begin(self, picked, mode)
			return
		if mode == "select":
			unit_selection.press(self, event.position)
			if unit_selection.has_group(self):
				unit_selection.clear(self)
			if placing_banner >= 0:
				place_banner(picked)
				return
			# A click on one of the player's triremes selects it for orders; any other click lets it go.
			var trireme := trireme_orders.trireme_at(self, picked)
			if trireme >= 0:
				trireme_orders.select(self, trireme)
				close_inspection()
				hint.text = tr("Trireme selected  •  right-click the water to send it  •  Escape lets it go")
				return
			trireme_orders.clear()
			var banner_id := army_view.banner_at(picked)
			if banner_id >= 0:
				# A banner is selected, not the ground under it: the army panel takes the inspector's place.
				close_inspection()
				if not army_panel.visible:
					open_army()
				army_panel.select(banner_id)
				return
			if army_panel.visible:
				army_panel.close()
			inspected = picked
			refresh_inspection()
			if inspected != Vector2i(99999, 99999):
				GameAudio.request_building_sound(core, picked)
		else:
			placement_key = ""
			refresh_placement()
			if not placement_result.get("valid", false):
				return
			core.send("build %s %d %d %d%s" % [mode, placement_cell.x, placement_cell.y, orientation, partner_suffix()])
			# A trade post is built for one partner: the tool ends with the placement, as in the SDL view.
			if mode in ["trade_post", "pier"]:
				set_tool("select")

# A press and release on one tile in the demolition tool: the single-tile demolition, which asks first for a landmark or stocked
# market. A dragged rectangle is `RoadDrag`'s (`demolish_area`). Returns true when something was sent or asked.
func demolish_click(cell: Vector2i) -> bool:
	if tiles.has(cell):
		picked = cell
	placement_key = ""
	refresh_placement()
	if not placement_result.get("valid", false):
		return false
	if placement_result.confirmation_required:
		demolition_request = "demolish %d %d 1 %d" % [cell.x, cell.y, int(placement_result.target_token)]
		hud.set_demolition_area(false)
		open_demolition_dialog(tr("This removes the complete landmark or stocked market. Cost: %d. Demolition cannot be undone.") % int(placement_result.cost))
		return true
	return core.send("demolish %d %d 0 %d" % [cell.x, cell.y, int(placement_result.target_token)])

# A dragged rectangle holding landmarks or stocked markets: remove everything, spare those, or keep all.
func ask_area_demolition(area: String, plan: Dictionary) -> void:
	demolition_request = "demolish_area %s 1 %d" % [area, int(plan.target_token)]
	demolition_spare_request = "demolish_area %s 0" % area
	hud.set_demolition_area(true)
	var text := tr("This area holds %d landmarks or stocked markets. Demolishing everything costs %d; sparing them costs %d. Demolition cannot be undone.")
	open_demolition_dialog(text % [int(plan.protected), int(plan.cost), int(plan.cost_spared)])

# The city stands still while the player decides.
func open_demolition_dialog(text: String) -> void:
	demolition_was_running = not state.get("paused", true)
	if demolition_was_running:
		core.send("pause 1")
	demolition_dialog.dialog_text = text
	demolition_dialog.popup_centered(Vector2i(470, 180))

func capture() -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(capture_path)
	print("GODOT_CAPTURE ", capture_path, " result=", error)

func check(condition: bool, message: String) -> bool:
	print("GODOT_CHECK ", "PASS " if condition else "FAIL ", message)
	return condition

# The windowed validation (--validate) lives in validate_main.gd.
func run_checks() -> void:
	await preload("res://scripts/validate_main.gd").new().run(self)

# Right-click goes back from city surfaces; an offered decision Postpone is an explicit reply.
func right_click_city(event: InputEventMouseButton) -> bool:
	if is_instance_valid(city_help) and city_help.visible and city_help.card.get_global_rect().has_point(event.position):
		city_help.hide();get_viewport().set_input_as_handled();return true
	if world_flight.busy() or world_map.visible or episode_overlay.visible: return false
	if is_instance_valid(escape_menu) or get_tree().root.get_node("UiAccess").dialog_open: return false
	var popup: PopupMenu=hud.visible_popup()
	if popup != null:
		popup.hide()
		get_viewport().set_input_as_handled()
		return true
	for child in hud.find_children("*", "Window", true, false):
		if child is PopupMenu and child.visible:
			child.hide()
			get_viewport().set_input_as_handled()
			return true
		if child is Window and child.visible: return false
	# Selected armies retain native right-click orders on terrain; clicks on UI go back.
	var army_map_click: bool = mode == "select" and ((army_panel.visible and army_panel.selected_id >= 0 and not army_panel.get_global_rect().has_point(event.position)) or trireme_orders.selected >= 0 or unit_selection.has_group(self)) and not hud.message_panel.visible and not hud.decision_expanded and not hud.get_node("%BuildTray").visible and not hud.get_node("%LayersPanel").visible
	for name in ["EventRail", "ResourceRibbon", "ResourcesReveal", "MinimapPanel", "GoalsPanel", "BottomBar", "MapToggle", "LayersPanel", "TimeBar"]:
		var panel: Control = hud.get_node("%" + name)
		if panel.is_visible_in_tree() and panel.get_global_rect().has_point(event.position): army_map_click = false
	if army_map_click: return false
	if route_editor.active and mode == "select" and not hud.get_node("%LayersPanel").visible and not ui_at(hud, event.position): return false
	get_viewport().set_input_as_handled()
	var decision_icon: Control = hud.get_node("%DecisionReview")
	if hud.decision_expanded or (decision_icon.is_visible_in_tree() and decision_icon.get_global_rect().has_point(event.position)):
		if not postpone_decision(): hud.set_decision_expanded(false)
	elif hud.get_node("%LayersPanel").visible: hud.set_layers_open(false)
	elif hud.message_panel.visible: hud.set_messages_open(false)
	elif hud.get_node("%BuildTray").visible:
		hud.close_build_tray()
		set_tool("select")
	elif road_drag.active: set_tool("select")
	elif placing_banner >= 0: end_banner_placement()
	elif army_panel.visible: army_panel.close()
	elif inspector.visible and walker_at(event.position) < 0: close_inspection()
	elif mode != "select": set_tool("select")
	elif walker_at(event.position) >= 0: open_character(walker_at(event.position))
	elif hud.resources_open:
		hud.set_resources_open(false)
		hud._release_header_focus()
	elif hud.goals_list.visible: hud.set_goals_expanded(false)
	elif hud.get_node("%MinimapPanel").visible: hud.set_minimap_open(false, true)
	elif overlay_view.active(): set_overlay("normal")
	else:
		# Idle right-click inspects the pointed native tile, just like the SDL view.
		pick_tile(event.position)
		if tiles.has(picked):
			inspected = picked
			refresh_inspection()
	return true

func _input(event: InputEvent) -> void:
	# Close Layers before a terrain click can reach a previously selected construction tool.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and hud.get_node("%LayersPanel").visible:
		if not hud.get_node("%LayersPanel").get_global_rect().has_point(event.position) and not hud.overlay_menu.get_global_rect().has_point(event.position):
			hud.set_layers_open(false)
			if not ui_at(hud,event.position):
				get_viewport().set_input_as_handled()
				return
	# The editor's keys (Escape) and its right button (putting a tool down) come before the city's.
	if editor_panel != null and (event is InputEventKey or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT)) and editor_panel.input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if right_click_city(event): return
	if not (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_ESCAPE or event.keycode==KEY_ESCAPE)):return
	if world_flight.busy() or world_map.visible or episode_overlay.visible:return
	if is_instance_valid(escape_menu) or get_tree().root.get_node("UiAccess").dialog_open:return
	for child in hud.get_children():
		if child is Window and child.visible:return
	get_viewport().set_input_as_handled()
	if hud.decision_expanded:hud.set_decision_expanded(false);return
	if hud.get_node("%LayersPanel").visible:hud.set_layers_open(false);return
	if hud.message_panel.visible:hud.set_messages_open(false);return
	if hud.resources_open:hud.set_resources_open(false);hud._release_header_focus();return
	if hud._header_has_focus():hud._release_header_focus();return
	if monster_card != null and monster_card.visible:monster_card.set_open(false);return
	if hud.get_node("%BuildTray").visible:hud.close_build_tray();return
	if road_drag.active:road_drag.cancel(self);update_hint();return
	if route_editor.active:route_editor.end();update_hint();return
	if placing_banner>=0:end_banner_placement();return
	if unit_selection.has_group(self):unit_selection.clear(self);update_hint();return
	if trireme_orders.selected>=0:trireme_orders.clear();update_hint();return
	if army_panel.visible:army_panel.close();return
	if inspector.visible:close_inspection();return
	if is_instance_valid(city_help) and city_help.visible:city_help.hide();return
	if hud.goals_list.visible:hud.set_goals_expanded(false);return
	if mode!="select":set_tool("select");return
	if overlay_view.active():set_overlay("normal");return
	open_escape_menu()

# The walker under the pointer for the character window: the ringed person, or else any other figure (a god, a hero,
# a monster, an animal, a boat) whose middle is near the pointer on screen. -1 when there is none.
func walker_at(point: Vector2) -> int:
	# A walker behind a panel, card or button is not under the pointer.
	if ui_at(hud, point):
		return -1
	if walker_streets.hovered >= 0 and walkers.has(walker_streets.hovered):
		return walker_streets.hovered
	var camera: Camera3D = orbit.camera
	var best := WalkerStreets.HOVER_PIXELS
	var found := -1
	for id in walkers:
		var entry: Dictionary = walkers[id]
		if not entry.node.visible or entry.has("roll") or str(entry.asset) == "sacrifice_goods":
			continue
		var reach: float = entry.get("pick_height", -1.0)
		if reach < 0.0:
			reach = figure_height(entry.node)
			entry.pick_height = reach
		var middle: Vector3 = entry.node.global_position + Vector3.UP * reach * .5
		if camera.is_position_behind(middle):
			continue
		# Big figures are easier to hit: the allowance grows with their size on screen.
		var top := camera.unproject_position(entry.node.global_position + Vector3.UP * reach)
		var foot := camera.unproject_position(entry.node.global_position)
		var gap := camera.unproject_position(middle).distance_to(point) - top.distance_to(foot) * .35
		if gap < best:
			best = gap
			found = id
	return found

# True when a visible interface control that takes the mouse covers the point (pass-through layers do not).
func ui_at(node: Node, point: Vector2) -> bool:
	for child in node.get_children():
		if child is Window or not (child is Control) or not child.visible:
			continue
		if child.mouse_filter != Control.MOUSE_FILTER_IGNORE and child.get_global_rect().has_point(point) and not (child is Container and child.mouse_filter == Control.MOUSE_FILTER_PASS):
			return true
		if ui_at(child, point):
			return true
	return false

func figure_height(node: Node3D) -> float:
	var top := 0.5
	for mesh in node.find_children("*", "VisualInstance3D", true, false):
		var box: AABB = node.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		top = maxf(top, box.end.y)
	return top * node.scale.y

# The character window (ui/character_panel.gd): the core words what the walker says; the city pauses while it is open,
# as the SDL game's window did, and goes on again when it closes if it was running before.
func open_character(walker_id: int) -> void:
	if core.simulation == null:
		return
	var answer: Dictionary = core.query("character_info %d" % walker_id)
	if answer.has("error"):
		return
	open_character_info(answer)

# Opens the window on a `character_info` answer (reviews pass one of their own).
func open_character_info(answer: Dictionary) -> void:
	close_character()
	if inspector.visible: close_inspection()
	var observed: Dictionary = core.simulation.snapshot(false)
	core.snapshot_received.emit(observed)
	character_resume = not observed.get("paused", true)
	character_held_before = core.commands_held
	core.commands_held = true
	if character_resume: core.snapshot_received.emit(core.query("pause 1"))
	character_panel = CharacterPanel.new()
	character_panel.city = self
	character_panel.portrait_source = character_portrait_source
	hud.add_child(character_panel)
	character_panel.closed.connect(close_character)
	character_panel.focus_requested.connect(focus_walker)
	character_panel.show_character(answer)

func close_character() -> void:
	if not is_instance_valid(character_panel):
		return
	var old: Control = character_panel
	character_panel = null
	old.hide()
	old.queue_free()
	get_tree().root.get_node("UiAccess").dialog_open = false
	if character_resume and core.simulation != null: core.snapshot_received.emit(core.query("pause 0"))
	character_resume = false
	core.commands_held = character_held_before

# "Go to": the camera moves over the walker.
func focus_walker(walker_id: int) -> void:
	if walkers.has(walker_id):
		var at: Vector3 = walkers[walker_id].node.global_position
		orbit.target = Vector3(at.x, orbit.target.y, at.z)
		orbit.clamp_target()
		orbit.refresh()

func open_escape_menu() -> void:
	if is_instance_valid(escape_menu) or core.simulation==null:return
	var observed: Dictionary=core.simulation.snapshot(false)
	core.snapshot_received.emit(observed)
	menu_resume=not observed.get("paused",true)
	menu_held_before=core.commands_held
	core.commands_held=true
	if menu_resume:core.snapshot_received.emit(core.query("pause 1"))
	escape_menu=EscapeMenu.new();escape_menu.hud=hud;hud.add_child(escape_menu)
	escape_menu.closed.connect(close_escape_menu)
	escape_menu.language_requested.connect(change_language)
	escape_menu.action_requested.connect(escape_menu_action)

func close_escape_menu() -> void:
	if not is_instance_valid(escape_menu):return
	var old: Control=escape_menu;escape_menu=null
	old.hide();old.queue_free()
	get_tree().root.get_node("UiAccess").dialog_open=false
	if menu_resume and core.simulation!=null:core.snapshot_received.emit(core.query("pause 0"))
	menu_resume=false;core.commands_held=menu_held_before

func escape_menu_action(action: String) -> void:
	if not is_instance_valid(escape_menu):return
	if action in ["world","army","quick_save","quick_load","attention","guide"]:
		close_escape_menu();game_action(action);return
	escape_menu.suspend()
	game_action(action)
	var windows: Array=hud.get_children().filter(func(child):return child is Window and child.visible)
	if windows.is_empty():escape_menu.restore();return
	var window: Window=windows[-1]
	escape_menu.watch(window,window in [hud.save_dialog,hud.load_dialog,hud.menu_dialog])
