extends RefCounted
# Read-only tutorial coaching. Native observations and the currently offered
# catalog are authoritative; these tasks never grant, build, or advance time.
const SOURCES := ["hunting_lodge", "fishery", "urchin_quay", "wheat_farm", "onion_farm", "carrot_farm", "dairy", "orange_tenders_lodge"]

static func placed(buildings: Array, assets: Array) -> bool:
	return buildings.any(func(building): return str(building.get("asset", "")) in assets)

static func pick(entries: Dictionary, names: Array) -> String:
	for name in names:
		if entries.has(name): return name
	return ""

static func task(index: int, values: Dictionary, entries: Dictionary, buildings: Array, stock: Array, road_baseline: int) -> Dictionary:
	var result := {"tool":"", "action":"", "instruction":"", "hint":"", "progress":"", "ready":false, "unavailable":false, "wait":false}
	match index:
		0:
			result.tool = pick(entries,["road"])
			result.instruction = "Extend an existing road by 3 tiles. Click and drag over open land, leaving room for houses on both sides."
			if road_baseline == 0 and int(values.get("roads",0)) == 0:
				result.instruction = "Lay a short road of at least 3 tiles near the city's entry point. Click and drag over open land, leaving room for houses."
			result.progress = TranslationServer.translate("New road tiles: %d / 3") % clampi(int(values.get("roads",0))-road_baseline,0,3)
			result.ready = int(values.get("roads",0)) >= road_baseline+3
		1:
			result.ready = int(values.get("houses",0)) >= 2 and int(values.get("residents",0)) > 0
			if int(values.get("houses",0)) < 2:
				result.tool = pick(entries,["house"])
				result.instruction = "Place 2 common houses beside the connected road. An edge of each house must touch the road."
				result.progress = TranslationServer.translate("Homes placed: %d / 2") % mini(int(values.get("houses",0)),2)
			else:
				result.wait = true
				result.instruction = "Let city time run until your first residents arrive. They will fill the jobs in your service buildings."
				result.hint = "If no one arrives, check that the houses connect to the city's entry road."
				result.progress = TranslationServer.translate("Residents: %s") % str(int(values.get("residents",0)))
		2:
			result.ready = int(values.get("watered",0)) > 0
			result.tool = pick(entries,["fountain"])
			result.instruction = "Place a fountain near your houses and connect it to the road. Let residents staff it and supply the homes."
			result.hint = "Completion means a home has received water, not just that a fountain exists."
			result.progress = TranslationServer.translate("Homes with water: %s") % str(int(values.get("watered",0)))
			if placed(buildings,["fountain"]): result.tool = ""; result.wait = true
		3:
			result.ready = int(values.get("fed",0)) > 0
			result.progress = TranslationServer.translate("Homes with food: %s") % str(int(values.get("fed",0)))
			var food := 0
			for good in stock:
				if int(good.get("resource",0)) == 255: food = int(good.get("count",0))
			if not placed(buildings,["granary"]):
				result.tool = pick(entries,["granary"])
				result.instruction = "Build a granary on the road. It stores food for the market; a warehouse does not store food."
			elif food == 0 and not placed(buildings,SOURCES):
				if not pick(entries,SOURCES).is_empty(): result.action = "agriculture"
				result.instruction = "Choose a food source in Agriculture and connect it to the granary's road. Place it beside the resource or on suitable farmland."
				result.hint = "Use a source suited to this map. Hunting needs animals; fishing needs the shore; farms need fertile land."
				if result.action.is_empty() and entries.keys().any(func(name):return str(name).begins_with("trade_post:") or str(name).begins_with("pier:")):
					result.action = "trade"
					result.instruction = "Open Trade to find a partner that sells food. Build its trading post and set a food import order."
				elif result.action.is_empty() and placed(buildings,["trade_post","harbour"]):
					result.action = "trade_existing"
					result.instruction = "Inspect your trading post and check its food imports. A partner must sell food before you can enable an import order."
			elif not placed(buildings,["agora_space"]):
				result.tool = pick(entries,["common_agora","grand_agora"])
				result.instruction = "Place an agora along the road near your houses. It provides spaces for market vendors."
			elif not placed(buildings,["food_vendor"]):
				result.tool = pick(entries,["food_vendor"])
				result.instruction = "Place a Food Vendor inside the agora. The peddler takes food from the granary and delivers it to homes."
			else:
				result.wait = true
				result.instruction = "Let the food vendor collect food and visit a home. Keep the source, granary and agora on the same road network."
				result.hint = "If food is not reaching homes, inspect the vendor's stock and check the Issues tab for missing workers or road access."
		4:
			result.ready = int(values.get("maintenance",0)) > 0
			result.tool = pick(entries,["maintenance_office"])
			result.instruction = "Place a maintenance office on your settlement's road. Its workers patrol to reduce fire and collapse risk."
			result.progress = TranslationServer.translate("Working maintenance offices: %s") % str(int(values.get("maintenance",0)))
			if placed(buildings,["maintenance_office"]): result.tool = ""; result.wait = true
		5:
			result.action = "objectives"
			result.instruction = "Review this chapter's objectives. Keep food, water and service jobs working before expanding the city."
			result.hint = "The settlement guide teaches the basics. Your adventure objectives decide how the chapter is won."
			result.progress = TranslationServer.translate("Review your next objective")
	return result
