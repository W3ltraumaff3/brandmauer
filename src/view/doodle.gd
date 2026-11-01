class_name Doodle
## Static "Doodle/Paint" drawing helpers (GDD §20).
##
## Two ways to draw:
## - Immediate helpers (`circle_pts`, `rect_pts`, `text` …) for the few things that
##   change shape every frame (hazards, HUD panels, effects).
## - `Sketch`: a builder that bakes a hand-drawn figure (wobbly ink lines, fills
##   slightly misregistered against their outlines) into one ArrayMesh. Every
##   entity in the world is one cached mesh, so it costs one draw call per frame.
##
## "Boil": every shape exists in VARIANTS slightly different wobbles; the variant
## shown changes every BOIL seconds, which gives the hand-animated flicker.

const INK := Color("222222")
const PAPER := Color("f4efe1")
const VARIANTS := 3
const BOIL := 0.15
const UNIT_POINTS := 20

static var frame := 0
static var _unit_circles: Array[PackedVector2Array] = []
static var _unit_circles_hi: Array[PackedVector2Array] = []
static var _cache := {}


## Advance the boil clock (call once per frame with a running time).
static func tick(t: float) -> void:
	frame = int(t / BOIL)


## Boil variant for an entity; offsetting by its id keeps them out of sync.
static func variant(id: int) -> int:
	return posmod(frame + id, VARIANTS)


## Deterministic pseudo-random value in [-1, 1].
static func noise(seed_value: int) -> float:
	return float(posmod(hash(seed_value * 7919 + 13), 20001)) / 10000.0 - 1.0


## Desaturation amount for a Zusammenhalt stage (0 nearly grey, 4 full color).
static func desat_amount(stage: int) -> float:
	return float(4 - clampi(stage, 0, 4)) / 4.0 * 0.85


static func desat_amt(c: Color, amt: float) -> Color:
	if amt <= 0.0:
		return c
	var g := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	# Grey drifts slightly warm, like pencil on paper.
	return Color(lerpf(c.r, g * 1.02, amt), lerpf(c.g, g, amt), lerpf(c.b, g * 0.94, amt), c.a)


static func desat(c: Color, stage: int) -> Color:
	return desat_amt(c, desat_amount(stage))


# --- Immediate helpers -------------------------------------------------------

## Closed wobbly unit circle (cached per variant; `hi` = more points for big rings).
static func unit_circle(v: int, hi := false) -> PackedVector2Array:
	var arr := _unit_circles_hi if hi else _unit_circles
	if arr.is_empty():
		var n := 64 if hi else UNIT_POINTS
		for k in VARIANTS:
			var pts := PackedVector2Array()
			var off := noise(k * 31) * 0.4
			for i in n + 2:
				var a := off + TAU * float(i) / n
				var r := 1.0 + noise(k * 1000 + i / (3 if hi else 1)) * (0.02 if hi else 0.045)
				if i >= n:
					r += 0.03 * float(i - n + 1)  # overshoot past the start
				pts.append(Vector2(cos(a), sin(a)) * r)
			arr.append(pts)
	return arr[posmod(v, VARIANTS)]


## Irregular blob (puddles, splashes) as a polygon; `closed` appends the start point.
static func blob_pts(center: Vector2, r: float, v := 0, seed_value := 0, spiky := 0.12, closed := false) -> PackedVector2Array:
	var key := "b%d_%d_%d" % [posmod(v, VARIANTS), seed_value % 16, int(spiky * 100.0)]
	var unit: PackedVector2Array
	if _cache.has(key):
		unit = _cache[key]
	else:
		unit = PackedVector2Array()
		for i in 18:
			var a := TAU * i / 18.0
			var rr := 1.0 + noise(seed_value * 101 + i) * spiky + noise(v * 7 + i * 3) * 0.03
			unit.append(Vector2(cos(a), sin(a)) * rr)
		_cache[key] = unit
	var out := Transform2D(0.0, Vector2(r, r), 0.0, center) * unit
	if closed:
		out.append(out[0])
	return out


