class_name Sim
extends RefCounted
## Host-authoritative simulation (docs/GDD.md, docs/specs/architecture.md).
## Pure logic: no nodes, no engine physics. Runs identically in solo, listen
## server and dedicated server. All randomness comes from `rng` (seeded).

enum Phase { WAVE, SHOP, OVER }

const ARENA := Vector2(1600, 1000)
const WALL_TOP := 78.0
const WALL_BOTTOM := 102.0
const WALL_SEGMENTS := 12
const SEG_W := 1600.0 / 12.0
const STAGING_Y := 40.0
const PLAYER_MIN_Y := WALL_BOTTOM + Content.PLAYER_RADIUS
const CELL := 80.0
const GRID_W := 20
const GRID_H := 13
const INTRO_DELAY := 2.5
const IFRAMES := 0.5
const REVIVE_TIME := 2.5
const REVIVE_RANGE := 60.0
const SAY_INTERVAL := 3.5
const STREIK_TIME := 5.0
const DMG_EVENTS_PER_FRAME := 24
const KASSE_IN := 10
## Player targeting preference (options): which enemy in range the weapons pick.
enum Target { CLOSEST, MOST_HP, LEAST_HP }
const KASSE_OUT := 20              # taken from the Kasse ...
const KASSE_TAX := 0.25            # ... minus 25 % Kapitalertragsteuer
const KASSE_REPAIR_DISCOUNT := 0.3


class SimPlayer:
	var id := 0
	var name := ""
	var char_id := ""
	var pos := Vector2.ZERO
	var input := Vector2.ZERO
	var last_seq := 0
	var hp := 15.0
	var stats := {}
	var levelup_stats := {}
	var weapons: Array = []          # [{id, tier, cd, angle}]
	var items: Array[String] = []
	var flags := {}                  # item flags
	var pfand := 0
	var state := 0                   # 0 alive, 1 downed, 2 gone
	var iframes := 0.0
	var aim := 0.0
	var still_time := 0.0
	var reversed := 0.0
	var stunned := 0.0
	var db_timer := 10.0
	var revive_progress := 0.0
	var reviving := false
	var followers := 0
	var knock := Vector2.ZERO
	var dmg_mult := 1.0
	var offers: Array = []
	var rerolls_done := 0
	var free_rerolls := 0
	var spent := 0
	var levelups := 0
	var levelup_options: Array = []
	var ready := false
	var paid_in := 0
	var taken_out := 0
	var kills := 0
	var damage := 0.0
	var bought_weapons := 0
	var pending_shots: Array = []    # faxgeraet: [{t, w, dir}]
	var achievements: Array[String] = []
	var mietzone_acc := 0.0
	var lifesteal_cd := 0.0
	var repair_time := 0.0
	var max_weapons := Content.MAX_WEAPONS
	var target_mode := 0               # Sim.Target
	var last_fire := -10.0             # sim time of the last shot (aim follows shots)
	var ult_ready := true              # ultimate: once per wave
	var ult_t := 0.0                   # Urlaubsantrag: lying on the sun lounger
	var dash_t := 0.0                  # Critical Mass dash
	var dash_dir := Vector2.ZERO
	var boost_t := 0.0                 # Critical Mass speed boost
	var regen_boost_t := 0.0           # Kaffee und Kuchen


class SimEnemy:
	var id := 0
	var type := 0
	var tid := ""
	var def := {}
	var pos := Vector2.ZERO
	var dir := Vector2.ZERO
	var hp := 1.0
	var max_hp := 1.0
	var dmg := 1.0
	var speed := 1.0
	var radius := 16.0
	var alive := true
	var timer := 0.0
	var timer2 := 0.0
	var timer3 := 0.0
	var state := 0
	var seg := -1
	var target := Vector2.ZERO
	var poison := 0.0
	var poison_t := 0.0
	var poison_src := 0
	var slow := 0.0
	var slow_t := 0.0
	var frozen := 0.0
	var hit_flash := 0.0
	var knock := Vector2.ZERO
	var elite := false
	var behind := false
	var armored := false
	var buffed := false
	var phase := 0
	var shield := 0.0
	var shield_max := 0.0
	var hit_cd := {}
	var stun_t := 0.0
	var vuln_t := 0.0
	var no_reward := false
	var encounter := ""


class SimProj:
	var type := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var dmg := 0.0
	var owner := 0                   # player id, 0 = enemy
	var life := 1.0
	var pierce := 0
	var bounce := 0
	var boomerang := false
	var returning := false
	var hit_ids := {}
	var crit := false
	var weapon := ""
	var radius := 10.0
	var split := 0
	var split_t := 0.0
	var wall_bounce := false
	var harmless := false
	var alive := true


class SimPickup:
	var type := 0
	var pos := Vector2.ZERO
	var value := 1
	var life := -1.0
	var alive := true


class SimHazard:
	var type := 0
	var pos := Vector2.ZERO
	var radius := 40.0
	var life := 1.0
	var max_life := 1.0
	var dps := 0.0
	var owner := 0                   # player id for player hazards, 0 enemy
	var slow := 0.0
	var data := {}
	var alive := true


class SimSummon:
	var type := 0
	var pos := Vector2.ZERO
	var life := -1.0
	var owner := 0
	var cd := 0.0
	var dmg := 0.0
	var reach := 300.0
	var fire_cd := 1.0
	var weapon_index := -1
	var hp := 0.0
	var alive := true


var rng := RandomNumberGenerator.new()
var time := 0.0
var phase: int = Phase.SHOP
var wave := 0
var wave_time := 0.0
var wave_len := 30.0
var players := {}                    # id -> SimPlayer
var enemies: Array = []
var projectiles: Array = []
var pickups: Array = []
var hazards: Array = []
var summons: Array = []
var wall: Array[bool] = []
var events: Array = []
var config := {}
var org := "gewerkschaft"
var difficulty := 0
var diff := {}
var blackrock := false
var kasse := 0
var team_level := 0
var team_xp := 0.0
var stage := 0
var vertrag := {"options": [], "votes": {}, "active": "", "waves_left": 0}
var streik_available := false
var streik_active := 0.0
var streik_discount := false
var effects := {}                    # team/global ultimate effects: id -> seconds left
var encounter := ""
var encounter_pending := -1.0
var intro_wait := false              # boss card shown, world paused until everyone continues
var intro_done := {}
var skip_intro := false              # bots/tests
var encounters_beaten: Array[String] = []
var result := {}
var meta_dirty := true
var shown_quotes := {}

var _next_id := 1
var _spawn_acc := 0.0
var _say_timer := 2.0
var _passant_timer := 4.0
var _sitz_timer := 15.0
var _oma_timer := 0.0
var _oma_pfand := 0.0
var _dmg_events := 0
var _grid: Array = []
var _hole_repair_counter := 0


# --- Setup -------------------------------------------------------------------

## config: {seed, players: [{id, name, char}], org, difficulty, blackrock}
func start_run(cfg: Dictionary) -> void:
	config = cfg
	rng.seed = int(cfg.get("seed", 1))
	org = cfg.get("org", "gewerkschaft")
	difficulty = int(cfg.get("difficulty", 0))
	diff = Content.difficulty_mult(difficulty)
	blackrock = cfg.get("blackrock", false)
	skip_intro = cfg.get("skip_intro", false)
	wall.clear()
	for i in WALL_SEGMENTS:
		wall.append(true)
	wall[WALL_SEGMENTS / 2] = false   # "Es gibt immer einen, der mit denen redet."
	_grid.resize(GRID_W * GRID_H)
	for pd in cfg.get("players", []):
		var p := SimPlayer.new()
		p.id = int(pd["id"])
		p.name = pd.get("name", "")
		p.char_id = pd.get("char", "stadtbild")
		if not Content.CHARACTERS.has(p.char_id):
			p.char_id = "stadtbild"
		var c: Dictionary = Content.CHARACTERS[p.char_id]
		p.weapons.append({"id": c["weapon"], "tier": 1, "cd": 0.5, "angle": 0.0})
		p.pfand = int(c.get("start_pfand", 0))
		p.max_weapons = int(c.get("max_weapons", Content.MAX_WEAPONS))
		p.db_timer = rng.randf_range(8.0, 15.0)
		players[p.id] = p
		_recompute(p)
		p.hp = p.stats["max_hp"]
	_begin_wave(1)


func remove_player(id: int) -> void:
	if players.has(id):
		players[id].state = 2
		meta_dirty = true
		_check_intro_done()
		_check_game_over()


func set_input(id: int, dir: Vector2, seq := 0) -> void:
	var p: SimPlayer = players.get(id)
	if p == null:
		return
	if seq != 0 and seq < p.last_seq:
		return
	p.input = dir.limit_length(1.0)
	if seq != 0:
		p.last_seq = seq


func num_players() -> int:
	var n := 0
	for p in players.values():
		if p.state != 2:
			n += 1
	return maxi(n, 1)


# --- Stats -------------------------------------------------------------------

func _recompute(p: SimPlayer) -> void:
	var s: Dictionary = Content.BASE_STATS.duplicate()
	var mods: Dictionary = Content.CHARACTERS[p.char_id]["mods"]
	for k in mods:
		s[k] += mods[k]
	p.flags.clear()
	for it in p.items:
		var d: Dictionary = Content.ITEMS[it]
		for k in d.get("mods", {}):
			s[k] += d["mods"][k]
		for f in d.get("flags", []):
			p.flags[f] = true
	for k in p.levelup_stats:
		s[k] += p.levelup_stats[k]
	var v := _vertrag_def()
	s["speed"] += v.get("player_speed", 0.0)
	s["damage"] += v.get("damage", 0.0)
	s["xp"] += v.get("xp", 0.0)
	if org == "omas":
		s["hp_regen"] += 1.0
	s["max_hp"] = maxf(1.0, s["max_hp"])
	p.stats = s
	p.hp = minf(p.hp, s["max_hp"])
	meta_dirty = true


func player_speed(p: SimPlayer) -> float:
	return Content.PLAYER_BASE_SPEED * maxf(0.3, 1.0 + p.stats["speed"] / 100.0)


func _vertrag_def() -> Dictionary:
	return Content.VERTRAG.get(vertrag["active"], {})


## Shared by host and client prediction: movement without knockback.
static func move_player(pos: Vector2, dir: Vector2, speed: float, dt: float) -> Vector2:
	var np := pos + dir * speed * dt
	return clamp_player(np)


static func clamp_player(pos: Vector2) -> Vector2:
	var r := Content.PLAYER_RADIUS
	return Vector2(clampf(pos.x, r, ARENA.x - r), clampf(pos.y, PLAYER_MIN_Y, ARENA.y - r))


# --- Main loop ---------------------------------------------------------------

func step(dt: float) -> void:
	time += dt
	if phase != Phase.WAVE or intro_wait:
		return
	_dmg_events = 0
	wave_time += dt
	streik_active = maxf(0.0, streik_active - dt)
	for k in effects.keys():
		effects[k] -= dt
		if effects[k] <= 0.0:
			effects.erase(k)
		meta_dirty = true
	_build_grid()
	_step_spawning(dt)
	_step_encounter_spawn(dt)
	_step_players(dt)
	_step_weapons(dt)
	_step_summons(dt)
	_step_enemies(dt)
	_step_projectiles(dt)
	_step_hazards(dt)
	_step_pickups(dt)
	_step_org(dt)
	_step_say(dt)
	_cleanup()
	if phase == Phase.WAVE and wave_len > 0.0 and wave_time >= wave_len:
		_end_wave()


func _cleanup() -> void:
	enemies = enemies.filter(func(e): return e.alive)
	projectiles = projectiles.filter(func(p): return p.alive)
	pickups = pickups.filter(func(k): return k.alive)
	hazards = hazards.filter(func(h): return h.alive)
	summons = summons.filter(func(s): return s.alive)


# --- Grid --------------------------------------------------------------------

func _build_grid() -> void:
	for i in _grid.size():
		_grid[i] = []
	for e in enemies:
		if e.alive:
			_grid[_cell(e.pos)].append(e)


func _cell(pos: Vector2) -> int:
	var cx := clampi(int(pos.x / CELL), 0, GRID_W - 1)
	var cy := clampi(int(pos.y / CELL), 0, GRID_H - 1)
	return cy * GRID_W + cx


