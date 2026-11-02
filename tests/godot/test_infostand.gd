extends TestCase
## Infostand stands per copy by tier 2 / 2 / 3 / 4, lifetime 10 / 10 / 15 / 20 s,
## no cap per player (D-100).


func _sim() -> Sim:
	var s := Sim.new()
	s.start_run({"seed": 3, "players": [{"id": 1, "name": "P1", "char": "stadtbild"}], "org": "gewerkschaft",
		"difficulty": 0, "skip_intro": true})
	s.enemies.clear()
	var p: Sim.SimPlayer = s.players[1]
	p.weapons.clear()
	p.pos = Vector2(950, 610)
	return s


func _stands(s: Sim) -> Array:
	return s.summons.filter(func(x): return x.alive and x.type == Content.idx(Content.SUMMON_ORDER, "infostand"))


func test_stands_per_tier() -> void:
	for tier in [1, 2, 3, 4]:
		var s := _sim()
		var p: Sim.SimPlayer = s.players[1]
		s._add_weapon(p, "infostand", tier)
		for i in 6:
			s._fire(p, p.weapons[0], Vector2.RIGHT)
		var stands := _stands(s)
		assert_eq(stands.size(), [2, 2, 3, 4][tier - 1], "tier %d keeps its stands" % tier)
		assert_near(stands[0].life, [10.0, 10.0, 15.0, 20.0][tier - 1], 0.001, "tier %d lifetime" % tier)


func test_every_copy_keeps_its_own_stands() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	for i in 3:
		s._add_weapon(p, "infostand", 4)
	for w in p.weapons:
		for i in 6:
			s._fire(p, w, Vector2.RIGHT)
	assert_eq(_stands(s).size(), 12, "three tier-IV copies, no cap per player")
