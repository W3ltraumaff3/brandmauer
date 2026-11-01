extends TestCase
## Simulation tests (GDD §4–§16). The full-run tests drive a bot through all
## 20 waves so every enemy, encounter and shop path executes at least once.


func _sim(chars: Array, org := "gewerkschaft", seed := 7) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": org, "difficulty": 0})
	return s


func _to_shop(s: Sim) -> void:
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 20000:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(1.0 / 60.0)
		guard += 1


func test_wave_lengths_ramp_to_about_16_minutes() -> void:
	var total := 0.0
	for w in range(1, 20):
		total += Content.wave_length(w)
	assert_eq(total, 960.0, "waves 1-19 seconds")
	assert_eq(Content.wave_length(20), -1.0, "boss wave has no timer")


func test_start_run() -> void:
	var s := _sim(["oma", "antifa"])
	assert_eq(s.wave, 1)
	assert_eq(s.phase, Sim.Phase.WAVE)
	assert_eq(s.players.size(), 2)
	var oma: Sim.SimPlayer = s.players[1]
	assert_near(oma.stats["max_hp"], 30.0, 0.01, "oma max hp")
	assert_near(oma.hp, 30.0, 0.01)
	assert_eq(oma.weapons[0]["id"], "stricknadeln")
	assert_eq(s.wall.count(false), 1, "one hole at start")


func test_determinism() -> void:
	var a := _sim(["stadtbild"], "omas", 42)
	var b := _sim(["stadtbild"], "omas", 42)
	for i in 900:
		a.set_input(1, Vector2(sin(i * 0.05), cos(i * 0.03)))
		b.set_input(1, Vector2(sin(i * 0.05), cos(i * 0.03)))
		a.step(1.0 / 60.0)
		b.step(1.0 / 60.0)
	assert_eq(a.enemies.size(), b.enemies.size(), "enemy count")
	var sa := Vector2.ZERO
	var sb := Vector2.ZERO
	for e in a.enemies:
		sa += e.pos
	for e in b.enemies:
		sb += e.pos
	assert_true(sa.is_equal_approx(sb), "enemy positions")
	assert_eq(a.players[1].pfand, b.players[1].pfand, "pfand")


func test_vertrag_unanimous_or_worst() -> void:
	var opts := ["digitalpakt", "mindestlohn", "sanktionen"]
	assert_eq(Sim.resolve_votes(opts, {1: 1, 2: 1}, [1, 2]), "mindestlohn", "unanimous")
	assert_eq(Sim.resolve_votes(opts, {1: 0, 2: 1}, [1, 2]), "sanktionen", "split -> worst")
	assert_eq(Sim.resolve_votes(opts, {1: 0}, [1, 2]), "sanktionen", "missing vote -> worst")
	assert_eq(Sim.resolve_votes(opts, {1: 0}, [1]), "digitalpakt", "solo choice")


func test_shop_buy_reroll_sell_deny() -> void:
	var s := _sim(["sozialtourist"])
	_to_shop(s)
	assert_eq(s.phase, Sim.Phase.SHOP)
	var p: Sim.SimPlayer = s.players[1]
	assert_eq(p.offers.size(), 4)
	p.pfand = 0
	assert_false(s.request(1, "buy", 0), "no pfand -> deny")
	var denied := s.take_events().any(func(e): return e[0] == "deny" and e[2] == "DENY_NO_PFAND")
	assert_true(denied, "deny event")
	p.pfand = 1000
	assert_true(s.request(1, "buy", 0), "buy")
	assert_true(p.offers[0]["sold"])
	assert_eq(p.free_rerolls, 2, "sozialtourist free rerolls")
	var before := p.pfand
	assert_true(s.request(1, "reroll"))
	assert_eq(p.pfand, before, "free reroll costs nothing")
	assert_false(s.request(1, "sell", 0) and p.weapons.size() == 0, "never sells the last weapon")


