extends TestCase
## Die Remigrantin as the final exam (GDD §14 "Final boss", D-140 to D-145):
## Ansturm-Kette with falling turbines, Reichweite (safe only in front of the
## intact Brandmauer), Briefkastenfirmen feeding her shield, Wahlabend, the
## snapshot field and the view contract.

const AREAS := ["sim", "view"]
const DT := 1.0 / 60.0


func _sim(chars: Array, level := 0, seed := 7) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": "gewerkschaft", "difficulty": level, "skip_intro": true})
	s.enemies.clear()
	for p in s.players.values():
		p.weapons.clear()
		p.stats["dodge"] = 0.0
		p.stats["armor"] = 0.0
		p.pos = Arena.CENTER + Vector2(0, 300)
	return s


## Die Remigrantin as in wave 20, no regular spawns, big HP so nothing ends early.
func _boss(s: Sim) -> Sim.SimEnemy:
	s._begin_wave(20, "eidgenossin")
	s.diff["spawn"] = 0.0
	s.encounter_pending = 0.0001
	s._step_encounter_spawn(0.001)
	s.enemies = s.enemies.filter(func(e): return e.encounter != "")
	for p in s.players.values():
		p.weapons.clear()
		p.pos = Arena.CENTER + Vector2(0, 300)
	var b: Sim.SimEnemy = s.enemies[0]
	b.max_hp = 1.0e7
	b.hp = b.max_hp
	s._build_grid()
	return b


func _run(s: Sim, seconds: float, safe := true) -> void:
	for i in int(round(seconds / DT)):
		if safe:
			for p in s.players.values():
				p.iframes = 10.0
		s.step(DT)


## Takes her to phase `ph` (0..2) past the Pressekonferenz.
func _to_phase(s: Sim, b: Sim.SimEnemy, ph: int) -> void:
	for i in ph:
		s._damage_enemy(b, b.max_hp, null)
		_run(s, 2.6)
	s.take_events()


func _hazards(s: Sim, id: String) -> Array:
	return s.hazards.filter(func(h): return h.alive and h.type == Content.idx(Content.HAZARD_ORDER, id))


# --- P1: Ansturm-Kette (D-143) ----------------------------------------------------

func test_ansturm_kette_length_by_level_and_players() -> void:
	assert_eq(_sim(["oma"], 0).kette_len(), 2, "2 charges")
	assert_eq(_sim(["oma"], 4).kette_len(), 3, "3 from Umfrage 30 %")
	assert_eq(_sim(["oma", "oma", "oma"], 0).kette_len(), 3, "+1 from 3 players")
	assert_eq(_sim(["oma", "oma", "oma", "oma"], 4).kette_len(), 4)


func test_ansturm_kette_lane_telegraph_then_chained_charges() -> void:
	var s := _sim(["oma"])
	var b := _boss(s)
	b.pos = Arena.CENTER + Vector2(-500, -200)
	s.summons.clear()   # no turbine to draw the charge
	var starts := 0
	var lane_seen := false
	var was := ""
	var p: Sim.SimPlayer = s.players[1]
	for i in int(12.0 / DT):
		p.iframes = 10.0
		p.pos = Arena.CENTER + Vector2(650.0 * cos(i * DT * 0.6), 380.0 * sin(i * DT * 0.6))   # kites around
		s.step(DT)
		if s.boss_cast == "ansturm" and was != "ansturm":
			starts += 1
			var lanes := _hazards(s, "ansturm_bahn")
			assert_eq(lanes.size(), 1, "one lane per charge")
			var lane: Sim.SimHazard = lanes[0]
			assert_near(absf(angle_difference(lane.ang, (p.pos - lane.pos).angle())), 0.0, 0.05,
				"lane points at the target (%s -> %s, boss %s)" % [lane.pos, p.pos, b.pos])
			assert_near(s.boss_cast_left, s._telegraph(Content.BOSS["ansturm_warn"]), 0.05, "0.8 s warning")
			lane_seen = true
		was = s.boss_cast
	assert_true(lane_seen, "the lane is shown")
	# 12 s: the first chain after 1.5 s, then every 3.5 s plus its charges
	assert_true(starts >= 4, "chains of charges (%d wind-ups)" % starts)
	assert_true(starts % 2 == 0 or starts >= 5, "2 charges per chain (%d)" % starts)


