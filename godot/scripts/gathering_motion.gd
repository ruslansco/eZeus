extends RefCounted
# Authored collection clips, without rotating the whole body or borrowing walk
# frames for work. The native action and gameplay clock are authoritative.
const COUNTS := {"collect":40,"carry":12,"deposit":12,"hunt":24,"shear":24,"milk":24,"groom":24,
 "prunegrapes":24,"pruneolives":24,"pruneoranges":24,"pickgrapes":24,"pickolives":24,"pickoranges":24,
 "lead":24,"fallen":12,"animalattack":24,"restanimal":12,
 "putout":24,"chop":24,"mine":24,"quarry":24,"build":24,"buildstand":24}
const PERIODS := {"collect":5.0,"deposit":1.5,"hunt":1.6,"shear":2.4,"milk":2.4,"groom":2.5,
 "prunegrapes":2.8,"pruneolives":2.8,"pruneoranges":2.8,"pickgrapes":2.8,"pickolives":2.8,"pickoranges":2.8,
 "fallen":1.0,"animalattack":1.6,"restanimal":3.0,
 "putout":2.6,"chop":1.3,"mine":1.5,"quarry":1.7,"build":1.5,"buildstand":2.2}
const ASSETS := ["walker_urchin","fishing_boat","walker_hunter","walker_deerhunter","walker_shepherd",
 "walker_goatherd","walker_grower","walker_orangetender","walker_rancher","animal_boar","animal_deer",
 "animal_wolf","animal_sheep_fleeced","animal_sheep_nude","animal_goat",
 "walker_firefighter","walker_lumberjack","walker_bronzeminer","walker_silverminer","walker_orichalcminer","walker_marbleminer","walker_artisan"]
const TASKS := {
 "walker_hunter":{4:"hunt",7:"hunt"},"walker_deerhunter":{4:"hunt",7:"hunt"},
 "walker_shepherd":{7:"shear",4:"groom"},"walker_goatherd":{7:"milk",4:"groom"},
 "walker_grower":{8:"prunegrapes",9:"pruneolives",11:"pickgrapes",12:"pickolives"},
 "walker_orangetender":{10:"pruneoranges",13:"pickoranges"},
 "animal_boar":{6:"fallen",4:"animalattack",2:"restanimal"},"animal_deer":{6:"fallen",4:"animalattack",2:"restanimal"},
 # 6 October: the wolf's lunging bites (its native fight), and every animal's collapse and lying down (eAnimalAction lies half the time).
 "animal_wolf":{6:"fallen",4:"animalattack",2:"restanimal"},"animal_sheep_fleeced":{6:"fallen",2:"restanimal"},
 "animal_sheep_nude":{6:"fallen",2:"restanimal"},"animal_goat":{6:"fallen",2:"restanimal"},
 # The native work states of the townspeople's crews (5 October). A collector carries only with goods collected (the core's
 # goBackDecision); the firefighter carries his bucket to the fire (14) and throws (4: the native "fight" is his put-out).
 "walker_firefighter":{14:"carry",4:"putout"},"walker_lumberjack":{7:"chop",14:"carry"},
 "walker_bronzeminer":{7:"mine",14:"carry"},"walker_silverminer":{7:"mine",14:"carry"},"walker_orichalcminer":{7:"mine",14:"carry"},
 "walker_marbleminer":{7:"quarry"},"walker_artisan":{20:"build",21:"buildstand",4:"buildstand"}}
static var frame_names := {}

static func frames(clip: String) -> Array:
 if not frame_names.has(clip):
  var names := []
  for i in COUNTS[clip]: names.append("%s_%02d"%[clip,i])
  frame_names[clip] = names
 return frame_names[clip]

static func clip_for(entry: Dictionary) -> String:
 if entry.asset not in ASSETS: return ""
 if entry.asset=="walker_rancher":
  return "lead" if str(entry.get("field_task",""))=="lead_cattle" and int(entry.action) in [3,14] else ""
 if TASKS.has(entry.asset):
  if int(entry.action)==14 and entry.asset in ["walker_hunter","walker_deerhunter","walker_shepherd","walker_goatherd"]:
   return "carry" if int(entry.get("field_load",0))>0 else ""
  return TASKS[entry.asset].get(int(entry.action),"")
 if int(entry.action)==7: return "collect"
 if entry.asset=="walker_urchin" and int(entry.action)==14: return "carry"
 if entry.asset=="walker_urchin" and int(entry.action)==22: return "deposit"
 return ""

