class_name Fx
extends Node2D
## World-space effects driven by Game.events (architecture §5): floating damage
## numbers, kill puffs, speech bubbles (invented lines handwritten, real quotes in
## typewriter with a source line), melee swooshes, down/revive markers and the
## one-shot part of ultimates (shouts, shockwaves, crowds, signs, coffee and cake).
## Lasting ultimate visuals (lounger, ghost bikes, paper storm) are in WorldView.
## Not desaturated by stage: feedback must stay readable.

const MAX_NUMBERS := 40
const MAX_PUFFS := 60
const MAX_BUBBLES := 5
const MAX_SWINGS := 40
const MAX_ULTS := 12
const MAX_LINES := 24
const CHAIN_LIFE := 0.4
const BEAM_LIFE := 0.25
const WHISTLE_LIFE := 0.6
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
var _ults: Array = []        # {id, peer, pos, t, life} from ["ult", peer, ult_id, pos]
var _chains: Array = []      # {pts, t, seed} from ["chain", points] (Unterschriftenliste)
var _beams: Array = []       # {from, to, t} from ["beam", from, to] (Scheinwerfer)
var _whistles: Array = []    # {pos, range, t, seed} from a Trillerpfeife "swing"
var _hand: Font
var _type: Font
var _t := 0.0
## Save option `bubble_opacity` (0..1, 0 = hidden), re-read every frame so a
## change in the options applies live (architecture §11).
var bubble_opacity := 0.7
## Set by tools (view_preview); < 0 = read the Save option.
var bubble_opacity_override := -1.0
## Speech-line keys of ordinary enemies (Content.ENEMIES[*].say). Every other
## "say" key is a status bubble (Verspätung, Schwarz gefahren!, …).
static var _chatter := {}

## Status bubbles never fade below this while bubbles are on.
const STATUS_MIN_ALPHA := 0.9


func _ready() -> void:
	_hand = UITheme.hand()
	_type = UITheme.typewriter()
	_read_bubble_opacity()


static func is_chatter(key: String) -> bool:
	if _chatter.is_empty():
		for id in Content.ENEMIES:
			var lines = Content.ENEMIES[id].get("say", [])
			if lines is Array:
				for k in lines:
					_chatter[str(k)] = true
		_chatter[""] = false  # marks the cache as built
	return bool(_chatter.get(key, false))


func _read_bubble_opacity() -> void:
	if bubble_opacity_override >= 0.0:
		bubble_opacity = clampf(bubble_opacity_override, 0.0, 1.0)
	else:
		bubble_opacity = UIKit.option_float("bubble_opacity", 0.7)


