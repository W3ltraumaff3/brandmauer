extends TestCase
## The eight v0.3 status and summon weapons and their status effects
## (GDD §11 "Status and summon weapons", D-091 to D-096).

const DT := 1.0 / 60.0


func _sim(chars := ["oma"], seed := 11) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	s.enemies.clear()
	s.projectiles.clear()
	s.hazards.clear()
	for p in s.players.values():
		p.weapons.clear()
		p.pos = Vector2(950, 610)
	s._spawn_acc = -1000.0   # no random spawns during a test
	return s


func _enemy(s: Sim, tid: String, pos: Vector2, hp := 100000.0) -> Sim.SimEnemy:
	var e := s.spawn_enemy(tid, pos)
	e.behind = false
	e.speed = 0.0
	e.max_hp = hp
	e.hp = hp
	s._build_grid()
	return e


func _run(s: Sim, frames: int) -> void:
	for i in frames:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(DT)


func _weapon(s: Sim, id: String, tier := 1, pid := 1) -> Dictionary:
	var p: Sim.SimPlayer = s.players[pid]
	s._add_weapon(p, id, tier)
	return p.weapons[p.weapons.size() - 1]


## Fires a shot weapon straight at `e` and lets the projectile land.
func _shoot(s: Sim, w: Dictionary, e: Sim.SimEnemy, frames := 40) -> void:
	var p: Sim.SimPlayer = s.players[1]
	s._fire(p, w, (e.pos - p.pos).normalized(), e.pos)
	for i in frames:
		p.iframes = 10.0
		s._build_grid()
		s._step_projectiles(DT)
		s._cleanup()


func _new_ids() -> Array[String]:
	return ["kleine_anfrage", "lobbyregister", "faktencheck", "soli_sticker",
		"menschenkette", "pappkamerad", "demo_sanis", "lauti"]


# --- data and rules ---------------------------------------------------------------

func test_new_weapons_are_complete() -> void:
	for id in _new_ids():
		assert_has(Content.WEAPON_ORDER, id)
		var d: Dictionary = Content.WEAPONS[id]
		assert_true(d.has("range"), id + " needs a range (balance bot)")
		assert_eq(d["dmg"].size(), 4, id + " tiers")
		var scale_stat := "status" if id in ["kleine_anfrage", "lobbyregister", "faktencheck", "soli_sticker"] else "summon"
		assert_true(d["scale"].has(scale_stat), id + " scales with " + scale_stat)
		assert_true(TranslationServer.translate("WEAPON_%s_DESC" % id.to_upper()) != "WEAPON_%s_DESC" % id.to_upper(), id + " desc")
	# new ids sit at the end of the order lists (stable network ids)
	assert_eq(Content.PROJ_ORDER.slice(-3), ["akte", "aktenblatt", "sticker"])
	assert_eq(Content.HAZARD_ORDER.find("kette"), 13, "kette keeps its id; the boss telegraphs (D-108) come after it")
	assert_eq(Content.HAZARD_ORDER.slice(14, 18), ["abstimmung", "plenum", "kahlschlag", "kahlschlag_hit"])   # then the final boss's (D-144)
	assert_eq(Content.SUMMON_ORDER.slice(-4), ["laterne", "pappkamerad", "sani", "lauti"])


## D-078: the shop offers them to matching builds.
func test_shop_matches_build_scaling() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	_weapon(s, "kleber")
	var style := Sim.weapon_style(p)
	for id in ["kleine_anfrage", "lobbyregister", "faktencheck", "soli_sticker"]:
		assert_near(Sim.style_match(style, id), 1.0, 0.001, id + " matches a status build")
	p.weapons.clear()
	_weapon(s, "infostand")
	style = Sim.weapon_style(p)
	for id in ["menschenkette", "pappkamerad", "demo_sanis", "lauti"]:
		assert_near(Sim.style_match(style, id), 1.0, 0.001, id + " matches a summon build")


