class_name WorldView
extends Node2D
## Draws the arena from a ViewState (architecture §3) in the Doodle/Paint style.
##
## Every entity is a cached ArrayMesh baked by Doodle.Sketch (one draw call each),
## keyed by kind, type, Zusammenhalt stage (desaturation and player posture),
## boil variant and hit flash. No per-entity nodes.
## Reads `source_view` if set (preview harness), else `Game.view`; draws nothing
## when neither exists.

## Geometry comes from Arena (GDD §5a): the sheet, four Brandmauer walls, the
## inner arena. Wall meshes are baked in the top wall's local frame (y from
## WALL_TOP to WALL_BOTTOM, +y into the arena) and rotated onto their side.
const ARENA := Arena.SIZE
const INNER := Arena.INNER
const WALL_TOP := Arena.WALL_OUT
const WALL_BOTTOM := Arena.WALL_IN
const WALL_SEGMENTS := Arena.WALL_SEGMENTS
const SEG_W := Arena.SEG_LEN_H
const REVIVE_RANGE := 60.0
## K_WALL types: 0..37 intact segments, then rubble (horizontal / vertical
## length) and the corner pillar.
const WALL_RUBBLE_H := 38
const WALL_RUBBLE_V := 39
const WALL_PILLAR := 40

enum { K_ENEMY = 1, K_PROJ, K_PICK, K_SUMMON, K_PLAYER, K_WEAPON, K_MISC, K_FOLLOWER, K_BIKE, K_WHEEL, K_WALL }
enum { M_BG, M_WALL, M_RUBBLE, M_URNE, M_BLADES, M_YACHT, M_SCHIRM, M_FLAG, M_CHALET, M_CIRCUS, M_SITTER,
	M_LOUNGER, M_SHEET, M_STAMP, M_NOTE, M_DESK, M_HIT, M_POTATO, M_ZIEGEL, M_ZIEGEL_V, M_DROP, M_KETTE }
## M_KETTE .. M_KETTE + 3: Menschenkette activists (four looks).
const KETTE_LOOKS := 4

## Friendly ink for our own ground markers (Kartoffelbrei target), so they never
## read like the red enemy lob marker.
const FRIEND := Color("2f8a5a")
const MASH := Color("f3e2a0")
const CHALK: Array[Color] = [Color("f28fb1"), Color("8fc8f2"), Color("f2e08f"), Color("a8e3a1"), Color("c9a8f0")]
## Ballpoint blue (Unterschriftenliste) and stamp red (Normenkontrolle).
const BIC := Color("1f3a9a")
const STAMP_RED := Color("c0262d")

## Lastenrad (Long John) geometry, facing +x, ground at y = 22. The body mesh
## (frame, box, rider) is baked in BIKE_FRAMES pedal phases; both wheels are
## separate meshes so their spokes can roll with the distance travelled.
const BIKE_FRAMES := 6
const BIKE_GHOST := 8                  # type offset for the Critical Mass ghost riders
const BIKE_RW := Vector2(-26, 13)
const BIKE_RW_R := 9.0
const BIKE_FW := Vector2(29, 16)
const BIKE_FW_R := 6.0
const BIKE_BB := Vector2(-9, 13)
const BIKE_HIP := Vector2(-16, 0)
const BIKE_GRIP := Vector2(1, -8.5)
const BIKE_CRANK := 4.5
const BIKE_BLUE := Color("2a8fbd")
const WOOD := Color("c98f55")
const GHOST_TINT := Color("bfe9cb")
## Spray-painted tags on the Brandmauer: [segment, text, paint color, angle].
## Language-neutral on purpose (no translation keys needed).
const GRAFFITI := [[1, "FCK AfD", Color("f4f1e6"), -0.05], [5, "NO PASARAN", Color("f2c418"), 0.04],
	[9, "FCK AfD", Color("ff8fc8"), 0.03], [16, "NO PASARAN", Color("8fe08a"), 0.03],
	[22, "FCK AfD", Color("f2c418"), -0.04], [28, "NO PASARAN", Color("f4f1e6"), 0.02], [33, "FCK AfD", Color("7ad0f0"), -0.03]]

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
## Telegraph standard (GDD §14 "Boss rules", research B7): enemy danger is red with a
## dashed edge and a fill that grows until impact; lasting zones are red hatching;
## "stand here" is a solid blue-turquoise ring with a hand. Never faded (D-086).
const DANGER := Color(0.85, 0.15, 0.1)
const TEAL := Color(0.05, 0.6, 0.68)
const WENDE_PINK := Color(0.7, 0.1, 0.45)
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
## Hazards the players' side creates (weapons, ultimates); they fade with
## `own_fx_opacity`. Explosions are not listed: enemy bombs use them too.
const OWN_HAZARDS := ["kleber", "sitzblockade", "farbklecks", "brei_marker", "ziegel", "paragraf", "kreide", "kette"]
const OWN_FX_MIN := 0.2
const INFOSTAND_SCALE := 0.55       # several stands per player must not cover the arena
const INFOSTAND_FOOT := 18.0        # mesh y of the stand's feet (stays on the ground when scaled)

## Overrides used by the preview harness (and possible replays).
var source_view: ViewState = null
var source_meta = null           # Dictionary or null
var local_id_override := -1

var draw_usec := 0               # duration of the last _draw() in microseconds
var anim_time := 0.0

var _cache := {}
var _tables := {}
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
var _p_roll := {}                 # player id -> distance ridden (Lastenrad wheels + pedals)
var _p_face := {}                 # player id -> facing (+1 / -1) of the Lastenrad
var _p_speed := {}                # player id -> smoothed px per frame (Lastenrad speed lines)
var _t_brei := -1                 # Kartoffelbrei projectile type (drawn on a lob arc)
var _t_overall := -1
var _s_prev := PackedVector2Array()   # summon positions last frame (Weißer Overall facing)
var _s_face := PackedFloat32Array()
var _brei_seen := {}              # Vector2i(target) -> anim_time a Kartoffelbrei marker was last seen
var _ziegel := PackedInt32Array() # hazard indices of wall bricks, drawn in a y-sorted second pass
var _kette := PackedInt32Array()  # hazard indices of Menschenkette links (5 per chain, in order)
var _stamp_q: Array = []          # Kahlschlag "GESTRICHEN" stamps, drawn above the players
var _t_mobile := {}               # summon types that face where they move (Overall, Sani, Lauti)
var _t_papp := -1
var _t_lauti := -1
var _t_laterne := -1
## Save option `own_fx_opacity` (GDD §19a, OWN_FX_MIN..1): alpha of everything the
## players' side draws except the characters. Re-read every frame (applies live).
var own_fx := 1.0
## Set by tools and tests; < 0 = read the Save option.
var own_fx_override := -1.0
var _own_proj := PackedByteArray()   # PROJ_ORDER index -> 1 if a players' projectile

## Lobby / Späti portraits (CharPortrait): baked player meshes, shared by all
## portraits. Static so no WorldView has to live in the UI tree.
static var _preview_cache := {}


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
	for id in ["stern", "flasche", "bierdeckel", "zirkusball", "farbe", "flugblatt", "aktenblatt", "sticker"]:
		_t_spin[Content.PROJ_ORDER.find(id)] = true
	_t_brei = Content.PROJ_ORDER.find("kartoffelbrei")
	_t_overall = Content.SUMMON_ORDER.find("overall")
	_t_papp = Content.SUMMON_ORDER.find("pappkamerad")
	_t_lauti = Content.SUMMON_ORDER.find("lauti")
	_t_laterne = Content.SUMMON_ORDER.find("laterne")
	for id in ["overall", "sani", "lauti"]:
		_t_mobile[Content.SUMMON_ORDER.find(id)] = true
	_own_proj.resize(Content.PROJ_ORDER.size())
	for i in Content.PROJ_ORDER.size():
		_own_proj[i] = 1 if is_own_proj(Content.PROJ_ORDER[i]) else 0
	read_own_fx()


static func is_own_proj(id: String) -> bool:
	return not (id in ENEMY_PROJ)


static func is_own_hazard(id: String) -> bool:
	return id in OWN_HAZARDS


func read_own_fx() -> void:
	if own_fx_override >= 0.0:
		own_fx = clampf(own_fx_override, OWN_FX_MIN, 1.0)
	else:
		own_fx = UIKit.option_float("own_fx_opacity", 1.0, OWN_FX_MIN, 1.0)


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
	read_own_fx()
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
	if not _stamp_q.is_empty():
		_draw_stamps()
	_draw_wende_countdown(vs)
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


## Per-stage lookup table for one mesh kind (index = type * VARIANTS + variant),
## filled lazily by the hot loops. Skips key hashing and a call per entity.
func _table(kind: int, count: int, st: int, white := false) -> Array:
	var key := (kind * 8 + st) * 2 + (1 if white else 0)
	var tab: Array = _tables.get(key, [])
	if tab.is_empty():
		tab.resize(count * Doodle.VARIANTS)
		_tables[key] = tab
	return tab


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
	for t in WALL_PILLAR + 1:
		for v in Doodle.VARIANTS:
			_mesh(K_WALL, t, st, v)
	# Lastenrad pedal phases + wheels, only when someone rides one
	var vs := get_view()
	var t_rad := Content.CHAR_ORDER.find("lastenrad")
	if vs != null:
		for p in vs.players:
			if int(p.get("char", -1)) == t_rad:
				for v in Doodle.VARIANTS:
					_mesh(K_WHEEL, 0, st, v)
					_mesh(K_WHEEL, 1, st, v)
					for f in BIKE_FRAMES:
						_mesh(K_BIKE, f, st, v)
				break
	for t in Content.SUMMON_ORDER.size():
		for v in Doodle.VARIANTS:
			_mesh(K_SUMMON, t, st, v)
	# weapon-made ground pieces (Kartoffelbrei marker, Brandmauer-Ziegel)
	for v in Doodle.VARIANTS:
		_mesh(K_MISC, M_POTATO, st, v)
		_mesh(K_MISC, M_ZIEGEL, st, v)
		_mesh(K_MISC, M_ZIEGEL_V, st, v)
		for k in KETTE_LOOKS:
			_mesh(K_MISC, M_KETTE + k, st, v)
	_mesh(K_MISC, M_DROP, st, 0)


## A character exactly as drawn in the arena (GDD §6: lobby and Späti portraits),
## baked once and shared. `grey` = fully desaturated (locked characters).
## Feet are at about y = +22, the figure faces +x.
static func character_preview(char_idx: int, stage: int, v := 0, grey := false) -> ArrayMesh:
	var ci := clampi(char_idx, 0, Content.CHAR_ORDER.size() - 1)
	var st := clampi(stage, 0, 4)
	var key := ((ci * 8 + st) * 4 + posmod(v, Doodle.VARIANTS)) * 2 + (1 if grey else 0)
	var m: ArrayMesh = _preview_cache.get(key)
	if m != null:
		return m
	var wv := WorldView.new()
	if grey:
		var sk := Doodle.Sketch.new(K_PLAYER * 7919 + ci * 131 + posmod(v, Doodle.VARIANTS) * 977 + 7, st)
		sk.amt = 1.0
		wv._b_player(sk, Content.CHAR_ORDER[ci], st)
		m = sk.build()
	else:
		m = wv._mesh(K_PLAYER, ci, st, posmod(v, Doodle.VARIANTS))
	wv.free()
	_preview_cache[key] = m
	return m


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
		K_BIKE:
			if type >= BIKE_GHOST:
				_ghostify(sk)
			_b_bike(sk, st, type % BIKE_GHOST, type < BIKE_GHOST)
		K_WHEEL:
			if type >= 2:
				_ghostify(sk)
			if type % 2 == 0:
				_b_wheel(sk, Vector2.ZERO, BIKE_RW_R)
			else:
				_b_wheel(sk, Vector2.ZERO, BIKE_FW_R)
		K_WALL:
			if type < WALL_SEGMENTS:
				_b_wall(sk, type)
			elif type == WALL_PILLAR:
				_b_pillar(sk)
			else:
				_b_rubble(sk, Arena.SEG_LEN_H if type == WALL_RUBBLE_H else Arena.SEG_LEN_V)
	return sk.build()


## Critical Mass ghost riders: a pale mint wash over every color.
func _ghostify(sk: Doodle.Sketch) -> void:
	sk.tint = GHOST_TINT
	sk.tint_fill = 0.72
	sk.tint_ink = 0.45


# --- Ground, wall, circus ------------------------------------------------------

func _draw_ground(vs: ViewState, st: int) -> void:
	draw_rect(Rect2(-1400, -1200, ARENA.x + 2800, ARENA.y + 2400), Doodle.desat(DESK, st))
	draw_mesh(_mesh(K_MISC, M_DESK, st, 0), null)
	# soft drop shadow of the paper sheet on the desk
	for k in 3:
		var o := 4.0 + k * 5.0
		draw_rect(Rect2(o, o + 2.0, ARENA.x + 2.0 - k * 2.0, ARENA.y), Color(0, 0, 0, 0.16))
	draw_mesh(_mesh(K_MISC, M_BG, st, 0), null)
	var b := vs.boss
	if not b.is_empty() and int(b.get("enc", -1)) == Content.ENCOUNTER_ORDER.find("sauerlaender") and int(b.get("phase", 0)) >= 2:
		draw_mesh(_mesh(K_MISC, M_CIRCUS, st, Doodle.variant(0)), null)
	if not b.is_empty() and int(b.get("enc", -1)) == Content.ENCOUNTER_ORDER.find("eidgenossin") and int(b.get("phase", 0)) >= 2:
		# Steuerparadies: Swiss chalet at the top where she retreats
		draw_mesh(_mesh(K_MISC, M_CHALET, st, Doodle.variant(1)), null, Transform2D(0.0, Vector2(1.4, 1.4), 0.0, Vector2(Arena.CENTER.x, INNER.position.y + 98.0)))


## Text on a wall segment reads upright on the top and bottom walls and along
## the left (bottom to top) and right (top to bottom) walls.
static func _wall_text_angle(seg: int) -> float:
	var side := Arena.side_of(seg)
	if side == Arena.RIGHT:
		return PI * 0.5
	if side == Arena.LEFT:
		return -PI * 0.5
	return 0.0


## Baseline anchor of a label on a segment; d = baseline depth on the top wall
## (from its outer face), mirrored so glyphs always sit on the wall.
static func _wall_label_pos(seg: int, d: float) -> Vector2:
	return Arena.seg_center(seg) + Vector2(0, 1).rotated(_wall_text_angle(seg)) * (d - Arena.WALL_THICK * 0.5)


func _draw_wall(vs: ViewState, st: int) -> void:
	var red := Doodle.desat(RED, maxi(st, 2))
	# four straight walls (GDD §5a): every segment is the top wall's mesh rotated onto its side
	for i in WALL_SEGMENTS:
		var v := Doodle.variant(i)
		var xf := Arena.seg_xform(i)
		if vs.wall & (1 << i):
			draw_mesh(_mesh(K_WALL, i, st, v), null, xf)
		else:
			var rubble := WALL_RUBBLE_H if Arena.side_of(i) % 2 == 0 else WALL_RUBBLE_V
			draw_mesh(_mesh(K_WALL, rubble, st, v), null, xf)
			draw_set_transform(_wall_label_pos(i, 17.0), _wall_text_angle(i) - 0.12 + 0.02 * Doodle.noise(v + i), Vector2.ONE)
			Doodle.text(self, tr("HUD_WALL_ABGESTIMMT"), Vector2.ZERO, 17, red, _hand, 4)
			draw_set_transform_matrix(Transform2D.IDENTITY)
	for k in 4:
		var pr: Rect2 = Arena.pillars()[k]
		draw_mesh(_mesh(K_WALL, WALL_PILLAR, st, Doodle.variant(k)), null, Transform2D(k * PI * 0.5, pr.get_center()))
	# spray-painted tags on intact segments (a little boil wobble in the angle)
	for g in GRAFFITI:
		var seg: int = g[0]
		if not (vs.wall & (1 << seg)):
			continue
		var v := Doodle.variant(seg + 5)
		var ang: float = g[3]
		draw_set_transform(_wall_label_pos(seg, 20.0), _wall_text_angle(seg) + ang + 0.012 * Doodle.noise(v * 3 + seg), Vector2.ONE)
		var col: Color = g[2]
		Doodle.text(self, g[1], Vector2.ZERO, 18, Doodle.desat(col, maxi(st, 1)), _hand, 4, Color(0.13, 0.1, 0.12, 0.9))
	draw_set_transform_matrix(Transform2D.IDENTITY)


# --- Hazards (immediate, few) ---------------------------------------------------

func _draw_hazards(vs: ViewState, st: int) -> void:
	_ziegel.clear()
	_kette.clear()
	_stamp_q.clear()
	if not _brei_seen.is_empty():
		for key in _brei_seen.keys():
			if anim_time - float(_brei_seen[key]) > 1.0:
				_brei_seen.erase(key)
	var fa := own_fx
	for i in vs.h_pos.size():
		var id: String = Content.HAZARD_ORDER[vs.h_type[i]] if vs.h_type[i] < Content.HAZARD_ORDER.size() else ""
		var pos := vs.h_pos[i]
		var r := vs.h_rad[i] if i < vs.h_rad.size() else 40.0
		var life := vs.h_life[i] if i < vs.h_life.size() else 1.0
		var v := Doodle.variant(i)
		var amt := Doodle.desat_amount(st) * 0.5
		match id:
			"kleber":
				var c := Doodle.desat_amt(Color(0.96, 0.93, 0.7, 0.75 * minf(1.0, life * 3.0) * fa), amt)
				draw_colored_polygon(Doodle.blob_pts(pos, r, v, i), c)
				draw_polyline(Doodle.blob_pts(pos, r, v, i, 0.12, true), Color(INK, 0.5 * fa), 2.0)
				draw_arc(pos + Vector2(-r * 0.3, -r * 0.3), r * 0.35, PI * 1.1, PI * 1.6, 6, Color(1, 1, 1, 0.8 * fa), 3.0)
				draw_multiline(Transform2D(0.0, pos) * Doodle.hatch_circle(r * 0.8, 14.0, 0.5), Color(0.75, 0.68, 0.3, 0.35 * fa), 1.5)
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
				draw_circle(pos, r, Color(c, 0.12 * fa))
				_dashed_circle(pos, r, Color(c, 0.8 * fa), 3.0, 22, anim_time * 0.3)
				var n := 6
				for k in n:
					var ang := TAU * k / n + 0.3
					var sp := pos + Vector2(cos(ang), sin(ang) * 0.8) * r * 0.62
					draw_mesh(_mesh(K_MISC, M_SITTER, st, Doodle.variant(k)), null,
						Transform2D(0.0, Vector2(-1.0 if k % 2 else 1.0, 1.0), 0.0, sp), Color(1, 1, 1, fa))
			"brei_marker":
				_draw_brei_marker(pos, r, life, st, v, amt)
				_brei_seen[Vector2i(pos.round())] = anim_time
			"ziegel":
				_ziegel.append(i)
			"kette":
				_kette.append(i)
			"kreide":
				# Straßenkreide: a pastel chalk scribble on the asphalt, fading out
				var chalk: Color = CHALK[int(absf(pos.x * 0.37 + pos.y * 0.61)) % CHALK.size()]
				var ca := minf(1.0, life * 2.5) * fa
				draw_circle(pos, r * 0.9, Doodle.desat_amt(Color(chalk, 0.18 * ca), amt))
				draw_multiline(Transform2D(v * 1.3, pos) * Doodle.hatch_circle(r * 0.85, 9.0, 0.6),
					Doodle.desat_amt(Color(chalk, 0.75 * ca), amt), 2.6)
				draw_polyline(Doodle.blob_pts(pos, r * 0.9, v, i, 0.18, true), Doodle.desat_amt(Color(chalk.darkened(0.15), 0.6 * ca), amt), 2.0)
			"paragraf":
				_draw_paragraf(pos, r, life, amt)
			"explosion":
				if not _brei_seen.is_empty() and _brei_seen.has(Vector2i(pos.round())):
					_draw_mash_splat(pos, r, life, v, i, amt)
					continue
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
				_draw_abschiebezone(vs, r, life, amt, v)
			"abstimmung":
				_draw_vote_segment(pos, life, st, v)
			"plenum":
				_draw_plenum(pos, r, v)
			"kahlschlag":
				_draw_kahlschlag(pos, r, vs.h_ang[i] if i < vs.h_ang.size() else 0.0, life, amt)
			"kahlschlag_hit":
				_draw_kahlschlag_hit(pos, r, vs.h_ang[i] if i < vs.h_ang.size() else 0.0, life, amt, v)
			"ansturm_bahn":
				_draw_lane(pos, r, vs.h_ang[i] if i < vs.h_ang.size() else 0.0, life, amt)
			"rotor":
				_draw_rotor(pos, r, vs.h_ang[i] if i < vs.h_ang.size() else 0.0, life, amt, st, v)
			"reichweite":
				_draw_reichweite(vs, pos, life, amt, v)
			"reichweite_hit":
				_draw_reichweite_hit(pos, life, amt, v)
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
				var c := Doodle.desat_amt(Color(0.9, 0.2, 0.6, 0.7 * minf(1.0, life * 2.0) * fa), amt)
				draw_colored_polygon(Doodle.blob_pts(pos, r * 0.75, v, i, 0.35), c)
				for k in 5:
					var ang := TAU * k / 5.0 + i
					draw_circle(pos + Vector2(cos(ang), sin(ang)) * r * (0.9 + 0.1 * (k % 2)), 4.0 + k % 3, c)
			_:
				_dashed_circle(pos, r, Color(INK, 0.5), 2.0, 12)
	if not _ziegel.is_empty():
		_draw_ziegel(vs, st)
	if not _kette.is_empty():
		_draw_kette(vs, st)
	_draw_brief_links(vs)


