class_name Hud
extends Control
## In-run HUD and screen-space overlays, drawn by hand in _draw (Doodle style).
##
## Panels: Solidarität (HP), Pfand/Aktien, Sitzungswoche + timer (wave 20:
## "Koalitionsverhandlungen", counting up 3x slower than real time), Zusammenhalt,
## Brandmauer holes, co-op team, boss bar, Streik prompt, Koalitionsvertrag,
## the local ultimate (bottom left) and global ultimate effects with countdowns.
## Overlays from events: encounter card, Wende, Streik stamp, stage banner,
## level-up, wave start/end, achievement and deny toasts, run over.
## Funkloch easter egg: every 3–4 min the HUD loses its signal for 2 s.

const INK := Color("222222")
const PAPER := Color("f4efe1")
const CARD := Color("fbf6e6")
const RED := Color("c0392b")
const GREEN := Color("3f8f4f")
const GOLD := Color("e8b923")
const ULT_POP_MAX := 1.3            # the ult panel grows up to this when it becomes ready (pivot bottom left)
const BOSS_BAR_MIN_W := 380.0      # narrower than this beside the ult panel: the boss bar goes above it
const BLUE := Color("2e6db4")
const SLOT_COLORS := [Color("c0392b"), Color("2e6db4"), Color("3f8f4f"), Color("8e44ad")]
const CARD_TIME := 4.2
const FUNKLOCH_TIME := 2.0

var source_view: ViewState = null
var source_meta = null
var local_id_override := -1
var world: WorldView

## Freeze the overlay clock for screenshots (preview harness).
var preview_overlay_t := -1.0
## Preview harness: >= 0 forces the reconnect indicator with this many seconds left.
var preview_reconnect_left := -1.0

var _hand: Font
var _type: Font
var _typeb: Font
var _t := 0.0
var _overlays: Array = []    # {kind, t, life, data}
var _presse := {}            # last boss_phase: {enc, phase, t0} (D-158)
var _toasts: Array = []      # {text, sub, t, life, kind}
var _koal_time := 0.0
var _funk_next := 0.0
var _funk_t := -1.0
var _flicker := {}
var _last_xp := 0.0
var _rng := RandomNumberGenerator.new()
var _ult_ready_prev := false
var _ult_pop := -1.0         # seconds since the local ultimate became ready (pop)
var _ult_fire := -1.0        # seconds since the local player fired it (squash)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_hand = UITheme.hand()
	_type = UITheme.typewriter()
	_typeb = UITheme.typewriter(true)
	_rng.randomize()
	_funk_next = _rng.randf_range(180.0, 240.0)


# --- Data ------------------------------------------------------------------------

func get_view() -> ViewState:
	if source_view != null:
		return source_view
	if world:
		return world.get_view()
	var g := WorldView.game_node()
	var v = g.get("view") if g else null
	return v if v is ViewState else null


func get_meta_dict() -> Dictionary:
	if source_meta is Dictionary:
		return source_meta
	var g := WorldView.game_node()
	if g:
		var m = g.get("meta")
		if m is Dictionary:
			return m
	return {}


func local_id() -> int:
	if local_id_override >= 0:
		return local_id_override
	if world:
		return world.local_id()
	return 1


func _local_meta(meta: Dictionary) -> Dictionary:
	return _player_meta(meta, local_id())


func _player_meta(meta: Dictionary, id: int) -> Dictionary:
	var ps = meta.get("players", {})
	if ps is Dictionary:
		if ps.has(id):
			return ps[id]
		if ps.has(str(id)):
			return ps[str(id)]
	return {}


## Client lost the host and reconnects in the background (Net, networking.md §7.4).
## Never true in solo or on the host.
func _reconnecting() -> bool:
	if preview_reconnect_left >= 0.0:
		return true
	var net := get_node_or_null("/root/Net")
	return net != null and net.has_method("is_reconnecting") and bool(net.call("is_reconnecting"))


func _reconnect_left() -> float:
	if preview_reconnect_left >= 0.0:
		return preview_reconnect_left
	var net := get_node_or_null("/root/Net")
	return float(net.call("reconnect_time_left")) if net != null and net.has_method("reconnect_time_left") else 0.0


# --- Events -------------------------------------------------------------------------

func handle_event(ev: Array) -> void:
	if ev.is_empty():
		return
	match str(ev[0]):
		"card":
			_overlay("card", CARD_TIME, {"enc": str(ev[1]) if ev.size() > 1 else ""})
		"wende":
			_overlay("wende", 2.6, {"dur": float(ev[1]) if ev.size() > 1 else 4.0, "axis": int(ev[2]) if ev.size() > 2 else 0})
		"boss_phase":
			# Pressekonferenz at a boss phase change (GDD §14, D-106): the banner above
			# the boss bar shows this phase name while the flag lasts (D-158)
			if ev.size() >= 3:
				_presse = {"enc": str(ev[1]), "phase": int(ev[2]), "t0": _t}
		"streik":
			_overlay("streik", 2.0, {})
		"stage":
			_overlay("stage", 2.8, {"stage": int(ev[1]) if ev.size() > 1 else 0})
		"levelup":
			_overlay("levelup", 1.6, {"level": int(ev[1]) if ev.size() > 1 else 0})
		"wave_start":
			_overlay("wave_start", 2.2, {"wave": int(ev[1]) if ev.size() > 1 else 0})
			if ev.size() > 1 and int(ev[1]) == Content.WAVE_COUNT:
				_koal_time = 0.0
		"wave_end":
			_overlay("wave_end", 2.2, {"wave": int(ev[1]) if ev.size() > 1 else 0})
		"over":
			_overlay("over", 3.0, {"won": bool(ev[1]) if ev.size() > 1 else false})
		"ach":
			if ev.size() >= 3 and int(ev[1]) == local_id():
				var id := str(ev[2])
				_toasts.append({"text": tr("HUD_ACH"), "sub": tr("ACH_%s_NAME" % id.to_upper()), "t": 0.0, "life": 4.5, "kind": "ach"})
		"deny":
			if ev.size() >= 3 and int(ev[1]) == local_id():
				_toasts.append({"text": tr(str(ev[2])), "sub": "", "t": 0.0, "life": 2.5, "kind": "deny"})
		"ult":
			if ev.size() >= 2 and int(ev[1]) == local_id():
				_ult_fire = 0.0
		"away", "back":
			# Co-op connection drops (networking.md §7.4).
			if ev.size() >= 2:
				var pid := int(ev[1])
				var nm := str(_player_meta(get_meta_dict(), pid).get("name", "?"))
				var text: String
				if ev[0] == "away":
					text = tr("HUD_PLAYER_AWAY") % nm
				elif pid == local_id():
					text = tr("HUD_RECONNECTED")
				else:
					text = tr("HUD_PLAYER_BACK") % nm
				_toasts.append({"text": text, "sub": "", "t": 0.0, "life": 3.5, "kind": "net"})


func _overlay(kind: String, life: float, data: Dictionary) -> void:
	for i in range(_overlays.size() - 1, -1, -1):
		if _overlays[i]["kind"] == kind:
			_overlays.remove_at(i)
	_overlays.append({"kind": kind, "t": 0.0, "life": life, "data": data})