## Every weapon's damage grows with its scaling stat.
func test_every_new_weapon_scales() -> void:
	for id in _new_ids():
		var s := _sim()
		var p: Sim.SimPlayer = s.players[1]
		var w := _weapon(s, id)
		var stat: String = Content.WEAPONS[id]["scale"].keys()[0]
		var before := s.weapon_damage(p, w)
		p.stats[stat] += 10.0
		assert_true(s.weapon_damage(p, w) > before, id + " scales with " + stat)


## D-114: Ehrenamtskarte boosts every weapon that scales with Ehrenamt alike (walls and
## the Overall too, which got the ×0.6 of other weapons before).
func test_ehrenamtskarte_boosts_every_ehrenamt_weapon() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	p.flags["summon_build"] = true
	for id in ["menschenkette", "pappkamerad", "demo_sanis", "lauti", "infostand", "brandmauer_ziegel", "weisser_overall"]:
		assert_near(s._build_mult(p, Content.WEAPONS[id]), Content.RED_BUILD["summon"], 0.001, id)
	assert_near(s._build_mult(p, Content.WEAPONS["doener"]), Content.RED_BUILD["summon_other"], 0.001, "others")


# --- Kleine Anfrage: "In Bearbeitung" -------------------------------------------------

func test_kleine_anfrage_silences_and_pauses_the_vote() -> void:
	var s := _sim()
	var w := _weapon(s, "kleine_anfrage")
	var ju := _enemy(s, "ju_schnoesel", Vector2(950, 450))
	ju.state = 1   # voting at the wall
	ju.seg = 5
	_shoot(s, w, ju)
	assert_true(ju.hp < ju.max_hp, "hit")
	assert_true(ju.silence_t > 2.5, "In Bearbeitung")
	var t2 := ju.timer2
	s._ai_voter(ju, 0.0, 0.5)
	assert_near(ju.timer2, t2, 0.0001, "vote timer pauses")
	ju.silence_t = 0.0
	s._ai_voter(ju, 0.0, 0.5)
	assert_true(ju.timer2 > t2, "vote runs again once it's over")


func test_silence_expires_and_blocks_abilities() -> void:
	var s := _sim()
	var onkel := _enemy(s, "telegram_onkel", Vector2(1200, 610))
	s._apply_silence(onkel, 3.0)
	onkel.timer = 0.01
	var shots := s.projectiles.size()
	_run(s, 60)
	assert_eq(s.projectiles.size(), shots, "a silenced Telegram-Onkel doesn't throw")
	_run(s, 150)
	assert_eq(onkel.silence_t, 0.0, "In Bearbeitung runs out after 3 s")
	# FDP-Jungunternehmer dying "in Bearbeitung" founds no startups
	var fdp := _enemy(s, "fdp_jungunternehmer", Vector2(700, 610), 5.0)
	s._apply_silence(fdp, 3.0)
	s._damage_enemy(fdp, 50.0, s.players[1])
	assert_eq(s.enemies.filter(func(e): return e.alive and e.tid == "startup").size(), 0, "noch in Bearbeitung")
	var fdp2 := _enemy(s, "fdp_jungunternehmer", Vector2(700, 610), 5.0)
	s._damage_enemy(fdp2, 50.0, s.players[1])
	assert_eq(s.enemies.filter(func(e): return e.alive and e.tid == "startup").size(), 2, "normally two startups")


func test_kleine_anfrage_prefers_ability_enemies() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "kleine_anfrage")
	w["cd"] = 0.0
	var near := _enemy(s, "besorgter_buerger", p.pos + Vector2(80, 0))
	var onkel := _enemy(s, "telegram_onkel", p.pos + Vector2(-250, 0))
	s._step_weapons(DT)
	var shots := s.projectiles.filter(func(pr): return pr.owner == 1)
	assert_eq(shots.size(), 1)
	assert_true(shots[0].vel.x < 0.0, "aims at the Telegram-Onkel, not the closer Bürger")
	assert_true(near.alive)
	onkel.silence_t = 3.0
	w["cd"] = 0.0
	s.projectiles.clear()
	s._step_weapons(DT)
	shots = s.projectiles.filter(func(pr): return pr.owner == 1)
	assert_true(shots[0].vel.x > 0.0, "already in Bearbeitung: back to the normal target")


