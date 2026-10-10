extends VBoxContainer
# Read-only summary of inspect observations. The editor below retains its token and unfinished drafts.
signal overlay_selected(id: String)
const STATUS={"operational":"Operational","on_fire":"On fire","industry_paused":"Industry paused",
	"no_workers":"No workers","no_road":"No road access","waiting_input":"Waiting for raw materials","no_target":"No resource to collect",
	"staffed":"Staffed","understaffed":"Understaffed","vacant":"Vacant housing","housing":"Occupied housing","building":"City building","ruin":"Ruins"}
const NEEDS=["Food","Water","Fleece","Olive oil","Arms","Wine","Horses","Culture / science","Appeal"]
var status_id:=""
var status: Label
var cause: Label
var metrics: Dictionary={}
var grid: GridContainer
var needs: Label
var views: HFlowContainer
var value: Dictionary={}
const Goods=preload("res://scripts/goods.gd")
const Guidance=preload("res://ui/city_guidance.gd")
const TONE={"on_fire":Color(.98,.47,.37),"warn":Color(.97,.76,.40),"good":Color(.55,.83,.66),"neutral":Color(.58,.64,.72)}
# The house's own page (level, residents, each need ticked or crossed): the core's `house` card, shown for a house someone lives in.
var status_card: PanelContainer
var house_box: VBoxContainer
var house_signature:=""

func _ready() -> void:
	add_theme_constant_override("separation",10)
	# The state of the building as a tinted card with an accent bar on the left; its colour follows the state.
	status_card=PanelContainer.new();add_child(status_card)
	var card_column:=VBoxContainer.new();card_column.add_theme_constant_override("separation",3);status_card.add_child(card_column)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card_column.add_child(status)
	cause=Label.new();cause.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cause.theme_type_variation="Caption";card_column.add_child(cause)
	grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);add_child(grid)
	for key in ["road","workers","maintenance","residents"]:
		# Each reading sits in a small chip.
		var column:=PanelContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_theme_stylebox_override("panel",chip_style())
		var inner:=VBoxContainer.new();inner.add_theme_constant_override("separation",0);column.add_child(inner)
		var caption:=Label.new();caption.theme_type_variation="Detail";caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inner.add_child(caption)
		var reading:=Label.new();reading.theme_type_variation="ToolHeading";reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inner.add_child(reading)
		grid.add_child(column);metrics[key]={"column":column,"caption":caption,"reading":reading}
	needs=Label.new();needs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;needs.theme_type_variation="Caption";add_child(needs)
	house_box=VBoxContainer.new();house_box.add_theme_constant_override("separation",4);house_box.visible=false;add_child(house_box)
	views=HFlowContainer.new();views.add_theme_constant_override("h_separation",6);views.add_theme_constant_override("v_separation",6);add_child(views)

static func chip_style() -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color(.04,.08,.12,.6);box.border_color=Color(.45,.55,.68,.25);box.set_border_width_all(1);box.set_corner_radius_all(6)
	box.content_margin_left=10;box.content_margin_right=8;box.content_margin_top=5;box.content_margin_bottom=6
	return box

static func alert_chip_style() -> StyleBoxFlat:
	var box:=chip_style()
	box.bg_color=Color(TONE.on_fire,.12);box.border_color=Color(TONE.on_fire,.7)
	return box

