extends RefCounted
const PANEL := preload("res://assets/menu/greek_menu_panel_v3.png")
const SHEET := preload("res://assets/menu/greek_menu_sheet_v3.png")
const SettingsSkin = preload("res://ui/settings_shell.gd")
const BUTTON := preload("res://assets/menu/greek_menu_button_v3.png")
const PAPER := preload("res://assets/menu/aged_parchment_v1.png")
var button_texture: ImageTexture

func install(host: Control, compact: bool) -> void:
	# Copy current scaled values into a menu-owned Theme. Never mutate/save the shared Theme.
	var source: Theme = host.get_node("/root/UiAccess").shared
	var theme: Theme = source.duplicate()
	if button_texture == null:
		var image := BUTTON.get_image()
		# The generated atlas has transparent padding; sample only the button artwork.
		image = image.get_region(Rect2i(0,178,2098,361))
		image.resize(520,roundi(520.0*image.get_height()/image.get_width()),Image.INTERPOLATE_LANCZOS)
		button_texture = ImageTexture.create_from_image(image)
	var factor: float = host.get_node("/root/UiAccess").text_size/100.0
	# Small dialog/key buttons inherit the readable shared controls, not the large
	# ornamental texture: its gold ends crowd text when compressed into a short row.
	theme.set_font_size("font_size","Button",roundi(17*factor))
	for kind in ["Primary","MenuChoice","MainMenuPrimary","MainMenuSecondary","MainMenuContinue","MainMenuEditor"]:
		theme.set_type_variation(kind,"Button")
		for state in ["normal","hover","pressed","disabled"]:
			var style := StyleBoxTexture.new()
			style.texture = button_texture
			style.texture_margin_left = 48
			style.texture_margin_right = 48
			style.texture_margin_top = 10
			style.texture_margin_bottom = 10
			style.content_margin_left = 50
			style.content_margin_right = 50
			style.content_margin_top = 5
			style.content_margin_bottom = 5
			style.modulate_color = Color(1.15,1.12,1.04) if state == "hover" else (Color(.78,.77,.74) if state == "pressed" else (Color(.48,.48,.48) if state == "disabled" else Color.WHITE))
			theme.set_stylebox(state,kind,style)
		# Focus follows the enamel/bronze silhouette, with no rectangular outline.
		var focus: StyleBoxTexture = theme.get_stylebox("normal",kind).duplicate()
		focus.modulate_color = Color(1.35,1.25,1.08,.55)
		theme.set_stylebox("focus",kind,focus)
		theme.set_color("font_color",kind,Color("f6e8bd"))
		theme.set_color("font_hover_color",kind,Color("fff3d4"))
		theme.set_color("font_focus_color",kind,Color("fff3d4"))
		theme.set_color("font_disabled_color",kind,Color("a49d88"))
		theme.set_color("font_shadow_color",kind,Color(0,0,0,.85))
		theme.set_constant("shadow_offset_y",kind,1)
		theme.set_font_size("font_size",kind,roundi((17 if compact else 20)*factor))
		theme.set_font("font",kind,source.get_font("font","Subheading"))
	theme.set_font_size("font_size","MainMenuTitle",roundi((28 if compact else 40)*factor))
	theme.set_font_size("font_size","Caption",roundi(13*factor))
	theme.set_color("font_color","Label",Color("e8dec5"))
	install_paper(theme,factor,compact)
	install_preview(theme)
	install_pages(theme,factor)
	host.theme = theme

func install_pages(theme: Theme, factor: float) -> void:
	# Full pages keep the carved frame; compact forms/confirmations and secondary
	# navigation use restrained matching controls with generous text padding.
	SettingsSkin.install_frame(theme,factor)
	for kind in ["MenuPageChoice","MenuPagePrimary"]:
		theme.set_type_variation(kind,"Button")
		theme.set_font_size("font_size",kind,roundi(17*factor))
		for state in ["normal","hover","pressed","disabled","focus"]:
			var surface := StyleBoxFlat.new()
			surface.bg_color = Color("244456") if kind == "MenuPagePrimary" else Color("142d3b")
			if state == "hover": surface.bg_color = Color("2a4c5d")
			if state == "pressed": surface.bg_color = Color("0b202c")
			if state == "disabled": surface.bg_color = Color("101d24")
			surface.border_color = Color("c3a15e") if kind == "MenuPagePrimary" else Color("796343")
			if state == "hover" or state == "focus": surface.border_color = Color("ddc18a")
			if state == "disabled": surface.border_color = Color("49483e")
			surface.set_border_width_all(1); surface.set_corner_radius_all(3)
			surface.content_margin_left = 18; surface.content_margin_right = 18
			surface.content_margin_top = 9; surface.content_margin_bottom = 9
			if state == "focus": surface.draw_center = false
			theme.set_stylebox(state,kind,surface)
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			theme.set_color(state,kind,Color("eee5cf"))
		theme.set_color("font_disabled_color",kind,Color("a9a596"))

