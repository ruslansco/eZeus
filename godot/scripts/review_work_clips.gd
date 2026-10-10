# Render-only review of the townspeople's work clips (5 October): fixtures on native ground; simulation and save unchanged.
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
func capture(name: String, start: Vector3) -> void:
 city.orbit.target=start+Vector3.UP*.35
 city.orbit.distance=6.4;city.orbit.pitch=38;city.orbit.yaw=20;city.orbit.refresh()
 for frame in 40:
  var clock:=float(frame)*.1
  city.water_life.receive({"time":clock*30,"running":true});city.water_life.advance(.1)
  for entry in fixtures:
   var previous: Vector3=entry.native_position
   if int(entry.action)==14:entry.native_position=entry.preview_start+Vector3.FORWARD*clock*.16
   entry.node.position=city.walker_surface_position(entry.native_position,0,true)
   city.animate_walker(entry,.1,(entry.native_position-previous).length())
   Motion.apply(entry,city,clock)
  await process_frame
  RenderingServer.force_draw(true,.016)
  if frame in [14,29]:root.get_texture().get_image().save_png("res://captures/work-clips-"+name+"-%d.png"%frame)
 print("WORK_CLIPS_VIEW PASS ",name)
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
 if not found:print("WORK_CLIPS_REVIEW FAIL no clear native ground");quit(1);return
 var base: Vector3=city.world_position(cell.x,cell.y,city.tiles[cell][2])
 var row := [["walker_firefighter",4],["walker_lumberjack",7],["walker_bronzeminer",7],["walker_marbleminer",7],["walker_artisan",20],["walker_artisan",21],["walker_silverminer",7]]
 for i in row.size():actor(row[i][0],base+Vector3.RIGHT*(i-3)*.9,row[i][1])
 await capture("work",base);clear_preview();await process_frame
 var carry := ["walker_firefighter","walker_lumberjack","walker_bronzeminer","walker_orichalcminer"]
 for i in carry.size():actor(carry[i],base+Vector3.RIGHT*(i-1.5)*.9,14)
 await capture("carry",base);clear_preview();await process_frame
 print("WORK_CLIPS_REVIEW PASS")
 city.queue_free();await process_frame;await process_frame;quit(0)
