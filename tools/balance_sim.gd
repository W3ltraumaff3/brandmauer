extends SceneTree
## Balance simulation (docs/specs/balancing.md §2): bots without cheats play one
## full run and print one JSON line with per-wave numbers.
##   godot --headless --path . -s res://tools/balance_sim.gd -- players=2 umfrage=3 seed=7
## Options: immortal (bots can't die), random (random level-ups and purchases,
## for the item/weapon/stat analysis), build=<melee|ranged|status|summon|tank|crit>
## (plays like a human going for that build: level-ups, weapons and items; the
## build's own character unless char= is given), char=<id>[,<id>...] (bot i plays
## the i-th character, cycling), start=<weapon>[:tier][,...] (replaces the start
## weapon), item=<item>[,...] (start items), prefer=<weapon|item>[,...] (bought
## first whenever offered), buy=<item>:<wave>[,...] (offered in every Späti from that
## wave on until owned, at the shop price, and bought first once affordable),
## jobs=N / tag=<text> (only recorded).
## Behaviour switches for A/B runs (default first): ult=smart|1|boss|0,
## move=1|0 (planner / v2 kiting), dodge=1|0, spread=1|0, target=1|0, pickup=1|0,
## shop=1|0, streik=1|0, castult=1|0, metrics=1|0 (weapon delivery metrics).
## Game-rule experiments: place=target|lead|cluster|between (where ground weapons land),
## zonetime=<k> (puddles and walls live k x as long at 1/k damage per second).
## stop=<wave>: end the run at the Späti after that wave (quick early-game probes).
## tools/balance_matrix.sh runs many of these in parallel; tools/balance_report.py
## turns the JSON lines into tables.

const Bot := preload("res://tools/balance_bot.gd")
const Metrics := preload("res://tools/balance_metrics.gd")

## Bump when the bot's behaviour changes, so runs of different bots aren't mixed.
## 2: kites only by aiming weapons, Klimakleber walks for trail weapons, red build
##    items, char/start/item/prefer, ultimates, dodging telegraphs, content hash,
##    acquisition and per-wave data.
## 3: movement planner (telegraphs with lookahead, walls and corners, strafing,
##    spreading, pickups), boss targeting, Streik, smart ultimates, smarter Späti,
##    weapon delivery metrics.
const BOT_VERSION := 3
const PRIORITY := ["damage", "max_hp", "attack_speed", "armor", "hp_regen", "melee", "ranged", "lifesteal", "speed"]
const CHARS := ["stadtbild", "oma", "lastenrad", "antifa", "sozialtourist", "buergergeld", "klimakleber", "gewerkschaft"]
const AVOID := ["faxgeraet", "db_ticket", "schuldenbremse", "bierdeckel", "vogelschiss"]
const DT := 1.0 / 60.0
const STUCK_S := 600.0
const STILL_BONUS_AFTER := 0.6
## Red build items: flag -> weapon scaling it boosts (bought by build bots of that scaling).
const BUILD_FLAG_SCALE := {"melee_build": "melee", "ranged_build": "ranged", "summon_build": "summon", "status_build": "status"}
const RED_FIT := 14.0        # item score of a fitting red build item (tier-I weapon: 12, twin: +8)
const PREFER_SCORE := 40.0
## Optional enemy effect timers (newer status effects); counted when the sim has them.
const EXTRA_EFFECTS := {"silence": "silence_t", "reverse": "reverse_t", "sticker": "sticker_t", "file": "file_n"}
## Heal kinds the sim logs per player (p.log); everything else the HP rose by is "other".
const HEAL_KEYS := ["regen", "lifesteal", "sani"]
const DEFENSIVE := ["max_hp", "armor", "hp_regen", "dodge"]
const PRESSURE_HIGH := 0.6   # damage taken in the last wave (× max HP) that makes the Späti defensive

var _random := false
var _build := ""
var _shop3 := true
var _metrics_on := true
var _bot: Bot
var _metrics: Metrics

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
var _buys := {}      # player id -> [[Späti after wave, id, tier, price], ...]
var _first := {}     # player id -> {weapon id: Späti wave it was first owned (0 = start)}
var _offered := {}   # player id -> {id: times seen in an offer}
var _loadout := {}   # player id -> [{"w", "weapons", "stats", "dmg"}, ...] per Späti visit
var _pressure := {}  # player id -> damage taken in the last wave (× max HP)
var _shop_log := {}  # player id -> {"sold", "lu_rerolls", "repairs"}
var _prefer: Array = []
var _buy: Array = []   # buy=: [[item id, first Späti wave], ...], offered and bought at the shop price


