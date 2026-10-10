extends "res://scripts/terrain_forest.gd"
# Original streetscape on the OUTSIDE edges of the native two/three-cell roads.
# The median is walkable in the core, so its centre must remain paved and clear.
const Presentation = preload("res://scripts/terrain_presentation.gd")
const Streets = preload("res://scripts/street_layout.gd")
const Furniture = preload("res://scripts/street_furniture.gd")

func _init() -> void:
	super()
	# Outside edges depend on the flank and the cell beyond it, across sections.
	neighbor_radius = 2
	var stone := StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.roughness = .62
	for kind in ["street_statue","street_planter","street_bench"]: materials[kind] = stone

func signature(tile: Array) -> Array:
	return super(tile) + [tile[8] if tile.size() >= 9 else 0]

func kind_at(cell: Vector2i) -> int:
	return Presentation.road_kind(tiles.get(cell, []))

func layout(cell: Vector2i) -> Array:
	var kind := kind_at(cell)
	var axis := Streets.axis(tiles,cell)
	if kind < 2 or axis == Vector2i.ZERO: return []
	var along := cell.x if axis.x else cell.y
	var phase := posmod(along,8)
	if phase % 2: return []
	var result := []
	for edge in Streets.edges(tiles,cell):
		var ornament := "street_statue" if phase == 0 else ("street_bench" if phase == 4 else "street_planter")
		var item := placement(cell,ornament,71,edge,Vector3.ONE)
		var yaw := PI*.5 if axis.x else 0.0
		item.transform.basis = Basis(Vector3.UP,yaw)
		result.append(item)
		if ornament == "street_planter":
			var tree := placement(cell,"cypress" if kind == 3 else "olive",61,edge,Vector3(.22,.78,.42))
			tree.transform.basis = Basis(Vector3.UP,yaw).scaled(Vector3(.22,.78,.42))
			result.append(tree)
	return result

func mesh_for(kind: String, variant: int) -> ArrayMesh:
	if not kind.begins_with("street_"): return super(kind,variant)
	if not meshes.has(kind): meshes[kind] = Furniture.mesh(kind)
	return meshes[kind]
