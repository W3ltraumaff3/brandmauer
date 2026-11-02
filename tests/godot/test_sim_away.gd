extends TestCase
## Sim player state 3 "away": a co-op client lost its connection and may come
## back within the grace period (networking.md §7.4, architecture.md §3).

const AREAS := ["sim", "net"]  # ci-cd.md §2a

const TICK := 1.0 / 60.0


func _sim(chars: Array, skip_intro := true) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": 3, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": skip_intro})
	return s


func _has_event(s: Sim, ev: Array) -> bool:
	for e in s.take_events():
		if e == ev:
			return true
	return false


func _to_shop(s: Sim) -> void:
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 20000:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(TICK)
		guard += 1


func test_away_and_back_events_and_meta() -> void:
	var s := _sim(["oma", "antifa"])
	s.take_events()
	s.set_away(2, true)
	assert_eq(s.players[2].state, 3, "away")
	assert_true(_has_event(s, ["away", 2]), "away event")
	var m := s.build_meta()
	assert_true(bool(m["players"][2]["away"]), "meta away flag")
	assert_false(bool(m["players"][2]["alive"]), "away is not alive")
	assert_eq(int(m["num_players"]), 2, "still counts for scaling")
	var vs := ViewState.new()
	s.build_view(vs)
	assert_eq(int(vs.find_player(2)["state"]), 3, "view state 3")
	s.set_away(2, true)
	assert_false(_has_event(s, ["away", 2]), "no duplicate event")
	s.set_away(2, false)
	assert_eq(s.players[2].state, 0, "back alive")
	assert_true(_has_event(s, ["back", 2]), "back event")


func test_away_is_invulnerable_frozen_and_not_targeted() -> void:
	var s := _sim(["oma", "antifa"])
	var a: Sim.SimPlayer = s.players[1]
	var b: Sim.SimPlayer = s.players[2]
	b.pos = Vector2(400, 500)
	a.pos = Vector2(1200, 500)
	s.set_away(2, true)
	var hp := b.hp
	s.damage_player(b, 9999.0)
	assert_eq(b.hp, hp, "no damage while away")
	assert_eq(b.state, 3, "still away")
	assert_eq(s._nearest_player(Vector2(390, 500), true), a, "enemies target the present player")
	s.set_input(2, Vector2.RIGHT, 5)
	for i in 30:
		a.iframes = 10.0
		s.step(TICK)
	assert_eq(b.pos, Vector2(400, 500), "frozen")
	assert_false(s.request(2, "ultimate"), "no requests while away")


func test_away_never_causes_game_over() -> void:
	var s := _sim(["oma", "antifa"])
	var a: Sim.SimPlayer = s.players[1]
	a.stats["dodge"] = 0.0
	s.set_away(2, true)
	assert_eq(s.phase, Sim.Phase.WAVE, "one away, one alive: run goes on")
	s.damage_player(a, 9999.0)
	assert_eq(a.state, 1, "present player downed")
	assert_eq(s.phase, Sim.Phase.WAVE, "no game over while someone is away")
	assert_true(s.waiting_for_away(), "world waits for the away player")
	var t := s.wave_time
	s.step(1.0)
	assert_eq(s.wave_time, t, "world frozen")
	s.set_away(2, false)
	assert_false(s.waiting_for_away(), "back: world runs")
	s.set_away(2, true)
	s.remove_player(2)
	assert_eq(s.phase, Sim.Phase.OVER, "removed after the grace period: game over")


func test_everyone_away_freezes_the_world() -> void:
	var s := _sim(["oma"])
	s.set_away(1, true)
	assert_eq(s.phase, Sim.Phase.WAVE, "no game over")
	var t := s.wave_time
	for i in 60:
		s.step(TICK)
	assert_eq(s.wave_time, t, "frozen while nobody is there")
	s.set_away(1, false)
	s.step(TICK)
	assert_true(s.wave_time > t, "runs again")


func test_away_does_not_block_ready() -> void:
	var s := _sim(["oma", "antifa", "lastenrad"])
	_to_shop(s)
	assert_eq(s.phase, Sim.Phase.SHOP)
	s.set_away(3, true)
	s.request(1, "ready", true)
	assert_eq(s.phase, Sim.Phase.SHOP, "waits for player 2")
	assert_false(s.request(3, "ready", true), "away player can't ready")
	s.request(2, "ready", true)
	assert_eq(s.phase, Sim.Phase.WAVE, "away player doesn't block")
	assert_eq(s.wave, 2)
	assert_eq(s.players[3].state, 3, "still away in the new wave")
	s.set_away(3, false)
	assert_eq(s.players[3].state, 0, "comes back alive")


func test_going_away_completes_ready() -> void:
	var s := _sim(["oma", "antifa"])
	_to_shop(s)
	s.request(1, "ready", true)
	s.set_away(2, true)
	assert_eq(s.phase, Sim.Phase.WAVE, "last unready player dropping starts the wave")


func test_away_does_not_block_boss_intro() -> void:
	var s := Sim.new()
	s.start_run({"seed": 1, "players": [{"id": 1, "char": "oma"}, {"id": 2, "char": "antifa"}], "org": "omas"})
	s._begin_wave(5)
	assert_true(s.intro_wait, "boss card pauses")
	s.request(1, "continue_intro")
	assert_true(s.intro_wait, "waits for player 2")
	s.set_away(2, true)
	assert_false(s.intro_wait, "away player doesn't block the intro")


func test_downed_player_stays_downed_after_coming_back() -> void:
	var s := _sim(["oma", "antifa"])
	var b: Sim.SimPlayer = s.players[2]
	b.stats["dodge"] = 0.0
	s.damage_player(b, 9999.0)
	assert_eq(b.state, 1, "downed")
	s.set_away(2, true)
	s.set_away(2, false)
	assert_eq(b.state, 1, "still downed")