func _initialize() -> void:
	var save := root.get_node_or_null("Save")
	if save:
		save.persist = false
	_bot = Bot.new()
	var cfg := {"n": 1, "umfrage": 0, "seed": 1, "immortal": false, "chars": [], "start": [], "items": [],
		"jobs": 0, "tag": "", "place": "", "zonetime": 1.0, "stop": 0}
	var bad := []
	var switches := {"move": true, "dodge": true, "spread": true, "target": true, "pickup": true, "shop": true,
		"streik": true, "castult": false, "metrics": true}
	for a in OS.get_cmdline_user_args():
		var v := a.get_slice("=", 1)
		var key := a.get_slice("=", 0)
		if a.begins_with("players="):
			cfg["n"] = clampi(int(v), 1, 4)
		elif a.begins_with("umfrage="):
			cfg["umfrage"] = int(v)
		elif a.begins_with("seed="):
			cfg["seed"] = int(v)
		elif a == "immortal":
			cfg["immortal"] = true
		elif a == "random":
			_random = true
		elif a.begins_with("char="):
			cfg["chars"] = _list(v)
			for c in cfg["chars"]:
				if not Content.CHARACTERS.has(c):
					bad.append("char " + c)
		elif a.begins_with("build="):
			if BUILDS.has(v):
				_build = v
			else:
				bad.append("build " + v)
		elif a.begins_with("start="):
			for e in _list(v):
				var es := str(e)
				var id := es.get_slice(":", 0)
				var tier := clampi(int(es.get_slice(":", 1)) if es.contains(":") else 1, 1, 4)
				if Content.WEAPONS.has(id):
					cfg["start"].append([id, tier])
				else:
					bad.append("weapon " + id)
		elif a.begins_with("item="):
			for id in _list(v):
				if Content.ITEMS.has(id):
					cfg["items"].append(id)
				else:
					bad.append("item " + id)
		elif a.begins_with("prefer="):
			for id in _list(v):
				if Content.WEAPONS.has(id) or Content.ITEMS.has(id):
					_prefer.append(id)
				else:
					bad.append("prefer " + id)
		elif a.begins_with("buy="):
			for e in _list(v):
				var es := str(e)
				var id := es.get_slice(":", 0)
				var at := int(es.get_slice(":", 1)) if es.contains(":") else 1
				if Content.ITEMS.has(id) and at >= 1:
					_buy.append([id, at])
				else:
					bad.append("buy " + es)
		elif a.begins_with("ult="):
			if v in ["0", "1", "boss", "smart"]:
				_bot.ult = v
			else:
				bad.append("ult " + v)
		elif a.begins_with("tune="):
			for e in _list(v):
				var kv := str(e).split(":")
				if kv.size() == 2 and _bot.tune.has(kv[0]):
					_bot.tune[kv[0]] = float(kv[1])
					cfg["tune"] = str(cfg.get("tune", "") + " " + str(e)).strip_edges()
				else:
					bad.append("tune " + str(e))
		elif switches.has(key) and a.contains("="):
			if v in ["0", "1"]:
				switches[key] = v == "1"
			else:
				bad.append(key + " " + v)
		elif a.begins_with("place="):
			if v in ["target", "lead", "cluster", "between"]:
				cfg["place"] = v
			else:
				bad.append("place " + v)
		elif a.begins_with("zonetime="):
			if v.is_valid_float() and float(v) > 0.0:
				cfg["zonetime"] = float(v)
			else:
				bad.append("zonetime " + v)
		elif a.begins_with("stop="):
			if v.is_valid_int() and int(v) >= 1:
				cfg["stop"] = int(v)
			else:
				bad.append("stop " + v)
		elif a.begins_with("jobs="):
			cfg["jobs"] = int(v)
		elif a.begins_with("tag="):
			cfg["tag"] = v
	if not bad.is_empty():
		printerr("balance_sim: unknown ", ", ".join(bad))
		quit(2)
		return
	_bot.move = switches["move"]
	_bot.dodge = switches["dodge"]
	_bot.spread = switches["spread"]
	_bot.target = switches["target"]
	_bot.pickup = switches["pickup"]
	_bot.streik = switches["streik"]
	_bot.cast_ult = switches["castult"]
	_shop3 = switches["shop"]
	_metrics_on = switches["metrics"]
	cfg["switches"] = switches
	_pick_rng.seed = int(cfg["seed"]) * 7919 + 13
	var out := _run(cfg)
	if not out.has("wave"):
		# The run failed (e.g. a script error in the game code): no half line in the batch.
		printerr("balance_sim: run failed")
		quit(1)
		return
	out["args"] = " ".join(OS.get_cmdline_user_args())
	print(JSON.stringify(out))
	quit()


