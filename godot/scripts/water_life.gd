extends Node3D
# Original procedural water-life art. Native tile column 9 and collect action 7
# are observations only. No RNG, physics, placement or production authority.
const LIFE = preload("res://shaders/water_life.gdshader")
const GatheringMotion = preload("res://scripts/gathering_motion.gd")
const RIPPLE = preload("res://shaders/fishing_ripple.gdshader")
const WORKER_CAP := 128
var sections := {}
var meshes := {}
var finishes := {}
var clock := 0.0
var from_clock := 0.0
var to_clock := 0.0
var age := 0.0
var initialized := false
var running := false
var worker_rings: MultiMesh
var bubbles: MultiMesh
var spot_counts := {"fish": 0, "urchin": 0}

func _init() -> void:
 name = "WaterLife"
 for kind in ["fish", "urchin", "bubble"]:
  var finish := ShaderMaterial.new()
  finish.shader = LIFE
  finish.set_shader_parameter("swimming", kind == "fish")
  finishes[kind] = finish
 var ripple := ShaderMaterial.new()
 ripple.shader = RIPPLE
 finishes.ripple = ripple
 meshes.fish = with_lod(fish_mesh(),fish_mesh(true))
 meshes.urchin = with_lod(urchin_mesh(),urchin_mesh(true))
 var plane := PlaneMesh.new()
 plane.size = Vector2(1.0, 1.0)
 meshes.ripple = plane
 var sphere := SphereMesh.new()
 sphere.radius = .025; sphere.height = .05
 sphere.radial_segments = 8; sphere.rings = 4
 meshes.bubble = sphere
 worker_rings = batch(self, "ripple", WORKER_CAP)
 bubbles = batch(self, "bubble", WORKER_CAP * 3)

func batch(parent: Node, kind: String, count: int) -> MultiMesh:
 var multi := MultiMesh.new()
 multi.transform_format = MultiMesh.TRANSFORM_3D
 multi.use_colors = true
 multi.use_custom_data = true
 multi.mesh = meshes[kind]
 multi.instance_count = count
 multi.visible_instance_count = 0
 var node := MultiMeshInstance3D.new()
 node.multimesh = multi
 node.material_override = finishes[kind]
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 node.visibility_range_end = 110.0
 parent.add_child(node)
 return multi

static func resource_mask(tile: Array) -> int:
 return int(tile[9]) if tile.size() > 9 and (int(tile[3]) & 4) and not (int(tile[4]) or (int(tile[6]) & 8)) else 0

func update_tiles(city, changed: Array[Vector2i], full: bool) -> void:
 var dirty := {}
 if full:
  for node in sections.values():
   remove_child(node); node.queue_free()
  sections.clear()
 for cell in changed:
  dirty[Vector2i(floori(float(cell.x-city.origin.x)/32), floori(float(cell.y-city.origin.y)/32))] = true
 for section in dirty:
  if sections.has(section):
   remove_child(sections[section]); sections[section].queue_free(); sections.erase(section)
  var root := Node3D.new()
  var groups := {"fish": [], "urchin": [], "ripple": []}
  for y in range(city.origin.y+section.y*32, mini(city.origin.y+(section.y+1)*32, city.origin.y+city.extent.y)):
   for x in range(city.origin.x+section.x*32, mini(city.origin.x+(section.x+1)*32, city.origin.x+city.extent.x)):
    var tile: Array = city.tiles.get(Vector2i(x,y), [])
    var mask := resource_mask(tile)
    if mask == 0: continue
    var center: Vector3 = city.world_position(x,y,tile[2])+Vector3.UP*.045
    var seed := float(posmod(x*73+y*131,997))/997.0
    for kind in ["fish", "urchin"]:
     if not (mask & (1 if kind == "fish" else 2)): continue
     for i in (5 if kind == "fish" else 4):
      var a := seed*TAU+float(i)*2.4
      var radius := .12+float(i%2)*.04 if kind == "fish" else .16+float(i%2)*.08
      var p := center+Vector3(cos(a),0,sin(a))*radius
      var tint := Color(.34,.63,.66) if kind == "fish" else Color(.22,.10,.29)
      var basis := Basis.IDENTITY.scaled(Vector3.ONE*.8) if kind == "fish" else Basis.IDENTITY
      groups[kind].append([Transform3D(basis,p),tint,Color(fposmod(seed+i*.19,1.0),0,0,1)])
    groups.ripple.append([Transform3D(Basis.IDENTITY,center+Vector3.UP*.02),Color.WHITE,Color(seed,0,0,1)])
  for kind in groups:
   var records: Array = groups[kind]
   if records.is_empty(): continue
   var multi := batch(root,kind,records.size())
   for i in records.size():
    multi.set_instance_transform(i,records[i][0]); multi.set_instance_color(i,records[i][1]); multi.set_instance_custom_data(i,records[i][2])
   multi.visible_instance_count = records.size()
  if root.get_child_count() > 0:
   add_child(root); sections[section] = root
  else: root.free()
 spot_counts = {"fish":0,"urchin":0}
 for section in sections.values():
  for node in section.get_children():
   if node.multimesh.mesh == meshes.fish: spot_counts.fish += node.multimesh.instance_count/5
   if node.multimesh.mesh == meshes.urchin: spot_counts.urchin += node.multimesh.instance_count/4