func _query(pos: Vector2, radius: float) -> Array:
	var out := []
	var x0 := clampi(int((pos.x - radius) / CELL), 0, GRID_W - 1)
	var x1 := clampi(int((pos.x + radius) / CELL), 0, GRID_W - 1)
	var y0 := clampi(int((pos.y - radius) / CELL), 0, GRID_H - 1)
	var y1 := clampi(int((pos.y + radius) / CELL), 0, GRID_H - 1)
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			for e in _grid[cy * GRID_W + cx]:
				if e.alive and e.pos.distance_to(pos) <= radius + e.radius:
					out.append(e)
	return out


# --- Waves -------------------------------------------------------------------

func _begin_wave(n: int) -> void:
	_resolve_vertrag()
	wave = n
	wave_time = 0.0
	wave_len = Content.wave_length(n)
	phase = Phase.WAVE
	enemies.clear()
	projectiles.clear()
	hazards.clear()
	pickups.clear()
	summons = summons.filter(func(s): return s.type == Content.idx(Content.SUMMON_ORDER, "oma"))
	_spawn_acc = 0.0
	var alive := players.values().filter(func(p): return p.state != 2)
	var i := 0
	for p in alive:
		p.state = 0
		_recompute(p)
		p.hp = p.stats["max_hp"]
		var ang := TAU * i / maxf(1, alive.size())
		p.pos = Vector2(800, 600) + (Vector2.RIGHT.rotated(ang) * 60.0 if alive.size() > 1 else Vector2.ZERO)
		p.knock = Vector2.ZERO
		p.reversed = 0.0
		p.stunned = 0.0
		p.pending_shots.clear()
		p.ult_ready = true
		p.ult_t = 0.0
		p.dash_t = 0.0
		p.boost_t = 0.0
		p.regen_boost_t = 0.0
		p.ready = false
		for w in p.weapons:
			w["cd"] = 0.5
		i += 1
	streik_available = org == "gewerkschaft" and n % 5 == 0
	effects.clear()
	encounter = ""
	encounter_pending = -1.0
	if Content.ENCOUNTER_POOLS.has(n):
		var pool: Array = Content.ENCOUNTER_POOLS[n]
		encounter = pool[rng.randi_range(0, pool.size() - 1)]
		encounter_pending = INTRO_DELAY
		intro_wait = not skip_intro
		intro_done = {}
		_event(["card", encounter])
	if org == "omas" and summons.is_empty():
		var s := SimSummon.new()
		s.type = Content.idx(Content.SUMMON_ORDER, "oma")
		s.pos = Vector2(760, 640)
		summons.append(s)
	_event(["wave_start", n])
	_event(["sfx", "wave_start", Vector2.INF])
	meta_dirty = true


func _end_wave() -> void:
	for e in enemies:
		if e.elite and e.alive and e.encounter != "":
			_event(["say", e.pos, "SAY_ELITE_FLEES", ""])
	enemies.clear()
	projectiles.clear()
	hazards.clear()
	encounter = ""
	for k in pickups:
		if k.alive and k.type == Content.idx(Content.PICKUP_ORDER, "pfand"):
			var p := _nearest_player(k.pos, true)
			if p:
				_give_pfand(p, k.value)
	pickups.clear()
	var v := _vertrag_def()
	for p in players.values():
		if p.state == 2:
			continue
		var income := int(p.stats["income"]) + int(v.get("income", 0))
		if org == "gewerkschaft":
			income += wave
		if v.has("income_mult") and income > 0:
			income = int(income * v["income_mult"])
		if income > 0:
			_give_pfand(p, income)
		if p.flags.has("streikkasse"):
			_give_pfand(p, mini(20, int(p.pfand * 0.1)))
		if blackrock:
			p.pfand = int(p.pfand * 0.95)
		if p.flags.has("taugenichts"):
			var stat: String = Content.STATS[rng.randi_range(0, Content.STATS.size() - 1)]
			p.levelup_stats[stat] = p.levelup_stats.get(stat, 0.0) + Content.LEVELUP_AMOUNTS[stat]
			_recompute(p)
		p.state = 0
		p.spent = 0
		p.rerolls_done = 0
		p.free_rerolls = int(Content.CHARACTERS[p.char_id].get("free_rerolls", 0))
		p.ready = false
		_make_offers(p)
		_make_levelup_options(p)
	if org == "antifa":
		_hole_repair_counter += 1
		if _hole_repair_counter % 2 == 0:
			_repair_one_hole()
	if vertrag["active"] != "":
		vertrag["waves_left"] -= 1
		if vertrag["waves_left"] <= 0:
			vertrag["active"] = ""
			for p in players.values():
				_recompute(p)
	if (wave + 1) in Content.VERTRAG_WAVES:
		var opts: Array = Content.VERTRAG_ORDER.duplicate()
		_shuffle(opts)
		vertrag["options"] = opts.slice(0, 3)
		vertrag["votes"] = {}
	_event(["wave_end", wave])
	_event(["sfx", "wave_end", Vector2.INF])
	phase = Phase.SHOP
	streik_active = 0.0
	meta_dirty = true


func _resolve_vertrag() -> void:
	var opts: Array = vertrag["options"]
	if opts.is_empty():
		return
	var ids := players.values().filter(func(p): return p.state != 2).map(func(p): return p.id)
	var chosen := resolve_votes(opts, vertrag["votes"], ids)
	vertrag = {"options": [], "votes": {}, "active": chosen, "waves_left": 4}
	for p in players.values():
		_recompute(p)
	_event(["say", Vector2(800, 500), "VERTRAG_%s_NAME" % chosen.to_upper(), ""])


## Unanimous vote picks that option, otherwise the worst one (exposed for tests).
static func resolve_votes(options: Array, votes: Dictionary, voters: Array) -> String:
	var first := -1
	for v in voters:
		if not votes.has(v) or (first != -1 and votes[v] != first):
			first = -2
			break
		first = votes[v]
	if voters.is_empty():
		first = -2
	if first >= 0 and first < options.size():
		return options[first]
	var chosen := ""
	var worst := -1
	for o in options:
		if Content.VERTRAG[o]["badness"] > worst:
			worst = Content.VERTRAG[o]["badness"]
			chosen = o
	return chosen


# --- Spawning ----------------------------------------------------------------

func _step_spawning(dt: float) -> void:
	if wave_len > 0.0 and wave_time > wave_len - 1.5:
		return
	var n := num_players()
	var rate = (0.45 + 0.17 * wave) * diff["spawn"] * (1.0 + 0.6 * (n - 1))
	if encounter != "" and _encounter_alive():
		rate *= 0.4
	_spawn_acc += dt * rate
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		if enemies.size() >= Content.MAX_ENEMIES:
			break
		_spawn_random()


func _spawn_random() -> void:
	var pool := []
	var total := 0
	for tid in Content.ENEMY_ORDER:
		var d: Dictionary = Content.ENEMIES[tid]
		if d["weight"] > 0 and d["from_wave"] <= wave:
			pool.append(tid)
			total += d["weight"]
	var r := rng.randi_range(0, total - 1)
	var pick := ""
	for tid in pool:
		r -= Content.ENEMIES[tid]["weight"]
		if r < 0:
			pick = tid
			break
	var count := (2 + wave / 7) if pick == "besorgter_buerger" else 1
	var base := _spawn_pos(pick)
	for i in count:
		spawn_enemy(pick, base + Vector2(rng.randf_range(-30, 30), rng.randf_range(-10, 10)))


func _spawn_pos(tid: String) -> Vector2:
	var d: Dictionary = Content.ENEMIES[tid]
	if d["faction"] == "afd":
		return Vector2(rng.randf_range(40, ARENA.x - 40), STAGING_Y)
	if d["ai"] == "flyer":
		var left := rng.randf() < 0.5
		return Vector2(-40 if left else ARENA.x + 40, rng.randf_range(200, ARENA.y - 100))
	var best := Vector2(ARENA.x / 2, ARENA.y - 20)
	for attempt in 8:
		var side := rng.randi_range(0, 2)
		var p := Vector2.ZERO
		match side:
			0: p = Vector2(20, rng.randf_range(WALL_BOTTOM + 60, ARENA.y - 20))
			1: p = Vector2(ARENA.x - 20, rng.randf_range(WALL_BOTTOM + 60, ARENA.y - 20))
			_: p = Vector2(rng.randf_range(20, ARENA.x - 20), ARENA.y - 20)
		best = p
		var ok := true
		for pl in players.values():
			if pl.state == 0 and pl.pos.distance_to(p) < 260:
				ok = false
		if ok:
			break
	return best


func spawn_enemy(tid: String, pos: Vector2, elite_scale := 1.0) -> SimEnemy:
	var d: Dictionary = Content.ENEMIES[tid]
	var e := SimEnemy.new()
	e.id = _next_id
	_next_id += 1
	e.tid = tid
	e.type = Content.idx(Content.ENEMY_ORDER, tid)
	e.def = d
	e.pos = pos
	e.radius = d["radius"]
	var vh: float = 1.0 + _vertrag_def().get("enemy_hp", 0.0)
	var vd: float = 1.0 + _vertrag_def().get("enemy_dmg", 0.0)
	var vs: float = 1.0 + _vertrag_def().get("enemy_speed", 0.0)
	if d["faction"] == "elite":
		e.elite = true
		e.max_hp = d["hp"] * diff["hp"] * elite_scale
		e.dmg = d["dmg"] * diff["dmg"] * vd * (1.0 + 0.03 * (wave - 1))
	else:
		var w := float(wave - 1)
		e.max_hp = d["hp"] * (1.0 + 0.16 * w + 0.012 * w * w) * diff["hp"] * vh
		e.dmg = d["dmg"] * (0.6 + 0.08 * w) * diff["dmg"] * vd
	e.hp = e.max_hp
	e.speed = d["speed"] * vs * rng.randf_range(0.92, 1.08)
	e.behind = d["faction"] == "afd"
	e.timer = rng.randf_range(0.5, 1.5)
	if d["ai"] == "bomb":
		e.timer = d["fuse"]
	if d["ai"] == "flyer":
		e.dir = Vector2.RIGHT if pos.x < 0 else Vector2.LEFT
	enemies.append(e)
	return e


func _step_encounter_spawn(dt: float) -> void:
	if encounter_pending < 0.0:
		return
	encounter_pending -= dt
	if encounter_pending > 0.0:
		return
	encounter_pending = -1.0
	var enc: Dictionary = Content.ENCOUNTERS[encounter]
	var scale := 1.0 + 0.75 * (num_players() - 1)
	var units: Array = enc["units"]
	for i in units.size():
		var pos := Vector2(800, 380)
		if units.size() > 1:
			pos = Vector2(300 + i * 330, ARENA.y - 120)
		var e := spawn_enemy(units[i], pos, scale)
		e.encounter = encounter
		e.behind = false
		if e.tid == "eidgenossin":
			_place_turbines()
	var q := Quotes.random_for("boss_ruf:" + encounter, rng)
	if q != "":
		_say_quote(Vector2(800, 380), q)
	meta_dirty = true


func _place_turbines() -> void:
	for p in [Vector2(400, 350), Vector2(1200, 350), Vector2(400, 780), Vector2(1200, 780)]:
		var s := SimSummon.new()
		s.type = Content.idx(Content.SUMMON_ORDER, "turbine")
		s.pos = p
		s.hp = 1.0
		summons.append(s)


func _encounter_alive() -> bool:
	for e in enemies:
		if e.alive and e.encounter != "":
			return true
	return encounter_pending >= 0.0


# --- Players -----------------------------------------------------------------

