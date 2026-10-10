extends Node
# Shared presentation preferences. Mutate only the cached Theme in memory; never save its resource.
signal changed
const Settings=preload("res://scripts/user_settings.gd")
const PlayOptions=preload("res://scripts/play_settings.gd")
const THEME_PATH="res://ui/lapis_gold.tres"
const UI_SIZES=[100,110,125]
const TEXT_SIZES=[100,115,130]
var ui_size:=100
var text_size:=100
var baseline: Theme
var shared: Theme
var dialog_open:=false
var reduced_motion := false

func _ready() -> void:
	shared=load(THEME_PATH)
	baseline=shared.duplicate(true)
	# Automation has a reproducible layout and never reads a player's size preferences.
	var automated:=OS.get_cmdline_args().has("--script")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--validate") or argument.begins_with("--skip-start") or argument.contains("-review"):automated=true
	if not automated:
		load_preferences()
		# Restore confirmed display preferences along with the interface sizes.
		PlayOptions.apply_window()
	preload("res://scripts/graphics_settings.gd").startup(get_tree())

func load_preferences() -> void:
	var motion: Variant=Settings.get_value("interface","reduced_motion",false)
	reduced_motion=motion if motion is bool else false
	var ui: Variant=Settings.get_value("interface","ui_size",100)
	var text: Variant=Settings.get_value("interface","text_size",100)
	apply(ui if typeof(ui)==TYPE_INT else 100,text if typeof(text)==TYPE_INT else 100)

func apply(ui: int, text: int) -> void:
	ui_size=ui if ui in UI_SIZES else 100
	text_size=text if text in TEXT_SIZES else 100
	var factor:=text_size/100.0
	shared.default_font_size=roundi(baseline.default_font_size*factor)
	for type in baseline.get_font_size_type_list():
		for name in baseline.get_font_size_list(type):
			shared.set_font_size(name,type,roundi(baseline.get_font_size(name,type)*factor))
	get_tree().root.content_scale_factor=ui_size/100.0
	changed.emit()

func save_preferences() -> Error:
	var file:=ConfigFile.new()
	file.load(Settings.path())
	file.set_value("interface","ui_size",ui_size)
	file.set_value("interface","text_size",text_size)
	file.set_value("interface","reduced_motion",reduced_motion)
	return file.save(Settings.path())
