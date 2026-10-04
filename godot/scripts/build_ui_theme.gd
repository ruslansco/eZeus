extends SceneTree
# Builds res://ui/lapis_gold.tres, the one Theme every interface scene uses: the native game's lapis and
# bronze accents in Godot Controls. Body text uses Godot’s bundled sans; headings use Alegreya
# (OFL, the repository's body face; assets/fonts/Alegreya-OFL.txt). The .tres is an ordinary resource that
# can be tuned in the editor; rerun this script to regenerate it:
#   godot --headless --path godot --script res://scripts/build_ui_theme.gd

const OUTPUT := "res://ui/lapis_gold.tres"
const FONT := "res://assets/fonts/Alegreya-UI.ttf"
const LAPIS := Color(.045, .13, .18)
const LAPIS_RAISED := Color(.075, .22, .29)
const LAPIS_HOVER := Color(.12, .31, .39)
const GOLD := Color(.79, .66, .41)
const GOLD_PALE := Color(.97, .87, .64)
const GOLD_DEEP := Color(.46, .35, .17)
const IVORY := Color(.949, .918, .839)
const MUTED := Color(.67, .72, .78)
const DISABLED := Color(.47, .46, .42)
const ACCENT := Color(.48, .77, .84)

func box(background: Color, border: Color, border_width := 1, radius := 6, margin_x := 10, margin_y := 7) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.anti_aliasing = true
	return style

# The gold-rimmed lapis frame every HUD surface shares (the objectives panel's look): a soft shadow lifts it
# off the city, and the rim is brighter on top, as if lit from above.
func gold_frame(background_alpha := .97, rim := .55, radius := 10, margin_x := 12, margin_y := 8, shadow := 8) -> StyleBoxFlat:
	var frame := box(Color(LAPIS, background_alpha), Color(GOLD, rim), 1, radius, margin_x, margin_y)
	if shadow > 0:
		frame.shadow_color = Color(0, 0, 0, .28)
		frame.shadow_size = shadow
		frame.shadow_offset = Vector2(0, 3)
	return frame