# --- Weapon hazards (GDD §11 "New weapons") -------------------------------------------

## Menschenkette (GDD §11 v0.3): every 5 consecutive `kette` links are one chain
## from its owner to the teammate or lamppost. A red ribbon on the ground marks
## the line that hurts; activists stand on the links and hold hands.
func _draw_kette(vs: ViewState, st: int) -> void:
	var chains: Array = []
	var cur := PackedInt32Array()
	for idx in _kette:
		if not cur.is_empty() and (idx != cur[cur.size() - 1] + 1 or cur.size() >= 5):
			chains.append(cur)
			cur = PackedInt32Array()
		cur.append(idx)
	if not cur.is_empty():
		chains.append(cur)
	var amt := Doodle.desat_amount(st) * 0.5
	for ch in chains:
		var pts := PackedVector2Array()
		for idx in ch:
			pts.append(vs.h_pos[idx])
		var life := vs.h_life[ch[0]] if ch[0] < vs.h_life.size() else 1.0
		var a := clampf(life * 8.0, 0.0, 1.0) * own_fx
		var ends := PackedVector2Array()
		if pts.size() >= 2:
			ends.append(pts[0] - (pts[1] - pts[0]) * 0.5)
			ends.append_array(pts)
			ends.append(pts[pts.size() - 1] + (pts[pts.size() - 1] - pts[pts.size() - 2]) * 0.5)
		else:
			ends = pts
		# the line that hurts: a red demo ribbon on the ground, slightly wavy
		var ground := PackedVector2Array()
		for k in ends.size():
			ground.append(ends[k] + Vector2(0, 16 + sin(anim_time * 5.0 + k) * 1.5))
		if ground.size() >= 2:
			draw_polyline(ground, Color(1, 1, 1, 0.55 * a), 9.0)
			draw_polyline(ground, Doodle.desat_amt(Color(0.82, 0.16, 0.16, 0.75 * a), amt), 5.0)
		# activists, back to front, alternately facing each other's hands
		var order := Array(range(pts.size()))
		order.sort_custom(func(x, y): return pts[x].y < pts[y].y)
		for k in order:
			var bob := absf(sin(anim_time * 6.0 + k * 1.3)) * 1.5
			draw_mesh(_mesh(K_MISC, M_KETTE + k % KETTE_LOOKS, st, Doodle.variant(k)), null,
				Transform2D(sin(anim_time * 3.0 + k) * 0.04, Vector2(-1.0 if k % 2 else 1.0, 1.0), 0.0, pts[k] + Vector2(0, -bob)),
				Color(1, 1, 1, a))
		# held hands: a line between neighbours at hand height
		var hands := PackedVector2Array()
		for k in ends.size():
			hands.append(ends[k] + Vector2(0, 2))
		if hands.size() >= 2:
			draw_polyline(hands, Color(Doodle.desat_amt(FACE.darkened(0.25), amt), a), 2.5)

## Kartoffelbrei target: friendly green ring that fills with mash until impact,
## a potato in the middle. Deliberately unlike the red enemy lob marker (X).
func _draw_brei_marker(pos: Vector2, r: float, life: float, st: int, v: int, amt: float) -> void:
	var k := clampf(1.0 - life, 0.0, 1.0)
	var g := Doodle.desat_amt(FRIEND, amt)
	var f := own_fx
	draw_colored_polygon(Doodle.blob_pts(pos, maxf(4.0, r * k), v, 3, 0.08), Doodle.desat_amt(Color(MASH, 0.45 * f), amt))
	_dashed_circle(pos, r, Color(g, 0.85 * f), 2.5, 16, -anim_time * 1.5)
	draw_arc(pos, r + 6.0, -PI / 2, -PI / 2 + TAU * k, 32, Color(g, 0.9 * f), 3.5)
	var hop := absf(sin(anim_time * 9.0)) * 3.0 * (1.0 - k)
	var sc := 1.0 + 0.25 * k
	draw_mesh(_mesh(K_MISC, M_POTATO, st, v), null, Transform2D(sin(anim_time * 4.0) * 0.12, Vector2(sc, sc), 0.0, pos + Vector2(0, -hop)),
		Color(1, 1, 1, f))


## Kartoffelbrei impact: a lumpy mash splat with flying blobs (replaces the
## orange explosion when it lands where a Kartoffelbrei marker just was).
func _draw_mash_splat(pos: Vector2, r: float, life: float, v: int, i: int, amt: float) -> void:
	var k := 1.0 - life
	var a := clampf(life * 2.2, 0.0, 1.0) * own_fx
	var mash := Doodle.desat_amt(MASH, amt)
	var pts := Doodle.blob_pts(pos, r * (0.45 + 0.4 * k), v, i + 11, 0.3)
	draw_colored_polygon(pts, Color(mash, 0.92 * a))
	draw_colored_polygon(Doodle.blob_pts(pos + Vector2(-4, -3), r * (0.22 + 0.15 * k), v, i + 5, 0.2), Color(1, 1, 0.92, 0.8 * a))
	draw_polyline(Doodle.blob_pts(pos, r * (0.45 + 0.4 * k), v, i + 11, 0.3, true), Color(INK, 0.85 * a), 2.5)
	# butter melting on top
	var bp := pos + Vector2(6, -5)
	draw_colored_polygon(PackedVector2Array([bp + Vector2(-5, -4), bp + Vector2(5, -5), bp + Vector2(6, 4), bp + Vector2(-5, 4)]),
		Doodle.desat_amt(Color(1.0, 0.85, 0.25, a), amt))
	# blobs flying outward
	for j in 9:
		var ang := TAU * j / 9.0 + i * 0.7
		var d := Vector2(cos(ang), sin(ang) * 0.8)
		var bpos := pos + d * r * (0.55 + 0.6 * k) + Vector2(0, -18.0 * sin(k * PI))
		var br := (4.0 + 2.0 * (j % 3)) * (1.0 - 0.4 * k)
		draw_circle(bpos, br, Color(mash, a))
		draw_arc(bpos, br, 0, TAU, 8, Color(INK, 0.7 * a), 1.5)
	# a bit of steam
	for j in 3:
		var sx := pos.x - 14.0 + j * 14.0
		var y0 := pos.y - 14.0 - k * 20.0
		draw_polyline(PackedVector2Array([Vector2(sx, y0), Vector2(sx + 4, y0 - 8), Vector2(sx - 2, y0 - 16), Vector2(sx + 3, y0 - 24)]),
			Color(0.55, 0.52, 0.48, 0.5 * a), 2.0)


## Normenkontrolle: a "§" stamp hovering over the marked enemy; the ring
## around it runs down until the law is declared void.
func _draw_paragraf(pos: Vector2, r: float, life: float, amt: float) -> void:
	var f := own_fx
	var red := Doodle.desat_amt(Color(STAMP_RED, f), amt * 0.5)
	_dashed_circle(pos, r, Color(red, 0.7 * f), 2.5, 12, anim_time * 2.5)
	var urgent := life < 0.3
	var c := pos + Vector2(0, -maxf(54.0, r * 1.9) + sin(anim_time * 3.0) * 2.5)
	var sc := 1.0 + (0.14 * absf(sin(anim_time * 18.0)) if urgent else 0.0)
	draw_set_transform(c, -0.12 + (sin(anim_time * 40.0) * 0.06 if urgent else 0.0), Vector2(sc, sc))
	draw_line(Vector2(0, 17), Vector2(0, maxf(54.0, r * 1.9) - r - 8.0), Color(red, 0.35 * f), 1.5)
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.98, 0.92, f))
	draw_polyline(Doodle.circle_pts(Vector2.ZERO, 16.0, Doodle.frame % Doodle.VARIANTS), red, 2.5)
	draw_arc(Vector2.ZERO, 12.5, 0, TAU, 20, Color(red, 0.45 * f), 1.0)
	draw_arc(Vector2.ZERO, 21.0, -PI / 2, -PI / 2 + TAU * clampf(life, 0.0, 1.0), 28, red, 4.0)
	Doodle.text(self, "§", Vector2(0, 8), 24, red, _type)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Brandmauer-Ziegel: five brick blocks per wall, back to front so a wall that
## runs down the screen overlaps correctly. Blocks rise out of the ground when
## the wall is built and crumble (fade) at the end.
func _draw_ziegel(vs: ViewState, st: int) -> void:
	var n := _ziegel.size()
	if n > 1:
		var order := Array(_ziegel)
		order.sort_custom(func(x, y): return vs.h_pos[x].y < vs.h_pos[y].y)
		_ziegel = PackedInt32Array(order)
	for idx in _ziegel:
		var pos := vs.h_pos[idx]
		# a wall running down the screen is seen end-on: brick tops, front only at the near end
		var vertical := false
		var best := 45.0 * 45.0
		for j in _ziegel:
			if j != idx:
				var d := vs.h_pos[j] - pos
				if d.length_squared() < best:
					best = d.length_squared()
					vertical = absf(d.y) > absf(d.x)
		var life := vs.h_life[idx] if idx < vs.h_life.size() else 1.0
		var rise := clampf((1.0 - life) / 0.06, 0.0, 1.0)
		var a := clampf(life / 0.08, 0.0, 1.0) * own_fx
		var sy := rise * (1.0 + 0.12 * sin(rise * PI))
		var v := Doodle.variant(idx)
		var base := 17.5 if vertical else 6.0
		draw_mesh(_mesh(K_MISC, M_ZIEGEL_V if vertical else M_ZIEGEL, st, v), null,
			Transform2D(0.0, Vector2(1.0, sy), 0.0, pos + Vector2(0, base * (1.0 - sy))), Color(1, 1, 1, a))


# --- Boss telegraphs (GDD §14 "Boss rules", D-108 to D-111) ---------------------------
# They belong to the boss: never faded with own_fx_opacity (D-086), never in OWN_HAZARDS.

## "Die Brandmauer hält" (D-111): the Abschiebezone only in front of open wall
## segments and their neighbours (the same Arena.band_mask as the sim), `width`
## deep; without a hole the old 70 px band along every wall. While it is announced
## (life < 1) a dashed red edge and a fill that grows from the wall; then hatching.
func _draw_abschiebezone(vs: ViewState, width: float, life: float, amt: float, v: int) -> void:
	var c := Doodle.desat_amt(DANGER, amt)
	var full_mask := (1 << WALL_SEGMENTS) - 1
	var mask := vs.wall & full_mask
	var rects: Array[Rect2] = []
	var segs: Array[int] = []   # the wall side of each rect
	if mask == full_mask:
		var h := float(Arena.WALL["abschiebe_band"])
		rects = [Rect2(INNER.position, Vector2(INNER.size.x, h)), Rect2(INNER.position.x, INNER.end.y - h, INNER.size.x, h),
			Rect2(INNER.position.x, INNER.position.y + h, h, INNER.size.y - 2.0 * h),
			Rect2(INNER.end.x - h, INNER.position.y + h, h, INNER.size.y - 2.0 * h)]
		segs = [Arena.TOP, Arena.BOTTOM, Arena.LEFT, Arena.RIGHT]
	else:
		var bm := Arena.band_mask(mask)
		var prev := -2
		for seg in WALL_SEGMENTS:
			if not (bm & (1 << seg)):
				continue
			if seg == prev + 1 and not rects.is_empty() and segs[segs.size() - 1] == Arena.side_of(seg):
				rects[rects.size() - 1] = rects[rects.size() - 1].merge(_band_rect(seg, width))   # one band, one hatching
			else:
				rects.append(_band_rect(seg, width))
				segs.append(Arena.side_of(seg))
			prev = seg
	var warn := life < 0.995
	var k := clampf(1.0 - life, 0.0, 1.0)
	var stripes := PackedVector2Array()
	var ph := fmod(anim_time * 30.0, 40.0)
	for j in rects.size():
		var b: Rect2 = rects[j]
		var side: int = segs[j]
		if warn:
			# announced: the fill grows from the wall into the arena until it is armed
			draw_rect(_band_part(b, side, k), Color(c, 0.12 + 0.18 * k))
			_dashed_rect(b, Color(c, 0.95), 3.0, anim_time)
		else:
			draw_rect(b, Color(c, 0.13 + 0.05 * sin(anim_time * 5.0)))
			stripes.append_array(_hatch_rect(b, ph))
			var e := _band_inner_edge(b, side)
			draw_polyline(Doodle.line_pts(e[0], e[1], v + j, 2.5), Color(c, 0.9), 3.0)
	if not stripes.is_empty():
		draw_multiline(stripes, Color(c, 0.35), 10.0)


## The band in front of a segment: `w` deep from its inner wall face.
static func _band_rect(seg: int, w: float) -> Rect2:
	var sr := Arena.seg_rect(seg)
	match Arena.side_of(seg):
		Arena.TOP:
			return Rect2(sr.position.x, INNER.position.y, sr.size.x, w)
		Arena.BOTTOM:
			return Rect2(sr.position.x, INNER.end.y - w, sr.size.x, w)
		Arena.RIGHT:
			return Rect2(INNER.end.x - w, sr.position.y, w, sr.size.y)
	return Rect2(INNER.position.x, sr.position.y, w, sr.size.y)


## The part of a band rect `k` (0..1) deep from its wall.
static func _band_part(b: Rect2, side: int, k: float) -> Rect2:
	match side:
		Arena.TOP:
			return Rect2(b.position, Vector2(b.size.x, b.size.y * k))
		Arena.BOTTOM:
			return Rect2(b.position.x, b.end.y - b.size.y * k, b.size.x, b.size.y * k)
		Arena.RIGHT:
			return Rect2(b.end.x - b.size.x * k, b.position.y, b.size.x * k, b.size.y)
	return Rect2(b.position, Vector2(b.size.x * k, b.size.y))


## The arena-side edge of a band rect (where it ends).
static func _band_inner_edge(b: Rect2, side: int) -> Array:
	match side:
		Arena.TOP:
			return [Vector2(b.position.x, b.end.y), b.end]
		Arena.BOTTOM:
			return [b.position, Vector2(b.end.x, b.position.y)]
		Arena.RIGHT:
			return [b.position, Vector2(b.position.x, b.end.y)]
	return [Vector2(b.end.x, b.position.y), b.end]