## Alpha factor for a bubble: enemy chatter (and the legacy real-quote path)
## follows the option, status text stays readable; 0 hides everything.
func _bubble_alpha(b: Dictionary) -> float:
	if bubble_opacity <= 0.001:
		return 0.0
	if bool(b.get("status", false)):
		return maxf(bubble_opacity, STATUS_MIN_ALPHA)
	return bubble_opacity


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
			if ev.size() >= 6 and str(ev[5]) == "trillerpfeife":
				_push(_whistles, {"pos": ev[1], "range": float(ev[3]), "t": 0.0, "seed": randi() % 1000}, MAX_LINES)
			elif ev.size() >= 6:
				_push(_swings, {"pos": ev[1], "ang": float(ev[2]), "range": float(ev[3]), "arc": float(ev[4]),
					"id": str(ev[5]), "t": 0.0}, MAX_SWINGS)
		"chain":
			if ev.size() >= 2 and (ev[1] is Array or ev[1] is PackedVector2Array):
				var pts := PackedVector2Array()
				for q in ev[1]:
					if q is Vector2:
						pts.append(q)
				if pts.size() >= 2:
					_push(_chains, {"pts": pts, "t": 0.0, "seed": randi() % 1000}, MAX_LINES)
		"beam":
			if ev.size() >= 3 and ev[1] is Vector2 and ev[2] is Vector2:
				_push(_beams, {"from": ev[1], "to": ev[2], "t": 0.0}, MAX_LINES)
		"down", "revive":
			var p := _player_pos(int(ev[1]) if ev.size() > 1 else -1)
			if p != Vector2.INF:
				var down: bool = ev[0] == "down"
				_marks.append({"pos": p, "text": tr("FX_DOWN") if down else tr("FX_REVIVE"),
					"col": Color(0.6, 0.15, 0.15) if down else Color(0.15, 0.55, 0.25), "t": 0.0, "heart": not down})
		"ult":
			if ev.size() >= 4:
				var id := str(ev[2])
				var pos: Vector2 = ev[3] if ev[3] is Vector2 else Vector2.ZERO
				_push(_ults, {"id": id, "peer": int(ev[1]), "pos": pos, "t": 0.0, "life": _ult_life(id),
					"seed": randi() % 1000}, MAX_ULTS)


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
	_read_bubble_opacity()
	if bubble_opacity <= 0.001:
		return  # bubbles off: don't even take a slot
	var b := {"pos": pos, "t": 0.0, "quote": false, "src": "", "status": quote_id == "" and not is_chatter(key)}
	if quote_id != "":
		var q := Quotes.get_quote(quote_id)
		if q.is_empty():
			return
		b["text"] = "„%s“" % str(q.get("zitat", ""))
		b["src"] = "– " + Quotes.source_label(q)
		b["ctx"] = Quotes.context_label(q)
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
	b["ctx_h"] = 0.0
	if b["quote"] and str(b.get("ctx", "")) != "":
		b["ctx_h"] = font.get_multiline_string_size(b["ctx"], HORIZONTAL_ALIGNMENT_LEFT, w, 11).y + 2.0
		h += b["ctx_h"]
	b["size"] = Vector2(minf(sz.x, w) + 20.0, h + 14.0)
	_push(_bubbles, b, MAX_BUBBLES)


func _process(delta: float) -> void:
	_t += delta
	_read_bubble_opacity()
	_age(_numbers, delta, NUMBER_LIFE)
	_age(_puffs, delta, PUFF_LIFE)
	_age(_swings, delta, SWING_LIFE)
	_age(_marks, delta, MARK_LIFE)
	_age(_chains, delta, CHAIN_LIFE)
	_age(_beams, delta, BEAM_LIFE)
	_age(_whistles, delta, WHISTLE_LIFE)
	var j := _ults.size() - 1
	while j >= 0:
		_ults[j]["t"] += delta
		if _ults[j]["t"] > _ults[j]["life"]:
			_ults.remove_at(j)
		j -= 1
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
	for b in _beams:
		_draw_beam(b)
	for c in _chains:
		_draw_chain(c)
	for w in _whistles:
		_draw_whistle(w)
	for p in _puffs:
		_draw_puff(p)
	for u in _ults:
		_draw_ult(u)
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


## Unterschriftenliste: a ballpoint signature that scrawls from the player through
## every hit enemy (it re-wobbles with the boil, so it crackles), a tick at each
## signer.
func _draw_chain(c: Dictionary) -> void:
	var k: float = c["t"] / CHAIN_LIFE
	var a := 1.0 - k * k
	var pts: PackedVector2Array = c["pts"]
	var seed_v: int = c["seed"]
	var reveal := clampf(c["t"] / 0.1, 0.0, 1.0) * (pts.size() - 1)
	var ink := Color(0.12, 0.23, 0.62, a)
	var line := PackedVector2Array()
	var fr := Doodle.frame
	for s in pts.size() - 1:
		if s >= reveal:
			break
		var p0 := pts[s]
		var p1 := pts[s + 1]
		var part := clampf(reveal - s, 0.0, 1.0)
		var d := p1 - p0
		var dl := d.length()
		if dl < 1.0:
			continue
		var dir := d / dl
		var nrm := dir.orthogonal()
		var steps := maxi(8, int(dl / 2.5))
		for j in steps + 1:
			var u := float(j) / steps
			if u > part:
				break
			# cursive handwriting: a prolate cycloid (little loops) riding on a slow
			# wave, faded in/out at the signers and re-jittered per boil frame (crackle)
			var env := sqrt(sin(u * PI))
			var ph := u * dl / 5.0 + seed_v + s
			var along := -6.5 * sin(ph) * env
			var wave := sin(u * dl / 23.0 + seed_v * 0.1 + s) * 6.0
			var jit := Doodle.noise(seed_v + j * 13 + fr * 7 + s) * 1.4
			line.append(p0 + d * u + dir * along + nrm * ((5.0 * cos(ph) + wave + jit) * env))
	if line.size() >= 2:
		draw_polyline(line, Color(1, 1, 1, 0.65 * a), 6.0)
		draw_polyline(line, ink, 2.4)
	# ticks at the signers, plus a blue ink blot
	for s in range(1, pts.size()):
		if s > reveal + 0.01:
			break
		var p := pts[s] + Vector2(10, -26)
		var tk := _pop(c["t"] - s * 0.03)
		draw_circle(pts[s] + Vector2(0, -6), 3.0 * tk, Color(ink, a * 0.8))
		draw_polyline(PackedVector2Array([p + Vector2(-5, 0) * tk, p + Vector2(-1, 5) * tk, p + Vector2(7, -7) * tk]),
			Color(1, 1, 1, a), 5.0)
		draw_polyline(PackedVector2Array([p + Vector2(-5, 0) * tk, p + Vector2(-1, 5) * tk, p + Vector2(7, -7) * tk]),
			Color(0.15, 0.55, 0.25, a), 2.5)