func install_preview(theme: Theme) -> void:
	# Parchment belongs to prose. The library uses a quiet enamel/slate reading surface.
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("0d2028")
	surface.border_color = Color("756044")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(4)
	surface.content_margin_left = 24; surface.content_margin_right = 24
	surface.content_margin_top = 20; surface.content_margin_bottom = 20
	theme.set_stylebox("panel","AdventurePaper",surface)
	var ribbon: StyleBoxFlat = theme.get_stylebox("panel","AdventureRibbon").duplicate()
	ribbon.bg_color = Color("19313e")
	ribbon.border_color = Color("756044")
	theme.set_stylebox("panel","AdventureRibbon",ribbon)
	theme.set_type_variation("AdventurePreviewText","AdventureBodyText")
	theme.set_color("font_color","AdventurePreviewText",Color("e8dec5"))
	theme.set_color("font_color","AdventureGoalText",Color("eee4cc"))
	theme.set_color("font_color","AdventurePaperHeading",Color("e9ca8b"))
	var rule: StyleBoxFlat = theme.get_stylebox("separator","AdventureRule").duplicate()
	rule.bg_color = Color(.46,.38,.27,.55)
	theme.set_stylebox("separator","AdventureRule",rule)

func install_paper(theme: Theme, factor: float, compact: bool) -> void:
	var paper := StyleBoxTexture.new()
	paper.texture = PAPER
	# Scale the sheet as a whole; fixed-size torn edges would consume short pages.
	# Keep dark ink away from the weathered perimeter, including short pages.
	paper.content_margin_left = 36 if compact else 48
	paper.content_margin_right = paper.content_margin_left
	paper.content_margin_top = 28 if compact else 38
	paper.content_margin_bottom = 24 if compact else 36
	for kind in ["EpisodePaper","ParchmentSheet"]:
		theme.set_type_variation(kind,"PanelContainer")
		theme.set_stylebox("panel",kind,paper)
	theme.set_font_size("font_size","EpisodeBody",roundi((14 if compact else 16)*factor))
	theme.set_constant("line_spacing","EpisodeBody",3 if compact else 5)
	theme.set_color("font_color","EpisodeBody",Color("302419"))
	theme.set_font_size("font_size","EpisodePaperHeading",roundi((17 if compact else 20)*factor))
	theme.set_color("font_color","EpisodePaperHeading",Color("47321e"))
	theme.set_font_size("font_size","EpisodeGoalText",roundi((14 if compact else 16)*factor))
	theme.set_font_size("font_size","EpisodeGoalHeading",roundi((17 if compact else 21)*factor))
	var goal: StyleBoxFlat = theme.get_stylebox("panel","EpisodeGoal").duplicate()
	goal.content_margin_left = 10; goal.content_margin_right = 10
	goal.content_margin_top = 6; goal.content_margin_bottom = 6
	theme.set_stylebox("panel","EpisodeGoal",goal)
	theme.set_type_variation("ParchmentPageButton","Button")
	for state in ["normal","hover","pressed","disabled","focus","hover_pressed"]:
		var button := StyleBoxFlat.new()
		button.bg_color = Color("dbc18b") if state == "normal" else (Color("ecd6a5") if state == "hover" else Color("bca06e"))
		button.border_color = Color("806038")
		button.set_border_width_all(1)
		button.set_corner_radius_all(3)
		button.content_margin_left = 10; button.content_margin_right = 10
		button.content_margin_top = 4; button.content_margin_bottom = 4
		if state == "focus": button.draw_center = false; button.border_color = Color("533719"); button.set_border_width_all(2)
		if state == "disabled": button.bg_color = Color(.77,.66,.46,.3); button.border_color = Color(.50,.38,.22,.3)
		theme.set_stylebox(state,"ParchmentPageButton",button)
	for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color","font_hover_pressed_color"]:
		theme.set_color(state,"ParchmentPageButton",Color("392719"))
	theme.set_color("font_disabled_color","ParchmentPageButton",Color(.37,.28,.17,.55))
	theme.set_font_size("font_size","ParchmentPageButton",roundi((14 if compact else 16)*factor))

func clear_panel(control: Control, margins: Vector4) -> void:
	var style := StyleBoxEmpty.new()
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	control.add_theme_stylebox_override("panel",style)
