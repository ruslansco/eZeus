extends RefCounted
# Authored collection clips, without rotating the whole body or borrowing walk
# frames for work. The native action and gameplay clock are authoritative.
const COUNTS := {"collect":40,"carry":12,"deposit":12}
const PERIODS := {"collect":5.0,"deposit":1.5}
static var frame_names := {}

static func frames(clip: String) -> Array:
 if not frame_names.has(clip):
  var names := []
  for i in COUNTS[clip]: names.append("%s_%02d"%[clip,i])
  frame_names[clip] = names
 return frame_names[clip]

static func clip_for(entry: Dictionary) -> String:
 if entry.asset not in ["walker_urchin","fishing_boat"]: return ""
 if int(entry.action)==7: return "collect"
 if entry.asset=="walker_urchin" and int(entry.action)==14: return "carry"
 if entry.asset=="walker_urchin" and int(entry.action)==22: return "deposit"
 return ""

static func apply(entry: Dictionary, city, clock: float) -> void:
 if entry.asset not in ["walker_urchin","fishing_boat"]: return
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
 var phase := fposmod(float(entry.get("travel",0))/.64*12.0,12.0) if clip=="carry" else fposmod((clock-float(entry.gather_start))/float(PERIODS[clip])*float(COUNTS[clip]),float(COUNTS[clip]))
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
