extends Node
# Presentation for start-menu settings only. The original dialogs own their drafts,
# callbacks, key capture, persistence and display-preview/revert lifecycle.
const FRAME = preload("res://ui/settings_art/bronze_frame.svg")
const ARROW = preload("res://ui/settings_art/choice_arrow.svg")
const GRIP = preload("res://ui/settings_art/slider_grip.svg")
const CLOSE = preload("res://ui/settings_art/close.svg")
const CHECK_ON = preload("res://ui/settings_art/check_on.svg")
const CHECK_OFF = preload("res://ui/settings_art/check_off.svg")
const PATHS := ["display_dialog.gd", "graphics_dialog.gd", "sound_dialog.gd",
	"interface_dialog.gd", "controls_dialog.gd", "game_settings_dialog.gd"]
var dialog: AcceptDialog
var menu: Control
var refreshing := false
var finished := false

static func accepts(node: Node) -> bool:
	return node is AcceptDialog and node.get_script() != null and node.get_script().resource_path.get_file() in PATHS

func setup(window: AcceptDialog, host: Control) -> void:
	dialog = window
	menu = host
	dialog.add_child(self)
	dialog.set_meta("settings_shell", self)
	# Menu settings are modal even for the two legacy non-exclusive dialogs.
	dialog.exclusive = true
	menu.get_node("/root/UiAccess").changed.connect(refresh.call_deferred)
	menu.get_viewport().size_changed.connect(fit.call_deferred)
	refresh()
	# Run after AcceptDialog has built its native footer and content controls.
	finish.call_deferred()

func face(fill: Color, edge: Color, horizontal := 14, vertical := 9) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = horizontal; style.content_margin_right = horizontal
	style.content_margin_top = vertical; style.content_margin_bottom = vertical
	return style

func refresh() -> void:
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion(): return
	var theme: Theme = menu.theme.duplicate()
	var factor: float = menu.get_node("/root/UiAccess").text_size / 100.0
	install_frame(theme,factor)
	install_controls(theme,factor)
	dialog.theme = theme
	if dialog.is_node_ready(): align_fields()
	fit.call_deferred()

static func install_frame(theme: Theme, factor: float) -> void:
	# Shared by menu pages' native confirmations and the detailed settings windows.
	var frame := StyleBoxTexture.new()
	frame.texture = FRAME
	frame.texture_margin_left = 28; frame.texture_margin_right = 28
	frame.texture_margin_top = 64; frame.texture_margin_bottom = 28
	frame.expand_margin_top = 60
	frame.expand_margin_left = 6; frame.expand_margin_right = 6; frame.expand_margin_bottom = 6
	for kind in ["Window", "AcceptDialog", "ConfirmationDialog"]:
		theme.set_stylebox("embedded_border", kind, frame)
		theme.set_stylebox("embedded_unfocused_border", kind, frame)
		theme.set_font("title_font", kind, theme.get_font("font", "Subheading"))
		theme.set_font_size("title_font_size", kind, roundi(24 * factor))
		theme.set_color("title_color", kind, Color("f1dfb5"))
		theme.set_constant("title_height", kind, 60)
		theme.set_constant("close_h_offset", kind, 34)
		theme.set_constant("close_v_offset", kind, 36)
		theme.set_icon("close", kind, CLOSE)
		theme.set_icon("close_pressed", kind, CLOSE)

