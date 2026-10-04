extends VBoxContainer
# Read-only summary of inspect observations. The editor below retains its token and unfinished drafts.
signal overlay_selected(id: String)
const STATUS={"operational":"Operational","on_fire":"On fire","industry_paused":"Industry paused",
	"no_workers":"No workers","no_road":"No road access","waiting_input":"Waiting for raw materials","no_target":"No resource to collect",
	"staffed":"Staffed","understaffed":"Understaffed","vacant":"Vacant housing","housing":"Occupied housing","building":"City building"}
const NEEDS=["Food","Water","Fleece","Olive oil","Arms","Wine","Horses","Culture / science","Appeal"]
var status_id:=""
var status: Label
var cause: Label
var metrics: Dictionary={}
var grid: GridContainer
var needs: Label
var views: HFlowContainer
var value: Dictionary={}

func _ready() -> void:
	add_theme_constant_override("separation",10)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(status)
	cause=Label.new();cause.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;cause.theme_type_variation="Caption";add_child(cause)
	grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",8);add_child(grid)
	for key in ["road","workers","maintenance","residents"]:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var caption:=Label.new();caption.theme_type_variation="Detail";caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(caption)
		var reading:=Label.new();reading.theme_type_variation="ToolHeading";reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(reading)
		grid.add_child(column);metrics[key]={"column":column,"caption":caption,"reading":reading}
	needs=Label.new();needs.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;needs.theme_type_variation="Caption";add_child(needs)
	views=HFlowContainer.new();add_child(views)

func state_for(data: Dictionary) -> String:
	if data.get("on_fire",false):return "on_fire"
	if data.has("production"):return str(data.production.status)
	if data.get("shut_down",false):return "industry_paused"
	if int(data.get("max_employees",0))>0:
		if int(data.employees)==0:return "no_workers"
		if not data.get("road_access",true):return "no_road"
		return "understaffed" if int(data.employees)<int(data.max_employees) else "staffed"
	if data.has("residents"):return "vacant" if int(data.residents)==0 else "housing"
	return "building"

func show_data(data: Dictionary) -> void:
	visible=data.has("footprint")
	if not visible:return
	var shape:=hash([data.get("target_token",0),TranslationServer.get_locale(),data.has("production"),data.has("storage"),data.has("residents")])
	if shape!=hash([value.get("target_token",-1),value.get("locale",""),value.has("production"),value.has("storage"),value.has("residents")]):
		for child in views.get_children():child.free()
		var links: Array=[["roads","Road network"],["hazards","Fire and collapse risk"]]
		if data.has("residents"):links=[["supplies","Food and housing supplies"],["water","Water and fountains"],["hygiene","Hygiene and health"]]
		elif data.has("production"):links.push_front(["industry","Industry"])
		elif data.has("storage"):links.push_front(["distribution","Storage and trade"])
		for link in links:
			var button:=Button.new();button.text=tr(link[1]);button.theme_type_variation="Quiet";button.focus_mode=Control.FOCUS_NONE
			button.pressed.connect(func():overlay_selected.emit(link[0]));views.add_child(button)
	value=data.duplicate();value.locale=TranslationServer.get_locale()
	status_id=state_for(data)
	status.text=tr(STATUS.get(status_id,"Building status"))
	status.theme_type_variation="DangerStatus" if status_id=="on_fire" else ("WarningStatus" if status_id in ["industry_paused","no_workers","no_road","waiting_input","no_target","understaffed"] else "GoodStatus")
	if status_id=="building":status.theme_type_variation="NeutralStatus"
	cause.text = ""
	if status_id in ["understaffed", "no_workers"]:
		cause.text = tr("Fill %d vacant jobs to reach full staffing.") % maxi(0,int(data.get("max_employees",0))-int(data.get("employees",0)))
	elif status_id == "no_road": cause.text = tr("Connect this building to the road network.")
	elif status_id == "industry_paused": cause.text = tr("This industry is paused city-wide. Resume it in the production controls.")
	elif status_id == "waiting_input": cause.text = tr("Check the native recipe and available inputs below.")
	elif data.has("residents"):
		var vacancies := maxi(0,int(data.get("capacity",0))-int(data.get("residents",0)))
		if vacancies > 0: cause.text = tr("Space for %d more residents.") % vacancies
	cause.visible = not cause.text.is_empty()
	metric("road",tr("Road access"),tr("Connected") if data.road_access else tr("Not connected"))
	metric("maintenance",tr("Maintenance"),"%d%%"%int(data.maintenance))
	metric("workers",tr("Workers"),"%d / %d"%[int(data.get("employees",0)),int(data.get("max_employees",0))],int(data.get("max_employees",0))>0)
	metric("residents",tr("Residents"),"%d / %d"%[int(data.get("residents",0)),int(data.get("capacity",0))],data.has("residents"))
	needs.visible=data.has("residents")
	if needs.visible:
		var missing: Array[String]=[]
		for need in data.missing:
			if int(need)>=0 and int(need)<NEEDS.size():missing.append(tr(NEEDS[int(need)]))
		var level: String=tr("Level %d  ·  Next level %d")%[int(data.level),int(data.target_level)] if int(data.target_level)>int(data.level) else tr("Level %d")%int(data.level)
		needs.text=level+"\n"+(tr("Needs are met") if missing.is_empty() else tr("Needed: %s")%", ".join(missing))

func metric(key: String, caption: String, reading: String, shown:=true) -> void:
	metrics[key].column.visible=shown
	metrics[key].caption.text=caption;metrics[key].reading.text=reading
