extends SceneTree
# Preserve the historical entry point without overwriting the new authored scene.
func _initialize() -> void:
	var scene: PackedScene = load("res://ui/login_scene_3d.tscn")
	if scene == null:
		quit(1)
		return
	print("Cinematic menu uses cinematic_menu_world.gd; earlier procedural scene/bake remains available.")
	quit()
