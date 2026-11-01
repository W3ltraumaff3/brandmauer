class_name WorldView
extends Node2D
## Draws the arena from a ViewState (architecture §3) in the Doodle/Paint style.
##
## Every entity is a cached ArrayMesh baked by Doodle.Sketch (one draw call each),
## keyed by kind, type, Zusammenhalt stage (desaturation and player posture),
## boil variant and hit flash. No per-entity nodes.
## Reads `source_view` if set (preview harness), else `Game.view`; draws nothing
## when neither exists.

const ARENA := Vector2(1600, 1000)
const WALL_TOP := 78.0
const WALL_BOTTOM := 102.0
const WALL_SEGMENTS := 12
const SEG_W := 1600.0 / 12.0
const REVIVE_RANGE := 60.0

enum { K_ENEMY = 1, K_PROJ, K_PICK, K_SUMMON, K_PLAYER, K_WEAPON, K_MISC, K_FOLLOWER }
enum { M_BG, M_WALL, M_RUBBLE, M_URNE, M_BLADES, M_YACHT, M_SCHIRM, M_FLAG, M_CHALET, M_CIRCUS, M_SITTER,
	M_LOUNGER, M_SHEET, M_STAMP, M_NOTE }

const INK := Color("222222")
const FACE := Color("f7e4cc")
const PAPER := Color("f4efe1")
const WHITE := Color("fbfaf5")
const PANTS := Color("4a4f5c")
const DENIM := Color("4b6a96")
const CHINO := Color("cdb88c")
const SUIT_GREY := Color("8a8f98")
const NAVY := Color("27324a")
const GOLD := Color("e8b923")
const RED := Color("c0392b")
const GREEN := Color("3f8f4f")
const BRICK := Color("b5654a")
const DESK := Color("5b4a3c")
const POISON_TINT := Color(0.55, 1.0, 0.45)
const SLOW_TINT := Color(0.55, 0.75, 1.0)
const SLOT_COLORS := [Color("c0392b"), Color("2e6db4"), Color("3f8f4f"), Color("8e44ad")]

## Person scale and height stretch per enemy type.
const LOOK := {
	"besorgter_buerger": [1.0, 1.0], "telegram_onkel": [1.0, 1.0], "identitaerer_hipster": [0.95, 1.1],
	"reichsbuerger": [1.5, 1.0], "ju_schnoesel": [0.85, 1.0], "hinterbaenkler": [1.1, 1.0],
	"lobbyist": [1.0, 1.3], "immobilienerbe": [1.1, 1.0], "golfclub_vorstand": [1.05, 1.0],
	"fdp_jungunternehmer": [1.05, 1.0], "sylt_member": [1.25, 1.0], "geschichtslehrer": [2.1, 1.0],
	"sauerlaender": [2.0, 1.45], "eidgenossin": [2.1, 1.0],
}
const BOSSES := ["geschichtslehrer", "sauerlaender", "eidgenossin"]
const ENEMY_PROJ := ["kettenbrief", "golfball", "champagner", "buch", "bierdeckel", "zirkusball", "fluegel", "goldbarren"]

## Overrides used by the preview harness (and possible replays).
var source_view: ViewState = null
var source_meta = null           # Dictionary or null
var local_id_override := -1

var draw_usec := 0               # duration of the last _draw() in microseconds
var anim_time := 0.0

var _cache := {}
var _etop := PackedFloat32Array()
var _boss_idx := {}
var _prev := {}
var _heading := {}
var _exits: Array = []
var _hand: Font
var _type: Font
var _ppos := PackedVector2Array()
var _t_jet := -1
var _t_porsche := -1
var _t_ju := -1
var _t_startup := -1
var _t_spin := {}
# Ultimates (architecture §9): global effects from meta, eased for fading.
var _eff_tarif := 0.0
var _eff_antrag := 0.0
var antrag_vis := 0.0             # 0..1 paper storm visibility (public for the preview)
var _p_prev := {}                 # player id -> last position (Critical Mass heading)
var _p_heading := {}


func _ready() -> void:
	_hand = UITheme.hand()
	_type = UITheme.typewriter()
	_etop.resize(Content.ENEMY_ORDER.size())
	for i in Content.ENEMY_ORDER.size():
		var id: String = Content.ENEMY_ORDER[i]
		if LOOK.has(id):
			var s: float = LOOK[id][0]
			var tall: float = LOOK[id][1]
			_etop[i] = -(9.0 * s * tall + 13.0 * s + 5.0)
		else:
			_etop[i] = -float(Content.ENEMIES[id]["radius"]) - 10.0
		if id in BOSSES:
			_boss_idx[i] = true
	_t_jet = Content.ENEMY_ORDER.find("privatjet")
	_t_porsche = Content.ENEMY_ORDER.find("porsche_suv")
	_t_ju = Content.ENEMY_ORDER.find("ju_schnoesel")
	_t_startup = Content.ENEMY_ORDER.find("startup")
	for id in ["stern", "flasche", "bierdeckel", "zirkusball", "farbe", "flugblatt"]:
		_t_spin[Content.PROJ_ORDER.find(id)] = true


# --- Data access ----------------------------------------------------------------

static func game_node() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("Game")
	return null


func get_view() -> ViewState:
	if source_view != null:
		return source_view
	var g := game_node()
	if g == null:
		return null
	var v = g.get("view")
	return v if v is ViewState else null


func get_meta_dict() -> Dictionary:
	if source_meta is Dictionary:
		return source_meta
	var g := game_node()
	if g:
		var m = g.get("meta")
		if m is Dictionary:
			return m
	return {}


func local_id() -> int:
	if local_id_override >= 0:
		return local_id_override
	var g := game_node()
	if g and g.has_method("local_id"):
		return int(g.call("local_id"))
	return 1


# --- Events -------------------------------------------------------------------

func handle_event(ev: Array) -> void:
	if ev.is_empty():
		return
	if ev[0] == "exit" and ev.size() >= 3:
		_exits.append({"enc": str(ev[1]), "pos": ev[2], "t": 0.0})


# --- Frame --------------------------------------------------------------------

func _process(delta: float) -> void:
	anim_time += delta
	Doodle.tick(anim_time)
	var i := _exits.size() - 1
	while i >= 0:
		_exits[i]["t"] += delta
		if _exits[i]["t"] > 5.5:
			_exits.remove_at(i)
		i -= 1
	_read_effects()
	antrag_vis = move_toward(antrag_vis, 1.0 if _eff_antrag > 0.0 else 0.0, delta * 2.5)
	queue_redraw()


## Global ultimate effects from meta (seconds left, absent when inactive).
func _read_effects() -> void:
	var eff = get_meta_dict().get("effects", {})
	_eff_tarif = 0.0
	_eff_antrag = 0.0
	if eff is Dictionary:
		_eff_tarif = float(eff.get("tarifrunde", 0.0))
		_eff_antrag = float(eff.get("antrag_gestellt", 0.0))


func _draw() -> void:
	var vs := get_view()
	if vs == null:
		return
	var t0 := Time.get_ticks_usec()
	var st := clampi(vs.stage, 0, 4)
	_read_effects()
	_ppos.clear()
	for p in vs.players:
		if int(p.get("state", 0)) == 0:
			_ppos.append(p.get("pos", Vector2.ZERO))
	_draw_ground(vs, st)
	_draw_wall(vs, st)
	_draw_hazards(vs, st)
	_draw_pickups(vs, st)
	_draw_summons(vs, st)
	_draw_enemies(vs, st)
	if antrag_vis > 0.0:
		_draw_formular_notes(vs, st)
	_draw_players(vs, st)
	_draw_projectiles(vs, st)
	if antrag_vis > 0.0:
		_draw_paper_storm(st)
	_draw_exits(st)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	draw_usec = Time.get_ticks_usec() - t0


# --- Mesh cache -----------------------------------------------------------------

func _mesh(kind: int, type: int, st: int, v: int, white := false) -> ArrayMesh:
	var key := ((((kind * 64 + type) * 8 + st) * 4 + v) * 2) + (1 if white else 0)
	var m: ArrayMesh = _cache.get(key)
	if m == null:
		m = _build(kind, type, st, v, white)
		_cache[key] = m
	return m


## A cached passer-by doodle (Fx: Flashmob crowd). Full colour, boils over time.
func person_mesh(k: int) -> ArrayMesh:
	return _mesh(K_FOLLOWER, posmod(k, 6), 4, Doodle.variant(k))


## Bake every enemy/projectile/pickup mesh for a stage up front (avoids hitches).
func prewarm(st: int) -> void:
	for t in Content.ENEMY_ORDER.size():
		for v in Doodle.VARIANTS:
			_mesh(K_ENEMY, t, st, v)
	for t in Content.PROJ_ORDER.size():
		for v in Doodle.VARIANTS:
			_mesh(K_PROJ, t, st, v)
	for t in Content.PICKUP_ORDER.size():
		for v in Doodle.VARIANTS:
			_mesh(K_PICK, t, st, v)
	for t in Content.SUMMON_ORDER.size():
		for v in Doodle.VARIANTS:
			_mesh(K_SUMMON, t, st, v)


func _build(kind: int, type: int, st: int, v: int, white: bool) -> ArrayMesh:
	var sk := Doodle.Sketch.new(kind * 7919 + type * 131 + v * 977 + 7, st, white)
	match kind:
		K_ENEMY:
			_b_enemy(sk, Content.ENEMY_ORDER[type])
		K_PROJ:
			_b_proj(sk, Content.PROJ_ORDER[type])
		K_PICK:
			_b_pickup(sk, Content.PICKUP_ORDER[type])
		K_SUMMON:
			_b_summon(sk, Content.SUMMON_ORDER[type])
		K_PLAYER:
			_b_player(sk, Content.CHAR_ORDER[type], st)
		K_WEAPON:
			_b_weapon(sk, Content.WEAPON_ORDER[type])
		K_FOLLOWER:
			_b_follower(sk, type, st)
		K_MISC:
			_b_misc(sk, type)
	return sk.build()


# --- Ground, wall, circus ------------------------------------------------------

func _draw_ground(vs: ViewState, st: int) -> void:
	draw_rect(Rect2(-1400, -1200, ARENA.x + 2800, ARENA.y + 2400), Doodle.desat(DESK, st))
	draw_rect(Rect2(10, 14, ARENA.x, ARENA.y), Color(0, 0, 0, 0.35))
	draw_mesh(_mesh(K_MISC, M_BG, st, 0), null)
	var b := vs.boss
	if not b.is_empty() and int(b.get("enc", -1)) == Content.ENCOUNTER_ORDER.find("sauerlaender") and int(b.get("phase", 0)) >= 2:
		draw_mesh(_mesh(K_MISC, M_CIRCUS, st, Doodle.variant(0)), null)
	if not b.is_empty() and int(b.get("enc", -1)) == Content.ENCOUNTER_ORDER.find("eidgenossin") and int(b.get("phase", 0)) >= 2:
		# Steuerparadies: Swiss chalet at the top where she retreats
		draw_mesh(_mesh(K_MISC, M_CHALET, st, Doodle.variant(1)), null, Transform2D(0.0, Vector2(1.4, 1.4), 0.0, Vector2(800, 200)))


func _draw_wall(vs: ViewState, st: int) -> void:
	var red := Doodle.desat(RED, maxi(st, 2))
	for i in WALL_SEGMENTS:
		var x := i * SEG_W
		var v := Doodle.variant(i)
		if vs.wall & (1 << i):
			draw_mesh(_mesh(K_MISC, M_WALL, st, v), null, Transform2D(0.0, Vector2(x, 0)))
		else:
			draw_mesh(_mesh(K_MISC, M_RUBBLE, st, v), null, Transform2D(0.0, Vector2(x, 0)))
			draw_set_transform(Vector2(x + SEG_W * 0.5, WALL_TOP + 17), -0.12 + 0.02 * Doodle.noise(v + i), Vector2.ONE)
			Doodle.text(self, tr("HUD_WALL_ABGESTIMMT"), Vector2.ZERO, 17, red, _hand, 4)
			draw_set_transform_matrix(Transform2D.IDENTITY)


# --- Hazards (immediate, few) ---------------------------------------------------

func _draw_hazards(vs: ViewState, st: int) -> void:
	for i in vs.h_pos.size():
		var id: String = Content.HAZARD_ORDER[vs.h_type[i]] if vs.h_type[i] < Content.HAZARD_ORDER.size() else ""
		var pos := vs.h_pos[i]
		var r := vs.h_rad[i] if i < vs.h_rad.size() else 40.0
		var life := vs.h_life[i] if i < vs.h_life.size() else 1.0
		var v := Doodle.variant(i)
		var amt := Doodle.desat_amount(st) * 0.5
		match id:
			"kleber":
				var c := Doodle.desat_amt(Color(0.96, 0.93, 0.7, 0.75 * minf(1.0, life * 3.0)), amt)
				draw_colored_polygon(Doodle.blob_pts(pos, r, v, i), c)
				draw_polyline(Doodle.blob_pts(pos, r, v, i, 0.12, true), Color(INK, 0.5), 2.0)
				draw_arc(pos + Vector2(-r * 0.3, -r * 0.3), r * 0.35, PI * 1.1, PI * 1.6, 6, Color(1, 1, 1, 0.8), 3.0)
				draw_multiline(Transform2D(0.0, pos) * Doodle.hatch_circle(r * 0.8, 14.0, 0.5), Color(0.75, 0.68, 0.3, 0.35), 1.5)
			"mietzone":
				var pulse := 0.5 + 0.5 * sin(anim_time * 4.0)
				draw_colored_polygon(Doodle.blob_pts(pos, r, v, i, 0.06), Doodle.desat_amt(Color(0.8, 0.15, 0.2, 0.16 + 0.06 * pulse), amt))
				_dashed_circle(pos, r, Doodle.desat_amt(Color(0.7, 0.1, 0.15, 0.8), amt), 2.5, 18)
				var post := pos + Vector2(r * 0.35, -r * 0.1)
				draw_line(post, post + Vector2(0, -34), INK, 3.0)
				var sign_r := Rect2(post + Vector2(-24, -56), Vector2(48, 24))
				draw_rect(sign_r, Doodle.desat_amt(Color("fff6d8"), amt))
				draw_polyline(Doodle.rect_pts(sign_r, v, 1.2), INK, 2.0)
				Doodle.text(self, tr("HUD_MIETZONE"), sign_r.position + Vector2(24, 18), 17, Doodle.desat_amt(RED, amt), _hand)
			"kerosin":
				draw_colored_polygon(Doodle.blob_pts(pos, r, v, i, 0.2), Color(0.18, 0.12, 0.22, 0.5 * minf(1.0, life * 2.0)))
				draw_arc(pos, r * 0.6, 0.3, 1.7, 8, Doodle.desat_amt(Color(0.6, 0.3, 0.9, 0.5), amt), 2.0)
				draw_arc(pos, r * 0.45, 0.6, 1.9, 8, Doodle.desat_amt(Color(0.2, 0.8, 0.7, 0.5), amt), 2.0)
			"lob_marker":
				var k := 1.0 - life
				var c := Doodle.desat_amt(Color(0.85, 0.15, 0.1), amt)
				draw_circle(pos, r * k, Color(c, 0.25))
				_dashed_circle(pos, r, Color(c, 0.9), 2.5, 14, anim_time * 2.0)
				var a := r * 0.45
				draw_line(pos + Vector2(-a, -a), pos + Vector2(a, a), c, 3.0)
				draw_line(pos + Vector2(-a, a), pos + Vector2(a, -a), c, 3.0)
			"sitzblockade":
				var c := Doodle.desat_amt(Color(0.25, 0.55, 0.85), amt)
				draw_circle(pos, r, Color(c, 0.12))
				_dashed_circle(pos, r, Color(c, 0.8), 3.0, 22, anim_time * 0.3)
				var n := 6
				for k in n:
					var ang := TAU * k / n + 0.3
					var sp := pos + Vector2(cos(ang), sin(ang) * 0.8) * r * 0.62
					draw_mesh(_mesh(K_MISC, M_SITTER, st, Doodle.variant(k)), null,
						Transform2D(0.0, Vector2(-1.0 if k % 2 else 1.0, 1.0), 0.0, sp))
			"explosion":
				var k := 1.0 - life
				var pts := PackedVector2Array()
				for j in 16:
					var ang := TAU * j / 16.0 + v
					var rr := r * (0.55 + 0.45 * k) * (1.0 if j % 2 == 0 else 0.62 + 0.1 * Doodle.noise(j + v))
					pts.append(pos + Vector2(cos(ang), sin(ang)) * rr)
				draw_colored_polygon(pts, Doodle.desat_amt(Color(1.0, 0.75, 0.15, 0.9 * life + 0.1), amt))
				draw_colored_polygon(Transform2D(0.0, Vector2(0.55, 0.55), 0.0, pos) * (Transform2D(0.0, -pos) * pts),
					Doodle.desat_amt(Color(1.0, 0.35, 0.1, 0.9 * life), amt))
				pts.append(pts[0])
				draw_polyline(pts, Color(INK, life), 2.5)
			"abschiebezone":
				var c := Doodle.desat_amt(Color(0.85, 0.1, 0.1), amt)
				var y0 := WALL_BOTTOM
				var h := 70.0
				draw_rect(Rect2(0, y0, ARENA.x, h), Color(c, 0.13 + 0.05 * sin(anim_time * 5.0)))
				var stripes := PackedVector2Array()
				var x := -h + fmod(anim_time * 30.0, 40.0)
				while x < ARENA.x:
					stripes.append(Vector2(x, y0 + h))
					stripes.append(Vector2(x + h, y0))
					x += 40.0
				draw_multiline(stripes, Color(c, 0.35), 10.0)
				draw_polyline(Doodle.line_pts(Vector2(0, y0 + h), Vector2(ARENA.x, y0 + h), v, 3.0), Color(c, 0.9), 3.0)
			"push_ring":
				var c := Doodle.desat_amt(Color(0.75, 0.2, 0.1, 0.85 * life), amt)
				draw_polyline(Doodle.circle_pts(pos, r, v), c, 6.0)
				draw_polyline(Doodle.circle_pts(pos, r - 10.0, v + 1), Color(c, c.a * 0.4), 2.0)
				for k in 12:
					var ang := TAU * k / 12.0 + anim_time * 0.2
					var d := Vector2(cos(ang), sin(ang))
					var tip := pos + d * (r + 14.0)
					var nn := d.orthogonal() * 7.0
					draw_polyline(PackedVector2Array([tip - d * 9.0 + nn, tip, tip - d * 9.0 - nn]), c, 3.0)
			"farbklecks":
				var c := Doodle.desat_amt(Color(0.9, 0.2, 0.6, 0.7 * minf(1.0, life * 2.0)), amt)
				draw_colored_polygon(Doodle.blob_pts(pos, r * 0.75, v, i, 0.35), c)
				for k in 5:
					var ang := TAU * k / 5.0 + i
					draw_circle(pos + Vector2(cos(ang), sin(ang)) * r * (0.9 + 0.1 * (k % 2)), 4.0 + k % 3, c)
			_:
				_dashed_circle(pos, r, Color(INK, 0.5), 2.0, 12)