static func circle_pts(center: Vector2, r: float, v := 0) -> PackedVector2Array:
	return Transform2D(0.0, Vector2(r, r), 0.0, center) * unit_circle(v, r > 60.0)


static func ellipse_pts(center: Vector2, rx: float, ry: float, v := 0) -> PackedVector2Array:
	return Transform2D(0.0, Vector2(rx, ry), 0.0, center) * unit_circle(v)


## Wobbly closed rectangle outline (the end overshoots the start a little).
static func rect_pts(r: Rect2, v := 0, amp := 2.0) -> PackedVector2Array:
	var k := v * 17
	var p := PackedVector2Array()
	p.append(r.position + Vector2(noise(k), noise(k + 1)) * amp)
	p.append(Vector2(r.end.x, r.position.y) + Vector2(noise(k + 2), noise(k + 3)) * amp)
	p.append(r.end + Vector2(noise(k + 4), noise(k + 5)) * amp)
	p.append(Vector2(r.position.x, r.end.y) + Vector2(noise(k + 6), noise(k + 7)) * amp)
	p.append(r.position + Vector2(noise(k + 8) * amp, -noise(k + 9) * amp + 3.0))
	return p


## A wobbly line from a to b, 4 points.
static func line_pts(a: Vector2, b: Vector2, v := 0, amp := 1.5) -> PackedVector2Array:
	var d := b - a
	var n := Vector2(-d.y, d.x).normalized() * amp
	return PackedVector2Array([a, a + d * 0.33 + n * noise(v * 5 + 1), a + d * 0.66 + n * noise(v * 5 + 2), b])


## Diagonal hatch segments clipped to a circle (pairs for draw_multiline), cached.
static func hatch_circle(r: float, spacing: float, angle := 0.785) -> PackedVector2Array:
	var key := "hc%d_%d_%d" % [int(r), int(spacing * 10.0), int(angle * 100.0)]
	if _cache.has(key):
		return _cache[key]
	var out := PackedVector2Array()
	var dir := Vector2(cos(angle), sin(angle))
	var nrm := Vector2(-dir.y, dir.x)
	var d := -r + spacing * 0.5
	var i := 0
	while d < r:
		var h := sqrt(maxf(r * r - d * d, 0.0))
		var wob := noise(i) * 1.5
		out.append(nrm * d - dir * h + Vector2(wob, 0))
		out.append(nrm * d + dir * h - Vector2(0, wob))
		d += spacing
		i += 1
	_cache[key] = out
	return out


## Draw text with an optional paper-colored outline, horizontally centered on pos.x.
static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, font: Font = null,
		outline := 0, outline_col := PAPER, align := HORIZONTAL_ALIGNMENT_CENTER, width := -1.0) -> void:
	if font == null:
		font = UITheme.hand()
	var w := width
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER and width < 0.0:
		w = 2000.0
		p.x -= 1000.0
	if outline > 0:
		ci.draw_string_outline(font, p, s, align, w, size, outline, outline_col)
	ci.draw_string(font, p, s, align, w, size, col)


# --- Sketch: bakes doodles into meshes ----------------------------------------

