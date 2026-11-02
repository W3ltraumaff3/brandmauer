class_name Arena
extends RefCounted
## Arena geometry and Brandmauer tunables (docs/GDD.md §5a, D-082).
## Pure static data and math, shared by the Sim, the view, the HUD and tools.
##
## The Brandmauer is a rectangle of four straight walls around the inner arena,
## with a fixed concrete pillar in every corner. Behind every wall lies the
## staging area where AfD enemies gather. Segment order is clockwise from the
## top-left corner:
##   0..11 top (left -> right), 12..18 right (top -> bottom),
##   19..30 bottom (right -> left), 31..37 left (bottom -> top).

const SIZE := Vector2(1904, 1224)          # whole sheet: staging + wall + arena
const WALL_OUT := 78.0                     # sheet edge -> outer wall face
const WALL_IN := 102.0                     # sheet edge -> inner wall face
const WALL_MID := 90.0                     # sheet edge -> wall centre line
const WALL_THICK := 24.0
const STAGING := 40.0                      # AfD staging line, distance from the sheet edge
const INNER := Rect2(102, 102, 1700, 1020)  # where players live (+21 % over the old 1600 x 898)
const CENTER := Vector2(952, 612)
const STAGING_RECT := Rect2(40, 40, 1824, 1144)
const SEG_H := 12                          # segments on the top and bottom walls
const SEG_V := 7                           # segments on the left and right walls
const WALL_SEGMENTS := 38
const SEG_LEN_H := 1700.0 / 12.0           # 141.7 px
const SEG_LEN_V := 1020.0 / 7.0            # 145.7 px

enum { TOP, RIGHT, BOTTOM, LEFT }
const SIDE_FIRST := [0, 12, 19, 31]
const SIDE_COUNT := [12, 7, 12, 7]
const SIDE_IN := [Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]   # into the arena

## Brandmauer tunables (GDD §5a). Everything that scales the wall pressure.
const WALL := {
	"start_holes_max": 4,      # one start hole per player, at most this many (top, bottom, left, right)
	"side_base": 1.0,          # AfD spawn side weight ...
	"side_hole": 3.0,          # ... plus this per hole on that side
	"staging_speed": 1.5,      # speed factor of AfD enemies walking behind the wall to a hole
	"vote_per_player": 0.25,   # JU vote speed: +25 % per extra player ...
	"vote_per_wave": 0.03,     # ... and +3 % per wave after the first
	"inner_spawn_inset": 20.0, # Union/Kapital spawn this far inside the wall
	"repair_reach": 60.0,      # Antifa-Ortsgruppe player repair: max distance to the hole
	"abschiebe_band": 70.0,    # Abschiebezone width along the inside of every wall
}

const _START_SIDES := [TOP, BOTTOM, LEFT, RIGHT]


static func side_of(seg: int) -> int:
	if seg < 12:
		return TOP
	if seg < 19:
		return RIGHT
	if seg < 31:
		return BOTTOM
	return LEFT


static func seg_len(seg: int) -> float:
	return SEG_LEN_H if side_of(seg) % 2 == 0 else SEG_LEN_V


## The wall block of a segment in world coordinates.
static func seg_rect(seg: int) -> Rect2:
	var side := side_of(seg)
	var k: int = seg - int(SIDE_FIRST[side])
	match side:
		TOP:
			return Rect2(WALL_IN + k * SEG_LEN_H, WALL_OUT, SEG_LEN_H, WALL_THICK)
		RIGHT:
			return Rect2(SIZE.x - WALL_IN, WALL_IN + k * SEG_LEN_V, WALL_THICK, SEG_LEN_V)
		BOTTOM:
			return Rect2(SIZE.x - WALL_IN - (k + 1) * SEG_LEN_H, SIZE.y - WALL_IN, SEG_LEN_H, WALL_THICK)
	return Rect2(WALL_OUT, SIZE.y - WALL_IN - (k + 1) * SEG_LEN_V, WALL_THICK, SEG_LEN_V)


static func seg_center(seg: int) -> Vector2:
	return seg_rect(seg).get_center()


static func inward(seg: int) -> Vector2:
	return SIDE_IN[side_of(seg)]


## A point inside the arena, `d` px in front of the segment's inner face.
static func seg_inner(seg: int, d: float) -> Vector2:
	return seg_center(seg) + inward(seg) * (WALL_THICK * 0.5 + d)