func _dashed_circle(c: Vector2, r: float, col: Color, w: float, n: int, rot := 0.0) -> void:
	var segs := PackedVector2Array()
	for k in n:
		var a0 := rot + TAU * k / n
		var a1 := a0 + TAU / n * 0.55
		segs.append(c + Vector2(cos(a0), sin(a0)) * r)
		segs.append(c + Vector2(cos(a1), sin(a1)) * r)
	draw_multiline(segs, col, w)


# --- Pickups / summons / projectiles ----------------------------------------------

func _draw_pickups(vs: ViewState, st: int) -> void:
	var t := anim_time
	for i in vs.k_pos.size():
		var ty: int = vs.k_type[i]
		var v := Doodle.variant(i)
		var bob := sin(t * 4.0 + i * 1.3) * 2.0
		draw_mesh(_mesh(K_PICK, ty, st, v), null, Transform2D(0.0, vs.k_pos[i] + Vector2(0, bob)))


func _draw_summons(vs: ViewState, st: int) -> void:
	var t_turb := Content.SUMMON_ORDER.find("turbine")
	var t_gen := Content.SUMMON_ORDER.find("genosse")
	for i in vs.s_pos.size():
		var ty: int = vs.s_type[i]
		if ty >= Content.SUMMON_ORDER.size():
			continue
		var pos := vs.s_pos[i]
		var v := Doodle.variant(i)
		var rot := 0.0
		var sx := 1.0
		if Content.SUMMON_ORDER[ty] == "oma":
			rot = sin(anim_time * 6.0 + i) * 0.08
		elif ty == t_gen:
			# marching comrades: brisk step, face the nearest player's side outward
			rot = sin(anim_time * 10.0 + i * 1.7) * 0.07
			pos.y -= absf(sin(anim_time * 10.0 + i * 1.7)) * 3.0
			var best := 1e12
			for k in _ppos.size():
				var d := _ppos[k].distance_squared_to(pos)
				if d < best:
					best = d
					sx = -1.0 if _ppos[k].x > pos.x else 1.0
			draw_polyline(Doodle.ellipse_pts(vs.s_pos[i] + Vector2(0, 19), 13, 4, v), Color(0.75, 0.12, 0.12, 0.5), 2.0)
		draw_mesh(_mesh(K_SUMMON, ty, st, v), null, Transform2D(rot, Vector2(sx, 1.0), 0.0, pos))
		if ty == t_turb:
			draw_mesh(_mesh(K_MISC, M_BLADES, st, v), null, Transform2D(anim_time * 2.2 + i, pos + Vector2(0, -78)))


func _draw_projectiles(vs: ViewState, st: int) -> void:
	var n := vs.p_pos.size()
	var t := anim_time
	for i in n:
		var ty: int = vs.p_type[i]
		var ang := vs.p_ang[i] if i < vs.p_ang.size() else 0.0
		if _t_spin.has(ty):
			ang += t * 9.0 + i
		draw_mesh(_mesh(K_PROJ, ty, st, Doodle.variant(i)), null, Transform2D(ang, vs.p_pos[i]))


# --- Enemies ----------------------------------------------------------------------

func _draw_enemies(vs: ViewState, st: int) -> void:
	var n := vs.e_pos.size()
	var t := anim_time
	var has_ids := vs.e_id.size() == n
	var new_prev := {}
	var np := _ppos.size()
	var excl := Color(0.85, 0.1, 0.1)
	for i in n:
		var ty: int = vs.e_type[i]
		var pos := vs.e_pos[i]
		var fl: int = vs.e_flags[i] if i < vs.e_flags.size() else 0
		var id: int = vs.e_id[i] if has_ids else i
		var v := Doodle.variant(id)
		var hit := (fl & ViewState.EF_HIT) != 0
		var mesh := _mesh(K_ENEMY, ty, st, v, hit)
		var mod := Color.WHITE
		if not hit:
			if fl & ViewState.EF_POISONED:
				mod = POISON_TINT
			elif fl & ViewState.EF_SLOWED:
				mod = SLOW_TINT
		var ph := float(id) * 0.77
		var speed := 3.0 if (fl & ViewState.EF_SLOWED) != 0 else 9.0
		var rot := sin(t * speed + ph) * 0.07
		var bob := -absf(sin(t * speed + ph)) * 2.5
		var sx := 1.0
		if ty == _t_jet or ty == _t_porsche:
			rot = 0.0
			bob = 0.0
			var prev: Vector2 = _prev.get(id, pos)
			var hd: Vector2 = _heading.get(id, Vector2.RIGHT)
			if pos.distance_squared_to(prev) > 0.25:
				hd = hd.lerp((pos - prev).normalized(), 0.3).normalized()
				_heading[id] = hd
			new_prev[id] = pos
			if ty == _t_jet:
				rot = hd.angle()
			else:
				sx = -1.0 if hd.x < 0.0 else 1.0
				if fl & ViewState.EF_WINDUP:
					rot = sin(t * 50.0) * 0.03
		else:
			var best := 1e12
			var tx := pos.x + 1.0
			for k in np:
				var d := _ppos[k].distance_squared_to(pos)
				if d < best:
					best = d
					tx = _ppos[k].x
			sx = -1.0 if tx < pos.x else 1.0
		if fl & ViewState.EF_PARKED:
			rot = 0.0
			bob = 0.0
		if fl & ViewState.EF_WINDUP:
			pos.x += sin(t * 70.0 + ph) * 2.0
		var at := pos + Vector2(0, bob)
		if fl & ViewState.EF_BUFFED:
			var rr := float(Content.ENEMIES[Content.ENEMY_ORDER[ty]]["radius"]) + 8.0
			draw_polyline(Doodle.circle_pts(pos + Vector2(0, -rr * 0.3), rr, v), Color(0.9, 0.15, 0.1, 0.55), 4.0)
		if fl & ViewState.EF_ELITE:
			draw_mesh(mesh, null, Transform2D(rot, Vector2(sx * 1.09, 1.07), 0.0, at + Vector2(0, 1)), Color(0, 0, 0, 1))
		draw_mesh(mesh, null, Transform2D(rot, Vector2(sx, 1.0), 0.0, at), mod)
		var top := _etop[ty] if ty < _etop.size() else -30.0
		if fl & ViewState.EF_WINDUP:
			var p := at + Vector2(0, top - 6)
			draw_line(p + Vector2(0, -16), p + Vector2(0, -5), excl, 4.0)
			draw_circle(p, 2.5, excl)
		if fl & ViewState.EF_PARKED:
			if ty == _t_ju:
				draw_mesh(_mesh(K_MISC, M_URNE, st, v), null, Transform2D(0.0, at + Vector2(0, top - 4)))
			elif ty == _t_porsche and int(t * 3.0) % 2 == 0:
				draw_circle(at + Vector2(-26 * sx, 2), 3.5, Color(1, 0.6, 0.1))
				draw_circle(at + Vector2(26 * sx, 2), 3.5, Color(1, 0.6, 0.1))
		if fl & ViewState.EF_SHIELDED:
			var gr := 34.0 if not _boss_idx.has(ty) else 62.0
			var gm := _mesh(K_PROJ, Content.PROJ_ORDER.find("goldbarren"), 4, v)
			var cnt := 6 if _boss_idx.has(ty) else 3
			for k in cnt:
				var a := t * 0.9 + TAU * k / cnt
				draw_mesh(gm, null, Transform2D(a * 0.5, pos + Vector2(cos(a) * gr, sin(a) * gr * 0.7 - 10.0)))
		if ty == _t_startup:
			var sp := at + Vector2(9 * sx, -21)
			var fl_r := 3.0 + 2.0 * absf(sin(t * 25.0 + ph))
			draw_circle(sp, fl_r, Color(1.0, 0.8, 0.2))
			draw_circle(sp, fl_r * 0.5, Color(1.0, 0.35, 0.1))
		if (fl & ViewState.EF_ELITE) and not _boss_idx.has(ty) and i < vs.e_hp.size():
			var w := 40.0
			var bp := at + Vector2(-w * 0.5, top - 12)
			draw_rect(Rect2(bp, Vector2(w, 6)), Color(1, 1, 1, 0.85))
			draw_rect(Rect2(bp, Vector2(w * vs.e_hp[i], 6)), Color(0.8, 0.15, 0.1))
			draw_rect(Rect2(bp, Vector2(w, 6)), INK, false, 1.5)
	_prev = new_prev
	if _heading.size() > new_prev.size() + 32:
		for k in _heading.keys():
			if not new_prev.has(k):
				_heading.erase(k)


# --- Players ----------------------------------------------------------------------

func _draw_players(vs: ViewState, st: int) -> void:
	var meta := get_meta_dict()
	var mplayers: Dictionary = meta.get("players", {}) if meta.get("players") is Dictionary else {}
	var coop := vs.players.size() > 1 or int(meta.get("num_players", 1)) > 1
	var me := local_id()
	var t := anim_time
	var slot := 0
	var t_stadt := Content.CHAR_ORDER.find("stadtbild")
	var t_klima := Content.CHAR_ORDER.find("klimakleber")
	var t_sozial := Content.CHAR_ORDER.find("sozialtourist")
	var t_rad := Content.CHAR_ORDER.find("lastenrad")
	var new_prev := {}
	for p in vs.players:
		var col: Color = SLOT_COLORS[slot % SLOT_COLORS.size()]
		slot += 1
		var state := int(p.get("state", 0))
		if state == 2:
			continue
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var ci := clampi(int(p.get("char", 0)), 0, Content.CHAR_ORDER.size() - 1)
		var flags := int(p.get("flags", 0))
		var aim: float = p.get("aim", 0.0)
		var pid := int(p.get("id", 0))
		var v := Doodle.variant(pid * 3)
		var sx := -1.0 if cos(aim) < -0.05 else 1.0
		# movement heading (Critical Mass trail); falls back to the aim direction
		var prev: Vector2 = _p_prev.get(pid, pos)
		var hd: Vector2 = _p_heading.get(pid, Vector2(cos(aim), sin(aim)))
		if pos.distance_squared_to(prev) > 1.0:
			hd = hd.lerp((pos - prev).normalized(), 0.35).normalized()
			_p_heading[pid] = hd
		new_prev[pid] = pos
		var ult := (flags & ViewState.PF_ULT) != 0 and state == 0
		var lounging := ult and ci == t_sozial
		if ult and ci == t_rad:
			_draw_critical_mass(pos, hd, ci, st, v, pid)
		if _eff_tarif > 0.0 and state == 0:
			_draw_tarif_glow(pos, pid)
		# ground marker
		var mc := Color(col, 0.75) if pid == me else Color(col, 0.45)
		draw_polyline(Doodle.ellipse_pts(pos + Vector2(0, 22), 20, 7, v), mc, 3.0 if pid == me else 2.0)
		if state == 1:
			_dashed_circle(pos, REVIVE_RANGE, Color(col, 0.6), 2.5, 20, t * 0.8)
			var prog: float = p.get("revive", -1.0)
			if prog > 0.0:
				draw_arc(pos, REVIVE_RANGE - 6.0, -PI / 2, -PI / 2 + TAU * prog, 32, Color(0.25, 0.7, 0.3), 6.0)
			draw_mesh(_mesh(K_PLAYER, ci, st, v), null, Transform2D(PI / 2 * sx, pos + Vector2(0, 6)), Color(0.85, 0.85, 0.85))
			var hp := pos + Vector2(0, -34 - absf(sin(t * 3.0)) * 6.0)
			draw_rect(Rect2(hp - Vector2(3, 10), Vector2(6, 20)), Color(0.25, 0.7, 0.3))
			draw_rect(Rect2(hp - Vector2(10, 3), Vector2(20, 6)), Color(0.25, 0.7, 0.3))
			Doodle.text(self, tr("HUD_REVIVE_HINT"), pos + Vector2(0, 50), 16, INK, _hand, 4)
		else:
			if ci == t_klima and flags & ViewState.PF_STILL:
				draw_colored_polygon(Doodle.blob_pts(pos + Vector2(0, 20), 24, v, 3, 0.15), Color(0.95, 0.92, 0.65, 0.8))
			if ci == t_stadt:
				_draw_followers(int(p.get("followers", 0)), pos, st, pid)
			var mod := Color.WHITE
			if flags & ViewState.PF_INVULNERABLE and int(t * 14.0) % 2 == 0 and not lounging:
				mod = Color(1, 1, 1, 0.45)
			if lounging:
				_draw_lounger(pos, sx, st, v, pid)
			else:
				var bob := -absf(sin(t * 8.0 + pid)) * 2.0
				draw_mesh(_mesh(K_PLAYER, ci, st, v), null, Transform2D(sin(t * 8.0 + pid) * 0.04, Vector2(sx, 1), 0.0, pos + Vector2(0, bob)), mod)
				_draw_weapons(p.get("weapons", PackedByteArray()), pos, aim, st, v)
			if _eff_tarif > 0.0:
				_draw_tarif_tag(pos + Vector2(32, -40 if not lounging else -46), pid)
			if st >= 4:
				for k in 3:
					var a := t * 1.5 + TAU * k / 3.0
					_sparkle(pos + Vector2(cos(a) * 30, sin(a) * 18 - 14), 4.0 + 2.0 * absf(sin(t * 5.0 + k)), Color(1.0, 0.8, 0.15))
			var head := pos + Vector2(0, -50)
			if flags & ViewState.PF_REVERSED:
				Doodle.text(self, tr("HUD_REVERSED"), head + Vector2(0, -6), 22, Color(0.75, 0.1, 0.5), _hand, 5)
				head.y -= 22
			if flags & ViewState.PF_STUNNED:
				_clock(head + Vector2(-46, -12), 10.0)
				Doodle.text(self, tr("HUD_VERSPAETUNG"), head + Vector2(6, -6), 18, Color(0.15, 0.3, 0.7), _hand, 5)
				head.y -= 22
		if coop:
			var nm := str(mplayers.get(pid, {}).get("name", ""))
			if nm != "":
				Doodle.text(self, nm, pos + Vector2(0, 42 if state == 0 else 72), 16, col.darkened(0.2), _hand, 4)
	_p_prev = new_prev
	for k in _p_heading.keys():
		if not new_prev.has(k):
			_p_heading.erase(k)


# --- Ultimates (architecture §9) ------------------------------------------------------

## Urlaubsantrag: on the sun lounger with parasol and cocktail, Zzz and heal sparkles.
func _draw_lounger(pos: Vector2, sx: float, st: int, v: int, pid: int) -> void:
	var t := anim_time
	var breathe := 1.0 + sin(t * 2.2 + pid) * 0.015
	draw_mesh(_mesh(K_MISC, M_LOUNGER, st, v), null, Transform2D(0.0, Vector2(sx, breathe), 0.0, pos))
	var head := pos + Vector2(-30.0 * sx, -22.0)
	for k in 3:
		var ph := fmod(t * 0.55 + k / 3.0, 1.0)
		var zp := head + Vector2((-6.0 - ph * 20.0 + sin(ph * 6.0 + k) * 4.0) * sx, -10.0 - ph * 40.0)
		var za := sin(ph * PI)
		Doodle.text(self, "Z", zp, int(13 + ph * 12), Color(0.2, 0.35, 0.7, za), _hand, 3, Color(PAPER, za))
	var heal := Color(0.25, 0.72, 0.35)
	for k in 4:
		var ph := fmod(t * 0.7 + k * 0.27, 1.0)
		var hp := pos + Vector2((-6.0 + k * 13.0 + sin(t * 2.0 + k) * 5.0) * sx, 6.0 - ph * 46.0)
		var a := sin(ph * PI)
		var r := 3.5 + 1.5 * (k % 2)
		draw_line(hp + Vector2(-r, 0), hp + Vector2(r, 0), Color(heal, a), 2.5)
		draw_line(hp + Vector2(0, -r), hp + Vector2(0, r), Color(heal, a), 2.5)


## Critical Mass: ghost bikes trailing behind, plus speed lines.
func _draw_critical_mass(pos: Vector2, hd: Vector2, ci: int, st: int, v: int, pid: int) -> void:
	var t := anim_time
	var dir := hd.normalized() if hd.length_squared() > 0.01 else Vector2.RIGHT
	var sx := -1.0 if dir.x < -0.05 else 1.0
	var nrm := dir.orthogonal()
	var mesh := _mesh(K_PLAYER, ci, st, v)
	for k in range(4, 0, -1):
		var off := -dir * (34.0 * k) + nrm * sin(t * 9.0 + k * 1.3 + pid) * 5.0 * k * 0.5
		var a := 0.5 - k * 0.1
		draw_mesh(mesh, null, Transform2D(0.0, Vector2(sx, 1.0), 0.0, pos + off), Color(0.55, 0.95, 0.6, a))
	var lc := Color(0.25, 0.55, 0.3, 0.6)
	for k in 6:
		var lane := (float(k) - 2.5) * 9.0
		var ph := fmod(t * 3.0 + k * 0.37, 1.0)
		var a0 := pos - dir * (30.0 + ph * 120.0) + nrm * lane
		var a1 := a0 - dir * (24.0 + 16.0 * Doodle.noise(k))
		draw_line(a0, a1, Color(lc, lc.a * (1.0 - ph)), 2.5)


