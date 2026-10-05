extends SceneTree
var city: Node3D
func _initialize() -> void:
 Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
 Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
 call_deferred("run")
func run() -> void:
 city = load("res://main.tscn").instantiate(); root.add_child(city)
 while city.state.is_empty() or city.frame_count < 80: await process_frame
 city.core.query("pause 1"); city.core.set_process(false); city.set_process(false)
 city.orbit.enabled=false; city.ui_layer.visible=false
 DisplayServer.window_move_to_foreground()
 var core: RefCounted = city.core.simulation
 var state: Dictionary = core.snapshot(true)
 var spot: Array = []
 var fish: Array = []
 for tile in state.tiles:
  if city.water_life.resource_mask(tile) & 2 and spot.is_empty(): spot=tile
  if city.water_life.resource_mask(tile) & 1 and fish.is_empty(): fish=tile
 if fish.is_empty():
  print("WATER_LIFE_REVIEW FAIL designated map lacks fish resources"); city.queue_free(); await process_frame; quit(1); return
 if spot.is_empty():
  # Designated map has no native urchins. Only a copied presentation tile gets
  # bit 2, on real unoccupied water near the genuine fish deposit.
  for tile in state.tiles:
   if tile.size()>=10 and int(tile[3]) & 4 and not int(tile[4]) and not (int(tile[6]) & 8) and Vector2(float(tile[0]-fish[0]),float(tile[1]-fish[1])).length() >= 2.0 and Vector2(float(tile[0]-fish[0]),float(tile[1]-fish[1])).length() <= 4.0:
    spot=tile; spot[9]=int(spot[9])|2; break
  print("WATER_LIFE_REVIEW urchin spot is a presentation-only fixture; no native urchin deposits in this map")
 print("WATER_LIFE_REVIEW native counts ",city.water_life.spot_counts)
 city.receive_state(state)
 city.orbit.target=city.world_position((float(spot[0])+float(fish[0]))*.5,(float(spot[1])+float(fish[1]))*.5,fish[2])
 city.orbit.distance=10; city.orbit.pitch=55; city.orbit.yaw=30; city.orbit.refresh()
 for i in 8: await process_frame
 RenderingServer.force_draw(true,.016)
 root.get_texture().get_image().save_png("res://captures/water-life-spots.png")
 # Temporary render-only collectors at resource tiles: no spawn/rules/save change.
 for fixture in [[spot,"walker_urchin",-90001],[fish,"fishing_boat",-90002]]:
  var tile: Array = fixture[0]
  state.walkers.append({"id":fixture[2],"asset":fixture[1],"type":-1,"action":7,"orientation":2,"x":float(tile[0])+.5,"y":float(tile[1])+.5,"altitude":tile[2]})
 city.receive_state(state)
 var recorded := 0
 var frame_directory := OS.get_environment("EZEUS_WATER_FRAME_DIRECTORY")
 for view in [[spot,"urchins"],[fish,"fish"]]:
  var tile: Array = view[0]
  city.orbit.target=city.world_position(tile[0],tile[1],tile[2])+Vector3.UP*.2
  city.orbit.distance=7; city.orbit.pitch=45; city.orbit.yaw=30; city.orbit.refresh()
  for frame in 60:
   city.water_life.receive({"time":float(frame)*3,"running":true})
   city.water_life.advance(.1)
   for entry in city.walkers.values():
    entry.node.position=city.walker_surface_position(entry.to,entry.to_offset,not entry.waterborne)
    city.animate_walker(entry,0,0)
    city.water_life.animate_gatherer(entry,city)
   city.water_life.update_workers(city)
   await process_frame
   if not frame_directory.is_empty():
    RenderingServer.force_draw(true,.016)
    root.get_texture().get_image().save_png(frame_directory.path_join("%04d.png"%recorded))
    recorded += 1
  city.water_life.receive({"time":177,"running":false})
  RenderingServer.force_draw(true,.016)
  root.get_texture().get_image().save_png("res://captures/water-life-"+view[1]+".png")
 print("WATER_LIFE_REVIEW PASS native fish spots, fixture urchins and presentation-only collectors captured")
 city.queue_free(); await process_frame; await process_frame; quit(0)
