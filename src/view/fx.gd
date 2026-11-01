class_name Fx
extends Node2D
## World-space effects driven by Game.events (architecture §5): floating damage
## numbers, kill puffs, speech bubbles (invented lines handwritten, real quotes in
## typewriter with a source line), melee swooshes and down/revive markers.
## Not desaturated by stage: feedback must stay readable.

const MAX_NUMBERS := 40
const MAX_PUFFS := 60
const MAX_BUBBLES := 5
const MAX_SWINGS := 40
const NUMBER_LIFE := 0.8
const PUFF_LIFE := 0.45
const SWING_LIFE := 0.22
const SAY_LIFE := 3.2
const QUOTE_LIFE := 7.0
const MARK_LIFE := 1.8
const BUBBLE_W := 230.0
const QUOTE_W := 300.0

const INK := Color("222222")
const PAPER := Color("fffbea")
const SWING_COLORS := {
	"doener": Color(0.85, 0.5, 0.15), "grundgesetz": Color(0.2, 0.35, 0.75), "megafon": Color(0.85, 0.2, 0.2),
	"transparent": Color(0.55, 0.25, 0.7), "oma": Color(0.2, 0.45, 0.8),
}

var world: WorldView

var _numbers: Array = []
var _puffs: Array = []
var _bubbles: Array = []
var _swings: Array = []
var _marks: Array = []
var _hand: Font
var _type: Font
var _t := 0.0


func _ready() -> void:
	_hand = UITheme.hand()
	_type = UITheme.typewriter()


func handle_event(ev: Array) -> void:
	if ev.is_empty():
		return
	match str(ev[0]):
		"dmg":
			if ev.size() < 3:
				return
			var crit: bool = ev.size() > 3 and bool(ev[3])
			var to_player: bool = ev.size() > 4 and bool(ev[4])
			var col := Color(0.85, 0.1, 0.1) if to_player else (Color(1.0, 0.55, 0.05) if crit else INK)
			var txt := str(int(ev[2])) + ("!" if crit else "")
			var jitter := Vector2(randf_range(-10, 10), randf_range(-6, 2))
			_push(_numbers, {"pos": ev[1] + jitter, "text": txt, "col": col, "t": 0.0,
				"size": 30 if crit else (24 if to_player else 20)}, MAX_NUMBERS)
		"kill":
			if ev.size() >= 2:
				_push(_puffs, {"pos": ev[1], "t": 0.0, "seed": randi() % 1000}, MAX_PUFFS)
		"say":
			if ev.size() >= 4:
				_add_bubble(ev[1], str(ev[2]), str(ev[3]))
		"swing":
			if ev.size() >= 6:
				_push(_swings, {"pos": ev[1], "ang": float(ev[2]), "range": float(ev[3]), "arc": float(ev[4]),
					"id": str(ev[5]), "t": 0.0}, MAX_SWINGS)
		"down", "revive":
			var p := _player_pos(int(ev[1]) if ev.size() > 1 else -1)
			if p != Vector2.INF:
				var down: bool = ev[0] == "down"
				_marks.append({"pos": p, "text": tr("FX_DOWN") if down else tr("FX_REVIVE"),
					"col": Color(0.6, 0.15, 0.15) if down else Color(0.15, 0.55, 0.25), "t": 0.0, "heart": not down})


func _player_pos(peer: int) -> Vector2:
	if world == null:
		return Vector2.INF
	var vs := world.get_view()
	if vs == null:
		return Vector2.INF
	var p := vs.find_player(peer)
	return p.get("pos", Vector2.INF) if not p.is_empty() else Vector2.INF


func _push(arr: Array, item: Dictionary, cap: int) -> void:
	if arr.size() >= cap:
		arr.remove_at(0)
	arr.append(item)