static func _list(v: String) -> Array:
	var out := []
	for e in v.split(",", false):
		out.append(e.strip_edges())
	return out


## Short md5 of the game logic files (sim, arena, content source), so runs made
## while the game code changed (not only its numbers) can be told apart.
static func code_hash() -> String:
	var all := ""
	for path in ["res://src/sim/sim.gd", "res://src/sim/arena.gd", "res://src/data/content.gd"]:
		all += FileAccess.get_file_as_string(path).md5_text()
	return all.md5_text().substr(0, 10)


## Short hashes of the tuning data, so runs of different content are never mixed
## (`content` = everything; the parts show what changed).
static func content_hash() -> Dictionary:
	var parts := {
		"weapons": Content.WEAPONS, "items": Content.ITEMS, "balance": Content.BALANCE,
		"red": Content.RED_BUILD, "chars": Content.CHARACTERS, "enemies": Content.ENEMIES,
		"levelup": Content.LEVELUP_AMOUNTS, "base": Content.BASE_STATS, "ults": Content.ULTS,
	}
	var out := {}
	var all := ""
	for k in parts:
		var h := JSON.stringify(parts[k]).md5_text()
		out[k] = h.substr(0, 8)
		all += h
	out["all"] = all.md5_text().substr(0, 10)
	return out


