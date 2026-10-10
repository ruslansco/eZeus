extends SceneTree
# Native growth is observed in the designated city held in scratch memory only.
const Crops = preload("res://scripts/farm_crops.gd")
const Inspector = preload("res://scripts/building_inspector.gd")
var checks := 0
var okay := true

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("FARM_CROP_CHECK ","PASS " if value else "FAIL ",message)

func _initialize() -> void:
	call_deferred("run")

func find(state: Dictionary, id: int) -> Dictionary:
	for crop in state.get("farm_crops",[]):
		if int(crop.id)==id: return crop
	return {}

func run() -> void:
	var crops := Crops.new()
	root.add_child(crops)
	var mesh := crops.wheat_mesh()
	var arrays := mesh.surface_get_arrays(0)
	check(mesh.get_surface_count()==1 and arrays[Mesh.ARRAY_VERTEX].size()<=6000,"one shared wheat mesh stays within its 6,000-vertex field budget")
	var bounds := mesh.get_aabb()
	check(bounds.position.x>=-.5 and bounds.end.x<=.5 and bounds.position.z>=-.5 and bounds.end.z<=.5 and bounds.end.y<.75,"stalks, leaves and grain ears stay inside one field tile")
	check(RenderingServer.mesh_get_surface(mesh.get_rid(),0).get("lods",[]).size()==2,"two reduced crop LODs retain the shared geometry")
	check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size() and arrays[Mesh.ARRAY_TEX_UV2].size()==arrays[Mesh.ARRAY_VERTEX].size(),"both authored UV sets preserve late grain-head anchors")
	var group := [{"id":1,"field":0,"transform":Transform3D.IDENTITY,"progress":.25},{"id":2,"field":0,"transform":Transform3D(Basis.IDENTITY,Vector3(4,0,0)),"progress":.8}]
	crops.refresh_groups({"test":group})
	var node: Node = crops.nodes.test
	group[0].progress=.4
	crops.refresh_groups({"test":group})
	check(crops.nodes.test==node and crops.last_rebuilt==0 and crops.last_updates==1,"growth updates only the changed farm's GPU data without rebuilding placements")
	crops.refresh_groups({"test":group})
	check(crops.last_rebuilt==0 and crops.last_updates==0,"paused or unchanged crops require no GPU writes")
	crops.refresh_groups({})
	check(crops.nodes.is_empty(),"demolition or hiding an overlay removes its crop batches")
	crops.free()
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var source_hash := FileAccess.get_sha256(save)
	var scratch := "/tmp/ezeus-farm-crops-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	for language in ["en","ru"]:
		TranslationServer.set_locale(language)
		var state: Dictionary = core.open_city(engine,save,language)
		check(state.has("farm_crops"),language+" native snapshot exposes crops separately from architecture")
		var farm := {}
		for building in state.buildings:
			var crop := find(state,int(building.id))
			if not crop.is_empty() and crop.crop=="wheat": farm=building; break
		if farm.is_empty():
			for tile in state.tiles:
				if int(tile[5])==0 or (int(tile[3])&8)==0: continue
				var preview: Dictionary = core.command("preview wheat_farm %d %d 0" % [tile[0],tile[1]])
				if not preview.get("valid",false): continue
				core.command("build wheat_farm %d %d 0" % [tile[0],tile[1]])
				state=core.snapshot(true)
				for building in state.buildings:
					if int(building.x)==int(preview.x) and int(building.y)==int(preview.y): farm=building; break
				break
		check(not farm.is_empty(),language+" wheat farm found or built through native fertile-land placement")
		if farm.is_empty(): continue
		var id := int(farm.id)
		var query := "inspect %d %d" % [farm.x,farm.y]
		core.command("set_priority 0 5")
		state=core.snapshot(true)
		var info: Dictionary = core.command(query)
		var crop := find(state,id)
		check(info.production.has("harvest_progress") and is_equal_approx(float(info.production.harvest_progress),float(crop.progress)),language+" inspector percentage and 3D growth read the same native cycle")
		var before: Dictionary = core.replay(0,7)
		for i in 8:
			core.snapshot(false); core.command(query)
		check(core.replay(0,-1).save==before.save,language+" repeated growth observations preserve serialized state and RNG")
		var panel := Inspector.new(); root.add_child(panel)
		panel.show_inspection(info)
		check(panel.harvest_label!=null and panel.harvest_label.text.contains("%") and is_equal_approx(panel.harvest_bar.value,float(crop.progress)*100),language+" building panel shows native readiness and a progress bar")
		check(not core.snapshot(false).buildings_changed,language+" repeated crop observations retain the cached architecture list")
		core.command("pause 1")
		core.advance(.5)
		check(is_equal_approx(float(find(core.snapshot(false),id).progress),float(crop.progress)),language+" pause holds native crop progress")
		# Replay advances ordinary native ticks; it never grants resources or farm maturity.
		core.replay(300,7)
		state=core.snapshot(true); crop=find(state,id); info=core.command(query)
		check(not crop.is_empty() and float(crop.progress)>=0 and float(crop.progress)<=1 and int(crop.fields)>=1 and int(crop.fields)<=5,language+" ordinary native ticks expose bounded growth and staffed fields")
		print("FARM_SAMPLE ",language," ",JSON.stringify({"farm":farm,"crop":crop,"production":info.production,"workers":info.get("employees",0)}))
		check(int(info.get("employees",0))>0,language+" ordinary farming workforce priority staffs the farm")
		if int(info.get("employees",0))>0:
			check(float(crop.progress)>0,language+" staffed farm grows during native simulation")
			var shutdown := "industry %d %d %d 64 1" % [farm.x,farm.y,int(info.target_token)]
			core.command(shutdown)
			var stopped := find(core.snapshot(false),id)
			core.replay(60,-1)
			check(is_equal_approx(float(find(core.snapshot(false),id).progress),float(stopped.progress)),language+" native industry shutdown freezes growth")
			info=core.command(query)
			core.command("industry %d %d %d 64 0" % [farm.x,farm.y,int(info.target_token)])
		# Save/load retains mRipe and mNextRipe without any new binary fields.
		crop=find(core.snapshot(false),id)
		check(core.save_city("crop roundtrip").has("saved"),language+" native farm state saves to scratch")
		core.close_city(); core.open_city(engine,scratch.path_join("crop roundtrip.ez"),language)
		info=core.command(query)
		check(is_equal_approx(float(info.production.harvest_progress),float(crop.progress)),language+" native save/load preserves exact harvest readiness")
		panel.free()
		core.close_city()
	check(FileAccess.get_sha256(save)==source_hash,"designated source save remains unchanged")
	for file in DirAccess.get_files_at(scratch): DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	print("FARM_CROP_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