## Tarifrunde: soft red union-vest glow behind a player.
func _draw_tarif_glow(pos: Vector2, pid: int) -> void:
	var a := clampf(_eff_tarif / 0.5, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(anim_time * 6.0 + pid)
	var c := Color(0.85, 0.12, 0.1)
	var v := Doodle.frame % Doodle.VARIANTS
	var ctr := pos + Vector2(0, -4)
	var squash := Transform2D(0.0, Vector2(0.85, 1.0), 0.0, ctr) * Transform2D(0.0, -ctr)
	draw_colored_polygon(squash * Doodle.blob_pts(ctr, 36.0 + 3.0 * pulse, v, pid, 0.03), Color(c, (0.1 + 0.05 * pulse) * a))
	draw_colored_polygon(squash * Doodle.blob_pts(ctr, 26.0, v, pid + 1, 0.03), Color(c, 0.1 * a))
	draw_polyline(Doodle.ellipse_pts(ctr, 31.0 + 3.0 * pulse, 37.0 + 3.0 * pulse, v), Color(c, 0.5 * a), 2.5)


## Tarifrunde: small red "+50 %" badge next to a player.
func _draw_tarif_tag(p: Vector2, pid: int) -> void:
	var a := clampf(_eff_tarif / 0.5, 0.0, 1.0)
	var pct := int(round(float(Content.ULTS["tarifrunde"]["damage"]) * 100.0))
	var s := tr("HUD_ULT_TARIF_BONUS") % pct
	var bob := sin(anim_time * 4.0 + pid) * 2.0
	var w := _hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 12.0
	var r := Rect2(p + Vector2(-w * 0.5, -11 + bob), Vector2(w, 20))
	draw_set_transform(r.get_center(), -0.12, Vector2.ONE)
	var rr := Rect2(-r.size * 0.5, r.size)
	draw_rect(rr, Color(0.82, 0.12, 0.1, a))
	draw_polyline(Doodle.rect_pts(rr, Doodle.frame % 3, 1.0), Color(INK, a), 1.5)
	Doodle.text(self, s, Vector2(0, 6), 15, Color(1, 1, 1, a), _hand)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Antrag gestellt: every enemy carries a little form clipped to it.
func _draw_formular_notes(vs: ViewState, st: int) -> void:
	var n := vs.e_pos.size()
	var a := antrag_vis
	var label := tr("HUD_ULT_FORMULAR")
	var lw := _hand.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var with_text := n <= 140
	var note := _mesh(K_MISC, M_NOTE, st, Doodle.frame % Doodle.VARIANTS)
	var col := Color(1, 1, 1, a)
	var tcol := Color(0.15, 0.2, 0.45, a)
	var xf: Array[Transform2D] = []
	for i in n:
		var ty: int = vs.e_type[i]
		var top := _etop[ty] if ty < _etop.size() else -30.0
		var id: int = vs.e_id[i] if i < vs.e_id.size() else i
		var sway := sin(anim_time * 3.0 + id * 0.9) * 0.12
		var tr2 := Transform2D(-0.15 + sway, vs.e_pos[i] + Vector2(14, top - 8))
		draw_mesh(note, null, tr2, col)
		if with_text:
			xf.append(tr2)
	for tr2 in xf:
		draw_set_transform_matrix(tr2)
		draw_string(_hand, Vector2(-lw * 0.5, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tcol)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Antrag gestellt: sheets of paper and rubber stamps drift across the arena.
func _draw_paper_storm(st: int) -> void:
	var t := anim_time
	var a := antrag_vis
	var span := ARENA.x + 240.0
	var sheet := _mesh(K_MISC, M_SHEET, st, Doodle.frame % Doodle.VARIANTS)
	var stamp := _mesh(K_MISC, M_STAMP, st, Doodle.frame % Doodle.VARIANTS)
	for k in 46:
		var sp := 110.0 + 70.0 * (0.5 + 0.5 * Doodle.noise(k * 3))
		var x := fmod(Doodle.noise(k) * 2000.0 + 2000.0 + t * sp, span) - 120.0
		var y := WALL_BOTTOM + 20.0 + (0.5 + 0.5 * Doodle.noise(k + 77)) * (ARENA.y - WALL_BOTTOM - 40.0)
		y += sin(t * (1.1 + 0.4 * Doodle.noise(k + 5)) + k) * 26.0
		var rot := t * (1.5 + Doodle.noise(k + 9)) + k
		var flip := 0.35 + 0.65 * absf(sin(t * 2.3 + k * 0.7))
		if k % 7 == 3:
			draw_mesh(stamp, null, Transform2D(sin(t * 2.0 + k) * 0.5, Vector2(1.0, 1.0), 0.0, Vector2(x, y)), Color(1, 1, 1, a))
		else:
			draw_mesh(sheet, null, Transform2D(rot, Vector2(1.0, flip), 0.0, Vector2(x, y)), Color(1, 1, 1, a * 0.95))


func _draw_followers(n: int, pos: Vector2, st: int, pid: int) -> void:
	var t := anim_time
	n = mini(n, 16)
	for k in n:
		var ring := 0 if k < 8 else 1
		var cnt := mini(n - ring * 8, 8)
		var a := t * (0.7 if ring == 0 else -0.5) + TAU * (k % 8) / maxf(cnt, 1)
		var rad := 50.0 + ring * 18.0
		var fp := pos + Vector2(cos(a) * rad, sin(a) * rad * 0.7 + 6)
		var fs := -1.0 if sin(a) < 0.0 else 1.0
		draw_mesh(_mesh(K_FOLLOWER, k % 6, st, Doodle.variant(k + pid)), null,
			Transform2D(sin(t * 9.0 + k) * 0.06, Vector2(fs, 1), 0.0, fp + Vector2(0, -absf(sin(t * 9.0 + k)) * 2.0)))


func _draw_weapons(wb, pos: Vector2, aim: float, st: int, v: int) -> void:
	if not (wb is PackedByteArray):
		return
	var n: int = wb.size()
	if n == 0:
		return
	var flip := Vector2(1, -1) if cos(aim) < 0.0 else Vector2(1, 1)
	for i in n:
		var wi: int = wb[i]
		if wi >= Content.WEAPON_ORDER.size():
			continue
		var off := (float(i) - (n - 1) * 0.5) * 0.8
		var a := aim + off
		var wp := pos + Vector2(0, -8) + Vector2(cos(a), sin(a) * 0.85) * 36.0
		draw_mesh(_mesh(K_WEAPON, wi, st, v), null, Transform2D(aim, flip, 0.0, wp))


func _sparkle(p: Vector2, r: float, c: Color) -> void:
	draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), c, 2.0)
	draw_line(p + Vector2(0, -r), p + Vector2(0, r), c, 2.0)
	draw_line(p + Vector2(-r, -r) * 0.5, p + Vector2(r, r) * 0.5, c, 1.5)
	draw_line(p + Vector2(-r, r) * 0.5, p + Vector2(r, -r) * 0.5, c, 1.5)


func _clock(c: Vector2, r: float) -> void:
	draw_circle(c, r, WHITE)
	draw_polyline(Doodle.circle_pts(c, r, Doodle.frame), INK, 2.0)
	var a := anim_time * 6.0
	draw_line(c, c + Vector2(cos(a), sin(a)) * r * 0.8, RED, 2.0)
	draw_line(c, c + Vector2(0, -r * 0.55), INK, 2.0)


# --- Exit animations ------------------------------------------------------------

func _draw_exits(st: int) -> void:
	for ex in _exits:
		var t: float = ex["t"]
		var pos: Vector2 = ex["pos"]
		var enc: String = ex["enc"]
		var alpha := clampf((5.5 - t) / 0.8, 0.0, 1.0)
		var fade := Color(1, 1, 1, alpha)
		var v := Doodle.frame % Doodle.VARIANTS
		match enc:
			"sylt_clique":
				var p := pos + Vector2(pow(t, 1.6) * 90.0, sin(t * 3.0) * 4.0)
				var sm := _mesh(K_ENEMY, Content.ENEMY_ORDER.find("sylt_member"), st, v)
				for k in 4:
					draw_mesh(sm, null, Transform2D(sin(t * 6.0 + k) * 0.1, Vector2(0.55, 0.55), 0.0, p + Vector2(-36 + k * 22, -30)), fade)
				draw_mesh(_mesh(K_MISC, M_YACHT, st, v), null, Transform2D(sin(t * 2.0) * 0.04, p), fade)
				for k in 3:
					var np := p + Vector2(-30 + k * 30, -80 - fmod(t * 30.0 + k * 20.0, 60.0))
					Doodle.text(self, "♪", np, 26, Color(0.1, 0.3, 0.7, alpha), _hand, 3)
				Doodle.text(self, tr("SAY_SYLT_HUM"), p + Vector2(0, -110), 22, Color(INK, alpha), _hand, 5)
			"sauerlaender":
				var jp := pos + Vector2(t * t * 160.0, -t * t * 90.0)
				var js := 1.0 + t * 0.5
				draw_mesh(_mesh(K_ENEMY, _t_jet, st, v), null, Transform2D(-0.45, Vector2(js, js), 0.0, jp), fade)
				for k in 4:
					draw_circle(jp - Vector2(40 + k * 18, -12 - k * 10), 6.0 + k * 3, Color(0.7, 0.7, 0.7, 0.5 * alpha))
				_exit_text(enc, pos + Vector2(0, 70), alpha)
			"geschichtslehrer":
				# walks off to the sideline: into the political wilderness
				var et := Content.ENEMY_ORDER.find(enc)
				var wp := pos + Vector2(-t * 80.0, -absf(sin(t * 7.0)) * 4.0)
				draw_mesh(_mesh(K_ENEMY, et, st, v), null, Transform2D(sin(t * 7.0) * 0.06, Vector2(0.8, 0.8), 0.0, wp), fade)
				Doodle.text(self, "ABSEITS →", wp + Vector2(-60, -70), 20, Color(0.75, 0.12, 0.12, alpha), _hand, 4)
				_exit_text(enc, pos + Vector2(0, 80), alpha)
			"eidgenossin":
				var et := Content.ENEMY_ORDER.find(enc)
				var wp := pos + Vector2(t * 70.0, -absf(sin(t * 8.0)) * 4.0)
				draw_mesh(_mesh(K_ENEMY, et, st, v), null, Transform2D(sin(t * 8.0) * 0.06, wp), fade)
				draw_mesh(_mesh(K_MISC, M_FLAG, st, v), null, Transform2D(0.0, wp + Vector2(30, -20)), fade)
				_exit_text(enc, pos + Vector2(0, 80), alpha)
			_:
				_exit_text(enc, pos, alpha)


func _exit_text(enc: String, p: Vector2, alpha: float) -> void:
	var s := "%s %s" % [tr("ENC_%s_NAME" % enc.to_upper()), tr("ENC_%s_EXIT" % enc.to_upper())]
	Doodle.text(self, s, p, 22, Color(INK, alpha), _hand, 6, Color(PAPER, alpha))


# ==================================================================================
# Builders (baked into meshes)
# ==================================================================================

## A generic doodle person. Feet at (x, y), facing right. Returns anchor points.
func _person(sk: Doodle.Sketch, o: Dictionary) -> Dictionary:
	var x: float = o.get("x", 0.0)
	var y: float = o.get("y", 0.0)
	var s: float = o.get("s", 1.0)
	var tall: float = o.get("tall", 1.0)
	var k := s * tall
	var lean: float = o.get("lean", 0.0) * s
	var body: Color = o.get("body", SUIT_GREY)
	var pants: Color = o.get("pants", PANTS)
	var wb: float = o.get("wb", 6.5)
	var wt: float = o.get("wt", 7.5)
	var hr: float = o.get("hr", 7.5)
	var arms: String = o.get("arms", "down")
	var sleeve: Color = o.get("sleeve", body)
	var old_lw := sk.lw
	sk.lw = 1.5 + 0.55 * s
	var hip := y - 12.0 * k
	var sh := y - 29.0 * k
	# legs
	var legs: String = o.get("legs", "stand")
	if legs == "sit":
		sk.stroke(Vector2(x - 3 * s, hip), Vector2(x + 7 * s, hip + 2 * k), 3.4 * s, pants)
		sk.stroke(Vector2(x + 7 * s, hip + 2 * k), Vector2(x + 6 * s, y), 3.4 * s, pants)
		sk.line2(Vector2(x + 5 * s, y), Vector2(x + 10 * s, y), 3.0 * s, o.get("shoes", INK))
	else:
		var spread: float = o.get("spread", 3.5)
		var lf := Vector2(x - spread * s, y)
		var rf := Vector2(x + spread * s, y)
		sk.stroke(Vector2(x - 3 * s, hip), lf, 3.4 * s, pants)
		sk.stroke(Vector2(x + 3 * s, hip), rf, 3.4 * s, pants)
		var shoes: Color = o.get("shoes", INK)
		var sw: float = o.get("shoe_w", 3.0)
		sk.line2(lf + Vector2(-1.5 * s, -0.5 * s), lf + Vector2(sw * s, 0), 3.2 * s, shoes)
		sk.line2(rf + Vector2(-1.5 * s, -0.5 * s), rf + Vector2(sw * s, 0), 3.2 * s, shoes)
	# torso
	var torso := PackedVector2Array([
		Vector2(x - wb * s, hip), Vector2(x + wb * s, hip),
		Vector2(x + wt * s + lean, sh + 3.5 * k), Vector2(x + (wt - 3.0) * s + lean, sh),
		Vector2(x - (wt - 3.0) * s + lean, sh), Vector2(x - wt * s + lean, sh + 3.5 * k)])
	if o.get("skirt", false):
		torso = PackedVector2Array([
			Vector2(x - (wb + 3.0) * s, hip + 5 * k), Vector2(x + (wb + 3.0) * s, hip + 5 * k),
			Vector2(x + wt * s + lean, sh + 3.5 * k), Vector2(x + (wt - 3.0) * s + lean, sh),
			Vector2(x - (wt - 3.0) * s + lean, sh), Vector2(x - wt * s + lean, sh + 3.5 * k)])
	sk.shape(torso, body)
	var a := {
		"chest": Vector2(x + lean * 0.6, sh + 8.0 * k), "neck": Vector2(x + lean, sh),
		"hip": Vector2(x, hip), "s": s, "k": k, "torso": torso,
		"shl": Vector2(x - (wt - 1.5) * s + lean, sh + 3.5 * k), "shr": Vector2(x + (wt - 1.5) * s + lean, sh + 3.5 * k),
	}
	if o.has("deco"):
		(o["deco"] as Callable).call(sk, a)
	# arms
	var shl: Vector2 = a["shl"]
	var shr: Vector2 = a["shr"]
	var hl := shl + Vector2(-3 * s, 14 * k)
	var hrr := shr + Vector2(3 * s, 14 * k)
	var el := Vector2.INF
	var er := Vector2.INF
	var fist := false
	match arms:
		"crossed":
			hl = Vector2(x + 5 * s + lean, sh + 10 * k)
			hrr = Vector2(x - 4 * s + lean, sh + 11 * k)
			el = shl + Vector2(-1 * s, 9 * k)
			er = shr + Vector2(1 * s, 9 * k)
		"fists":
			el = shl + Vector2(1 * s, 9 * k)
			er = shr + Vector2(4 * s, 8 * k)
			hl = Vector2(x + 3 * s + lean, sh + 1 * k)
			hrr = Vector2(x + 12 * s + lean, sh - 2 * k)
			fist = true
		"fist_up":
			hrr = shr + Vector2(4 * s, -16 * k)
			el = shl + Vector2(-6 * s, 7 * k)
			hl = Vector2(x - wb * s, hip - 1 * k)
			fist = true
		"akimbo":
			el = shl + Vector2(-7 * s, 7 * k)
			er = shr + Vector2(7 * s, 7 * k)
			hl = Vector2(x - wb * s - 1 * s, hip - 1 * k)
			hrr = Vector2(x + wb * s + 1 * s, hip - 1 * k)
		"mug":
			er = shr + Vector2(4 * s, 9 * k)
			hrr = shr + Vector2(7 * s, 4 * k)
		"hold":
			el = shl + Vector2(1 * s, 9 * k)
			er = shr + Vector2(3 * s, 9 * k)
			hl = Vector2(x + 4 * s + lean, sh + 11 * k)
			hrr = Vector2(x + 12 * s + lean, sh + 10 * k)
		"phone_up":
			hrr = shr + Vector2(5 * s, -16 * k)
		"wave":
			hrr = shr + Vector2(7 * s, -13 * k)
		"point":
			hrr = shr + Vector2(14 * s, -4 * k)
		"banner":
			er = shr + Vector2(5 * s, 6 * k)
			hrr = shr + Vector2(8 * s, -4 * k)
			hl = shr + Vector2(7 * s, 8 * k)
			el = shl + Vector2(4 * s, 10 * k)
		"pockets":
			hl = Vector2(x - wb * s + 2 * s, hip - 1 * k)
			hrr = Vector2(x + wb * s - 2 * s, hip - 1 * k)
		"offer":
			er = shr + Vector2(4 * s, 9 * k)
			hrr = shr + Vector2(12 * s, 6 * k)
	var aw := 3.2 * s
	if el != Vector2.INF:
		sk.stroke(shl, el, aw, sleeve)
		sk.stroke(el, hl, aw, sleeve)
	else:
		sk.stroke(shl, hl, aw, sleeve)
	if er != Vector2.INF:
		sk.stroke(shr, er, aw, sleeve)
		sk.stroke(er, hrr, aw, sleeve)
	else:
		sk.stroke(shr, hrr, aw, sleeve)
	if arms != "pockets":
		var hs := (3.1 if fist else 2.2) * s
		sk.circle(hl, hs, FACE, true, sk.lw * 0.8)
		sk.circle(hrr, hs, FACE, true, sk.lw * 0.8)
	a["hl"] = hl
	a["hr"] = hrr
	# head
	var hc := Vector2(x + lean * 1.25 + float(o.get("head_dx", 0.0)) * s, sh - (hr - 2.0) * s + float(o.get("head_drop", 0.0)) * s)
	var hry: float = hr * s * float(o.get("head_ry", 1.0))
	var hrx: float = hr * s
	var hair: String = o.get("hair", "short")
	var hair_c: Color = o.get("hair_c", Color("4a3526"))
	if hair in ["long", "ponytail", "bob"]:
		_hair_back(sk, hair, hc, hrx, hry, hair_c, s)
	sk.ellipse(hc, hrx, hry, FACE)
	a["head"] = hc
	a["hrx"] = hrx
	a["hry"] = hry
	a["top"] = hc.y - hry
	_hair(sk, hair, hc, hrx, hry, hair_c, s)
	_face(sk, o, hc, hrx, hry, s)
	if o.has("hat"):
		_hat(sk, str(o["hat"]), hc, hrx, hry, o.get("hat_c", NAVY), s)
		a["top"] = hc.y - hry - 4.0 * s
	if o.has("after"):
		(o["after"] as Callable).call(sk, a)
	sk.lw = old_lw
	return a