func _step_players(dt: float) -> void:
	var v := _vertrag_def()
	var suits := 0
	if _any_char("toechter"):
		for e in enemies:
			if e.alive and (e.def["faction"] in Content.SUIT_FACTIONS or e.tid == "sauerlaender"):
				suits += 1
	for p in players.values():
		if p.state != 0:
			continue
		p.iframes = maxf(0.0, p.iframes - dt)
		p.reversed = maxf(0.0, p.reversed - dt)
		p.stunned = maxf(0.0, p.stunned - dt)
		p.lifesteal_cd = maxf(0.0, p.lifesteal_cd - dt)
		# DB-Ticket: random "Verspätung"
		if p.flags.has("db_ticket"):
			p.db_timer -= dt
			if p.db_timer <= 0.0:
				p.db_timer = rng.randf_range(8.0, 15.0)
				p.stunned = 1.0
				_event(["say", p.pos, "SAY_VERSPAETUNG", ""])
		# movement
		var dir = p.input
		if p.reversed > 0.0:
			dir = -dir
		if p.stunned > 0.0:
			dir = Vector2.ZERO
		if dir.length() > 0.05:
			p.still_time = 0.0
			if time - p.last_fire > 0.6:
				p.aim = dir.angle()
		else:
			p.still_time += dt
		if p.ult_t > 0.0:
			p.ult_t -= dt
			p.hp = minf(p.stats["max_hp"], p.hp + p.stats["max_hp"] * Content.ULTS["urlaubsantrag"]["heal_per_s"] * dt)
		if p.dash_t > 0.0:
			_step_dash(p, dt)
		else:
			p.pos = move_player(p.pos, dir, player_speed(p) * (Content.ULTS["critical_mass"]["boost"] if p.boost_t > 0.0 else 1.0), dt)
		p.boost_t = maxf(0.0, p.boost_t - dt)
		if p.regen_boost_t > 0.0:
			p.regen_boost_t -= dt
			p.hp = minf(p.stats["max_hp"], p.hp + Content.ULTS["kaffee_und_kuchen"]["regen"] * 0.12 * dt)
		if p.knock.length() > 1.0:
			var resist := _knock_resist(p)
			p.pos = clamp_player(p.pos + p.knock * (1.0 - resist) * dt)
			p.knock = p.knock.move_toward(Vector2.ZERO, 1400.0 * dt)
		# regen
		if not v.get("no_regen", false) and p.stats["hp_regen"] > 0.0:
			p.hp = minf(p.stats["max_hp"], p.hp + p.stats["hp_regen"] * 0.12 * dt)
		# damage multiplier for this frame
		var m := 1.0
		match p.char_id:
			"stadtbild":
				m += 0.03 * p.followers
			"klimakleber":
				if p.still_time >= 0.6:
					m += 0.6
					for e in _query(p.pos, 120.0):
						_apply_slow(e, 0.3, 0.3)
			"gewerkschaft":
				m += minf(0.6, 0.15 * _allies_near(p, 220.0))
			"toechter":
				m += minf(0.6, 0.04 * suits)
			"antifa":
				_antifa_repair(p, dt)
		if effects.has("tarifrunde"):
			m *= 1.0 + Content.ULTS["tarifrunde"]["damage"]
		p.dmg_mult = m
		if p.char_id == "lastenrad":
			_ram(p)
		# Faxgeraet: delayed shots
		for s in p.pending_shots:
			s["t"] -= dt
			if s["t"] <= 0.0:
				_fire(p, p.weapons[s["w"]] if s["w"] < p.weapons.size() else null, s["dir"])
		p.pending_shots = p.pending_shots.filter(func(s): return s["t"] > 0.0)
	_step_revives(dt)


func _knock_resist(p: SimPlayer) -> float:
	if p.char_id == "stadtbild":
		return minf(0.9, 0.5 + 0.04 * p.followers)
	return 0.0


func _any_char(id: String) -> bool:
	for p in players.values():
		if p.state == 0 and p.char_id == id:
			return true
	return false


func _allies_near(p: SimPlayer, r: float) -> int:
	var n := 0
	for o in players.values():
		if o != p and o.state == 0 and o.pos.distance_to(p.pos) <= r:
			n += 1
	for s in summons:
		if s.alive and (s.owner == p.id or s.type == Content.idx(Content.SUMMON_ORDER, "oma")) and s.pos.distance_to(p.pos) <= r:
			n += 1
	return n


func _ram(p: SimPlayer) -> void:
	var dmg = (4.0 + p.stats["speed"] * 0.1) * maxf(0.1, 1.0 + p.stats["damage"] / 100.0) * p.dmg_mult
	for e in _query(p.pos, Content.PLAYER_RADIUS + 4.0):
		var key := "ram%d" % p.id
		if e.hit_cd.get(key, 0.0) <= time:
			e.hit_cd[key] = time + 0.4
			_damage_enemy(e, dmg, p, false, (e.pos - p.pos).normalized(), 80.0)


func _antifa_repair(p: SimPlayer, dt: float) -> void:
	if p.pos.y > WALL_BOTTOM + 60.0:
		p.repair_time = 0.0
		return
	var seg := clampi(int(p.pos.x / SEG_W), 0, WALL_SEGMENTS - 1)
	if wall[seg]:
		p.repair_time = 0.0
		return
	p.repair_time += dt
	if p.repair_time >= 3.0:
		p.repair_time = 0.0
		wall[seg] = true
		_event(["say", p.pos, "SAY_ANTIFA_REPAIR", ""])
		_event(["sfx", "vote", p.pos])
		meta_dirty = true


func _step_revives(dt: float) -> void:
	for p in players.values():
		p.reviving = false
	for d in players.values():
		if d.state != 1:
			continue
		var helper: SimPlayer = null
		for o in players.values():
			if o.state == 0 and o.pos.distance_to(d.pos) <= REVIVE_RANGE:
				helper = o
				break
		if helper == null:
			d.revive_progress = maxf(0.0, d.revive_progress - dt)
			continue
		helper.reviving = true
		d.revive_progress += dt
		if d.revive_progress >= REVIVE_TIME:
			d.revive_progress = 0.0
			d.state = 0
			d.hp = d.stats["max_hp"] * 0.4
			d.iframes = 1.5
			var cost = helper.stats["max_hp"] * (0.05 if helper.flags.has("erste_hilfe") else 0.1)
			helper.hp = maxf(1.0, helper.hp - cost)
			_event(["revive", d.id])
			_event(["sfx", "revive", d.pos])
			meta_dirty = true


func damage_player(p: SimPlayer, amount: float, source_pos := Vector2.INF) -> void:
	if p.state != 0 or p.iframes > 0.0 or amount <= 0.0:
		return
	if rng.randf() * 100.0 < minf(p.stats["dodge"], Content.DODGE_CAP):
		_event(["say", p.pos, "SAY_DODGE", ""])
		p.iframes = 0.2
		return
	var armor: float = p.stats["armor"]
	var dmg := amount * (15.0 / (15.0 + armor) if armor >= 0.0 else 1.0 - armor * 0.05)
	dmg = maxf(1.0, dmg)
	p.hp -= dmg
	p.iframes = IFRAMES
	_event(["dmg", p.pos, int(round(dmg)), false, true])
	_event(["sfx", "hurt", p.pos])
	if p.hp <= 0.0:
		p.hp = 0.0
		if num_players() > 1:
			p.state = 1
			p.revive_progress = 0.0
			_event(["down", p.id])
			_event(["sfx", "down", p.pos])
		else:
			p.state = 1
		meta_dirty = true
		_check_game_over()


func _check_game_over() -> void:
	if phase == Phase.OVER:
		return
	for p in players.values():
		if p.state == 0:
			return
	_finish(false)


# --- Weapons -----------------------------------------------------------------

func _step_weapons(dt: float) -> void:
	for p in players.values():
		if p.state != 0:
			continue
		var as_mult := maxf(0.2, 1.0 + p.stats["attack_speed"] / 100.0)
		for wi in p.weapons.size():
			var w: Dictionary = p.weapons[wi]
			var def: Dictionary = Content.WEAPONS[w["id"]]
			if def["kind"] == "orbit":
				_step_orbit(p, w, def, dt)
				continue
			w["cd"] -= dt * as_mult
			if w["cd"] > 0.0:
				continue
			var rng_r := _weapon_range(p, def)
			var target := _pick_target(p.pos, rng_r, p.target_mode)
			if target == null:
				w["cd"] = 0.05
				continue
			w["cd"] = def["cd"]
			var aim_at: Vector2 = target.pos
			var dir = (aim_at - p.pos).normalized()
			w["angle"] = dir.angle()
			p.aim = dir.angle()
			p.last_fire = time
			if p.flags.has("fax"):
				p.pending_shots.append({"t": 3.0, "w": wi, "dir": dir})
			else:
				_fire(p, w, dir, aim_at)


func _weapon_range(p: SimPlayer, def: Dictionary) -> float:
	var bonus: float = p.stats["range"]
	if def.get("melee", false):
		bonus *= 0.5
	return maxf(40.0, def["range"] + bonus)


func weapon_damage(p: SimPlayer, w: Dictionary) -> float:
	var def: Dictionary = Content.WEAPONS[w["id"]]
	var d := Content.weapon_damage(w["id"], w["tier"])
	for s in def["scale"]:
		d += p.stats[s] * def["scale"][s]
	d *= maxf(0.1, 1.0 + p.stats["damage"] / 100.0) * p.dmg_mult
	return maxf(1.0, d)


func _roll_crit(p: SimPlayer) -> bool:
	return rng.randf() * 100.0 < p.stats["crit"] + 3.0


func _fire(p: SimPlayer, w, dir: Vector2, target_pos := Vector2.INF) -> void:
	if w == null:
		return
	var def: Dictionary = Content.WEAPONS[w["id"]]
	var dmg := weapon_damage(p, w)
	var crit := _roll_crit(p)
	if crit:
		dmg *= def.get("crit_mult", 1.5)
	match def["kind"]:
		"shot":
			var pr := SimProj.new()
			pr.type = Content.idx(Content.PROJ_ORDER, def["proj"])
			pr.pos = p.pos + dir * 18.0
			pr.vel = dir * def["speed"]
			pr.dmg = dmg
			pr.crit = crit
			pr.owner = p.id
			pr.weapon = w["id"]
			pr.life = _weapon_range(p, def) / def["speed"] * (2.2 if def.get("boomerang", false) else 1.15)
			pr.pierce = def.get("pierce", 0)
			pr.bounce = def.get("bounce", 0) + (w["tier"] - 1 if w["id"] == "gendersternchen" else 0)
			pr.boomerang = def.get("boomerang", false)
			projectiles.append(pr)
			_event(["sfx", "shoot", p.pos])
		"cone":
			var r := _weapon_range(p, def)
			var half := deg_to_rad(def["arc"]) / 2.0
			for e in _query(p.pos, r):
				if e.behind and shot_blocked(p.pos, e.pos):
					continue
				var to: Vector2 = e.pos - p.pos
				if def["arc"] >= 360.0 or absf(angle_difference(dir.angle(), to.angle())) <= half + 0.15:
					_damage_enemy(e, dmg, p, crit, to.normalized(), def.get("knock", 0.0))
			_event(["swing", p.pos, dir.angle(), r, def["arc"], w["id"]])
			_event(["sfx", "melee", p.pos])
		"puddle":
			var h := SimHazard.new()
			h.type = Content.idx(Content.HAZARD_ORDER, "kleber")
			h.pos = target_pos if target_pos != Vector2.INF else p.pos + dir * 150.0
			h.radius = def["radius"]
			h.life = def["life"]
			h.max_life = h.life
			h.dps = dmg
			h.slow = def["slow"]
			h.owner = p.id
			hazards.append(h)
			_event(["sfx", "shoot", p.pos])
		"turret":
			var mine := summons.filter(func(s): return s.owner == p.id and s.weapon_index == p.weapons.find(w))
			if mine.size() >= def["max"]:
				mine[0].alive = false
			var s := SimSummon.new()
			s.type = Content.idx(Content.SUMMON_ORDER, "infostand")
			s.pos = p.pos
			s.owner = p.id
			s.life = def["life"]
			s.dmg = dmg
			s.reach = def["range"] + p.stats["range"]
			s.fire_cd = def["fire_cd"] / maxf(0.2, 1.0 + p.stats["attack_speed"] / 100.0)
			s.weapon_index = p.weapons.find(w)
			summons.append(s)


func _step_orbit(p: SimPlayer, w: Dictionary, def: Dictionary, dt: float) -> void:
	var count: int = def["count"][w["tier"] - 1]
	w["angle"] = fmod(w["angle"] + dt * 3.2, TAU)
	var dmg := weapon_damage(p, w)
	for i in count:
		var pt = p.pos + Vector2.RIGHT.rotated(w["angle"] + TAU * i / count) * def["range"]
		for e in _query(pt, 20.0):
			var key := "orb%d" % p.id
			if e.hit_cd.get(key, 0.0) <= time:
				e.hit_cd[key] = time + def["cd"]
				_damage_enemy(e, dmg, p, _roll_crit(p), (e.pos - p.pos).normalized(), 50.0)
		for pr in projectiles:
			if pr.alive and pr.owner == 0 and not pr.harmless and pr.pos.distance_to(pt) < 24.0:
				pr.alive = false


func orbit_points(p: SimPlayer) -> Array:
	var out := []
	for w in p.weapons:
		var def: Dictionary = Content.WEAPONS[w["id"]]
		if def["kind"] != "orbit":
			continue
		var count: int = def["count"][w["tier"] - 1]
		for i in count:
			out.append(p.pos + Vector2.RIGHT.rotated(w["angle"] + TAU * i / count) * def["range"])
	return out


