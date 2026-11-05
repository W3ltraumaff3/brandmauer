extends TestCase
## Run save and Wellen-Wiederholung (GDD §17 "Weiterspielen", balancing.md §8a,
## architecture.md "Run checkpoints", D-162/D-163).

const AREAS := ["sim", "save", "net", "ui"]  # ci-cd.md §2a

var game: Node
var save: Node


func before_each() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	game = root.get_node_or_null("Game")
	save = root.get_node_or_null("Save")
	if save:
		save.clear_run()


func after_each() -> void:
	if game:
		game.quit_to_menu()
	if save:
		save.clear_run()


func _sim(chars: Array, extra := {}) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var cfg := {"seed": 11, "players": players, "org": "gewerkschaft", "difficulty": 1, "skip_intro": true}
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


func _wipe(s: Sim) -> void:
	for p in s.players.values():
		if p.state == 0:
			p.stats["dodge"] = 0.0
			p.iframes = 0.0
			p.second_round_used = true
			s.damage_player(p, 1.0e6)
	for i in 5:
		s.step(1.0 / 60.0)


## Like the disk: binary without objects.
func _through_disk(cp: Dictionary) -> Dictionary:
	return bytes_to_var(var_to_bytes(cp))


func _cfg_for(cp: Dictionary, lobby: Dictionary) -> Dictionary:
	var mapping: Dictionary = GameScript.resume_mapping(lobby, cp)
	var cfg: Dictionary = (cp["config"] as Dictionary).duplicate(true)
	var players := []
	for id in lobby:
		players.append({"id": int(id), "name": lobby[id]["name"], "char": lobby[id]["char"], "from": mapping[int(id)]})
	cfg["players"] = players
	return cfg


const GameScript := preload("res://src/autoload/game.gd")


func test_wave_checkpoint_resumes_at_that_wave_start() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	var p1: Sim.SimPlayer = s.players[1]
	p1.pfand = 321
	p1.items.append("bierdeckel" if Content.ITEMS.has("bierdeckel") else Content.ITEM_ORDER[0])
	p1.levelup_stats["damage"] = 7.0
	s.kasse = 40
	s.wall[3] = false
	s.request(1, "ready", true)
	s.request(2, "ready", true)
	assert_eq(s.wave, 2, "wave 2 started")
	var cp := _through_disk(s.checkpoint)
	assert_eq(cp["resume"], "wave")
	assert_eq(int(cp["next_wave"]), 2)
	var r := Sim.new()
	r.resume_run(_cfg_for(cp, {1: {"name": "P1", "char": "oma"}, 2: {"name": "P2", "char": "antifa"}}), cp)
	assert_eq(r.phase, Sim.Phase.WAVE, "playing")
	assert_eq(r.wave, 2, "the saved wave")
	var q: Sim.SimPlayer = r.players[1]
	assert_eq(q.pfand, 321, "Pfand")
	assert_eq(Array(q.items), Array(p1.items), "items")
	assert_eq(q.weapons.size(), p1.weapons.size(), "weapons")
	assert_near(float(q.levelup_stats.get("damage", 0.0)), 7.0, 0.001, "level-ups")
	assert_eq(r.kasse, 40, "Kasse")
	assert_false(r.wall[3], "Brandmauer hole stays")
	assert_eq(r.difficulty, 1, "Umfrage")
	assert_eq(q.hp, q.stats["max_hp"], "full HP")
	assert_eq(r.checkpoint_seq, 1, "a fresh checkpoint for the new ids")


func test_shop_checkpoint_resumes_in_the_spaeti_as_it_was() -> void:
	var s := _sim(["lastenrad"])
	_to_shop(s)
	s.players[1].pfand = 500
	s.request(1, "reroll")
	var offers: Array = s.players[1].offers.duplicate(true)
	var cp := _through_disk(s.make_checkpoint("shop"))
	var r := Sim.new()
	r.resume_run(_cfg_for(cp, {1: {"name": "P1", "char": "lastenrad"}}), cp)
	assert_eq(r.phase, Sim.Phase.SHOP, "in the Späti")
	assert_eq(r.wave, 1, "after wave 1")
	assert_eq(r.players[1].offers, offers, "the same offers, no free reroll")
	assert_eq(r.players[1].pfand, s.players[1].pfand, "Pfand after the reroll")
	assert_false(r.players[1].ready, "nobody ready")
	r.request(1, "ready", true)
	assert_eq(r.wave, 2, "ready starts wave 2")


