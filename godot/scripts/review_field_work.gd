extends SceneTree
const Motion = preload("res://scripts/gathering_motion.gd")
const Batches = preload("res://scripts/building_batches.gd")
var city: Node3D
var previews := []
var fixtures := []
var recorded := 0
func _initialize() -> void:
 Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
 Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
 call_deferred("run")
func actor(asset: String, at: Vector3, action: int) -> Dictionary:
 var node: Node3D=city.model(asset);city.world.add_child(node);node.position=at
 previews.append(node)
 node.rotation.y=deg_to_rad(90)
 var morphs: Array=node.get_meta("vat_parts") if node.has_meta("vat_parts") else []
 if morphs.is_empty():city.collect_morphs(node,morphs)
 var entry: Dictionary=city.new_walker_entry(node,asset,-1,at,0,morphs)
 entry.facing=6;entry.action=action;entry.field_load=1;entry.field_task="lead_cattle";entry.preview_start=at
 fixtures.append(entry);return entry
func prop(asset: String, at: Vector3) -> Node3D:
 var node: Node3D=city.model(asset);city.world.add_child(node);node.position=at;previews.append(node);return node
func clear_preview() -> void:
 for node in previews:node.queue_free()
 previews.clear();fixtures.clear()
func capture(name: String, start: Vector3, gallery := false) -> void:
 city.orbit.target=start+Vector3.UP*.35
 city.orbit.distance=8.0 if name=="corral" else (5.8 if gallery else 4.6);city.orbit.pitch=46;city.orbit.yaw=35;city.orbit.refresh()
 var directory:=OS.get_environment("EZEUS_FIELD_FRAME_DIRECTORY")
 for frame in 64:
  var clock:=float(frame)*.1
  city.water_life.receive({"time":clock*30,"running":true});city.water_life.advance(.1)
  city.static_batches.activity.receive({"time":clock*30,"running":true});city.static_batches.activity.advance(.1)
  for entry in fixtures:
   var previous: Vector3=entry.native_position
   var carries: bool=entry.asset in ["walker_hunter","walker_shepherd","walker_deerhunter","walker_goatherd"] and clock>=3.6
   if carries:entry.action=14
   if entry.asset=="animal_boar" and gallery:
    if clock>=3.0:entry.action=6
    entry.node.visible=clock<3.6
   if carries or entry.asset in ["walker_rancher","animal_cattle"]:
    var progress:=maxf(0,clock-(3.6 if carries else 0.0))*.16
    entry.native_position=entry.preview_start+Vector3.LEFT*progress
   entry.node.position=city.walker_surface_position(entry.native_position,0,true)
   city.animate_walker(entry,.1,(entry.native_position-previous).length())
   Motion.apply(entry,city,clock)
  await process_frame
  RenderingServer.force_draw(true,.016)
  if frame in [25,50]:root.get_texture().get_image().save_png("res://captures/field-work-"+name+("-work" if frame==25 else "-return")+".png")
  if gallery and not directory.is_empty():
   root.get_texture().get_image().save_png(directory.path_join("%04d.png"%recorded));recorded+=1
 print("FIELD_WORK_VIEW PASS ",name)
func run() -> void:
 city=load("res://main.tscn").instantiate();root.add_child(city)
 while city.state.is_empty() or city.frame_count<80:await process_frame
 city.core.query("pause 1");city.core.set_process(false);city.set_process(false);city.orbit.enabled=false;city.ui_layer.visible=false
 DisplayServer.window_move_to_foreground()
 var cell:=Vector2i.ZERO;var found:=false
 for tile in city.tiles.values():
  if int(tile[3]) & (4|16) or int(tile[4]) or int(tile[6]) & 8:continue
  if not city.terrain_details.resource(tile).is_empty():continue
  var clear:=true
  for dx in range(-3,4):
   for dy in range(-2,3):
    var neighbor: Array=city.tiles.get(Vector2i(tile[0]+dx,tile[1]+dy),[])
    clear=clear and not neighbor.is_empty() and int(neighbor[2])==int(tile[2]) and not (int(neighbor[3]) & (4|16)) and not int(neighbor[4]) and not (int(neighbor[6]) & 8)
    if not neighbor.is_empty():clear=clear and city.terrain_details.resource(neighbor).is_empty()
  if clear:cell=Vector2i(tile[0],tile[1]);found=true;break
 if not found:print("FIELD_WORK_REVIEW FAIL no clear native ground");quit(1);return
 var base: Vector3=city.world_position(cell.x,cell.y,city.tiles[cell][2])
 print("FIELD_WORK_REVIEW render-only fixtures on native ground; simulation and save unchanged")
 actor("walker_hunter",base+Vector3.LEFT*1.65,4)
 actor("animal_boar",base+Vector3.LEFT*1.65,4)
 actor("walker_shepherd",base,7)
 actor("walker_orangetender",base+Vector3.RIGHT*1.65,13)
 prop("orange_3",base+Vector3.RIGHT*1.65)
 await capture("gallery",base,true);clear_preview();await process_frame
 for view in [["boar","walker_hunter",14,""],["deer","walker_deerhunter",4,""],["goatherd","walker_goatherd",7,""],["grapes","walker_grower",8,"vine_3"],["olives","walker_grower",12,"olive_3"],["oranges","walker_orangetender",10,"orange_3"]]:
  actor(view[1],base,view[2])
  if not str(view[3]).is_empty():prop(view[3],base)
  await capture(view[0],base);clear_preview();await process_frame
 var batch:=Batches.new();city.world.add_child(batch);previews.append(batch)
 batch.rebuild({"corral|preview":[{"transform":Transform3D(Basis.IDENTITY,base),"working":true,"animation_offset":0}]})
 actor("walker_rancher",base+Vector3(0,0,3.1),3)
 actor("animal_cattle",base+Vector3(.65,0,3.1),3)
 await capture("corral",base+Vector3(1,0,.7));clear_preview();await process_frame
 print("FIELD_WORK_REVIEW PASS hunting/carry, shearing, milking, orchards and corral work captured")
 city.queue_free();await process_frame;await process_frame;quit(0)