static func apply(entry: Dictionary, city, clock: float) -> void:
 if entry.asset not in ASSETS: return
 if not str(entry.get("clip", "")).is_empty():
  # Death/combat has already been applied by the normal walker animator.
  entry.gather_weight = 0.0
  entry.gather_requested = ""
  entry.gather_clip = ""
  entry.erase("gather_from_clip")
  return
 var requested := clip_for(entry)
 var previous := str(entry.get("gather_requested",""))
 var elapsed := maxf(0,clock-float(entry.get("gather_clock",clock)))
 entry.gather_clock = clock
 if previous != requested:
  entry.gather_requested = requested
  if not requested.is_empty():
   if not previous.is_empty() and float(entry.get("gather_weight",0.0))>0.0:
    entry.gather_from_clip = str(entry.get("gather_clip",""))
    entry.gather_from_phase = float(entry.get("gather_frame",0.0))
    entry.gather_weight = 0.0
    elapsed = 0.0
   else:
    entry.erase("gather_from_clip")
   entry.gather_start = clock
   entry.gather_clip = requested
 var clip := str(entry.get("gather_clip",""))
 if clip.is_empty(): return
 var goal := 0.0 if requested.is_empty() else 1.0
 entry.gather_weight = move_toward(float(entry.get("gather_weight",0.0)),goal,elapsed/.22)
 var blend := float(entry.gather_weight)
 if blend <= 0.0 and requested.is_empty(): return
 var count: float = COUNTS[clip]
 var phase := fposmod(float(entry.get("travel",0))/.64*count,count) if clip in ["carry","lead"] else fposmod((clock-float(entry.gather_start))/float(PERIODS[clip])*count,count)
 if clip=="fallen": phase=minf(maxf(0,clock-float(entry.gather_start))/PERIODS.fallen*(count-1),count-1)
 if not requested.is_empty() and clip not in ["carry","lead","fallen","restanimal"]:
  entry.node.rotation.y=lerp_angle(entry.node.rotation.y,deg_to_rad(-180.0+int(entry.facing)*45.0),clampf(elapsed/.15,0,1))
 # Stand outside the native target's centre while hands reach into it. This is
 # a presentation stance only; the native position, path and picking record stay intact.
 var standing_work := clip in ["hunt","shear","milk","groom","prunegrapes","pruneolives","pruneoranges","pickgrapes","pickolives","pickoranges"] and not requested.is_empty()
 entry.field_stance=move_toward(float(entry.get("field_stance",0)),.30 if standing_work else 0.0,elapsed/.22*.30)
 if float(entry.field_stance)>0.0:
  var at: Vector3 = entry.native_position+entry.node.basis*Vector3(0,0,float(entry.field_stance))
  entry.node.position=city.walker_surface_position(at,float(entry.get("offset",0)),true)
 entry.gather_phase = phase/float(COUNTS[clip])
 entry.gather_frame = phase
 for morph in entry.morphs:
  if not morph.has("gather_clips"):
   var available := {}
   for name in morph.table:
    var prefix: String = str(name).get_slice("_",0)
    if COUNTS.has(prefix): available[prefix]=true
   morph.gather_clips=available
  if not morph.gather_clips.has(clip): continue
  var pair: Vector3 = city.pose_pair(morph.table,frames(clip),phase)
  # Blend authored work against the normal travel/idle pose at entry/exit.
  # The crowd/VAT path uses two normalized pose pairs, the fallback the same weights.
  var moving := float(entry.get("walk_weight",0.0)) if entry.get("human",false) else (1.0 if entry.get("moving",false) else 0.0)
  var normal: Vector3 = city.pose_pair(morph.table,city.WALK_FRAMES,fposmod(float(entry.get("travel",0))/.64*24.0,24.0)) if moving>.5 else city.pose_pair(morph.table,city.IDLE_FRAMES,fposmod(float(entry.get("idle",0))/3.0*12.0,12.0))
  var from_clip := str(entry.get("gather_from_clip",""))
  if blend<1.0 and morph.gather_clips.has(from_clip):
   normal = city.pose_pair(morph.table,frames(from_clip),float(entry.gather_from_phase))
  if morph.has("vat"):
   morph.node.set_instance_shader_parameter("vat_pose",pair)
   morph.node.set_instance_shader_parameter("vat_idle_pose",normal)
   morph.node.set_instance_shader_parameter("vat_walk_blend",blend)
   morph.blend = blend
  else:
   for index in morph.lit: morph.node.set_blend_shape_value(index,0.0)
   morph.lit.clear()
   var weights := {}
   city.add_pose_weights(weights,pair,blend)
   city.add_pose_weights(weights,normal,1.0-blend)
   for index in weights:
    morph.node.set_blend_shape_value(index,weights[index]); morph.lit.append(index)
 if blend>=1.0: entry.erase("gather_from_clip")