## Diagonal hatch stripes clipped to a rect (pairs for draw_multiline).
static func _hatch_rect(b: Rect2, ph: float, gap := 40.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var h := b.size.y
	var d := -h + ph - gap * ceilf(h / gap)
	while d < b.size.x:
		var t0 := maxf(0.0, -d / h)
		var t1 := minf(1.0, (b.size.x - d) / h)
		if t1 > t0:
			out.append(Vector2(b.position.x + d + t0 * h, b.end.y - t0 * h))
			out.append(Vector2(b.position.x + d + t1 * h, b.end.y - t1 * h))
		d += gap
	return out


func _dashed_rect(r: Rect2, col: Color, w: float, phase: float, dash := 10.0) -> void:
	var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	var segs := PackedVector2Array()
	for k in 4:
		_dash_line(segs, c[k], c[k + 1], dash, phase)
	draw_multiline(segs, col, w)


static func _dash_line(segs: PackedVector2Array, a: Vector2, b: Vector2, dash: float, phase: float) -> void:
	var l := a.distance_to(b)
	if l < 0.5:
		return
	var d := fmod(phase * 20.0, dash * 2.0) - dash * 2.0
	while d < l:
		var s0 := maxf(d, 0.0)
		var s1 := minf(d + dash, l)
		if s1 > s0:
			segs.append(a.lerp(b, s0 / l))
			segs.append(a.lerp(b, s1 / l))
		d += dash * 2.0


## "Abstimmung, egal mit wem" (D-109): the voted wall segment glows red with a
## dashed edge and fills up red along the wall until the vote passes (the
## progress), "Abstimmung" written on it; his ballot box stands beside him.
func _draw_vote_segment(pos: Vector2, life: float, st: int, v: int) -> void:
	var seg := Arena.wall_at(pos)
	if seg < 0:
		return
	var k := clampf(1.0 - life, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(anim_time * 8.0)
	var wr := Arena.seg_rect(seg)
	var sr := wr.grow(7.0)
	draw_rect(sr, Color(DANGER, 0.3 + 0.25 * pulse))
	var horizontal := Arena.side_of(seg) % 2 == 0
	var fill := Rect2(wr.position, Vector2(wr.size.x * k, wr.size.y)) if horizontal else Rect2(wr.position, Vector2(wr.size.x, wr.size.y * k))
	if Arena.side_of(seg) == Arena.BOTTOM:
		fill.position.x = wr.end.x - fill.size.x   # fills clockwise like the segment order
	elif Arena.side_of(seg) == Arena.LEFT:
		fill.position.y = wr.end.y - fill.size.y
	draw_rect(fill, Color(DANGER, 0.85))
	draw_rect(wr, INK, false, 2.0)
	_dashed_rect(sr.grow(3.0), Color(DANGER, 0.95), 3.0, anim_time)
	draw_set_transform(_wall_label_pos(seg, 17.0), _wall_text_angle(seg), Vector2.ONE)
	Doodle.text(self, tr("FX_ABSTIMMUNG"), Vector2.ZERO, 16, WHITE, _hand, 4, DANGER.darkened(0.35))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var urn := Arena.seg_inner(seg, 70.0) + Vector2(-Arena.inward(seg).y, Arena.inward(seg).x) * 52.0
	draw_mesh(_mesh(K_MISC, M_URNE, st, v), null, Transform2D(0.0, Vector2(1.3, 1.3), 0.0, urn))


## A Plenum circle (D-109): "stand here" in the telegraph standard: a solid
## blue-turquoise ring with a hand; it fills and shows a tick while someone stands in it.
func _draw_plenum(pos: Vector2, r: float, v: int) -> void:
	var occupied := false
	for q in _ppos:
		if q.distance_to(pos) <= r:
			occupied = true
			break
	var pulse := 0.5 + 0.5 * sin(anim_time * 4.0)
	draw_circle(pos, r, Color(TEAL, 0.32 if occupied else 0.1 + 0.06 * pulse))
	draw_polyline(Doodle.circle_pts(pos, r, v), Color(WHITE, 0.8), 8.0)
	draw_polyline(Doodle.circle_pts(pos, r, v), TEAL, 4.5)
	if occupied:
		draw_polyline(PackedVector2Array([pos + Vector2(-14, 0), pos + Vector2(-4, 11), pos + Vector2(16, -12)]), Color(WHITE, 0.9), 9.0)
		draw_polyline(PackedVector2Array([pos + Vector2(-14, 0), pos + Vector2(-4, 11), pos + Vector2(16, -12)]), TEAL.darkened(0.3), 5.0)
	else:
		_hand_icon(pos + Vector2(0, -sin(anim_time * 5.0) * 3.0), 1.0, TEAL.darkened(0.25))
	Doodle.text(self, tr("FX_PLENUM"), pos + Vector2(0, r + 20), 17, TEAL.darkened(0.35), _hand, 4)


## An open hand ("stand here"), about 34 px tall at scale 1.
func _hand_icon(c: Vector2, s: float, col: Color) -> void:
	var palm := Rect2(c + Vector2(-9, -2) * s, Vector2(18, 16) * s)
	for k in 4:
		var x := c.x + (-7.5 + k * 5.0) * s
		var h: float = [11.0, 14.0, 13.0, 10.0][k] * s
		draw_line(Vector2(x, palm.position.y + 2.0 * s), Vector2(x, palm.position.y - h), INK, 6.5 * s)
		draw_line(Vector2(x, palm.position.y + 2.0 * s), Vector2(x, palm.position.y - h), WHITE, 4.0 * s)
	draw_line(c + Vector2(-8, 8) * s, c + Vector2(-16, -1) * s, INK, 6.5 * s)
	draw_line(c + Vector2(-8, 8) * s, c + Vector2(-16, -1) * s, WHITE, 4.0 * s)
	draw_rect(palm.grow(1.2 * s), INK)
	draw_rect(palm, WHITE)
	draw_circle(palm.get_center() + Vector2(0, 1) * s, 3.0 * s, Color(col, 0.6))


static func _cone_pts(o: Vector2, r: float, ang: float, half: float, n := 18) -> PackedVector2Array:
	var pts := PackedVector2Array([o])
	for k in n + 1:
		var a := ang - half + 2.0 * half * k / n
		pts.append(o + Vector2(cos(a), sin(a)) * r)
	return pts


## Kahlschlag warning (D-110): a red 90° cone with a dashed edge, the fill grows
## from him outward until the stamp comes down; "GESTRICHEN" on it.
func _draw_kahlschlag(pos: Vector2, r: float, ang: float, life: float, amt: float) -> void:
	var half := deg_to_rad(float(Content.BOSS["kahl_arc"])) * 0.5
	var c := Doodle.desat_amt(DANGER, amt)
	var k := clampf(1.0 - life, 0.0, 1.0)
	draw_colored_polygon(_cone_pts(pos, r, ang, half), Color(c, 0.1))
	draw_colored_polygon(_cone_pts(pos, maxf(6.0, r * k), ang, half), Color(c, 0.3))
	var segs := PackedVector2Array()
	var a0 := pos + Vector2(cos(ang - half), sin(ang - half)) * r
	var a1 := pos + Vector2(cos(ang + half), sin(ang + half)) * r
	_dash_line(segs, pos, a0, 12.0, anim_time)
	_dash_line(segs, pos, a1, 12.0, anim_time)
	var arc := _cone_pts(pos, r, ang, half, 18)
	for j in range(1, arc.size() - 1):
		_dash_line(segs, arc[j], arc[j + 1], 12.0, anim_time)
	draw_multiline(segs, Color(c, 0.95), 3.5)
	_queue_stamp(pos, ang, r, 1.0 + 0.1 * k, Color(STAMP_RED, 0.55 + 0.4 * k))


## Kahlschlag impact: the cone flashes and fades, the stamp is down.
func _draw_kahlschlag_hit(pos: Vector2, r: float, ang: float, life: float, amt: float, v: int) -> void:
	var half := deg_to_rad(float(Content.BOSS["kahl_arc"])) * 0.5
	var a := clampf(life * 2.0, 0.0, 1.0)
	var c := Doodle.desat_amt(DANGER, amt)
	var pts := _cone_pts(pos, r, ang, half)
	draw_colored_polygon(pts, Color(c, 0.45 * a))
	pts.append(pos)
	draw_polyline(pts, Color(INK, 0.8 * a), 3.0)
	for j in 7:
		var d := ang + (Doodle.noise(v * 7 + j) * 0.9) * half
		var p0 := pos + Vector2(cos(d), sin(d)) * r * (0.3 + 0.1 * j)
		draw_line(p0, p0 + Vector2(cos(d), sin(d)) * 22.0, Color(INK, 0.6 * a), 2.5)
	_queue_stamp(pos, ang, r, 1.15, Color(STAMP_RED, a))


## The corners of a lane from `o` along `ang`, `length` long, `w` wide.
static func _lane_pts(o: Vector2, ang: float, length: float, w: float) -> PackedVector2Array:
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal() * (w * 0.5)
	return PackedVector2Array([o + n, o + d * length + n, o + d * length - n, o - n])


func _dashed_poly(pts: PackedVector2Array, col: Color, w: float, dash := 12.0) -> void:
	var segs := PackedVector2Array()
	for k in pts.size():
		_dash_line(segs, pts[k], pts[(k + 1) % pts.size()], dash, anim_time)
	draw_multiline(segs, col, w)


## Ansturm-Kette lane (D-143): a red dashed lane in the charge direction, the fill
## runs from her to the tip until she goes; chevrons show the direction.
func _draw_lane(pos: Vector2, r: float, ang: float, life: float, amt: float) -> void:
	var c := Doodle.desat_amt(DANGER, amt)
	var w := float(Content.BOSS["lane_w"])
	var k := clampf(1.0 - life, 0.0, 1.0)
	draw_colored_polygon(_lane_pts(pos, ang, r, w), Color(c, 0.1))
	draw_colored_polygon(_lane_pts(pos, ang, maxf(4.0, r * k), w), Color(c, 0.32))
	_dashed_poly(_lane_pts(pos, ang, r, w), Color(c, 0.95), 3.5)
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal() * (w * 0.28)
	for j in 4:
		var tip := pos + d * (r * (0.3 + 0.18 * j) + fmod(anim_time * 60.0, 30.0))
		draw_polyline(PackedVector2Array([tip - d * 16.0 + n, tip, tip - d * 16.0 - n]), Color(c, 0.85), 4.0)


## A falling turbine (D-143): life 1 -> 0.5 it tips over (red dashed line that
## fills), 0.5 -> 0 the rotor lies there: mast and blades on red hatching.
func _draw_rotor(pos: Vector2, r: float, ang: float, life: float, amt: float, st: int, v: int) -> void:
	var c := Doodle.desat_amt(DANGER, amt)
	var w := float(Content.BOSS["rotor_w"])
	var d := Vector2(cos(ang), sin(ang))
	var pts := _lane_pts(pos, ang, r, w)
	if life > 0.5:
		var k := clampf((1.0 - life) * 2.0, 0.0, 1.0)
		draw_colored_polygon(pts, Color(c, 0.08 + 0.2 * k))
		_dashed_poly(pts, Color(c, 0.95), 3.0)
		# the mast tipping toward the lane
		var tip := pos + d.rotated(-(1.0 - k) * PI * 0.5) * r
		draw_line(pos, tip, INK, 7.0)
		draw_line(pos, tip, Color("e8e8e2"), 4.0)
		return
	var a := clampf(life * 4.0, 0.0, 1.0)
	draw_colored_polygon(pts, Color(c, 0.22 * a))
	var hs := PackedVector2Array()
	var n := d.orthogonal() * (w * 0.5)
	var step := 22.0
	var t := fmod(anim_time * 30.0, step)
	while t < r:
		var p0 := pos + d * t
		hs.append(p0 - n)
		hs.append(p0 + d * minf(w, r - t) + n)
		t += step
	draw_multiline(hs, Color(c, 0.4 * a), 5.0)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(c, 0.9 * a), 2.5)
	var tip := pos + d * (r - 26.0)
	draw_line(pos, tip, Color(INK, a), 8.0)
	draw_line(pos, tip, Color("e8e8e2", a), 5.0)
	draw_mesh(_mesh(K_MISC, M_BLADES, st, v), null, Transform2D(ang * 0.5 + 0.4, Vector2(0.9, 0.9), 0.0, tip), Color(1, 1, 1, a))


## Strips in front of the wall that are safe from the Reichweite (Arena.reich_mask),
## merged per side like the Abschiebezone.
func _reich_rects(vs: ViewState, depth: float) -> Array[Rect2]:
	var mask := Arena.reich_mask(vs.wall & ((1 << WALL_SEGMENTS) - 1))
	var rects: Array[Rect2] = []
	var prev := -2
	var prev_side := -1
	for seg in WALL_SEGMENTS:
		if not (mask & (1 << seg)):
			continue
		if seg == prev + 1 and Arena.side_of(seg) == prev_side and not rects.is_empty():
			rects[rects.size() - 1] = rects[rects.size() - 1].merge(_band_rect(seg, depth))
		else:
			rects.append(_band_rect(seg, depth))
		prev = seg
		prev_side = Arena.side_of(seg)
	return rects


## Reichweite warning (D-141): her broadcast floods the arena red from her outward,
## only the strips in front of the intact Brandmauer stay blue-turquoise ("stand
## here", with a hand and "Brandmauer").
func _draw_reichweite(vs: ViewState, pos: Vector2, life: float, amt: float, v: int) -> void:
	var c := Doodle.desat_amt(DANGER, amt)
	var k := clampf(1.0 - life, 0.0, 1.0)
	draw_rect(INNER, Color(c, 0.05 + 0.13 * k))
	for j in 4:
		var rr := fmod(k * 1.6 + j * 0.25, 1.0) * 1900.0
		_dashed_circle(pos, rr, Color(c, 0.55 * (1.0 - rr / 1900.0)), 4.0, 48, anim_time * 0.3)
	draw_arc(pos, k * 1900.0, 0.0, TAU, 96, Color(c, 0.5), 6.0)
	var depth := float(Content.BOSS["reich_safe"])
	var pulse := 0.5 + 0.5 * sin(anim_time * 5.0)
	for b in _reich_rects(vs, depth):
		draw_rect(b, Color(TEAL, 0.3 + 0.12 * pulse))
		draw_rect(b, TEAL, false, 4.0)
		if b.size.x > 90.0 and b.size.y > 90.0 or b.size.x > 260.0 or b.size.y > 260.0:
			var cc := b.get_center()
			_hand_icon(cc + Vector2(0, -10 - sin(anim_time * 5.0) * 3.0), 1.3, TEAL.darkened(0.25))
			Doodle.text(self, tr("FX_REICHWEITE_SAFE"), cc + Vector2(0, 32), 22, TEAL.darkened(0.45), _hand, 4)


## Reichweite impact: a red wave rolls over the arena and fades.
func _draw_reichweite_hit(pos: Vector2, life: float, amt: float, v: int) -> void:
	var c := Doodle.desat_amt(DANGER, amt)
	var a := clampf(life / 0.6, 0.0, 1.0)
	draw_rect(INNER, Color(c, 0.22 * a))
	var rr := (1.0 - a) * 1900.0
	draw_polyline(Doodle.circle_pts(pos, maxf(10.0, rr), v), Color(c, 0.8 * a), 10.0)


## Briefkastenfirmen (D-142): a pulsing gold dashed line from every letterbox to
## her while it feeds her shield, coins running along it.
func _draw_brief_links(vs: ViewState) -> void:
	var t_box := Content.ENEMY_ORDER.find("briefkasten")
	var t_boss := Content.ENEMY_ORDER.find("eidgenossin")
	var boss := Vector2.INF
	for i in vs.e_type.size():
		if vs.e_type[i] == t_boss:
			boss = vs.e_pos[i]
	if boss == Vector2.INF:
		return
	var segs := PackedVector2Array()
	for i in vs.e_type.size():
		if vs.e_type[i] != t_box:
			continue
		var a := vs.e_pos[i] + Vector2(0, -14)
		_dash_line(segs, a, boss, 14.0, -anim_time)
		var l := a.distance_to(boss)
		for j in 3:
			var f := fmod(anim_time * 0.45 + j / 3.0, 1.0)
			var q := a.lerp(boss, f)
			draw_circle(q, 6.0, Color(INK, 0.8))
			draw_circle(q, 4.5, GOLD)
		if l > 0.0:
			Doodle.text(self, tr("FX_BRIEFKASTEN"), vs.e_pos[i] + Vector2(0, 52), 15, GOLD.darkened(0.5), _hand, 4)
	if not segs.is_empty():
		draw_multiline(segs, Color(GOLD, 0.5 + 0.3 * sin(anim_time * 6.0)), 3.0)


## Queues a "GESTRICHEN" stamp inside a cone (origin, direction, length). Two
## cones (35 %) or a warning next to an impact never stack their stamps: a stamp
## too close to an earlier one moves further out along its own cone.
func _queue_stamp(origin: Vector2, ang: float, r: float, s: float, col: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var side := Vector2(-dir.y, dir.x)
	var best := origin + dir * r * 0.55
	var best_d := -1.0
	for cand in [[0.55, 0.0], [0.85, 0.0], [0.55, 60.0], [0.55, -60.0], [0.85, 60.0], [0.85, -60.0], [0.3, 0.0]]:
		var c: Vector2 = origin + dir * r * float(cand[0]) + side * float(cand[1])
		var free := true
		var dmin := INF
		for q in _stamp_q:
			dmin = minf(dmin, (q["pos"] as Vector2).distance_to(c))
			if stamps_clash(q["pos"], q["ang"], c, ang):
				free = false
		if free:
			best = c
			break
		if dmin > best_d:
			best_d = dmin
			best = c
	_stamp_q.append({"pos": best, "ang": ang, "s": s, "col": col})


## Would two GESTRICHEN stamps (about 200 × 40 px, long side along their cone)
## overlap? Same orientation: compare in the stamp's frame; else by distance.
static func stamps_clash(p1: Vector2, a1: float, p2: Vector2, a2: float) -> bool:
	var d := absf(angle_difference(a1, a2))
	if d < 0.3 or absf(d - PI) < 0.3:
		var local := (p2 - p1).rotated(-a1)
		return absf(local.x) < 200.0 and absf(local.y) < 44.0
	return p1.distance_to(p2) < 150.0


## The queued stamps, above players and enemies so nothing hides the word. Each
## box is sized to its text and turned along its cone but always readable.
func _draw_stamps() -> void:
	var text := tr("FX_GESTRICHEN")
	var tw := _type.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	for q in _stamp_q:
		var rot: float = q["ang"]
		if cos(rot) < 0.0:
			rot += PI
		var col: Color = q["col"]
		draw_set_transform(q["pos"], rot - 0.12, Vector2(q["s"], q["s"]))
		var box := Rect2(-tw * 0.5 - 14.0, -20, tw + 28.0, 34)
		draw_rect(box, Color(1, 1, 1, col.a * 0.45))
		draw_polyline(Doodle.rect_pts(box, 2, 2.0), col, 3.5)
		Doodle.text(self, text, Vector2(0, 7), 22, col, _type)
	draw_set_transform_matrix(Transform2D.IDENTITY)


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
	var t4 := anim_time * 4.0
	var fr := Doodle.frame
	var tab := _table(K_PICK, Content.PICKUP_ORDER.size(), st)
	for i in vs.k_pos.size():
		var idx: int = vs.k_type[i] * Doodle.VARIANTS + posmod(fr + i, Doodle.VARIANTS)
		var m: ArrayMesh = tab[idx]
		if m == null:
			m = _mesh(K_PICK, vs.k_type[i], st, idx % Doodle.VARIANTS)
			tab[idx] = m
		# bob and breathe (bigger at the top of the bob) so pickups catch the eye
		var bob := sin(t4 + i * 1.3) * 2.0
		var sc := 1.0 - 0.035 * bob
		draw_mesh(m, null, Transform2D(0.0, Vector2(sc, sc), 0.0, vs.k_pos[i] + Vector2(0, bob)))


func _draw_summons(vs: ViewState, st: int) -> void:
	var t_turb := Content.SUMMON_ORDER.find("turbine")
	var t_gen := Content.SUMMON_ORDER.find("genosse")
	var t_info := Content.SUMMON_ORDER.find("infostand")
	var face := PackedFloat32Array()
	face.resize(vs.s_pos.size())
	face.fill(1.0)
	var fa := own_fx
	var mod := Color(1, 1, 1, fa)
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
			draw_polyline(Doodle.ellipse_pts(vs.s_pos[i] + Vector2(0, 19), 13, 4, v), Color(0.75, 0.12, 0.12, 0.5 * fa), 2.0)
		elif ty == _t_overall:
			# Weißer Overall: sprinting at the nearest enemy, little dust dashes behind
			var ph := anim_time * 16.0 + i * 1.9
			rot = sin(ph) * 0.09
			pos.y -= absf(sin(ph)) * 4.0
			# face where it runs (last frame's position at the same index)
			sx = _s_face[i] if i < _s_face.size() else 1.0
			if i < _s_prev.size():
				var dx := vs.s_pos[i].x - _s_prev[i].x
				if absf(dx) > 0.2 and absf(dx) < 40.0:
					sx = signf(dx)
			var dc := Color(0.35, 0.33, 0.3, 0.4 * fa)
			for k in 3:
				var y := vs.s_pos[i].y + 4.0 + k * 6.0
				var x0 := vs.s_pos[i].x - sx * (14.0 + fmod(anim_time * 60.0 + k * 7.0, 10.0))
				draw_line(Vector2(x0, y), Vector2(x0 - sx * (8.0 + k * 3.0), y), dc, 2.0)
		elif _t_mobile.has(ty):
			# Demo-Sani walking behind you, Lauti driving its circle: face where they move
			var ph := anim_time * 9.0 + i * 1.3
			sx = _s_face[i] if i < _s_face.size() else 1.0
			if i < _s_prev.size():
				var dx := vs.s_pos[i].x - _s_prev[i].x
				if absf(dx) > 0.15 and absf(dx) < 40.0:
					sx = signf(dx)
			if ty == _t_lauti:
				rot = sin(anim_time * 14.0 + i) * 0.025
				_draw_ska_notes(vs.s_pos[i], fa, i)
			else:
				rot = sin(ph) * 0.05
				pos.y -= absf(sin(ph)) * 2.0
		elif ty == _t_papp:
			rot = sin(anim_time * 2.6 + i) * 0.05   # cardboard wobbling on its stand
		elif ty == _t_laterne:
			draw_circle(pos + Vector2(14, -50), 16.0, Color(1.0, 0.92, 0.55, 0.25 * fa))
		var sc := 1.0
		if ty == t_info:
			sc = INFOSTAND_SCALE
			pos.y += INFOSTAND_FOOT * (1.0 - sc)
		draw_mesh(_mesh(K_SUMMON, ty, st, v), null, Transform2D(rot, Vector2(sx * sc, sc), 0.0, pos), mod)
		if ty == _t_overall or _t_mobile.has(ty):
			face[i] = sx
		if ty == t_turb:
			draw_mesh(_mesh(K_MISC, M_BLADES, st, v), null, Transform2D(anim_time * 2.2 + i, pos + Vector2(0, -78)), mod)
		if ty == _t_papp and i < vs.s_hp.size() and vs.s_hp[i] < 0.999:
			# Pappkamerad HP bar (s_hp, D-093)
			var bw := 38.0
			var bp := vs.s_pos[i] + Vector2(-bw * 0.5, -86)
			draw_rect(Rect2(bp, Vector2(bw, 5)), Color(1, 1, 1, 0.85 * fa))
			draw_rect(Rect2(bp, Vector2(bw * vs.s_hp[i], 5)), Color(0.78, 0.6, 0.35, fa))
			draw_rect(Rect2(bp, Vector2(bw, 5)), Color(INK, fa), false, 1.5)
	_s_prev = vs.s_pos.duplicate()
	_s_face = face


## Lauti: little ska notes bobbing up from the loudspeakers.
func _draw_ska_notes(pos: Vector2, fa: float, i: int) -> void:
	for k in 3:
		var u := fmod(anim_time * 0.9 + k / 3.0 + i * 0.37, 1.0)
		var np := pos + Vector2(-14.0 + k * 14.0 + sin(u * 9.0 + k) * 5.0, -44.0 - u * 34.0)
		var c := Color(INK, (1.0 - u) * 0.85 * fa)
		draw_circle(np, 3.2, c)
		draw_line(np + Vector2(2.8, 0), np + Vector2(2.8, -11), c, 1.6)
		if k % 2 == 0:
			draw_line(np + Vector2(2.8, -11), np + Vector2(8, -8), c, 1.6)


func _draw_projectiles(vs: ViewState, st: int) -> void:
	var n := vs.p_pos.size()
	var t9 := anim_time * 9.0
	var fr := Doodle.frame
	var tab := _table(K_PROJ, Content.PROJ_ORDER.size(), st)
	var na := vs.p_ang.size()
	var brei_marks := PackedInt32Array()   # filled on the first Kartoffelbrei blob
	var own_mod := Color(1, 1, 1, own_fx)
	for i in n:
		var ty: int = vs.p_type[i]
		var ang := vs.p_ang[i] if i < na else 0.0
		var pos := vs.p_pos[i]
		var mod := own_mod if ty < _own_proj.size() and _own_proj[ty] == 1 else Color.WHITE
		if _t_spin.has(ty):
			ang += t9 + i
		elif ty == _t_brei:
			# Kartoffelbrei flies on a lob arc: shadow on the ground, blob above it
			if brei_marks.is_empty():
				brei_marks = _brei_marks(vs)
			var h := _brei_height(vs, brei_marks, pos, ang)
			var ss := 1.0 - h * 0.004
			draw_mesh(_mesh(K_MISC, M_DROP, st, 0), null, Transform2D(0.0, Vector2(ss, ss), 0.0, pos + Vector2(0, 8)), mod)
			pos.y -= h
			ang = sin(anim_time * 7.0 + i) * 0.25
		var idx := ty * Doodle.VARIANTS + posmod(fr + i, Doodle.VARIANTS)
		var m: ArrayMesh = tab[idx]
		if m == null:
			m = _mesh(K_PROJ, ty, st, idx % Doodle.VARIANTS)
			tab[idx] = m
		draw_mesh(m, null, Transform2D(ang, pos), mod)


## Hazard indices of all Kartoffelbrei target markers ([-1] when there are none,
## so the caller doesn't search again this frame).
func _brei_marks(vs: ViewState) -> PackedInt32Array:
	var t_mark := Content.HAZARD_ORDER.find("brei_marker")
	var out := PackedInt32Array()
	for j in vs.h_type.size():
		if vs.h_type[j] == t_mark:
			out.append(j)
	if out.is_empty():
		out.append(-1)
	return out


## Height of a Kartoffelbrei blob above the ground: its target marker (the
## brei_marker ahead of it along the flight direction) tells the flight progress.
func _brei_height(vs: ViewState, marks: PackedInt32Array, pos: Vector2, ang: float) -> float:
	var dir := Vector2(cos(ang), sin(ang))
	var best := -1
	var best_dot := 0.8
	for j in marks:
		if j < 0:
			continue
		var d := vs.h_pos[j] - pos
		var l := d.length()
		var dot := 1.0 if l < 4.0 else d.dot(dir) / l
		if dot > best_dot:
			best_dot = dot
			best = j
	if best < 0:
		return 0.0
	var k := 1.0 - (vs.h_life[best] if best < vs.h_life.size() else 1.0)
	return sin(PI * clampf(k, 0.0, 1.0)) * 70.0


# --- Enemies ----------------------------------------------------------------------

func _draw_enemies(vs: ViewState, st: int) -> void:
	var n := vs.e_pos.size()
	var t := anim_time
	var has_ids := vs.e_id.size() == n
	var new_prev := {}
	var np := _ppos.size()
	var excl := Color(0.85, 0.1, 0.1)
	var fr := Doodle.frame
	var nt := Content.ENEMY_ORDER.size()
	var tab := _table(K_ENEMY, nt, st)
	var tab_hit := _table(K_ENEMY, nt, st, true)
	var nfl := vs.e_flags.size()
	var nfl2 := vs.e_flags2.size()
	for i in n:
		var ty: int = vs.e_type[i]
		var pos := vs.e_pos[i]
		var fl: int = vs.e_flags[i] if i < nfl else 0
		var id: int = vs.e_id[i] if has_ids else i
		var v := posmod(fr + id, Doodle.VARIANTS)
		var hit := (fl & ViewState.EF_HIT) != 0
		var idx := ty * Doodle.VARIANTS + v
		var mesh: ArrayMesh = tab_hit[idx] if hit else tab[idx]
		if mesh == null:
			mesh = _mesh(K_ENEMY, ty, st, v, hit)
			if hit:
				tab_hit[idx] = mesh
			else:
				tab[idx] = mesh
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
		var fl2: int = vs.e_flags2[i] if i < nfl2 else 0
		if fl2 & ViewState.EF2_REVERSED:
			sx = -sx   # "Rolle rückwärts": turned away, walking backwards
		if fl & ViewState.EF_PARKED:
			rot = 0.0
			bob = 0.0
		if fl & ViewState.EF_WINDUP:
			pos.x += sin(t * 70.0 + ph) * 2.0
		var at := pos + Vector2(0, bob)
		if fl & ViewState.EF_BUFFED:
			var rr := float(Content.ENEMIES[Content.ENEMY_ORDER[ty]]["radius"]) + 8.0
			draw_polyline(Doodle.circle_pts(pos + Vector2(0, -rr * 0.3), rr, v), Color(0.9, 0.15, 0.1, 0.55), 4.0)
		var top := _etop[ty] if ty < _etop.size() else -30.0
		var scl := Vector2(sx, 1.0)
		if hit:
			# hit flash: comic "POW" burst behind a white, squashed figure
			var bs := clampf(-top / 30.0, 0.8, 2.6)
			draw_mesh(_mesh(K_MISC, M_HIT, st, v), null, Transform2D(ph, Vector2(bs, bs), 0.0, at + Vector2(0, top * 0.45)))
			scl = Vector2(sx * 1.1, 0.93)
		if fl2 & ViewState.EF2_PRESSE:
			# Pressekonferenz (D-102): invulnerable, a pulsing golden outline
			var wm: ArrayMesh = tab_hit[idx]
			if wm == null:
				wm = _mesh(K_ENEMY, ty, st, v, true)
				tab_hit[idx] = wm
			var g := 1.24 + 0.04 * sin(t * 7.0)
			var er := float(Content.ENEMIES[Content.ENEMY_ORDER[ty]]["radius"])
			draw_set_transform(at + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
			draw_circle(Vector2.ZERO, er * 1.6, Color(GOLD, 0.35))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			draw_mesh(wm, null, Transform2D(rot, scl * Vector2(g, g * 0.97), 0.0, at + Vector2(0, 3)), Color(GOLD, 1.0))
		if fl & ViewState.EF_ELITE:
			draw_mesh(mesh, null, Transform2D(rot, scl * Vector2(1.09, 1.07), 0.0, at + Vector2(0, 1)), Color(0, 0, 0, 1))
		draw_mesh(mesh, null, Transform2D(rot, scl, 0.0, at), mod)
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
		if fl2 != 0:
			_draw_status_icons(at, top, sx, fl2, id)
		if fl2 & (ViewState.EF2_PRESSE | ViewState.EF2_STANDFEST):
			_draw_boss_marks(at, top, fl2, id)
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

## Symbols of the v0.3 status effects (GDD §11, D-092), one per effect so they
## read at a glance: a waiting ticket (In Bearbeitung), "↺" (Rolle rückwärts),
## a stack of file sheets (Aktenkundig) and a sticker on the body (Soli-Sticker).
## They belong to the enemy, so they never fade with own_fx_opacity.
func _draw_status_icons(at: Vector2, top: float, sx: float, fl2: int, id: int) -> void:
	var head := at + Vector2(0, top - 14)
	var silenced := (fl2 & ViewState.EF2_SILENCED) != 0
	var reversed := (fl2 & ViewState.EF2_REVERSED) != 0
	if fl2 & ViewState.EF2_STICKER:
		var sp := at + Vector2(-4.0 * sx, top * 0.45 + 2.0)
		draw_circle(sp, 5.0, Color("f06aa7"))
		draw_arc(sp, 5.0, 0, TAU, 12, INK, 1.4)
		_heart_icon(sp, 2.4, WHITE)
	if silenced:
		# "Nr. 552": a numbered waiting ticket, swaying a little
		var tp := head + Vector2(-16.0 if reversed else 0.0, 0)
		draw_set_transform(tp, sin(anim_time * 3.0 + id) * 0.08, Vector2.ONE)
		var r := Rect2(-27, -10, 54, 19)
		draw_rect(r, Color("fffdf2"))
		draw_rect(Rect2(-27, -10, 54, 4), Color("d8262e"))
		draw_polyline(Doodle.rect_pts(r, id % Doodle.VARIANTS, 1.0), INK, 1.6)
		Doodle.text(self, tr("FX_WAITING_NO") % (552 + id % 48), Vector2(0, 6), 11, INK, _type)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	if reversed:
		var c := head + Vector2(16.0 if silenced else 0.0, -2)
		var blue := Color("2e6db4")
		draw_arc(c, 9.0, -PI * 0.15, PI * 1.45, 16, Color(1, 1, 1, 0.9), 6.0)
		draw_arc(c, 9.0, -PI * 0.15, PI * 1.45, 16, blue, 3.0)
		var tip := c + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * 9.0
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-6, -2), tip + Vector2(4, -5), tip + Vector2(2, 5)]), blue)
	var files := ViewState.file_stacks(fl2)
	if files > 0:
		# Aktenkundig: 1-5 sheets stacked beside the head, the top one with a red stamp
		var base := at + Vector2(-20.0 * sx, top + 6)
		for k in files:
			var o := base + Vector2(sin(k * 1.7) * 1.5, -k * 3.5)
			var sheet := Rect2(o + Vector2(-8, -5), Vector2(16, 10))
			draw_rect(sheet, Color("fbf8ee"))
			draw_rect(sheet, INK, false, 1.2)
		var top_o := base + Vector2(0, -(files - 1) * 3.5)
		draw_line(top_o + Vector2(-5, -1), top_o + Vector2(5, -1), Color(0.4, 0.4, 0.45), 1.0)
		draw_circle(top_o + Vector2(3, 1.5), 2.2, Color(STAMP_RED, 0.85))


