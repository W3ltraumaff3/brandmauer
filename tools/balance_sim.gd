extends SceneTree
## Balance simulation (docs/specs/balancing.md): kiting bots without cheats play
## one full run and print one JSON line with per-wave numbers.
##   godot --headless --path . -s res://tools/balance_sim.gd -- players=2 umfrage=3 seed=7
## Options: immortal (bots can't die), random (random level-ups and purchases,
## for the item/weapon/stat analysis), char=<id> (every bot plays that character),
## build=<melee|ranged|status|summon|tank|crit> (plays like a human going for that
## build: fitting character, level-ups, weapons and items).
## tools/balance_matrix.sh runs many of these in parallel; tools/balance_report.py
## turns the JSON lines into tables.

const PRIORITY := ["damage", "max_hp", "attack_speed", "armor", "hp_regen", "melee", "ranged", "lifesteal", "speed"]
const CHARS := ["stadtbild", "oma", "lastenrad", "antifa", "sozialtourist", "buergergeld", "klimakleber", "gewerkschaft"]
const AVOID := ["faxgeraet", "db_ticket", "schuldenbremse", "bierdeckel", "vogelschiss"]
const DT := 1.0 / 60.0
const STUCK_S := 600.0

var _random := false
var _build := ""

## Human-like builds: character, level-up priority (first = most wanted) and the
## weapon scaling stat they buy.
const BUILDS := {
	"melee": {"char": "stadtbild", "scale": "melee",
		"stats": ["melee", "damage", "attack_speed", "max_hp", "armor", "lifesteal", "hp_regen", "speed"]},
	"ranged": {"char": "oma", "scale": "ranged",
		"stats": ["ranged", "damage", "attack_speed", "range", "crit", "max_hp", "dodge", "speed"]},
	"status": {"char": "klimakleber", "scale": "status",
		"stats": ["status", "damage", "attack_speed", "max_hp", "range", "hp_regen", "armor"]},
	"summon": {"char": "gewerkschaft", "scale": "summon",
		"stats": ["summon", "damage", "max_hp", "armor", "attack_speed", "hp_regen"]},
	"tank": {"char": "toechter", "scale": "melee",
		"stats": ["max_hp", "armor", "hp_regen", "lifesteal", "melee", "damage", "dodge"]},
	"crit": {"char": "buergergeld", "scale": "ranged",
		"stats": ["crit", "ranged", "attack_speed", "damage", "range", "max_hp", "dodge"]},
}
var _pick_rng := RandomNumberGenerator.new()
var _spent := {}     # player id -> {weapon/item id: Pfand spent}
var _picks := {}     # player id -> ["stat:rarity", ...]


func _initialize() -> void:
	var save := root.get_node_or_null("Save")
	if save:
		save.persist = false
	var n := 1
	var umfrage := 0
	var seed := 1
	var immortal := false
	var random := false
	var char_id := ""
	for a in OS.get_cmdline_user_args():
		var v := a.get_slice("=", 1)
		if a.begins_with("players="):
			n = clampi(int(v), 1, 4)
		elif a.begins_with("umfrage="):
			umfrage = int(v)
		elif a.begins_with("seed="):
			seed = int(v)
		elif a == "immortal":
			immortal = true
		elif a == "random":
			random = true
		elif a.begins_with("char="):
			char_id = v
		elif a.begins_with("build=") and BUILDS.has(v):
			_build = v
			if char_id == "":
				char_id = BUILDS[v]["char"]
	_random = random
	_pick_rng.seed = seed * 7919 + 13
	print(JSON.stringify(_run(n, umfrage, seed, immortal, char_id)))
	quit()