## Enthüllungs-Scheinwerfer: a cone of bright, translucent light from the player
## along the beam, widening to the hit width, with a pool of light at the end.
func _draw_beam(b: Dictionary) -> void:
	var k: float = b["t"] / BEAM_LIFE
	var a := 1.0 - k
	a *= a * (3.0 - 2.0 * a)
	var p0: Vector2 = b["from"]
	var p1: Vector2 = b["to"]
	var d := p1 - p0
	var dl := d.length()
	if dl < 1.0:
		return
	var dir := d / dl
	var n := dir.orthogonal()
	var start := p0 + dir * 14.0
	var flare := 1.0 + 0.25 * k
	var warm := Color(1.0, 0.95, 0.62)
	draw_colored_polygon(PackedVector2Array([start + n * 7.0, p1 + n * 30.0 * flare, p1 - n * 30.0 * flare, start - n * 7.0]),
		Color(warm, 0.26 * a))
	draw_colored_polygon(PackedVector2Array([start + n * 3.5, p1 + n * 15.0 * flare, p1 - n * 15.0 * flare, start - n * 3.5]),
		Color(1.0, 1.0, 0.86, 0.42 * a))
	draw_line(start, p1, Color(1, 1, 1, 0.85 * a), 2.5)
	draw_line(start + n * 7.0, p1 + n * 30.0 * flare, Color(0.95, 0.75, 0.2, 0.55 * a), 1.5)
	draw_line(start - n * 7.0, p1 - n * 30.0 * flare, Color(0.95, 0.75, 0.2, 0.55 * a), 1.5)
	var pool := PackedVector2Array()
	for j in 16:
		var ang := TAU * j / 16.0
		pool.append(p1 + Vector2(cos(ang) * 30.0, sin(ang) * 20.0) * flare)
	draw_colored_polygon(pool, Color(warm, 0.3 * a))
	# dust motes drifting in the light
	for j in 7:
		var u := fmod(0.12 + j * 0.13 + k * 0.3, 1.0)
		var side := Doodle.noise(j * 31 + 5) * 0.8
		var mp := start + d * u + n * side * (7.0 + 23.0 * u)
		draw_circle(mp, 1.6, Color(1, 1, 1, 0.8 * a))
	# the lamp itself at the start
	draw_circle(p0 + dir * 12.0, 6.0, Color(0.23, 0.24, 0.27, a))
	draw_circle(p0 + dir * 14.0, 3.5, Color(1.0, 0.98, 0.8, a))


