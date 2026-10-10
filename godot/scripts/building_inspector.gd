extends VBoxContainer

signal action_requested(command: String)

const Goods = preload("res://scripts/goods.gd")

var value: Dictionary = {}
var schema := ""
var rows: Dictionary = {}
var industry_buttons: Dictionary = {}
var bay_label: Label
var production_label: Label
var harvest_label: Label
var harvest_bar: ProgressBar
var stock_label: Label
var native_notes: Label
var trade_status: Label
var trade_rows: Dictionary = {}
var hall_stage_label: Label
var monument_lines: Label
var construction_bar: ProgressBar
var construction_advice: Label
var monument_halt_button: Button
var monument_help_button: Button
var monument_help_bar: ProgressBar
var monument_help_result: Label
var monument_attack_button: Button
var monument_attack_popup: PopupMenu
var monument_attack_bar: ProgressBar
var monument_attack_result: Label
var hall_rows: Array = []
var summon_button: Button
# The SDL page's own lines (the hippodrome, the trireme wharf: engine/ebuildinginfotext) and the wharf's switch.
var notes_label: Label
var switch_button: Button
# A walker building's route (the SDL route editor): the button that begins editing it (scripts/route_editor.gd).
var route_button: Button
var ruin_demolish_button: Button
var pending := false
# Edits apply by themselves: a changed order is sent at once, a typed limit once it settles (LIMIT_SETTLE_MS) or is committed. A draft
# stays dirty (and keeps the player's value on screen) until the core has answered, and the drafts go out one at a time.
const LIMIT_SETTLE_MS := 700
var commit_at := {}
var inflight := {}
var sync_label: Label
var all_order: OptionButton
var all_limit: SpinBox
var storage_grid: GridContainer
var agora_tiles := {}
var native_expanded := false
# True while a command is being handed over: a refusal then (the command queue is full) keeps the draft and tries again.
var handing_over := false
const RETRY_MS := 1000

func resource_name(resource: int) -> String:
	return Goods.name_of(resource)

func label(text: String, heading := false) -> Label:
	var item := Label.new()
	item.text = text
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if heading:
		item.theme_type_variation = "Subheading"
	add_child(item)
	return item