func _add_bubble(pos: Vector2, key: String, quote_id: String) -> void:
	var b := {"pos": pos, "t": 0.0, "quote": false, "src": ""}
	if quote_id != "":
		var q := Quotes.get_quote(quote_id)
		if q.is_empty():
			return
		b["text"] = "„%s“" % str(q.get("zitat", ""))
		b["src"] = "– " + Quotes.source_label(q)
		b["quote"] = true
		b["life"] = QUOTE_LIFE
	elif key != "":
		b["text"] = tr(key)
		b["life"] = SAY_LIFE
	else:
		return
	# Don't stack bubbles on the same spot: nudge upward.
	for o in _bubbles:
		if (o["pos"] as Vector2).distance_to(pos) < 80.0:
			b["pos"] = pos + Vector2(0, -50)
	var font := _type if b["quote"] else _hand
	var fs := 15 if b["quote"] else 19
	var w := QUOTE_W if b["quote"] else BUBBLE_W
	var sz := font.get_multiline_string_size(b["text"], HORIZONTAL_ALIGNMENT_LEFT, w, fs)
	var h := sz.y + (22.0 if b["quote"] else 6.0)
	b["size"] = Vector2(minf(sz.x, w) + 20.0, h + 14.0)
	_push(_bubbles, b, MAX_BUBBLES)


func _process(delta: float) -> void:
	_t += delta
	_age(_numbers, delta, NUMBER_LIFE)
	_age(_puffs, delta, PUFF_LIFE)
	_age(_swings, delta, SWING_LIFE)
	_age(_marks, delta, MARK_LIFE)
	var i := _bubbles.size() - 1
	while i >= 0:
		_bubbles[i]["t"] += delta
		if _bubbles[i]["t"] > _bubbles[i]["life"]:
			_bubbles.remove_at(i)
		i -= 1
	queue_redraw()


func _age(arr: Array, delta: float, life: float) -> void:
	var i := arr.size() - 1
	while i >= 0:
		arr[i]["t"] += delta
		if arr[i]["t"] > life:
			arr.remove_at(i)
		i -= 1


func _draw() -> void:
	for s in _swings:
		_draw_swing(s)
	for p in _puffs:
		_draw_puff(p)
	for m in _marks:
		var k: float = m["t"] / MARK_LIFE
		var pos: Vector2 = m["pos"] + Vector2(0, -60 - k * 30)
		var c: Color = m["col"]
		c.a = 1.0 - k * k
		Doodle.text(self, m["text"], pos, 26, c, _hand, 6, Color(1, 1, 1, c.a))
		if m["heart"]:
			for j in 3:
				_heart(pos + Vector2(-40 + j * 40, 20 - k * 40 - j * 6), 6.0, Color(0.85, 0.2, 0.3, c.a))
	for n in _numbers:
		var k: float = n["t"] / NUMBER_LIFE
		var c: Color = n["col"]
		c.a = 1.0 - k * k
		var pos: Vector2 = n["pos"] + Vector2(0, -24 * k - 10)
		var pop := 1.0 + maxf(0.0, 0.25 - n["t"]) * 2.0
		Doodle.text(self, n["text"], pos, int(n["size"] * pop), c, _hand, 5, Color(1, 1, 1, c.a * 0.9))
	for b in _bubbles:
		_draw_bubble(b)


