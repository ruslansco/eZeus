extends SceneTree
# The adventure editor (headless). It edits a copy of The Founding of Athens in a scratch adventures folder
# (`set_adventures_directory`), so the player's own adventures are never written; the designated save is not touched.
#   New: an adventure is made by name (a taken or unusable name is refused) and listed.
#   The adventure: start date, starting funds and prices change; parent episodes are added, inserted, deleted and their next
#   episode switched; an episode's goals are added, changed through their fields (the sentence follows) and removed; events
#   are added for a city, changed through their fields and removed; friendly gods, buildings and the sanctuary limit change.
#   The map: terrain tools paint through the engine's editor code (water, height, forest), unknown tools are refused, and
#   while editing the city never runs and game commands are refused; outside the editor the editor's commands are refused.
#   The world: city settings change (kind, visibility, name, leader, trade), a city moves, one is added, the picture changes.
#   Saving writes the copy; opened again, every change is there.
#   The interface: the episodes window and an episode's settings are built from the core's answers.
const Episodes = preload("res://ui/editor_episodes.gd")
const Form = preload("res://ui/editor_form.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("EDITOR_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	if not OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH").is_empty():
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	if not OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").is_empty():
		Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	for file in DirAccess.get_files_at(from):
		DirAccess.copy_absolute(from.path_join(file), to.path_join(file))
	for sub in DirAccess.get_directories_at(from):
		copy_tree(from.path_join(sub), to.path_join(sub))

func remove_tree(folder: String) -> void:
	for sub in DirAccess.get_directories_at(folder):
		remove_tree(folder.path_join(sub))
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)

func tiles_of(state: Dictionary) -> Dictionary:
	var out := {}
	for tile in state.get("tiles", []) + state.get("tile_changes", []):
		out[Vector2i(int(tile[0]), int(tile[1]))] = tile
	return out

func field(fields: Array, id: String) -> Dictionary:
	for f in fields:
		if str(f.id) == id:
			return f
	return {}