## Trillerpfeife: sound waves rippling out to the stun radius and a "PFIFF!".
func _draw_whistle(w: Dictionary) -> void:
	var t: float = w["t"]
	var k := t / WHISTLE_LIFE
	var a := 1.0 - k * k
	var pos: Vector2 = w["pos"]
	var rng: float = w["range"]
	var seed_v: int = w["seed"]
	var col := Color(0.93, 0.47, 0.12)
	# faint stun-radius ring
	if k < 0.6:
		var ra := 1.0 - k / 0.6
		draw_polyline(Doodle.circle_pts(pos, rng, Doodle.frame % Doodle.VARIANTS), Color(0.15, 0.3, 0.7, 0.35 * ra), 2.0)
	# ")))" wave fronts in eight directions, moving outward
	for j in 3:
		var u := clampf(k * 1.5 - j * 0.18, 0.0, 1.0)
		if u <= 0.0 or u >= 1.0:
			continue
		var r := 24.0 + (rng - 24.0) * u
		var wa := a * (1.0 - u * 0.6)
		for dirn in 8:
			var ang := TAU * dirn / 8.0 + seed_v * 0.01
			draw_arc(pos, r, ang - 0.28, ang + 0.28, 7, Color(col, wa), 3.5 - j * 0.8)
	# lettering pops above the player
	var tk := _pop(t)
	if tk > 0.0:
		draw_set_transform(pos + Vector2(4, -72.0 - minf(t, 0.4) * 22.0), -0.1 + sin(t * 40.0) * 0.03, Vector2(tk, tk))
		Doodle.text(self, tr("FX_PFIFF"), Vector2.ZERO, 30, Color(col.darkened(0.15), a), _hand, 6, Color(1, 1, 1, a))
		draw_set_transform_matrix(Transform2D.IDENTITY)


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
	var a := clampf(minf(t * 6.0, (life - t) * 3.0), 0.0, 1.0) * _bubble_alpha(b)
	if a <= 0.0:
		return
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
		var ctx_h: float = b.get("ctx_h", 0.0)
		draw_string(font, Vector2(r.position.x + 10, r.end.y - 8 - ctx_h), b["src"], HORIZONTAL_ALIGNMENT_LEFT, w, 11, Color(0.35, 0.33, 0.3, a))
		if ctx_h > 0.0:
			draw_multiline_string(font, Vector2(r.position.x + 10, r.end.y - ctx_h + 4), b["ctx"], HORIZONTAL_ALIGNMENT_LEFT, w, 11, -1, Color(0.45, 0.42, 0.38, a))


func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, 0), r * 0.6, col)
	draw_circle(c + Vector2(r * 0.5, 0), r * 0.6, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.08, r * 0.15), c + Vector2(r * 1.08, r * 0.15), c + Vector2(0, r * 1.3)]), col)


# --- Ultimates (architecture §9): ["ult", peer, ult_id, pos] ------------------------------

const ULT_FLASH := Color(0.92, 0.45, 0.1)
const ULT_PURPLE := Color(0.5, 0.2, 0.62)
const ULT_RED := Color(0.78, 0.12, 0.1)
const ULT_GREEN := Color(0.2, 0.55, 0.25)
const ULT_BLUE := Color(0.15, 0.3, 0.65)


func _ult_life(id: String) -> float:
	match id:
		"flashmob":
			return 1.8
		"strassenblockade":
			return float(Content.ULTS["strassenblockade"]["time"])
		"kaffee_und_kuchen", "fragen_sie_uns":
			return 2.8
	return 2.2


## Pop-in scale with a little overshoot; 0 before the item starts.
static func _pop(t: float) -> float:
	if t <= 0.0:
		return 0.0
	var k := clampf(t / 0.22, 0.0, 1.0)
	return k + sin(k * PI) * 0.25


## The caster's current position if they're still in the view, else the event position.
func _ult_anchor(u: Dictionary) -> Vector2:
	var p := _player_pos(int(u["peer"]))
	return p if p != Vector2.INF else (u["pos"] as Vector2)