## immortal: bots can't die (healed every frame); measures pressure (damage taken
## per wave as a share of max HP) and kill speed independent of bot skill.
func _run(cfg: Dictionary) -> Dictionary:
	var n: int = cfg["n"]
	var seed: int = cfg["seed"]
	var umfrage: int = cfg["umfrage"]
	var immortal: bool = cfg["immortal"]
	var chars: Array = cfg["chars"]
	var players := []
	for i in n:
		var c: String
		if not chars.is_empty():
			c = chars[i % chars.size()]
		elif _build != "":
			c = BUILDS[_build]["char"]
		else:
			c = CHARS[(seed + i * 3) % CHARS.size()]
		players.append({"id": i + 1, "name": "bot%d" % (i + 1), "char": c})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": Content.ORG_ORDER[seed % Content.ORG_ORDER.size()],
		"difficulty": umfrage, "skip_intro": true})
	if cfg["place"] != "":
		s.place_mode = cfg["place"]
	s.zone_time_mult = cfg["zonetime"]
	for p in s.players.values():
		_setup_player(s, p, cfg)
	if _metrics_on:
		_metrics = Metrics.new()
	var heal_keys := HEAL_KEYS.filter(func(k): return s.players.values()[0].log.has(k))
	var waves := []
	var cur := {}
	var acc := {}
	var steps := 0
	var last_phase := -1
	var enc_start := -1.0
	var started := Time.get_ticks_msec()
	var game_t := 0.0
	# per player-run extras
	var taken_by := {}    # pid -> {source: damage}
	var heal_other := {}  # pid -> HP healed by anything but the logged heal kinds (pickups, ults, ...)
	var alive_t := {}
	var still_t := {}
	var summons_max := {}
	for p in s.players.values():
		taken_by[p.id] = {}
		heal_other[p.id] = 0.0
		alive_t[p.id] = 0.0
		still_t[p.id] = 0.0
		summons_max[p.id] = 0
		_pressure[p.id] = 0.0
	while s.phase != Sim.Phase.OVER and steps < 400000:
		var ph := s.phase
		if ph == Sim.Phase.SHOP:
			if last_phase != Sim.Phase.SHOP:
				_close_wave(cur, acc, n)
				for p in s.players.values():
					_pressure[p.id] = (float(p.log["dmg_taken"]) - float(p.get_meta("taken0", 0.0))) \
						/ maxf(1.0, p.stats["max_hp"])
				cur["shop"] = _shop_all(s)
				waves.append(cur)
				if int(cfg["stop"]) > 0 and s.wave >= int(cfg["stop"]):
					break   # stop=N: only the first N waves (e.g. wave-1 income per start weapon)
			for p in s.players.values():
				s.request(p.id, "vote", -1)
				s.request(p.id, "ready", true)
		else:
			if last_phase != Sim.Phase.WAVE:
				cur = {"wave": s.wave, "t": 0.0, "hp_min": 1.0, "downs": 0, "enemies_max": 0, "taken": 0.0, "dealt": 0.0}
				acc = {"enemy_s": 0.0, "slow": 0.0, "poison": 0.0, "stun": 0.0, "immune": 0.0, "summons": 0.0,
					"summons_max": 0, "frames": 0}
				for p in s.players.values():
					p.set_meta("taken0", float(p.log["dmg_taken"]))
					p.set_meta("dealt0", float(p.damage))
				enc_start = -1.0
			_bot.tick()
			for p in s.players.values():
				if p.state == 0:
					p.input = _bot.input(s, p)
					_bot.choose_target(s, p)
					if _bot.want_ult(s, p):
						s.request(p.id, "ultimate")
			_bot.use_streik(s)
			var states := {}
			var before := {}
			var heal_before := 0.0
			for p in s.players.values():
				states[p.id] = p.state
				var hb := {}
				for k in heal_keys:
					hb[k] = float(p.log[k])
				before[p.id] = [p.hp, float(p.log["dmg_taken"]), hb, _projectiles_near(s, p)]
			if _metrics:
				_metrics.before_step(s)
			s.step(DT)
			if _metrics:
				_metrics.after_step(s, DT)
			cur["t"] += DT
			game_t += DT
			cur["enemies_max"] = maxi(int(cur["enemies_max"]), s.enemies.size())
			_count_effects(s, acc)
			var team_hp := 0.0
			var team_max := 0.0
			# Demo-Sanis heal is logged on the owner, but the HP rises on the patient:
			# the team's sani delta pays for unexplained HP rises first.
			var sani_budget := 0.0
			for p in s.players.values():
				if heal_keys.has("sani"):
					sani_budget += float(p.log["sani"]) - float(before[p.id][2]["sani"])
			for p in s.players.values():
				if states[p.id] == 0 and p.state == 1:
					cur["downs"] += 1
				team_hp += p.hp if p.state == 0 else 0.0
				team_max += p.stats["max_hp"]
				var b: Array = before[p.id]
				var taken_now := float(p.log["dmg_taken"]) - float(b[1])
				if taken_now > 0.0:
					var src := _damage_source(s, p, b[3])
					taken_by[p.id][src] = float(taken_by[p.id].get(src, 0.0)) + taken_now
				if states[p.id] == 0 and p.state == 0 and s.phase == Sim.Phase.WAVE:
					alive_t[p.id] += DT
					if p.still_time >= STILL_BONUS_AFTER:
						still_t[p.id] += DT
					var other: float = p.hp - float(b[0]) + taken_now
					for k in heal_keys:
						if k != "sani":
							other -= float(p.log[k]) - float(b[2][k])
					if other > 0.001 and sani_budget > 0.0:
						var take := minf(other, sani_budget)
						other -= take
						sani_budget -= take
					if other > 0.001:
						heal_other[p.id] += other
			for pid in acc.get("per_player", {}):
				summons_max[pid] = maxi(int(summons_max.get(pid, 0)), int(acc["per_player"][pid]))
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
				if enc_start >= 0.0 and s._encounter_alive():
					# HP share the encounter still has (the last value before the wave ends):
					# > 0 without enc_kill = it fled at the wave timer or the team died
					cur["enc_left"] = snappedf(s._enc_frac(s.encounter), 0.001)
		last_phase = ph
		s.take_events()
		steps += 1
		# A wave that lasts 10 minutes is stuck (e.g. a boss the bots can't kill): end the run.
		if ph == Sim.Phase.WAVE and float(cur.get("t", 0.0)) > STUCK_S:
			cur["stuck"] = true
			_close_wave(cur, acc, n)
			waves.append(cur)
			break
	if s.phase == Sim.Phase.OVER and not cur.get("stuck", false):
		_close_wave(cur, acc, n)
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
		var tb := {}
		for k in taken_by[p.id]:
			tb[k] = int(round(taken_by[p.id][k]))
		var heal := {"other": int(round(heal_other[p.id]))}
		for k in heal_keys:
			heal[k] = int(round(p.log[k]))
		var entry := {"char": p.char_id, "items": p.items.duplicate(), "weapons": weapons, "weapon_dmg": wdmg,
			"spent": _spent.get(p.id, {}), "picks": _picks.get(p.id, []), "stats": p.stats.duplicate(),
			"damage_total": int(p.damage), "taken_total": int(p.log["dmg_taken"]),
			"weapon_wave": _first.get(p.id, {}), "buys": _buys.get(p.id, []), "offered": _offered.get(p.id, {}),
			"loadout": _loadout.get(p.id, []), "taken_by": tb, "heal": heal,
			"still_share": snappedf(still_t[p.id] / maxf(DT, alive_t[p.id]), 0.01), "ults": int(p.log["ults"]),
			"summons_max": summons_max[p.id], "shop3": _shop_log.get(p.id, {})}
		if _metrics:
			entry["delivery"] = _metrics.result(p.id)
		final.append(entry)
	var secs := (Time.get_ticks_msec() - started) / 1000.0
	return {"players": n, "umfrage": umfrage, "seed": seed, "immortal": immortal, "random": _random, "build": _build,
		"char": ",".join(chars), "start": cfg["start"].map(func(e): return "%s:%d" % e), "item": cfg["items"],
		"prefer": _prefer, "buy": _buy.map(func(e): return "%s:%d" % e), "ult": _bot.ult, "dodge": _bot.dodge, "switches": cfg["switches"], "tune": cfg.get("tune", ""),
		"place": s.place_mode, "zonetime": cfg["zonetime"], "bot": BOT_VERSION,
		"content": content_hash(), "code": code_hash(), "jobs": cfg["jobs"], "tag": cfg["tag"],
		"won": won, "wave": s.wave, "secs": snappedf(secs, 0.1),
		"ms_per_game_s": snappedf(secs * 1000.0 / maxf(1.0, game_t), 0.1), "waves": waves, "final": final}


