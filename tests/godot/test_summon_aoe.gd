extends TestCase
## Area damage for the summon weapons (GDD §11, D-115): Infostand leaflets bounce
## ("Flugblatt wird weitergereicht"), the Weißer Overall splashes ("Blockade-Knäuel").

const DT := 1.0 / 60.0


func _sim() -> Sim:
	var s := Sim.new()
	s.start_run({"seed": 7, "players": [{"id": 1, "name": "P1", "char": "oma"}], "org": "gewerkschaft",
		"difficulty": 0, "skip_intro": true})
	s.enemies.clear()
	s.projectiles.clear()
	s.summons.clear()
	s._spawn_acc = -1000.0
	var p: Sim.SimPlayer = s.players[1]
	p.weapons.clear()
	p.pos = Vector2(400, 610)
	p.stats["crit"] = -10.0   # no crits: damage values stay exact
	return s


func _enemy(s: Sim, pos: Vector2) -> Sim.SimEnemy:
	var e := s.spawn_enemy("besorgter_buerger", pos)
	e.behind = false
	e.speed = 0.0
	e.max_hp = 100000.0
	e.hp = e.max_hp
	return e


func _hits(enemies: Array) -> Array:
	return enemies.map(func(e): return snappedf(e.max_hp - e.hp, 0.01))


## One leaflet from a fresh stand of the given tier at enemies on a line 100 px apart.
func _one_leaflet(tier: int, positions: Array) -> Array:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s._add_weapon(p, "infostand", tier)
	var es := []
	for x in positions:
		es.append(_enemy(s, p.pos + Vector2(x, 0)))
	s._fire(p, p.weapons[0], Vector2.RIGHT)
	var stand: Sim.SimSummon = s.summons[0]
	stand.cd = 0.0
	s._build_grid()
	s._step_summons(DT)          # the stand fires one leaflet
	stand.cd = 1000.0            # and no more
	for i in 120:
		for e in es:
			e.knock = Vector2.ZERO
		s._build_grid()
		s._step_projectiles(DT)
		s._cleanup()
	assert_true(s.projectiles.is_empty(), "tier %d: the leaflet ended" % tier)
	return _hits(es)


func test_leaflet_bounces_by_tier() -> void:
	var line := [150.0, 250.0, 350.0, 450.0]
	var t1 := _one_leaflet(1, line)
	assert_eq(t1.filter(func(d): return d > 0.0).size(), 2, "tier I hits 2 enemies: %s" % [t1])
	var t3 := _one_leaflet(3, line)
	assert_eq(t3.filter(func(d): return d > 0.0).size(), 3, "tier III hits 3 enemies: %s" % [t3])
	assert_near(t3[1], t3[0] * 0.8, 0.05, "−20 % per jump")
	assert_near(t3[2], t3[0] * 0.64, 0.05, "−20 % again")


func test_leaflet_never_hits_the_same_enemy_twice() -> void:
	# two enemies, tier III (2 bounces): A -> B, then nobody new in reach -> it ends
	var d := _one_leaflet(3, [150.0, 230.0])
	assert_true(d[0] > 0.0 and d[1] > 0.0, "both hit: %s" % [d])
	assert_near(d[1], d[0] * 0.8, 0.05, "B once, after one jump")
	# A was hit exactly once: its damage is one leaflet's, not more
	var single := _one_leaflet(3, [150.0])
	assert_near(d[0], single[0], 0.05, "A once")


func test_leaflet_ends_without_an_enemy_in_reach() -> void:
	# the second enemy is 300 px on, beyond the 140 px bounce range
	var d := _one_leaflet(1, [150.0, 450.0])
	assert_true(d[0] > 0.0, "first hit")
	assert_eq(d[1], 0.0, "no jump beyond bounce_range")


func test_wurfmaschine_adds_no_pierce_to_leaflets() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	p.flags["ranged_build"] = true
	s._add_weapon(p, "infostand", 1)
	_enemy(s, p.pos + Vector2(150, 0))
	s._fire(p, p.weapons[0], Vector2.RIGHT)
	s.summons[0].cd = 0.0
	s._build_grid()
	s._step_summons(DT)
	assert_eq(s.projectiles.size(), 1, "one leaflet")
	assert_eq(s.projectiles[0].pierce, 0, "the Infostand isn't a ranged weapon")


func test_overall_splashes_on_arrival() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s._add_weapon(p, "weisser_overall", 1)
	var target := _enemy(s, p.pos + Vector2(200, 0))
	var near := _enemy(s, target.pos + Vector2(0, 40))     # within 55 px of the impact
	var far := _enemy(s, target.pos + Vector2(0, 130))     # well outside
	var o := Sim.SimSummon.new()
	o.type = Content.idx(Content.SUMMON_ORDER, "overall")
	o.pos = p.pos
	o.owner = 1
	o.life = 4.0
	o.dmg = 10.0
	o.cd = float(target.id)
	s.summons.append(o)
	for i in 120:
		for e in [target, near, far]:
			e.knock = Vector2.ZERO
			e.pos = e.pos   # immobile
		s._build_grid()
		s._step_summons(DT)
		s._cleanup()
		if s.summons.is_empty():
			break
	assert_true(s.summons.is_empty(), "the activist arrived and left")
	assert_near(target.max_hp - target.hp, 10.0, 0.01, "target: full damage")
	assert_near(near.max_hp - near.hp, 5.0, 0.01, "neighbour within 55 px: half")
	assert_near(far.max_hp - far.hp, 0.0, 0.001, "nothing outside")


## D-117: below its stand cap a copy places the next stand after refill_cd, then the full cooldown.
func test_infostand_refills_quickly_below_the_cap() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s._add_weapon(p, "infostand", 1)
	var w: Dictionary = p.weapons[0]
	var def: Dictionary = Content.WEAPONS["infostand"]
	w["cd"] = def["cd"]
	s._fire(p, w, Vector2.RIGHT)
	assert_near(w["cd"], def["refill_cd"], 0.001, "one of two stands up: the second comes fast")
	w["cd"] = def["cd"]
	s._fire(p, w, Vector2.RIGHT)
	assert_near(w["cd"], def["cd"], 0.001, "cap reached: the normal cooldown")


## Wave-1 check (D-117): a tier-I stand with no stats kills a wave-1 Besorgter Bürger
## with at most two leaflets (one leaflet plus its bounce counts as one).
func test_tier1_stand_kills_a_wave1_enemy_in_two_leaflets() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s._add_weapon(p, "infostand", 1)
	var e := s.spawn_enemy("besorgter_buerger", p.pos + Vector2(150, 0))
	e.behind = false
	e.speed = 0.0
	s._fire(p, p.weapons[0], Vector2.RIGHT)
	var stand: Sim.SimSummon = s.summons[0]
	var shots := 0
	for i in 600:
		if not e.alive:
			break
		if stand.cd <= 0.0:
			shots += 1
		e.knock = Vector2.ZERO
		s._build_grid()
		s._step_summons(DT)
		s._step_projectiles(DT)
		s._cleanup()
	assert_false(e.alive, "killed")
	assert_true(shots <= 2, "in %d leaflets (wave-1 HP %.0f)" % [shots, e.max_hp])
