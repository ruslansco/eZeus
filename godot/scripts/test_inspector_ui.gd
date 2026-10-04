extends SceneTree
func _init():
	var inspector = load("res://scripts/building_inspector.gd").new()
	var data = {
		"trade": {
			"trading": true,
			"water": true,
			"two_way": false,
			"imports": [
				{
					"enabled": true,
					"max": 12.0,
					"name": "Wheat",
					"price": 30.0,
					"quota": 12.0,
					"resource": 64.0,
					"stock": 0.0,
					"used": 0.0
				}
			],
			"exports": [
				{
					"enabled": true,
					"max": 12.0,
					"name": "Urchin",
					"price": 30.0,
					"quota": 12.0,
					"resource": 1.0,
					"stock": 0.0,
					"used": 0.0
				}
			]
		}
	}
	var panel = VBoxContainer.new()
	panel.set_script(inspector.get_script())
	
	panel.show_inspection(data)
	panel.update_live_data()
	
	print("INSPECTOR HAS ", panel.get_child_count(), " CHILDREN")
	for c in panel.get_children():
		print(" - ", c.get_class(), " text: ", c.get("text"))
		if c is HBoxContainer:
			for gc in c.get_children():
				print("   - ", gc.get_class())
	quit()
