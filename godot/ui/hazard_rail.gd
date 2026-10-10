extends Node
# The hazard alerts in the right-hand rail: one button of its own for each kind of hazard (the SDL view's alert tiles: fire,
# collapse, earthquake, flood, lava, a god's visit or attack, a hero's arrival, invasion, plague, the army's return). A button
# appears with the kind's first alert, counts the live ones, pulses on arrival, goes to the newest site when pressed and is put
# away by a right click; alerts also lapse after LIFETIME seconds (hovering a button holds them). Monsters keep their own
# button and card (ui/monster_card.gd). The core's snapshot `alerts` list (id, kind, at) feeds it through `observe`; ids are
# shown once. Built by main.gd (no scene of its own).
signal go_requested(cell: Vector2i)
signal changed

const LIFETIME := 12.0
const MAX_PER_KIND := 6
const HAZARD := Color(1.0, .55, .45)
const BOON := Color(.96, .82, .46)
# Event kind (the core's name) -> button.
const GROUP := {
	"fire": "fire", "collapse": "collapse", "earthquake": "quake", "earthquakeGod": "quake",
	"tidalWave": "flood", "tidalWaveGod": "flood", "lavaFlow": "lava", "godVisit": "god_visit", "godHelp": "god_visit",
	"godInvasion": "god_attack", "playerGodAttack": "god_attack", "heroArrival": "hero", "invasion": "invasion",
	"playerInvasion": "invasion", "plague": "plague", "armyReturns": "army", "aidArrives": "army",
	# Beyond the SDL alert tiles: the gods' lava, land that gives way, a road cut that brings buildings down, the warnings that an
	# invasion or a monster is coming, and the engine's risk warnings. A monster already in the city has its own button and card.
	"lavaFlowGod": "lava", "sinkLand": "land", "sinkLandGod": "land", "landSlide": "land", "areaCutOff": "collapse",
	"invasionInitial": "invasion", "invasion24": "invasion", "invasion12": "invasion", "invasion6": "invasion", "invasion1": "invasion",
	"monsterInvasionInitial": "monster", "monsterInvasion24": "monster", "monsterInvasion12": "monster", "monsterInvasion6": "monster",
	"monsterInvasion1": "monster", "godMonsterUnleash": "monster", "riskWarning": "risk"}
const ORDER := ["fire", "collapse", "quake", "land", "flood", "lava", "plague", "invasion", "monster", "god_attack", "risk", "god_visit", "hero", "army"]
const BOONS := ["god_visit", "hero", "army"]
const NotificationButton = preload("res://ui/notification_button.gd")

var column: Control
var icons := {}
var buttons := {}
# kind group -> [{"id", "cell" (Vector2i or null), "left"}], oldest first.
var alerts := {}
var last_id := -1
var held := {}
var suspended := false
# Hazards that last while they exist (a fire burning, houses sick with plague): group -> {"count", "cell"}. Their button stays until
# they are over; putting it away (right click) silences it until the hazard has ended and comes again.
var persistent := {}
var silenced := {}

func attach(rail_column: Control, icon_loader: Callable) -> void:
	column = rail_column
	for group in ORDER:
		icons[group] = icon_loader.call("alert_" + group)

static func title_of(group: String) -> String:
	match group:
		"fire": return TranslationServer.translate("Fire")
		"collapse": return TranslationServer.translate("Building collapse")
		"quake": return TranslationServer.translate("Earthquake")
		"flood": return TranslationServer.translate("Flood")
		"lava": return TranslationServer.translate("Lava flow")
		"land": return TranslationServer.translate("Land gives way")
		"monster": return TranslationServer.translate("A monster approaches")
		"risk": return TranslationServer.translate("Risk warning")
		"plague": return TranslationServer.translate("Plague")
		"invasion": return TranslationServer.translate("Invasion")
		"god_attack": return TranslationServer.translate("A god attacks")
		"god_visit": return TranslationServer.translate("A god visits")
		"hero": return TranslationServer.translate("A hero arrives")
		_: return TranslationServer.translate("The army returns")