## Elites and bosses: abilities at half speed instead of a full stop.
func test_silence_halves_elite_ability_timers() -> void:
	var s := _sim()
	var boss := _enemy(s, "geschichtslehrer", Vector2(950, 300))
	boss.timer = 2.0
	boss.timer2 = 0.0
	s._apply_silence(boss, 3.0)
	_run(s, 60)
	assert_near(boss.timer, 1.5, 0.05, "timer runs at half speed")
	assert_near(boss.timer2, 0.5, 0.05, "Wende counter runs at half speed")


# --- Status immunity (D-087, D-092) ---------------------------------------------------

func test_reichsbuerger_ignores_new_status_but_takes_damage() -> void:
	var s := _sim()
	var rb := _enemy(s, "reichsbuerger", Vector2(1100, 610))
	for id in ["kleine_anfrage", "lobbyregister", "soli_sticker"]:
		var w := _weapon(s, id)
		_shoot(s, w, rb)
	var p: Sim.SimPlayer = s.players[1]
	var fc := _weapon(s, "faktencheck")
	s._fire(p, fc, Vector2.RIGHT)
	assert_true(rb.hp < rb.max_hp, "every new weapon still hurts him (D-079)")
	assert_eq(rb.silence_t, 0.0, "no In Bearbeitung")
	assert_eq(rb.reverse_t, 0.0, "no Rolle rückwärts")
	assert_eq(rb.sticker_t, 0.0, "no Soli-Sticker")
	assert_near(s._file_mult(rb), 1.0, 0.0001, "no Aktenkundig vulnerability")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_eq(vs.e_flags2[0], 0, "nothing shows on him")


## D-079 floor: at least 60 % of a status weapon's damage lands on immune enemies.
func test_status_weapons_keep_60_percent_on_immune() -> void:
	for id in ["kleine_anfrage", "lobbyregister", "faktencheck", "soli_sticker"]:
		var dealt := {}
		for tid in ["hinterbaenkler", "reichsbuerger"]:
			var s := _sim()
			var p: Sim.SimPlayer = s.players[1]
			_weapon(s, id)
			var e := _enemy(s, tid, p.pos + Vector2(120, 0))
			_run(s, 600)
			dealt[tid] = e.max_hp - e.hp
		assert_true(dealt["hinterbaenkler"] > 0.0, id + " deals damage")
		var share: float = dealt["reichsbuerger"] / dealt["hinterbaenkler"]
		assert_true(share >= 0.6, "%s: %.0f %% on the Reichsbürger" % [id, share * 100.0])


# --- Lobbyregister: "Aktenkundig" ------------------------------------------------------

func test_lobbyregister_stacks_and_offengelegt() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "lobbyregister")
	var e := _enemy(s, "hinterbaenkler", Vector2(1100, 610))
	for i in 5:
		_shoot(s, w, e)
	assert_eq(e.file_n, 5, "five stacks")
	assert_near(s._file_mult(e), 1.25, 0.0001, "+25 % from every source")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_eq(ViewState.file_stacks(vs.e_flags2[0]), 5, "stacks in the snapshot")
	# other players' damage profits too
	var hp := e.hp
	s._damage_enemy(e, 10.0, p, false, Vector2.ZERO, 0.0, "other")
	assert_near(hp - e.hp, 12.5, 0.01, "another source is boosted")
	hp = e.hp
	s.take_events()
	_shoot(s, w, e)
	assert_eq(e.file_n, 0, "Offengelegt resets the file")
	assert_true(hp - e.hp > 16.0, "the burst lands")
	assert_true(s.take_events().any(func(ev): return ev[0] == "say" and ev[2] == "SAY_OFFENGELEGT"), "Offengelegt!")