## Boss rules marks (D-102, D-107): microphones during the Pressekonferenz, the
## press-spokesperson shield while "Standfest" makes the unit immune to stuns.
func _draw_boss_marks(at: Vector2, top: float, fl2: int, id: int) -> void:
	if fl2 & ViewState.EF2_PRESSE:
		for k in 2:
			var sgn := -1.0 if k == 0 else 1.0
			var base := at + Vector2(sgn * (-top * 0.55 + 18.0), top * 0.35)
			var head := base + Vector2(-sgn * 14.0, -16.0 + sin(anim_time * 5.0 + k) * 2.0)
			draw_line(base + Vector2(sgn * 10.0, 10.0), head, INK, 3.0)
			draw_circle(head, 6.5, INK)
			draw_circle(head, 4.5, Color(0.55, 0.55, 0.6))
			draw_rect(Rect2(head + Vector2(-5, 5), Vector2(10, 5)), Color("d8262e"))
		_sparkle(at + Vector2(-top * 0.4, top - 4), 6.0, GOLD)
		_sparkle(at + Vector2(top * 0.45, top + 10), 5.0, GOLD)
	elif fl2 & ViewState.EF2_STANDFEST:
		var c := at + Vector2(0, top - 34 + sin(anim_time * 3.0 + id) * 1.5)
		var pts := PackedVector2Array([c + Vector2(-13, -14), c + Vector2(13, -14), c + Vector2(13, 1),
			c + Vector2(7, 10), c + Vector2(0, 15), c + Vector2(-7, 10), c + Vector2(-13, 1)])
		draw_colored_polygon(pts, NAVY)
		pts.append(pts[0])
		draw_polyline(pts, INK, 2.0)
		draw_circle(c + Vector2(0, -5), 4.0, WHITE)
		draw_line(c + Vector2(0, -2), c + Vector2(0, 7), WHITE, 2.0)
		draw_arc(c + Vector2(0, -3), 6.5, 0.3, PI - 0.3, 8, WHITE, 1.5)
		Doodle.text(self, tr("FX_STANDFEST"), c + Vector2(0, -20), 14, NAVY, _hand, 4)


## Over every player while the Geschichtslehrer counts down his Wende (cast
## "wende", D-112): a 180° arrow and 3 – 2 – 1.
func _draw_wende_countdown(vs: ViewState) -> void:
	if vs.boss_cast() != "wende":
		return
	var left := 1.0 - float(vs.boss.get("cast_t", 0.0))
	var n := clampi(int(ceil(left * 3.0)), 1, 3)
	var spin := (1.0 - fmod(left * 3.0, 1.0)) * PI
	for p in vs.players:
		if int(p.get("state", 0)) != 0:
			continue
		var c: Vector2 = p.get("pos", Vector2.ZERO) + Vector2(0, -104)
		draw_set_transform(c, spin, Vector2.ONE)
		draw_arc(Vector2.ZERO, 22.0, 0.3, PI - 0.1, 14, Color(WHITE, 0.9), 8.0)
		draw_arc(Vector2.ZERO, 22.0, 0.3, PI - 0.1, 14, WENDE_PINK, 4.5)
		var tip := Vector2(cos(0.3), sin(0.3)) * 22.0
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-9, -2), tip + Vector2(7, -8), tip + Vector2(4, 9)]), WENDE_PINK)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		Doodle.text(self, str(n), c + Vector2(0, 12), 34, WENDE_PINK, _hand, 6)


## A straight double arrow (Teilwende: which axis is flipped).
func _double_arrow(c: Vector2, vertical: bool, len: float, col: Color) -> void:
	var d: Vector2 = Vector2(0, 1) if vertical else Vector2(1, 0)
	var n := Vector2(-d.y, d.x)
	var a := c - d * len * 0.5
	var b := c + d * len * 0.5
	draw_line(a, b, col, 3.5)
	for e in [[a, -1.0], [b, 1.0]]:
		var p: Vector2 = e[0]
		var s: float = e[1]
		draw_colored_polygon(PackedVector2Array([p + d * s * 4.0, p - d * s * 8.0 + n * 7.0, p - d * s * 8.0 - n * 7.0]), col)


func _heart_icon(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(0, r)]), col)


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
		var bike := ci == t_rad
		var face := sx
		var roll := 0.0
		if bike:
			# the cargo bike faces where it rides (aim only until it first moves)
			face = float(_p_face.get(pid, sx))
			if absf(hd.x) > 0.25:
				face = signf(hd.x)
			_p_face[pid] = face
			var moved := minf(pos.distance_to(prev), 24.0)
			roll = float(_p_roll.get(pid, 0.0)) + moved
			_p_roll[pid] = roll
			_p_speed[pid] = lerpf(float(_p_speed.get(pid, 0.0)), moved, 0.25)
		var ult := (flags & ViewState.PF_ULT) != 0 and state == 0
		var lounging := ult and ci == t_sozial
		if ult and bike:
			_draw_critical_mass(pos, hd, st, v, pid, roll)
		if _eff_tarif > 0.0 and state == 0:
			_draw_tarif_glow(pos, pid)
		# ground marker
		var mc := Color(col, 0.75) if pid == me else Color(col, 0.45)
		draw_polyline(Doodle.ellipse_pts(pos + Vector2(0, 22), 20, 7, v), mc, 3.0 if pid == me else 2.0)
		if state == 3:
			# Away (connection lost, networking.md §7.4): frozen and greyed out.
			draw_mesh(_mesh(K_PLAYER, ci, st, v), null, Transform2D(0.0, Vector2(face, 1), 0.0, pos), Color(0.55, 0.55, 0.55, 0.5))
			Doodle.text(self, tr("HUD_AWAY_TAG"), pos + Vector2(0, -50), 18, Color(0.45, 0.45, 0.45, 0.5 + 0.4 * absf(sin(t * 3.0))), _hand, 4)
		elif state == 1:
			_dashed_circle(pos, REVIVE_RANGE, Color(col, 0.6), 2.5, 20, t * 0.8)
			var prog: float = p.get("revive", -1.0)
			if prog > 0.0:
				draw_arc(pos, REVIVE_RANGE - 6.0, -PI / 2, -PI / 2 + TAU * prog, 32, Color(0.25, 0.7, 0.3), 6.0)
			draw_mesh(_mesh(K_PLAYER, ci, st, v), null, Transform2D(PI / 2 * face, pos + Vector2(0, 6)), Color(0.85, 0.85, 0.85))
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
			elif bike:
				var spd := float(_p_speed.get(pid, 0.0))
				if spd > 0.6 and not ult:
					_draw_bike_lines(pos, face, clampf(spd / 4.0, 0.0, 1.0), pid)
				_draw_bike(pos, face, roll, st, v, mod)
				_draw_weapons(p.get("weapons", PackedByteArray()), pos, aim, st, v, 44.0)
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
				if flags & (ViewState.PF_REVERSE_X | ViewState.PF_REVERSE_Y):
					# Teilwende: only one axis flipped (D-112)
					_double_arrow(head + Vector2(48, -12), (flags & ViewState.PF_REVERSE_Y) != 0, 26.0, Color(0.75, 0.1, 0.5))
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
	for k in _p_roll.keys():
		if not new_prev.has(k):
			_p_roll.erase(k)
			_p_face.erase(k)
			_p_speed.erase(k)


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


## Critical Mass: a pack of pale ghost cargo bikes riding behind (staggered in
## two lanes, pedalling out of step), plus speed lines.
func _draw_critical_mass(pos: Vector2, hd: Vector2, st: int, v: int, pid: int, roll: float) -> void:
	var t := anim_time
	var dir := hd.normalized() if hd.length_squared() > 0.01 else Vector2.RIGHT
	var sx := float(_p_face.get(pid, -1.0 if dir.x < -0.05 else 1.0))
	var nrm := dir.orthogonal()
	for k in range(4, 0, -1):
		var lane := (1.0 if k % 2 == 1 else -1.0) * 14.0
		var off := -dir * (14.0 + 34.0 * k) + nrm * (lane + sin(t * 7.0 + k * 1.3 + pid) * 3.0)
		var a := (1.18 - k * 0.18) * own_fx
		_draw_bike(pos + off, sx, roll + k * 11.0, st, v + k, Color(1, 1, 1, a), true)
	var lc := Color(0.25, 0.55, 0.3, 0.6 * own_fx)
	for k in 6:
		var lane := (float(k) - 2.5) * 9.0
		var ph := fmod(t * 3.0 + k * 0.37, 1.0)
		var a0 := pos - dir * (30.0 + ph * 120.0) + nrm * lane
		var a1 := a0 - dir * (24.0 + 16.0 * Doodle.noise(k))
		draw_line(a0, a1, Color(lc, lc.a * (1.0 - ph)), 2.5)


