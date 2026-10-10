extends SceneTree
# The townspeople's work clips (5 October): firefighter carry/put-out, lumberjack chop, miners' pick, quarryman's cut,
# artisan's building work, and their deaths. Each native action selects a complete authored clip in the source GLB and the
# baked VAT model, work holds still while paused, carrying follows distance, and ordinary travel comes back.
const Motion = preload("res://scripts/gathering_motion.gd")
const Combat = preload("res://scripts/walker_combat.gd")
const ASSETS = ["walker_firefighter","walker_lumberjack","walker_bronzeminer","walker_silverminer","walker_orichalcminer","walker_marbleminer","walker_artisan"]
var okay := true
var checks := 0
func check(value: bool,label: String) -> void:
 checks+=1;okay=okay and value
 print("WORK_CLIPS_CHECK ","PASS " if value else "FAIL ",label)
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
 Engine.set_meta("ezeus_settings_path","/tmp/ezeus-work-clips-validation-settings.cfg")
 Engine.set_meta("ezeus_save_directory","/tmp/ezeus-work-clips-validation-saves")
 var city = load("res://main.tscn").instantiate();root.add_child(city)
 while city.state.is_empty(): await process_frame
 city.core.query("pause 1");city.core.set_process(false);city.set_process(false);city.orbit.enabled=false
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
   var clock := 0.0
   for action in Motion.TASKS[asset].keys():
    entry.action=action
    var clip := Motion.clip_for(entry)
    var complete := not clip.is_empty()
    for morph in morphs:
     for i in Motion.COUNTS.get(clip,0): complete=complete and morph.table.has("%s_%02d"%[clip,i])
    check(complete,asset+" complete "+clip+" samples")
    # The native fight state of a firefighter or artisan is work, never a combat clip.
    check(Combat.clip_for(entry).is_empty(),asset+" action "+str(action)+" plays no combat clip")
    node.position=target;city.animate_walker(entry,0,0);Motion.apply(entry,city,clock)
    node.position=target;city.animate_walker(entry,0,0);Motion.apply(entry,city,clock+.3)
    check(entry.gather_clip==clip and is_equal_approx(entry.gather_weight,1.0),asset+" action "+str(action)+" selects "+clip)
    var before := signature(morphs)
    Motion.apply(entry,city,clock+.3)
    check(before==signature(morphs),asset+" "+clip+" pause holds the pose")
    if clip=="carry":
     var old_phase: float = entry.gather_phase
     entry.travel+=.16;Motion.apply(entry,city,clock+.3)
     check(not is_equal_approx(old_phase,entry.gather_phase),asset+" carry gait follows distance")
    else:
     var old_frame: float = entry.gather_frame
     Motion.apply(entry,city,clock+.9)
     check(not is_equal_approx(old_frame,entry.gather_frame),asset+" "+clip+" advances with the gameplay clock")
    clock+=6.0
   entry.action=3;node.position=target
   city.animate_walker(entry,0,0);Motion.apply(entry,city,clock)
   check(is_zero_approx(entry.get("gather_weight",0.0)),asset+" restores ordinary travel")
   entry.action=6
   check(Combat.clip_for(entry)=="die",asset+" death plays its die clip")
   node.free()
 city.queue_free();await process_frame;await process_frame
 print("WORK_CLIPS_VALIDATION ","PASS " if okay else "FAIL ",checks)
 quit(0 if okay else 1)
