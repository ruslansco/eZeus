extends Node
# Menu-only presentation and navigation. Existing native callbacks remain in start_menu.gd.
const MenuSkin = preload("res://ui/menu_skin.gd")
const Pager = preload("res://ui/menu_list_pager.gd")
const SettingsShell = preload("res://ui/settings_shell.gd")
var host: Control
var skin := MenuSkin.new()
var frames: Dictionary = {}
var adventure_pager := Pager.new()
var save_pager := Pager.new()
var profile_pager := Pager.new()
var settings_page: PanelContainer
var extras_page: PanelContainer
var settings_buttons: Dictionary = {}
var parents := {"adventures":"main","leaders":"main"}
var extras_button: Button
var settings_back: Button
var extras_back: Button
var fitting := false
var last_fit := ""
var compact := false
var story_pages: Array[String] = []
var story_page := 0
var story_original := ""
var story_count: Label
var story_previous: Button
var story_next: Button
var story_slot: Control
var intro_paginating := false
var settings_windows: Array[Window] = []
var settings_focus: Control
var settings_shade: ColorRect

func setup(menu: Control) -> void:
	host = menu
	host.add_child(self)
	host.get_node("MainAnchor").z_index = 2
	host.get_node("Center").z_index = 2
	var column: VBoxContainer = host.get_node("%MainColumn")
	# Promote Settings/Quit into clear top-level choices. Sound/editor move to their hubs.
	host.get_node("%Interface").reparent(column)
	host.quit_button.reparent(column)
	extras_button = Button.new(); extras_button.name = "Extras"; extras_button.text = tr("Extras")
	column.add_child(extras_button)
	column.move_child(host.get_node("%Interface"),host.load_game_button.get_index()+1)
	column.move_child(extras_button,host.get_node("%Interface").get_index()+1)
	column.move_child(host.quit_button,extras_button.get_index()+1)
	column.move_child(host.get_node("MainAnchor/MainPage/MainScroll/MainColumn/MainFooter"),column.get_child_count()-1)
	extras_button.pressed.connect(func(): host.show_page("extras"))
	_hide_named(column,"MainFooterRule")
	_hide_named(column,"MainRule")
	host.get_node("%ContinueHeading").hide()
	host.continue_info.hide()
	host.get_node("%MainEmblem").hide()
	host.title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host.get_node("MainAnchor/MainPage/MainScroll/MainColumn/MainFooter").alignment = BoxContainer.ALIGNMENT_CENTER
	settings_page = simple_page("SettingsPage","Settings")
	extras_page = simple_page("ExtrasPage","Extras")
	host.pages.settings = settings_page
	host.pages.extras = extras_page
	var grid := GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation",16); grid.add_theme_constant_override("v_separation",14)
	settings_page.get_child(0).add_child(grid)
	for spec in [["display","Display","res://ui/display_dialog.gd"],["graphics","Graphics","res://ui/graphics_dialog.gd"],["sound","Sound","res://ui/sound_dialog.gd"],["interface","Interface","res://ui/interface_dialog.gd"],["controls","Controls","res://ui/controls_dialog.gd"],["game","Game","res://ui/game_settings_dialog.gd"]]:
		var button: Button
		if spec[0] == "sound":
			button = host.sound_button
			button.reparent(grid)
		else:
			button = Button.new(); grid.add_child(button)
			button.pressed.connect(func(): load(spec[2]).open(host))
		button.theme_type_variation = "MenuChoice"; button.icon = null; button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.set_meta("caption",spec[1]); button.text = tr(spec[1]); button.name = "Settings_"+spec[0]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(230,60)
		settings_buttons[spec[0]] = button
	settings_back = back_button(settings_page)
	var extra_column: VBoxContainer = extras_page.get_child(0)
	host.editor_button.reparent(extra_column)
	host.editor_button.custom_minimum_size = Vector2(320,54)
	host.editor_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var profiles := Button.new(); profiles.text = tr("Profiles"); profiles.set_meta("caption","Profiles"); profiles.custom_minimum_size = Vector2(320,54); profiles.pressed.connect(host.open_leaders); extra_column.add_child(profiles)
	extras_back = back_button(extras_page)
	adventure_pager.setup(host.adventure_list,"Search adventures")
	adventure_pager.selected.connect(host.show_adventure)
	adventure_pager.filtered.connect(func(found): host.adventure_start.disabled = not found; host.get_node("%AdventureDetail").visible = found)
	save_pager.setup(host.save_list,"Search saved games",true)
	save_pager.selected.connect(func(index): host.save_info.text = host.save_entries[index].detail)
	save_pager.filtered.connect(func(found): host.load_open.disabled = not found)
	profile_pager.setup(host.leader_list,"Search profiles")
	profile_pager.filtered.connect(func(found): host.leader_proceed.disabled = not found; host.leader_delete.disabled = not found or not host.Leaders.can_delete(host.selected_leader()))
	profile_pager.selected.connect(func(_index): host.leader_proceed.disabled = false; host.leader_delete.disabled = not host.Leaders.can_delete(host.selected_leader()))
	host.adventure_goals = goal_grid(host.adventure_goals)
	for label in [host.adventure_text,host.adventure_episode,host.adventure_empty_goals]:
		label.theme_type_variation = "AdventurePreviewText"
	host.adventure_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.adventure_text.max_lines_visible = 3
	host.adventure_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	host.save_info.max_lines_visible = 3
	host.adventure_back.custom_minimum_size = Vector2(180,46)
	host.adventure_start.custom_minimum_size = Vector2(220,46)
	# Only story prose is paged. Every objective remains visible together.
	build_intro_pages()
	for key in host.pages:
		var texture := TextureRect.new()
		texture.texture = MenuSkin.PANEL if key == "main" else MenuSkin.SHEET
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.name = "Art_"+key
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture.z_index = 1
		add_child(texture)
		frames[key] = texture
	for button in [host.adventure_start,host.load_open,host.leader_proceed,host.intro_begin]:
		button.theme_type_variation = "MenuPagePrimary"
	for button in [host.adventure_back,host.load_back,host.leader_back,host.intro_back,settings_back,extras_back]:
		button.theme_type_variation = "MenuPageChoice"
	host.get_node("/root/UiAccess").changed.connect(fit)
	get_viewport().size_changed.connect(fit)
	settings_shade = ColorRect.new()
	settings_shade.name = "SettingsShade"
	settings_shade.color = Color(0.015,0.025,0.035,.36)
	settings_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_shade.z_index = 3
	settings_shade.hide()
	host.add_child(settings_shade)
	host.child_entered_tree.connect(settings_added)
	fit.call_deferred()