func test_aktenkundig_boosts_damage_over_time_and_expires() -> void:
	var s := _sim()
	var e := _enemy(s, "hinterbaenkler", Vector2(1100, 610))
	e.file_n = 4
	e.file_t = 5.0
	var hp := e.hp
	s._damage_dot(e, 10.0, 1, "x")
	assert_near(hp - e.hp, 12.0, 0.01, "DoT is boosted too")
	_run(s, 320)
	assert_eq(e.file_n, 0, "stacks run out after 5 s")


# --- Faktencheck: "Rolle rückwärts" ---------------------------------------------------

func test_faktencheck_reverses_and_clears_shots() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "faktencheck")
	var e := _enemy(s, "besorgter_buerger", p.pos + Vector2(100, 0))
	e.speed = 95.0
	var boss := _enemy(s, "sauerlaender", p.pos + Vector2(140, 40))
	var shot := s._enemy_shot(e, "kettenbrief", Vector2.LEFT, 1.0, 3.0)
	shot.pos = p.pos + Vector2(60, 5)
	var behind_me := s._enemy_shot(e, "kettenbrief", Vector2.LEFT, 1.0, 3.0)
	behind_me.pos = p.pos + Vector2(-60, 0)
	s._fire(p, w, Vector2.RIGHT)
	p.weapons.clear()   # no automatic re-casts during the test
	assert_true(e.hp < e.max_hp, "hit")
	assert_near(e.reverse_t, 1.2, 0.001, "Rolle rückwärts 1.2 s")
	assert_eq(boss.reverse_t, 0.0, "elites don't turn around")
	assert_false(shot.alive, "wipes enemy shots in the cone")
	assert_true(behind_me.alive, "but only in the cone")
	var d0 := e.pos.distance_to(p.pos)
	_run(s, 30)
	assert_true(e.pos.distance_to(p.pos) > d0 + 15.0, "walks backwards away from the player")
	_run(s, 60)
	assert_eq(e.reverse_t, 0.0, "runs out")
	var d1 := e.pos.distance_to(p.pos)
	_run(s, 30)
	assert_true(e.pos.distance_to(p.pos) < d1, "chases again afterwards")


# --- Soli-Sticker ----------------------------------------------------------------------

func test_soli_sticker_spreads_once_per_second() -> void:
	var s := _sim()
	var w := _weapon(s, "soli_sticker")
	var a := _enemy(s, "besorgter_buerger", Vector2(1100, 610))
	var b := _enemy(s, "besorgter_buerger", Vector2(1140, 610))
	var far := _enemy(s, "besorgter_buerger", Vector2(1400, 610))
	_shoot(s, w, a, 25)
	s.players[1].weapons.clear()
	assert_true(a.sticker_t > 3.5, "stuck")
	assert_eq(b.sticker_t, 0.0, "not spread yet")
	_run(s, 70)
	assert_true(b.sticker_t > 0.0, "passed to the neighbour within 50 px")
	assert_eq(far.sticker_t, 0.0, "never to a far enemy")
	assert_true(b.hp < b.max_hp, "the copy hurts")
	var stats: Array = s.run_stats(s.players[1])["damage"]
	assert_true(stats.any(func(r): return r["key"] == s._wkey(w) and r["total"] > 0), "sticker damage booked on the weapon")
	_run(s, 300)
	assert_eq(a.sticker_t, 0.0, "runs out after 4 s")


func test_soli_sticker_cap_per_player() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "soli_sticker")
	var crowd := []
	for i in 30:
		crowd.append(_enemy(s, "besorgter_buerger", Vector2(700 + (i % 6) * 34, 400 + (i / 6) * 34)))
	s._apply_sticker(crowd[0], 3.0, p.id, s._wkey(w))
	_run(s, 230)
	var stuck: int = crowd.filter(func(e): return e.sticker_t > 0.0).size()
	assert_true(stuck > 1, "spreads in a crowd (%d)" % stuck)
	assert_true(stuck <= int(Content.WEAPONS["soli_sticker"]["sticker_max"]), "capped (%d)" % stuck)


