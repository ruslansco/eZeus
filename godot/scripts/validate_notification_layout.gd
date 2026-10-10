extends SceneTree
# Regression for the attached recording: a notice must retain its allotted width
# across many frames, pin/unpin, refresh and independent text scaling.
const Chip = preload("res://ui/notification_chip.gd")
var checks := 0
var okay := true

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("NOTICE_LAYOUT_CHECK ", "PASS " if value else "FAIL ", description)

func frames(count := 12) -> void:
	for frame in count: await process_frame

func run() -> void:
	var host := Control.new()
	host.theme = load("res://ui/lapis_gold.tres")
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(32,72)
	scroll.size = Vector2(560,360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	var card := Chip.new()
	card.open = true
	var text := "Какой позор для всего города, о Ruslan! Ваши философы выставили себя глупцами на Истмийских играх. Все смеялись над их речами! Если вы не хотите, чтобы вас опозорили и на следующих играх — постройте побольше академий и трибун!"
	card.configure(17,"Истмийские игры закончились",text,24)
	stack.add_child(card)
	await frames(60)
	check(card.size.x >= stack.size.x-2 and card.size.x > 500 and card.body_scroll.size.x > 350, "notice keeps its full container width and readable body after 60 frames")
	check(card.heading == null and card.find_children("*","Button",true,false).is_empty(), "instant notice has no title row or Close button")
	check(card.body_scroll.get_child(0).text == text, "the full original message survives wrapping")
	var width := card.size.x
	card.set_expanded(true)
	await frames(30)
	check(is_equal_approx(card.size.x,width) and card.expanded, "pinning preserves the notice width")
	card.set_expanded(false)
	await frames(30)
	check(is_equal_approx(card.size.x,width) and card.body_scroll.visible, "unpinning keeps the readable open notice")
	var body: Label = card.body_scroll.get_child(0)
	var base_font := body.get_theme_font_size("font_size")
	root.get_node("UiAccess").apply(125,130)
	await frames(30)
	check(body.get_theme_font_size("font_size") > base_font and card.size.x >= stack.size.x-2, "independent text scaling enlarges the body without collapsing its width")
	card.update_text(card.title_text,text.repeat(15),"1 Mar 3493 BC")
	card.set_expanded(true)
	await frames(30)
	var bar := card.body_scroll.get_v_scroll_bar()
	card.body_scroll.scroll_vertical = 100000
	await frames()
	check(body.text == text.repeat(15) and bar.max_value > bar.page and bar.value+bar.page >= bar.max_value-1, "long full text scrolls to its end inside the bounded notice")
	var before := card.body_scroll.scroll_vertical
	card.update_text(card.title_text,body.text,"")
	await frames(30)
	check(card.body_scroll.scroll_vertical == before and card.size.x >= stack.size.x-2, "unchanged refresh preserves reading position and card width")
	var journal := Chip.new()
	journal.history_row = true
	journal.configure(18,card.title_text,text.repeat(12),0,"1 Mar 3493 BC")
	stack.add_child(journal)
	journal.set_expanded(true)
	await frames(40)
	check(journal.size.x >= stack.size.x-2 and journal.body_scroll.visible and journal.body_scroll.custom_minimum_size.y <= 180, "journal disclosures also keep their full width and bounded reading area")
	journal.update_text(journal.title_text,text.repeat(12),"1 Mar 3493 BC")
	await frames(30)
	check(journal.size.x >= stack.size.x-2, "refresh does not shrink an open journal row")
	journal.set_expanded(false)
	await frames()
	check(not journal.is_processing() and not journal.body_scroll.visible, "folded static history retains idle-disabled processing")
	check(journal.heading != null and journal.heading.text == card.title_text, "journal retains its original title and disclosure button")
	root.get_node("UiAccess").apply(100,100)
	card.update_text("City","Lack of housing hinders immigration","")
	card.set_expanded(false)
	await frames()
	check(card.size.y <= card.body_scroll.size.y + 24, "a short instant message uses one slim content row")
	card.grab_focus()
	for pressed in [true,false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = pressed
		root.push_input(key,true)
	await frames()
	check(card.expanded, "keyboard activation pins the message without needing a title button")
	print("NOTICE_LAYOUT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