func settings_added(child: Node) -> void:
	if not SettingsShell.accepts(child): return
	if settings_windows.is_empty(): settings_focus = get_viewport().gui_get_focus_owner()
	settings_windows.append(child)
	settings_page.hide()
	frames.settings.hide()
	settings_shade.show()
	SettingsShell.new().setup(child, host)
	child.tree_exited.connect(func():
		settings_windows.erase(child)
		if settings_windows.is_empty() and host.page == "settings":
			settings_shade.hide()
			settings_page.show()
			if is_instance_valid(settings_focus): settings_focus.grab_focus())

func _hide_named(parent: Node, name: String) -> void:
	var child := parent.get_node_or_null(name)
	if child != null: child.hide()

func goal_grid(original: Container) -> GridContainer:
	var parent := original.get_parent()
	var index := original.get_index()
	var original_name := original.name
	var original_owner := original.owner
	original.unique_name_in_owner = false
	original.name = str(original_name)+"Retired"
	var grid := GridContainer.new()
	grid.name = original_name
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",8)
	parent.add_child(grid); parent.move_child(grid,index)
	grid.owner = original_owner; grid.unique_name_in_owner = true
	for child in original.get_children(): child.reparent(grid)
	original.free()
	return grid

func simple_page(name: String, caption: String) -> PanelContainer:
	var page := PanelContainer.new(); page.name = name; page.visible = false
	host.get_node("Center").add_child(page)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",20); column.alignment = BoxContainer.ALIGNMENT_CENTER; page.add_child(column)
	var title := Label.new(); title.text = tr(caption); title.set_meta("caption",caption); title.theme_type_variation = "Heading"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(title)
	return page