## start= / item= options and the start loadout record.
func _setup_player(s: Sim, p, cfg: Dictionary) -> void:
	if not cfg["start"].is_empty():
		for w in p.weapons:
			s.summons = s.summons.filter(func(x): return x.owner != p.id)
			p.sources.erase(Sim._wkey(w))
		p.weapons.clear()
		for e in cfg["start"]:
			if p.weapons.size() < p.max_weapons:
				s._add_weapon(p, e[0], e[1])
	if not cfg["items"].is_empty():
		for id in cfg["items"]:
			p.items.append(id)
		s._recompute(p)
		p.hp = p.stats["max_hp"]
	_first[p.id] = {}
	for w in p.weapons:
		_first[p.id][w["id"]] = 0
	_shop_log[p.id] = {"sold": 0, "lu_rerolls": 0, "repairs": 0, "defensive": 0}


## Per-wave effect counters: share of enemy-seconds slowed / poisoned / stunned,
## on status-immune enemies, and summons alive per player.
func _count_effects(s: Sim, acc: Dictionary) -> void:
	for e in s.enemies:
		if not e.alive:
			continue
		acc["enemy_s"] += DT
		if e.slow_t > 0.0 and e.slow > 0.0:
			acc["slow"] += DT
		if e.poison_t > 0.0 and e.poison > 0.0:
			acc["poison"] += DT
		if e.stun_t > 0.0:
			acc["stun"] += DT
		if e.def.get("immune", false):
			acc["immune"] += DT
		for k in EXTRA_EFFECTS:
			var t = e.get(EXTRA_EFFECTS[k])
			if t != null and float(t) > 0.0:
				acc[k] = float(acc.get(k, 0.0)) + DT
	var per := {}
	for p in s.players.values():
		per[p.id] = 0
	for sm in s.summons:
		if sm.alive and per.has(sm.owner):
			per[sm.owner] += 1
	var total := 0
	for pid in per:
		total += per[pid]
		acc["summons_max"] = maxi(int(acc["summons_max"]), int(per[pid]))
	acc["summons"] += float(total) / maxf(1.0, per.size())
	acc["frames"] += 1
	acc["per_player"] = per


