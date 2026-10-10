extends RefCounted
# Generator-owned, unscaled panel styles. No input, polling, runtime Theme saves
# or simulation logic. Large panels use wood; compact HUD styles stay intact.
const FRAME := "res://assets/ui/greek_panel_v1.png"
const ACTION := "res://ui/settings_art/menu_action.svg"
const TYPES := ["EscapeCard","CharacterCard","EpisodeShell","EpisodePaper","CityLedger","Window","AcceptDialog",
	"ConfirmationDialog","EscapeAction","EscapePrimary","CityPanelPrimary","GameMenuAction","GameMenuPrimary","GameMenuTitle","GameMenuChoice"]

static func wood(margin_x: int, margin_y: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(FRAME)
	# A compact import keeps the decorative corners outside the reading insets.
	style.texture_margin_left = 48; style.texture_margin_right = 48
	style.texture_margin_top = 48; style.texture_margin_bottom = 48
	style.content_margin_left = margin_x; style.content_margin_right = margin_x
	style.content_margin_top = margin_y; style.content_margin_bottom = margin_y
	return style

static func install(theme: Theme) -> void:
	for kind in ["EscapeCard","CharacterCard","EpisodeShell"]:
		theme.set_stylebox("panel",kind,wood(44,44))
	var paper := StyleBoxTexture.new()
	paper.texture = load("res://assets/menu/aged_parchment_v1.png")
	paper.content_margin_left = 32; paper.content_margin_right = 32
	paper.content_margin_top = 26; paper.content_margin_bottom = 24
	theme.set_stylebox("panel","EpisodePaper",paper)
	for kind in ["Window","AcceptDialog","ConfirmationDialog"]:
		var style := wood(24,20)
		style.expand_margin_top = 72
		style.expand_margin_left = 6; style.expand_margin_right = 6; style.expand_margin_bottom = 6
		theme.set_stylebox("embedded_border",kind,style)
		theme.set_stylebox("embedded_unfocused_border",kind,style)
		theme.set_constant("title_height",kind,72)
		theme.set_constant("close_h_offset",kind,30)
		theme.set_constant("close_v_offset",kind,38)
		theme.set_color("title_color",kind,Color("f1dfb5"))
		theme.set_icon("close",kind,load("res://ui/settings_art/close.svg"))
		theme.set_icon("close_pressed",kind,load("res://ui/settings_art/close.svg"))
	for kind in ["AcceptDialog","ConfirmationDialog"]:
		var content := StyleBoxEmpty.new()
		content.content_margin_left = 24; content.content_margin_right = 24
		content.content_margin_top = 20; content.content_margin_bottom = 36
		theme.set_stylebox("panel",kind,content)
		theme.set_constant("buttons_min_height",kind,38)
		theme.set_constant("buttons_min_width",kind,80)
	theme.set_type_variation("CityLedger","TabContainer")
	var ledger := StyleBoxFlat.new()
	ledger.bg_color = Color("101e26")
	ledger.border_color = Color(.46,.38,.25,.6)
	ledger.set_border_width_all(1); ledger.set_corner_radius_all(3)
	ledger.content_margin_left = 12; ledger.content_margin_right = 12
	ledger.content_margin_top = 10; ledger.content_margin_bottom = 10
	theme.set_stylebox("panel","CityLedger",ledger)
	theme.set_type_variation("GameMenuTitle","Heading")
	theme.set_font_size("font_size","GameMenuTitle",26)
	theme.set_type_variation("GameMenuChoice","OptionButton")
	theme.set_font_size("font_size","GameMenuChoice",18)
	theme.set_icon("arrow","GameMenuChoice",load("res://ui/settings_art/choice_arrow.svg"))
	theme.set_constant("h_separation","GameMenuChoice",16)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var choice := StyleBoxFlat.new()
		choice.bg_color = Color("0a1922") if state == "normal" else Color("234554")
		choice.border_color = Color("796343") if state == "normal" else Color("ddc18a")
		choice.set_border_width_all(1); choice.set_corner_radius_all(3)
		choice.content_margin_left = 14; choice.content_margin_right = 14
		choice.content_margin_top = 9; choice.content_margin_bottom = 9
		if state == "focus": choice.draw_center = false
		theme.set_stylebox(state,"GameMenuChoice",choice)
	for kind in ["EscapeAction","EscapePrimary","CityPanelPrimary","GameMenuAction","GameMenuPrimary"]:
		theme.set_type_variation(kind,"Button")
		var navigation: bool = kind.begins_with("GameMenu")
		theme.set_font_size("font_size",kind,18 if navigation else (20 if kind=="CityPanelPrimary" else 14))
		if navigation: theme.set_font("font",kind,theme.get_font("font","Subheading"))
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var style := StyleBoxTexture.new()
			style.texture = load(ACTION)
			style.texture_margin_left = 20; style.texture_margin_right = 20
			style.texture_margin_top = 12; style.texture_margin_bottom = 12
			style.content_margin_left = 22 if navigation else 14; style.content_margin_right = style.content_margin_left
			style.content_margin_top = 10 if navigation else 7; style.content_margin_bottom = style.content_margin_top
			style.modulate_color = Color(.75,.81,.87) if kind in ["EscapeAction","GameMenuAction"] else Color.WHITE
			if state == "hover": style.modulate_color *= Color(1.2,1.16,1.08)
			if state in ["pressed","hover_pressed"]: style.modulate_color *= Color(.68,.7,.74)
			if state == "disabled": style.modulate_color *= Color(.45,.47,.5)
			if state == "focus": style.modulate_color = Color(1.15,1.1,1,.3)
			theme.set_stylebox(state,kind,style)
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
			theme.set_color(state,kind,Color("f4e6c5"))
		theme.set_color("font_disabled_color",kind,Color("a9a596"))

static func prepare_window(node: Node) -> void:
	# Embedded Window clears otherwise cover the side/bottom artwork drawn by
	# embedded_border. Preserve the complete window's native input rectangle.
	if node is Window and not node is Popup:
		node.transparent_bg = true
		if node is AcceptDialog: node.get_ok_button().theme_type_variation = "EscapePrimary"
		if node is ConfirmationDialog: node.get_cancel_button().theme_type_variation = "EscapeAction"