func _hair_back(sk: Doodle.Sketch, style: String, hc: Vector2, rx: float, ry: float, c: Color, s: float) -> void:
	match style:
		"long":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.1, -ry * 0.3), hc + Vector2(rx * 1.1, -ry * 0.3),
				hc + Vector2(rx * 1.2, ry * 1.7), hc + Vector2(-rx * 1.2, ry * 1.7)]), c)
		"bob":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.15, -ry * 0.2), hc + Vector2(rx * 1.15, -ry * 0.2),
				hc + Vector2(rx * 1.2, ry * 0.9), hc + Vector2(-rx * 1.2, ry * 0.9)]), c)
		"ponytail":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.8, -ry * 0.6), hc + Vector2(-rx * 1.9, ry * 0.2),
				hc + Vector2(-rx * 1.7, ry * 1.2), hc + Vector2(-rx * 0.9, ry * 0.2)]), c)


func _hair(sk: Doodle.Sketch, style: String, hc: Vector2, rx: float, ry: float, c: Color, s: float) -> void:
	var cap := PackedVector2Array()
	for i in 9:
		var ang := PI * 1.1 + PI * 0.8 * i / 8.0
		cap.append(hc + Vector2(cos(ang) * rx * 1.08, sin(ang) * ry * 1.12))
	match style:
		"none":
			pass
		"bald":
			sk.line(PackedVector2Array([hc + Vector2(-rx * 0.3, -ry * 0.75), hc + Vector2(rx * 0.1, -ry * 0.85)]), 1.2 * s, WHITE)
		"horseshoe":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.05, -ry * 0.1), hc + Vector2(-rx * 0.8, -ry * 0.55),
				hc + Vector2(-rx * 0.55, -ry * 0.2), hc + Vector2(-rx * 0.85, ry * 0.3)]), c)
			sk.shape(PackedVector2Array([hc + Vector2(rx * 1.05, -ry * 0.1), hc + Vector2(rx * 0.8, -ry * 0.55),
				hc + Vector2(rx * 0.6, -ry * 0.2), hc + Vector2(rx * 0.85, ry * 0.3)]), c)
		"undercut":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.75, -ry * 0.55), hc + Vector2(-rx * 0.55, -ry * 1.45),
				hc + Vector2(rx * 0.3, -ry * 1.7), hc + Vector2(rx * 1.15, -ry * 1.15), hc + Vector2(rx * 0.85, -ry * 0.5)]), c)
			sk.hatch(PackedVector2Array([hc + Vector2(-rx * 0.95, -ry * 0.45), hc + Vector2(-rx * 0.6, -ry * 0.5),
				hc + Vector2(-rx * 0.6, ry * 0.1), hc + Vector2(-rx * 0.95, ry * 0.1)]), 2.0 * s, 1.4, Color(c, 0.6), 0.9)
		"slick":
			cap.append(hc + Vector2(rx * 1.0, -ry * 0.3))
			cap.insert(0, hc + Vector2(-rx * 1.05, -ry * 0.25))
			sk.shape(cap, c)
			sk.line(PackedVector2Array([hc + Vector2(-rx * 0.6, -ry * 0.75), hc + Vector2(rx * 0.6, -ry * 0.85)]), 1.2 * s, WHITE)
			sk.line(PackedVector2Array([hc + Vector2(-rx * 0.5, -ry * 0.5), hc + Vector2(rx * 0.7, -ry * 0.6)]), 0.9 * s, INK)
		"side":
			sk.shape(cap, c)
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.3, -ry * 1.05), hc + Vector2(rx * 1.2, -ry * 0.75),
				hc + Vector2(rx * 1.05, -ry * 0.4), hc + Vector2(rx * 0.3, -ry * 0.62)]), c)
		"bun":
			sk.shape(cap, c)
			sk.circle(hc + Vector2(-rx * 0.3, -ry * 1.3), rx * 0.45, c)
		"curly":
			for i in 5:
				var ang := PI * 1.05 + PI * 0.9 * i / 4.0
				sk.circle(hc + Vector2(cos(ang) * rx * 0.95, sin(ang) * ry * 0.95), rx * 0.42, c)
		"bob", "long", "ponytail":
			sk.shape(cap, c)
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.9, -ry * 0.8), hc + Vector2(rx * 0.9, -ry * 0.85),
				hc + Vector2(rx * 0.95, -ry * 0.42), hc + Vector2(-rx * 0.2, -ry * 0.55)]), c)
		_:
			sk.shape(cap, c)


func _hat(sk: Doodle.Sketch, hat: String, hc: Vector2, rx: float, ry: float, c: Color, s: float) -> void:
	match hat:
		"cap":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.05, -ry * 0.4), hc + Vector2(-rx * 0.8, -ry * 1.15),
				hc + Vector2(rx * 0.6, -ry * 1.2), hc + Vector2(rx * 1.05, -ry * 0.45)]), c)
			sk.shape(PackedVector2Array([hc + Vector2(rx * 0.6, -ry * 0.6), hc + Vector2(rx * 1.9, -ry * 0.48),
				hc + Vector2(rx * 1.8, -ry * 0.3), hc + Vector2(rx * 0.6, -ry * 0.38)]), c.darkened(0.2))
		"visor":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.05, -ry * 0.7), hc + Vector2(rx * 1.05, -ry * 0.75),
				hc + Vector2(rx * 1.05, -ry * 0.45), hc + Vector2(-rx * 1.05, -ry * 0.4)]), c)
			sk.shape(PackedVector2Array([hc + Vector2(rx * 0.7, -ry * 0.65), hc + Vector2(rx * 1.9, -ry * 0.5),
				hc + Vector2(rx * 1.8, -ry * 0.3), hc + Vector2(rx * 0.7, -ry * 0.45)]), c)
		"hardhat":
			var dome := sk.ellipse_pts(hc + Vector2(0, -ry * 0.5), rx * 1.1, ry * 0.85, 10, PI, PI)
			sk.shape(dome, c)
			sk.line2(hc + Vector2(-rx * 1.4, -ry * 0.5), hc + Vector2(rx * 1.4, -ry * 0.5), 2.6 * s, INK)
		"peaked":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.0, -ry * 0.45), hc + Vector2(-rx * 1.15, -ry * 1.15),
				hc + Vector2(rx * 1.15, -ry * 1.2), hc + Vector2(rx * 1.0, -ry * 0.45)]), c)
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.2, -ry * 0.5), hc + Vector2(rx * 1.5, -ry * 0.4),
				hc + Vector2(rx * 1.0, -ry * 0.25)]), INK)
			sk.dot(hc + Vector2(0, -ry * 0.85), 1.4 * s, GOLD)
		"beanie":
			var dome := sk.ellipse_pts(hc + Vector2(0, -ry * 0.45), rx * 1.08, ry * 0.9, 10, PI, PI)
			sk.shape(dome, c)
			sk.circle(hc + Vector2(0, -ry * 1.35), rx * 0.3, c.lightened(0.3))
		"oma":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.8, -ry * 0.62), hc + Vector2(rx * 1.8, -ry * 0.67),
				hc + Vector2(rx * 1.5, -ry * 0.5), hc + Vector2(-rx * 1.5, -ry * 0.45)]), c)
			var dome := sk.ellipse_pts(hc + Vector2(0, -ry * 0.55), rx * 0.95, ry * 0.75, 10, PI, PI)
			sk.shape(dome, c)
			sk.circle(hc + Vector2(rx * 0.7, -ry * 0.85), rx * 0.32, Color("e05a8a"))
			sk.dot(hc + Vector2(rx * 0.7, -ry * 0.85), rx * 0.12, GOLD)
		"hood":
			# hoodie hood framing the (visible) face
			var outer := sk.ellipse_pts(hc + Vector2(-rx * 0.08, 0), rx * 1.38, ry * 1.32, 14, PI * 0.62, PI * 1.76)
			var inner := sk.ellipse_pts(hc + Vector2(rx * 0.14, ry * 0.18), rx * 0.92, ry * 0.86, 12, PI * 0.62, PI * 1.76)
			inner.reverse()
			var hood := outer.duplicate()
			hood.append_array(inner)
			sk.shape(hood, c)
			sk.line(PackedVector2Array([hc + Vector2(-rx * 1.1, -ry * 0.2), hc + Vector2(-rx * 0.7, -ry * 0.9)]), 0.8 * s, Color(1, 1, 1, 0.35))
		"helmet":
			var dome := sk.ellipse_pts(hc + Vector2(0, -ry * 0.42), rx * 1.12, ry * 0.9, 10, PI, PI)
			sk.shape(dome, c)
			sk.line2(hc + Vector2(-rx * 0.2, -ry * 1.15), hc + Vector2(rx * 0.5, -ry * 1.1), 1.4 * s, WHITE)
		"pot":
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 1.15, -ry * 0.42), hc + Vector2(-rx * 1.05, -ry * 1.35),
				hc + Vector2(rx * 1.05, -ry * 1.35), hc + Vector2(rx * 1.15, -ry * 0.42)]), Color("a5abb3"))
			sk.line2(hc + Vector2(rx * 1.1, -ry * 0.75), hc + Vector2(rx * 2.2, -ry * 0.95), 3.0 * s, INK)
			sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.2, -ry * 1.25), hc + Vector2(0, -ry * 2.2),
				hc + Vector2(rx * 0.2, -ry * 1.25)]), Color("c9cdd2"))
			sk.line2(hc + Vector2(-rx * 0.9, -ry * 0.45), hc + Vector2(-rx * 0.3, -ry * 1.1), 2.2 * s, Color("d8c79a"))
			sk.line2(hc + Vector2(-rx * 0.85, -ry * 1.05), hc + Vector2(-rx * 0.2, -ry * 0.5), 2.2 * s, Color("d8c79a"))
			sk.line2(hc + Vector2(rx * 0.2, -ry * 0.75), hc + Vector2(rx * 0.85, -ry * 0.75), 1.0 * s, INK)


func _face(sk: Doodle.Sketch, o: Dictionary, hc: Vector2, rx: float, ry: float, s: float) -> void:
	var eyes: String = o.get("eyes", "dots")
	var mouth: String = o.get("mouth", "flat")
	var brows: String = o.get("brows", "")
	var fx := rx * 0.22
	var el := hc + Vector2(-rx * 0.38 + fx, ry * 0.04)
	var er := hc + Vector2(rx * 0.38 + fx, ry * 0.04)
	var ew := 1.1 * s
	match eyes:
		"dots", "angry":
			sk.dot(el, ew, INK)
			sk.dot(er, ew, INK)
		"tired":
			sk.line2(el + Vector2(-1.6 * s, 0), el + Vector2(1.6 * s, 0.3 * s), 1.1 * s)
			sk.line2(er + Vector2(-1.6 * s, 0), er + Vector2(1.6 * s, 0.3 * s), 1.1 * s)
			sk.line2(el + Vector2(-1.2 * s, 1.8 * s), el + Vector2(1.2 * s, 1.9 * s), 0.7 * s, Color(0.4, 0.3, 0.45))
			sk.line2(er + Vector2(-1.2 * s, 1.8 * s), er + Vector2(1.2 * s, 1.9 * s), 0.7 * s, Color(0.4, 0.3, 0.45))
		"roll":
			sk.circle(el, 1.7 * s, WHITE, true, 0.8 * s)
			sk.circle(er, 1.7 * s, WHITE, true, 0.8 * s)
			sk.dot(el + Vector2(0.3 * s, -0.9 * s), 0.8 * s, INK)
			sk.dot(er + Vector2(0.3 * s, -0.9 * s), 0.8 * s, INK)
		"closed":
			sk.line(PackedVector2Array([el + Vector2(-1.5 * s, 0.4 * s), el + Vector2(0, -1.0 * s), el + Vector2(1.5 * s, 0.4 * s)]), 1.0 * s)
			sk.line(PackedVector2Array([er + Vector2(-1.5 * s, 0.4 * s), er + Vector2(0, -1.0 * s), er + Vector2(1.5 * s, 0.4 * s)]), 1.0 * s)
		"glasses":
			sk.dot(el, ew * 0.9, INK)
			sk.dot(er, ew * 0.9, INK)
			sk.circle(el, 2.4 * s, Color(1, 1, 1, 0.0), true, 0.9 * s)
			sk.circle(er, 2.4 * s, Color(1, 1, 1, 0.0), true, 0.9 * s)
			sk.line2(el + Vector2(2.4 * s, 0), er - Vector2(2.4 * s, 0), 0.8 * s)
		"sunglasses":
			sk.shape(PackedVector2Array([el + Vector2(-2.6 * s, -1.4 * s), er + Vector2(2.6 * s, -1.4 * s),
				er + Vector2(2.2 * s, 1.4 * s), er + Vector2(-1.5 * s, 1.6 * s), hc + Vector2(fx, -ry * 0.05),
				el + Vector2(1.5 * s, 1.6 * s), el + Vector2(-2.2 * s, 1.4 * s)]), Color("1d1d22"), true, 0.8 * s)
			sk.line2(er + Vector2(-0.6 * s, -0.6 * s), er + Vector2(0.8 * s, -0.8 * s), 0.7 * s, WHITE)
	match brows:
		"angry":
			sk.line2(el + Vector2(-2.0 * s, -2.8 * s), el + Vector2(1.6 * s, -1.6 * s), 1.2 * s)
			sk.line2(er + Vector2(-1.6 * s, -1.6 * s), er + Vector2(2.0 * s, -2.8 * s), 1.2 * s)
		"worried":
			sk.line2(el + Vector2(-2.0 * s, -2.0 * s), el + Vector2(1.6 * s, -2.9 * s), 1.0 * s)
			sk.line2(er + Vector2(-1.6 * s, -2.9 * s), er + Vector2(2.0 * s, -2.0 * s), 1.0 * s)
		"raised":
			sk.line(PackedVector2Array([el + Vector2(-1.8 * s, -2.6 * s), el + Vector2(0, -3.4 * s), el + Vector2(1.8 * s, -2.8 * s)]), 1.0 * s)
			sk.line(PackedVector2Array([er + Vector2(-1.8 * s, -2.8 * s), er + Vector2(0, -3.6 * s), er + Vector2(1.8 * s, -2.6 * s)]), 1.0 * s)
		"thick":
			sk.line2(el + Vector2(-2.0 * s, -2.6 * s), el + Vector2(1.8 * s, -2.2 * s), 1.8 * s)
			sk.line2(er + Vector2(-1.8 * s, -2.2 * s), er + Vector2(2.0 * s, -2.6 * s), 1.8 * s)
	var m := hc + Vector2(fx, ry * 0.52)
	var mw := rx * 0.36
	if o.has("mustache"):
		sk.shape(PackedVector2Array([m + Vector2(-mw * 1.3, -ry * 0.05), m + Vector2(0, -ry * 0.2), m + Vector2(mw * 1.3, -ry * 0.05),
			m + Vector2(mw * 0.4, -ry * 0.1), m + Vector2(-mw * 0.4, -ry * 0.1)]), o["mustache"], true, 0.6 * s)
	if o.has("beard"):
		sk.shape(PackedVector2Array([hc + Vector2(-rx * 0.95, ry * 0.05), hc + Vector2(-rx * 0.6, ry * 0.95),
			hc + Vector2(fx, ry * 1.25), hc + Vector2(rx * 0.75, ry * 0.95), hc + Vector2(rx * 1.0, ry * 0.05),
			hc + Vector2(rx * 0.5, ry * 0.3), hc + Vector2(-rx * 0.4, ry * 0.3)]), o["beard"])
	match mouth:
		"smile":
			sk.line(PackedVector2Array([m + Vector2(-mw, -0.6 * s), m + Vector2(0, 0.7 * s), m + Vector2(mw, -0.6 * s)]), 1.0 * s)
		"grin":
			sk.shape(PackedVector2Array([m + Vector2(-mw * 1.2, -1.0 * s), m + Vector2(mw * 1.2, -1.0 * s), m + Vector2(0, 1.6 * s)]),
				Color("7a2a2a"), true, 0.8 * s)
		"teeth":
			sk.shape(PackedVector2Array([m + Vector2(-mw * 1.3, -1.2 * s), m + Vector2(mw * 1.3, -1.2 * s),
				m + Vector2(mw * 0.9, 0.9 * s), m + Vector2(-mw * 0.9, 0.9 * s)]), WHITE, true, 0.8 * s)
			sk.line2(m + Vector2(-mw * 1.1, -0.2 * s), m + Vector2(mw * 1.1, -0.2 * s), 0.5 * s)
		"frown":
			sk.line(PackedVector2Array([m + Vector2(-mw, 0.8 * s), m + Vector2(0, -0.4 * s), m + Vector2(mw, 0.8 * s)]), 1.0 * s)
		"o":
			sk.circle(m + Vector2(0, 0.3 * s), 1.3 * s, Color("7a2a2a"), true, 0.7 * s)
		"smug":
			sk.line(PackedVector2Array([m + Vector2(-mw * 0.8, 0), m + Vector2(mw * 0.4, 0.3 * s), m + Vector2(mw * 1.1, -1.0 * s)]), 1.0 * s)
		"grit":
			sk.shape(PackedVector2Array([m + Vector2(-mw * 1.1, -0.8 * s), m + Vector2(mw * 1.1, -0.8 * s),
				m + Vector2(mw * 1.1, 0.8 * s), m + Vector2(-mw * 1.1, 0.8 * s)]), WHITE, true, 0.7 * s)
			sk.line2(m + Vector2(-mw * 1.1, 0), m + Vector2(mw * 1.1, 0), 0.5 * s)
		"flat":
			sk.line2(m + Vector2(-mw * 0.9, 0), m + Vector2(mw * 0.9, 0.2 * s), 1.0 * s)
	if o.get("blush", false):
		sk.dot(hc + Vector2(-rx * 0.55 + fx, ry * 0.3), 1.4 * s, Color(0.95, 0.5, 0.5, 0.7))
		sk.dot(hc + Vector2(rx * 0.6 + fx, ry * 0.3), 1.4 * s, Color(0.95, 0.5, 0.5, 0.7))


## Scribbled pencil shadow under feet.
func _shadow(sk: Doodle.Sketch, c: Vector2, w: float) -> void:
	var pts := PackedVector2Array()
	var n := int(w / 4.0) + 2
	for i in n:
		var fx := -w * 0.5 + w * i / (n - 1)
		pts.append(c + Vector2(fx, -2.0 if i % 2 == 0 else 2.0))
	sk.line(pts, 1.2, Color(0.2, 0.2, 0.2, 0.35))


# --- Enemies -----------------------------------------------------------------------

