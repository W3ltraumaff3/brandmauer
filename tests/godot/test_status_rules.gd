extends TestCase
## Status immunity (D-087), damage-over-time attribution (D-088) and the
## Brandmauer-Ziegel tick rule (D-089).


func _sim(chars: Array, seed := 7) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	s.enemies.clear()
	for p in s.players.values():
		p.weapons.clear()
		p.pos = Vector2(950, 610)
	return s


func _enemy(s: Sim, tid: String, pos: Vector2) -> Sim.SimEnemy:
	var e := s.spawn_enemy(tid, pos)
	e.behind = false
	e.speed = 0.0
	e.max_hp = 100000.0
	e.hp = e.max_hp
	s._build_grid()   # direct _fire/_activate_ult calls query the grid
	return e


func _run(s: Sim, frames: int) -> void:
	for i in frames:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(1.0 / 60.0)


## GDD §13: the Reichsbürger ignores every stun, whichever weapon or ultimate
## causes it; a normal enemy next to him is stunned (proves the path ran).
func test_status_immune_enemy_is_never_stunned() -> void:
	for wid in ["trillerpfeife", "bierkiste"]:
		var s := _sim(["stadtbild"])
		var p: Sim.SimPlayer = s.players[1]
		var rb := _enemy(s, "reichsbuerger", p.pos + Vector2(60, 0))
		var bb := _enemy(s, "besorgter_buerger", p.pos + Vector2(-60, 0))
		s._add_weapon(p, wid, 1)
		s._fire(p, p.weapons[0], Vector2.RIGHT)
		assert_true(bb.stun_t > 0.0, wid + " stuns a normal enemy")
		assert_eq(rb.stun_t, 0.0, wid + " must not stun the Reichsbürger")
	# Flashmob (Stadtbild)
	var s := _sim(["stadtbild"])
	var p: Sim.SimPlayer = s.players[1]
	var rb := _enemy(s, "reichsbuerger", p.pos + Vector2(80, 0))
	var bb := _enemy(s, "besorgter_buerger", p.pos + Vector2(-80, 0))
	s._activate_ult(p)
	assert_true(bb.stun_t > 0.0, "Flashmob stuns a normal enemy")
	assert_eq(rb.stun_t, 0.0, "Flashmob must not stun the Reichsbürger")
	assert_true(rb.hp < rb.max_hp, "Flashmob still damages him (D-079)")
	# Fragen Sie mal uns (Töchter): an immune suit is not stunned, but takes double damage.
	var t := _sim(["toechter"])
	var q: Sim.SimPlayer = t.players[1]
	var suit := _enemy(t, "lobbyist", q.pos + Vector2(200, 0))
	var immune_suit := _enemy(t, "lobbyist", q.pos + Vector2(-200, 0))
	immune_suit.def = immune_suit.def.duplicate()
	immune_suit.def["immune"] = true
	t._activate_ult(q)
	assert_true(suit.stun_t > 0.0, "Fragen Sie mal uns stuns suits")
	assert_eq(immune_suit.stun_t, 0.0, "Fragen Sie mal uns must not stun an immune suit")
	assert_true(immune_suit.vuln_t > 0.0, "double damage is not a status effect")


## Distance a lone enemy walks in 10 frames under a global effect.
func _walked(tid: String, effect: String) -> float:
	var s := _sim(["buergergeld"])
	var p: Sim.SimPlayer = s.players[1]
	var e := _enemy(s, tid, p.pos + Vector2(400, 0))
	e.speed = 60.0
	if effect == "antrag_gestellt":
		s._activate_ult(p)
	elif effect == "streik":
		s.streik_active = 5.0
	var start := e.pos
	_run(s, 10)
	return e.pos.distance_to(start)