func _close_wave(cur: Dictionary, acc: Dictionary, _n: int) -> void:
	if cur.is_empty() or acc.is_empty() or cur.has("effects"):
		return
	var es := maxf(DT, float(acc["enemy_s"]))
	cur["effects"] = {"slow": snappedf(acc["slow"] / es, 0.01), "poison": snappedf(acc["poison"] / es, 0.01),
		"stun": snappedf(acc["stun"] / es, 0.01), "immune": snappedf(acc["immune"] / es, 0.01)}
	for k in EXTRA_EFFECTS:
		if acc.has(k):
			cur["effects"][k] = snappedf(acc[k] / es, 0.01)
	cur["summons_max"] = acc["summons_max"]
	cur["summons_mean"] = snappedf(acc["summons"] / maxf(1.0, acc["frames"]), 0.1)


## Enemy projectiles close to a player before a step (to find what hit them).
func _projectiles_near(s: Sim, p) -> Array:
	var out := []
	if p.state != 0:
		return out
	for pr in s.projectiles:
		if pr.alive and pr.owner == 0 and not pr.harmless and pr.pos.distance_squared_to(p.pos) < 8100.0:
			out.append(pr)
	return out


## Best guess at what just damaged a player: an enemy projectile that vanished next
## to them, else an enemy touching them, else an enemy hazard under them.
func _damage_source(s: Sim, p, near: Array) -> String:
	for pr in near:
		if not pr.alive and pr.pos.distance_to(p.pos) < Content.PLAYER_RADIUS + pr.radius + 16.0:
			return "proj:" + str(Content.PROJ_ORDER[pr.type])
	var best = null
	var best_d := INF
	for e in s.enemies:
		if not e.alive:
			continue
		var d: float = e.pos.distance_to(p.pos) - e.radius
		if d < Content.PLAYER_RADIUS + 8.0 and d < best_d:
			best_d = d
			best = e
	if best != null:
		return str(best.tid)
	for h in s.hazards:
		if h.alive and h.owner == 0 and h.pos.distance_to(p.pos) < h.radius + Content.PLAYER_RADIUS + 30.0:
			return "hazard:" + str(Content.HAZARD_ORDER[h.type])
	return "other"


## Greedy shopper: level-ups by priority, then buys as long as anything is
## affordable (rerolls when rich). Returns what one Späti visit offered.
## shop=1 adds: level-up rerolls when nothing fits the build, defensive picks and
## items under HP pressure, swapping off-build weapons for build weapons and wall
## repairs (always before the final wave).
func _shop_all(s: Sim) -> Dictionary:
	var out := {"pfand_in": 0, "levelups": 0, "bought": 0, "rerolls": 0, "pfand_left": 0}
	for p in s.players.values():
		out["pfand_in"] += p.pfand
		out["levelups"] += p.levelups
		var lu_rerolls := 0
		while p.levelups > 0 and not p.levelup_options.is_empty():
			var best := 0
			var best_score := -1.0
			if _random:
				best = _pick_rng.randi_range(0, p.levelup_options.size() - 1)
			elif _build != "":
				for i in p.levelup_options.size():
					var stat := str(p.levelup_options[i]["stat"])
					var sc := _stat_score(stat)
					if _shop3 and stat in DEFENSIVE and _pressure.get(p.id, 0.0) > PRESSURE_HIGH:
						sc += 3.0
					sc *= float(p.levelup_options[i]["amount"]) / maxf(0.1, float(Content.LEVELUP_AMOUNTS[stat]))
					if sc > best_score:
						best_score = sc
						best = i
				# nothing the build wants: reroll the picks (twice at most) when it's cheap
				if _shop3 and best_score <= 0.0 and lu_rerolls < 2 \
						and p.pfand >= 3 * int(Content.reroll_price(s.wave, p.levelup_rerolls)):
					if s.request(p.id, "levelup_reroll"):
						lu_rerolls += 1
						_shop_log[p.id]["lu_rerolls"] += 1
						continue
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
			lu_rerolls = 0
		_note_offers(p)
		var forced := _offer_forced(s, p)
		for attempt in 8:
			var bought := false
			var order: Array = range(p.offers.size())
			if _random:
				order.shuffle()
			elif _build != "":
				order = _build_order(p)
			elif _shop3 and _pressure.get(p.id, 0.0) > PRESSURE_HIGH:
				order = _defensive_first(p, order)
			order = _prefer_first(p, order)
			if forced >= 0 and not p.offers[forced]["sold"]:
				order.erase(forced)
				order.push_front(forced)
			for i in order:
				var o: Dictionary = p.offers[i]
				if o["sold"] or o["price"] > p.pfand:
					continue
				if o["kind"] == "weapon" and p.weapons.size() >= p.max_weapons and Sim.find_twin(p, o["id"], o["tier"], -1) < 0:
					if not (o["id"] in _prefer and _make_room(s, p)) and not _swap_off_build(s, p, o):
						continue
				if o["kind"] == "item" and o["id"] in AVOID and not o["id"] in _prefer and i != forced:
					continue
				var price: int = o["price"]
				if s.request(p.id, "buy", i):
					bought = true
					out["bought"] += 1
					if not _spent.has(p.id):
						_spent[p.id] = {}
					_spent[p.id][o["id"]] = int(_spent[p.id].get(o["id"], 0)) + price
					if not _buys.has(p.id):
						_buys[p.id] = []
					_buys[p.id].append([s.wave, o["id"], int(o["tier"]), price])
					if o["kind"] == "weapon" and not _first[p.id].has(o["id"]):
						_first[p.id][o["id"]] = s.wave
					if o["kind"] == "item" and _is_defensive(o["id"]):
						_shop_log[p.id]["defensive"] += 1
			if not bought and p.pfand > int(Content.reroll_price(s.wave, p.rerolls_done)) * 4:
				if s.request(p.id, "reroll"):
					out["rerolls"] += 1
					_note_offers(p)
					forced = _offer_forced(s, p)
			elif not bought:
				break
		if _shop3 and not _random:
			_repair_walls(s, p)
		out["pfand_left"] += p.pfand
		_note_loadout(s, p)
	var n := s.players.size()
	for k in out:
		out[k] = snappedf(float(out[k]) / n, 0.1)
	return out


