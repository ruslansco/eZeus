extends RefCounted
# Choosing several units at once, as the SDL view's drag does: with the selection tool, dragging the left button draws a box,
# and on release every company banner and every orderable trireme of the player's inside it is chosen (their rings show). A
# right click then sends them all: the companies with `banners_move` (spaced as the SDL view places a selection), the triremes
# with `trireme_move`. Escape or a plain click lets them go. A press that does not move far stays an ordinary click.

const THRESHOLD := 10.0
var start := Vector2.ZERO
var pressing := false
var active := false
var box: Panel
var banners: Array = []

func press(city, at: Vector2) -> void:
	start = at
	pressing = true
	active = false

func drag(city, at: Vector2) -> void:
	if not pressing:
		return
	if not active and at.distance_to(start) < THRESHOLD:
		return
	if not active:
		active = true
		if box == null or not is_instance_valid(box):
			box = Panel.new()
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style := StyleBoxFlat.new()
			style.bg_color = Color(.95, .76, .26, .12)
			style.border_color = Color(.95, .76, .26, .9)
			style.set_border_width_all(2)
			box.add_theme_stylebox_override("panel", style)
			city.hud.add_child(box)
		box.visible = true
	var rect := Rect2(start, Vector2.ZERO).expand(at)
	box.position = rect.position
	box.size = rect.size

# The release: an ordinary click (false) or a finished box, whose units are chosen (true).
func release(city, at: Vector2) -> bool:
	pressing = false
	if not active:
		return false
	active = false
	if box != null and is_instance_valid(box):
		box.visible = false
	var rect := Rect2(start, Vector2.ZERO).expand(at)
	var camera: Camera3D = city.orbit.camera
	var inside := func(point: Vector3) -> bool:
		return not camera.is_position_behind(point) and rect.has_point(camera.unproject_position(point))
	banners = []
	for id in city.army_view.flags:
		var node: Node3D = city.army_view.flags[id].node
		if inside.call(node.global_position):
			banners.append(int(id))
	var ships: Array = []
	for id in city.walkers:
		var entry: Dictionary = city.walkers[id]
		if entry.asset == "trireme" and entry.get("selectable", false) and inside.call(entry.node.global_position):
			ships.append(int(id))
	city.army_view.select_group(banners)
	city.trireme_orders.select_many(city, ships)
	city.close_inspection()
	if banners.is_empty() and ships.is_empty():
		city.update_hint()
	else:
		city.hint.text = city.tr("%d companies and %d triremes chosen  •  right-click to send them  •  Escape lets them go") % [banners.size(), ships.size()]
	return true

func has_group(city) -> bool:
	return not banners.is_empty() or city.trireme_orders.group.size() > 1

# A right click with a group chosen: every company and trireme of it goes there.
func order(city, cell: Vector2i) -> bool:
	var sent := false
	if not banners.is_empty():
		sent = city.core.send("banners_move %d %d %s" % [cell.x, cell.y, " ".join(banners.map(func(id): return str(id)))]) or sent
	if not city.trireme_orders.group.is_empty():
		sent = city.trireme_orders.order(city, cell) or sent
	return sent

func clear(city) -> void:
	banners = []
	city.army_view.select_group([])
	city.trireme_orders.clear()
