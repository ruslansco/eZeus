extends RefCounted
# The enlist-forces dialog of the SDL game: which companies, heroes and allied troops go on a raid, a conquest, a reinforcement or to a
# city that asked for troops. The core decides what may be enlisted (the engine's own rules, kept as a session: the `enlist` query) and
# does the sending (`enlist_dispatch`); this dialog lists what the core offers, lets the player choose, and sends the choice.
# Companies that are abroad are shown but cannot be chosen; only one allied city's troops may go along; nothing is sent without at
# least one company or hero. Used by the world map (raids, conquest) and by the decision of a troop request.

const Goods = preload("res://scripts/goods.gd")
const SECTIONS := [["horseman", "Horsemen"], ["hoplite", "Hoplites"], ["hero", "Heroes"], ["mythical", "Amazons and warriors of Ares"], ["ally", "Troops of allied cities"]]

var window: AcceptDialog
var core: Node
var session: Dictionary = {}
var done: Callable
var closed: Callable
var city_id := -1
var chosen_soldiers: Dictionary = {}
var chosen_heroes: Dictionary = {}
var chosen_ally := -1
var plunder: OptionButton
var list: VBoxContainer
var summary: Label
var status: Label
var buttons: Array = []

# Opens the dialog over `parent`. `finished` is called with the core's answer once the forces are sent; `dismissed` when it closes.
static func open(parent: Node, core_node: Node, session_value: Dictionary, finished := Callable(), dismissed := Callable()) -> RefCounted:
	var dialog := new()
	dialog.core = core_node
	dialog.session = session_value
	dialog.done = finished
	dialog.closed = dismissed
	dialog.build(parent)
	return dialog

func title_text() -> String:
	var target := String(session.get("target", {}).get("name", ""))
	match String(session.purpose):
		"raid": return tr("Raid on %s") % target
		"conquer": return tr("Conquest of %s") % target
		"reinforce": return tr("Reinforcements for %s") % target
	return tr("Troops to send")

func build(parent: Node) -> void:
	window = AcceptDialog.new()
	window.title = title_text()
	window.exclusive = true
	window.theme = load("res://ui/lapis_gold.tres")
	window.get_ok_button().hide()
	var cities: Array = session.cities
	city_id = int(cities[0].id) if not cities.is_empty() else -1
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	window.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	if cities.size() > 1:
		var chooser := OptionButton.new()
		for city in cities:
			chooser.add_item(String(city.name), int(city.id))
		chooser.item_selected.connect(func(slot: int):
			city_id = chooser.get_item_id(slot)
			rebuild_list())
		top.add_child(chooser)
	var plunder_choices: Array = session.get("plunder", [])
	if not plunder_choices.is_empty():
		var label := Label.new()
		label.theme_type_variation = "Caption"
		label.text = tr("Plunder")
		top.add_child(label)
		plunder = OptionButton.new()
		for choice in plunder_choices:
			plunder.add_item(tr("Anything") if int(choice.resource) == -1 else Goods.name_of(int(choice.resource)), int(choice.resource) + 1)
		top.add_child(plunder)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	summary = Label.new()
	summary.theme_type_variation = "Caption"
	column.add_child(summary)
	status = Label.new()
	status.theme_type_variation = "Caption"
	status.add_theme_color_override("font_color", Color(1.0, .55, .45))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for entry in [["Enlist all", enlist_all], ["Clear", clear_all], ["Send", send], ["Cancel", cancel]]:
		var button := Button.new()
		button.text = tr(entry[0])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		if entry[0] == "Send":
			button.theme_type_variation = "Primary"
		button.pressed.connect(entry[1])
		row.add_child(button)
	window.canceled.connect(cancel)
	window.close_requested.connect(cancel)
	parent.add_child(window)
	rebuild_list()
	window.popup_centered(Vector2i(680, 560))

func clean(text: String) -> String:
	return text.strip_edges().trim_prefix("\"").trim_suffix("\"")

func section_of(soldier: Dictionary) -> String:
	match String(soldier.type):
		"horseman": return "horseman"
		"hoplite": return "hoplite"
	return "mythical"

