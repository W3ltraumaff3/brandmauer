class_name CharPortrait
extends Control
## A character drawn exactly as in the arena (GDD §6): WorldView's baked player
## mesh at a Zusammenhalt stage, scaled to fit and standing on the bottom edge.
## Used by the lobby character grid (stage 4) and the Späti portrait (current
## stage). Boils like the arena. Locked characters are drawn grey and faded.

var char_id := ""
var stage := 4
var locked := false
## Upper limit for the scale (keeps tiny portraits crisp, big ones calm).
var max_scale := 2.0
## Fraction of the height the figure may use.
var fill := 0.95

var _variant := 0
var _fit := {}   # "char:stage" -> Rect2 bounds of the variant-0 mesh


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(_delta: float) -> void:
	var v := posmod(int(Time.get_ticks_msec() / (Doodle.BOIL * 1000.0)), Doodle.VARIANTS)
	if v != _variant:
		_variant = v
		queue_redraw()


func _char_idx() -> int:
	return Content.CHAR_ORDER.find(char_id)


func _bounds(ci: int) -> Rect2:
	var key := "%d:%d:%s" % [ci, stage, locked]
	if _fit.has(key):
		return _fit[key]
	var aabb := WorldView.character_preview(ci, stage, 0, locked).get_aabb()
	var r := Rect2(aabb.position.x, aabb.position.y, aabb.size.x, aabb.size.y)
	_fit[key] = r
	return r


func _draw() -> void:
	var ci := _char_idx()
	if ci < 0 or size.x < 4.0 or size.y < 4.0:
		return
	var b := _bounds(ci)
	if b.size.x <= 0.0 or b.size.y <= 0.0:
		return
	var sc := minf(minf(size.x / b.size.x, size.y * fill / b.size.y), max_scale)
	# centre horizontally on the figure's bounds, stand on the bottom edge
	var origin := Vector2(size.x * 0.5 - (b.position.x + b.size.x * 0.5) * sc, size.y - (b.position.y + b.size.y) * sc)
	var mesh := WorldView.character_preview(ci, stage, _variant, locked)
	var mod := Color(1, 1, 1, 0.55) if locked else Color.WHITE
	draw_mesh(mesh, null, Transform2D(0.0, Vector2(sc, sc), 0.0, origin), mod)
