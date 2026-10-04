extends RefCounted
# The cities of the player's map, as the SDL view follows them: the district under the middle of the view is the city in
# view (`view_tile`), and the player's own city in view is the one the pages, the Build menu and the header follow. With
# more than one city of their own the player gets a menu beside the city's name that takes the camera to each; looking at a
# district no one owns shows its price and a Buy button (`buy_city`), as the SDL view's offer does. Attached at runtime so the
# HUD scene stays as it is.

const INTERVAL := .4
var city
var menu: MenuButton
var banner: PanelContainer
var banner_text: Label
var buy_button: Button
var cities: Array = []
var viewed := -1
var last_tile := Vector2i(99999, 99999)
var age := 0.0

func attach(main) -> void:
	city = main
	menu = MenuButton.new()
	menu.name = "CitySwitch"
	menu.flat = true
	menu.visible = false
	menu.focus_mode = Control.FOCUS_NONE
	menu.get_popup().id_pressed.connect(go_to)
	var plaque: Node = city.hud.get_node("%CityName").get_parent()
	plaque.add_child(menu)
	banner = PanelContainer.new()
	banner.name = "CityForSale"
	banner.visible = false
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-220, 64)
	banner.custom_minimum_size = Vector2(440, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	banner.add_child(row)
	banner_text = Label.new()
	banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(banner_text)
	buy_button = Button.new()
	buy_button.name = "BuyCity"
	buy_button.theme_type_variation = "Primary"
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.pressed.connect(buy)
	row.add_child(buy_button)
	city.hud.add_child(banner)

# Called every frame: the tile in the middle of the view is reported when it changes (at most every INTERVAL seconds).
func update(dt: float) -> void:
	age += dt
	if age < INTERVAL or city.core.simulation == null:
		return
	age = 0.0
	var point: Vector2 = city.tile_coordinates(city.orbit.target)
	var tile := Vector2i(roundi(point.x), roundi(point.y))
	if tile == last_tile:
		return
	last_tile = tile
	var answer: Dictionary = city.core.query("view_tile %d %d" % [tile.x, tile.y])
	if answer.get("kind", "") == "cities":
		apply(answer)

func apply(answer: Dictionary) -> void:
	cities = answer.get("cities", [])
	viewed = int(answer.get("viewed", -1))
	var mine := cities.filter(func(c): return c.owner == "player")
	menu.visible = mine.size() > 1
	menu.text = "▾"
	menu.tooltip_text = city.tr("Your cities")
	var popup := menu.get_popup()
	popup.clear()
	for index in mine.size():
		popup.add_item(str(mine[index].name), int(mine[index].id))
		if int(mine[index].id) == int(answer.get("player_city", -1)):
			popup.set_item_disabled(index, true)
	var looked := viewed_city()
	if not looked.is_empty() and looked.owner == "unowned":
		banner_text.text = city.tr("%s has no ruler. It can be bought for %d drachmas.") % [str(looked.name), int(looked.price)]
		buy_button.text = city.tr("Buy")
		banner.visible = true
	else:
		banner.visible = false
	if answer.get("changed", false):
		city.refresh_catalog()
		city.hint.text = city.tr("Now governing %s") % str(answer_city_name(int(answer.get("player_city", -1))))

func viewed_city() -> Dictionary:
	for item in cities:
		if int(item.id) == viewed:
			return item
	return {}

func answer_city_name(id: int) -> String:
	for item in cities:
		if int(item.id) == id:
			return str(item.name)
	return ""

func go_to(id: int) -> void:
	for item in cities:
		if int(item.id) == id:
			city.jump_to_cell(Vector2(int(item.centre[0]), int(item.centre[1])))

func buy() -> void:
	if viewed >= 0:
		city.core.send("buy_city %d" % viewed)

# The answer to a queued `buy_city`.
func bought(result: Dictionary) -> void:
	if result.get("kind", "") == "cities":
		apply(result)
		city.refresh_catalog()
		city.hint.text = city.tr("%s is yours.") % answer_city_name(int(result.get("player_city", -1)))
	elif str(result.get("error", "")) == "insufficient_funds":
		city.hint.text = city.tr("There are not enough drachmas to buy this city")
	else:
		city.hint.text = city.reason_text(str(result.get("error", "")))
