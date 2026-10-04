extends CanvasLayer
# The world map screen: the map picture of the adventure with its cities, and the panel of the selected city. It shows what the core's
# `world` query reports (regard, goods, relationship, pending requests, armies on the road) and offers the dealings of the SDL world
# screen: asking a city for goods, giving it a gift, fulfilling the requests it made (world_request, world_gift, world_fulfil), and the
# military ones: a raid, a conquest (or reinforcements for a city of the player's), defensive aid and a military strike. A raid and a
# conquest ask the core for the forces to send (ui/enlist_dialog.gd). Every rule lives in C++; this scene only lists, asks and reports.
# Layout and text live in ui/world_map.tscn.

signal closed
signal close_requested

const Goods = preload("res://scripts/goods.gd")
const KeyBindings = preload("res://scripts/key_bindings.gd")
const Marker = preload("res://ui/world_marker.gd")
const Armies = preload("res://ui/world_armies.gd")
const EnlistDialog = preload("res://ui/enlist_dialog.gd")
const MAP_DIRECTORY := "Textures/Zeus_Data_Images"
const DRACHMAS := 8388608

@onready var map: TextureRect = %Map
@onready var markers: Control = %Markers
@onready var atlas = %Atlas
@onready var relation: Label = %Relation
@onready var city_name: Label = %Name
@onready var leader: Label = %Leader
@onready var regard_name: Label = %RegardName
@onready var regard: ProgressBar = %Regard
@onready var goods_box: VBoxContainer = %Goods
@onready var tribute: Label = %Tribute
@onready var status: Label = %Status
@onready var request_button: Button = %Request
@onready var fulfil_button: Button = %Fulfil
@onready var gift_button: Button = %Gift
@onready var raid_button: Button = %Raid
@onready var conquer_button: Button = %Conquer
@onready var aid_button: Button = %Aid
@onready var quests_button: Button = %Quests

var core: Node
var world: Dictionary = {}
var envoy_portrait: Control
var selected := -1
var textures: Dictionary = {}
var marker_nodes: Dictionary = {}
var dialog: Window
var enlisting: RefCounted
var armies_layer: Control
var transitioning := false

func _ready() -> void:
	map.resized.connect(place_markers)
	markers.resized.connect(place_markers)
	atlas.camera_changed.connect(place_markers)
	%AtlasCaption.text=tr("City states of the ancient world")
	%AtlasOverview.text=tr("Overview")
	%AtlasFocus.text=tr("Focus city")
	%AtlasZoomIn.tooltip_text=tr("Zoom in")
	%AtlasZoomOut.tooltip_text=tr("Zoom out")
	%AtlasHint.text=tr("Drag to orbit · Wheel to zoom · Right drag to pan")
	%AtlasOverview.pressed.connect(atlas.reset_view)
	%AtlasZoomIn.pressed.connect(func(): atlas.zoom(.8))
	%AtlasZoomOut.pressed.connect(func(): atlas.zoom(1.25))
	%AtlasFocus.pressed.connect(func():
		var city:=find_city(selected)
		if not city.is_empty():
			atlas.target=atlas.surface_point(Vector2(float(city.x),float(city.y)))
			atlas.zoom(16.0/atlas.desired_distance))
	%Previous.pressed.connect(func(): step(-1))
	%Next.pressed.connect(func(): step(1))
	%Back.pressed.connect(close)
	request_button.pressed.connect(open_request)
	fulfil_button.pressed.connect(open_fulfil)
	gift_button.pressed.connect(open_gift)
	raid_button.pressed.connect(func(): open_enlist("world_raid %d" % selected))
	conquer_button.pressed.connect(func(): open_enlist("world_conquer %d" % selected))
	aid_button.pressed.connect(open_aid)
	quests_button.pressed.connect(open_quests)
	# The armies on the road lie over the picture and under the markers.
	armies_layer = Armies.new()
	markers.get_parent().add_child(armies_layer)
	markers.get_parent().move_child(armies_layer, markers.get_index())

