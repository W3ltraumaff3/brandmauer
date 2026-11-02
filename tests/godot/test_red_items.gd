extends TestCase
## Red items (rarity 4, GDD §12 "Red" and "Politics items", D-127 onwards): every red
## item can show up in the Späti, and the reworked effects do what the spec says.

const AREAS := ["sim", "content"]  # ci-cd.md §2a

const DT := 1.0 / 60.0
const REDS := ["hausbesetzung", "wurfmaschine", "genossenschaftsanteil", "ehrenamtskarte", "kompost",
	"kritische_masse", "robin_hood", "tarnkappe", "cumex_erstattung", "doppelwumms",
	"brandmauer_fertigputz", "entlassungsurkunde"]


func _sim(chars := ["oma"], seed := 11, org := "omas") -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": org, "difficulty": 0, "skip_intro": true})
	s.enemies.clear()
	s.projectiles.clear()
	s.hazards.clear()
	for p in s.players.values():
		p.weapons.clear()
		p.pos = Vector2(950, 610)
	s._spawn_acc = -1000.0   # no random spawns during a test
	return s


func _give(s: Sim, p: Sim.SimPlayer, id: String) -> void:
	p.items.append(id)
	s._recompute(p)


## Regression (D-127): the four red politics items were defined but missing from
## ITEM_ORDER, so the Späti never offered them.
func test_every_red_item_can_be_offered() -> void:
	for id in REDS:
		assert_eq(int(Content.ITEMS[id]["rarity"]), 4, id + " is red")
		assert_has(Content.ITEM_ORDER, id, id + " is in the shop pool")
	var reds := 0
	for id in Content.ITEM_ORDER:
		if int(Content.ITEMS[id]["rarity"]) == 4:
			reds += 1
	assert_eq(reds, REDS.size(), "no other red items")
	# and they really come up: many rolls late in a run offer each of them
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s.wave = 15
	var seen := {}
	for i in 6000:
		var o: Dictionary = s._roll_offer(p)
		if o["kind"] == "item":
			seen[o["id"]] = true
	for id in REDS:
		assert_true(seen.has(id), id + " offered at wave 15")


## Regression (D-128): Wurfmaschine's pierce and speed apply to every player
## projectile weapon, the 9-Euro-Ticket fan included (it was left out).
func test_wurfmaschine_covers_fan_projectiles() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var w := {"id": "neun_euro_ticket", "tier": 1, "cd": 0.0, "angle": 0.0}
	s._fire(p, w, Vector2.RIGHT)
	assert_true(s.projectiles.size() > 0, "fan fired")
	var pierce0: int = s.projectiles[0].pierce
	var speed0: float = s.projectiles[0].vel.length()
	s.projectiles.clear()
	_give(s, p, "wurfmaschine")
	s._fire(p, w, Vector2.RIGHT)
	for pr in s.projectiles:
		assert_eq(pr.pierce, pierce0 + int(Content.RED_BUILD["ranged_pierce"]), "fan pierces +1")
		assert_near(pr.vel.length(), speed0 * Content.RED_BUILD["ranged_speed"], 0.01, "fan flies faster")


func _enemy(s: Sim, pos: Vector2, hp := 100000.0) -> Sim.SimEnemy:
	var e := s.spawn_enemy("besorgter_buerger", pos)
	e.behind = false
	e.speed = 0.0
	e.max_hp = hp
	e.hp = hp
	s._build_grid()
	return e


## Genossenschaftsanteil (D-129): dividend 30 % growing by 5 % per held wave end up to
## 50 %, capped at what a new share costs in the coming Späti; no purchase limit.
func test_genossenschaft_dividend_grows_and_keeps_its_value() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	_give(s, p, "genossenschaftsanteil")
	s.wave = 10
	p.pfand = 100
	assert_eq(s.coop_dividend(p), 30, "30 % at the first wave end")
	var cap := Content.item_price("genossenschaftsanteil", 11)
	var got := []
	for i in 6:
		p.pfand = 200
		var before := p.pfand
		s._end_wave()
		got.append(p.pfand - before)
	assert_eq(got, [60, 70, 80, 90, 100, 100], "30 / 35 / 40 / 45 / 50 / 50 % of 200")
	assert_true(cap > 100, "cap above these amounts")
	# the cap is the share's price in the coming Späti
	p.pfand = 10000
	s.wave = 14
	assert_eq(s.coop_dividend(p), Content.item_price("genossenschaftsanteil", 15), "capped at a new share's price")
	assert_true(s.coop_dividend(p) > 50, "the old flat cap of 50 is gone")
	assert_eq(int(Content.ITEMS["genossenschaftsanteil"]["price"]), 60, "price 60")


