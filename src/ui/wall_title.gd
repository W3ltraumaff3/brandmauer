class_name WallTitle
extends Control
## The "BRANDMAUER" logo: a wobbly doodled brick wall with a hole knocked into
## it (bricks lying in front), the title painted across it.

const ROWS := 5
const BRICK := Vector2(64, 26)

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(720, 190)
	resized.connect(queue_redraw)


func _draw() -> void:
	_rng.seed = 1949  # Grundgesetz; the doodle is stable between frames
	var wall_w := minf(size.x, 760.0)
	var origin := Vector2((size.x - wall_w) * 0.5, 8)
	var wall_h := ROWS * BRICK.y
	var hole_c := origin + Vector2(wall_w * 0.73, wall_h * 0.55)
	var hole := _hole_polygon(hole_c, 52.0, 40.0)
	# Bricks.
	for row in ROWS:
		var off := 0.0 if row % 2 == 0 else -BRICK.x * 0.5
		var x := off
		while x < wall_w:
			var r := Rect2(origin + Vector2(maxf(x, 0.0), row * BRICK.y), Vector2(BRICK.x, BRICK.y))
			r.size.x = minf(r.size.x, wall_w - maxf(x, 0.0)) if x >= 0 else BRICK.x + x
			if r.size.x > 4:
				_brick(r, hole)
			x += BRICK.x
	# The hole: paper showing through, jagged ink edge.
	draw_colored_polygon(hole, UITheme.PAPER)
	var edge := hole.duplicate()
	edge.append(hole[0])
	draw_polyline(edge, UITheme.INK, 3.0)
	# Debris in front of the hole.
	for i in 4:
		var d := hole_c + Vector2(-50 + i * 30 + _rng.randf_range(-6, 6), wall_h * 0.5 + 18 + _rng.randf_range(-4, 6))
		var rot := _rng.randf_range(-0.5, 0.5)
		_wobbly_rect(Rect2(d, Vector2(26, 12)), UITheme.RED.darkened(0.15), rot)
	# Outline of the wall.
	_wobbly_outline(Rect2(origin, Vector2(wall_w, wall_h)), UITheme.INK, 3.5)
	# Title painted over the wall (left of the hole), with a paper "plaster" outline.
	var font := UITheme.hand()
	var fs := 88
	var text := "BRANDMAUER"
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tpos := Vector2(origin.x + (wall_w - tw) * 0.5 - 30, origin.y + wall_h * 0.5 + fs * 0.33)
	draw_string_outline(font, tpos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, UITheme.PAPER)
	draw_string(font, tpos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.INK)
	# Little crack lines from the hole.
	for a in [0.2, 2.6, 4.2]:
		var p0 := hole_c + Vector2(cos(a), sin(a)) * 52
		var p1 := p0 + Vector2(cos(a + 0.3), sin(a + 0.3)) * 22
		var p2 := p1 + Vector2(cos(a - 0.4), sin(a - 0.4)) * 16
		draw_polyline(PackedVector2Array([p0, p1, p2]), UITheme.INK, 2.0)


func _brick(r: Rect2, hole: PackedVector2Array) -> void:
	if Geometry2D.is_point_in_polygon(r.get_center(), hole):
		return
	var shade := UITheme.RED.lerp(UITheme.PAPER_DARK, _rng.randf_range(0.05, 0.3))
	_wobbly_rect(r.grow(-2), shade, 0.0)


func _wobbly_rect(r: Rect2, fill: Color, rot: float) -> void:
	var pts := PackedVector2Array()
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var c := r.get_center()
	for p in corners:
		var q: Vector2 = (p - c).rotated(rot) + c + Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-1.6, 1.6))
		pts.append(q)
	draw_colored_polygon(pts, fill)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, UITheme.INK, 1.6)


func _wobbly_outline(r: Rect2, color: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in steps + 1:
		pts.append(r.position + Vector2(r.size.x * i / steps, _rng.randf_range(-1.5, 1.5)))
	for i in range(1, 5):
		pts.append(Vector2(r.end.x + _rng.randf_range(-1.5, 1.5), r.position.y + r.size.y * i / 4))
	for i in range(1, steps + 1):
		pts.append(Vector2(r.end.x - r.size.x * i / steps, r.end.y + _rng.randf_range(-1.5, 1.5)))
	for i in range(1, 5):
		pts.append(Vector2(r.position.x + _rng.randf_range(-1.5, 1.5), r.end.y - r.size.y * i / 4))
	draw_polyline(pts, color, width)


func _hole_polygon(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		var a := TAU * i / n
		var k := _rng.randf_range(0.7, 1.15)
		pts.append(c + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	return pts