func test_spend_limit_schuldenbremse() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	p.items.append("schuldenbremse")
	s._recompute(p)
	p.pfand = 10000
	p.spent = s._spend_limit(p)
	p.offers[0]["price"] = 5
	assert_false(s.request(1, "buy", 0), "over limit")
	p.items.append("sondervermoegen")
	s._recompute(p)
	assert_true(s.request(1, "buy", 0), "sondervermoegen lifts the limit")


func test_kasse_and_steuermoral() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	s.players[1].pfand = 50
	var before: int = s.players[2].pfand
	assert_true(s.request(1, "kasse_in"))
	assert_false(s.request(2, "kasse_out"), "needs 20 in the Kasse")
	assert_true(s.request(1, "kasse_in"))
	assert_true(s.request(2, "kasse_out"))
	assert_eq(s.kasse, 0)
	assert_eq(s.players[2].pfand - before, 15, "20 minus 25 % Kapitalertragsteuer")
	s._finish(false)
	assert_near(s.result["players"][1]["steuermoral"], 1.0)
	assert_near(s.result["players"][2]["steuermoral"], 0.0)


func test_ready_starts_next_wave() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	s.request(1, "ready", true)
	assert_eq(s.phase, Sim.Phase.SHOP, "waits for everyone")
	s.request(2, "ready", true)
	assert_eq(s.phase, Sim.Phase.WAVE)
	assert_eq(s.wave, 2)


func test_levelup_applies_stat() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	p.levelups = 1
	s._make_levelup_options(p)
	var o: Dictionary = p.levelup_options[0]
	var before: float = p.stats[o["stat"]]
	assert_true(s.request(1, "levelup", 0))
	assert_near(p.stats[o["stat"]], before + o["amount"], 0.001)
	assert_eq(p.levelups, 0)


func test_view_arrays_consistent() -> void:
	var s := _sim(["lastenrad", "toechter"], "antifa")
	for i in 1200:
		s.step(1.0 / 60.0)
	var vs := ViewState.new()
	s.build_view(vs)
	assert_eq(vs.e_id.size(), vs.e_pos.size())
	assert_eq(vs.e_id.size(), vs.e_flags.size())
	assert_eq(vs.p_type.size(), vs.p_ang.size())
	assert_eq(vs.h_type.size(), vs.h_life.size())
	assert_eq(vs.players.size(), 2)
	assert_true(vs.e_id.size() > 0, "enemies spawned")


func test_solo_death_ends_run() -> void:
	var s := _sim(["buergergeld"])
	var p: Sim.SimPlayer = s.players[1]
	s.damage_player(p, 9999.0)
	assert_eq(s.phase, Sim.Phase.OVER)
	assert_false(s.result["won"])


func test_coop_down_and_revive() -> void:
	var s := _sim(["oma", "antifa"])
	var a: Sim.SimPlayer = s.players[1]
	var b: Sim.SimPlayer = s.players[2]
	a.stats["dodge"] = 0.0
	s.damage_player(a, 9999.0)
	assert_eq(a.state, 1, "downed")
	assert_eq(s.phase, Sim.Phase.WAVE, "run continues")
	b.pos = a.pos
	for i in 200:
		b.iframes = 10.0
		s.step(1.0 / 60.0)
		b.pos = a.pos
	assert_eq(a.state, 0, "revived")