## Picks the target for a weapon among enemies in range, by the player's mode.
func _pick_target(pos: Vector2, r: float, mode: int) -> SimEnemy:
	if mode == Target.CLOSEST:
		return _nearest_enemy(pos, r)
	var best: SimEnemy = null
	for e in enemies:
		if not e.alive or (e.behind and shot_blocked(pos, e.pos)) or e.pos.distance_to(pos) - e.radius > r:
			continue
		if best == null or (mode == Target.MOST_HP and e.hp > best.hp) or (mode == Target.LEAST_HP and e.hp < best.hp):
			best = e
	return best



## True if an intact Brandmauer segment lies between a and b (shots can pass holes).
func shot_blocked(a: Vector2, b: Vector2) -> bool:
	var mid := (WALL_TOP + WALL_BOTTOM) * 0.5
	if (a.y - mid) * (b.y - mid) > 0.0:
		return false
	var t := (mid - a.y) / (b.y - a.y) if b.y != a.y else 0.0
	var x := a.x + (b.x - a.x) * t
	return wall[clampi(int(x / SEG_W), 0, WALL_SEGMENTS - 1)]


func _nearest_enemy(pos: Vector2, r: float, exclude := {}) -> SimEnemy:
	var best: SimEnemy = null
	var bd := r
	for e in enemies:
		if not e.alive or exclude.has(e.id) or (e.behind and shot_blocked(pos, e.pos)):
			continue
		var d: float = e.pos.distance_to(pos) - e.radius
		if d < bd:
			bd = d
			best = e
	return best


func _nearest_player(pos: Vector2, include_downed := false) -> SimPlayer:
	var best: SimPlayer = null
	var bd := INF
	for p in players.values():
		if p.state == 2 or (p.state == 1 and not include_downed):
			continue
		var d: float = p.pos.distance_to(pos)
		if d < bd:
			bd = d
			best = p
	return best


# --- Damage to enemies -------------------------------------------------------

func _damage_enemy(e: SimEnemy, amount: float, src: SimPlayer, crit := false, kdir := Vector2.ZERO, knock := 0.0) -> void:
	if not e.alive:
		return
	if src:
		if e.def["faction"] == "afd" or e.tid == "eidgenossin" or e.tid == "geschichtslehrer":
			if src.char_id == "antifa":
				amount *= 1.4
			if org == "antifa":
				amount *= 1.2
	if e.vuln_t > 0.0:
		amount *= Content.ULTS["fragen_sie_uns"]["vuln"]
	if e.armored:
		amount *= 0.7
	if e.shield > 0.0:
		e.shield -= amount
		if e.shield < 0.0:
			amount = -e.shield
			e.shield = 0.0
			_event(["say", e.pos, "SAY_SHIELD_BROKEN", ""])
		else:
			amount = 0.0
	e.hp -= amount
	e.hit_flash = 0.1
	if knock > 0.0 and not e.elite:
		e.knock += kdir * knock * 4.0
	if src:
		src.damage += amount
		if src.stats["lifesteal"] > 0.0 and src.lifesteal_cd <= 0.0 and rng.randf() * 100.0 < src.stats["lifesteal"] * 5.0:
			src.hp = minf(src.stats["max_hp"], src.hp + 1.0)
			src.lifesteal_cd = 0.1
	if _dmg_events < DMG_EVENTS_PER_FRAME and amount > 0.0:
		_dmg_events += 1
		_event(["dmg", e.pos, int(round(amount)), crit, false])
	if e.hp <= 0.0:
		_kill_enemy(e, src)


func _kill_enemy(e: SimEnemy, killer: SimPlayer) -> void:
	e.alive = false
	if killer:
		killer.kills += 1
	if e.def["ai"] == "bomb" or e.no_reward:
		_event(["kill", e.pos, e.type])
		return
	if e.encounter != "":
		_on_encounter_unit_down(e)
	else:
		_event(["kill", e.pos, e.type])
		_event(["sfx", "kill", e.pos])
	# loot
	var value: int = e.def["pfand"]
	var v := _vertrag_def()
	if v.has("pfand_drop"):
		value = int(round(value * (1.0 - v["pfand_drop"])))
	var luck: float = killer.stats["luck"] if killer else 0.0
	if value > 0 and rng.randf() < luck / 200.0:
		value += 1
	if value > 0:
		var drops := 1 if not e.elite else 6
		for i in drops:
			_drop(Content.idx(Content.PICKUP_ORDER, "pfand"), e.pos + Vector2(rng.randf_range(-24, 24), rng.randf_range(-24, 24)), maxi(1, value / drops))
	if rng.randf() < 0.015 + luck * 0.0002:
		_drop(Content.idx(Content.PICKUP_ORDER, "stulle"), e.pos, 1)
	if e.tid == "reichsbuerger" and rng.randf() < 0.05:
		_drop(Content.idx(Content.PICKUP_ORDER, "reichsausweis"), e.pos, 1)
	if e.def.has("split"):
		for i in 2:
			var s := spawn_enemy(e.def["split"], e.pos + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)))
			s.behind = false
	# Zusammenhalt
	var xp: float = e.def["xp"]
	if killer:
		xp *= 1.0 + killer.stats["xp"] / 100.0
		if _allies_near(killer, 250.0) > 0:
			xp *= 1.25
	_add_xp(xp)


func _add_xp(xp: float) -> void:
	team_xp += xp
	while team_xp >= Content.xp_for_level(team_level):
		team_xp -= Content.xp_for_level(team_level)
		team_level += 1
		for p in players.values():
			if p.state != 2:
				p.levelups += 1
		_event(["levelup", team_level])
		_event(["sfx", "levelup", Vector2.INF])
		var st := Content.stage_for_level(team_level)
		if st != stage:
			stage = st
			_event(["stage", stage])
	meta_dirty = true


const MAX_PICKUPS := 250


func _drop(type: int, pos: Vector2, value: int, life := -1.0) -> void:
	# Too many bottles lying around: add the value to an existing bottle instead.
	if pickups.size() >= MAX_PICKUPS and type == Content.idx(Content.PICKUP_ORDER, "pfand"):
		for i in 8:
			var other: SimPickup = pickups[rng.randi_range(0, pickups.size() - 1)]
			if other.alive and other.type == type:
				other.value += value
				return
	var k := SimPickup.new()
	k.type = type
	k.pos = Vector2(clampf(pos.x, 10, ARENA.x - 10), clampf(pos.y, PLAYER_MIN_Y, ARENA.y - 10))
	k.value = value
	k.life = life
	pickups.append(k)


func _give_pfand(p: SimPlayer, amount: int) -> void:
	p.pfand += amount
	meta_dirty = true


func _apply_slow(e: SimEnemy, amount: float, t: float) -> void:
	if e.def.get("immune", false):
		return
	e.slow = maxf(e.slow, amount)
	e.slow_t = maxf(e.slow_t, t)


func _apply_poison(e: SimEnemy, dps: float, t: float, src: int) -> void:
	if e.def.get("immune", false):
		return
	e.poison = maxf(e.poison, dps)
	e.poison_t = t
	e.poison_src = src


# --- Encounters --------------------------------------------------------------

func _on_encounter_unit_down(e: SimEnemy) -> void:
	for o in enemies:
		if o.alive and o.encounter == e.encounter:
			return
	var enc_id := e.encounter
	var enc: Dictionary = Content.ENCOUNTERS[enc_id]
	encounters_beaten.append(enc_id)
	_event(["exit", enc_id, e.pos])
	for p in players.values():
		if p.state != 2:
			_grant(p, enc["achievement"])
	for q in Quotes.ids_for("boss_karte:" + enc_id) + Quotes.ids_for("boss_ruf:" + enc_id):
		shown_quotes[q] = true
	summons = summons.filter(func(s): return s.type != Content.idx(Content.SUMMON_ORDER, "turbine"))
	hazards = hazards.filter(func(h): return h.type != Content.idx(Content.HAZARD_ORDER, "abschiebezone"))
	meta_dirty = true
	if enc_id == "eidgenossin" or wave >= Content.WAVE_COUNT:
		_finish(true)


func _grant(p: SimPlayer, ach: String) -> void:
	if ach == "" or ach in p.achievements:
		return
	p.achievements.append(ach)
	_event(["ach", p.id, ach])


func _finish(won: bool) -> void:
	phase = Phase.OVER
	var holes := wall.count(false)
	var res_players := {}
	for p in players.values():
		if won and holes == 0:
			_grant(p, "ach_unmoeglich")
		if won and p.char_id == "buergergeld" and p.bought_weapons == 0:
			_grant(p, "ach_faul_effizient")
		var total = p.paid_in + p.taken_out
		res_players[p.id] = {
			"name": p.name, "char": p.char_id, "kills": p.kills, "damage": int(p.damage),
			"paid_in": p.paid_in, "taken_out": p.taken_out,
			"steuermoral": float(p.paid_in) / total if total > 0 else -1.0,
			"bought_weapons": p.bought_weapons, "achievements": p.achievements.duplicate(),
		}
	var quotes := shown_quotes.keys()
	var album := Quotes.album_ids()
	for i in 2:
		if not album.is_empty():
			var q: String = album[rng.randi_range(0, album.size() - 1)]
			if not q in quotes:
				quotes.append(q)
	result = {
		"won": won, "wave": wave, "time": time, "difficulty": difficulty,
		"encounters_beaten": encounters_beaten.duplicate(), "wall_intact": holes == 0,
		"players": res_players, "quotes": quotes,
	}
	_event(["over", won])
	meta_dirty = true


# --- Summons -----------------------------------------------------------------

func _step_summons(dt: float) -> void:
	var oma_t := Content.idx(Content.SUMMON_ORDER, "oma")
	var info_t := Content.idx(Content.SUMMON_ORDER, "infostand")
	var genosse_t := Content.idx(Content.SUMMON_ORDER, "genosse")
	for s in summons:
		if not s.alive:
			continue
		if s.life > 0.0:
			s.life -= dt
			if s.life <= 0.0:
				s.alive = false
				continue
		if s.type == info_t:
			s.cd -= dt
			if s.cd <= 0.0:
				var owner: SimPlayer = players.get(s.owner)
				var t := _pick_target(s.pos, s.reach, owner.target_mode if owner else Target.CLOSEST)
				if t:
					s.cd = s.fire_cd
					var pr := SimProj.new()
					pr.type = Content.idx(Content.PROJ_ORDER, "flugblatt")
					pr.pos = s.pos
					pr.vel = (t.pos - s.pos).normalized() * 520.0
					pr.dmg = s.dmg * _team_dmg()
					pr.owner = s.owner
					pr.weapon = "infostand"
					pr.life = s.reach / 520.0 * 1.2
					projectiles.append(pr)
		elif s.type == genosse_t:
			_step_genosse(s, dt)
		elif s.type == oma_t:
			var lead := _nearest_player(s.pos)
			if lead:
				var goal: Vector2 = lead.pos + Vector2(-50, 30)
				s.pos = s.pos.move_toward(goal, 230.0 * dt)
			s.cd -= dt
			if s.cd <= 0.0:
				s.cd = 1.0
				var hit := false
				for e in _query(s.pos, 70.0):
					_damage_enemy(e, (4.0 + wave * 1.2) * _team_dmg(), null, false, (e.pos - s.pos).normalized(), 60.0)
					hit = true
				if hit:
					_event(["swing", s.pos, 0.0, 70.0, 360.0, "oma"])
			_oma_pfand += dt
			if _oma_pfand >= 5.0:
				_oma_pfand = 0.0
				_drop(Content.idx(Content.PICKUP_ORDER, "pfand"), s.pos + Vector2(10, 10), 1)


# --- Ultimates (GDD §9a) -----------------------------------------------------

func _team_dmg() -> float:
	return 1.0 + Content.ULTS["tarifrunde"]["damage"] if effects.has("tarifrunde") else 1.0


