extends TestCase
## Simulation tests (GDD §4–§16). The full-run tests drive a bot through all
## 20 waves so every enemy, encounter and shop path executes at least once.


func _sim(chars: Array, org := "gewerkschaft", seed := 7) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": org, "difficulty": 0, "skip_intro": true})
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
	assert_eq(Sim.resolve_votes(opts, {1: 0}, [1]), "digitalpakt", "solo choice")
	assert_eq(Sim.resolve_votes(opts, {1: 0, 2: -1}, [1, 2]), "digitalpakt", "abstention doesn't count")
	assert_eq(Sim.resolve_votes(opts, {1: -1, 2: -1}, [1, 2]), "", "everyone abstains -> no contract")
	assert_eq(Sim.resolve_votes(opts, {}, [1]), "", "nobody voted -> no contract")


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


func test_target_modes() -> void:
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	s.enemies.clear()
	var near := s.spawn_enemy("besorgter_buerger", p.pos + Vector2(60, 0))
	var tank := s.spawn_enemy("reichsbuerger", p.pos + Vector2(200, 0))
	var weak := s.spawn_enemy("ju_schnoesel", p.pos + Vector2(-150, 0))
	near.behind = false
	tank.behind = false
	weak.behind = false
	weak.hp = 1.0
	assert_eq(s._pick_target(p.pos, 400.0, Sim.Target.CLOSEST), near, "closest")
	assert_eq(s._pick_target(p.pos, 400.0, Sim.Target.MOST_HP), tank, "most hp")
	assert_eq(s._pick_target(p.pos, 400.0, Sim.Target.LEAST_HP), weak, "least hp")
	assert_true(s.request(1, "target_mode", 2))
	assert_eq(p.target_mode, 2)


func test_boss_intro_pauses_until_everyone_continues() -> void:
	var s := Sim.new()
	s.start_run({"seed": 1, "players": [{"id": 1, "char": "oma"}, {"id": 2, "char": "antifa"}], "org": "omas"})
	s._begin_wave(5)
	assert_true(s.intro_wait, "boss card pauses")
	var t := s.wave_time
	s.step(1.0)
	assert_eq(s.wave_time, t, "world frozen")
	s.request(1, "continue_intro")
	assert_true(s.intro_wait, "waits for player 2")
	s.request(2, "continue_intro")
	assert_false(s.intro_wait, "continues")
	s.step(0.5)
	assert_true(s.wave_time > t, "world runs again")


func test_shots_pass_holes_but_not_wall() -> void:
	var s := _sim(["oma"])
	for i in Sim.WALL_SEGMENTS:
		s.wall[i] = true
	var below := Vector2(100, 300)
	var above := Vector2(100, 40)
	assert_true(s.shot_blocked(below, above), "intact wall blocks")
	s.wall[0] = false
	assert_false(s.shot_blocked(below, above), "hole lets shots through")
	assert_false(s.shot_blocked(below, Vector2(500, 600)), "same side never blocked")


func test_every_weapon_aims_at_closest_enemy_in_all_directions() -> void:
	for wid in Content.WEAPON_ORDER:
		var kind: String = Content.WEAPONS[wid]["kind"]
		if kind == "orbit" or kind == "turret":
			continue  # orbit circles the player; turrets place a stand, then aim on their own
		for k in 8:
			var ang := TAU * k / 8.0
			var s := _sim(["oma"])
			var p: Sim.SimPlayer = s.players[1]
			p.pos = Vector2(800, 560)
			p.input = Vector2.ZERO
			p.weapons = [{"id": wid, "tier": 1, "cd": 0.0, "angle": 0.0}]
			s.enemies.clear()
			s.projectiles.clear()
			s.hazards.clear()
			s.take_events()
			var reach: float = s._weapon_range(p, Content.WEAPONS[wid])
			var near := s.spawn_enemy("hinterbaenkler", p.pos + Vector2.RIGHT.rotated(ang) * reach * 0.5)
			var far := s.spawn_enemy("hinterbaenkler", p.pos + Vector2.RIGHT.rotated(ang + PI) * reach * 0.9)
			for e in [near, far]:
				e.speed = 0.0
				e.behind = false
			s._build_grid()
			s._step_weapons(1.0 / 60.0)
			var want := Vector2.RIGHT.rotated(ang)
			var label := "%s at %d°" % [wid, k * 45]
			match kind:
				"shot":
					var shots := s.projectiles.filter(func(pr): return pr.owner == 1)
					assert_false(shots.is_empty(), label + " fired")
					for pr in shots:
						assert_true(pr.vel.normalized().dot(want) > 0.95, label + " aims at closest")
				"cone":
					var swings := s.take_events().filter(func(e): return e[0] == "swing")
					assert_false(swings.is_empty(), label + " swung")
					for sw in swings:
						assert_true(Vector2.RIGHT.rotated(sw[2]).dot(want) > 0.95, label + " swings at closest")
					assert_true(near.hp < near.max_hp, label + " hit the closest enemy")
				"puddle":
					var puddles := s.hazards.filter(func(h): return h.owner == 1)
					assert_false(puddles.is_empty(), label + " placed glue")
					for h in puddles:
						assert_true(h.pos.distance_to(near.pos) < 1.0, label + " glue on closest")


