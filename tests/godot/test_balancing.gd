extends TestCase
## Balancing rules (docs/specs/balancing.md): level-up schedule and rarities,
## Brotato lifesteal, boss retry, boss phase 2, Umfrage from the start.

const AREAS := ["sim", "content", "ui"]  # ci-cd.md §2a


func _sim(chars: Array, extra := {}) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var cfg := {"seed": 3, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true}
	cfg.merge(extra, true)
	var s := Sim.new()
	s.start_run(cfg)
	return s


func _to_shop(s: Sim) -> void:
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 40000:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(1.0 / 60.0)
		guard += 1


## §4: picks per Späti 1 / 2 / 3 (waves 1–4 / 5–11 / 12–19), the same for 1 and 4 players; team levels no longer give picks.
func test_levelup_picks_per_spaeti_not_per_team_level() -> void:
	assert_eq(Content.levelups_after_wave(1), 1)
	assert_eq(Content.levelups_after_wave(4), 1)
	assert_eq(Content.levelups_after_wave(5), 2)
	assert_eq(Content.levelups_after_wave(11), 2)
	assert_eq(Content.levelups_after_wave(12), 3)
	assert_eq(Content.levelups_after_wave(19), 3)
	for chars in [["oma"], ["oma", "antifa", "lastenrad", "stadtbild"]]:
		var s := _sim(chars)
		s._add_xp(500.0)
		assert_true(s.team_level > 3, "team levels still rise")
		for p in s.players.values():
			assert_eq(p.levelups, 0, "team levels give no picks")
		_to_shop(s)
		for p in s.players.values():
			assert_eq(p.levelups, 1, "%d player(s): one pick after wave 1" % chars.size())
			assert_eq(p.levelup_options.size(), 4)


## §4: options carry an item rarity; the amount is base × rarity multiplier.
func test_levelup_options_have_rarities() -> void:
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	p.levelups = 1
	s.wave = 18
	var seen := {}
	for i in 60:
		s._make_levelup_options(p)
		for o in p.levelup_options:
			var r := int(o["rarity"])
			seen[r] = true
			var mult: float = Content.BALANCE["levelup_rarity_mult"][r - 1]
			assert_near(float(o["amount"]), Content.LEVELUP_AMOUNTS[o["stat"]] * mult, 0.001, "amount × rarity")
	assert_true(seen.has(1) and seen.has(4), "late waves roll green and red level-ups (%s)" % [seen.keys()])
	s.wave = 1
	var early := {}
	for i in 60:
		s._make_levelup_options(p)
		for o in p.levelup_options:
			early[int(o["rarity"])] = true
	assert_false(early.has(4), "no red level-ups at the start")


## §6: 1 Umverteilung = 1 % chance per hit to heal 1 HP.
func test_lifesteal_is_one_percent_per_point() -> void:
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	p.stats["lifesteal"] = 10.0
	var e := s.spawn_enemy("besorgter_buerger", p.pos + Vector2(300, 0))
	e.behind = false
	var heals := 0
	var n := 4000
	for i in n:
		e.hp = 1.0e9
		e.alive = true
		p.hp = 1.0
		p.lifesteal_cd = 0.0
		s._damage_enemy(e, 1.0, p, false, Vector2.RIGHT, 0.0, "test")
		if p.hp > 1.0:
			heals += 1
	assert_near(float(heals) / n, 0.10, 0.025, "10 points: about 10 % of hits heal")


## §8: with Boss-Wiederholung a wiped boss wave starts over with the same encounter.
func test_boss_retry_restarts_the_boss_wave() -> void:
	for on in [true, false]:
		var s := _sim(["oma", "antifa"], {"boss_retry": on})
		s._begin_wave(5)
		var enc := s.encounter
		assert_true(enc != "", "wave 5 has an elite")
		for p in s.players.values():
			p.stats["dodge"] = 0.0
			p.iframes = 0.0
			s.damage_player(p, 1.0e6)
		for i in 30:
			s.step(1.0 / 60.0)
		if on:
			assert_true(s.phase == Sim.Phase.WAVE, "retry: still playing")
			assert_eq(s.wave, 5, "same wave")
			assert_eq(s.encounter, enc, "same encounter")
			assert_eq(s.retries, 1, "counted")
			for p in s.players.values():
				assert_eq(p.state, 0, "everyone back")
		else:
			assert_eq(s.phase, Sim.Phase.OVER, "without the option the run ends")
	# Regular waves never retry.
	var t := _sim(["oma"], {"boss_retry": true})
	t._begin_wave(3)
	var q: Sim.SimPlayer = t.players[1]
	q.stats["dodge"] = 0.0
	q.iframes = 0.0
	t.damage_player(q, 1.0e6)
	for i in 30:
		t.step(1.0 / 60.0)
	assert_eq(t.phase, Sim.Phase.OVER, "no retry in a regular wave")


