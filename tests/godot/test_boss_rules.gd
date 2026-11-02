extends TestCase
## Boss rules (GDD §14 "Boss rules", D-102 to D-112): phase lock and
## Pressekonferenz, random targets, stun resistance and interruptible casts, the
## slow cap, the boss HP lever, the new abilities and the old-arena coordinate fix.

const AREAS := ["sim", "view"]  # ci-cd.md §2a

const DT := 1.0 / 60.0


func _sim(chars: Array, level := 0, seed := 7, org := "gewerkschaft") -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": org, "difficulty": level, "skip_intro": true})
	s.enemies.clear()
	for p in s.players.values():
		p.weapons.clear()
		p.stats["dodge"] = 0.0
		p.pos = Arena.CENTER + Vector2(0, 300)
	return s


## Starts encounter `enc` like its boss wave would; no regular spawns.
func _boss(s: Sim, enc: String, wave := 15) -> Sim.SimEnemy:
	s._begin_wave(wave, enc)
	s.diff["spawn"] = 0.0
	s.encounter_pending = 0.0001
	s._step_encounter_spawn(0.001)
	s.enemies = s.enemies.filter(func(e): return e.encounter != "")
	for p in s.players.values():
		p.weapons.clear()
		p.pos = Arena.CENTER + Vector2(0, 300)
	s._build_grid()
	return s.enemies[0]


func _run(s: Sim, seconds: float, safe := true) -> void:
	for i in int(round(seconds / DT)):
		if safe:
			for p in s.players.values():
				p.iframes = 10.0
		s.step(DT)


func _events(s: Sim, name: String) -> Array:
	return s.take_events().filter(func(ev): return ev[0] == name)


# --- Phase lock and Pressekonferenz (D-102, D-106) ----------------------------------

func test_phase_lock_and_pressekonferenz() -> void:
	var s := _sim(["oma"])
	var boss := _boss(s, "geschichtslehrer", 10)
	var mx := boss.max_hp
	boss.vuln_t = 3.0
	boss.slow = 0.3
	boss.slow_t = 5.0
	boss.stun_t = 1.0
	s._damage_enemy(boss, mx * 10.0, null)
	assert_near(boss.hp, mx * 0.66, 0.5, "damage can't skip the 66 % boundary; the rest is lost")
	s.take_events()
	_run(s, DT)
	assert_eq(boss.phase, 1, "phase 2 at the boundary")
	assert_near(boss.presse_t, 2.5 - DT, 0.02, "Pressekonferenz 2.5 s")
	assert_eq(boss.stun_t, 0.0, "stun ends")
	assert_eq(boss.slow, 0.0, "slow ends")
	var hp0 := boss.hp
	s._damage_enemy(boss, 500.0, s.players[1])
	s._damage_dot(boss, 500.0, 1, "x")
	assert_eq(boss.hp, hp0, "invulnerable during the Pressekonferenz")
	s._apply_stun(boss, 2.0)
	s._apply_slow(boss, 0.5, 2.0)
	assert_eq(boss.stun_t, 0.0, "no stun lands")
	assert_eq(boss.slow, 0.0, "no slow lands")
	var d0 := boss.pos.distance_to(Arena.CENTER)
	_run(s, 1.0)
	assert_near(boss.vuln_t, 3.0, 0.001, "vulnerability paused, not used up")
	assert_true(boss.pos.distance_to(Arena.CENTER) < d0, "walks to the middle")
	_run(s, 1.6)
	assert_eq(boss.presse_t, 0.0, "over after 2.5 s")
	assert_true(boss.vuln_t < 3.0, "vulnerability runs again")
	s._damage_enemy(boss, mx * 10.0, null)
	assert_near(boss.hp, mx * 0.33, 0.5, "second boundary at 33 %")
	_run(s, DT)
	assert_eq(boss.phase, 2, "phase 3")
	_run(s, 2.6)
	s._damage_enemy(boss, mx * 10.0, null)
	assert_false(boss.alive, "no lock in the last phase")


func test_phase_change_event_and_shorter_pressekonferenz_from_30() -> void:
	var s := _sim(["oma"], 4)
	var boss := _boss(s, "sauerlaender")
	s.take_events()
	s._damage_enemy(boss, boss.max_hp, null)
	s.step(DT)
	var evs := _events(s, "boss_phase")
	assert_eq(evs.size(), 1, "one boss_phase event")
	assert_eq(evs[0][1], "sauerlaender")
	assert_eq(evs[0][2], 1)
	assert_near(boss.presse_t, 1.5 - DT, 0.02, "1.5 s from Umfrage 30 %")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_true(vs.e_flags2[0] & ViewState.EF2_PRESSE, "golden outline flag")


