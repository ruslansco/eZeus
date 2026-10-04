extends RefCounted
# Presentation grouping of the buildings the embedded core offers.
#
# The core's `buildable` query (presentation/esimulationservice.cpp, `buildSpecs`) is the authority for what can be
# built: names, native display labels, footprints, models, costs and whether the city's culture allows each one.
# This file only decides how the player finds them: the category each name belongs to and its order inside the
# category. A name the core lists but this table does not (a new building) is shown under "Other", and
# validate_buildings.gd fails until it is given a place, so nothing silently disappears from the menu.
#
# Buildings whose native class has no converted Godot model yet ("unconverted") are hidden: placing one would show a
# bare box. Launch with `--placeholders` (or set Engine meta `ezeus_placeholders`) to list them for development.
# Category titles are `tr()` keys (data/ui_strings.csv); building labels are the native English names, also keys.

const CATEGORIES := [
	["Housing and roads", ["house", "elite_house", "road", "roadblock", "bridge"]],
	["Agriculture", ["wheat_farm", "onion_farm", "carrot_farm", "growers_lodge", "orange_tenders_lodge", "hunting_lodge", "carding_shed", "corral", "dairy", "vine", "olive_tree", "orange_tree", "goat", "sheep", "cattle", "fishery", "urchin_quay"]],
	["Industry", ["timber_mill", "masonry_shop", "foundry", "refinery", "olive_press", "winery", "sculpture_studio", "artisans_guild", "black_marble_workshop", "mint", "chariot_factory"]],
	["Storage", ["warehouse", "granary"]],
	["Trade", ["trade_post", "pier"]],
	["Markets", ["common_agora", "grand_agora", "food_vendor", "fleece_vendor", "oil_vendor", "wine_vendor", "arms_vendor", "horse_vendor", "chariot_vendor"]],
	["Health and water", ["hospital", "fountain", "baths"]],
	["Administration and security", ["palace", "tax_office", "maintenance_office", "watchpost", "armory"]],
	["Walls and defence", ["wall", "tower", "gatehouse", "horse_ranch", "trireme_wharf"]],
	["Culture", ["gymnasium", "podium", "drama_school", "theater", "college", "stadium", "hippodrome", "crosswalk"]],
	["Science", ["bibliotheke", "university", "laboratory", "observatory", "inventors_workshop", "museum"]],
	["Sanctuaries", ["temple_aphrodite", "temple_apollo", "temple_ares", "temple_artemis", "temple_athena", "temple_atlas", "temple_demeter", "temple_dionysus", "temple_hades", "temple_hephaestus", "temple_hera", "temple_hermes", "temple_poseidon", "temple_zeus"]],
	["Pyramids", ["pyramid_modest", "pyramid_standard", "pyramid_great", "pyramid_majestic", "pyramid_sky_small", "pyramid_sky", "pyramid_sky_grand", "pyramid_pantheon", "pyramid_altar", "pyramid_temple", "pyramid_observatory", "pyramid_museum"]],
	["Shrines", ["shrine_minor_aphrodite", "shrine_minor_apollo", "shrine_minor_ares", "shrine_minor_artemis", "shrine_minor_athena", "shrine_minor_atlas", "shrine_minor_demeter", "shrine_minor_dionysus", "shrine_minor_hades", "shrine_minor_hephaestus", "shrine_minor_hera", "shrine_minor_hermes", "shrine_minor_poseidon", "shrine_minor_zeus", "shrine_aphrodite", "shrine_apollo", "shrine_ares", "shrine_artemis", "shrine_athena", "shrine_atlas", "shrine_demeter", "shrine_dionysus", "shrine_hades", "shrine_hephaestus", "shrine_hera", "shrine_hermes", "shrine_poseidon", "shrine_zeus", "shrine_major_aphrodite", "shrine_major_apollo", "shrine_major_ares", "shrine_major_artemis", "shrine_major_athena", "shrine_major_atlas", "shrine_major_demeter", "shrine_major_dionysus", "shrine_major_hades", "shrine_major_hephaestus", "shrine_major_hera", "shrine_major_hermes", "shrine_major_poseidon", "shrine_major_zeus"]],
	["Heroes' halls", ["hero_hall_achilles", "hero_hall_atalanta", "hero_hall_bellerophon", "hero_hall_hercules", "hero_hall_jason", "hero_hall_odysseus", "hero_hall_perseus", "hero_hall_theseus"]],
	["Gardens and monuments", ["park", "bench", "flower_garden", "bird_bath", "gazebo", "fish_pond", "shell_garden", "hedge_maze", "topiary", "sundial", "spring", "stone_circle", "orrery", "dolphin_sculpture", "short_obelisk", "tall_obelisk",
		"water_park", "doric_column", "ionic_column", "corinthian_column", "avenue", "boulevard",
		"monument_population", "monument_victory", "monument_colony", "monument_athlete", "monument_conquest", "monument_happiness", "monument_heroic", "monument_diplomacy", "monument_scholar",
		"god_monument_aphrodite", "god_monument_apollo", "god_monument_ares", "god_monument_artemis", "god_monument_athena", "god_monument_atlas", "god_monument_demeter",
		"god_monument_dionysus", "god_monument_hades", "god_monument_hephaestus", "god_monument_hera", "god_monument_hermes", "god_monument_poseidon", "god_monument_zeus"]],
]
const OTHER := "Other"
# Buildings that belong to one partner city: the menu lists one item per partner the core offers ("pier:3"), not the building.
const PARTNER_TOOLS := ["trade_post", "pier"]
# English display names: the translation keys of data/building_names.csv. They equal the core's English labels
# (validate_buildings.gd checks that), but the core's own label follows the language the city was opened in, while
# the menu follows the interface language, which can change at any time.
const NAMES := {
	"house": "Common Housing",
	"elite_house": "Elite Housing",
	"road": "Road",
	"wheat_farm": "Wheat Farm",
	"onion_farm": "Onion Farm",
	"carrot_farm": "Carrot Farm",
	"growers_lodge": "Growers' Lodge",
	"orange_tenders_lodge": "Orange Tenders' Lodge",
	"hunting_lodge": "Hunting Lodge",
	"carding_shed": "Carding Shed",
	"corral": "Corral",
	"dairy": "Dairy",
	"timber_mill": "Timber Mill",
	"masonry_shop": "Masonry Shop",
	"foundry": "Foundry",
	"refinery": "Refinery",
	"olive_press": "Olive Press",
	"winery": "Winery",
	"sculpture_studio": "Sculpture Studio",
	"artisans_guild": "Artisans' Guild",
	"black_marble_workshop": "Black Marble Workshop",
	"mint": "Mint",
	"chariot_factory": "Chariot Factory",
	"warehouse": "Storehouse",
	"granary": "Granary",
	"trade_post": "Trading Post",
	"pier": "Pier",
	"common_agora": "Common Agora",
	"grand_agora": "Grand Agora",
	"food_vendor": "Food Vendor",
	"fleece_vendor": "Fleece Vendor",
	"oil_vendor": "Oil Vendor",
	"wine_vendor": "Wine Vendor",
	"arms_vendor": "Arms Vendor",
	"horse_vendor": "Horse Trainer",
	"chariot_vendor": "Chariot Vendor",
	"hospital": "Infirmary",
	"fountain": "Fountain",
	"baths": "Baths",
	"tax_office": "Tax Office",
	"maintenance_office": "Maintenance Office",
	"watchpost": "Watchpost",
	"wall": "Wall",
	"tower": "Tower",
	"gatehouse": "Gatehouse",
	"armory": "Armory",
	"gymnasium": "Gymnasium",
	"podium": "Podium",
	"drama_school": "Drama School",
	"theater": "Theater",
	"college": "College",
	"bibliotheke": "Bibliotheke",
	"university": "University",
	"laboratory": "Laboratory",
	"observatory": "Observatory",
	"inventors_workshop": "Inventors' Workshop",
	"museum": "Museum",
	"park": "Park",
	"bench": "Bench",
	"flower_garden": "Flower Garden",
	"bird_bath": "Bird Bath",
	"gazebo": "Gazebo",
	"fish_pond": "Fish Pond",
	"shell_garden": "Shell Garden",
	"hedge_maze": "Hedge Maze",
	"topiary": "Topiary",
	"sundial": "Sundial",
	"spring": "Spring",
	"stone_circle": "Stone Circle",
	"orrery": "Orrery",
	"dolphin_sculpture": "Dolphin Sculpture",
	"short_obelisk": "Short Obelisk",
	"tall_obelisk": "Tall Obelisk",
	"temple_aphrodite": "Aphrodite's Haven",
	"temple_apollo": "Oracle of Apollo",
	"temple_ares": "Ares' Fortress",
	"temple_artemis": "Artemis' Menagerie",
	"temple_athena": "Arbor of Athena",
	"temple_atlas": "Pillar of Atlas",
	"temple_demeter": "Garden of Demeter",
	"temple_dionysus": "Grove of Dionysus",
	"temple_hades": "Gates of Hades",
	"temple_hephaestus": "Forge of Hephaestus",
	"temple_hera": "Orchard of Hera",
	"temple_hermes": "Hermes' Refuge",
	"temple_poseidon": "Promontory of Poseidon",
	"temple_zeus": "Zeus' Stronghold",
	"pyramid_modest": "Modest Pyramid",
	"pyramid_standard": "Pyramid",
	"pyramid_great": "Great Pyramid",
	"pyramid_majestic": "Majestic Pyramid",
	"pyramid_sky_small": "Small Monument to the Sky",
	"pyramid_sky": "Monument to the Sky",
	"pyramid_sky_grand": "Grand Monument to the Sky",
	"pyramid_pantheon": "Pyramid of the Pantheon",
	"pyramid_altar": "Altar of Olympus",
	"pyramid_temple": "Temple of Olympus",
	"pyramid_observatory": "Observatory Kosmika",
	"pyramid_museum": "Museum Atlantika",
	"shrine_minor_aphrodite": "Aphrodite Minor Shrine",
	"shrine_minor_apollo": "Apollo Minor Shrine",
	"shrine_minor_ares": "Ares Minor Shrine",
	"shrine_minor_artemis": "Artemis Minor Shrine",
	"shrine_minor_athena": "Athena Minor Shrine",
	"shrine_minor_atlas": "Atlas Minor Shrine",
	"shrine_minor_demeter": "Demeter Minor Shrine",
	"shrine_minor_dionysus": "Dionysus Minor Shrine",
	"shrine_minor_hades": "Hades Minor Shrine",
	"shrine_minor_hephaestus": "Hephaestus Minor Shrine",
	"shrine_minor_hera": "Hera Minor Shrine",
	"shrine_minor_hermes": "Hermes Minor Shrine",
	"shrine_minor_poseidon": "Poseidon Minor Shrine",
	"shrine_minor_zeus": "Zeus Minor Shrine",
	"shrine_aphrodite": "Aphrodite Shrine",
	"shrine_apollo": "Apollo Shrine",
	"shrine_ares": "Ares Shrine",
	"shrine_artemis": "Artemis Shrine",
	"shrine_athena": "Athena Shrine",
	"shrine_atlas": "Atlas Shrine",
	"shrine_demeter": "Demeter Shrine",
	"shrine_dionysus": "Dionysus Shrine",
	"shrine_hades": "Hades Shrine",
	"shrine_hephaestus": "Hephaestus Shrine",
	"shrine_hera": "Hera Shrine",
	"shrine_hermes": "Hermes Shrine",
	"shrine_poseidon": "Poseidon Shrine",
	"shrine_zeus": "Zeus Shrine",
	"shrine_major_aphrodite": "Aphrodite Major Shrine",
	"shrine_major_apollo": "Apollo Major Shrine",
	"shrine_major_ares": "Ares Major Shrine",
	"shrine_major_artemis": "Artemis Major Shrine",
	"shrine_major_athena": "Athena Major Shrine",
	"shrine_major_atlas": "Atlas Major Shrine",
	"shrine_major_demeter": "Demeter Major Shrine",
	"shrine_major_dionysus": "Dionysus Major Shrine",
	"shrine_major_hades": "Hades Major Shrine",
	"shrine_major_hephaestus": "Hephaestus Major Shrine",
	"shrine_major_hera": "Hera Major Shrine",
	"shrine_major_hermes": "Hermes Major Shrine",
	"shrine_major_poseidon": "Poseidon Major Shrine",
	"shrine_major_zeus": "Zeus Major Shrine",
	"hero_hall_achilles": "Hero's Hall for Achilles",
	"hero_hall_atalanta": "Hero's Hall for Atalanta",
	"hero_hall_bellerophon": "Hero's Hall for Bellerophon",
	"hero_hall_hercules": "Hero's Hall for Hercules",
	"hero_hall_jason": "Hero's Hall for Jason",
	"hero_hall_odysseus": "Hero's Hall for Odysseus",
	"hero_hall_perseus": "Hero's Hall for Perseus",
	"hero_hall_theseus": "Hero's Hall for Theseus",
	"roadblock": "Road Block",
	"bridge": "Water Crossing",
	"vine": "Grapevine",
	"olive_tree": "Olive Tree",
	"orange_tree": "Orange Tree",
	"goat": "Goat",
	"sheep": "Sheep",
	"cattle": "Cattle",
	"fishery": "Fishery",
	"urchin_quay": "Urchin Quay",
	"palace": "Palace",
	"horse_ranch": "Horse Ranch",
	"trireme_wharf": "Trireme Wharf",
	"stadium": "Stadium",
	"hippodrome": "Hippodrome",
	"crosswalk": "Crosswalk",
	"water_park": "Water Park",
	"doric_column": "Doric Column",
	"ionic_column": "Ionic Column",
	"corinthian_column": "Corinthian Column",
	"avenue": "Avenue",
	"boulevard": "Boulevard",
	"monument_population": "Population Monument",
	"monument_victory": "Victory Monument",
	"monument_colony": "Colony Monument",
	"monument_athlete": "Athlete Monument",
	"monument_conquest": "Conquest Monument",
	"monument_happiness": "Happiness Monument",
	"monument_heroic": "Heroic Figure Monument",
	"monument_diplomacy": "Diplomacy Monument",
	"monument_scholar": "Scholar Monument",
	"god_monument_aphrodite": "Small Aphrodite Statue",
	"god_monument_apollo": "Small Apollo Statue",
	"god_monument_ares": "Small Ares Statue",
	"god_monument_artemis": "Small Artemis Statue",
	"god_monument_athena": "Small Athena Statue",
	"god_monument_atlas": "Small Atlas Statue",
	"god_monument_demeter": "Small Demeter Statue",
	"god_monument_dionysus": "Small Dionysus Statue",
	"god_monument_hades": "Small Hades Statue",
	"god_monument_hephaestus": "Small Hephaestus Statue",
	"god_monument_hera": "Small Hera Statue",
	"god_monument_hermes": "Small Hermes Statue",
	"god_monument_poseidon": "Small Poseidon Statue",
	"god_monument_zeus": "Small Zeus Statue",
}

