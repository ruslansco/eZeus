extends Control
# Non-modal help: only this card captures the pointer. Nothing pauses or answers decisions.
# Two tabs: Issues lists native warnings; Guide is a six-step stepper whose ticks come from native observations.
# Steps advance only when the player chooses (Next, Back or a click on a step). While the current step is not yet
# done, a pulsing outline points at the dock button that builds it (still with Reduce interface motion).
const Guidance = preload("res://ui/city_guidance.gd")
const Overlays = preload("res://scripts/overlays.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
# Title, advice, settlement observation, overlay, and where to build: ["tool", id] presses that dock tool,
# ["category", titles...] opens the first of these build categories the city has (all of them are outlined),
# ["goals"] opens the objectives.
const STEPS = [
	["Start with a short road", "Lay a short road from the entry road into open land. Leave space on both sides for houses and services, and keep the first settlement compact.", "roads", "roads", ["tool", "road"]],
	["Welcome your first residents", "Place a few houses along the road, then let time run. Settlers arrive and become the workers your services need. Grow in small steps rather than opening many jobs at once.", "residents", "normal", ["tool", "house"]],
	["Supply water", "Build a fountain (or a well, where available) near the houses and make sure it has workers. Check the water view: each house needs water itself, being nearby is not always enough.", "watered", "water", ["category", "Health and water"]],
	["Deliver food to homes", "Farm or import a food this adventure allows and store it in a granary. Then add a food vendor to an agora beside the houses; the vendor carries food to each home.", "fed", "supplies", ["category", "Agriculture", "Storage", "Markets"]],
	["Keep services working", "Build a maintenance office with workers and road access to prevent fires and collapses. The Issues tab shows buildings that need help.", "maintenance", "hazards", ["category", "Administration and security"]],
	["Grow at a sustainable pace", "Keep food arriving and jobs filled before adding industry. Check your objectives, then expand in small blocks. If a building stops, the Issues tab explains why.", "employed", "industry", ["goals"]]]
# The live count shown under each step (native settlement observations).
const MEASURES := {"roads": "Road tiles: %s", "residents": "Residents: %s", "watered": "Homes with water: %s", "fed": "Homes with food: %s", "maintenance": "Working maintenance offices: %s", "employed": "Workers employed: %s"}
const TOOL_ACTIONS := {"road": ["build_road", "Roads"], "house": ["build_house", "Housing"]}
const FILTERS = [["all","All"],["production","Production"],["workers","Workers"],["roads","Roads"],["housing","Housing"],["construction","Construction"]]
# Each warning's card edge, icon tint and status colour (IssueCard*/IssueStatus* in the Theme), and its icon.
const SEVERITY := {"on_fire": "Danger", "housing_decline": "Danger", "no_workers": "Warning", "no_road": "Warning", "industry_paused": "Warning", "no_target": "Warning", "waiting_input": "Warning", "understaffed": "Info", "waiting_dispatch": "Info", "construction": "Info"}
const STATUS_ICONS := {"on_fire": "alert_fire", "housing_decline": "homes", "no_workers": "people", "understaffed": "people", "no_road": "road", "waiting_input": "industry", "waiting_dispatch": "storage", "industry_paused": "industry", "no_target": "industry", "construction": "build"}
const PAGE_SIZE := 8
var city: Node
var card := PanelContainer.new()
var scroll := ScrollContainer.new()
var body := VBoxContainer.new()
# The folded card's single line: the current step, or the number of warnings.
var summary := Button.new()
var tab_buttons := {}
var fold_button := Button.new()
var tab := "attention"
var filter_id := "all"
var step := 0
# The guide opens on the first step not yet done, once; afterwards it stays where the player leaves it.
var step_chosen := false
var folded := false
var page := 0
var age := 5.0
var report: Dictionary = {}
var signature := ""
var report_ms := 0.0
var rows: Array = []
# The current step's overlay toggle, kept in step with the overlay chosen anywhere else.
var view_button: Button
var view_id := ""
var marked := false
var mark_style := StyleBoxFlat.new()

func _ready() -> void:
	name = "CityHelp"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.theme_type_variation = "GuideCard"
	add_child(card)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",8); card.add_child(column)
	var heading := HBoxContainer.new(); heading.add_theme_constant_override("separation",4); column.add_child(heading)
	var strip := PanelContainer.new(); strip.theme_type_variation = "GuideTabs"; heading.add_child(strip)
	var segments := HBoxContainer.new(); segments.name = "HelpTabs"; segments.add_theme_constant_override("separation",2); strip.add_child(segments)
	for id in ["attention","guide"]:
		var button := Button.new(); button.theme_type_variation = "GuideTab"; button.toggle_mode = true
		button.pressed.connect(func():
			if tab != id: open(id)
			else: button.set_pressed_no_signal(true))
		segments.add_child(button); tab_buttons[id] = button
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE; heading.add_child(spacer)
	fold_button.theme_type_variation = "GuideIconButton"; fold_button.pressed.connect(func(): set_folded(not folded)); heading.add_child(fold_button)
	var close := Button.new(); close.theme_type_variation = "GuideIconButton"; close.icon = load("res://ui/icons/close.svg")
	close.tooltip_text = tr("Close"); close.pressed.connect(hide); heading.add_child(close)
	summary.theme_type_variation = "GuideStep"; summary.alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; summary.clip_text = true
	summary.pressed.connect(func(): set_folded(false)); column.add_child(summary)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true; scroll.get_v_scroll_bar().theme_type_variation = "GuideScrollBar"; column.add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",6); scroll.add_child(body)
	mark_style.draw_center = false; mark_style.set_border_width_all(2); mark_style.set_corner_radius_all(6); mark_style.anti_aliasing = true
	resized.connect(fit)
	get_tree().root.get_node("UiAccess").changed.connect(func(): signature=""; render(); fit())
	fit(); hide()

# Sized to its content, below the header on the left. It stays above the time controls, and above the open minimap
# when the whole card fits there; otherwise it uses the height down to the time controls and scrolls beyond that.
func fit() -> void:
	if not is_node_ready() or city == null: return
	var hud: Control = city.hud
	var origin := get_global_rect().position
	var text_scale: float = get_tree().root.get_node("UiAccess").text_size / 100.0
	var ribbon: Control = hud.get_node("%ResourceRibbon")
	var left: float = clampf(ribbon.get_global_rect().position.x - origin.x, 8, 24)
	var top: float = maxf(90, hud.get_node("%StatusBar").offset_bottom + 12)
	var width: float = clampf(388 * text_scale, minf(300, size.x - left - 12), maxf(200, size.x - left - 12))
	var floor_y: float = size.y - 12
	var clear_y: float = floor_y
	for path in ["%TimeBar", "%MinimapPanel", "%MapToggle", "%MapPeek"]:
		var other: Control = hud.get_node_or_null(path)
		if other == null or not other.is_visible_in_tree(): continue
		var rect := Rect2(other.get_global_rect().position - origin, other.size)
		if rect.position.x < left + width and rect.end.x > left and rect.position.y > top:
			if path == "%TimeBar": floor_y = minf(floor_y, rect.position.y - 12)
			clear_y = minf(clear_y, rect.position.y - 12)
	card.position = Vector2(left, top)
	card.custom_minimum_size.x = width
	if scroll.visible:
		var chrome: float = card.get_combined_minimum_size().y - scroll.custom_minimum_size.y
		var wanted: float = body.get_combined_minimum_size().y
		var bottom: float = clear_y if clear_y - top >= chrome + wanted else floor_y
		scroll.custom_minimum_size = Vector2(0, clampf(wanted, 40, maxf(80, bottom - top - chrome)))
	card.size = Vector2(width, card.get_combined_minimum_size().y)

func open(which := "attention") -> void:
	tab = which; page = 0; signature = ""; folded = false; show(); refresh(); fit()
	for id in tab_buttons: tab_buttons[id].set_pressed_no_signal(id == tab)

func set_folded(value: bool) -> void:
	folded = value; signature = ""; render(); fit()

func _process(dt: float) -> void:
	if not visible: return
	fit()
	age += dt
	# Hold the list while reading/pointing at it. A hidden card never polls; the collapsed tracker still does.
	if age>=5.0 and not card.get_global_rect().has_point(get_viewport().get_mouse_position()): refresh()
	var locale: String = TranslationServer.get_locale()
	if not signature.begins_with(locale+":"): signature=""; render()
	if is_instance_valid(view_button): view_button.set_pressed_no_signal(city.hud.current_overlay == view_id)
	var pointing := not targets().is_empty()
	if pointing or marked: queue_redraw()
	marked = pointing

func refresh() -> void:
	age = 0
	if city.core.simulation == null: return
	var began := Time.get_ticks_usec()
	report = city.core.query("city_attention")
	report_ms = (Time.get_ticks_usec()-began)/1000.0
	render()

func paragraph(text: String, heading := false) -> Label:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = "ToolHeading" if heading else "Caption"
	body.add_child(label); return label

func text_label(text: String, variation: String, parent: Node, wrap := false) -> Label:
	var label := Label.new(); label.text = text; label.theme_type_variation = variation
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label); return label