## Lastenrad: two rolling wheels plus the body baked in the current pedal phase.
func _draw_bike(pos: Vector2, face: float, roll: float, st: int, v: int, mod: Color, ghost := false) -> void:
	var crank := roll / 11.0
	var fr := posmod(int(floor(crank / TAU * BIKE_FRAMES)), BIKE_FRAMES)
	var g := 2 if ghost else 0
	var vv := posmod(v, Doodle.VARIANTS)
	var base := Transform2D(0.0, Vector2(face, 1.0), 0.0, pos)
	draw_mesh(_mesh(K_WHEEL, g, st, vv), null, base * Transform2D(roll / BIKE_RW_R, BIKE_RW), mod)
	draw_mesh(_mesh(K_WHEEL, 1 + g, st, vv), null, base * Transform2D(roll / BIKE_FW_R, BIKE_FW), mod)
	draw_mesh(_mesh(K_BIKE, fr + (BIKE_GHOST if ghost else 0), st, vv), null, base, mod)


## Three pencil speed dashes behind a moving Lastenrad (k = 0..1 strength).
func _draw_bike_lines(pos: Vector2, face: float, k: float, pid: int) -> void:
	var c := Color(0.2, 0.2, 0.25, 0.45 * k)
	for i in 3:
		var ph := fmod(anim_time * 4.0 + i * 0.33 + pid * 0.2, 1.0)
		var y := -4.0 + i * 9.0
		var x0 := -38.0 - ph * 10.0
		var ln := (10.0 + 6.0 * Doodle.noise(i + pid)) * k
		draw_line(pos + Vector2(x0 * face, y), pos + Vector2((x0 - ln) * face, y), Color(c, c.a * (1.0 - ph * 0.6)), 2.0)


## Tarifrunde: soft red union-vest glow behind a player.
func _draw_tarif_glow(pos: Vector2, pid: int) -> void:
	var a := clampf(_eff_tarif / 0.5, 0.0, 1.0) * own_fx
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
	var a := antrag_vis * own_fx
	var span := ARENA.x + 240.0
	var sheet := _mesh(K_MISC, M_SHEET, st, Doodle.frame % Doodle.VARIANTS)
	var stamp := _mesh(K_MISC, M_STAMP, st, Doodle.frame % Doodle.VARIANTS)
	for k in 46:
		var sp := 110.0 + 70.0 * (0.5 + 0.5 * Doodle.noise(k * 3))
		var x := fmod(Doodle.noise(k) * 2000.0 + 2000.0 + t * sp, span) - 120.0
		var y := INNER.position.y + 20.0 + (0.5 + 0.5 * Doodle.noise(k + 77)) * (INNER.size.y - 40.0)
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
			Transform2D(sin(t * 9.0 + k) * 0.06, Vector2(fs, 1), 0.0, fp + Vector2(0, -absf(sin(t * 9.0 + k)) * 2.0)),
			Color(1, 1, 1, own_fx))


func _draw_weapons(wb, pos: Vector2, aim: float, st: int, v: int, radius := 36.0) -> void:
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
		var wp := pos + Vector2(0, -8) + Vector2(cos(a), sin(a) * 0.85) * radius
		draw_mesh(_mesh(K_WEAPON, wi, st, v), null, Transform2D(aim, flip, 0.0, wp), Color(1, 1, 1, own_fx))


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
	if legs == "none":
		pass  # drawn by the caller (Lastenrad: pedalling legs)
	elif legs == "sit":
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
		"chain":
			# Menschenkette: both arms out sideways, hands at the neighbours'
			hl = shl + Vector2(-11 * s, 8 * k)
			hrr = shr + Vector2(11 * s, 8 * k)
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
		"bars", "bars_mug", "bars_fist":
			# riding: far hand (and near hand unless busy) on the handlebar grip
			var g: Vector2 = o.get("grip", Vector2(x + 14 * s, sh + 12 * k))
			hl = g + Vector2(-1.5 * s, 0.4 * s)
			el = shl.lerp(hl, 0.5) + Vector2(-0.5 * s, 3.5 * k)
			if arms == "bars":
				hrr = g
				er = shr.lerp(g, 0.5) + Vector2(0, 3.5 * k)
			elif arms == "bars_mug":
				er = shr + Vector2(2 * s, 9 * k)
				hrr = shr + Vector2(7 * s, 5 * k)
			else:
				hrr = shr + Vector2(3 * s, -16 * k)
				fist = true
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


## Soft smudge shadow under feet with a light pencil scribble on top.
func _shadow(sk: Doodle.Sketch, c: Vector2, w: float) -> void:
	sk.soft_shadow(c, w * 0.6, maxf(3.0, w * 0.17))
	var pts := PackedVector2Array()
	var n := int(w / 5.0) + 2
	for i in n:
		var fx := -w * 0.4 + w * 0.8 * i / (n - 1)
		pts.append(c + Vector2(fx, -1.5 if i % 2 == 0 else 1.5))
	sk.line(pts, 1.0, Color(0.2, 0.2, 0.2, 0.22))


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
		"briefkasten":
			# Briefkastenfirma (D-142): a letterbox on a post, covered in little company
			# plates, a gold slot. A structure, not a person: no money bag, no face (§2).
			_shadow(sk, Vector2(0, 30), 40)
			sk.rect(Rect2(-3, 4, 6, 26), Color("6b6f75"), true, 1.4)
			sk.shape(PackedVector2Array([Vector2(-24, -30), Vector2(24, -30), Vector2(26, 6), Vector2(-26, 6)]), Color("c9a227"))
			sk.rect(Rect2(-14, -26, 28, 4), Color("3a2c10"), true, 1.0)
			var plates := [Color("f4f1e6"), Color("dfe7ef"), Color("f2e3c4"), Color("e6e6e6")]
			for row in 3:
				for col in 3:
					var pr := Rect2(-21 + col * 14.5, -18 + row * 7.6, 12.5, 6.0)
					sk.rect(pr, plates[(row * 3 + col) % plates.size()], true, 0.7)
					sk.line2(pr.position + Vector2(2, 3), pr.position + Vector2(9, 3), 0.7, Color("55534c"))
			sk.line2(Vector2(-26, 6), Vector2(26, 6), 1.6, INK)
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
		"kartoffelbrei":
			# a lumpy dollop of mash with a butter flake and a wisp of steam (drawn upright)
			var blob := PackedVector2Array()
			for i in 12:
				var a := TAU * i / 12.0
				var rr := 8.5 + (1.6 if i % 3 == 0 else 0.0) + sk.rng.randf_range(-0.6, 0.6)
				blob.append(Vector2(cos(a) * rr * 1.1, sin(a) * rr * 0.85))
			sk.shape(blob, MASH, true, 1.7)
			sk.fill(sk.ellipse_pts(Vector2(-2.5, -2.5), 4.5, 3.0, 8), Color(1, 1, 0.94), false)
			sk.line(PackedVector2Array([Vector2(-6, 2), Vector2(-2, 3.5), Vector2(3, 2.5)]), 0.9, Color("c9b06a"))
			sk.shape(PackedVector2Array([Vector2(2, -6), Vector2(6.5, -7), Vector2(7, -3.5), Vector2(2.5, -3)]), Color("f7d23a"), true, 0.9)
			sk.line(PackedVector2Array([Vector2(-3, -10), Vector2(-1, -13), Vector2(-3.5, -16), Vector2(-1.5, -19)]), 1.1, Color(0.55, 0.55, 0.55, 0.7))
			sk.line(PackedVector2Array([Vector2(3, -10), Vector2(5, -13), Vector2(2.5, -16)]), 1.0, Color(0.55, 0.55, 0.55, 0.6))
		"ticket":
			# 9-Euro-Ticket: small paper ticket, red stripe, punched hole, a few printed lines
			var card := PackedVector2Array([Vector2(-8, -5), Vector2(8, -5), Vector2(8, 5), Vector2(-8, 5)])
			sk.line(card, 3.6, WHITE, true)
			sk.shape(card, Color("fbf6e6"), true, 1.3)
			sk.fill(PackedVector2Array([Vector2(-7.4, -4.4), Vector2(-3, -4.4), Vector2(-3, 4.4), Vector2(-7.4, 4.4)]), Color("d8262e"), false)
			sk.line2(Vector2(-5.2, -2.5), Vector2(-5.2, 2.5), 1.2, WHITE)
			sk.line2(Vector2(-6.4, -1.0), Vector2(-4.2, -1.0), 1.0, WHITE)
			sk.line2(Vector2(-1, -2.3), Vector2(6, -2.3), 0.8, INK)
			sk.line2(Vector2(-1, 0.3), Vector2(4, 0.3), 0.8, INK)
			sk.line2(Vector2(-1, 2.7), Vector2(5.5, 2.7), 0.8, Color("2e6db4"))
			sk.dot(Vector2(6, 0.3), 1.0, Color(0.5, 0.45, 0.4))
		"akte":
			# Kleine Anfrage: a buff file folder with a red tab and a paper sticking out
			sk.shape(PackedVector2Array([Vector2(-9, -6), Vector2(9, -6), Vector2(9, 6), Vector2(-9, 6)]), Color("e8d29a"), true, 1.5)
			sk.fill(PackedVector2Array([Vector2(-8, -5.5), Vector2(-3, -5.5), Vector2(-3, 5.5), Vector2(-8, 5.5)]), Color("d8c286"), false)
			sk.rect(Rect2(2, -9, 6, 3.5), Color("d8262e"), true, 1.0)
			sk.line2(Vector2(-1, -2.5), Vector2(6, -2.5), 0.8, INK)
			sk.line2(Vector2(-1, 0.5), Vector2(7, 0.5), 0.8, INK)
			sk.line2(Vector2(-1, 3.5), Vector2(4, 3.5), 0.8, INK)
		"aktenblatt":
			# Lobbyregister: a sheet with typed lines and a punched margin
			sk.rect(Rect2(-6, -7.5, 12, 15), WHITE, true, 1.3)
			sk.dot(Vector2(-4, -4), 0.9, INK)
			sk.dot(Vector2(-4, 4), 0.9, INK)
			for k in 4:
				sk.line2(Vector2(-2, -4.5 + k * 3), Vector2(4, -4.5 + k * 3), 0.7, Color(0.3, 0.3, 0.35))
		"sticker":
			# Soli-Sticker: a round pink sticker with a white heart and a peeled corner
			sk.circle(Vector2.ZERO, 7.0, Color("f06aa7"), true, 1.5)
			sk.fill(PackedVector2Array([Vector2(-3.2, -1.4), Vector2(0, 2.8), Vector2(3.2, -1.4), Vector2(1.6, -3.2), Vector2(0, -1.8), Vector2(-1.6, -3.2)]), WHITE, false)
			sk.fill(PackedVector2Array([Vector2(4, 4), Vector2(7, 1), Vector2(6.5, 5.5)]), Color("fbf6e6"), false)
		_:
			sk.circle(Vector2.ZERO, 5.0, RED)


# --- Pickups ---------------------------------------------------------------------------

## Pickups pop off the paper: a warm glow, a thin sparkle ring and (for the
## simple shapes) a white sticker edge around the item.
func _pickup_glow(sk: Doodle.Sketch, c: Vector2, r: float, col: Color) -> void:
	for k in 2:
		sk.fill(sk.ellipse_pts(c, r * (1.0 - 0.35 * k), r * (0.82 - 0.3 * k), 14), Color(col, 0.2), false)
	var ring := sk.ellipse_pts(c, r * 1.02, r * 0.84, 16, 0.4, TAU * 0.3)
	sk.line(ring, 1.1, Color(col.darkened(0.15), 0.55))
	ring = sk.ellipse_pts(c, r * 1.02, r * 0.84, 16, PI + 0.4, TAU * 0.3)
	sk.line(ring, 1.1, Color(col.darkened(0.15), 0.55))


func _b_pickup(sk: Doodle.Sketch, id: String) -> void:
	sk.lw = 1.6
	match id:
		"pfand":
			_pickup_glow(sk, Vector2(0, 1), 13.0, Color("f2c418"))
			_shadow(sk, Vector2(0, 9), 10)
			var bottle := PackedVector2Array([Vector2(-3.5, 8), Vector2(-3.5, -1), Vector2(-1.6, -4), Vector2(-1.6, -9),
				Vector2(1.6, -9), Vector2(1.6, -4), Vector2(3.5, -1), Vector2(3.5, 8)])
			sk.line(bottle, 4.6, WHITE, true)
			sk.shape(bottle, Color("6a4a22"))
			sk.fill(PackedVector2Array([Vector2(-3.2, 1), Vector2(3.2, 1), Vector2(3.2, 5), Vector2(-3.2, 5)]), Color("e8dfb8"), false)
			sk.line2(Vector2(-2, -2), Vector2(-2, 6), 0.9, Color(1, 1, 1, 0.6))
			sk.rect(Rect2(-1.8, -10.5, 3.6, 2), GOLD, true, 0.8)
		"passant":
			_pickup_glow(sk, Vector2(0, 0), 15.0, Color("6ccf8a"))
			_b_follower_body(sk, 0, 2, 0.62, "wave", Vector2(0, 11))
		"geldschein":
			_pickup_glow(sk, Vector2(0, 0), 15.0, Color("6ccf5a"))
			var note := PackedVector2Array([Vector2(-10, -5), Vector2(10, -6), Vector2(11, 5), Vector2(-10, 6)])
			sk.line(note, 4.6, WHITE, true)
			sk.shape(note, Color("8fcf8a"))
			sk.circle(Vector2(0, 0), 3.2, Color("d6f0c8"), true, 0.9)
			sk.line2(Vector2(-1.6, -1), Vector2(1.4, -1.2), 0.8, INK)
			sk.line2(Vector2(-1.6, 1), Vector2(1.4, 0.8), 0.8, INK)
			sk.line(PackedVector2Array([Vector2(1.6, -2.4), Vector2(-1.2, -1.6), Vector2(-1.4, 1.6), Vector2(1.6, 2.4)]), 0.9)
		"stulle":
			_pickup_glow(sk, Vector2(0, -1), 15.0, Color("f08a24"))
			_shadow(sk, Vector2(0, 7), 16)
			sk.shape(PackedVector2Array([Vector2(-10, 4), Vector2(10, 4), Vector2(10, 1), Vector2(-10, 1)]), Color("d8a868"))
			sk.line(PackedVector2Array([Vector2(-10, 0), Vector2(-6, -2), Vector2(-2, 0), Vector2(2, -2), Vector2(6, 0), Vector2(10, -2)]), 2.4, Color("5aa83a"))
			sk.shape(PackedVector2Array([Vector2(-8, -1), Vector2(8, -1), Vector2(8, -3), Vector2(-8, -3)]), Color("e88a8a"), true, 1.0)
			sk.shape(PackedVector2Array([Vector2(-10, -3), Vector2(10, -3), Vector2(9, -8), Vector2(-9, -8)]), Color("d8a868"))
			sk.dot(Vector2(-3, -5.5), 0.7, Color("8a6030"))
			sk.dot(Vector2(4, -6), 0.7, Color("8a6030"))
		"reichsausweis":
			_pickup_glow(sk, Vector2(0, 0), 13.0, Color("a8a090"))
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
		"overall":
			# Weißer Overall: friendly activist in a white overall with the hood up,
			# face visible and smiling, sprinting forward (legs wide, arm reaching).
			_shadow(sk, Vector2(0, 19), 20)
			var suit := Color("f6f5ef")
			_person(sk, {"x": 0.0, "y": 18.0, "s": 0.92, "body": suit, "pants": suit, "sleeve": suit,
				"hair": "none", "hat": "hood", "hat_c": Color("ecebe4"), "eyes": "dots", "mouth": "grin", "blush": true,
				"brows": "raised", "arms": "point", "lean": 3.2, "spread": 6.5, "wb": 6.8, "wt": 7.6,
				"shoes": Color("3f8f4f"), "shoe_w": 4.0,
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var n: Vector2 = a["neck"]
					var hp: Vector2 = a["hip"]
					# zip, a colourful patch and a painted sun on the chest
					k.line2(n + Vector2(0, 1), hp + Vector2(0.5, -1), 0.8, Color(0.6, 0.6, 0.62))
					k.circle(a["chest"] + Vector2(-3.2, 1.0), 2.2, Color("f2c418"), true, 0.7)
					k.line(PackedVector2Array([hp + Vector2(-6, -1), hp + Vector2(6, -1)]), 1.0, Color(0.72, 0.72, 0.7)),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var hl: Vector2 = a["hl"]
					k.circle(hl, 2.0, Color("6ccf8a"), true, 0.8)
					var hr: Vector2 = a["hr"]
					k.circle(hr, 2.0, Color("6ccf8a"), true, 0.8)})
		"laterne":
			# Menschenkette solo anchor: a city lamppost with a ribbon tied to it
			_shadow(sk, Vector2(0, 18), 18)
			sk.rect(Rect2(-5, 12, 10, 6), Color("4a5260"), true, 1.4)
			sk.stroke(Vector2(0, 12), Vector2(0, -54), 3.0, Color("4a5260"))
			sk.line(PackedVector2Array([Vector2(0, -54), Vector2(6, -62), Vector2(14, -62)]), 2.6, Color("4a5260"))
			sk.shape(PackedVector2Array([Vector2(8, -63), Vector2(20, -63), Vector2(17, -56), Vector2(11, -56)]), Color("3a404c"), true, 1.3)
			sk.ellipse(Vector2(14, -55), 4.0, 2.0, Color("fff2a8"), true, 0.9)
			sk.line(PackedVector2Array([Vector2(-1, -6), Vector2(8, -4), Vector2(12, 2)]), 2.4, Color("d63a2e"))
			sk.line(PackedVector2Array([Vector2(-1, -6), Vector2(-8, -1)]), 2.0, Color("d63a2e"))
		"pappkamerad":
			# a faceless cardboard figure on a stand holding a crossed-out schnitzel sign
			# (invented "Verbotspartei"); no real person, no real group (D-095)
			_shadow(sk, Vector2(0, 18), 26)
			var card := Color("c9a36b")
			sk.line2(Vector2(-12, 18), Vector2(12, 18), 2.4, Color("8a6a3a"))
			sk.line2(Vector2(0, 18), Vector2(6, 4), 1.8, Color("8a6a3a"))
			var body := PackedVector2Array([Vector2(-10, 16), Vector2(10, 16), Vector2(11, -12), Vector2(7, -18), Vector2(-7, -18),
				Vector2(-11, -12)])
			sk.shape(body, card, true, 1.8)
			sk.circle(Vector2(0, -28), 9.0, card, true, 1.8)
			sk.line2(Vector2(-6, 2), Vector2(-3, 6), 0.9, Color("a8824e"))
			sk.line2(Vector2(4, -6), Vector2(7, -3), 0.9, Color("a8824e"))
			# the sign on a stick
			sk.line2(Vector2(14, 6), Vector2(14, -40), 1.8, Color("8a6a3a"))
			sk.rect(Rect2(2, -66, 26, 26), WHITE, true, 1.6)
			var schnitzel := PackedVector2Array()
			for i in 10:
				var a := TAU * i / 10.0
				schnitzel.append(Vector2(15, -53) + Vector2(cos(a) * 7.5, sin(a) * 5.0 + (0.8 if i % 2 else -0.4)))
			sk.shape(schnitzel, Color("d9a24a"), true, 1.0)
			sk.line(sk.ellipse_pts(Vector2(15, -53), 10.5, 10.5, 16), 2.2, Color("d8262e"), true)
			sk.line2(Vector2(8, -60), Vector2(22, -46), 2.2, Color("d8262e"))
		"sani":
			# Demosanitäter:in: high-vis vest with a green cross (not the protected Red
			# Cross emblem, D-095), a first-aid bag, competent and friendly
			_shadow(sk, Vector2(0, 19), 20)
			_person(sk, {"x": 0.0, "y": 18.0, "s": 0.92, "body": Color("f2d22e"), "pants": Color("33406a"),
				"sleeve": Color("e9e6dc"), "hair": "ponytail", "hair_c": Color("6a3e22"), "eyes": "dots", "mouth": "smile",
				"blush": true, "arms": "hold", "wb": 6.8, "wt": 7.8, "shoes": Color("2e2e34"),
				"deco": func(k: Doodle.Sketch, a: Dictionary):
					var c: Vector2 = a["chest"] + Vector2(0, 1)
					k.rect(Rect2(c + Vector2(-4, -4), Vector2(8, 8)), WHITE, true, 0.8)
					k.fill(PackedVector2Array([c + Vector2(-1, -3), c + Vector2(1, -3), c + Vector2(1, 3), c + Vector2(-1, 3)]), Color("2f9a4c"), false)
					k.fill(PackedVector2Array([c + Vector2(-3, -1), c + Vector2(3, -1), c + Vector2(3, 1), c + Vector2(-3, 1)]), Color("2f9a4c"), false)
					var hp: Vector2 = a["hip"]
					k.line(PackedVector2Array([hp + Vector2(-6, -4), hp + Vector2(6, -4)]), 1.4, Color("c9c9c9")),
				"after": func(k: Doodle.Sketch, a: Dictionary):
					var h: Vector2 = a["hr"]
					k.rect(Rect2(h + Vector2(-2, 0), Vector2(11, 8)), Color("2f9a4c"), true, 1.2)
					k.line2(h + Vector2(3.5, 1.5), h + Vector2(3.5, 6.5), 1.2, WHITE)
					k.line2(h + Vector2(1, 4), h + Vector2(6, 4), 1.2, WHITE)})
		"lauti":
			# Lauti: a small sound truck with two horn speakers and a banner
			_shadow(sk, Vector2(0, 16), 40)
			sk.shape(PackedVector2Array([Vector2(-26, 12), Vector2(22, 12), Vector2(22, -6), Vector2(14, -16), Vector2(-26, -16)]),
				Color("e8742a"), true, 1.8)
			sk.shape(PackedVector2Array([Vector2(14, -14), Vector2(21, -6), Vector2(14, -6)]), Color("bfe3f2"), true, 1.2)
			sk.rect(Rect2(-23, -10, 32, 11), WHITE, true, 1.2)
			sk.line2(Vector2(-20, -6), Vector2(4, -6), 1.4, Color("d8262e"))
			sk.line2(Vector2(-20, -2.5), Vector2(-2, -2.5), 1.0, INK)
			for x in [-14.0, 6.0]:
				sk.circle(Vector2(x, 13), 5.0, Color("2e2e34"), true, 1.4)
				sk.dot(Vector2(x, 13), 1.5, Color("c0c4ca"))
			for d in [-1.0, 1.0]:
				var b := Vector2(-6 + d * 9, -16)
				sk.line2(b, b + Vector2(0, -6), 1.6, INK)
				sk.shape(PackedVector2Array([b + Vector2(-2, -6), b + Vector2(2, -6), b + Vector2(7 * d, -13), b + Vector2(-1 * d, -14)]),
					Color("c0c4ca"), true, 1.2)
		"turbine":
			_shadow(sk, Vector2(0, 2), 30)
			sk.shape(PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(2, -76), Vector2(-2, -76)]), WHITE)
			sk.ellipse(Vector2(0, -78), 7, 4.5, Color("e6e8ec"))
			sk.line2(Vector2(-3, -30), Vector2(3, -30), 0.8, Color(0.5, 0.5, 0.5))


