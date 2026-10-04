extends SceneTree
# Offline render of original authored meshes; runtime HUD uses static imported textures.
const Art = preload("res://ui/resource_art/resource_models.gd")
const KINDS = ["food_total","urchin","fish","meat","cheese","carrots","onions","grain","oranges","grapes","olives","wine","oil","fleece","wood","bronze","marble","arms","sculptures","orichalcum","black_marble","horses","chariots","silver"]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	DisplayServer.window_move_to_foreground()
	var viewport:=SubViewport.new();viewport.size=Vector2i(128,128);viewport.transparent_bg=true;viewport.own_world_3d=true
	root.add_child(viewport)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;viewport.add_child(camera)
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("b9cbd5");env.ambient_light_energy=.55
	environment.environment=env;viewport.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-35,0);light.light_energy=1.8;viewport.add_child(light)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,130,0);fill.light_energy=.55;fill.light_color=Color("95baca");viewport.add_child(fill)
	var manifest:=[]
	var sheet:=Image.create(768,512,false,Image.FORMAT_RGBA8);sheet.fill(Color("122e3e"))
	for kind in KINDS:
		var model: Node3D=Art.new().make(kind);viewport.add_child(model)
		var bounds:=AABB();var first:=true;var triangles:=0
		for part in model.get_children():
			var box: AABB=part.transform*part.get_aabb();bounds=box if first else bounds.merge(box);first=false
			var arrays: Array=part.mesh.surface_get_arrays(0)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size()/3
		var center:=bounds.get_center();camera.position=center+Vector3(3,2.4,4);camera.look_at(center);camera.size=maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))*1.45
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		for frame in 4:await process_frame
		await RenderingServer.frame_post_draw
		var icon:=viewport.get_texture().get_image()
		var slot: int=KINDS.find(kind);sheet.blend_rect(icon,Rect2i(0,0,128,128),Vector2i((slot%6)*128,(slot/6)*128))
		var error:=icon.save_png("res://ui/resource_art/"+kind+".png")
		var scene:=PackedScene.new();scene.pack(model);ResourceSaver.save(scene,"res://ui/resource_art/models/"+kind+".tscn")
		manifest.append({"resource":kind,"model":"models/"+kind+".tscn","triangles":triangles,"icon":kind+".png","source":"resource_models.gd","provenance":"original procedural meshes; no reference/native art extracted","needs_evidence":false})
		print("RESOURCE_ICON ",kind," triangles=",triangles," save=",error)
		model.queue_free();await process_frame
	FileAccess.open("res://ui/resource_art/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	sheet.save_png("res://captures/resources-art-sheet.png")
	print("RESOURCE_ICONS_RENDERED ",KINDS.size());quit()