func install_controls(theme: Theme, factor: float) -> void:
	var content := StyleBoxEmpty.new()
	content.content_margin_left = 32; content.content_margin_right = 32
	content.content_margin_top = 22; content.content_margin_bottom = 24
	for kind in ["AcceptDialog", "ConfirmationDialog"]:
		theme.set_stylebox("panel", kind, content)
		theme.set_constant("buttons_separation", kind, 16)
	for kind in ["Label", "Button", "OptionButton", "CheckBox", "CheckButton"]:
		theme.set_font_size("font_size", kind, roundi(17 * factor))
		theme.set_color("font_color", kind, Color("eee5cf"))
		theme.set_color("font_disabled_color", kind, Color("a9a596"))
	theme.set_font_size("font_size", "Caption", roundi(14 * factor))
	theme.set_color("font_color", "Caption", Color("c7c5b6"))
	theme.set_color("font_color", "Subheading", Color("e9ca8b"))
	for kind in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var fill := Color("142d3b") if kind == "Button" else Color("0a1922")
			if state == "hover": fill = Color("234554")
			if state == "pressed": fill = Color("0b202c")
			if state == "disabled": fill = Color("101d24")
			var style := face(fill, Color("796343") if state == "normal" else Color("b89759"))
			if state == "disabled": style.border_color = Color("49483e")
			theme.set_stylebox(state, kind, style)
		var focus := face(Color.TRANSPARENT, Color("ddc18a"))
		focus.draw_center = false
		theme.set_stylebox("focus", kind, focus)
		for state in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, kind, Color("fff2d4"))
	theme.set_icon("arrow", "OptionButton", ARROW)
	theme.set_constant("arrow_margin", "OptionButton", 12)
	theme.set_constant("h_separation", "OptionButton", 16)
	theme.set_type_variation("SettingsApply", "Button")
	theme.set_stylebox("normal", "SettingsApply", face(Color("244456"), Color("c3a15e"), 20, 9))
	for kind in ["CheckBox", "CheckButton"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			theme.set_stylebox(state, kind, face(Color.TRANSPARENT, Color.TRANSPARENT, 4, 8))
		theme.set_constant("h_separation", kind, 10)
	for state in ["checked", "checked_disabled"]: theme.set_icon(state, "CheckBox", CHECK_ON)
	for state in ["unchecked", "unchecked_disabled"]: theme.set_icon(state, "CheckBox", CHECK_OFF)
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		theme.set_icon(state, "HSlider", GRIP)
	theme.set_stylebox("slider", "HSlider", face(Color("06131c"), Color("675737"), 0, 4))
	theme.set_stylebox("grabber_area", "HSlider", face(Color("ae8c4e"), Color("d8bb7c"), 0, 4))
	theme.set_stylebox("grabber_area_highlight", "HSlider", face(Color("c4a566"), Color("e7ce95"), 0, 4))

func finish() -> void:
	if finished or dialog.is_queued_for_deletion(): return
	finished = true
	if dialog is ConfirmationDialog:
		dialog.get_ok_button().theme_type_variation = "SettingsApply"
	dialog.confirmed.connect(pad_actions.call_deferred)
	dialog.canceled.connect(pad_actions.call_deferred)
	dialog.theme_changed.connect(pad_actions.call_deferred)
	if dialog.get_script().resource_path.get_file() == "controls_dialog.gd":
		dialog.message.minimum_size_changed.connect(fit.call_deferred)
	pad_actions()
	align_fields()
	fit.call_deferred()

func pad_actions() -> void:
	if dialog.is_queued_for_deletion(): return
	var minimum := Vector2(128,42)
	for button in dialog.get_ok_button().get_parent().get_children(true):
		if not button is Button: continue
		var font: Font = button.get_theme_font("font")
		var font_size: int = button.get_theme_font_size("font_size")
		var text_size := Vector2(ceilf(font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x),ceilf(font.get_height(font_size)))
		minimum = minimum.max(text_size + button.get_theme_stylebox("normal").get_minimum_size() + Vector2(8,4))
	# AcceptDialog resets footer custom_minimum_size during its own layout; use
	# its supported Theme constants so native layout retains the reading padding.
	var changed := false
	for kind in ["AcceptDialog", "ConfirmationDialog"]:
		for spec in [["buttons_min_width",roundi(minimum.x)],["buttons_min_height",roundi(minimum.y)]]:
			if dialog.theme.get_constant(spec[0],kind) != spec[1]:
				dialog.theme.set_constant(spec[0],kind,spec[1])
				changed = true
	if changed: fit.call_deferred()

func choice_controls(node: Node) -> Array[OptionButton]:
	var choices: Array[OptionButton] = []
	for child in node.get_children(true):
		if child is Window: continue
		if child is OptionButton: choices.append(child)
		choices.append_array(choice_controls(child))
	return choices

func align_fields() -> void:
	# Fix the caption column and let choices fill the remainder, so longer
	# resolution values cannot shift one field out of alignment. Native minima
	# remain authoritative; live text previews can also shrink back down.
	var columns: Dictionary = {}
	for choice in choice_controls(dialog):
		if not choice.get_parent() is HBoxContainer: continue
		var caption := choice.get_parent().get_child(0) as Label
		if caption == null: continue
		if not caption.has_meta("settings_native_width"):
			caption.set_meta("settings_native_width", caption.custom_minimum_size.x)
		var column: Node = choice.get_parent().get_parent()
		if not columns.has(column): columns[column] = []
		columns[column].append([choice,caption])
	for choices in columns.values():
		var width := 0.0
		for pair in choices:
			var caption: Label = pair[1]
			width = maxf(width,maxf(caption.get_meta("settings_native_width"),ceilf(caption.get_theme_font("font").get_string_size(caption.text,HORIZONTAL_ALIGNMENT_LEFT,-1,caption.get_theme_font_size("font_size")).x)+4))
		for pair in choices:
			pair[1].custom_minimum_size.x = width
			pair[1].size_flags_horizontal = Control.SIZE_FILL
			pair[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL

func fit() -> void:
	if refreshing or not is_instance_valid(dialog) or not dialog.visible or dialog.is_queued_for_deletion(): return
	refreshing = true
	# Only the long controls list scrolls. Preserve the original native content and
	# bound its reading area so footer/key capture remain reachable at larger sizes.
	var viewport := menu.get_viewport_rect().size
	if dialog.get_script().resource_path.get_file() == "controls_dialog.gd":
		var overhead: float = dialog.get_contents_minimum_size().y - dialog.scroller.get_combined_minimum_size().y
		dialog.scroller.custom_minimum_size.y = clampf(viewport.y - 98 - overhead, 180, 580)
	dialog.reset_size()
	dialog.popup_centered()
	# Center the complete frame, including the reserved title above Window's body.
	dialog.position = Vector2i(roundi((viewport.x-dialog.size.x)/2),roundi((viewport.y-dialog.size.y-66)/2+60))
	refreshing = false
