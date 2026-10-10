extends Button
# Original illustrated toolbar buttons use the native tooltip title, with a concise translated explanation.
# This also attaches to MenuButton (a Button subclass); native popup/pressed behavior stays intact.
const HoverHelp = preload("res://ui/hover_help.gd")
var help_detail := ""

func _ready() -> void:
	# Return camera control after mouse-up. Losing focus on mouse-down cancels
	# Godot's armed press before a normal, later mouse-up can activate the button.
	gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			release_focus.call_deferred())

func _make_custom_tooltip(_text: String) -> Object:
	return HoverHelp.build(tooltip_text, help_detail, self)
