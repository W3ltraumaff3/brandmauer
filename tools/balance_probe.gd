extends SceneTree
## Rough balance probe: a kiting bot without cheats plays runs per character.
##   godot --headless --path . -s res://tools/balance_probe.gd [-- runs=2 umfrage=0]

const PRIORITY := ["damage", "max_hp", "attack_speed", "armor", "hp_regen", "melee", "ranged", "speed"]


func _initialize() -> void:
	var runs := 2
	var umfrage := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("runs="):
			runs = int(a.substr(5))
		elif a.begins_with("umfrage="):
			umfrage = int(a.substr(8))
	for char_id in Content.CHAR_ORDER:
		var waves := []
		for r in runs:
			waves.append(_run(char_id, 100 + r, umfrage))
		print("%-14s waves: %s" % [char_id, waves])
	quit()


func _run(char_id: String, seed: int, umfrage: int) -> int:
	var s := Sim.new()
	s.start_run({"seed": seed, "players": [{"id": 1, "name": "bot", "char": char_id}],
		"org": Content.ORG_ORDER[seed % 3], "difficulty": umfrage, "skip_intro": true})
	var p: Sim.SimPlayer = s.players[1]
	var steps := 0
	while s.phase != Sim.Phase.OVER and steps < 200000:
		if s.phase == Sim.Phase.SHOP:
			_shop(s, p)
			s.request(1, "vote", -1)
			s.request(1, "ready", true)
		else:
			p.input = _kite(s, p)
			s.step(1.0 / 60.0)
		s.take_events()
		steps += 1
	return s.wave if not s.result.get("won", false) else 21


func _kite(s: Sim, p: Sim.SimPlayer) -> Vector2:
	var reach := 999.0
	for w in p.weapons:
		reach = minf(reach, s._weapon_range(p, Content.WEAPONS[w["id"]]))
	var flee := 90.0 if reach < 200.0 else 260.0
	var push := Vector2.ZERO
	var nearest: Vector2 = Vector2.INF
	for e in s.enemies:
		if e.alive and not e.behind and (nearest == Vector2.INF or e.pos.distance_to(p.pos) < nearest.distance_to(p.pos)):
			nearest = e.pos
	if nearest != Vector2.INF and nearest.distance_to(p.pos) > reach * 0.8:
		push += (nearest - p.pos).normalized() * 0.6
	for e in s.enemies:
		if not e.alive or e.behind:
			continue
		var d: Vector2 = p.pos - e.pos
		var l := d.length()
		if l < flee and l > 0.1:
			push += d / l * (flee - l) / flee * 1.5
	for pr in s.projectiles:
		if pr.owner == 0 and pr.pos.distance_to(p.pos) < 120.0:
			push += (p.pos - pr.pos).normalized() * 0.8
	var center := Arena.CENTER - p.pos
	push += center / 900.0
	# collect nearby pfand when safe
	if push.length() < 0.3:
		for k in s.pickups:
			if k.alive and k.pos.distance_to(p.pos) < 300.0:
				push += (k.pos - p.pos).normalized() * 0.5
				break
	return push.normalized() if push.length() > 0.05 else Vector2.ZERO


func _shop(s: Sim, p: Sim.SimPlayer) -> void:
	while p.levelups > 0 and not p.levelup_options.is_empty():
		var best := 0
		var best_rank := 99
		for i in p.levelup_options.size():
			var rank := PRIORITY.find(p.levelup_options[i]["stat"])
			if rank >= 0 and rank < best_rank:
				best_rank = rank
				best = i
		s.request(1, "levelup", best)
	for attempt in 3:
		var bought := false
		for i in p.offers.size():
			var o: Dictionary = p.offers[i]
			if o["sold"] or o["price"] > p.pfand:
				continue
			if o["kind"] == "weapon" and p.weapons.size() >= p.max_weapons:
				continue
			if o["kind"] == "item" and o["id"] in ["faxgeraet", "db_ticket", "schuldenbremse", "bierdeckel", "vogelschiss"]:
				continue
			if s.request(1, "buy", i):
				bought = true
		if not bought and p.pfand > 60:
			s.request(1, "reroll")
		elif not bought:
			break
