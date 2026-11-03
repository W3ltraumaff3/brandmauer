extends TestCase
## One sound per action (audio.md §1.1 B1–B6, §6): real sim actions, their
## events through Audio.plan_events, and the Späti's local sounds.

const AREAS := ["audio", "sim", "ui"]  # ci-cd.md §2a

const AudioScript := preload("res://src/autoload/audio.gd")

var _state: Dictionary
var _now := 100000


func before_each() -> void:
	_state = AudioScript.new_state()
	(_state["rng"] as RandomNumberGenerator).seed = 3


func _sim(chars: Array, org := "gewerkschaft") -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": 7, "players": players, "org": org, "difficulty": 0, "skip_intro": true})
	s.take_events()
	return s


## Sound ids the local player hears for the events since the last call.
func _ids(s: Sim, local := 1) -> Array:
	_now += 1000
	return AudioScript.plan_events(s.take_events(), local, _state, _now).map(func(p): return p["id"])


func _to_shop(s: Sim) -> Array:
	var ids := []
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 20000:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(1.0 / 60.0)
		ids.append_array(_ids(s))
		guard += 1
	return ids


func test_a_kill_plays_one_kill_sound() -> void:
	var s := _sim(["oma"])
	var e := s.spawn_enemy("hinterbaenkler", Vector2(600, 400))
	s._damage_enemy(e, 99999.0, s.players[1])
	var ids := _ids(s)
	assert_eq(ids.count("kill"), 1, "kill once (B2): %s" % [ids])
	assert_eq(ids.count("hit"), 1, "your own hit is audible (B1)")


func test_an_elite_kill_plays_the_coin_burst_instead() -> void:
	var s := _sim(["oma"])
	var e := s.spawn_enemy("hinterbaenkler", Vector2(600, 400))
	e.elite = true
	s._damage_enemy(e, 99999.0, s.players[1])
	var ids := _ids(s)
	assert_eq(ids.count("kill_elite"), 1, "elite kill: %s" % [ids])
	assert_eq(ids.count("kill"), 0, "no plain kill on top")


func test_team_level_up_plays_once() -> void:
	var s := _sim(["oma"])
	s._add_xp(Content.xp_for_level(s.team_level) + 0.5)
	assert_eq(_ids(s).count("levelup"), 1, "levelup once (B3)")


func test_wave_end_and_start_play_once() -> void:
	var s := _sim(["oma"])
	var ids := _to_shop(s)
	assert_eq(ids.count("wave_end"), 1, "wave_end once (B3): %d" % ids.count("wave_end"))
	for p in s.players.values():
		s.request(p.id, "ready", true)
	s.step(1.0 / 60.0)
	assert_eq(_ids(s).count("wave_start"), 1, "wave_start once (B3)")


func test_down_and_revive_play_once() -> void:
	var s := _sim(["oma", "antifa"])
	var a: Sim.SimPlayer = s.players[1]
	var b: Sim.SimPlayer = s.players[2]
	a.stats["dodge"] = 0.0
	s.damage_player(a, 9999.0)
	var ids := _ids(s, 2)
	assert_eq(ids.count("down"), 1, "down once (B3): %s" % [ids])
	assert_eq(ids.count("hurt"), 1, "the teammate's hurt is audible, quieter")
	var revived := []
	for i in 200:
		b.iframes = 10.0
		b.pos = a.pos
		s.step(1.0 / 60.0)
		revived.append_array(_ids(s, 2))
	assert_eq(a.state, 0, "revived")
	assert_eq(revived.count("revive"), 1, "revive once (B3)")


func test_wende_and_streik_play_once() -> void:
	var s := _sim(["oma"])
	var e := s.spawn_enemy("hinterbaenkler", Vector2(600, 400))
	s._wende(e)
	assert_eq(_ids(s).count("wende"), 1, "wende once (B3)")
	s.streik_available = true
	assert_true(s.request(1, "streik"), "streik request")
	assert_eq(_ids(s).count("streik"), 1, "streik once (B3)")


func test_spaeti_requests_leave_the_sound_to_the_ui() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	s.take_events()
	var p: Sim.SimPlayer = s.players[1]
	p.pfand = 10000
	p.offers[0] = {"kind": "item", "id": "solibutton", "tier": 1, "price": 10, "sold": false, "locked": false}
	assert_true(s.request(1, "buy", 0), "buy")
	var ev := s.take_events()
	_now += 1000
	var mine: Array = AudioScript.plan_events(ev, 1, _state, _now).map(func(x): return x["id"])
	assert_true(mine.filter(func(id): return str(id).begins_with("buy")).is_empty(), "no buy from the sim (B4): %s" % [mine])
	s.vertrag["options"] = ["digitalpakt", "tempolimit", "sanktionen"]
	s.vertrag["votes"] = {}
	assert_true(s.request(1, "vote", 0), "vote")
	ev = s.take_events()
	_now += 1000
	assert_eq(AudioScript.plan_events(ev, 1, _state, _now).map(func(x): return x["id"]).count("vote"), 0,
		"your own vote: only the UI's stamp (B5)")
	_now += 1000
	assert_eq(AudioScript.plan_events(ev, 2, _state, _now).map(func(x): return x["id"]).count("vote"), 1,
		"a teammate hears that you voted")