func test_stun_breaks_the_whole_chain() -> void:
	var s := _sim(["stadtbild"])
	var b := _boss(s)
	var p: Sim.SimPlayer = s.players[1]
	for i in int(3.0 / DT):
		p.iframes = 10.0
		s.step(DT)
		if s.boss_cast == "ansturm":
			break
	assert_eq(s.boss_cast, "ansturm", "a wind-up runs")
	s.take_events()
	s._apply_stun(b, 2.0)
	assert_eq(b.cast, "", "interrupted")
	assert_eq(b.state, 0, "the chain is over")
	assert_true(_hazards(s, "ansturm_bahn").is_empty(), "lane gone")
	assert_near(float(b.data["kette_cd"]), float(Content.BOSS["kette_every"]), 0.001, "next chain after the normal pause")
	var ints := s.take_events().filter(func(ev): return ev[0] == "interrupt")
	assert_eq(ints.size(), 1, "UNTERBROCHEN")


func test_turbine_falls_in_the_charge_direction() -> void:
	var s := _sim(["oma"])
	var b := _boss(s)
	var p: Sim.SimPlayer = s.players[1]
	# one turbine right next to the target: the charge goes for it (Don Quixote)
	var t_turb := Content.idx(Content.SUMMON_ORDER, "turbine")
	s.summons = s.summons.filter(func(x): return x.type != t_turb)
	b.pos = Arena.CENTER + Vector2(-300, 0)
	p.pos = Arena.CENTER + Vector2(100, 80)
	var tb := Sim.SimSummon.new()
	tb.type = t_turb
	tb.pos = Arena.CENTER + Vector2(0, 0)
	tb.hp = 1.0
	s.summons.append(tb)
	b.data["kette_cd"] = 0.0
	s.step(DT)
	assert_eq(s.boss_cast, "ansturm")
	var lane: Sim.SimHazard = _hazards(s, "ansturm_bahn")[0]
	assert_near(absf(angle_difference(lane.ang, (tb.pos - b.pos).angle())), 0.0, 0.05, "aims at the turbine by the target")
	var rotor: Sim.SimHazard = null
	for i in int(2.0 / DT):
		p.pos = Arena.CENTER + Vector2(100, 300)   # out of the way
		p.iframes = 10.0
		s.step(DT)
		var rs := _hazards(s, "rotor")
		if not rs.is_empty():
			rotor = rs[0]
			break
	assert_true(rotor != null, "the turbine falls")
	assert_false(tb.alive, "and is gone")
	assert_near(absf(angle_difference(rotor.ang, lane.ang)), 0.0, 0.05, "in the charge direction")
	# the falling rotor warns first (no damage), then the line hurts
	var on_line: Vector2 = rotor.pos + Vector2.RIGHT.rotated(rotor.ang) * 150.0
	b.pos = Arena.CENTER + Vector2(-700, 400)
	b.data["kette_cd"] = 99.0
	b.state = 0
	p.iframes = 0.0
	var hp0 := p.hp
	for i in int(0.5 / DT):
		p.pos = on_line
		b.pos = Arena.CENTER + Vector2(-700, 400)
		s.step(DT)
	assert_eq(p.hp, hp0, "warning: harmless while it falls")
	assert_true(rotor.life > 0.5, "life above 0.5 = still falling")
	for i in int(1.0 / DT):
		p.pos = on_line
		b.pos = Arena.CENTER + Vector2(-700, 400)
		s.step(DT)
	assert_true(p.hp < hp0, "the rotor line hurts")
	assert_true(rotor.life < 0.5)
	assert_true(s.danger_at(rotor, on_line), "danger_at for the bot")
	assert_false(s.danger_at(rotor, on_line + Vector2.RIGHT.rotated(rotor.ang + PI * 0.5) * 120.0), "beside it is safe")


# --- Reichweite (D-141) -------------------------------------------------------------

func test_reich_mask_excludes_holes_and_their_neighbours() -> void:
	var full := (1 << Arena.WALL_SEGMENTS) - 1
	assert_eq(Arena.reich_mask(full), full, "no hole: every segment is safe")
	var mask := full & ~(1 << 5)
	var rm := Arena.reich_mask(mask)
	for seg in [4, 5, 6]:
		assert_false(rm & (1 << seg), "segment %d: hole or next to it" % seg)
	for seg in [3, 7, 20]:
		assert_true(rm & (1 << seg), "segment %d safe" % seg)
	assert_true(Arena.reich_safe(Arena.seg_inner(20, 60.0), mask, 130.0), "in front of an intact segment")
	assert_false(Arena.reich_safe(Arena.seg_inner(20, 160.0), mask, 130.0), "too far from the wall")
	assert_false(Arena.reich_safe(Arena.seg_inner(5, 60.0), mask, 130.0), "in front of the hole")