## §8, D-164: a retry brings back who is down, never who left the run.
func test_boss_retry_keeps_who_left_gone() -> void:
	var s := _sim(["oma", "antifa"], {"boss_retry": true})
	s._begin_wave(5)
	s.remove_player(2)
	var p: Sim.SimPlayer = s.players[1]
	p.stats["dodge"] = 0.0
	p.iframes = 0.0
	s.damage_player(p, 1.0e6)
	for i in 30:
		s.step(1.0 / 60.0)
	assert_eq(s.retries, 1, "retried")
	assert_eq(s.players[1].state, 0, "the downed player is back")
	assert_eq(s.players[2].state, 2, "who left stays gone")


## §7 (D-106): the old 50 % switch is gone; the tempo comes with the phases at
## 66 % / 33 % of the encounter's total HP (the Sylt-Clique as one group).
func test_elite_phase_tempo() -> void:
	var s := _sim(["oma"])
	s._begin_wave(5)
	for i in 300:
		s.players[1].iframes = 10.0
		s.step(1.0 / 60.0)
	var elites := s.enemies.filter(func(e): return e.alive and e.elite and e.encounter != "")
	assert_false(elites.is_empty(), "elite spawned")
	var boss = elites[0]
	assert_eq(boss.phase, 0, "phase 1 at full HP")
	assert_near(boss.tempo, 1.0, 0.0001, "normal tempo")
	boss.hp = boss.max_hp * 0.4   # one member at 40 %: the group is still above 66 %
	s.players[1].iframes = 10.0
	s.step(1.0 / 60.0)
	assert_eq(boss.phase, 0, "one hurt member doesn't change the group's phase")
	for e in elites:
		e.hp = e.max_hp * 0.6
	s.players[1].iframes = 10.0
	s.step(1.0 / 60.0)
	for e in elites:
		assert_eq(e.phase, 1, "the whole clique enters phase 2")
		assert_near(e.tempo, float(Content.BOSS["phase_tempo"][1]), 0.0001, "phase 2 tempo")


## §5: every Späti offers a weapon for the build (fitting scaling or a weapon you hold).
func test_every_shop_has_a_weapon_for_your_build() -> void:
	for start in ["doener", "stricknadeln", "kleber", "infostand"]:
		var s := _sim(["oma"])
		var p: Sim.SimPlayer = s.players[1]
		p.weapons.clear()
		s._add_weapon(p, start, 1)
		var style := Sim.weapon_style(p)
		for i in 200:
			s.wave = 1 + i % 19
			s._make_offers(p)
			var ok := false
			for o in p.offers:
				if o["kind"] == "weapon" and (o["id"] == start or Sim.style_match(style, o["id"]) >= 0.5):
					ok = true
			assert_true(ok, "%s: a fitting weapon in every shop (roll %d)" % [start, i])
			if not ok:
				break
			assert_eq(p.offers.size(), 4, "still 4 offers")


## §5a: every row of the Reichensteuer table in the spec.
func test_reichensteuer_table() -> void:
	var rows := [
		[[150, 100], [150, 100]], [[200, 100], [175, 125]], [[300, 100], [225, 175]], [[100, 0], [55, 45]],
		[[300, 100, 100], [210, 145, 145]], [[300, 100, 50], [188, 131, 131]], [[300, 300, 100], [255, 255, 190]],
		[[300, 100, 100, 100], [195, 135, 135, 135]], [[300, 200, 100, 100], [234, 166, 150, 150]],
		[[300, 300, 100, 100], [223, 223, 177, 177]], [[400, 300, 100, 100], [323, 223, 177, 177]],
		[[300, 300, 300, 100], [275, 275, 273, 177]],
	]
	for row in rows:
		var before: Array = row[0]
		var d := {}
		for i in before.size():
			d[i + 1] = before[i]
		var t := Sim.reichensteuer(d)
		var after := []
		var sum := 0
		for i in before.size():
			after.append(int(before[i]) + int(t[i + 1]))
			sum += int(t[i + 1])
		assert_eq(after, row[1], "%s" % [before])
		assert_eq(sum, 0, "%s: nothing created or lost" % [before])
		# Order kept: whoever had more still has at least as much.
		for i in before.size():
			for j in before.size():
				if int(before[i]) > int(before[j]):
					assert_true(after[i] >= after[j], "%s: order kept" % [before])


## §5a: in a real co-op wave end the tax moves Pfand and is logged; solo never pays.
func test_reichensteuer_at_wave_end() -> void:
	var s := _sim(["oma", "antifa", "lastenrad", "stadtbild"])
	_to_shop(s)
	s._begin_wave(2)
	var ps := s.players.values()
	var paid_before := int(ps[0].log["tax_paid"])   # wave 1 may already have taxed someone
	for i in ps.size():
		ps[i].collected_wave = 300 if i == 0 else 100
		ps[i].pfand = 1000
	s._apply_reichensteuer()
	assert_eq(ps[0].tax_wave, -105, "rich player pays")
	assert_eq(ps[0].pfand, 895)
	for i in range(1, 4):
		assert_eq(ps[i].tax_wave, 35, "the others receive")
	assert_eq(int(ps[0].log["tax_paid"]) - paid_before, 105, "logged as paid")
	assert_eq(int(s.build_meta()["players"][ps[1].id]["tax_wave"]), 35, "Späti sees it")
	var solo := _sim(["oma"])
	solo.players[1].collected_wave = 500
	solo._apply_reichensteuer()
	assert_eq(solo.players[1].tax_wave, 0, "no tax in solo")


