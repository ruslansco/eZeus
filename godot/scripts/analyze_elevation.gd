extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var state: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	if not state.has("tiles"):
		print(state)
		quit(1)
		return
	var heights := {}
	var categories := {}
	var tiles := {}
	for tile in state.tiles:
		tiles[Vector2i(int(tile[0]),int(tile[1]))] = tile
		heights[str(tile[2])] = heights.get(str(tile[2]),0) + 1
		categories[str(tile[6])] = categories.get(str(tile[6]),0) + 1
	var edges := {}
	var examples := {}
	for cell in tiles:
		var tile: Array = tiles[cell]
		if int(tile[6]) & 1:
			var label := "ramp" if int(tile[6]) & 2 else "cliff"
			if not examples.has(label):
				examples[label] = []
			if examples[label].size() < 8:
				var neighbors := []
				for y in range(-1,2):
					for x in range(-1,2):
						neighbors.append(tiles.get(cell+Vector2i(x,y),[]))
				examples[label].append(neighbors)
		for delta in [Vector2i.RIGHT,Vector2i.UP]:
			var neighbor: Array = tiles.get(cell+delta,[])
			if neighbor.is_empty():
				continue
			var difference := absf(tile[2] - neighbor[2])
			edges[str(difference)] = edges.get(str(difference),0) + 1
	var file := FileAccess.open("res://captures/elevation-city.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(state))
	var report := {"heights":heights,"geometry_flags":categories,"edge_differences":edges,"examples":examples}
	file = FileAccess.open("res://captures/elevation-analysis.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("ELEVATION_ANALYSIS ",JSON.stringify(report))
	core.close_city()
	quit()
