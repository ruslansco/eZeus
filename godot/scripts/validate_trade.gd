extends SceneTree
# Trade posts against the embedded core (headless, in memory): the partner list is the SDL panel's, a land trade post and a
# sea pier are previewed, built for the quoted cost, undone and demolished by the native rules, a partner gets one post, the
# post's panel reports what the partner buys and sells and its orders are edited with the quota rules, and asking never
# changes the simulation.
var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("TRADE_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func adventure(core: RefCounted, engine: String, title: String) -> Dictionary:
	for item in core.adventures(engine, "en").adventures:
		if item.title == title:
			return core.open_adventure(engine, item.kind, item.ref, "en")
	return {}

func site(core: RefCounted, state: Dictionary, tool: String, partner: int) -> Vector2i:
	for tile in state.tiles:
		if int(tile[5]) and core.command("preview %s %d %d 0 %d" % [tool, tile[0], tile[1], partner]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

# Buildings are removed on the simulation's next step, so what a demolition or an undo frees shows up a moment later.
func settle(core: RefCounted) -> void:
	core.command("pause 0")
	for i in 30:
		core.advance(.05)
	core.command("pause 1")

func pieces(state: Dictionary, asset: String) -> Array:
	return state.buildings.filter(func(b): return b.asset == asset)

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")

	# Land: The Peloponnesian War has only land partners.
	var state := adventure(core, engine, "The Peloponnesian War")
	var partners: Array = core.command("trade_partners").partners
	check(partners.size() == 5 and partners.all(func(p): return not p.water and p.available and not p.has_post), "the Peloponnesian War offers five land partners, none with a post yet")
	check(partners.all(func(p): return p.sells is Array and p.buys is Array and (p.sells.size() + p.buys.size()) > 0), "each partner lists the goods it sells and buys")
	var first: Dictionary = partners[0]
	check(core.command("preview trade_post 60 -40 0").get("reason", "") == "trade_partner_unavailable", "a trade post needs a partner")
	check(core.command("preview trade_post 60 -40 0 99").get("reason", "") == "trade_partner_unavailable" and core.command("preview pier 60 -40 0 %d" % first.index).get("reason", "") == "trade_partner_unavailable", "an unknown partner, or a pier for a land partner, is refused")
	var spot := site(core, state, "trade_post", first.index)
	check(spot != Vector2i(99999, 99999), "a site for a trade post exists")
	var query: Dictionary = core.command("preview trade_post %d %d 0 %d" % [spot.x, spot.y, first.index])
	var listed: Dictionary = {}
	for item in core.command("buildable").buildings:
		if item.name == "trade_post":
			listed = item
	check(query.valid and query.tiles.size() == 16 and query.w == 4 and query.h == 4 and query.asset == "trade_post" and int(query.cost) == int(listed.cost) and listed.available, "the preview covers 4x4 tiles at the quoted cost (%d)" % int(query.cost))
	var before: Dictionary = core.snapshot(true)
	var quiet: Dictionary = core.snapshot(true)
	core.command("trade_partners")
	check(quiet.money == before.money and quiet.buildings == before.buildings, "asking for the partners does not change the city")
	var built: Dictionary = core.command("build trade_post %d %d 0 %d" % [spot.x, spot.y, first.index])
	check(not built.has("error") and built.money == before.money - int(query.cost) and built.undo_available, "it is built for the quoted cost and can be undone")
	check(pieces(built, "trade_post").size() == pieces(before, "trade_post").size() + 1, "the snapshot lists the new trade post")
	var again: Array = core.command("trade_partners").partners
	var mine: Dictionary = again.filter(func(p): return p.index == first.index)[0]
	check(mine.has_post and not mine.available and again.size() == partners.size(), "the partner now has its post and is no longer offered")
	check(core.command("preview trade_post %d %d 0 %d" % [spot.x + 8, spot.y, first.index]).get("reason", "") == "trade_partner_unavailable", "a second post for the same partner is refused")
	var refunded: Dictionary = core.command("undo")
	settle(core)
	check(refunded.money == before.money and core.command("trade_partners").partners.filter(func(p): return p.index == first.index)[0].available, "undo refunds it and frees the partner")
	core.command("build trade_post %d %d 0 %d" % [spot.x, spot.y, first.index])
	# The post's panel and orders.
	var info: Dictionary = core.command("inspect %d %d" % [spot.x, spot.y])
	var trade: Dictionary = info.get("trade", {})
	check(trade.get("partner", "") == first.name and not trade.water and not trade.two_way and trade.imports.size() == first.sells.size() and trade.exports.size() == first.buys.size(), "the panel names the partner and lists %d imports and %d exports" % [trade.imports.size(), trade.exports.size()])
	check(trade.imports.all(func(g): return not g.enabled and int(g.step) in [1, 4] and int(g.max_quota) >= int(g.quota)) and trade.exports.all(func(g): return not g.enabled), "no good is traded until the player chooses")
	var good: Dictionary = trade.imports[0]
	var order := "trade %d %d %d %d 0 1 %d" % [spot.x, spot.y, info.target_token, int(good.resource), int(good.step) * 2]
	check(not core.command(order).has("error"), "an import is switched on with a quota")
	var after: Dictionary = core.command("inspect %d %d" % [spot.x, spot.y]).trade
	var changed: Dictionary = after.imports.filter(func(g): return int(g.resource) == int(good.resource))[0]
	check(changed.enabled and int(changed.quota) == int(good.step) * 2 and after.imports.filter(func(g): return g.enabled).size() == 1, "the order is kept by the post")
	var export_good: Dictionary = trade.exports[0]
	check(not core.command("trade %d %d %d %d 1 1 0" % [spot.x, spot.y, info.target_token, int(export_good.resource)]).has("error") and core.command("inspect %d %d" % [spot.x, spot.y]).trade.exports[0].enabled, "an export is switched on")
	check(core.command("trade %d %d %d %d 0 1 3" % [spot.x, spot.y, info.target_token, int(good.resource)]).get("error", "") == "invalid_storage_order", "a quota off the step is refused")
	check(core.command("trade %d %d %d %d 0 1 99999" % [spot.x, spot.y, info.target_token, int(good.resource)]).get("error", "") == "invalid_storage_order", "a quota beyond the post's space is refused")
	check(core.command("trade %d %d %d %d 0 1 4" % [spot.x, spot.y, info.target_token, 1 << 22]).has("error") and core.command("trade %d %d %d %d 1 1 4" % [spot.x, spot.y, info.target_token, int(good.resource)]).get("error", "") in ["unsupported_resource", ""] , "a good the partner does not trade that way is refused")
	check(core.command("trade %d %d 12345 %d 0 1 4" % [spot.x, spot.y, int(good.resource)]).get("error", "") == "inspection_target_changed", "a stale inspection cannot edit the post")
	var snapshot: Dictionary = core.snapshot(true)
	core.command("demolish %d %d 1 0" % [spot.x, spot.y])
	settle(core)
	check(pieces(core.snapshot(true), "trade_post").size() == pieces(snapshot, "trade_post").size() - 1, "demolishing the post removes it")
	core.close_city()

	# Sea: The Founding of Athens trades by sea only.
	state = adventure(core, engine, "The Founding of Athens")
	partners = core.command("trade_partners").partners
	check(partners.size() == 2 and partners.all(func(p): return p.water and p.available), "the Founding of Athens offers two sea partners")
	var sea: Dictionary = partners[0]
	check(core.command("preview trade_post 40 0 0 %d" % sea.index).get("reason", "") == "trade_partner_unavailable", "a land post for a sea partner is refused")
	var shore := site(core, state, "pier", sea.index)
	check(shore != Vector2i(99999, 99999), "a shore site for a pier exists")
	var inland := Vector2i(99999, 99999)
	for tile in state.tiles:
		if int(tile[5]) and core.command("preview pier %d %d 0 %d" % [tile[0], tile[1], sea.index]).get("reason", "") == "not_on_shore":
			inland = Vector2i(int(tile[0]), int(tile[1]))
			break
	check(inland != Vector2i(99999, 99999), "away from the water a pier is refused (not on the shore)")
	var plan: Dictionary = core.command("preview pier %d %d 0 %d" % [shore.x, shore.y, sea.index])
	check(plan.valid and plan.tiles.size() == 20 and plan.w == 2 and plan.h == 2 and plan.asset == "harbour" and int(plan.cost) == int(listed.cost), "the pier preview covers the pier and its 4x4 trade post (%d tiles) at a trade post's cost" % plan.tiles.size())
	var shore_before: Dictionary = core.snapshot(true)
	var laid: Dictionary = core.command("build pier %d %d 0 %d" % [shore.x, shore.y, sea.index])
	check(not laid.has("error") and laid.money == shore_before.money - int(plan.cost) and laid.undo_available, "the pier is built for the quoted cost")
	check(pieces(laid, "harbour").size() == pieces(shore_before, "harbour").size() + 1 and pieces(laid, "trade_post").size() == pieces(shore_before, "trade_post").size() + 1, "a pier and a trade post appear")
	var harbour: Dictionary = pieces(laid, "harbour").filter(func(b): return pieces(shore_before, "harbour").all(func(o): return o.id != b.id))[0]
	check(harbour.w == 2 and harbour.h == 2 and int(harbour.orientation) == int(plan.orientation), "the pier faces the water the rule found (orientation %d)" % int(harbour.orientation))
	var sea_info: Dictionary = {}
	for b in pieces(laid, "trade_post"):
		if pieces(shore_before, "trade_post").all(func(o): return o.id != b.id):
			sea_info = core.command("inspect %d %d" % [b.x, b.y])
	check(sea_info.get("trade", {}).get("water", false) and sea_info.trade.partner == sea.name, "the new post is a sea post for the partner")
	check(core.command("trade_partners").partners.filter(func(p): return p.index == sea.index)[0].has_post, "the sea partner has its post")
	var undone: Dictionary = core.command("undo")
	settle(core)
	var gone: Dictionary = core.snapshot(true)
	check(undone.money == shore_before.money and pieces(gone, "harbour").size() == pieces(shore_before, "harbour").size() and pieces(gone, "trade_post").size() == pieces(shore_before, "trade_post").size(), "undo removes the pier together with its post and refunds")
	core.command("build pier %d %d 0 %d" % [shore.x, shore.y, sea.index])
	var kept: Dictionary = core.snapshot(true)
	var post_at: Dictionary = {}
	for b in pieces(kept, "trade_post"):
		if pieces(shore_before, "trade_post").all(func(o): return o.id != b.id):
			post_at = b
	core.command("demolish %d %d 1 0" % [post_at.x, post_at.y])
	settle(core)
	var razed: Dictionary = core.snapshot(true)
	check(pieces(razed, "harbour").size() == pieces(shore_before, "harbour").size() and pieces(razed, "trade_post").size() == pieces(shore_before, "trade_post").size(), "demolishing the post takes the pier with it")
	core.close_city()

	# The campaign's test city already trades: no partner is left to open.
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	core.open_city(engine, designated, "en")
	var test_partners: Array = core.command("trade_partners").partners
	check(test_partners.size() == 4 and test_partners.all(func(p): return p.has_post and not p.available), "the test city has a post for each of its four partners")
	var existing: Dictionary = {}
	for b in core.snapshot(true).buildings:
		if b.asset == "trade_post":
			existing = core.command("inspect %d %d" % [b.x, b.y])
			break
	check(existing.has("trade") and existing.trade.imports.size() + existing.trade.exports.size() > 0, "an existing post reports its partner's goods")
	print("TRADE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
