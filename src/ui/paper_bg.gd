class_name PaperBg
extends Control
## Paper background: ruled lines, a red margin line and a few doodles in the
## corners. Purely decorative, ignores the mouse.

@export var ruled := true
@export var doodles := true
@export var tint := UITheme.PAPER


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), tint)
	if ruled:
		var line := UITheme.BLUE
		line.a = 0.10
		var y := 46.0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y + 1.5), line, 1.5)
			y += 34.0
		var margin := UITheme.RED
		margin.a = 0.22
		draw_line(Vector2(64, 0), Vector2(63, size.y), margin, 2.0)
	if doodles:
		_doodles()


func _doodles() -> void:
	var c := UITheme.INK_SOFT
	c.a = 0.18
	# Coffee ring, bottom right.
	var ring := UITheme.PAPER_DARK
	ring.a = 0.9
	draw_arc(Vector2(size.x - 90, size.y - 70), 38, 0.3, TAU - 0.4, 40, ring, 5.0)
	draw_arc(Vector2(size.x - 88, size.y - 69), 33, 0.9, TAU - 0.1, 40, ring, 2.0)
	# Spiral scribble, bottom left.
	var pts := PackedVector2Array()
	for i in 40:
		var t := i * 0.45
		pts.append(Vector2(30, size.y - 40) + Vector2(cos(t), sin(t)) * (2.0 + t * 1.6))
	draw_polyline(pts, c, 2.0)
