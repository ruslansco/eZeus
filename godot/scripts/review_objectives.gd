extends RefCounted

# Captures the objectives panel (ui/objective_card.gd, ui/objective_wreath.gd) over the designated city: closed, open with
# the city's own objectives, and open with a sample housing objective that falls short (the shortfall of a new Sparta:
# 27 Hovels lacking fleece and appeal), so its need chips can be reviewed. The sample is presentation only; nothing is
# sent to the core. Files: captures/objectives-<name>-*.png.

func shot(city: Node3D, name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await city.get_tree().create_timer(1.2).timeout
	city.capture_path = ProjectSettings.globalize_path("res://captures/objectives-%s.png" % name)
	await city.capture()

func run(city: Node3D, phase: String) -> void:
	var hud: Control = city.hud
	var okay := true
	await city.get_tree().create_timer(2.5).timeout
	var episode: Dictionary = city.core.query("episode")
	okay = okay and not episode.has("error") and not episode.get("goals", []).is_empty()
	okay = okay and episode.goals.all(func(g): return g.has("kind") and g.has("current") and g.has("required"))
	hud.set_goals(episode)
	hud.set_goals_expanded(false)
	await shot(city, phase + "-closed")
	hud.set_goals_expanded(true)
	await shot(city, phase + "-open")
	okay = okay and hud.goals_list.get_child_count() == episode.goals.size()
	# Hold the city's own two-second refresh (main.update_goals) so it does not replace the sample.
	city.goals_age = -1.0e9
	var sample := episode.duplicate(true)
	sample.goals.push_front({"index": 9, "kind": "housing", "met": false, "progress": 0.0, "current": 0, "required": 800,
		"set_aside": false, "status": "0 qualify", "text": "800 people in Homestead or better",
		"housing": {"houses": 27, "people": 648, "target": "Homestead", "levels": [{"level": 2, "name": "Hovel", "houses": 27, "people": 648}],
			"missing": [{"need": "fleece", "houses": 27}, {"need": "appeal", "houses": 27}]}})
	sample.total = int(sample.total) + 1
	hud.set_goals(sample)
	await shot(city, phase + "-housing")
	okay = okay and hud.goals_list.get_child_count() == sample.goals.size()
	print("OBJECTIVES_REVIEW ", "PASS" if okay else "FAIL")
	city.get_tree().quit(0 if okay else 1)