func test_every_ultimate_fires_once_per_wave() -> void:
	for char_id in Content.CHAR_ORDER:
		var s := _sim([char_id, "oma"])
		var p: Sim.SimPlayer = s.players[1]
		for i in 6:
			var e := s.spawn_enemy("hinterbaenkler", p.pos + Vector2(80, 0).rotated(i))
			e.behind = false
		s._build_grid()
		s.take_events()
		assert_true(s.request(1, "ultimate"), char_id + " ult fires")
		assert_false(s.request(1, "ultimate"), char_id + " only once per wave")
		var evs := s.take_events().filter(func(e): return e[0] == "ult")
		assert_eq(evs.size(), 1, char_id + " ult event")
		for i in 120:
			s.step(1.0 / 60.0)
		_to_shop(s)
		s.request(1, "ready", true)
		s.request(2, "ready", true)
		assert_true(s.players[1].ult_ready, char_id + " ult ready again next wave")


func test_ultimate_effects() -> void:
	var s := _sim(["toechter", "buergergeld"])
	var p: Sim.SimPlayer = s.players[1]
	var suit := s.spawn_enemy("lobbyist", p.pos + Vector2(100, 0))
	var other := s.spawn_enemy("besorgter_buerger", p.pos + Vector2(-100, 0))
	suit.behind = false
	other.behind = false
	s.request(1, "ultimate")
	assert_true(suit.stun_t > 0.0 and suit.vuln_t > 0.0, "suit stunned and vulnerable")
	assert_eq(other.stun_t, 0.0, "non-suit unaffected")
	s.request(2, "ultimate")
	assert_true(s.effects.has("antrag_gestellt"), "paperwork storm active")
	var meta := s.build_meta()
	assert_true(meta["effects"].has("antrag_gestellt"))
	assert_false(meta["players"][1]["ult_ready"])

	var t := _sim(["oma", "antifa"])
	var b: Sim.SimPlayer = t.players[2]
	b.stats["dodge"] = 0.0
	t.damage_player(b, 9999.0)
	assert_eq(b.state, 1, "downed")
	t.request(1, "ultimate")
	assert_eq(b.state, 0, "Kaffee und Kuchen revives")
	assert_true(t.request(2, "ultimate"), "antifa ult")
	var comrades := t.summons.filter(func(x): return x.type == Content.idx(Content.SUMMON_ORDER, "genosse"))
	assert_eq(comrades.size(), 6, "Schwarzer Block spawns 6")


func test_run_stats_track_damage_per_weapon_and_heals() -> void:
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	p.stats["lifesteal"] = 100.0
	p.hp = 1.0
	for i in 1800:
		p.iframes = 10.0
		s.step(1.0 / 60.0)
	var st := s.run_stats(p)
	assert_false(st["damage"].is_empty(), "damage recorded")
	var row: Dictionary = st["damage"][0]
	assert_eq(row["kind"], "weapon")
	assert_eq(row["id"], "stricknadeln")
	assert_true(row["total"] > 0, "stricknadeln dealt damage")
	assert_true(st["lifesteal"] > 0, "lifesteal healed")
	assert_true(st["pfand_collected"] >= 0)
	var m := s.build_meta()
	assert_true(m["players"][1].has("run_stats"))


func test_ready_needs_vote_when_contract_is_open() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	s.vertrag["options"] = ["digitalpakt", "tempolimit", "sanktionen"]
	s.vertrag["votes"] = {}
	assert_false(s.request(1, "ready", true), "must vote first")
	assert_true(s.request(1, "vote", -1), "abstain")
	assert_true(s.request(1, "ready", true), "ready after abstaining")
	assert_eq(s.vertrag["active"], "", "nobody voted -> no contract")


func test_discard_items() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	p.items.append_array(["schuldenbremse", "solibutton", "solibutton", "solibutton"])
	s._recompute(p)
	assert_true(s.request(1, "discard_item", {"id": "solibutton", "count": 1}))
	assert_eq(p.items.count("solibutton"), 2, "one removed")
	assert_true(s.request(1, "discard_item", {"id": "solibutton", "count": -1}))
	assert_eq(p.items.count("solibutton"), 0, "all removed")
	assert_true(s.request(1, "discard_item", {"id": "schuldenbremse", "count": 1}))
	assert_false(p.flags.has("schuldenbremse"), "curse gone")
	assert_false(s.request(1, "discard_item", {"id": "schuldenbremse", "count": 1}), "nothing left")