func icon(name: String) -> Texture2D:
	return load("res://ui/icons/%s.svg" % name)

# Whether a warning belongs to a filter (the chosen one unless another is named, to count the filter pills).
func matches(item: Dictionary, id := "") -> bool:
	var flags: Array = item.flags
	var chosen: String = filter_id if id.is_empty() else id
	match chosen:
		"production": return flags.has("waiting_input") or flags.has("waiting_dispatch") or flags.has("no_target") or flags.has("industry_paused")
		"workers": return flags.has("no_workers") or flags.has("understaffed")
		"roads": return flags.has("no_road")
		"housing": return flags.has("housing_decline")
		"construction": return flags.has("construction")
	return true

func milestone(index: int) -> bool:
	if index==5:
		var values: Dictionary=report.get("settlement",{})
		if int(values.get("fed",0))==0 or int(values.get("watered",0))==0 or int(values.get("maintenance",0))==0:return false
		for item in report.get("items",[]):
			if item.flags.has("no_workers") or item.flags.has("understaffed") or item.flags.has("no_road") or item.flags.has("housing_decline"):return false
	return int(report.get("settlement",{}).get(STEPS[index][2],0))>0

func first_open_step() -> int:
	for index in STEPS.size():
		if not milestone(index): return index
	return STEPS.size()-1

