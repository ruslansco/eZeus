extends AcceptDialog
# The sound settings: one slider per kind of sound and a mute switch, remembered per user (scripts/audio_manager.gd).
# Built in code because it is a plain stack of rows; styled by the theme of the interface it opens in.

const ROWS := [["Master volume", "master"], ["Music", "Music"], ["Effects", "Effects"], ["Ambient sounds", "Ambient"], ["Voices", "Voice"]]
var sliders: Dictionary = {}
var mute: CheckBox

static func open(parent: Node) -> Window:
	var dialog: Window = load("res://ui/sound_dialog.gd").new()
	parent.add_child(dialog)
	dialog.popup_centered()
	return dialog

func _init() -> void:
	exclusive = false

func _ready() -> void:
	title = tr("Sound")
	ok_button_text = tr("Done")
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size=Vector2(500,minf(400,maxf(160,get_tree().root.size.y-180)))
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	for row in ROWS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		var label := Label.new()
		label.text = tr(row[0])
		label.custom_minimum_size.x = 170
		line.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = .05
		slider.custom_minimum_size.x = 260
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value = GameAudio.master_volume() if row[1] == "master" else GameAudio.volume(row[1])
		var percent := Label.new()
		percent.custom_minimum_size.x = 48
		percent.text = "%d%%" % roundi(slider.value * 100.0)
		slider.value_changed.connect(func(value):
			percent.text = "%d%%" % roundi(value * 100.0)
			if row[1] == "master":
				GameAudio.set_master_volume(value)
			else:
				GameAudio.set_volume(row[1], value))
		line.add_child(slider)
		line.add_child(percent)
		column.add_child(line)
		sliders[row[1]] = slider
	mute = CheckBox.new()
	mute.text = tr("Mute all sound")
	mute.button_pressed = GameAudio.muted()
	mute.toggled.connect(func(pressed): GameAudio.set_muted(pressed))
	column.add_child(mute)
	var original:=CheckBox.new();original.text=tr("Original lyre score and countryside ambience")
	original.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	original.button_pressed=GameAudio.original_soundscape
	original.toggled.connect(GameAudio.set_original_soundscape);column.add_child(original)
	var note:=Label.new();note.text=tr("Development soundscape. Battle music, effects and voices keep their current recordings.")
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.theme_type_variation="Caption";column.add_child(note)
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)