func _b_enemy(sk: Doodle.Sketch, id: String) -> void:
	var s := 1.0
	var tall := 1.0
	if LOOK.has(id):
		s = LOOK[id][0]
		tall = LOOK[id][1]
	var feet := 20.0 * s * tall
	var o := {"x": 0.0, "y": feet, "s": s, "tall": tall}
	if LOOK.has(id):
		_shadow(sk, Vector2(0, feet + 1), 22.0 * s)
	match id:
		"besorgter_buerger":
			o.merge({"body": Color("d9c48f"), "pants": Color("6c6152"), "wb": 7.8, "wt": 8.0, "hair": "horseshoe",
				"hair_c": Color("8a8a84"), "arms": "crossed", "brows": "angry", "mouth": "frown", "eyes": "dots",
				"shoes": Color("8a6a4a"), "shoe_w": 4.0, "mustache": Color("8a8a84"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.line2(c + Vector2(0, 2), c + Vector2(-0.5, 17 * s), 1.0, INK)
					k.shape(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(0, 4), c + Vector2(5, 0), c + Vector2(0, -1)]), Color("c7b07a"))})
			_person(sk, o)
		"telegram_onkel":
			o.merge({"body": Color("6f7a52"), "pants": DENIM, "hair": "bald", "eyes": "glasses", "mustache": Color("6a5a48"),
				"arms": "phone_up", "mouth": "o", "brows": "raised", "wb": 7.2,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"]
					k.hatch(a["torso"], 3.5, 0.7, Color(0.25, 0.3, 0.2, 0.5), 0.8)
					k.line2(c + Vector2(0, -7), c + Vector2(0, 9), 1.2, INK),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.rect(Rect2(h + Vector2(-3, -12), Vector2(7, 12)), Color("2a2a30"), true, 1.2)
					k.rect(Rect2(h + Vector2(-2, -11), Vector2(5, 8)), Color("8fd3ff"), false)
					k.fill(PackedVector2Array([h + Vector2(-1.5, -10.5), h + Vector2(2.5, -10.5), h + Vector2(2.5, -4), h + Vector2(-1.5, -4)]), Color("8fd3ff"), false)
					k.line(PackedVector2Array([h + Vector2(6, -16), h + Vector2(9, -19)]), 1.2, Color("2e9be0"))
					k.line(PackedVector2Array([h + Vector2(7, -11), h + Vector2(12, -12)]), 1.2, Color("2e9be0"))
					k.line(PackedVector2Array([h + Vector2(-5, -16), h + Vector2(-8, -19)]), 1.2, Color("2e9be0"))})
			_person(sk, o)
		"identitaerer_hipster":
			o.merge({"body": Color("2c3e66"), "pants": CHINO, "hair": "undercut", "hair_c": Color("c9a646"),
				"lean": 3.0, "arms": "down", "mouth": "smug", "eyes": "dots", "brows": "thick", "wb": 5.5, "wt": 7.0,
				"shoes": WHITE,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.shape(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(-1, 5), c + Vector2(-2, -1)]), WHITE, true, 1.0)
					k.shape(PackedVector2Array([c + Vector2(5, 0), c + Vector2(1, 5), c + Vector2(2, -1)]), WHITE, true, 1.0)
					k.line2(c + Vector2(0, 4), c + Vector2(0, 9), 1.0, INK)
					k.dot(c + Vector2(0, 6), 0.8, WHITE)})
			_person(sk, o)
		"reichsbuerger":
			o.merge({"body": Color("7a6a48"), "pants": Color("4c4a3a"), "hair": "none", "hat": "pot", "wb": 9.5, "wt": 9.0,
				"beard": Color("7a6450"), "mouth": "frown", "brows": "angry", "arms": "fists", "shoes": Color("3a2e22"),
				"shoe_w": 4.0,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"]
					k.rect(Rect2(c + Vector2(-8, -4), Vector2(6, 5)), Color("6a5b3c"), true, 1.0)
					k.rect(Rect2(c + Vector2(2, -4), Vector2(6, 5)), Color("6a5b3c"), true, 1.0)
					k.line(PackedVector2Array([a["hip"] + Vector2(-9, -3), a["hip"] + Vector2(0, 1), a["hip"] + Vector2(9, -3)]), 1.2, INK)})
			_person(sk, o)
		"ju_schnoesel":
			o.merge({"body": Color("f2a7c3"), "pants": CHINO, "hair": "side", "hair_c": Color("b88a4a"), "mouth": "smug",
				"eyes": "dots", "brows": "raised", "arms": "pockets", "wb": 5.5, "wt": 6.8, "shoes": Color("7a4a2a"),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.shape(PackedVector2Array([c + Vector2(-2, 1), c + Vector2(-8, -7), c + Vector2(-6, 3)]), Color("f7c6d9"), true, 1.1)
					k.shape(PackedVector2Array([c + Vector2(2, 1), c + Vector2(8, -7), c + Vector2(6, 3)]), Color("f7c6d9"), true, 1.1)})
			_person(sk, o)
		"hinterbaenkler":
			o.merge({"body": SUIT_GREY, "pants": Color("70757d"), "hair": "slick", "hair_c": Color("a0a0a0"), "eyes": "tired",
				"mouth": "flat", "arms": "hold", "wb": 7.0, "wt": 8.0,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.fill(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(3, 0), c + Vector2(0, 9)]), WHITE, false)
					k.shape(PackedVector2Array([c + Vector2(-1, 1), c + Vector2(1, 1), c + Vector2(1.5, 11), c + Vector2(0, 13), c + Vector2(-1.5, 11)]), Color("3a4a6a"), true, 0.8),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.rect(Rect2(h + Vector2(-10, -6), Vector2(13, 10)), Color("e2c46a"), true, 1.2)
					k.line2(h + Vector2(-8, -3), h + Vector2(0, -3), 0.8, INK)})
			_person(sk, o)
		"lobbyist":
			o.merge({"body": NAVY, "pants": Color("1d2436"), "hair": "slick", "hair_c": Color("1c1c1c"), "eyes": "dots",
				"brows": "raised", "mouth": "teeth", "arms": "offer", "wb": 5.0, "wt": 7.0, "hr": 7.0, "shoes": Color("3a1d10"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.fill(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(3, 0), c + Vector2(0, 10)]), WHITE, false)
					k.line2(c + Vector2(0, 1), c + Vector2(0, 12), 1.8, Color("1f8a8a"))
					k.line(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(-2, 14), c + Vector2(0, 17)]), 1.0, Color("d03030"))
					k.line(PackedVector2Array([c + Vector2(4, 0), c + Vector2(2, 14), c + Vector2(0, 17)]), 1.0, Color("d03030"))
					k.rect(Rect2(c + Vector2(-3.5, 16), Vector2(7, 9)), WHITE, true, 0.9)
					k.fill(PackedVector2Array([c + Vector2(-3.5, 16), c + Vector2(3.5, 16), c + Vector2(3.5, 18.5), c + Vector2(-3.5, 18.5)]), Color("d03030"), false),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.rect(Rect2(h + Vector2(1, -4), Vector2(8, 5)), WHITE, true, 0.9)})
			_person(sk, o)
		"porsche_suv":
			_shadow(sk, Vector2(0, 18), 64)
			sk.shape(PackedVector2Array([Vector2(-34, 12), Vector2(-35, -2), Vector2(-28, -6), Vector2(-16, -8), Vector2(-9, -20),
				Vector2(14, -20), Vector2(22, -8), Vector2(33, -5), Vector2(35, 4), Vector2(34, 12)]), Color("3d4248"))
			sk.shape(PackedVector2Array([Vector2(-7, -17), Vector2(1, -17), Vector2(1, -8), Vector2(-13, -8)]), Color("9cc9e8"), true, 1.4)
			sk.shape(PackedVector2Array([Vector2(4, -17), Vector2(13, -17), Vector2(19, -8), Vector2(4, -8)]), Color("9cc9e8"), true, 1.4)
			sk.line2(Vector2(-32, 1), Vector2(32, 1), 1.2, Color("8a9098"))
			sk.circle(Vector2(-20, 12), 7.5, Color("1a1a1a"))
			sk.circle(Vector2(-20, 12), 3.5, Color("b8bec6"), true, 1.0)
			sk.circle(Vector2(21, 12), 7.5, Color("1a1a1a"))
			sk.circle(Vector2(21, 12), 3.5, Color("b8bec6"), true, 1.0)
			sk.ellipse(Vector2(32, -1), 3, 2.2, Color("ffe27a"), true, 1.0)
			sk.ellipse(Vector2(-34, -1), 2, 2.2, Color("e03a2a"), true, 1.0)
			sk.line2(Vector2(-14, -21), Vector2(16, -21), 1.6, INK)
		"immobilienerbe":
			o.merge({"body": Color("5d5e3c"), "pants": CHINO, "hair": "side", "hair_c": Color("d9b860"), "mouth": "smug",
				"eyes": "dots", "brows": "raised", "arms": "offer", "wb": 7.2, "wt": 8.0, "shoes": Color("7a4a2a"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.shape(PackedVector2Array([c + Vector2(-7, 2), c + Vector2(-3, -1), c + Vector2(0, 6), c + Vector2(3, -1), c + Vector2(7, 2), c + Vector2(0, 9)]), Color("8a5a35"), true, 1.0)
					var hp: Vector2 = a["hip"]
					k.line2(hp + Vector2(-7, -5), hp + Vector2(-1, -5), 1.0, INK)
					k.line2(hp + Vector2(1, -5), hp + Vector2(7, -5), 1.0, INK)
					k.line2(c + Vector2(0, 8), hp + Vector2(0, -1), 1.0, INK),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"] + Vector2(3, 3)
					k.circle(h, 2.5, Color(0, 0, 0, 0), true, 1.0)
					k.line2(h + Vector2(1, 2), h + Vector2(3, 9), 1.8, GOLD)
					k.line2(h + Vector2(-1, 2), h + Vector2(-3, 8), 1.8, Color("c0c4ca"))
					k.line2(h + Vector2(0, 2), h + Vector2(0, 10), 1.8, GOLD)})
			_person(sk, o)
		"golfclub_vorstand":
			o.merge({"body": Color("f4e7a1"), "pants": Color("b3473f"), "hair": "horseshoe", "hair_c": WHITE, "hat": "visor",
				"hat_c": WHITE, "mustache": WHITE, "mouth": "smug", "eyes": "dots", "arms": "down", "wb": 7.5, "wt": 8.0,
				"shoes": WHITE,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"]
					for dx in [-4.0, 2.0]:
						k.shape(PackedVector2Array([c + Vector2(dx, -4), c + Vector2(dx + 3, 0), c + Vector2(dx, 4), c + Vector2(dx - 3, 0)]), Color("7aa6d6"), true, 0.8),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.line2(h + Vector2(0, -2), h + Vector2(6, 20), 1.8, Color("9a9a9a"))
					k.shape(PackedVector2Array([h + Vector2(4, 19), h + Vector2(12, 21), h + Vector2(11, 24), h + Vector2(4, 23)]), Color("c0c4ca"), true, 1.2)})
			_person(sk, o)
		"fdp_jungunternehmer":
			o.merge({"body": Color("f2c418"), "sleeve": Color("1f5aa6"), "pants": DENIM, "hair": "bun", "hair_c": Color("6a4a2a"),
				"mouth": "grin", "eyes": "dots", "brows": "raised", "arms": "hold", "wb": 7.0, "wt": 7.8, "shoes": WHITE,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.shape(PackedVector2Array([c + Vector2(-7, 3), c + Vector2(0, 7), c + Vector2(7, 3), c + Vector2(4, -1), c + Vector2(-4, -1)]), Color("1f5aa6"), true, 1.0)
					k.line2(c + Vector2(-2, 7), c + Vector2(-2, 13), 1.0, INK)
					k.line2(c + Vector2(2, 7), c + Vector2(2, 13), 1.0, INK),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = (a["hl"] + a["hr"]) * 0.5
					k.shape(PackedVector2Array([h + Vector2(-9, 1), h + Vector2(9, 1), h + Vector2(7, -13), h + Vector2(-7, -13)]), Color("c8ccd2"), true, 1.2)
					k.line(PackedVector2Array([h + Vector2(-4, -3), h + Vector2(-1, -6), h + Vector2(1, -5), h + Vector2(5, -11)]), 1.4, Color("e0207a"))
					k.line2(h + Vector2(-11, 1), h + Vector2(11, 1), 2.4, INK)})
			_person(sk, o)
		"startup":
			_shadow(sk, Vector2(0, 12), 18)
			sk.line2(Vector2(-4, 6), Vector2(-5, 12), 1.8, INK)
			sk.line2(Vector2(4, 6), Vector2(5, 12), 1.8, INK)
			sk.rect(Rect2(-9, -10, 18, 16), Color("c9a26b"), true, 1.8)
			sk.line2(Vector2(-9, -6), Vector2(9, -6), 2.4, Color("e0d0a0"))
			sk.shape(sk.star_pts(Vector2(0, 1), 4.0, 1.8, 5), Color("e0207a"), true, 0.8)
			sk.line(PackedVector2Array([Vector2(2, -10), Vector2(5, -15), Vector2(9, -18), Vector2(9, -21)]), 1.4, INK)
			sk.dot(Vector2(-3, -2), 0.9, INK)
			sk.dot(Vector2(3, -2), 0.9, INK)
		"privatjet":
			_shadow(sk, Vector2(-4, 22), 40)
			sk.shape(PackedVector2Array([Vector2(-6, -4), Vector2(-16, -30), Vector2(-9, -30), Vector2(10, -4)]), Color("e6e8ec"))
			sk.shape(PackedVector2Array([Vector2(-6, 4), Vector2(-16, 30), Vector2(-9, 30), Vector2(10, 4)]), Color("e6e8ec"))
			sk.line2(Vector2(-12, -24), Vector2(2, -6), 1.6, GOLD)
			sk.line2(Vector2(-12, 24), Vector2(2, 6), 1.6, GOLD)
			sk.shape(PackedVector2Array([Vector2(-30, -2), Vector2(-36, -12), Vector2(-31, -12), Vector2(-24, -2)]), Color("e6e8ec"))
			sk.shape(PackedVector2Array([Vector2(-30, 2), Vector2(-36, 12), Vector2(-31, 12), Vector2(-24, 2)]), Color("e6e8ec"))
			sk.ellipse(Vector2(0, 0), 34, 6.5, WHITE)
			sk.line2(Vector2(-28, 0), Vector2(26, 0), 1.6, GOLD)
			sk.ellipse(Vector2(28, 0), 5, 3.5, Color("2a3a5a"), true, 1.0)
			for i in 5:
				sk.dot(Vector2(-14 + i * 7, -2.5), 1.2, Color("2a3a5a"))
		"sylt_member":
			o.merge({"body": WHITE, "pants": Color("e0806a"), "hair": "slick", "hair_c": Color("e0c070"), "eyes": "sunglasses",
				"mouth": "grin", "arms": "offer", "wb": 6.8, "wt": 7.8, "shoes": Color("7a4a2a"), "blush": true,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var sl: Vector2 = a["shl"]
					var sr: Vector2 = a["shr"]
					var c: Vector2 = a["chest"]
					k.shape(PackedVector2Array([sl + Vector2(-1, -3), sr + Vector2(1, -3), sr + Vector2(1, 2), c + Vector2(2, 2), c + Vector2(-2, 2), sl + Vector2(-1, 2)]), Color("e86aa0"), true, 1.1)
					k.stroke(c + Vector2(-2, 1), c + Vector2(-4, 9), 2.4, Color("e86aa0"))
					k.stroke(c + Vector2(2, 1), c + Vector2(4, 9), 2.4, Color("e86aa0"))
					k.circle(c + Vector2(0, 2), 1.8, Color("e86aa0"), true, 0.9),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.shape(PackedVector2Array([h + Vector2(-2, -9), h + Vector2(3, -9), h + Vector2(1, -3), h + Vector2(0, -3)]), Color(1, 0.95, 0.7, 0.9), true, 0.8)
					k.line2(h + Vector2(0.5, -3), h + Vector2(0.5, 1), 0.9, INK)})
			_person(sk, o)
		"geschichtslehrer":
			o.merge({"body": Color("8b6b47"), "pants": Color("4a3a2a"), "hair": "side", "hair_c": Color("3a2a1e"),
				"mouth": "flat", "brows": "thick", "eyes": "dots", "arms": "point", "wb": 7.0, "wt": 8.0, "shoes": Color("2a1e14"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.hatch(a["torso"], 3.0, 0.8, Color(0.35, 0.25, 0.15, 0.6), 0.8)
					k.hatch(a["torso"], 3.0, -0.8, Color(0.35, 0.25, 0.15, 0.4), 0.8)
					k.fill(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(3, 0), c + Vector2(0, 9)]), WHITE, false)
					k.shape(PackedVector2Array([c + Vector2(-1, 1), c + Vector2(1, 1), c + Vector2(1.6, 11), c + Vector2(0, 13), c + Vector2(-1.6, 11)]), Color("7a1f2a"), true, 0.8)
					k.ellipse(a["hip"] + Vector2(-7, -6), 2.0, 3.0, Color("5a4030"), true, 0.8),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.line2(h, h + Vector2(16, -14), 1.6, Color("9a7a50"))
					k.dot(h + Vector2(16, -14), 1.4, RED)})
			_person(sk, o)
		"sauerlaender":
			o.merge({"body": Color("2d3340"), "pants": Color("252a35"), "hair": "horseshoe", "hair_c": Color("b0b0b0"),
				"head_ry": 1.25, "eyes": "glasses", "mouth": "smug", "brows": "raised", "arms": "point", "wb": 6.0, "wt": 7.5,
				"hr": 7.0, "shoes": Color("1a1a1a"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.fill(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(3, 0), c + Vector2(0, 11)]), WHITE, false)
					k.shape(PackedVector2Array([c + Vector2(-1, 1), c + Vector2(1, 1), c + Vector2(1.6, 14), c + Vector2(0, 16), c + Vector2(-1.6, 14)]), Color("3a6ab0"), true, 0.8)})
			_person(sk, o)
		"eidgenossin":
			o.merge({"body": Color("1f2a44"), "pants": Color("1f2a44"), "hair": "ponytail", "hair_c": Color("c8a868"),
				"mouth": "flat", "brows": "angry", "eyes": "dots", "arms": "akimbo", "wb": 6.0, "wt": 7.5, "shoes": Color("1a1a1a"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.fill(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(3, 0), c + Vector2(0, 8)]), WHITE, false)
					k.line(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(-1, 9), c + Vector2(-3, 16)]), 1.0, INK)
					k.line(PackedVector2Array([c + Vector2(3, 0), c + Vector2(1, 9), c + Vector2(3, 16)]), 1.0, INK)
					var pin: Vector2 = c + Vector2(4.5, 6)
					k.rect(Rect2(pin - Vector2(2.2, 2.2), Vector2(4.4, 4.4)), Color("d52b1e"), true, 0.6)
					k._seg(pin - Vector2(1.4, 0), pin + Vector2(1.4, 0), 0.8, Color.WHITE)
					k._seg(pin - Vector2(0, 1.4), pin + Vector2(0, 1.4), 0.8, Color.WHITE)})
			_person(sk, o)


