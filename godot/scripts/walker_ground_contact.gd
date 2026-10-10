extends RefCounted
# A small, cached clearance correction for human soles on native slopes.
# This is root support, not IK; routes, stride and foundation heights stay native.
const HALF_STANCE := .10
const HALF_STEP := .16
const MAX_LIFT := .065
var samples := 0

func lift(entry: Dictionary, point: Vector3, city: Node) -> float:
	if not entry.get("human",false) or entry.get("god",false) or entry.get("waterborne",false) or not entry.get("perch",{}).is_empty() or int(entry.get("action",1)) not in [0,1]: return 0.0
	var heading: int=roundi(entry.node.rotation.y/.15)
	# Small sub-tile travel reuses the local slope support instead of adding four
	# terrain queries at display frequency. Native centre height remains exact.
	var bucket:=Vector2i((Vector2(point.x,point.z)*32).round())
	if entry.get("contact_bucket") == bucket and entry.get("contact_heading",-999)==heading and entry.get("contact_revision",-1)==city.surface_revision and entry.get("contact_offset") == entry.offset:return float(entry.get("contact_lift",0.0))
	entry.contact_bucket=bucket;entry.contact_heading=heading;entry.contact_revision=city.surface_revision;entry.contact_offset=entry.offset;entry.contact_lift=0.0
	var cell := Vector2i(city.tile_coordinates(point).round())
	if not city.terrain_geometry.near_slope.has(cell): return 0.0
	var across:=Vector3(cos(heading*.15),0,-sin(heading*.15))*HALF_STANCE
	var forward:=Vector3(-sin(heading*.15),0,-cos(heading*.15))*HALF_STEP
	var left: Vector3=city.walker_surface_position(point+across,entry.offset,true)
	var right: Vector3=city.walker_surface_position(point-across,entry.offset,true)
	var front: Vector3=city.walker_surface_position(point+forward,entry.offset,true)
	var back: Vector3=city.walker_surface_position(point-forward,entry.offset,true)
	samples+=4
	var result:=clampf(maxf(maxf(left.y,right.y),maxf(front.y,back.y))-point.y,0.0,MAX_LIFT)
	entry.contact_lift=result
	return result
