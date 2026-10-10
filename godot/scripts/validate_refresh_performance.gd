extends SceneTree
const Checks = preload("res://scripts/refresh_performance_checks.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var validation := Checks.new()
	validation.run(self)
	await process_frame
	print("REFRESH_PERFORMANCE_VALIDATION ", "PASS" if validation.okay else "FAIL", " checks=", validation.checks)
	quit(0 if validation.okay else 1)