# A gold-rimmed button face: `lit` 0 resting, 1 hovered, 2 chosen.
func gold_face(lit: int, radius := 8, margin_x := 8, margin_y := 6) -> StyleBoxFlat:
	var fill: Color = [Color(LAPIS_RAISED, .9), Color(LAPIS_HOVER, 1), Color(.27, .22, .12, 1)][lit]
	var rim: Color = [Color(GOLD, .22), Color(GOLD, .7), GOLD_PALE][lit]
	var face := box(fill, rim, 1, radius, margin_x, margin_y)
	if lit == 2:
		face.border_width_top = 2
	return face

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var regular: FontFile = load(FONT)
	print("THEME font axes ", regular.get_supported_variation_list())
	var weight_tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	var medium := FontVariation.new()
	medium.base_font = regular
	medium.variation_opentype = {weight_tag: 500}
	var bold := FontVariation.new()
	bold.base_font = regular
	bold.variation_opentype = {weight_tag: 700}

	var theme := Theme.new()
	# Leave the body font unset to use Godot’s bundled, Cyrillic-capable sans.
	theme.default_font_size = 15

	# Text.
	theme.set_color("font_color", "Label", IVORY)
	theme.set_type_variation("Heading", "Label")
	theme.set_font("font", "Heading", bold)
	theme.set_font_size("font_size", "Heading", 24)
	theme.set_color("font_color", "Heading", IVORY)
	theme.set_type_variation("Subheading", "Label")
	theme.set_font("font", "Subheading", bold)
	theme.set_font_size("font_size", "Subheading", 21)
	theme.set_color("font_color", "Subheading", IVORY)
	theme.set_type_variation("Value", "Label")
	theme.set_font_size("font_size", "Value", 16)
	theme.set_color("font_color", "Value", GOLD_PALE)
	theme.set_type_variation("Caption", "Label")
	theme.set_font_size("font_size", "Caption", 14)
	theme.set_color("font_color", "Caption", Color(IVORY, .86))
	theme.set_type_variation("Detail", "Label")
	theme.set_font_size("font_size", "Detail", 13)
	theme.set_color("font_color", "Detail", MUTED)
	theme.set_type_variation("ToolHeading", "Label")
	theme.set_font_size("font_size", "ToolHeading", 17)
	theme.set_color("font_color", "ToolHeading", IVORY)
	theme.set_type_variation("Title","Heading")
	theme.set_font_size("font_size","Title",44)
	# Preserve the atlas typography when regenerating the shared city Theme.
	theme.set_type_variation("AtlasTitle", "Label")
	theme.set_font("font", "AtlasTitle", bold)
	theme.set_font_size("font_size", "AtlasTitle", 34)
	theme.set_color("font_color", "AtlasTitle", Color(.96, .84, .59))
	theme.set_type_variation("AtlasHint", "Label")
	theme.set_font_size("font_size", "AtlasHint", 13)
	for entry in [["GoodStatus",Color(.55,.83,.66)],["WarningStatus",Color(.97,.76,.40)],["DangerStatus",Color(.98,.47,.37)],["NeutralStatus",MUTED]]:
		theme.set_type_variation(entry[0],"Label")
		theme.set_font_size("font_size",entry[0],16)
		theme.set_color("font_color",entry[0],entry[1])
	for variant in ["CardName","CardPrice"]:
		theme.set_type_variation(variant,"Label")
		theme.set_font_size("font_size",variant,12 if variant=="CardName" else 13)
		theme.set_color("font_color",variant,IVORY if variant=="CardName" else GOLD_PALE)

	# Panels share the gold-rimmed lapis frame of the objectives panel.
	var panel := gold_frame(.985, .5, 10, 12, 10)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_type_variation("Card", "PanelContainer")
	theme.set_stylebox("panel", "Card", box(Color(LAPIS_RAISED, .92), Color(GOLD, .3), 1, 8, 12, 10))

	# Buttons.
	var button_states := {
		"normal": box(Color(LAPIS_RAISED, .96), Color(GOLD, .28)),
		"hover": box(Color(LAPIS_HOVER, .98), Color(GOLD, .6)),
		"pressed": box(Color(.22, .25, .19, .98), GOLD_PALE),
		"disabled": box(Color(LAPIS, .75), Color(GOLD_DEEP, .3)),
		"focus": box(Color(0, 0, 0, 0), Color(GOLD_PALE, .9)),
	}
	for type_name in ["Button", "MenuButton", "OptionButton"]:
		for state in button_states:
			theme.set_stylebox(state, type_name, button_states[state])
		theme.set_color("font_color", type_name, IVORY)
		theme.set_color("font_hover_color", type_name, GOLD_PALE)
		theme.set_color("font_pressed_color", type_name, GOLD_PALE)
		theme.set_color("font_hover_pressed_color", type_name, GOLD_PALE)
		theme.set_color("font_focus_color", type_name, IVORY)
		theme.set_color("font_disabled_color", type_name, DISABLED)
		theme.set_font_size("font_size", type_name, 14)
		theme.set_constant("icon_max_width", type_name, 22)
	theme.set_type_variation("Primary", "Button")
	# Its faces are set with the escape menu's below.
	theme.set_color("font_color", "Primary", IVORY)
	theme.set_color("font_hover_color", "Primary", IVORY)

	# HUD variations use the same palette; borders are reserved for focus and selection.
	for type_name in ["Dock", "StatusStrip", "MiniPanel"]:
		theme.set_type_variation(type_name, "PanelContainer")
		theme.set_stylebox("panel", type_name, box(Color(LAPIS, .985), Color(GOLD, .25), 1, 12, 10, 6))
	# Slim city header; independent text scaling still uses this Theme's baseline.
	theme.set_stylebox("panel", "StatusStrip", box(Color(LAPIS, .985), Color(GOLD, .25), 1, 10, 10, 4))
	theme.set_type_variation("StatusValue", "Value")
	theme.set_font_size("font_size", "StatusValue", 14)
	for kind in ["StatusTool", "StatusSpeed"]:
		theme.set_type_variation(kind, "OptionButton" if kind == "StatusSpeed" else "Button")
		theme.set_font_size("font_size", kind, 13)
		theme.set_constant("icon_max_width", kind, 16)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var compact: StyleBoxFlat = button_states[state].duplicate()
			compact.content_margin_left = 6; compact.content_margin_right = 6
			compact.content_margin_top = 3; compact.content_margin_bottom = 3
			theme.set_stylebox(state, kind, compact)
	theme.set_type_variation("FloatingTray", "PanelContainer")
	var floating := box(Color(LAPIS,.99), Color(GOLD,.32),1,12,14,12)
	floating.shadow_color=Color(0,0,0,.25);floating.shadow_size=10
	theme.set_stylebox("panel","FloatingTray",floating)
	for type_name in ["PlacementGood","PlacementBad"]:
		theme.set_type_variation(type_name,"PanelContainer")
		theme.set_stylebox("panel",type_name,box(Color(LAPIS,.96),Color(GOLD,.8) if type_name=="PlacementGood" else Color(.95,.40,.30),1,8,10,7))
	for type_name in ["Tool", "Category", "BuildingCard", "Quiet"]:
		theme.set_type_variation(type_name, "Button")
		theme.set_stylebox("normal", type_name, box(Color(LAPIS_RAISED, .5 if type_name == "BuildingCard" else 0), Color(MUTED, .16 if type_name == "BuildingCard" else 0), 1, 5, 8, 6))
		theme.set_stylebox("hover", type_name, box(Color(LAPIS_HOVER, 1), Color(GOLD, .6), 1, 8, 8, 6))
		theme.set_stylebox("pressed", type_name, box(Color(.24,.22,.19,1), GOLD, 1, 8, 8, 6))
		theme.set_constant("icon_max_width", type_name, 24)
		theme.set_font_size("font_size", type_name, 12 if type_name == "Category" else 14)
	# News chips and the map use shared, scalable Theme entries, never baked font overrides.
	for kind in ["NoticeCard", "DecisionCard", "MapCard"]:
		theme.set_type_variation(kind, "PanelContainer")
		var edge:=Color(GOLD,.65) if kind=="DecisionCard" else Color(GOLD,.45)
		var surface:=box(Color(LAPIS,.99),edge,1,10,8 if kind!="MapCard" else 10,5 if kind!="MapCard" else 8)
		if kind == "MapCard":
			surface.content_margin_left = 0; surface.content_margin_right = 0
			surface.content_margin_top = 0; surface.content_margin_bottom = 0
		surface.shadow_color=Color(0,0,0,.22);surface.shadow_size=6
		theme.set_stylebox("panel",kind,surface)
	var correspondence := box(Color("202d39"), Color("a39578"), 1, 3, 18, 12)
	correspondence.shadow_color = Color(0,0,0,.3)
	correspondence.shadow_size = 10
	theme.set_stylebox("panel", "DecisionCard", correspondence)
	theme.set_type_variation("EnvoyAction", "Button")
	for state in ["normal", "hover", "pressed", "focus"]:
		theme.set_stylebox(state, "EnvoyAction", box(Color("344653") if state == "normal" else Color("4a5b64"), Color("a39578"), 1, 3, 12, 10))
	for kind in ["NoticeButton", "DecisionButton", "MapPill"]:
		theme.set_type_variation(kind, "Quiet")
		theme.set_font_size("font_size",kind,14)
		theme.set_color("icon_normal_color",kind,GOLD_PALE)
		if kind=="MapPill":
			theme.set_stylebox("normal",kind,box(Color(LAPIS,.99),Color(GOLD,.32),1,18,12,6))
			theme.set_stylebox("hover",kind,box(Color(LAPIS_HOVER,1),GOLD,1,18,12,6))
	theme.set_type_variation("MapFold", "Button")
	theme.set_font_size("font_size", "MapFold", 11)
	theme.set_constant("icon_max_width", "MapFold", 12)
	for state in ["normal", "hover", "pressed"]:
		theme.set_stylebox(state, "MapFold", box(Color(LAPIS,.9), Color(GOLD,.85 if state != "normal" else .4), 1, 6, 4, 2))
	theme.set_type_variation("NoticeProgress","ProgressBar")
	theme.set_stylebox("fill","NoticeProgress",box(Color(GOLD,.75),Color.TRANSPARENT,0,1,0,0))
	theme.set_type_variation("NoticeCaption","Eyebrow")
	theme.set_color("font_color","NoticeCaption",GOLD_PALE)
	for pair in [["homes",Color(.60,.82,.59)],["food",Color(.78,.74,.42)],["industry",Color(.67,.73,.77)],["storage",Color(.76,.73,.60)],["trade",Color(.56,.78,.83)],["markets",Color(.88,.69,.44)],["water",Color(.36,.76,.89)],["civic",Color(.86,.74,.54)],["defence",Color(.86,.51,.43)],["culture",Color(.76,.65,.84)],["science",Color(.56,.83,.74)],["gardens",Color(.45,.76,.52)],["sanctuaries",Color(.89,.81,.56)],["pyramids",Color(.86,.76,.52)],["shrines",Color(.90,.72,.50)],["heroes",Color(.88,.66,.48)],["build",IVORY]]:
		var variant: String="Category_"+pair[0]
		theme.set_type_variation(variant,"Category")
		theme.set_color("icon_normal_color",variant,GOLD_PALE)
		theme.set_color("icon_hover_color",variant,IVORY)
		theme.set_color("icon_pressed_color",variant,IVORY)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var selected: bool = state in ["pressed", "hover_pressed"]
		var medallion := box(LAPIS_RAISED if state == "normal" else (Color(.25,.23,.20) if selected else LAPIS_HOVER), Color(GOLD, .8 if selected else .32), 1, 24, 8, 8)
		medallion.border_width_top = 2
		medallion.shadow_color = Color(0,0,0,.2); medallion.shadow_size = 3; medallion.shadow_offset = Vector2(0,2)
		theme.set_stylebox(state, "Category", medallion)
	for kind in ["JournalRow"]:
		theme.set_type_variation(kind, "PanelContainer")
		theme.set_stylebox("panel",kind,box(Color(LAPIS_RAISED,.8),Color(GOLD,.12),1,8,8,7))
	# The HUD's frames, ribbons and controls all wear the objectives panel's gold rim (they replaced the slim teal
	# "Nova Roma" frames on 4 October 2026).
	for kind in ["StatusStrip", "Dock", "MiniPanel", "FloatingTray"]:
		theme.set_type_variation(kind, "PanelContainer")
		theme.set_stylebox("panel", kind, gold_frame(.97, .55, 12 if kind != "StatusStrip" else 10, 10, 6 if kind != "FloatingTray" else 12))
	theme.set_stylebox("panel", "StatusStrip", gold_frame(.97, .55, 10, 12, 4))
	theme.set_stylebox("panel", "ResourceRibbon", gold_frame(.95, .55, 10, 10, 6))
	theme.set_type_variation("OverviewInset","PanelContainer")
	theme.set_stylebox("panel","OverviewInset",StyleBoxEmpty.new())
	theme.set_type_variation("CityPlaque","PanelContainer")
	theme.set_stylebox("panel","CityPlaque",box(Color(GOLD_DEEP, .35),Color(GOLD,.7),1,8,12,3))
	theme.set_type_variation("CityName","Label")
	theme.set_font("font","CityName",bold)
	theme.set_font_size("font_size","CityName",15)
	theme.set_color("font_color","CityName",GOLD_PALE)
	for kind in ["ResourcePill","WelfareButton","RailButton"]:
		theme.set_type_variation(kind,"Button")
		theme.set_constant("icon_max_width",kind,28 if kind=="ResourcePill" else 21)
		theme.set_font_size("font_size",kind,12)
		if kind=="ResourcePill":
			theme.set_color("icon_normal_color",kind,Color.WHITE)
			theme.set_color("icon_hover_color",kind,Color.WHITE)
			theme.set_color("icon_pressed_color",kind,Color.WHITE)
		for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
			var lit := 0 if state in ["normal","disabled","focus"] else (2 if state in ["pressed","hover_pressed"] else 1)
			var face := gold_face(lit, 6, 5, 3)
			if kind == "ResourcePill" and state == "normal":
				face = box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 6, 5, 3)
			theme.set_stylebox(state,kind,face)
	# Tools: gold-rimmed tiles; categories: round gold medallions, lit when chosen.
	theme.set_constant("icon_max_width","Tool",22)
	theme.set_constant("icon_max_width","Category",22)
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var lit := 0 if state in ["normal","disabled","focus"] else (2 if state in ["pressed","hover_pressed"] else 1)
		theme.set_stylebox(state,"Tool",gold_face(lit, 8, 4, 4))
		var medallion := gold_face(lit, 24, 4, 4)
		medallion.shadow_color = Color(0,0,0,.25); medallion.shadow_size = 3; medallion.shadow_offset = Vector2(0,2)
		theme.set_stylebox(state,"Category",medallion)
	for variant in theme.get_type_list():
		if str(variant).begins_with("Category_"):
			theme.set_color("icon_normal_color",variant,GOLD_PALE)
			theme.set_color("icon_hover_color",variant,IVORY)
			theme.set_color("icon_pressed_color",variant,IVORY)
	for kind in ["Tool","Quiet","StatusTool"]:
		theme.set_color("icon_normal_color",kind,GOLD_PALE)
		theme.set_color("icon_hover_color",kind,IVORY)
		theme.set_color("icon_pressed_color",kind,IVORY)
	# Building cards in the build tray: gold-rimmed tiles, lit when chosen.
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var lit := 0 if state in ["normal","disabled","focus"] else (2 if state in ["pressed","hover_pressed"] else 1)
		var card := gold_face(lit, 8, 8, 6)
		if lit == 0:
			card.border_color = Color(GOLD, .3)
		theme.set_stylebox(state,"BuildingCard",card)
	theme.set_type_variation("EscapeCard","PanelContainer")
	theme.set_stylebox("panel","EscapeCard",gold_frame(.99,.7,12,24,22,12))
	theme.set_type_variation("Rail","PanelContainer")
	theme.set_stylebox("panel","Rail",box(Color.TRANSPARENT,Color.TRANSPARENT,0,0,0,0))
	# The round minimap frame: a gold ring.
	var map_ring := box(Color(LAPIS,.95),Color(GOLD,.75),2,112,0,0)
	map_ring.shadow_color = Color(0,0,0,.3); map_ring.shadow_size = 8; map_ring.shadow_offset = Vector2(0,3)
	theme.set_stylebox("panel","MapCard",map_ring)
	theme.set_color("rim","MapCard",GOLD)
	theme.set_color("rim_shadow","MapCard",Color(0,0,0,.45))
	theme.set_type_variation("Eyebrow", "Label")
	theme.set_font_size("font_size", "Eyebrow", 11)
	theme.set_color("font_color", "Eyebrow", MUTED)
	theme.set_stylebox("background", "ProgressBar", box(Color(0, 0, 0, .35), Color(GOLD, .22), 1, 4, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", box(GOLD, Color(GOLD_PALE, .5), 1, 4, 0, 0))

	# Menus and pop-ups.
	theme.set_stylebox("panel", "PopupMenu", box(Color(LAPIS, .98), Color(GOLD, .7), 1, 7, 6, 6))
	theme.set_stylebox("hover", "PopupMenu", box(Color(LAPIS_HOVER, 1.0), Color(0, 0, 0, 0), 0, 5, 8, 4))
	theme.set_color("font_color", "PopupMenu", IVORY)
	theme.set_color("font_hover_color", "PopupMenu", GOLD_PALE)
	theme.set_color("font_disabled_color", "PopupMenu", DISABLED)
	theme.set_stylebox("panel", "PopupPanel", box(Color(LAPIS, .98), Color(GOLD, .7), 1, 7, 8, 8))
	theme.set_stylebox("panel", "TooltipPanel", box(Color(LAPIS, .97), Color(GOLD, .55), 1, 6, 10, 6))
	theme.set_color("font_color", "TooltipLabel", IVORY)
	theme.set_font_size("font_size", "TooltipLabel", 15)

	# Dialogs (embedded windows draw their own border and title): the HUD's gold frame with a deeper shadow and a
	# bright gold line along the top of the title bar; the content inside has no second border.
	var dialog := box(Color(LAPIS, .99), Color(GOLD, .7), 1, 12, 18, 14)
	dialog.border_width_top = 3
	dialog.border_color = Color(GOLD, .75)
	dialog.shadow_color = Color(0, 0, 0, .45)
	dialog.shadow_size = 18
	dialog.shadow_offset = Vector2(0, 6)
	# Godot draws the border under the content only; growing it upward by the title height takes the title bar and
	# the close button inside the frame.
	dialog.expand_margin_top = 40
	dialog.expand_margin_left = 2
	dialog.expand_margin_right = 2
	dialog.expand_margin_bottom = 2
	for type_name in ["Window", "AcceptDialog", "ConfirmationDialog"]:
		theme.set_stylebox("embedded_border", type_name, dialog)
		theme.set_stylebox("embedded_unfocused_border", type_name, dialog)
		theme.set_color("title_color", type_name, GOLD_PALE)
		theme.set_color("title_outline_modulate", type_name, Color(0, 0, 0, .6))
		theme.set_constant("title_outline_size", type_name, 0)
		theme.set_font("title_font", type_name, bold)
		theme.set_font_size("title_font_size", type_name, 20)
		theme.set_constant("title_height", type_name, 40)
		# The close cross sits inside the frame, centred in the title bar.
		theme.set_constant("close_h_offset", type_name, 30)
		theme.set_constant("close_v_offset", type_name, 26)
	var content := box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 18, 14)
	theme.set_stylebox("panel", "AcceptDialog", content)
	theme.set_stylebox("panel", "ConfirmationDialog", content)
	theme.set_constant("buttons_separation", "AcceptDialog", 12)
	theme.set_constant("buttons_separation", "ConfirmationDialog", 12)

	# The escape menu (ui/escape_menu.gd): the gold card, its title over a gold rule, the section headings in pale gold
	# and the actions as gold tiles (the "Return to city" action is Primary).
	theme.set_type_variation("EscapeHeading", "ToolHeading")
	theme.set_font("font", "EscapeHeading", bold)
	theme.set_font_size("font_size", "EscapeHeading", 15)
	theme.set_color("font_color", "EscapeHeading", GOLD_PALE)
	theme.set_type_variation("EscapeRule", "HSeparator")
	var rule := StyleBoxLine.new()
	rule.color = Color(GOLD, .55)
	rule.thickness = 1
	theme.set_stylebox("separator", "EscapeRule", rule)
	theme.set_constant("separation", "EscapeRule", 4)
	theme.set_type_variation("EscapeAction", "Button")
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var lit := 0 if state in ["normal","disabled"] else (2 if state in ["pressed","hover_pressed"] else 1)
		var face := gold_face(lit, 8, 12, 6)
		if state == "focus":
			face = box(Color.TRANSPARENT, Color(GOLD_PALE, .9), 1, 8, 12, 6)
		theme.set_stylebox(state, "EscapeAction", face)
	theme.set_font_size("font_size", "EscapeAction", 15)
	theme.set_color("font_color", "EscapeAction", IVORY)
	theme.set_color("font_hover_color", "EscapeAction", GOLD_PALE)
	theme.set_color("font_pressed_color", "EscapeAction", GOLD_PALE)
	theme.set_color("font_focus_color", "EscapeAction", IVORY)
	theme.set_color("font_disabled_color", "EscapeAction", DISABLED)
	for state in ["normal","hover","pressed","focus"]:
		var face := box(Color(GOLD_DEEP, .9) if state == "normal" else Color(GOLD_DEEP.lightened(.15), .97), GOLD if state == "normal" else GOLD_PALE, 1, 8, 12, 6)
		face.border_width_top = 2
		theme.set_stylebox(state, "Primary", face)

	# Text entry (the inspector's stock limits).
	for type_name in ["LineEdit", "SpinBox"]:
		theme.set_stylebox("normal", "LineEdit", box(Color(.02, .04, .1, .95), Color(GOLD, .3), 1, 5, 8, 5))
		theme.set_stylebox("focus", "LineEdit", box(Color(.02, .04, .1, .95), Color(GOLD_PALE, .9), 1, 5, 8, 5))
		theme.set_color("font_color", "LineEdit", IVORY)
		theme.set_color("caret_color", "LineEdit", GOLD_PALE)
		theme.set_color("selection_color", "LineEdit", Color(GOLD, .35))

	# Lists (the saved games).
	theme.set_stylebox("panel", "ItemList", box(Color(.02, .04, .1, .9), Color(GOLD, .3), 1, 6, 6, 6))
	var selected := box(Color(.30, .22, .08, .92), GOLD, 1, 5, 6, 3)
	theme.set_stylebox("selected", "ItemList", selected)
	theme.set_stylebox("selected_focus", "ItemList", selected)
	theme.set_stylebox("hovered", "ItemList", box(Color(LAPIS_HOVER, .85), Color(0, 0, 0, 0), 0, 5, 6, 3))
	theme.set_color("font_color", "ItemList", IVORY)
	theme.set_color("font_selected_color", "ItemList", GOLD_PALE)
	theme.set_color("font_hovered_color", "ItemList", GOLD_PALE)
	theme.set_constant("v_separation", "ItemList", 4)

	# Scroll bars.
	for type_name in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", type_name, box(Color(0, 0, 0, .25), Color(0, 0, 0, 0), 0, 4, 0, 0))
		theme.set_stylebox("grabber", type_name, box(Color(GOLD, .5), Color(0, 0, 0, 0), 0, 4, 0, 0))
		theme.set_stylebox("grabber_highlight", type_name, box(Color(GOLD, .8), Color(0, 0, 0, 0), 0, 4, 0, 0))
		theme.set_stylebox("grabber_pressed", type_name, box(Color(GOLD_PALE, .95), Color(0, 0, 0, 0), 0, 4, 0, 0))

	# Objectives panel (ui/objective_card.gd, ui/objective_wreath.gd): the panel, a card per objective
	# (green when met), the round medallion with the kind's icon, the need chips and the progress bars.
	var achieved := Color(.55, .83, .66)
	theme.set_type_variation("ObjectivesPanel", "PanelContainer")
	theme.set_stylebox("panel", "ObjectivesPanel", gold_frame(.97, .55, 12, 12, 10))
	for entry in [["ObjectiveCard", Color(LAPIS_RAISED, .92), Color(GOLD, .3), 8, 10, 8],
			["ObjectiveCardDone", Color(.10, .25, .22, .92), Color(achieved, .6), 8, 10, 8],
			["ObjectiveMedal", Color(LAPIS, .9), GOLD, 18, 7, 7],
			["ObjectiveMedalDone", Color(achieved, .22), achieved, 18, 7, 7],
			["ObjectiveNeed", Color(.98, .47, .37, .14), Color(.98, .55, .42, .55), 10, 7, 3]]:
		theme.set_type_variation(entry[0], "PanelContainer")
		theme.set_stylebox("panel", entry[0], box(entry[1], entry[2], 1, entry[3], entry[4], entry[5]))
	for entry in [["ObjectiveBar", GOLD], ["ObjectiveBarDone", achieved]]:
		theme.set_type_variation(entry[0], "ProgressBar")
		theme.set_stylebox("background", entry[0], box(Color(0, 0, 0, .35), Color(GOLD, .22), 1, 4, 0, 0))
		theme.set_stylebox("fill", entry[0], box(entry[1], Color(GOLD_PALE, .5), 1, 4, 0, 0))
	theme.set_type_variation("ObjectiveDone", "Detail")
	theme.set_color("font_color", "ObjectiveDone", achieved)
	theme.set_type_variation("ObjectiveWarning", "Detail")
	theme.set_color("font_color", "ObjectiveWarning", Color(.97, .76, .40))
	theme.set_type_variation("ObjectiveCount", "Detail")
	theme.set_color("font_color", "ObjectiveCount", GOLD_PALE)
	theme.set_type_variation("ObjectiveNote", "Detail")
	theme.set_color("font_color", "ObjectiveNote", IVORY)

	# The character window (right click on a walker, ui/character_panel.gd): a gold-rimmed card, the portrait's frame and
	# plinth badge, the name in the bold face, the occupation in gold and the spoken line in the Alegreya text face.
	theme.set_type_variation("CharacterCard", "PanelContainer")
	theme.set_stylebox("panel", "CharacterCard", box(Color(LAPIS, .985), Color(GOLD, .62), 1, 10, 22, 20))
	theme.set_type_variation("CharacterFrame", "PanelContainer")
	theme.set_stylebox("panel", "CharacterFrame", box(Color(.02, .05, .07), Color(GOLD, .78), 2, 8, 0, 0))
	theme.set_type_variation("CharacterBadge", "PanelContainer")
	theme.set_stylebox("panel", "CharacterBadge", box(Color(LAPIS, .92), Color(GOLD, .6), 1, 10, 10, 3))
	theme.set_type_variation("CharacterName", "Label")
	theme.set_font("font", "CharacterName", bold)
	theme.set_font_size("font_size", "CharacterName", 30)
	theme.set_color("font_color", "CharacterName", GOLD_PALE)
	theme.set_type_variation("CharacterRole", "Label")
	theme.set_font("font", "CharacterRole", medium)
	theme.set_font_size("font_size", "CharacterRole", 16)
	theme.set_color("font_color", "CharacterRole", GOLD)
	theme.set_type_variation("CharacterSpeech", "Label")
	theme.set_font("font", "CharacterSpeech", regular)
	theme.set_font_size("font_size", "CharacterSpeech", 20)
	theme.set_color("font_color", "CharacterSpeech", IVORY)
	theme.set_type_variation("CharacterVoice", "ProgressBar")
	theme.set_stylebox("background", "CharacterVoice", box(Color(0, 0, 0, .35), Color(GOLD, .25), 1, 3, 0, 0))
	theme.set_stylebox("fill", "CharacterVoice", box(GOLD, Color(GOLD_PALE, .6), 1, 3, 0, 0))

	var error := ResourceSaver.save(theme, OUTPUT)
	print("THEME saved ", OUTPUT, " result=", error)
	quit(0 if error == OK else 1)
