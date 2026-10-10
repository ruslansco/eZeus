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
@onready var goals: Container = %Goals
@onready var difficulty_row: HBoxContainer = %DifficultyRow
@onready var difficulty_label: Label = %DifficultyLabel
@onready var difficulty_down: Button = %DifficultyDown
@onready var difficulty_value: Label = %DifficultyValue
@onready var difficulty_up: Button = %DifficultyUp
@onready var secondary: Button = %Secondary
@onready var primary: Button = %Primary
@onready var phase: Label = %Phase
@onready var episode_progress: Label = %EpisodeProgress
@onready var goal_summary: Label = %GoalSummary
@onready var goal_scroll: ScrollContainer = %GoalScroll

var mode := ""
var difficulty := 2
var difficulty_names: Array = []
var colony_indices: Array = []
var menu_layout := false

func _ready() -> void:
	primary.pressed.connect(func(): primary_pressed.emit())
	secondary.pressed.connect(func(): secondary_pressed.emit())
	colonies.item_activated.connect(func(_row): _choose())
	colonies.item_selected.connect(func(_row): primary.disabled = false)
	difficulty_down.pressed.connect(func(): _step(-1))
	difficulty_up.pressed.connect(func(): _step(1))
	difficulty_label.text = tr("Difficulty")
	difficulty_down.tooltip_text = tr("Lower difficulty")
	difficulty_up.tooltip_text = tr("Higher difficulty")
	%StoryHeading.text = tr("Story")
	for area in [scroll, goal_scroll]:
		area.get_v_scroll_bar().theme_type_variation = "AdventureScrollBar"
	colonies.get_v_scroll_bar().theme_type_variation = "AdventureScrollBar"
	get_viewport().size_changed.connect(fit_host)
	UiAccess.changed.connect(fit_host)
	fit_host.call_deferred()

# Both the start-menu briefing and the city overlay share the same bounded shell.
func fit_host() -> void:
	if menu_layout: return # The ornate start-menu frame owns its safe reading area.
	var host := get_parent() as PanelContainer
	if host == null: return
	var viewport := get_viewport_rect().size
	var width := minf(1080, viewport.x - 48)
	host.theme_type_variation = "EpisodeShell"
	host.custom_minimum_size = Vector2(width, minf(700, viewport.y - 48))
	%Content.vertical = width < 740
	%GoalsPanel.custom_minimum_size.x = 0 if %Content.vertical else clampf(width * .32, 260, 350)
	add_theme_constant_override("separation", 12 if viewport.y < 650 else 16)
	%Medal.custom_minimum_size = Vector2(56,56) if viewport.y < 650 else Vector2(72,72)

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
	%GoalsPanel.visible = true
	goal_summary.visible = false
	goal_scroll.visible = true
	%EmptyGoals.visible = false
	episode_progress.visible = false
	%Medal.texture = load("res://ui/icons/menu_emblem.svg")
	heading.theme_type_variation = "EpisodeHeading"
	scroll.scroll_vertical = 0
	goal_scroll.scroll_vertical = 0
	for child in goals.get_children():
		child.free()
	goals.visible = true

# Each objective retains its native wording/state, in a distinct wrapped card.
func fill_goals(list: Array, with_status: bool) -> void:
	for child in goals.get_children():
		child.free()
	goals_heading.visible = true
	goals_heading.text = tr("Objectives")
	%EmptyGoals.text = tr("No fixed victory objectives")
	%EmptyGoals.visible = list.is_empty()
	goal_scroll.visible = not list.is_empty()
	goal_summary.visible = mode == "victory" and not list.is_empty()
	goal_summary.text = tr("%d of %d achieved") % [list.filter(func(goal): return bool(goal.get("met", false))).size(),list.size()]
	for goal in list:
		var tile := PanelContainer.new()
		tile.theme_type_variation = "EpisodeGoalMet" if goal.get("met",false) else "EpisodeGoal"
		var line := VBoxContainer.new()
		line.add_theme_constant_override("separation", 5)
		tile.add_child(line)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var mark := Label.new()
		mark.text = "✓" if goal.get("met",false) else "◇"
		mark.theme_type_variation = "EpisodeGoalMark"
		mark.add_theme_color_override("font_color",Color(.57,.84,.68) if goal.get("met",false) else Color(.87,.75,.50))
		row.add_child(mark)
		var text := Label.new()
		text.text = str(goal.text)
		text.theme_type_variation = "EpisodeGoalText"
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
			detail.text = str(goal.status)
			detail.theme_type_variation = "Detail"
			detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_child(detail)
		goals.add_child(tile)