func status_for(item: Dictionary) -> String:
	var preferred: Array=[]
	match filter_id:
		"roads":preferred=["no_road"]
		"workers":preferred=["no_workers","understaffed"]
		"housing":preferred=["housing_decline"]
		"construction":preferred=["construction"]
		"production":preferred=["industry_paused","waiting_input","no_target","waiting_dispatch"]
	for flag in preferred:
		if item.flags.has(flag):return flag
	return str(item.flags[0])

# "Done" or "Not yet" with the step's live count; the last step lists what still holds the settlement back.
func step_status(index: int, done: bool) -> String:
	var values: Dictionary = report.get("settlement", {})
	var key: String = STEPS[index][2]
	var parts: Array[String] = [tr("Done") if done else tr("Not yet")]
	if index < STEPS.size()-1 or done:
		parts.append(tr(MEASURES[key]) % city.hud.group_digits(int(values.get(key, 0))))
		return "  ·  ".join(parts)
	for need in ["fed", "watered", "maintenance"]:
		if int(values.get(need, 0)) == 0: parts.append(tr(MEASURES[need]) % "0")
	var vacant := 0; var roadless := 0; var declining := 0
	for item in report.get("items", []):
		if item.flags.has("no_workers") or item.flags.has("understaffed"): vacant += maxi(0, int(item.get("max_employees", 0)) - int(item.get("employees", 0)))
		if item.flags.has("no_road"): roadless += 1
		if item.flags.has("housing_decline"): declining += 1
	for entry in [[vacant, "Vacant jobs: %s"], [roadless, "Buildings without a road: %s"], [declining, "Declining homes: %s"]]:
		if entry[0] > 0: parts.append(tr(entry[1]) % city.hud.group_digits(entry[0]))
	if parts.size() == 1: parts.append(tr(MEASURES[key]) % city.hud.group_digits(int(values.get(key, 0))))
	return "  ·  ".join(parts)