func _activate_ult(p: SimPlayer) -> void:
	var ult: String = Content.CHARACTERS[p.char_id].get("ult", "")
	var u: Dictionary = Content.ULTS.get(ult, {})
	if u.is_empty():
		return
	p.ult_ready = false
	var power := maxf(0.1, 1.0 + p.stats["damage"] / 100.0) * p.dmg_mult
	match ult:
		"flashmob":
			var dmg: float = (u["dmg"] + u["dmg_per_follower"] * p.followers) * power
			for e in _query(p.pos, u["radius"]):
				if e.behind and shot_blocked(p.pos, e.pos):
					continue
				e.stun_t = maxf(e.stun_t, u["stun"])
				_damage_enemy(e, dmg, p, false, (e.pos - p.pos).normalized(), u["knock"])
		"urlaubsantrag":
			p.ult_t = u["time"]
			p.stunned = u["time"]
			p.iframes = u["time"]
		"antrag_gestellt", "tarifrunde":
			effects[ult] = u["time"]
		"strassenblockade":
			var x: float = 35.0
			while x < ARENA.x:
				var h := SimHazard.new()
				h.type = Content.idx(Content.HAZARD_ORDER, "kleber")
				h.pos = Vector2(x, p.pos.y)
				h.radius = u["radius"]
				h.life = u["time"]
				h.max_life = u["time"]
				h.slow = u["slow"]
				h.dps = u["dps"] * (1.0 + p.stats["status"] * 0.1) * power
				h.owner = p.id
				hazards.append(h)
				x += u["spacing"]
		"critical_mass":
			p.dash_dir = p.input.normalized() if p.input.length() > 0.1 else Vector2.RIGHT.rotated(p.aim)
			p.dash_t = u["dash_time"]
			p.boost_t = u["dash_time"] + u["boost_time"]
			p.iframes = maxf(p.iframes, u["dash_time"])
		"schwarzer_block":
			for i in int(u["count"]):
				var s := SimSummon.new()
				s.type = Content.idx(Content.SUMMON_ORDER, "genosse")
				s.pos = clamp_player(p.pos + Vector2.RIGHT.rotated(TAU * i / u["count"]) * 50.0)
				s.owner = p.id
				s.life = u["time"]
				s.dmg = u["dmg"] * (1.0 + p.stats["summon"] * 0.1) * power
				s.reach = u["radius"]
				summons.append(s)
		"kaffee_und_kuchen":
			for o in players.values():
				if o.state == 0:
					o.hp = o.stats["max_hp"]
				elif o.state == 1:
					o.state = 0
					o.hp = o.stats["max_hp"] * u["revive_hp"]
					o.iframes = 1.5
					_event(["revive", o.id])
				if o.state == 0:
					o.regen_boost_t = u["regen_time"]
		"fragen_sie_uns":
			for e in enemies:
				if e.alive and not e.behind and (e.def["faction"] in Content.SUIT_FACTIONS or e.tid == "sauerlaender"):
					e.stun_t = maxf(e.stun_t, u["stun"])
					e.vuln_t = u["vuln_time"]
	_event(["ult", p.id, ult, p.pos])
	_event(["sfx", "streik", p.pos])
	meta_dirty = true


func _step_dash(p: SimPlayer, dt: float) -> void:
	var u: Dictionary = Content.ULTS["critical_mass"]
	p.dash_t -= dt
	p.pos = clamp_player(p.pos + p.dash_dir * u["dash_speed"] * dt)
	var dmg: float = (4.0 + p.stats["speed"] * 0.1) * u["ram_mult"] * maxf(0.1, 1.0 + p.stats["damage"] / 100.0) * p.dmg_mult
	var key := "cm%d" % p.id
	for e in _query(p.pos, Content.PLAYER_RADIUS + 10.0):
		if e.hit_cd.get(key, 0.0) <= time:
			e.hit_cd[key] = time + 1.0
			_damage_enemy(e, dmg, p, false, p.dash_dir, 120.0)


func _step_genosse(s: SimSummon, dt: float) -> void:
	var t := _nearest_enemy(s.pos, 600.0)
	if t:
		s.pos = clamp_player(s.pos.move_toward(t.pos, 260.0 * dt))
	s.cd -= dt
	if s.cd > 0.0:
		return
	s.cd = 0.5
	var owner: SimPlayer = players.get(s.owner)
	for e in _query(s.pos, s.reach):
		var away: Vector2 = (e.pos - s.pos).normalized()
		_damage_enemy(e, s.dmg * _team_dmg(), owner, false, away, 90.0)


# --- Enemies -----------------------------------------------------------------

func _step_enemies(dt: float) -> void:
	# auras
	for e in enemies:
		e.armored = false
		e.buffed = false
	for e in enemies:
		if not e.alive:
			continue
		if e.tid == "lobbyist":
			for o in _query(e.pos, e.def["aura"]):
				if o != e:
					o.armored = true
		elif e.tid == "hinterbaenkler":
			for o in _query(e.pos, 150.0):
				if o.def["faction"] == "afd" and not o.behind:
					e.buffed = true
					break
		elif e.tid == "sylt_member":
			for o in _query(e.pos, 160.0):
				if o != e and o.tid == "sylt_member":
					e.buffed = true
					break
	var frozen := streik_active > 0.0
	for e in enemies:
		if not e.alive:
			continue
		e.hit_flash = maxf(0.0, e.hit_flash - dt)
		if e.poison_t > 0.0:
			e.poison_t -= dt
			_damage_poison(e, e.poison * dt)
			if not e.alive:
				continue
		if e.slow_t > 0.0:
			e.slow_t -= dt
			if e.slow_t <= 0.0:
				e.slow = 0.0
		e.vuln_t = maxf(0.0, e.vuln_t - dt)
		if e.stun_t > 0.0:
			e.stun_t -= dt
			continue
		var spd: float = e.speed * (1.0 - e.slow) * (1.2 if e.buffed else 1.0)
		if effects.has("antrag_gestellt"):
			spd *= 1.0 - Content.ULTS["antrag_gestellt"]["slow"]
		if frozen:
			if e.elite:
				spd *= 0.5
			else:
				continue
		if e.knock.length() > 1.0:
			e.pos += e.knock * dt
			e.knock = e.knock.move_toward(Vector2.ZERO, 2400.0 * dt)
		if e.behind:
			_move_behind_wall(e, spd, dt)
		else:
			match e.def["ai"]:
				"chase": _ai_chase(e, spd, dt)
				"ranged": _ai_ranged(e, spd, dt)
				"voter": _ai_voter(e, spd, dt)
				"charger": _ai_charger(e, spd, dt)
				"zone": _ai_zone(e, spd, dt)
				"lob": _ai_lob(e, spd, dt)
				"bomb": _ai_bomb(e, spd, dt)
				"flyer": _ai_flyer(e, spd, dt)
				"sylt": _ai_sylt(e, spd, dt)
				"boss": _ai_boss(e, spd, dt)
		if not e.alive:
			continue
		_separate(e)
		if e.def["ai"] != "flyer":
			var min_y = WALL_BOTTOM + e.radius if not e.behind else 0.0
			e.pos = Vector2(clampf(e.pos.x, e.radius, ARENA.x - e.radius), clampf(e.pos.y, min_y + 2.0, ARENA.y - e.radius))
		_contact(e)


func _damage_poison(e: SimEnemy, amount: float) -> void:
	var src: SimPlayer = players.get(e.poison_src)
	e.hp -= amount
	if src:
		src.damage += amount
	if e.hp <= 0.0:
		_kill_enemy(e, src)


func _separate(e: SimEnemy) -> void:
	if e.elite and e.def["ai"] == "boss":
		return
	for o in _query(e.pos, e.radius + 8.0):
		if o == e or o.behind != e.behind:
			continue
		var d: Vector2 = e.pos - o.pos
		var min_d: float = e.radius + o.radius
		var l := d.length()
		if l < min_d and l > 0.01:
			e.pos += d / l * (min_d - l) * 0.5


func _contact(e: SimEnemy) -> void:
	if e.behind or e.def["ai"] == "bomb":
		return
	var dmg: float = e.dmg * (1.5 if e.buffed else 1.0)
	if dmg <= 0.0:
		return
	for p in players.values():
		if p.state == 0 and p.pos.distance_to(e.pos) < e.radius + Content.PLAYER_RADIUS:
			if p.iframes <= 0.0:
				damage_player(p, dmg)
				if e.def.has("push_up"):
					p.knock = Vector2(0, -e.def["push_up"]) * 2.0


func _move_toward(e: SimEnemy, goal: Vector2, spd: float, dt: float) -> void:
	var d := goal - e.pos
	if d.length() > 1.0:
		e.dir = d.normalized()
		e.pos += e.dir * minf(spd * dt, d.length())


func _move_behind_wall(e: SimEnemy, spd: float, dt: float) -> void:
	var holes := []
	for i in WALL_SEGMENTS:
		if not wall[i]:
			holes.append(i)
	if holes.is_empty():
		# pace along the wall, grumbling
		if e.target == Vector2.ZERO or e.pos.distance_to(e.target) < 10.0:
			e.target = Vector2(rng.randf_range(40, ARENA.x - 40), rng.randf_range(20, WALL_TOP - 20))
		_move_toward(e, e.target, spd * 0.5, dt)
		return
	var best: int = holes[0]
	for h in holes:
		if absf((h + 0.5) * SEG_W - e.pos.x) < absf((best + 0.5) * SEG_W - e.pos.x):
			best = h
	var cx := (best + 0.5) * SEG_W
	if absf(e.pos.x - cx) > SEG_W * 0.3 and e.pos.y < WALL_TOP - 4.0:
		_move_toward(e, Vector2(cx, minf(e.pos.y, WALL_TOP - 14.0)), spd, dt)
	else:
		_move_toward(e, Vector2(cx, WALL_BOTTOM + e.radius + 12.0), spd, dt)
		if e.pos.y >= WALL_BOTTOM + e.radius:
			e.behind = false


func _target_player(e: SimEnemy) -> SimPlayer:
	return _nearest_player(e.pos)


func _ai_chase(e: SimEnemy, spd: float, dt: float) -> void:
	var p := _target_player(e)
	if p:
		_move_toward(e, p.pos, spd, dt)


func _keep_distance(e: SimEnemy, p: SimPlayer, keep: float, spd: float, dt: float) -> void:
	var d := e.pos.distance_to(p.pos)
	if d > keep + 40.0:
		_move_toward(e, p.pos, spd, dt)
	elif d < keep - 40.0:
		_move_toward(e, e.pos + (e.pos - p.pos).normalized() * 50.0, spd, dt)


func _enemy_shot(e: SimEnemy, proj: String, dir: Vector2, speed: float, dmg: float, life := 4.0) -> SimProj:
	var pr := SimProj.new()
	pr.type = Content.idx(Content.PROJ_ORDER, proj)
	pr.pos = e.pos + dir * e.radius
	pr.vel = dir * speed
	pr.dmg = dmg
	pr.owner = 0
	pr.life = life
	pr.radius = 9.0
	projectiles.append(pr)
	return pr


func _ai_ranged(e: SimEnemy, spd: float, dt: float) -> void:
	var p := _target_player(e)
	if p == null:
		return
	_keep_distance(e, p, e.def["keep"], spd, dt)
	e.timer -= dt
	if e.timer <= 0.0 and e.pos.distance_to(p.pos) < e.def["keep"] + 160.0:
		e.timer = e.def["fire_cd"]
		var dmg: float = e.def["proj_dmg"] * e.dmg / e.def["dmg"]
		var pr := _enemy_shot(e, e.def["proj"], (p.pos - e.pos).normalized(), e.def["proj_speed"], dmg)
		pr.split = 1
		pr.split_t = 0.8


func _ai_voter(e: SimEnemy, spd: float, dt: float) -> void:
	if e.state == 2:
		_ai_chase(e, spd, dt)
		return
	if e.seg < 0 or not wall[e.seg]:
		e.seg = -1
		var bd := INF
		for i in WALL_SEGMENTS:
			if wall[i]:
				var d := absf((i + 0.5) * SEG_W - e.pos.x)
				if d < bd:
					bd = d
					e.seg = i
		if e.seg < 0:
			e.state = 2
			return
		e.state = 0
	var spot := Vector2((e.seg + 0.5) * SEG_W, WALL_BOTTOM + e.radius + 4.0)
	if e.state == 0:
		_move_toward(e, spot, spd, dt)
		if e.pos.distance_to(spot) < 8.0:
			e.state = 1
			e.timer2 = 0.0
	elif e.state == 1:
		e.timer2 += dt
		if e.timer2 >= e.def["vote_time"]:
			wall[e.seg] = false
			e.state = 2
			_event(["say", e.pos, "SAY_JU_VOTE", ""])
			_event(["sfx", "vote", e.pos])
			meta_dirty = true