# Shows the world of the city being played. Returns false when the core cannot tell (no city loaded).
func prewarm(core_node: Node) -> void:
	var answer: Dictionary = core_node.query("world")
	if answer.has("error"): return
	load_map(String(answer.image))
	atlas.configure(answer)
	# Prepare the relief during the initial paused city load, without a render
	# pass, visible world screen, native action or changed selection.

func open(core_node: Node) -> bool:
	core = core_node
	var answer: Dictionary = core.query("world")
	if answer.has("error"):
		return false
	world = answer
	load_map(String(world.image))
	atlas.configure(world)
	rebuild_markers()
	if find_city(selected).is_empty():
		selected = default_city()
	status.text = ""
	visible = true
	atlas.set_active(true)
	%AtlasTitle.text=tr("The Aegean world") if String(world.image).begins_with("Zeus") else tr("The Atlantean world")
	select_city(selected)
	place_markers.call_deferred()   # the layout of a screen that has just appeared settles a frame later
	return true

func close() -> void:
	if not visible: return
	close_dialog()
	if close_requested.has_connections():
		close_requested.emit()
	else:
		finish_close()

func finish_close() -> void:
	visible = false
	atlas.set_active(false)
	closed.emit()

# ---------------------------------------------------------------------------------------------------- map and markers
func load_map(image_name: String) -> void:
	if not textures.has(image_name):
		# The original game's pictures sit beside the repository (Textures/Zeus_Data_Images), like Audio/ and DATA/.
		var path := ProjectSettings.globalize_path("res://..").simplify_path().get_base_dir().path_join(MAP_DIRECTORY).path_join(image_name)
		var image := Image.load_from_file(path) if FileAccess.file_exists(path) else null
		textures[image_name] = ImageTexture.create_from_image(image) if image != null else null
	map.texture = textures[image_name]

# Where the map picture lies inside the marker layer (the picture keeps its proportions in the space it has).
func image_rect() -> Rect2:
	return Rect2(Vector2.ZERO,markers.size)

func rebuild_markers() -> void:
	for child in markers.get_children():
		child.free()
	marker_nodes.clear()
	if atlas.built:
		atlas.update_cities(world.get("cities",[]))
	for city in world.cities:
		var marker := Marker.new()
		markers.add_child(marker)
		marker.setup(city)
		marker.picked.connect(select_city)
		marker_nodes[int(city.index)] = marker
	place_markers()

func place_markers() -> void:
	if not atlas.built:
		return
	var rect := image_rect()
	if rect.size.x<10 or rect.size.y<10:
		return
	armies_layer.set_state(world.get("armies", []), world.get("cities", []), rect)
	armies_layer.projection=func(uv:Vector2): return atlas.project(uv,.18)
	for index in marker_nodes:
		var marker: Control = marker_nodes[index]
		var city := find_city(int(index))
		var uv:=Vector2(float(city.x),float(city.y))
		var point:Vector2=atlas.project(uv,.78)
		marker.position=point-marker.anchor()
		marker.visible=not atlas.camera.is_position_behind(atlas.surface_point(uv,.78)) and rect.grow(-5).has_point(point)
	armies_layer.queue_redraw()

# ------------------------------------------------------------------------------------------------------------ cities
func find_city(index: int) -> Dictionary:
	for city in world.get("cities", []):
		if int(city.index) == index:
			return city
	return {}

func default_city() -> int:
	for city in world.get("cities", []):
		if bool(city.current):
			return int(city.index)
	var cities: Array = world.get("cities", [])
	return int(cities[0].index) if not cities.is_empty() else -1

func step(direction: int) -> void:
	var cities: Array = world.get("cities", [])
	if cities.is_empty():
		return
	var at := -1
	for slot in cities.size():
		if int(cities[slot].index) == selected:
			at = slot
	var next := (at + direction + cities.size()) % cities.size() if at >= 0 else 0
	select_city(int(cities[next].index))

