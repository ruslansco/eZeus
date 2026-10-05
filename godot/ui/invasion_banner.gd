extends PanelContainer
# The red notice at the top of the city while an enemy force is in it: how many invaders still stand, and a button that takes the camera
# to them. (Monsters have their own button and card beside the journal, ui/monster_card.gd; main.gd passes no monster here.) The core says so in every snapshot during an invasion (`invasion`, `invaders`,
# `invader_at`) or a monster's visit (`monsters`, `monster`, `monster_at`) and says nothing in peace. The army
# does not defend by itself for a human player (the engine's own defence runs only for computer-controlled cities): the player calls the
# companies out and places their banners with the army panel. Built by main.gd (no scene of its own).
signal show_requested(cell: Vector2i)

var label := Label.new()
var show_button := Button.new()
var invaders := 0
var monsters := 0
var monster_name := ""
var at := Vector2i.ZERO

func _init() -> void:
	name = "InvasionBanner"
	visible = false
	anchor_left = .5
	anchor_right = .5
	offset_left = -250
	offset_right = 250
	offset_top = 16
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation = "Subheading"
	label.add_theme_color_override("font_color", Color(1.0, .55, .45))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	show_button.focus_mode = Control.FOCUS_NONE
	show_button.custom_minimum_size = Vector2(150, 0)
	show_button.pressed.connect(func(): show_requested.emit(at))
	row.add_child(show_button)

# The invaders come first; when there are none, a monster at large is announced instead.
func set_invaders(count: int, cell := Vector2i.ZERO, monster_count := 0, monster := "", monster_cell := Vector2i.ZERO) -> void:
	invaders = count
	monsters = monster_count if count <= 0 else 0
	monster_name = monster
	at = cell if count > 0 else monster_cell
	visible = count > 0 or monsters > 0
	retranslate()

func retranslate() -> void:
	if invaders <= 0 and monsters > 0:
		label.text = (tr("A monster stalks the city: %s") % monster_name) if monsters == 1 else (tr("%d monsters stalk the city") % monsters)
		show_button.text = tr("Go to the monster")
		return
	label.text = tr("Under attack: %d invaders") % invaders
	show_button.text = tr("Go to the invaders")
