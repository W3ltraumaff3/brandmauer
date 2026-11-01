extends SceneTree
## Dev harness for the in-run view layer (src/view/*). Renders fake ViewStates and
## saves PNG screenshots, then measures the stress case. Needs a real window:
##   godot --path . -s res://tools/view_preview.gd [-- out_dir] [-- only=<shot>]
## Labels drawn here are debug-only (not player-facing).

const DEFAULT_OUT := "C:/Users/Weltr/AppData/Local/Temp/claude/c--PythonProjekte-Rogue-Like-AnticapAntiFa/67c50bb6-ac99-4e3a-8940-ad9037ff683c/scratchpad/view/"

var out_dir := DEFAULT_OUT
var only := ""
var world: WorldView
var fx: Fx
var hud: Hud
var cam: Camera2D
var labels: Node2D
var meta := {}
var report: Array[String] = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
		elif a != "":
			out_dir = a
	if not out_dir.ends_with("/"):
		out_dir += "/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	if root.get_node_or_null("Loc") == null:
		var loc: Node = load("res://src/autoload/loc.gd").new()
		loc.name = "Loc"
		root.add_child(loc)
	root.theme = UITheme.get_theme()
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	world = WorldView.new()
	root.add_child(world)
	fx = Fx.new()
	fx.world = world
	root.add_child(fx)
	labels = Node2D.new()
	root.add_child(labels)
	cam = Camera2D.new()
	root.add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 5
	root.add_child(layer)
	hud = Hud.new()
	hud.world = world
	layer.add_child(hud)
	hud.visible = false
	world.local_id_override = 1
	hud.local_id_override = 1

	var t0 := Time.get_ticks_usec()
	world.prewarm(0)
	report.append("prewarm stage 0: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	t0 = Time.get_ticks_usec()
	world.prewarm(4)
	report.append("prewarm stage 4: %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))

	if _want("overview"):
		for st in 5:
			await _shot_overview(st)
	if _want("enemies"):
		await _shot_enemies(4, "enemies_s4")
		await _shot_enemies(0, "enemies_s0")
	if _want("flags"):
		await _shot_flags()
	if _want("players"):
		await _shot_players()
	if _want("things"):
		await _shot_things()
	if _want("hud"):
		await _shot_hud()
	if _want("fx"):
		await _shot_fx()
	if _want("bubbles"):
		await _shot_bubbles()
	if _want("exits"):
		await _shot_exits()
	if _want("ults"):
		await _shot_ults()
	if _want("ulthud"):
		await _shot_ult_hud()
	if _want("bike"):
		await _shot_bike()
	if _want("weapons"):
		await _shot_new_weapons()
	if _want("stress"):
		await _stress()
	for line in report:
		print("[view_preview] ", line)
	var f := FileAccess.open(out_dir + "report.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(report))
	quit()


func _want(name: String) -> bool:
	return only == "" or only == name


# --- helpers ---------------------------------------------------------------------

func _capture(name: String, frames := 4) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out_dir + name + ".png")
	report.append("saved %s.png" % name)


func _clear_labels() -> void:
	for c in labels.get_children():
		c.queue_free()


func _label(text: String, pos: Vector2, fs := 12) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(0.1, 0.1, 0.6))
	labels.add_child(l)


func _vs(stage: int) -> ViewState:
	var vs := ViewState.new()
	vs.stage = stage
	vs.wave = 7
	vs.wave_time_left = 23.4
	vs.wall = 0xFFF & ~((1 << 3) | (1 << 8))
	return vs


func _enemy(vs: ViewState, type: String, pos: Vector2, flags := 0, hp := 1.0) -> void:
	vs.e_id.append(vs.e_id.size() + 1)
	vs.e_type.append(Content.ENEMY_ORDER.find(type))
	vs.e_pos.append(pos)
	vs.e_hp.append(hp)
	vs.e_flags.append(flags)


func _player(vs: ViewState, id: int, ch: String, pos: Vector2, weapons: Array = [], extra := {}) -> void:
	var wb := PackedByteArray()
	for w in weapons:
		wb.append(Content.WEAPON_ORDER.find(w))
	var p := {"id": id, "char": Content.CHAR_ORDER.find(ch), "pos": pos, "hp": 11.0, "max_hp": 15.0, "state": 0,
		"aim": 0.0, "flags": 0, "followers": 0, "weapons": wb}
	p.merge(extra, true)
	vs.players.append(p)


func _meta(num := 1) -> Dictionary:
	var ps := {}
	var names := ["Rosa", "Kalle", "Ayla", "Jo"]
	for i in num:
		ps[i + 1] = {"name": names[i], "char": "oma", "pfand": 37 + i * 11, "alive": true}
	return {"wave": 7, "phase": 0, "org": "gewerkschaft", "blackrock": false, "kasse": 25, "wall_holes": 2,
		"streik": {"available": true, "active": 0.0},
		"vertrag": {"options": [], "votes": {}, "active": "tempolimit", "waves_left": 2},
		"encounter": "", "team": {"level": 7, "xp": 13.0, "need": 52.0, "stage": 2}, "num_players": num, "players": ps}


func _show(vs: ViewState, center: Vector2, zoom: float, m := {}) -> void:
	world.source_view = vs
	world.source_meta = m
	hud.source_view = vs
	hud.source_meta = m
	cam.position = center
	cam.zoom = Vector2(zoom, zoom)
	cam.reset_smoothing()


# --- shots --------------------------------------------------------------------------

func _shot_overview(st: int) -> void:
	_clear_labels()
	var vs := _vs(st)
	vs.stage = st
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var types := Content.ENEMY_ORDER.slice(0, 13)
	for i in 26:
		_enemy(vs, types[i % types.size()], Vector2(rng.randf_range(150, 1450), rng.randf_range(160, 900)))
	for i in 4:
		_enemy(vs, "besorgter_buerger", Vector2(200 + i * 300, 45))
	_enemy(vs, "ju_schnoesel", Vector2(3.5 * WorldView.SEG_W, 120), ViewState.EF_PARKED)
	for i in 30:
		vs.k_type.append(i % 3)
		vs.k_pos.append(Vector2(rng.randf_range(150, 1450), rng.randf_range(160, 900)))
	for i in 40:
		vs.p_type.append(i % Content.PROJ_ORDER.size())
		vs.p_pos.append(Vector2(rng.randf_range(300, 1300), rng.randf_range(250, 800)))
		vs.p_ang.append(rng.randf() * TAU)
	vs.h_type.append(Content.HAZARD_ORDER.find("kleber")); vs.h_pos.append(Vector2(560, 640)); vs.h_rad.append(60); vs.h_life.append(0.8)
	vs.h_type.append(Content.HAZARD_ORDER.find("mietzone")); vs.h_pos.append(Vector2(1150, 380)); vs.h_rad.append(70); vs.h_life.append(0.8)
	vs.s_type.append(0); vs.s_pos.append(Vector2(700, 760))
	vs.s_type.append(2); vs.s_pos.append(Vector2(1300, 800))
	var chars := ["oma", "antifa", "stadtbild", "lastenrad"]
	for i in 4:
		_player(vs, i + 1, chars[i], Vector2(640 + i * 110, 520), ["stricknadeln", "tofu", "megafon"], {"aim": 0.4 * i, "followers": 5})
	var m := _meta(4)
	m["team"]["stage"] = st
	hud.visible = true
	_show(vs, Vector2(800, 500), 0.8, m)
	await _capture("overview_s%d" % st, 6)
	hud.visible = false


func _shot_enemies(st: int, name: String) -> void:
	_clear_labels()
	var vs := _vs(st)
	var rows := [Content.ENEMY_ORDER.slice(0, 9), Content.ENEMY_ORDER.slice(9, 14), Content.ENEMY_ORDER.slice(14, 17)]
	var y := 120.0
	var spacing := [72.0, 100.0, 150.0]
	for r in rows.size():
		var row: Array = rows[r]
		var x0: float = 800.0 - (row.size() - 1) * float(spacing[r]) * 0.5
		for i in row.size():
			var p := Vector2(x0 + i * spacing[r], y)
			var flags := ViewState.EF_ELITE if r == 2 or row[i] == "sylt_member" else 0
			_enemy(vs, row[i], p, flags, 0.7)
			_label(str(row[i]).substr(0, 12), p + Vector2(-30, 30 if r < 2 else 70), 9)
		y += [95.0, 150.0, 0.0][r]
	vs.players.clear()
	vs.players.append({"id": 9, "char": 0, "pos": Vector2(1400, 700), "state": 2})
	_show(vs, Vector2(800, 240), 1.95)
	await _capture(name)


func _shot_flags() -> void:
	_clear_labels()
	var vs := _vs(4)
	var flags := [0, ViewState.EF_HIT, ViewState.EF_POISONED, ViewState.EF_SLOWED, ViewState.EF_WINDUP,
		ViewState.EF_PARKED, ViewState.EF_SHIELDED, ViewState.EF_BUFFED, ViewState.EF_ELITE]
	var names := ["none", "hit", "poison", "slow", "windup", "parked", "shield", "buffed", "elite"]
	var types := ["besorgter_buerger", "ju_schnoesel", "porsche_suv", "lobbyist"]
	for r in types.size():
		for i in flags.size():
			var p := Vector2(500 + i * 75, 140 + r * 85)
			_enemy(vs, types[r], p, flags[i], 0.6)
			if r == 0:
				_label(names[i], p + Vector2(-20, -70), 10)
	_enemy(vs, "eidgenossin", Vector2(1260, 260), ViewState.EF_ELITE | ViewState.EF_SHIELDED, 0.4)
	_label("eidgenossin shielded", Vector2(1200, 340), 10)
	_show(vs, Vector2(900, 270), 1.6)
	await _capture("enemy_flags")


func _shot_players() -> void:
	_clear_labels()
	for half in 2:
		var vs := _vs(0)
		vs.stage = 4
		var chars := Content.CHAR_ORDER.slice(0, 5) if half == 0 else Content.CHAR_ORDER.slice(5, 9)
		_clear_labels()
		# one row per stage; but stage is global -> render 5 shots? Instead stage per row via separate views.
		await _players_grid(chars, "players_%d" % half)


func _players_grid(chars: Array, name: String) -> void:
	# Stage is global in a ViewState, so draw each stage row in its own pass and stitch.
	var imgs: Array[Image] = []
	for st in 5:
		_clear_labels()
		var vs := _vs(st)
		for i in chars.size():
			var p := Vector2(400 + i * 120, 500)
			var flags := 0
			if st == 1 and i == 0: flags = ViewState.PF_REVERSED
			if st == 2 and i == 1: flags = ViewState.PF_STUNNED
			_player(vs, i + 1, chars[i], p, ["gendersternchen", "doener", "grundgesetz"] if st >= 2 else ["pfandflasche"],
				{"aim": 0.3, "followers": 6 if chars[i] == "stadtbild" else 0, "flags": flags})
			if st == 0:
				_label(chars[i], p + Vector2(-35, 40), 11)
		_show(vs, Vector2(400 + (chars.size() - 1) * 60, 495), 2.0, _meta(1))
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		imgs.append(img.get_region(Rect2i(0, 230, img.get_width(), 260)))
	var out := Image.create(imgs[0].get_width(), imgs[0].get_height() * 5, false, imgs[0].get_format())
	for st in 5:
		out.blit_rect(imgs[st], Rect2i(Vector2i.ZERO, imgs[st].get_size()), Vector2i(0, st * imgs[st].get_height()))
	out.save_png(out_dir + name + ".png")
	report.append("saved %s.png (rows = stage 0..4)" % name)


func _shot_things() -> void:
	_clear_labels()
	var vs := _vs(4)
	for i in Content.PROJ_ORDER.size():
		var p := Vector2(420 + i * 55, 160)
		vs.p_type.append(i); vs.p_pos.append(p); vs.p_ang.append(0.0)
		_label(Content.PROJ_ORDER[i], p + Vector2(-20, 18), 8)
	for i in Content.PICKUP_ORDER.size():
		var p := Vector2(500 + i * 90, 250)
		vs.k_type.append(i); vs.k_pos.append(p)
		_label(Content.PICKUP_ORDER[i], p + Vector2(-25, 18), 9)
	for i in Content.SUMMON_ORDER.size():
		var p := Vector2(1000 + i * 110, 290)
		vs.s_type.append(i); vs.s_pos.append(p)
		_label(Content.SUMMON_ORDER[i], p + Vector2(-25, 22), 9)
	# weapons as a fan on a player
	_player(vs, 1, "gewerkschaft", Vector2(1180, 480), Content.WEAPON_ORDER.slice(0, 6), {"aim": 0.0})
	_player(vs, 2, "antifa", Vector2(1300, 480), Content.WEAPON_ORDER.slice(6, 12), {"aim": PI})
	var hz := [["kleber", Vector2(430, 380), 50.0, 0.8], ["mietzone", Vector2(560, 390), 55.0, 0.8], ["kerosin", Vector2(680, 380), 28.0, 0.8],
		["lob_marker", Vector2(770, 380), 45.0, 0.4], ["sitzblockade", Vector2(910, 390), 70.0, 0.8], ["explosion", Vector2(1050, 390), 55.0, 0.5],
		["farbklecks", Vector2(1150, 380), 50.0, 0.8]]
	for h in hz:
		vs.h_type.append(Content.HAZARD_ORDER.find(h[0])); vs.h_pos.append(h[1]); vs.h_rad.append(h[2]); vs.h_life.append(h[3])
		_label(h[0], h[1] + Vector2(-25, 50), 9)
	_show(vs, Vector2(830, 330), 1.5)
	await _capture("things")
	# Weapon icons: draw directly (players hold them). Second shot: ring + Abschiebezone + push ring.
	_clear_labels()
	var vs2 := _vs(3)
	vs2.h_type.append(Content.HAZARD_ORDER.find("abschiebezone")); vs2.h_pos.append(Vector2(800, 137)); vs2.h_rad.append(35); vs2.h_life.append(1.0)
	vs2.h_type.append(Content.HAZARD_ORDER.find("push_ring")); vs2.h_pos.append(Vector2(800, 520)); vs2.h_rad.append(220); vs2.h_life.append(0.7)
	_enemy(vs2, "eidgenossin", Vector2(800, 520), ViewState.EF_ELITE)
	_player(vs2, 1, "klimakleber", Vector2(600, 300), ["kleber", "tofu"], {"flags": ViewState.PF_STILL})
	_player(vs2, 2, "oma", Vector2(1000, 640), [], {"state": 1, "revive": 0.6})
	_player(vs2, 3, "sozialtourist", Vector2(1100, 400), ["pfandflasche"], {"flags": ViewState.PF_INVULNERABLE | ViewState.PF_REVERSED})
	vs2.boss = {"enc": 3, "hp": 0.55, "phase": 1, "shield": 0.0}
	_show(vs2, Vector2(800, 420), 1.0, _meta(3))
	await _capture("hazards_boss_phase2")
	# Circus tent (Sauerländer phase 3)
	var vs3 := _vs(2)
	_enemy(vs3, "sauerlaender", Vector2(800, 500), ViewState.EF_ELITE)
	vs3.boss = {"enc": 2, "hp": 0.2, "phase": 2, "shield": 0.0}
	for i in 6:
		vs3.p_type.append(Content.PROJ_ORDER.find("zirkusball")); vs3.p_pos.append(Vector2(600 + i * 70, 650)); vs3.p_ang.append(0.0)
	_show(vs3, Vector2(800, 500), 0.8)
	await _capture("circus")


func _shot_hud() -> void:
	_clear_labels()
	hud.visible = true
	var vs := _vs(3)
	_player(vs, 1, "oma", Vector2(800, 500), ["stricknadeln"])
	_player(vs, 2, "antifa", Vector2(900, 520), [], {"state": 1, "hp": 0.0})
	_player(vs, 3, "lastenrad", Vector2(700, 540), [], {"hp": 6.0})
	_enemy(vs, "geschichtslehrer", Vector2(800, 300), ViewState.EF_ELITE)
	vs.boss = {"enc": 1, "hp": 0.62, "phase": 1, "shield": 0.0}
	var m := _meta(3)
	_show(vs, Vector2(800, 450), 1.0, m)
	hud.handle_event(["levelup", 8])
	hud.handle_event(["ach", 1, "ach_180"])
	hud.handle_event(["deny", 1, "DENY_NO_PFAND"])
	hud.preview_overlay_t = 0.8
	await _capture("hud_coop_boss")
	hud._overlays.clear()
	hud._toasts.clear()
	for enc in Content.ENCOUNTER_ORDER:
		hud.handle_event(["card", enc])
		hud.preview_overlay_t = 1.5
		await _capture("card_" + enc)
		hud._overlays.clear()
	for ev in [["wende", 4.0], ["streik", 5.0], ["stage", 3], ["wave_start", 12], ["wave_end", 12], ["wave_start", 20], ["over", true]]:
		hud.handle_event(ev)
		hud.preview_overlay_t = 0.9
		await _capture("overlay_%s_%s" % [ev[0], str(ev[1])])
		hud._overlays.clear()
	hud.preview_overlay_t = -1.0
	# Wave 20 timer + blackrock + Funkloch, single player
	var vs2 := _vs(4)
	vs2.wave = 20
	vs2.wave_time_left = -1.0
	_player(vs2, 1, "buergergeld", Vector2(800, 500), ["gendersternchen", "tofu"])
	_enemy(vs2, "eidgenossin", Vector2(800, 330), ViewState.EF_ELITE | ViewState.EF_SHIELDED)
	vs2.boss = {"enc": 3, "hp": 0.3, "phase": 2, "shield": 0.7}
	vs2.e_pos[0] = Vector2(800, 250)
	var m2 := _meta(1)
	m2["blackrock"] = true
	m2["streik"] = {"available": false, "active": 3.2}
	m2["vertrag"] = {"active": ""}
	m2["team"]["stage"] = 4
	hud._koal_time = 137.0
	_show(vs2, Vector2(800, 450), 1.0, m2)
	hud.trigger_funkloch()
	await _capture("hud_wave20_funkloch")
	# Connection loss (networking.md §7.4): away teammate + own reconnect indicator.
	var vs3 := _vs(3)
	_player(vs3, 1, "oma", Vector2(800, 500), ["stricknadeln"])
	_player(vs3, 2, "antifa", Vector2(900, 520), [], {"state": 3})
	_player(vs3, 3, "lastenrad", Vector2(700, 540), [])
	_show(vs3, Vector2(800, 450), 1.0, _meta(3))
	hud.handle_event(["away", 2])
	hud.preview_reconnect_left = 47.0
	await _capture("hud_reconnecting")
	hud.preview_reconnect_left = -1.0
	hud._toasts.clear()
	hud.visible = false


func _shot_fx() -> void:
	_clear_labels()
	var vs := _vs(4)
	_player(vs, 1, "gewerkschaft", Vector2(800, 520), ["megafon"])
	_enemy(vs, "besorgter_buerger", Vector2(640, 420))
	_enemy(vs, "lobbyist", Vector2(980, 420))
	_enemy(vs, "hinterbaenkler", Vector2(700, 640))
	_show(vs, Vector2(800, 500), 1.3)
	fx.handle_event(["say", Vector2(640, 420), "SAY_BESORGT_1", ""])
	fx.handle_event(["say", Vector2(980, 420), "", "amthor-01"])
	fx.handle_event(["say", Vector2(700, 640), "", "merz-12"])
	for i in 6:
		fx.handle_event(["dmg", Vector2(620 + i * 20, 400), 7 + i * 3, i == 2, false])
	fx.handle_event(["dmg", Vector2(800, 480), 4, false, true])
	fx.handle_event(["kill", Vector2(900, 560), 0])
	fx.handle_event(["swing", Vector2(800, 510), 0.0, 130.0, 25.0, "doener"])
	fx.handle_event(["swing", Vector2(800, 510), PI, 200.0, 60.0, "megafon"])
	fx.handle_event(["swing", Vector2(800, 510), PI * 0.5, 110.0, 360.0, "transparent"])
	await _capture("fx", 6)


## Option `bubble_opacity` (architecture §11): enemy chatter fades with it,
## status bubbles (Verspätung, Schwarz gefahren!) stay readable; 0 hides all.
func _shot_bubbles() -> void:
	_clear_labels()
	var vs := _vs(2)
	_player(vs, 1, "gewerkschaft", Vector2(800, 520), ["megafon"])
	_enemy(vs, "besorgter_buerger", Vector2(620, 420))
	_enemy(vs, "telegram_onkel", Vector2(990, 430))
	_enemy(vs, "ju_schnoesel", Vector2(660, 650))
	_show(vs, Vector2(800, 520), 1.3)
	for op in [1.0, 0.3, 0.0]:
		_fx_reset()
		fx.bubble_opacity_override = op if op > 0.0 else 0.3
		fx.handle_event(["say", Vector2(620, 420), "SAY_BESORGT_1", ""])
		fx.handle_event(["say", Vector2(990, 430), "SAY_TELEGRAM_1", ""])
		fx.handle_event(["say", Vector2(660, 650), "SAY_JU_1", ""])
		fx.handle_event(["say", Vector2(800, 520), "SAY_VERSPAETUNG", ""])
		fx.handle_event(["say", Vector2(940, 640), "SAY_DODGE", ""])
		for b in fx._bubbles:
			b["t"] = 1.0
		# 0 %: bubbles already on screen vanish live, new ones are not added.
		fx.bubble_opacity_override = op
		_label("bubble_opacity = %d %%  (debug)" % int(op * 100), Vector2(330, 750), 16)
		await _capture("bubbles_%d" % int(op * 100), 3)
		_clear_labels()
	fx.bubble_opacity_override = -1.0
	_fx_reset()


func _shot_exits() -> void:
	_clear_labels()
	var vs := _vs(4)
	_show(vs, Vector2(800, 500), 0.9)
	world._exits.clear()
	fx._bubbles.clear()
	fx._numbers.clear()
	fx._swings.clear()
	fx._puffs.clear()
	world.handle_event(["exit", "sylt_clique", Vector2(350, 350)])
	world.handle_event(["exit", "geschichtslehrer", Vector2(900, 420)])
	world.handle_event(["exit", "sauerlaender", Vector2(350, 780)])
	world.handle_event(["exit", "eidgenossin", Vector2(1050, 780)])
	world._exits[0]["t"] = 1.2
	world._exits[1]["t"] = 1.4
	world._exits[2]["t"] = 1.0
	world._exits[3]["t"] = 1.5
	world.set_process(false)
	world.queue_redraw()
	await _capture("exits")
	world._exits[2]["t"] = 3.0
	world._exits[0]["t"] = 3.5
	world.queue_redraw()
	await _capture("exits_jet_parachute")
	world._exits.clear()
	world.set_process(true)


# --- ultimates (architecture §9) ---------------------------------------------------------

func _fx_reset() -> void:
	fx._ults.clear()
	fx._bubbles.clear()
	fx._numbers.clear()
	fx._swings.clear()
	fx._puffs.clear()
	fx._marks.clear()
	fx._chains.clear()
	fx._beams.clear()
	fx._whistles.clear()
	fx.queue_redraw()


## Send an ult event to world/fx/hud and freeze its fx clock at `t`.
func _fire_ult(peer: int, id: String, pos: Vector2, t: float) -> void:
	var ev := ["ult", peer, id, pos]
	world.handle_event(ev)
	fx.handle_event(ev)
	hud.handle_event(ev)
	if not fx._ults.is_empty():
		fx._ults[fx._ults.size() - 1]["t"] = t
	fx.queue_redraw()


func _ult_meta(ult: String, ready: bool, num := 1) -> Dictionary:
	var m := _meta(num)
	m["players"][1]["ult"] = ult
	m["players"][1]["ult_ready"] = ready
	m["streik"] = {"available": false, "active": 0.0}
	return m


func _ring_enemies(vs: ViewState, c: Vector2, r: float, types: Array, flags: int, n := 10) -> void:
	for i in n:
		var a := TAU * i / n + 0.3
		_enemy(vs, types[i % types.size()], c + Vector2(cos(a) * r, sin(a) * r * 0.75), flags)


func _shot_ults() -> void:
	fx.set_process(false)
	var slowed := ViewState.EF_SLOWED
	# 1 Flashmob
	_clear_labels(); _fx_reset()
	var vs := _vs(4)
	_player(vs, 1, "stadtbild", Vector2(800, 520), ["doener"], {"followers": 8})
	_ring_enemies(vs, Vector2(800, 520), 250, ["besorgter_buerger", "telegram_onkel", "ju_schnoesel"], slowed, 12)
	_show(vs, Vector2(800, 500), 1.0, _ult_meta("flashmob", false))
	world.antrag_vis = 0.0
	_fire_ult(1, "flashmob", Vector2(800, 520), 0.32)
	await _capture("ult_flashmob")
	fx._ults[0]["t"] = 0.9
	fx.queue_redraw()
	await _capture("ult_flashmob_late")
	# 2 Urlaubsantrag (facing right and left)
	_fx_reset()
	vs = _vs(4)
	_player(vs, 1, "sozialtourist", Vector2(740, 500), ["pfandflasche"], {"flags": ViewState.PF_ULT | ViewState.PF_INVULNERABLE})
	_player(vs, 2, "sozialtourist", Vector2(900, 500), ["pfandflasche"], {"flags": ViewState.PF_ULT | ViewState.PF_INVULNERABLE, "aim": PI})
	_enemy(vs, "besorgter_buerger", Vector2(640, 470))
	_enemy(vs, "lobbyist", Vector2(1000, 520))
	_show(vs, Vector2(820, 470), 2.0, _ult_meta("urlaubsantrag", false, 2))
	_fire_ult(1, "urlaubsantrag", Vector2(740, 500), 0.6)
	await _capture("ult_urlaubsantrag")
	# 3 Antrag gestellt (+ HUD effect chip)
	_fx_reset()
	vs = _vs(3)
	_player(vs, 1, "buergergeld", Vector2(800, 520), ["gendersternchen"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 22:
		_enemy(vs, Content.ENEMY_ORDER[i % 10], Vector2(rng.randf_range(380, 1220), rng.randf_range(250, 800)), slowed)
	var m := _ult_meta("antrag_gestellt", false)
	m["effects"] = {"antrag_gestellt": 4.2}
	hud.visible = true
	_show(vs, Vector2(800, 520), 1.0, m)
	world.antrag_vis = 1.0
	_fire_ult(1, "antrag_gestellt", Vector2(800, 520), 0.45)
	await _capture("ult_antrag_gestellt")
	hud.visible = false
	world.antrag_vis = 0.0
	# 4 Straßenblockade
	_fx_reset()
	vs = _vs(4)
	_player(vs, 1, "klimakleber", Vector2(800, 520), ["kleber"], {"flags": ViewState.PF_STILL})
	var x := 23.0
	while x < 1600.0:
		vs.h_type.append(Content.HAZARD_ORDER.find("kleber")); vs.h_pos.append(Vector2(x, 520)); vs.h_rad.append(46.0); vs.h_life.append(0.9)
		x += 70.0
	for i in 8:
		_enemy(vs, ["besorgter_buerger", "porsche_suv", "lobbyist", "hinterbaenkler"][i % 4], Vector2(420 + i * 110, 505 + (i % 2) * 20), slowed)
	_show(vs, Vector2(800, 480), 0.85, _ult_meta("strassenblockade", false))
	_fire_ult(1, "strassenblockade", Vector2(800, 520), 0.9)
	await _capture("ult_strassenblockade")
	# 5 Critical Mass (moving right, and one moving up-left)
	_fx_reset()
	vs = _vs(4)
	_player(vs, 1, "lastenrad", Vector2(860, 480), ["megafon"], {"flags": ViewState.PF_ULT, "aim": 0.0})
	_player(vs, 2, "lastenrad", Vector2(700, 600), ["megafon"], {"flags": ViewState.PF_ULT, "aim": PI * 1.2})
	_enemy(vs, "porsche_suv", Vector2(1000, 470), slowed)
	_show(vs, Vector2(800, 500), 1.6, _ult_meta("critical_mass", false, 2))
	world._p_prev.clear()
	world._p_heading.clear()
	_fire_ult(1, "critical_mass", Vector2(860, 480), 0.4)
	await _capture("ult_critical_mass")
	# 6 Tarifrunde (+ HUD chip)
	_fx_reset()
	vs = _vs(3)
	_player(vs, 1, "gewerkschaft", Vector2(760, 520), ["megafon"])
	_player(vs, 2, "oma", Vector2(880, 540), ["stricknadeln"])
	_player(vs, 3, "lastenrad", Vector2(660, 580), ["tofu"])
	vs.s_type.append(Content.SUMMON_ORDER.find("infostand")); vs.s_pos.append(Vector2(980, 460))
	m = _ult_meta("tarifrunde", false, 3)
	m["effects"] = {"tarifrunde": 5.3}
	hud.visible = true
	_show(vs, Vector2(800, 500), 1.3, m)
	_fire_ult(1, "tarifrunde", Vector2(760, 520), 0.5)
	await _capture("ult_tarifrunde")
	hud.visible = false
	# 7 Schwarzer Block
	_fx_reset()
	vs = _vs(4)
	_player(vs, 1, "antifa", Vector2(800, 520), ["farbbeutel"])
	for i in 6:
		var a := TAU * i / 6.0 + 0.2
		vs.s_type.append(Content.SUMMON_ORDER.find("genosse"))
		vs.s_pos.append(Vector2(800, 520) + Vector2(cos(a) * 120, sin(a) * 85))
	_ring_enemies(vs, Vector2(800, 520), 230, ["besorgter_buerger", "identitaerer_hipster", "reichsbuerger"], 0, 8)
	_show(vs, Vector2(800, 500), 1.4, _ult_meta("schwarzer_block", false))
	_fire_ult(1, "schwarzer_block", Vector2(800, 520), 0.5)
	await _capture("ult_schwarzer_block")
	# genosse close-up
	_fx_reset()
	vs = _vs(4)
	for i in 3:
		vs.s_type.append(Content.SUMMON_ORDER.find("genosse")); vs.s_pos.append(Vector2(760 + i * 50, 500))
	_player(vs, 1, "antifa", Vector2(700, 500), [])
	_show(vs, Vector2(790, 485), 3.5, _ult_meta("schwarzer_block", false))
	await _capture("ult_genosse_closeup")
	# 8 Kaffee und Kuchen
	_fx_reset()
	vs = _vs(4)
	_player(vs, 1, "oma", Vector2(720, 520), ["stricknadeln"])
	_player(vs, 2, "klimakleber", Vector2(860, 500), ["kleber"])
	_player(vs, 3, "buergergeld", Vector2(800, 640), ["tofu"])
	_show(vs, Vector2(790, 540), 1.6, _ult_meta("kaffee_und_kuchen", false, 3))
	_fire_ult(1, "kaffee_und_kuchen", Vector2(720, 520), 0.7)
	await _capture("ult_kaffee_und_kuchen")
	# 9 Fragen Sie mal uns
	_fx_reset()
	vs = _vs(4)
	_player(vs, 1, "toechter", Vector2(800, 560), ["transparent"])
	var suits := ["hinterbaenkler", "lobbyist", "ju_schnoesel", "golfclub_vorstand", "fdp_jungunternehmer", "immobilienerbe"]
	for i in suits.size():
		_enemy(vs, suits[i], Vector2(560 + i * 95, 360 + (i % 2) * 40), ViewState.EF_BUFFED | slowed)
	_enemy(vs, "besorgter_buerger", Vector2(1100, 600))
	_enemy(vs, "telegram_onkel", Vector2(500, 640))
	_show(vs, Vector2(800, 480), 1.2, _ult_meta("fragen_sie_uns", false))
	_fire_ult(1, "fragen_sie_uns", Vector2(800, 560), 0.55)
	await _capture("ult_fragen_sie_uns")
	_fx_reset()
	fx.set_process(true)


func _shot_ult_hud() -> void:
	_clear_labels()
	_fx_reset()
	hud.visible = true
	hud.set_process(false)
	var vs := _vs(3)
	_player(vs, 1, "stadtbild", Vector2(800, 500), ["doener"], {"followers": 4})
	_show(vs, Vector2(800, 450), 1.0, _ult_meta("flashmob", true))
	hud._ult_ready_prev = true
	hud._ult_pop = -1.0
	hud.queue_redraw()
	await _capture("hud_ult_ready")
	hud._ult_pop = 0.22
	hud.queue_redraw()
	await _capture("hud_ult_ready_pop")
	hud._ult_pop = -1.0
	vs = _vs(3)
	_player(vs, 1, "toechter", Vector2(800, 500), ["transparent"])
	_show(vs, Vector2(800, 450), 1.0, _ult_meta("fragen_sie_uns", false))
	hud.queue_redraw()
	await _capture("hud_ult_used")
	var m := _ult_meta("tarifrunde", true)
	m["effects"] = {"tarifrunde": 6.4, "antrag_gestellt": 2.1}
	vs = _vs(3)
	_player(vs, 1, "gewerkschaft", Vector2(800, 500), ["megafon"])
	_show(vs, Vector2(800, 450), 1.0, m)
	hud.queue_redraw()
	await _capture("hud_ult_effects")
	# boss intro: panel hidden, card shows "W/A/S/D or Space"
	m = _ult_meta("tarifrunde", true)
	m["intro_wait"] = true
	m["intro_done"] = []
	vs = _vs(3)
	_player(vs, 1, "gewerkschaft", Vector2(800, 500), ["megafon"])
	_show(vs, Vector2(800, 450), 1.0, m)
	hud.handle_event(["card", "sauerlaender"])
	hud.preview_overlay_t = 1.5
	hud.queue_redraw()
	await _capture("hud_ult_intro_hidden")
	hud._overlays.clear()
	hud.preview_overlay_t = -1.0
	hud.set_process(true)
	hud.visible = false


## Lastenrad close-ups: one row per Zusammenhalt stage (facing right / left),
## then two bikes in motion (close and at game zoom).
func _shot_bike() -> void:
	_clear_labels()
	_fx_reset()
	var imgs: Array[Image] = []
	for st in 5:
		var vs := _vs(st)
		_player(vs, 1, "lastenrad", Vector2(700, 500), ["megafon"] if st >= 2 else [], {"aim": 0.0})
		_player(vs, 2, "lastenrad", Vector2(860, 500), [], {"aim": PI})
		world._p_prev.clear()
		world._p_heading.clear()
		_show(vs, Vector2(780, 490), 3.0, _meta(1))
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		imgs.append(img.get_region(Rect2i(0, 190, img.get_width(), 290)))
	var out := Image.create(imgs[0].get_width(), imgs[0].get_height() * 5, false, imgs[0].get_format())
	for st in 5:
		out.blit_rect(imgs[st], Rect2i(Vector2i.ZERO, imgs[st].get_size()), Vector2i(0, st * imgs[st].get_height()))
	out.save_png(out_dir + "bike_stages.png")
	report.append("saved bike_stages.png (rows = stage 0..4)")
	# in motion: one riding right, one riding up-left, positions advance every frame
	for st in [4, 0]:
		var vs := _vs(st)
		_player(vs, 1, "lastenrad", Vector2(600, 470), ["megafon", "tofu"], {"aim": 0.0})
		_player(vs, 2, "lastenrad", Vector2(990, 610), ["kleber"], {"aim": 0.0})
		world._p_prev.clear()
		world._p_heading.clear()
		_show(vs, Vector2(780, 510), 2.6, _meta(2))
		for i in 30:
			vs.players[0]["pos"] = Vector2(600, 470) + Vector2(4.0, 0.0) * i
			vs.players[1]["pos"] = Vector2(990, 610) + Vector2(-3.4, -1.2) * i
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out_dir + "bike_motion_s%d.png" % st)
		report.append("saved bike_motion_s%d.png" % st)
	# game zoom, three bikes riding among enemies
	var vs2 := _vs(3)
	_player(vs2, 1, "lastenrad", Vector2(520, 520), ["megafon", "tofu", "doener"], {"aim": 0.0})
	_player(vs2, 2, "lastenrad", Vector2(1080, 640), ["kleber"], {"aim": PI})
	_player(vs2, 3, "oma", Vector2(800, 380), ["stricknadeln"])
	for i in 10:
		_enemy(vs2, Content.ENEMY_ORDER[i % 7], Vector2(420 + i * 85, 300 + (i % 3) * 170))
	world._p_prev.clear()
	world._p_heading.clear()
	_show(vs2, Vector2(780, 500), 0.92, _meta(3))
	for i in 20:
		vs2.players[0]["pos"] = Vector2(520, 520) + Vector2(5.0, 1.0) * i
		vs2.players[1]["pos"] = Vector2(1080, 640) + Vector2(-5.0, 0.0) * i
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir + "bike_gamezoom.png")
	report.append("saved bike_gamezoom.png")
	world._p_prev.clear()
	world._p_heading.clear()


## GDD §11 "New weapons": every new weapon in action (overview), then a
## close-up per weapon plus the held icons.
const NEW_WEAPONS := ["kartoffelbrei", "trillerpfeife", "brandmauer_ziegel", "normenkontrolle",
	"unterschriftenliste", "scheinwerfer", "neun_euro_ticket", "weisser_overall"]


func _hz(vs: ViewState, id: String, pos: Vector2, r: float, life: float) -> void:
	vs.h_type.append(Content.HAZARD_ORDER.find(id)); vs.h_pos.append(pos); vs.h_rad.append(r); vs.h_life.append(life)


func _weapons_vs() -> ViewState:
	var vs := _vs(4)
	vs.wall = 0xFFF
	# Kartoffelbrei: blob in flight above its target marker, plus a fresh splat
	_player(vs, 1, "oma", Vector2(200, 330), ["kartoffelbrei"], {"aim": 0.0})
	_hz(vs, "brei_marker", Vector2(440, 330), 110.0 * 0.6, 0.5)
	vs.p_type.append(Content.PROJ_ORDER.find("kartoffelbrei")); vs.p_pos.append(Vector2(320, 330)); vs.p_ang.append(0.0)
	_hz(vs, "explosion", Vector2(330, 500), 66.0, 0.6)
	_enemy(vs, "besorgter_buerger", Vector2(460, 350))
	_enemy(vs, "ju_schnoesel", Vector2(350, 520))
	_label("kartoffelbrei (lob + marker) / splat", Vector2(150, 230), 11)
	# Trillerpfeife: 360° whistle
	_player(vs, 2, "gewerkschaft", Vector2(720, 330), ["trillerpfeife"], {"aim": 0.0})
	_enemy(vs, "telegram_onkel", Vector2(640, 290))
	_enemy(vs, "hinterbaenkler", Vector2(810, 370))
	_label("trillerpfeife", Vector2(680, 200), 11)
	# Brandmauer-Ziegel: a wall across a horizontal aim (vertical row) and across an upward aim
	for k in 5:
		_hz(vs, "ziegel", Vector2(1060, 300 + (k - 2) * 35.0), 20.0, 0.7)
		_hz(vs, "ziegel", Vector2(1290 + (k - 2) * 35.0, 290), 20.0, 0.5 if k != 4 else 0.97)
	_enemy(vs, "besorgter_buerger", Vector2(1090, 320), ViewState.EF_SLOWED)
	_enemy(vs, "lobbyist", Vector2(1300, 300), ViewState.EF_SLOWED)
	_label("brandmauer_ziegel (2 walls)", Vector2(1080, 170), 11)
	# Normenkontrolle: § stamps with countdown (one almost due)
	_enemy(vs, "lobbyist", Vector2(220, 660))
	_hz(vs, "paragraf", Vector2(220, 660), 27.0, 0.65)
	_enemy(vs, "reichsbuerger", Vector2(410, 690))
	_hz(vs, "paragraf", Vector2(410, 690), 36.0, 0.22)
	_label("normenkontrolle", Vector2(250, 560), 11)
	# Unterschriftenliste: chain through four signers
	_player(vs, 3, "antifa", Vector2(600, 640), ["unterschriftenliste"], {"aim": 0.0})
	for p in [Vector2(690, 600), Vector2(770, 670), Vector2(850, 600), Vector2(930, 660)]:
		_enemy(vs, "besorgter_buerger", p)
	_label("unterschriftenliste", Vector2(700, 540), 11)
	# Scheinwerfer: beam along the aim
	_player(vs, 4, "klimakleber", Vector2(1040, 640), ["scheinwerfer"], {"aim": 0.0})
	for p in [Vector2(1150, 630), Vector2(1280, 655), Vector2(1400, 640)]:
		_enemy(vs, "fdp_jungunternehmer", p)
	_label("scheinwerfer", Vector2(1200, 560), 11)
	# 9-Euro-Ticket: fan of nine tickets
	_player(vs, 5, "sozialtourist", Vector2(220, 880), ["neun_euro_ticket"], {"aim": 0.0})
	for k in 9:
		var a := -PI / 6.0 + PI / 3.0 * k / 8.0
		vs.p_type.append(Content.PROJ_ORDER.find("ticket")); vs.p_pos.append(Vector2(220, 880) + Vector2.RIGHT.rotated(a) * 70.0)
		vs.p_ang.append(a)
	_label("neun_euro_ticket", Vector2(220, 790), 11)
	# Weißer Overall: three activists sprinting at enemies
	_player(vs, 6, "buergergeld", Vector2(640, 880), ["weisser_overall"], {"aim": 0.0})
	for p in [Vector2(730, 850), Vector2(770, 900), Vector2(710, 930)]:
		vs.s_type.append(Content.SUMMON_ORDER.find("overall")); vs.s_pos.append(p)
	_enemy(vs, "porsche_suv", Vector2(880, 880))
	_label("weisser_overall", Vector2(700, 790), 11)
	# held icons: all eight new weapons in the fans
	_player(vs, 7, "lastenrad", Vector2(1160, 880), NEW_WEAPONS.slice(0, 7), {"aim": 0.0})
	_player(vs, 8, "toechter", Vector2(1380, 880), [NEW_WEAPONS[7], NEW_WEAPONS[0], NEW_WEAPONS[5]], {"aim": PI})
	_label("held icons", Vector2(1230, 790), 11)
	return vs


## Fire the one-shot fx of the new weapons and park their clocks mid-effect.
func _weapons_fx() -> void:
	_fx_reset()
	fx.handle_event(["swing", Vector2(720, 330), 0.0, 150.0, 360.0, "trillerpfeife"])
	fx.handle_event(["chain", [Vector2(600, 640), Vector2(690, 600), Vector2(770, 670), Vector2(850, 600), Vector2(930, 660)]])
	fx.handle_event(["beam", Vector2(1040, 640), Vector2(1440, 640)])
	fx._whistles[-1]["t"] = 0.16
	fx._chains[-1]["t"] = 0.12
	fx._beams[-1]["t"] = 0.0
	# the splat at (330, 500) belongs to a Kartoffelbrei that just landed
	world._brei_seen[Vector2i(330, 500)] = world.anim_time


func _shot_new_weapons() -> void:
	_clear_labels()
	var vs := _weapons_vs()
	_show(vs, Vector2(800, 560), 0.78, _meta(1))
	for i in 3:
		await process_frame  # bake every mesh first, so the fx clocks don't jump
	_weapons_fx()
	await _capture("weapons_overview", 3)
	_clear_labels()
	var shots := [["kartoffelbrei", Vector2(330, 400), 2.0], ["trillerpfeife", Vector2(720, 300), 2.2],
		["ziegel", Vector2(1180, 290), 2.2], ["normenkontrolle", Vector2(320, 640), 2.4],
		["unterschriftenliste", Vector2(765, 620), 2.4], ["scheinwerfer", Vector2(1240, 630), 1.9],
		["neun_euro_ticket", Vector2(280, 870), 2.8], ["weisser_overall", Vector2(760, 880), 2.8],
		["icons", Vector2(1270, 860), 3.0]]
	for s in shots:
		_show(vs, s[1], s[2], _meta(1))
		_weapons_fx()
		await _capture("weapon_%s" % s[0], 3)


func _stress() -> void:
	_clear_labels()
	var vs := _vs(4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var view := Rect2(800 - 690, 500 - 390, 1380, 780)
	var reg := Content.ENEMY_ORDER.slice(0, 14)
	for i in 250:
		var fl := 0
		if i % 7 == 0: fl |= ViewState.EF_HIT
		if i % 11 == 0: fl |= ViewState.EF_POISONED
		if i % 13 == 0: fl |= ViewState.EF_SLOWED
		if i % 29 == 0: fl |= ViewState.EF_ELITE
		_enemy(vs, reg[i % reg.size()], view.position + Vector2(rng.randf() * view.size.x, rng.randf() * view.size.y), fl)
	for i in 400:
		vs.p_type.append(i % Content.PROJ_ORDER.size())
		vs.p_pos.append(view.position + Vector2(rng.randf() * view.size.x, rng.randf() * view.size.y))
		vs.p_ang.append(rng.randf() * TAU)
	for i in 300:
		vs.k_type.append(i % Content.PICKUP_ORDER.size())
		vs.k_pos.append(view.position + Vector2(rng.randf() * view.size.x, rng.randf() * view.size.y))
	for i in 4:
		_player(vs, i + 1, Content.CHAR_ORDER[i * 2], Vector2(700 + i * 60, 500), Content.WEAPON_ORDER.slice(0, 6), {"followers": 8})
	for i in 6:
		vs.h_type.append(i); vs.h_pos.append(Vector2(300 + i * 200, 700)); vs.h_rad.append(60); vs.h_life.append(0.6)
	hud.visible = true
	_show(vs, Vector2(800, 500), 0.92, _meta(4))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for i in 30:
		await process_frame
	var draw_sum := 0.0
	var draw_max := 0.0
	var cpu_sum := 0.0
	var gpu_sum := 0.0
	var n := 240
	var t_start := Time.get_ticks_usec()
	for i in n:
		await process_frame
		draw_sum += world.draw_usec
		draw_max = maxf(draw_max, world.draw_usec)
		cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		gpu_sum += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	var wall := (Time.get_ticks_usec() - t_start) / 1000.0 / n
	report.append("STRESS 250 enemies / 400 projectiles / 300 pickups / 4 players / 6 hazards:")
	report.append("  WorldView._draw (GDScript, command recording): avg %.2f ms, max %.2f ms" % [draw_sum / n / 1000.0, draw_max / 1000.0])
	report.append("  render cpu %.2f ms, gpu %.2f ms per frame" % [cpu_sum / n, gpu_sum / n])
	report.append("  full frame (vsync off): %.2f ms  => %.0f fps" % [wall, 1000.0 / wall])
	await _capture("stress", 2)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	hud.visible = false