# Takes the snapshot's `alerts`; ids at or below the last one seen are old news.
func observe(entries: Array) -> void:
	var fresh := false
	for entry in entries:
		var id := int(entry.id)
		if id <= last_id:
			continue
		last_id = id
		var group: String = GROUP.get(str(entry.kind), "")
		if group.is_empty():
			continue
		var at: Array = entry.get("at", [-1, -1])
		var cell = Vector2i(int(at[0]), int(at[1])) if int(at[0]) >= 0 else null
		var list: Array = alerts.get(group, [])
		var repeat := false
		# The same hazard at the same place is one alert, kept alive.
		for old in list:
			if old.cell == cell:
				old.id = id
				old.left = LIFETIME
				repeat = true
		if not repeat:
			list.append({"id": id, "cell": cell, "left": LIFETIME})
			while list.size() > MAX_PER_KIND:
				list.pop_front()
		alerts[group] = list
		fresh = true
		_show(group, not repeat)
	if fresh:
		changed.emit()

# The hazards the city holds now: a count and a place (null when unknown). Zero ends it.
func set_persistent(group: String, count: int, cell) -> void:
	if count <= 0:
		if persistent.has(group) or silenced.has(group):
			persistent.erase(group)
			silenced.erase(group)
			if not alerts.has(group):
				_dismiss(group)
			elif buttons.has(group):
				_describe(group)
		return
	var arrived := not persistent.has(group)
	persistent[group] = {"count": count, "cell": cell}
	if silenced.has(group):
		return
	if arrived or not buttons.has(group):
		_show(group, arrived)
		changed.emit()
	else:
		_describe(group)

func clear() -> void:
	for group in buttons.keys():
		_remove(buttons[group])
	buttons.clear()
	alerts.clear()
	last_id = -1
	changed.emit()

func retranslate() -> void:
	for group in buttons:
		_describe(group)

func _show(group: String, pulse: bool) -> void:
	var button: Button = buttons.get(group)
	if button == null:
		button = NotificationButton.new()
		button.name = "Alert_" + group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = icons[group]
		var tint := BOON if group in BOONS else HAZARD
		button.accent = tint
		button.pressed.connect(func(): _go(group))
		button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				_dismiss(group)
				button.accept_event())
		button.mouse_entered.connect(func(): held[group] = true)
		button.mouse_exited.connect(func(): held.erase(group))
		column.add_child(button)
		# Keep the rail in a steady order whatever arrived first.
		var place := 0
		for other in ORDER.slice(0, ORDER.find(group)):
			if buttons.has(other): place += 1
		buttons[group] = button
		column.move_child(button, mini(column.get_child_count() - 1, 1 + place))
	_describe(group)
	if pulse: button.highlight()

func _describe(group: String) -> void:
	var button: Button = buttons.get(group)
	if button == null:
		return
	var count: int = maxi(alerts.get(group, []).size(), int(persistent.get(group, {}).get("count", 0)))
	button.set_badge(str(count) if count > 1 else "")
	button.tooltip_text = title_of(group) + (" · %d" % count if count > 1 else "")
	button.help_detail = tr("Click to look · right click to put away")

# Out of the rail at once, so its height is right in the same frame.
func _remove(button: Control) -> void:
	column.remove_child(button)
	button.queue_free()

func _newest_cell(group: String):
	var list: Array = alerts.get(group, [])
	for index in range(list.size() - 1, -1, -1):
		if list[index].cell != null:
			return list[index].cell
	var standing: Dictionary = persistent.get(group, {})
	return standing.get("cell", null)

func _go(group: String) -> void:
	var cell = _newest_cell(group)
	if cell != null:
		go_requested.emit(cell)

func _dismiss(group: String) -> void:
	if persistent.has(group):
		silenced[group] = true
	alerts.erase(group)
	held.erase(group)
	if buttons.has(group):
		_remove(buttons[group])
		buttons.erase(group)
	changed.emit()

func _can_count_down(button: Control) -> bool:
	if not button.is_visible_in_tree() or button.has_focus(): return false
	var area := button.get_global_rect()
	var ancestor := button.get_parent()
	while ancestor is Control:
		if ancestor.clip_contents and not ancestor.get_global_rect().grow(1).encloses(area): return false
		ancestor = ancestor.get_parent()
	return button.get_viewport_rect().encloses(area)

func _process(delta: float) -> void:
	var lapsed := false
	if suspended or get_tree().root.get_node("UiAccess").dialog_open: return
	for group in alerts.keys():
		if held.has(group) or (buttons.has(group) and not _can_count_down(buttons[group])):
			continue
		var list: Array = alerts[group]
		for entry in list.duplicate():
			entry.left -= delta
			if entry.left <= 0.0:
				list.erase(entry)
		if list.is_empty():
			alerts.erase(group)
			if persistent.has(group) and not silenced.has(group):
				_describe(group)
			else:
				_dismiss(group)
			lapsed = true
		elif buttons.has(group):
			_describe(group)
	if lapsed:
		changed.emit()