func _draw_ult(u: Dictionary) -> void:
	var t: float = u["t"]
	var life: float = u["life"]
	var a := clampf((life - t) / 0.5, 0.0, 1.0)
	match str(u["id"]):
		"flashmob":
			_ult_flashmob(u, t, a)
		"urlaubsantrag":
			_shout(tr("HUD_ULT_URLAUB"), _ult_anchor(u) + Vector2(0, -24), t, a, Color(0.1, 0.5, 0.75), 26, false)
		"antrag_gestellt":
			_ult_antrag(u, t, a)
		"strassenblockade":
			_ult_blockade(u, t, a)
		"critical_mass":
			var p := _ult_anchor(u)
			if t < 0.6:
				var k := t / 0.6
				for i in 12:
					var ang := TAU * i / 12.0
					var d := Vector2(cos(ang), sin(ang) * 0.8)
					draw_line(p + d * (30.0 + 90.0 * k), p + d * (50.0 + 130.0 * k), Color(ULT_GREEN, 1.0 - k), 3.0)
			_shout(tr("HUD_ULT_VERKEHR"), p, t, a, ULT_GREEN, 28, true)
		"tarifrunde":
			var p := _ult_anchor(u)
			if t < 1.0:
				for i in 10:
					var ang := TAU * i / 10.0 + t * 2.0
					var r := 40.0 + t * 150.0
					_cross(p + Vector2(cos(ang) * r, sin(ang) * r * 0.75 - 10.0), 6.0, Color(ULT_RED, 1.0 - t))
			_shout(tr("HUD_ULT_TARIF"), p, t, a, ULT_RED, 30, true)
		"schwarzer_block":
			_shout(tr("HUD_ULT_BLOCK"), _ult_anchor(u), t, a, Color(0.15, 0.15, 0.18), 28, true)
		"kaffee_und_kuchen":
			_ult_kaffee(u, t, a)
		"fragen_sie_uns":
			_ult_fragen(u, t, a)


## Speech/shout bubble over a point; `loud` = jagged outline.
func _shout(text: String, anchor: Vector2, t: float, a: float, col: Color, fs: int, loud: bool) -> void:
	var k := _pop(t)
	if k <= 0.0 or a <= 0.0:
		return
	var sz := _hand.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var w := sz.x + 26.0
	var h := float(fs) + 18.0
	var c := anchor + Vector2(0, -96.0 - minf(t, 0.5) * 16.0)
	var bg := Color(1, 1, 1, 0.96 * a)
	var tail := PackedVector2Array([c + Vector2(-10, h * 0.5 * k - 4), c + Vector2(10, h * 0.5 * k - 4), anchor + Vector2(4, -46)])
	draw_colored_polygon(tail, bg)
	draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), Color(INK, a), 2.0)
	draw_set_transform(c, -0.04, Vector2(k, k))
	if loud:
		var pts := PackedVector2Array()
		var n := 26
		for i in n:
			var ang := TAU * i / n
			var r := 1.0 if i % 2 == 0 else 0.86
			pts.append(Vector2(cos(ang) * (w * 0.5 + 22.0) * r, sin(ang) * (h * 0.5 + 16.0) * r))
		draw_colored_polygon(pts, bg)
		pts.append(pts[0])
		draw_polyline(pts, Color(col, a), 3.0)
	else:
		var r := Rect2(-w * 0.5, -h * 0.5, w, h)
		draw_rect(r, bg)
		draw_polyline(Doodle.rect_pts(r, Doodle.frame % 3, 1.5), Color(INK, a), 2.0)
	Doodle.text(self, text, Vector2(0, fs * 0.36), fs, Color(col, a), _hand)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _cross(p: Vector2, r: float, c: Color) -> void:
	draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), c, 3.0)
	draw_line(p + Vector2(0, -r), p + Vector2(0, r), c, 3.0)