## §3: every Umfrage level can be picked from the start.
func test_every_umfrage_level_selectable() -> void:
	var save: Node = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Save")
	if save:
		save.data["max_umfrage"] = 0
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	UIApi.preview_lobby = {1: {"name": "A", "char": "oma", "ready": false}}
	var l := Lobby.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(l)
	var pick := l.find_child("diff_pick", true, false) as OptionButton
	assert_true(pick != null, "picker for the host")
	if pick:
		assert_eq(pick.item_count, Content.DIFFICULTY_PERCENT.size())
		for i in pick.item_count:
			assert_false(pick.is_item_disabled(i), "Umfrage %d %% selectable" % Content.DIFFICULTY_PERCENT[i])
	l.free()
	UIApi.preview_mode = ""
	UIApi.preview_local_id = 0
	UIApi.preview_lobby = {}


## §2 delivery metrics (tools/balance_metrics.gd): the sim clears hazards at the end of a
## wave without marking them dead; a cleared Kleber puddle must stop counting its life
## and the enemies near its old spot (it did, which inflated zone_life about 7x).
func test_delivery_metrics_drop_cleared_zones() -> void:
	var metrics = load("res://tools/balance_metrics.gd").new()
	var s := _sim(["klimakleber"])
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 40000:
		s.players[1].iframes = 10.0
		metrics.before_step(s)
		s.step(1.0 / 60.0)
		metrics.after_step(s, 1.0 / 60.0)
		guard += 1
	for i in 600:
		metrics.before_step(s)
		metrics.after_step(s, 1.0 / 60.0)
	var r: Dictionary = metrics.result(1).get("kleber", {})
	assert_true(int(r.get("zones", 0)) > 0, "the Klimakleber placed puddles")
	var per_zone := float(r.get("zone_life", 0.0)) / maxf(1, int(r.get("zones", 0)))
	assert_true(per_zone <= float(Content.WEAPONS["kleber"]["life"]) + 0.1,
		"a puddle lives at most its life time (%.1f s per puddle)" % per_zone)


## §9 (D-113): ground weapons land on the densest group in range, not on a lone closer target.
func test_ground_weapons_land_on_the_densest_group() -> void:
	var s := _sim(["klimakleber"])
	var p: Sim.SimPlayer = s.players[1]
	s.enemies.clear()
	s.hazards.clear()
	p.pos = Vector2(800, 560)
	var lone := s.spawn_enemy("hinterbaenkler", p.pos + Vector2(100, 0))
	var group := []
	for k in 4:
		group.append(s.spawn_enemy("hinterbaenkler", p.pos + Vector2(-220, 0) + Vector2.from_angle(TAU * k / 4.0) * 25.0))
	for e in [lone] + group:
		e.speed = 0.0
		e.behind = false
	s._build_grid()
	p.weapons = [{"id": "kleber", "tier": 1, "cd": 0.0, "angle": 0.0}]
	s._step_weapons(1.0 / 60.0)
	var puddles := s.hazards.filter(func(h): return h.owner == 1)
	assert_eq(puddles.size(), 1, "one puddle")
	assert_true(puddles[0].pos.distance_to(p.pos + Vector2(-220, 0)) < 20.0, "on the group, not on the closer lone enemy")


## §7 (D-121): melee weapons deal melee_vs_boss × damage to encounter units only.
func test_melee_hits_bosses_harder() -> void:
	var s := _sim(["stadtbild"])
	var p: Sim.SimPlayer = s.players[1]
	s._begin_wave(10)
	s._add_weapon(p, "doener", 1)
	s._add_weapon(p, "gendersternchen", 1)
	var melee_key := Sim._wkey(p.weapons[p.weapons.size() - 2])
	var ranged_key := Sim._wkey(p.weapons[p.weapons.size() - 1])
	var boss := s.spawn_enemy("geschichtslehrer", Arena.CENTER, 1.0)
	boss.encounter = "geschichtslehrer"
	boss.max_hp = 1.0e7
	boss.hp = boss.max_hp
	var mob := s.spawn_enemy("besorgter_buerger", Arena.CENTER + Vector2(200, 0))
	mob.behind = false
	mob.max_hp = 1.0e7
	mob.hp = mob.max_hp
	var k: float = Content.BALANCE["melee_vs_boss"]
	for pair in [[melee_key, boss, k], [ranged_key, boss, 1.0], [melee_key, mob, 1.0]]:
		var e: Sim.SimEnemy = pair[1]
		var before := e.hp
		s._damage_enemy(e, 10.0, p, false, Vector2.ZERO, 0.0, pair[0])
		assert_near(before - e.hp, 10.0 * pair[2], 0.001, "%s on %s" % [pair[0], e.tid])