func test_combine_plays_only_for_the_player_who_combined() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	s.take_events()
	var p: Sim.SimPlayer = s.players[1]
	p.pfand = 10000
	p.offers[0] = {"kind": "weapon", "id": p.weapons[0]["id"], "tier": int(p.weapons[0]["tier"]), "price": 10,
		"sold": false, "locked": false}
	assert_true(s.request(1, "buy", 0), "buy a twin: combines")
	var ev := s.take_events()
	_now += 1000
	var mine: Array = AudioScript.plan_events(ev, 1, _state, _now).map(func(x): return x["id"])
	_now += 1000
	var theirs: Array = AudioScript.plan_events(ev, 2, _state, _now).map(func(x): return x["id"])
	assert_eq(mine.count("combine_2"), 1, "combine_2 for the buyer: %s" % [mine])
	assert_eq(mine.count("levelup"), 0, "no level-up fanfare on a combine (B6)")
	assert_true(theirs.is_empty(), "teammates hear nothing: %s" % [theirs])


func test_events_carry_the_player_who_caused_them() -> void:
	var s := _sim(["oma", "antifa"])
	var e := s.spawn_enemy("hinterbaenkler", Vector2(600, 400))
	s._damage_enemy(e, 1.0, s.players[2], true)
	s._damage_enemy(e, 99999.0, s.players[2])
	var dmg := []
	var kill := []
	for ev in s.take_events():
		if ev[0] == "dmg":
			dmg.append(ev)
		elif ev[0] == "kill":
			kill.append(ev)
	assert_eq(int(dmg[0][5]), 2, "dmg carries the attacker")
	assert_eq(int(kill[0][3]), 2, "kill carries the killer")
	# both players shoot: every shot sound names its shooter
	var shooters := {}
	for i in 600:
		for p in s.players.values():
			p.iframes = 10.0
		if i % 30 == 0:
			for p in s.players.values():
				s.spawn_enemy("hinterbaenkler", p.pos + Vector2(120, 0))
		s.step(1.0 / 60.0)
		for ev in s.take_events():
			if ev[0] == "sfx" and str(ev[1]) in ["shoot", "melee"]:
				assert_eq(ev.size(), 4, "sfx %s has a peer" % ev[1])
				shooters[int(ev[3])] = true
	assert_true(shooters.has(1) and shooters.has(2), "both shooters named: %s" % [shooters.keys()])


func test_spaeti_ka_ching_follows_tier_and_rarity() -> void:
	assert_eq(SpaetiPanel.buy_sfx({"kind": "weapon", "id": "tofu", "tier": 2}), "buy_2")
	assert_eq(SpaetiPanel.buy_sfx({"kind": "weapon", "id": "tofu", "tier": 4}), "buy_4")
	assert_eq(SpaetiPanel.buy_sfx({"kind": "item", "id": "hausbesetzung"}), "buy_4", "red item")
	assert_eq(SpaetiPanel.buy_sfx({"kind": "item", "id": "x", "rarity": 1}), "buy_1")


func test_spaeti_plays_buy_and_sell_locally() -> void:
	const Preview := preload("res://tools/ui_preview.gd")
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	var meta: Dictionary = Preview._rarity_meta()
	var sp := SpaetiPanel.new()
	sp.preview_meta = meta
	(Engine.get_main_loop() as SceneTree).root.add_child(sp)
	UIApi.sfx_log = []
	var me: Dictionary = meta["players"][1]
	var i := -1
	for k in (me["offers"] as Array).size():
		if not me["offers"][k].get("sold", false) and SpaetiPanel.buy_block_reason(me["offers"][k], me) == "":
			i = k
			break
	assert_true(i >= 0, "a buyable preview offer")
	sp._on_buy(i)
	var w: Dictionary = me["weapons"][0]
	sp._on_sell(0, str(w["id"]), int(w["tier"]))
	var log: Array = UIApi.sfx_log
	UIApi.sfx_log = null
	sp.free()
	UIApi.preview_mode = ""
	UIApi.preview_local_id = 0
	assert_eq(log, [SpaetiPanel.buy_sfx(me["offers"][i]), "sell"], "one ka-ching by tier, then sell")