## Flashmob: shockwave ring (radius from Content.ULTS) and a crowd bursting outward.
func _ult_flashmob(u: Dictionary, t: float, a: float) -> void:
	var p: Vector2 = u["pos"]
	var big: float = Content.ULTS["flashmob"]["radius"]
	var seed_v: int = u["seed"]
	var k1 := clampf(t / 0.45, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k1, 3.0)
	var wa := clampf(1.0 - t / 0.9, 0.0, 1.0)
	if wa > 0.0:
		var v := Doodle.frame % Doodle.VARIANTS
		draw_circle(p, big * e, Color(1.0, 0.85, 0.3, 0.16 * wa))
		draw_polyline(Doodle.circle_pts(p, big * e, v), Color(ULT_FLASH, wa), 6.0)
		draw_polyline(Doodle.circle_pts(p, big * e * 0.82, v + 1), Color(ULT_FLASH, wa * 0.5), 2.5)
	var n := 14
	var ke := 1.0 - pow(1.0 - clampf(t / 0.6, 0.0, 1.0), 2.0)
	for k in n:
		var ang := TAU * k / n + seed_v * 0.01
		var d := Vector2(cos(ang), sin(ang) * 0.8)
		var hop := absf(sin(t * 14.0 + k)) * 7.0
		var fp := p + d * (26.0 + big * 0.72 * ke) + Vector2(0, -hop)
		if t < 0.7:
			draw_line(fp - d * 16.0, fp - d * 40.0, Color(INK, 0.45 * (1.0 - t / 0.7)), 2.0)
		if world:
			var sx := -1.0 if d.x < 0.0 else 1.0
			draw_mesh(world.person_mesh(k + seed_v), null, Transform2D(sin(t * 12.0 + k) * 0.12, Vector2(1.5 * sx, 1.5), 0.0, fp),
				Color(1, 1, 1, a))
	var tk := _pop(t)
	if tk > 0.0:
		draw_set_transform(p + Vector2(0, -70.0 - t * 12.0), -0.06, Vector2(tk, tk))
		Doodle.text(self, tr("HUD_ULT_FLASHMOB"), Vector2.ZERO, 40, Color(ULT_FLASH, a), _hand, 8, Color(1, 1, 1, a))
		draw_set_transform_matrix(Transform2D.IDENTITY)


## Antrag gestellt: a burst of forms out of the caster's folder, plus a shout.
func _ult_antrag(u: Dictionary, t: float, a: float) -> void:
	var p: Vector2 = u["pos"]
	var seed_v: int = u["seed"]
	if t < 1.4:
		var k := t / 1.4
		var fa := 1.0 - k * k
		for i in 12:
			var ang := TAU * i / 12.0 + seed_v * 0.1
			var d := Vector2(cos(ang), sin(ang) * 0.8)
			var sp := p + d * (20.0 + 220.0 * (1.0 - pow(1.0 - k, 2.0))) + Vector2(0, -30.0 + 60.0 * k * k)
			draw_set_transform(sp, ang + t * 8.0 * (1.0 if i % 2 else -1.0), Vector2(1.0, 0.5 + 0.5 * absf(sin(t * 9.0 + i))))
			var r := Rect2(-8, -10, 16, 20)
			draw_rect(r, Color(1, 1, 1, fa))
			for j in 4:
				draw_line(Vector2(-5, -6 + j * 4), Vector2(4, -6 + j * 4), Color(0.3, 0.35, 0.55, fa), 1.0)
			draw_rect(r, Color(INK, fa), false, 1.2)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	_shout(tr("HUD_ULT_ANTRAG"), _ult_anchor(u), t, a, ULT_BLUE, 26, false)


