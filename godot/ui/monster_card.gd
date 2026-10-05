extends PanelContainer
# The monsters at large in the city: a button in the right-hand rail under the journal (a red count, shown only while a monster is
# in the city) and the card it opens below the rail. The card gives each monster's own message (the engine's words for its coming,
# as the SDL view shows them), the hero who alone can slay it (soldiers cannot hurt a monster; only a hero's hunt kills one) and how
# far the city is with that hero: the hall may be built, it stands, the hero is summoned or in the city. Its buttons go to the monster,
# open the Build menu on the hero's hall or show the built hall. The core's `monster_info` answers it; the snapshot's `monsters` count
# drives the button. Built by main.gd (no scene of its own).
signal go_requested(cell: Vector2i)
signal build_hall_requested(tool_name: String)
signal show_hall_requested(cell: Vector2i)
signal opened

var button := Button.new()
var count := 0
var monsters: Array = []
var list := VBoxContainer.new()
var heading := Label.new()
var close_button := Button.new()
var scroll := ScrollContainer.new()
var pulse: Tween

func _init() -> void:
	name = "MonsterCard"
	visible = false
	theme_type_variation = "FloatingTray"
	anchor_left = 1
	anchor_right = 1
	button.name = "MonsterAlert"
	button.theme_type_variation = "RailButton"
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", Color(1.0, .55, .45))
	button.add_theme_color_override("font_hover_color", Color(1.0, .66, .58))
	button.add_theme_color_override("icon_normal_color", Color(1.0, .55, .45))
	button.add_theme_color_override("icon_hover_color", Color(1.0, .66, .58))
	button.visible = false
	button.pressed.connect(func(): set_open(not visible))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	heading.theme_type_variation = "ToolHeading"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	close_button.theme_type_variation = "Quiet"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.pressed.connect(func(): set_open(false))
	header.add_child(close_button)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

func attach(rail_column: Control, close_icon: Texture2D, monster_icon: Texture2D) -> void:
	rail_column.add_child(button)
	button.icon = monster_icon
	close_button.icon = close_icon
	retranslate()

# The snapshot's count of monsters at large. The button appears with the first one (and pulses once to catch the eye) and goes with
# the last; the card closes when nothing is left to show.
func set_count(value: int) -> void:
	if value == count:
		return
	var arrived := value > count
	count = value
	button.visible = count > 0
	button.text = str(count) if count > 0 else ""
	if count == 0:
		set_open(false)
	elif arrived:
		if pulse != null: pulse.kill()
		button.modulate = Color(1, 1, 1)
		pulse = button.create_tween().set_loops(3)
		pulse.tween_property(button, "modulate", Color(1.6, .7, .6), .35)
		pulse.tween_property(button, "modulate", Color(1, 1, 1), .35)
	retranslate()

func set_open(open: bool) -> void:
	if open == visible:
		return
	visible = open and count > 0
	if visible:
		opened.emit()

func set_monsters(entries: Array) -> void:
	if entries == monsters:
		return
	monsters = entries
	for child in list.get_children():
		child.free()
	for index in entries.size():
		if index > 0:
			list.add_child(HSeparator.new())
		list.add_child(_monster_entry(entries[index]))

func _monster_entry(entry: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var name_label := Label.new()
	name_label.theme_type_variation = "Heading"
	name_label.add_theme_color_override("font_color", Color(1.0, .55, .45))
	name_label.text = str(entry.name)
	box.add_child(name_label)
	# The engine's title usually names the monster again ("Hydra in city"); then it is left out.
	if not str(entry.get("title", "")).is_empty() and not str(entry.title).contains(str(entry.name)):
		var title := Label.new()
		title.theme_type_variation = "Subheading"
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.text = str(entry.title)
		box.add_child(title)
	if not str(entry.get("text", "")).is_empty():
		var text := Label.new()
		text.theme_type_variation = "Detail"
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.text = str(entry.text)
		box.add_child(text)
	var slayer := Label.new()
	slayer.theme_type_variation = "Eyebrow"
	slayer.text = tr("Only a hero can slay it: %s") % str(entry.hero)
	box.add_child(slayer)
	var state := Label.new()
	state.theme_type_variation = "Caption"
	state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state.text = hero_state(entry)
	box.add_child(state)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var go := Button.new()
	go.focus_mode = Control.FOCUS_NONE
	go.text = tr("Go to the monster")
	var at := Vector2i(int(entry.x), int(entry.y))
	go.pressed.connect(func(): go_requested.emit(at))
	actions.add_child(go)
	var built: bool = entry.get("hall_built", false)
	if built:
		var show := Button.new()
		show.focus_mode = Control.FOCUS_NONE
		show.text = tr("Show the hero's hall")
		var hall: Array = entry.get("hall_at", [0, 0])
		var hall_cell := Vector2i(int(hall[0]), int(hall[1]))
		show.pressed.connect(func(): show_hall_requested.emit(hall_cell))
		actions.add_child(show)
	elif entry.get("hall_allowed", false) and not str(entry.get("hall_tool", "")).is_empty():
		var build := Button.new()
		build.theme_type_variation = "Primary"
		build.focus_mode = Control.FOCUS_NONE
		build.text = tr("Build the hero's hall")
		var tool_name := str(entry.hall_tool)
		build.pressed.connect(func(): build_hall_requested.emit(tool_name))
		actions.add_child(build)
	return box

# Where the city stands with the slaying hero, in the words of the hall's inspector where they exist.
func hero_state(entry: Dictionary) -> String:
	if not entry.get("hall_built", false):
		if entry.get("hall_allowed", false):
			return tr("Build the hall of %s, meet its requirements and summon the hero.") % str(entry.hero)
		return tr("The hall of %s cannot be built in this city yet.") % str(entry.hero)
	match str(entry.get("hero_stage", "")):
		"arrived": return tr("The hero is in the city and defends it.")
		"summoned": return tr("The hero has been summoned and is on his way.")
	return tr("The hero has not been summoned yet.")

func retranslate() -> void:
	heading.text = tr("Monsters in the city")
	close_button.tooltip_text = tr("Close")
	button.tooltip_text = (tr("A monster stalks the city: %s") % str(monsters[0].name)) if count == 1 and not monsters.is_empty() else tr("%d monsters stalk the city") % count
	var entries := monsters
	monsters = []
	set_monsters(entries)