# --- Frame ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	var vs := get_view()
	if vs and vs.wave >= Content.WAVE_COUNT and vs.wave_time_left < 0.0 and vs.phase == 0:
		_koal_time += delta / 3.0
	var md := get_meta_dict()
	# Boss card stays while the game waits for *this* player; once they continue it fades out quickly.
	var holding: bool = bool(md.get("intro_wait", false)) and not (local_id() in md.get("intro_done", []))
	for i in range(_overlays.size() - 1, -1, -1):
		_overlays[i]["t"] += delta
		if _overlays[i]["kind"] == "card":
			if holding:
				_overlays[i]["t"] = minf(_overlays[i]["t"], 1.2)
				_overlays[i]["held"] = true
			elif _overlays[i].get("held", false):
				_overlays[i]["t"] = maxf(_overlays[i]["t"], _overlays[i]["life"] - 0.3)
		if _overlays[i]["t"] > _overlays[i]["life"]:
			_overlays.remove_at(i)
	for i in range(_toasts.size() - 1, -1, -1):
		_toasts[i]["t"] += delta
		if _toasts[i]["t"] > _toasts[i]["life"]:
			_toasts.remove_at(i)
	var ult_ready := bool(_local_meta(get_meta_dict()).get("ult_ready", false))
	if ult_ready and not _ult_ready_prev:
		_ult_pop = 0.0
	_ult_ready_prev = ult_ready
	if _ult_pop >= 0.0:
		_ult_pop += delta
		if _ult_pop > 1.2:
			_ult_pop = -1.0
	if _ult_fire >= 0.0:
		_ult_fire += delta
		if _ult_fire > 0.6:
			_ult_fire = -1.0
	# Funkloch easter egg (only while a wave runs, never during a real reconnect)
	if _reconnecting():
		_funk_t = -1.0
		_flicker.clear()
	elif vs and vs.phase == 0:
		_funk_next -= delta
		if _funk_next <= 0.0:
			_funk_t = 0.0
			_funk_next = _rng.randf_range(420.0, 600.0)
	if _funk_t >= 0.0:
		_funk_t += delta
		if _funk_t > FUNKLOCH_TIME:
			_funk_t = -1.0
			_flicker.clear()
	queue_redraw()


## Force the Funkloch on (preview harness / testing).
func trigger_funkloch() -> void:
	_funk_t = 0.0
	for k in ["hp", "wave", "team", "zus", "wall", "vertrag"]:
		_flicker[k] = _rng.randf() < 0.5


func _hidden(part: String) -> bool:
	return _funk_t >= 0.0 and _flicker.get(part, false)


func _draw() -> void:
	var vs := get_view()
	if vs == null:
		return
	var meta := get_meta_dict()
	var sz := size
	var shop := vs.phase == 1 or int(meta.get("phase", vs.phase)) == 1
	if not _hidden("hp"):
		_draw_player_panel(vs, meta)
	if not shop:
		if not _hidden("wave"):
			_draw_wave(vs, meta, sz)
		if not _hidden("vertrag"):
			_draw_vertrag(meta, sz)
	if not _hidden("zus"):
		_draw_zusammenhalt(vs, meta, sz)
	if not _hidden("wall"):
		_draw_wall_info(vs, meta, sz)
	if not _hidden("team"):
		_draw_team(vs, meta)
	if not shop:
		# bottom row: ult panel at the left, the boss bar beside it (never under it);
		# the left column above the ult panel holds the Streik prompt and the ult effects
		var ult_r := _ult_panel_rect(vs, meta, sz)
		var boss_r := _draw_boss(vs, sz, ult_r)
		_draw_down_hint(vs, sz)
		var left_h := _draw_ult_panel(vs, meta, sz)
		if boss_r.size.x > 0.0 and boss_r.position.x < ult_r.end.x + 8.0:
			left_h = sz.y - 16.0 - (boss_r.position.y - 40.0)   # boss bar (and cast tag) stacked above the ult panel
		left_h += _draw_streik(meta, sz, left_h)
		_draw_ult_effects(meta, sz, left_h)
	if _funk_t >= 0.0:
		_draw_funkloch(sz)
	if _reconnecting():
		_draw_reconnect(sz)
	for o in _overlays:
		_draw_overlay(o, sz)
	_draw_intro_hint(sz)
	_draw_toasts(sz)


# --- Panels ---------------------------------------------------------------------------

func _panel(r: Rect2, bg := PAPER, v := 0, border := INK) -> void:
	draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.18))
	draw_rect(r, bg)
	draw_polyline(Doodle.rect_pts(r, v + int(_t / 0.3) % 3, 1.6), border, 2.5)


func _bar(r: Rect2, frac: float, col: Color, back := Color(1, 1, 1, 0.6), v := 0) -> void:
	draw_rect(r, back)
	var f := clampf(frac, 0.0, 1.0)
	if f > 0.0:
		draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)
		# scribbled shading on the fill
		var segs := PackedVector2Array()
		var x := r.position.x + 6.0
		while x < r.position.x + r.size.x * f - 2.0:
			segs.append(Vector2(x, r.end.y - 2))
			segs.append(Vector2(x + r.size.y * 0.6, r.position.y + 2))
			x += 9.0
		if segs.size() >= 2:
			draw_multiline(segs, Color(1, 1, 1, 0.25), 2.0)
	draw_polyline(Doodle.rect_pts(r, v + int(_t / 0.3) % 3, 1.0), INK, 2.0)


func _txt(s: String, p: Vector2, fs: int, col := INK, font: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0, outline := 0) -> void:
	if font == null:
		font = _hand
	if outline > 0:
		draw_string_outline(font, p, s, align, w, fs, outline, PAPER)
	draw_string(font, p, s, align, w, fs, col)


func _draw_player_panel(vs: ViewState, meta: Dictionary) -> void:
	var me := vs.find_player(local_id())
	var lm := _local_meta(meta)
	var r := Rect2(14, 12, 290, 86)
	_panel(r, PAPER, 1)
	var hp: float = me.get("hp", 0.0)
	var mx: float = maxf(me.get("max_hp", 1.0), 1.0)
	_heart(Vector2(36, 38), 9.0, RED)
	_txt(tr("HUD_SOLIDARITAET"), Vector2(54, 36), 20)
	draw_string(_hand, Vector2(r.position.x, 36), "%d / %d" % [int(ceil(hp)), int(mx)], HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14, 20, INK)
	_bar(Rect2(26, 44, 266, 16), hp / mx, Color(0.82, 0.2, 0.18), Color(1, 1, 1, 0.6), 2)
	var pf := int(lm.get("pfand", 0))
	var blackrock: bool = bool(meta.get("blackrock", false))
	var ip := Vector2(36, 80)
	if blackrock:
		_chart_icon(ip)
		_txt("%s: %d" % [tr("HUD_AKTIEN"), pf], Vector2(54, 88), 21)
	else:
		_bottle_icon(ip)
		_txt("%s: %d" % [tr("HUD_PFAND"), pf], Vector2(54, 88), 21)
	var kasse := int(meta.get("kasse", 0))
	if int(meta.get("num_players", 1)) > 1:
		draw_string(_hand, Vector2(r.position.x, 88), "%s: %d" % [tr("HUD_KASSE"), kasse], HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14, 17, Color(0.3, 0.3, 0.3))