## The Sylt-Clique shares one lock on the group's total HP (D-106).
func test_sylt_clique_group_lock() -> void:
	var s := _sim(["oma"])
	var first := _boss(s, "sylt_clique", 5)
	assert_eq(s.enemies.size(), 4, "four members")
	var total := 0.0
	for e in s.enemies:
		total += e.max_hp
	var second: Sim.SimEnemy = s.enemies[1]
	s._damage_enemy(first, total, null)
	assert_false(first.alive, "a member may fall while the group is above 66 %")
	s._damage_enemy(second, total, null)
	assert_near(second.hp, second.max_hp - total * 0.09, 0.5, "the next one only down to the group's 66 %")
	s.step(DT)
	assert_eq(s.enemies.size(), 3)
	for e in s.enemies:
		assert_eq(e.phase, 1, "all in phase 2")
		assert_true(e.presse_t > 0.0, "all hold the Pressekonferenz")


# --- Random targets (D-103) ---------------------------------------------------------

func _picks(seed: int, downed := 0) -> Array:
	var s := _sim(["oma", "antifa", "lastenrad"], 0, seed)
	var boss := _boss(s, "geschichtslehrer", 10)
	s.players[1].pos = boss.pos + Vector2(40, 0)    # nearest
	s.players[2].pos = boss.pos + Vector2(600, 200)
	s.players[3].pos = boss.pos + Vector2(-700, 300)
	if downed > 0:
		s.players[downed].state = 1
	var out := []
	for i in 60:
		boss.target_t = 0.0
		var p: Sim.SimPlayer = s._target_player(boss)
		out.append(p.id)
		assert_true(boss.target_t >= 4.0 and boss.target_t <= 7.0, "next pick in 4–7 s")
	return out


func test_random_targets() -> void:
	var a := _picks(11)
	for id in [1, 2, 3]:
		assert_true(id in a, "player %d gets picked, not only the nearest" % id)
	assert_eq(a, _picks(11), "deterministic (the sim's rng)")
	var d := _picks(11, 2)
	assert_false(2 in d, "downed players aren't picked")
	# the pick holds until its timer runs out
	var s := _sim(["oma", "antifa"])
	var boss := _boss(s, "geschichtslehrer", 10)
	var p: Sim.SimPlayer = s._target_player(boss)
	for i in 10:
		assert_eq(s._target_player(boss), p, "same target while the timer runs")
	p.state = 3
	assert_true(s._target_player(boss) != p, "an away target is dropped at once")


# --- Resistance (D-102, D-107) -------------------------------------------------------

func test_stun_halved_then_standfest_and_interrupts_a_cast() -> void:
	for level in [0, 4]:
		var s := _sim(["stadtbild"], level)
		var boss := _boss(s, "geschichtslehrer", 10)
		var p: Sim.SimPlayer = s.players[1]
		p.pos = boss.pos + Vector2(60, 0)
		s._start_cast(boss, "wende", 1.5)
		s.take_events()
		s._build_grid()
		s._activate_ult(p)   # Flashmob: 2 s stun
		assert_near(boss.stun_t, 1.0, 0.001, "half as long")
		var standfest := 15.0 if level >= 4 else 10.0
		assert_near(boss.standfest_t, 1.0 + standfest, 0.001, "Standfest after the stun")
		assert_eq(boss.cast, "", "the cast is interrupted")
		var ints := _events(s, "interrupt")
		assert_eq(ints.size(), 1, "UNTERBROCHEN event")
		assert_eq(ints[0][2], "wende")
		boss.stun_t = 0.0
		s._apply_stun(boss, 2.0)
		assert_eq(boss.stun_t, 0.0, "Standfest: immune")
		_run(s, 2.0)
		for q in s.players.values():
			assert_eq(q.reversed, 0.0, "the interrupted Wende never comes")
		var vs := ViewState.new()
		s.build_view(vs)
		assert_true(vs.e_flags2[0] & ViewState.EF2_STANDFEST, "shield icon flag")
		assert_false(s.boss_can_stun(), "bot hook: no stun would land")


func test_slow_cap_on_bosses_not_on_the_sylt_clique() -> void:
	var s := _sim(["oma"])
	var boss := _boss(s, "sauerlaender")
	s._apply_slow(boss, 0.85, 3.0)
	assert_near(boss.slow, 0.4, 0.0001, "Kleber/Straßenblockade capped at 40 %")
	var t := _sim(["oma"])
	var sylt := _boss(t, "sylt_clique", 5)
	t._apply_slow(sylt, 0.85, 3.0)
	assert_near(sylt.slow, 0.85, 0.0001, "Sylt-Clique (tier 1) uncapped")


