extends VBoxContainer

signal action_requested(command: String)

const Goods = preload("res://scripts/goods.gd")

var value: Dictionary = {}
var schema := ""
var rows: Dictionary = {}
var industry_buttons: Dictionary = {}
var bay_label: Label
var production_label: Label
var stock_label: Label
var native_notes: Label
var trade_status: Label
var trade_rows: Dictionary = {}
var hall_stage_label: Label
var monument_lines: Label
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
var pending := false

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
	var key := "%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [data.get("target_token", 0), TranslationServer.get_locale(), data.get("storage", {}).get("resources", []).size(), data.has("production"), trade_shape, data.get("hall", {}).get("requirements", []).size(), data.get("monument", {}).get("finished", "-"), data.get("monument", {}).get("attack", {}).get("targets", []).size(), data.has("notes"), data.has("switch"), data.has("route")]
	if key != schema:
		schema = key
		pending = false
		rows.clear()
		trade_rows.clear()
		industry_buttons.clear()
		hall_rows.clear()
		hall_stage_label = null
		summon_button = null
		notes_label = null
		switch_button = null
		route_button = null
		monument_lines = null
		monument_halt_button = null
		monument_help_button = null
		monument_help_bar = null
		monument_help_result = null
		monument_attack_button = null
		monument_attack_popup = null
		monument_attack_bar = null
		monument_attack_result = null
		native_notes = null
		for child in get_children():
			remove_child(child)
			child.queue_free()
		add_theme_constant_override("separation", 10)
		# A trade post is a store whose orders are its trade with one partner: show those instead of the raw store orders.
		if data.has("trade"):
			build_trade(data.trade)
		elif data.has("storage"):
			build_storage(data.storage)
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
			native_notes.visible = false
			more.pressed.connect(func(): native_notes.visible = not native_notes.visible)
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

func build_storage(storage: Dictionary) -> void:
	label(tr("Stored goods"), true)
	bay_label = label("")
	var note := label(tr("Limits use cargo loads. Each bay holds 4 loads, or 1 sculpture. Lower limits keep existing stock."))
	note.theme_type_variation="Caption"
	for goods in storage.resources:
		var resource := int(goods.resource)
		var count := label("")
		var row := HBoxContainer.new()
		add_child(row)
		var order := OptionButton.new()
		order.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		order.focus_mode = Control.FOCUS_NONE
		for names in ["Reject", "Accept", "Get", "Empty"]:
			order.add_item(tr(names))
		order.tooltip_text = tr("Get collects from other stores; Empty sends stock away through native carts.")
		row.add_child(order)
		var limit := SpinBox.new()
		limit.min_value = 0
		limit.max_value = int(goods.max_limit)
		limit.step = int(goods.step)
		limit.custom_minimum_size.x = 90
		limit.tooltip_text = tr("Stock limit")
		row.add_child(limit)
		var apply := Button.new()
		apply.text = tr("Apply")
		apply.focus_mode = Control.FOCUS_NONE
		row.add_child(apply)
		rows[resource] = {"count": count, "order": order, "limit": limit, "apply": apply, "dirty": false}
		order.item_selected.connect(func(_index): mark_dirty(resource))
		limit.value_changed.connect(func(_number): mark_dirty(resource))
		apply.pressed.connect(func(): submit_storage(resource))

# ---- trade posts --------------------------------------------------------------------------------------------
func build_trade(trade: Dictionary) -> void:
	label(tr("Trade with %s") % trade.partner, true)
	trade_status = label("")
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
			var apply := Button.new()
			apply.text = tr("Apply")
			apply.focus_mode = Control.FOCUS_NONE
			row.add_child(apply)
			trade_rows[key] = {"caption": caption, "toggle": toggle, "quota": quota, "apply": apply, "dirty": false, "direction": int(section[1]), "resource": int(item.resource)}
			toggle.item_selected.connect(func(_index): mark_trade_dirty(key))
			quota.value_changed.connect(func(_number): mark_trade_dirty(key))
			apply.pressed.connect(func(): submit_trade(key))

func mark_trade_dirty(key: String) -> void:
	trade_rows[key].dirty = true
	trade_rows[key].apply.disabled = pending or not value.get("can_edit", false)

func submit_trade(key: String) -> void:
	if pending or not value.get("can_edit", false):
		return
	var row: Dictionary = trade_rows[key]
	pending = true
	action_requested.emit("trade %d %d %d %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), row.resource, row.direction, row.toggle.selected, int(row.quota.value)])
	update_live_data()

func mark_dirty(resource: int) -> void:
	rows[resource].dirty = true
	rows[resource].apply.disabled = pending or not value.get("can_edit", false)

func submit_storage(resource: int) -> void:
	if pending or not value.get("can_edit", false):
		return
	var row: Dictionary = rows[resource]
	# The native command includes the selected object's token, not just a tile.
	pending = true
	action_requested.emit("storage %d %d %d %d %d %d" % [int(value.x), int(value.y), int(value.target_token), resource, row.order.selected, int(row.limit.value)])
	update_live_data()

func build_production(production: Dictionary) -> void:
	label(tr("Production"), true)
	production_label = label("")
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
				row.toggle.disabled = not editable
				row.quota.editable = editable
				row.apply.disabled = not editable or not row.dirty
	if value.has("storage") and not value.has("trade"):
		bay_label.text = tr("Bays in use: %d / %d") % [int(value.storage.occupied_bays), int(value.storage.bays)]
		for goods in value.storage.resources:
			var row: Dictionary = rows[int(goods.resource)]
			row.count.text = "%s  ·  %d" % [resource_name(int(goods.resource)), int(goods.count)]
			if int(goods.overflow) > 0:
				row.count.text += tr(" (overflow: %d)") % int(goods.overflow)
			if not row.dirty:
				row.order.select(int(goods.order))
				row.limit.set_value_no_signal(int(goods.limit))
			row.order.disabled = not editable
			row.limit.editable = editable
			row.apply.disabled = not editable or not row.dirty
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
	if succeeded:
		for row in rows.values():
			row.dirty = false
		for row in trade_rows.values():
			row.dirty = false