func _draw_wave(vs: ViewState, meta: Dictionary, sz: Vector2) -> void:
	var cx := sz.x * 0.5
	var r := Rect2(cx - 160, 10, 320, 66)
	_panel(r, PAPER, 2)
	var boss_wave := vs.wave >= Content.WAVE_COUNT and vs.wave_time_left < 0.0
	if boss_wave:
		_txt(tr("HUD_WAVE_BOSS"), Vector2(r.position.x, 36), 24, RED, null, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		_txt(_clock_str(_koal_time), Vector2(r.position.x, 66), 28, INK, _typeb, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	else:
		_txt(tr("HUD_WAVE") % vs.wave, Vector2(r.position.x, 36), 24, INK, null, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var left := maxf(vs.wave_time_left, 0.0)
		var col := RED if left <= 5.0 and int(_t * 4.0) % 2 == 0 else INK
		_txt(_clock_str(ceilf(left)), Vector2(r.position.x, 66), 28, col, _typeb, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var enc := str(meta.get("encounter", ""))
	if enc != "" and vs.boss.is_empty() and not boss_wave:
		_txt(tr("ENC_%s_NAME" % enc.to_upper()), Vector2(r.position.x, r.end.y + 22), 18, RED, null, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 4)


func _draw_vertrag(meta: Dictionary, sz: Vector2) -> void:
	var v = meta.get("vertrag", {})
	if not (v is Dictionary):
		return
	var act := str(v.get("active", ""))
	if act == "":
		return
	var left := int(v.get("waves_left", 0))
	var name := tr("VERTRAG_%s_NAME" % act.to_upper())
	var s := (tr("HUD_VERTRAG_ONE") % name) if left == 1 else (tr("HUD_VERTRAG") % [name, left])
	var w := _hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 24
	var r := Rect2(sz.x * 0.5 - w * 0.5, 82, w, 28)
	draw_rect(r, Color(1, 1, 1, 0.75))
	draw_polyline(Doodle.rect_pts(r, 4, 1.0), Color(INK, 0.7), 1.5)
	_txt(s, Vector2(r.position.x, r.position.y + 20), 17, INK, null, HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_zusammenhalt(vs: ViewState, meta: Dictionary, sz: Vector2) -> void:
	var team = meta.get("team", {})
	if not (team is Dictionary):
		team = {}
	var lvl := int(team.get("level", 0))
	var xp: float = team.get("xp", 0.0)
	var need: float = maxf(team.get("need", 1.0), 1.0)
	var st := int(team.get("stage", vs.stage))
	var r := Rect2(sz.x - 304, 12, 290, 76)
	_panel(r, PAPER, 3)
	_txt(tr("HUD_ZUSAMMENHALT"), Vector2(r.position.x + 14, 36), 20)
	_txt(tr("HUD_LEVEL") % lvl, Vector2(r.position.x, 36), 20, INK, null, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 14)
	var stage_col := Doodle.desat(Color(0.85, 0.35, 0.1), st)
	_bar(Rect2(r.position.x + 12, 44, 266, 12), xp / need, Color(0.95, 0.65, 0.15), Color(1, 1, 1, 0.6), 4)
	_txt(tr("STAGE_%d" % clampi(st, 0, 4)), Vector2(r.position.x + 14, 78), 20, stage_col.darkened(0.2))
	for i in 5:
		var c := Vector2(r.end.x - 90 + i * 16, 70)
		if i <= st:
			draw_circle(c, 5.0, Color(0.95, 0.65, 0.15))
		draw_arc(c, 5.0, 0, TAU, 10, INK, 1.5)


func _draw_wall_info(vs: ViewState, meta: Dictionary, sz: Vector2) -> void:
	var holes := int(meta.get("wall_holes", -1))
	if holes < 0:
		holes = 0
		for i in Arena.WALL_SEGMENTS:
			if not (vs.wall & (1 << i)):
				holes += 1
	var s: String
	if holes == 0:
		s = tr("HUD_WALL_INTACT")
	elif holes == 1:
		s = tr("HUD_WALL_HOLE_ONE")
	else:
		s = tr("HUD_WALL_HOLES") % holes
	var w := _hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 56
	var r := Rect2(sz.x - 14 - w, 96, w, 30)
	_panel(r, Color("ecd9cf"), 5)
	_draw_wall_map(vs.wall, Rect2(r.position + Vector2(9, 6), Vector2(30, 19)))
	_txt(s, Vector2(r.position.x + 48, r.position.y + 22), 19, RED if holes > 0 else INK)


## Tiny map of the four Brandmauer walls (GDD §5a): brick strokes for intact
## segments, short red ticks where a hole is, so you see on which side.
func _draw_wall_map(mask: int, m: Rect2) -> void:
	var k := m.size / Arena.SIZE
	var brick := Color("b5654a")
	for i in Arena.WALL_SEGMENTS:
		var sr := Arena.seg_rect(i)
		var c := m.position + sr.get_center() * k
		var along := Vector2(sr.size.x * k.x, 0) if sr.size.x > sr.size.y else Vector2(0, sr.size.y * k.y)
		if mask & (1 << i):
			draw_line(c - along * 0.5, c + along * 0.5, brick, 3.0)
		else:
			var across := Vector2(along.y, along.x).normalized() * 2.5
			draw_line(c - across, c + across, RED, 2.0)
	for pr in Arena.pillars():
		draw_rect(Rect2(m.position + pr.position * k - Vector2(1, 1), Vector2(2.5, 2.5)), INK)


func _draw_team(vs: ViewState, meta: Dictionary) -> void:
	if vs.players.size() <= 1:
		return
	var ps = meta.get("players", {})
	var me := local_id()
	var y := 108.0
	var slot := 0
	for p in vs.players:
		var col: Color = SLOT_COLORS[slot % SLOT_COLORS.size()]
		slot += 1
		var pid := int(p.get("id", 0))
		if pid == me:
			continue
		var pm: Dictionary = {}
		if ps is Dictionary:
			pm = ps.get(pid, ps.get(str(pid), {}))
		var r := Rect2(14, y, 220, 44)
		_panel(r, Color(1, 1, 1, 0.85), slot)
		draw_circle(r.position + Vector2(16, 16), 6.0, col)
		var nm := str(pm.get("name", "?"))
		var state := int(p.get("state", 0))
		_txt(nm, r.position + Vector2(28, 22), 18, INK, null, HORIZONTAL_ALIGNMENT_LEFT, 120)
		if state == 1:
			draw_string(_hand, r.position + Vector2(0, 22), tr("HUD_DOWN_TAG"), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 10, 16, RED)
		elif state == 2:
			draw_string(_hand, r.position + Vector2(0, 22), tr("HUD_GONE_TAG"), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 10, 16, Color(0.4, 0.4, 0.4))
		elif state == 3:
			var pulse := 0.55 + 0.45 * absf(sin(_t * 3.0))
			draw_string(_hand, r.position + Vector2(0, 22), tr("HUD_AWAY_TAG"), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 10, 16, Color(0.8, 0.4, 0.05, pulse))
		var mx: float = maxf(p.get("max_hp", 1.0), 1.0)
		_bar(Rect2(r.position + Vector2(12, 28), Vector2(r.size.x - 24, 9)), float(p.get("hp", 0.0)) / mx,
			Color(0.82, 0.2, 0.18) if state == 0 else Color(0.5, 0.5, 0.5), Color(1, 1, 1, 0.6), slot)
		y += 52.0


## Where the boss bar goes: centred at the bottom unless the ult panel (bottom
## left) is in the way; then right of it, or above it if the window is too narrow.
static func boss_bar_rect(sz: Vector2, ult_r: Rect2) -> Rect2:
	var w := minf(640.0, sz.x - 80.0)
	var r := Rect2(sz.x * 0.5 - w * 0.5, sz.y - 74, w, 58)
	if ult_r.size.x <= 0.0:
		return r
	var x0 := ult_r.position.x + ult_r.size.x * ULT_POP_MAX + 16.0   # room for the panel's "ready" pop
	if r.position.x >= x0:
		return r
	r.position.x = x0
	r.size.x = minf(w, sz.x - 24.0 - x0)
	if r.size.x >= BOSS_BAR_MIN_W:
		return r
	r.size.x = w
	r.position = Vector2(sz.x * 0.5 - w * 0.5, ult_r.end.y - ult_r.size.y * ULT_POP_MAX - 12.0 - 58.0)
	return r


func _draw_boss(vs: ViewState, sz: Vector2, ult_r := Rect2()) -> Rect2:
	var b := vs.boss
	if b.is_empty():
		return Rect2()
	var ei := int(b.get("enc", -1))
	if ei < 0 or ei >= Content.ENCOUNTER_ORDER.size():
		return Rect2()
	var enc: String = Content.ENCOUNTER_ORDER[ei]
	var r := boss_bar_rect(sz, ult_r)
	var w := r.size.x
	_panel(r, Color("f1e3d3"), 6, INK)
	_txt(tr("ENC_%s_NAME" % enc.to_upper()), Vector2(r.position.x + 16, r.position.y + 24), 22, RED)
	var ph := int(b.get("phase", 0))
	for i in 3:
		var c := Vector2(r.end.x - 60 + i * 18, r.position.y + 16)
		if i <= ph:
			draw_circle(c, 5.5, RED)
		draw_arc(c, 5.5, 0, TAU, 10, INK, 1.5)
	var bar := Rect2(r.position + Vector2(14, 32), Vector2(w - 28, 16))
	_bar(bar, float(b.get("hp", 0.0)), Color(0.75, 0.12, 0.12), Color(1, 1, 1, 0.6), 7)
	var hoch := int(b.get("hoch", 0))
	if hoch > 0:
		# Wahlabend (D-144): the final fight speeds up, shown left of the phase dots
		var pct := int(round(hoch * float(Content.BOSS["wahl_step"]) * 100.0))
		_txt(tr("HUD_HOCHRECHNUNG") % pct, Vector2(r.position.x + w * 0.45, r.position.y + 22), 16, RED.darkened(0.15),
			null, HORIZONTAL_ALIGNMENT_RIGHT, w * 0.55 - 74.0)
	_draw_boss_cast(vs, r)
	var sh: float = b.get("shield", 0.0)
	if sh > 0.0:
		var sb := Rect2(bar.position + Vector2(0, -6), Vector2(bar.size.x * sh, 7))
		draw_rect(sb, GOLD)
		draw_rect(sb, INK, false, 1.2)
		for i in int(sb.size.x / 16.0):
			draw_line(sb.position + Vector2(8 + i * 16, 0), sb.position + Vector2(8 + i * 16, 7), Color(0.6, 0.45, 0.05), 1.0)
	return r


## The boss's running cast above the boss bar (research B3, D-108): name and a
## progress bar, e.g. "Abstimmung läuft …" with how many Plenum circles are taken;
## While the boss is invulnerable, the Pressekonferenz banner instead (D-158).
func _draw_boss_cast(vs: ViewState, panel: Rect2) -> void:
	var presse := false
	for i in mini(vs.e_flags2.size(), vs.e_flags.size()):
		if (vs.e_flags[i] & ViewState.EF_ELITE) and (vs.e_flags2[i] & ViewState.EF2_PRESSE):
			presse = true
			break
	var cast := vs.boss_cast()
	if cast == "" and not presse:
		return
	if presse:
		_draw_presse_banner(panel)
		return
	var w := minf(340.0, panel.size.x)
	var r := Rect2(panel.get_center().x - w * 0.5, panel.position.y - 36, w, 30)
	_panel(r, Color("fde8e2"), 4, RED)
	var k := clampf(float(vs.boss.get("cast_t", 0.0)), 0.0, 1.0)
	draw_rect(Rect2(r.position + Vector2(4, r.size.y - 8), Vector2((w - 8) * k, 5)), RED)
	var label := tr("CAST_" + cast.to_upper())
	if cast == "abstimmung":
		var circles := 0
		var taken := 0
		var t_pl := Content.HAZARD_ORDER.find("plenum")
		for i in vs.h_type.size():
			if vs.h_type[i] != t_pl:
				continue
			circles += 1
			for p in vs.players:
				if int(p.get("state", 0)) == 0 and (p.get("pos", Vector2.INF) as Vector2).distance_to(vs.h_pos[i]) <= vs.h_rad[i]:
					taken += 1
					break
		if circles > 0:
			label += "   " + tr("HUD_PLENUM") % [taken, circles if circles <= 2 else circles - 1]
	_txt(label, Vector2(r.position.x, r.position.y + 20), 19, RED.darkened(0.2), null, HORIZONTAL_ALIGNMENT_CENTER, w)


## "Pressekonferenz" banner above the boss bar (D-158): a lectern sign with the
## phase name, for as long as the boss is invulnerable. Slides up out of the bar.
func _draw_presse_banner(panel: Rect2) -> void:
	var age := preview_overlay_t if preview_overlay_t >= 0.0 else _t - float(_presse.get("t0", _t - 1.0))
	var slide := minf(age * 4.0, 1.0)
	var a := slide
	var w := minf(440.0, panel.size.x)
	var r := Rect2(panel.get_center().x - w * 0.5, panel.position.y - 70 + (1.0 - slide) * 24, w, 64)
	_panel(r, Color(1.0, 0.97, 0.86, a), 4, Color(GOLD.darkened(0.35), a))
	draw_rect(Rect2(r.position + Vector2(10, 6), Vector2(w - 20, 4)), Color(GOLD, a))
	_txt(tr("HUD_PRESSE").to_upper(), Vector2(r.position.x, r.position.y + 34), 26, Color(INK, a), _typeb, HORIZONTAL_ALIGNMENT_CENTER, w)
	var enc := str(_presse.get("enc", ""))
	if enc != "":
		var ph := int(_presse.get("phase", 0))
		_txt(tr("HUD_PRESSE_SUB") % [ph + 1, tr("PHASE_%s_%d" % [enc.to_upper(), ph])], Vector2(r.position.x, r.position.y + 56),
			18, Color(RED.darkened(0.1), a), null, HORIZONTAL_ALIGNMENT_CENTER, w)
	for s in [-1.0, 1.0]:
		var m := Vector2(r.get_center().x + s * (w * 0.5 - 26), r.position.y + 34)
		draw_line(m + Vector2(0, 16), m + Vector2(-s * 5, -4), Color(INK, a), 2.5)
		draw_circle(m + Vector2(-s * 5, -8), 7.0, Color(INK, a))
		draw_circle(m + Vector2(-s * 5, -8), 4.5, Color(0.6, 0.6, 0.65, a))


## Streik prompt / countdown in the left column above the ult panel (`below` px
## from the bottom are taken), so it never covers the arena centre or the bottom
## wall. Returns the height it used.
func _draw_streik(meta: Dictionary, sz: Vector2, below: float) -> float:
	var s = meta.get("streik", {})
	if not (s is Dictionary):
		return 0.0
	var active: float = s.get("active", 0.0)
	var y := sz.y - 16.0 - below - 8.0 - 40.0
	var txt := ""
	if active > 0.0:
		txt = tr("HUD_STREIK_ACTIVE") % int(ceil(active))
	elif bool(s.get("available", false)):
		txt = tr("HUD_STREIK_PROMPT") % InputGlyphs.key("streik")
	else:
		return 0.0
	var w := _hand.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 40
	var pulse := 1.0 + (0.04 * sin(_t * 6.0) if active <= 0.0 else 0.0)
	var r := Rect2(14, y, w * pulse, 40)
	_panel(r, Color("fbe3a0") if active <= 0.0 else Color(1.0, 0.92, 0.88), 8, RED)
	_txt(txt, Vector2(r.position.x, r.position.y + 28), 24, RED, null, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	return 48.0


func _draw_down_hint(vs: ViewState, sz: Vector2) -> void:
	var me := vs.find_player(local_id())
	if me.is_empty() or int(me.get("state", 0)) != 1:
		return
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.2, 0.15, 0.1, 0.18))
	_txt(tr(down_hint_key(get_meta_dict())), Vector2(0, sz.y * 0.32), 30, INK, null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 6)


## Downed hint (GDD §16, D-157): with one player left nobody can revive you, going
## down ends the run (Sim.damage_player uses the same count), so solo gets its own
## line and no revive marker (WorldView).
## In co-op the run ends when the last player goes down: then nobody can help either.
static func can_be_revived(meta: Dictionary) -> bool:
	return int(meta.get("num_players", 1)) > 1 and int(meta.get("phase", 0)) != Sim.Phase.OVER


static func down_hint_key(meta: Dictionary) -> String:
	if int(meta.get("num_players", 1)) <= 1:
		return "HUD_YOU_DOWN_SOLO"
	return "HUD_YOU_DOWN" if can_be_revived(meta) else "HUD_YOU_DOWN_ALL"


## Real connection loss (client, mid-run): an unplugged plug with a solid orange
## frame and a countdown, in the slot the Funkloch joke uses (which is suppressed
## meanwhile), so the two can never be confused.
func _draw_reconnect(sz: Vector2) -> void:
	var text := tr("HUD_RECONNECTING")
	var sub := tr("HUD_RECONNECT_LEFT") % int(ceil(_reconnect_left()))
	var w := maxf(_hand.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x,
			_type.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x) + 82.0
	var r := Rect2(sz.x - 14 - w, 132, w, 50)
	var orange := Color(0.85, 0.42, 0.05)
	_panel(r, Color(1.0, 0.95, 0.86), 9, orange)
	# plug (left) and socket (right) pulled apart, with a pulsing gap
	var c := r.position + Vector2(36, 27)
	var gap := 2.0 + 2.5 * absf(sin(_t * 4.0))
	var plug := Rect2(c + Vector2(-16 - gap, -7), Vector2(12, 14))
	draw_line(plug.position + Vector2(0, 7), plug.position + Vector2(-8, 12), INK, 2.5)
	draw_rect(plug, Color(0.3, 0.3, 0.3))
	draw_rect(plug, INK, false, 1.5)
	draw_line(plug.position + Vector2(12, 3.5), plug.position + Vector2(17, 3.5), INK, 2.0)
	draw_line(plug.position + Vector2(12, 10.5), plug.position + Vector2(17, 10.5), INK, 2.0)
	var sock := Rect2(c + Vector2(4 + gap, -9), Vector2(12, 18))
	draw_rect(sock, Color.WHITE)
	draw_rect(sock, INK, false, 1.5)
	draw_circle(sock.position + Vector2(4, 6), 1.3, INK)
	draw_circle(sock.position + Vector2(4, 12), 1.3, INK)
	draw_line(sock.position + Vector2(12, 9), sock.position + Vector2(18, 14), INK, 2.5)
	if int(_t * 2.0) % 2 == 0:
		_sparkle(c + Vector2(0, -14), 4.0, orange)
	_txt(text, Vector2(r.position.x + 66, r.position.y + 22), 17, orange.darkened(0.3))
	_txt(sub, Vector2(r.position.x + 66, r.position.y + 41), 13, Color(0.35, 0.33, 0.3), _type)


## Funkloch easter egg: a small, harmless joke icon at the right edge (not an error).
func _draw_funkloch(sz: Vector2) -> void:
	var r := Rect2(sz.x - 236, 132, 220, 30)
	var a := clampf(minf(_funk_t * 4.0, (FUNKLOCH_TIME - _funk_t) * 4.0), 0.0, 1.0)
	_panel(r, Color(1, 1, 1, 0.75 * a), 9, Color(INK, a))
	var base := r.position + Vector2(10, 24)
	for i in 4:
		var h := 4.0 + i * 3.5
		draw_rect(Rect2(base + Vector2(i * 5, -h), Vector2(3, h)), Color(0.5, 0.5, 0.5, a))
	draw_line(base + Vector2(-2, 1), base + Vector2(20, -17), Color(RED, a), 2.0)
	_txt(tr("HUD_KEIN_NETZ"), Vector2(r.position.x + 36, r.position.y + 21), 16, Color(INK, a))


# --- Ultimate (architecture §9) -----------------------------------------------------------

## Local player's ultimate id: meta "ult", falling back to the character's.
static func ult_id_for(lm: Dictionary) -> String:
	var id := str(lm.get("ult", ""))
	if id == "":
		var ch := str(lm.get("char", ""))
		if Content.CHARACTERS.has(ch):
			id = str(Content.CHARACTERS[ch].get("ult", ""))
	return id


static func _ult_key() -> String:
	var k := _action_key("ultimate")
	if k == "?" or k == "Space":
		return String(TranslationServer.translate("HUD_ULT_SPACE"))
	return k


## Bottom-left panel: name, [key], ready / used. Returns the height it took (0 if hidden).
## The ult panel's rect at the bottom left (Rect2() when there is none).
func _ult_panel_rect(vs: ViewState, meta: Dictionary, sz: Vector2) -> Rect2:
	if bool(meta.get("intro_wait", false)):
		return Rect2()
	var lm := _local_meta(meta)
	if lm.is_empty() or ult_id_for(lm) == "":
		return Rect2()
	var me := vs.find_player(local_id())
	if not me.is_empty() and int(me.get("state", 0)) == 2:
		return Rect2()
	var ready := bool(lm.get("ult_ready", false))
	var name := tr("ULT_%s_NAME" % ult_id_for(lm).to_upper())
	var state := tr("HUD_ULT_READY") if ready else tr("HUD_ULT_USED")
	var kw := _type.get_string_size(InputGlyphs.label("ultimate"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 14.0
	var nw := _hand.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var stw := _hand.get_string_size(state, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var w := maxf(kw + nw + 72.0, stw + 30.0)   # room for the sparkle / cross on the right
	return Rect2(14, sz.y - 16 - 72.0, w, 72.0)


func _draw_ult_panel(vs: ViewState, meta: Dictionary, sz: Vector2) -> float:
	var r := _ult_panel_rect(vs, meta, sz)
	if r.size.x <= 0.0:
		return 0.0
	var lm := _local_meta(meta)
	var id := ult_id_for(lm)
	var ready := bool(lm.get("ult_ready", false))
	var name := tr("ULT_%s_NAME" % id.to_upper())
	var key := InputGlyphs.label("ultimate")
	var state := tr("HUD_ULT_READY") if ready else tr("HUD_ULT_USED")
	var kw := _type.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 14.0
	var w := r.size.x
	var h := r.size.y
	var sc := Vector2.ONE
	var rot := 0.0
	if ready:
		var s := 1.0 + 0.02 * sin(_t * 5.0)
		if _ult_pop >= 0.0:
			var k := clampf(_ult_pop / 0.5, 0.0, 1.0)
			s += 0.35 * sin(k * PI) * (1.0 - k * 0.5)
			rot = sin(_ult_pop * 30.0) * 0.06 * (1.0 - k)
		sc = Vector2(s, s)
		rot += -0.015
	elif _ult_fire >= 0.0:
		var k := _ult_fire / 0.6
		sc = Vector2(1.0 + 0.12 * (1.0 - k), 1.0 - 0.12 * (1.0 - k))
	# pivot at the bottom-left corner so the pop never leaves the screen
	var pivot := Vector2(r.position.x, r.end.y)
	draw_set_transform(pivot, rot, sc)
	var rr := Rect2(Vector2(0, -h), r.size)
	var ink := RED if ready else Color(0.45, 0.43, 0.4)
	if ready:
		var glow := 0.25 + 0.15 * sin(_t * 5.0)
		draw_rect(rr.grow(6), Color(1.0, 0.75, 0.15, glow))
		_panel(rr, Color("fbe3a0"), 11, RED)
	else:
		_panel(rr, Color(0.9, 0.88, 0.84), 11, Color(0.45, 0.43, 0.4))
	var kr := Rect2(rr.position + Vector2(12, 11), Vector2(kw, 26))
	draw_rect(kr, Color(1, 1, 1, 0.9 if ready else 0.5))
	draw_polyline(Doodle.rect_pts(kr, 2 + int(_t / 0.3) % 3, 1.0), ink, 1.5)
	_txt(key, Vector2(kr.position.x, kr.position.y + 19), 16, ink, _type, HORIZONTAL_ALIGNMENT_CENTER, kw)
	_txt(name, Vector2(kr.end.x + 10, rr.position.y + 34), 26, RED if ready else Color(0.4, 0.38, 0.36))
	_txt(state, Vector2(rr.position.x + 14, rr.end.y - 10), 21 if ready else 18, GREEN if ready else Color(0.45, 0.43, 0.4))
	if ready:
		for i in 3:
			var a := _t * 2.0 + TAU * i / 3.0
			var p := Vector2(rr.end.x - 18 + cos(a) * 8.0, rr.position.y + 16 + sin(a) * 6.0)
			_sparkle(p, 4.0 + 2.0 * absf(sin(_t * 6.0 + i)), Color(1.0, 0.6, 0.05))
	else:
		# crossed-out "used" tick
		draw_line(Vector2(rr.end.x - 30, rr.position.y + 12), Vector2(rr.end.x - 12, rr.position.y + 30), Color(RED, 0.6), 3.0)
		draw_line(Vector2(rr.end.x - 12, rr.position.y + 12), Vector2(rr.end.x - 30, rr.position.y + 30), Color(RED, 0.6), 3.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	return h + 16.0


## Global ultimate effects (Tarifrunde, Antrag gestellt) with a countdown, above the panel.
func _draw_ult_effects(meta: Dictionary, sz: Vector2, below: float) -> void:
	var eff = meta.get("effects", {})
	if not (eff is Dictionary) or eff.is_empty():
		return
	var y := sz.y - 16.0 - below - 8.0
	for id in ["tarifrunde", "antrag_gestellt"]:
		var left := float(eff.get(id, 0.0))
		if left <= 0.0:
			continue
		var name := tr("ULT_%s_NAME" % id.to_upper())
		if id == "tarifrunde":
			name += " " + tr("HUD_ULT_TARIF_BONUS") % int(round(float(Content.ULTS["tarifrunde"]["damage"]) * 100.0))
		var s := tr("HUD_ULT_EFFECT") % [name, int(ceil(left))]
		var w := _hand.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 52.0
		var r := Rect2(14, y - 38, w, 38)
		var col := RED if id == "tarifrunde" else BLUE
		_panel(r, Color(1.0, 0.95, 0.9) if id == "tarifrunde" else Color(0.92, 0.95, 1.0), 12, col)
		var ic := r.position + Vector2(20, 18)
		if id == "tarifrunde":
			draw_line(ic + Vector2(-5, 10), ic + Vector2(-5, -11), INK, 2.0)
			var fl := PackedVector2Array([ic + Vector2(-4, -11), ic + Vector2(9, -8 + sin(_t * 6.0)), ic + Vector2(8, 0), ic + Vector2(-4, -2)])
			draw_colored_polygon(fl, RED)
			fl.append(fl[0])
			draw_polyline(fl, INK, 1.5)
		else:
			for k in 2:
				var o := Vector2(k * 4.0 - 4.0, -k * 3.0)
				var pr := Rect2(ic + o + Vector2(-6, -9), Vector2(12, 16))
				draw_rect(pr, Color.WHITE)
				draw_rect(pr, INK, false, 1.2)
			draw_line(ic + Vector2(-2, -5), ic + Vector2(4, -5), BLUE, 1.0)
			draw_line(ic + Vector2(-2, -2), ic + Vector2(4, -2), BLUE, 1.0)
		_txt(s, Vector2(r.position.x + 38, r.position.y + 25), 19, col.darkened(0.15))
		var total := maxf(float(Content.ULTS[id].get("time", 1.0)), 0.1)
		var bar := Rect2(r.position + Vector2(38, 30), Vector2(r.size.x - 50, 3))
		draw_rect(bar, Color(col, 0.2))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(left / total, 0.0, 1.0), 3)), col)
		y -= 46.0


# --- Overlays ---------------------------------------------------------------------------

func _ot(o: Dictionary) -> float:
	return preview_overlay_t if preview_overlay_t >= 0.0 else float(o["t"])


func _draw_overlay(o: Dictionary, sz: Vector2) -> void:
	var t := _ot(o)
	var life: float = o["life"]
	var a := clampf(minf(t * 5.0, (life - t) * 3.0), 0.0, 1.0)
	var d: Dictionary = o["data"]
	var c := sz * 0.5
	match str(o["kind"]):
		"card":
			_draw_card(str(d["enc"]), t, a, sz)
		"wende":
			var arc_c := Color(0.7, 0.1, 0.45, a)
			var axis := int(d.get("axis", 0))
			if axis == 0:
				var rot := minf(t / 0.9, 1.0) * PI
				draw_set_transform(c + Vector2(0, -60), rot, Vector2.ONE)
				draw_arc(Vector2.ZERO, 70, 0.4, TAU - 0.5, 36, arc_c, 10.0)
				var tip := Vector2(cos(-0.5), sin(-0.5)) * 70
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-18, -6), tip + Vector2(14, -14), tip + Vector2(6, 18)]), arc_c)
			else:
				# Teilwende (D-112): a big double arrow shows the one flipped axis
				var wob := sin(t * 6.0) * 10.0
				draw_set_transform(c + Vector2(0, -60), PI * 0.5 if axis == 2 else 0.0, Vector2.ONE)
				draw_line(Vector2(-110 - wob, 0), Vector2(110 + wob, 0), arc_c, 12.0)
				for s in [-1.0, 1.0]:
					var e := Vector2(s * (118 + wob), 0)
					draw_colored_polygon(PackedVector2Array([e, e + Vector2(-s * 34, -26), e + Vector2(-s * 34, 26)]), arc_c)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			var sc := 1.0 + maxf(0.0, 0.3 - t) * 1.5
			draw_set_transform(c + Vector2(0, 60), sin(t * 3.0) * 0.04, Vector2(sc, sc))
			_txt(tr("HUD_WENDE"), Vector2(-sz.x * 0.5, 0), 64, Color(0.7, 0.1, 0.45, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 10)
			var sub := "HUD_WENDE_SUB" if axis == 0 else ("HUD_WENDE_SUB_X" if axis == 1 else "HUD_WENDE_SUB_Y")
			_txt(tr(sub), Vector2(-sz.x * 0.5, 44), 26, Color(INK, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 6)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"streik":
			var punch := 1.0 + maxf(0.0, 0.18 - t) * 5.0
			draw_set_transform(c + Vector2(0, -40), -0.18, Vector2(punch, punch))
			var col := Color(0.8, 0.1, 0.1, a * 0.9)
			var r := Rect2(-210, -62, 420, 112)
			draw_polyline(Doodle.rect_pts(r, 1, 4.0), col, 9.0)
			draw_polyline(Doodle.rect_pts(r.grow(-14), 2, 3.0), col, 3.0)
			_txt(tr("HUD_STREIK_STAMP"), Vector2(-210, 28), 86, col, _typeb, HORIZONTAL_ALIGNMENT_CENTER, 420)
			# stamp speckles
			for i in 14:
				var p := Vector2(Doodle.noise(i) * 200, Doodle.noise(i + 40) * 50)
				draw_circle(p, 3.0 + absf(Doodle.noise(i + 80)) * 4.0, Color(0.98, 0.95, 0.9, a * 0.7))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"stage":
			var st := clampi(int(d["stage"]), 0, 4)
			var slide := minf(t * 4.0, 1.0)
			var w := 520.0
			var r := Rect2(c.x - w * 0.5, 130 - (1.0 - slide) * 80, w, 64)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_panel(r, Color(0.99, 0.93, 0.75, a), 3, Color(INK, a))
			var stc := Doodle.desat(Color(0.85, 0.35, 0.1), st)
			_txt(tr("HUD_STAGE_BANNER") % tr("STAGE_%d" % st), Vector2(r.position.x, r.position.y + 44), 36,
				Color(stc.darkened(0.25), a), null, HORIZONTAL_ALIGNMENT_CENTER, w)
		"levelup":
			var p := Vector2(sz.x - 160, 160 - t * 10.0)
			_txt(tr("HUD_LEVELUP") % int(d["level"]), Vector2(p.x - 150, p.y), 28, Color(0.85, 0.5, 0.05, a), null, HORIZONTAL_ALIGNMENT_CENTER, 300, 6)
			for i in 5:
				var ang := TAU * i / 5.0 + t * 3.0
				_sparkle(p + Vector2(cos(ang) * 110, sin(ang) * 22 - 8), 6.0, Color(1.0, 0.75, 0.1, a))
		"wave_start":
			var wv := int(d["wave"])
			var title := tr("HUD_WAVE_BOSS") if wv >= Content.WAVE_COUNT else tr("HUD_WAVE") % wv
			var sub := tr("HUD_WAVE_BOSS_SUB") if wv >= Content.WAVE_COUNT else tr("HUD_WAVE_START_SUB")
			var sc := 1.0 + maxf(0.0, 0.25 - t) * 2.0
			draw_set_transform(c + Vector2(0, -90), -0.03, Vector2(sc, sc))
			_txt(title, Vector2(-sz.x * 0.5, 0), 60, Color(INK, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 10)
			_txt(sub, Vector2(-sz.x * 0.5, 40), 26, Color(0.35, 0.3, 0.25, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 6)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"wave_end":
			draw_set_transform(c + Vector2(0, -90), 0.03, Vector2.ONE)
			_txt(tr("HUD_WAVE_END"), Vector2(-sz.x * 0.5, 0), 60, Color(0.2, 0.5, 0.25, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 10)
			_txt(tr("HUD_WAVE_END_SUB") % int(d.get("wave", 0)), Vector2(-sz.x * 0.5, 40), 26, Color(0.35, 0.3, 0.25, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 6)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"over":
			var won: bool = d["won"]
			_txt(tr("HUD_OVER_WON") if won else tr("HUD_OVER_LOST"), Vector2(0, c.y), 72,
				Color(0.2, 0.5, 0.25, a) if won else Color(0.6, 0.15, 0.15, a), null, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 12)


func _draw_card(enc: String, t: float, a: float, sz: Vector2) -> void:
	var w := minf(700.0, sz.x - 60.0)
	var qid := ""
	var ids := Quotes.ids_for("boss_karte:" + enc) if enc != "" else []
	if not ids.is_empty():
		qid = str(ids[0])
	var q := Quotes.get_quote(qid) if qid != "" else {}
	var qtext := "„%s“" % str(q.get("zitat", "")) if not q.is_empty() else ""
	var qsz := Vector2.ZERO
	if qtext != "":
		qsz = _type.get_multiline_string_size(qtext, HORIZONTAL_ALIGNMENT_LEFT, w - 80, 21)
	var qctx := Quotes.context_label(q) if not q.is_empty() else ""
	var csz := Vector2.ZERO
	if qctx != "":
		csz = _type.get_multiline_string_size(qctx, HORIZONTAL_ALIGNMENT_LEFT, w - 80, 14)
	var h := 120.0 + qsz.y + csz.y + (40.0 if qtext != "" else 30.0)
	var slide := 1.0 - pow(1.0 - minf(t * 3.0, 1.0), 3.0)
	var c := Vector2(sz.x * 0.5, sz.y * 0.42 + (1.0 - slide) * sz.y * 0.6)
	draw_set_transform(c, -0.025 + 0.01 * sin(t * 2.0), Vector2.ONE)
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	draw_rect(Rect2(r.position + Vector2(8, 10), r.size), Color(0, 0, 0, 0.3 * a))
	draw_rect(r, Color(CARD, a))
	draw_polyline(Doodle.rect_pts(r, int(t / 0.3) % 3, 2.5), Color(INK, a), 3.0)
	# tape strips on the corners
	for p in [r.position + Vector2(30, 0), Vector2(r.end.x - 30, r.position.y)]:
		draw_set_transform(c + p.rotated(-0.025), -0.5 if p.x < 0 else 0.5, Vector2.ONE)
		draw_rect(Rect2(-28, -10, 56, 20), Color(0.95, 0.9, 0.7, 0.75 * a))
		draw_set_transform(c, -0.025 + 0.01 * sin(t * 2.0), Vector2.ONE)
	var name := tr("ENC_%s_NAME" % enc.to_upper())
	_txt(name, Vector2(r.position.x, r.position.y + 70), 56, Color(0.75, 0.12, 0.12, a), null, HORIZONTAL_ALIGNMENT_CENTER, w)
	draw_line(Vector2(r.position.x + 60, r.position.y + 88), Vector2(r.end.x - 60, r.position.y + 86), Color(INK, a * 0.6), 2.0)
	if qtext != "":
		draw_multiline_string(_type, Vector2(r.position.x + 40, r.position.y + 124), qtext, HORIZONTAL_ALIGNMENT_LEFT, w - 80, 21, -1, Color(INK, a))
		draw_string(_type, Vector2(r.position.x + 40, r.end.y - 22 - csz.y), "– " + Quotes.source_label(q), HORIZONTAL_ALIGNMENT_RIGHT, w - 80, 15, Color(0.35, 0.33, 0.3, a))
		if qctx != "":
			draw_multiline_string(_type, Vector2(r.position.x + 40, r.end.y - csz.y - 4), qctx, HORIZONTAL_ALIGNMENT_RIGHT, w - 80, 14, -1, Color(0.45, 0.42, 0.38, a))
	elif enc == "sylt_clique":
		_txt(tr("SAY_SYLT_HUM"), Vector2(r.position.x, r.position.y + 128), 30, Color(0.15, 0.3, 0.7, a), null, HORIZONTAL_ALIGNMENT_CENTER, w)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_toasts(sz: Vector2) -> void:
	var y := sz.y - 20.0
	for i in range(_toasts.size() - 1, -1, -1):
		var o: Dictionary = _toasts[i]
		var t: float = o["t"]
		var a := clampf(minf(t * 5.0, (float(o["life"]) - t) * 3.0), 0.0, 1.0)
		var ach: bool = o["kind"] == "ach"
		var w := 330.0 if ach else maxf(220.0, _hand.get_string_size(o["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 40)
		var h := 66.0 if ach else 40.0
		var x := sz.x - 16 - w + (1.0 - minf(t * 5.0, 1.0)) * (w + 30)
		var r := Rect2(x, y - h, w, h)
		_panel(r, Color(1.0, 0.97, 0.85, a) if ach else Color(0.98, 0.88, 0.85, a), i, Color(INK, a))
		if ach:
			_trophy(r.position + Vector2(26, 34), Color(1, 1, 1, a))
			_txt(o["text"], r.position + Vector2(52, 26), 18, Color(0.4, 0.35, 0.3, a))
			_txt(o["sub"], r.position + Vector2(52, 52), 24, Color(INK, a))
		else:
			var tc := Color(0.6, 0.3, 0.02, a) if o["kind"] == "net" else Color(0.6, 0.12, 0.12, a)
			_txt(o["text"], r.position + Vector2(0, 27), 20, tc, null, HORIZONTAL_ALIGNMENT_CENTER, w)
		y -= h + 10.0


# --- Icons -------------------------------------------------------------------------------

func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.62, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.62, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.1, 0), c + Vector2(r * 1.1, 0), c + Vector2(0, r * 1.1)]), col)
	draw_polyline(PackedVector2Array([c + Vector2(0, -r * 0.3), c + Vector2(-r * 0.6, -r * 0.85), c + Vector2(-r * 1.15, -r * 0.2),
		c + Vector2(0, r * 1.1), c + Vector2(r * 1.15, -r * 0.2), c + Vector2(r * 0.6, -r * 0.85), c + Vector2(0, -r * 0.3)]), INK, 1.5)


func _bottle_icon(c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(-5, 11), c + Vector2(-5, -1), c + Vector2(-2, -5), c + Vector2(-2, -12),
		c + Vector2(2, -12), c + Vector2(2, -5), c + Vector2(5, -1), c + Vector2(5, 11)])
	draw_colored_polygon(pts, Color("6a4a22"))
	draw_rect(Rect2(c + Vector2(-5, 1), Vector2(10, 5)), Color("e8dfb8"))
	pts.append(pts[0])
	draw_polyline(pts, INK, 1.8)


func _chart_icon(c: Vector2) -> void:
	var r := Rect2(c + Vector2(-11, -11), Vector2(22, 22))
	draw_rect(r, Color.WHITE)
	draw_rect(r, INK, false, 1.5)
	draw_polyline(PackedVector2Array([c + Vector2(-9, -8), c + Vector2(-4, -4), c + Vector2(-1, -6), c + Vector2(4, 3), c + Vector2(9, 8)]), RED, 2.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(9, 8), c + Vector2(3, 7), c + Vector2(8, 2)]), RED)


func _trophy(c: Vector2, _col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -14), c + Vector2(10, -14), c + Vector2(7, -2), c + Vector2(0, 2), c + Vector2(-7, -2)]), GOLD)
	draw_rect(Rect2(c + Vector2(-2, 2), Vector2(4, 7)), GOLD)
	draw_rect(Rect2(c + Vector2(-8, 9), Vector2(16, 4)), GOLD)
	draw_polyline(PackedVector2Array([c + Vector2(-10, -14), c + Vector2(10, -14), c + Vector2(7, -2), c + Vector2(0, 2), c + Vector2(-7, -2), c + Vector2(-10, -14)]), INK, 1.5)
	draw_arc(c + Vector2(-10, -9), 4, PI * 0.5, PI * 1.5, 6, INK, 1.5)
	draw_arc(c + Vector2(10, -9), 4, -PI * 0.5, PI * 0.5, 6, INK, 1.5)


