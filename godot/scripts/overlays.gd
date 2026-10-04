extends RefCounted
# The city overlays (the SDL game's "view modes"): which ones exist, their names, hotkeys and legends. The core's
# `overlay <id>` query supplies the data (which buildings and walker kinds stay visible, the value columns over houses,
# supplies, the appeal grid); scripts/overlay_view.gd draws it. Hotkeys are the SDL game's: 1 water, 2 supplies,
# 3 hygiene, 4 fire and collapse risk, 5 appeal, 6 taxes, 7 unrest, 8 security, 9 roads, Tab problems, 0 or ` normal.
# Labels and legends are `tr()` keys (data/ui_strings.csv).

# id -> [menu label, legend shown while it is on, hotkey]
const MODES := {
	"normal": ["Normal view", "", KEY_0],
	"water": ["Water and fountains", "Columns: the water each house gets. Taller is better.", KEY_1],
	"supplies": ["Food and housing supplies", "Markers on each house: food, fleece and oil (and for palaces wine, arms and horses). Coloured when stocked, red when short.", KEY_2],
	"hygiene": ["Hygiene and health", "Columns: the hygiene of each house. Taller and greener is better.", KEY_3],
	"hazards": ["Fire and collapse risk", "Columns: fire and collapse risk of each building. Taller and redder is worse.", KEY_4],
	"appeal": ["Desirability and appeal", "Ground colour: appeal rises from red through green to blue.", KEY_5],
	"taxes": ["Tax collection", "Columns over houses: green and tall when the taxes are paid, a short red stub when they are not.", KEY_6],
	"unrest": ["Unrest and crime", "Columns: unrest in each house. Taller and redder is worse.", KEY_7],
	"security": ["Security and defences", "Walls, towers, gates, soldiers, the watch and the immortals.", KEY_8],
	"roads": ["Road network", "Only the roads, the citizens and the carts.", KEY_9],
	"problems": ["City problems", "Only discontented and sick citizens.", KEY_TAB],
	"husbandry": ["Farming and animals", "Farms, orchards, lodges, herds and the people who tend them.", 0],
	"industry": ["Industry", "Workshops, mills and the people who work in them.", 0],
	"distribution": ["Storage and trade", "Granaries, storehouses, trade posts, piers and the carts and ships between them.", 0],
	"immortals": ["Gods, heroes and monsters", "Sanctuaries and halls, and the gods, heroes and monsters on the map.", 0],
	"actors": ["Actors", "Columns: the theatre each house enjoys. Taller is better.", 0],
	"athletes": ["Athletes", "Columns: the gymnasium each house enjoys. Taller is better.", 0],
	"philosophers": ["Philosophers", "Columns: the philosophy each house enjoys. Taller is better.", 0],
	"competitors": ["Competitors", "Columns: the games each house enjoys. Taller is better.", 0],
	"all_culture": ["All culture", "Columns: all the culture each house enjoys. Taller is better.", 0],
	"astronomers": ["Astronomers", "Columns: the astronomy each house enjoys. Taller is better.", 0],
	"scholars": ["Scholars", "Columns: the scholarship each house enjoys. Taller is better.", 0],
	"inventors": ["Inventors", "Columns: the invention each house enjoys. Taller is better.", 0],
	"curators": ["Curators", "Columns: the museum each house enjoys. Taller is better.", 0],
	"all_science": ["All science", "Columns: all the science each house enjoys. Taller is better.", 0],
}

# The menu: ids, or [submenu title, [ids]]; "" separates groups.
const MENU := [
	"normal", "",
	"water", "supplies", "hygiene", "hazards", "appeal", "taxes", "unrest", "security", "roads", "problems", "",
	"husbandry", "industry", "distribution", "immortals", "",
	["Culture overlays", ["actors", "athletes", "philosophers", "competitors", "all_culture"]],
	["Science overlays", ["astronomers", "scholars", "inventors", "curators", "all_science"]],
]

# Column colours by the core's tone: 1 green, 2 yellow, 3 orange, 4 red, 5 water blue.
const TONES := {1: Color(.36, .80, .42), 2: Color(.95, .84, .30), 3: Color(.95, .56, .22), 4: Color(.90, .26, .22), 5: Color(.36, .62, .95)}
# Supplies: food, fleece, oil, wine, arms, horses.
const SUPPLY_COLORS := [Color(.95, .78, .25), Color(.96, .94, .86), Color(.62, .78, .30), Color(.62, .30, .72), Color(.62, .66, .74), Color(.70, .46, .26)]
const SHORT := Color(.88, .20, .20)
# Appeal rating 0..9 (the core's own rounding of the heat map) -> ground colour.
const APPEAL := [Color(.80, .10, .10), Color(.92, .36, .16), Color(.96, .80, .30), Color(.80, .88, .36), Color(.58, .84, .38),
	Color(.40, .80, .44), Color(.30, .76, .56), Color(.24, .72, .68), Color(.22, .66, .80), Color(.28, .56, .92)]

static func ids() -> Array:
	return MODES.keys()

static func hotkeys() -> Dictionary:
	var keys := {}
	for id in MODES:
		if int(MODES[id][2]) != 0:
			keys[int(MODES[id][2])] = id
	return keys