func _ai_charger(e: SimEnemy, spd: float, dt: float) -> void:
	var p := _target_player(e)
	match e.state:
		0:
			if p == null:
				return
			_move_toward(e, p.pos, spd, dt)
			e.timer -= dt
			if e.timer <= 0.0 and e.pos.distance_to(p.pos) < 320.0:
				e.state = 1
				e.timer2 = 0.8
				e.target = (p.pos - e.pos).normalized()
		1:
			e.timer2 -= dt
			if e.timer2 <= 0.0:
				e.state = 2
				e.timer2 = 0.6
		2:
			e.pos += e.target * spd * 3.5 * dt
			e.timer2 -= dt
			if e.timer2 <= 0.0:
				e.state = 3
				e.timer2 = 3.0
		3:
			e.timer2 -= dt
			if e.timer2 <= 0.0:
				e.state = 0
				e.timer = 2.0


func _ai_zone(e: SimEnemy, spd: float, dt: float) -> void:
	var p := _target_player(e)
	if p:
		_keep_distance(e, p, e.def["keep"], spd, dt)
	e.timer -= dt
	if e.timer <= 0.0:
		e.timer = 5.0
		var h := SimHazard.new()
		h.type = Content.idx(Content.HAZARD_ORDER, "mietzone")
		h.pos = e.pos
		h.radius = 70.0
		h.life = 8.0
		h.max_life = 8.0
		hazards.append(h)


func _lob(from: Vector2, to: Vector2, dmg: float, proj: String, radius := 50.0) -> void:
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "lob_marker")
	h.pos = to
	h.radius = radius
	h.life = 1.0
	h.max_life = 1.0
	h.data = {"dmg": dmg}
	hazards.append(h)
	var pr := SimProj.new()
	pr.type = Content.idx(Content.PROJ_ORDER, proj)
	pr.pos = from
	pr.vel = (to - from) / 1.0
	pr.life = 1.0
	pr.harmless = true
	projectiles.append(pr)


func _ai_lob(e: SimEnemy, spd: float, dt: float) -> void:
	var p := _target_player(e)
	if p == null:
		return
	_keep_distance(e, p, e.def["keep"], spd, dt)
	e.timer -= dt
	if e.timer <= 0.0 and e.pos.distance_to(p.pos) < 520.0:
		e.timer = e.def["fire_cd"]
		_lob(e.pos, p.pos, e.def["proj_dmg"] * e.dmg / e.def["dmg"], "golfball")


func _ai_bomb(e: SimEnemy, spd: float, dt: float) -> void:
	_ai_chase(e, spd, dt)
	e.timer -= dt
	if e.timer <= 0.0:
		e.alive = false
		_explode(e.pos, 60.0, e.dmg)
		_event(["say", e.pos, "SAY_STARTUP_INSOLVENT", ""])


func _explode(pos: Vector2, radius: float, dmg: float) -> void:
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "explosion")
	h.pos = pos
	h.radius = radius
	h.life = 0.4
	h.max_life = 0.4
	hazards.append(h)
	for p in players.values():
		if p.state == 0 and p.pos.distance_to(pos) < radius + Content.PLAYER_RADIUS:
			damage_player(p, dmg)
	_event(["sfx", "explosion", pos])


func _ai_flyer(e: SimEnemy, spd: float, dt: float) -> void:
	e.pos += e.dir * spd * dt
	e.behind = false
	e.timer -= dt
	if e.timer <= 0.0:
		e.timer = 0.25
		var h := SimHazard.new()
		h.type = Content.idx(Content.HAZARD_ORDER, "kerosin")
		h.pos = e.pos
		h.radius = 28.0
		h.life = 3.0
		h.max_life = 3.0
		h.dps = e.dmg * 0.5
		hazards.append(h)
	if e.pos.x < -80 or e.pos.x > ARENA.x + 80:
		e.alive = false


func _ai_sylt(e: SimEnemy, spd: float, dt: float) -> void:
	_ai_chase(e, spd * 0.9, dt)
	var p := _target_player(e)
	e.timer -= dt
	if p and e.timer <= 0.0:
		e.timer = e.def["fire_cd"] + rng.randf_range(0.0, 0.8)
		_lob(e.pos, p.pos + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40)), e.def["proj_dmg"] * diff["dmg"] * (1.4 if e.buffed else 1.0), "champagner")
	e.timer3 -= dt
	if e.timer3 <= 0.0:
		e.timer3 = rng.randf_range(5.0, 9.0)
		_event(["say", e.pos, "SAY_SYLT_HUM", ""])


# --- Bosses ------------------------------------------------------------------

func _ai_boss(e: SimEnemy, spd: float, dt: float) -> void:
	match e.tid:
		"geschichtslehrer": _boss_lehrer(e, spd, dt)
		"sauerlaender": _boss_sauerlaender(e, spd, dt)
		"eidgenossin": _boss_eidgenossin(e, spd, dt)


func _boss_phase(e: SimEnemy) -> void:
	var f := e.hp / e.max_hp
	var ph := 0 if f > 0.66 else (1 if f > 0.33 else 2)
	if ph != e.phase:
		e.phase = ph
		e.state = 0
		var q := Quotes.random_for("boss_ruf:" + e.tid, rng)
		if q != "":
			_say_quote(e.pos, q)
		meta_dirty = true


func _ring(e: SimEnemy, proj: String, count: int, speed: float, dmg: float, offset := 0.0) -> void:
	for i in count:
		_enemy_shot(e, proj, Vector2.RIGHT.rotated(offset + TAU * i / count), speed, dmg, 5.0)


func _spread(e: SimEnemy, proj: String, target: Vector2, count: int, arc: float, speed: float, dmg: float) -> void:
	var base := (target - e.pos).angle()
	for i in count:
		var a := base + (float(i) / maxf(1, count - 1) - 0.5) * arc if count > 1 else base
		_enemy_shot(e, proj, Vector2.RIGHT.rotated(a), speed, dmg, 5.0)


func _boss_lehrer(e: SimEnemy, spd: float, dt: float) -> void:
	_boss_phase(e)
	_ai_chase(e, spd, dt)
	e.timer -= dt
	if e.timer <= 0.0:
		e.timer = 3.0 - e.phase * 0.5
		_ring(e, "buch", 10 + e.phase * 2, 220.0, e.dmg * 0.6, rng.randf() * TAU)
	e.timer2 += dt
	if e.timer2 >= 10.5 and e.state == 0:
		e.state = 1   # telegraph
		_event(["say", e.pos, "SAY_LEHRER_WENDE", ""])
	if e.timer2 >= 12.0:
		e.timer2 = 0.0
		e.state = 0
		for p in players.values():
			if p.state == 0:
				p.reversed = 4.0
		_event(["wende", 4.0])
		_event(["sfx", "wende", Vector2.INF])


func _boss_sauerlaender(e: SimEnemy, spd: float, dt: float) -> void:
	_boss_phase(e)
	var p := _target_player(e)
	match e.phase:
		0:
			if e.target == Vector2.ZERO or e.pos.distance_to(e.target) < 12.0:
				e.target = Vector2(rng.randf_range(200, 1400), rng.randf_range(220, 800))
			_move_toward(e, e.target, spd, dt)
			e.timer -= dt
			if e.timer <= 0.0 and p:
				e.timer = 1.6
				_spread(e, "bierdeckel", p.pos, 5, 0.9, 300.0, e.dmg * 0.6)
		1:
			_ai_chase(e, spd * 0.6, dt)
			e.timer -= dt
			if e.timer <= 0.0 and p:
				e.timer = 2.4
				_spread(e, "bierdeckel", p.pos, 5, 0.9, 260.0, e.dmg * 0.6)
			e.timer2 -= dt
			if e.timer2 <= 0.0:
				e.timer2 = 4.0
				for i in 8:
					_drop(Content.idx(Content.PICKUP_ORDER, "geldschein"),
						Vector2(rng.randf_range(150, 1450), rng.randf_range(200, 900)), 2, 4.0)
				_event(["say", e.pos, "SAY_SONDERVERMOEGEN", ""])
		2:
			_ai_chase(e, spd * 1.2, dt)
			e.timer -= dt
			if e.timer <= 0.0:
				e.timer = 3.0
				for i in 3:
					var pr := _enemy_shot(e, "zirkusball", Vector2.RIGHT.rotated(rng.randf() * TAU), 300.0, e.dmg * 0.7, 6.0)
					pr.wall_bounce = true
					pr.radius = 14.0


func _boss_eidgenossin(e: SimEnemy, spd: float, dt: float) -> void:
	_boss_phase(e)
	var p := _target_player(e)
	match e.phase:
		0:
			# Windmühlen der Schande: dash at players, tear down turbines
			match e.state:
				0:
					if p:
						_move_toward(e, p.pos, spd * 0.7, dt)
					e.timer -= dt
					if e.timer <= 0.0 and p:
						e.state = 1
						e.timer2 = 0.7
						e.target = (p.pos - e.pos).normalized()
				1:
					e.timer2 -= dt
					if e.timer2 <= 0.0:
						e.state = 2
						e.timer2 = 0.6
				2:
					e.pos += e.target * spd * 4.0 * dt
					e.timer2 -= dt
					for s in summons:
						if s.alive and s.type == Content.idx(Content.SUMMON_ORDER, "turbine") and s.pos.distance_to(e.pos) < 50.0:
							s.alive = false
							_event(["say", s.pos, "SAY_WINDMUEHLE", ""])
					if e.timer2 <= 0.0:
						e.state = 0
						e.timer = 3.0
			e.timer3 -= dt
			if e.timer3 <= 0.0 and p:
				e.timer3 = 2.2
				_spread(e, "fluegel", p.pos, 3, 0.7, 260.0, e.dmg * 0.6)
		1:
			# Remigration: push rings toward the wall, the top edge burns
			if not hazards.any(func(h): return h.type == Content.idx(Content.HAZARD_ORDER, "abschiebezone")):
				var z := SimHazard.new()
				z.type = Content.idx(Content.HAZARD_ORDER, "abschiebezone")
				z.pos = Vector2(800, WALL_BOTTOM + 35.0)
				z.radius = 35.0
				z.life = 9999.0
				z.max_life = 9999.0
				z.dps = e.dmg * 0.4
				hazards.append(z)
			if p:
				_move_toward(e, p.pos, spd * 0.5, dt)
			e.timer -= dt
			if e.timer <= 0.0:
				e.timer = 3.5
				_push_ring(e.pos, e.dmg * 0.3)
		2:
			# Steuerparadies: gold-bar shield at the top
			if e.state == 0:
				e.state = 1
				e.shield_max = e.max_hp * 0.25
				e.shield = e.shield_max
			_move_toward(e, Vector2(800, 230), spd, dt)
			e.timer -= dt
			if e.timer <= 0.0 and p:
				e.timer = 1.2
				_spread(e, "goldbarren", p.pos, 5, 1.0, 280.0, e.dmg * 0.5)
			e.timer2 -= dt
			if e.timer2 <= 0.0:
				e.timer2 = 6.0
				_push_ring(e.pos, e.dmg * 0.3)


func _push_ring(pos: Vector2, dmg: float) -> void:
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "push_ring")
	h.pos = pos
	h.radius = 0.0
	h.life = 2.5
	h.max_life = 2.5
	h.data = {"dmg": dmg, "hit": {}}
	hazards.append(h)


# --- Projectiles -------------------------------------------------------------

