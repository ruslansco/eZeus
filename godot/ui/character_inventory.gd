extends VBoxContainer
# Read-only cargo / the peddler's own agora stock. Counts never refresh speech.
const Goods = preload("res://scripts/goods.gd")
var heading := Label.new()
var source := Label.new()
var grid := GridContainer.new()
var empty := Label.new()
var rows := {}
var layout_key := ""
var data: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	heading.theme_type_variation = "ToolHeading"; add_child(heading)
	source.theme_type_variation = "Detail"
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(source)
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8); add_child(grid)
	empty.theme_type_variation = "Caption"
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; add_child(empty)
	visible = false

func show_inventory(value: Variant) -> void:
	visible = value is Dictionary and not value.is_empty()
	if not visible: data = {}; return
	data = value
	var agora: bool = value.get("kind", "") == "agora"
	heading.text = tr("Supplies") if agora else tr("Cargo")
	source.text = tr("Supplies from %s") % str(value.get("source", "")) if agora and value.get("available", false) else ""
	source.visible = not source.text.is_empty()
	var items: Array = value.get("items", [])
	var next_key := str(value.get("kind", "")) + str(items.map(func(item): return int(item.resource)))
	if layout_key != next_key:
		layout_key = next_key; rows.clear()
		for child in grid.get_children(): grid.remove_child(child); child.queue_free()
		for item in items: build_tile(int(item.resource))
	grid.visible = not items.is_empty() and (not agora or value.get("available", false))
	empty.visible = not grid.visible
	empty.text = tr("No Agora available") if agora else tr("No goods carried")
	for item in items:
		var row: Dictionary = rows[int(item.resource)]
		var present: bool = item.get("present", true)
		var count := int(item.get("count", 0))
		row.count.text = "%d / %d" % [count, int(item.get("capacity", 0))] if agora and present else ("—" if not present else str(count))
		row.status.text = (tr("Distributing") if count > 0 else tr("No goods")) if present else tr("No vendor")
		if not agora: row.status.text = tr("Cargo loads") if value.get("unit", "") == "loads" else tr("Collected")
		row.status.theme_type_variation = "CharacterStockGood" if count > 0 and present else "CharacterStockMuted"
		row.tile.theme_type_variation = "CharacterStockTile" if count > 0 and present else "CharacterEmptyTile"

func build_tile(resource: int) -> void:
	var tile := PanelContainer.new(); tile.theme_type_variation = "CharacterStockTile"
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 3); tile.add_child(column)
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 6); column.add_child(head)
	var icon := TextureRect.new(); icon.texture = Goods.icon_of(resource)
	icon.custom_minimum_size = Vector2(24, 24); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; head.add_child(icon)
	var label := Label.new()
	label.text = tr("Food") if resource == 255 else tr("Arms") if resource == 65536 and data.get("kind", "") == "agora" else Goods.name_of(resource)
	label.theme_type_variation = "Detail"; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_PASS; label.tooltip_text = label.text; head.add_child(label)
	var count := Label.new(); count.theme_type_variation = "ToolHeading"; column.add_child(count)
	var status := Label.new(); status.theme_type_variation = "CharacterStockMuted"
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; column.add_child(status)
	grid.add_child(tile); rows[resource] = {"tile":tile,"count":count,"status":status}
