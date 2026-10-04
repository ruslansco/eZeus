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