## immortal: bots can't die (healed every frame); measures pressure (damage taken
## per wave as a share of max HP) and kill speed independent of bot skill.
func _run(n: int, umfrage: int, seed: int, immortal := false, char_id := "") -> Dictionary:
	var players := []
	for i in n:
		var c: String = char_id if char_id != "" else CHARS[(seed + i * 3) % CHARS.size()]
		players.append({"id": i + 1, "name": "bot%d" % (i + 1), "char": c})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": Content.ORG_ORDER[seed % Content.ORG_ORDER.size()],
		"difficulty": umfrage, "skip_intro": true})
	var waves := []
	var cur := {}
	var steps := 0
	var last_phase := -1
	var enc_start := -1.0
	var started := Time.get_ticks_msec()
	while s.phase != Sim.Phase.OVER and steps < 400000:
		var ph := s.phase
		if ph == Sim.Phase.SHOP:
			if last_phase != Sim.Phase.SHOP:
				cur["shop"] = _shop_all(s)
				waves.append(cur)
			for p in s.players.values():
				s.request(p.id, "vote", -1)
				s.request(p.id, "ready", true)
		else:
			if last_phase != Sim.Phase.WAVE:
				cur = {"wave": s.wave, "t": 0.0, "hp_min": 1.0, "downs": 0, "enemies_max": 0, "taken": 0.0, "dealt": 0.0}
				for p in s.players.values():
					p.set_meta("taken0", float(p.log["dmg_taken"]))
					p.set_meta("dealt0", float(p.damage))
				enc_start = -1.0
			for p in s.players.values():
				if p.state == 0:
					p.input = _kite(s, p)
			var states := {}
			for p in s.players.values():
				states[p.id] = p.state
			s.step(DT)
			cur["t"] += DT
			cur["enemies_max"] = maxi(int(cur["enemies_max"]), s.enemies.size())
			var team_hp := 0.0
			var team_max := 0.0
			for p in s.players.values():
				if states[p.id] == 0 and p.state == 1:
					cur["downs"] += 1
				team_hp += p.hp if p.state == 0 else 0.0
				team_max += p.stats["max_hp"]
			cur["hp_min"] = minf(float(cur["hp_min"]), team_hp / maxf(1.0, team_max))
			var taken := 0.0
			var dealt := 0.0
			for p in s.players.values():
				taken += (float(p.log["dmg_taken"]) - float(p.get_meta("taken0"))) / maxf(1.0, p.stats["max_hp"])
				dealt += float(p.damage) - float(p.get_meta("dealt0"))
				if immortal:
					if p.state == 1:
						p.state = 0
					p.hp = p.stats["max_hp"]
			cur["taken"] = snappedf(taken / n, 0.01)
			cur["dps"] = snappedf(dealt / maxf(1.0, cur["t"]) / n, 0.1)
			if s.encounter != "":
				if enc_start < 0.0 and s._encounter_alive():
					enc_start = cur["t"]
					cur["enc"] = s.encounter
				elif enc_start >= 0.0 and not cur.has("enc_kill") and not s._encounter_alive():
					cur["enc_kill"] = snappedf(cur["t"] - enc_start, 0.1)
		last_phase = ph
		s.take_events()
		steps += 1
		# A wave that lasts 10 minutes is stuck (e.g. a boss the bots can't kill): end the run.
		if ph == Sim.Phase.WAVE and float(cur.get("t", 0.0)) > STUCK_S:
			cur["stuck"] = true
			waves.append(cur)
			break
	if s.phase == Sim.Phase.OVER and not cur.get("stuck", false):
		waves.append(cur)
	var won: bool = s.result.get("won", false)
	var final := []
	for p in s.players.values():
		var wdmg := {}
		for row in s.run_stats(p)["damage"]:
			if str(row["kind"]) == "weapon":
				wdmg[str(row["id"])] = int(wdmg.get(str(row["id"]), 0)) + int(row["total"])
		var weapons := []
		for w in p.weapons:
			weapons.append("%s:%d" % [w["id"], w["tier"]])
		final.append({"char": p.char_id, "items": p.items.duplicate(), "weapons": weapons, "weapon_dmg": wdmg,
			"spent": _spent.get(p.id, {}), "picks": _picks.get(p.id, []), "stats": p.stats.duplicate(),
			"damage_total": int(p.damage), "taken_total": int(p.log["dmg_taken"])})
	return {"players": n, "umfrage": umfrage, "seed": seed, "immortal": immortal, "random": _random, "build": _build,
		"won": won, "wave": s.wave,
		"secs": snappedf((Time.get_ticks_msec() - started) / 1000.0, 0.1), "waves": waves, "final": final}


