extends Control
# Read-only statistic help uses the first line as its heading, keeping the native explanation below it.
const HoverHelp = preload("res://ui/hover_help.gd")

func _make_custom_tooltip(text: String) -> Object:
	var parts := text.split("\n", true, 1)
	return HoverHelp.build(parts[0], parts[1] if parts.size() > 1 else "", self)
