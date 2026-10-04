extends VBoxContainer
# The card behind every campaign screen, one layout in several modes: the briefing before an episode (story, objectives,
# difficulty), its result, the choice of a colony, the end of the adventure and a defeat. The host (the start menu or the
# city's episode overlay) fills it from the core's answers and listens to its signals; the card holds no game logic.

signal primary_pressed
signal secondary_pressed
signal colony_chosen(index: int)
signal difficulty_changed(value: int)
signal set_aside_pressed(index: int)

@onready var heading: Label = %Heading
@onready var subtitle: Label = %Subtitle
@onready var body: Label = %Body
@onready var scroll: ScrollContainer = %Scroll
@onready var colonies: ItemList = %Colonies
@onready var goals_heading: Label = %GoalsHeading
@onready var goals: VBoxContainer = %Goals
@onready var difficulty_row: HBoxContainer = %DifficultyRow
@onready var difficulty_label: Label = %DifficultyLabel
@onready var difficulty_down: Button = %DifficultyDown
@onready var difficulty_value: Label = %DifficultyValue
@onready var difficulty_up: Button = %DifficultyUp
@onready var secondary: Button = %Secondary
@onready var primary: Button = %Primary

var mode := ""
var difficulty := 2
var difficulty_names: Array = []
var colony_indices: Array = []

func _ready() -> void:
	primary.pressed.connect(func(): primary_pressed.emit())
	secondary.pressed.connect(func(): secondary_pressed.emit())
	colonies.item_activated.connect(func(_row): _choose())
	colonies.item_selected.connect(func(_row): primary.disabled = false)
	difficulty_down.pressed.connect(func(): _step(-1))
	difficulty_up.pressed.connect(func(): _step(1))
	difficulty_label.text = tr("Difficulty")

func _step(by: int) -> void:
	var next := clampi(difficulty + by, 0, 4)
	if next == difficulty:
		return
	set_difficulty(next)
	difficulty_changed.emit(next)

func set_difficulty(value: int, names := []) -> void:
	if not names.is_empty():
		difficulty_names = names
	difficulty = clampi(value, 0, 4)
	difficulty_value.text = str(difficulty_names[difficulty]) if difficulty < difficulty_names.size() else str(difficulty)
	difficulty_down.disabled = difficulty <= 0
	difficulty_up.disabled = difficulty >= 4

func _reset() -> void:
	colonies.visible = false
	scroll.visible = true
	difficulty_row.visible = false
	secondary.visible = false
	primary.disabled = false
	secondary.disabled = false
	goals_heading.visible = false
	for child in goals.get_children():
		child.free()
	goals.visible = true

# One line per objective: a tick or a bullet, its wording, its status, and "Set aside" when the goods are in stock.
func fill_goals(list: Array, with_status: bool) -> void:
	for child in goals.get_children():
		child.free()
	goals_heading.visible = not list.is_empty()
	goals_heading.text = tr("Objectives")
	for goal in list:
		var line := VBoxContainer.new()
		line.add_theme_constant_override("separation", 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var text := Label.new()
		text.text = ("✓  " if goal.get("met", false) else "•  ") + str(goal.text)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		if goal.get("set_aside", false):
			var aside := Button.new()
			aside.text = tr("Set aside")
			aside.custom_minimum_size.y = 34
			var index := int(goal.get("index", 0))
			aside.pressed.connect(func(): set_aside_pressed.emit(index))
			row.add_child(aside)
		line.add_child(row)
		if with_status and not str(goal.get("status", "")).is_empty():
			var detail := Label.new()
			detail.text = "     " + str(goal.status)
			detail.theme_type_variation = "Detail"
			line.add_child(detail)
		goals.add_child(line)

func episode_label(data: Dictionary) -> String:
	if data.get("colony", false) or int(data.get("episode_count", 0)) <= 1:
		return str(data.get("episode_title", ""))
	return "%s  —  %s" % [str(data.get("episode_title", "")), tr("Episode %d of %d") % [int(data.get("episode_number", 1)), int(data.get("episode_count", 1))]]

# The briefing before an episode: story, objectives, difficulty. `back` shows a Back button (the first episode only).
func show_intro(data: Dictionary, back := false) -> void:
	_reset()
	mode = "intro"
	heading.text = str(data.get("title", ""))
	subtitle.text = episode_label(data)
	body.text = str(data.get("introduction", ""))
	fill_goals(data.get("goals", []), false)
	difficulty_label.text = tr("Difficulty")
	difficulty_row.visible = true
	set_difficulty(int(data.get("difficulty", 2)))
	secondary.visible = back
	secondary.text = tr("Back")
	primary.text = tr("Begin")

# The result of a won episode: the adventure's closing words, the objectives ticked, the way on.
func show_victory(data: Dictionary) -> void:
	_reset()
	mode = "victory"
	heading.text = tr("Victory")
	subtitle.text = str(data.get("episode_title", ""))
	body.text = str(data.get("complete", ""))
	fill_goals(data.get("goals", []), false)
	primary.text = tr("Continue")

func show_colonies(list: Array, text: String) -> void:
	_reset()
	mode = "colonies"
	heading.text = tr("Choose a colony")
	subtitle.text = ""
	body.text = text
	scroll.visible = true
	goals.visible = false
	colonies.visible = true
	colonies.clear()
	colony_indices = []
	for colony in list:
		colonies.add_item(str(colony.name))
		colony_indices.append(int(colony.index))
	primary.text = tr("Choose")
	primary.disabled = true
	if not list.is_empty():
		colonies.select(0)
		primary.disabled = false

func selected_colony() -> int:
	var rows := colonies.get_selected_items()
	return colony_indices[rows[0]] if not rows.is_empty() else -1

func _choose() -> void:
	if selected_colony() >= 0:
		colony_chosen.emit(selected_colony())

func show_complete(data: Dictionary) -> void:
	_reset()
	mode = "complete"
	heading.text = tr("Adventure complete")
	subtitle.text = str(data.get("title", ""))
	body.text = str(data.get("complete", ""))
	goals.visible = false
	primary.text = tr("Main menu")

func show_defeat(can_restart: bool) -> void:
	_reset()
	mode = "defeat"
	heading.text = tr("Defeat")
	subtitle.text = ""
	body.text = tr("Your city has fallen. You can try the episode again from its start.")
	goals.visible = false
	secondary.visible = true
	secondary.disabled = not can_restart
	secondary.text = tr("Restart episode")
	primary.text = tr("Main menu")