## Antrag gestellt (60 %) and Streik (50 % on elites) on top of a slow: all
## sources together still leave a boss 60 % of its speed (D-107).
func test_slow_cap_covers_global_slows() -> void:
	var walked := {}
	for slowed in [false, true]:
		var s := _sim(["buergergeld"])
		var boss := _boss(s, "geschichtslehrer", 10)
		var p: Sim.SimPlayer = s.players[1]
		p.pos = boss.pos + Vector2(800, 0)
		boss.target_id = p.id
		boss.target_t = 100.0
		boss.timer = 100.0
		boss.timer2 = -100.0
		if slowed:
			s._activate_ult(p)
			s.streik_active = 10.0
			s._apply_slow(boss, 0.9, 10.0)
		var x0 := boss.pos.x
		_run(s, 0.5)
		walked[slowed] = boss.pos.x - x0
	assert_near(walked[true] / walked[false], 0.6, 0.03, "at most 40 % slower")


func test_fragen_sie_mal_uns_is_x1_5_on_the_boss() -> void:
	var s := _sim(["toechter"])
	var boss := _boss(s, "sauerlaender")
	var suit := s.spawn_enemy("lobbyist", boss.pos + Vector2(300, 0))
	suit.behind = false
	suit.max_hp = 10000.0
	suit.hp = suit.max_hp
	s._activate_ult(s.players[1])
	assert_true(boss.vuln_t > 0.0 and suit.vuln_t > 0.0, "both vulnerable")
	assert_near(boss.stun_t, 1.0, 0.001, "boss stun halved")
	var h0 := boss.hp
	s._damage_enemy(boss, 100.0, null)
	assert_near(h0 - boss.hp, 150.0, 0.01, "×1.5 on the Sauerländer")
	s._damage_enemy(suit, 100.0, null)
	assert_near(suit.max_hp - suit.hp, 200.0, 0.01, "suits stay ×2")


func test_final_boss_recharges_ultimates_at_each_phase_change() -> void:
	for enc in ["eidgenossin", "geschichtslehrer"]:
		var s := _sim(["oma", "antifa"])
		var boss := _boss(s, enc, 20 if enc == "eidgenossin" else 10)
		for p in s.players.values():
			p.ult_ready = false
		s.players[2].state = 1   # downed players get it too
		s._damage_enemy(boss, boss.max_hp, null)
		s.step(DT)
		for p in s.players.values():
			assert_eq(p.ult_ready, enc == "eidgenossin", "%s: ult ready again" % enc)


# --- HP lever (D-102) ----------------------------------------------------------------

func test_boss_hp_lever() -> void:
	var s := _sim(["oma"])
	# v0.4 values (D-118): hp_mult 1.25 / 2.2 / 2.0, elite_coop 0.3; final_boss_mult 5.5 (v0.4.1, D-145)
	assert_near(s.encounter_hp_scale("sylt_clique"), 0.6 * 1.25, 0.0001, "solo, 10 %, hp_mult 1.25")
	assert_near(s.encounter_hp_scale("geschichtslehrer"), 0.6 * 2.2, 0.0001, "hp_mult 2.2")
	assert_near(s.encounter_hp_scale("sauerlaender"), 0.6 * 2.0, 0.0001, "hp_mult 2.0")
	assert_near(s.encounter_hp_scale("eidgenossin"), 0.6 * 5.5, 0.0001, "final_boss_mult 5.5")
	var t := _sim(["oma", "antifa", "lastenrad", "toechter"], 5)
	assert_near(t.encounter_hp_scale("eidgenossin"), (0.6 + 0.3 * 3) * 1.75 * 5.5, 0.0001, "4 players, 35 %")
	assert_near(t.encounter_hp_scale("geschichtslehrer"), (0.6 + 0.3 * 3) * 1.75 * 2.2, 0.0001, "diff_boss_hp on top")
	# the spawned unit really gets it, on top of the normal Umfrage HP
	var boss := _boss(t, "geschichtslehrer", 10)
	var d: Dictionary = Content.ENEMIES["geschichtslehrer"]
	var grow := pow(Content.enemy_hp_curve(10) / Content.enemy_hp_curve(5), float(Content.BALANCE["elite_wave_exp"]))
	assert_near(boss.max_hp, d["hp"] * t.diff["hp"] * t.encounter_hp_scale("geschichtslehrer") * grow, 0.5, "spawned HP")
	# normal enemies don't change
	var e := t.spawn_enemy("besorgter_buerger", Arena.CENTER)
	assert_near(e.max_hp, 8.0 * Content.enemy_hp_curve(10) * t.diff["hp"] * (1.0 + Content.BALANCE["coop_hp"] * 3), 0.01, "waves untouched")


