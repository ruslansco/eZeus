extends CanvasLayer
# Owned by the tree root so the menu can leave without exposing a half-built city.
# Native loading remains on the main thread; this indicator does not claim a percentage.
const GROUP := "city_loading_screen"
var surface: ColorRect
var column: VBoxContainer
var heading: Label
var status: Label
var indicator: Control
var back: Button
var failed := false
var phase := .38

static func current(tree: SceneTree) -> CanvasLayer:
	return tree.get_first_node_in_group(GROUP) as CanvasLayer

static func open(tree: SceneTree) -> CanvasLayer:
	var existing := current(tree)
	if existing != null:
		return existing
	var screen := load("res://ui/loading_screen.gd").new() as CanvasLayer
	tree.root.add_child(screen)
	return screen

func _ready() -> void:
	name = "CityLoadingScreen"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	surface = ColorRect.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.theme = load("res://ui/lapis_gold.tres")
	surface.theme_type_variation = "LoadingScreen"
	surface.color = surface.get_theme_color("background")
	add_child(surface)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_child(center)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)
	var emblem := TextureRect.new()
	emblem.texture = load("res://ui/icons/menu_emblem.svg")
	emblem.custom_minimum_size = Vector2(88, 88)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(emblem)
	heading = Label.new()
	heading.text = tr("Loading your city")
	heading.theme_type_variation = "AtlasTitle"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)
	status = Label.new()
	status.text = tr("Preparing your city…")
	status.theme_type_variation = "Caption"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	indicator = Control.new()
	indicator.theme_type_variation = "LoadingScreen"
	indicator.custom_minimum_size.y = 4
	indicator.draw.connect(draw_indicator)
	column.add_child(indicator)
	back = Button.new()
	back.text = tr("Main menu")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.visible = false
	column.add_child(back)
	get_viewport().size_changed.connect(fit)
	UiAccess.changed.connect(fit)
	fit()

func fit() -> void:
	column.custom_minimum_size.x = minf(520, maxf(120, get_viewport().get_visible_rect().size.x - 64))

func _input(_event: InputEvent) -> void:
	if not failed:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not UiAccess.reduced_motion:
		phase = fmod(phase + delta * .55, 1.0)
	indicator.queue_redraw()

func draw_indicator() -> void:
	var bounds := Rect2(Vector2.ZERO, indicator.size)
	indicator.draw_rect(bounds, indicator.get_theme_color("track"))
	if UiAccess.reduced_motion:
		indicator.draw_rect(bounds, indicator.get_theme_color("still_activity"))
	else:
		var width := bounds.size.x * .22
		var x := phase * (bounds.size.x + width) - width
		indicator.draw_rect(Rect2(maxf(0, x), 0, maxf(0, minf(x + width, bounds.size.x) - maxf(0, x)), bounds.size.y), indicator.get_theme_color("activity"))

# Two scene-tree frames let layout settle; a draw barrier confirms the screen was
# presented before synchronous native/model work. Headless validation has no draw signal.
func present() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func set_status(text: String) -> void:
	status.text = text

func fail(action: Callable) -> void:
	failed = true
	set_process(false)
	heading.text = tr("The city could not be loaded")
	status.text = ""
	indicator.hide()
	back.show()
	back.pressed.connect(func():
		dismiss()
		action.call())
	back.grab_focus()

func dismiss() -> void:
	remove_from_group(GROUP)
	hide()
	set_process_input(false)
	queue_free()
