extends RefCounted
# Same bitmap mapping as eBitmapWidget; installed loose overrides take precedence over interface.e.
# Metadata only is bundled. Keep the commercial/development artwork's existing provenance and release gates.
const DATA := "res://data/adventure_art.json"
var entries: Array = []
var cache := {}
var loaded_paths := {}

func texture(engine: String, bitmap: int) -> Texture2D:
	if cache.has(bitmap):
		return cache[bitmap]
	if entries.is_empty():
		entries = JSON.parse_string(FileAccess.get_file_as_string(DATA)).entries
	if bitmap < 0 or bitmap >= entries.size():
		return null
	var entry: Dictionary = entries[bitmap]
	var installation := engine.get_base_dir()
	var image: Image = null
	var origin := ""
	var paths := [installation.path_join("Textures").path_join(entry.loose)]
	if not String(entry.shared).is_empty():
		paths.append(installation.path_join("Textures").path_join(entry.shared))
		paths.append(installation.path_join("DATA").path_join(String(entry.shared).get_file()))
	for path in paths:
		if FileAccess.file_exists(path):
			image = Image.load_from_file(path)
			if image != null and not image.is_empty():
				origin = path
				break
	if image == null or image.is_empty():
		var file := FileAccess.open(engine.path_join("interface.e"), FileAccess.READ)
		if file == null or int(entry.offset) + int(entry.length) > file.get_length():
			return null
		file.seek(int(entry.offset))
		var bytes := file.get_buffer(int(entry.length))
		image = Image.new()
		var error := image.load_png_from_buffer(bytes) if entry.format == "png" else image.load_jpg_from_buffer(bytes)
		if error != OK:
			return null
		origin = "interface.e:%d" % int(entry.offset)
	if not entry.crop.is_empty():
		var crop: Array = entry.crop
		image = image.get_region(Rect2i(int(crop[0]), int(crop[1]), int(crop[2]), int(crop[3])))
	# A bounded cache: 18 images at at most 960 pixels, independent of installed full-screen resolution.
	if image.get_width() > 960:
		image.resize(960, roundi(960.0 * image.get_height() / image.get_width()), Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	var result := ImageTexture.create_from_image(image)
	cache[bitmap] = result
	loaded_paths[bitmap] = origin
	return result
