extends RefCounted
# Names of the goods, by the core's resource value (a single bit), as `tr()` keys of data/ui_strings.csv. The storage
# panel, the trade post panel and the trade partners dialog all name goods the same way.

const NAMES := [
	"Sea urchins", "Fish", "Meat", "Cheese",
	"Carrots", "Onions", "Wheat", "Oranges",
	"Grapes", "Olives", "Wine", "Olive oil",
	"Fleece", "Timber", "Bronze", "Marble",
	"Armor", "Sculptures", "Orichalcum", "Black marble",
	"Horses", "Chariots", "Silver", "Drachmas"]

static func name_of(resource: int) -> String:
	for index in NAMES.size():
		if resource == (1 << index):
			return TranslationServer.translate(NAMES[index])
	return TranslationServer.translate("Goods")

# The icon file of each good by the same bit order (res://ui/resource_art); drachmas have none.
const ICONS := [
	"urchin", "fish", "meat", "cheese", "carrots", "onions", "grain", "oranges",
	"grapes", "olives", "wine", "oil", "fleece", "wood", "bronze", "marble",
	"arms", "sculptures", "orichalcum", "black_marble", "horses", "chariots", "silver", ""]
static var icon_cache := {}

# A good's icon by the core's resource value; the all-food mask (255) is the food icon. Null when there is none.
static func icon_of(resource: int) -> Texture2D:
	var file := "food_total" if resource == 255 else ""
	if file.is_empty():
		for index in ICONS.size():
			if resource == (1 << index):
				file = ICONS[index]
	return icon_named(file)

static func icon_named(file: String) -> Texture2D:
	if file.is_empty():
		return null
	if not icon_cache.has(file):
		var path := "res://ui/resource_art/%s.png" % file
		icon_cache[file] = load(path) if ResourceLoader.exists(path) else null
	return icon_cache[file]