## The point on the staging line right behind a segment.
static func seg_staging(seg: int) -> Vector2:
	return seg_center(seg) - inward(seg) * (WALL_MID - STAGING)


## Mesh frame of a segment for the view: the top wall's local frame (x along the
## wall from 0 to seg_len, y from WALL_OUT to WALL_IN, +y into the arena)
## rotated onto its side.
static func seg_xform(seg: int) -> Transform2D:
	var side := side_of(seg)
	var k: int = seg - int(SIDE_FIRST[side])
	var o := Vector2.ZERO
	match side:
		TOP:
			o = Vector2(WALL_IN + k * SEG_LEN_H, 0)
		RIGHT:
			o = Vector2(SIZE.x, WALL_IN + k * SEG_LEN_V)
		BOTTOM:
			o = Vector2(SIZE.x - WALL_IN - k * SEG_LEN_H, SIZE.y)
		LEFT:
			o = Vector2(0, SIZE.y - WALL_IN - k * SEG_LEN_V)
	return Transform2D(side * PI * 0.5, o)


## The four corner pillars (always intact).
static func pillars() -> Array[Rect2]:
	return [Rect2(WALL_OUT, WALL_OUT, WALL_THICK, WALL_THICK),
		Rect2(SIZE.x - WALL_IN, WALL_OUT, WALL_THICK, WALL_THICK),
		Rect2(SIZE.x - WALL_IN, SIZE.y - WALL_IN, WALL_THICK, WALL_THICK),
		Rect2(WALL_OUT, SIZE.y - WALL_IN, WALL_THICK, WALL_THICK)]


## What of the wall is at p: a segment index, -2 for a corner pillar, -1 for none.
static func wall_at(p: Vector2) -> int:
	if p.x < WALL_OUT or p.x > SIZE.x - WALL_OUT or p.y < WALL_OUT or p.y > SIZE.y - WALL_OUT:
		return -1
	var in_x := p.x > WALL_IN and p.x < SIZE.x - WALL_IN
	var in_y := p.y > WALL_IN and p.y < SIZE.y - WALL_IN
	if in_x and in_y:
		return -1
	if not in_x and not in_y:
		return -2
	if in_x:
		if p.y <= WALL_IN:
			return clampi(int((p.x - WALL_IN) / SEG_LEN_H), 0, SEG_H - 1)
		return 19 + clampi(int((SIZE.x - WALL_IN - p.x) / SEG_LEN_H), 0, SEG_H - 1)
	if p.x >= SIZE.x - WALL_IN:
		return 12 + clampi(int((p.y - WALL_IN) / SEG_LEN_V), 0, SEG_V - 1)
	return 31 + clampi(int((SIZE.y - WALL_IN - p.y) / SEG_LEN_V), 0, SEG_V - 1)


## Every piece of wall the line a -> b crosses (segment indices, -2 = pillar).
## Crossing = passing the wall's centre line on any of the four sides.
static func wall_crossings(a: Vector2, b: Vector2) -> PackedInt32Array:
	var out := PackedInt32Array()
	for line in [[1, WALL_MID], [1, SIZE.y - WALL_MID], [0, WALL_MID], [0, SIZE.x - WALL_MID]]:
		var axis: int = line[0]
		var c: float = line[1]
		var da: float = a[axis] - c
		var db: float = b[axis] - c
		if da * db > 0.0 or da == db:
			continue
		var w := wall_at(a.lerp(b, da / (da - db)))
		if w != -1:
			out.append(w)
	return out


## Distance from p (inside the arena) to the nearest inner wall face.
static func edge_dist(p: Vector2) -> float:
	return minf(minf(p.x - INNER.position.x, INNER.end.x - p.x), minf(p.y - INNER.position.y, INNER.end.y - p.y))


static func nearest_side(p: Vector2) -> int:
	var d := [p.y - INNER.position.y, INNER.end.x - p.x, INNER.end.y - p.y, p.x - INNER.position.x]
	var best := 0
	for i in 4:
		if float(d[i]) < float(d[best]):
			best = i
	return best


## Unit vector from p toward the nearest wall ("Remigration" pushes).
static func toward_wall(p: Vector2) -> Vector2:
	return -(SIDE_IN[nearest_side(p)] as Vector2)