## Regression (D-129): the old "only 2 purchases per Späti visit" limit is gone.
func test_genossenschaft_has_no_purchase_limit() -> void:
	var s := Sim.new()
	s.start_run({"seed": 3, "players": [{"id": 1, "name": "P1", "char": "oma"}], "org": "antifa",
		"difficulty": 0, "skip_intro": true})
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 20000:
		s.players[1].iframes = 10.0
		s.step(DT)
		guard += 1
	var p: Sim.SimPlayer = s.players[1]
	_give(s, p, "genossenschaftsanteil")
	p.pfand = 100000
	for i in 4:
		p.offers[i] = {"kind": "item", "id": "solibutton", "tier": 1, "price": 1, "sold": false}
	for i in 4:
		assert_true(s.request(1, "buy", i), "purchase %d allowed" % (i + 1))


## Cum-Ex-Erstattung (D-130): the refund cap grows with the price factor.
func test_cumex_cap_grows_with_prices() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	_give(s, p, "cumex_erstattung")
	s.wave = 12
	p.pfand = 5000
	s._end_wave()
	var want := int(round(Content.RED_BUILD["cumex_max"] * Content.price_mult(13)))
	assert_eq(p.pfand, 5000 + want, "refund = 40 x price factor")
	assert_true(want > 3 * int(Content.RED_BUILD["cumex_max"]), "much more than the flat 40 late in the run")
	assert_eq(int(Content.ITEMS["cumex_erstattung"]["price"]), 60, "price 60")
	p.pfand = 10
	s._end_wave()
	assert_eq(p.pfand, 20, "never more than the unspent Pfand")


## Wurfmaschine (D-128): Durchschlagskraft weapons x1.4, melee x0.5, others unchanged.
func test_wurfmaschine_boosts_ranged_weapons() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var ws := {}
	for id in ["stricknadeln", "megafon", "kartoffelbrei", "doener", "tofu", "infostand"]:
		ws[id] = {"id": id, "tier": 2, "cd": 0.0, "angle": 0.0}
	var d0 := {}
	for id in ws:
		d0[id] = s.weapon_damage(p, ws[id])
	_give(s, p, "wurfmaschine")
	var r: float = Content.RED_BUILD["ranged"]
	for id in ["stricknadeln", "megafon", "kartoffelbrei"]:
		assert_near(s.weapon_damage(p, ws[id]), d0[id] * r, 0.01, id + " x1.4")
	assert_near(s.weapon_damage(p, ws["doener"]), d0["doener"] * 0.5, 0.01, "melee halved")
	assert_near(s.weapon_damage(p, ws["tofu"]), d0["tofu"], 0.01, "status unchanged")
	assert_near(s.weapon_damage(p, ws["infostand"]), d0["infostand"], 0.01, "summon unchanged")


## Kritische Masse (D-131): +15 Direkte Aktion, weapon crits x2, every other weapon hit x0.75.
func test_kritische_masse_numbers() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var crit0: float = p.stats["crit"]
	_give(s, p, "kritische_masse")
	assert_near(p.stats["crit"], crit0 + 15.0, 0.01, "+15 crit")
	var e := _enemy(s, Vector2(1100, 610))
	s._damage_enemy(e, 100.0, p, true, Vector2.ZERO, 0.0, "w1")
	assert_near(100000.0 - e.hp, 200.0, 0.01, "crit x2")
	e.hp = e.max_hp
	s._damage_enemy(e, 100.0, p, false, Vector2.ZERO, 0.0, "w1")
	assert_near(100000.0 - e.hp, 75.0, 0.01, "other hits x0.75")