class Sketch:
	extends RefCounted
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var rng := RandomNumberGenerator.new()
	var amt := 0.0
	var white := false
	var jit := 0.7
	var lw := 2.0
	var seg := 9.0
	var misreg := 1.3
	## Optional wash over every color (ghost bikes): fills move `tint_fill`,
	## ink lines `tint_ink` of the way toward `tint`.
	var tint := Color(0, 0, 0, 0)
	var tint_fill := 0.0
	var tint_ink := 0.0

	func _init(seed_value: int, stage := 4, white_fill := false) -> void:
		rng.seed = seed_value
		amt = Doodle.desat_amount(stage)
		white = white_fill

	## Fill color as baked: white (hit flash) or desaturated by stage.
	func fc(c: Color) -> Color:
		if white:
			return Color(1, 1, 1, c.a)
		var d := Doodle.desat_amt(c, amt)
		if tint_fill > 0.0:
			return Color(d.lerp(tint, tint_fill), c.a)
		return d

	func lc(c: Color) -> Color:
		var d := Doodle.desat_amt(c, amt)
		if tint_ink > 0.0:
			return Color(d.lerp(tint, tint_ink), c.a)
		return d

	## Soft pencil-smudge shadow: two stacked translucent ellipses (darker core).
	## Not affected by the hit flash, so a flashing figure keeps its ground contact.
	func soft_shadow(c: Vector2, rx: float, ry: float, alpha := 0.13) -> void:
		var col := Color(0.18, 0.14, 0.1, alpha)
		if tint_fill > 0.0:
			col = Color(tint.darkened(0.3), alpha)
		for k in 2:
			var f := 1.0 - 0.38 * k
			var pts := PackedVector2Array()
			for i in 14:
				var a := TAU * i / 14.0
				pts.append(c + Vector2(cos(a) * rx * f, sin(a) * ry * f) * (1.0 + rng.randf_range(-0.04, 0.04)))
			_poly_raw(pts, col)

	## Quad with a color gradient (a,b get ca; c,d get cb); final colors, no jitter.
	func grad_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color) -> void:
		verts.append(a); verts.append(b); verts.append(c)
		cols.append(ca); cols.append(ca); cols.append(cb)
		verts.append(a); verts.append(c); verts.append(d)
		cols.append(ca); cols.append(cb); cols.append(cb)

	func j(scale := 1.0) -> Vector2:
		return Vector2(rng.randf_range(-jit, jit), rng.randf_range(-jit, jit)) * scale

	func tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		verts.append(a); verts.append(b); verts.append(c)
		cols.append(col); cols.append(col); cols.append(col)

	## Filled polygon (already-final color, no jitter).
	func _poly_raw(p: PackedVector2Array, col: Color) -> void:
		var idx := Geometry2D.triangulate_polygon(p)
		if idx.is_empty():
			var ctr := Vector2.ZERO
			for q in p:
				ctr += q
			ctr /= maxf(p.size(), 1)
			for i in p.size():
				tri(ctr, p[i], p[(i + 1) % p.size()], col)
			return
		for i in range(0, idx.size(), 3):
			tri(p[idx[i]], p[idx[i + 1]], p[idx[i + 2]], col)

	## Filled polygon, slightly shifted against its outline ("misregistered").
	func fill(pts: PackedVector2Array, col: Color, shift := true) -> void:
		var off := Vector2(rng.randf_range(-misreg, misreg), rng.randf_range(-misreg, misreg)) if shift else Vector2.ZERO
		var p := PackedVector2Array()
		for q in pts:
			p.append(q + off + j(0.4))
		_poly_raw(p, fc(col))

	func _seg(a: Vector2, b: Vector2, w: float, col: Color) -> void:
		var d := b - a
		var l := d.length()
		if l < 0.01:
			return
		d /= l
		var n := Vector2(-d.y, d.x) * w * 0.5
		var a2 := a - d * w * 0.3
		var b2 := b + d * w * 0.3
		tri(a2 + n, b2 + n, b2 - n, col)
		tri(a2 + n, b2 - n, a2 - n, col)

	## Wobbly ink polyline.
	func line(pts: PackedVector2Array, w := -1.0, col := Doodle.INK, closed := false) -> void:
		if pts.size() < 2:
			return
		var ww := lw if w < 0.0 else w
		var c := lc(col)
		var p := pts.duplicate()
		if closed:
			p.append(pts[0])
			p.append(pts[0].lerp(pts[1], 0.25))  # overshoot
		var prev := p[0] + j()
		for i in range(1, p.size()):
			var a := p[i - 1]
			var b := p[i]
			var n := int(ceil(a.distance_to(b) / seg))
			var nrm := (b - a).orthogonal().normalized()
			for k in range(1, n + 1):
				var t := float(k) / n
				var q := a.lerp(b, t)
				q += nrm * rng.randf_range(-jit, jit) * 0.8 if k < n else j()
				_seg(prev, q, ww, c)
				prev = q

	func line2(a: Vector2, b: Vector2, w := -1.0, col := Doodle.INK) -> void:
		line(PackedVector2Array([a, b]), w, col)

	func ellipse_pts(center: Vector2, rx: float, ry: float, n := 0, start := 0.0, arc := TAU) -> PackedVector2Array:
		if n <= 0:
			n = clampi(int((rx + ry) * 0.6), 7, 28)
		var pts := PackedVector2Array()
		var full := arc >= TAU - 0.001
		var cnt := n if full else n + 1
		for i in cnt:
			var a := start + arc * float(i) / n
			var r := 1.0 + rng.randf_range(-0.05, 0.05)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry) * r)
		return pts

	## Filled + outlined ellipse.
	func ellipse(center: Vector2, rx: float, ry: float, fill_col: Color, outline := true, w := -1.0) -> void:
		var pts := ellipse_pts(center, rx, ry)
		if fill_col.a > 0.0:
			fill(pts, fill_col)
		if outline:
			line(pts, w, Doodle.INK, true)

	func circle(center: Vector2, r: float, fill_col: Color, outline := true, w := -1.0) -> void:
		ellipse(center, r, r, fill_col, outline, w)

	## Small filled dot without outline.
	func dot(center: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 7:
			var a := TAU * i / 7.0
			pts.append(center + Vector2(cos(a), sin(a)) * r)
		_poly_raw(pts, lc(col) if not white or col.v < 0.3 else fc(col))

	## Filled + outlined polygon.
	func shape(pts: PackedVector2Array, fill_col: Color, outline := true, w := -1.0) -> void:
		if fill_col.a > 0.0:
			fill(pts, fill_col)
		if outline:
			line(pts, w, Doodle.INK, true)

	func rect(r: Rect2, fill_col: Color, outline := true, w := -1.0) -> void:
		shape(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
				fill_col, outline, w)

	## Thick colored stroke with ink edges (limbs, straps, poles).
	func stroke(a: Vector2, b: Vector2, w: float, col: Color) -> void:
		line2(a, b, w + 2.4, Doodle.INK)
		_seg(a, b, w, fc(col))

	## Hatch lines clipped to a polygon.
	func hatch(poly: PackedVector2Array, spacing: float, angle: float, col: Color, w := 1.0) -> void:
		var bb := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			bb = bb.expand(q)
		var ctr := bb.get_center()
		var rad := bb.size.length() * 0.5
		var dir := Vector2(cos(angle), sin(angle))
		var nrm := Vector2(-dir.y, dir.x)
		var d := -rad
		while d < rad:
			var a := ctr + nrm * d - dir * rad
			var b := ctr + nrm * d + dir * rad
			for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), poly):
				if piece.size() >= 2:
					_seg(piece[0] + j(), piece[piece.size() - 1] + j(), w, lc(col))
			d += spacing

	## Star / burst polygon.
	func star_pts(center: Vector2, r_out: float, r_in: float, points := 5, rot := -PI / 2) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in points * 2:
			var r := r_out if i % 2 == 0 else r_in
			var a := rot + PI * i / points
			pts.append(center + Vector2(cos(a), sin(a)) * r * (1.0 + rng.randf_range(-0.08, 0.08)))
		return pts

	func is_empty() -> bool:
		return verts.is_empty()

	func build() -> ArrayMesh:
		var m := ArrayMesh.new()
		if verts.is_empty():
			return m
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_COLOR] = cols
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
		return m
