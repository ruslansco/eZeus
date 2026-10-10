extends RefCounted
# Unscaled, generator-owned atlas styles. No camera, native command or RNG work.
const PanelSkin = preload("res://ui/city_panel_skin.gd")
const TYPES := ["AtlasFrame","AtlasPanel","AtlasHeadingPanel","AtlasToolbar",
	"AtlasPortrait","AtlasGoods","AtlasAction","AtlasPrimary","AtlasCityName"]

static func install(theme: Theme) -> void:
	for spec in [["AtlasFrame",24,24],["AtlasPanel",32,30],["AtlasHeadingPanel",28,28],["AtlasToolbar",28,28]]:
		theme.set_type_variation(spec[0],"PanelContainer")
		var wood := PanelSkin.wood(spec[1],spec[2])
		# Frame the live map without painting over its independent viewport.
		if spec[0] == "AtlasFrame": wood.draw_center = false
		theme.set_stylebox("panel",spec[0],wood)
	theme.set_type_variation("AtlasPortrait","Control")
	theme.set_stylebox("panel","AtlasPortrait",PanelSkin.wood(14,14))
	theme.set_type_variation("AtlasGoods","ScrollContainer")
	var reading := StyleBoxFlat.new()
	reading.bg_color = Color("101e26")
	reading.border_color = Color("6c5838")
	reading.set_border_width_all(1); reading.set_corner_radius_all(3)
	reading.content_margin_left = 12; reading.content_margin_right = 12
	reading.content_margin_top = 12; reading.content_margin_bottom = 12
	theme.set_stylebox("panel","AtlasGoods",reading)
	theme.set_type_variation("AtlasCityName","Subheading")
	theme.set_font_size("font_size","AtlasCityName",24)
	theme.set_color("font_color","AtlasCityName",Color("f4e6c5"))
	for kind in ["AtlasAction","AtlasPrimary"]:
		theme.set_type_variation(kind,"Button")
		theme.set_font("font",kind,theme.get_font("font","Subheading"))
		theme.set_font_size("font_size",kind,16)
		var original := "GameMenuPrimary" if kind == "AtlasPrimary" else "GameMenuAction"
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var style: StyleBoxTexture = theme.get_stylebox(state,original).duplicate()
			style.content_margin_left = 18; style.content_margin_right = 18
			style.content_margin_top = 8; style.content_margin_bottom = 8
			theme.set_stylebox(state,kind,style)
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:
			theme.set_color(state,kind,theme.get_color(state,original))
