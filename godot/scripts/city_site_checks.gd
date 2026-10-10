extends RefCounted
const Sites=preload("res://scripts/building_sites.gd")
const Guidance=preload("res://ui/city_guidance.gd")

class Ground extends RefCounted:
	var calls:=0
	var level:=0.0
	var slope:=0.0
	func height_at(x: float, _y: float) -> float:calls+=1;return level+x*slope

class Lot extends Node:
	var tiles: Dictionary={}
	var terrain_geometry:=Ground.new()
	func tile_coordinates(point: Vector3) -> Vector2:return Vector2(point.x,-point.z)
	func world_position(x: float, y: float, height: float) -> Vector3:return Vector3(x,height*.22,-y)

func run(city: Node, check: Callable) -> void:
	var native: Dictionary=city.core.simulation.snapshot(true)
	var sites: Node=city.building_sites
	var vertices: int=sites.support_vertices;var beams: int=sites.scaffold_instances
	sites.refresh(city.state.buildings,city)
	check.call(sites.rebuilt==0 and sites.support_vertices==vertices and sites.scaffold_instances==beams,"unchanged work and stock observations reuse site geometry")
	check.call(not Sites.supported("gatehouse") and not Sites.supported("harbour") and not Sites.supported("common_house_0a"),"supports retain open gates, shore structures and starter earth lots")
	var textured:=StandardMaterial3D.new();textured.vertex_color_use_as_albedo=true;textured.normal_texture=GradientTexture2D.new()
	check.call(not preload("res://scripts/building_construction.gd").plain_palette(textured),"finish/reveal adapters retain normal-map-only PBR materials")
	var lot:=Lot.new()
	for x in range(-1,3):
		for y in range(-1,3):lot.tiles[Vector2i(x,y)]=[x,y,0,1,0,1,8,0]
	var building: Dictionary={"id":-990,"asset":"warehouse","x":0,"y":0,"w":2,"h":2}
	var base: Dictionary={"low":0.0,"height":2.0,"polygon":PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1),Vector2(-1,-1)])}
	var placement:=Transform3D(Basis.IDENTITY,Vector3(.5,0,-.5))
	check.call(sites.support(building,placement,base,lot).vertices.is_empty(),"level lot adds no support faces or new flat-ground draw")
	placement.origin.y=.3;lot.terrain_geometry.slope=.1
	var skin: Dictionary=sites.support(building,placement,base,lot)
	var valid: bool=not skin.vertices.is_empty()
	for point in skin.vertices:
		valid=valid and point.x>=-.46001 and point.x<=1.46001 and point.z>=-1.46001 and point.z<=.46001 and point.y>=-.05401
	check.call(valid,"sloped supports meet the sampled ground within the native lot")
	for cell in lot.tiles:lot.tiles[cell][4]=1
	check.call(sites.support(building,placement,base,lot).vertices.is_empty(),"supports never cover road tiles")
	for cell in lot.tiles:lot.tiles[cell][4]=0;lot.tiles[cell][3]=4
	check.call(sites.support(building,placement,base,lot).vertices.is_empty(),"supports never fill water")
	lot.tiles.clear();check.call(sites.support(building,placement,base,lot).vertices.is_empty(),"supports never create land outside an irregular map")
	lot.free()
	var stages: Dictionary={"id":-991,"asset":"sanctuary_temple_0","x":0,"y":0,"w":4,"h":4,"grow":25}
	var quarter:=Transform3D(Basis.from_scale(Vector3(1,.25,1)),Vector3.ZERO)
	var first: Array=sites.scaffolding(stages,quarter,3.0)
	check.call(first.size()>8,"unfinished native monument geometry gets timber posts, rails and braces")
	var bounded:=true
	for beam in first:
		for sign in [-.5,.5]:
			var end: Vector3=beam*Vector3(0,sign,0)
			bounded=bounded and absf(end.x)<=1.9101 and absf(end.z)<=1.9101 and end.y>=-.0001 and end.y<=.9101
	check.call(bounded,"scaffolding stays within its lot and rises to the current build stage")
	var revealing: Dictionary=stages.duplicate();revealing.id=-994;revealing.altitude=0
	var revealed: Transform3D=city.building_draw_transform(revealing)
	check.call(city.static_batches.construction.active(revealing) and revealed.basis.y.length()>.99,"compatible monument stages retain full architectural proportions")
	var clipped: Array=sites.scaffolding(stages,Transform3D.IDENTITY,3,true)
	check.call(clipped[0].basis.y.length()<1,"reveal-stage scaffolding rises only with the native completed fraction")
	var batches:=preload("res://scripts/building_batches.gd").new();city.world.add_child(batches)
	var rows: Array=[{"transform":Transform3D.IDENTITY,"constructing":true,"construction_top":20.25},{"transform":Transform3D(Basis.IDENTITY,Vector3(6,0,0)),"constructing":false,"construction_top":0.0}]
	batches.rebuild({"sanctuary_temple_0|review":rows})
	var custom:=true
	for node in batches.group_nodes["sanctuary_temple_0|review"]:
		var batch: MultiMesh=node.multimesh
		var data: PackedColorArray=node.get_meta("activity_data")
		var first_upload: Color=data[0] if DisplayServer.get_name()=="headless" else batch.get_instance_custom_data(0)
		var second_upload: Color=data[1] if DisplayServer.get_name()=="headless" else batch.get_instance_custom_data(1)
		custom=custom and batch.use_custom_data and is_equal_approx(first_upload.b,1) and is_equal_approx(first_upload.a,20.25) and is_zero_approx(second_upload.b)
	check.call(custom,"construction flags and unclamped world heights remain independent per building (GPU readback on Metal)")
	rows[0].construction_top=21.5;batches.rebuild({"sanctuary_temple_0|review":rows})
	check.call(batches.last_rebuilt==0 and batches.last_activity_updates>0,"a reveal-height change uploads only instance data without rebuilding geometry")
	batches.free()
	sites.refresh([revealing],city)
	check.call(sites.scaffold_instances>0,"runtime site batches show a partially built monument's scaffolding")
	revealing.grow=100;sites.refresh([revealing],city)
	check.call(sites.scaffold_instances==0,"runtime completion removes timber without changing the monument mesh")
	sites.refresh(city.state.buildings,city)
	var diagonal: Transform3D=Sites.beam(Vector3.ZERO,Vector3(1,2,3),.03)
	check.call((diagonal*Vector3(0,-.5,0)).is_equal_approx(Vector3.ZERO) and (diagonal*Vector3(0,.5,0)).is_equal_approx(Vector3(1,2,3)),"braces preserve exact end positions at every heading")
	stages.grow=100
	check.call(sites.scaffolding(stages,quarter,3).is_empty(),"finished monuments remove their scaffolding")
	stages.grow=0;stages.stretch=true;stages.asset="sanctuary_court_0"
	check.call(sites.scaffolding(stages,quarter,3).is_empty(),"native foundation-only stages retain their paved slab")
	var paused: Dictionary={"finished":false,"halted":true,"road":false,"needed":{"wood":4},"employees":0}
	check.call(Guidance.construction_advice(paused)==city.tr("Construction is paused. Resume it with the button below when you are ready."),"construction advice leads with an explicit native halt")
	paused.halted=false
	check.call(Guidance.construction_advice(paused)==city.tr("Construction needs road access. Connect the monument to the road used by your artisans and deliveries."),"disconnected construction explains delivery and artisan roads")
	paused.road=true
	check.call(Guidance.construction_advice(paused).contains("4") and Guidance.construction_advice(paused).contains(city.tr("Timber")),"construction reports exact undelivered native materials")
	paused.needed={}
	check.call(Guidance.construction_advice(paused)==city.tr("Materials are ready. A staffed artisans' guild must send builders along a connected road."),"supplied construction with no artisans has a clear next action")
	paused.employees=2
	check.call(Guidance.construction_advice(paused)==city.tr("Builders are assigned. Keep deliveries flowing; construction advances while the city runs."),"staffed construction preserves native work semantics")
	# Newly begun empty adventures offer help once; this uses disposable presentation
	# observations only and cannot replace the actual native city or its callbacks.
	var saved: Dictionary=city.state;var pause: bool=city.core.simulation.snapshot(false).paused
	city.state=city.state.duplicate();city.state.housing={"people":0}
	Engine.set_meta("ezeus_offer_settlement_guide",true);city.offer_settlement_guide()
	check.call(city.city_help.visible and city.city_help.tab=="guide" and city.core.simulation.snapshot(false).paused==pause,"first empty settlement offers the non-modal guide without changing pause")
	city.city_help.step=5;city.city_help.render()
	var finish: Array=city.city_help.body.find_children("*","Button",true,false).filter(func(node):return node.text==city.tr("Finish guide"))
	finish[0].pressed.emit()
	Engine.set_meta("ezeus_offer_settlement_guide",true);city.offer_settlement_guide()
	check.call(not city.city_help.visible,"finishing the guide remembers the choice and prevents repeat automatic openings")
	preload("res://scripts/user_settings.gd").set_value("interface","settlement_guide_finished",false)
	city.state=saved
	var after: Dictionary=city.core.simulation.snapshot(true)
	check.call(native.tiles==after.tiles and native.buildings==after.buildings and native.walkers==after.walkers and native.time==after.time and native.money==after.money,"site geometry, guide offers and advice leave native state unchanged")