# --- Misc ---------------------------------------------------------------------------------

## Menschenkette activist (four looks): ordinary people, arms out to hold the
## neighbours' hands, feet at y = 18 (GDD §11 v0.3).
func _b_kette(sk: Doodle.Sketch, look: int) -> void:
	var looks := [
		{"body": Color("d63a2e"), "pants": DENIM, "hair": "short", "hair_c": Color("3a2a1e")},
		{"body": Color("2e6db4"), "pants": PANTS, "hair": "long", "hair_c": Color("a8742e")},
		{"body": Color("3f8f4f"), "pants": CHINO, "hair": "bun", "hair_c": Color("d8d8d8")},
		{"body": Color("8e44ad"), "pants": DENIM, "hair": "bob", "hair_c": Color("1e1e22")},
	]
	var o: Dictionary = looks[look % looks.size()].duplicate()
	o.merge({"x": 0.0, "y": 18.0, "s": 0.9, "eyes": "dots", "mouth": "smile", "arms": "chain", "wb": 6.5, "wt": 7.5})
	_shadow(sk, Vector2(0, 19), 18)
	_person(sk, o)


func _b_misc(sk: Doodle.Sketch, id: int) -> void:
	if id >= M_KETTE and id < M_KETTE + KETTE_LOOKS:
		_b_kette(sk, id - M_KETTE)
		return
	match id:
		M_BG:
			sk.jit = 0.5
			sk.seg = 60.0
			sk.misreg = 0.0
			sk.fill(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), ARENA, Vector2(0, ARENA.y)]), PAPER, false)
			_b_paper_grain(sk)
			# the staging area behind all four walls: trampled grey ground (GDD §5a)
			# (fills overlap in the corners so no paper seam shows; hatching doesn't)
			var bands: Array[PackedVector2Array] = []
			for r in [Rect2(0, 0, ARENA.x, WALL_TOP), Rect2(0, ARENA.y - WALL_TOP, ARENA.x, WALL_TOP),
					Rect2(0, WALL_TOP, WALL_TOP, ARENA.y - 2.0 * WALL_TOP), Rect2(ARENA.x - WALL_TOP, WALL_TOP, WALL_TOP, ARENA.y - 2.0 * WALL_TOP)]:
				var rr: Rect2 = r
				bands.append(PackedVector2Array([rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)]))
			for r in [Rect2(0, 0, ARENA.x, WALL_TOP + 6.0), Rect2(0, ARENA.y - WALL_TOP - 6.0, ARENA.x, WALL_TOP + 6.0),
					Rect2(0, 0, WALL_TOP + 6.0, ARENA.y), Rect2(ARENA.x - WALL_TOP - 6.0, 0, WALL_TOP + 6.0, ARENA.y)]:
				var rr: Rect2 = r
				sk.fill(PackedVector2Array([rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)]),
					Color("a89c84"), false)
			var x := INNER.position.x + 40.0
			while x < INNER.end.x:
				sk.line2(Vector2(x, INNER.position.y), Vector2(x, INNER.end.y), 1.0, Color(0.3, 0.45, 0.7, 0.13))
				x += 40.0
			var y := INNER.position.y + 40.0
			while y < INNER.end.y:
				sk.line2(Vector2(INNER.position.x, y), Vector2(INNER.end.x, y), 1.0, Color(0.3, 0.45, 0.7, 0.13))
				y += 40.0
			sk.line2(Vector2(INNER.position.x + 70, INNER.position.y), Vector2(INNER.position.x + 68, INNER.end.y), 1.6, Color(0.8, 0.2, 0.2, 0.25))
			for b in bands:
				sk.hatch(b, 7.0, 2.3, Color(0.25, 0.2, 0.15, 0.22), 1.2)
				sk.hatch(b, 13.0, 0.9, Color(0.25, 0.2, 0.15, 0.15), 1.0)
			var pebbles := 44
			for i in pebbles:
				var s := (i + 0.5 + Doodle.noise(i) * 0.25) * Arena.perimeter(Arena.STAGING_RECT) / pebbles
				var p := Arena.perimeter_point(Arena.STAGING_RECT, s) + Vector2(Doodle.noise(i + 50), Doodle.noise(i + 70)) * 20.0
				sk.line(sk.ellipse_pts(p, 6 + absf(Doodle.noise(i + 9)) * 6, 3, 6), 1.0, Color(0.2, 0.18, 0.12, 0.3), true)
			sk.seg = 9.0
			var faint := Color(0.25, 0.25, 0.3, 0.18)
			_coffee_stain(sk, _ip(Vector2(1380, 820)), 45.0, 0.85)
			_coffee_stain(sk, _ip(Vector2(240, 300)), 29.0, 0.6)
			_coffee_stain(sk, _ip(Vector2(1545, 150)), 34.0, 0.7)
			_margin_doodles(sk)
			for p in [Vector2(520, 880), Vector2(1180, 230), Vector2(150, 640), Vector2(900, 520), Vector2(1500, 420)]:
				sk.line(sk.star_pts(_ip(p), 12, 5, 5), 1.4, faint, true)
			sk.line(_ipa([Vector2(700, 940), Vector2(760, 930), Vector2(820, 945), Vector2(880, 928)]), 1.6, faint)
			sk.line(_ipa([Vector2(300, 160), Vector2(340, 175), Vector2(330, 150), Vector2(370, 170)]), 1.4, faint)
			sk.line(_ipa([Vector2(1060, 760), Vector2(1100, 760), Vector2(1092, 752)]), 1.4, faint)
			sk.line(_ipa([Vector2(1100, 760), Vector2(1092, 768)]), 1.4, faint)
			var hrt := _ipa([Vector2(1500, 900), Vector2(1488, 886), Vector2(1492, 878), Vector2(1500, 884),
				Vector2(1508, 878), Vector2(1512, 886)])
			sk.line(hrt, 1.4, Color(0.8, 0.2, 0.3, 0.2), true)
			for i in 5:
				sk.line2(_ip(Vector2(90 + i * 6, 950)), _ip(Vector2(92 + i * 6, 970)), 1.4, faint)
			sk.line2(_ip(Vector2(86, 966)), _ip(Vector2(122, 954)), 1.4, faint)
			sk.seg = 30.0
			sk.line(PackedVector2Array([Vector2(0, 0), Vector2(ARENA.x, 0), ARENA, Vector2(0, ARENA.y)]), 4.0, INK, true)
		M_WALL:
			_b_wall(sk, 0)
		M_DESK:
			# wood grain of the desk around the sheet (only the visible border band)
			sk.misreg = 0.0
			sk.seg = 40.0
			sk.jit = 1.2
			var grain := Color(DESK.darkened(0.3), 0.55)
			var light := Color(DESK.lightened(0.12), 0.45)
			var y := -260.0
			var i := 0
			while y < ARENA.y + 260.0:
				var pts := PackedVector2Array()
				var ph := Doodle.noise(i) * 3.0
				var x := -300.0
				while x <= ARENA.x + 300.0:
					pts.append(Vector2(x, y + sin(x * 0.004 + ph) * 6.0 + sin(x * 0.013 + ph * 2.0) * 2.0))
					x += 80.0
				sk.line(pts, 1.4 if i % 3 else 2.2, grain if i % 2 == 0 else light)
				y += 11.0 + absf(Doodle.noise(i + 40)) * 9.0
				i += 1
			for c in PackedVector2Array([Vector2(-120, -110), Vector2(ARENA.x + 120, 300), Vector2(400, -130), Vector2(1200, ARENA.y + 120),
					Vector2(-150, 820), Vector2(ARENA.x + 150, -90)]):
				sk.line(sk.ellipse_pts(c, 22, 7, 12), 1.6, grain, true)
				sk.line(sk.ellipse_pts(c, 12, 3.5, 10), 1.2, grain, true)
		M_HIT:
			sk.lw = 1.6
			sk.misreg = 0.0
			sk.shape(sk.star_pts(Vector2.ZERO, 18.0, 9.5, 9, 0.2), Color("fff3a6"), true, 1.6)
			sk.fill(sk.star_pts(Vector2.ZERO, 11.0, 6.0, 9, 0.5), Color(1.0, 0.62, 0.2, 0.75), false)
		M_RUBBLE:
			_b_rubble(sk, SEG_W)
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
			# tent stripes and bunting along the inside of the four walls
			var x0 := INNER.position.x
			var x1 := INNER.end.x
			var yy := INNER.position.y
			var k := 0
			while yy < INNER.end.y - sw:
				sk.fill(PackedVector2Array([Vector2(x0, yy), Vector2(x0 + 60, yy + 10), Vector2(x0 + 60, yy + sw + 10), Vector2(x0, yy + sw)]), cols[k % 2], false)
				sk.fill(PackedVector2Array([Vector2(x1, yy), Vector2(x1 - 60, yy + 10), Vector2(x1 - 60, yy + sw + 10), Vector2(x1, yy + sw)]), cols[k % 2], false)
				yy += sw
				k += 1
			var x := x0
			k = 0
			while x < x1 - 1.0:
				sk.shape(PackedVector2Array([Vector2(x, INNER.position.y + 2), Vector2(x + 40, INNER.position.y + 2), Vector2(x + 20, INNER.position.y + 30)]),
					Color("e8443a") if k % 3 == 0 else (Color("f2c418") if k % 3 == 1 else Color("2e6db4")), true, 1.2)
				sk.shape(PackedVector2Array([Vector2(x, INNER.end.y), Vector2(x + 40, INNER.end.y), Vector2(x + 20, INNER.end.y - 26)]),
					Color("e8443a") if k % 2 == 0 else WHITE, true, 1.2)
				x += 40.0
				k += 1
			sk.line(PackedVector2Array([Vector2(x0, INNER.position.y + 2), Vector2(x1, INNER.position.y + 2)]), 2.0)
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
		M_DROP:
			# ground shadow under a flying Kartoffelbrei blob
			sk.soft_shadow(Vector2.ZERO, 9.0, 3.5, 0.2)
		M_POTATO:
			# Kartoffelbrei target icon: one friendly potato with eyes (sprouts)
			sk.lw = 1.6
			sk.misreg = 0.5
			var pot := PackedVector2Array()
			for i in 14:
				var a := TAU * i / 14.0
				pot.append(Vector2(cos(a) * 11.0, sin(a) * 7.5 + sin(a * 2.0) * 0.8))
			sk.shape(pot, Color("c9995a"), true, 1.6)
			sk.fill(sk.ellipse_pts(Vector2(-3, -2.5), 5.0, 2.4, 8), Color("e2bf86"), false)
			for d in [Vector2(-5, 2), Vector2(2, -1), Vector2(6, 3), Vector2(-1, 4)]:
				sk.dot(d, 0.9, Color("6a4a22"))
			sk.line(PackedVector2Array([Vector2(6, -6), Vector2(8, -10), Vector2(11, -11)]), 1.2, FRIEND)
		M_ZIEGEL:
			# Brandmauer-Ziegel block: brick front face in mortar, concrete coping on
			# top; base at y = +6, 36 px wide so five blocks (35 px apart) form a wall.
			sk.lw = 1.8
			sk.misreg = 0.6
			sk.soft_shadow(Vector2(0, 7), 22.0, 4.5, 0.18)
			var mortar := Color("e3d6bf")
			var front := PackedVector2Array([Vector2(-18, -14), Vector2(18, -14), Vector2(18, 6), Vector2(-18, 6)])
			sk.fill(front, mortar, false)
			var rows := [[-14.0, -7.4, 0.0], [-7.4, -0.8, 6.0], [-0.8, 5.6, 0.0]]
			for row in rows:
				var y0: float = row[0]
				var y1: float = row[1]
				var off: float = row[2]
				var x := -18.0 - off
				var bi := 0
				while x < 18.0:
					var xa := maxf(x, -18.0) + 0.8
					var xb := minf(x + 12.0, 18.0) - 0.8
					if xb - xa > 1.5:
						var shade := BRICK.darkened(0.12) if (bi + int(off)) % 3 == 0 else (BRICK.lightened(0.08) if bi % 2 else BRICK)
						sk.fill(PackedVector2Array([Vector2(xa, y0 + 0.8), Vector2(xb, y0 + 0.8), Vector2(xb, y1 - 0.6), Vector2(xa, y1 - 0.6)]), shade, false)
					x += 12.0
					bi += 1
			sk.line(front, 1.8, INK, true)
			var cap := PackedVector2Array([Vector2(-19.5, -14), Vector2(19.5, -14), Vector2(18, -19.5), Vector2(-18, -19.5)])
			sk.shape(cap, Color("c4bcae"), true, 1.6)
			sk.line2(Vector2(-14, -17), Vector2(10, -17.4), 0.8, Color(1, 1, 1, 0.5))
		M_ZIEGEL_V:
			# The same wall piece seen end-on (wall running down the screen): the
			# brick tops along the wall, the brick end face at the near side. Ground
			# footprint y = -17.5..17.5 (one 35 px step), so consecutive pieces join.
			sk.lw = 1.8
			sk.misreg = 0.6
			sk.soft_shadow(Vector2(4, 4), 13.0, 18.0, 0.16)
			var mortar := Color("e3d6bf")
			var top := PackedVector2Array([Vector2(-8, -37.5), Vector2(8, -37.5), Vector2(8, -2.5), Vector2(-8, -2.5)])
			sk.fill(top, mortar, false)
			for col in 2:
				var x0 := -8.0 + col * 8.0
				var y := -37.5 - (5.5 if col == 1 else 0.0)
				var bi := 0
				while y < -2.5:
					var ya := maxf(y, -37.5) + 0.8
					var yb := minf(y + 11.0, -2.5) - 0.8
					if yb - ya > 1.5:
						var shade := BRICK.lightened(0.2) if (bi + col) % 3 else BRICK.lightened(0.08)
						sk.fill(PackedVector2Array([Vector2(x0 + 0.8, ya), Vector2(x0 + 7.2, ya), Vector2(x0 + 7.2, yb), Vector2(x0 + 0.8, yb)]), shade, false)
					y += 11.0
					bi += 1
			# shaded side and the end face
			sk.fill(PackedVector2Array([Vector2(8, -37.5), Vector2(10.5, -35), Vector2(10.5, 17.5), Vector2(8, 17.5)]), BRICK.darkened(0.35), false)
			var front := PackedVector2Array([Vector2(-8, -2.5), Vector2(8, -2.5), Vector2(8, 17.5), Vector2(-8, 17.5)])
			sk.fill(front, mortar, false)
			for row in 3:
				var y0 := -2.5 + row * 6.6
				var xs := [[-8.0, 8.0]] if row % 2 == 0 else [[-8.0, 0.0], [0.0, 8.0]]
				for seg in xs:
					var xa: float = seg[0] + 0.8
					var xb: float = seg[1] - 0.8
					sk.fill(PackedVector2Array([Vector2(xa, y0 + 0.8), Vector2(xb, y0 + 0.8), Vector2(xb, y0 + 6.0), Vector2(xa, y0 + 6.0)]),
						BRICK if row != 1 else BRICK.darkened(0.1), false)
			sk.line(PackedVector2Array([Vector2(-8, -2.5), Vector2(-8, -37.5), Vector2(8, -37.5), Vector2(10.5, -35), Vector2(10.5, 17.5),
				Vector2(-8, 17.5), Vector2(-8, -2.5), Vector2(8, -2.5), Vector2(8, 17.5)]), 1.8, INK)
			sk.line2(Vector2(8, -37.5), Vector2(8, -2.5), 1.2, INK)


