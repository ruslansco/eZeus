extends RefCounted
# One card per episode objective in the objectives panel (hud.gd set_goals): the kind's icon, the
# objective, a progress bar with the count, the core's status, and for housing goals what keeps the
# houses below the level back (the core's `housing` shortfall: houses per level, lacking needs).
# Every style is a type variation of ui/lapis_gold.tres (scripts/build_ui_theme.gd: Objective*).
const DONE := Color(.55, .83, .66)
const GOLD_PALE := Color(.97, .87, .64)
const ICONS := {
	"population": "people", "treasury": "coin", "sanctuary": "sanctuaries", "support": "defence",
	"quest": "heroes", "slay": "heroes", "rule": "compass", "housing": "homes", "set_aside": "storage",
	"survive": "risk", "deadline": "risk", "trade": "trade", "production": "industry", "profit": "coin",
	"pyramid": "pyramids", "hippodrome": "culture",
}
# Kinds whose count reads as "current / required"; the others show the core's status beside the bar.
const COUNTED := ["population", "treasury", "housing", "support", "trade", "production", "profit", "set_aside"]
# Yes-or-no objectives: no bar, only the core's status.
const BINARY := ["quest", "slay", "rule", "hippodrome", "survive", "deadline"]
const NEED_ICONS := {
	"food": "food", "water": "water", "fleece": "resource_fleece", "oil": "resource_oil", "arms": "resource_arms",
	"wine": "resource_wine", "horse": "people", "venues": "culture", "appeal": "gardens",
}

static func icon(name: String) -> Texture2D:
	var path := "res://ui/icons/%s.svg" % name
	return load(path) if ResourceLoader.exists(path) else null

# A thin gold bar; `done` turns it green.
static func bar(fraction: float, done: bool, height := 8.0) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.min_value = 0.0
	progress.max_value = 1.0
	progress.value = clampf(fraction, 0.0, 1.0)
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, height)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.theme_type_variation = "ObjectiveBarDone" if done else "ObjectiveBar"
	return progress

static func label(text: String, variation: String) -> Label:
	var line := Label.new()
	line.text = text
	line.theme_type_variation = variation
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line

static func number(value: float) -> String:
	var whole := int(round(value))
	var digits := str(absi(whole))
	var grouped := ""
	var separator := " " if TranslationServer.get_locale().begins_with("ru") else ","
	while digits.length() > 3:
		grouped = separator + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if whole < 0 else "") + digits + grouped

# A round gold-rimmed disc with the kind's icon; a tick when the objective is met.
static func medallion(kind: String, met: bool) -> Control:
	var disc := PanelContainer.new()
	disc.theme_type_variation = "ObjectiveMedalDone" if met else "ObjectiveMedal"
	disc.custom_minimum_size = Vector2(36, 36)
	disc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var picture := TextureRect.new()
	picture.texture = icon(ICONS.get(kind, "inspect"))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(22, 22)
	picture.modulate = DONE if met else GOLD_PALE
	disc.add_child(picture)
	return disc

# A need the houses lack: its icon, its name and how many houses lack it; the tooltip says what to do.
static func chip(need: String, houses: int, translate: Callable) -> Control:
	var holder := PanelContainer.new()
	holder.theme_type_variation = "ObjectiveNeed"
	holder.tooltip_text = translate.call(advice(need))
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.texture = icon(NEED_ICONS.get(need, "inspect"))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(16, 16)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var text := Label.new()
	text.text = "%s  ×%d" % [translate.call(need_name(need)), houses]
	text.theme_type_variation = "ObjectiveNote"
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	holder.add_child(row)
	return holder

static func need_name(need: String) -> String:
	return {"food": "Food", "water": "Water", "fleece": "Fleece", "oil": "Olive oil", "arms": "Armor", "wine": "Wine",
		"horse": "Horses", "venues": "Entertainment", "appeal": "Appeal"}.get(need, need)

