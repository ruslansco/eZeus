extends RefCounted
# Read-only presentation policy. Choices, rather than event wording, determine whether an answer is required.
const Log = preload("res://scripts/message_log.gd")
const URGENT := ["fire", "collapse", "godInvasion", "godMonsterUnleash", "monsterInCity", "monsterInvasion", "invasion", "invasion1", "monsterInvasion1"]
const GROUPABLE := ["shortageWarning", "riskWarning", "employees"]

static func delivery(event: Dictionary) -> String:
	if not Log.is_informational(event): return "decision"
	var kind: String = str(event.get("kind", ""))
	# Old adapters and message-shower events have no specific native kind. Keep a visible fallback.
	if kind.is_empty() or kind in URGENT: return "alert"
	return "journal"

static func group_key(entry: Dictionary) -> String:
	if entry.get("decision", false) or not str(entry.get("kind", "")) in GROUPABLE: return ""
	# Exact wording keeps warnings about different goods/places separate. Native kind is mandatory.
	return JSON.stringify([entry.kind, entry.title, entry.text])

static func rows(entries: Array) -> Array:
	var groups := {}
	var result: Array = []
	for entry in entries:
		var key := group_key(entry)
		if not key.is_empty() and groups.has(key):
			var row: Dictionary = groups[key]
			row.date = entry.date
			row.occurrences.append(entry)
			result.erase(row); result.append(row)
		else:
			var row: Dictionary = entry.duplicate()
			row.occurrences = [entry]
			result.append(row)
			if not key.is_empty(): groups[key] = row
	return result