func set_episode_header(data: Dictionary) -> void:
	subtitle.text = str(data.get("episode_title", ""))
	subtitle.visible = not subtitle.text.is_empty()
	episode_progress.text = tr("Colony") if data.get("colony",false) else tr("Episode %d of %d") % [int(data.get("episode_number",1)),int(data.get("episode_count",1))]
	episode_progress.visible = bool(data.get("colony",false)) or int(data.get("episode_count",0)) > 1
	fit_host.call_deferred()

func episode_label(data: Dictionary) -> String:
	if data.get("colony", false) or int(data.get("episode_count", 0)) <= 1:
		return str(data.get("episode_title", ""))
	return "%s  —  %s" % [str(data.get("episode_title", "")), tr("Episode %d of %d") % [int(data.get("episode_number", 1)), int(data.get("episode_count", 1))]]

# The briefing before an episode: story, objectives, difficulty. `back` shows a Back button (the first episode only).
func show_intro(data: Dictionary, back := false) -> void:
	_reset()
	mode = "intro"
	phase.text = tr("Adventure briefing") if back else tr("Next chapter")
	heading.text = str(data.get("title", ""))
	set_episode_header(data)
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
	phase.text = str(data.get("title", ""))
	%Medal.texture = load("res://ui/icons/episode_victory.svg")
	heading.theme_type_variation = "EpisodeResultHeading"
	heading.text = tr("Victory")
	set_episode_header(data)
	body.text = str(data.get("complete", ""))
	fill_goals(data.get("goals", []), true)
	var completed: Array = data.get("goals",[])
	goals_heading.text = tr("Completed objectives") if not completed.is_empty() and completed.all(func(goal): return bool(goal.get("met",false))) else tr("Objectives")
	primary.text = tr("Continue")

func show_colonies(list: Array, text: String) -> void:
	_reset()
	mode = "colonies"
	phase.text = tr("Next chapter")
	%Medal.texture = load("res://ui/icons/menu_emblem.svg")
	heading.text = tr("Choose a colony")
	subtitle.text = ""
	subtitle.visible = false
	body.text = text
	scroll.visible = true
	goals.visible = false
	goal_scroll.visible = false
	goals_heading.visible = true
	goals_heading.text = tr("Colonies")
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
	fit_host.call_deferred()

func selected_colony() -> int:
	var rows := colonies.get_selected_items()
	return colony_indices[rows[0]] if not rows.is_empty() else -1

func _choose() -> void:
	if selected_colony() >= 0:
		colony_chosen.emit(selected_colony())

func show_complete(data: Dictionary) -> void:
	_reset()
	mode = "complete"
	phase.text = tr("Campaign")
	%Medal.texture = load("res://ui/icons/episode_victory.svg")
	heading.theme_type_variation = "EpisodeResultHeading"
	heading.text = tr("Adventure complete")
	subtitle.text = str(data.get("title", ""))
	subtitle.visible = not subtitle.text.is_empty()
	body.text = str(data.get("complete", ""))
	goals.visible = false
	%GoalsPanel.visible = false
	primary.text = tr("Main menu")
	fit_host.call_deferred()

func show_defeat(can_restart: bool) -> void:
	_reset()
	mode = "defeat"
	phase.text = tr("Campaign")
	%Medal.texture = load("res://ui/icons/risk.svg")
	heading.theme_type_variation = "EpisodeResultHeading"
	heading.text = tr("Defeat")
	subtitle.text = ""
	subtitle.visible = false
	body.text = tr("Your city has fallen. You can try the episode again from its start.")
	goals.visible = false
	%GoalsPanel.visible = false
	secondary.visible = true
	secondary.disabled = not can_restart
	secondary.text = tr("Restart episode")
	primary.text = tr("Main menu")
	fit_host.call_deferred()