# --- Bug fix: old arena coordinates (GDD §14, D-109) ---------------------------------

## Share of points in the right quarter / bottom third of the inner arena.
func _shares(pts: Array) -> Vector2:
	var r := Arena.INNER
	var right := 0
	var bottom := 0
	for q in pts:
		var v: Vector2 = q
		if v.x > r.position.x + r.size.x * 0.75:
			right += 1
		if v.y > r.position.y + r.size.y * 2.0 / 3.0:
			bottom += 1
		assert_true(Arena.is_inside(v, 0.0), "inside the arena: %s" % v)
	return Vector2(float(right) / pts.size(), float(bottom) / pts.size())


## Regression: the Sauerländer's walk targets, his money and the Stadtbild
## passers-by used the old 1600 × 898 field (x 200–1400, y 220–800 …) and
## almost never reached the right quarter or the bottom third of the arena.
func test_positions_use_the_whole_arena() -> void:
	var s := _sim(["stadtbild"], 0, 3)
	var boss := s.spawn_enemy("sauerlaender", Arena.CENTER)   # outside an encounter: no vote, no Kahlschlag
	boss.behind = false
	var walk := []
	for i in 600:
		boss.target = Vector2.ZERO
		boss.timer = 100.0
		s._boss_sauerlaender(boss, 0.0, DT)
		walk.append(boss.target)
	var money := []
	var t_geld := Content.idx(Content.PICKUP_ORDER, "geldschein")
	for i in 75:
		s.pickups.clear()
		s._money_rain(boss)
		for k in s.pickups:
			if k.type == t_geld:
				money.append(k.pos)
	var passers := []
	var t_pass := Content.idx(Content.PICKUP_ORDER, "passant")
	for i in 600:
		s.pickups.clear()
		s._passant_timer = 0.0
		s._step_pickups(0.001)
		for k in s.pickups:
			if k.type == t_pass:
				passers.append(k.pos)
	for set in [["walk targets", walk], ["money", money], ["passers-by", passers]]:
		var pts: Array = set[1]
		assert_true(pts.size() >= 500, "%s sampled" % set[0])
		var sh := _shares(pts)
		assert_true(sh.x >= 0.15, "%s reach the right quarter (%.3f)" % [set[0], sh.x])
		assert_true(sh.y >= 0.22, "%s reach the bottom third (%.3f)" % [set[0], sh.y])
	# the Antifa Sitzblockade lands around the real middle (was the old field's middle)
	var a := _sim(["oma"], 0, 3, "antifa")
	var sum := Vector2.ZERO
	var t_sitz := Content.idx(Content.HAZARD_ORDER, "sitzblockade")
	var n := 0
	for i in 400:
		a.hazards.clear()
		a._sitz_timer = 0.0
		a._step_org(0.001)
		for h in a.hazards:
			if h.type == t_sitz:
				sum += h.pos
				n += 1
	assert_eq(n, 400, "one blockade each")
	assert_true((sum / n).distance_to(Arena.CENTER) < 40.0, "centred on the arena: %s" % (sum / n))


# --- Geschichtslehrer: Wende um 180 Grad (D-104, D-112) ------------------------------

func _wende_times(level: int) -> Array:
	var s := _sim(["oma"], level)
	var boss := _boss(s, "geschichtslehrer", 10)
	boss.max_hp = 1.0e9
	boss.hp = boss.max_hp
	var out := []
	var cast_at := -1.0
	var t := 0.0
	var was := false
	while t < 15.0:
		_run(s, DT)
		t += DT
		if s.boss_cast == "wende" and cast_at < 0.0:
			cast_at = t
		var p: Sim.SimPlayer = s.players[1]
		if p.reversed > 0.0 and not was:
			out.append([t, p.reversed, p.reverse_axis])
		was = p.reversed > 0.0
	out.push_front(cast_at)
	return out


func test_wende_timing_axis_and_length() -> void:
	var r := _wende_times(0)
	assert_near(float(r[0]), 2.5, 0.05, "3 – 2 – 1 countdown starts 1.5 s before")
	assert_eq(r.size(), 3, "two reversals in 15 s")
	assert_near(float(r[1][0]), 4.0, 0.05, "first Wende 4 s into the fight")
	assert_near(float(r[2][0]), 14.0, 0.1, "then every 10 s")
	assert_near(float(r[1][1]), 4.0, 0.05, "4 s long")
	assert_eq(int(r[1][2]), 0, "both axes below 25 %")
	var r3 := _wende_times(3)
	assert_true(int(r3[1][2]) in [1, 2], "Teilwende from 25 %")
	var r4 := _wende_times(4)
	assert_near(float(r4[1][1]), 5.0, 0.05, "5 s from 30 %")
	# one-axis reversal: movement and the client's prediction flags agree
	assert_eq(Sim.reverse_dir(Vector2(1, 1), 1), Vector2(-1, 1))
	assert_eq(Sim.reverse_dir(Vector2(1, 1), 2), Vector2(1, -1))
	assert_eq(Sim.reverse_dir(Vector2(1, 1), 0), Vector2(-1, -1))
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	p.reversed = 2.0
	p.reverse_axis = 2
	var vs := ViewState.new()
	s.build_view(vs)
	var fl: int = vs.players[0]["flags"]
	assert_eq(Sim.reverse_axis_of(fl), 2, "PF_REVERSE_Y reaches the client")
	p.input = Vector2(0, 1)
	var y0 := p.pos.y
	s._step_players(0.1)
	assert_true(p.pos.y < y0, "down becomes up")


