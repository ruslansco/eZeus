extends RefCounted
# Buildings turn their front to the street they stand on. Presentation only: footprints, native
# rules and the core's stored facing are unchanged; this only picks the quarter turn the model is
# drawn with, for the placement ghost and the built city alike.
#
# The models come from the SDL kits, which are built to be seen from the +X/+Y corner, so +X and +Y
# are the dressed faces and -X/-Y the backs (yards, clutter). FRONTS names the face with the door
# where the kit has one (art/common_house/levels.py); other models use their dressed corner.
# Sides and fronts count in quarter turns: 0 +x, 1 +y, 2 -x, 3 -y. A model turned by k quarter
# turns (model_basis) shows its face f toward side (f + k) % 4.
const StreetSetback = preload("res://scripts/street_setback.gd")
const CORNER := -1
const FRONTS := {
	"common_house_0a": 1, "common_house_1a": 1, "common_house_2a": 0, "common_house_3a": 0,
	"common_house_4a": CORNER, "common_house_5a": 1, "common_house_6a": 1,
}
# Facing that means something to the engine or to the layout of a piece stays as it is.
const KEEP := ["pier", "gatehouse", "fishery", "urchin_quay", "trireme_wharf", "stadium", "roadblock", "hippodrome", "palace", "vendor", "stall"]

static func applies(asset: String) -> bool:
	if not StreetSetback.applies(asset):
		return false
	for part in KEEP:
		if asset.contains(part):
			return false
	return true

# How many tiles of road run along each side of the footprint.
static func road_sides(tiles: Dictionary, x: int, y: int, w: int, h: int) -> Array[int]:
	var count: Array[int] = [0, 0, 0, 0]
	for index in h:
		count[0] += 1 if StreetSetback.road(tiles, Vector2i(x + w, y + index)) else 0
		count[2] += 1 if StreetSetback.road(tiles, Vector2i(x - 1, y + index)) else 0
	for index in w:
		count[1] += 1 if StreetSetback.road(tiles, Vector2i(x + index, y + h)) else 0
		count[3] += 1 if StreetSetback.road(tiles, Vector2i(x + index, y - 1)) else 0
	return count

# The quarter turn to draw with: the front looks at the longest stretch of road beside the
# footprint. `preferred` is the stored facing (the T key's choice); it is kept without a road
# and breaks ties, so T picks the street when roads run equally on several sides (all around).
static func facing(tiles: Dictionary, asset: String, x: int, y: int, w: int, h: int, preferred: int) -> int:
	if not applies(asset):
		return preferred
	var sides := road_sides(tiles, x, y, w, h)
	if sides.max() == 0:
		return preferred
	var front: int = FRONTS.get(asset, CORNER)
	var best := preferred
	var best_score := -1.0
	for turn in 4:
		# A long building only turns end for end, so the model keeps its footprint.
		if w != h and (turn - preferred) % 2 != 0:
			continue
		var score := 0.0
		if front == CORNER:
			# Both dressed faces count; the back faces must not look at the street.
			score = sides[turn % 4] + sides[(turn + 1) % 4] - (sides[(turn + 2) % 4] + sides[(turn + 3) % 4]) * .5
		else:
			score = sides[(front + turn) % 4] * 2.0 + sides[(front + turn + 1) % 4] * .1 + sides[(front + turn + 3) % 4] * .1
		score += .01 if turn == posmod(preferred, 4) else 0.0
		if score > best_score:
			best_score = score
			best = turn
	return best