# --- Menschenkette ---------------------------------------------------------------------

func test_menschenkette_solo_uses_a_lamppost() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "menschenkette")
	var e := _enemy(s, "reichsbuerger", p.pos + Vector2(100, 0))
	s._fire(p, w, Vector2.RIGHT, p.pos + Vector2(200, 0))
	var lamps := s.summons.filter(func(x): return x.alive and x.type == Content.idx(Content.SUMMON_ORDER, "laterne"))
	assert_eq(lamps.size(), 1, "one lamppost")
	_run(s, 1)
	var hp := e.hp
	assert_true(hp < e.max_hp, "an enemy on the chain is hurt (immune ones too)")
	_run(s, 10)
	assert_near(e.hp, hp, 0.001, "at most once per 0.5 s, however many links it touches")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_eq(Array(vs.h_type).count(Content.idx(Content.HAZARD_ORDER, "kette")), 5, "five links in the snapshot")
	assert_true(Array(vs.s_type).has(Content.idx(Content.SUMMON_ORDER, "laterne")), "the lamppost is drawn")
	# a second cast keeps one chain (max 1)
	s._fire(p, w, Vector2.RIGHT, p.pos + Vector2(200, 0))
	assert_eq(s.summons.filter(func(x): return x.alive and x.type == Content.idx(Content.SUMMON_ORDER, "laterne")).size(), 1)
	assert_eq(s.hazards.filter(func(h): return h.alive and h.type == Content.idx(Content.HAZARD_ORDER, "kette")).size(), 5)


func test_menschenkette_coop_spans_to_teammate_and_tears() -> void:
	var s := _sim(["oma", "antifa"])
	var p: Sim.SimPlayer = s.players[1]
	var q: Sim.SimPlayer = s.players[2]
	q.pos = p.pos + Vector2(0, 200)
	var w := _weapon(s, "menschenkette")
	var e := _enemy(s, "besorgter_buerger", p.pos + Vector2(0, 100))
	s._fire(p, w, Vector2.RIGHT, p.pos + Vector2(200, 0))
	_run(s, 1)
	assert_true(e.hp < e.max_hp, "the chain to the teammate hurts")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_false(Array(vs.s_type).has(Content.idx(Content.SUMMON_ORDER, "laterne")), "lamppost hidden while the chain hangs on a teammate")
	# the teammate walks away: the chain falls back to the lamppost or tears
	q.pos = p.pos + Vector2(0, 500)
	var lamp: Sim.SimSummon = s.summons.filter(func(x): return x.type == Content.idx(Content.SUMMON_ORDER, "laterne"))[0]
	lamp.pos = p.pos + Vector2(-400, 0)
	e.hit_cd.clear()
	var hp := e.hp
	_run(s, 2)
	assert_true(lamp.data["torn"], "too long: torn")
	assert_near(e.hp, hp, 0.001, "a torn chain does no damage")
	s.build_view(vs)
	assert_eq(Array(vs.h_type).count(Content.idx(Content.HAZARD_ORDER, "kette")), 0, "a torn chain isn't drawn")


# --- Pappkamerad -----------------------------------------------------------------------

