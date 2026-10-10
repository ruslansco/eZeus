extends Node
# Hardware cursors follow the existing Control cursor shapes. No input interception,
# per-frame work, mouse-mode changes or simulation state is needed.
const MANIFEST := "res://assets/cursors/runtime.json"
const SHAPES := {
	Input.CURSOR_ARROW:"arrow", Input.CURSOR_IBEAM:"text",
	Input.CURSOR_POINTING_HAND:"point", Input.CURSOR_CROSS:"cross",
	Input.CURSOR_WAIT:"wait", Input.CURSOR_BUSY:"busy",
	Input.CURSOR_DRAG:"drag", Input.CURSOR_CAN_DROP:"point",
	Input.CURSOR_FORBIDDEN:"forbidden", Input.CURSOR_VSIZE:"vertical",
	Input.CURSOR_HSIZE:"horizontal", Input.CURSOR_BDIAGSIZE:"back_diagonal",
	Input.CURSOR_FDIAGSIZE:"forward_diagonal", Input.CURSOR_MOVE:"cross",
	Input.CURSOR_VSPLIT:"vertical", Input.CURSOR_HSPLIT:"horizontal",
	Input.CURSOR_HELP:"help",
}
var manifest: Dictionary
var originals: Dictionary = {}
var cache: Dictionary = {}
var textures: Dictionary = {}
var hotspots: Dictionary = {}
var installed_ui := 0
var cursor_size := 0
var registered_shapes: Array[int] = []

func _ready() -> void:
	set_process(false)
	manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for name in manifest.cursors:
		var texture := load(str(manifest.cursors[name].path)) as Texture2D
		originals[name] = texture.get_image()
	get_node("/root/UiAccess").changed.connect(refresh)
	refresh()

func refresh() -> void:
	var ui: int = get_node("/root/UiAccess").ui_size
	if installed_ui == ui: return
	var factor := ui/100.0
	if not cache.has(ui):
		var images := {}
		var points := {}
		for name in originals:
			var image: Image = originals[name].duplicate()
			var edge := roundi(int(manifest.base_size)*factor)
			if image.get_width() != edge: image.resize(edge,edge,Image.INTERPOLATE_LANCZOS)
			images[name] = ImageTexture.create_from_image(image)
			var point: Array = manifest.cursors[name].hotspot
			points[name] = (Vector2(point[0],point[1])*factor).round()
		cache[ui] = {"textures":images,"hotspots":points}
	textures = cache[ui].textures
	hotspots = cache[ui].hotspots
	cursor_size = roundi(int(manifest.base_size)*factor)
	installed_ui = ui
	registered_shapes.clear()
	if DisplayServer.get_name() == "headless": return
	for shape in SHAPES:
		var name: String = SHAPES[shape]
		Input.set_custom_mouse_cursor(textures[name],shape,hotspots[name])
		registered_shapes.append(shape)