## Straßenblockade: protest signs pop up along the glue strip, "BLOCKADE!" banner.
func _ult_blockade(u: Dictionary, t: float, a: float) -> void:
	var p: Vector2 = u["pos"]
	var x := 75.0
	var idx := 0
	while x < WorldView.ARENA.x - 40.0:
		if absf(x - p.x) > 60.0:
			var k := _pop(t - absf(x - p.x) / 1400.0)
			if k > 0.0:
				_sign(Vector2(x, p.y + 6.0 + float(idx % 2) * 10.0), k, a, idx)
		x += 150.0
		idx += 1
	if t < 2.6:
		var ba := clampf((2.6 - t) / 0.4, 0.0, 1.0)
		var k := _pop(t)
		var txt := tr("HUD_ULT_BLOCKADE")
		var w := _hand.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 44.0
		draw_set_transform(p + Vector2(0, -92), sin(t * 3.0) * 0.03 - 0.03, Vector2(k, k))
		var pole := Color("8a5a35")
		draw_line(Vector2(-w * 0.5 - 6, 40), Vector2(-w * 0.5 - 6, -26), Color(pole, ba), 4.0)
		draw_line(Vector2(w * 0.5 + 6, 40), Vector2(w * 0.5 + 6, -26), Color(pole, ba), 4.0)
		var cloth := PackedVector2Array()
		var n := 10
		for i in n + 1:
			var fx_ := -w * 0.5 + w * i / n
			cloth.append(Vector2(fx_, -24 + sin(t * 6.0 + i * 0.9) * 2.5))
		for i in range(n, -1, -1):
			var fx_ := -w * 0.5 + w * i / n
			cloth.append(Vector2(fx_, 20 + sin(t * 6.0 + i * 0.9 + 0.6) * 2.5))
		draw_colored_polygon(cloth, Color(0.94, 0.54, 0.14, ba))
		cloth.append(cloth[0])
		draw_polyline(cloth, Color(INK, ba), 2.5)
		Doodle.text(self, txt, Vector2(0, 11), 34, Color(1, 1, 1, ba), _hand, 4, Color(INK, ba))
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _sign(base: Vector2, k: float, a: float, idx: int) -> void:
	var sway := sin(_t * 2.5 + idx * 1.3) * 0.08
	draw_set_transform(base, sway, Vector2(k, k))
	draw_line(Vector2(0, 0), Vector2(0, -48), Color(Color("8a5a35"), a), 3.0)
	var txt := tr("HUD_ULT_SIGN_%d" % (idx % 3 + 1))
	var w := maxf(_hand.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 16.0, 50.0)
	var r := Rect2(-w * 0.5, -78, w, 32)
	var bgs := [Color("fffbea"), Color("f7e27a"), Color("cfe8c4")]
	var bg: Color = bgs[idx % 3]
	draw_rect(r, Color(bg, a))
	draw_polyline(Doodle.rect_pts(r, (idx + Doodle.frame) % 3, 1.2), Color(INK, a), 2.0)
	var tc := ULT_GREEN if idx % 3 != 1 else ULT_RED
	Doodle.text(self, txt, Vector2(0, -55), 18, Color(tc, a), _hand)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Kaffee und Kuchen: coffee pot + cake slice pop over every player, hearts rise.
func _ult_kaffee(u: Dictionary, t: float, a: float) -> void:
	var spots := PackedVector2Array()
	var vs: ViewState = world.get_view() if world else null
	if vs:
		for pl in vs.players:
			if int(pl.get("state", 0)) != 2:
				spots.append(pl.get("pos", Vector2.ZERO))
	if spots.is_empty():
		spots.append(u["pos"])
	for i in spots.size():
		var s := spots[i]
		var k := _pop(t - i * 0.12)
		if k <= 0.0:
			continue
		var rise := minf(t, 0.6) * 10.0
		_coffee_pot(s + Vector2(-20, -84 - rise), k, a)
		_cake(s + Vector2(20, -78 - rise), k, a)
		for j in 4:
			var ph := fmod(t * 0.8 + j * 0.25 + i * 0.1, 1.0)
			var hp := s + Vector2(-30.0 + j * 20.0 + sin(t * 3.0 + j) * 6.0, -20.0 - ph * 70.0)
			_heart(hp, 5.0 + (j % 2) * 2.0, Color(0.88, 0.22, 0.35, a * sin(ph * PI)))