func back_button(page: PanelContainer) -> Button:
	var button := Button.new(); button.text = tr("Back"); button.set_meta("caption","Back"); button.custom_minimum_size = Vector2(180,48); button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; button.pressed.connect(func(): host.show_page("main")); page.get_child(0).add_child(button)
	return button

func retranslate() -> void:
	extras_button.text = tr("Extras")
	host.leader_change.text = tr("Profiles")
	host.language_button.text = "Русский" if host.language == "ru" else "English"
	for page in [settings_page,extras_page]:
		for child in page.get_child(0).get_children():
			if child is Label or child is Button:
				if child.has_meta("caption"): child.text = tr(str(child.get_meta("caption")))
	for button in settings_buttons.values(): button.text = tr(str(button.get_meta("caption")))
	for pager in [adventure_pager,save_pager,profile_pager]:
		pager.search.placeholder_text = tr(str(pager.search.get_meta("prompt")))
		pager.previous.tooltip_text = tr("Previous page"); pager.next.tooltip_text = tr("Next page"); pager.rebuild()
	fit.call_deferred()

func fit() -> void:
	if fitting: return
	fitting = true
	var viewport := host.get_viewport_rect().size
	var stamp: String = str(viewport)+host.language+str(host.get_node("/root/UiAccess").ui_size)+str(host.get_node("/root/UiAccess").text_size)+str(host.get_node("%ContinueCard").visible)+host.page
	if stamp == last_fit:
		fitting = false
		return
	last_fit = stamp
	compact = viewport.y < 790
	skin.install(host,compact)
	for frame in frames.values(): frame.theme = host.theme
	var anchor: MarginContainer = host.get_node("%MainAnchor")
	var margin := 28.0 if compact else 40.0
	var width := minf(490,viewport.x*.41)
	anchor.add_theme_constant_override("margin_left",roundi(margin))
	anchor.add_theme_constant_override("margin_top",16 if compact else 28)
	anchor.add_theme_constant_override("margin_bottom",16 if compact else 28)
	anchor.offset_right = margin+width
	var height := viewport.y-(32 if compact else 56)
	var main: PanelContainer = host.get_node("%MainPage")
	main.custom_minimum_size = Vector2(width,height)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skin.clear_panel(main,Vector4(width*.12,height*.135,width*.12,height*.085))
	host.get_node("%MainColumn").add_theme_constant_override("separation",4 if compact else 12)
	host.get_node("%MainColumn").alignment = BoxContainer.ALIGNMENT_CENTER
	host.tagline.visible = not compact
	host.get_node("%NewGameHint").visible = not compact
	skin.clear_panel(host.get_node("%ContinueCard"),Vector4.ZERO)
	skin.clear_panel(host.get_node("%LeaderSlot"),Vector4(0,2,0,2))
	host.get_node("%ContinueSaveName").theme_type_variation = "Caption"
	host.get_node("%ContinueCard").get_child(0).add_theme_constant_override("separation",2)
	for button in [host.continue_button,host.new_game_button,host.load_game_button,host.get_node("%Interface"),extras_button,host.quit_button]:
		button.theme_type_variation = "MenuChoice"
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon = null
		button.custom_minimum_size = Vector2(0,38 if compact else 58)
		host.theme.set_font_size("font_size","MenuChoice",roundi((17 if compact else 21)*host.get_node("/root/UiAccess").text_size/100.0))
	host.leader_change.custom_minimum_size.y = 26
	host.language_button.custom_minimum_size.y = 24 if compact else 32
	var desired := Vector2(minf(1260,viewport.x-48),minf(850,viewport.y-40))
	var adventure: PanelContainer = host.get_node("%AdventurePage")
	adventure.custom_minimum_size = desired
	skin.clear_panel(adventure,Vector4(desired.x*.08,desired.y*.16,desired.x*.08,desired.y*.10))
	host.adventure_list.custom_minimum_size.x = clampf(desired.x*.27,220,320)
	host.get_node("%AdventureHint").custom_minimum_size.x = host.adventure_list.custom_minimum_size.x
	host.get_node("%AdventureHint").visible = not compact
	host.get_node("%AdventureHero").custom_minimum_size.y = 56 if compact else 80
	host.get_node("%AdventureHero").visible = not compact
	host.adventure_episodes.visible = not compact
	host.campaign_progress.visible = not compact
	host.adventure_goals.get_parent().add_theme_constant_override("separation",4 if compact else 6)
	host.adventure_text.visible = not compact
	host.adventure_text.get_parent().get_node("Rule").visible = not compact
	host.get_node("%AdventurePage/AdventureColumn").add_theme_constant_override("separation",8 if compact else 12)
	host.adventure_list.get_parent().add_theme_constant_override("separation",8)
	for key in ["load","leaders","settings","extras"]:
		var page: PanelContainer = host.pages[key]
		var size := Vector2(minf(860,viewport.x-64),minf(740,viewport.y-48))
		page.custom_minimum_size = size
		skin.clear_panel(page,Vector4(size.x*.11,size.y*.14,size.x*.09,size.y*.08))
	var intro_size := Vector2(minf(1260,viewport.x-48),minf(850,viewport.y-40))
	host.get_node("%IntroPage").custom_minimum_size = intro_size
	skin.clear_panel(host.get_node("%IntroPage"),Vector4(intro_size.x*.08,intro_size.y*.16,intro_size.x*.08,intro_size.y*.10))
	skin.clear_panel(host.intro_card.get_node("Banner"),Vector4.ZERO)
	host.intro_card.get_node("%Medal").hide()
	fit_intro(viewport)
	for pager in [adventure_pager,save_pager,profile_pager]: pager.fit.call_deferred()
	goals_changed()
	if host.page == "intro": paginate_intro.call_deferred()
	fitting = false