## Wall repair in the Späti: one hole per visit when there are more holes than at
## the start and it costs at most a quarter of the Pfand; before the final wave
## (the Remigrantin's deportation band works in front of holes) as many as cost
## at most half of the Pfand each.
func _repair_walls(s: Sim, p) -> void:
	var holes: int = s.wall.count(false)
	if holes == 0:
		return
	var price: int = Content.repair_price(s.wave)
	if s.wave >= Content.WAVE_COUNT - 1:
		while s.wall.count(false) > 0 and price <= p.pfand * 0.5:
			if not s.request(p.id, "repair_wall"):
				break
			_shop_log[p.id]["repairs"] += 1
	elif holes > s.players.size() and price <= p.pfand * 0.25:
		if s.request(p.id, "repair_wall"):
			_shop_log[p.id]["repairs"] += 1


static func _is_defensive(id: String) -> bool:
	for stat in Content.ITEMS[id].get("mods", {}):
		if stat in DEFENSIVE and float(Content.ITEMS[id]["mods"][stat]) > 0.0:
			return true
	return false


## Priority bots under HP pressure: defensive items first, the rest in offer order.
func _defensive_first(p, order: Array) -> Array:
	var first := []
	var rest := []
	for i in order:
		var o: Dictionary = p.offers[i]
		if o["kind"] == "item" and _is_defensive(o["id"]):
			first.append(i)
		else:
			rest.append(i)
	return first + rest


## Build bot with full slots: sells its lowest-tier weapon that doesn't fit the
## build to make room for an offered weapon that does.
func _swap_off_build(s: Sim, p, o: Dictionary) -> bool:
	if not _shop3 or _build == "" or _random:
		return false
	var scale: String = BUILDS[_build]["scale"]
	if not Content.WEAPONS[o["id"]].get("scale", {}).has(scale):
		return false
	var worst := -1
	for i in p.weapons.size():
		if Content.WEAPONS[p.weapons[i]["id"]].get("scale", {}).has(scale):
			continue
		if worst < 0 or p.weapons[i]["tier"] < p.weapons[worst]["tier"]:
			worst = i
	if worst < 0 or p.weapons.size() <= 1 or p.weapons[worst]["tier"] > o["tier"]:
		return false
	if s.request(p.id, "sell", worst):
		_shop_log[p.id]["sold"] += 1
		return true
	return false


func _note_offers(p) -> void:
	if not _offered.has(p.id):
		_offered[p.id] = {}
	for o in p.offers:
		_offered[p.id][o["id"]] = int(_offered[p.id].get(o["id"], 0)) + 1