func test_reichweite_hits_everyone_outside_the_intact_brandmauer() -> void:
	var s := _sim(["oma", "oma", "oma"])
	var b := _boss(s)
	_to_phase(s, b, 1)
	_run(s, 2.2)   # the band's warning
	var holes := []
	for i in Arena.WALL_SEGMENTS:
		if not s.wall[i]:
			holes.append(i)
	assert_false(holes.is_empty(), "3 players: start holes")
	var safe_seg := -1
	var rm := Arena.reich_mask(s._wall_mask())
	for i in Arena.WALL_SEGMENTS:
		if rm & (1 << i):
			safe_seg = i
			break
	b.data["reich_cd"] = 0.0
	b.data["ring_cd"] = 99.0
	b.timer3 = 99.0   # no wing fans in this test
	for h in _hazards(s, "push_ring"):
		h.alive = false
	s.take_events()
	s.step(DT)
	assert_eq(s.boss_cast, "reichweite", "cast starts")
	var tele := _hazards(s, "reichweite")
	assert_eq(tele.size(), 1, "arena-wide telegraph")
	assert_true(s.danger_at(tele[0], Arena.CENTER), "the middle is not safe")
	assert_near(s.boss_cast_left, s._telegraph(Content.BOSS["reich_warn"]), 0.05, "3 s warning (B8 arena change)")
	var rings := _hazards(s, "push_ring")
	assert_eq(rings.size(), 1, "combined pattern: a push ring toward the holes first")
	var says := s.take_events().filter(func(ev): return ev[0] == "say" and ev[2] == "SAY_REICHWEITE")
	assert_eq(says.size(), 1)
	var spots := {1: Arena.CENTER, 2: Arena.seg_inner(safe_seg, 50.0), 3: Arena.seg_inner(int(holes[0]), 50.0)}
	var hp0 := {}
	var frames := int((s._telegraph(Content.BOSS["reich_warn"]) + 0.1) / DT)
	for i in frames:
		for id in spots:
			var p: Sim.SimPlayer = s.players[id]
			p.pos = spots[id]
			p.knock = Vector2.ZERO
			p.iframes = 0.0 if i >= frames - 14 else 10.0
			hp0[id] = p.hp if i == 0 else hp0[id]
		for h in s.hazards:
			if h.type == Content.idx(Content.HAZARD_ORDER, "push_ring"):
				h.alive = false
		s.step(DT)
	var hit_ev := s.take_events().filter(func(ev): return ev[0] == "say" and ev[2] == "SAY_BRANDMAUER_STEHT")
	assert_true(s.players[1].hp < hp0[1], "in the middle: hit")
	assert_eq(s.players[2].hp, hp0[2], "in front of the intact Brandmauer: safe")
	assert_true(s.players[3].hp < hp0[3], "in front of a hole: hit")
	assert_eq(hit_ev.size(), 1, "the players answer")
	assert_false(_hazards(s, "reichweite_hit").is_empty(), "impact wave shown")
	assert_true(float(b.data["reich_cd"]) > 10.0, "next one after 16 s")


func test_reichweite_interrupted_by_a_stun() -> void:
	var s := _sim(["stadtbild"])
	var b := _boss(s)
	_to_phase(s, b, 1)
	_run(s, 2.2)
	b.data["reich_cd"] = 0.0
	s.step(DT)
	assert_eq(s.boss_cast, "reichweite")
	s._apply_stun(b, 2.0)
	assert_eq(b.cast, "", "UNTERBROCHEN")
	assert_true(_hazards(s, "reichweite").is_empty(), "telegraph gone")
	var p: Sim.SimPlayer = s.players[1]
	p.pos = Arena.CENTER
	p.iframes = 0.0
	var hp0 := p.hp
	_run(s, 3.5, false)
	assert_true(_hazards(s, "reichweite_hit").is_empty(), "no impact")


# --- Briefkastenfirmen (D-142) ---------------------------------------------------------