func marker(done: bool, current: bool) -> Texture2D:
	return icon("guide_done" if done else ("guide_current" if current else "guide_todo"))

# The dock buttons the current step points at: none once the step is done or its tool/category is already open.
func targets() -> Array[Control]:
	var found: Array[Control] = []
	if tab != "guide" or not visible or city == null or milestone(step): return found
	var where: Array = STEPS[step][4]
	match str(where[0]):
		"tool":
			var button: Control = city.hud.tool_buttons.get(where[1])
			if button != null and button.is_visible_in_tree() and city.mode != where[1]: found.append(button)
		"category":
			var tray_open: bool = city.hud.get_node("%BuildTray").visible
			for title in where.slice(1):
				var button: Control = city.hud.category_buttons.get(title)
				if button != null and not button.disabled and button.is_visible_in_tree() and not (tray_open and city.hud.active_category == title): found.append(button)
	return found

func _draw() -> void:
	var marks := targets()
	if marks.is_empty(): return
	var colour: Color = get_theme_color("highlight", "GuideCard")
	var pulse: float = 1.0 if get_tree().root.get_node("UiAccess").reduced_motion else .55 + .45 * sin(Time.get_ticks_msec() / 1000.0 * 3.2)
	var origin := get_global_rect().position
	for target in marks:
		var rect := Rect2(target.get_global_rect().position - origin, target.size)
		draw_rect(rect.grow(2), Color(colour, .10 * pulse))
		mark_style.set_border_width_all(4); mark_style.border_color = Color(colour, .30 * pulse); draw_style_box(mark_style, rect.grow(7))
		mark_style.set_border_width_all(2); mark_style.border_color = Color(colour, .55 + .45 * pulse); draw_style_box(mark_style, rect.grow(3))

# Builds the current step: presses its dock tool, opens its build category or shows the objectives.
func build_action(index: int) -> Button:
	var where: Array = STEPS[index][4]
	var button := Button.new(); button.theme_type_variation = "GuideAction"
	match str(where[0]):
		"tool":
			var tool: Button = city.hud.tool_buttons.get(where[1])
			if tool == null or not tool.visible or tool.disabled: return null
			button.text = tr(TOOL_ACTIONS[where[1]][1]); button.icon = tool.icon
			button.tooltip_text = tr("Choose this building tool")
			button.pressed.connect(func(): city.hud.activate_dock_action(TOOL_ACTIONS[where[1]][0]))
		"category":
			for title in where.slice(1):
				if city.hud.category_buttons.has(title) and not city.hud.category_buttons[title].disabled:
					button.text = tr(title); button.icon = city.hud.category_buttons[title].icon
					button.tooltip_text = tr("Open in the build menu")
					button.pressed.connect(func(): city.hud.open_category(title))
					return button
			button.free()
			return null
		"goals":
			if city.hud.goals_state.get("goals", []).is_empty(): return null
			button.text = tr("Objectives"); button.icon = icon("episode_victory")
			button.pressed.connect(func(): city.hud.set_goals_expanded(true))
	return button

func finish() -> void:
	UserSettings.set_value("interface","settlement_guide_finished",true); hide()

