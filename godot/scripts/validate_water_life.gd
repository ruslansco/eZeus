extends SceneTree
const Life = preload("res://scripts/water_life.gd")
var checks := 0
var okay := true
class Fixture:
 extends Node3D
 var origin := Vector2i.ZERO
 var extent := Vector2i(64,64)
 var tiles := {}
 var walkers := {}
 func world_position(x: float,y: float,h: float) -> Vector3:
  return Vector3(x-31.5,h*.22,-y+31.5)
func check(value: bool, label: String) -> void:
 checks += 1; okay = okay and value
 print("WATER_LIFE_CHECK ","PASS " if value else "FAIL ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
 var path := ProjectSettings.globalize_path("res://..").simplify_path()
 var state: Dictionary = core.open_city(path,path.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),"en")
 check(state.has("tiles"),"designated city loads")
 var counts := [0,0]
 var complete := true
 for tile in state.get("tiles",[]):
  complete = complete and tile.size() == 10
  if tile.size() == 10:
   if int(tile[9]) & 1: counts[0] += 1
   if int(tile[9]) & 2: counts[1] += 1
 check(complete,"native full snapshot carries water-resource flags")
 check(counts[0]==4,"designated native map exposes its four fish deposits (urchins use presentation fixtures)")
 print("WATER_LIFE_NATIVE_SPOTS ",counts)
 var delta: Dictionary = core.snapshot(false)
 check(delta.get("tile_changes",[]).is_empty(),"unchanged resources do not resend tiles")
 check(core.snapshot(false).get("tile_changes",[]).is_empty(),"repeated idle observations retain tile cache")
 core.close_city()
 var city := Fixture.new(); root.add_child(city)
 var life := Life.new(); root.add_child(life)
 var a := Vector2i(2,2); var b := Vector2i(35,2)
 city.tiles[a] = [2,2,0,4,0,0,0,0,0,3]
 city.tiles[b] = [35,2,0,4,0,0,0,0,0,1]
 var changed: Array[Vector2i] = [a,b]
 life.update_tiles(city,changed,true)
 check(life.spot_counts == {"fish":2,"urchin":1},"mixed fish and urchin spots render distinctly")
 check(life.sections.size() == 2,"water-life batches are spatially divided")
 var retained = life.sections[Vector2i(1,0)]
 city.tiles[a][9] = 0
 changed = [a]; life.update_tiles(city,changed,false)
 check(life.spot_counts == {"fish":1,"urchin":0},"removed deposits disappear incrementally")
 check(life.sections[Vector2i(1,0)] == retained,"unaffected spatial batch survives tile changes")
 for blocked in [[0,0,0,0,0,0,0,0,0,3],[0,0,0,4,1,0,0,0,0,3],[0,0,0,4,0,0,8,0,0,3],[0,0,0,4,0,0]]:
  check(Life.resource_mask(blocked)==0,"land, bridges, foundations and legacy snapshots omit water life")
 life.receive({"time":30,"running":true}); life.advance(.1)
 life.receive({"time":60,"running":true}); life.advance(.05)
 check(is_equal_approx(life.clock,1.5),"effects interpolate native gameplay time")
 life.receive({"time":60,"running":false}); life.advance(10)
 check(is_equal_approx(life.clock,2),"pause freezes effects")
 life.receive({"time":90,"running":true,"blocked":true}); life.advance(10)
 check(is_equal_approx(life.clock,3),"pending decisions freeze effects")
 for asset in ["walker_urchin","fishing_boat"]:
  var node := Node3D.new(); city.add_child(node)
  var entry := {"asset":asset,"action":7,"node":node,"facing":0,"gather_phase":.5,"morphs":[],"native_position":city.world_position(35,2,0)}
  node.position=entry.native_position
  city.walkers[asset] = entry
  check(Life.gathering(entry),asset+" native collect state enables effect")
 life.update_workers(city)
 check(life.worker_rings.visible_instance_count==2,"both collectors disturb the water")
 check(life.bubbles.visible_instance_count==3,"urchin diver emits only three small bubbles during submerged reach")
 check(Life.GatheringMotion.clip_for(city.walkers.fishing_boat)=="collect","fishing net and hand work come from the authored collect clip")
 var diver: Dictionary = city.walkers.walker_urchin
 check(Life.GatheringMotion.clip_for(diver)=="collect","native collecting action selects authored dive and reach motion")
 diver.action=14
 check(Life.GatheringMotion.clip_for(diver)=="carry","returning diver selects authored bag-carry gait")
 diver.action=22
 check(Life.GatheringMotion.clip_for(diver)=="deposit","depositing selects authored bag-emptying cycle")
 diver.action=3
 check(Life.GatheringMotion.clip_for(diver).is_empty(),"normal travel restores existing locomotion")
 city.walkers.walker_urchin.action=14; city.walkers.fishing_boat.action=3
 life.update_workers(city)
 check(life.worker_rings.visible_instance_count==0 and life.bubbles.visible_instance_count==0,"carry and travel stop collection effects")
 city.walkers.clear()
 diver.action = 7
 for i in 200: city.walkers[i] = diver
 life.update_workers(city)
 check(life.worker_rings.visible_instance_count==128 and life.bubbles.visible_instance_count==384,"large collector population respects bounded effect capacity")
 city.walkers.clear(); life.update_workers(city)
 check(life.worker_rings.visible_instance_count==0 and life.bubbles.visible_instance_count==0,"removed collectors leave no orphan effects")
 var budgets := true
 for mesh in life.meshes.values():
  if mesh is ArrayMesh: budgets = budgets and mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()<1200
 check(budgets,"procedural models remain below 1200 vertices each")
 for kind in ["fish","urchin"]:
  var arrays: Array = life.meshes[kind].surface_get_arrays(0)
  var reach := 0.0
  for index in arrays[Mesh.ARRAY_INDEX]:
   var vertex: Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
   reach=maxf(reach,vertex.x if kind=="fish" else vertex.length())
  check(reach>(.22 if kind=="fish" else .13),kind+" drawn indices include the tail/spines, not only the body")
  var surface: Dictionary = RenderingServer.mesh_get_surface(life.meshes[kind].get_rid(),0)
  check(surface.get("lods",[]).size()==1,kind+" has a reduced geometry LOD")
 life.free(); city.free()
 print("WATER_LIFE_VALIDATION ","PASS " if okay else "FAIL ",checks)
 quit(0 if okay else 1)
