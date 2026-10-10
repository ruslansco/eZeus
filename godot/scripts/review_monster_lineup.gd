extends SceneTree
# A native gallery of the sixteen real studio captures, for the art review.
const NAMES := ["cyclops","talos","hector","minotaur","satyr","medusa","maenads","harpies","calydonianboar","cerberus","chimera","sphinx","dragon","echidna","scylla","kraken"]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var board:=SubViewport.new();board.size=Vector2i(1800,1600);board.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(board)
	var canvas:=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);board.add_child(canvas)
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",0);grid.add_theme_constant_override("v_separation",0);canvas.add_child(grid)
	for name in NAMES:
		var tile:=TextureRect.new();tile.texture=ImageTexture.create_from_image(Image.load_from_file("res://captures/monsters/%s-three.png" % name))
		tile.custom_minimum_size=Vector2(450,400);tile.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;tile.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;grid.add_child(tile)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	board.get_texture().get_image().save_png("res://captures/monster-reference-lineup.png")
	print("MONSTER_LINEUP PASS 16 studio sculptures")
	quit()
