# Frozen pre-filter building refresh loop for the owned paired benchmark.
# This designated city has no empty Agora spaces.
func baseline_update_buildings() -> void:
	# The embedded core flags an unchanged building list, so steady snapshots cost nothing.
	# Other sources (the legacy bridge) carry no flag and fall back to hashing the list.
	var signature: int
	if state.has("buildings_changed"):
		if not state.buildings_changed and building_signature != 0:
			return
		signature = 1
	else:
		signature = state.buildings.hash()
		if signature == building_signature:
			return
	building_signature = signature
	defence_perch.refresh(state.buildings)
	hud.minimap.set_buildings(state.buildings)
	var groups := {}
	var placeholders: Array = []
	var altars: Array = []
	var alive := {}
	var wanted_plazas := {}
	asset_count = 0
	building_index.clear()
	building_placements.clear()
	var trade_now := 0
	for building in state.buildings:
		building_index[int(building.id)] = building
		alive[int(building.id)] = true
		trade_now += 1 if building.asset in ["trade_post", "harbour"] else 0
		if building.asset in ["native_marker", "terrain_road"]:
			asset_count += 1
			continue
		if building.asset == "agora_space":
			wanted_plazas[int(building.id)] = true
			add_plaza(building)
			asset_count += 1
			continue
		var center := world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
		var transform := Transform3D(Basis.IDENTITY, center)
		if not overlay_view.building_visible(building):
			# An overlay shows what it is about; everything else lies flat on its footprint.
			transform.basis = Basis.from_scale(Vector3(building.w * .9, .05, building.h * .9))
			placeholders.append(transform)
			continue
		if not model_file_exists(building.asset):
			transform.basis = Basis.from_scale(Vector3(building.w * .88, .28, building.h * .88))
			placeholders.append(transform)
			continue
		asset_count += 1
		transform = building_draw_transform(building)
		if building.asset == "sanctuary_altar" and not bool(building.get("stretch", false)) and int(building.get("grow", 100)) >= 100:
			altars.append({"id": int(building.id), "transform": transform, "key": rite_key(float(building.x) + building.w * .5, float(building.y) + building.h * .5)})
		var group := "%s|%d:%d" % [building.asset, floori(float(building.x) / batch_cells), floori(float(building.y) / batch_cells)]
		if not groups.has(group):
			groups[group] = []
		groups[group].append({"transform":transform,"working":building.get("working",building.get("active",false)),"animation_offset":building.get("animation_offset",0)})
		building_placements["%d,%d" % [int(building.x), int(building.y)]] = {"asset": str(building.asset), "transform": transform}
		if building.has("bays") and overlay_view.building_visible(building):
			var cell_x := floori(float(building.x) / batch_cells)
			var cell_y := floori(float(building.y) / batch_cells)
			for bay in building.bays:
				var bay_idx: int = int(bay.get("bay", -1))
				var good_name: String = str(bay.get("good", ""))
				if bay_idx < 0 or good_name.is_empty():
					continue
				var bay_model := ""
				var local_tf := Transform3D.IDENTITY
				if building.asset == "granary":
					bay_model = "granary_food_" + good_name
					local_tf = Transform3D(Basis(Vector3.UP, bay_idx * PI / 4.0), GRANARY_DRUM_CENTER)
				elif building.asset == "warehouse":
					if bay_idx < WAREHOUSE_BAYS.size():
						bay_model = "good_" + good_name
						local_tf = Transform3D(Basis.IDENTITY, WAREHOUSE_BAYS[bay_idx])
				elif building.asset == "trade_post":
					if bay_idx < TRADE_POST_BAYS.size():
						bay_model = "good_" + good_name
						local_tf = Transform3D(Basis.IDENTITY, TRADE_POST_BAYS[bay_idx])
				if not bay_model.is_empty() and model_file_exists(bay_model):
					var bay_tf := transform * local_tf
					var good_group := "%s|%d:%d" % [bay_model, cell_x, cell_y]
					if not groups.has(good_group):
						groups[good_group] = []
					groups[good_group].append({"transform": bay_tf})
	groups["__footprint"] = placeholders
	for id in plaza_nodes.keys():
		if not wanted_plazas.has(id):
			plaza_nodes[id].free()
			plaza_nodes.erase(id)
	for id in building_draw_cache.keys():
		if not alive.has(id): building_draw_cache.erase(id)
	static_batches.rebuild(groups)
	altar_fires.refresh(altars)
	if overlay_view.active():
		overlay_view.redraw()
	# A trade post uses up its partner (and removing one frees it): the menu follows.
	if trade_now != trade_buildings:
		trade_buildings = trade_now
		if hud.build_menu != null and core.simulation != null:
			refresh_catalog()
			# A removed post leaves the map at once but frees its partner on the next simulation step: ask again.
			get_tree().create_timer(1.5).timeout.connect(refresh_catalog)