## The wall segment straight across from p on its nearest wall (-1 at a pillar).
static func facing_seg(p: Vector2) -> int:
	var side := nearest_side(p)
	var q := p
	match side:
		TOP:
			q = Vector2(p.x, WALL_MID)
		RIGHT:
			q = Vector2(SIZE.x - WALL_MID, p.y)
		BOTTOM:
			q = Vector2(p.x, SIZE.y - WALL_MID)
		LEFT:
			q = Vector2(WALL_MID, p.y)
	var w := wall_at(q)
	return w if w >= 0 else -1


## Keeps a circle of radius r inside the arena.
static func clamp_inner(p: Vector2, r: float) -> Vector2:
	return Vector2(clampf(p.x, INNER.position.x + r, INNER.end.x - r), clampf(p.y, INNER.position.y + r, INNER.end.y - r))


static func is_inside(p: Vector2, r: float) -> bool:
	return p.x >= INNER.position.x + r and p.x <= INNER.end.x - r and p.y >= INNER.position.y + r and p.y <= INNER.end.y - r


# --- Walking around a rectangle (staging line, inner edge) ----------------------

static func perimeter(r: Rect2) -> float:
	return 2.0 * (r.size.x + r.size.y)


## Clockwise distance from r's top-left corner to the point of r's outline closest to p.
static func perimeter_param(r: Rect2, p: Vector2) -> float:
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	var dt := q.y - r.position.y
	var dr := r.end.x - q.x
	var db := r.end.y - q.y
	var dl := q.x - r.position.x
	var m := minf(minf(dt, dr), minf(db, dl))
	if m == dt:
		return q.x - r.position.x
	if m == dr:
		return r.size.x + q.y - r.position.y
	if m == db:
		return r.size.x + r.size.y + r.end.x - q.x
	return 2.0 * r.size.x + r.size.y + r.end.y - q.y


static func perimeter_point(r: Rect2, s: float) -> Vector2:
	s = fposmod(s, perimeter(r))
	if s < r.size.x:
		return Vector2(r.position.x + s, r.position.y)
	s -= r.size.x
	if s < r.size.y:
		return Vector2(r.end.x, r.position.y + s)
	s -= r.size.y
	if s < r.size.x:
		return Vector2(r.end.x - s, r.end.y)
	s -= r.size.x
	return Vector2(r.position.x, r.end.y - s)


## Signed shortest way from s0 to s1 around r's outline.
static func perimeter_delta(r: Rect2, s0: float, s1: float) -> float:
	var per := perimeter(r)
	return fposmod(s1 - s0 + per * 0.5, per) - per * 0.5


# --- Wall pressure (GDD §5a) ------------------------------------------------------

## Start holes: one per player (max 4), middle of top, bottom, left, right.
static func start_holes(players: int) -> Array[int]:
	var out: Array[int] = []
	for i in clampi(players, 1, int(WALL["start_holes_max"])):
		var side: int = _START_SIDES[i]
		out.append(int(SIDE_FIRST[side]) + int(SIDE_COUNT[side]) / 2)
	return out


## Factor on the JU vote speed (vote time is divided by it).
static func vote_speed(players: int, wave: int) -> float:
	return 1.0 + float(WALL["vote_per_player"]) * maxi(0, players - 1) + float(WALL["vote_per_wave"]) * maxi(0, wave - 1)


## AfD spawn weight of each side: base + per hole on it.
static func side_weights(wall: Array[bool]) -> Array[float]:
	var w: Array[float] = []
	for side in 4:
		var holes := 0
		for i in int(SIDE_COUNT[side]):
			if not wall[int(SIDE_FIRST[side]) + i]:
				holes += 1
		w.append(float(WALL["side_base"]) + float(WALL["side_hole"]) * holes)
	return w


## A point on the staging line behind `side`, t = 0..1 along the wall.
static func staging_point(side: int, t: float) -> Vector2:
	match side:
		TOP:
			return Vector2(lerpf(INNER.position.x, INNER.end.x, t), STAGING)
		RIGHT:
			return Vector2(SIZE.x - STAGING, lerpf(INNER.position.y, INNER.end.y, t))
		BOTTOM:
			return Vector2(lerpf(INNER.end.x, INNER.position.x, t), SIZE.y - STAGING)
	return Vector2(STAGING, lerpf(INNER.end.y, INNER.position.y, t))


## Which side's staging area p is in (for tests and the view), by the nearest sheet edge.
static func staging_side(p: Vector2) -> int:
	var d := [p.y, SIZE.x - p.x, SIZE.y - p.y, p.x]
	var best := 0
	for i in 4:
		if float(d[i]) < float(d[best]):
			best = i
	return best