func test_wende_turns_books_around_in_phase_two() -> void:
	var s := _sim(["oma"])
	var boss := _boss(s, "geschichtslehrer", 10)
	var book := s._enemy_shot(boss, "buch", Vector2.RIGHT, 220.0, 3.0, 5.0)
	book.life = 1.0
	s._wende(boss)
	assert_true(book.vel.x > 0.0, "phase 1: books fly on")
	boss.phase = 1
	s._wende(boss)
	assert_true(book.vel.x < 0.0, "phase 2: books turn around")
	assert_true(book.life >= 4.0, "and come back through the arena")


# --- Sauerländer: Abstimmung, egal mit wem (D-104, D-109) ----------------------------

## Starts a vote and runs until the vote (the cast) begins.
func _vote_sim(chars: Array, level := 0) -> Array:
	var s := _sim(chars, level)
	var boss := _boss(s, "sauerlaender")
	boss.max_hp = 1.0e6
	boss.hp = boss.max_hp
	boss.data["vote_cd"] = 0.0
	for p in s.players.values():
		p.pos = Arena.CENTER
	var guard := 0
	while s.boss_cast != "abstimmung" and guard < 600:
		_run(s, DT)
		guard += 1
	return [s, boss]


func test_vote_passes_opens_a_hole_and_lets_afd_through() -> void:
	var r := _vote_sim(["oma"])
	var s: Sim = r[0]
	var boss: Sim.SimEnemy = r[1]
	assert_eq(s.boss_cast, "abstimmung", "vote running")
	var segs: Array = boss.data["vote_segs"]
	assert_eq(segs.size(), 1, "one segment below 35 %")
	var seg := int(segs[0])
	assert_true(Arena.side_of(seg) != Arena.TOP, "not the side with the start hole")
	var t_pl := Content.idx(Content.HAZARD_ORDER, "plenum")
	assert_eq(s.hazards.filter(func(h): return h.type == t_pl).size(), 1, "one Plenum circle per player")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_eq(vs.boss_cast(), "abstimmung", "cast in the snapshot view")
	assert_true(s.boss_can_stun(), "bot hook: a stun would land now")
	_run(s, 3.2)
	assert_false(s.wall[seg], "the vote passed: a hole")
	assert_eq(s.boss_cast, "", "vote over")
	var afd := s.enemies.filter(func(e): return e.def["faction"] == "afd")
	assert_eq(afd.size(), 4 + 2 * 1, "4 + 2 × players AfD enemies")
	for e in afd:
		assert_true(e.pos.distance_to(Arena.seg_center(seg)) < 200.0, "right at the hole")
	assert_eq(s.hazards.filter(func(h): return h.type == t_pl).size(), 0, "circles gone")


func test_vote_fails_when_the_plenum_is_occupied() -> void:
	assert_eq(_needed(1), 1)
	assert_eq(_needed(2), 2)
	assert_eq(_needed(3), 2)
	assert_eq(_needed(4), 3)
	for n in [1, 3]:
		var chars := ["oma", "antifa", "lastenrad"].slice(0, n)
		var r := _vote_sim(chars)
		var s: Sim = r[0]
		var boss: Sim.SimEnemy = r[1]
		var seg := int(boss.data["vote_segs"][0])
		var t_pl := Content.idx(Content.HAZARD_ORDER, "plenum")
		var circles := s.hazards.filter(func(h): return h.type == t_pl)
		assert_eq(circles.size(), n, "%d circles" % n)
		var need: int = n if n <= 2 else n - 1
		# one short of enough: the vote goes on
		for i in need - 1:
			s.players[i + 1].pos = circles[i].pos
		_run(s, 0.3)
		assert_eq(s.boss_cast, "abstimmung", "%d of %d circles: not enough" % [need - 1, need])
		s.players[need].pos = circles[need - 1].pos
		s.take_events()
		_run(s, DT * 2)
		assert_eq(s.boss_cast, "", "enough circles: the vote fails")
		assert_true(s.wall[seg], "no hole")
		assert_true(boss.stun_t > 1.0, "he staggers 1.5 s")
		assert_eq(boss.standfest_t, 0.0, "his own stagger starts no Standfest")