# --- Projectiles (pointing +x) --------------------------------------------------------

func _b_proj(sk: Doodle.Sketch, id: String) -> void:
	sk.lw = 1.6
	sk.misreg = 0.6
	if id in ENEMY_PROJ:
		var hr := 13.0 if id != "fluegel" else 16.0
		sk.fill(sk.ellipse_pts(Vector2.ZERO, hr, hr * 0.85), Color(0.9, 0.15, 0.1, 0.22), false)
	match id:
		"stern":
			var c := Color("b43ad6")
			for i in 3:
				var a := PI * i / 3.0
				var d := Vector2(cos(a), sin(a)) * 8.0
				sk.line2(-d, d, 3.6, INK)
			for i in 3:
				var a := PI * i / 3.0
				var d := Vector2(cos(a), sin(a)) * 7.0
				sk._seg(-d, d, 2.0, sk.fc(c))
		"flasche":
			sk.shape(PackedVector2Array([Vector2(-8, -3.5), Vector2(3, -3.5), Vector2(6, -1.8), Vector2(10, -1.8),
				Vector2(10, 1.8), Vector2(6, 1.8), Vector2(3, 3.5), Vector2(-8, 3.5)]), Color("4f8a3a"))
			sk.rect(Rect2(-5, -3.2, 5, 6.4), Color("f4e6b8"), false)
		"nadel":
			sk.line2(Vector2(-10, 0), Vector2(10, 0), 1.8, Color("8a8f98"))
			sk.circle(Vector2(-10, 0), 2.4, Color("e05a8a"), true, 1.0)
			sk.line(PackedVector2Array([Vector2(-11, 1), Vector2(-15, 3), Vector2(-18, 1), Vector2(-22, 3)]), 1.2, Color("e05a8a"))
		"tofu":
			sk.rect(Rect2(-5, -5, 10, 10), Color("f3ecd2"))
			sk.shape(PackedVector2Array([Vector2(-5, -5), Vector2(-2, -8), Vector2(8, -8), Vector2(5, -5)]), Color("fff8e4"), true, 1.2)
			sk.shape(PackedVector2Array([Vector2(5, -5), Vector2(8, -8), Vector2(8, 2), Vector2(5, 5)]), Color("ddd2b2"), true, 1.2)
		"farbe":
			sk.shape(PackedVector2Array([Vector2(-6, -5), Vector2(3, -6), Vector2(7, -1), Vector2(6, 5), Vector2(-3, 6), Vector2(-7, 1)]), Color("e0207a"))
			sk.line2(Vector2(-7, -5), Vector2(-10, -8), 1.4, INK)
			sk.dot(Vector2(2, -2), 1.3, Color(1, 1, 1, 0.8))
		"flugblatt":
			sk.rect(Rect2(-6, -8, 12, 16), WHITE)
			sk._seg(Vector2(-4, -5), Vector2(4, -5), 2.0, sk.lc(RED))
			for i in 3:
				sk.line2(Vector2(-4, -1 + i * 3), Vector2(4, -1 + i * 3), 0.8, INK)
		"kettenbrief":
			sk.rect(Rect2(-8, -5.5, 16, 11), Color("f2ead2"))
			sk.line(PackedVector2Array([Vector2(-8, -5.5), Vector2(0, 1), Vector2(8, -5.5)]), 1.4)
			sk.circle(Vector2(6, 3), 2.4, RED, true, 0.8)
			sk.line(PackedVector2Array([Vector2(-14, 2), Vector2(-10, 2)]), 1.2, Color("2e9be0"))
		"golfball":
			sk.circle(Vector2.ZERO, 4.8, WHITE, true, 1.4)
			sk.dot(Vector2(-1.5, -1), 0.6, Color(0.5, 0.5, 0.5))
			sk.dot(Vector2(1.5, 1), 0.6, Color(0.5, 0.5, 0.5))
			sk.dot(Vector2(1.5, -1.8), 0.6, Color(0.5, 0.5, 0.5))
			sk.line2(Vector2(-12, 0), Vector2(-7, 0), 1.0, Color(0.4, 0.4, 0.4, 0.6))
		"champagner":
			sk.shape(PackedVector2Array([Vector2(-10, -4), Vector2(2, -4), Vector2(6, -2), Vector2(11, -2),
				Vector2(11, 2), Vector2(6, 2), Vector2(2, 4), Vector2(-10, 4)]), Color("21452e"))
			sk.shape(PackedVector2Array([Vector2(4, -3), Vector2(12, -2.4), Vector2(12, 2.4), Vector2(4, 3)]), GOLD, true, 1.0)
			sk.rect(Rect2(-6, -3.5, 5, 7), Color("f4ecd0"), false)
		"buch":
			sk.rect(Rect2(-7, -5.5, 14, 11), Color("7a3a2a"))
			sk.fill(PackedVector2Array([Vector2(-6, 4), Vector2(7, 4), Vector2(7, 6), Vector2(-6, 6)]), Color("f4ecd0"), false)
			sk.line2(Vector2(-4, -5), Vector2(-4, 5), 1.0, INK)
			sk.line2(Vector2(-1, -2), Vector2(5, -2), 1.0, GOLD)
		"bierdeckel":
			sk.circle(Vector2.ZERO, 8.0, Color("f4ead0"), true, 1.6)
			sk.line(sk.ellipse_pts(Vector2.ZERO, 6.0, 6.0), 1.4, RED, true)
			for i in 4:
				sk.line2(Vector2(-3 + i * 1.6, -2.5), Vector2(-3.3 + i * 1.6, 2.5), 0.9, INK)
			sk.line2(Vector2(-4, 2.2), Vector2(3.5, -2.2), 0.9, INK)
		"zirkusball":
			sk.circle(Vector2.ZERO, 10.0, Color("e8443a"), true, 2.0)
			sk.fill(PackedVector2Array([Vector2(-3, -9.5), Vector2(3, -9.5), Vector2(3, 9.5), Vector2(-3, 9.5)]), WHITE, false)
			sk.fill(PackedVector2Array([Vector2(-9.5, -2.5), Vector2(-5, -2.5), Vector2(-5, 2.5), Vector2(-9.5, 2.5)]), Color("2e6db4"), false)
			sk.fill(PackedVector2Array([Vector2(5, -2.5), Vector2(9.5, -2.5), Vector2(9.5, 2.5), Vector2(5, 2.5)]), Color("2e6db4"), false)
			sk.line(sk.ellipse_pts(Vector2.ZERO, 10, 10), 2.0, INK, true)
			sk.shape(sk.star_pts(Vector2.ZERO, 3.2, 1.4, 5), GOLD, true, 0.7)
		"fluegel":
			sk.shape(PackedVector2Array([Vector2(-14, -1), Vector2(-2, -4), Vector2(14, -2.5), Vector2(15, 0), Vector2(2, 3), Vector2(-14, 2)]), WHITE, true, 1.5)
			sk.line2(Vector2(10, -2), Vector2(14, -1), 1.6, RED)
		"goldbarren":
			sk.shape(PackedVector2Array([Vector2(-8, 4), Vector2(8, 4), Vector2(5.5, -4), Vector2(-5.5, -4)]), GOLD)
			sk.line2(Vector2(-3, -1.5), Vector2(3, -1.5), 0.9, Color(1, 1, 0.8))
		"spiegel":
			sk.line2(Vector2(0, 6), Vector2(0, 13), 2.6, Color("8a5a35"))
			sk.circle(Vector2.ZERO, 7.0, Color("bfe3f2"), true, 1.8)
			sk.line2(Vector2(-3.5, -1.5), Vector2(-0.5, -4.5), 1.4, WHITE)
			sk.line2(Vector2(1, 3), Vector2(3.5, 0.5), 1.0, WHITE)
		_:
			sk.circle(Vector2.ZERO, 5.0, RED)


# --- Pickups ---------------------------------------------------------------------------

func _b_pickup(sk: Doodle.Sketch, id: String) -> void:
	sk.lw = 1.6
	match id:
		"pfand":
			_shadow(sk, Vector2(0, 9), 10)
			sk.shape(PackedVector2Array([Vector2(-3.5, 8), Vector2(-3.5, -1), Vector2(-1.6, -4), Vector2(-1.6, -9),
				Vector2(1.6, -9), Vector2(1.6, -4), Vector2(3.5, -1), Vector2(3.5, 8)]), Color("6a4a22"))
			sk.fill(PackedVector2Array([Vector2(-3.2, 1), Vector2(3.2, 1), Vector2(3.2, 5), Vector2(-3.2, 5)]), Color("e8dfb8"), false)
			sk.line2(Vector2(-2, -2), Vector2(-2, 6), 0.9, Color(1, 1, 1, 0.5))
			sk.rect(Rect2(-1.8, -10.5, 3.6, 2), GOLD, true, 0.8)
		"passant":
			_b_follower_body(sk, 0, 2, 0.62, "wave", Vector2(0, 11))
		"geldschein":
			sk.shape(PackedVector2Array([Vector2(-10, -5), Vector2(10, -6), Vector2(11, 5), Vector2(-10, 6)]), Color("8fcf8a"))
			sk.circle(Vector2(0, 0), 3.2, Color("d6f0c8"), true, 0.9)
			sk.line2(Vector2(-1.6, -1), Vector2(1.4, -1.2), 0.8, INK)
			sk.line2(Vector2(-1.6, 1), Vector2(1.4, 0.8), 0.8, INK)
			sk.line(PackedVector2Array([Vector2(1.6, -2.4), Vector2(-1.2, -1.6), Vector2(-1.4, 1.6), Vector2(1.6, 2.4)]), 0.9)
		"stulle":
			_shadow(sk, Vector2(0, 7), 16)
			sk.shape(PackedVector2Array([Vector2(-10, 4), Vector2(10, 4), Vector2(10, 1), Vector2(-10, 1)]), Color("d8a868"))
			sk.line(PackedVector2Array([Vector2(-10, 0), Vector2(-6, -2), Vector2(-2, 0), Vector2(2, -2), Vector2(6, 0), Vector2(10, -2)]), 2.4, Color("5aa83a"))
			sk.shape(PackedVector2Array([Vector2(-8, -1), Vector2(8, -1), Vector2(8, -3), Vector2(-8, -3)]), Color("e88a8a"), true, 1.0)
			sk.shape(PackedVector2Array([Vector2(-10, -3), Vector2(10, -3), Vector2(9, -8), Vector2(-9, -8)]), Color("d8a868"))
			sk.dot(Vector2(-3, -5.5), 0.7, Color("8a6030"))
			sk.dot(Vector2(4, -6), 0.7, Color("8a6030"))
		"reichsausweis":
			sk.shape(PackedVector2Array([Vector2(-9, -6), Vector2(9, -6), Vector2(9, 6), Vector2(-9, 6)]), Color("b8a878"))
			sk.rect(Rect2(-7, -4, 5, 7), Color("e8e0c8"), true, 0.8)
			for i in 3:
				sk.line2(Vector2(0, -3 + i * 3), Vector2(7, -3 + i * 3), 0.8, INK)
			sk.circle(Vector2(5, 3), 3.0, Color(0.7, 0.2, 0.2, 0.0), true, 0.9)
			sk.line(PackedVector2Array([Vector2(-12, -9), Vector2(12, 9)]), 1.0, Color(0.7, 0.2, 0.2, 0.8))


# --- Summons ----------------------------------------------------------------------------

func _b_summon(sk: Doodle.Sketch, id: String) -> void:
	match id:
		"infostand":
			_shadow(sk, Vector2(0, 18), 46)
			sk.line2(Vector2(-18, 4), Vector2(-18, 18), 2.4)
			sk.line2(Vector2(18, 4), Vector2(18, 18), 2.4)
			sk.rect(Rect2(-22, -2, 44, 8), Color("e8dcc0"))
			sk.rect(Rect2(-20, 6, 40, 9), Color("c0392b"), true, 1.6)
			sk.line2(Vector2(-14, 10), Vector2(14, 10), 1.2, WHITE)
			sk.rect(Rect2(-16, -6, 8, 5), WHITE, true, 1.0)
			sk.rect(Rect2(-5, -7, 8, 6), Color("f2e27a"), true, 1.0)
			sk.line2(Vector2(10, -2), Vector2(10, -42), 2.2)
			var top := sk.ellipse_pts(Vector2(10, -40), 26, 14, 12, PI, PI)
			sk.shape(top, Color("e8443a"))
			for i in 3:
				var x := -10.0 + i * 13.0
				sk.fill(PackedVector2Array([Vector2(10, -53), Vector2(x, -40), Vector2(x + 6, -40)]), WHITE, false)
			sk.line(top, 2.0, INK, true)
		"oma":
			_person(sk, {"x": 0.0, "y": 18.0, "s": 0.95, "body": Color("8e6aa8"), "pants": Color("6a5a7a"), "skirt": true,
				"hair": "bun", "hair_c": Color("d8d8d8"), "hat": "oma", "hat_c": Color("b892d0"), "eyes": "glasses",
				"mouth": "smile", "arms": "fist_up", "wb": 6.0, "shoes": Color("5a3a2a"),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.line2(h + Vector2(0, 4), h + Vector2(0, -16), 1.8, INK)
					k.shape(PackedVector2Array([h + Vector2(-3, -14), h + Vector2(0, -22), h + Vector2(3, -14), h + Vector2(0, -2)]), Color("2e6db4"), true, 1.2)
					k.line(PackedVector2Array([h + Vector2(0, 4), h + Vector2(1, 7), h + Vector2(3, 7)]), 1.6)})
			_shadow(sk, Vector2(0, 19), 20)
		"genosse":
			# Schwarzer Block comrade: black hoodie, face visible and smiling, small flag.
			_shadow(sk, Vector2(0, 19), 20)
			_person(sk, {"x": 0.0, "y": 18.0, "s": 0.92, "body": Color("26262b"), "pants": Color("33333a"),
				"hair": "none", "hat": "hood", "hat_c": Color("2e2e34"), "eyes": "dots", "mouth": "smile", "blush": true,
				"arms": "wave", "wb": 6.8, "wt": 7.8, "shoes": Color("8a1e1e"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var n: Vector2 = a["neck"]
					k.line2(n + Vector2(-2, 1), n + Vector2(-2.5, 7), 0.9, WHITE)
					k.line2(n + Vector2(2, 1), n + Vector2(2.5, 7), 0.9, WHITE)
					var hp: Vector2 = a["hip"]
					k.line(PackedVector2Array([hp + Vector2(-5, -3), hp + Vector2(5, -3)]), 1.0, Color(0.5, 0.5, 0.55)),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.line2(h + Vector2(0, 5), h + Vector2(0, -20), 1.6, Color("8a5a35"))
					var f := PackedVector2Array([h + Vector2(1, -20), h + Vector2(15, -19), h + Vector2(14, -10), h + Vector2(1, -11)])
					k.fill(f, Color("d63a2e"), false)
					k.fill(PackedVector2Array([f[0], f[1], f[3]]), Color("26262b"), false)
					k.line(f, 1.1, INK, true)})
		"turbine":
			_shadow(sk, Vector2(0, 2), 30)
			sk.shape(PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(2, -76), Vector2(-2, -76)]), WHITE)
			sk.ellipse(Vector2(0, -78), 7, 4.5, Color("e6e8ec"))
			sk.line2(Vector2(-3, -30), Vector2(3, -30), 0.8, Color(0.5, 0.5, 0.5))


# --- Misc ---------------------------------------------------------------------------------

