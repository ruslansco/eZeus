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
const METAL := Color(.075, .090, .097)

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
	theme.set_type_variation("NoticeBody", "Caption")
	theme.set_font_size("font_size", "NoticeBody", 15)
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
	# Compact atlas surfaces leave the landscape visible and protect text contrast.
	for kind in ["AtlasFrame", "AtlasPanel", "AtlasToolbar", "AtlasHeadingPanel"]:
		theme.set_type_variation(kind, "PanelContainer")
		theme.set_stylebox("panel", kind, gold_frame(.94 if kind=="AtlasHeadingPanel" else .985,.5,10,0 if kind=="AtlasFrame" else 12,0 if kind=="AtlasFrame" else 8,0 if kind=="AtlasFrame" else 6))

	# Buttons.
	# Adventure library and illustrated campaign card (original layout; installed campaign art).
	# Cinematic main menu: clear title, a distinct saved-city card and quiet utility controls.
	theme.set_type_variation("MainMenuTitle","Title")
	theme.set_font_size("font_size","MainMenuTitle",44)
	theme.set_color("font_color","MainMenuTitle",GOLD_PALE)
	theme.set_type_variation("MainMenuEyebrow","Detail")
	theme.set_color("font_color","MainMenuEyebrow",Color(GOLD_PALE,.82))
	for entry in [["MainMenuShell",box(Color(.018,.037,.050,.88),Color(GOLD,.38),1,8,24,24)],
		["MainMenuProfile",box(Color(.08,.16,.19,.62),Color(GOLD,.16),1,4,10,5)],
		["MainMenuSave",box(Color(.075,.16,.20,.94),Color(GOLD,.50),1,5,14,12)]]:
		theme.set_type_variation(entry[0],"PanelContainer")
		var face: StyleBoxFlat = entry[1]
		if entry[0] == "MainMenuShell":
			face.shadow_size = 16
			face.shadow_color = Color(0,0,0,.30)
		if entry[0] == "MainMenuSave": face.border_width_top = 2
		theme.set_stylebox("panel",entry[0],face)
	for entry in [["MainMenuPrimary",20],["MainMenuContinue",16],["MainMenuSecondary",17],["MainMenuEditor",14],["MainMenuUtility",14]]:
		var kind: String = entry[0]
		theme.set_type_variation(kind,"Button")
		theme.set_font_size("font_size",kind,entry[1])
		theme.set_constant("h_separation",kind,12 if kind != "MainMenuUtility" else 6)
		theme.set_constant("icon_max_width",kind,24 if kind != "MainMenuUtility" else 18)
		var utility := kind in ["MainMenuEditor","MainMenuUtility"]
		var primary := kind == "MainMenuPrimary"
		for state in ["normal","hover","pressed","disabled","focus"]:
			var fill := Color(.10,.22,.27,.85)
			var rim := Color(GOLD,.30)
			if primary:
				fill = Color(.29,.23,.12)
				rim = Color(GOLD,.85)
			if utility:
				fill = Color.TRANSPARENT
				rim = Color.TRANSPARENT
			if state == "hover":
				fill = Color(.37,.29,.15) if primary else Color(.13,.29,.34,.90)
				rim = Color(GOLD,.75)
			if state == "pressed":
				fill = Color(.43,.33,.16) if primary else Color(.18,.34,.38)
				rim = GOLD_PALE
			if state == "disabled":
				fill = Color(.04,.09,.12,.45)
				rim = Color(GOLD,.15)
			if state == "focus":
				fill = Color.TRANSPARENT
				rim = GOLD_PALE
			theme.set_stylebox(state,kind,box(fill,rim,1,4,8 if utility else 16,5 if utility else 10))
	theme.set_type_variation("MainMenuRule","HSeparator")
	theme.set_stylebox("separator","MainMenuRule",box(Color(GOLD,.24),Color.TRANSPARENT,0,0,0,1))

	# Shared campaign transitions: a readable chronicle beside native objective cards.
	for entry in [["EpisodeShell",gold_frame(.985,.65,10,22,22,18)],
		["EpisodeBanner",box(Color(.075,.14,.17),Color(GOLD,.25),1,5,18,14)],
		["EpisodePaper",box(Color(.91,.865,.75),Color(GOLD,.55),1,5,22,20)],
		["EpisodeObjectives",box(Color(.04,.10,.135),Color(GOLD,.25),1,5,14,16)],
		["EpisodeGoal",box(Color(.08,.18,.22),Color(GOLD,.20),1,4,12,12)],
		["EpisodeGoalMet",box(Color(.075,.19,.16),Color(.42,.70,.52,.5),1,4,12,12)]]:
		theme.set_type_variation(entry[0],"PanelContainer")
		theme.set_stylebox("panel",entry[0],entry[1])
	for entry in [["EpisodeEyebrow","Caption",13,GOLD_PALE],
		["EpisodeHeading","Heading",23,GOLD_PALE],
		["EpisodeResultHeading","Heading",34,GOLD_PALE],
		["EpisodeTitle","Subheading",28,IVORY],
		["EpisodePaperHeading","Subheading",20,Color(.32,.25,.15)],
		["EpisodeBody","Label",15,Color(.18,.20,.18)],
		["EpisodeGoalHeading","Subheading",23,GOLD_PALE],
		["EpisodeGoalText","Label",15,IVORY],
		["EpisodeGoalMark","Label",19,GOLD_PALE]]:
		theme.set_type_variation(entry[0],entry[1])
		theme.set_font_size("font_size",entry[0],entry[2])
		theme.set_color("font_color",entry[0],entry[3])
	theme.set_constant("line_spacing","EpisodeBody",7)
	theme.set_type_variation("EpisodeDifficultyButton","MainMenuSecondary")
	theme.set_font_size("font_size","EpisodeDifficultyButton",24)

	for entry in [["AdventureShell",gold_frame(.97,.55,8,22,20,14)],
		["AdventureCard",box(Color(.08,.12,.15),GOLD,1,3,1,1)],
		["AdventureRibbon",box(Color(.24,.19,.105),Color(GOLD,.8),0,0,18,10)],
		["AdventurePaper",box(Color(.90,.85,.73),Color(GOLD,.7),0,0,20,18)],
		["AdventureBadge",box(Color(.025,.075,.095,.94),Color(GOLD,.8),1,3,10,6)]]:
		theme.set_type_variation(entry[0],"PanelContainer")
		theme.set_stylebox("panel",entry[0],entry[1])
	theme.set_type_variation("AdventureBodyText","Label")
	theme.set_color("font_color","AdventureBodyText",Color(.20,.18,.14))
	theme.set_font_size("font_size","AdventureBodyText",14)
	theme.set_type_variation("AdventureGoalText","AdventureBodyText")
	theme.set_font_size("font_size","AdventureGoalText",15)
	theme.set_type_variation("AdventurePaperHeading","Subheading")
	theme.set_color("font_color","AdventurePaperHeading",Color(.25,.20,.11))
	theme.set_font_size("font_size","AdventurePaperHeading",20)
	theme.set_type_variation("AdventureBadgeText","Caption")
	theme.set_color("font_color","AdventureBadgeText",GOLD_PALE)
	theme.set_type_variation("AdventureRule","HSeparator")
	theme.set_stylebox("separator","AdventureRule",box(Color(.4,.32,.17,.20),Color.TRANSPARENT,0,0,0,1))
	theme.set_type_variation("AdventureList","ItemList")
	theme.set_stylebox("panel","AdventureList",box(Color(.02,.055,.075,.8),Color(GOLD,.25),1,3,10,10))
	theme.set_stylebox("selected","AdventureList",box(Color(.28,.23,.13),Color(GOLD,.75),1,3,8,6))
	theme.set_stylebox("selected_focus","AdventureList",box(Color(.28,.23,.13),GOLD_PALE,1,3,8,6))
	theme.set_stylebox("focus","AdventureList",box(Color.TRANSPARENT,Color(GOLD,.5),1,3,0,0))
	theme.set_constant("v_separation","AdventureList",12)
	theme.set_constant("outline_size","AdventureList",0)
	theme.set_font_size("font_size","AdventureList",15)
	theme.set_type_variation("AdventureScrollBar","VScrollBar")
	for entry in [["scroll",Color(.3,.25,.15,.14)],["grabber",Color(.48,.37,.19,.70)],["grabber_highlight",Color(.37,.27,.12,.90)],["grabber_pressed",Color(.30,.23,.12)]]:
		theme.set_stylebox(entry[0],"AdventureScrollBar",box(entry[1],Color.TRANSPARENT,0,3,3,0))

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
	# The decision card (an envoy awaiting the player's answer): the gold frame, brighter, with the top line of a dialog.
	var correspondence := gold_frame(.99, .75, 4, 20, 18, 10)
	theme.set_stylebox("panel", "DecisionCard", correspondence)
	theme.set_type_variation("DecisionReminder", "PanelContainer")
	theme.set_stylebox("panel", "DecisionReminder", gold_frame(.99, .75, 10, 12, 10))
	theme.set_type_variation("EnvoyPaper", "PanelContainer")
	theme.set_stylebox("panel", "EnvoyPaper", box(Color(.105,.125,.135,.99), Color(GOLD,.25), 1, 4, 18, 16))
	theme.set_type_variation("EnvoyPortrait", "Control")
	theme.set_stylebox("panel", "EnvoyPortrait", box(Color(.055,.065,.072,.98), Color(GOLD,.3), 1, 4, 8, 8))
	theme.set_type_variation("EnvoyBody", "Label")
	theme.set_font("font", "EnvoyBody", ThemeDB.fallback_font)
	theme.set_font_size("font_size", "EnvoyBody", 16)
	theme.set_color("font_color", "EnvoyBody", IVORY)
	theme.set_constant("line_spacing", "EnvoyBody", 4)
	theme.set_type_variation("EnvoyCityName", "Subheading")
	theme.set_font_size("font_size", "EnvoyCityName", 20)
	theme.set_type_variation("EnvoyTitleButton", "Button")
	theme.set_font("font", "EnvoyTitleButton", bold)
	theme.set_font_size("font_size", "EnvoyTitleButton", 24)
	theme.set_color("font_color", "EnvoyTitleButton", IVORY)
	for state in ["normal", "hover", "pressed"]:
		theme.set_stylebox(state, "EnvoyTitleButton", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, 0, 0))
	theme.set_stylebox("focus", "EnvoyTitleButton", box(Color.TRANSPARENT, Color(GOLD,.8), 1, 4, 0, 0))
	theme.set_type_variation("EnvoyAction", "Button")
	for state in ["normal", "hover", "pressed", "focus"]:
		var lit := 0 if state == "normal" else (2 if state == "pressed" else 1)
		var face := gold_face(lit, 8, 12, 10)
		if state == "focus":
			face = box(Color.TRANSPARENT, Color(GOLD_PALE, .9), 1, 8, 12, 10)
		theme.set_stylebox(state, "EnvoyAction", face)
	theme.set_color("font_hover_color", "EnvoyAction", GOLD_PALE)
	theme.set_type_variation("EnvoyPrimary", "EnvoyAction")
	for state in ["normal", "hover", "pressed"]:
		theme.set_stylebox(state, "EnvoyPrimary", box(Color(.40,.31,.16) if state == "normal" else Color(.51,.40,.21), GOLD_PALE, 1, 8, 12, 10))
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
	theme.set_stylebox("panel", "CharacterFrame", box(Color(.06, .075, .08), Color(GOLD, .45), 1, 4, 0, 0))
	theme.set_type_variation("CharacterQuote", "PanelContainer")
	theme.set_stylebox("panel", "CharacterQuote", box(Color(.055,.065,.072,.8), Color(GOLD,.16), 1, 4, 12, 10))
	for entry in [["CharacterStockTile",Color(.40,.62,.49,.60)],["CharacterEmptyTile",Color(.45,.49,.50,.35)]]:
		theme.set_type_variation(entry[0], "PanelContainer")
		theme.set_stylebox("panel", entry[0], box(Color(.055,.065,.072,.9), entry[1], 1, 4, 9, 7))
	for entry in [["CharacterStockGood",Color(.55,.83,.66)],["CharacterStockMuted",MUTED]]:
		theme.set_type_variation(entry[0], "Detail")
		theme.set_font_size("font_size", entry[0], 13)
		theme.set_color("font_color", entry[0], entry[1])
	theme.set_type_variation("CharacterBadge", "PanelContainer")
	theme.set_stylebox("panel", "CharacterBadge", box(Color(LAPIS, .92), Color(GOLD, .6), 1, 10, 10, 3))
	theme.set_type_variation("CharacterName", "Label")
	theme.set_font("font", "CharacterName", bold)
	theme.set_font_size("font_size", "CharacterName", 26)
	theme.set_color("font_color", "CharacterName", GOLD_PALE)
	theme.set_type_variation("CharacterRole", "Label")
	theme.set_font("font", "CharacterRole", medium)
	theme.set_font_size("font_size", "CharacterRole", 16)
	theme.set_color("font_color", "CharacterRole", GOLD)
	theme.set_type_variation("CharacterSpeech", "Label")
	theme.set_font("font", "CharacterSpeech", regular)
	theme.set_font_size("font_size", "CharacterSpeech", 18)
	theme.set_color("font_color", "CharacterSpeech", IVORY)
	theme.set_type_variation("CharacterVoice", "ProgressBar")
	theme.set_stylebox("background", "CharacterVoice", box(Color(0, 0, 0, .35), Color(GOLD, .25), 1, 3, 0, 0))
	theme.set_stylebox("fill", "CharacterVoice", box(GOLD, Color(GOLD_PALE, .6), 1, 3, 0, 0))

	# Original illustrated construction dock: dark metal, readable color silhouettes, restrained active/focus markers.
	theme.set_type_variation("ToolbarDock", "PanelContainer")
	var dock := box(Color(.075,.090,.097,.985), Color(.55,.49,.36,.72), 1, 4, 10, 7)
	dock.shadow_color = Color(0,0,0,.35); dock.shadow_size = 8
	theme.set_stylebox("panel", "ToolbarDock", dock)
	theme.set_type_variation("ToolbarCategory", "Button")
	theme.set_type_variation("ToolbarTool", "Button")
	for kind in ["ToolbarCategory", "ToolbarTool"]:
		theme.set_font_size("font_size", kind, 12)
		theme.set_constant("icon_max_width", kind, 36 if kind == "ToolbarCategory" else 24)
		theme.set_color("icon_normal_color", kind, Color.WHITE)
		theme.set_color("icon_hover_color", kind, Color.WHITE)
		theme.set_color("icon_pressed_color", kind, Color.WHITE)
		theme.set_color("icon_hover_pressed_color", kind, Color.WHITE)
		theme.set_color("icon_disabled_color", kind, Color(.45,.45,.45,.7))
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var chosen: bool = state in ["pressed", "hover_pressed"]
			var lit: bool = state in ["hover", "hover_pressed"]
			var face := box(Color(.28,.25,.18) if chosen else (Color(.18,.22,.24) if lit else Color(.10,.12,.13,.9)), Color(GOLD,.9 if chosen or state=="focus" else (.48 if lit else .12)), 1, 2, 4, 4)
			if chosen:
				face.border_width_bottom = 3
			if state == "focus": face.bg_color = Color.TRANSPARENT
			theme.set_stylebox(state, kind, face)
	for variant in theme.get_type_list():
		if str(variant).begins_with("Category_"):
			theme.set_type_variation(variant,"ToolbarCategory")
			for state in ["normal", "hover", "pressed", "hover_pressed"]: theme.set_color("icon_"+state+"_color", variant, Color.WHITE)
	theme.set_type_variation("ToolbarContext", "Label")
	theme.set_font("font", "ToolbarContext", medium)
	theme.set_font_size("font_size", "ToolbarContext", 14)
	theme.set_color("font_color", "ToolbarContext", IVORY)
	theme.set_type_variation("ToolbarTooltip", "PanelContainer")
	theme.set_stylebox("panel", "ToolbarTooltip", box(Color(.075,.090,.097,.99), Color(GOLD,.8), 1, 4, 16, 12))
	theme.set_type_variation("ToolbarTooltipTitle", "Subheading")
	theme.set_font_size("font_size", "ToolbarTooltipTitle", 20)
	theme.set_color("font_color", "ToolbarTooltipTitle", GOLD_PALE)
	theme.set_type_variation("ToolbarTooltipDetail", "Label")
	theme.set_font_size("font_size", "ToolbarTooltipDetail", 14)
	theme.set_color("font_color", "ToolbarTooltipDetail", MUTED)
	# Match city panels to the illustrated dock; keep their existing content bounds.
	for kind in ["PanelContainer", "Panel", "StatusStrip", "Dock", "MiniPanel", "FloatingTray", "ObjectivesPanel", "NoticeCard", "DecisionCard", "DecisionReminder", "CharacterCard", "EscapeCard", "EpisodeShell", "Card", "JournalRow", "ObjectiveCard", "PopupMenu", "ItemList"]:
		var surface: StyleBoxFlat = theme.get_stylebox("panel", kind).duplicate()
		surface.bg_color = Color(METAL, .985)
		surface.border_color = dock.border_color
		surface.set_corner_radius_all(4)
		surface.shadow_color = dock.shadow_color
		surface.shadow_size = 8
		theme.set_stylebox("panel", kind, surface)
	for kind in ["Button", "MenuButton", "OptionButton", "Tool", "Quiet", "WelfareButton", "RailButton", "ResourcePill", "BuildingCard", "MapFold", "EnvoyAction", "EnvoyPrimary"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var face: StyleBoxFlat = theme.get_stylebox(state, kind).duplicate()
			var chosen: bool = state in ["pressed", "hover_pressed"]
			var hovered: bool = state in ["hover", "hover_pressed"]
			if face.bg_color.a > 0:
				face.bg_color = Color(.28,.25,.18) if chosen else Color(.18,.22,.24) if hovered else Color(.10,.12,.13,face.bg_color.a)
			face.set_corner_radius_all(2)
			theme.set_stylebox(state, kind, face)
	for state in ["normal", "focus"]:
		var input_face: StyleBoxFlat = theme.get_stylebox(state, "LineEdit").duplicate()
		input_face.bg_color = Color(.055,.065,.072,.98)
		input_face.set_corner_radius_all(2)
		theme.set_stylebox(state, "LineEdit", input_face)
	for kind in ["Window", "AcceptDialog", "ConfirmationDialog"]:
		for state in ["embedded_border", "embedded_unfocused_border"]:
			var frame: StyleBoxFlat = theme.get_stylebox(state, kind).duplicate()
			frame.bg_color = Color(METAL,.99)
			frame.border_color = dock.border_color
			frame.set_corner_radius_all(4)
			theme.set_stylebox(state, kind, frame)
	theme.set_type_variation("ResourceRibbon", "PanelContainer")
	theme.set_stylebox("panel", "ResourceRibbon", box(Color(METAL,.90),dock.border_color,1,4,8,3))
	theme.set_type_variation("NotificationRail", "PanelContainer")
	theme.set_stylebox("panel", "NotificationRail", box(Color(METAL,.90),dock.border_color,1,4,5,5))
	theme.set_type_variation("NotificationScrollBar","VScrollBar")
	for entry in [["scroll",Color(0,0,0,.25)],["grabber",Color(GOLD,.6)],["grabber_highlight",GOLD],["grabber_pressed",GOLD_PALE]]:
		theme.set_stylebox(entry[0],"NotificationScrollBar",box(entry[1],Color.TRANSPARENT,0,3,3,0))
	theme.set_type_variation("NotificationButton", "Button")
	theme.set_font_size("font_size", "NotificationButton", 11)
	theme.set_constant("icon_max_width", "NotificationButton", 32)
	for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
		var lit: bool = state in ["hover","pressed","hover_pressed","focus"]
		theme.set_stylebox(state,"NotificationButton",box(Color(.22,.25,.24) if lit else Color(.10,.12,.13,.8),GOLD if lit else Color(GOLD,.30),1,3,5,5))
	for state in ["normal","hover","pressed","hover_pressed"]:
		theme.set_color("icon_"+state+"_color","NotificationButton",Color.WHITE)
	theme.set_type_variation("HeaderWell", "PanelContainer")
	theme.set_stylebox("panel", "HeaderWell", box(Color(.10,.12,.13,.65),Color(GOLD,.16),1,2,4,2))
	for spec in [["HeaderCaption",11,MUTED],["HeaderValue",14,IVORY],["HeaderTrend",13,IVORY]]:
		theme.set_type_variation(spec[0], "Label")
		theme.set_font_size("font_size",spec[0],spec[1])
		theme.set_color("font_color",spec[0],spec[2])
	theme.set_type_variation("HeaderCityTitle", "Label")
	theme.set_font("font","HeaderCityTitle",bold)
	theme.set_font_size("font_size","HeaderCityTitle",18)
	theme.set_color("font_color","HeaderCityTitle",GOLD_PALE)
	for kind in ["HeaderAction","HeaderSpeed"]:
		theme.set_type_variation(kind,"Button")
		theme.set_font_size("font_size",kind,12 if kind=="HeaderAction" else 14)
		theme.set_constant("icon_max_width",kind,20)
		for state in ["normal","hover","pressed","hover_pressed"]:
			theme.set_color("icon_"+state+"_color",kind,Color.WHITE)
		for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
			var chosen: bool=state in ["pressed","hover_pressed"]
			var hovered: bool=state in ["hover","hover_pressed"]
			var face:=box(Color(.28,.25,.18) if chosen else (Color(.18,.22,.24) if hovered else Color(.10,.12,.13,.9)),Color(GOLD,.85 if chosen or state=="focus" else (.50 if hovered else .22)),1,2,5 if kind=="HeaderAction" else 4,3)
			if chosen:face.border_width_bottom=2
			if state=="focus":face.bg_color=Color.TRANSPARENT
			theme.set_stylebox(state,kind,face)
	# The city help card (ui/city_help_panel.gd): segmented Issues/Guide tabs and the settlement guide's stepper. A thin
	# segmented progress bar, step rows with done/current/upcoming markers, the current step as an inset card with a
	# gold edge on the left, a full-width status strip (green when done, teal while to do), quiet secondary actions and
	# one gold primary action. `highlight` is the pulsing outline the guide draws round the dock button it points at.
	var to_do := ACCENT
	theme.set_type_variation("GuideCard", "PanelContainer")
	var guide_card := box(Color(METAL, .97), dock.border_color, 1, 6, 14, 10)
	guide_card.shadow_color = Color(0, 0, 0, .35); guide_card.shadow_size = 10; guide_card.shadow_offset = Vector2(0, 3)
	theme.set_stylebox("panel", "GuideCard", guide_card)
	theme.set_color("highlight", "GuideCard", GOLD_PALE)
	theme.set_type_variation("GuideTabs", "PanelContainer")
	theme.set_stylebox("panel", "GuideTabs", box(Color(.035, .045, .05, .9), Color(GOLD, .16), 1, 5, 3, 3))
	theme.set_type_variation("GuideTab", "Button")
	theme.set_font("font", "GuideTab", medium)
	theme.set_font_size("font_size", "GuideTab", 14)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var chosen: bool = state in ["pressed", "hover_pressed"]
		var face := box(Color(.24, .21, .15) if chosen else (Color(.16, .19, .21) if state == "hover" else Color.TRANSPARENT), Color(GOLD, .75) if chosen else (Color(GOLD_PALE, .9) if state == "focus" else Color.TRANSPARENT), 1, 4, 12, 4)
		theme.set_stylebox(state, "GuideTab", face)
	for entry in [["font_color", MUTED], ["font_hover_color", IVORY], ["font_pressed_color", GOLD_PALE], ["font_hover_pressed_color", GOLD_PALE], ["font_focus_color", IVORY]]:
		theme.set_color(entry[0], "GuideTab", entry[1])
	theme.set_type_variation("GuideIconButton", "Button")
	theme.set_constant("icon_max_width", "GuideIconButton", 16)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var lit: bool = state in ["hover", "pressed", "hover_pressed"]
		theme.set_stylebox(state, "GuideIconButton", box(Color(.18, .22, .24) if lit else Color.TRANSPARENT, Color(GOLD_PALE, .9) if state == "focus" else (Color(GOLD, .45) if lit else Color.TRANSPARENT), 1, 4, 6, 6))
	for entry in [["icon_normal_color", MUTED], ["icon_hover_color", IVORY], ["icon_pressed_color", GOLD_PALE], ["icon_hover_pressed_color", GOLD_PALE], ["icon_focus_color", IVORY]]:
		theme.set_color(entry[0], "GuideIconButton", entry[1])
	for entry in [["GuideTitle", 18, IVORY, bold], ["GuideStepTitle", 16, GOLD_PALE, bold], ["GuideMeta", 13, MUTED, null], ["GuideBody", 14, Color(IVORY, .88), null], ["GuideChipDoneText", 14, achieved, medium], ["GuideChipTodoText", 14, to_do, medium]]:
		theme.set_type_variation(entry[0], "Label")
		theme.set_font_size("font_size", entry[0], entry[1])
		theme.set_color("font_color", entry[0], entry[2])
		if entry[3] != null: theme.set_font("font", entry[0], entry[3])
	theme.set_constant("line_spacing", "GuideBody", 3)
	for entry in [["GuideSegment", Color(1, 1, 1, .12)], ["GuideSegmentDone", Color(achieved, .9)], ["GuideSegmentCurrent", GOLD]]:
		theme.set_type_variation(entry[0], "PanelContainer")
		theme.set_stylebox("panel", entry[0], box(entry[1], Color.TRANSPARENT, 0, 2, 0, 0))
	# The base scroll bar styles have no content margins (zero width); the guide's list needs a visible bar.
	theme.set_type_variation("GuideScrollBar", "VScrollBar")
	for entry in [["scroll", Color(0, 0, 0, .25)], ["grabber", Color(GOLD, .6)], ["grabber_highlight", GOLD], ["grabber_pressed", GOLD_PALE]]:
		theme.set_stylebox(entry[0], "GuideScrollBar", box(entry[1], Color.TRANSPARENT, 0, 3, 3, 0))
	theme.set_type_variation("GuideStepCard", "PanelContainer")
	var step_card := box(Color(.10, .12, .13, .95), Color(GOLD, .4), 1, 5, 12, 8)
	step_card.border_width_left = 3
	theme.set_stylebox("panel", "GuideStepCard", step_card)
	for entry in [["GuideChipDone", achieved], ["GuideChipTodo", to_do]]:
		theme.set_type_variation(entry[0], "PanelContainer")
		theme.set_stylebox("panel", entry[0], box(Color(entry[1], .1), Color(entry[1], .4), 1, 4, 8, 4))
	theme.set_type_variation("GuideStep", "Button")
	theme.set_type_variation("GuideStepDone", "GuideStep")
	for kind in ["GuideStep", "GuideStepDone"]:
		theme.set_font_size("font_size", kind, 14)
		theme.set_constant("icon_max_width", kind, 18)
		theme.set_constant("h_separation", kind, 10)
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var lit: bool = state in ["hover", "pressed", "hover_pressed"]
			theme.set_stylebox(state, kind, box(Color(.16, .19, .21, .85) if lit else Color.TRANSPARENT, Color(GOLD_PALE, .9) if state == "focus" else Color.TRANSPARENT, 1, 4, 8, 3))
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			theme.set_color("icon_" + state + "_color", kind, Color.WHITE)
		theme.set_color("font_color", kind, Color(IVORY, .92) if kind == "GuideStep" else MUTED)
		for state in ["hover", "pressed", "hover_pressed"]:
			theme.set_color("font_" + state + "_color", kind, GOLD_PALE)
		theme.set_color("font_focus_color", kind, IVORY)
	theme.set_type_variation("GuideAction", "Button")
	theme.set_font_size("font_size", "GuideAction", 13)
	theme.set_constant("icon_max_width", "GuideAction", 20)
	theme.set_constant("h_separation", "GuideAction", 6)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var chosen: bool = state in ["pressed", "hover_pressed"]
		var hovered: bool = state in ["hover", "hover_pressed"]
		var face := box(Color(.28, .25, .18) if chosen else (Color(.18, .22, .24) if hovered else Color(.13, .155, .165, .95)), Color(GOLD, .85 if chosen else (.55 if hovered else .28)), 1, 4, 10, 5)
		if state == "focus": face = box(Color.TRANSPARENT, Color(GOLD_PALE, .9), 1, 4, 10, 5)
		theme.set_stylebox(state, "GuideAction", face)
	for entry in [["font_color", IVORY], ["font_hover_color", GOLD_PALE], ["font_pressed_color", GOLD_PALE], ["font_hover_pressed_color", GOLD_PALE], ["icon_normal_color", Color.WHITE], ["icon_hover_color", Color.WHITE], ["icon_pressed_color", Color.WHITE], ["icon_hover_pressed_color", Color.WHITE]]:
		theme.set_color(entry[0], "GuideAction", entry[1])
	theme.set_type_variation("GuidePrimary", "Button")
	theme.set_font("font", "GuidePrimary", medium)
	theme.set_font_size("font_size", "GuidePrimary", 14)
	theme.set_constant("icon_max_width", "GuidePrimary", 16)
	theme.set_constant("h_separation", "GuidePrimary", 4)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var fill: Color = {"hover": Color(.52, .40, .19), "pressed": Color(.34, .26, .12), "hover_pressed": Color(.34, .26, .12)}.get(state, Color(.42, .32, .15))
		var face := box(fill, GOLD if state == "normal" else GOLD_PALE, 1, 4, 14, 6)
		if state == "focus": face = box(Color.TRANSPARENT, GOLD_PALE, 1, 4, 14, 6)
		theme.set_stylebox(state, "GuidePrimary", face)
	for entry in [["font_color", IVORY], ["font_hover_color", Color.WHITE], ["font_pressed_color", GOLD_PALE], ["font_hover_pressed_color", GOLD_PALE], ["font_focus_color", IVORY], ["icon_normal_color", IVORY], ["icon_hover_color", Color.WHITE], ["icon_pressed_color", GOLD_PALE], ["icon_hover_pressed_color", GOLD_PALE]]:
		theme.set_color(entry[0], "GuidePrimary", entry[1])
	theme.set_type_variation("GuideLink", "Button")
	theme.set_font_size("font_size", "GuideLink", 13)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, "GuideLink", box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 4, 6, 4))
	theme.set_stylebox("focus", "GuideLink", box(Color.TRANSPARENT, Color(GOLD_PALE, .9), 1, 4, 6, 4))
	for entry in [["font_color", MUTED], ["font_hover_color", GOLD_PALE], ["font_pressed_color", GOLD_PALE], ["font_hover_pressed_color", GOLD_PALE], ["font_focus_color", IVORY]]:
		theme.set_color(entry[0], "GuideLink", entry[1])
	# The Issues tab of the same card: filter pills with counts, and one card per warning with a severity edge (red
	# danger, amber warning, teal information). A transparent IssueCardButton lies over each whole card, so the card
	# lights up on hover/focus and any part of it opens the building. Tags list a warning's other conditions.
	for entry in [["Danger", Color(.98, .47, .37)], ["Warning", Color(.97, .76, .40)], ["Info", ACCENT]]:
		var tone: Color = entry[1]
		theme.set_type_variation("IssueCard" + entry[0], "PanelContainer")
		var issue := box(Color(.10, .12, .13, .95), Color(tone, .45), 1, 5, 0, 0)
		issue.border_width_left = 3
		theme.set_stylebox("panel", "IssueCard" + entry[0], issue)
		theme.set_type_variation("IssueStatus" + entry[0], "Label")
		theme.set_font("font", "IssueStatus" + entry[0], medium)
		theme.set_font_size("font_size", "IssueStatus" + entry[0], 13)
		theme.set_color("font_color", "IssueStatus" + entry[0], tone)
	theme.set_type_variation("IssueCardButton", "Button")
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var face := box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 5, 0, 0)
		if state == "hover": face = box(Color(1, 1, 1, .035), Color(GOLD, .6), 1, 5, 0, 0)
		elif state in ["pressed", "hover_pressed"]: face = box(Color(GOLD, .08), GOLD_PALE, 1, 5, 0, 0)
		elif state == "focus": face = box(Color.TRANSPARENT, Color(GOLD_PALE, .9), 1, 5, 0, 0)
		theme.set_stylebox(state, "IssueCardButton", face)
	theme.set_type_variation("IssueName", "Label")
	theme.set_font("font", "IssueName", bold)
	theme.set_font_size("font_size", "IssueName", 15)
	theme.set_color("font_color", "IssueName", IVORY)
	theme.set_type_variation("IssueAdvice", "Label")
	theme.set_font_size("font_size", "IssueAdvice", 13)
	theme.set_color("font_color", "IssueAdvice", Color(IVORY, .74))
	theme.set_constant("line_spacing", "IssueAdvice", 2)
	theme.set_type_variation("IssueTag", "PanelContainer")
	theme.set_stylebox("panel", "IssueTag", box(Color(1, 1, 1, .04), Color(MUTED, .35), 1, 9, 7, 1))
	theme.set_type_variation("IssueTagText", "Label")
	theme.set_font_size("font_size", "IssueTagText", 12)
	theme.set_color("font_color", "IssueTagText", MUTED)
	theme.set_type_variation("IssueFilter", "Button")
	theme.set_font_size("font_size", "IssueFilter", 13)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var chosen: bool = state in ["pressed", "hover_pressed"]
		var pill := box(Color(.24, .21, .15) if chosen else (Color(.16, .19, .21) if state == "hover" else Color.TRANSPARENT), Color(GOLD, .75) if chosen else (Color(GOLD_PALE, .9) if state == "focus" else Color(GOLD, .22 if state != "disabled" else .1)), 1, 12, 10, 3)
		if state == "focus": pill.bg_color = Color.TRANSPARENT
		theme.set_stylebox(state, "IssueFilter", pill)
	for entry in [["font_color", MUTED], ["font_hover_color", IVORY], ["font_pressed_color", GOLD_PALE], ["font_hover_pressed_color", GOLD_PALE], ["font_focus_color", IVORY], ["font_disabled_color", Color(MUTED, .45)]]:
		theme.set_color(entry[0], "IssueFilter", entry[1])
	theme.set_type_variation("LoadingScreen", "Control")
	theme.set_color("background", "LoadingScreen", Color("101b24"))
	theme.set_color("track", "LoadingScreen", Color("30404a"))
	theme.set_color("still_activity", "LoadingScreen", Color("b99a62"))
	theme.set_color("activity", "LoadingScreen", Color("dec08a"))
	# Focused updates preserve unrelated authored Theme items in the working tree.
	# Add -- --decisions-only to refresh only the correspondence styles, or -- --guide-only for the city help card's
	# (its Guide* and Issue* variations).
	var focused: Array = []
	if OS.get_cmdline_user_args().has("--decisions-only"):
		focused = ["DecisionCard", "EnvoyPaper", "EnvoyPortrait", "EnvoyBody", "EnvoyCityName", "EnvoyTitleButton", "EnvoyAction", "EnvoyPrimary"]
	elif OS.get_cmdline_user_args().has("--guide-only"):
		focused = Array(theme.get_type_list()).filter(func(kind): return str(kind).begins_with("Guide") or str(kind).begins_with("Issue"))
	if not focused.is_empty():
		var current: Theme = load(OUTPUT).duplicate(true)
		if OS.get_cmdline_user_args().has("--guide-only"):
			for kind in current.get_type_list():
				if str(kind).begins_with("Guide") or str(kind).begins_with("Issue"): current.remove_type(kind)
		for kind in focused:
			current.set_type_variation(kind, theme.get_type_variation_base(kind))
			for item in theme.get_property_list():
				var name := str(item.name)
				if name.begins_with(kind + "/"): current.set(name, theme.get(name))
		theme = current
	var error := ResourceSaver.save(theme, OUTPUT)
	print("THEME saved ", OUTPUT, " result=", error)
	quit(0 if error == OK else 1)
