extends RefCounted
# The session's message log: every message the core sends is recorded the first time it is seen (the core drops
# informational messages once they are dismissed), with the game date it arrived on. The native game keeps the
# same kind of log; saving it with the city comes with save/load.

const LIMIT := 300

var entries: Array = []
var seen := {}
var unread := 0

# Records an event dictionary from a snapshot; returns true when it is new.
func record(event: Dictionary, date_text: String, decision: bool) -> bool:
	var id := int(event.id)
	if seen.has(id):
		return false
	seen[id] = true
	entries.append({"id": id, "kind": str(event.get("kind", "")), "date": date_text, "title": sentence(str(event.title)), "text": str(event.text), "decision": decision})
	if entries.size() > LIMIT:
		entries.pop_front()
	unread += 1
	return true

func mark_read() -> void:
	unread = 0

# The core's titles are lower case; show them as a sentence ("Fire at the granary"), not Title Case.
static func sentence(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)

# Informational messages only offer to be dismissed; anything else is a decision or a pending interface.
static func is_informational(event: Dictionary) -> bool:
	var actions: Array = event.get("actions", [])
	return actions.size() == 1 and int(actions[0].choice) == -1