func on_page(name: String) -> void:
	fit.call_deferred()
	if name == "settings": settings_buttons.display.grab_focus()
	if name == "extras": host.editor_button.grab_focus()

func _process(_delta: float) -> void:
	for key in frames:
		var page: Control = host.pages[key]
		frames[key].visible = page.is_visible_in_tree()
		if frames[key].visible:
			frames[key].global_position = page.get_global_rect().position
			frames[key].size = page.get_global_rect().size

func goals_changed() -> void:
	host.adventure_goals.columns = 2 if host.adventure_goals.get_child_count() > (2 if compact else 3) else 1
	for child in host.adventure_goals.get_children():
		child.visible = true
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func build_intro_pages() -> void:
	var card = host.intro_card
	card.menu_layout = true
	# A plain bounded Control does not propagate a long Label's minimum height
	# into the frame. The full story is measured into pages after layout settles.
	story_slot = Control.new(); story_slot.clip_contents = true
	story_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.scroll.add_child(story_slot)
	card.body.reparent(story_slot)
	card.body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.goals = goal_grid(card.goals)
	host.intro_goals = card.goals
	card.phase.hide()
	card.heading.reparent(card.episode_progress.get_parent())
	card.heading.get_parent().move_child(card.heading,0)
	card.scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.goal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var story_bar := HBoxContainer.new(); card.scroll.get_parent().add_child(story_bar)
	story_previous = Button.new(); story_previous.text = "‹"; story_bar.add_child(story_previous)
	story_count = Label.new(); story_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; story_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL; story_count.theme_type_variation = "AdventureBodyText"; story_bar.add_child(story_count)
	story_next = Button.new(); story_next.text = "›"; story_bar.add_child(story_next)
	story_previous.pressed.connect(func(): story_page = maxi(0,story_page-1); show_intro_story())
	story_next.pressed.connect(func(): story_page = mini(story_pages.size()-1,story_page+1); show_intro_story())
	for button in [story_previous,story_next]:
		button.theme_type_variation = "ParchmentPageButton"
		button.custom_minimum_size = Vector2(40,30)
	for button in [card.difficulty_down,card.difficulty_up]: button.theme_type_variation = "MainMenuUtility"
	story_previous.tooltip_text = tr("Previous page")
	story_next.tooltip_text = tr("Next page")

