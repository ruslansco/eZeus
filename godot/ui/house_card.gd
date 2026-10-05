extends RefCounted
# The house card, as the SDL remaster's (widgets/ehousehovercard): resting the pointer on an inhabited house for a moment, with
# no tool chosen, shows its level (pips), residents and what it needs for the next level, each need ticked or crossed and the
# missing ones first; missing culture or science venues name the kinds that do not reach the house, and a house that cannot
# keep its level says so in red. The core words the card (`house_card`, buildings/ehousecard, shared with the SDL card).

const REST_SECONDS := .35
const REFRESH_SECONDS := 1.0
const RED := Color(.94, .38, .29)
const GREEN := Color(.50, .84, .57)
const DIM := Color(.61, .67, .77)
const GOLD := Color(1.0, .87, .55)

var city
var panel: PanelContainer
var column: VBoxContainer
var cell := Vector2i(99999, 99999)
var rest := 0.0
var age := 0.0
var shown := false
var footprint := Rect2i()
var signature := ""

func attach(main) -> void:
	city = main
	panel = PanelContainer.new()
	panel.name = "HouseCard"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(250, 0)
	column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	city.hud.add_child(panel)

# The card may show only over the map, with no tool, editor, drag or dialog in the way.
func allowed() -> bool:
	if city.mode != "select" or city.route_editor.active or city.road_drag.active or city.unit_selection.pressing:
		return false
	if city.world_map.visible or city.get_viewport().gui_get_hovered_control() != null:
		return false
	for child in city.hud.get_children():
		if child is Window and child.visible:
			return false
	return city.tiles.has(city.picked)

func update(dt: float) -> void:
	if not allowed():
		hide()
		cell = Vector2i(99999, 99999)
		return
	var here: Vector2i = city.picked
	if here != cell:
		cell = here
		# Moving within the same house keeps its card; another tile starts the rest again.
		if not (shown and footprint.has_point(here)):
			hide()
			rest = 0.0
	rest += dt
	age += dt
	if not shown and rest >= REST_SECONDS:
		read()
	elif shown and age >= REFRESH_SECONDS:
		read()
	if shown:
		place()

# The card of the house on `at`, at once (tests; the pointer's rest is the player's way).
func show_at(at: Vector2i) -> void:
	cell = at
	rest = REST_SECONDS
	read()
	if shown:
		place()

func hide() -> void:
	shown = false
	panel.visible = false

func read() -> void:
	age = 0.0
	if city.core.simulation == null:
		return
	var answer: Dictionary = city.core.query("house_card %d %d" % [cell.x, cell.y])
	if not bool(answer.get("valid", false)):
		hide()
		rest = -INF  # nothing to show on this tile until the pointer moves
		return
	var r: Array = answer.footprint
	footprint = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	var key := JSON.stringify(answer)
	if key != signature:
		signature = key
		fill(answer)
	shown = true
	panel.visible = true

func label(text: String, color: Color, variation := "") -> Label:
	var item := Label.new()
	item.text = text
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_color_override("font_color", color)
	if variation != "":
		item.theme_type_variation = variation
	return item

func fill(card: Dictionary) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var title := str(card.name)
	column.add_child(label(title.left(1).to_upper() + title.substr(1), GOLD, "Subheading"))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.add_child(label(str(card.residents), DIM))
	var pips := ""
	for index in int(card.levels):
		pips += "◆" if index <= int(card.level) else "◇"
	row.add_child(label(pips, GOLD))
	column.add_child(row)
	var rule := HSeparator.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	var tone := int(card.tone)
	column.add_child(label(str(card.status), RED if tone == 1 else (GREEN if tone == 2 else Color(.93, .89, .82))))
	for need in card.lines:
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 8)
		var met := bool(need.met)
		line.add_child(label("✓" if met else "✗", GREEN if met else RED))
		var name := label(str(need.label), Color(.75, .77, .81) if met else Color(.96, .94, .89))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name)
		if not str(need.detail).is_empty():
			line.add_child(label(str(need.detail), DIM if met else Color(1.0, .75, .43)))
		column.add_child(line)
		if not str(need.note).is_empty():
			var note := label(str(need.note), DIM, "Caption")
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.custom_minimum_size = Vector2(230, 0)
			column.add_child(note)
	panel.reset_size()

# Beside the pointer, kept on screen.
func place() -> void:
	var view: Vector2 = city.get_viewport().get_visible_rect().size
	var mouse: Vector2 = city.get_viewport().get_mouse_position()
	var size: Vector2 = panel.get_combined_minimum_size()
	var at := mouse + Vector2(22, 22)
	if at.x + size.x > view.x - 8:
		at.x = mouse.x - size.x - 22
	if at.y + size.y > view.y - 8:
		at.y = mouse.y - size.y - 22
	panel.global_position = at.clamp(Vector2(8, 8), (view - size - Vector2(8, 8)).max(Vector2(8, 8)))