func show_inspection(data: Dictionary) -> void:
	value = data
	var trade_shape := "%d/%d" % [data.get("trade", {}).get("imports", []).size(), data.get("trade", {}).get("exports", []).size()] if data.has("trade") else ""
	var key := "%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [data.get("target_token", 0), TranslationServer.get_locale(), data.get("storage", {}).get("resources", []).size(), data.has("production"), trade_shape, data.get("hall", {}).get("requirements", []).size(), data.get("monument", {}).get("finished", "-"), data.get("monument", {}).get("attack", {}).get("targets", []).size(), data.has("notes"), data.has("switch"), data.has("route"), data.get("agora", {}).get("vendors", []).size()]
	if key != schema:
		schema = key
		pending = false
		commit_at.clear()
		inflight = {}
		sync_label = null
		all_order = null
		all_limit = null
		storage_grid = null
		agora_tiles.clear()
		rows.clear()
		trade_rows.clear()
		industry_buttons.clear()
		hall_rows.clear()
		hall_stage_label = null
		summon_button = null
		notes_label = null
		switch_button = null
		route_button = null
		ruin_demolish_button = null
		monument_lines = null
		construction_bar = null
		construction_advice = null
		monument_halt_button = null
		monument_help_button = null
		monument_help_bar = null
		monument_help_result = null
		monument_attack_button = null
		monument_attack_popup = null
		monument_attack_bar = null
		monument_attack_result = null
		native_notes = null
		harvest_label = null
		harvest_bar = null
		for child in get_children():
			remove_child(child)
			child.queue_free()
		add_theme_constant_override("separation", 10)
		if data.has("ruin"):
			ruin_demolish_button = Button.new()
			ruin_demolish_button.name = "DemolishRuin"
			ruin_demolish_button.focus_mode = Control.FOCUS_NONE
			add_child(ruin_demolish_button)
			ruin_demolish_button.pressed.connect(func():
				if pending or not value.ruin.can_demolish: return
				pending = true
				action_requested.emit("demolish_ruin %d %d %d %d" % [int(value.x),int(value.y),int(value.target_token),int(value.ruin.target_token)])
				update_live_data())
		# A trade post is a store whose orders are its trade with one partner: show those instead of the raw store orders.
		if data.has("trade"):
			build_trade(data.trade)
		elif data.has("storage"):
			build_storage(data.storage)
		if data.has("agora"):
			build_agora(data.agora)
		if data.has("production"):
			build_production(data.production)
		if data.has("hall"):
			build_hall(data.hall)
		if data.has("monument"):
			build_monument(data.monument)
		if data.has("notes"):
			if not str(data.get("notes_title", "")).is_empty():
				label(str(data.notes_title), true)
			notes_label = label("")
		if data.has("switch"):
			switch_button = Button.new()
			switch_button.focus_mode = Control.FOCUS_NONE
			add_child(switch_button)
			switch_button.pressed.connect(func():
				if pending or not value.get("can_edit", false):
					return
				pending = true
				action_requested.emit("building_switch %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), 0 if value.switch.working else 1])
				update_live_data())
		if data.has("route"):
			route_button = Button.new()
			route_button.name = "WalkerRoute"
			route_button.focus_mode = Control.FOCUS_NONE
			route_button.tooltip_text = tr("Lead this building's walkers along the roads you choose")
			add_child(route_button)
			route_button.pressed.connect(func():
				if not value.get("can_edit", false):
					return
				action_requested.emit("route_begin %d %d %d" % [int(value.x), int(value.y), int(value.target_token)]))
		var native_text: Array[String] = []
		for field in ["info", "employment_info", "additional_info"]:
			if not str(data.get(field, "")).is_empty():
				native_text.append(str(data[field]))
		if not native_text.is_empty():
			var more := Button.new()
			more.text = tr("Building details")
			more.focus_mode = Control.FOCUS_NONE
			add_child(more)
			native_notes = label("\n\n".join(native_text))
			native_notes.theme_type_variation = "Caption"
			# An agora's words (what its peddler is doing) are part of its page; elsewhere the details fold away.
			native_notes.visible = data.has("agora")
			more.toggle_mode = true
			more.button_pressed = native_notes.visible
			more.pressed.connect(func(): native_notes.visible = more.button_pressed)
	update_live_data()

# A hero's hall: the hero's requirements, each with how far the city is from meeting it, the stage of the summoning and the button that
# summons him once every requirement is met (the SDL hall inspector's content; the core words the requirements).
func build_hall(hall: Dictionary) -> void:
	label(str(hall.hero_name), true)
	hall_stage_label = label("")
	label(tr("The hero asks of the city"), true)
	for requirement in hall.requirements:
		var row := label("")
		hall_rows.append(row)
	summon_button = Button.new()
	summon_button.focus_mode = Control.FOCUS_NONE
	add_child(summon_button)
	summon_button.pressed.connect(func():
		if pending or not value.get("hall", {}).get("can_summon", false):
			return
		pending = true
		action_requested.emit("hero_summon %d %d %d" % [int(value.x), int(value.y), int(value.target_token)])
		update_live_data())

# A monument (a sanctuary): while it is being built how far it has come, what it still needs and a button to halt or resume the work; once it
# stands the god's description and the button that asks the god for help (the SDL sanctuary inspector's content, worded by the core).
func build_monument(monument: Dictionary) -> void:
	label(str(monument.title), true)
	if not bool(monument.finished):
		label(tr("Construction progress"),true)
		construction_bar=ProgressBar.new();construction_bar.max_value=100
		construction_bar.custom_minimum_size.y=20;add_child(construction_bar)
		construction_advice=label("")
		monument_lines = label("")
		monument_halt_button = Button.new()
		monument_halt_button.focus_mode = Control.FOCUS_NONE
		add_child(monument_halt_button)
		monument_halt_button.pressed.connect(func():
			if pending or not value.get("can_control", false):
				return
			pending = true
			action_requested.emit("monument_halt %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), 0 if value.monument.halted else 1])
			update_live_data())
	elif bool(monument.get("pyramid", false)):
		# A finished pyramid, monument or shrine only stands: the game's description of it (a shrine names its god).
		var summary := label(str(monument.description))
		summary.theme_type_variation = "Caption"
	elif bool(monument.sanctuary):
		var description := label(str(monument.description))
		description.theme_type_variation="Caption"
		monument_help_button = Button.new()
		monument_help_button.focus_mode = Control.FOCUS_NONE
		monument_help_button.text = str(monument.help_label)
		add_child(monument_help_button)
		monument_help_bar = ProgressBar.new()
		monument_help_bar.min_value = 0
		monument_help_bar.max_value = 100
		monument_help_bar.show_percentage = false
		monument_help_bar.custom_minimum_size = Vector2(0, 10)
		add_child(monument_help_bar)
		monument_help_result = label("")
		monument_help_result.theme_type_variation = "Caption"
		monument_help_button.pressed.connect(func():
			if pending or not value.get("can_control", false):
				return
			pending = true
			action_requested.emit("sanctuary_help %d %d %d" % [int(value.x), int(value.y), int(value.target_token)])
			update_live_data())
		if monument.has("attack"):
			build_attack(monument.attack)

# "God Invasion": send the god against an enemy city on the board (one city is asked at once, several through a small menu). The wait for
# the next attack is the bar; the god's answer, in the game's words, is the line under it.
func build_attack(attack: Dictionary) -> void:
	monument_attack_button = Button.new()
	monument_attack_button.focus_mode = Control.FOCUS_NONE
	monument_attack_button.text = str(attack.label)
	monument_attack_button.tooltip_text = tr("Send the god against an enemy city")
	add_child(monument_attack_button)
	monument_attack_popup = PopupMenu.new()
	monument_attack_button.add_child(monument_attack_popup)
	for target in attack.targets:
		monument_attack_popup.add_item(str(target.name), int(target.city))
	monument_attack_popup.id_pressed.connect(func(city): ask_attack(int(city)))
	monument_attack_bar = ProgressBar.new()
	monument_attack_bar.min_value = 0
	monument_attack_bar.max_value = 100
	monument_attack_bar.show_percentage = false
	monument_attack_bar.custom_minimum_size = Vector2(0, 10)
	add_child(monument_attack_bar)
	monument_attack_result = label("")
	monument_attack_result.theme_type_variation = "Caption"
	monument_attack_button.pressed.connect(func():
		if pending or not value.get("can_control", false):
			return
		if attack.targets.size() == 1:
			ask_attack(int(attack.targets[0].city))
		else:
			monument_attack_popup.popup(Rect2i(Vector2i(monument_attack_button.get_screen_position()) + Vector2i(0, int(monument_attack_button.size.y)), Vector2i(int(monument_attack_button.size.x), 0))))

func ask_attack(city: int) -> void:
	if pending or not value.get("can_control", false):
		return
	pending = true
	action_requested.emit("sanctuary_attack %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), city])
	update_live_data()

# ---- agora --------------------------------------------------------------------------------------------------
# The SDL agora window's six boxes: each stall's goods, what it holds and whether it is handing them out.
const AGORA_NAMES := {"food": "Food", "fleece": "Fleece", "oil": "Olive oil", "wine": "Wine", "arms": "Arms", "horses": "Horses", "chariots": "Chariots"}
const AGORA_ICONS := {"food": "food_total", "fleece": "fleece", "oil": "oil", "wine": "wine", "arms": "arms", "horses": "horses", "chariots": "chariots"}

func build_agora(agora: Dictionary) -> void:
	label(tr("Stalls"), true)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for vendor in agora.vendors:
		var key := str(vendor.key)
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel", tile_style(Color(.45, .55, .68, .35)))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		tile.add_child(column)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		column.add_child(head)
		var icon := TextureRect.new()
		icon.texture = Goods.icon_named(str(AGORA_ICONS.get(key, "")))
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(icon)
		var name := Label.new()
		name.text = tr(AGORA_NAMES.get(key, "Goods"))
		name.theme_type_variation = "Detail"
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name.tooltip_text = name.text
		name.mouse_filter = Control.MOUSE_FILTER_PASS
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name)
		var stock := Label.new()
		stock.theme_type_variation = "ToolHeading"
		column.add_child(stock)
		var status := Label.new()
		status.theme_type_variation = "Caption"
		column.add_child(status)
		grid.add_child(tile)
		agora_tiles[key] = {"tile": tile, "stock": stock, "status": status}

static func tile_style(border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(.04, .08, .12, .7)
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 9
	box.content_margin_right = 9
	box.content_margin_top = 6
	box.content_margin_bottom = 7
	return box

# ---- stores ---------------------------------------------------------------------------------------------------
const ORDER_NAMES := ["Reject", "Accept", "Get", "Empty"]

func order_button() -> OptionButton:
	var order := OptionButton.new()
	order.focus_mode = Control.FOCUS_NONE
	order.custom_minimum_size.x = 104
	order.fit_to_longest_item = false
	order.tooltip_text = tr("Get collects from other stores; Empty sends stock away through native carts.")
	return order

func limit_box(maximum: int, step: int) -> SpinBox:
	var limit := SpinBox.new()
	limit.min_value = 0
	limit.max_value = maximum
	limit.step = step
	limit.custom_minimum_size.x = 86
	limit.tooltip_text = tr("Stock limit")
	return limit

func small_caption(text: String, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var item := Label.new()
	item.text = text
	item.theme_type_variation = "Detail"
	item.horizontal_alignment = align
	return item

func build_storage(storage: Dictionary) -> void:
	label(tr("Stored goods"), true)
	var capacity := HBoxContainer.new()
	capacity.add_theme_constant_override("separation", 10)
	add_child(capacity)
	bay_label = Label.new()
	bay_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capacity.add_child(bay_label)
	sync_label = Label.new()
	sync_label.theme_type_variation = "Caption"
	capacity.add_child(sync_label)
	var note := label(tr("Limits use cargo loads. Each bay holds 4 loads, or 1 sculpture. Lower limits keep existing stock."))
	note.theme_type_variation = "Caption"
	storage_grid = GridContainer.new()
	storage_grid.columns = 4
	storage_grid.add_theme_constant_override("h_separation", 8)
	storage_grid.add_theme_constant_override("v_separation", 5)
	add_child(storage_grid)
	storage_grid.add_child(small_caption(""))
	storage_grid.add_child(small_caption(tr("Stock"), HORIZONTAL_ALIGNMENT_RIGHT))
	storage_grid.add_child(small_caption(tr("Orders")))
	storage_grid.add_child(small_caption(tr("Limit")))
	# One row to set them all: choosing an order or a limit here sends it for every good below.
	var largest := 0
	for goods in storage.resources:
		largest = maxi(largest, int(goods.max_limit))
	var everything := Label.new()
	everything.text = tr("All goods")
	everything.theme_type_variation = "ToolHeading"
	everything.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_grid.add_child(everything)
	storage_grid.add_child(small_caption(""))
	all_order = order_button()
	all_order.add_item(tr("Mixed"))
	for names in ORDER_NAMES:
		all_order.add_item(tr(names))
	all_order.tooltip_text = tr("Set the order for every good in this store")
	storage_grid.add_child(all_order)
	all_limit = limit_box(largest, 4)
	all_limit.tooltip_text = tr("Set the limit for every good in this store")
	storage_grid.add_child(all_limit)
	all_order.item_selected.connect(func(index):
		if index <= 0 or not value.get("can_edit", false):
			return
		for resource in rows:
			rows[resource].order.select(index - 1)
			edit_storage(resource, 0))
	all_limit.value_changed.connect(func(number):
		if not value.get("can_edit", false):
			return
		for resource in rows:
			var row: Dictionary = rows[resource]
			row.limit.value = minf(number, row.limit.max_value))
	all_limit.get_line_edit().text_submitted.connect(func(_text): settle_all())
	all_limit.get_line_edit().focus_exited.connect(settle_all)
	for goods in storage.resources:
		var resource := int(goods.resource)
		var name_box := HBoxContainer.new()
		name_box.add_theme_constant_override("separation", 6)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var icon := TextureRect.new()
		icon.texture = Goods.icon_of(resource)
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		name_box.add_child(icon)
		var caption := Label.new()
		caption.text = resource_name(resource)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.tooltip_text = caption.text
		caption.mouse_filter = Control.MOUSE_FILTER_PASS
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_box.add_child(caption)
		storage_grid.add_child(name_box)
		var count := Label.new()
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.custom_minimum_size.x = 38
		storage_grid.add_child(count)
		var order := order_button()
		for names in ORDER_NAMES:
			order.add_item(tr(names))
		storage_grid.add_child(order)
		var limit := limit_box(int(goods.max_limit), int(goods.step))
		storage_grid.add_child(limit)
		rows[resource] = {"caption": caption, "count": count, "order": order, "limit": limit, "dirty": false}
		order.item_selected.connect(func(_index): edit_storage(resource, 0))
		limit.value_changed.connect(func(_number): edit_storage(resource, LIMIT_SETTLE_MS))
		limit.get_line_edit().text_submitted.connect(func(_text): settle(resource))
		limit.get_line_edit().focus_exited.connect(func(): settle(resource))

# ---- trade posts --------------------------------------------------------------------------------------------
func build_trade(trade: Dictionary) -> void:
	label(tr("Trade with %s") % trade.partner, true)
	var status_row := HBoxContainer.new()
	add_child(status_row)
	trade_status = Label.new()
	trade_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trade_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_row.add_child(trade_status)
	sync_label = Label.new()
	sync_label.theme_type_variation = "Caption"
	status_row.add_child(sync_label)
	var note := label(tr("Choose the goods this post trades and how much to keep in store: an import is bought until that much is held, an export is sold from the stock above nothing."))
	note.theme_type_variation="Caption"
	for section in [["imports", 0, "Imports: goods the partner sells"], ["exports", 1, "Exports: goods the partner buys"]]:
		var goods: Array = trade[section[0]]
		if goods.is_empty():
			continue
		label(tr(section[2]), true).theme_type_variation="ToolHeading"
		for item in goods:
			var key := "%d:%d" % [int(section[1]), int(item.resource)]
			var caption := label("")
			var row := HBoxContainer.new()
			add_child(row)
			var toggle := OptionButton.new()
			toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			toggle.focus_mode = Control.FOCUS_NONE
			toggle.add_item(tr("Not trading"))
			toggle.add_item(tr("Importing") if int(section[1]) == 0 else tr("Exporting"))
			row.add_child(toggle)
			var quota := SpinBox.new()
			quota.min_value = 0
			quota.max_value = int(item.max_quota)
			quota.step = int(item.step)
			quota.custom_minimum_size.x = 90
			quota.tooltip_text = tr("Stock to keep")
			row.add_child(quota)
			trade_rows[key] = {"caption": caption, "toggle": toggle, "quota": quota, "dirty": false, "direction": int(section[1]), "resource": int(item.resource)}
			toggle.item_selected.connect(func(_index): edit_trade(key, 0))
			quota.value_changed.connect(func(_number): edit_trade(key, LIMIT_SETTLE_MS))
			quota.get_line_edit().text_submitted.connect(func(_text): settle_trade(key))
			quota.get_line_edit().focus_exited.connect(func(): settle_trade(key))

# ---- automatic apply ------------------------------------------------------------------------------------------
func edit_trade(key: String, delay_ms: int) -> void:
	trade_rows[key].dirty = true
	commit_at["t|" + key] = Time.get_ticks_msec() + delay_ms
	update_live_data()

func edit_storage(resource: int, delay_ms: int) -> void:
	rows[resource].dirty = true
	commit_at["s|%d" % resource] = Time.get_ticks_msec() + delay_ms
	update_live_data()

# A typed limit is committed now (Enter, or leaving the box) instead of waiting for the pause.
func settle(resource: int) -> void:
	if commit_at.has("s|%d" % resource):
		commit_at["s|%d" % resource] = 0

func settle_trade(key: String) -> void:
	if commit_at.has("t|" + key):
		commit_at["t|" + key] = 0

func settle_all() -> void:
	for key in commit_at:
		commit_at[key] = 0

func _process(_delta: float) -> void:
	# Drafts go one at a time, in the order they came due, once the previous command has been answered.
	if pending or commit_at.is_empty():
		return
	var now := Time.get_ticks_msec()
	var due := ""
	for key in commit_at:
		if commit_at[key] <= now and (due.is_empty() or commit_at[key] < commit_at[due]):
			due = key
	if due.is_empty():
		return
	commit_at.erase(due)
	var kind := due.get_slice("|", 0)
	var id := due.get_slice("|", 1)
	if kind == "s":
		submit_storage(int(id))
	else:
		submit_trade(id)

func submit_trade(key: String) -> void:
	var row: Dictionary = trade_rows.get(key, {})
	if row.is_empty():
		return
	if not value.get("can_edit", false):
		row.dirty = false
		return
	pending = true
	inflight = {"kind": "t", "key": key, "state": row.toggle.selected, "number": int(row.quota.value)}
	handing_over = true
	action_requested.emit("trade %d %d %d %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), row.resource, row.direction, row.toggle.selected, int(row.quota.value)])
	handing_over = false
	update_live_data()

func submit_storage(resource: int) -> void:
	var row: Dictionary = rows.get(resource, {})
	if row.is_empty():
		return
	if not value.get("can_edit", false):
		row.dirty = false
		return
	# The native command includes the selected object's token, not just a tile.
	pending = true
	inflight = {"kind": "s", "key": resource, "state": row.order.selected, "number": int(row.limit.value)}
	handing_over = true
	action_requested.emit("storage %d %d %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), resource, row.order.selected, int(row.limit.value)])
	handing_over = false
	update_live_data()

func build_production(production: Dictionary) -> void:
	label(tr("Production"), true)
	production_label = label("")
	if production.has("harvest_progress"):
		harvest_label = label("")
		harvest_bar = ProgressBar.new()
		harvest_bar.step = 0.0
		harvest_bar.show_percentage = false
		harvest_bar.custom_minimum_size.y = 6
		harvest_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(harvest_bar)
	stock_label = label("")
	if not production.industries.is_empty():
		var note := label(tr("Industry controls affect every producer of these goods in this city, including shared producers."))
		note.theme_type_variation="Caption"
	for industry in production.industries:
		var resource := int(industry.resource)
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		add_child(button)
		industry_buttons[resource] = button
		button.pressed.connect(func():
			if pending or not value.get("can_edit", false):
				return
			var shut_down := false
			for current in value.production.industries:
				if int(current.resource) == resource:
					shut_down = current.shut_down
			pending = true
			action_requested.emit("industry %d %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), resource, 0 if shut_down else 1])
			update_live_data())

func update_live_data() -> void:
	if ruin_demolish_button != null:
		ruin_demolish_button.text = tr("Demolish · Cost: %d") % int(value.ruin.cost)
		ruin_demolish_button.disabled = pending or not value.ruin.can_demolish
		var reasons := {"on_fire":"A burning building cannot be demolished","not_owned":"Another city's land","pending_decision":"Resolve the city's pending decision first","insufficient_funds":"The city's credit limit has been reached"}
		ruin_demolish_button.tooltip_text = tr("Remove this entire ruined building. Demolition cannot be undone.") if value.ruin.can_demolish else tr(reasons.get(str(value.ruin.reason),"The selected building changed. Inspect it again"))
	var editable: bool = value.get("can_edit", false) and not pending
	if notes_label != null:
		notes_label.text = "\n".join(PackedStringArray(value.get("notes", [])))
	if switch_button != null and value.has("switch"):
		# As the SDL switch: it names the state the building is in; pressing it changes to the other.
		switch_button.text = str(value.switch.labels[1 if value.switch.working else 0])
		switch_button.disabled = not editable
	if route_button != null and value.has("route"):
		var guides := int(value.route.guides)
		route_button.text = tr("Walker route (%d guides)") % guides if guides > 0 else tr("Walker route")
		route_button.disabled = not editable
	if native_notes != null:
		var lines: Array[String] = []
		for field in ["info", "employment_info", "additional_info"]:
			if not str(value.get(field, "")).is_empty():
				lines.append(str(value[field]))
		native_notes.text = "\n\n".join(lines)
	if sync_label != null:
		sync_label.text = tr("Saving…") if pending or not commit_at.is_empty() else (tr("Changes apply automatically") if editable else "")
	if value.has("trade"):
		var trade: Dictionary = value.trade
		var kind := tr("A sea trade post (a pier).") if trade.water else tr("A land trade post.")
		trade_status.text = kind + ("" if trade.trading else "  " + tr("Trade with this partner is stopped."))
		for section in [["imports", 0], ["exports", 1]]:
			for item in trade[section[0]]:
				var row: Dictionary = trade_rows["%d:%d" % [int(section[1]), int(item.resource)]]
				var price := "" if trade.two_way else "  ·  " + tr("%d dr each") % int(item.price)
				row.caption.text = "%s  ·  %s %d%s  ·  %s" % [resource_name(int(item.resource)), tr("in store"), int(item.stock), price, tr("this year %d of %d") % [int(item.used), int(item.max)]]
				if not row.dirty:
					row.toggle.select(1 if item.enabled else 0)
					row.quota.set_value_no_signal(int(item.quota))
				row.toggle.disabled = not value.get("can_edit", false)
				row.quota.editable = value.get("can_edit", false)
	if value.has("storage") and not value.has("trade"):
		bay_label.text = tr("Bays in use: %d / %d") % [int(value.storage.occupied_bays), int(value.storage.bays)]
		var orders := {}
		var limits := {}
		for goods in value.storage.resources:
			var row: Dictionary = rows[int(goods.resource)]
			row.count.text = str(int(goods.count))
			row.count.tooltip_text = tr("(overflow: %d)") % int(goods.overflow) if int(goods.overflow) > 0 else ""
			row.count.add_theme_color_override("font_color", Color(1.0, .78, .38) if int(goods.overflow) > 0 else Color(.93, .89, .82))
			if int(goods.overflow) > 0:
				row.count.text += " +%d" % int(goods.overflow)
			if not row.dirty:
				row.order.select(int(goods.order))
				row.limit.set_value_no_signal(int(goods.limit))
			var can_edit: bool = value.get("can_edit", false)
			row.order.disabled = not can_edit
			row.limit.editable = can_edit
			orders[row.order.selected] = true
			limits[int(row.limit.value)] = true
		# The "all goods" row shows what the goods share, or "Mixed".
		if all_order != null and commit_at.is_empty() and not pending:
			all_order.select(orders.keys()[0] + 1 if orders.size() == 1 else 0)
			all_order.disabled = not value.get("can_edit", false)
			if not all_limit.get_line_edit().has_focus():
				all_limit.set_value_no_signal(limits.keys()[0] if limits.size() == 1 else all_limit.max_value)
			all_limit.editable = value.get("can_edit", false)
	if value.has("agora"):
		for vendor in value.agora.vendors:
			var tile: Dictionary = agora_tiles.get(str(vendor.key), {})
			if tile.is_empty():
				continue
			var present: bool = vendor.present
			var stocked: bool = int(vendor.stock) > 0
			tile.stock.text = "%d / %d" % [int(vendor.stock), int(vendor.capacity)] if present else "—"
			tile.status.text = tr("Distributing") if present and stocked else (tr("No goods") if present else tr("No vendor"))
			var tint := Color(.55, .83, .66) if present and stocked else (Color(.97, .76, .40) if present else Color(.58, .64, .72))
			tile.status.add_theme_color_override("font_color", tint)
			tile.stock.add_theme_color_override("font_color", Color(.93, .89, .82) if present else Color(.58, .64, .72))
			tile.tile.add_theme_stylebox_override("panel", tile_style(Color(tint, .55 if present else .25)))
	if value.has("hall") and hall_stage_label != null:
		var hall: Dictionary = value.hall
		var stages := {"none": "The hero has not been summoned yet.", "summoned": "The hero has been summoned and is on his way.", "arrived": "The hero is in the city and defends it."}
		var stage_text: String = tr(stages.get(hall.stage, stages.none))
		if hall.on_quest:
			stage_text = tr("The hero is away on a quest.")
		hall_stage_label.text = stage_text
		var index := 0
		for requirement in hall.requirements:
			if index >= hall_rows.size():
				break
			var row: Label = hall_rows[index]
			row.text = "%s  ·  %s" % [str(requirement.text), str(requirement.status)]
			row.add_theme_color_override("font_color", Color(.62, .86, .55) if requirement.met else Color(1.0, .78, .38))
			index += 1
		summon_button.text = tr("Summon %s") % str(hall.hero_name)
		summon_button.visible = hall.stage == "none"
		summon_button.disabled = not hall.can_summon or pending
	if value.has("monument"):
		var monument: Dictionary = value.monument
		if construction_bar!=null: construction_bar.value=clampf(float(monument.progress),0,100)
		if construction_advice!=null: construction_advice.text=preload("res://ui/city_guidance.gd").construction_advice(monument)
		if monument_lines != null:
			var lines: Array[String] = []
			for line in monument.lines:
				lines.append(str(line))
			monument_lines.text = "\n".join(lines)
			monument_halt_button.text = tr("Resume the work") if monument.halted else tr("Halt the work")
			monument_halt_button.disabled = not value.get("can_control", false) or pending
		if monument_help_button != null:
			monument_help_bar.value = clampf(float(monument.help_fraction) * 100.0, 5.0, 100.0)
			monument_help_button.disabled = not value.get("can_control", false) or pending
		if monument_attack_button != null and monument.has("attack"):
			monument_attack_bar.value = clampf(float(monument.attack.fraction) * 100.0, 5.0, 100.0)
			monument_attack_button.disabled = not value.get("can_control", false) or pending
	if value.has("production"):
		var statuses := {
			"operational": "Operational", "on_fire": "On fire",
			"industry_paused": "Industry paused", "no_workers": "No workers",
			"no_road": "No road access", "waiting_input": "Waiting for raw materials",
			"no_target": "No resource to collect"}
		var status: String = statuses.get(value.production.status, statuses.operational)
		production_label.text = tr(status)
		if harvest_label != null:
			var percent := clampf(float(value.production.harvest_progress)*100.0,0,100)
			harvest_label.text = tr("Harvest readiness: %d%%") % floori(percent)
			harvest_bar.value = percent
		var lines: Array[String] = []
		if value.production.has("input"):
			var input: Dictionary = value.production.input
			lines.append(tr("Input: %s — %d / %d") % [resource_name(int(input.resource)), int(input.count), int(input.capacity)])
			lines.append(tr("Recipe: %d input → 1 output") % int(input.per_output))
		for output in value.production.outputs:
			lines.append(tr("Output: %s — %d / %d") % [resource_name(int(output.resource)), int(output.count), int(output.capacity)])
			if int(output.overflow) > 0:
				lines.append(tr("Awaiting dispatch: %d") % int(output.overflow))
		stock_label.text = "\n".join(lines)
		for industry in value.production.industries:
			var button: Button = industry_buttons[int(industry.resource)]
			button.text = tr("Resume %s industry") % resource_name(int(industry.resource)) if industry.shut_down else tr("Pause %s industry") % resource_name(int(industry.resource))
			button.disabled = not editable

# The god's answer to a request for help (the words come from the core).
func show_attack_answer(answer: Dictionary) -> void:
	if monument_attack_result != null and answer.has("text"):
		monument_attack_result.text = str(answer.text)
		monument_attack_result.add_theme_color_override("font_color", Color(.62, .86, .55) if answer.granted else Color(1.0, .78, .38))

func show_help_answer(answer: Dictionary) -> void:
	if monument_help_result != null and answer.has("text"):
		monument_help_result.text = str(answer.text)
		monument_help_result.add_theme_color_override("font_color", Color(.62, .86, .55) if answer.granted else Color(1.0, .78, .38))

func command_done(command: String, succeeded: bool) -> void:
	if int(command.get_slice(" ", 3)) != int(value.get("target_token", -1)):
		return
	pending = false
	var sent := inflight
	inflight = {}
	if sent.is_empty():
		update_live_data()
		return
	if succeeded:
		# The draft is settled unless the player changed it again while the command was on its way.
		if sent.kind == "s" and rows.has(sent.key):
			var row: Dictionary = rows[sent.key]
			if row.order.selected == sent.state and int(row.limit.value) == sent.number and not commit_at.has("s|%d" % sent.key):
				row.dirty = false
		elif sent.kind == "t" and trade_rows.has(sent.key):
			var row: Dictionary = trade_rows[sent.key]
			if row.toggle.selected == sent.state and int(row.quota.value) == sent.number and not commit_at.has("t|" + str(sent.key)):
				row.dirty = false
	elif handing_over:
		# The command never left (the queue is full): the draft stays and goes again shortly.
		var retry := ("s|%d" % sent.key) if sent.kind == "s" else ("t|" + str(sent.key))
		commit_at[retry] = Time.get_ticks_msec() + RETRY_MS
	else:
		# Refused: the rest of the queue is dropped and every row goes back to what the building says.
		commit_at.clear()
		for row in rows.values():
			row.dirty = false
		for row in trade_rows.values():
			row.dirty = false
	update_live_data()