func render() -> void:
	if not is_node_ready(): return
	if tab == "guide" and not step_chosen and report.has("settlement"):
		step = first_open_step(); step_chosen = true
	var key := TranslationServer.get_locale()+":"+JSON.stringify([tab,filter_id,page,step,folded,report])
	if signature == key: return
	signature = key
	tab_buttons.attention.text = tr("Issues"); tab_buttons.attention.tooltip_text = tr("City attention")
	tab_buttons.guide.text = tr("Guide"); tab_buttons.guide.tooltip_text = tr("Settlement guide")
	for id in tab_buttons: tab_buttons[id].set_pressed_no_signal(id == tab)
	fold_button.icon = icon("chevron" if folded else "minimize")
	fold_button.tooltip_text = tr("Expand") if folded else tr("Collapse")
	scroll.visible = not folded; summary.visible = folded
	var old_scroll := scroll.scroll_vertical
	for child in body.get_children(): body.remove_child(child); child.queue_free()
	view_button = null
	if report.has("error"):
		paragraph(tr("City help will be available after relaunching the game.")); summary.text = ""; return
	if tab == "guide": render_guide()
	else: render_attention()
	scroll.set_deferred("scroll_vertical",old_scroll)

func render_guide() -> void:
	var done: Array = range(STEPS.size()).filter(milestone)
	summary.icon = marker(milestone(step), true)
	summary.text = tr(STEPS[step][0]) + "  ·  " + tr("Step %d of %d") % [step+1, STEPS.size()]
	var top := HBoxContainer.new(); body.add_child(top)
	text_label(tr("Settlement guide"), "GuideTitle", top).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var progress := text_label(tr("%d of %d done") % [done.size(), STEPS.size()], "GuideMeta", top)
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bar := HBoxContainer.new(); bar.add_theme_constant_override("separation", 4); body.add_child(bar)
	for index in STEPS.size():
		var segment := PanelContainer.new(); segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.custom_minimum_size.y = 4; segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.theme_type_variation = "GuideSegmentDone" if index in done else ("GuideSegmentCurrent" if index == step else "GuideSegment")
		bar.add_child(segment)
	var list := VBoxContainer.new(); list.add_theme_constant_override("separation", 0); body.add_child(list)
	for index in STEPS.size():
		if index == step:
			list.add_child(step_card(index, index in done)); continue
		var row := Button.new(); row.theme_type_variation = "GuideStepDone" if index in done else "GuideStep"
		row.text = tr(STEPS[index][0]); row.icon = marker(index in done, false)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT; row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.tooltip_text = tr("Done") if index in done else tr("Step %d of %d") % [index+1, STEPS.size()]
		row.pressed.connect(func(): step = index; render())
		list.add_child(row)
	var skip := Button.new(); skip.theme_type_variation = "GuideLink"; skip.text = tr("Don't offer again")
	skip.tooltip_text = tr("Stop opening this guide when a new city begins. It stays available from ? and the Game menu.")
	skip.size_flags_horizontal = Control.SIZE_SHRINK_END; skip.pressed.connect(finish); body.add_child(skip)

