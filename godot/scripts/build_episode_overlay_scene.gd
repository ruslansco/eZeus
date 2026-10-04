extends SceneTree
# One-off generator for res://ui/episode_overlay.tscn: the full-screen layer that carries the episode card over the
# city (result of an episode, choice of colony, briefing of the next one, end of the adventure, defeat). After
# generation the .tscn is the source of truth: edit it in the Godot editor, and do not rerun this script over edits.
#   godot --headless --path godot --script res://scripts/build_episode_overlay_scene.gd

const OUTPUT := "res://ui/episode_overlay.tscn"
var overlay_root: CanvasLayer

func make(type: Variant, node_name: String, parent: Node, unique := true) -> Node:
	var node: Node = type.new()
	node.name = node_name
	parent.add_child(node)
	node.owner = overlay_root
	if unique:
		node.unique_name_in_owner = true
	return node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	overlay_root = CanvasLayer.new()
	overlay_root.name = "EpisodeOverlay"
	overlay_root.layer = 30
	overlay_root.visible = false
	overlay_root.set_script(load("res://ui/episode_overlay.gd"))
	var themed: Control = make(Control, "Themed", overlay_root, false)
	themed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	themed.theme = load("res://ui/lapis_gold.tres")
	var dim: ColorRect = make(ColorRect, "Dim", themed, false)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(.01, .02, .06, .72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var center: CenterContainer = make(CenterContainer, "Center", themed, false)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = make(PanelContainer, "Panel", center, false)
	panel.custom_minimum_size = Vector2(820, 560)
	var card: Node = load("res://ui/episode_card.tscn").instantiate()
	card.name = "Card"
	card.unique_name_in_owner = true
	panel.add_child(card)
	card.owner = overlay_root
	var scene := PackedScene.new()
	var packed := scene.pack(overlay_root)
	var saved := ResourceSaver.save(scene, OUTPUT)
	print("OVERLAY packed=", packed, " saved=", saved)
	quit(0 if packed == OK and saved == OK else 1)