## Greedy shopper: level-ups by priority, then buys as long as anything is
## affordable (rerolls when rich). Returns what one Späti visit offered.
func _shop_all(s: Sim) -> Dictionary:
	var out := {"pfand_in": 0, "levelups": 0, "bought": 0, "rerolls": 0, "pfand_left": 0}
	for p in s.players.values():
		out["pfand_in"] += p.pfand
		out["levelups"] += p.levelups
		while p.levelups > 0 and not p.levelup_options.is_empty():
			var best := 0
			if _random:
				best = _pick_rng.randi_range(0, p.levelup_options.size() - 1)
			elif _build != "":
				var best_score := -1.0
				for i in p.levelup_options.size():
					var sc := _stat_score(str(p.levelup_options[i]["stat"])) * float(p.levelup_options[i]["amount"]) \
						/ maxf(0.1, float(Content.LEVELUP_AMOUNTS[str(p.levelup_options[i]["stat"])]))
					if sc > best_score:
						best_score = sc
						best = i
			else:
				var best_rank := 99
				for i in p.levelup_options.size():
					var rank := PRIORITY.find(str(p.levelup_options[i]["stat"]))
					if rank >= 0 and rank < best_rank:
						best_rank = rank
						best = i
			var o: Dictionary = p.levelup_options[best]
			if not _picks.has(p.id):
				_picks[p.id] = []
			_picks[p.id].append("%s:%d" % [o["stat"], int(o.get("rarity", 1))])
			s.request(p.id, "levelup", best)
		for attempt in 8:
			var bought := false
			var order := range(p.offers.size())
			if _random:
				order.shuffle()
			elif _build != "":
				order = _build_order(p)
			for i in order:
				var o: Dictionary = p.offers[i]
				if o["sold"] or o["price"] > p.pfand:
					continue
				if o["kind"] == "weapon" and p.weapons.size() >= p.max_weapons and Sim.find_twin(p, o["id"], o["tier"], -1) < 0:
					continue
				if o["kind"] == "item" and o["id"] in AVOID:
					continue
				var price: int = o["price"]
				if s.request(p.id, "buy", i):
					bought = true
					out["bought"] += 1
					if not _spent.has(p.id):
						_spent[p.id] = {}
					_spent[p.id][o["id"]] = int(_spent[p.id].get(o["id"], 0)) + price
			if not bought and p.pfand > int(Content.reroll_price(s.wave, p.rerolls_done)) * 4:
				if s.request(p.id, "reroll"):
					out["rerolls"] += 1
			elif not bought:
				break
		out["pfand_left"] += p.pfand
	var n := s.players.size()
	for k in out:
		out[k] = snappedf(float(out[k]) / n, 0.1)
	return out


## Build bot: how much it wants a stat (0 = not at all).
func _stat_score(stat: String) -> float:
	var list: Array = BUILDS[_build]["stats"]
	var i := list.find(stat)
	return 0.0 if i < 0 else float(list.size() - i)


## Build bot: offers worth buying, best first. Weapons of the build's scaling (or a
## twin to combine), items by how well their stat changes fit the build.
func _build_order(p) -> Array:
	var scored := []
	for i in p.offers.size():
		var o: Dictionary = p.offers[i]
		var sc := 0.0
		if o["kind"] == "weapon":
			var scale: Dictionary = Content.WEAPONS[o["id"]].get("scale", {})
			if scale.has(BUILDS[_build]["scale"]):
				sc = 10.0 + o["tier"] * 2.0
			if Sim.find_twin(p, o["id"], o["tier"], -1) >= 0:
				sc += 8.0
		else:
			for stat in Content.ITEMS[o["id"]].get("mods", {}):
				var amount := float(Content.ITEMS[o["id"]]["mods"][stat])
				sc += _stat_score(str(stat)) * signf(amount) * minf(absf(amount), 10.0) / 5.0
		if sc > 0.0:
			scored.append([sc, i])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out := []
	for e in scored:
		out.append(e[1])
	return out


func _kite(s: Sim, p) -> Vector2:
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
	# revive downed team mates when it is calm enough
	for o in s.players.values():
		if o.state == 1 and o.pos.distance_to(p.pos) < 500.0:
			push += (o.pos - p.pos).normalized() * 0.7
	# Klimakleber:in stands still for the bonus (+60 % damage) while nobody is close,
	# like a human would; it only dodges when needed.
	if p.char_id == "klimakleber" and push.length() < 0.25:
		return Vector2.ZERO
	push += (Sim.ARENA * 0.5 - p.pos) / 900.0
	if push.length() < 0.3:
		for k in s.pickups:
			if k.alive and k.pos.distance_to(p.pos) < 300.0:
				push += (k.pos - p.pos).normalized() * 0.5
				break
	return push.normalized() if push.length() > 0.05 else Vector2.ZERO