# The current step: its advice, live status, a way to build it, its overlay, and Back/Next.
func step_card(index: int, done: bool) -> Control:
	var panel := PanelContainer.new(); panel.theme_type_variation = "GuideStepCard"
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 6); panel.add_child(column)
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 10); column.add_child(head)
	var mark := TextureRect.new(); mark.texture = marker(done, true); mark.custom_minimum_size = Vector2(18, 18)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER; head.add_child(mark)
	text_label(tr(STEPS[index][0]), "GuideStepTitle", head, true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label(tr("Step %d of %d") % [index+1, STEPS.size()], "GuideMeta", head).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_label(tr(STEPS[index][1]), "GuideBody", column, true)
	var chip := PanelContainer.new(); chip.name = "StepStatus"; chip.theme_type_variation = "GuideChipDone" if done else "GuideChipTodo"
	var chip_row := HBoxContainer.new(); chip_row.add_theme_constant_override("separation", 6); chip.add_child(chip_row)
	var chip_mark := TextureRect.new(); chip_mark.texture = marker(done, false); chip_mark.custom_minimum_size = Vector2(14, 14)
	chip_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; chip_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER; chip_row.add_child(chip_mark)
	text_label(step_status(index, done), "GuideChipDoneText" if done else "GuideChipTodoText", chip_row, true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(chip)
	var tools := HFlowContainer.new(); tools.add_theme_constant_override("h_separation", 6); tools.add_theme_constant_override("v_separation", 6)
	var build := build_action(index)
	if build != null: tools.add_child(build)
	view_id = STEPS[index][3]
	if view_id != "normal":
		view_button = Button.new(); view_button.theme_type_variation = "GuideAction"; view_button.toggle_mode = true
		view_button.text = tr(Overlays.MODES[view_id][0]); view_button.icon = icon("layers")
		view_button.tooltip_text = tr("Show or hide this view of the city")
		view_button.button_pressed = city.hud.current_overlay == view_id
		view_button.pressed.connect(func(): city.set_overlay(view_id, true))
		tools.add_child(view_button)
	if tools.get_child_count() > 0: column.add_child(tools)
	var nav := HBoxContainer.new(); nav.add_theme_constant_override("separation", 6); column.add_child(nav)
	if index > 0:
		var back := Button.new(); back.theme_type_variation = "GuideLink"; back.text = tr("Back")
		back.pressed.connect(func(): step -= 1; render()); nav.add_child(back)
	var gap := Control.new(); gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL; gap.mouse_filter = Control.MOUSE_FILTER_IGNORE; nav.add_child(gap)
	var last := index == STEPS.size()-1
	var next := Button.new(); next.name = "NextStep"; next.theme_type_variation = "GuidePrimary"
	next.text = tr("Finish guide") if last else tr("Next step")
	if not last:
		next.icon = icon("next"); next.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next.pressed.connect(func():
		if last: finish()
		else: step += 1; scroll.scroll_vertical = 0; render())
	nav.add_child(next)
	return panel

# Filter pills with counts, then a card per warning on this page: severity edge and icon, building, status, advice
# and tags for its other conditions. The whole card opens the building. A pager and a calm empty state.
func render_attention() -> void:
	var items: Array = report.get("items", [])
	summary.icon = icon("risk")
	summary.text = tr("City attention") + "  ·  " + tr("Buildings needing attention: %s") % city.hud.group_digits(items.size())
	var top := HBoxContainer.new(); body.add_child(top)
	text_label(tr("City attention"), "GuideTitle", top).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var again := Button.new(); again.theme_type_variation = "GuideIconButton"; again.icon = icon("refresh")
	again.tooltip_text = tr("Refresh"); again.pressed.connect(refresh); top.add_child(again)
	text_label(tr("Click a warning to visit the building and see how to help it."), "GuideMeta", body, true)
	var pills := HFlowContainer.new(); pills.add_theme_constant_override("h_separation", 6); pills.add_theme_constant_override("v_separation", 6); body.add_child(pills)
	for spec in FILTERS:
		var count: int = items.filter(func(item): return matches(item, spec[0])).size()
		var pill := Button.new(); pill.theme_type_variation = "IssueFilter"; pill.toggle_mode = true
		pill.text = "%s  %s" % [tr(spec[1]), city.hud.group_digits(count)]
		pill.button_pressed = spec[0] == filter_id
		pill.disabled = count == 0 and spec[0] != filter_id
		pill.pressed.connect(func(): filter_id = spec[0]; page = 0; signature = ""; scroll.scroll_vertical = 0; render())
		pills.add_child(pill)
	rows = items.filter(matches)
	rows.sort_custom(func(a,b):
		var ar: int = 0 if a.flags.has("on_fire") else (1 if a.flags.has("housing_decline") else 2)
		var br: int = 0 if b.flags.has("on_fire") else (1 if b.flags.has("housing_decline") else 2)
		return ar<br if ar!=br else (a.y<b.y if a.y!=b.y else a.x<b.x))
	page = mini(page,maxi(0,(rows.size()-1)/PAGE_SIZE))
	if rows.is_empty():
		var calm := VBoxContainer.new(); calm.alignment = BoxContainer.ALIGNMENT_CENTER; calm.custom_minimum_size.y = 96; body.add_child(calm)
		var mark := TextureRect.new(); mark.texture = icon("guide_done"); mark.custom_minimum_size = Vector2(28, 28)
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; calm.add_child(mark)
		text_label(tr("Nothing needs attention right now.") if filter_id == "all" else tr("No issues in this category."), "GuideBody", calm, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var shown: Array = rows.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)
	for item in shown: body.add_child(issue_card(item))
	if rows.size() > PAGE_SIZE:
		var pager := HBoxContainer.new(); pager.alignment = BoxContainer.ALIGNMENT_CENTER; pager.add_theme_constant_override("separation", 8); body.add_child(pager)
		var last: int = mini(rows.size(), (page+1)*PAGE_SIZE)
		for entry in [["previous", "Previous page", -1, page == 0], ["", "", 0, false], ["next", "Next page", 1, last >= rows.size()]]:
			if entry[2] == 0:
				text_label(tr("%d–%d of %d") % [page*PAGE_SIZE+1, last, rows.size()], "GuideMeta", pager).size_flags_vertical = Control.SIZE_SHRINK_CENTER
				continue
			var turn := Button.new(); turn.theme_type_variation = "GuideIconButton"; turn.icon = icon(entry[0])
			turn.tooltip_text = tr(entry[1]); turn.disabled = entry[3]
			turn.pressed.connect(func(): page += entry[2]; signature = ""; scroll.scroll_vertical = 0; render())
			pager.add_child(turn)
	if shown.any(func(item): return item.flags.has("housing_decline")):
		text_label(tr("Housing warnings show needs required to keep a home's current level. Optional upgrades are explained in the house inspector."), "GuideMeta", body, true)

func issue_card(item: Dictionary) -> Control:
	var status: String = status_for(item)
	var tone: String = SEVERITY.get(status, "Info")
	var card := PanelContainer.new(); card.theme_type_variation = "IssueCard" + tone
	var pad := MarginContainer.new(); pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [["left", 14], ["right", 10], ["top", 8], ["bottom", 9]]: pad.add_theme_constant_override("margin_" + side[0], side[1])
	card.add_child(pad)
	var row := HBoxContainer.new(); row.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_theme_constant_override("separation", 10); pad.add_child(row)
	var mark := TextureRect.new(); mark.texture = icon(STATUS_ICONS.get(status, "risk")); mark.custom_minimum_size = Vector2(20, 20)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.self_modulate = get_theme_color("font_color", "IssueStatus" + tone); row.add_child(mark)
	var column := VBoxContainer.new(); column.mouse_filter = Control.MOUSE_FILTER_IGNORE; column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3); row.add_child(column)
	text_label(str(item.name), "IssueName", column, true)
	text_label(tr(Guidance.TITLES.get(status, "Building status")), "IssueStatus" + tone, column, true)
	text_label(Guidance.advice(item, status), "IssueAdvice", column, true)
	if item.flags.size() > 1:
		var tags := HFlowContainer.new(); tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tags.add_theme_constant_override("h_separation", 4); tags.add_theme_constant_override("v_separation", 4); column.add_child(tags)
		for flag in item.flags:
			if str(flag) == status: continue
			var tag := PanelContainer.new(); tag.theme_type_variation = "IssueTag"; tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_label(tr(Guidance.TITLES.get(flag, "Building status")), "IssueTagText", tag); tags.add_child(tag)
	var go := TextureRect.new(); go.texture = icon("next"); go.custom_minimum_size = Vector2(14, 14); go.modulate = Color(1, 1, 1, .55)
	go.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; go.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER; go.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(go)
	# Last, so it lies over the whole card: one click target, with the card's hover and focus outline.
	var hit := Button.new(); hit.theme_type_variation = "IssueCardButton"; hit.tooltip_text = tr("Go to")
	hit.set_meta("attention_item", item); hit.pressed.connect(func(): city.focus_attention(item)); card.add_child(hit)
	return card
