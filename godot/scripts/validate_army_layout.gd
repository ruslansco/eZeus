extends SceneTree
# Presentation-only fixtures: no native city, orders, preferences or saves are changed.
const ArmyScene = preload("res://ui/army_panel.tscn")
var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("ARMY_LAYOUT_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 4: await process_frame

func fixture(id: int, language: String) -> Dictionary:
	return {
		"id": id, "name": ('"The extraordinarily long company name of the eastern city guard"' if language == "en" else '"Отряд с очень длинным именем защитников восточного города"'),
		"kind_name": "Hoplites" if language == "en" else "Гоплиты",
		"type": "hoplite", "count": 6, "home": true, "abroad": false,
		"aid": false, "fighting": false, "placed": true, "x": 14, "y": 22,
	}

func inside(outer: Rect2, inner: Rect2) -> bool:
	return outer.grow(1).encloses(inner)

func run() -> void:
	var access := root.get_node("UiAccess")
	var host := Control.new()
	host.theme = access.shared
	root.add_child(host)
	var panel = ArmyScene.instantiate()
	host.add_child(panel)
	await settle()
	for language in ["en", "ru"]:
		TranslationServer.set_locale(language)
		for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1024, 576)]:
			for ui in [100, 125]:
				access.apply(ui, 130)
				root.size = dimensions
				await settle()
				host.size = root.get_visible_rect().size
				var bounds := Rect2(16, 110, host.size.x - 32, maxf(90, host.size.y - 242))
				var tag := "%s %d×%d UI%d/text130" % [language, dimensions.x, dimensions.y, ui]
				panel.set_banners([], 8)
				panel.open()
				panel.retranslate()
				panel.fit_host(bounds)
				await settle()
				check(inside(bounds, panel.get_rect()) and panel.size.x <= 440, tag + " empty panel fits the host")
				check(panel.empty.visible and panel.call_all.disabled and panel.home_all.disabled and not panel.call_all.tooltip_text.is_empty(), tag + " empty-company actions explain their state")
				var companies: Array = []
				for id in 12: companies.append(fixture(id, language))
				companies[0].placed = false
				companies[1].abroad = true
				companies[2].abroad = true; companies[2].aid = true
				panel.set_banners(companies, 8)
				panel.select(0, false)
				panel.fit_host(bounds)
				await settle()
				check(inside(bounds, panel.get_rect()), tag + " long companies and details fit the host")
				check(panel.rows.values().all(func(row): return row.clip_text and row.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS and row.tooltip_text == panel.row_text(companies[int(row.get_index())]) and row.size.x <= panel.content.size.x + 1), tag + " rows are bounded and retain full native wording")
				var help: Control = panel.rows[0]._make_custom_tooltip(panel.rows[0].tooltip_text)
				root.add_child(help)
				await settle()
				check(help.size.x <= host.size.x - 40 and help.size.y < 240, tag + " long-name help wraps within the viewport")
				help.queue_free()
				check(panel.go_button.disabled and panel.go_button.tooltip_text.contains(panel.tr("This company has no banner placed on the map")), tag + " unplaced company explains Go to")
				var retained = panel.rows[0]
				panel.set_banners(companies.duplicate(true), 8)
				check(panel.rows[0] == retained and panel.selected_id == 0, tag + " refresh retains controls and selection")
				panel.select(1, false)
				check(panel.toggle_button.disabled and panel.place_button.disabled and panel.toggle_button.tooltip_text.contains(panel.tr("This company is abroad and cannot be called out or sent home")) and panel.place_button.tooltip_text.contains(panel.tr("This company is abroad and its banner cannot be moved")), tag + " abroad restrictions explain both actions")
				panel.select(2, false)
				check(not panel.toggle_button.disabled and panel.place_button.disabled, tag + " native aid company remains eligible to return")
				await settle()
				check(panel.content.scroll_vertical > 0, tag + " company selection reveals detail below the long list")
				panel.content.ensure_control_visible(panel.place_button)
				await settle()
				check(inside(panel.content.get_global_rect(), panel.place_button.get_global_rect()) and inside(panel.get_global_rect(), panel.close_button.get_global_rect()), tag + " scrolling reaches detail actions while Close stays fixed")
				panel.close()
	access.apply(100, 100)
	host.queue_free()
	await process_frame
	print("ARMY_LAYOUT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
