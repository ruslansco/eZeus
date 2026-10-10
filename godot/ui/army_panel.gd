extends PanelContainer
# The army panel: the companies (banners) of the city with their size and whether they are called out, orders for all of
# them or one, and the way to move a banner. The companies themselves, their tiles and their soldiers are the core's;
# this panel only lists what the snapshot says and sends the orders.
signal closed
signal selection_changed(id: int)
signal order(command: String)
signal go_to(cell: Vector2i)
signal place_requested(id: int)

const ArmyView = preload("res://scripts/army_view.gd")
const HoverHelp = preload("res://ui/hover_help.gd")

class CompanyRow extends Button:
	func _make_custom_tooltip(text: String) -> Object:
		var parts := text.split("\n", true, 1)
		return HoverHelp.build(parts[0], parts[1] if parts.size() > 1 else "", self)

@onready var title: Label = %ArmyTitle
@onready var close_button: Button = %ArmyClose
@onready var summary: Label = %ArmySummary
@onready var call_all: Button = %CallAll
@onready var home_all: Button = %HomeAll
@onready var list: VBoxContainer = %ArmyList
@onready var empty: Label = %ArmyEmpty
@onready var detail: PanelContainer = %ArmyDetail
@onready var detail_name: Label = %DetailName
@onready var detail_info: Label = %DetailInfo
@onready var go_button: Button = %DetailGo
@onready var toggle_button: Button = %DetailToggle
@onready var place_button: Button = %DetailPlace
@onready var frame: VBoxContainer = %ArmyFrame
@onready var header: HBoxContainer = %ArmyHeader
@onready var content: ScrollContainer = %ArmyContent
@onready var column: VBoxContainer = %ArmyColumn

var banners: Array = []
var per_banner := 8
var selected_id := -1
var placing := false
var group := ButtonGroup.new()
var rows: Dictionary = {}
var swatches: Dictionary = {}
var host_bounds := Rect2()
var fit_queued := false

func _ready() -> void:
	close_button.pressed.connect(func(): close())
	call_all.pressed.connect(func(): order.emit("army_call"))
	home_all.pressed.connect(func(): order.emit("army_home"))
	go_button.pressed.connect(func():
		var banner := selected_banner()
		if not banner.is_empty():
			go_to.emit(Vector2i(int(banner.x), int(banner.y))))
	toggle_button.pressed.connect(func():
		var banner := selected_banner()
		if banner.is_empty():
			return
		order.emit(("banner_call %d" if bool(banner.home) else "banner_home %d") % int(banner.id)))
	place_button.pressed.connect(func():
		if selected_id >= 0:
			place_requested.emit(selected_id))
	group.allow_unpress = false
	column.minimum_size_changed.connect(queue_fit)
	header.minimum_size_changed.connect(queue_fit)
	retranslate()

func open() -> void:
	visible = true
	refresh()
	queue_fit()

func close() -> void:
	visible = false
	set_placing(false)
	closed.emit()

func set_banners(list_value: Array, per: int) -> void:
	banners = list_value
	per_banner = per
	if selected_id >= 0 and selected_banner().is_empty():
		selected_id = -1
	if visible:
		refresh()

func selected_banner() -> Dictionary:
	for banner in banners:
		if int(banner.id) == selected_id:
			return banner
	return {}

func select(id: int, announce := true) -> void:
	selected_id = id
	if visible:
		refresh()
		reveal_detail.call_deferred()
	if announce:
		selection_changed.emit(id)

func reveal_detail() -> void:
	if visible and detail.visible:
		content.ensure_control_visible(detail)

func set_placing(value: bool) -> void:
	placing = value
	if place_button != null:
		place_button.text = tr("Click the ground…") if placing else tr("Place banner")
		if not place_button.disabled:
			place_button.tooltip_text = place_button.text

# Bounds are logical HUD coordinates. The host reserves its actual header and dock,
# rather than this panel assuming the old fixed 72 / 180 pixel margins.
func fit_host(bounds: Rect2) -> void:
	host_bounds = bounds
	if not is_node_ready() or not visible:
		return
	var width := minf(maxf(bounds.size.x * .32, 388.0), minf(440.0, maxf(0, bounds.size.x)))
	anchor_left = 0; anchor_right = 0; anchor_top = 0; anchor_bottom = 0
	position = Vector2(bounds.end.x - width, bounds.position.y)
	size.x = width
	for row in rows.values():
		row.custom_minimum_size.y = maxf(56, row.get_theme_font("font").get_height(row.get_theme_font_size("font_size")) * 2 + row.get_theme_stylebox("normal").get_minimum_size().y)
	var margins := get_theme_stylebox("panel").get_minimum_size().y
	var wanted := header.get_combined_minimum_size().y + column.get_combined_minimum_size().y + frame.get_theme_constant("separation") + margins
	size.y = minf(maxf(0, bounds.size.y), maxf(180, wanted))