func _needed(n: int) -> int:
	var s := _sim(["oma", "antifa", "lastenrad", "toechter"].slice(0, n))
	return s.plenum_needed()


func test_vote_fails_on_damage_or_a_stun() -> void:
	for how in ["little", "damage", "stun"]:
		var r := _vote_sim(["stadtbild"])
		var s: Sim = r[0]
		var boss: Sim.SimEnemy = r[1]
		var seg := int(boss.data["vote_segs"][0])
		s.take_events()
		match how:
			"little":
				s._damage_enemy(boss, boss.max_hp * 0.05, s.players[1])
			"damage":
				s._damage_enemy(boss, boss.max_hp * 0.061, s.players[1])
			"stun":
				s._apply_stun(boss, 2.0)
		_run(s, DT)
		if how == "little":
			assert_eq(s.boss_cast, "abstimmung", "5 % isn't enough")
			continue
		assert_eq(s.boss_cast, "", how + ": the vote fails")
		assert_true(s.wall[seg], how + ": no hole")
		var says := s.take_events().filter(func(ev): return ev[0] == "say" and ev[2] == "SAY_VOTE_FAIL")
		assert_eq(says.size(), 1, how + ": \"Keine Mehrheit?\"")
		if how == "stun":
			assert_true(boss.standfest_t > 0.0, "a player's stun: Standfest")


func test_vote_picks_the_side_with_fewest_holes_and_two_segments_at_35() -> void:
	var s := _sim(["oma"])
	var boss := _boss(s, "sauerlaender")
	# top has the start hole; open one on the left and one on the right: bottom has none
	s.wall[33] = false
	s.wall[14] = false
	var segs := s._vote_pick(boss.pos)
	assert_eq(Arena.side_of(int(segs[0])), Arena.BOTTOM, "fewest holes")
	assert_eq(segs.size(), 1)
	var t := _sim(["oma"], 5)
	var b5 := _boss(t, "sauerlaender")
	var two := t._vote_pick(b5.pos)
	assert_eq(two.size(), 2, "two segments at 35 %")
	assert_eq(absi(int(two[0]) - int(two[1])), 1, "neighbours")
	assert_eq(Arena.side_of(int(two[0])), Arena.side_of(int(two[1])), "on the same wall")
	assert_near(t._by_level(Content.BOSS["vote_time"]), 2.2, 0.0001, "2.2 s at 35 %")
	assert_near(t._by_level(Content.BOSS["vote_dmg"]), 0.09, 0.0001, "9 % at 35 %")


# --- Sauerländer: Kahlschlag (D-104, D-110) ------------------------------------------

func _summon(s: Sim, id: String, pos: Vector2, owner: int) -> Sim.SimSummon:
	var m := Sim.SimSummon.new()
	m.type = Content.idx(Content.SUMMON_ORDER, id)
	m.pos = pos
	m.owner = owner
	m.cd = 100.0
	m.life = 100.0
	s.summons.append(m)
	return m


func _zone(s: Sim, id: String, pos: Vector2) -> Sim.SimHazard:
	var h := Sim.SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, id)
	h.pos = pos
	h.radius = 40.0
	h.life = 100.0
	h.max_life = 100.0
	h.owner = 1
	s.hazards.append(h)
	return h


