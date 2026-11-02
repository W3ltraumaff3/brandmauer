extends TestCase
## Balancing rules (docs/specs/balancing.md): level-up schedule and rarities,
## Brotato lifesteal, boss retry, boss phase 2, Umfrage from the start.


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


## §7: below enrage_at HP an elite enters phase 2.
func test_elite_phase_two() -> void:
	var s := _sim(["oma"])
	s._begin_wave(5)
	for i in 300:
		s.players[1].iframes = 10.0
		s.step(1.0 / 60.0)
	var elites := s.enemies.filter(func(e): return e.alive and e.elite and e.encounter != "")
	assert_false(elites.is_empty(), "elite spawned")
	var boss = elites[0]
	assert_false(boss.phase2, "phase 1 at full HP")
	boss.hp = boss.max_hp * 0.4
	s.players[1].iframes = 10.0
	s.step(1.0 / 60.0)
	assert_true(boss.phase2, "phase 2 below 50 %")


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