func test_resume_mapping_by_character_and_name() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	var cp := s.make_checkpoint("shop")
	var m: Dictionary = GameScript.resume_mapping({1: {"name": "P1", "char": "oma"}, 5: {"name": "X", "char": "antifa"}}, cp)
	assert_eq(m, {1: 1, 5: 2}, "same character")
	m = GameScript.resume_mapping({1: {"name": "P2", "char": "antifa"}, 5: {"name": "P1", "char": "oma"}}, cp)
	assert_eq(m, {1: 2, 5: 1}, "character and name")
	m = GameScript.resume_mapping({1: {"name": "Z", "char": "stadtbild"}}, cp)
	assert_eq(m.size(), 1, "any free character when none fits")
	assert_eq(GameScript.resume_mapping({1: {}, 2: {}, 3: {}}, cp), {}, "more players than saved characters")
	assert_eq(GameScript.resume_mapping({}, cp), {}, "empty lobby")
	# Only one of the two continues: the other character is left out, votes follow the new ids.
	s.vertrag["votes"] = {1: 0, 2: 1}
	cp = s.make_checkpoint("shop")
	var r := Sim.new()
	r.resume_run(_cfg_for(cp, {9: {"name": "P2", "char": "antifa"}}), cp)
	assert_eq(r.players.keys(), [9], "only the taken character")
	assert_eq(r.players[9].char_id, "antifa")
	assert_eq(r.vertrag["votes"], {9: 1}, "vote remapped, the left-out one dropped")


## D-163: any wave starts over from its start; the lost attempt brings nothing.
func test_wave_retry_restores_the_wave_start() -> void:
	for on in [true, false]:
		var s := _sim(["oma", "antifa"], {"wave_retry": on})
		_to_shop(s)
		s.request(1, "ready", true)
		s.request(2, "ready", true)
		assert_eq(s.wave, 2)
		var pfand: int = s.players[1].pfand
		var level := s.team_level
		s.players[1].pfand += 999
		s._add_xp(5000.0)
		s.wall[0] = false
		_wipe(s)
		if not on:
			assert_eq(s.phase, Sim.Phase.OVER, "without the option the run ends")
			continue
		assert_eq(s.phase, Sim.Phase.WAVE, "still playing")
		assert_eq(s.wave, 2, "same wave")
		assert_eq(s.retries, 1, "counted")
		assert_eq(s.players[1].pfand, pfand, "Pfand as at the wave start")
		assert_eq(s.team_level, level, "Zusammenhalt as at the wave start")
		for p in s.players.values():
			assert_eq(p.state, 0, "everyone back")
			assert_eq(p.hp, p.stats["max_hp"], "full HP")
		# Again: the checkpoint itself was not changed by the first attempt.
		s.players[1].pfand += 50
		_wipe(s)
		assert_eq(s.retries, 2, "unlimited")
		assert_eq(s.players[1].pfand, pfand, "still the wave-start Pfand")
		assert_eq(int(s.checkpoint["sim"]["retries"]), 2, "the run save knows the retries")


func test_wave_retry_keeps_who_left_gone() -> void:
	var s := _sim(["oma", "antifa"], {"wave_retry": true})
	_to_shop(s)
	s.request(1, "ready", true)
	s.request(2, "ready", true)
	s.remove_player(2)
	_wipe(s)
	assert_eq(s.phase, Sim.Phase.WAVE, "retry")
	assert_eq(s.players[1].state, 0, "back")
	assert_eq(s.players[2].state, 2, "who left stays gone")


