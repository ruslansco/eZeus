extends RefCounted
# How much of a mesh's silhouette a set of triangles keeps: the cells they touch along each of the three axes, over a box shared
# with the mesh they simplify, so the full mesh and a LOD of it compare. The grid is as coarse as the LOD's own error (`cell`, in
# model units): a roof that a LOD deletes loses most of its cells, while a thin rail that moves by less than the error does not.
# Used by lod_guard.gd and audit_lod_coverage.gd to find LODs that lose a roof or a wall they should keep.
const MAX_CELLS := 64
const MIN_CELLS := 3

# Cells touched along each axis (top, front, side views), `cell` model units wide (a fixed 64-cell grid when 0).
func occupancy(vertices: PackedVector3Array, indices: PackedInt32Array, low: Vector3, size: Vector3, cell := 0.0) -> PackedInt32Array:
	var views := [[0, 2], [0, 1], [2, 1]]   # drop y (top), drop z (front), drop x (side)
	var result := PackedInt32Array()
	for view in views:
		var a: int = view[0]
		var b: int = view[1]
		var na := cells(size[a], cell)
		var nb := cells(size[b], cell)
		var grid := PackedByteArray()
		grid.resize(na * nb)
		var sa: float = maxf(size[a], 1e-5)
		var sb: float = maxf(size[b], 1e-5)
		for i in range(0, indices.size() - 2, 3):
			var p: Array = []
			var lo := Vector2(1e9, 1e9)
			var hi := Vector2(-1e9, -1e9)
			for k in 3:
				var v := vertices[indices[i + k]]
				var q := Vector2((v[a] - low[a]) / sa * na, (v[b] - low[b]) / sb * nb)
				p.append(q)
				lo = lo.min(q)
				hi = hi.max(q)
			var min_x := clampi(int(floorf(lo.x)), 0, na - 1)
			var max_x := clampi(int(floorf(hi.x)), 0, na - 1)
			var min_y := clampi(int(floorf(lo.y)), 0, nb - 1)
			var max_y := clampi(int(floorf(hi.y)), 0, nb - 1)
			if (max_x - min_x + 1) * (max_y - min_y + 1) > 4096:
				continue
			# A triangle within a cell or two touches every cell its box does; a larger one covers the cells whose centre it holds
			# (and its corners' cells, so a sliver is not lost).
			var small := max_x - min_x <= 1 and max_y - min_y <= 1
			for x in range(min_x, max_x + 1):
				for y in range(min_y, max_y + 1):
					if grid[y * na + x] == 0 and (small or inside(p, Vector2(x + .5, y + .5))):
						grid[y * na + x] = 1
			if not small:
				for q in p:
					grid[clampi(int(floorf(q.y)), 0, nb - 1) * na + clampi(int(floorf(q.x)), 0, na - 1)] = 1
		var count := 0
		for value in grid:
			count += value
		result.append(count)
	return result

func cells(extent: float, cell: float) -> int:
	if cell <= 0.0:
		return MAX_CELLS
	return clampi(ceili(extent / cell), MIN_CELLS, MAX_CELLS)

func inside(p: Array, q: Vector2) -> bool:
	var d1: float = (q - p[1]).cross(p[0] - p[1])
	var d2: float = (q - p[2]).cross(p[1] - p[2])
	var d3: float = (q - p[0]).cross(p[2] - p[0])
	return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))

# The worst share of the full mesh's occupancy that `indices` keeps, on a grid as coarse as `cell`; 1 when nothing is lost.
func kept(vertices: PackedVector3Array, full_indices: PackedInt32Array, indices: PackedInt32Array, low: Vector3, size: Vector3, cell: float) -> float:
	var full := occupancy(vertices, full_indices, low, size, cell)
	var now := occupancy(vertices, indices, low, size, cell)
	var worst := 1.0
	for axis in 3:
		if full[axis] > 12:
			worst = minf(worst, float(now[axis]) / full[axis])
	return worst