static func advice(need: String) -> String:
	return {
		"food": "Houses need food: farms or fishermen, a granary and a food vendor in an agora.",
		"water": "Houses need water: a fountain whose water carriers reach them.",
		"fleece": "Houses need fleece: sheep and a carding shed, a storehouse and a fleece vendor in an agora.",
		"oil": "Houses need olive oil: olive groves, a press, a storehouse and an oil vendor in an agora.",
		"arms": "Houses need armor: bronze, a foundry and an armory, and an agora that sells it.",
		"wine": "Houses need wine: vineyards, a winery and a wine vendor in an agora.",
		"horse": "Elite houses need horses: a horse ranch and a horse trainer.",
		"venues": "Houses need more kinds of entertainment in reach: theaters, gymnasiums, podiums or stadiums.",
		"appeal": "Raise the appeal around the houses: parks, gardens, statues and fountains nearby, and no workshops, storehouses or other plain buildings beside them.",
	}.get(need, "")

static func build(goal: Dictionary, translate: Callable, set_aside: Callable) -> Control:
	var met := bool(goal.get("met", false))
	var kind := str(goal.get("kind", ""))
	var card := PanelContainer.new()
	card.theme_type_variation = "ObjectiveCardDone" if met else "ObjectiveCard"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(medallion(kind, met))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	column.add_child(label(str(goal.get("text", "")), "Caption" if met else "Value"))
	if met:
		column.add_child(label("✓  " + translate.call("Achieved"), "ObjectiveDone"))
		return card
	# The bar and its count ("1,920 / 2,000"), or for the other kinds the core's own status ("98% complete").
	var counted := kind in COUNTED and float(goal.get("required", 0)) > 0
	var status := str(goal.get("status", "")).strip_edges()
	if kind in BINARY:
		if not status.is_empty():
			column.add_child(label(status.left(1).to_upper() + status.substr(1), "Detail"))
	else:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		var holder := VBoxContainer.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.alignment = BoxContainer.ALIGNMENT_CENTER
		holder.add_child(bar(float(goal.get("progress", 0.0)), false))
		line.add_child(holder)
		var count := Label.new()
		count.theme_type_variation = "ObjectiveCount"
		if counted:
			count.text = "%s / %s" % [number(float(goal.current)), number(float(goal.required))]
		else:
			count.text = status if not status.is_empty() else "%d%%" % int(round(float(goal.get("progress", 0.0)) * 100))
		line.add_child(count)
		column.add_child(line)
	# Housing: which houses fall short and what they lack.
	var housing: Dictionary = goal.get("housing", {})
	if not housing.is_empty() and int(housing.get("houses", 0)) > 0:
		var levels: Array = housing.get("levels", [])
		var parts: Array[String] = []
		for entry in levels:
			parts.append("%s ×%d" % [str(entry.name), int(entry.houses)])
		var short := maxi(int(goal.get("required", 0)) - int(goal.get("current", 0)), 0)
		column.add_child(label(translate.call("Below %s: %s (%s people)") % [str(housing.target), ", ".join(parts), number(float(housing.people))], "Detail"))
		var missing: Array = housing.get("missing", [])
		if not missing.is_empty():
			column.add_child(label(translate.call("To reach %s they lack:") % str(housing.target), "ObjectiveNote"))
			var chips := HFlowContainer.new()
			chips.add_theme_constant_override("h_separation", 6)
			chips.add_theme_constant_override("v_separation", 6)
			for entry in missing:
				chips.add_child(chip(str(entry.need), int(entry.houses), translate))
			column.add_child(chips)
		if int(housing.people) < short:
			column.add_child(label(translate.call("Even when they all qualify, %s more people are needed: build more houses.") % number(float(short - int(housing.people))), "ObjectiveWarning"))
	elif kind == "housing" and int(goal.get("current", 0)) < int(goal.get("required", 0)):
		column.add_child(label(translate.call("Build more houses."), "Detail"))
	# Goods that count only once reserved: the button appears when the stock is there (the SDL goals window's button).
	if goal.get("set_aside", false):
		var aside := Button.new()
		aside.text = translate.call("Set aside")
		aside.theme_type_variation = "Primary"
		aside.focus_mode = Control.FOCUS_NONE
		var index := int(goal.get("index", 0))
		aside.pressed.connect(func(): set_aside.call(index))
		column.add_child(aside)
	return card