func test_pappkamerad_lures_and_bursts() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "pappkamerad")
	var e := _enemy(s, "besorgter_buerger", p.pos + Vector2(300, 0))
	e.speed = 95.0
	var elite := _enemy(s, "sylt_member", p.pos + Vector2(250, 60))
	s._fire(p, w, Vector2.RIGHT, e.pos)
	p.weapons.clear()
	var decoy: Sim.SimSummon = s.summons.filter(func(x): return x.type == Content.idx(Content.SUMMON_ORDER, "pappkamerad"))[0]
	assert_true(decoy.max_hp > 0.0, "has HP")
	s._step_enemies(0.0)
	assert_true(s._lure_for(e) == decoy, "a non-elite goes for the decoy")
	assert_true(s._lure_for(elite) == null, "elites ignore it")
	var hp0 := decoy.hp
	_run(s, 200)
	assert_true(e.pos.distance_to(decoy.pos) < 40.0, "walked to the decoy")
	assert_true(decoy.hp < hp0, "and hit it")
	var vs := ViewState.new()
	s.build_view(vs)
	var idx := Array(vs.s_type).find(Content.idx(Content.SUMMON_ORDER, "pappkamerad"))
	assert_true(vs.s_hp[idx] < 1.0, "HP bar in the snapshot")
	var ehp := e.hp
	s._hurt_decoy(decoy, 99999.0)
	assert_false(decoy.alive, "falls over")
	assert_true(e.hp < ehp, "confetti burst hurts nearby enemies")


# --- Demo-Sanis ------------------------------------------------------------------------

func test_demo_sanis_heal_shove_and_revive() -> void:
	var s := _sim(["oma", "antifa"])
	var p: Sim.SimPlayer = s.players[1]
	var q: Sim.SimPlayer = s.players[2]
	q.pos = p.pos + Vector2(40, 0)
	var w := _weapon(s, "demo_sanis")
	s._fire(p, w, Vector2.RIGHT)
	var sanis := s.summons.filter(func(x): return x.type == Content.idx(Content.SUMMON_ORDER, "sani"))
	assert_eq(sanis.size(), 1, "one Sani per copy")
	var sani: Sim.SimSummon = sanis[0]
	sani.pos = p.pos + Vector2(-20, 0)
	q.hp = 5.0
	p.hp = p.stats["max_hp"] - 1.0
	var e := _enemy(s, "besorgter_buerger", sani.pos + Vector2(-30, 0))
	s._fire(p, w, Vector2.RIGHT)
	assert_true(q.hp > 5.0, "heals the most injured player")
	assert_near(p.hp, p.stats["max_hp"] - 1.0, 0.001, "not the less injured one")
	assert_true(s.run_stats(p)["sani"] > 0, "healing is booked")
	assert_true(e.hp < e.max_hp, "Platz da! shoves and hurts a little")
	assert_eq(s.summons.filter(func(x): return x.type == Content.idx(Content.SUMMON_ORDER, "sani")).size(), 1, "still one")
	# a downed player next to her is revived 50 % faster
	q.state = 1
	q.revive_progress = 0.0
	q.pos = sani.pos + Vector2(10, 0)
	p.pos = q.pos + Vector2(20, 0)
	s._step_revives(1.0)
	assert_near(q.revive_progress, 1.5, 0.001, "revive +50 %")
	# she isn't an ally for Gewerkschaft's bonus (D-094)
	q.state = 2
	assert_eq(s._allies_near(p, 300.0), 0, "followers don't count")


# --- Lauti -----------------------------------------------------------------------------

func test_lauti_circles_and_pulses() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "lauti")
	s._fire(p, w, Vector2.RIGHT)
	var trucks := s.summons.filter(func(x): return x.type == Content.idx(Content.SUMMON_ORDER, "lauti"))
	assert_eq(trucks.size(), 1)
	var e := _enemy(s, "reichsbuerger", p.pos + Vector2(140, 0))
	var positions := []
	for i in 4:
		_run(s, 30)
		positions.append(trucks[0].pos)
		assert_near(trucks[0].pos.distance_to(p.pos), float(Content.WEAPONS["lauti"]["range"]), 2.0, "on its circle")
	assert_true(positions[0].distance_to(positions[3]) > 50.0, "it drives")
	assert_true(e.hp < e.max_hp, "the pulse hurts")
	s._fire(p, w, Vector2.RIGHT)
	assert_eq(s.summons.filter(func(x): return x.alive and x.type == Content.idx(Content.SUMMON_ORDER, "lauti")).size(), 1, "max 1, refreshed")
	assert_eq(s._allies_near(p, 300.0), 0, "the Lauti isn't an ally for the Gewerkschaft bonus")