func _step_projectiles(dt: float) -> void:
	var turbine_t := Content.idx(Content.SUMMON_ORDER, "turbine")
	for pr in projectiles:
		if not pr.alive:
			continue
		pr.life -= dt
		if pr.life <= 0.0:
			pr.alive = false
			continue
		if pr.boomerang:
			var owner: SimPlayer = players.get(pr.owner)
			if not pr.returning and pr.life < 1.0:
				pr.returning = true
				pr.hit_ids.clear()
			if pr.returning and owner:
				pr.vel = (owner.pos - pr.pos).normalized() * pr.vel.length()
				if pr.pos.distance_to(owner.pos) < 20.0:
					pr.alive = false
					continue
		if pr.split > 0:
			pr.split_t -= dt
			if pr.split_t <= 0.0:
				pr.split -= 1
				for s in [-0.45, 0.45]:
					var c := SimProj.new()
					c.type = pr.type
					c.pos = pr.pos
					c.vel = pr.vel.rotated(s)
					c.dmg = pr.dmg
					c.life = pr.life
					c.radius = pr.radius
					projectiles.append(c)
				pr.alive = false
				continue
		pr.pos += pr.vel * dt
		if pr.wall_bounce:
			if pr.pos.x < 0 or pr.pos.x > ARENA.x:
				pr.vel.x = -pr.vel.x
			if pr.pos.y < WALL_BOTTOM or pr.pos.y > ARENA.y:
				pr.vel.y = -pr.vel.y
		elif pr.pos.x < -50 or pr.pos.x > ARENA.x + 50 or pr.pos.y < -50 or pr.pos.y > ARENA.y + 50:
			pr.alive = false
			continue
		if pr.harmless:
			continue
		# intact wall blocks shots
		if pr.pos.y > WALL_TOP and pr.pos.y < WALL_BOTTOM and wall[clampi(int(pr.pos.x / SEG_W), 0, WALL_SEGMENTS - 1)]:
			pr.alive = false
			continue
		if pr.owner == 0:
			for s in summons:
				if s.alive and s.type == turbine_t and s.pos.distance_to(pr.pos) < 34.0:
					pr.alive = false
					break
			if not pr.alive:
				continue
			for p in players.values():
				if p.state == 0 and p.pos.distance_to(pr.pos) < Content.PLAYER_RADIUS + pr.radius:
					damage_player(p, pr.dmg)
					pr.alive = false
					break
		else:
			_proj_hit_enemies(pr)


func _proj_hit_enemies(pr: SimProj) -> void:
	var src: SimPlayer = players.get(pr.owner)
	for e in _query(pr.pos, pr.radius):
		if pr.hit_ids.has(e.id):
			continue
		pr.hit_ids[e.id] = true
		var def: Dictionary = Content.WEAPONS.get(pr.weapon, {})
		_damage_enemy(e, pr.dmg, src, pr.crit, pr.vel.normalized(), 20.0)
		if def.has("poison") and src:
			var tier := 1
			for w in src.weapons:
				if w["id"] == pr.weapon:
					tier = w["tier"]
			_apply_poison(e, def["poison"][tier - 1] * (1.0 + src.stats["status"] * 0.1), def["poison_time"], src.id)
		if def.has("splash"):
			for o in _query(pr.pos, def["splash"]):
				if o != e:
					_damage_enemy(o, pr.dmg * 0.5, src)
				_apply_slow(o, def["slow"], def["slow_time"])
			var h := SimHazard.new()
			h.type = Content.idx(Content.HAZARD_ORDER, "farbklecks")
			h.pos = pr.pos
			h.radius = def["splash"]
			h.life = 1.5
			h.max_life = 1.5
			hazards.append(h)
			pr.alive = false
			return
		if def.get("pfand_chance", 0.0) > 0.0 and rng.randf() < def["pfand_chance"]:
			_drop(Content.idx(Content.PICKUP_ORDER, "pfand"), e.pos, 1)
		if pr.bounce > 0:
			pr.bounce -= 1
			var next := _nearest_enemy(pr.pos, 260.0, pr.hit_ids)
			if next:
				pr.vel = (next.pos - pr.pos).normalized() * pr.vel.length()
				pr.life = maxf(pr.life, 0.6)
				return
		if pr.pierce > 0:
			pr.pierce -= 1
			continue
		pr.alive = false
		return


# --- Hazards -----------------------------------------------------------------

func _step_hazards(dt: float) -> void:
	var t_kleber := Content.idx(Content.HAZARD_ORDER, "kleber")
	var t_miet := Content.idx(Content.HAZARD_ORDER, "mietzone")
	var t_ker := Content.idx(Content.HAZARD_ORDER, "kerosin")
	var t_lob := Content.idx(Content.HAZARD_ORDER, "lob_marker")
	var t_sitz := Content.idx(Content.HAZARD_ORDER, "sitzblockade")
	var t_absch := Content.idx(Content.HAZARD_ORDER, "abschiebezone")
	var t_ring := Content.idx(Content.HAZARD_ORDER, "push_ring")
	for h in hazards:
		if not h.alive:
			continue
		h.life -= dt
		if h.type == t_ring:
			h.radius = (1.0 - h.life / h.max_life) * 900.0
			for p in players.values():
				if p.state == 0 and not h.data["hit"].has(p.id) and absf(p.pos.distance_to(h.pos) - h.radius) < 24.0:
					h.data["hit"][p.id] = true
					var away = (p.pos - h.pos).normalized()
					p.knock = (Vector2(0, -1) * 0.75 + away * 0.25).normalized() * 700.0
					damage_player(p, h.data["dmg"])
		elif h.type == t_kleber:
			for e in _query(h.pos, h.radius):
				_apply_slow(e, h.slow, 0.3)
				if not e.def.get("immune", false):
					e.poison_src = h.owner
					_damage_poison(e, h.dps * dt)
		elif h.type == t_miet:
			for p in players.values():
				if p.state == 0 and not p.flags.has("mietendeckel") and p.pos.distance_to(h.pos) < h.radius:
					p.mietzone_acc += dt
					if p.mietzone_acc >= 0.5:
						p.mietzone_acc = 0.0
						if p.pfand > 0:
							p.pfand -= 1
							meta_dirty = true
		elif h.type == t_ker or h.type == t_absch:
			for p in players.values():
				if p.state != 0:
					continue
				var inside = p.pos.distance_to(h.pos) < h.radius + Content.PLAYER_RADIUS
				if h.type == t_absch:
					inside = p.pos.y < WALL_BOTTOM + 70.0
				if inside and p.iframes <= 0.0:
					damage_player(p, h.dps * 0.5)
		elif h.type == t_lob and h.life <= 0.0:
			_explode(h.pos, h.radius, h.data.get("dmg", 5.0))
		elif h.type == t_sitz:
			for e in _query(h.pos, h.radius):
				_apply_slow(e, 0.5, 0.3)
		if h.life <= 0.0:
			h.alive = false


# --- Pickups -----------------------------------------------------------------

func _step_pickups(dt: float) -> void:
	var t_pfand := Content.idx(Content.PICKUP_ORDER, "pfand")
	var t_passant := Content.idx(Content.PICKUP_ORDER, "passant")
	var t_geld := Content.idx(Content.PICKUP_ORDER, "geldschein")
	var t_stulle := Content.idx(Content.PICKUP_ORDER, "stulle")
	var t_ausweis := Content.idx(Content.PICKUP_ORDER, "reichsausweis")
	# Stadtbild: passers-by join the crowd
	if _any_char("stadtbild"):
		_passant_timer -= dt
		if _passant_timer <= 0.0:
			_passant_timer = 6.0
			if pickups.filter(func(k): return k.type == t_passant).size() < 3:
				_drop(t_passant, Vector2(rng.randf_range(100, 1500), rng.randf_range(200, 900)), 1)
	for k in pickups:
		if not k.alive:
			continue
		if k.life > 0.0:
			k.life -= dt
			if k.life <= 0.0:
				k.alive = false
				if k.type == t_geld:
					for e in enemies:
						if e.alive and e.tid == "sauerlaender":
							e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.015)
				continue
		var best: SimPlayer = null
		var bd := INF
		for p in players.values():
			if p.state != 0:
				continue
			if k.type == t_passant and p.char_id != "stadtbild":
				continue
			var d: float = p.pos.distance_to(k.pos)
			if d < Content.PLAYER_BASE_PICKUP + p.stats["pickup"] and d < bd:
				bd = d
				best = p
		if best == null:
			continue
		k.pos = k.pos.move_toward(best.pos, 650.0 * dt)
		if k.pos.distance_to(best.pos) < 18.0:
			k.alive = false
			if k.type == t_pfand or k.type == t_geld:
				_give_pfand(best, k.value)
				_event(["sfx", "pickup", k.pos])
			elif k.type == t_passant:
				best.followers = mini(12, best.followers + 1)
				_event(["say", best.pos, "SAY_PASSANT_JOINS", ""])
				meta_dirty = true
			elif k.type == t_stulle:
				best.hp = minf(best.stats["max_hp"], best.hp + 3.0)
			elif k.type == t_ausweis:
				if not "reichsausweis" in best.items:
					best.items.append("reichsausweis")
					_recompute(best)
				_event(["say", best.pos, "SAY_REICHSAUSWEIS", ""])


# --- Organisation effects ----------------------------------------------------

func _step_org(dt: float) -> void:
	if org == "antifa":
		_sitz_timer -= dt
		if _sitz_timer <= 0.0:
			_sitz_timer = 20.0
			var h := SimHazard.new()
			h.type = Content.idx(Content.HAZARD_ORDER, "sitzblockade")
			h.pos = Vector2(rng.randf_range(400, 1200), rng.randf_range(350, 750))
			h.radius = 110.0
			h.life = 6.0
			h.max_life = 6.0
			hazards.append(h)


# --- Speech bubbles ----------------------------------------------------------

func _step_say(dt: float) -> void:
	_say_timer -= dt
	if _say_timer > 0.0 or enemies.is_empty():
		return
	_say_timer = SAY_INTERVAL + rng.randf_range(0.0, 2.0)
	for attempt in 6:
		var e: SimEnemy = enemies[rng.randi_range(0, enemies.size() - 1)]
		if not e.alive or e.behind or e.elite:
			continue
		var quotes := Quotes.ids_for("sprechblase:" + e.tid)
		var lines: Array = e.def.get("say", [])
		if not quotes.is_empty() and (lines.is_empty() or rng.randf() < 0.5):
			_say_quote(e.pos, quotes[rng.randi_range(0, quotes.size() - 1)])
			return
		if not lines.is_empty():
			_event(["say", e.pos, lines[rng.randi_range(0, lines.size() - 1)], ""])
			return


func _say_quote(pos: Vector2, quote_id: String) -> void:
	shown_quotes[quote_id] = true
	_event(["say", pos, "", quote_id])


func _event(ev: Array) -> void:
	events.append(ev)


func take_events() -> Array:
	var out := events
	events = []
	return out


# --- Shop & requests ---------------------------------------------------------

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


func _make_offers(p: SimPlayer) -> void:
	p.offers.clear()
	var count := 4 + int(_vertrag_def().get("offers", 0))
	for i in count:
		p.offers.append(_roll_offer(p))


func _roll_offer(p: SimPlayer) -> Dictionary:
	var luck: float = p.stats["luck"]
	var next_wave := wave + 1
	if rng.randf() < 0.35:
		var id: String = Content.WEAPON_ORDER[rng.randi_range(0, Content.WEAPON_ORDER.size() - 1)]
		var max_tier := 1 + int(next_wave >= 4) + int(next_wave >= 8) + int(next_wave >= 12)
		var weights := []
		var total := 0.0
		for t in range(1, max_tier + 1):
			var w := maxf(1.0, 10.0 - next_wave * 0.5) if t == 1 else (1.5 + next_wave * 0.3) / (t - 1)
			w *= 1.0 + luck / 100.0 * (t - 1) * 0.5
			weights.append(w)
			total += w
		var r := rng.randf() * total
		var tier := 1
		for t in weights.size():
			r -= weights[t]
			if r <= 0.0:
				tier = t + 1
				break
		return {"kind": "weapon", "id": id, "tier": tier, "price": _price(Content.weapon_price(id, tier, next_wave)), "sold": false}
	var pool := []
	var total_w := 0.0
	for id in Content.ITEM_ORDER:
		var d: Dictionary = Content.ITEMS[id]
		if d.get("no_shop", false) or (d.get("coop_only", false) and num_players() <= 1):
			continue
		var w := 0.0
		match int(d["rarity"]):
			1: w = 10.0
			2: w = 6.0 * (1.0 + luck / 200.0)
			3: w = 3.0 * (1.0 + luck / 100.0)
			_: w = 0.25
		pool.append([id, w])
		total_w += w
	var r2 := rng.randf() * total_w
	var pick: String = pool[0][0]
	for entry in pool:
		r2 -= entry[1]
		if r2 <= 0.0:
			pick = entry[0]
			break
	return {"kind": "item", "id": pick, "tier": 1, "price": _price(Content.item_price(pick, next_wave)), "sold": false}


func _price(base: int) -> int:
	var m = 1.0 + _vertrag_def().get("price", 0.0)
	if streik_discount:
		m *= 0.8
	return maxi(1, int(round(base * m)))


func _make_levelup_options(p: SimPlayer) -> void:
	p.levelup_options.clear()
	if p.levelups <= 0:
		return
	var stats := Content.STATS.duplicate()
	_shuffle(stats)
	for i in 4:
		p.levelup_options.append({"stat": stats[i], "amount": Content.LEVELUP_AMOUNTS[stats[i]]})


