extends Node
# Isolate owned automation windows from hardware input; injected events still take the actual GUI path.
func _input(event: InputEvent) -> void:
	if not event.has_meta("review_input"):get_viewport().set_input_as_handled()