func rebuild_list() -> void:
	for child in list.get_children():
		child.free()
	buttons.clear()
	for section in SECTIONS:
		var rows: Array = []
		match section[0]:
			"horseman", "hoplite", "mythical":
				for soldier in session.soldiers:
					if int(soldier.city) == city_id and section_of(soldier) == section[0]:
						rows.append(["s", int(soldier.id), "%s  —  %d" % [clean(str(soldier.name)), int(soldier.count)], bool(soldier.abroad)])
			"hero":
				for hero in session.heroes:
					if int(hero.city) == city_id:
						rows.append(["h", "%d:%d" % [int(hero.city), int(hero.hero)], str(hero.name), bool(hero.abroad)])
			"ally":
				for ally in session.allies:
					rows.append(["a", int(ally.index), "%s  —  %s" % [str(ally.name), tr("%d troops") % int(ally.troops)], bool(ally.abroad)])
		if rows.is_empty():
			continue
		var heading := Label.new()
		heading.theme_type_variation = "Subheading"
		heading.text = tr(section[1])
		list.add_child(heading)
		for entry in rows:
			var button := Button.new()
			button.toggle_mode = true
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.focus_mode = Control.FOCUS_NONE
			button.text = String(entry[2]) + ("   (%s)" % tr("abroad") if bool(entry[3]) else "")
			button.disabled = bool(entry[3])
			button.set_pressed_no_signal(is_chosen(String(entry[0]), entry[1]))
			var kind: String = entry[0]
			var key = entry[1]
			button.toggled.connect(func(pressed: bool): choose(kind, key, pressed))
			list.add_child(button)
			buttons.append({"button": button, "kind": kind, "key": key})
	if list.get_child_count() == 0:
		var none := Label.new()
		none.theme_type_variation = "Caption"
		none.text = tr("There is nothing to enlist.")
		list.add_child(none)
	update_summary()

func is_chosen(kind: String, key) -> bool:
	match kind:
		"s": return chosen_soldiers.has(int(key))
		"h": return chosen_heroes.has(String(key))
		"a": return chosen_ally == int(key)
	return false

func choose(kind: String, key, pressed: bool) -> void:
	status.text = ""
	match kind:
		"s":
			if pressed: chosen_soldiers[int(key)] = true
			else: chosen_soldiers.erase(int(key))
		"h":
			if pressed: chosen_heroes[String(key)] = true
			else: chosen_heroes.erase(String(key))
		"a":
			# Only one allied city's troops may go along: choosing another replaces it.
			chosen_ally = int(key) if pressed else -1
			for entry in buttons:
				if entry.kind == "a":
					entry.button.set_pressed_no_signal(chosen_ally == int(entry.key))
	update_summary()

func clear_all() -> void:
	chosen_soldiers.clear()
	chosen_heroes.clear()
	chosen_ally = -1
	status.text = ""
	rebuild_list()

func enlist_all() -> void:
	clear_all()
	for soldier in session.soldiers:
		if not bool(soldier.abroad):
			chosen_soldiers[int(soldier.id)] = true
	for hero in session.heroes:
		if not bool(hero.abroad):
			chosen_heroes["%d:%d" % [int(hero.city), int(hero.hero)]] = true
	for ally in session.allies:
		if not bool(ally.abroad):
			chosen_ally = int(ally.index)
			break
	rebuild_list()

func update_summary() -> void:
	var soldiers := 0
	for soldier in session.soldiers:
		if chosen_soldiers.has(int(soldier.id)):
			soldiers += int(soldier.count)
	var text := tr("Enlisted: %d soldiers in %d companies, %d heroes") % [soldiers, chosen_soldiers.size(), chosen_heroes.size()]
	if chosen_ally >= 0:
		for ally in session.allies:
			if int(ally.index) == chosen_ally:
				text += "  •  " + tr("troops of %s") % str(ally.name)
	summary.text = text

func command_text() -> String:
	var resource := -1
	if plunder != null and plunder.selected >= 0:
		resource = plunder.get_item_id(plunder.selected) - 1
	var command := "enlist_dispatch %d" % resource
	if not chosen_soldiers.is_empty():
		command += " s:" + ",".join(chosen_soldiers.keys().map(func(id): return str(id)))
	if not chosen_heroes.is_empty():
		command += " h:" + ",".join(chosen_heroes.keys())
	if chosen_ally >= 0:
		command += " a:%d" % chosen_ally
	return command

func reason(code: String) -> String:
	var messages := {
		"no_forces": "Choose at least one company or hero first.",
		"already_abroad": "That force is already abroad.",
		"one_ally_only": "Only one allied city's troops may go along.",
		"not_enlistable": "That force cannot be enlisted now.",
		"not_offered": "That plunder is not on offer.",
		"no_enlistment": "Nothing is waiting to be sent.",
		"invalid_enlistment": "That choice could not be understood."}
	return tr(messages.get(code, "The action could not be completed"))

func send() -> void:
	var answer: Dictionary = core.query(command_text())
	if answer.has("error"):
		status.text = reason(str(answer.error))
		return
	close()
	if done.is_valid():
		done.call(answer)

func cancel() -> void:
	core.query("enlist_cancel")
	close()

func close() -> void:
	if window != null and is_instance_valid(window):
		window.hide()
		window.queue_free()
	window = null
	if closed.is_valid():
		closed.call()