func test_kahlschlag_wipes_summons_and_zones_in_the_cone() -> void:
	var s := _sim(["oma"])
	var boss := _boss(s, "sauerlaender")
	boss.max_hp = 1.0e6
	boss.hp = boss.max_hp
	var p: Sim.SimPlayer = s.players[1]
	p.pos = boss.pos + Vector2(220, 0)
	boss.data["vote_cd"] = 1000.0
	boss.data["kahl_cd"] = 0.0
	_run(s, DT)
	assert_eq(s.boss_cast, "", "no Kahlschlag in phase 1")
	boss.phase = 1
	boss.data.erase("phase_start")
	var at := boss.pos
	var in_stand := _summon(s, "infostand", at + Vector2(250, 40), 1)
	var out_stand := _summon(s, "infostand", at + Vector2(-250, 0), 1)
	var oma := _summon(s, "oma", at + Vector2(150, -20), 0)
	var in_glue := _zone(s, "kleber", at + Vector2(300, -60))
	var out_glue := _zone(s, "kleber", at + Vector2(0, 300))
	var chalk := _zone(s, "kreide", at + Vector2(120, 10))
	p.iframes = 0.0
	s.step(DT)
	assert_eq(s.boss_cast, "kahlschlag", "winds up")
	var t_k := Content.idx(Content.HAZARD_ORDER, "kahlschlag")
	var cone: Array = s.hazards.filter(func(h): return h.type == t_k)
	assert_eq(cone.size(), 1, "one cone below 35 %")
	assert_near(absf(angle_difference(cone[0].ang, 0.0)), 0.0, 0.05, "aimed at the target")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_true(vs.h_ang.size() == vs.h_type.size(), "angles in the view")
	var hp0 := p.hp
	for i in int(1.3 / DT):
		p.iframes = 0.0
		p.pos = at + Vector2(220, 0)
		s.step(DT)
	assert_true(p.hp < hp0, "the cone hits the player")
	assert_false(in_stand.alive, "Infostand in the cone removed")
	assert_true(out_stand.alive, "Infostand behind him stays")
	assert_true(oma.alive, "the Oma stays")
	assert_false(in_glue.alive, "Kleber in the cone removed")
	assert_false(chalk.alive, "Straßenkreide in the cone removed")
	assert_true(out_glue.alive, "Kleber outside stays")
	assert_eq(s.boss_cast, "", "done")


func test_kahlschlag_two_cones_at_35_and_a_stun_cancels() -> void:
	var s := _sim(["oma"], 5)
	var boss := _boss(s, "sauerlaender")
	boss.max_hp = 1.0e6
	boss.hp = boss.max_hp
	boss.phase = 1
	boss.data["vote_cd"] = 1000.0
	boss.data["kahl_cd"] = 0.0
	s.step(DT)
	var t_k := Content.idx(Content.HAZARD_ORDER, "kahlschlag")
	assert_eq(s.hazards.filter(func(h): return h.type == t_k).size(), 2, "two cones")
	s._apply_stun(boss, 2.0)
	assert_eq(s.boss_cast, "kahlschlag", "boss_cast updates next tick")
	s.step(DT)
	assert_eq(s.boss_cast, "", "interrupted")
	assert_eq(s.hazards.filter(func(h): return h.type == t_k).size(), 0, "telegraphs gone")


# --- Remigrantin: Die Brandmauer hält (D-104, D-111) ---------------------------------

func test_band_only_in_front_of_holes() -> void:
	var s := _sim(["oma"])   # start hole: top middle (segment 6)
	var w := 110.0
	assert_true(s.in_band(Arena.seg_inner(6, 50.0), w), "in front of the hole")
	assert_true(s.in_band(Arena.seg_inner(7, 50.0), w), "next to it")
	assert_false(s.in_band(Arena.seg_inner(9, 50.0), w), "further along: safe")
	assert_false(s.in_band(Arena.seg_inner(15, 30.0), w), "other walls: safe")
	assert_false(s.in_band(Arena.seg_inner(6, 130.0), w), "beyond the width")
	# no hole: the old band along every wall
	for i in Arena.WALL_SEGMENTS:
		s.wall[i] = true
	assert_true(s.in_band(Arena.seg_inner(15, 30.0), w), "no hole: every wall")
	assert_false(s.in_band(Arena.seg_inner(15, 90.0), w), "no hole: the old 70 px")
	# neighbours only on the same wall
	var mask := (1 << Arena.WALL_SEGMENTS) - 1
	mask &= ~(1 << 11)
	var bm := Arena.band_mask(mask)
	assert_true(bm & (1 << 10) and bm & (1 << 11), "hole and its neighbour")
	assert_false(bm & (1 << 12), "not around the corner")
	# widths
	assert_near(s.band_width(), 110.0, 0.001, "110 px")
	assert_near(_sim(["oma"], 3).band_width(), 150.0, 0.001, "150 px from 25 %")
	assert_near(_sim(["oma", "antifa", "lastenrad", "toechter"]).band_width(), 80.0, 0.001, "co-op: −10 px per extra player")