## Bot: invulnerable, very strong, buys stuff, readies up. Plays all 20 waves.
func _full_run(chars: Array, org: String, seed: int) -> Sim:
	var s := _sim(chars, org, seed)
	for p in s.players.values():
		p.levelup_stats["damage"] = 4000.0
		s._recompute(p)
	var steps := 0
	while s.phase != Sim.Phase.OVER and steps < 200000:
		if s.phase == Sim.Phase.SHOP:
			for p in s.players.values():
				s.request(p.id, "buy", 0)
				s.request(p.id, "levelup", 0)
				s.request(p.id, "vote", 0)
				s.request(p.id, "kasse_in")
				s.request(p.id, "repair_wall")
			for p in s.players.values():
				s.request(p.id, "ready", true)
		else:
			for p in s.players.values():
				p.iframes = 10.0
				var target := Vector2(800, 600)
				var best := INF
				for e in s.enemies:
					if e.alive and not e.behind and (e.elite or best == INF) and e.pos.distance_to(p.pos) < best:
						best = e.pos.distance_to(p.pos) if not e.elite else -1.0
						target = e.pos
				p.input = (target - p.pos).normalized() if target.distance_to(p.pos) > 60.0 else Vector2.ZERO
			if s.streik_available:
				s.request(1, "streik")
			s.step(1.0 / 60.0)
		s.take_events()
		steps += 1
	return s


func test_full_run_solo_wins() -> void:
	var s := _full_run(["stadtbild"], "gewerkschaft", 3)
	assert_eq(s.phase, Sim.Phase.OVER, "run finished")
	assert_true(s.result.get("won", false), "won")
	assert_eq(s.result["encounters_beaten"].size(), 4, "all encounters beaten %s" % [s.result["encounters_beaten"]])
	assert_has(s.players[1].achievements, "ach_aufsichtsrat")
	assert_has(s.players[1].achievements, "ach_remigration")
	assert_true(s.time < 25.0 * 60.0, "under 25 sim minutes: %.0f s" % s.time)
	assert_true(not s.result["quotes"].is_empty(), "album quotes unlocked")


func test_full_run_coop_all_characters_and_orgs() -> void:
	var chars := Content.CHAR_ORDER.duplicate()
	var orgs := Content.ORG_ORDER
	for i in range(0, chars.size(), 4):
		var group := chars.slice(i, i + 4)
		var s := _full_run(group, orgs[(i / 4) % orgs.size()], 10 + i)
		assert_true(s.result.get("won", false), "group %s won" % [group])


func test_meta_shape() -> void:
	var s := _sim(["gewerkschaft"])
	var m := s.build_meta()
	for key in ["wave", "phase", "org", "kasse", "wall_holes", "streik", "vertrag", "team", "players", "result"]:
		assert_true(m.has(key), "meta has " + key)
	var pm: Dictionary = m["players"][1]
	for key in ["pfand", "stats", "weapons", "offers", "levelup_options", "ready", "spend_left"]:
		assert_true(pm.has(key), "player meta has " + key)


func test_pickups_are_capped_without_losing_pfand() -> void:
	var s := _sim(["oma"])
	var t := Content.idx(Content.PICKUP_ORDER, "pfand")
	for i in 400:
		s._drop(t, Vector2(500, 500), 1)
	assert_true(s.pickups.size() <= Sim.MAX_PICKUPS, "capped: %d" % s.pickups.size())
	var total := 0
	for k in s.pickups:
		total += k.value
	assert_true(total >= 395, "value kept: %d" % total)


func test_kasse_disabled_in_solo() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	s.players[1].pfand = 100
	assert_false(s.request(1, "kasse_in"), "no Kasse in solo")
	assert_false(s.build_meta()["kasse_enabled"])


func test_repair_wall_from_kasse_is_cheaper() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	s.wall[0] = false
	s.kasse = 1000
	var holes := s.wall.count(false)
	assert_true(s.request(2, "repair_wall_kasse"))
	assert_eq(s.wall.count(false), holes - 1)
	assert_eq(s.kasse, 1000 - s.kasse_repair_price())
	assert_true(s.kasse_repair_price() < Content.repair_price(s.wave))


func test_coop_only_items_not_in_solo_shop() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	for i in 400:
		var o := s._roll_offer(p)
		assert_false(Content.ITEMS.get(o["id"], {}).get("coop_only", false), "coop item offered in solo: " + o["id"])

