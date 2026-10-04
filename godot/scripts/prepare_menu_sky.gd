extends SceneTree
# Optional development preparation from the retained menu HDR source. No downloads.
# Convert RGBE to float BEFORE Lanczos resizing; resizing RGBE first loses the sky.
func _initialize() -> void:
	var source := ProjectSettings.globalize_path("res://../../art/menu/backdrop/assets/kloofendal_48d_partly_cloudy_puresky_8k.hdr")
	var image := Image.load_from_file(source)
	if image == null or image.is_empty():
		push_error("Retained menu sky source is unavailable: "+source)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBF)
	image.resize(2048,1024,Image.INTERPOLATE_LANCZOS)
	var result := image.save_exr("res://assets/menu/cloud_sky_2k.exr")
	print("MENU_SKY_PREPARE ","PASS" if result==OK else "FAIL")
	quit(0 if result==OK else 1)