func visual(city: Node, language: String) -> void:
	# Isolated studio samples of real imported geometry and native stage transforms.
	# No fixture is installed, saved, selectable or included in simulation records.
	var fixture:=Node3D.new();city.add_child(fixture)
	var center: Vector3=city.orbit.target
	fixture.position=center
	var pad:=MeshInstance3D.new();var plane:=BoxMesh.new();plane.size=Vector3(18,.08,7);pad.mesh=plane
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.34,.40,.36);material.roughness=.95
	pad.material_override=material;pad.position.y=-.045;fixture.add_child(pad)
	for index in 3:
		var progress: int=[25,65,100][index]
		var building: Dictionary={"asset":"sanctuary_temple_0","x":0,"y":0,"w":4,"h":4,"grow":progress}
		var position:=Vector3((index-1)*5.5,0,0)
		var basis: Basis=city.model_basis(building.asset,4,4,0)
		var transform:=Transform3D(basis,position)
		var site: Node=city.building_sites
		var full: Dictionary=site.shape(building.asset,city.static_batches)
		var top: float=fixture.global_position.y+position.y+(float(full.low)+float(full.height)*progress*.01)*basis.y.length()
		for piece in city.static_batches.template(building.asset):
			var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_custom_data=true;batch.mesh=piece.mesh;batch.instance_count=1
			batch.set_instance_transform(0,transform*piece.transform);batch.set_instance_custom_data(0,Color(0,0,1 if progress<100 else 0,top))
			var instance:=MultiMeshInstance3D.new();instance.multimesh=batch;instance.material_override=piece.material;fixture.add_child(instance)
		for beam in site.scaffolding(building,transform,float(full.height),true):
			var timber:=MeshInstance3D.new();timber.mesh=site.cube;timber.material_override=site.timber;timber.transform=beam;fixture.add_child(timber)
		var label:=Label3D.new();label.text="%d%%"%progress;label.position=position+Vector3(0,.03,2.6);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=72;label.pixel_size=.005;fixture.add_child(label)
	city.world.hide();city.horizon.hide();city.hud.hide()
	city.orbit.target=center;city.orbit.distance=17;city.orbit.yaw=0;city.orbit.pitch=48;city.orbit.refresh()
	var caption:=Label.new();caption.text="Construction presentation samples · 25 / 65 / 100%";caption.position=Vector2(28,28);caption.theme_type_variation="ToolHeading";city.ui_layer.add_child(caption)
	for i in 12:await city.get_tree().process_frame
	await RenderingServer.frame_post_draw
	city.get_viewport().get_texture().get_image().save_png("res://captures/city-sites-"+language+"-stages.png")
	caption.queue_free();fixture.queue_free();city.world.show();city.horizon.show();city.hud.show()
	for i in 3:await city.get_tree().process_frame
	await support_visual(city,language)

