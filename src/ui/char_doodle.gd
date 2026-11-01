class_name CharDoodle
extends Control
## Tiny doodle portrait for the character grid: stick figures in their
## character color. Das Stadtbild is a crowd, Die Töchter are a group.

const COLORS := {
	"stadtbild": UITheme.YELLOW, "sozialtourist": UITheme.BLUE, "buergergeld": UITheme.GREEN,
	"klimakleber": UITheme.YELLOW, "lastenrad": UITheme.GREEN, "gewerkschaft": UITheme.RED,
	"antifa": UITheme.INK, "oma": UITheme.BLUE, "toechter": UITheme.RED,
}

var char_id := ""
var locked := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


static func color_for(id: String) -> Color:
	return COLORS.get(id, UITheme.GREY)


func _draw() -> void:
	var col := UITheme.GREY if locked else color_for(char_id)
	var ink := UITheme.GREY if locked else UITheme.INK
	var base := Vector2(size.x * 0.5, size.y - 4)
	match char_id:
		"stadtbild":
			var cols := [UITheme.YELLOW, UITheme.BLUE, UITheme.GREEN, UITheme.RED, UITheme.PAPER_DARK]
			for i in 5:
				var c: Color = UITheme.GREY if locked else cols[i]
				_figure(base + Vector2((i - 2) * 15, -(i % 2) * 4), 0.62 + (i % 3) * 0.06, c, ink)
		"toechter":
			for i in 3:
				_figure(base + Vector2((i - 1) * 20, 0), 0.75, col if i != 1 else (UITheme.GREY if locked else UITheme.YELLOW), ink)
		"oma":
			_figure(base, 0.95, col, ink)
			draw_line(base + Vector2(10, -26), base + Vector2(24, -40), ink, 2.0)
			draw_line(base + Vector2(14, -26), base + Vector2(20, -42), ink, 2.0)
		"lastenrad":
			_figure(base + Vector2(-10, -8), 0.85, col, ink)
			draw_arc(base + Vector2(-16, -6), 7, 0, TAU, 16, ink, 2.0)
			draw_arc(base + Vector2(20, -6), 7, 0, TAU, 16, ink, 2.0)
			draw_rect(Rect2(base + Vector2(6, -22), Vector2(24, 12)), ink, false, 2.0)
		"gewerkschaft":
			_figure(base, 0.95, col, ink)
			draw_line(base + Vector2(14, -20), base + Vector2(14, -54), ink, 2.0)
			draw_rect(Rect2(base + Vector2(14, -54), Vector2(20, 12)), col)
		_:
			_figure(base, 0.95, col, ink)


func _figure(foot: Vector2, s: float, shirt: Color, ink: Color) -> void:
	var head := foot + Vector2(0, -50 * s)
	var body := PackedVector2Array([
		foot + Vector2(-10 * s, -14 * s), foot + Vector2(10 * s, -14 * s),
		foot + Vector2(7 * s, -40 * s), foot + Vector2(-7 * s, -40 * s)])
	draw_colored_polygon(body, shirt)
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, ink, 1.6)
	draw_line(foot + Vector2(-5 * s, -14 * s), foot + Vector2(-7 * s, 0), ink, 2.0)
	draw_line(foot + Vector2(5 * s, -14 * s), foot + Vector2(7 * s, 0), ink, 2.0)
	draw_circle(head, 9 * s, UITheme.PAPER)
	draw_arc(head, 9 * s, 0, TAU, 18, ink, 1.8)