# A stand-in for the editor panel: the windows only ask it for the core's answers.
class FakePanel extends RefCounted:
	var core: RefCounted
	var overview: Dictionary = {}
	var changes := 0
	func query(text: String) -> Dictionary:
		return core.command(text)
	func mark_changed() -> void:
		changes += 1

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var scratch := ProjectSettings.globalize_path("res://captures/editor-scratch-%d" % Time.get_ticks_usec())
	var adventures := scratch.path_join("Adventures")
	copy_tree(engine.path_join("Adventures/The Founding of Athens"), adventures.path_join("The Founding of Athens"))
	var original := FileAccess.get_file_as_bytes(engine.path_join("Adventures/The Founding of Athens/The Founding of Athens.epak"))
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	core.set_adventures_directory(adventures)

	# ---------------------------------------------------------------------------------------------------- a new adventure
	check(core.new_adventure(engine, "a/b", "en").get("error", "") == "invalid_name" and core.new_adventure(engine, "", "en").get("error", "") == "invalid_name",
		"names a folder cannot have are refused")
	var made: Dictionary = core.new_adventure(engine, "Editor Test", "en")
	check(made.get("kind", "") == "new_adventure" and FileAccess.file_exists(adventures.path_join("Editor Test/Editor Test.epak")), "a new adventure is made and saved (%s)" % str(made))
	check(core.new_adventure(engine, "Editor Test", "en").get("error", "") == "name_taken", "a name already used is refused")
	var listed: Array = core.adventures(engine, "en").get("adventures", []).filter(func(a): return str(a.kind) == "folder")
	var refs: Array = listed.map(func(a): return str(a.ref))
	check(refs.has("Editor Test") and refs.has("The Founding of Athens"), "the scratch folder's adventures are listed (%s)" % str(refs))
	var fresh: Dictionary = core.open_editor(engine, "folder", "Editor Test", "en")
	check(fresh.has("protocol") and bool(fresh.get("editor", false)) and core.command("editor").parent.size() == 1, "the new adventure opens for editing with one episode")
	core.close_city()

	# ---------------------------------------------------------------------------------------------------- the adventure
	var state: Dictionary = core.open_editor(engine, "folder", "The Founding of Athens", "en")
	check(state.has("protocol") and bool(state.get("editor", false)) and bool(state.get("paused", false)), "The Founding of Athens opens for editing, paused, its map in view")
	var overview: Dictionary = core.command("editor")
	check(overview.get("kind", "") == "editor" and overview.parent.size() >= 1 and overview.colonies.size() == 4 and not str(overview.labels.save).is_empty(),
		"the overview lists %d parent episodes and four colony episodes, with the game's labels" % overview.get("parent", []).size())
	check(bool(overview.saved), "nothing has changed yet")
	overview = core.command("editor_date 5 2 -1200")
	check(overview.date.map(func(v): return int(v)) == [5, 2, -1200] and not bool(overview.saved), "the start date changes (%s)" % overview.date_text)
	check(core.command("editor_date 40 2 -1200").has("error"), "an impossible date is refused")
	var player := int(overview.funds[0].player)
	overview = core.command("editor_funds %d 12345" % player)
	check(int(overview.funds[0].value) == 12345, "the starting funds change")
	var resource := int(overview.prices[0].resource)
	overview = core.command("editor_price %d 77" % resource)
	check(int(overview.prices[0].value) == 77, "a price changes")
	overview = core.command("editor_prices_reset")
	check(int(overview.prices[0].value) == int(overview.prices[0].default), "prices go back to the game's own")
	var count: int = overview.parent.size()
	overview = core.command("editor_episode_add")
	check(overview.parent.size() == count + 1 and bool(overview.parent[count].last), "an episode is added at the end")
	overview = core.command("editor_episode_insert 0")
	check(overview.parent.size() == count + 2, "an episode is inserted before the first")
	overview = core.command("editor_episode_delete 0")
	overview = core.command("editor_episode_delete %d" % count)
	check(overview.parent.size() == count, "episodes are deleted")
	var next_before := str(overview.parent[0].next)
	if count > 1:
		overview = core.command("editor_episode_next 0")
		check(str(overview.parent[0].next) != next_before, "the next episode switches between the parent city and a colony")
		overview = core.command("editor_episode_next 0")

	# ------------------------------------------------------------------------------------------------- an episode's settings
	var episode: Dictionary = core.command("editor_episode p 0")
	check(episode.get("kind", "") == "episode" and episode.cities.size() >= 1 and episode.goal_kinds.size() == 14 and episode.event_kinds.size() == 24,
		"the first episode's settings: %d cities, 14 kinds of goal and 24 of event" % episode.get("cities", []).size())
	var goals: int = episode.goals.size()
	episode = core.command("editor_goal_add p 0 0")
	check(episode.goals.size() == goals + 1 and not field(episode.goals[goals].fields, "count").is_empty(), "a population goal is added with its count")
	episode = core.command("editor_goal_set p 0 %d count 4321" % goals)
	check(str(episode.goals[goals].text).contains("4321") or str(episode.goals[goals].text).contains("4,321"), "the goal's sentence follows its count: %s" % str(episode.goals[goals].text))
	check(core.command("editor_goal_set p 0 %d nonsense 1" % goals).has("error"), "an unknown field is refused")
	episode = core.command("editor_goal_remove p 0 %d" % goals)
	check(episode.goals.size() == goals, "the goal is removed")
	var cid := int(episode.cities[0].id)
	var events: int = episode.cities[0].events.size()
	var added: Dictionary = core.command("editor_event_add p 0 %d 27" % cid)
	check(added.get("kind", "") == "event" and not field(added.fields, "years_min").is_empty() and not field(added.fields, "point_min").is_empty(),
		"an earthquake is added with its date and point fields: %s" % str(added.get("name", "")))
	var number := int(added.get("index", -1))
	var changed: Dictionary = core.command("editor_event_set p 0 %d %d years_min 3" % [cid, number])
	check(int(field(changed.get("fields", []), "years_min").get("value", -1)) == 3, "the event's years change")
	var invasion: Dictionary = core.command("editor_event_add p 0 %d 5" % cid)
	check(not field(invasion.fields, "count_min").is_empty() and not field(invasion.fields, "city_min").is_empty() and not field(invasion.fields, "hardcoded").is_empty(),
		"an invasion has its count, cities and the invasion's own choice")
	core.command("editor_event_remove p 0 %d %d" % [cid, int(invasion.index)])
	episode = core.command("editor_event_remove p 0 %d %d" % [cid, number])
	check(episode.cities[0].events.size() == events, "the events are removed")
	episode = core.command("editor_gods p 0 %d 0,13" % cid)
	check(episode.cities[0].gods.map(func(g): return int(g)) == [0, 13], "the city's friendly gods are Aphrodite and Zeus")
	var building: Dictionary = episode.cities[0].buildings[0]
	episode = core.command("editor_building p 0 %d %d 0" % [cid, int(building.type)])
	check(not bool(episode.cities[0].buildings[0].available), "%s is no longer allowed" % str(building.name))
	episode = core.command("editor_building p 0 %d %d 1" % [cid, int(building.type)])
	check(bool(episode.cities[0].buildings[0].available), "and is allowed again")
	episode = core.command("editor_max_sanctuaries p 0 %d 3" % cid)
	check(int(episode.cities[0].max_sanctuaries) == 3, "at most three sanctuaries")

	# ----------------------------------------------------------------------------------------------------------- the map
	var tiles := tiles_of(core.snapshot(true))
	var spot := Vector2i(99999, 99999)
	for cell in tiles:
		var tile: Array = tiles[cell]
		if int(tile[5]) == 1 and int(tile[4]) == 0 and not (int(tile[3]) & 4):
			var clear := true
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var near: Array = tiles.get(cell + Vector2i(dx, dy), [])
					clear = clear and not near.is_empty() and int(near[5]) == 1 and int(near[4]) == 0
			if clear:
				spot = cell
				break
	check(spot.x != 99999, "open ground to paint on (%s)" % str(spot))
	var painted: Dictionary = core.command("editor_paint water 1 square 3 %d %d" % [spot.x, spot.y])
	check(int(painted.get("changed", 0)) == 9, "a 3x3 square of water is painted (%s)" % str(painted))
	var after := tiles_of(core.snapshot(false))
	check(after.has(spot) and int(after[spot][3]) & 4, "the snapshot sends the painted tile as water")
	var high_spot := spot + Vector2i(6, 6)
	var raised: Dictionary = core.command("editor_paint raise 1 apply 1 %d %d %d %d" % [high_spot.x, high_spot.y, high_spot.x + 1, high_spot.y + 1])
	var later := tiles_of(core.snapshot(true))
	check(int(raised.get("changed", 0)) == 4 and bool(raised.get("heights", false)) and later.has(high_spot) and int(later[high_spot][2]) > int(tiles.get(high_spot, [0, 0, 0])[2]),
		"the area tool raises the ground (%s)" % str(raised))
	var woods := spot
	for cell in tiles:
		if int(tiles[cell][5]) == 1 and Vector2(cell).distance_to(Vector2(spot)) > 12.0 and tiles.has(cell + Vector2i(1, 1)) and tiles.has(cell - Vector2i(1, 1)):
			woods = cell
			break
	var forest: Dictionary = core.command("editor_paint forest 1 brush 2 %d %d" % [woods.x, woods.y])
	check(int(forest.get("changed", 0)) > 1, "the brush plants forest (%d tiles)" % int(forest.get("changed", 0)))
	check(core.command("editor_paint nonsense 1 brush 1 0 0").get("error", "") == "unknown_tool", "an unknown tool is refused")
	var time_before: float = float(core.snapshot(true).time)
	core.command("pause 0")
	for step in 20:
		core.advance(.25)
	check(float(core.snapshot(true).time) == time_before, "while editing the city never runs")
	check(core.command("build road %d %d 0" % [spot.x + 9, spot.y]).get("error", "") == "editing", "game commands are refused while editing")

	# --------------------------------------------------------------------------------------------------------- the world
	var world: Dictionary = core.command("editor_world")
	check(world.get("kind", "") == "editor_world" and world.cities.size() >= 2 and str(world.image).length() > 4, "the world lists %d cities on %s" % [world.get("cities", []).size(), str(world.get("image", ""))])
	var index := 1
	var city: Dictionary = core.command("editor_city %d" % index)
	check(not field(city.get("fields", []), "type").is_empty() and city.names.size() > 10, "a city's settings and the game's names")
	city = core.command("editor_city_set %d visible 0" % index)
	check(int(field(city.fields, "visible").value) == 0, "the city is made invisible")
	city = core.command("editor_city_name %d Testopolis" % index)
	city = core.command("editor_city_leader %d Kleon" % index)
	check(str(city.name) == "Testopolis" and str(city.leader) == "Kleon", "the city is renamed and given a leader")
	var marble: int = int(city.resources.filter(func(r): return str(r.label).to_lower().contains("marble"))[0].value) if city.resources.any(func(r): return str(r.label).to_lower().contains("marble")) else int(city.resources[0].value)
	city = core.command("editor_city_trade %d sells %d 20" % [index, marble])
	check(city.sells.any(func(t): return int(t.resource) == marble and int(t.max) == 20), "it sells a good, 20 a year")
	world = core.command("editor_city_move %d 0.25 0.75" % index)
	check(absf(float(world.cities[index].x) - .25) < .01 and absf(float(world.cities[index].y) - .75) < .01, "it moves on the map")
	var cities_before: int = world.cities.size()
	world = core.command("editor_city_add 0.5 0.5")
	check(world.cities.size() == cities_before + 1, "a city is added")
	var map_before := int(world.map)
	world = core.command("editor_world_map")
	check(int(world.map) != map_before, "the world picture changes")

	# ------------------------------------------------------------------------------------------------------ the interface
	var fake := FakePanel.new()
	fake.core = core
	var root_control := Control.new()
	get_root().add_child(root_control)
	var episodes = Episodes.new()
	episodes.attach(fake, root_control)
	episodes.rebuild()
	check(episodes.list.find_child("Parent0", true, false) != null and episodes.list.find_child("AddEpisode", true, false) != null and episodes.list.find_child("Colony3", true, false) != null,
		"the episodes window lists the parent episodes, Add episode and the four colonies")
	episodes.open_settings("p", 0)
	check(episodes.city_choice.item_count >= 1 and episodes.goal_kind.item_count == 14 and episodes.event_kind.item_count == 24 and episodes.buildings_box.get_child_count() >= 20,
		"an episode's settings window: cities, goal and event kinds, buildings")
	episodes.goal_kind.selected = 1
	episodes.episode = fake.query("editor_goal_add p 0 %d" % episodes.goal_kind.get_item_id(1))
	episodes.show_episode()
	check(episodes.goals_list.find_child("Goal%d" % goals, true, false) != null, "an added goal shows as a card with its form")
	var form_holder := VBoxContainer.new()
	root_control.add_child(form_holder)
	var seen := []
	Form.build(form_holder, [{"id": "n", "label": "Count", "kind": "int", "value": 3, "min": 0, "max": 9}, {"id": "c", "label": "Kind", "kind": "choice", "value": 2, "options": [{"value": 1, "label": "a"}, {"value": 2, "label": "b"}]},
		{"id": "b", "label": "On", "kind": "bool", "value": 1}], func(id, value): seen.append([id, value]))
	var spin: SpinBox = form_holder.get_node("Field_n/Value")
	spin.value = 5
	var choice: OptionButton = form_holder.get_node("Field_c/Value")
	check(choice.selected == 1 and seen.has(["n", 5]), "a form shows each field's value and sends its changes")
	episodes.settings.hide()
	episodes.window.hide()
	root_control.queue_free()
	await process_frame

	# ----------------------------------------------------------------------------------------------------------- saving
	var saved: Dictionary = core.command("editor_save")
	check(bool(saved.get("saved", false)), "the copy is saved")
	core.close_city()
	check(FileAccess.get_file_as_bytes(engine.path_join("Adventures/The Founding of Athens/The Founding of Athens.epak")) == original, "the player's own adventure is untouched")
	core.open_editor(engine, "folder", "The Founding of Athens", "en")
	var reopened: Dictionary = core.command("editor")
	check(reopened.date.map(func(v): return int(v)) == [5, 2, -1200] and int(reopened.funds[0].value) == 12345, "opened again, the date and funds are kept")
	var again: Dictionary = core.command("editor_episode p 0")
	check(again.cities[0].gods.map(func(g): return int(g)) == [0, 13] and int(again.cities[0].max_sanctuaries) == 3 and again.goals.size() == goals + 1, "the gods, the sanctuary limit and the goal are kept")
	var kept := tiles_of(core.snapshot(true))
	check(kept.has(spot) and int(kept[spot][3]) & 4, "the painted water is kept")
	var named: Dictionary = core.command("editor_city %d" % index)
	check(str(named.get("name", "")) == "Testopolis", "the renamed city is kept")
	# A terrain adaptation gets independent files, one blank episode and no colonies.
	var before_fork: Array = core.snapshot(true).tiles
	check(core.command("editor_single_parent Editor Test").get("error") == "name_taken" and core.command("editor_single_parent ../invalid").get("error") == "invalid_name", "fork refuses existing adventures and unsafe names")
	var forked: Dictionary = core.command("editor_single_parent Editor Fork")
	check(forked.parent.size() == 1 and forked.colonies.is_empty() and core.command("editor_episode p 0").goals.is_empty() and core.snapshot(true).tiles == before_fork, "fork retains parent terrain and resets episode/colony content")
	check(core.command("editor_difficulty 9").get("error") == "invalid_difficulty" and core.command("editor_difficulty 1").get("kind") == "editor", "editor difficulty is validated and explicitly changed")
	check(core.command("editor_save").saved, "fork writes its own native adventure")
	core.close_city()
	var fork_state: Dictionary = core.open_adventure(engine, "folder", "Editor Fork", "en")
	check(not fork_state.has("error") and core.command("episode").episode_count == 1 and int(core.command("difficulty").value) == 1, "zero-colony fork opens as a playable native adventure with the chosen difficulty")
	check(core.command("editor_single_parent Illegal").get("error") == "not_editing", "a running adventure refuses authoring forks")
	core.close_city()
	check(core.command("editor").get("error", "") != "", "with nothing open the editor's commands are refused")
	core.set_adventures_directory("")
	var plain: RefCounted = ClassDB.instantiate("EZeusSimulation")
	plain.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(plain.command("editor").get("error", "") == "not_editing", "a played city refuses the editor's commands")
	plain.close_city()
	remove_tree(scratch)
	print("EDITOR_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