func test_briefkasten_feed_the_shield_and_come_back() -> void:
	var s := _sim(["oma"])
	var b := _boss(s)
	_to_phase(s, b, 2)
	s.step(DT)
	var bx := Content.BOSS
	assert_eq(s.brief_count(), 3, "solo: three letterboxes")
	assert_eq(_sim(["oma", "oma"]).brief_count(), 4, "from 2 players: four")
	assert_eq(s.briefkasten_alive(), 3)
	assert_near(b.shield, b.max_hp * float(bx["shield"]), b.max_hp * 0.01, "gold-bar shield 25 %")
	var t_box := Content.idx(Content.ENEMY_ORDER, "briefkasten")
	var boxes := s.enemies.filter(func(e): return e.alive and e.type == t_box)
	for o in boxes:
		assert_near(o.max_hp, b.max_hp * float(bx["brief_hp"]), 1.0, "brief_hp of her max HP")
		assert_eq(o.encounter, "", "not an encounter unit (doesn't block the win)")
		assert_true(Arena.edge_dist(o.pos) <= float(bx["brief_inset"]) + 1.0, "near the walls")
	# shield recharge: 3 × brief_regen of her max HP per s
	b.shield = 0.0
	_run(s, 1.0)
	assert_near(b.shield, 3 * float(bx["brief_regen"]) * b.max_hp, b.max_hp * 0.002, "recharged by the boxes")
	# two down: the last one still recharges, the dead ones stay dead
	b.shield = 0.0
	for k in 2:
		s._damage_enemy(boxes[k], boxes[k].max_hp * 2.0, s.players[1])
		assert_false(boxes[k].alive)
	_run(s, 1.0)
	assert_eq(s.briefkasten_alive(), 1, "no single comeback")
	assert_near(b.shield, float(bx["brief_regen"]) * b.max_hp, b.max_hp * 0.001, "one box, a third of the recharge")
	# the last one: the shield breaks, no recharge until they reopen together
	b.shield = b.shield_max
	s.take_events()
	s._damage_enemy(boxes[2], boxes[2].max_hp * 2.0, s.players[1])
	s.step(DT)
	assert_eq(s.briefkasten_alive(), 0)
	assert_eq(b.shield, 0.0, "Steuerparadies cracks with the last letterbox")
	assert_eq(s.take_events().filter(func(ev): return ev[0] == "say" and ev[2] == "SAY_SHIELD_BROKEN").size(), 1)
	_run(s, s._by_level(bx["brief_back"]) - 0.5)
	assert_eq(s.briefkasten_alive(), 0, "a window to hit her")
	assert_eq(b.shield, 0.0, "no box, no recharge")
	_run(s, 0.6)
	assert_eq(s.briefkasten_alive(), 3, "all back after 15 s")
	var spots := {}
	for o in s.enemies:
		if o.alive and o.type == t_box:
			spots[Vector2i(o.pos)] = true
	assert_eq(spots.size(), 3, "three different addresses")
	var neu := s.take_events().filter(func(ev): return ev[0] == "say" and ev[2] == "SAY_BRIEFKASTEN_NEU")
	assert_eq(neu.size(), 1, "Neue Adresse, gleiche Firma.")
	assert_true(b.shield > 0.0 and b.shield < b.shield_max * 0.2, "the shield regrows from zero")
	# she still falls; the boxes don't keep the encounter alive
	b.shield = 0.0
	s._damage_enemy(b, b.max_hp * 10.0, s.players[1])
	b.shield = 0.0
	s._damage_enemy(b, b.max_hp * 10.0, s.players[1])
	assert_eq(s.phase, Sim.Phase.OVER, "won with boxes standing")
	assert_true(s.result.get("won", false))


# --- Wahlabend (D-144) ------------------------------------------------------------------

func test_wahlabend_speeds_up_long_fights() -> void:
	for level in [0, 4]:
		var s := _sim(["oma"], level)
		var b := _boss(s)
		var from: float = Content.BOSS["wahl_from_l4" if level >= 4 else "wahl_from"]
		b.data["fight_t"] = from - 0.5
		_run(s, 0.4)
		assert_eq(int(b.data.get("wahl", 0)), 0, "not yet")
		s.take_events()
		_run(s, 0.2)
		assert_eq(int(b.data["wahl"]), 1, "first Hochrechnung at %.0f s" % from)
		var ev := s.take_events().filter(func(e): return e[0] == "hochrechnung")
		assert_eq(ev.size(), 1)
		assert_near(s._wahl_k(b), 1.1, 0.0001, "+10 %")
		b.data["fight_t"] = from + 20.0 * float(Content.BOSS["wahl_every"])
		_run(s, DT)
		assert_eq(int(b.data["wahl"]), int(Content.BOSS["wahl_max"]), "capped")
		var vs := ViewState.new()
		s.build_view(vs)
		assert_eq(int(vs.boss["hoch"]), int(Content.BOSS["wahl_max"]), "in the view")


