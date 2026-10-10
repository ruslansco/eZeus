extends RefCounted
# Advice consumes native observations only; it does not decide building state.
const Goods = preload("res://scripts/goods.gd")
const NEEDS = ["Food", "Water", "Fleece", "Olive oil", "Arms", "Wine", "Horses", "Culture / science", "Appeal"]
const TITLES = {"on_fire":"On fire", "no_workers":"No workers", "understaffed":"Missing workers", "no_road":"No road access", "waiting_input":"Waiting for raw materials", "waiting_dispatch":"Goods awaiting collection", "industry_paused":"Industry paused", "no_target":"No resource to collect", "housing_decline":"Housing is declining", "construction":"Under construction"}

static func construction_advice(monument: Dictionary) -> String:
	if monument.get("finished",false):return ""
	if monument.get("halted",false):return TranslationServer.translate("Construction is paused. Resume it with the button below when you are ready.")
	if not monument.get("road",true):return TranslationServer.translate("Construction needs road access. Connect the monument to the road used by your artisans and deliveries.")
	var lacking: Array[String]=[]
	for good in ["wood","marble","black_marble","sculpture","orichalc"]:
		var amount:=int(monument.get("needed",{}).get(good,0))
		if amount>0:
			var label: String={"wood":"Timber","marble":"Marble","black_marble":"Black marble","sculpture":"Sculptures","orichalc":"Orichalc"}[good]
			lacking.append("%d %s"%[amount,TranslationServer.translate(label)])
	if not lacking.is_empty():return TranslationServer.translate("Still to deliver: %s. Keep these materials in reachable storage for the artisans.")%", ".join(lacking)
	if int(monument.get("employees",0))==0:return TranslationServer.translate("Materials are ready. A staffed artisans' guild must send builders along a connected road.")
	return TranslationServer.translate("Builders are assigned. Keep deliveries flowing; construction advances while the city runs.")

static func advice(data: Dictionary, status: String) -> String:
	var text := ""
	match status:
		"no_workers", "understaffed":
			var vacancies:=maxi(0, int(data.get("max_employees",0))-int(data.get("employees",0)))
			text = TranslationServer.translate("1 job is vacant. Bring in residents with food and water; check workforce priorities in the City window.") if vacancies==1 else TranslationServer.translate("%d jobs are vacant. Bring in residents with food and water; check workforce priorities in the City window.") % vacancies
			if (data.has("road_access") and not data.road_access) or data.get("flags",[]).has("no_road"):
				text += " " + TranslationServer.translate("This building also needs a road connection.")
		"no_road": text = TranslationServer.translate("Run a road along an edge of this building and connect it to your settlement. A road touching only a corner does not give access.")
		"waiting_input":
			var input: Dictionary = data.get("input", data.get("production",{}).get("input",{}))
			if not input.is_empty():
				text = TranslationServer.translate("Needs %d more %s for the next batch. Produce or import it, allow storage to accept it, and check the delivery road.") % [maxi(0,int(input.per_output)-int(input.count)), Goods.name_of(int(input.resource))]
			else: text = TranslationServer.translate("Produce or import the required input, allow storage to accept it, and check the delivery road.")
		"industry_paused": text = TranslationServer.translate("This industry is paused city-wide. Resume it in the production controls.")
		"waiting_dispatch": text = TranslationServer.translate("Stored goods are waiting for pickup. Check accepting storage or buyers, free capacity and a clear delivery road.")
		"no_target": text = TranslationServer.translate("No suitable resource is available to this collector. Check nearby deposits or crops and a reachable route to them.")
		"housing_decline":
			var missing: Array[String] = []
			for need in data.get("missing",[]):
				if int(need)>=0 and int(need)<NEEDS.size(): missing.append(TranslationServer.translate(NEEDS[int(need)]))
			text = TranslationServer.translate("Restore %s to keep this housing level. Open the house to see the exact supply and service requirements.") % ", ".join(missing)
		"on_fire": text = TranslationServer.translate("The building is burning. Check fire coverage and keep roads clear for maintenance walkers.")
		"construction": text = TranslationServer.translate("%d%% built. Construction needs delivered materials and a staffed artisans' guild with road access.") % int(data.get("progress",0))
	return text