func _sparkle(p: Vector2, r: float, c: Color) -> void:
	draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), c, 2.0)
	draw_line(p + Vector2(0, -r), p + Vector2(0, r), c, 2.0)


# --- Helpers ------------------------------------------------------------------------------

static func _clock_str(sec: float) -> String:
	var s := maxi(int(sec), 0)
	return "%d:%02d" % [s / 60, s % 60]


static func _action_key(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var k := e as InputEventKey
			var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code) if k.physical_keycode != KEY_NONE else code)
	for e in InputMap.action_get_events(action):
		return e.as_text()
	return "?"


## Top banner while a boss card pauses the game.
func _draw_intro_hint(sz: Vector2) -> void:
	var m := get_meta_dict()
	if not bool(m.get("intro_wait", false)):
		return
	var me := local_id()
	var done: Array = m.get("intro_done", [])
	var text := tr("HUD_INTRO_WAITING") if me in done else InputGlyphs.fmt("INPUT_INTRO_CONTINUE", ["move", "ultimate"])
	var w := 640.0
	var r := Rect2(Vector2((sz.x - w) * 0.5, 12.0), Vector2(w, 46.0))
	_panel(r, Color(1.0, 0.96, 0.8), 0, Color(0.75, 0.12, 0.12))
	var pulse := 0.75 + 0.25 * sin(_t * 4.0)
	_txt(text, Vector2(r.position.x, r.position.y + 32.0), 26, Color(0.75, 0.12, 0.12, pulse), null, HORIZONTAL_ALIGNMENT_CENTER, w)