func select_city(index: int) -> void:
	selected = index
	atlas.select_city(index)
	for key in marker_nodes:
		marker_nodes[key].set_selected(int(key) == index)
	var marker: Control = marker_nodes.get(index)
	if marker != null:
		markers.move_child(marker, markers.get_child_count() - 1)
	show_city()

func relation_text(city: Dictionary) -> String:
	if bool(city.current):
		return tr("Your city")
	match String(city.type):
		"parent": return tr("Parent city")
		"colony": return tr("Colony")
		"distant": return tr("Distant city")
		"place": return tr("Enchanted place")
		"ruins": return tr("Ruins")
	match String(city.relationship):
		"ally": return tr("Ally")
		"vassal": return tr("Vassal")
		"rival": return tr("Rival")
	return tr("City")

func requests_of(index: int) -> Array:
	return world.get("requests", []).filter(func(request): return int(request.city) == index)

func show_city() -> void:
	show_quests()
	var city := find_city(selected)
	for child in goods_box.get_children():
		child.free()
	if city.is_empty():
		relation.text = ""
		city_name.text = tr("Select a city on the map")
		leader.text = ""
		regard_name.text = ""
		regard.visible = false
		tribute.text = ""
		for button in [request_button, fulfil_button, gift_button, raid_button, conquer_button, aid_button]:
			button.disabled = true
		return
	relation.text = relation_text(city)
	city_name.text = String(city.name)
	if envoy_portrait == null:
		envoy_portrait = load("res://ui/envoy_portrait.gd").new()
		leader.get_parent().add_child(envoy_portrait)
		leader.get_parent().move_child(envoy_portrait, leader.get_index())
	envoy_portrait.set_sender(int(city.index))
	leader.text = tr("Leader: %s") % city.leader if String(city.leader) != "" and String(city.type) == "foreign" else ""
	var named := String(city.attitude_name) != ""
	regard_name.text = String(city.attitude_name)
	regard.visible = named
	regard.value = float(city.attitude)
	regard.tooltip_text = tr("Regard: %d of 100") % int(city.attitude)
	add_goods(tr("Sells to you"), city.sells)
	add_goods(tr("Buys from you"), city.buys)
	var due := requests_of(selected)
	tribute.text = ""
	if (String(city.type) == "colony" or String(city.relationship) == "vassal") and int(city.tribute.count) > 0:
		tribute.text = tr("Tribute: %d %s") % [int(city.tribute.count), Goods.name_of(int(city.tribute.resource))]
	request_button.disabled = not bool(city.can_request)
	gift_button.disabled = not bool(city.can_gift)
	fulfil_button.disabled = not bool(city.can_fulfil)
	fulfil_button.text = tr("Fulfil") + (" (%d)" % due.size() if not due.is_empty() else "")
	raid_button.disabled = not bool(city.can_raid)
	raid_button.tooltip_text = tr("Send an army to raid this city for plunder.") if bool(city.can_raid) else tr("This city cannot be raided.")
	conquer_button.disabled = not bool(city.can_conquer)
	conquer_button.text = tr("Reinforce") if bool(city.reinforce) else tr("Conquer")
	conquer_button.tooltip_text = (tr("Send troops to defend this city.") if bool(city.reinforce) else tr("Send an army to conquer this city.")) if bool(city.can_conquer) else tr("This city cannot be conquered.")
	aid_button.disabled = String(city.aid) == ""
	aid_button.tooltip_text = tr("Ask this city for troops, or to strike a rival.") if String(city.aid) != "" else tr("Nothing can be asked of this city.")

func add_goods(title: String, list: Array) -> void:
	if list.is_empty():
		return
	var heading := Label.new()
	heading.theme_type_variation = "Subheading"
	heading.text = title
	goods_box.add_child(heading)
	for item in list:
		var line := Label.new()
		line.theme_type_variation = "Caption"
		line.text = "%s  —  %d  (%d / %d)" % [Goods.name_of(int(item.resource)), int(item.price), int(item.used), int(item.max)]
		goods_box.add_child(line)