func test_snapshot_v5_carries_the_hochrechnung() -> void:
	assert_eq(Snapshot.VERSION, 5)
	var vs := ViewState.new()
	vs.boss = {"enc": 3, "hp": 0.3, "phase": 2, "shield": 0.5, "cast": 1 + Content.BOSS_CASTS.find("reichweite"), "cast_t": 0.25, "hoch": 3}
	var dec := Snapshot.decode(Snapshot.encode(vs))
	assert_eq(int(dec.boss["hoch"]), 3)
	assert_eq(dec.boss_cast(), "reichweite")
	var bytes := Snapshot.encode(vs)
	bytes[0] = 4
	assert_true(Snapshot.decode(bytes) == null, "version 4 is rejected")


# --- Pressure vs the Sauerländer (D-140) ------------------------------------------------

## She is the hardest fight: more HP than the Sauerländer for the same team, and
## every phase has an attack that needs an answer (lane, Reichweite, boxes).
func test_final_boss_outweighs_the_sauerlaender() -> void:
	for n in [1, 4]:
		var chars := []
		for i in n:
			chars.append("oma")
		var s := _sim(chars, 5)
		s.wave = 20
		var hp_final: float = Content.ENEMIES["eidgenossin"]["hp"] * s.encounter_hp_scale("eidgenossin")
		s.wave = 15
		var hp_sauer: float = Content.ENEMIES["sauerlaender"]["hp"] * s.encounter_hp_scale("sauerlaender")
		assert_true(hp_final > 3.0 * hp_sauer, "%d players: final boss HP factor ×%.1f of the Sauerländer" % [n, hp_final / hp_sauer])
	for id in ["ansturm", "reichweite"]:
		assert_has(Content.BOSS_CASTS, id)


# --- View contract --------------------------------------------------------------------

func test_new_telegraphs_are_the_bosses_and_translated() -> void:
	# appended ids only (stable network ids, D-144)
	assert_eq(Content.HAZARD_ORDER.slice(18), ["ansturm_bahn", "rotor", "reichweite", "reichweite_hit"])
	assert_eq(Content.ENEMY_ORDER[-1], "briefkasten")
	assert_eq(Content.BOSS_CASTS[-1], "reichweite")
	for id in ["ansturm_bahn", "rotor", "reichweite", "reichweite_hit"]:
		assert_has(Content.HAZARD_ORDER, id)
		assert_false(WorldView.is_own_hazard(id), id + " is the boss's (never fades, D-086)")
	for key in ["CAST_REICHWEITE", "HUD_HOCHRECHNUNG", "FX_REICHWEITE_SAFE", "FX_BRIEFKASTEN", "ENEMY_BRIEFKASTEN_NAME",
			"SAY_REICHWEITE", "SAY_BRANDMAUER_STEHT", "SAY_BRIEFKASTEN", "SAY_BRIEFKASTEN_NEU", "SAY_HOCHRECHNUNG"]:
		assert_true(TranslationServer.translate(key) != key, key)


## The letterbox has its own doodle (not the fallback), and a whole fight in all
## three phases goes through the snapshot without loss of the new hazards.
func test_letterbox_mesh_and_fight_snapshots() -> void:
	var w := WorldView.new()
	var m: ArrayMesh = w._mesh(WorldView.K_ENEMY, Content.ENEMY_ORDER.find("briefkasten"), 4, 0)
	assert_true(m != null and m.get_surface_count() > 0, "letterbox doodle")
	w.free()
	var s := _sim(["oma", "oma"])
	var b := _boss(s)
	var seen := {}
	for ph in 3:
		if ph > 0:
			_to_phase(s, b, 1)
		for i in int(16.0 / DT):
			for p in s.players.values():
				p.iframes = 10.0
			s.step(DT)
			if i % 20 == 0:
				var vs := ViewState.new()
				s.build_view(vs)
				var dec := Snapshot.decode(Snapshot.encode(vs))
				assert_true(dec != null, "decodes")
				for t in dec.h_type:
					seen[Content.HAZARD_ORDER[t]] = true
				for t in dec.e_type:
					seen[Content.ENEMY_ORDER[t]] = true
	for id in ["ansturm_bahn", "reichweite", "briefkasten", "abschiebezone", "push_ring"]:
		assert_true(seen.has(id), "%s reaches the client" % id)