func support_visual(city: Node, language: String) -> void:
	var before: Vector3=city.orbit.target
	var fixture:=Node3D.new();fixture.position=before;city.add_child(fixture)
	var lot:=Lot.new();lot.terrain_geometry.slope=.12
	for x in range(-3,4):
		for y in range(-3,4):lot.tiles[Vector2i(x,y)]=[x,y,0,1,0,1,8,0]
	var land:=SurfaceTool.new();land.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array=[Vector3(-2,-.24,-2),Vector3(3,.36,-2),Vector3(3,.36,3),Vector3(-2,-.24,3)]
	for index in [0,1,2,0,2,3]:land.set_normal(Vector3(-.12,1,0).normalized());land.add_vertex(corners[index])
	var ground:=MeshInstance3D.new();ground.mesh=land.commit()
	var grass:=StandardMaterial3D.new();grass.albedo_color=Color(.34,.41,.28);grass.roughness=.95;ground.material_override=grass;fixture.add_child(ground)
	var building: Dictionary={"id":-993,"asset":"common_house_2a","x":0,"y":0,"w":2,"h":2}
	var placement:=Transform3D(Basis.IDENTITY,Vector3(.5,.42,-.5))
	var holder:=Node3D.new();holder.transform=placement;holder.add_child(city.model(building.asset));fixture.add_child(holder)
	var sites: Node=city.building_sites
	var skin: Dictionary=sites.support(building,placement,sites.shape(building.asset,city.static_batches),lot)
	var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=skin.vertices;arrays[Mesh.ARRAY_NORMAL]=skin.normals;arrays[Mesh.ARRAY_COLOR]=skin.colors
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var skirt:=MeshInstance3D.new();skirt.mesh=mesh;skirt.material_override=sites.stone;fixture.add_child(skirt)
	city.world.hide();city.horizon.hide();city.hud.hide();city.orbit.target=before+Vector3(.5,.5,-.5);city.orbit.distance=7;city.orbit.yaw=35;city.orbit.pitch=35;city.orbit.refresh()
	var caption:=Label.new();caption.text="Ground contact sample · native building stays level";caption.position=Vector2(28,28);caption.theme_type_variation="ToolHeading";city.ui_layer.add_child(caption)
	for i in 12:await city.get_tree().process_frame
	await RenderingServer.frame_post_draw
	city.get_viewport().get_texture().get_image().save_png("res://captures/city-sites-"+language+"-support.png")
	caption.queue_free();fixture.queue_free();lot.free();city.world.show();city.horizon.show();city.hud.show()
	for i in 3:await city.get_tree().process_frame