static func placeholders_wanted() -> bool:
	return bool(Engine.get_meta("ezeus_placeholders", false)) or "--placeholders" in OS.get_cmdline_user_args()

# Groups the core's list for the menu: [{title, items: [{name, label, cost, w, h, asset}]}], categories in table order,
# only buildings this city may build now (and that have a model unless `placeholders`). Empty groups are omitted.
static func groups(list: Array, placeholders := false, partners := []) -> Array:
	var by_name := {}
	for item in list:
		by_name[String(item.name)] = item
	var result: Array = []
	var seen := {}
	for category in CATEGORIES:
		var items := _items(category[1], by_name, seen, placeholders)
		if category[0] == "Trade":
			items = _partner_items(partners, by_name)
		if not items.is_empty():
			result.append({"title": category[0], "items": items})
	var rest: Array = []
	for item in list:
		if not seen.has(String(item.name)):
			rest.append(item.name)
	var others := _items(rest, by_name, seen, placeholders)
	if not others.is_empty():
		result.append({"title": OTHER, "items": others})
	return result

static func _items(names: Array, by_name: Dictionary, seen: Dictionary, placeholders: bool) -> Array:
	var items: Array = []
	for name in names:
		seen[name] = true
		if not by_name.has(name):
			continue
		var item: Dictionary = by_name[name]
		if not item.available or (item.asset == "unconverted" and not placeholders) or name in PARTNER_TOOLS:
			continue
		items.append({"name": name, "label": NAMES.get(name, item.label), "cost": int(item.cost), "marble": int(item.get("marble", 0)), "w": int(item.w), "h": int(item.h), "asset": item.asset})
	return items

# One item per trade partner the core offers: "trade_post:<partner>" for a land partner, "pier:<partner>" for a sea one.
static func _partner_items(partners: Array, by_name: Dictionary) -> Array:
	var items: Array = []
	for partner in partners:
		if not partner.available:
			continue
		var kind := "pier" if partner.water else "trade_post"
		if not by_name.has(kind) or not by_name[kind].available:
			continue
		var spec: Dictionary = by_name[kind]
		items.append({"name": "%s:%d" % [kind, int(partner.index)], "label": NAMES[kind], "partner_name": str(partner.name),
			"cost": int(spec.cost), "w": int(spec.w), "h": int(spec.h), "asset": spec.asset, "partner": int(partner.index), "tool": kind})
	return items

# Names the core lists that no category claims.
static func uncategorized(list: Array) -> PackedStringArray:
	var claimed := {}
	for category in CATEGORIES:
		for name in category[1]:
			claimed[name] = true
	var missing := PackedStringArray()
	for item in list:
		if not claimed.has(String(item.name)):
			missing.append(item.name)
	return missing