func test_item_rarities_and_red_builds() -> void:
	for id in Content.ITEM_ORDER:
		var r := int(Content.ITEMS[id]["rarity"])
		assert_true(r >= 1 and r <= 4, id + " rarity")
	assert_eq(Content.rarity_weight(4, 3, 0.0), 0.0, "no red items early")
	assert_true(Content.rarity_weight(4, 15, 0.0) > 0.0, "red items late")
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	var melee := {"id": "doener", "tier": 1, "cd": 0.0, "angle": 0.0}
	var ranged := {"id": "stricknadeln", "tier": 1, "cd": 0.0, "angle": 0.0}
	var m0 := s.weapon_damage(p, melee)
	var r0 := s.weapon_damage(p, ranged)
	p.items.append("hausbesetzung")
	s._recompute(p)
	assert_near(s.weapon_damage(p, melee), m0 * 2.0, 0.01, "melee doubled")
	assert_near(s.weapon_damage(p, ranged), r0 * 0.5, 0.01, "ranged halved")
	p.items.append("lastenrad_anhaenger")
	s._recompute(p)
	assert_eq(p.max_weapons, Content.MAX_WEAPONS + 1, "extra weapon slot")
	p.items.append("tarnkappe")
	p.items.append("betriebsrat")
	s._recompute(p)
	assert_eq(p.stats["armor"], 0.0, "Tarnkappe zeroes armor")


func test_combine_weapons() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	p.pfand = 10000
	# buying a twin combines automatically, even with full slots
	while p.weapons.size() < p.max_weapons:
		s._add_weapon(p, "tofu", 1)
	p.offers[0] = {"kind": "weapon", "id": "stricknadeln", "tier": 1, "price": 10, "sold": false}
	assert_true(s.request(1, "buy", 0), "buy twin with full slots")
	assert_eq(p.weapons.filter(func(w): return w["id"] == "stricknadeln").size(), 1, "merged into one")
	assert_eq(int(p.weapons.filter(func(w): return w["id"] == "stricknadeln")[0]["tier"]), 2, "tier 2")
	# manual combine of two tofu I
	var i := -1
	for k in p.weapons.size():
		if p.weapons[k]["id"] == "tofu":
			i = k
			break
	var before := p.weapons.size()
	assert_true(s.request(1, "combine", i))
	assert_eq(p.weapons.size(), before - 1)
	assert_true(p.weapons.any(func(w): return w["id"] == "tofu" and int(w["tier"]) == 2), "tofu II")
	assert_eq(Sim.find_twin(p, "x", 4, -1), -1, "tier IV never combines")


func test_no_real_quote_bubbles_in_waves() -> void:
	var s := _sim(["oma"])
	for i in 60 * 40:
		s.players[1].iframes = 10.0
		s.step(1.0 / 60.0)
		for e in s.take_events():
			if e[0] == "say":
				assert_eq(str(e[3]), "", "no real quote bubble during a wave")


func test_new_weapons_fire_and_hit() -> void:
	for wid in ["kartoffelbrei", "trillerpfeife", "brandmauer_ziegel", "normenkontrolle", "unterschriftenliste",
			"scheinwerfer", "neun_euro_ticket", "weisser_overall"]:
		var s := _sim(["oma"])
		var p: Sim.SimPlayer = s.players[1]
		p.pos = Vector2(800, 560)
		p.weapons.clear()
		s._add_weapon(p, wid, 1)
		s.enemies.clear()
		var targets := []
		for k in 4:
			var e := s.spawn_enemy("reichsbuerger", p.pos + Vector2(110 + k * 40, k * 10))
			e.behind = false
			e.speed = 0.0
			targets.append(e)
		for i in 240:
			p.iframes = 10.0
			s.step(1.0 / 60.0)
		var hurt := targets.filter(func(e): return not e.alive or e.hp < e.max_hp)
		assert_false(hurt.is_empty(), wid + " damaged enemies")
		assert_false(s.run_stats(p)["damage"].is_empty(), wid + " recorded damage")


func test_politics_items() -> void:
	var s := _sim(["oma"])
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	p.pfand = 0
	p.offers[0] = {"kind": "item", "id": "maut_vertrag", "tier": 1, "price": 0, "sold": false}
	assert_true(s.request(1, "buy", 0))
	assert_eq(p.pfand, Content.RED_BUILD["maut_now"], "Maut pays on purchase")
	p.items.append("zweiter_wahlgang")
	s._recompute(p)
	s.request(1, "ready", true)
	p.stats["dodge"] = 0.0
	p.iframes = 0.0
	s.damage_player(p, 9999.0)
	assert_eq(p.state, 0, "Zweiter Wahlgang saves once")
	assert_near(p.hp, p.stats["max_hp"] * 0.5, 0.01)
	p.iframes = 0.0
	s.damage_player(p, 9999.0)
	assert_eq(s.phase, Sim.Phase.OVER, "only once per run")
	var t := _sim(["oma"])
	var q: Sim.SimPlayer = t.players[1]
	q.items.append("ber_eroeffnungstermin")
	t._recompute(q)
	assert_eq(t.dyn_damage(q), -10.0, "BER early")
	t.wave = 10
	assert_eq(t.dyn_damage(q), 40.0, "BER late")