func _spend_limit(p: SimPlayer) -> int:
	if p.flags.has("schuldenbremse") and not p.flags.has("sondervermoegen"):
		return 30 + 10 * wave
	return -1


func _deny(p: SimPlayer, key: String) -> bool:
	_event(["deny", p.id, key])
	return false


## Applies a request from a player (architecture §5). Returns true on success.
func request(peer: int, action: String, arg = null) -> bool:
	var p: SimPlayer = players.get(peer)
	if p == null or p.state == 2:
		return false
	if action == "ultimate":
		if phase != Phase.WAVE or intro_wait or p.state != 0 or not p.ult_ready:
			return false
		_activate_ult(p)
		return true
	if action == "continue_intro":
		if intro_wait:
			intro_done[p.id] = true
			_check_intro_done()
		return true
	if action == "target_mode":
		p.target_mode = clampi(int(arg), 0, Target.size() - 1)
		return true
	if action == "streik":
		if phase == Phase.WAVE and streik_available:
			streik_available = false
			streik_active = STREIK_TIME
			streik_discount = true
			_event(["streik", STREIK_TIME])
			_event(["sfx", "streik", Vector2.INF])
			meta_dirty = true
			return true
		return false
	if phase != Phase.SHOP:
		return false
	meta_dirty = true
	match action:
		"buy":
			var i := int(arg)
			if i < 0 or i >= p.offers.size() or p.offers[i]["sold"]:
				return false
			var o: Dictionary = p.offers[i]
			if p.pfand < o["price"]:
				return _deny(p, "DENY_NO_PFAND")
			var limit := _spend_limit(p)
			if limit >= 0 and p.spent + o["price"] > limit:
				return _deny(p, "DENY_SPEND_LIMIT")
			if o["kind"] == "weapon":
				if p.weapons.size() >= p.max_weapons:
					return _deny(p, "DENY_SLOTS_FULL")
				p.weapons.append({"id": o["id"], "tier": o["tier"], "cd": 0.5, "angle": 0.0})
				p.bought_weapons += 1
			else:
				p.items.append(o["id"])
				if o["id"] == "vogelschiss":
					_grant(p, "ach_vogelschiss")
				_recompute(p)
			p.pfand -= o["price"]
			p.spent += o["price"]
			o["sold"] = true
			_event(["sfx", "buy", Vector2.INF])
			return true
		"reroll":
			var price := 0 if p.free_rerolls > 0 else Content.reroll_price(wave, p.rerolls_done)
			if p.pfand < price:
				return _deny(p, "DENY_NO_PFAND")
			if p.free_rerolls > 0:
				p.free_rerolls -= 1
			else:
				p.pfand -= price
				p.rerolls_done += 1
			_make_offers(p)
			return true
		"sell":
			var i := int(arg)
			if i < 0 or i >= p.weapons.size():
				return false
			if p.weapons.size() <= 1:
				return _deny(p, "DENY_LAST_WEAPON")
			var w: Dictionary = p.weapons[i]
			p.pfand += Content.sell_price(w["id"], w["tier"], wave + 1)
			p.weapons.remove_at(i)
			summons = summons.filter(func(s): return not (s.owner == p.id and s.weapon_index == i))
			return true
		"levelup":
			var i := int(arg)
			if p.levelups <= 0 or i < 0 or i >= p.levelup_options.size():
				return false
			var o: Dictionary = p.levelup_options[i]
			p.levelup_stats[o["stat"]] = p.levelup_stats.get(o["stat"], 0.0) + o["amount"]
			p.levelups -= 1
			_recompute(p)
			_make_levelup_options(p)
			return true
		"kasse_in":
			if not kasse_enabled():
				return false
			if p.pfand < KASSE_IN:
				return _deny(p, "DENY_NO_PFAND")
			p.pfand -= KASSE_IN
			kasse += KASSE_IN
			p.paid_in += KASSE_IN
			if p.paid_in >= 200:
				_grant(p, "ach_kassenwart")
			return true
		"kasse_out":
			if not kasse_enabled():
				return false
			if kasse < KASSE_OUT:
				return _deny(p, "DENY_KASSE_EMPTY")
			kasse -= KASSE_OUT
			p.pfand += kasse_payout()
			p.taken_out += KASSE_OUT
			return true
		"repair_wall_kasse":
			if not kasse_enabled():
				return false
			if wall.count(false) == 0:
				return _deny(p, "DENY_NOTHING_TO_REPAIR")
			var kprice := kasse_repair_price()
			if kasse < kprice:
				return _deny(p, "DENY_KASSE_EMPTY")
			kasse -= kprice
			_repair_one_hole()
			return true
		"vote":
			var i := int(arg)
			if vertrag["options"].is_empty() or i < 0 or i >= vertrag["options"].size():
				return false
			vertrag["votes"][p.id] = i
			_event(["sfx", "vote", Vector2.INF])
			return true
		"repair_wall":
			if wall.count(false) == 0:
				return _deny(p, "DENY_NOTHING_TO_REPAIR")
			var price := Content.repair_price(wave)
			if p.pfand < price:
				return _deny(p, "DENY_NO_PFAND")
			p.pfand -= price
			_repair_one_hole()
			return true
		"ready":
			p.ready = bool(arg)
			_check_all_ready()
			return true
	return false


## The Koalitionskasse only exists in co-op.
func kasse_enabled() -> bool:
	return num_players() > 1


func kasse_payout() -> int:
	return int(round(KASSE_OUT * (1.0 - KASSE_TAX)))


func kasse_repair_price() -> int:
	return int(round(Content.repair_price(wave) * (1.0 - KASSE_REPAIR_DISCOUNT)))


func _repair_one_hole() -> void:
	for i in WALL_SEGMENTS:
		if not wall[i]:
			wall[i] = true
			meta_dirty = true
			return


func _check_intro_done() -> void:
	if not intro_wait:
		return
	for p in players.values():
		if p.state != 2 and not intro_done.has(p.id):
			meta_dirty = true
			return
	intro_wait = false
	meta_dirty = true


func _check_all_ready() -> void:
	if phase != Phase.SHOP:
		return
	for p in players.values():
		if p.state != 2 and not p.ready:
			return
	streik_discount = false
	_begin_wave(wave + 1)


# --- Meta & view -------------------------------------------------------------

func build_meta() -> Dictionary:
	var pm := {}
	for p in players.values():
		var weapons := []
		for w in p.weapons:
			weapons.append({"id": w["id"], "tier": w["tier"]})
		pm[p.id] = {
			"name": p.name, "char": p.char_id, "pfand": p.pfand, "alive": p.state == 0,
			"stats": p.stats.duplicate(), "weapons": weapons, "max_weapons": p.max_weapons,
			"items": Array(p.items), "offers": p.offers.duplicate(true),
			"reroll_price": Content.reroll_price(wave, p.rerolls_done), "free_rerolls": p.free_rerolls,
			"spend_left": (_spend_limit(p) - p.spent) if _spend_limit(p) >= 0 else -1,
			"levelups": p.levelups, "levelup_options": p.levelup_options.duplicate(true),
			"ready": p.ready, "paid_in": p.paid_in, "taken_out": p.taken_out,
			"kills": p.kills, "damage": int(p.damage),
			"ult": Content.CHARACTERS[p.char_id].get("ult", ""), "ult_ready": p.ult_ready,
		}
	return {
		"wave": wave, "phase": phase, "org": org, "difficulty": difficulty, "blackrock": blackrock,
		"kasse": kasse, "kasse_enabled": kasse_enabled(), "kasse_in": KASSE_IN, "kasse_out": KASSE_OUT,
		"kasse_payout": kasse_payout(), "repair_price_kasse": kasse_repair_price(),
		"wall_holes": wall.count(false), "repair_price": Content.repair_price(wave),
		"streik": {"available": streik_available, "active": streik_active},
		"vertrag": vertrag.duplicate(true), "encounter": encounter,
		"intro_wait": intro_wait, "intro_done": intro_done.keys(),
		"team": {"level": team_level, "xp": team_xp, "need": Content.xp_for_level(team_level), "stage": stage},
		"num_players": num_players(), "players": pm, "result": result, "effects": effects.duplicate(),
	}


func build_view(vs: ViewState) -> void:
	vs.clear()
	vs.time = time
	vs.phase = phase
	vs.wave = wave
	vs.wave_time_left = maxf(0.0, wave_len - wave_time) if wave_len > 0.0 else -1.0
	vs.stage = stage
	var mask := 0
	for i in WALL_SEGMENTS:
		if wall[i]:
			mask |= 1 << i
	vs.wall = mask
	for p in players.values():
		var flags := 0
		if p.reversed > 0.0: flags |= ViewState.PF_REVERSED
		if p.stunned > 0.0: flags |= ViewState.PF_STUNNED
		if p.char_id == "klimakleber" and p.still_time >= 0.6: flags |= ViewState.PF_STILL
		if p.iframes > 0.0: flags |= ViewState.PF_INVULNERABLE
		if p.ult_t > 0.0 or p.dash_t > 0.0 or p.boost_t > 0.0: flags |= ViewState.PF_ULT
		if p.reviving: flags |= ViewState.PF_REVIVING
		var wb := PackedByteArray()
		for w in p.weapons:
			wb.append(Content.idx(Content.WEAPON_ORDER, w["id"]))
		vs.players.append({
			"id": p.id, "char": Content.idx(Content.CHAR_ORDER, p.char_id), "pos": p.pos,
			"hp": p.hp, "max_hp": p.stats["max_hp"], "state": p.state, "aim": p.aim,
			"flags": flags, "followers": p.followers, "weapons": wb, "seq": p.last_seq,
			"revive": p.revive_progress / REVIVE_TIME,
		})
	var boss_hp := 0.0
	var boss_max := 0.0
	var boss_phase := 0
	var boss_shield := 0.0
	for e in enemies:
		if not e.alive:
			continue
		vs.e_id.append(e.id)
		vs.e_type.append(e.type)
		vs.e_pos.append(e.pos)
		vs.e_hp.append(clampf(e.hp / e.max_hp, 0.0, 1.0))
		var f := 0
		if e.elite: f |= ViewState.EF_ELITE
		if e.poison_t > 0.0: f |= ViewState.EF_POISONED
		if e.slow_t > 0.0 or streik_active > 0.0 or e.stun_t > 0.0 or effects.has("antrag_gestellt"): f |= ViewState.EF_SLOWED
		if (e.def["ai"] == "charger" and e.state == 1) or (e.tid == "eidgenossin" and e.phase == 0 and e.state == 1) \
				or (e.tid == "geschichtslehrer" and e.state == 1):
			f |= ViewState.EF_WINDUP
		if (e.def["ai"] == "charger" and e.state == 3) or (e.def["ai"] == "voter" and e.state == 1):
			f |= ViewState.EF_PARKED
		if e.armored or e.shield > 0.0: f |= ViewState.EF_SHIELDED
		if e.buffed or e.vuln_t > 0.0: f |= ViewState.EF_BUFFED
		if e.hit_flash > 0.0: f |= ViewState.EF_HIT
		vs.e_flags.append(f)
		if e.encounter != "":
			boss_hp += maxf(0.0, e.hp)
			boss_max += e.max_hp
			boss_phase = e.phase
			if e.shield_max > 0.0:
				boss_shield = e.shield / e.shield_max
	if boss_max > 0.0:
		vs.boss = {"enc": Content.idx(Content.ENCOUNTER_ORDER, encounter), "hp": boss_hp / boss_max,
			"phase": boss_phase, "shield": boss_shield}
	for pr in projectiles:
		if pr.alive:
			vs.p_type.append(pr.type)
			vs.p_pos.append(pr.pos)
			vs.p_ang.append(pr.vel.angle())
	var spiegel := Content.idx(Content.PROJ_ORDER, "spiegel")
	for p in players.values():
		if p.state == 0:
			for pt in orbit_points(p):
				vs.p_type.append(spiegel)
				vs.p_pos.append(pt)
				vs.p_ang.append(0.0)
	for k in pickups:
		if k.alive:
			vs.k_type.append(k.type)
			vs.k_pos.append(k.pos)
	for h in hazards:
		if h.alive:
			vs.h_type.append(h.type)
			vs.h_pos.append(h.pos)
			vs.h_rad.append(h.radius)
			vs.h_life.append(clampf(h.life / h.max_life, 0.0, 1.0))
	for s in summons:
		if s.alive:
			vs.s_type.append(s.type)
			vs.s_pos.append(s.pos)