func queue_fit() -> void:
	if fit_queued: return
	fit_queued = true
	apply_fit.call_deferred()

func apply_fit() -> void:
	fit_queued = false
	if host_bounds.has_area(): fit_host(host_bounds)

func clean_name(text: String) -> String:
	return text.strip_edges().trim_prefix("\"").trim_suffix("\"")

func status_text(banner: Dictionary) -> String:
	if bool(banner.abroad):
		return tr("helping another city") if bool(banner.aid) else tr("abroad")
	if bool(banner.fighting):
		return tr("fighting")
	return tr("at the palace") if bool(banner.home) else tr("called out")

func swatch(kind: String) -> Texture2D:
	if not swatches.has(kind):
		var image := Image.create(10, 38, false, Image.FORMAT_RGBA8)
		image.fill(ArmyView.KIND_COLORS.get(kind, Color(.5, .5, .5)))
		swatches[kind] = ImageTexture.create_from_image(image)
	return swatches[kind]

func row_text(banner: Dictionary) -> String:
	return "%s\n%s  ·  %s  ·  %s" % [clean_name(str(banner.name)), str(banner.kind_name), tr("%d of %d") % [int(banner.count), per_banner], status_text(banner)]

func refresh() -> void:
	var soldiers := 0
	var out := 0
	for banner in banners:
		soldiers += int(banner.count)
		if not bool(banner.home) and not bool(banner.abroad):
			out += int(banner.count)
	empty.visible = banners.is_empty()
	summary.visible = not banners.is_empty()
	summary.text = tr("%d companies, %d soldiers, %d called out") % [banners.size(), soldiers, out]
	call_all.disabled = banners.is_empty()
	home_all.disabled = banners.is_empty()
	call_all.tooltip_text = tr("Call all out") + ("\n" + tr("No companies are available") if call_all.disabled else "")
	home_all.tooltip_text = tr("Send all home") + ("\n" + tr("No companies are available") if home_all.disabled else "")
	var alive := {}
	for banner in banners:
		var id := int(banner.id)
		alive[id] = true
		var row: Button = rows.get(id)
		if row == null:
			row = CompanyRow.new()
			row.toggle_mode = true
			row.button_group = group
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.focus_mode = Control.FOCUS_NONE
			row.custom_minimum_size = Vector2(0, 56)
			row.clip_text = true
			row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row.expand_icon = false
			row.pressed.connect(func(): select(id))
			list.add_child(row)
			rows[id] = row
		row.icon = swatch(str(banner.type))
		row.text = row_text(banner)
		row.tooltip_text = row.text
		row.set_pressed_no_signal(id == selected_id)
	for id in rows.keys():
		if not alive.has(id):
			rows[id].queue_free()
			rows.erase(id)
	# Keep the list in the core's order.
	for index in banners.size():
		list.move_child(rows[int(banners[index].id)], index)
	var banner := selected_banner()
	detail.visible = not banner.is_empty()
	if not banner.is_empty():
		detail_name.text = clean_name(str(banner.name))
		detail_info.text = "%s\n%s" % [str(banner.kind_name), status_text(banner)]
		toggle_button.text = tr("Call out") if bool(banner.home) else tr("Send home")
		var movable := not bool(banner.abroad)
		toggle_button.disabled = bool(banner.abroad) and not bool(banner.aid)
		place_button.disabled = not movable
		go_button.disabled = not bool(banner.get("placed", false))
		toggle_button.tooltip_text = toggle_button.text + ("\n" + tr("This company is abroad and cannot be called out or sent home") if toggle_button.disabled else "")
		place_button.tooltip_text = place_button.text + ("\n" + tr("This company is abroad and its banner cannot be moved") if place_button.disabled else "")
		go_button.tooltip_text = tr("Go to") + ("\n" + tr("This company has no banner placed on the map") if go_button.disabled else "")
	queue_fit()

func retranslate() -> void:
	if title == null:
		return
	title.text = tr("Army")
	close_button.text = ""
	close_button.icon = preload("res://ui/icons/close.svg")
	close_button.tooltip_text = tr("Close")
	empty.text = tr("The city has no soldiers yet. Once the palace stands, well-built houses supply them: common houses rock throwers, elite houses with arms hoplites, and with horses also horsemen.")
	call_all.text = tr("Call all out")
	home_all.text = tr("Send all home")
	go_button.text = tr("Go to")
	set_placing(placing)
	refresh()
