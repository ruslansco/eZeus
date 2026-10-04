extends CanvasLayer
# The campaign screens over the city: the result of an episode (victory, or defeat with a retry), then what the campaign
# offers next (the end of the adventure, a choice of colony, the briefing of the next episode). It drives the core's
# campaign commands (finish_episode, choose_colony, begin_episode) and only reports to the city by signals; the
# city then moves to the new session. All text and layout live in ui/episode_card.tscn.

signal main_menu_requested
signal restart_requested(path: String)
signal session_started

const SaveFiles = preload("res://scripts/save_files.gd")
const RESTART_SAVE := "autosave replay"

@onready var card = %Card
var core: Node

func _ready() -> void:
	card.primary_pressed.connect(_primary)
	card.secondary_pressed.connect(_secondary)
	card.colony_chosen.connect(_colony)
	card.difficulty_changed.connect(func(value): core.query("difficulty %d" % value))

func restart_path() -> String:
	return SaveFiles.directory().path_join(RESTART_SAVE + ".ez")

# The episode is over: `episode` is the core's answer to the `episode` query.
func show_result(episode: Dictionary) -> void:
	if bool(episode.get("victory", false)):
		card.show_victory(episode)
		GameAudio.play_result(str(episode.get("victory_voice", "")), "mission_victory")
	else:
		card.show_defeat(FileAccess.file_exists(restart_path()))
	visible = true
	card.primary.grab_focus()

func _primary() -> void:
	match card.mode:
		"victory":
			_advance(core.query("finish_episode"))
		"colonies":
			_colony(card.selected_colony())
		"intro":
			_begin()
		"complete", "defeat":
			main_menu_requested.emit()

func _secondary() -> void:
	if card.mode == "defeat" and FileAccess.file_exists(restart_path()):
		restart_requested.emit(restart_path())

# What follows a won episode.
func _advance(step: Dictionary) -> void:
	if step.has("error"):
		return
	match str(step.next):
		"complete":
			card.show_complete(step)
			GameAudio.play_result(str(step.get("voice", "")), "campaign_victory")
		"colonies":
			card.show_colonies(step.colonies, tr("Your city can found one of these colonies next."))
		"episode":
			_brief(step.preview)

func _brief(preview: Dictionary) -> void:
	card.show_intro(preview, false)
	var levels: Dictionary = core.query("difficulty")
	card.set_difficulty(int(levels.get("value", preview.get("difficulty", 2))), levels.get("names", []))
	GameAudio.play_briefing(str(preview.get("voice", "")))
	card.primary.grab_focus()

func _colony(index: int) -> void:
	if index < 0 or card.mode != "colonies":
		return
	var preview: Dictionary = core.query("choose_colony %d" % index)
	if not preview.has("error"):
		_brief(preview)

func _begin() -> void:
	var started: Dictionary = core.query("begin_episode")
	if started.has("error"):
		return
	GameAudio.stop_voice()
	visible = false
	session_started.emit()