func fit_intro(viewport: Vector2) -> void:
	var card = host.intro_card
	var many: bool = card.goals.get_child_count() > 4
	var short: bool = viewport.y < 700 and not many
	var tight := short or many
	card.get_node("%Content").vertical = short
	var content = card.get_node("%Content")
	content.move_child(card.get_node("%GoalsPanel"),0 if short else 1)
	var goals_width := minf(1260,viewport.x-48)*.84*.65 if many else 350.0
	card.get_node("%GoalsPanel").custom_minimum_size.x = 0 if short else goals_width
	card.get_node("%GoalsPanel").size_flags_horizontal = Control.SIZE_FILL if many else Control.SIZE_EXPAND_FILL
	card.get_node("%GoalsPanel").size_flags_vertical = Control.SIZE_SHRINK_BEGIN if short else Control.SIZE_EXPAND_FILL
	card.goals.columns = 2 if many else (mini(3,maxi(1,card.goals.get_child_count())) if short else 1)
	card.scroll.custom_minimum_size.y = 80
	card.goal_scroll.custom_minimum_size.y = 0
	card.add_theme_constant_override("separation",6 if tight else 12)
	card.scroll.get_parent().add_theme_constant_override("separation",4 if tight else 10)
	card.get_node("%Content").add_theme_constant_override("separation",8 if tight else 18)
	for row in card.goals.get_children(): row.visible = true; row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func prepare_intro() -> void:
	story_original = host.intro_card.body.text
	story_page = 0
	host.intro_card.body.text = story_original.left(140)
	fit_intro(host.get_viewport_rect().size)
	paginate_intro.call_deferred()

func paginate_intro() -> void:
	if intro_paginating: return
	intro_paginating = true
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	story_pages.clear()
	var label: Label = host.intro_card.body
	var font := label.get_theme_font("font")
	var offset := 0
	while offset < story_original.length():
		var low := 1
		var high := story_original.length()-offset
		while low < high:
			var mid := (low+high+1)/2
			var height := font.get_multiline_string_size(story_original.substr(offset,mid),HORIZONTAL_ALIGNMENT_LEFT,maxf(100,story_slot.size.x-4),label.get_theme_font_size("font_size")).y
			var lines := maxi(1,ceili(height/font.get_height(label.get_theme_font_size("font_size"))))
			height += (lines-1)*label.get_theme_constant("line_spacing")
			if height <= maxf(28,story_slot.size.y)-12: low = mid
			else: high = mid-1
		var length := low
		if offset+length < story_original.length():
			var cut := story_original.substr(offset,length).rfind(" ")
			if cut > 0: length = cut+1
		story_pages.append(story_original.substr(offset,length)); offset += length
	if story_pages.is_empty(): story_pages.append("")
	story_page = clampi(story_page,0,story_pages.size()-1)
	intro_paginating = false
	show_intro_story()

func show_intro_story() -> void:
	if story_pages.is_empty(): return
	host.intro_card.body.text = story_pages[story_page]
	story_count.text = tr("Page %d of %d") % [story_page+1,story_pages.size()]
	story_previous.disabled = story_page == 0; story_next.disabled = story_page >= story_pages.size()-1