func test_brandmauer_haelt_warns_then_burns_and_rings_push_to_the_hole() -> void:
	var s := _sim(["oma"])
	var boss := _boss(s, "eidgenossin", 20)
	boss.max_hp = 1.0e6
	boss.hp = boss.max_hp
	s._damage_enemy(boss, boss.max_hp, null)
	_run(s, 2.6)   # Pressekonferenz
	var p: Sim.SimPlayer = s.players[1]
	p.stats["armor"] = 0.0
	var hp0 := p.hp
	for i in int(1.5 / DT):
		p.pos = Arena.seg_inner(6, 40.0)
		p.iframes = 0.0
		s.step(DT)
	assert_eq(s.boss_cast, "remigration", "warning running")
	assert_eq(p.hp, hp0, "no damage while it is announced")
	var z := s._absch_zone()
	assert_true(z != null and z.radius > 100.0, "band width in the radius")
	p.iframes = 0.0
	for i in int(1.0 / DT):
		p.pos = Arena.seg_inner(6, 40.0)
		s.step(DT)
	assert_true(p.hp < hp0, "then the band hurts in front of the hole")
	assert_eq(p.state, 0, "still standing")
	var rings := s.hazards.filter(func(h): return h.type == Content.idx(Content.HAZARD_ORDER, "push_ring"))
	assert_false(rings.is_empty(), "first push ring after the warning")
	# a ring shoves toward the nearest hole, not the nearest wall
	p.pos = Arena.seg_inner(15, 150.0)   # right wall; the hole is at the top
	p.hp = p.stats["max_hp"]
	var ring: Sim.SimHazard = rings[0]
	ring.data["hit"] = {}
	ring.pos = p.pos + Vector2(-300, 0)
	ring.life = ring.max_life * (1.0 - 300.0 / 900.0) + 1.0 / 60.0
	p.knock = Vector2.ZERO
	p.iframes = 0.0
	s._step_hazards(DT)
	var to_hole := (Arena.seg_inner(6, 0.0) - p.pos).normalized()
	assert_true(p.knock.length() > 100.0, "pushed")
	assert_true(p.knock.normalized().dot(to_hole) > 0.6, "toward the hole (%s)" % p.knock)


# --- View contract -------------------------------------------------------------------

func test_boss_telegraphs_never_fade_with_own_fx() -> void:
	for id in ["abstimmung", "plenum", "kahlschlag", "kahlschlag_hit", "abschiebezone", "push_ring", "lob_marker"]:
		assert_has(Content.HAZARD_ORDER, id)
		assert_false(WorldView.is_own_hazard(id), id + " is the boss's (D-086)")


func test_cast_names_and_phase_names_translated() -> void:
	for id in Content.BOSS_CASTS:
		assert_true(TranslationServer.translate("CAST_" + id.to_upper()) != "CAST_" + id.to_upper(), "CAST_" + id.to_upper())
	for enc in Content.ENCOUNTER_ORDER:
		for ph in 3:
			var key := "PHASE_%s_%d" % [enc.to_upper(), ph]
			assert_true(TranslationServer.translate(key) != key, key)


## The boss bar never sits under the ult panel (even at its "ready" pop) and
## stays on screen: centred when there is room, beside it, or above it.
func test_boss_bar_beside_the_ult_panel() -> void:
	for sz in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(960, 600), Vector2(800, 600)]:
		for uw in [0.0, 250.0, 420.0]:
			var ult := Rect2(14, sz.y - 88, uw, 72) if uw > 0.0 else Rect2()
			var r := Hud.boss_bar_rect(sz, ult)
			assert_true(r.position.x >= 0.0 and r.end.x <= sz.x and r.position.y >= 0.0, "on screen %s / %d" % [sz, uw])
			if uw > 0.0:
				var popped := Rect2(ult.position.x, ult.end.y - ult.size.y * Hud.ULT_POP_MAX, ult.size.x * Hud.ULT_POP_MAX, ult.size.y * Hud.ULT_POP_MAX)
				assert_false(r.intersects(popped), "boss bar clear of the ult panel %s / %d" % [sz, uw])
				assert_true(r.size.x >= Hud.BOSS_BAR_MIN_W or r.end.y <= ult.position.y, "wide enough or above it")


## Two Kahlschlag cones (35 %) or a cone beside an impact: their GESTRICHEN
## stamps never stack.
func test_kahlschlag_stamps_dont_stack() -> void:
	var w := WorldView.new()
	for turn in [deg_to_rad(60.0), deg_to_rad(20.0), 0.0]:
		w._stamp_q.clear()
		w._queue_stamp(Arena.CENTER, 0.3, 380.0, 1.0, Color.RED)
		w._queue_stamp(Arena.CENTER, 0.3 + turn, 380.0, 1.0, Color.RED)
		var a: Dictionary = w._stamp_q[0]
		var b: Dictionary = w._stamp_q[1]
		assert_false(WorldView.stamps_clash(a["pos"], a["ang"], b["pos"], b["ang"]), "stamps apart at %.0f°" % rad_to_deg(turn))
		assert_true(Geometry2D.is_point_in_polygon(b["pos"], WorldView._cone_pts(Arena.CENTER, 380.0, 0.3 + turn, PI * 0.25)), "still in its cone")
	assert_true(WorldView.stamps_clash(Vector2.ZERO, 0.0, Vector2(120, 10), 0.0), "same spot, same direction: clash")
	w.free()
