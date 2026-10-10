extends RefCounted
# Presentation fixtures run over the designated disposable city. The caller also
# verifies native empty-settlement construction and unchanged simulation state.
const Steps = preload("res://ui/settlement_steps.gd")
const Settings = preload("res://scripts/user_settings.gd")

func frames(city: Node, count := 6) -> void:
	for i in count: await city.get_tree().process_frame

func click(city: Node, button: Control) -> void:
	var viewport := city.get_tree().root
	viewport.warp_mouse(button.get_global_rect().get_center())
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center();event.global_position=event.position
		event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed=pressed;event.set_meta("review_input",true)
		viewport.push_input(event,true)
		await frames(city,2)
	await frames(city)

func enter(city: Node) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ENTER;event.physical_keycode=KEY_ENTER
		event.pressed=pressed;event.set_meta("review_input",true)
		city.get_tree().root.push_input(event,true);await frames(city,2)

func run(city: Node, check: Callable, capture: Callable) -> void:
	var help: Control = city.city_help
	var native_report: Dictionary = help.report
	var native_state: Dictionary = city.state
	var catalog: Array = city.hud.build_groups.duplicate(true)
	var values := {"roads":137,"houses":0,"residents":0,"watered":0,"fed":0,"employed":0,"maintenance":0}
	city.state = native_state.duplicate(true)
	city.state.buildings = []
	city.state.city_header.stock = []
	help.report = {"items":[],"settlement":values}
	help.age = -1000; help.step_chosen = true
	help.offer(); await frames(city)
	check.call(help.welcome and help.body.find_child("GuideStart",true,false)!=null and help.targets().is_empty(),"new settlement begins with an optional introduction, not an armed building tool")
	check.call(not help.milestone(0) and help.road_baseline==137,"137 pre-authored road tiles do not complete the new-road tutorial task")
	await capture.call("guide-welcome")
	help.body.find_child("GuideLater",true,false).pressed.emit()
	check.call(not help.visible and not Settings.get_value("interface","settlement_guide_finished",false),"Explore on my own dismisses this offer without disabling future help")
	city.open_city_help("guide"); help.report = {"items":[],"settlement":values}; help.offer(); help.age = -1000
	await frames(city);await click(city,help.body.find_child("GuideStart",true,false))
	check.call(not help.welcome and help.step==0 and help.body.find_child("GuideBuild",true,false)!=null,"guided setup starts at one clear current road action")
	var next: Button = help.body.find_child("NextStep",true,false)
	next.pressed.emit()
	check.call(next.disabled and help.step==0,"Continue cannot silently skip an incomplete task, even through its signal")
	check.call(help.step_status(0,false).contains("0 / 3") and help.targets().size()==1,"first task shows measurable new-road progress and one matching dock target")
	await click(city,help.body.find_child("GuideBuild",true,false))
	check.call(city.mode=="road" and city.core.commands.is_empty(),"Select Road uses the original placement tool without constructing anything")
	await capture.call("guide-road")
	values.roads=140; help.render(); await frames(city)
	check.call(help.milestone(0) and not help.body.find_child("NextStep",true,false).disabled,"three additional native road cells satisfy the road task")
	help.body.find_child("NextStep",true,false).pressed.emit(); await frames(city)
	check.call(help.step==1 and help.completed.has(0),"Continue records the completed task and advances one step")
	help.body.find_child("GuideBuild",true,false).grab_focus();await frames(city)
	check.call(city.hud.toolbar_has_focus() and city.orbit.toolbar_input_blocked,"keyboard navigation in the guide holds camera controls")
	await enter(city);await frames(city)
	check.call(city.mode=="house" and city.core.commands.is_empty(),"housing action selects the original common-house placement tool")
	check.call(not city.hud.toolbar_has_focus() and not city.orbit.toolbar_input_blocked,"activating a placement action returns keyboard camera control")
	values.houses=2; help.render(); await frames(city)
	check.call(not help.milestone(1) and help.guide_task(1).wait and help.body.find_child("GuideBuild",true,false).text==city.tr("Resume city time"),"two empty homes require real residents and give an explicit paused-time action")
	check.call(help.body.find_children("*","Label",true,false).any(func(label):return label.text==city.tr("City paused: use Play to continue.")),"paused immigration explains why no progress is happening")
	help.report.items=[{"flags":["understaffed"],"employees":2,"max_employees":6}]
	help.render()
	check.call(help.guide_task(1).hint.contains("4"),"waiting tasks explain the exact native job shortfall instead of suggesting endless waiting")
	help.report.items=[]
	var pending: int = city.hud.decision_count
	city.hud.decision_count=1; help.render(); await frames(city)
	var resume: Button = help.body.find_child("GuideBuild",true,false)
	resume.pressed.emit()
	check.call(resume.disabled and city.core.commands.is_empty(),"a required native decision blocks the guide's explicit Resume action")
	city.hud.decision_count=pending
	values.residents=8; help.render(); await frames(city)
	help.body.find_child("NextStep",true,false).pressed.emit(); await frames(city)
	check.call(help.step==2 and help.milestone(1),"immigration completes the home stage using actual resident observations")
	var water_button: Button = help.body.find_child("GuideBuild",true,false)
	check.call(water_button.text.contains(city.hud.item_name(city.hud.build_entries.fountain)) and water_button.help_detail.contains(city.hud.cost_text(city.hud.build_entries.fountain)),"direct water action names the available fountain and its exact native cost")
	water_button.pressed.emit()
	check.call(city.mode=="fountain" and city.core.commands.is_empty(),"water action selects the actual fountain, rather than an unrelated category")
	city.state.buildings=[{"asset":"fountain","grow":100}]; help.render(); await frames(city)
	check.call(not help.milestone(2) and help.guide_task(2).wait,"an existing fountain does not claim that homes have received water")
	values.watered=1; help.render(); await frames(city)
	help.body.find_child("NextStep",true,false).pressed.emit(); await frames(city)
	check.call(help.step==3,"water reaching a home advances to the food chain")
	var task: Dictionary = help.guide_task(3)
	check.call(task.tool=="granary","food setup first asks for food storage")
	city.state.buildings.append({"asset":"granary","grow":100})
	help.render()
	task=help.guide_task(3)
	check.call(task.action=="agriculture" and task.tool.is_empty(),"empty granary leads to a choice of map-available food sources")
	city.state.buildings.append({"asset":"wheat_farm","grow":100})
	help.render()
	task=help.guide_task(3)
	check.call(task.tool=="common_agora","a food source leads to the agora before a vendor is requested")
	city.state.buildings.append({"asset":"agora_space","grow":100})
	help.render()
	task=help.guide_task(3)
	check.call(task.tool=="food_vendor","an agora leads to its food-vendor placement tool")
	city.state.buildings.append({"asset":"food_vendor","grow":100})
	help.render(); await frames(city)
	check.call(help.guide_task(3).wait and not help.milestone(3),"complete food infrastructure still waits for delivery to a home")
	await capture.call("guide-food")
	values.fed=1; help.render(); await frames(city)
	help.body.find_child("NextStep",true,false).pressed.emit(); await frames(city)
	check.call(help.step==4 and help.guide_task(4).tool=="maintenance_office","native food delivery leads to maintenance")
	city.state.buildings.append({"asset":"maintenance_office","grow":100})
	help.render()
	check.call(not help.milestone(4) and help.guide_task(4).wait,"unemployed maintenance office does not complete the staffed-service task")
	values.maintenance=1; help.render(); await frames(city)
	help.body.find_child("NextStep",true,false).pressed.emit(); await frames(city)
	help.body.find_child("GuideBuild",true,false).pressed.emit(); await frames(city)
	check.call(help.objectives_reviewed and (city.hud.get_node("%GoalsList").visible or help.tab=="attention"),"final action opens native objectives or sandbox issues without claiming chapter victory")
	city.hud.set_goals_expanded(false)
	city.open_city_help("guide");help.report={"items":[],"settlement":values};help.age=-1000
	help.step=1; help.completed.clear(); values.residents=0; help.render(); await frames(city)
	help.body.find_child("GuideSkipStep",true,false).pressed.emit(); await frames(city)
	check.call(help.step==2 and help.skipped.has(1) and not help.milestone(1),"optional skip advances without marking an incomplete step Done")
	help.body.find_child("GuideRoadmap",true,false).pressed.emit(); await frames(city)
	check.call(help.roadmap and help.body.find_children("*","Button",true,false).any(func(button):return button.text.contains(city.tr("Skipped"))),"all steps remain available on demand with a distinct Skipped state")
	help.roadmap=false
	city.state.buildings=[]; values.watered=0; help.completed.clear()
	city.hud.set_catalog(catalog.filter(func(group):return group.title!="Health and water"))
	help.step=2; help.render(); await frames(city)
	check.call(help.guide_task(2).unavailable and help.build_action(2)==null and not help.body.find_child("NextStep",true,false).disabled,"unsupported chapter buildings are explained and never block the guide")
	city.hud.set_catalog(catalog)
	var entries := {"granary":{"asset":"granary"},"trade_post:3":{"asset":"trade_post"}}
	task=Steps.task(3,values,entries,[{"asset":"granary"}],[],137)
	check.call(task.action=="trade","a chapter with trade but no local food source explains importing food")
	task=Steps.task(3,values,{"granary":{}},[{"asset":"granary"},{"asset":"trade_post"}],[],137)
	check.call(task.action=="trade_existing","an existing trading post remains a food-import route even after its category has no free partner slots")
	task=Steps.task(0,{"roads":0},city.hud.build_entries,[],[],0)
	check.call(not task.ready and task.instruction.begins_with("Lay a short road"),"a map without any roads explains how to lay the first road instead of extending one")
	var goals: Dictionary = city.hud.goals_state
	city.hud.goals_state={"goals":[]}; help.step=5; help.objectives_reviewed=false
	help.render()
	check.call(help.guide_task(5).action=="sandbox" and help.guide_task(5).progress.contains(city.tr("Sandbox: build at your own pace")),"sandbox guide does not invent campaign objectives")
	city.hud.goals_state={"goals":[{}]}
	help.render()
	check.call(help.guide_task(5).action=="objectives" and not help.milestone(5),"campaign mode asks players to review objectives before finishing the guide")
	city.hud.goals_state=goals
	help.step=0; help.road_baseline=137; help.skipped.clear(); help.completed.clear(); values.roads=137
	help.signature=""; help.render(); await frames(city)
	var tall: float = help.card.size.y
	help.set_folded(true); await frames(city)
	check.call(help.summary.visible and help.card.size.y<tall*.5,"collapsed help preserves a compact current-task tracker")
	help.summary.pressed.emit(); await frames(city)
	check.call(not help.folded and help.scroll.visible,"current-task tracker reopens the same guide")
	city.set_tool("select"); city.hud.close_build_tray()
	city.state=native_state;help.report=native_report;help.offer();help.begin_guide()
	help.report=native_report.duplicate(true);help.report.settlement.roads+=1;help.render();await frames(city)
	help.body.find_child("GuideBuild",true,false).grab_focus();help.refresh();await frames(city)
	var focused := city.get_viewport().gui_get_focus_owner()
	check.call(focused!=null and focused.name=="GuideBuild" and help.has_navigation_focus(),"live report rebuilding preserves keyboard focus on the current guide action")
	if focused!=null:focused.release_focus()
	help.report=native_report; help.road_baseline=0; help.completed.clear(); help.skipped.clear(); help.objectives_reviewed=false
	help.step=0; help.age=0; help.signature=""; help.render(); await frames(city)
	check.call(city.core.commands.is_empty(),"tutorial offers, learning progress, skips, and build-tool selection issue no automatic native commands")
