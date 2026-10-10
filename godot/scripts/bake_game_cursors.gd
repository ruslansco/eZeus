extends SceneTree
# Build small lossless hardware textures; preserve the generated source atlas.
const SOURCE := "res://assets/cursors/olympian_cursors_v1.png"
const DIRECTORY := "res://assets/cursors/runtime"
const BASE_SIZE := 48
const ART_SIZE := 38
const NAMES := ["arrow","point","text","cross","wait","busy","drag","forbidden"]

func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Cursor source atlas could not be read"); quit(1); return
	var records := {}
	for index in NAMES.size():
		var column := index%4
		var row := index/4
		var start := Vector2i(roundi(column*source.get_width()/4.0),roundi(row*source.get_height()/2.0))
		var end := Vector2i(roundi((column+1)*source.get_width()/4.0),roundi((row+1)*source.get_height()/2.0))
		var cell := source.get_region(Rect2i(start,end-start))
		var bounds := alpha_bounds(cell)
		var image := cell.get_region(bounds)
		var hotspot := Vector2(image.get_size())*.5
		if NAMES[index] in ["arrow","point","busy"]: hotspot = upper_tip(image)
		var factor := ART_SIZE/float(maxi(image.get_width(),image.get_height()))
		image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
		var padding := (Vector2i(BASE_SIZE,BASE_SIZE)-image.get_size())/2
		var result := Image.create(BASE_SIZE,BASE_SIZE,false,Image.FORMAT_RGBA8)
		result.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),padding)
		var path := DIRECTORY.path_join(NAMES[index]+".png")
		if result.save_png(path) != OK: push_error("Could not save "+path); quit(1); return
		hotspot = (hotspot*factor+Vector2(padding)).round()
		records[NAMES[index]] = {"path":path,"hotspot":[int(hotspot.x),int(hotspot.y)],"crop":[start.x+bounds.position.x,start.y+bounds.position.y,bounds.size.x,bounds.size.y]}
	for name in ["horizontal","vertical","back_diagonal","forward_diagonal","help"]:
		var image := Image.load_from_file("res://assets/cursors/"+name+".svg")
		if image == null: push_error("Cursor vector could not be read: "+name); quit(1); return
		image.convert(Image.FORMAT_RGBA8)
		var path := DIRECTORY.path_join(name+".png")
		if image.save_png(path) != OK: push_error("Could not save "+path); quit(1); return
		records[name] = {"path":path,"hotspot":[24,24],"source":name+".svg"}
	var manifest := {"version":1,"source":SOURCE,"source_sha256":FileAccess.get_sha256(SOURCE),"source_size":[source.get_width(),source.get_height()],"base_size":BASE_SIZE,"art_size":ART_SIZE,"cursors":records}
	var file := FileAccess.open("res://assets/cursors/runtime.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n"); file.close()
	print("CURSOR_BAKE PASS textures=",records.size()," base_size=",BASE_SIZE)
	quit()

func alpha_bounds(image: Image) -> Rect2i:
	var low := image.get_size()
	var high := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x,y).a > .1:
				low.x = mini(low.x,x); low.y = mini(low.y,y)
				high.x = maxi(high.x,x+1); high.y = maxi(high.y,y+1)
	return Rect2i(low,high-low)

func upper_tip(image: Image) -> Vector2:
	for y in image.get_height():
		var total := 0.0
		var count := 0
		for x in image.get_width():
			if image.get_pixel(x,y).a > .5: total += x; count += 1
		if count > 0: return Vector2(total/count,y)
	return Vector2.ZERO
