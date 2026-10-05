extends SceneTree
const Motion = preload("res://scripts/gathering_motion.gd")
var okay := true
var checks := 0
func check(value: bool,label: String) -> void:
 checks+=1;okay=okay and value
 print("GATHER_MOTION_CHECK ","PASS " if value else "FAIL ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 Engine.set_meta("ezeus_settings_path","/tmp/ezeus-gather-validation-settings.cfg")
 Engine.set_meta("ezeus_save_directory","/tmp/ezeus-gather-validation-saves")
 var city = load("res://main.tscn").instantiate()
 root.add_child(city)
 while city.state.is_empty(): await process_frame
 city.core.query("pause 1");city.core.set_process(false);city.set_process(false)
 city.orbit.enabled=false
 for asset in ["walker_urchin","fishing_boat"]:
  var contract = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+asset+".json"))
  check(contract.get("gathering",{}).get("revision","")=="authored_gather_v2",asset+" has authored work provenance")
  var node: Node3D = load("res://assets/models/"+asset+".glb").instantiate()
  var morphs := []
  city.collect_morphs(node,morphs)
  var complete := not morphs.is_empty()
  for morph in morphs:
   for i in 40: complete=complete and morph.table.has("collect_%02d"%i)
  check(complete,asset+" carries all 40 work samples on every animated part")
  var entry: Dictionary = city.new_walker_entry(node,asset,-1,Vector3.ZERO,0,morphs)
  entry.action=7
  city.animate_walker(entry,0,0);Motion.apply(entry,city,0)
  city.animate_walker(entry,0,0);Motion.apply(entry,city,.3)
  check(is_equal_approx(entry.gather_weight,1.0) and entry.gather_clip=="collect",asset+" transitions into authored collection")
  var normalized := true
  var sampled := []
  for morph in morphs:
   var total := 0.0
   for i in morph.node.get_blend_shape_count():
    var weight: float = morph.node.get_blend_shape_value(i)
    total += weight
    sampled.append(weight)
   normalized=normalized and is_equal_approx(total,1.0)
  check(normalized,asset+" pose weights remain normalized")
  var transform: Transform3D = node.transform
  Motion.apply(entry,city,.3)
  var held := []
  for morph in morphs:
   for i in morph.node.get_blend_shape_count(): held.append(morph.node.get_blend_shape_value(i))
  check(sampled==held and transform==node.transform,asset+" freezes when gameplay clock is held, with no root tilt")
  city.animate_walker(entry,0,0);Motion.apply(entry,city,1.7)
  check(not is_equal_approx(entry.gather_phase,.06),asset+" work phase advances with gameplay time")
  entry.action=3
  city.animate_walker(entry,0,0);Motion.apply(entry,city,2)
  check(is_zero_approx(entry.gather_weight),asset+" restores normal locomotion after collection")
  if asset=="walker_urchin":
   for action in [14,22]:
    var before := []
    for morph in morphs:
     for i in morph.node.get_blend_shape_count(): before.append(morph.node.get_blend_shape_value(i))
    entry.action=action
    Motion.apply(entry,city,3.3)
    if action==22:
     var after := []
     for morph in morphs:
      for i in morph.node.get_blend_shape_count(): after.append(morph.node.get_blend_shape_value(i))
     check(before==after,"carry-to-deposit starts at the previous pose without a jump")
    Motion.apply(entry,city,3.6)
    check(entry.gather_clip==("carry" if action==14 else "deposit"),"urchin bag carry/deposit clip connected to native action "+str(action))
   entry.action=6
   city.animate_walker(entry,.3,0)
   var death := []
   for morph in morphs:
    for i in morph.node.get_blend_shape_count(): death.append(morph.node.get_blend_shape_value(i))
   Motion.apply(entry,city,3.7)
   var after_death := []
   for morph in morphs:
    for i in morph.node.get_blend_shape_count(): after_death.append(morph.node.get_blend_shape_value(i))
   check(entry.get("clip","")=="die" and death==after_death and is_zero_approx(entry.gather_weight),"death pose takes priority over collection exit")
  node.free()
 city.queue_free();await process_frame;await process_frame
 print("GATHER_MOTION_VALIDATION ","PASS " if okay else "FAIL ",checks)
 quit(0 if okay else 1)