func receive(snapshot: Dictionary) -> void:
 var target := float(snapshot.get("time",0))/30.0
 running = bool(snapshot.get("running",false)) and not bool(snapshot.get("blocked",false))
 from_clock = clock if initialized and running and target >= to_clock else target
 to_clock = target; age = 0.0; initialized = true
 if not running: clock = target
 sync_clock()

func advance(dt: float) -> void:
 if not initialized: return
 age += dt
 clock = lerpf(from_clock,to_clock,clampf(age/.1,0,1)) if running else to_clock
 sync_clock()

func sync_clock() -> void:
 for finish in finishes.values(): finish.set_shader_parameter("life_clock",clock)

static func gathering(entry: Dictionary) -> bool:
 return entry.asset in ["walker_urchin","fishing_boat"] and int(entry.action) == 7

func animate_gatherer(entry: Dictionary, city) -> void:
 GatheringMotion.apply(entry,city,clock)

func update_workers(city) -> void:
 var count := 0
 var bubble_count := 0
 for entry in city.walkers.values():
  if count >= WORKER_CAP: break
  if not gathering(entry) or not entry.node.visible: continue
  var p: Vector3 = entry.native_position
  # Use the native cell's actual water top, never a bridge or cosmetic apron.
  var cell := Vector2i(roundi(p.x+city.origin.x+(city.extent.x-1)*.5),roundi(-p.z+city.origin.y+(city.extent.y-1)*.5))
  var tile: Array = city.tiles.get(cell,[])
  if tile.is_empty() or not (int(tile[3]) & 4): continue
  p.y = float(tile[2])*.22+.065
  var seed := float(entry.facing)*.123
  worker_rings.set_instance_transform(count,Transform3D(Basis.IDENTITY.scaled(Vector3(.8,1,.8)),p))
  worker_rings.set_instance_custom_data(count,Color(seed,1,float(entry.get("gather_phase",0)),1))
  count += 1
  if entry.asset == "walker_urchin":
   var phase := float(entry.get("gather_phase",0.0))
   # A few tiny air bubbles during the submerged reach, not a constant fountain.
   if phase > .28 and phase < .54:
    for i in 3:
     var t := fposmod(clock*.7+seed+i*.33,1.0)
     var at := p+Vector3(sin(i*2.4+seed)*.09,t*.055,cos(i*2.4+seed)*.09)
     bubbles.set_instance_transform(bubble_count,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.4),at))
     bubbles.set_instance_color(bubble_count,Color(.48,.70,.69)); bubble_count += 1
 worker_rings.visible_instance_count = count
 bubbles.visible_instance_count = bubble_count

func fish_mesh(reduced := false) -> ArrayMesh:
 var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var body := SphereMesh.new(); body.radius=.09; body.height=.18; body.radial_segments=6 if reduced else 10; body.rings=3 if reduced else 5
 st.append_from(body,0,Transform3D(Basis.IDENTITY.scaled(Vector3(1.7,.30,.55)),Vector3.ZERO))
 st.deindex()
 triangle(st,Vector3(.12,0,0),Vector3(.23,0,-.065),Vector3(.23,0,.065))
 triangle(st,Vector3(-.02,.018,0),Vector3(.08,.07,0),Vector3(.09,.018,0))
 st.generate_normals()
 return st.commit()

func urchin_mesh(reduced := false) -> ArrayMesh:
 var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var body := SphereMesh.new(); body.radius=.075; body.height=.12; body.radial_segments=6 if reduced else 10; body.rings=3 if reduced else 5
 st.append_from(body,0,Transform3D.IDENTITY)
 st.deindex()
 for i in (10 if reduced else 28):
  var a := float(i)*2.399963
  var y := float(i)/(10.0 if reduced else 28.0)
  var direction := Vector3(cos(a)*sqrt(1-y*y),y,sin(a)*sqrt(1-y*y))
  var side := direction.cross(Vector3.UP).normalized()*.009
  var base := direction*.055
  var tip := direction*(.13+float(i%3)*.014)
  triangle(st,base-side,tip,base+side)
  triangle(st,base+Vector3.UP*.007,tip,base-Vector3.UP*.007)
 st.generate_normals()
 return st.commit()

func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
 for p in [a,b,c]: st.add_vertex(p)

func with_lod(near_mesh: ArrayMesh, far_mesh: ArrayMesh) -> ArrayMesh:
 var near: Array = near_mesh.surface_get_arrays(0)
 var far: Array = far_mesh.surface_get_arrays(0)
 var count: int = near[Mesh.ARRAY_VERTEX].size()
 var indices: PackedInt32Array = near[Mesh.ARRAY_INDEX] if near[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
 if indices.is_empty():
  for i in count: indices.append(i)
 var reduced: PackedInt32Array = far[Mesh.ARRAY_INDEX] if far[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
 if reduced.is_empty():
  for i in far[Mesh.ARRAY_VERTEX].size(): reduced.append(i)
 for i in reduced.size(): reduced[i] += count
 for channel in Mesh.ARRAY_MAX:
  if channel == Mesh.ARRAY_INDEX or near[channel] == null: continue
  near[channel].append_array(far[channel])
 near[Mesh.ARRAY_INDEX] = indices
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,near,[],{.015:reduced})
 mesh.custom_aabb = mesh.get_aabb().grow(.12)
 return mesh