## Entlassungsurkunde (D-132): +30 crit, -10 Vernetzung, no Durchschlagskraft malus; a crit
## under 40 % HP takes a normal enemy out, not above.
func test_entlassungsurkunde_numbers() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var crit0: float = p.stats["crit"]
	var ranged0: float = p.stats["ranged"]
	var as0: float = p.stats["attack_speed"]
	var xp0: float = p.stats["xp"]
	_give(s, p, "entlassungsurkunde")
	assert_near(p.stats["crit"], crit0 + 30.0, 0.01, "+30 crit")
	assert_near(p.stats["ranged"], ranged0, 0.01, "Durchschlagskraft untouched")
	assert_near(p.stats["attack_speed"], as0, 0.01, "Akkord untouched")
	assert_near(p.stats["xp"], xp0 - 10.0, 0.01, "-10 Vernetzung")
	var low := _enemy(s, Vector2(1100, 610), 1000.0)
	low.hp = 390.0
	s._damage_enemy(low, 1.0, p, true, Vector2.ZERO, 0.0, "w1")
	assert_false(low.alive, "crit under 40 %: out")
	var high := _enemy(s, Vector2(1100, 700), 1000.0)
	high.hp = 410.0
	s._damage_enemy(high, 1.0, p, true, Vector2.ZERO, 0.0, "w1")
	assert_true(high.alive, "above 40 %: a normal hit")
	# elites and bosses can't be dismissed, but crits hit them x1.5
	var boss := s.spawn_enemy("sylt_member", Vector2(1200, 610))
	boss.max_hp = 100000.0
	boss.hp = 1000.0
	s._damage_enemy(boss, 100.0, p, true, Vector2.ZERO, 0.0, "w1")
	assert_true(boss.alive, "an elite under 40 % is not taken out")
	assert_near(1000.0 - boss.hp, 100.0 * Content.RED_BUILD["entlassung_boss"], 0.01, "crit on an elite x1.5")
	s._damage_enemy(boss, 100.0, p, false, Vector2.ZERO, 0.0, "w1")
	assert_near(1000.0 - boss.hp, 250.0, 0.01, "no bonus without a crit")


## Robin-Hood-Kostüm (D-134): +10 Umverteilung, Krankenschein points turn into
## Umverteilung (no regen), every Umverteilung heal is 4 HP.
func test_robin_hood_turns_regen_into_lifesteal() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	_give(s, p, "thermoskanne")
	_give(s, p, "spendendose")
	var regen: float = p.stats["hp_regen"]
	var ls: float = p.stats["lifesteal"]
	assert_true(regen > 0.0 and ls > 0.0, "has both")
	_give(s, p, "robin_hood")
	assert_eq(p.stats["hp_regen"], 0.0, "no Krankenschein left")
	assert_near(p.stats["lifesteal"], ls + regen + 10.0, 0.01, "its points count as Umverteilung, +10")
	p.hp = 1.0
	for i in 60:
		p.iframes = 10.0
		s.step(DT)
	assert_near(p.hp, 1.0, 0.001, "no regeneration over time")
	p.stats["lifesteal"] = 1000.0   # every hit procs
	p.lifesteal_cd = 0.0
	var e := _enemy(s, Vector2(1100, 610))
	s._damage_enemy(e, 10.0, p, false, Vector2.ZERO, 0.0, "w1")
	assert_near(p.hp, 1.0 + Content.RED_BUILD["lifesteal_heal"], 0.001, "one proc heals 4")
	assert_eq(Content.RED_BUILD["lifesteal_heal"], 4.0)


## Tarnkappe (D-135): +50 Schwarzfahren, cap 80 %, Kündigungsschutz 0.
func test_tarnkappe_numbers() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var dodge0: float = p.stats["dodge"]
	_give(s, p, "tarnkappe")
	assert_near(p.stats["dodge"], dodge0 + 50.0, 0.01, "+50 dodge")
	assert_eq(p.stats["armor"], 0.0, "armor 0")
	p.stats["dodge"] = 200.0
	var hits := 0
	for i in 2000:
		p.iframes = 0.0
		p.hp = p.stats["max_hp"]
		var hp0 := p.hp
		s.damage_player(p, 1.0)
		if p.hp < hp0:
			hits += 1
	assert_true(hits > 300 and hits < 500, "80 %% cap: about 400 of 2000 hits land (%d)" % hits)


## Doppelwumms (D-133): each explosion deals (20 + 3 x Durchschlagskraft) x Wut.
func test_doppelwumms_damage() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	_give(s, p, "doppelwumms")
	p.stats["ranged"] = 10.0
	p.stats["damage"] = 50.0
	var e := _enemy(s, Vector2(1100, 610))
	s._wumms(p, e.pos)
	assert_near(100000.0 - e.hp, (20.0 + 3.0 * 10.0) * 1.5, 0.01, "(20 + 3 x 10) x 1.5")
	assert_eq(int(Content.ITEMS["doppelwumms"]["mods"]["armor"]), -10, "-10 armor")