## Paper texture: aged edges, grain specks and fibres.
## Everything is very low contrast so the play area stays calm.
func _b_paper_grain(sk: Doodle.Sketch) -> void:
	var rng := sk.rng
	var w := ARENA.x
	var h := ARENA.y
	var e := Color(0.5, 0.4, 0.25, 0.11)
	var z := Color(0.5, 0.4, 0.25, 0.0)
	var d := 60.0
	sk.grad_quad(Vector2(0, 0), Vector2(w, 0), Vector2(w, d), Vector2(0, d), e, z)
	sk.grad_quad(Vector2(0, h), Vector2(w, h), Vector2(w, h - d), Vector2(0, h - d), e, z)
	sk.grad_quad(Vector2(0, 0), Vector2(0, h), Vector2(d, h), Vector2(d, 0), e, z)
	sk.grad_quad(Vector2(w, 0), Vector2(w, h), Vector2(w - d, h), Vector2(w - d, 0), e, z)
	for i in 2660:   # same density as before over the larger inner arena
		var p := INNER.position + Vector2(rng.randf(), rng.randf()) * INNER.size
		var r := rng.randf_range(0.5, 1.3)
		var a := rng.randf_range(0.05, 0.13)
		var c := Color(0.42, 0.35, 0.25, a) if i % 4 else Color(1, 1, 1, a * 2.5)
		var ang := rng.randf() * TAU
		sk.tri(p + Vector2(cos(ang), sin(ang)) * r, p + Vector2(cos(ang + 2.1), sin(ang + 2.1)) * r,
			p + Vector2(cos(ang + 4.2), sin(ang + 4.2)) * r, sk.fc(c))
	var old_seg := sk.seg
	sk.seg = 30.0
	for i in 85:
		var p := INNER.position + Vector2(rng.randf(), rng.randf()) * INNER.size
		var a0 := rng.randf() * TAU
		var dir := Vector2(cos(a0), sin(a0))
		var ln := rng.randf_range(6, 16)
		sk.line(PackedVector2Array([p, p + dir * ln * 0.5 + dir.orthogonal() * 1.5, p + dir * ln]), 0.7, Color(0.4, 0.33, 0.25, 0.1))
	sk.seg = old_seg


## Maps a point of the old 1600 x 898 play area (y from 102) onto today's inner
## arena, so the paper doodles keep their places relative to the walls.
static func _ip(p: Vector2) -> Vector2:
	return INNER.position + (p - Vector2(0, 102)) * (INNER.size / Vector2(1600, 898))


static func _ipa(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_ip(p))
	return out


## Coffee ring: faint wash, uneven ring, an inner echo and a drip.
func _coffee_stain(sk: Doodle.Sketch, c: Vector2, r: float, k: float) -> void:
	var brown := Color(0.55, 0.35, 0.15)
	sk.fill(sk.ellipse_pts(c, r * 0.97, r * 0.93, 22), Color(0.62, 0.44, 0.22, 0.045 * k), false)
	sk.line(sk.ellipse_pts(c, r, r * 0.96, 22, 0.4, TAU * 0.86), 4.5 * k + 1.0, Color(brown, 0.13 * k))
	sk.line(sk.ellipse_pts(c, r * 1.01, r * 0.97, 22, 3.6, TAU * 0.35), 1.6, Color(brown, 0.12 * k))
	sk.line(sk.ellipse_pts(c + Vector2(2, 2), r * 0.88, r * 0.85, 20, 1.2, TAU * 0.55), 1.6, Color(brown, 0.1 * k))
	sk.fill(sk.ellipse_pts(c + Vector2(r * 0.78, r * 0.72), 4.0, 3.0, 8), Color(brown, 0.12 * k), false)
	sk.fill(sk.ellipse_pts(c + Vector2(r * 0.98, r * 0.86), 2.0, 1.6, 7), Color(brown, 0.12 * k), false)


## Faint biro doodles in the margins (left margin and the bottom strip).
func _margin_doodles(sk: Doodle.Sketch) -> void:
	var pen := Color(0.22, 0.25, 0.42, 0.2)
	# spiral
	var sp := PackedVector2Array()
	for i in 28:
		var a := i * 0.55
		sp.append(_ip(Vector2(36, 640)) + Vector2(cos(a), sin(a)) * (1.0 + i * 0.5))
	sk.line(sp, 1.3, pen)
	# sun
	var sun := _ip(Vector2(35, 200))
	sk.line(sk.ellipse_pts(sun, 7, 7, 10), 1.3, pen, true)
	for i in 8:
		var d := Vector2(cos(TAU * i / 8.0), sin(TAU * i / 8.0))
		sk.line2(sun + d * 10.0, sun + d * 15.0, 1.2, pen)
	# peace sign
	var pc := _ip(Vector2(36, 880))
	sk.line(sk.ellipse_pts(pc, 10, 10, 12), 1.3, pen, true)
	sk.line2(pc + Vector2(0, -10), pc + Vector2(0, 10), 1.2, pen)
	sk.line2(pc, pc + Vector2(-7, 7), 1.2, pen)
	sk.line2(pc, pc + Vector2(7, 7), 1.2, pen)
	# tiny bike
	var bc := _ip(Vector2(1440, 968))
	sk.line(sk.ellipse_pts(bc + Vector2(-12, 0), 7, 7, 10), 1.2, pen, true)
	sk.line(sk.ellipse_pts(bc + Vector2(12, 0), 7, 7, 10), 1.2, pen, true)
	sk.line(PackedVector2Array([bc + Vector2(-12, 0), bc + Vector2(-2, 0), bc + Vector2(-6, -9), bc + Vector2(7, -9),
		bc + Vector2(12, 0)]), 1.2, pen)
	sk.line2(bc + Vector2(-2, 0), bc + Vector2(7, -9), 1.2, pen)
	sk.line2(bc + Vector2(7, -9), bc + Vector2(6, -14), 1.2, pen)
	# cube
	var q := _ip(Vector2(230, 958))
	sk.line(PackedVector2Array([q, q + Vector2(16, 0), q + Vector2(16, 16), q + Vector2(0, 16)]), 1.2, pen, true)
	sk.line(PackedVector2Array([q, q + Vector2(7, -6), q + Vector2(23, -6), q + Vector2(16, 0)]), 1.2, pen)
	sk.line(PackedVector2Array([q + Vector2(23, -6), q + Vector2(23, 10), q + Vector2(16, 16)]), 1.2, pen)
	# hashtag + cloud
	var hs := _ip(Vector2(600, 966))
	sk.line2(hs + Vector2(-3, -8), hs + Vector2(-5, 8), 1.2, pen)
	sk.line2(hs + Vector2(4, -8), hs + Vector2(2, 8), 1.2, pen)
	sk.line2(hs + Vector2(-8, -3), hs + Vector2(8, -3), 1.2, pen)
	sk.line2(hs + Vector2(-9, 3), hs + Vector2(7, 3), 1.2, pen)
	var cl := _ip(Vector2(1180, 968))
	sk.line(PackedVector2Array([cl + Vector2(-18, 6), cl + Vector2(-20, -2), cl + Vector2(-10, -6), cl + Vector2(-4, -13),
		cl + Vector2(7, -10), cl + Vector2(12, -4), cl + Vector2(20, 0), cl + Vector2(16, 6)]), 1.2, pen, true)


## One Brandmauer segment: concrete coping, staggered bricks in mortar,
## occasional cracks and spray doodles, and a soft shadow on the paper below.
func _b_wall(sk: Doodle.Sketch, seg: int) -> void:
	sk.jit = 0.45
	sk.misreg = 0.35
	var w := Arena.seg_len(seg)   # baked in the top wall's frame, rotated onto its side when drawn
	sk.fill(PackedVector2Array([Vector2(0, WALL_TOP), Vector2(w, WALL_TOP), Vector2(w, WALL_BOTTOM), Vector2(0, WALL_BOTTOM)]),
		Color("cdbd9f"), false)
	var cap := 5.0
	sk.fill(PackedVector2Array([Vector2(-1, WALL_TOP), Vector2(w + 1, WALL_TOP), Vector2(w + 1, WALL_TOP + cap), Vector2(-1, WALL_TOP + cap)]),
		Color("a39e94"), false)
	sk.line2(Vector2(0, WALL_TOP + cap), Vector2(w, WALL_TOP + cap), 1.0, Color(0.25, 0.22, 0.2, 0.6))
	for x in [w * 0.33, w * 0.71]:
		sk.line2(Vector2(x, WALL_TOP + 0.5), Vector2(x + 0.5, WALL_TOP + cap), 0.8, Color(0.3, 0.28, 0.25, 0.5))
	var top := WALL_TOP + cap + 0.4
	var rows := 3
	var rh := (WALL_BOTTOM - top) / rows
	var pal := [BRICK, Color("c27052"), Color("a35844"), Color("b8694c"), Color("9a5040"), Color("c9785a")]
	for r in rows:
		var yy := top + r * rh
		var bx := -12.0 if (r + seg) % 2 else -1.0
		while bx < w:
			var x0 := maxf(bx + 0.9, 0.0)
			var x1 := minf(bx + 21.1, w)
			if x1 - x0 > 2.0:
				var c: Color = pal[sk.rng.randi() % pal.size()]
				sk.fill(PackedVector2Array([Vector2(x0, yy + 0.7), Vector2(x1, yy + 0.7), Vector2(x1, yy + rh - 0.5), Vector2(x0, yy + rh - 0.5)]), c)
				if sk.rng.randf() < 0.55:
					sk._seg(Vector2(x0 + 1.2, yy + 1.5), Vector2(x1 - 2.5, yy + 1.5), 0.8, sk.fc(c.lightened(0.2)))
			bx += 22.0
	if sk.rng.randf() < 0.5:
		var cx := sk.rng.randf_range(20, w - 20)
		sk.line(PackedVector2Array([Vector2(cx, top), Vector2(cx + 3, top + 6), Vector2(cx - 1, top + 11), Vector2(cx + 2, top + 17)]),
			0.9, Color(0.2, 0.12, 0.1, 0.8))
	match {3: 3, 7: 7, 11: 11, 14: 11, 24: 3, 29: 7, 36: 3}.get(seg, -1):
		3:
			var hc := Vector2(w * 0.5, 91)
			sk.shape(PackedVector2Array([hc + Vector2(0, 7), hc + Vector2(-8, -1), hc + Vector2(-6, -6), hc + Vector2(-2, -6),
				hc + Vector2(0, -3), hc + Vector2(2, -6), hc + Vector2(6, -6), hc + Vector2(8, -1)]), Color("ff6fa8"), true, 1.2)
		7:
			sk.shape(sk.star_pts(Vector2(w * 0.4, 91), 8.0, 3.6, 5), Color("f2c418"), true, 1.2)
			sk.line(PackedVector2Array([Vector2(w * 0.55, 95), Vector2(w * 0.62, 87), Vector2(w * 0.68, 95), Vector2(w * 0.75, 87)]),
				2.0, Color("7ad0f0"))
		11:
			sk.line(PackedVector2Array([Vector2(w * 0.3, 96), Vector2(w * 0.36, 86), Vector2(w * 0.42, 95), Vector2(w * 0.5, 85),
				Vector2(w * 0.56, 96), Vector2(w * 0.66, 88)]), 2.2, Color("8fe08a"))
	sk.line(PackedVector2Array([Vector2(-1, WALL_TOP), Vector2(w + 1, WALL_TOP)]), 3.0)
	sk.line(PackedVector2Array([Vector2(-1, WALL_BOTTOM), Vector2(w + 1, WALL_BOTTOM)]), 3.0)
	var sh := Color(0.2, 0.15, 0.1, 0.17)
	sk.grad_quad(Vector2(0, WALL_BOTTOM + 1), Vector2(w, WALL_BOTTOM + 1), Vector2(w, WALL_BOTTOM + 14), Vector2(0, WALL_BOTTOM + 14),
		sh, Color(sh, 0.0))


## A voted-away segment of length w (same frame as _b_wall): a dusty gap with
## broken bricks at both ends and a few crumbs.
func _b_rubble(sk: Doodle.Sketch, w: float) -> void:
	sk.jit = 0.8
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


## Corner pillar, centred at 0 (drawn rotated so -x/-y face out of the arena):
## a concrete block with the coping on its outer edges and a shadow inside.
func _b_pillar(sk: Doodle.Sketch) -> void:
	sk.jit = 0.4
	sk.misreg = 0.3
	var h := Arena.WALL_THICK * 0.5 + 1.0
	var sh := Color(0.2, 0.15, 0.1, 0.17)
	sk.grad_quad(Vector2(h, -h), Vector2(h + 13, -h), Vector2(h + 13, h + 13), Vector2(h, h), sh, Color(sh, 0.0))
	sk.grad_quad(Vector2(-h, h), Vector2(h, h), Vector2(h + 13, h + 13), Vector2(-h, h + 13), sh, Color(sh, 0.0))
	sk.shape(PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]), Color("b9b2a6"), true, 2.6)
	sk.fill(PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h - 5, -h + 5), Vector2(-h + 5, -h + 5)]), Color("a39e94"), false)
	sk.fill(PackedVector2Array([Vector2(-h, -h), Vector2(-h + 5, -h + 5), Vector2(-h + 5, h - 5), Vector2(-h, h)]), Color("a39e94"), false)
	sk.line(PackedVector2Array([Vector2(-h + 5, h - 5), Vector2(-h + 5, -h + 5), Vector2(h - 5, -h + 5)]), 1.0, Color(0.25, 0.22, 0.2, 0.6))
	sk.line2(Vector2(-3, 2), Vector2(4, -3), 0.8, Color(0.3, 0.28, 0.25, 0.5))


# --- Lastenrad ---------------------------------------------------------------------------

## A bike wheel centred at c: tyre, rim, spokes, hub (rotated as a whole when drawn).
func _b_wheel(sk: Doodle.Sketch, c: Vector2, r: float) -> void:
	var old_jit := sk.jit
	sk.jit = 0.3
	var n := 8 if r > 7.0 else 6
	for i in n:
		var a := TAU * i / n + 0.2
		sk.line2(c, c + Vector2(cos(a), sin(a)) * (r - 1.6), 0.75, Color("5a5f68"))
	sk.line(sk.ellipse_pts(c, r - 2.0, r - 2.0, 14), 0.9, Color("9aa0a8"), true)
	sk.jit = 0.45
	sk.line(sk.ellipse_pts(c, r, r, 16), 2.7, Color("232326"), true)
	sk.circle(c, 1.6, Color("c0c4ca"), true, 0.9)
	sk.jit = old_jit


## Rider posture per Zusammenhalt stage: hunched with coffee, neutral, racing
## tuck, cheerful, upright with a raised fist.
func _bike_posture(st: int) -> Dictionary:
	match st:
		0: return {"lean": 4.5, "head_drop": 2.2, "arms": "bars_mug", "eyes": "tired", "mouth": "o", "brows": "worried"}
		1: return {"lean": 3.0, "arms": "bars", "eyes": "roll", "mouth": "flat", "brows": ""}
		2: return {"lean": 4.5, "head_drop": 0.8, "arms": "bars", "eyes": "angry", "mouth": "grit", "brows": "angry"}
		3: return {"lean": 2.5, "arms": "bars", "eyes": "dots", "mouth": "smile", "brows": "thick"}
		_: return {"lean": 0.5, "arms": "bars_fist", "eyes": "closed", "mouth": "grin", "brows": "raised"}


func _bike_crank(sk: Doodle.Sketch, phi: float) -> Vector2:
	var p := BIKE_BB + Vector2(cos(phi), sin(phi)) * BIKE_CRANK
	sk.line2(BIKE_BB, p, 1.7, Color("3a3a40"))
	sk.line2(p + Vector2(-1.9, 0), p + Vector2(1.9, 0), 2.1, INK)
	return p


## Two-bone leg from hip to pedal, knee bending forward.
func _bike_leg(sk: Doodle.Sketch, hip: Vector2, foot: Vector2, pants: Color, shoe: Color) -> void:
	var l1 := 9.0
	var l2 := 9.6
	var d := hip.distance_to(foot)
	var dir := (foot - hip) / maxf(d, 0.001)
	var dd := clampf(d, 2.0, l1 + l2 - 0.2)
	var a := (l1 * l1 - l2 * l2 + dd * dd) / (2.0 * dd)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var knee := hip + dir * a + dir.orthogonal() * h
	var f := hip + dir * dd
	sk.stroke(hip, knee, 3.5, pants)
	sk.stroke(knee, f, 3.1, pants)
	sk.line2(f + Vector2(-1.8, 0.2), f + Vector2(3.4, 0.5), 2.9, shoe)


## Wooden cargo box with a potted sunflower, a jute bag and a baguette;
## from stage 3 a little banner is tied to its front.
func _bike_box(sk: Doodle.Sketch, st: int) -> void:
	var leaf := Color("4f9a3a")
	sk.line2(Vector2(11, 4), Vector2(10, -12), 1.7, leaf)
	sk.shape(PackedVector2Array([Vector2(10.5, -5), Vector2(4.5, -8.5), Vector2(6, -5.5), Vector2(10, -3.5)]), leaf, true, 1.0)
	sk.shape(PackedVector2Array([Vector2(10.5, -8), Vector2(16, -11.5), Vector2(14.5, -8), Vector2(11, -6.5)]), leaf, true, 1.0)
	sk.shape(sk.star_pts(Vector2(10, -15.5), 6.2, 3.6, 9, 0.1), Color("f2c418"), true, 1.1)
	sk.circle(Vector2(10, -15.5), 2.5, Color("6a4022"), true, 0.8)
	sk.stroke(Vector2(19.5, 3), Vector2(23.5, -9), 3.0, Color("e0b070"))
	sk.line2(Vector2(21.6, -5.5), Vector2(23.2, -4.8), 0.7, Color("9a6a30"))
	sk.line2(Vector2(22.4, -7.8), Vector2(24.0, -7.1), 0.7, Color("9a6a30"))
	sk.line(PackedVector2Array([Vector2(14, -3), Vector2(15.5, -7.5), Vector2(18.5, -7.5), Vector2(20, -3.5)]), 1.0)
	sk.shape(PackedVector2Array([Vector2(12.5, -3), Vector2(21, -4), Vector2(21.5, 4), Vector2(12, 4)]), Color("d8c79a"), true, 1.2)
	var box := PackedVector2Array([Vector2(5.5, -1), Vector2(24.5, -2), Vector2(23.5, 15.5), Vector2(6.5, 15.5)])
	sk.shape(box, WOOD, true, 1.9)
	var plank := Color("8a5a35")
	sk.line2(Vector2(6.5, 4.5), Vector2(24, 4), 0.9, plank)
	sk.line2(Vector2(6.5, 10), Vector2(23.8, 9.8), 0.9, plank)
	sk.line2(Vector2(8.5, -0.8), Vector2(9, 15), 1.1, plank)
	sk.line2(Vector2(21.8, -1.6), Vector2(21.2, 15), 1.1, plank)
	sk.line2(Vector2(5.2, -1.3), Vector2(24.8, -2.3), 2.0, Color("7a4a26"))
	if st >= 3:
		var ban := PackedVector2Array([Vector2(7.5, 2.2), Vector2(23, 1.6), Vector2(22.5, 10.5), Vector2(8, 11)])
		sk.shape(ban, WHITE, true, 1.1)
		sk.line(PackedVector2Array([Vector2(9.5, 5), Vector2(12, 4), Vector2(14.5, 5.5), Vector2(17, 4), Vector2(20.5, 5)]), 1.3, Color("3f8f4f"))
		sk.line(PackedVector2Array([Vector2(10, 8.3), Vector2(15, 8), Vector2(19.5, 8.4)]), 1.0, Color("e8443a"))
	else:
		sk.circle(Vector2(15, 7), 2.8, Color("f2c418"), true, 0.8)
		sk.dot(Vector2(15, 7), 1.1, Color("6a4022"))