func _b_misc(sk: Doodle.Sketch, id: int) -> void:
	match id:
		M_BG:
			sk.jit = 0.5
			sk.seg = 60.0
			sk.misreg = 0.0
			sk.fill(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), ARENA, Vector2(0, ARENA.y)]), PAPER, false)
			sk.fill(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), Vector2(ARENA.x, WALL_TOP), Vector2(0, WALL_TOP)]), Color("a89c84"), false)
			var x := 40.0
			while x < ARENA.x:
				sk.line2(Vector2(x, WALL_BOTTOM), Vector2(x, ARENA.y), 1.0, Color(0.3, 0.45, 0.7, 0.13))
				x += 40.0
			var y := WALL_BOTTOM + 40.0
			while y < ARENA.y:
				sk.line2(Vector2(0, y), Vector2(ARENA.x, y), 1.0, Color(0.3, 0.45, 0.7, 0.13))
				y += 40.0
			sk.line2(Vector2(70, WALL_BOTTOM), Vector2(68, ARENA.y), 1.6, Color(0.8, 0.2, 0.2, 0.25))
			sk.hatch(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), Vector2(ARENA.x, WALL_TOP), Vector2(0, WALL_TOP)]),
				7.0, 2.3, Color(0.25, 0.2, 0.15, 0.22), 1.2)
			sk.hatch(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), Vector2(ARENA.x, WALL_TOP), Vector2(0, WALL_TOP)]),
				13.0, 0.9, Color(0.25, 0.2, 0.15, 0.15), 1.0)
			for i in 14:
				var p := Vector2(60 + i * 117 + Doodle.noise(i) * 30, 18 + absf(Doodle.noise(i + 50)) * 45)
				sk.line(sk.ellipse_pts(p, 6 + absf(Doodle.noise(i + 9)) * 6, 3, 6), 1.0, Color(0.2, 0.18, 0.12, 0.3), true)
			sk.seg = 9.0
			var faint := Color(0.25, 0.25, 0.3, 0.18)
			sk.line(sk.ellipse_pts(Vector2(1380, 820), 46, 44, 20, 0.4, TAU * 0.85), 5.0, Color(0.55, 0.35, 0.15, 0.13))
			sk.line(sk.ellipse_pts(Vector2(1384, 824), 40, 38, 18, 1.0, TAU * 0.7), 2.0, Color(0.55, 0.35, 0.15, 0.12))
			sk.line(sk.ellipse_pts(Vector2(240, 300), 30, 28, 16, 2.0, TAU * 0.8), 4.0, Color(0.55, 0.35, 0.15, 0.1))
			for p in [Vector2(520, 880), Vector2(1180, 230), Vector2(150, 640), Vector2(900, 520), Vector2(1500, 420)]:
				sk.line(sk.star_pts(p, 12, 5, 5), 1.4, faint, true)
			sk.line(PackedVector2Array([Vector2(700, 940), Vector2(760, 930), Vector2(820, 945), Vector2(880, 928)]), 1.6, faint)
			sk.line(PackedVector2Array([Vector2(300, 160), Vector2(340, 175), Vector2(330, 150), Vector2(370, 170)]), 1.4, faint)
			sk.line(PackedVector2Array([Vector2(1060, 760), Vector2(1100, 760), Vector2(1092, 752)]), 1.4, faint)
			sk.line(PackedVector2Array([Vector2(1100, 760), Vector2(1092, 768)]), 1.4, faint)
			var hrt := PackedVector2Array([Vector2(1500, 900), Vector2(1488, 886), Vector2(1492, 878), Vector2(1500, 884),
				Vector2(1508, 878), Vector2(1512, 886)])
			sk.line(hrt, 1.4, Color(0.8, 0.2, 0.3, 0.2), true)
			for i in 5:
				sk.line2(Vector2(90 + i * 6, 950), Vector2(92 + i * 6, 970), 1.4, faint)
			sk.line2(Vector2(86, 966), Vector2(122, 954), 1.4, faint)
			sk.seg = 30.0
			sk.line(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), ARENA, Vector2(0, ARENA.y)]), 4.0, INK, true)
		M_WALL:
			sk.jit = 0.6
			var w := SEG_W
			sk.rect(Rect2(0, WALL_TOP, w, WALL_BOTTOM - WALL_TOP), BRICK, false)
			var rows := 3
			var rh := (WALL_BOTTOM - WALL_TOP) / rows
			for r in rows:
				var yy := WALL_TOP + r * rh
				if r > 0:
					sk.line2(Vector2(0, yy), Vector2(w, yy), 1.2, Color("6a3a2a"))
				var bx := -11.0 if r % 2 else 0.0
				while bx < w:
					if bx > 0.0:
						sk.line2(Vector2(bx, yy), Vector2(bx, yy + rh), 1.2, Color("6a3a2a"))
					if sk.rng.randf() < 0.3:
						sk.fill(PackedVector2Array([Vector2(bx + 2, yy + 1.5), Vector2(bx + 20, yy + 1.5), Vector2(bx + 20, yy + rh - 1.5), Vector2(bx + 2, yy + rh - 1.5)]),
							Color("c9785a") if sk.rng.randf() < 0.6 else Color("9a5040"), false)
					bx += 22.0
			sk.line(PackedVector2Array([Vector2(-1, WALL_TOP), Vector2(w + 1, WALL_TOP)]), 3.0)
			sk.line(PackedVector2Array([Vector2(-1, WALL_BOTTOM), Vector2(w + 1, WALL_BOTTOM)]), 3.0)
		M_RUBBLE:
			sk.jit = 0.8
			var w := SEG_W
			sk.fill(PackedVector2Array([Vector2(0, WALL_TOP + 4), Vector2(w, WALL_TOP + 4), Vector2(w, WALL_BOTTOM - 2), Vector2(0, WALL_BOTTOM - 2)]),
				Color(0.45, 0.4, 0.35, 0.35), false)
			for side in [0.0, 1.0]:
				var bx := 6.0 if side == 0.0 else w - 26.0
				for i in 4:
					var c := Vector2(bx + sk.rng.randf_range(0, 20), WALL_TOP + 6 + i * 5 + sk.rng.randf_range(0, 4))
					var hw := sk.rng.randf_range(4, 8)
					sk.shape(PackedVector2Array([c + Vector2(-hw, -3), c + Vector2(hw, -4), c + Vector2(hw + 1, 3), c + Vector2(-hw, 4)]), BRICK, true, 1.4)
			for i in 4:
				var c := Vector2(sk.rng.randf_range(30, w - 30), sk.rng.randf_range(WALL_TOP + 2, WALL_BOTTOM + 12))
				sk.shape(PackedVector2Array([c + Vector2(-3, -2), c + Vector2(3, -2), c + Vector2(3, 2), c + Vector2(-3, 2)]), BRICK, true, 1.0)
		M_URNE:
			sk.lw = 1.6
			sk.rect(Rect2(-9, -8, 18, 13), Color("c8d2de"))
			sk.line2(Vector2(-5, -8), Vector2(5, -8), 2.4, INK)
			sk.shape(PackedVector2Array([Vector2(-3, -8), Vector2(-2, -16), Vector2(5, -16), Vector2(4, -8)]), WHITE, true, 1.2)
			sk.line2(Vector2(-1, -14), Vector2(3, -10), 1.0, RED)
			sk.line2(Vector2(3, -14), Vector2(-1, -10), 1.0, RED)
		M_BLADES:
			sk.lw = 1.6
			for i in 3:
				var a := TAU * i / 3.0
				var d := Vector2(cos(a), sin(a))
				var n := d.orthogonal()
				sk.shape(PackedVector2Array([d * 4 + n * 3, d * 40 + n * 1.5, d * 44, d * 40 - n * 1.0, d * 4 - n * 3]), WHITE, true, 1.5)
				sk.line2(d * 36, d * 42, 1.6, RED)
			sk.circle(Vector2.ZERO, 4, Color("e6e8ec"), true, 1.4)
		M_YACHT:
			sk.shape(PackedVector2Array([Vector2(-70, -10), Vector2(70, -14), Vector2(54, 14), Vector2(-56, 14)]), WHITE)
			sk.line2(Vector2(-64, 0), Vector2(62, -2), 2.6, Color("2e6db4"))
			sk.rect(Rect2(-30, -26, 50, 16), Color("e6e8ec"))
			for i in 4:
				sk.ellipse(Vector2(-20 + i * 12, -18), 3.5, 2.5, Color("2a3a5a"), true, 1.0)
			sk.line2(Vector2(30, -14), Vector2(30, -70), 2.2)
			sk.shape(PackedVector2Array([Vector2(32, -68), Vector2(62, -18), Vector2(32, -18)]), Color("fff8e8"))
			sk.line(PackedVector2Array([Vector2(-90, 16), Vector2(-70, 12), Vector2(-50, 18), Vector2(-30, 13), Vector2(-10, 18), Vector2(10, 13),
				Vector2(30, 18), Vector2(50, 13), Vector2(70, 18), Vector2(90, 14)]), 2.0, Color("2e6db4"))
		M_SCHIRM:
			var dome := sk.ellipse_pts(Vector2(0, -20), 44, 30, 14, PI, PI)
			sk.shape(dome, GOLD)
			for i in 4:
				var x := -33.0 + i * 22.0
				sk.line(PackedVector2Array([Vector2(x, -20), Vector2(x + 11, -46 + absf(x) * 0.25)]), 1.2, Color("a07810"))
			for x in [-42.0, -14.0, 14.0, 42.0]:
				sk.line2(Vector2(x, -20), Vector2(0, 40), 1.0, INK)
			sk.shape(sk.star_pts(Vector2(-18, -36), 4, 1.5, 4), WHITE, false)
		M_FLAG:
			sk.line2(Vector2(0, 0), Vector2(0, -40), 1.8)
			sk.rect(Rect2(1, -40, 18, 18), Color("d52b1e"), true, 1.4)
			sk._seg(Vector2(5, -31), Vector2(15, -31), 3.2, Color.WHITE)
			sk._seg(Vector2(10, -36), Vector2(10, -26), 3.2, Color.WHITE)
		M_CHALET:
			sk.rect(Rect2(-60, -40, 120, 50), Color("a0703a"))
			sk.shape(PackedVector2Array([Vector2(-74, -36), Vector2(0, -84), Vector2(74, -36)]), Color("6a4022"))
			sk.rect(Rect2(-40, -26, 20, 18), Color("cfe8f8"), true, 1.6)
			sk.rect(Rect2(20, -26, 20, 18), Color("cfe8f8"), true, 1.6)
			sk.rect(Rect2(-10, -20, 20, 30), Color("5a3418"), true, 1.6)
			for i in 9:
				sk.line2(Vector2(-60 + i * 15, -4), Vector2(-60 + i * 15, 4), 1.2)
			sk.line2(Vector2(-62, -4), Vector2(62, -4), 1.6)
		M_CIRCUS:
			sk.misreg = 0.0
			var sw := 26.0
			var cols := [Color(0.85, 0.15, 0.15, 0.55), Color(1, 1, 1, 0.55)]
			var yy := WALL_BOTTOM
			var k := 0
			while yy < ARENA.y:
				sk.fill(PackedVector2Array([Vector2(0, yy), Vector2(60, yy + 10), Vector2(60, yy + sw + 10), Vector2(0, yy + sw)]), cols[k % 2], false)
				sk.fill(PackedVector2Array([Vector2(ARENA.x, yy), Vector2(ARENA.x - 60, yy + 10), Vector2(ARENA.x - 60, yy + sw + 10), Vector2(ARENA.x, yy + sw)]), cols[k % 2], false)
				yy += sw
				k += 1
			var x := 0.0
			k = 0
			while x < ARENA.x:
				sk.shape(PackedVector2Array([Vector2(x, WALL_BOTTOM + 2), Vector2(x + 40, WALL_BOTTOM + 2), Vector2(x + 20, WALL_BOTTOM + 30)]),
					Color("e8443a") if k % 3 == 0 else (Color("f2c418") if k % 3 == 1 else Color("2e6db4")), true, 1.2)
				sk.shape(PackedVector2Array([Vector2(x, ARENA.y), Vector2(x + 40, ARENA.y), Vector2(x + 20, ARENA.y - 26)]),
					Color("e8443a") if k % 2 == 0 else WHITE, true, 1.2)
				x += 40.0
				k += 1
			sk.line(PackedVector2Array([Vector2(0, WALL_BOTTOM + 2), Vector2(ARENA.x, WALL_BOTTOM + 2)]), 2.0)
		M_SITTER:
			_person(sk, {"x": -2.0, "y": 8.0, "s": 0.62, "legs": "sit", "body": [Color("3f8f4f"), Color("e8b923"), Color("2e6db4")][sk.rng.randi() % 3],
				"pants": DENIM, "hair": ["curly", "ponytail", "short", "beanie"][sk.rng.randi() % 4], "arms": "hold", "mouth": "smile",
				"hair_c": [Color("2a2a2a"), Color("b8541e"), Color("c8a868")][sk.rng.randi() % 3],
				"after": func(k2: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k2.line2(h + Vector2(0, 2), h + Vector2(0, -14), 1.2)
					k2.rect(Rect2(h + Vector2(-6, -22), Vector2(12, 8)), WHITE, true, 1.0)
					k2.line2(h + Vector2(-4, -18), h + Vector2(4, -18), 1.0, RED)})
		M_LOUNGER:
			_b_lounger(sk)
		M_SHEET:
			sk.lw = 1.3
			sk.misreg = 0.6
			sk.shape(PackedVector2Array([Vector2(-8, -10), Vector2(6, -10), Vector2(8, -8), Vector2(8, 10), Vector2(-8, 10)]), WHITE)
			sk.fill(PackedVector2Array([Vector2(6, -10), Vector2(8, -8), Vector2(6, -8)]), Color("d8d2c0"), false)
			for i in 5:
				sk.line2(Vector2(-5, -6 + i * 3.2), Vector2(4 - (i % 2) * 3, -6 + i * 3.2), 0.8, Color(0.3, 0.35, 0.55))
			sk.circle(Vector2(3, 6), 2.6, Color(0, 0, 0, 0), true, 0.9)
			sk.line(sk.ellipse_pts(Vector2(3, 6), 2.6, 2.6, 8), 0.9, RED, true)
		M_STAMP:
			sk.lw = 1.5
			sk.rect(Rect2(-9, 2, 18, 5), RED)
			sk.rect(Rect2(-7, -2, 14, 4), Color("8a5a35"))
			sk.stroke(Vector2(0, -2), Vector2(0, -9), 3.0, Color("8a5a35"))
			sk.circle(Vector2(0, -12), 4.2, Color("a8703f"))
			sk.line2(Vector2(-6, 8.5), Vector2(6, 8.5), 1.2, Color(0.8, 0.15, 0.1, 0.8))
		M_NOTE:
			sk.lw = 1.1
			sk.misreg = 0.5
			sk.shape(PackedVector2Array([Vector2(-23, -8), Vector2(23, -9), Vector2(24, 8), Vector2(-22, 9)]), Color("fffbe0"))
			sk.line2(Vector2(-19, 6), Vector2(19, 5.5), 0.7, Color(0.75, 0.2, 0.2, 0.7))
			sk.rect(Rect2(-25, -11, 5, 9), Color("a5abb3"), true, 0.8)


# --- Players ------------------------------------------------------------------------------

## Stage posture (GDD §7): stooped with a mug, upright, fists, banner, confident.
func _posture(st: int) -> Dictionary:
	match st:
		0: return {"lean": 3.5, "head_drop": 2.5, "arms": "mug", "eyes": "tired", "mouth": "o", "brows": "worried"}
		1: return {"lean": 0.5, "arms": "down", "eyes": "roll", "mouth": "flat", "brows": ""}
		2: return {"lean": 0.0, "arms": "fists", "eyes": "angry", "mouth": "grit", "brows": "angry"}
		3: return {"lean": 0.0, "arms": "banner", "eyes": "dots", "mouth": "smile", "brows": "thick"}
		_: return {"lean": -0.8, "arms": "fist_up", "eyes": "closed", "mouth": "grin", "brows": "raised"}


func _stage_props(sk: Doodle.Sketch, a: Dictionary, st: int, s: float) -> void:
	var h: Vector2 = a["hr"]
	if st == 0:
		sk.shape(PackedVector2Array([h + Vector2(-1, -3), h + Vector2(5, -3), h + Vector2(4.5, 4), h + Vector2(-0.5, 4)]), WHITE, true, 1.2 * s)
		sk.line(PackedVector2Array([h + Vector2(5, -1.5), h + Vector2(7, -0.5), h + Vector2(5, 2)]), 1.0 * s)
		sk.line(PackedVector2Array([h + Vector2(1, -5), h + Vector2(2, -8), h + Vector2(1, -11)]), 0.9 * s, Color(0.5, 0.5, 0.5, 0.7))
		sk.line(PackedVector2Array([h + Vector2(3.5, -5), h + Vector2(4.5, -8), h + Vector2(3.5, -11)]), 0.9 * s, Color(0.5, 0.5, 0.5, 0.7))
	elif st == 3:
		sk.line2(h + Vector2(0, 12 * s), h + Vector2(0, -26 * s), 1.8 * s, Color("8a5a35"))
		sk.shape(PackedVector2Array([h + Vector2(1, -26 * s), h + Vector2(20 * s, -24 * s), h + Vector2(19 * s, -14 * s), h + Vector2(1, -15 * s)]), Color("e8443a"), true, 1.2 * s)
		sk.line(PackedVector2Array([h + Vector2(4 * s, -21 * s), h + Vector2(9 * s, -22 * s), h + Vector2(15 * s, -20 * s)]), 1.2 * s, WHITE)
		sk.line(PackedVector2Array([h + Vector2(4 * s, -18 * s), h + Vector2(12 * s, -18 * s)]), 1.0 * s, WHITE)


func _b_player(sk: Doodle.Sketch, id: String, st: int) -> void:
	var post := _posture(st)
	var base := {"x": 0.0, "y": 21.0, "s": 1.12}
	base.merge(post)
	var s := 1.12
	match id:
		"stadtbild":
			var crowd := [
				{"x": -11.0, "y": 13.0, "body": Color("3fa7a0"), "pants": Color("3fa7a0"), "hair": "ponytail", "hair_c": Color("2a1a14"),
					"deco": func(k: Doodle.Sketch, a: Dictionary):
						var c: Vector2 = a["neck"]
						k.line(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(-3, 6), c + Vector2(0, 8), c + Vector2(2, 6)]), 0.9, INK)
						k.dot(c + Vector2(2, 6.5), 1.0, Color("8a8f98"))},
				{"x": 10.0, "y": 12.0, "body": Color("2f5f9e"), "pants": Color("23324e"), "hair": "short", "hair_c": Color("6a4a2a"),
					"hat": "peaked", "hat_c": Color("23324e")},
				{"x": -5.0, "y": 22.0, "body": Color("8a8f98"), "pants": DENIM, "hair": "short", "hair_c": Color("b8541e"),
					"hat": "hardhat", "hat_c": Color("f2c418"),
					"deco": func(k: Doodle.Sketch, a: Dictionary):
						var t: PackedVector2Array = a["torso"]
						k.shape(t, Color("f08a24"), true, 1.0)
						k.line2((t[0] + t[5]) * 0.5, (t[1] + t[2]) * 0.5, 1.6, Color("f2f2a0"))},
				{"x": 13.0, "y": 23.0, "body": Color("7d4fa0"), "pants": Color("3a3a48"), "hair": "curly", "hair_c": Color("1a1a1a"),
					"deco": func(k: Doodle.Sketch, a: Dictionary):
						var sl: Vector2 = a["shl"]
						k.stroke(sl + Vector2(-2, 0), sl + Vector2(-3, 9), 2.0, Color("e8b923"))},
			]
			for c in crowd:
				var o := post.duplicate()
				o.merge(c, true)
				o["s"] = 0.74
				if st == 3 and c["x"] != 10.0:
					o["arms"] = "fists"
				var a := _person(sk, o)
				if st == 3 and c["x"] == 10.0:
					_stage_props(sk, a, st, 0.74)
				elif st == 0 and c["x"] == -5.0:
					_stage_props(sk, a, st, 0.74)
			_shadow(sk, Vector2(0, 24), 40)
			return
		"toechter":
			var girls := [
				{"x": -15.0, "y": 21.0, "body": Color("e05a8a"), "pants": DENIM, "hair": "ponytail", "hair_c": Color("2a1a14")},
				{"x": 0.0, "y": 23.0, "body": Color("3fa7a0"), "pants": Color("3a3a48"), "hair": "curly", "hair_c": Color("b8541e")},
				{"x": 15.0, "y": 21.0, "body": Color("f2c418"), "pants": DENIM, "hair": "bob", "hair_c": Color("4a3526")},
			]
			for c in girls:
				var o := post.duplicate()
				o.merge(c, true)
				o["s"] = 0.78
				o["arms"] = "hold" if st != 0 else "mug"
				o["wb"] = 5.5
				o["wt"] = 6.5
				_person(sk, o)
			var by := 12.0 if st >= 1 else 15.0
			sk.shape(PackedVector2Array([Vector2(-24, by - 7), Vector2(24, by - 8), Vector2(23, by + 3), Vector2(-23, by + 4)]), WHITE, true, 1.6)
			sk.line(PackedVector2Array([Vector2(-18, by - 3), Vector2(-10, by - 2), Vector2(-2, by - 4), Vector2(6, by - 2), Vector2(16, by - 3)]), 1.6, Color("8e44ad"))
			sk.line(PackedVector2Array([Vector2(-14, by + 0.5), Vector2(10, by + 0.5)]), 1.2, Color("8e44ad"))
			_shadow(sk, Vector2(0, 24), 44)
			return
	_shadow(sk, Vector2(0, 22), 24)
	var o := base
	match id:
		"sozialtourist":
			sk.rect(Rect2(-22, 2, 12, 18), Color("2e9be0"), true, 1.8)
			sk.line(PackedVector2Array([Vector2(-19, 2), Vector2(-19, -8), Vector2(-13, -8), Vector2(-13, 2)]), 1.8)
			sk.dot(Vector2(-19, 21), 2.0, INK)
			sk.dot(Vector2(-13, 21), 2.0, INK)
			sk.circle(Vector2(-16, 8), 2.4, Color("f2c418"), true, 0.8)
			sk.rect(Rect2(-20, 13, 5, 4), Color("e05a8a"), true, 0.8)
			o.merge({"body": Color("31b3a3"), "pants": CHINO, "hair": "short", "hair_c": Color("2a1a14"), "eyes": "sunglasses",
				"shoes": Color("c87a3a"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"]
					for d in [Vector2(-4, -3), Vector2(3, 1), Vector2(-2, 6), Vector2(4, 7)]:
						k.dot(c + d, 1.4, Color("f7d14a"))
					k.dot(c + Vector2(1, -5), 1.2, Color("e05a8a"))}, true)
			if st == 0:
				o["eyes"] = "sunglasses"
		"buergergeld":
			o.merge({"body": Color("e0a43a"), "pants": Color("9aa0a8"), "hair": "bun", "hair_c": Color("6a4a2a"), "wb": 7.8, "wt": 8.2,
				"shoes": Color("f2b8c8"), "shoe_w": 5.0,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["neck"]
					k.shape(PackedVector2Array([c + Vector2(-7, 2), c + Vector2(-5, -3), c + Vector2(5, -3), c + Vector2(7, 2), c + Vector2(0, 5)]), Color("c88a2a"), true, 1.0)
					k.line2(c + Vector2(-2, 5), c + Vector2(-2, 11), 1.0, WHITE)
					k.line2(c + Vector2(2, 5), c + Vector2(2, 11), 1.0, WHITE)
					k.rect(Rect2(a["hip"] + Vector2(-5, -7), Vector2(10, 5)), Color("c88a2a"), true, 1.0)}, true)
			if st >= 1:
				o["mouth"] = "smile" if st < 4 else "grin"
		"klimakleber":
			o.merge({"body": Color("f08a24"), "pants": DENIM, "hair": "short", "hat": "beanie", "hat_c": Color("3f8f4f"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var t: PackedVector2Array = a["torso"]
					var y1 := lerpf(t[0].y, t[3].y, 0.35)
					var y2 := lerpf(t[0].y, t[3].y, 0.65)
					k.line2(Vector2(t[0].x + 1, y1), Vector2(t[1].x - 1, y1), 2.2, Color("f4f4b0"))
					k.line2(Vector2(t[0].x + 1, y2), Vector2(t[1].x - 1, y2), 2.2, Color("f4f4b0"))
					k.line2(a["neck"], a["hip"], 1.0, INK)}, true)
		"lastenrad":
			sk.circle(Vector2(-16, 13), 9, Color(0, 0, 0, 0), true, 2.2)
			sk.circle(Vector2(22, 15), 7, Color(0, 0, 0, 0), true, 2.2)
			sk.line(PackedVector2Array([Vector2(-16, 13), Vector2(-4, 12), Vector2(-8, 0), Vector2(2, 0), Vector2(-4, 12)]), 2.0, Color("2e6db4"))
			sk.line(PackedVector2Array([Vector2(2, 0), Vector2(8, 14), Vector2(22, 15)]), 2.0, Color("2e6db4"))
			sk.rect(Rect2(8, -2, 24, 13), Color("6aa84f"), true, 2.0)
			sk.line2(Vector2(14, -2), Vector2(14, 11), 1.0)
			sk.line2(Vector2(26, -2), Vector2(26, 11), 1.0)
			sk.line2(Vector2(-10, 0), Vector2(-5, 0), 3.0)
			o.merge({"x": -6.0, "y": 8.0, "s": 1.0, "legs": "sit", "body": Color("6aa84f"), "pants": Color("3a4a3a"), "hair": "short",
				"hair_c": Color("c8a868"), "hat": "helmet", "hat_c": Color("2e6db4")}, true)
			s = 1.0
			if o["arms"] == "down" or o["arms"] == "mug":
				o["arms"] = "hold" if st != 0 else "mug"
		"gewerkschaft":
			o.merge({"body": Color("d63a2e"), "sleeve": WHITE, "pants": Color("3a3a48"), "hair": "short", "hair_c": Color("2a1a14"),
				"hat": "cap", "hat_c": Color("d63a2e"), "mustache": Color("2a1a14"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"]
					k.line(PackedVector2Array([c + Vector2(-5, -1), c + Vector2(-3, 2), c + Vector2(-1, -1), c + Vector2(1, 2), c + Vector2(3, -1), c + Vector2(5, 2)]), 1.2, WHITE)
					k.line2(a["neck"] + Vector2(-2, 0), a["neck"] + Vector2(-1, 9), 0.8, INK)
					k.rect(Rect2(a["neck"] + Vector2(-2.5, 9), Vector2(3, 2)), Color("c0c4ca"), true, 0.6)}, true)
		"antifa":
			o.merge({"body": Color("26262b"), "pants": Color("26262b"), "hair": "short", "hair_c": Color("2a1a14"), "shoes": Color("8a1e1e"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var n: Vector2 = a["neck"]
					k.shape(PackedVector2Array([n + Vector2(-8, 2), n + Vector2(-6, -4), n + Vector2(6, -4), n + Vector2(8, 2), n + Vector2(0, 4)]), Color("3a3a40"), true, 1.0)
					k.line2(n + Vector2(-2, 4), n + Vector2(-2, 10), 1.0, WHITE)
					var sl: Vector2 = a["shl"]
					k.line2(sl + Vector2(-2, 8), sl + Vector2(-2, -24), 1.6, Color("8a5a35"))
					k.shape(PackedVector2Array([sl + Vector2(-2, -24), sl + Vector2(-16, -24), sl + Vector2(-16, -14), sl + Vector2(-2, -14)]), Color("26262b"), true, 1.0)
					k.fill(PackedVector2Array([sl + Vector2(-2, -24), sl + Vector2(-16, -24), sl + Vector2(-2, -14)]), Color("d63a2e"), false)}, true)
		"oma":
			o.merge({"body": Color("8e6aa8"), "pants": Color("6a5a7a"), "skirt": true, "hair": "bun", "hair_c": Color("dcdcdc"),
				"hat": "oma", "hat_c": Color("b892d0"), "eyes": "glasses", "shoes": Color("5a3a2a"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"]
					for i in 3:
						k.dot(c + Vector2(0, -3 + i * 4), 0.9, WHITE)
					var sl: Vector2 = a["shl"]
					k.line(PackedVector2Array([sl, sl + Vector2(-3, 8)]), 1.0, INK)
					k.shape(PackedVector2Array([sl + Vector2(-8, 8), sl + Vector2(2, 8), sl + Vector2(1, 16), sl + Vector2(-7, 16)]), Color("8a3a3a"), true, 1.2)
					k.dot(sl + Vector2(-3, 11), 0.9, GOLD)}, true)
			if st == 1:
				o["eyes"] = "glasses"
	var a := _person(sk, o)
	_stage_props(sk, a, st, s)


## Passers-by orbiting Das Stadtbild: everyday jobs, varied clothes.
func _b_follower(sk: Doodle.Sketch, type: int, _st: int) -> void:
	_b_follower_body(sk, type, 0, 0.5, "", Vector2(0, 10))


func _b_follower_body(sk: Doodle.Sketch, type: int, _seed: int, s: float, arms: String, at: Vector2) -> void:
	var looks := [
		{"body": Color("3f8f4f"), "pants": DENIM, "hair": "short", "hair_c": Color("2a1a14")},
		{"body": WHITE, "pants": Color("3a3a48"), "hair": "bun", "hair_c": Color("6a4a2a"), "hat": "beanie", "hat_c": WHITE},
		{"body": Color("f2c418"), "pants": Color("23324e"), "hair": "ponytail", "hair_c": Color("b8541e"), "hat": "cap", "hat_c": Color("f2c418")},
		{"body": Color("2e9be0"), "pants": CHINO, "hair": "curly", "hair_c": Color("1a1a1a")},
		{"body": Color("b892d0"), "pants": Color("6a5a7a"), "hair": "bob", "hair_c": Color("d8d8d8"), "skirt": true},
		{"body": Color("e05a8a"), "pants": DENIM, "hair": "long", "hair_c": Color("4a3526")},
	]
	var o: Dictionary = looks[type % looks.size()].duplicate()
	o.merge({"x": at.x, "y": at.y, "s": s, "mouth": "smile", "eyes": "dots", "arms": arms if arms != "" else ("wave" if type % 2 else "down")}, true)
	_shadow(sk, at + Vector2(0, 1), 14 * s)
	_person(sk, o)


## Urlaubsantrag: Sozialtourist:in reclining on a sun lounger under a parasol,
## cocktail in hand. Head left, feet right (mirror for facing left). Ground y = 21.
func _b_lounger(sk: Doodle.Sketch) -> void:
	sk.lw = 1.8
	_shadow(sk, Vector2(2, 22), 66)
	# parasol behind
	sk.line2(Vector2(-42, 22), Vector2(-33, -58), 2.2, Color("8a5a35"))
	var dome := sk.ellipse_pts(Vector2(-30, -56), 38, 20, 12, PI, PI)
	sk.shape(dome, Color("e8443a"))
	for i in 3:
		var x0 := -30.0 - 38.0 + 76.0 * (i * 2 + 1) / 6.0
		var x1 := x0 + 76.0 / 6.0
		sk.fill(PackedVector2Array([Vector2(-30, -75), Vector2(x0, -56), Vector2(x1, -56)]), WHITE, false)
	sk.line(dome, 1.8, INK, true)
	for i in 6:
		var x := -68.0 + i * 76.0 / 5.0
		sk.line(sk.ellipse_pts(Vector2(x + 6.5, -56), 6.5, 3.5, 6, 0.0, PI), 1.2)
	# lounger frame + fabric
	sk.line2(Vector2(-26, 21), Vector2(-20, 9), 2.2)
	sk.line2(Vector2(30, 21), Vector2(27, 9), 2.2)
	sk.line2(Vector2(4, 21), Vector2(6, 9), 2.2)
	var seat := PackedVector2Array([Vector2(-18, 6), Vector2(34, 6), Vector2(34, 11), Vector2(-18, 11)])
	sk.shape(seat, Color("2e9be0"))
	var back := PackedVector2Array([Vector2(-18, 6), Vector2(-36, -16), Vector2(-31, -19), Vector2(-14, 4)])
	sk.shape(back, Color("2e9be0"))
	for i in 5:
		var x := -12.0 + i * 10.0
		sk.fill(PackedVector2Array([Vector2(x, 6.5), Vector2(x + 4, 6.5), Vector2(x + 4, 10.5), Vector2(x, 10.5)]), WHITE, false)
	# person: legs (knees up), torso along the backrest, head with sunglasses
	var hip := Vector2(-2, 2)
	sk.stroke(hip, Vector2(13, -5), 4.0, CHINO)
	sk.stroke(Vector2(13, -5), Vector2(27, 3), 3.8, CHINO)
	sk.line2(Vector2(26, 3), Vector2(31, 2), 3.4, Color("c87a3a"))
	var torso := PackedVector2Array([hip + Vector2(2, 4), hip + Vector2(-2, -6), Vector2(-24, -14), Vector2(-27, -5)])
	sk.shape(torso, Color("31b3a3"))
	for d in [Vector2(-8, -2), Vector2(-15, -7), Vector2(-20, -4), Vector2(-11, -8)]:
		sk.dot(d, 1.3, Color("f7d14a"))
	sk.dot(Vector2(-6, -5), 1.1, Color("e05a8a"))
	# arm behind the head
	sk.stroke(Vector2(-23, -12), Vector2(-33, -22), 3.0, Color("31b3a3"))
	sk.stroke(Vector2(-33, -22), Vector2(-26, -27), 3.0, FACE)
	var hc := Vector2(-28, -18)
	sk.ellipse(hc, 7.5, 7.5, FACE)
	sk.shape(PackedVector2Array([hc + Vector2(-7, -2), hc + Vector2(-5, -7), hc + Vector2(2, -8.5), hc + Vector2(7, -5), hc + Vector2(1, -5)]), Color("2a1a14"))
	sk.shape(PackedVector2Array([hc + Vector2(-1, -1.5), hc + Vector2(7.5, -1.8), hc + Vector2(7, 1.6), hc + Vector2(3.5, 1.4), hc + Vector2(2, 0.4), hc + Vector2(0, 1.6)]),
		Color("1d1d22"), true, 0.8)
	sk.line(PackedVector2Array([hc + Vector2(1, 4), hc + Vector2(3.5, 5.5), hc + Vector2(6, 3.5)]), 1.0)
	# arm with cocktail
	sk.stroke(Vector2(-19, -8), Vector2(-10, -14), 3.0, Color("31b3a3"))
	sk.stroke(Vector2(-10, -14), Vector2(-4, -22), 3.0, FACE)
	var g := Vector2(-3, -30)
	sk.shape(PackedVector2Array([g + Vector2(-6, -5), g + Vector2(6, -5), g + Vector2(0, 3)]), Color("f5a33a"), true, 1.2)
	sk.line2(g + Vector2(0, 3), g + Vector2(0, 8), 1.2)
	sk.line2(g + Vector2(2, -4), g + Vector2(6, -12), 1.0, Color("e05a8a"))
	sk.shape(sk.ellipse_pts(g + Vector2(-4, -8), 5, 3, 7, PI, PI), Color("f2c418"), true, 0.9)
	sk.line2(g + Vector2(-4, -8), g + Vector2(-3, -4), 0.8)
	sk.circle(g + Vector2(5, -5), 2.0, Color("b6e05a"), true, 0.8)


# --- Weapons (icons pointing +x) -------------------------------------------------------

func _b_weapon(sk: Doodle.Sketch, id: String) -> void:
	sk.lw = 1.5
	sk.misreg = 0.5
	match id:
		"gendersternchen":
			for i in 3:
				var a := PI * i / 3.0
				var d := Vector2(cos(a), sin(a)) * 7.0
				sk.line2(-d, d, 3.4, INK)
				sk._seg(-d * 0.9, d * 0.9, 1.8, sk.fc(Color("b43ad6")))
		"pfandflasche":
			_b_proj(sk, "flasche")
		"megafon":
			sk.shape(PackedVector2Array([Vector2(-8, -2.5), Vector2(2, -3), Vector2(10, -8), Vector2(10, 8), Vector2(2, 3), Vector2(-8, 2.5)]), Color("e8443a"))
			sk.line2(Vector2(10, -7), Vector2(10, 7), 2.4, WHITE)
			sk.line2(Vector2(-4, 2), Vector2(-5, 7), 2.4, INK)
		"stricknadeln":
			sk.line2(Vector2(-9, -4), Vector2(9, 4), 1.6, Color("8a8f98"))
			sk.line2(Vector2(-9, 4), Vector2(9, -4), 1.6, Color("8a8f98"))
			sk.circle(Vector2(-9, -4), 1.8, Color("e05a8a"), true, 0.8)
			sk.circle(Vector2(-9, 4), 1.8, Color("e05a8a"), true, 0.8)
			sk.circle(Vector2(-2, 6), 4.0, Color("e05a8a"), true, 1.0)
		"doener":
			sk.line2(Vector2(-10, 0), Vector2(14, 0), 1.6, Color("9a9a9a"))
			sk.shape(PackedVector2Array([Vector2(-4, -6), Vector2(8, -4), Vector2(8, 4), Vector2(-4, 6)]), Color("b0703a"))
			sk.line2(Vector2(-1, -5), Vector2(-1, 5), 0.8, Color("6a3a1a"))
			sk.line2(Vector2(3, -4.5), Vector2(3, 4.5), 0.8, Color("6a3a1a"))
		"grundgesetz":
			sk.rect(Rect2(-6, -8, 12, 16), Color("2a4a8a"))
			sk._seg(Vector2(-5, 3), Vector2(5, 3), 1.6, sk.fc(Color("1a1a1a")))
			sk._seg(Vector2(-5, 4.8), Vector2(5, 4.8), 1.6, sk.fc(Color("d52b1e")))
			sk._seg(Vector2(-5, 6.6), Vector2(5, 6.6), 1.6, sk.fc(GOLD))
			sk.line2(Vector2(-3, -4), Vector2(3, -4), 1.2, WHITE)
		"transparent":
			sk.line2(Vector2(-10, 4), Vector2(10, 4), 1.6, Color("8a5a35"))
			sk.shape(PackedVector2Array([Vector2(-8, -8), Vector2(9, -9), Vector2(9, 3), Vector2(-8, 3)]), WHITE)
			sk.line2(Vector2(-5, -4), Vector2(6, -5), 1.4, RED)
			sk.line2(Vector2(-5, -1), Vector2(3, -1), 1.0, RED)
		"mietspiegel":
			_b_proj(sk, "spiegel")
		"tofu":
			_b_proj(sk, "tofu")
		"farbbeutel":
			_b_proj(sk, "farbe")
		"kleber":
			sk.shape(PackedVector2Array([Vector2(-8, -3.5), Vector2(4, -3.5), Vector2(6, -2), Vector2(6, 2), Vector2(4, 3.5), Vector2(-8, 3.5)]), Color("f2f2f2"))
			sk.rect(Rect2(6, -2, 4, 4), Color("e8443a"), true, 1.0)
			sk.line2(Vector2(-5, 0), Vector2(1, 0), 1.6, Color("2e6db4"))
		"infostand":
			sk.rect(Rect2(-6, -8, 12, 16), Color("c8a868"))
			sk.rect(Rect2(-4, -6, 8, 12), WHITE, true, 0.8)
			sk.rect(Rect2(-2.5, -9.5, 5, 3), Color("8a8f98"), true, 0.8)
			for i in 3:
				sk.line2(Vector2(-3, -3 + i * 3), Vector2(3, -3 + i * 3), 0.7)
		_:
			sk.circle(Vector2.ZERO, 4, GOLD)