func test_lauti_hits_an_enemy_once_per_pulse() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "lauti")
	s._fire(p, w, Vector2.RIGHT)
	var truck: Sim.SimSummon = s.summons[s.summons.size() - 1]
	var e := _enemy(s, "hinterbaenkler", truck.pos)
	truck.cd = 0.0
	var hp := e.hp
	s._step_v3_summon(truck, 0.0)
	var one := hp - e.hp
	assert_near(one, s.weapon_damage(p, w), 0.01, "exactly one hit per pulse")


# --- Snapshot ---------------------------------------------------------------------------

func test_status_flags_reach_the_client() -> void:
	var s := _sim()
	var e := _enemy(s, "lobbyist", Vector2(1100, 610))
	s._apply_silence(e, 3.0)
	s._apply_reverse(e, 1.0)
	s._apply_sticker(e, 2.0, 1, "w1")
	e.file_n = 3
	e.file_t = 5.0
	var vs := ViewState.new()
	s.build_view(vs)
	var f2: int = vs.e_flags2[0]
	assert_true(f2 & ViewState.EF2_SILENCED != 0)
	assert_true(f2 & ViewState.EF2_REVERSED != 0)
	assert_true(f2 & ViewState.EF2_STICKER != 0)
	assert_eq(ViewState.file_stacks(f2), 3)
	var dec := Snapshot.decode(Snapshot.encode(vs))
	assert_true(dec != null, "decodes")
	assert_eq(dec.e_flags2, vs.e_flags2, "second flag byte round trip")
	assert_eq(dec.e_flags, vs.e_flags, "first flag byte unchanged")
	_run(s, 400)
	s.build_view(vs)
	assert_eq(vs.e_flags2[0], 0, "all effects expire")


## D-086: everything the new weapons draw fades with own_fx_opacity.
func test_new_visuals_fade_with_own_fx() -> void:
	for proj in ["akte", "aktenblatt", "sticker"]:
		assert_true(WorldView.is_own_proj(proj), proj + " fades")
	assert_true(WorldView.is_own_hazard("kette"), "Menschenkette fades")
	var root := (Engine.get_main_loop() as SceneTree).root
	var w := WorldView.new()
	w.own_fx_override = 0.4
	root.add_child(w)
	var fx := Fx.new()
	fx.world = w
	root.add_child(fx)
	for kind in ["lauti", "sani", "konfetti", "offengelegt"]:
		fx.handle_event(["pulse", Vector2(100, 100), 90.0, kind])
	fx.handle_event(["swing", Vector2(100, 100), 0.0, 170.0, 90.0, "faktencheck"])
	assert_eq(fx._own_layer._pulses.size(), 4, "pulses are drawn on the own-effects layer")
	assert_true(is_same(fx._own_layer._pulses, fx._pulses), "shared, not copied")
	assert_eq(fx._own_layer._swings.size(), 1, "the Faktencheck cone too")
	fx.free()
	w.free()


## Crowd cap (D-091): Faktencheck damages the 4 nearest in its cone but turns everyone around.
func test_faktencheck_damage_cap_reverse_all() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := _weapon(s, "faktencheck")
	var crowd := []
	for k in 7:
		crowd.append(_enemy(s, "besorgter_buerger", p.pos + Vector2(60 + k * 14, (k % 3 - 1) * 20)))
	s._fire(p, w, Vector2.RIGHT)
	assert_eq(crowd.filter(func(e): return e.hp < e.max_hp).size(), 4, "damage to the 4 nearest")
	assert_eq(crowd.filter(func(e): return e.reverse_t > 0.0).size(), 7, "everyone turns around")
