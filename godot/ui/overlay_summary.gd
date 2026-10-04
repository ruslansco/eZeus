extends VBoxContainer
# Legends and counts derive from the already-polled native overlay; this node never queries or changes the core.
signal overlay_selected(id: String)
const Overlays=preload("res://scripts/overlays.gd")
var mode:="normal"
var data: Dictionary={}
var title_label: Label
var legend: Label
var readings: Label
var key_row: HFlowContainer
var quick: Dictionary={}
var signature:=0
var header: HBoxContainer
var close_button: Button
var choices: HFlowContainer

func _ready() -> void:
	add_theme_constant_override("separation",10)
	header=HBoxContainer.new();add_child(header)
	title_label=Label.new();title_label.theme_type_variation="ToolHeading";title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title_label)
	close_button=Button.new();close_button.name="CloseView";close_button.icon=load("res://ui/icons/close.svg");close_button.theme_type_variation="Quiet";close_button.focus_mode=Control.FOCUS_NONE;close_button.tooltip_text=tr("Normal view")
	close_button.pressed.connect(func():overlay_selected.emit("normal"));header.add_child(close_button)
	var scroll:=ScrollContainer.new();scroll.name="ViewScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
	var body:=VBoxContainer.new();body.name="ViewBody";body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	legend=Label.new();legend.theme_type_variation="Caption";legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(legend)
	key_row=HFlowContainer.new();body.add_child(key_row)
	readings=Label.new();readings.theme_type_variation="Value";readings.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(readings)
	body.move_child(readings,0)
	choices=HFlowContainer.new();add_child(choices)
	for spec in [["water","Water"],["supplies","Supplies"],["hygiene","Health"],["hazards","Risks"],["roads","Roads"]]:
		var button:=Button.new();button.text=tr(spec[1]);button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE;button.theme_type_variation="Tool"
		button.tooltip_text=tr(Overlays.MODES[spec[0]][0]);button.pressed.connect(func():overlay_selected.emit(spec[0]));choices.add_child(button);quick[spec[0]]=button

func show_data(id: String, observations: Dictionary) -> void:
	mode=id;data=observations
	if mode=="normal":return
	title_label.text=tr(Overlays.MODES[mode][0])
	legend.text=tr(Overlays.MODES[mode][1])
	var wanted:=hash([mode,TranslationServer.get_locale(),supply_count()])
	if wanted!=signature:
		signature=wanted
		for child in key_row.get_children():child.free()
		for spec in legend_items():swatch(spec[0],tr(spec[1]))
	for id_key in quick:
		quick[id_key].button_pressed=id_key==mode
		quick[id_key].text=tr({"water":"Water","supplies":"Supplies","hygiene":"Health","hazards":"Risks","roads":"Roads"}[id_key])
		quick[id_key].tooltip_text=tr(Overlays.MODES[id_key][0])
	close_button.tooltip_text=tr("Normal view")
	readings.text=summary()

func supply_count() -> int:
	var count:=3
	for row in data.get("supplies",[]):count=maxi(count,int(row[2]))
	return count

func legend_items() -> Array:
	if mode=="water":return [[Overlays.SHORT,"Lowest coverage"],[Overlays.TONES[5],"Higher coverage"]]
	if mode=="taxes":return [[Overlays.TONES[1],"Taxes paid"],[Overlays.SHORT,"Taxes not paid"]]
	if mode in ["hazards","unrest"]:return [[Overlays.TONES[1],"Lower risk"],[Overlays.TONES[4],"Higher risk"]]
	if mode=="hygiene":return [[Overlays.TONES[4],"Poor health"],[Overlays.TONES[1],"Better health"]]
	if mode=="appeal":return [[Overlays.APPEAL[0],"Lower appeal"],[Overlays.APPEAL[-1],"Higher appeal"]]
	if mode=="supplies":
		var labels: Array=["Food","Fleece","Olive oil","Wine","Arms","Horses"]
		var out: Array=[[Overlays.SHORT,"Low stock"]]
		for index in supply_count():out.append([Overlays.SUPPLY_COLORS[index],labels[index]])
		return out
	if not data.get("columns",[]).is_empty():return [[Overlays.TONES[1],"Higher coverage"]]
	return []

func swatch(color: Color, caption: String) -> void:
	var row:=HBoxContainer.new()
	var patch:=ColorRect.new();patch.color=color;patch.custom_minimum_size=Vector2(12,12);patch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(patch)
	var label:=Label.new();label.text=caption;label.theme_type_variation="Detail";row.add_child(label);key_row.add_child(row)

func summary() -> String:
	if data.is_empty():return tr("Service readings unavailable")
	var rows: Array=data.get("columns",[])
	if mode=="supplies":
		var short:=0
		for row in data.get("supplies",[]):
			if int(row[1])!=(1<<int(row[2]))-1:short+=1
		return tr("Homes assessed: %d")%data.get("supplies",[]).size()+"\n"+tr("Low supplies: %d")%short
	if mode=="taxes":return tr("Homes assessed: %d")%rows.size()+"\n"+tr("Taxes not paid: %d")%rows.filter(func(row):return int(row[1])==0).size()
	if mode in ["hazards","unrest"]:return tr("Buildings flagged: %d")%rows.size()+"\n"+tr("Higher risk: %d")%rows.filter(func(row):return int(row[2])==4).size()
	if mode in ["water","hygiene","actors","athletes","philosophers","competitors","all_culture","astronomers","scholars","inventors","curators","all_science"]:
		return tr("Homes assessed: %d")%rows.size()+"\n"+tr("Lowest coverage: %d")%rows.filter(func(row):return int(row[1])==0).size()
	return tr("Buildings in this view: %d")%data.get("visible",[]).size()

func fit_height(available: float) -> void:
	var body: Control=get_node("ViewScroll/ViewBody")
	get_node("ViewScroll").custom_minimum_size.y=clampf(body.get_combined_minimum_size().y,40,maxf(40,available-header.get_combined_minimum_size().y-choices.get_combined_minimum_size().y-30))