# ---------------------------------------------------------------------------------------------------------- dealings
func reason(code: String) -> String:
	var messages := {
		"not_regarded": "This city does not regard you enough to grant anything.",
		"not_offered": "This city does not offer that.",
		"world_dealings_unavailable": "Nothing can be asked of or given to this city.",
		"invalid_gift": "That is not a size of gift.",
		"not_enough_goods": "There are not enough goods in that city.",
		"unknown_request": "That request is no longer there.",
		"unknown_city": "That city is not on the map.",
		"not_owned": "That is not one of your cities.",
		"pending_decision": "Resolve the city's pending decision first.",
		"military_unavailable": "That cannot be done to this city.",
		"cant_spare": "This city has no troops to spare.",
		"present": "Aid from this city is already with you.",
		"not_a_rival": "That city is not a rival.",
		"no_hall": "You have no hall for that hero.",
		"hero_not_ready": "The hero has not arrived yet.",
		"unknown_quest": "That quest is no longer asked for."}
	return tr(messages.get(code, "The action could not be completed"))

# Sends one dealing to the core; on success the world is read again so the panel, the markers and the requests follow.
func act(command: String, success: String) -> bool:
	var answer: Dictionary = core.query(command)
	if answer.has("error"):
		status.text = reason(str(answer.error))
		return false
	world = answer
	status.text = success
	rebuild_markers()
	select_city(selected)
	return true

# The enlisting of the forces for a raid or a conquest: the core says what may be enlisted, the dialog chooses, the core sends.
func open_enlist(command: String) -> void:
	close_dialog()
	var session: Dictionary = core.query(command)
	if session.has("error"):
		status.text = reason(str(session.error))
		return
	var city := find_city(selected)
	var sent := tr("The army sets out for %s.") % city.name
	var finished := func(answer: Dictionary):
		world = answer
		status.text = sent
		rebuild_markers()
		select_city(selected)
	var dismissed := func():
		enlisting = null
		dialog = null
	enlisting = EnlistDialog.open(self, core, session, finished, dismissed)
	dialog = enlisting.window

func close_dialog() -> void:
	if enlisting != null:
		# The enlisting is dropped in the core too; its dialog frees itself.
		enlisting.cancel()
		return
	if dialog != null and is_instance_valid(dialog):
		dialog.hide()   # an exclusive window frees its place at once; queue_free alone would keep it for a frame
		dialog.queue_free()
	dialog = null

# A dialog over the map with a column to fill and a Close button.
func open_dialog(title: String, size_hint := Vector2i(560, 420)) -> VBoxContainer:
	close_dialog()
	var window := AcceptDialog.new()
	window.title = title
	window.ok_button_text = tr("Close")
	window.exclusive = true
	window.theme = load("res://ui/lapis_gold.tres")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(size_hint.x - 40, size_hint.y - 110)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	window.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	add_child(window)
	window.confirmed.connect(close_dialog)
	window.canceled.connect(close_dialog)
	window.close_requested.connect(close_dialog)
	window.popup_centered(size_hint)
	dialog = window
	return column

func caption(parent: Node, text: String) -> Label:
	var line := Label.new()
	line.theme_type_variation = "Caption"
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(line)
	return line

# The player's cities (the dealing is made from or into one of them): a chooser when there are several. `holder.city` follows it.
func city_chooser(parent: Node, holder: Dictionary, changed: Callable) -> void:
	var mine: Array = world.get("mine", [])
	holder.city = int(mine[0].id) if not mine.is_empty() else -1
	if mine.size() < 2:
		return
	var row := HBoxContainer.new()
	var label := Label.new()
	label.theme_type_variation = "Caption"
	label.text = tr("Your city")
	row.add_child(label)
	var chooser := OptionButton.new()
	for city in mine:
		chooser.add_item(String(city.name), int(city.id))
	chooser.item_selected.connect(func(slot: int):
		holder.city = chooser.get_item_id(slot)
		changed.call())
	row.add_child(chooser)
	parent.add_child(row)

