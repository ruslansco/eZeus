extends SceneTree
const Motion = preload("res://scripts/gathering_motion.gd")
const ASSETS = ["walker_hunter","walker_deerhunter","walker_shepherd","walker_goatherd","walker_grower","walker_orangetender","walker_rancher","animal_boar","animal_deer"]
var okay := true
var checks := 0
func check(value: bool,label: String) -> void:
 checks+=1;okay=okay and value
 print("FIELD_WORK_CHECK ","PASS " if value else "FAIL ",label)
func _initialize() -> void: call_deferred("run")
func signature(morphs: Array) -> Array:
 var result := []
 for morph in morphs:
  if morph.has("vat"):
   result.append([morph.node.get_instance_shader_parameter("vat_pose"),morph.node.get_instance_shader_parameter("vat_idle_pose"),morph.node.get_instance_shader_parameter("vat_walk_blend")])
  else:
   var weights := []
   for i in morph.node.get_blend_shape_count(): weights.append(morph.node.get_blend_shape_value(i))
   result.append(weights)
 return result
func run() -> void:
 Engine.set_meta("ezeus_settings_path","/tmp/ezeus-field-validation-settings.cfg")
 Engine.set_meta("ezeus_save_directory","/tmp/ezeus-field-validation-saves")
 var city = load("res://main.tscn").instantiate();root.add_child(city)
 while city.state.is_empty(): await process_frame
 city.core.query("pause 1");city.core.set_process(false);city.set_process(false);city.orbit.enabled=false
 var seen := {}
 for record in city.state.walkers:
  if record.asset in ASSETS:
   seen[record.asset]=int(seen.get(record.asset,0))+1
   if record.asset in ["walker_hunter","walker_deerhunter","walker_shepherd","walker_goatherd"]:
    check(record.has("field_load") and int(record.field_load)>=0,"native "+str(record.asset)+" reports actual carried load")
 print("FIELD_WORK_NATIVE_INITIAL ",seen)
 var target: Vector3 = city.orbit.target
 for asset in ASSETS:
  var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+asset+".json"))
  check(manifest.get("field_work",{}).get("revision","")=="authored_field_work_v1",asset+" authored work manifest")
  for baked in [false,true]:
   var node: Node3D = city.model(asset) if baked else load("res://assets/models/"+asset+".glb").instantiate()
   city.world.add_child(node);node.position=target
   var morphs: Array = node.get_meta("vat_parts") if node.has_meta("vat_parts") else []
   if morphs.is_empty(): city.collect_morphs(node,morphs)
   check(not morphs.is_empty() and (not baked or node.has_meta("vat_parts")),asset+" "+("VAT" if baked else "source")+" animated parts")
   var entry: Dictionary = city.new_walker_entry(node,asset,-1,target,0,morphs)
   entry.field_load=1;entry.field_task="lead_cattle"
   var actions: Array = Motion.TASKS.get(asset,{}).keys()
   if asset=="walker_rancher": actions=[3]
   if asset in ["walker_hunter","walker_deerhunter","walker_shepherd","walker_goatherd"]: actions.append(14)
   var clock := 0.0
   for action in actions:
    entry.action=action
    var clip := Motion.clip_for(entry)
    var complete := not clip.is_empty()
    for morph in morphs:
     for i in Motion.COUNTS.get(clip,0): complete=complete and morph.table.has("%s_%02d"%[clip,i])
    check(complete,asset+" complete "+clip+" samples")
    node.position=target;city.animate_walker(entry,0,0);Motion.apply(entry,city,clock)
    node.position=target;city.animate_walker(entry,0,0);Motion.apply(entry,city,clock+.3)
    check(entry.gather_clip==clip and is_equal_approx(entry.gather_weight,1.0),asset+" action "+str(action)+" selects "+clip)
    var before := signature(morphs)
    var position: Vector3 = entry.native_position
    var transform: Transform3D = node.transform
    Motion.apply(entry,city,clock+.3)
    check(before==signature(morphs) and transform==node.transform and position==entry.native_position,asset+" "+clip+" pause holds pose/stance and native position")
    if clip in ["carry","lead"]:
     var old_phase: float = entry.gather_phase
     entry.travel+=.16;Motion.apply(entry,city,clock+.3)
     check(not is_equal_approx(old_phase,entry.gather_phase),asset+" "+clip+" gait follows distance")
    if clip=="fallen":
     Motion.apply(entry,city,clock+2.0);var phase: float=entry.gather_phase
     Motion.apply(entry,city,clock+5.0)
     check(is_equal_approx(phase,entry.gather_phase),asset+" collapse holds its final pose")
    clock+=6.0
   entry.action=3;entry.field_task="";node.position=target
   city.animate_walker(entry,0,0);Motion.apply(entry,city,clock)
   check(is_zero_approx(entry.get("gather_weight",0.0)),asset+" restores ordinary travel")
   entry.action=14;entry.field_load=0
   check(Motion.clip_for(entry).is_empty(),asset+" empty return never invents carried goods")
   node.free()
 check(Motion.clip_for({"asset":"philosopher","action":7}).is_empty(),"unrelated roles retain normal animation")
 city.queue_free();await process_frame;await process_frame
 print("FIELD_WORK_VALIDATION ","PASS " if okay else "FAIL ",checks)
 quit(0 if okay else 1)