## The Lastenrad body for one pedal phase (wheels are drawn separately).
## `full` adds the ground shadow (not on ghost riders).
func _b_bike(sk: Doodle.Sketch, st: int, fr: int, full: bool) -> void:
	var s := 0.95
	var phi := TAU * float(fr) / BIKE_FRAMES
	var pants := Color("3a4a3a")
	var shoe := Color("6a4a2a")
	var frame := BIKE_BLUE
	var steel := Color("3a3a40")
	sk.lw = 1.9
	if full:
		sk.soft_shadow(Vector2(1, 22), 40.0, 6.0)
		sk.line(PackedVector2Array([Vector2(-26, 22), Vector2(-14, 23), Vector2(0, 21.5), Vector2(14, 23), Vector2(28, 22)]), 1.0,
			Color(0.2, 0.2, 0.2, 0.2))
	# far leg + crank behind the frame
	var pf := _bike_crank(sk, phi + PI)
	_bike_leg(sk, BIKE_HIP + Vector2(1.5, 0.5), pf, pants.darkened(0.35), shoe.darkened(0.3))
	# mudguards
	sk.line(sk.ellipse_pts(BIKE_RW, BIKE_RW_R + 2.3, BIKE_RW_R + 2.3, 12, PI * 1.02, PI * 0.72), 1.8, frame)
	sk.line(sk.ellipse_pts(BIKE_FW, BIKE_FW_R + 2.0, BIKE_FW_R + 2.0, 10, PI * 1.35, PI * 0.6), 1.6, frame)
	# frame
	var seat := Vector2(-17, 2)
	var ht_top := Vector2(3, -4)
	var ht_bot := Vector2(5, 6)
	var tw := 2.3
	sk.stroke(BIKE_RW, BIKE_BB, tw, frame)
	sk.stroke(BIKE_RW, seat + Vector2(1.5, 1.5), tw, frame)
	sk.stroke(BIKE_BB, seat, tw, frame)
	sk.stroke(seat + Vector2(1.5, 2.5), ht_top + Vector2(0.4, 3.0), tw, frame)
	sk.stroke(BIKE_BB, ht_bot, tw + 0.4, frame)
	sk.stroke(ht_bot, Vector2(8, 16.5), tw + 0.4, frame)
	sk.stroke(Vector2(8, 16.5), BIKE_FW, tw + 0.4, frame)
	# rear rack, chain, chainring, saddle
	var rack := Color("6a6f78")
	sk.line2(Vector2(-33, 2.5), Vector2(-20, 2.5), 1.2, rack)
	sk.line2(Vector2(-32, 2.5), BIKE_RW + Vector2(-1, -1), 0.9, rack)
	sk.line2(BIKE_BB + Vector2(0, -3), BIKE_RW + Vector2(0, -2), 0.8, Color("4a4a50"))
	sk.line2(BIKE_BB + Vector2(0, 3), BIKE_RW + Vector2(0, 2), 0.8, Color("4a4a50"))
	sk.circle(BIKE_BB, 3.2, Color("b8bec6"), true, 1.1)
	sk.shape(PackedVector2Array([seat + Vector2(-4, -1.2), seat + Vector2(3, -1.6), seat + Vector2(3.5, 0), seat + Vector2(-3.5, 0.5)]),
		Color("6a4028"), true, 1.0)
	if st >= 4:
		# pennant on a whippy pole from the rack
		sk.line(PackedVector2Array([Vector2(-32, 2.5), Vector2(-34, -12), Vector2(-36.5, -27)]), 1.1, steel)
		sk.shape(PackedVector2Array([Vector2(-36.5, -27), Vector2(-23, -23.5), Vector2(-35.5, -18.5)]), Color("6ccf5a"), true, 1.1)
		sk.dot(Vector2(-32, -23), 1.4, Color("f2c418"))
	_bike_box(sk, st)
	# head tube, stem, handlebar, bell
	sk.stroke(ht_bot, ht_top, tw + 0.6, frame)
	sk.line2(ht_top, ht_top + Vector2(-0.5, -4.5), 1.8, steel)
	sk.line2(ht_top + Vector2(-0.5, -4.5), BIKE_GRIP + Vector2(-1.5, 0), 2.0, steel)
	sk.dot(ht_top + Vector2(1.0, -3.0), 1.4, GOLD)
	# rider (legs drawn here, not by _person)
	var o := {"x": BIKE_HIP.x, "y": BIKE_HIP.y + 12.0 * s, "s": s, "legs": "none", "body": Color("6aa84f"), "pants": pants,
		"hair": "short", "hair_c": Color("c8a868"), "hat": "helmet", "hat_c": Color("2e6db4"), "wb": 5.8, "wt": 6.8,
		"grip": BIKE_GRIP,
		"deco": func(k: Doodle.Sketch, a: Dictionary):
			var t: PackedVector2Array = a["torso"]
			var y := lerpf(t[0].y, t[3].y, 0.45)
			k.line2(Vector2(t[0].x + 0.5, y), Vector2(t[1].x - 0.5, y), 1.6, Color("f4f4b0"))
			k.dot(a["chest"] + Vector2(2.5, -3.5), 1.3, Color("f2c418"))}
	o.merge(_bike_posture(st), true)
	var a := _person(sk, o)
	if st == 0:
		_stage_props(sk, a, 0, s)
	# near leg + crank in front
	var pn := _bike_crank(sk, phi)
	_bike_leg(sk, BIKE_HIP, pn, pants, shoe)


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
		"lastenrad":
			# static composite (downed / away / previews); riding uses K_BIKE + K_WHEEL
			_b_wheel(sk, BIKE_RW, BIKE_RW_R)
			_b_wheel(sk, BIKE_FW, BIKE_FW_R)
			_b_bike(sk, st, 1, true)
			return
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
		"kartoffelbrei":
			# bowl of mash with a wooden spoon in it
			sk.line2(Vector2(-2, -1), Vector2(-10, -11), 2.2, Color("b07a40"))
			sk.ellipse(Vector2(-10.5, -11.5), 2.0, 2.8, Color("b07a40"), true, 0.8)
			sk.shape(sk.ellipse_pts(Vector2(0, -1), 8.0, 5.5, 10, PI, PI), MASH, true, 1.3)
			sk.shape(PackedVector2Array([Vector2(-9, -1), Vector2(9, -1), Vector2(6, 6), Vector2(-6, 6)]), Color("4f86c6"), true, 1.5)
			sk.line2(Vector2(-7, 1.5), Vector2(7, 1.5), 1.0, WHITE)
			sk.shape(PackedVector2Array([Vector2(1, -5), Vector2(4, -5.5), Vector2(4.5, -3), Vector2(1.5, -2.8)]), Color("f7d23a"), true, 0.7)
		"trillerpfeife":
			# referee whistle on a lanyard
			sk.line(PackedVector2Array([Vector2(-7, -2), Vector2(-11, -7), Vector2(-14, -2), Vector2(-11, 4), Vector2(-7, 2)]), 1.0, Color("2e6db4"))
			sk.shape(PackedVector2Array([Vector2(-1, -2.5), Vector2(10, -2.5), Vector2(10, 1.5), Vector2(3, 1.5)]), Color("e8742a"), true, 1.3)
			sk.circle(Vector2(-2, 1.5), 5.5, Color("e8742a"), true, 1.5)
			sk.dot(Vector2(-2, 1.5), 1.6, INK)
			sk.line2(Vector2(5, -2.5), Vector2(7, -0.5), 1.0, INK)
			sk.circle(Vector2(-7.2, -1.5), 1.3, Color("c0c4ca"), true, 0.7)
		"brandmauer_ziegel":
			# one brick with a trowel
			sk.shape(PackedVector2Array([Vector2(-9, -4), Vector2(7, -4), Vector2(7, 5), Vector2(-9, 5)]), BRICK, true, 1.5)
			sk.shape(PackedVector2Array([Vector2(-9, -4), Vector2(7, -4), Vector2(10, -7), Vector2(-6, -7)]), BRICK.lightened(0.18), true, 1.2)
			sk.shape(PackedVector2Array([Vector2(7, -4), Vector2(10, -7), Vector2(10, 2), Vector2(7, 5)]), BRICK.darkened(0.2), true, 1.2)
			sk.line2(Vector2(-7, 0.5), Vector2(5, 0.5), 0.8, Color("e3d6bf"))
			sk.shape(PackedVector2Array([Vector2(2, -9), Vector2(10, -13), Vector2(13, -9), Vector2(5, -6)]), Color("c0c4ca"), true, 1.0)
			sk.line2(Vector2(10, -13), Vector2(13, -17), 1.8, Color("8a5a35"))
		"normenkontrolle":
			# rubber stamp, red ink, a little "§" scribble on its side
			sk.shape(PackedVector2Array([Vector2(-8, 3), Vector2(8, 3), Vector2(8, 7), Vector2(-8, 7)]), STAMP_RED, true, 1.3)
			sk.rect(Rect2(-6, -1, 12, 4), Color("8a5a35"), true, 1.2)
			sk.stroke(Vector2(0, -1), Vector2(0, -7), 2.6, Color("8a5a35"))
			sk.circle(Vector2(0, -9.5), 3.6, Color("a8703f"), true, 1.2)
			sk.line(PackedVector2Array([Vector2(1.5, 0), Vector2(0, -0.6), Vector2(-1.2, 0.4), Vector2(1.2, 1.6), Vector2(0, 2.6), Vector2(-1.5, 2.0)]), 0.8, WHITE)
		"unterschriftenliste":
			# a signature sheet full of blue signatures and a ballpoint pen
			sk.shape(PackedVector2Array([Vector2(-8, -9), Vector2(6, -10), Vector2(7, 9), Vector2(-7, 10)]), WHITE, true, 1.3)
			for i in 4:
				var y := -6.0 + i * 4.2
				sk.line2(Vector2(-6, y + 1.2), Vector2(5, y + 1.0), 0.6, Color(0.6, 0.6, 0.65))
				sk.line(PackedVector2Array([Vector2(-5, y + 1), Vector2(-3, y - 1), Vector2(-2, y + 1), Vector2(0, y - 0.8), Vector2(2.5, y + 0.6)]), 0.8, BIC)
			sk.stroke(Vector2(2, 9), Vector2(12, -5), 2.4, BIC)
			sk.line2(Vector2(1.5, 9.5), Vector2(0.6, 11.4), 1.0, INK)
		"scheinwerfer":
			# spotlight: dark drum, bright lens, a short light cone
			sk.fill(PackedVector2Array([Vector2(8, -4), Vector2(15, -7), Vector2(15, 7), Vector2(8, 4)]), Color(1.0, 0.95, 0.6, 0.45), false)
			sk.shape(PackedVector2Array([Vector2(-7, -5), Vector2(5, -6), Vector2(7, 0), Vector2(5, 6), Vector2(-7, 5)]), Color("3a3d45"), true, 1.5)
			sk.ellipse(Vector2(6.5, 0), 2.3, 5.5, Color("fff6c2"), true, 1.2)
			sk.line2(Vector2(-3.5, -5), Vector2(-3.5, 5), 0.8, Color(0.6, 0.62, 0.68))
			sk.line2(Vector2(-5, 5), Vector2(-6, 9), 1.8, INK)
			sk.line2(Vector2(-9, 9), Vector2(-3, 9), 1.8, INK)
		"neun_euro_ticket":
			# two fanned tickets
			for k in 2:
				var o := Vector2(-2.0 + k * 3.0, -2.0 + k * 3.5)
				var rot := -0.25 + k * 0.3
				var corners := [Vector2(-9, -5.5), Vector2(9, -5.5), Vector2(9, 5.5), Vector2(-9, 5.5)]
				var card := PackedVector2Array()
				for c in corners:
					card.append(o + (c as Vector2).rotated(rot))
				sk.shape(card, Color("fbf6e6"), true, 1.3)
				var band := PackedVector2Array()
				for c in [Vector2(-8.4, -4.9), Vector2(-3.5, -4.9), Vector2(-3.5, 4.9), Vector2(-8.4, 4.9)]:
					band.append(o + (c as Vector2).rotated(rot))
				sk.fill(band, Color("d8262e"), false)
				sk.line2(o + Vector2(-1, -1.5).rotated(rot), o + Vector2(6, -1.5).rotated(rot), 0.8, INK)
				sk.line2(o + Vector2(-1, 1.8).rotated(rot), o + Vector2(4, 1.8).rotated(rot), 0.8, Color("2e6db4"))
		"weisser_overall":
			# a white overall with hood, zip and green boots
			var suit := PackedVector2Array([Vector2(-6, -7), Vector2(6, -7), Vector2(11, 2), Vector2(8, 3), Vector2(5, -2),
				Vector2(5, 10), Vector2(1, 10), Vector2(0, 4), Vector2(-1, 10), Vector2(-5, 10), Vector2(-5, -2), Vector2(-8, 3),
				Vector2(-11, 2)])
			sk.shape(suit, Color("f6f5ef"), true, 1.4)
			sk.shape(sk.ellipse_pts(Vector2(0, -9.5), 4.6, 4.0, 10), Color("ecebe4"), true, 1.2)
			sk.ellipse(Vector2(0.6, -9.0), 2.6, 2.4, FACE, false)
			sk.line2(Vector2(0, -6), Vector2(0, 4), 0.7, Color(0.55, 0.55, 0.58))
			sk.line2(Vector2(-5.5, 10.5), Vector2(-1, 10.5), 2.0, Color("3f8f4f"))
			sk.line2(Vector2(1, 10.5), Vector2(5.5, 10.5), 2.0, Color("3f8f4f"))
		"fahnenstange":
			# long pole with a red demo flag at the far end
			sk.line2(Vector2(-14, 2), Vector2(14, 2), 1.8, Color("8a5a35"))
			sk.shape(PackedVector2Array([Vector2(6, 1), Vector2(15, -1), Vector2(14, -9), Vector2(5, -8)]), Color("d8262e"), true, 1.2)
			sk.line2(Vector2(7.5, -5.5), Vector2(12.5, -6), 0.8, WHITE)
			sk.circle(Vector2(14.5, 2), 1.4, GOLD, true, 0.6)
		"bierkiste":
			# Späti beer crate with bottle necks sticking out
			for k in 3:
				var x := -6.0 + k * 6.0
				sk.rect(Rect2(x - 1.6, -10, 3.2, 5), Color("6a4a20"), true, 0.8)
				sk.rect(Rect2(x - 1.2, -11.5, 2.4, 1.8), GOLD, true, 0.6)
			sk.shape(PackedVector2Array([Vector2(-10, -5), Vector2(10, -5), Vector2(10, 8), Vector2(-10, 8)]), Color("2f7a3c"), true, 1.5)
			sk.rect(Rect2(-5, -2, 10, 3.5), Color("1f5a2a"), true, 0.8)
			sk.line2(Vector2(-10, 4), Vector2(10, 4), 0.8, Color("1f5a2a"))
		"strassenkreide":
			# two sticks of chalk, pink and blue, with a little scribble
			sk.line(PackedVector2Array([Vector2(-12, 7), Vector2(-8, 4), Vector2(-5, 7), Vector2(-1, 4)]), 1.2, Color("f28fb1"))
			sk.shape(PackedVector2Array([Vector2(-6, -3), Vector2(7, -8), Vector2(9, -4), Vector2(-4, 1)]), Color("f28fb1"), true, 1.2)
			sk.shape(PackedVector2Array([Vector2(-3, 3), Vector2(10, 0), Vector2(11, 4), Vector2(-2, 7)]), Color("8fc8f2"), true, 1.2)
		"kleine_anfrage":
			_b_proj(sk, "akte")
		"lobbyregister":
			# a Leitz folder: grey spine with the ring and label, red-brown cover
			sk.shape(PackedVector2Array([Vector2(-6, -10), Vector2(7, -10), Vector2(7, 10), Vector2(-6, 10)]), Color("8a3a2e"), true, 1.4)
			sk.rect(Rect2(-6, -10, 5, 20), Color("6a6e78"), true, 1.2)
			sk.rect(Rect2(-5.5, -6, 4, 6), WHITE, true, 0.8)
			sk.circle(Vector2(-3.5, 5), 1.8, Color("d8d8d8"), true, 0.8)
			sk.line2(Vector2(1, -6), Vector2(5, -6), 0.8, Color(1, 1, 1, 0.6))
		"faktencheck":
			# a magnifying glass over a green tick
			sk.line2(Vector2(3, 3), Vector2(10, 10), 2.6, Color("8a5a35"))
			sk.circle(Vector2(-2, -2), 7.0, Color("dff1fa"), true, 1.8)
			sk.line(PackedVector2Array([Vector2(-6, -2), Vector2(-3, 1.5), Vector2(2.5, -5)]), 1.8, Color("2f9a4c"))
		"soli_sticker":
			_b_proj(sk, "sticker")
			sk.circle(Vector2(6, -6), 4.0, Color("8fc8f2"), true, 1.0)
		"menschenkette":
			# three little people holding hands
			for k in 3:
				var x := -9.0 + k * 9.0
				sk.circle(Vector2(x, -6), 2.6, FACE, true, 0.9)
				sk.stroke(Vector2(x, -3), Vector2(x, 4), 3.0, [Color("d63a2e"), Color("2e6db4"), Color("f2c418")][k])
				sk.line2(Vector2(x, 4), Vector2(x - 1.5, 9), 1.2, INK)
				sk.line2(Vector2(x, 4), Vector2(x + 1.5, 9), 1.2, INK)
			sk.line2(Vector2(-13, -1), Vector2(13, -1), 1.2, INK)
		"pappkamerad":
			# a cardboard sign with a crossed-out schnitzel
			sk.line2(Vector2(0, 2), Vector2(0, 11), 1.8, Color("8a6a3a"))
			sk.rect(Rect2(-8, -10, 16, 13), Color("c9a36b"), true, 1.4)
			sk.ellipse(Vector2(0, -3.5), 4.0, 2.6, Color("d9a24a"), true, 0.8)
			sk.line(sk.ellipse_pts(Vector2(0, -3.5), 5.5, 5.5, 12), 1.4, Color("d8262e"), true)
			sk.line2(Vector2(-4, -7.5), Vector2(4, 0.5), 1.4, Color("d8262e"))
		"demo_sanis":
			# a green first-aid bag with a white cross
			sk.rect(Rect2(-9, -5, 18, 12), Color("2f9a4c"), true, 1.5)
			sk.line(PackedVector2Array([Vector2(-4, -5), Vector2(-4, -8), Vector2(4, -8), Vector2(4, -5)]), 1.4, INK)
			sk.fill(PackedVector2Array([Vector2(-1.2, -2.5), Vector2(1.2, -2.5), Vector2(1.2, 4.5), Vector2(-1.2, 4.5)]), WHITE, false)
			sk.fill(PackedVector2Array([Vector2(-4, -0.2), Vector2(4, -0.2), Vector2(4, 2.2), Vector2(-4, 2.2)]), WHITE, false)
		"lauti":
			# a horn loudspeaker with a note
			sk.shape(PackedVector2Array([Vector2(-8, -3), Vector2(-2, -3), Vector2(8, -9), Vector2(8, 9), Vector2(-2, 3), Vector2(-8, 3)]), Color("c0c4ca"), true, 1.4)
			sk.rect(Rect2(-11, -3, 3, 6), Color("e8742a"), true, 1.0)
			sk.circle(Vector2(12, -8), 2.0, INK, false)
			sk.dot(Vector2(12, -8), 2.0, INK)
			sk.line2(Vector2(13.8, -8), Vector2(13.8, -15), 1.2, INK)
		_:
			sk.circle(Vector2.ZERO, 4, GOLD)