func open_request() -> void:
	var city := find_city(selected)
	if city.is_empty() or not bool(city.can_request):
		return
	var column := open_dialog(tr("Request from %s") % city.name)
	if not bool(city.regarded):
		caption(column, tr("%s does not regard you enough to grant anything.") % city.name)
		return
	var holder := {}
	city_chooser(column, holder, func(): pass)
	var verb := tr("Request %s")
	if String(city.relationship) == "vassal" or String(city.type) == "colony":
		verb = tr("Order %s")
	elif String(city.relationship) == "rival":
		verb = tr("Demand %s")
	var offered: Array = city.sells.map(func(item): return int(item.resource))
	offered.append(DRACHMAS)
	for resource in offered:
		var button := Button.new()
		button.text = verb % Goods.name_of(resource)
		button.pressed.connect(func():
			close_dialog()
			act("world_request %d %d %d" % [selected, resource, holder.city], tr("Your request for %s has gone to %s. The answer comes in about three months.") % [Goods.name_of(resource), city.name]))
		column.add_child(button)
	caption(column, tr("Every city's regard falls by 10 when you ask, and this city's by 10 more."))

# Defensive aid and a military strike: the SDL request dialog's two military offers, which depend on the city's regard and its troops.
func open_aid() -> void:
	var city := find_city(selected)
	if city.is_empty() or String(city.aid) == "":
		return
	var column := open_dialog(tr("Aid from %s") % city.name)
	match String(city.aid):
		"not_regarded":
			caption(column, tr("%s does not regard you enough to send aid.") % city.name)
			return
		"cant_spare":
			caption(column, tr("%s has no troops to spare.") % city.name)
			return
		"present":
			caption(column, tr("Aid from %s is already with you.") % city.name)
			return
	var holder := {}
	city_chooser(column, holder, func(): pass)
	var aid_request := Button.new()
	aid_request.text = tr("Request defensive aid")
	aid_request.pressed.connect(func():
		close_dialog()
		act("world_aid %d %d" % [selected, holder.city], tr("Your request for aid has gone to %s. Its troops arrive in about a month.") % city.name))
	column.add_child(aid_request)
	caption(column, tr("Every city's regard falls by 10 when you ask, and this city's by 10 more."))
	var rivals: Array = world.get("rivals", [])
	if rivals.is_empty():
		caption(column, tr("There are no cities to strike."))
		return
	var chooser := OptionButton.new()
	for rival in rivals:
		chooser.add_item(String(find_city(int(rival)).name), int(rival))
	column.add_child(chooser)
	var strike := Button.new()
	strike.text = tr("Request a military strike")
	strike.pressed.connect(func():
		var target := chooser.get_selected_id()
		var target_name := String(find_city(target).name)
		close_dialog()
		act("world_strike %d %d" % [selected, target], tr("%s will strike %s in about a month.") % [city.name, target_name]))
	column.add_child(strike)

func open_gift() -> void:
	var city := find_city(selected)
	if city.is_empty() or not bool(city.can_gift):
		return
	var column := open_dialog(tr("Gift to %s") % city.name, Vector2i(600, 520))
	var holder := {}
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	var rebuild := func():
		for child in list.get_children():
			child.free()
		var mine := {}
		for entry in world.mine:
			if int(entry.id) == int(holder.city):
				mine = entry
		var any := false
		for item in mine.get("stock", []):
			var step := int(item.step)
			if int(item.count) < step:
				continue
			any = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var label := Label.new()
			label.text = "%s  (%d)" % [Goods.name_of(int(item.resource)), int(item.count)]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			for times in [1, 2, 3]:
				var count: int = step * times
				var button := Button.new()
				button.text = str(count)
				button.disabled = count > int(item.count)
				button.pressed.connect(func():
					close_dialog()
					act("world_gift %d %d %d %d" % [selected, int(item.resource), count, holder.city], tr("A gift of %d %s is on its way to %s. It arrives in about three months.") % [count, Goods.name_of(int(item.resource)), city.name]))
				row.add_child(button)
			list.add_child(row)
		if not any:
			caption(list, tr("There is nothing to give."))
	city_chooser(column, holder, rebuild)
	column.add_child(list)
	rebuild.call()

