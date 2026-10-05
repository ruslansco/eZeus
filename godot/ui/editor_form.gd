extends RefCounted
# A form of the adventure editor, built from the core's field list (eEditorSession): each field is a row with its label and
# a control for its kind: `int` a number box within its bounds, `choice` a list of the core's options, `bool` a tick box.
# Every change calls `changed` with the field's id and its new value; the core answers with the whole form again.

# Builds the rows into `parent` (its old rows are removed first).
static func build(parent: Container, fields: Array, changed: Callable) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	for field in fields:
		var row := HBoxContainer.new()
		row.name = "Field_" + str(field.id)
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.text = label_of(field)
		label.custom_minimum_size = Vector2(190, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.theme_type_variation = "Caption"
		row.add_child(label)
		var id := str(field.id)
		match str(field.kind):
			"int":
				var box := SpinBox.new()
				box.name = "Value"
				box.min_value = float(field.get("min", 0))
				box.max_value = float(field.get("max", 99999))
				box.value = float(field.value)
				box.allow_greater = false
				box.custom_minimum_size = Vector2(130, 0)
				box.value_changed.connect(func(v: float): changed.call(id, int(v)))
				row.add_child(box)
			"choice":
				var choice := OptionButton.new()
				choice.name = "Value"
				choice.fit_to_longest_item = false
				choice.custom_minimum_size = Vector2(220, 0)
				var selected := -1
				for option in field.get("options", []):
					choice.add_item(str(option.label), int(option.value))
					if int(option.value) == int(field.value):
						selected = choice.item_count - 1
				choice.selected = selected
				choice.item_selected.connect(func(slot: int): changed.call(id, choice.get_item_id(slot)))
				row.add_child(choice)
			"bool":
				var tick := CheckBox.new()
				tick.name = "Value"
				tick.button_pressed = int(field.value) != 0
				tick.toggled.connect(func(on: bool): changed.call(id, 1 if on else 0))
				row.add_child(tick)
		parent.add_child(row)

# The game's label, with "from"/"to" for the two ends of a range (the SDL editor shows them side by side under one label).
static func label_of(field: Dictionary) -> String:
	var id := str(field.id)
	var text := str(field.label).strip_edges().trim_suffix(":")
	if id.ends_with("_min"):
		return TranslationServer.translate("%s, from") % text
	if id.ends_with("_max"):
		return TranslationServer.translate("%s, to") % text
	return text