## Antrag gestellt (global slow) and the Streik freeze don't hold the Reichsbürger.
func test_status_immune_enemy_ignores_global_slow_and_freeze() -> void:
	var free_rb := _walked("reichsbuerger", "")
	var free_bb := _walked("besorgter_buerger", "")
	assert_true(free_rb > 5.0, "the Reichsbürger walks (%.1f)" % free_rb)
	assert_true(_walked("besorgter_buerger", "antrag_gestellt") < free_bb * 0.6, "Antrag gestellt slows a normal enemy")
	assert_true(_walked("besorgter_buerger", "streik") < 0.5, "Streik freezes a normal enemy")
	assert_near(_walked("reichsbuerger", "antrag_gestellt"), free_rb, 0.5, "Antrag gestellt must not slow the Reichsbürger")
	assert_near(_walked("reichsbuerger", "streik"), free_rb, 0.5, "Streik must not freeze the Reichsbürger")


## D-088: Tofu poison ticking inside another player's Kleber stays credited to
## the Tofu thrower; the Kleber's owner gets exactly the zone damage.
func test_poison_attribution_survives_a_zone() -> void:
	var s := _sim(["oma", "antifa"])
	var p1: Sim.SimPlayer = s.players[1]
	var p2: Sim.SimPlayer = s.players[2]
	var e := _enemy(s, "besorgter_buerger", Vector2(600, 400))
	s._add_weapon(p1, "tofu", 1)
	var tofu_key := Sim._wkey(p1.weapons[0])
	s._add_weapon(p2, "kleber", 1)
	var kleber_key := Sim._wkey(p2.weapons[0])
	p1.weapons.clear()
	p2.weapons.clear()
	var pr := Sim.SimProj.new()
	pr.weapon = "tofu"
	pr.source = tofu_key
	pr.owner = p1.id
	pr.dmg = 0.0
	pr.pos = e.pos
	s._proj_hit_enemies(pr)
	var poison_dps := e.poison
	assert_true(poison_dps > 0.0, "Tofu poisons")
	var h := Sim.SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "kleber")
	h.pos = e.pos
	h.radius = 60.0
	h.life = 10.0
	h.max_life = 10.0
	h.dps = 4.0
	h.owner = p2.id
	h.data = {"src": kleber_key}
	s.hazards.append(h)
	_run(s, 60)
	var tofu_dmg: float = p1.dmg_total.get(tofu_key, 0.0)
	var kleber_dmg: float = p2.dmg_total.get(kleber_key, 0.0)
	assert_near(tofu_dmg, poison_dps * 1.0, poison_dps * 0.1, "poison credited to the Tofu thrower")
	assert_near(kleber_dmg, 4.0, 0.4, "the Kleber owner gets only the zone damage")
	assert_eq(e.poison_src, p1.id, "the zone doesn't take over the poison")


## Damage per second an enemy takes standing in `walls` Brandmauer-Ziegel walls.
func _wall_dps(walls: int) -> Array:
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	var e := _enemy(s, "besorgter_buerger", p.pos + Vector2(200, 0))
	s._add_weapon(p, "brandmauer_ziegel", 1)
	var w: Dictionary = p.weapons[0]
	p.weapons.clear()
	for k in walls:
		s._fire(p, w, Vector2.RIGHT, e.pos)
		_run(s, 1)   # the next wall gets its own id
	var hp := e.hp
	_run(s, 60)
	return [hp - e.hp, s.weapon_damage(p, w) * 2.0]


## D-089 / GDD §11: "3 per 0.5 s" per wall, however many bricks overlap the enemy.
func test_brandmauer_ziegel_hurts_once_per_wall() -> void:
	var one := _wall_dps(1)
	assert_near(one[0], one[1], one[1] * 0.1, "one wall: its dps once (got %.1f, want %.1f)" % [one[0], one[1]])
	var two := _wall_dps(2)
	assert_near(two[0], two[1] * 2.0, two[1] * 0.2, "two walls: each counts (got %.1f, want %.1f)" % [two[0], two[1] * 2.0])
