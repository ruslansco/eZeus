extends Node3D
# Physical menu housings under the existing accessible Control text/input layer.
# Project every housing from the Control's current bounds: pointer targets, focus,
# scrolling and independent UI/text scaling remain exact, including reduced motion.
var menu: Control
var world: Node3D
var camera: Camera3D
var entries: Array[Dictionary] = []
var bronze: StandardMaterial3D
var marble: StandardMaterial3D
var obsidian: StandardMaterial3D
var selected: StandardMaterial3D
var base_button: StandardMaterial3D

func setup(host: Control, scenery: Node3D) -> void:
	menu = host
	world = scenery
	camera = world.camera
	if camera == null:
		free()
		return
	name = "OlympianMenuSurfaces"
	camera.add_child(self)
	bronze = world.finish(Color("bc9250"),.55,.32)
	marble = world.finish(Color("e5d5ae"),.15,.46)
	obsidian = world.finish(Color("10272e"),0.0,.85)
	obsidian.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selected = world.finish(Color("76512a"),.40,.34)
	base_button = world.finish(Color("23434b"),0.0,.85)
	base_button.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selected.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for page in menu.pages.values():
		add_surface(page,true)
	for button in [menu.new_game_button,menu.continue_button,menu.load_game_button,menu.adventure_start,menu.adventure_back,menu.load_open,menu.load_back,menu.leader_proceed,menu.leader_back]:
		add_surface(button,false)

func clear_style(control: Control, name: String) -> void:
	var original := control.get_theme_stylebox(name)
	var style := StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_content_margin(side,original.get_content_margin(side))
	control.add_theme_stylebox_override(name,style)

func add_surface(control: Control, shell: bool) -> void:
	if shell: clear_style(control,"panel")
	else:
		for state in ["normal","hover","pressed","disabled"]: clear_style(control,state)
	var mount := Node3D.new()
	mount.name = "Stone_" + str(control.name)
	add_child(mount)
	var rim := MeshInstance3D.new()
	rim.material_override = marble if shell else bronze
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mount.add_child(rim)
	var face := MeshInstance3D.new()
	face.material_override = obsidian if shell else base_button
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mount.add_child(face)
	var crown := MeshInstance3D.new()
	crown.material_override = bronze
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mount.add_child(crown)
	entries.append({"control":control,"mount":mount,"rim":rim,"face":face,"crown":crown,"shell":shell,"size":Vector2.ZERO,"lift":0.0})

func visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents: rect = rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return rect

func _process(delta: float) -> void:
	if camera == null: return
	var reduced: bool = get_node("/root/UiAccess").reduced_motion
	for entry in entries:
		var control: Control = entry.control
		var rect := visible_rect(control)
		entry.mount.visible = control.is_visible_in_tree() and rect.size.x > 1 and rect.size.y > 1
		if not entry.mount.visible: continue
		var active: bool = not entry.shell and not control.disabled and (control.is_hovered() or control.has_focus())
		var target := .024 if active else 0.0
		if not entry.shell and control.button_pressed: target = -.006
		entry.lift = target if reduced else move_toward(float(entry.lift),target,delta*.22)
		var base_depth: float = 3.0 if entry.shell else 2.91
		var depth: float = base_depth-float(entry.lift)
		var a := camera.to_local(camera.project_position(rect.position,depth))
		var b := camera.to_local(camera.project_position(rect.end,depth))
		var size := Vector2(absf(b.x-a.x),absf(b.y-a.y))*(base_depth/depth)
		entry.mount.scale = Vector3.ONE*(depth/base_depth)
		entry.mount.position = (a+b)*.5
		if not size.is_equal_approx(entry.size):
			entry.size = size
			var border := .016 if entry.shell else .006
			entry.rim.mesh = world._bevel_box(Vector3(size.x+.018,size.y+.018,.09 if entry.shell else .032),.012 if entry.shell else .005)
			entry.face.mesh = world._bevel_box(Vector3(maxf(.01,size.x-border),maxf(.01,size.y-border),.03),.009 if entry.shell else .005)
			entry.face.position.z = .04 if entry.shell else .014
			entry.crown.mesh = world._bevel_box(Vector3(size.x*.90,.009,.012),.002)
			entry.crown.position = Vector3(0,size.y*.5-.018,.055)
		if not entry.shell:
			entry.face.material_override = selected if active else base_button
