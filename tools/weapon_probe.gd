extends SceneTree
## Weapon probe (docs/specs/balancing.md §2): tier-I dps of weapons under fixed conditions,
## so a weapon's numbers can be checked against the design bands without bot noise.
##   godot --headless --path . -s res://tools/weapon_probe.gd -- [ids=a,b,...] [tier=1] [dist=150]
## An invulnerable Oma with 0 stats (no crits) stands still; immobile dummies (Hinterbänkler,
## HP 1e7) for 20 s: "single" = one at `dist` px, "crowd" = nine in a 45 px ring there,
## "immune" = one Reichsbürger. "/P" = dps per base price, "+pt" = dps gained per point of
## the weapon's first scaling stat (single target, +10 points).

var _dist := 150.0
var _tier := 1


func _case(id: String, tid: String, n: int, stat := 0.0) -> float:
	var s := Sim.new()
	s.start_run({"seed": 5, "players": [{"id": 1, "name": "P", "char": "oma"}], "org": "gewerkschaft",
		"difficulty": 0, "skip_intro": true})
	var p: Sim.SimPlayer = s.players[1]
	p.weapons.clear()
	p.pos = Vector2(950, 610)
	for k in ["status", "summon", "damage", "attack_speed", "range", "melee", "ranged"]:
		p.stats[k] = 0.0
	p.stats["crit"] = -3.0
	var scale_stat: String = Content.WEAPONS[id]["scale"].keys()[0]
	p.stats[scale_stat] = stat
	s._add_weapon(p, id, _tier)
	s.enemies.clear()
	s._spawn_acc = -100000.0
	var es := []
	for i in n:
		var e := s.spawn_enemy(tid, p.pos)
		e.behind = false
		e.speed = 0.0
		e.max_hp = 1e7
		e.hp = 1e7
		es.append(e)
	for f in 1200:
		p.iframes = 10.0
		p.hp = p.stats["max_hp"]
		for i in n:
			var off := Vector2.from_angle(TAU * i / n) * 45.0 if n > 1 else Vector2.ZERO
			es[i].pos = p.pos + Vector2(_dist, 0) + off
			es[i].knock = Vector2.ZERO
		s.step(1.0 / 60.0)
	var dealt := 0.0
	for e in es:
		dealt += e.max_hp - e.hp
	return dealt / 20.0


func _initialize() -> void:
	var ids: Array = Content.WEAPON_ORDER.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("ids="):
			ids = Array(a.get_slice("=", 1).split(",", false))
		elif a.begins_with("tier="):
			_tier = clampi(int(a.get_slice("=", 1)), 1, 4)
		elif a.begins_with("dist="):
			_dist = float(a.get_slice("=", 1))
	print("weapon               single (/P)       crowd (/P)        immune   +dps/pt   (tier %d, %d px)" % [_tier, int(_dist)])
	for id in ids:
		if not Content.WEAPONS.has(id):
			printerr("weapon_probe: unknown weapon ", id)
			continue
		var price: float = Content.WEAPONS[id]["price"]
		var single := _case(id, "hinterbaenkler", 1)
		var crowd := _case(id, "hinterbaenkler", 9)
		var immune := _case(id, "reichsbuerger", 1)
		var plus := _case(id, "hinterbaenkler", 1, 10.0)
		print("%-20s %6.2f (%.2f/P)  %6.2f (%.2f/P)  %4.0f %%   %+.2f" % [id, single, single / price, crowd, crowd / price,
			immune / maxf(0.001, single) * 100.0, (plus - single) / 10.0])
	quit()