static func status_style(tint: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color(tint,.10);box.border_color=tint;box.border_width_left=4;box.set_corner_radius_all(6)
	box.content_margin_left=12;box.content_margin_right=10;box.content_margin_top=7;box.content_margin_bottom=8
	return box

func state_for(data: Dictionary) -> String:
	if data.get("on_fire",false):return "on_fire"
	if data.has("ruin"):return "ruin"
	if data.has("production"):
		var native_status: String=str(data.production.status)
		if native_status!="operational":return native_status
		if int(data.get("max_employees",0))>int(data.get("employees",0)):return "understaffed"
		for output in data.production.get("outputs",[]):
			if int(output.get("overflow",0))>0 or (int(output.get("capacity",0))>0 and int(output.get("count",0))>=int(output.capacity)):return "waiting_dispatch"
		return native_status
	if data.get("shut_down",false):return "industry_paused"
	if int(data.get("max_employees",0))>0:
		if int(data.employees)==0:return "no_workers"
		if not data.get("road_access",true):return "no_road"
		return "understaffed" if int(data.employees)<int(data.max_employees) else "staffed"
	if data.has("residents"):
		if int(data.get("supported_level",data.get("level",0)))<int(data.get("level",0)) and int(data.residents)>0:return "housing_decline"
		if not data.get("road_access",true):return "no_road"
		return "vacant" if int(data.residents)==0 else "housing"
	return "building"

func show_data(data: Dictionary) -> void:
	visible=data.has("footprint")
	if not visible:return
	var shape:=hash([data.get("target_token",0),TranslationServer.get_locale(),data.has("production"),data.has("storage"),data.has("residents"),data.has("ruin")])
	if shape!=hash([value.get("target_token",-1),value.get("locale",""),value.has("production"),value.has("storage"),value.has("residents"),value.has("ruin")]):
		for child in views.get_children():child.free()
		var links: Array=[["roads","Road network"],["hazards","Fire and collapse risk"]]
		if data.has("residents"):links=[["supplies","Food and housing supplies"],["water","Water and fountains"],["hygiene","Hygiene and health"]]
		elif data.has("production"):links.push_front(["industry","Industry"])
		elif data.has("storage"):links.push_front(["distribution","Storage and trade"])
		if data.has("ruin"):links=[]
		for link in links:
			var button:=Button.new();button.text=tr(link[1]);button.theme_type_variation="Quiet";button.focus_mode=Control.FOCUS_NONE
			button.pressed.connect(func():overlay_selected.emit(link[0]));views.add_child(button)
	value=data.duplicate();value.locale=TranslationServer.get_locale()
	grid.visible=not data.has("ruin")
	views.visible=not data.has("ruin")
	# The wide pages (stores, agoras, houses) put the readings in one row to leave room for their tables.
	grid.columns=3 if (data.has("storage") or data.has("trade") or data.has("agora") or data.has("house")) else 2
	status_id=state_for(data)
	status.text=tr(STATUS.get(status_id,Guidance.TITLES.get(status_id,"Building status")))
	status.theme_type_variation="DangerStatus" if status_id=="on_fire" else ("WarningStatus" if status_id in ["industry_paused","no_workers","no_road","waiting_input","no_target","waiting_dispatch","understaffed","housing_decline"] else "GoodStatus")
	if status_id in ["building","ruin"]:status.theme_type_variation="NeutralStatus"
	var tone:="on_fire" if status_id=="on_fire" else ("warn" if status.theme_type_variation=="WarningStatus" else ("neutral" if status_id in ["building","ruin"] else "good"))
	status_card.add_theme_stylebox_override("panel",status_style(TONE[tone]))
	cause.text = ""
	if data.has("ruin"): cause.text = tr("A burning building cannot be demolished") if data.on_fire else tr("Clear the rubble to build here again.")
	var advice := Guidance.advice(data,status_id)
	if not advice.is_empty(): cause.text=advice
	elif data.has("residents"):
		var vacancies := maxi(0,int(data.get("capacity",0))-int(data.get("residents",0)))
		if vacancies > 0: cause.text = tr("Space for %d more residents.") % vacancies
	cause.visible = not cause.text.is_empty()
	# A building on the road network needs no word about it; only one cut off from the roads gets the chip.
	metric("road",tr("Road access"),tr("Not connected"),not data.road_access and not data.has("ruin"))
	metrics.road.column.add_theme_stylebox_override("panel",alert_chip_style() if not data.road_access else chip_style())
	metrics.road.reading.add_theme_color_override("font_color",TONE.on_fire if not data.road_access else Color(.93,.89,.82))
	metric("maintenance",tr("Maintenance"),"%d%%"%int(data.maintenance),not data.has("ruin"))
	metric("workers",tr("Workers"),"%d / %d"%[int(data.get("employees",0)),int(data.get("max_employees",0))],int(data.get("max_employees",0))>0)
	metric("residents",tr("Residents"),"%d / %d"%[int(data.get("residents",0)),int(data.get("capacity",0))],data.has("residents"))
	var card:Dictionary=data.get("house",{})
	needs.visible=data.has("residents") and card.is_empty()
	fill_house(card)
	if needs.visible:
		var missing: Array[String]=[]
		for need in data.missing:
			if int(need)>=0 and int(need)<NEEDS.size():missing.append(tr(NEEDS[int(need)]))
		var level: String=tr("Level %d  ·  Next level %d")%[int(data.level),int(data.target_level)] if int(data.target_level)>int(data.level) else tr("Level %d")%int(data.level)
		needs.text=level+"\n"+(tr("Needs are met") if missing.is_empty() else tr("Needed: %s")%", ".join(missing))

func metric(key: String, caption: String, reading: String, shown:=true) -> void:
	metrics[key].column.visible=shown
	metrics[key].caption.text=caption;metrics[key].reading.text=reading

# How to supply each need, in a sentence (by the card line's good or panel icon).
func hint_for(need: Dictionary) -> String:
	var resource:=int(need.resource)
	match str(need.icon):
		"water": return tr("A fountain or well that covers this house.")
		"science","culture": return tr("Staff the required venues and connect their walkers to this house's road. The missing venue types are listed below.")
		"aesthetics": return tr("Plant gardens, statues or fountains nearby, and keep industry and storage away.")
	match resource:
		255: return tr("Food from an agora food stall whose walker reaches this house.")
		4096: return tr("A fleece vendor in an agora that reaches this house.")
		2048: return tr("An olive oil vendor in an agora that reaches this house.")
		1024: return tr("A wine vendor in an agora that reaches this house.")
		65536: return tr("An arms vendor in an agora that reaches this house.")
		1048576: return tr("A horse vendor in an agora that reaches this house.")
	return ""

# The house's level (pips), its residents, the state of its needs, then what is still needed for the next level (each with how to
# supply it) above what is already met.
func fill_house(card: Dictionary) -> void:
	house_box.visible=not card.is_empty()
	if card.is_empty():
		house_signature="";return
	var signature:=JSON.stringify([card,TranslationServer.get_locale()])
	if signature==house_signature:return
	house_signature=signature
	for child in house_box.get_children():
		house_box.remove_child(child);child.queue_free()
	var rule:=HSeparator.new();house_box.add_child(rule)
	var head:=HBoxContainer.new();house_box.add_child(head)
	var name:=Label.new();name.text=str(card.name).left(1).to_upper()+str(card.name).substr(1);name.theme_type_variation="Subheading"
	name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;head.add_child(name)
	var pips:="";for index in int(card.levels):pips+="◆" if index<=int(card.level) else "◇"
	var pip_label:=Label.new();pip_label.text=pips;pip_label.add_theme_color_override("font_color",Color(1.0,.87,.55));head.add_child(pip_label)
	var residents:=Label.new();residents.text=str(card.residents);residents.theme_type_variation="Detail";house_box.add_child(residents)
	var tone:=int(card.tone)
	var lines: Array=card.lines
	var missing:=lines.filter(func(need):return not bool(need.met))
	var done:=lines.filter(func(need):return bool(need.met))
	var target:String=str(card.get("target_name",""))
	target=target.left(1).to_upper()+target.substr(1)
	# The state in a line: improving, declining or the finest.
	if lines.is_empty():
		var state:=Label.new();state.text=str(card.status);state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		state.add_theme_color_override("font_color",Color(.50,.84,.57) if tone==2 else Color(.93,.89,.82));house_box.add_child(state)
		return
	var heading:=Label.new();heading.theme_type_variation="ToolHeading";heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if tone==1:heading.text=tr("Needed to keep this level");heading.add_theme_color_override("font_color",Color(.94,.38,.29))
	elif missing.is_empty():heading.text=tr("%s: every need is met") % target;heading.add_theme_color_override("font_color",Color(.50,.84,.57))
	else:heading.text=tr("To reach %s") % target
	house_box.add_child(heading)
	var progress:=Label.new();progress.theme_type_variation="Caption"
	progress.text=tr("%d of %d needs met") % [done.size(),lines.size()]
	house_box.add_child(progress)
	for need in missing:
		house_box.add_child(need_block(need,false))
	if not done.is_empty():
		var met_heading:=Label.new();met_heading.theme_type_variation="Detail";met_heading.text=tr("Already met")
		house_box.add_child(met_heading)
		for need in done:
			house_box.add_child(need_block(need,true))

# One need: a tick or cross, its drawing, name and reading; a missing one also says how to supply it.
func need_block(need: Dictionary, met: bool) -> Control:
	var block:=VBoxContainer.new();block.add_theme_constant_override("separation",1)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);block.add_child(line)
	var mark:=Label.new();mark.text="✓" if met else "✗";mark.add_theme_color_override("font_color",Color(.50,.84,.57) if met else Color(.94,.38,.29));line.add_child(mark)
	var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(20,20);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture=Goods.icon_of(int(need.resource)) if int(need.resource)>0 else panel_icon(str(need.icon))
	icon.modulate=Color(1,1,1,.7 if met else 1.0)
	line.add_child(icon)
	var label:=Label.new();label.text=str(need.label);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",Color(.75,.77,.81) if met else Color(.96,.94,.89));line.add_child(label)
	if not str(need.detail).is_empty():
		var detail:=Label.new();detail.text=str(need.detail);detail.add_theme_color_override("font_color",Color(.61,.67,.77) if met else Color(1.0,.75,.43));line.add_child(detail)
	if not met:
		var advice:=hint_for(need)
		if str(need.icon)=="aesthetics":
			advice=tr("Surroundings must rise above the number shown. ")+advice
		if not str(need.note).is_empty():advice=(advice+" " if advice!="" else "")+str(need.note)
		if advice!="":
			var note:=Label.new();note.text=advice.strip_edges();note.theme_type_variation="Caption";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var margin:=MarginContainer.new();margin.add_theme_constant_override("margin_left",34);margin.add_child(note);block.add_child(margin)
	elif not str(need.note).is_empty():
		pass
	return block

# The HUD's own drawings for the needs that are not goods (water, culture, science, aesthetics).
func panel_icon(name: String) -> Texture2D:
	var file:="gardens" if name=="aesthetics" else name
	var path:="res://ui/icons/%s.svg"%file
	return load(path) if file!="" and ResourceLoader.exists(path) else null