## D-165: Boss-Wiederholung restarts the boss wave from its beginning too: same
## encounter, but the lost attempt's bounty is gone.
func test_boss_retry_restarts_at_the_wave_start() -> void:
	var s := _sim(["oma"], {"boss_retry": true})
	s.wave = 4
	s._start_wave(5)
	var enc := s.encounter
	assert_true(enc != "", "wave 5 has an elite")
	var pfand: int = s.players[1].pfand
	var level := s.team_level
	s.players[1].pfand += 77
	s._add_xp(5000.0)
	_wipe(s)
	assert_eq(s.phase, Sim.Phase.WAVE, "retry")
	assert_eq(s.wave, 5, "same wave")
	assert_eq(s.encounter, enc, "same encounter")
	assert_eq(s.retries, 1)
	assert_eq(s.players[1].pfand, pfand, "no bounty from the lost attempt")
	assert_eq(s.team_level, level, "no XP from the lost attempt")
	# A regular wave never retries with Boss-Wiederholung alone.
	_wipe_regular(s)


func _wipe_regular(s: Sim) -> void:
	s.wave = 5
	s._start_wave(6)
	_wipe(s)
	assert_eq(s.phase, Sim.Phase.OVER, "no retry in a regular wave")


## Integration: Game writes the run save, keeps it on quitting, continues it, and
## deletes it once the run is decided or given up.
func test_game_saves_continues_and_clears_the_run() -> void:
	if game == null or save == null:
		fail("Game/Save autoloads missing")
		return
	game.open_solo()
	game.get_node("/root/Net").set_char("oma")
	game.start_run()
	var cp: Dictionary = save.run_save()
	assert_eq(cp.get("resume", ""), "wave", "saved at the start of wave 1")
	for i in 60 * 31:
		game.sim.players[1].iframes = 10.0
		game._physics_process(1.0 / 60.0)
	assert_eq(int(game.sim.phase), Sim.Phase.SHOP, "Späti after wave 1")
	assert_eq(save.run_save().get("resume", ""), "shop", "saved when the Späti opens")
	game.sim.players[1].pfand = 400
	game.request("reroll")
	var offers: Array = game.sim.players[1].offers.duplicate(true)
	game.quit_to_menu()
	assert_false(game.is_running())
	var info: Dictionary = game.continue_info()
	assert_eq(int(info.get("wave", 0)), 2, "summary: before wave 2")
	assert_true(game.open_continue(), "continue")
	assert_true(game.is_running(), "back in the run")
	assert_eq(int(game.sim.phase), Sim.Phase.SHOP, "in the Späti")
	assert_eq(game.sim.players[1].offers, offers, "the Späti as it was left")
	assert_eq(game.sim.players[1].char_id, "oma")
	game.request("ready", true)
	assert_eq(game.sim.wave, 2, "wave 2")
	var p: Sim.SimPlayer = game.sim.players[1]
	p.stats["dodge"] = 0.0
	p.iframes = 0.0
	p.second_round_used = true
	game.sim.damage_player(p, 1.0e6)
	game._physics_process(1.0 / 60.0)
	assert_eq(int(game.sim.phase), Sim.Phase.OVER, "lost")
	assert_true(save.run_save().is_empty(), "a decided run leaves no save")
	game.quit_to_menu()
	assert_true(save.run_save().is_empty(), "quitting afterwards doesn't bring it back")


func test_give_up_deletes_the_run_save() -> void:
	if game == null or save == null:
		return
	game.open_solo()
	game.start_run()
	assert_false(save.run_save().is_empty(), "saved")
	game.give_up()
	assert_false(game.is_running())
	assert_true(save.run_save().is_empty(), "given up: gone")
	assert_false(game.open_continue(), "nothing to continue")


func test_a_save_of_another_format_is_ignored() -> void:
	if save == null:
		return
	save.write_run({"format": Sim.CHECKPOINT_FORMAT + 1, "players": [{"id": 1, "char_id": "oma"}]})
	assert_true(save.run_save().is_empty(), "other format")
	var s := _sim(["oma"])
	save.write_run(s.checkpoint)
	assert_false(save.run_save().is_empty(), "this format")
