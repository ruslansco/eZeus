extends SceneTree
# Regenerates only the menu's disposable static geometry derivative, never game models.
func _initialize() -> void:
	Engine.set_meta("ezeus_menu_review",true)
	Engine.set_meta("ezeus_rebuild_menu",true)
	call_deferred("run")
func run() -> void:
	var source = load("res://scripts/olympian_menu_world.gd").new()
	root.add_child(source)
	var geometry := Node3D.new()
	geometry.name = "OlympianSanctuary"
	for child in source.get_children():
		if child is MeshInstance3D or child is MultiMeshInstance3D:
			var copy: Node = child.duplicate()
			geometry.add_child(copy)
			copy.owner = geometry
	var packed := PackedScene.new()
	var error := packed.pack(geometry)
	if error == OK: error = ResourceSaver.save(packed,source.BAKE,ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		push_error("Menu bake failed: %d" % error)
		quit(1)
		return
	var inputs := {}
	for path in source.BAKE_INPUTS: inputs[path] = FileAccess.get_sha256(path)
	var file := FileAccess.open(source.BAKE_MANIFEST,FileAccess.WRITE)
	file.store_string(JSON.stringify({"inputs":inputs,"triangles":source.geometry_triangles,"batches":source.mesh_instances,"source":"Original procedural Aegean sanctuary; retained local portal and model inputs. See olympian_menu_sources.json."},"\t")+"\n")
	print("OLYMPIAN_BAKE PASS triangles=",source.geometry_triangles," batches=",source.mesh_instances)
	geometry.free()
	source.free()
	quit()
