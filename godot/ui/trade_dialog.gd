extends AcceptDialog
# The trade partners of the city: every city a trade post could serve, how it is reached (land or sea), whether a post
# stands there, and the goods it sells and buys with their prices and this year's quota. It is the part of the SDL world
# map a trader needs; opening a post is done from the Build menu.

const Goods = preload("res://scripts/goods.gd")

static func open(parent: Node, core: Node) -> Window:
	var dialog: Window = load("res://ui/trade_dialog.gd").new()
	parent.add_child(dialog)
	dialog.fill(core.query("trade_partners"))
	dialog.popup_centered(Vector2i(760, 560))
	return dialog

var partner_count := 0

func _ready() -> void:
	title = tr("Trade partners")
	ok_button_text = tr("Done")
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

func goods_line(list: Array) -> String:
	var parts: Array = []
	for item in list:
		parts.append("%s %d (%d/%d)" % [Goods.name_of(int(item.resource)), int(item.price), int(item.used), int(item.max)])
	return ", ".join(parts) if not parts.is_empty() else "—"

func fill(answer: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	var partners: Array = answer.get("partners", [])
	partner_count = partners.size()
	if partners.is_empty():
		var none := Label.new()
		none.text = tr("This city has no trade partners.")
		column.add_child(none)
		return
	for partner in partners:
		var card := PanelContainer.new()
		card.theme_type_variation = "Card"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)
		var heading := Label.new()
		heading.theme_type_variation = "Subheading"
		heading.text = "%s  —  %s" % [partner.name, tr("by sea") if partner.water else tr("by land")]
		box.add_child(heading)
		var status := Label.new()
		status.theme_type_variation = "Caption"
		if partner.has_post:
			status.text = tr("A trade post stands here.")
		elif partner.available:
			status.text = tr("No trade post yet: open one from the Build menu.")
		else:
			status.text = tr("A trade post cannot be opened now.")
		if not partner.trading:
			status.text += "  " + tr("Trade is stopped.")
		box.add_child(status)
		for section in [["sells", "Sells to you (price, this year / limit)"], ["buys", "Buys from you (price, this year / limit)"]]:
			var line := Label.new()
			line.text = tr(section[1]) + ": " + goods_line(partner[section[0]])
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.theme_type_variation = "Detail"
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(line)