func _draw_swing(s: Dictionary) -> void:
	var k: float = s["t"] / SWING_LIFE
	var pos: Vector2 = s["pos"]
	var ang: float = s["ang"]
	var rng: float = s["range"]
	var arc := deg_to_rad(float(s["arc"]))
	var id: String = s["id"]
	var c: Color = SWING_COLORS.get(id, Color(0.3, 0.3, 0.3))
	c.a = 0.85 * (1.0 - k)
	if id == "megafon":
		for j in 3:
			var r := rng * clampf(k * 1.4 - j * 0.18, 0.1, 1.0)
			draw_arc(pos, r, ang - arc * 0.5, ang + arc * 0.5, 14, c, 4.0 - j)
		return
	if arc >= TAU - 0.01:
		var sweep := TAU * (0.35 + k * 0.65)
		var start := ang + k * 4.0
		draw_arc(pos, rng * 0.85, start, start + sweep, 32, c, 7.0 * (1.0 - k) + 2.0)
		draw_arc(pos, rng * 0.65, start + 0.6, start + sweep * 0.8, 24, Color(c, c.a * 0.5), 3.0)
		return
	# crescent swoosh
	var pts := PackedVector2Array()
	var n := 10
	var a0 := ang - arc * 0.5
	var a1 := ang - arc * 0.5 + arc * minf(1.0, k * 2.2 + 0.3)
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(pos + Vector2(cos(a), sin(a)) * rng)
	for i in range(n, -1, -1):
		var a := lerpf(a0, a1, float(i) / n)
		var thick := 0.78 + 0.12 * sin(PI * float(i) / n)
		pts.append(pos + Vector2(cos(a), sin(a)) * rng * thick)
	draw_colored_polygon(pts, Color(c, c.a * 0.45))
	var outer := pts.slice(0, n + 1)
	draw_polyline(outer, c, 3.0)
	for j in 2:
		var off := 0.6 + 0.12 * j
		var sp := PackedVector2Array()
		for i in 5:
			var a := lerpf(a0, a1, 0.3 + 0.7 * float(i) / 4)
			sp.append(pos + Vector2(cos(a), sin(a)) * rng * off)
		draw_polyline(sp, Color(c, c.a * 0.6), 1.5)


func _draw_puff(p: Dictionary) -> void:
	var k: float = p["t"] / PUFF_LIFE
	var pos: Vector2 = p["pos"]
	var seed_v: int = p["seed"]
	var a := 1.0 - k
	for i in 5:
		var ang := TAU * i / 5.0 + seed_v
		var d := Vector2(cos(ang), sin(ang)) * (8.0 + 22.0 * k)
		var r := (7.0 + 3.0 * Doodle.noise(seed_v + i)) * (1.0 - k * 0.5)
		draw_circle(pos + d, r, Color(0.96, 0.95, 0.9, a))
		draw_arc(pos + d, r, 0, TAU, 10, Color(INK, a * 0.8), 1.5)
	for i in 4:
		var ang := TAU * i / 4.0 + 0.4 + seed_v
		var d := Vector2(cos(ang), sin(ang))
		draw_line(pos + d * (16 + 18 * k), pos + d * (24 + 26 * k), Color(INK, a), 2.0)


func _draw_bubble(b: Dictionary) -> void:
	var t: float = b["t"]
	var life: float = b["life"]
	var a := clampf(minf(t * 6.0, (life - t) * 3.0), 0.0, 1.0)
	var quote: bool = b["quote"]
	var sz: Vector2 = b["size"]
	var anchor: Vector2 = b["pos"] + Vector2(0, -44 - minf(t, 0.3) * 20)
	var r := Rect2(anchor - Vector2(sz.x * 0.5, sz.y), sz)
	var v := Doodle.frame % Doodle.VARIANTS
	var bg := Color(1, 1, 1, 0.95 * a) if not quote else Color(0.98, 0.96, 0.88, 0.97 * a)
	var tail := PackedVector2Array([anchor + Vector2(-10, -2), anchor + Vector2(8, -2), b["pos"] + Vector2(0, -26)])
	draw_rect(r, bg)
	draw_colored_polygon(tail, bg)
	draw_polyline(Doodle.rect_pts(r, v, 1.5), Color(INK, a), 2.0)
	draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), Color(INK, a), 2.0)
	var font := _type if quote else _hand
	var fs := 15 if quote else 19
	var w := QUOTE_W if quote else BUBBLE_W
	draw_multiline_string(font, r.position + Vector2(10, 8 + fs), b["text"], HORIZONTAL_ALIGNMENT_LEFT, w, fs, -1, Color(INK, a))
	if quote:
		draw_string(font, Vector2(r.position.x + 10, r.end.y - 8), b["src"], HORIZONTAL_ALIGNMENT_LEFT, w, 11, Color(0.35, 0.33, 0.3, a))


func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, 0), r * 0.6, col)
	draw_circle(c + Vector2(r * 0.5, 0), r * 0.6, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.08, r * 0.15), c + Vector2(r * 1.08, r * 0.15), c + Vector2(0, r * 1.3)]), col)