func _coffee_pot(c: Vector2, k: float, a: float) -> void:
	draw_set_transform(c, sin(_t * 3.0) * 0.06 - 0.05, Vector2(k, k))
	var body := PackedVector2Array([Vector2(-10, 11), Vector2(-12, -1), Vector2(-7, -12), Vector2(7, -12), Vector2(12, -1), Vector2(10, 11)])
	# handle and spout first (body covers their ends)
	draw_arc(Vector2(-12, 0), 7.0, PI * 0.5, PI * 1.5, 10, Color(INK, a), 3.0)
	draw_polyline(PackedVector2Array([Vector2(9, -1), Vector2(18, -9), Vector2(22, -12)]), Color(INK, a), 5.0)
	draw_polyline(PackedVector2Array([Vector2(9, -1), Vector2(18, -9), Vector2(22, -12)]), Color(1, 1, 1, a), 2.5)
	draw_colored_polygon(body, Color(1, 1, 1, a))
	draw_circle(Vector2(-4, 1), 2.4, Color(0.2, 0.4, 0.8, a))
	draw_circle(Vector2(4, 5), 2.0, Color(0.2, 0.4, 0.8, a))
	draw_circle(Vector2(3, -5), 1.6, Color(0.2, 0.4, 0.8, a))
	var bl := body.duplicate()
	bl.append(bl[0])
	draw_polyline(bl, Color(INK, a), 2.0)
	var lid := PackedVector2Array([Vector2(-7, -12), Vector2(-5, -16), Vector2(5, -16), Vector2(7, -12)])
	draw_colored_polygon(lid, Color(1, 1, 1, a))
	draw_polyline(lid, Color(INK, a), 2.0)
	draw_circle(Vector2(0, -18), 2.5, Color(INK, a))
	for j in 2:
		var sx := 21.0 + j * 5.0
		var ph := _t * 3.0 + j
		draw_polyline(PackedVector2Array([Vector2(sx, -16), Vector2(sx + 3 * sin(ph), -22), Vector2(sx - 2 * sin(ph), -28), Vector2(sx + 2, -34)]),
			Color(0.55, 0.5, 0.45, a * 0.6), 1.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _cake(c: Vector2, k: float, a: float) -> void:
	draw_set_transform(c, 0.06, Vector2(k, k))
	var plate := PackedVector2Array()
	for i in 17:
		var ang := TAU * i / 16.0
		plate.append(Vector2(cos(ang) * 20.0, 9.5 + sin(ang) * 3.5))
	draw_colored_polygon(plate, Color(1, 1, 1, a))
	draw_polyline(plate, Color(INK, a * 0.8), 1.5)
	var slice := PackedVector2Array([Vector2(-15, 8), Vector2(14, 8), Vector2(14, -9), Vector2(-15, 3)])
	draw_colored_polygon(slice, Color(0.95, 0.8, 0.5, a))
	draw_line(Vector2(-14, 5.5), Vector2(13, 0.5), Color(0.98, 0.95, 0.9, a), 3.0)
	draw_line(Vector2(-14, 3), Vector2(14, -9), Color(1, 1, 1, a), 4.0)
	var sl := slice.duplicate()
	sl.append(sl[0])
	draw_polyline(sl, Color(INK, a), 2.0)
	draw_circle(Vector2(9, -13), 4.0, Color(0.85, 0.15, 0.2, a))
	draw_line(Vector2(9, -17), Vector2(11, -19), Color(0.25, 0.6, 0.25, a), 2.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Fragen Sie mal uns: big shout and a megaphone shockwave rolling over the arena.
func _ult_fragen(u: Dictionary, t: float, a: float) -> void:
	var p := _ult_anchor(u)
	for j in 4:
		var r := t * 900.0 - j * 120.0
		if r > 12.0 and r < 1500.0:
			var ra := clampf(1.0 - r / 1500.0, 0.0, 1.0) * a
			draw_polyline(Doodle.circle_pts(p, r, Doodle.frame % Doodle.VARIANTS + j), Color(ULT_PURPLE, 0.75 * ra), maxf(1.5, 6.0 - j * 1.2))
	var mk := _pop(t)
	if mk > 0.0:
		draw_set_transform(p + Vector2(26, -44), -0.6, Vector2(mk, mk) * 1.6)
		var cone := PackedVector2Array([Vector2(-8, -2.5), Vector2(2, -3), Vector2(10, -8), Vector2(10, 8), Vector2(2, 3), Vector2(-8, 2.5)])
		draw_colored_polygon(cone, Color(0.9, 0.27, 0.23, a))
		cone.append(cone[0])
		draw_polyline(cone, Color(INK, a), 1.5)
		draw_line(Vector2(10, -7), Vector2(10, 7), Color(1, 1, 1, a), 2.0)
		for j in 3:
			draw_arc(Vector2(12, 0), 6.0 + j * 5.0 + fmod(t * 30.0, 5.0), -0.7, 0.7, 6, Color(ULT_PURPLE, a), 1.5)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	_shout(tr("HUD_ULT_FRAGEN"), p + Vector2(0, -10), t, a, ULT_PURPLE, 34, true)
