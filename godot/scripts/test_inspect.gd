extends SceneTree
func _init():
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	core.open_city(engine, save, "en")
	
	# Build a Granary at 150, 10
	core.command("build 150 10 35")
	
	var res: Dictionary = core.command("inspect 150 10")
	if res.has("storage"):
		print("FOUND Granary AT 150 10: ", JSON.stringify(res))
	quit()