# The gods' quests (the SDL overview lists them with the requests): the god, what it asks, the hero it asks for and whether he has arrived.
func show_quests() -> void:
	var list: Array = world.get("quests", [])
	quests_button.text = tr("Quests of the gods") + (" (%d)" % list.size() if not list.is_empty() else "")
	quests_button.disabled = list.is_empty()
	quests_button.tooltip_text = tr("Send a hero on the quest a god asks for.") if not list.is_empty() else tr("No god asks anything of you.")

func open_quests() -> void:
	var column := open_dialog(tr("Quests of the gods"))
	var list: Array = world.get("quests", [])
	if list.is_empty():
		caption(column, tr("No god asks anything of you."))
		return
	for quest in list:
		var heading := Label.new()
		heading.theme_type_variation = "Subheading"
		heading.text = "%s: %s" % [str(quest.god_name), str(quest.name)]
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(heading)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var line := Label.new()
		line.theme_type_variation = "Caption"
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not bool(quest.hall):
			line.text = tr("You have no hall for %s.") % str(quest.hero_name)
		elif not bool(quest.ready):
			line.text = tr("%s has not arrived yet.") % str(quest.hero_name)
		else:
			line.text = tr("%s waits in the city.") % str(quest.hero_name)
		row.add_child(line)
		var send := Button.new()
		send.text = tr("Send %s") % str(quest.hero_name)
		send.disabled = not bool(quest.ready)
		send.pressed.connect(func():
			close_dialog()
			act("world_quest %d" % int(quest.id), tr("%s sets out on the quest.") % str(quest.hero_name)))
		row.add_child(send)
		column.add_child(row)

func open_fulfil() -> void:
	var city := find_city(selected)
	if city.is_empty() or not bool(city.can_fulfil):
		return
	var column := open_dialog(tr("Requests of %s") % city.name)
	var due := requests_of(selected)
	if due.is_empty():
		caption(column, tr("%s asks nothing of you.") % city.name)
		return
	for request in due:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var label := Label.new()
		label.text = "%d  %s" % [int(request.count), Goods.name_of(int(request.resource))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var senders: Array = request.from.map(func(id): return int(id))
		if senders.is_empty():
			var none := Label.new()
			none.theme_type_variation = "Caption"
			none.text = tr("You do not have enough.")
			row.add_child(none)
		for entry in world.mine:
			if not int(entry.id) in senders:
				continue
			var button := Button.new()
			button.text = tr("Send from %s") % entry.name if world.mine.size() > 1 else tr("Send")
			button.pressed.connect(func():
				close_dialog()
				act("world_fulfil %d %d" % [int(request.id), int(entry.id)], tr("%d %s have gone to %s.") % [int(request.count), Goods.name_of(int(request.resource)), city.name]))
			row.add_child(button)
		column.add_child(row)

# ------------------------------------------------------------------------------------------------------------- input
func _input(event: InputEvent) -> void:
	if not visible or dialog != null or transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# City controls cannot change simulation/tools behind the atlas (the player's own keys for them, and Delete).
		if KeyBindings.matches(event, "world_map"):
			close()
			get_viewport().set_input_as_handled()
			return
		for id in ["pause", "quick_save", "quick_load", "turn_placement", "demolish", "undo"]:
			if KeyBindings.matches(event, id):
				get_viewport().set_input_as_handled()
				return
		match event.physical_keycode:
			KEY_ESCAPE:
				close()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				step(-1)
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				step(1)
				get_viewport().set_input_as_handled()
			KEY_HOME:
				atlas.reset_view()
				get_viewport().set_input_as_handled()
			KEY_DELETE:
				get_viewport().set_input_as_handled()