## Loadout after a Späti visit: weapons, non-zero stats and the damage each weapon
## dealt in the wave before it.
func _note_loadout(s: Sim, p) -> void:
	var weapons := []
	for w in p.weapons:
		weapons.append("%s:%d" % [w["id"], w["tier"]])
	var stats := {}
	for k in p.stats:
		if absf(float(p.stats[k])) > 0.001:
			stats[k] = snappedf(float(p.stats[k]), 0.1)
	var dmg := {}
	for row in s.run_stats(p)["damage"]:
		if int(row["wave"]) > 0:
			var id := str(row["id"]) if str(row["kind"]) == "weapon" else str(row["kind"])
			dmg[id] = int(dmg.get(id, 0)) + int(row["wave"])
	if not _loadout.has(p.id):
		_loadout[p.id] = []
	_loadout[p.id].append({"w": s.wave, "weapons": weapons, "stats": stats, "dmg": dmg})


## buy=<item>:<wave>: from the Späti after that wave on, until the player owns the item,
## it is added as an extra offer at its normal shop price (the rolled offers stay, so a
## run that never buys it is the same as without buy=), and the bot buys it before
## anything else once it can pay for it, like a player who sees a red item and saves
## for it. Returns the offer index (-1 = none). Added again after a shop reroll.
func _offer_forced(s: Sim, p) -> int:
	for e in _buy:
		if s.wave < int(e[1]) or p.items.has(e[0]):
			continue
		p.offers.append({"kind": "item", "id": e[0], "tier": 1, "rarity": int(Content.ITEMS[e[0]]["rarity"]),
			"price": s._price(Content.item_price(e[0], s.wave + 1)), "sold": false})
		return p.offers.size() - 1
	return -1


## prefer=: preferred offers first, keeping the rest of the order (and adding them
## even when the build bot didn't score them).
func _prefer_first(p, order: Array) -> Array:
	if _prefer.is_empty():
		return order
	var first := []
	for i in p.offers.size():
		if p.offers[i]["id"] in _prefer:
			first.append(i)
	var out := first.duplicate()
	for i in order:
		if not i in first:
			out.append(i)
	return out


## Slots full and a preferred weapon is offered: sell the cheapest non-preferred
## weapon (lowest tier first), like a human swapping a weapon out.
func _make_room(s: Sim, p) -> bool:
	var worst := -1
	for i in p.weapons.size():
		if p.weapons[i]["id"] in _prefer:
			continue
		if worst < 0 or p.weapons[i]["tier"] < p.weapons[worst]["tier"]:
			worst = i
	return worst >= 0 and s.request(p.id, "sell", worst)


## Build bot: how much it wants a stat (0 = not at all).
func _stat_score(stat: String) -> float:
	var list: Array = BUILDS[_build]["stats"]
	var i := list.find(stat)
	return 0.0 if i < 0 else float(list.size() - i)


## Build bot: red build items (empty `mods`, effect in `flags`) by how well they fit:
## the class item of the build's scaling (Kompost for status, Ehrenamtskarte for
## summon, ...) and Kritische Masse for a build that ranks crit first or second.
## Other build flags punish the build's weapons, so they score negative.
func _flag_score(flags: Array) -> float:
	var sc := 0.0
	var scale: String = BUILDS[_build]["scale"]
	for f in flags:
		if BUILD_FLAG_SCALE.has(f):
			sc += RED_FIT if BUILD_FLAG_SCALE[f] == scale else -RED_FIT
		elif f == "crit_build":
			sc += RED_FIT if (BUILDS[_build]["stats"] as Array).find("crit") in [0, 1] else -RED_FIT
	return sc


## Build bot: offers worth buying, best first. Weapons of the build's scaling (or a
## twin to combine), items by how well their stat changes and build flags fit;
## shop=1 adds a bonus for defensive items under HP pressure.
func _build_order(p) -> Array:
	var scored := []
	var pressure: float = _pressure.get(p.id, 0.0)
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
			var d: Dictionary = Content.ITEMS[o["id"]]
			for stat in d.get("mods", {}):
				var amount := float(d["mods"][stat])
				sc += _stat_score(str(stat)) * signf(amount) * minf(absf(amount), 10.0) / 5.0
			sc += _flag_score(d.get("flags", []))
			if _shop3 and pressure > PRESSURE_HIGH and _is_defensive(o["id"]):
				sc += 4.0 * minf(2.0, pressure)
		if o["id"] in _prefer:
			sc += PREFER_SCORE
		if sc > 0.0:
			scored.append([sc, i])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out := []
	for e in scored:
		out.append(e[1])
	return out
