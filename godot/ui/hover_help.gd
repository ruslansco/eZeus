extends RefCounted
# Bounded presentation-only help for toolbar controls and read-only city statistics.

static func build(title: String, detail: String, control: Control) -> Control:
	var panel := PanelContainer.new()
	panel.theme = control.theme if control.theme != null else load("res://ui/lapis_gold.tres")
	panel.theme_type_variation = "ToolbarTooltip"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := minf(320, control.get_viewport_rect().size.x - 80)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = width
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	for spec in [[title, "ToolbarTooltipTitle"], [detail, "ToolbarTooltipDetail"]]:
		if str(spec[0]).is_empty(): continue
		var label := Label.new()
		label.text = str(spec[0])
		label.theme_type_variation = str(spec[1])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# A tooltip window measures height before its first container layout.
		# Give wrapped labels their final width now, rather than a single-letter column.
		label.custom_minimum_size.x = width
		label.size.x = width
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	return panel
