class_name Sim
extends RefCounted
## Host-authoritative simulation (docs/GDD.md, docs/specs/architecture.md).
## Pure logic: no nodes, no engine physics. Runs identically in solo, listen
## server and dedicated server. All randomness comes from `rng` (seeded).

enum Phase { WAVE, SHOP, OVER }

## Geometry and Brandmauer tunables live in Arena (GDD §5a): a rectangle of four
## walls around the inner arena, AfD staging behind every side.
const ARENA := Arena.SIZE
const WALL_SEGMENTS := Arena.WALL_SEGMENTS
const CELL := 80.0
const GRID_W := 24                   # 24 * 80 >= Arena.SIZE.x
const GRID_H := 16                   # 16 * 80 >= Arena.SIZE.y
const INTRO_DELAY := 2.5
const IFRAMES := 0.5
const REVIVE_TIME := 2.5
const REVIVE_RANGE := 60.0
const SAY_INTERVAL := 3.5
const STREIK_TIME := 5.0
const DMG_EVENTS_PER_FRAME := 24
const STYLE_BIAS := 2.0             # shop: weapons matching your style weigh up to 1 + 2 (GDD §6)
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
	var state := 0                   # 0 alive, 1 downed, 2 gone, 3 away (connection lost, see set_away)
	var away_state := 0              # state to restore when an away player comes back
	var iframes := 0.0
	var aim := 0.0
	var still_time := 0.0
	var reversed := 0.0
	var reverse_axis := 0              # Wende: 0 both axes, 1 only left/right, 2 only up/down (D-112)
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
	var levelup_rerolls := 0           # paid level-up rerolls since the last pick (GDD §6)
	var collected_wave := 0            # Pfand picked up this wave (Reichensteuer, balancing.md §5a)
	var tax_wave := 0                  # Reichensteuer of the last wave: < 0 paid, > 0 received
	var spent := 0
	var buys := 0                      # purchases this Späti visit (Genossenschaftsanteil limit)
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
	var second_round_used := false     # Zweiter Wahlgang (once per run)
	var cumex_audited := false
	var coop_waves := 0                # Genossenschaftsanteil: wave ends held (dividend grows, D-129)
	var puma_down := false
	var ult_t := 0.0                   # Urlaubsantrag: lying on the sun lounger
	var dash_t := 0.0                  # Critical Mass dash
	var dash_dir := Vector2.ZERO
	var boost_t := 0.0                 # Critical Mass speed boost
	var regen_boost_t := 0.0           # Kaffee und Kuchen
	var next_wuid := 1                 # weapon instance ids (for damage stats)
	var dmg_total := {}                # source key -> damage dealt this run
	var dmg_wave := {}                 # source key -> damage dealt this wave
	var sources := {}                  # source key -> {"kind", "id", "tier", "sold"}
	var log := {
		"lifesteal": 0.0, "regen": 0.0, "sani": 0.0, "dmg_taken": 0.0, "dmg_blocked": 0.0, "dodges": 0,
		"crits": 0, "tax_paid": 0, "tax_received": 0, "pfand_collected": 0, "pfand_income": 0, "pfand_spent": 0, "ults": 0,
	}


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
	var poison_key := ""               # stats source of the poison/glue ticking on this enemy
	var expose_t := 0.0                # Enthüllungs-Scheinwerfer: extra crit chance against this enemy
	# Boss rules for encounter units (GDD §14, D-102 to D-112)
	var tempo := 1.0                   # Content.BOSS.phase_tempo of the current phase (movement, basic attacks)
	var presse_t := 0.0                # Pressekonferenz: invulnerable, walks to the middle
	var standfest_t := 0.0             # immune to stuns (covers the halved stun + Standfest time)
	var cast := ""                     # running cast (Content.BOSS_CASTS), "" = none
	var cast_t := 0.0                  # seconds into the cast
	var cast_time := 0.0               # cast length in seconds
	var cast_dmg := 0.0                # damage taken during the cast (Abstimmung threshold)
	var target_id := 0                 # random target player (D-103)
	var target_t := 0.0                # seconds until the next random pick
	var data := {}                     # per-boss ability state (vote segments, cooldowns, …)
	# v0.3 status effects (GDD §11, D-092); set only through the _apply_* helpers
	var silence_t := 0.0               # "In Bearbeitung" (Kleine Anfrage)
	var reverse_t := 0.0               # "Rolle rückwärts" (Faktencheck)
	var file_n := 0                    # Lobbyregister hits on file (0..max); "Aktenkundig" stacks unless immune
	var file_t := 0.0
	var sticker_t := 0.0               # Soli-Sticker poison, its own effect next to `poison`
	var sticker_dps := 0.0
	var sticker_src := 0
	var sticker_key := ""
	var sticker_cd := 0.0              # time until it passes a sticker on
	var sticker_free_at := 0.0         # passed-on stickers only after this sim time (no ping-pong)
	var no_reward := false
	var encounter := ""
	var vel := Vector2.ZERO            # smoothed velocity (px/s) for ground-weapon placement (place_mode lead)
	var last_pos := Vector2.ZERO


class SimProj:
	var source := ""                   # stats key of the weapon that fired it
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
	var ang := 0.0                   # direction of a cone (Kahlschlag), sent as h_ang (D-108)
	var data := {}
	var alive := true


class SimSummon:
	var source := ""
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
	var max_hp := 0.0                  # > 0: can be hurt (Pappkamerad), sent as s_hp
	var tier := 1
	var data := {}                     # per-kind state (chain anchor, orbit angle, hidden, …)
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
var _last_source := ""               # damage source of the current hit (Doppelwumms must not chain)
var encounter := ""
var encounter_pending := -1.0
var intro_wait := false              # boss card shown, world paused until everyone continues
var intro_done := {}
var skip_intro := false              # bots/tests
var retries := 0                     # Boss-Wiederholung used (balancing.md §8)
var last_encounter := ""             # encounter of the current/last boss wave (for a retry)
var encounters_beaten: Array[String] = []
## Cast of the current encounter (GDD §14, D-112), updated every tick; read by the
## balance bot (fire a stun ultimate when a cast starts) and mirrored in the snapshot.
var boss_cast := ""                  # Content.BOSS_CASTS id, "" = none
var boss_cast_t := 0.0               # progress 0..1
var boss_cast_left := 0.0            # seconds left
var _enc_max_hp := 0.0               # total max HP of the encounter's units (phase lock, D-106)
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
var _decoys: Array = []              # living Pappkameraden, refreshed every enemy step
var _stuck := {}                     # player id -> enemies with a Soli-Sticker (cap per player)
var _real_dt := 1.0 / 60.0           # this tick's dt without the phase tempo (boss abilities, D-106)
## Where ground weapons land (balancing.md §2 "Placement experiments", §9): target | lead | cluster | between.
var place_mode: String = Content.BALANCE["place"]
## Experiment only (balance_sim zonetime=): puddles and walls live k × as long at 1/k damage per second.
var zone_time_mult := 1.0


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
	# "Es gibt immer einen, der mit denen redet." One per player, max 4 (GDD §5a).
	for h in Arena.start_holes((cfg.get("players", []) as Array).size()):
		wall[h] = false
	_grid.resize(GRID_W * GRID_H)
	for pd in cfg.get("players", []):
		var p := SimPlayer.new()
		p.id = int(pd["id"])
		p.name = pd.get("name", "")
		p.char_id = pd.get("char", "stadtbild")
		if not Content.CHARACTERS.has(p.char_id):
			p.char_id = "stadtbild"
		var c: Dictionary = Content.CHARACTERS[p.char_id]
		_add_weapon(p, c["weapon"], 1)
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
		_check_all_ready()
		_check_game_over()


## Co-op: a client lost its connection (networking.md §7.4). An away player
## (state 3) keeps its character, frozen and invulnerable; enemies ignore it,
## it doesn't block the Späti ready check or the boss intro, and going away never
## causes a game over (see _check_game_over). If it doesn't come back, the host
## calls remove_player().
func set_away(id: int, away: bool) -> void:
	var p: SimPlayer = players.get(id)
	if p == null or p.state == 2 or (p.state == 3) == away:
		return
	if away:
		p.away_state = p.state
		p.state = 3
		p.input = Vector2.ZERO
		p.knock = Vector2.ZERO
		p.reviving = false
		p.revive_progress = 0.0
		_event(["away", id])
	else:
		p.state = p.away_state
		if p.state == 0:
			p.iframes = maxf(p.iframes, 1.5)
		_event(["back", id])
	meta_dirty = true
	_check_intro_done()
	_check_all_ready()
	_check_game_over()


## True while nobody is alive but at least one player is away: the world waits
## for the reconnect (or for remove_player, which then ends the run).
func waiting_for_away() -> bool:
	var away := false
	for p in players.values():
		if p.state == 0:
			return false
		if p.state == 3:
			away = true
	return away


## Players who are in the game right now: alive or downed (not gone, not away).
func _present_count() -> int:
	var n := 0
	for p in players.values():
		if p.state == 0 or p.state == 1:
			n += 1
	return n


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
	if p.flags.has("dodge_build"):
		s["armor"] = 0.0
	if p.flags.has("lifesteal_build"):
		# Robin-Hood-Kostüm: Krankenschein counts as Umverteilung (D-134)
		s["lifesteal"] += maxf(0.0, s["hp_regen"])
		s["hp_regen"] = 0.0
	s["max_hp"] = maxf(1.0, s["max_hp"])
	p.max_weapons = int(Content.CHARACTERS[p.char_id].get("max_weapons", Content.MAX_WEAPONS)) + p.items.count("lastenrad_anhaenger")
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
	# inside the Brandmauer rectangle on all four sides (GDD §5a)
	return Arena.clamp_inner(pos, Content.PLAYER_RADIUS)


# --- Main loop ---------------------------------------------------------------

func step(dt: float) -> void:
	time += dt
	if phase != Phase.WAVE or intro_wait or waiting_for_away():
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

func _begin_wave(n: int, force_encounter := "") -> void:
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
		if p.state == 3:
			p.away_state = 0
		else:
			p.state = 0
		_recompute(p)
		p.hp = p.stats["max_hp"]
		var ang := TAU * i / maxf(1, alive.size())
		p.pos = Arena.CENTER + (Vector2.RIGHT.rotated(ang) * 60.0 if alive.size() > 1 else Vector2.ZERO)
		p.knock = Vector2.ZERO
		p.reversed = 0.0
		p.reverse_axis = 0
		p.stunned = 0.0
		p.pending_shots.clear()
		p.dmg_wave.clear()
		p.collected_wave = 0
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
	boss_cast = ""
	boss_cast_t = 0.0
	boss_cast_left = 0.0
	_enc_max_hp = 0.0
	if Content.ENCOUNTER_POOLS.has(n):
		var pool: Array = Content.ENCOUNTER_POOLS[n]
		encounter = force_encounter if force_encounter != "" else pool[rng.randi_range(0, pool.size() - 1)]
		last_encounter = encounter
		encounter_pending = INTRO_DELAY
		intro_wait = not skip_intro
		intro_done = {}
		_event(["card", encounter])
	if org == "omas" and summons.is_empty():
		var s := SimSummon.new()
		s.type = Content.idx(Content.SUMMON_ORDER, "oma")
		s.pos = Arena.CENTER + Vector2(-40, 40)
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
	boss_cast = ""
	boss_cast_t = 0.0
	boss_cast_left = 0.0
	for k in pickups:
		if k.alive and k.type == Content.idx(Content.PICKUP_ORDER, "pfand"):
			var p := _nearest_player(k.pos, true)
			if p:
				_give_pfand(p, k.value)
	pickups.clear()
	_apply_reichensteuer()
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
			p.log["pfand_income"] += income
		if p.flags.has("treuhand") and rng.randf() < Content.RED_BUILD["treuhand_chance"] + p.stats["luck"] / 200.0:
			_give_pfand(p, Content.RED_BUILD["treuhand_pfand"])
			p.log["pfand_income"] += Content.RED_BUILD["treuhand_pfand"]
		if p.flags.has("maut"):
			p.pfand = maxi(0, p.pfand - Content.RED_BUILD["maut_wave"])
		if p.flags.has("cumex"):
			# the cap grows with the prices, so it keeps its value late in the run (D-130)
			var refund := mini(int(round(Content.RED_BUILD["cumex_max"] * Content.price_mult(wave + 1))), p.pfand)
			_give_pfand(p, refund)
			p.log["pfand_income"] += refund
			if wave >= Content.RED_BUILD["cumex_audit_wave"] and not p.cumex_audited:
				p.cumex_audited = true
				p.pfand = p.pfand / 2
				_event(["say", p.pos, "SAY_BETRIEBSPRUEFUNG", ""])
		if p.flags.has("coop_economy"):
			var interest := coop_dividend(p)
			p.coop_waves += 1
			_give_pfand(p, interest)
			p.log["pfand_income"] += interest
		if p.flags.has("streikkasse"):
			_give_pfand(p, mini(20, int(p.pfand * 0.1)))
		if blackrock:
			p.pfand = int(p.pfand * 0.95)
		if p.flags.has("taugenichts"):
			var stat: String = Content.STATS[rng.randi_range(0, Content.STATS.size() - 1)]
			p.levelup_stats[stat] = p.levelup_stats.get(stat, 0.0) + Content.LEVELUP_AMOUNTS[stat]
			_recompute(p)
		if p.state == 3:
			p.away_state = 0
		else:
			p.state = 0
		p.spent = 0
		p.buys = 0
		p.rerolls_done = 0
		p.levelup_rerolls = 0
		p.free_rerolls = int(Content.CHARACTERS[p.char_id].get("free_rerolls", 0))
		p.ready = false
		p.levelups += Content.levelups_after_wave(wave)
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
	vertrag = {"options": [], "votes": {}, "active": chosen, "waves_left": 4 if chosen != "" else 0}
	for p in players.values():
		_recompute(p)
	if chosen != "":
		_event(["say", Arena.CENTER - Vector2(0, 100), "VERTRAG_%s_NAME" % chosen.to_upper(), ""])


## Unanimous vote picks that option, otherwise the worst one (exposed for tests).
## Abstentions (-1) and missing votes don't count. Nobody voted -> no contract.
## All votes equal -> that option. Otherwise the worst option wins.
static func resolve_votes(options: Array, votes: Dictionary, voters: Array) -> String:
	var cast := []
	for v in voters:
		if votes.has(v) and int(votes[v]) >= 0 and int(votes[v]) < options.size():
			cast.append(int(votes[v]))
	if cast.is_empty():
		return ""
	if cast.all(func(c): return c == cast[0]):
		return options[cast[0]]
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
	var b := Content.BALANCE
	var rate = (float(b["spawn_base"]) + float(b["spawn_lin"]) * wave) * diff["spawn"] * (1.0 + b["coop_spawn"] * (n - 1))
	if encounter != "" and _encounter_alive():
		rate *= Content.BALANCE["boss_wave_spawn"]
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
	# a group stands side by side along its wall
	var sideways := Arena.staging_side(base) % 2 == 1 and not Arena.is_inside(base, 0.0)
	for i in count:
		var jit := Vector2(rng.randf_range(-30, 30), rng.randf_range(-10, 10))
		spawn_enemy(pick, base + (Vector2(jit.y, jit.x) if sideways else jit))


## Spawn positions (GDD §5a): AfD behind any of the four walls (sides with holes
## weigh more), Union/Kapital just inside the wall on any side, away from players.
func _spawn_pos(tid: String) -> Vector2:
	var d: Dictionary = Content.ENEMIES[tid]
	if d["faction"] == "afd":
		return _staging_spawn_pos()
	if d["ai"] == "flyer":
		var left := rng.randf() < 0.5
		return Vector2(-40 if left else ARENA.x + 40, rng.randf_range(Arena.INNER.position.y + 100, Arena.INNER.end.y - 100))
	var edge := Arena.INNER.grow(-float(Arena.WALL["inner_spawn_inset"]))
	var best := Arena.perimeter_point(edge, 0.0)
	for attempt in 8:
		var p := Arena.perimeter_point(edge, rng.randf() * Arena.perimeter(edge))
		best = p
		var ok := true
		for pl in players.values():
			if pl.state == 0 and pl.pos.distance_to(p) < 260:
				ok = false
		if ok:
			break
	return best


## A point on the staging line behind a wall. Side weight: base + per hole on
## that side (Arena.WALL), so every side gets spawns and sides with holes more.
func _staging_spawn_pos() -> Vector2:
	var w := Arena.side_weights(wall)
	var total := 0.0
	for x in w:
		total += x
	var r := rng.randf() * total
	var side := 3
	for i in 4:
		r -= w[i]
		if r < 0.0:
			side = i
			break
	return Arena.staging_point(side, rng.randf())


func spawn_enemy(tid: String, pos: Vector2, elite_scale := 1.0) -> SimEnemy:
	var d: Dictionary = Content.ENEMIES[tid]
	var e := SimEnemy.new()
	e.id = _next_id
	_next_id += 1
	e.tid = tid
	e.type = Content.idx(Content.ENEMY_ORDER, tid)
	e.def = d
	e.pos = pos
	e.last_pos = pos
	e.radius = d["radius"]
	var vh: float = 1.0 + _vertrag_def().get("enemy_hp", 0.0)
	var vd: float = 1.0 + _vertrag_def().get("enemy_dmg", 0.0)
	var vs: float = 1.0 + _vertrag_def().get("enemy_speed", 0.0)
	if d["faction"] == "elite":
		e.elite = true
		# Elites grow with the waves like the other enemies, relative to wave 5 (balancing.md §7).
		var grow := pow(Content.enemy_hp_curve(wave) / Content.enemy_hp_curve(5), float(Content.BALANCE["elite_wave_exp"]))
		e.max_hp = d["hp"] * diff["hp"] * elite_scale * maxf(1.0, grow)
		e.dmg = d["dmg"] * diff["dmg"] * vd * (1.0 + 0.03 * (wave - 1))
	else:
		var w := float(wave - 1)
		var b := Content.BALANCE
		var coop := 1.0 + float(b["coop_hp"]) * (num_players() - 1)
		e.max_hp = d["hp"] * Content.enemy_hp_curve(wave) * diff["hp"] * vh * coop
		e.dmg = d["dmg"] * (b["dmg_base"] + b["dmg_lin"] * w) * diff["dmg"] * vd
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
	var units: Array = enc["units"]
	_enc_max_hp = 0.0
	for i in units.size():
		var pos := Arena.CENTER + Vector2(0, -230)
		if units.size() > 1:
			pos = Vector2(Arena.CENTER.x + (i - (units.size() - 1) * 0.5) * 330.0, Arena.INNER.end.y - 120.0)
		var e := spawn_enemy(units[i], pos, encounter_hp_scale(encounter))
		e.encounter = encounter
		e.behind = false
		_enc_max_hp += e.max_hp
		if e.tid == "eidgenossin":
			_place_turbines()
	var q := Quotes.random_for("boss_ruf:" + encounter, rng)
	if q != "":
		shown_quotes[q] = true   # collected for the Album; not shown as a bubble mid-fight
	meta_dirty = true


## HP factor of an encounter's units on top of the elite HP (balancing.md §7, D-102):
## co-op (elite_base + elite_coop·(players − 1)) × boss Umfrage (1 + diff_boss_hp·L)
## × the encounter's hp_mult × final_boss_mult for Die Remigrantin.
func encounter_hp_scale(enc_id: String) -> float:
	var b := Content.BALANCE
	var enc: Dictionary = Content.ENCOUNTERS[enc_id]
	var scale := float(b["elite_base"]) + float(b["elite_coop"]) * (num_players() - 1)
	scale *= 1.0 + float(b["diff_boss_hp"]) * difficulty
	scale *= float(enc.get("hp_mult", 1.0))
	if enc_id == "eidgenossin":
		scale *= float(b["final_boss_mult"])
	return scale


func _place_turbines() -> void:
	for o in [Vector2(-420, -230), Vector2(420, -230), Vector2(-420, 210), Vector2(420, 210)]:
		var p: Vector2 = Arena.CENTER + o
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
			dir = reverse_dir(dir, p.reverse_axis)
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
			if not p.flags.has("lifesteal_build"):
				_heal(p, p.stats["hp_regen"] * 0.08 * dt, "regen")
		if p.flags.has("aufhoeren") and p.still_time >= Content.RED_BUILD["aufhoeren_after"] and not p.flags.has("lifesteal_build"):
			_heal(p, Content.RED_BUILD["aufhoeren_regen"] * 0.12 * dt, "regen")
		# damage multiplier for this frame
		var m := 1.0
		match p.char_id:
			"stadtbild":
				m += 0.03 * p.followers
			"klimakleber":
				if p.still_time >= 0.6:
					m += 0.8   # GDD §8: +80 % while standing still
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


## Reversed controls ("Wende um 180 Grad"): axis 0 flips both, 1 only left/right,
## 2 only up/down (Teilwende, D-112). Host and client prediction both use this.
static func reverse_dir(dir: Vector2, axis: int) -> Vector2:
	if axis == 1:
		return Vector2(-dir.x, dir.y)
	if axis == 2:
		return Vector2(dir.x, -dir.y)
	return -dir


## Teilwende axis from a player's view flags (PF_REVERSE_X / PF_REVERSE_Y).
static func reverse_axis_of(flags: int) -> int:
	if flags & ViewState.PF_REVERSE_X:
		return 1
	if flags & ViewState.PF_REVERSE_Y:
		return 2
	return 0


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
		if not s.alive or Content.SUMMON_ORDER[s.type] in NOT_ALLIES:
			continue
		if (s.owner == p.id or s.type == Content.idx(Content.SUMMON_ORDER, "oma")) and s.pos.distance_to(p.pos) <= r:
			n += 1
	return n


## Summons that always stay next to their owner don't count as allies nearby
## (Gewerkschaft passive, Zusammenhalt bonus), D-094.
const NOT_ALLIES := ["laterne", "sani", "lauti"]


func _ram(p: SimPlayer) -> void:
	var dmg = (4.0 + p.stats["speed"] * 0.1) * maxf(0.1, 1.0 + p.stats["damage"] / 100.0) * p.dmg_mult
	for e in _query(p.pos, Content.PLAYER_RADIUS + 4.0):
		var key := "ram%d" % p.id
		if e.hit_cd.get(key, 0.0) <= time:
			e.hit_cd[key] = time + 0.4
			_damage_enemy(e, dmg, p, false, (e.pos - p.pos).normalized(), 80.0, "ram")


func _antifa_repair(p: SimPlayer, dt: float) -> void:
	# a hole on any of the four walls, within reach (GDD §5a)
	var seg := Arena.facing_seg(p.pos)
	if Arena.edge_dist(p.pos) > float(Arena.WALL["repair_reach"]) or seg < 0 or wall[seg]:
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
		d.revive_progress += dt * (Content.WEAPONS["demo_sanis"]["revive"] if _sani_near(d.pos) else 1.0)
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
	if rng.randf() * 100.0 < minf(p.stats["dodge"], Content.RED_BUILD["dodge_cap"] if p.flags.has("dodge_build") else Content.DODGE_CAP):
		_event(["say", p.pos, "SAY_DODGE", ""])
		p.log["dodges"] += 1
		p.iframes = 0.2
		return
	var armor: float = p.stats["armor"]
	if p.flags.has("aufhoeren") and p.still_time >= Content.RED_BUILD["aufhoeren_after"]:
		armor += Content.RED_BUILD["aufhoeren_armor"]
	var dmg := amount * (15.0 / (15.0 + armor) if armor >= 0.0 else 1.0 - armor * 0.05)
	dmg = maxf(1.0, dmg)
	p.log["dmg_taken"] += dmg
	p.log["dmg_blocked"] += maxf(0.0, amount - dmg)
	p.hp -= dmg
	p.iframes = IFRAMES
	_event(["dmg", p.pos, int(round(dmg)), false, true])
	_event(["sfx", "hurt", p.pos])
	if p.hp <= 0.0 and p.flags.has("zweiter_wahlgang") and not p.second_round_used:
		p.second_round_used = true
		p.hp = p.stats["max_hp"] * Content.RED_BUILD["second_round_hp"]
		p.iframes = 1.5
		_event(["say", p.pos, "SAY_ZWEITER_WAHLGANG", ""])
		meta_dirty = true
		return
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
	# A lost connection alone never ends the run: while someone is away the world
	# waits (waiting_for_away); only remove_player after the grace period counts.
	for p in players.values():
		if p.state == 0 or p.state == 3:
			return
	if bool(config.get("boss_retry", false)) and Content.ENCOUNTER_POOLS.has(wave):
		_retry_wave()
		return
	_finish(false)


## Boss-Wiederholung (balancing.md §8): the lost elite/boss wave starts over with
## the same encounter; everyone is back with full HP, gear and Pfand stay.
func _retry_wave() -> void:
	retries += 1
	var enc := encounter
	if enc == "":
		enc = last_encounter
	for p in players.values():
		if p.state == 1 or p.state == 2:
			p.state = 0
	_begin_wave(wave, enc)
	_event(["say", Arena.CENTER - Vector2(0, 100), "SAY_BOSS_RETRY", ""])


# --- Weapons -----------------------------------------------------------------

func _step_weapons(dt: float) -> void:
	for p in players.values():
		if p.state != 0:
			continue
		var as_mult := maxf(0.2, 1.0 + (p.stats["attack_speed"] + dyn_attack_speed(p)) / 100.0)
		# Puma: every 18 s all weapons fail for 3 s.
		if p.flags.has("puma"):
			var down: bool = fmod(wave_time, Content.RED_BUILD["puma_period"]) >= Content.RED_BUILD["puma_period"] - Content.RED_BUILD["puma_down"]
			if down and not p.puma_down:
				_event(["say", p.pos, "SAY_PUMA_AUSFALL", ""])
			p.puma_down = down
			if down:
				continue
		for wi in p.weapons.size():
			var w: Dictionary = p.weapons[wi]
			var def: Dictionary = Content.WEAPONS[w["id"]]
			if def["kind"] == "orbit":
				_step_orbit(p, w, def, dt)
				continue
			w["cd"] -= dt * as_mult
			if w["cd"] > 0.0:
				continue
			if def["kind"] == "trail":
				w["cd"] = def["cd"]
				_lay_chalk(p, w, def)
				continue
			if def["kind"] in Content.UNTARGETED_KINDS:
				# summons that need no target (GDD §11 v0.3): the lamppost goes toward
				# the nearest enemy if there is one, else along the aim
				w["cd"] = def["cd"]
				var near := _nearest_enemy(p.pos, _weapon_range(p, def) + 200.0)
				var udir: Vector2 = (near.pos - p.pos).normalized() if near else Vector2.RIGHT.rotated(p.aim)
				_fire(p, w, udir, near.pos if near else Vector2.INF)
				continue
			var rng_r := _weapon_range(p, def)
			var target := _pick_target(p.pos, rng_r, p.target_mode)
			if def.get("prefer_ability", false):
				var busy := _ability_target(p.pos, rng_r)
				if busy:
					target = busy
			if target == null:
				w["cd"] = 0.05
				continue
			w["cd"] = def["cd"]
			var aim_at: Vector2 = target.pos
			if def["kind"] in Content.PLACED_KINDS:
				aim_at = _place_point(p, def, target, rng_r)
			var dir = (aim_at - p.pos).normalized()
			w["angle"] = dir.angle()
			p.aim = dir.angle()
			p.last_fire = time
			if p.flags.has("fax"):
				p.pending_shots.append({"t": 3.0, "w": wi, "dir": dir})
			else:
				_fire(p, w, dir, aim_at)


## Straßenkreide: a chalk mark at the player's feet; standing still renews the
## last mark instead of stacking new ones (GDD §11).
func _lay_chalk(p: SimPlayer, w: Dictionary, def: Dictionary) -> void:
	var t_kreide := Content.idx(Content.HAZARD_ORDER, "kreide")
	var key := _wkey(w)
	for h in hazards:
		if h.alive and h.type == t_kreide and h.owner == p.id and h.data.get("src", "") == key \
				and h.pos.distance_to(p.pos) < def["spacing"]:
			h.life = h.max_life
			# standing still draws a chalk circle around you (GDD §11)
			h.radius = minf(float(def.get("still_radius", def["radius"])), h.radius + float(def.get("still_grow", 0.0)))
			return
	var mark := SimHazard.new()
	mark.type = t_kreide
	mark.pos = p.pos
	mark.radius = def["radius"]
	mark.life = def["life"]
	mark.max_life = mark.life
	mark.dps = weapon_damage(p, w) * (Content.RED_BUILD["status"] / Content.RED_BUILD["status_direct"] if p.flags.has("status_build") else 1.0)
	mark.owner = p.id
	mark.data = {"src": key}
	hazards.append(mark)


## Genossenschaftsanteil (GDD §12, D-129): the dividend at this wave end. The rate grows
## with every wave end the share was held; it is capped at what a new share costs in the
## coming Späti, so it keeps its value while prices grow.
func coop_dividend(p: SimPlayer) -> int:
	var b := Content.RED_BUILD
	var rate := minf(b["coop_rate_max"], b["coop_rate"] + b["coop_rate_step"] * p.coop_waves)
	var cap := _price(Content.item_price("genossenschaftsanteil", wave + 1))
	return mini(cap, int(p.pfand * rate))


## Wahlversprechen and BER-Eröffnungstermin change Wut over time.
func dyn_damage(p: SimPlayer) -> float:
	var b := Content.RED_BUILD
	var d := 0.0
	if p.flags.has("wahlversprechen"):
		d += b["wahl_early"] if wave_time < b["wahl_time"] else b["wahl_late"]
	if p.flags.has("ber"):
		d += b["ber_early"] if wave < b["ber_wave"] else b["ber_late_dmg"]
	return d


func dyn_attack_speed(p: SimPlayer) -> float:
	if p.flags.has("ber") and wave >= Content.RED_BUILD["ber_wave"]:
		return Content.RED_BUILD["ber_late_as"]
	return 0.0


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
	d *= maxf(0.1, 1.0 + (p.stats["damage"] + dyn_damage(p)) / 100.0) * p.dmg_mult
	d *= _build_mult(p, def)
	return maxf(1.0, d)


## Red build items (GDD §12): big boost for one build, malus for everything else.
func _build_mult(p: SimPlayer, def: Dictionary) -> float:
	var b := Content.RED_BUILD
	var m := 1.0
	var melee: bool = def.get("melee", false)
	if p.flags.has("melee_build"):
		m *= b["melee"] if melee else b["melee_other"]
	if p.flags.has("ranged_build"):
		if melee:
			m *= b["ranged_other"]
		elif def["scale"].has("ranged"):
			m *= b["ranged"]   # every Durchschlagskraft weapon (D-128)
	if p.flags.has("summon_build"):
		m *= b["summon"] if def["scale"].has("summon") else b["summon_other"]   # every Ehrenamt weapon (D-114)
	if p.flags.has("status_build"):
		m *= b["status_direct"]
	return m


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
			pr.source = _wkey(w)
			pr.life = _weapon_range(p, def) / def["speed"] * (2.2 if def.get("boomerang", false) else 1.15)
			pr.pierce = def.get("pierce", 0)
			if p.flags.has("ranged_build"):
				pr.pierce += Content.RED_BUILD["ranged_pierce"]
				pr.vel *= Content.RED_BUILD["ranged_speed"]
			pr.bounce = def.get("bounce", 0) + (w["tier"] - 1 if w["id"] == "gendersternchen" else 0)
			pr.boomerang = def.get("boomerang", false)
			projectiles.append(pr)
			_event(["sfx", "shoot", p.pos])
		"cone":
			var r := _weapon_range(p, def)
			var half := deg_to_rad(def["arc"]) / 2.0
			var in_cone := []
			for e in _query(p.pos, r):
				if e.behind and shot_blocked(p.pos, e.pos):
					continue
				var to: Vector2 = e.pos - p.pos
				if def["arc"] >= 360.0 or absf(angle_difference(dir.angle(), to.angle())) <= half + 0.15:
					in_cone.append(e)
			# `max_hits` (Faktencheck): damage only the nearest few, the effect hits all (crowd cap, D-091)
			var hits: int = def.get("max_hits", in_cone.size())
			if hits < in_cone.size():
				in_cone.sort_custom(func(a, b): return a.pos.distance_squared_to(p.pos) < b.pos.distance_squared_to(p.pos))
			for k in in_cone.size():
				var e: SimEnemy = in_cone[k]
				if k < hits:
					_damage_enemy(e, dmg, p, crit, (e.pos - p.pos).normalized(), def.get("knock", 0.0), _wkey(w))
				if def.has("stun") and not e.elite:
					_apply_stun(e, def["stun"])
				if def.has("reverse"):
					_apply_reverse(e, def["reverse"][w["tier"] - 1])
			if def.get("clear_shots", false):
				# Faktencheck wipes enemy projectiles inside the cone (GDD §11)
				for pr in projectiles:
					if pr.alive and pr.owner == 0 and not pr.harmless and pr.pos.distance_to(p.pos) <= r \
							and absf(angle_difference(dir.angle(), (pr.pos - p.pos).angle())) <= half + 0.15:
						pr.alive = false
			_event(["swing", p.pos, dir.angle(), r, def["arc"], w["id"]])
			_event(["sfx", "melee", p.pos])
		"puddle":
			var h := SimHazard.new()
			h.type = Content.idx(Content.HAZARD_ORDER, "kleber")
			h.pos = target_pos if target_pos != Vector2.INF else p.pos + dir * 150.0
			h.radius = def["radius"]
			h.life = def["life"] * zone_time_mult
			h.max_life = h.life
			h.dps = dmg * (Content.RED_BUILD["status"] / Content.RED_BUILD["status_direct"] if p.flags.has("status_build") else 1.0) / zone_time_mult
			h.slow = def["slow"]
			h.owner = p.id
			h.data = {"src": _wkey(w)}
			hazards.append(h)
			_event(["sfx", "shoot", p.pos])
		"lob":
			var at: Vector2 = target_pos if target_pos != Vector2.INF else p.pos + dir * def["range"]
			var h := SimHazard.new()
			h.type = Content.idx(Content.HAZARD_ORDER, "brei_marker")
			h.pos = at
			h.radius = def["radius"]
			h.life = def["delay"]
			h.max_life = def["delay"]
			h.owner = p.id
			h.data = {"dmg": dmg, "crit": crit, "src": _wkey(w)}
			hazards.append(h)
			var pr := SimProj.new()
			pr.type = Content.idx(Content.PROJ_ORDER, def["proj"])
			pr.pos = p.pos
			pr.vel = (at - p.pos) / def["delay"]
			pr.life = def["delay"]
			pr.harmless = true
			pr.owner = p.id
			projectiles.append(pr)
			_event(["sfx", "shoot", p.pos])
		"wall":
			var at: Vector2 = target_pos if target_pos != Vector2.INF else p.pos + dir * def["range"]
			var wid := _wkey(w)
			var old := hazards.filter(func(x): return x.data.get("src", "") == wid and x.type == Content.idx(Content.HAZARD_ORDER, "ziegel"))
			var walls := {}
			for x in old:
				walls[x.data.get("wall", 0)] = true
			if walls.size() >= int(def["max"]):
				var oldest: int = walls.keys().min()
				for x in old:
					if x.data.get("wall", 0) == oldest:
						x.alive = false
			var wall_id := int(time * 1000.0)
			var across := dir.orthogonal()
			for k in 5:
				var h := SimHazard.new()
				h.type = Content.idx(Content.HAZARD_ORDER, "ziegel")
				h.pos = at + across * (k - 2) * (def["width"] / 4.0)
				h.radius = 20.0
				h.life = def["life"] * zone_time_mult * (Content.RED_BUILD["summon_life"] if p.flags.has("summon_build") else 1.0)
				h.max_life = h.life
				h.dps = dmg * 2.0 / zone_time_mult
				h.slow = def["slow"]
				h.owner = p.id
				h.data = {"src": wid, "wall": wall_id}
				hazards.append(h)
			_event(["sfx", "melee", p.pos])
		"mark":
			var strongest := _pick_target(p.pos, _weapon_range(p, def), Target.MOST_HP)
			if strongest:
				var h := SimHazard.new()
				h.type = Content.idx(Content.HAZARD_ORDER, "paragraf")
				h.pos = strongest.pos
				h.radius = strongest.radius + 10.0
				h.life = def["delay"]
				h.max_life = def["delay"]
				h.owner = p.id
				h.data = {"dmg": dmg, "crit": crit, "src": _wkey(w), "enemy": strongest.id}
				hazards.append(h)
				_event(["sfx", "vote", strongest.pos])
		"chain":
			var hit := {}
			var cur := _nearest_enemy(p.pos, _weapon_range(p, def))
			var pts := [p.pos]
			var d := dmg
			for k in int(def["jumps"]) + 1:
				if cur == null:
					break
				hit[cur.id] = true
				pts.append(cur.pos)
				_damage_enemy(cur, d, p, crit, Vector2.ZERO, 0.0, _wkey(w))
				d *= 1.0 - def["falloff"]
				cur = _nearest_enemy(cur.pos, def["jump_range"], hit)
			_event(["chain", pts])
			_event(["sfx", "shoot", p.pos])
		"thrust":
			# Demo-Fahnenstange: a straight jab, hits everything in a narrow line.
			var reach := _weapon_range(p, def)
			var tip: Vector2 = p.pos + dir * reach
			for e in _query((p.pos + tip) * 0.5, reach * 0.5 + def["width"] + 40.0):
				if e.behind and shot_blocked(p.pos, e.pos):
					continue
				var closest := Geometry2D.get_closest_point_to_segment(e.pos, p.pos, tip)
				if closest.distance_to(e.pos) <= def["width"] + e.radius:
					_damage_enemy(e, dmg, p, crit, dir, def.get("knock", 0.0), _wkey(w))
			_event(["swing", p.pos, dir.angle(), reach, def["arc"], w["id"]])
			_event(["sfx", "melee", p.pos])
		"beam":
			var to: Vector2 = p.pos + dir * _weapon_range(p, def)
			for e in _query((p.pos + to) * 0.5, _weapon_range(p, def) * 0.5 + def["width"]):
				if e.behind and shot_blocked(p.pos, e.pos):
					continue
				var closest := Geometry2D.get_closest_point_to_segment(e.pos, p.pos, to)
				if closest.distance_to(e.pos) <= def["width"] + e.radius:
					_damage_enemy(e, dmg, p, crit, dir, 10.0, _wkey(w))
					e.expose_t = def["expose"]
			_event(["beam", p.pos, to])
			_event(["sfx", "shoot", p.pos])
		"fan":
			var count: int = def["count_late"] if wave >= int(def["late_wave"]) else def["count"]
			var half := deg_to_rad(def["arc"]) / 2.0
			for k in count:
				var a := dir.angle() - half + (2.0 * half) * k / maxf(1, count - 1)
				var pr := SimProj.new()
				pr.type = Content.idx(Content.PROJ_ORDER, def["proj"])
				pr.pos = p.pos + Vector2.RIGHT.rotated(a) * 18.0
				pr.vel = Vector2.RIGHT.rotated(a) * def["speed"]
				pr.dmg = dmg
				pr.crit = crit
				pr.owner = p.id
				pr.weapon = w["id"]
				pr.source = _wkey(w)
				pr.life = _weapon_range(p, def) / def["speed"]
				if p.flags.has("ranged_build"):   # Wurfmaschine covers the fan too (D-128)
					pr.pierce += Content.RED_BUILD["ranged_pierce"]
					pr.vel *= Content.RED_BUILD["ranged_speed"]
				projectiles.append(pr)
			_event(["sfx", "shoot", p.pos])
		"swarm":
			var picked := {}
			for k in int(def["count"]):
				var t := _nearest_enemy(p.pos, _weapon_range(p, def), picked)
				if t == null:
					break
				picked[t.id] = true
				var s := SimSummon.new()
				s.type = Content.idx(Content.SUMMON_ORDER, "overall")
				s.pos = p.pos + Vector2.RIGHT.rotated(TAU * k / def["count"]) * 20.0
				s.owner = p.id
				s.life = 4.0
				s.dmg = dmg
				s.cd = float(t.id)          # target enemy id
				s.source = _wkey(w)
				summons.append(s)
			_event(["sfx", "melee", p.pos])
		"turret":
			# stands per copy by tier (D-100); each copy keeps its own, no cap per player
			var mine := summons.filter(func(s): return s.alive and s.owner == p.id and s.weapon_index == p.weapons.find(w))
			var cap: int = def["max"][w["tier"] - 1] if def["max"] is Array else int(def["max"])
			if mine.size() >= cap:
				mine[0].alive = false
			var s := SimSummon.new()
			s.type = Content.idx(Content.SUMMON_ORDER, "infostand")
			s.pos = p.pos
			s.owner = p.id
			# lives cap × cooldown so the higher tiers really keep more stands up
			s.life = def["life"][w["tier"] - 1] if def["life"] is Array else float(def["life"])
			s.dmg = dmg
			if p.flags.has("summon_build"):
				s.life *= Content.RED_BUILD["summon_life"]
			s.reach = def["range"] + p.stats["range"]
			s.fire_cd = def["fire_cd"] / maxf(0.2, 1.0 + p.stats["attack_speed"] / 100.0)
			s.weapon_index = p.weapons.find(w)
			s.source = _wkey(w)
			s.tier = int(w["tier"])
			summons.append(s)
			# "Schnell aufgebaut" (D-117): below the cap the next stand comes quickly
			if mine.size() + 1 < cap and def.has("refill_cd"):
				w["cd"] = minf(float(w["cd"]), float(def["refill_cd"]))
		"tether":
			_place_chain(p, w, def, dir, target_pos, dmg)
		"decoy":
			_place_decoy(p, w, def, dir, target_pos, dmg)
		"follower":
			_sani_fire(p, w, def, dmg)
		"patrol":
			_place_lauti(p, w, def, dmg)


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
				_damage_enemy(e, dmg, p, _roll_crit(p), (e.pos - p.pos).normalized(), 50.0, _wkey(w))
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


## Where a ground weapon (Content.PLACED_KINDS) lands, by place_mode (balancing.md §2, §9);
## never beyond the weapon's range.
func _place_point(p: SimPlayer, def: Dictionary, target: SimEnemy, r: float) -> Vector2:
	var at := target.pos
	if place_mode == "lead":
		at = target.pos + target.vel * float(def.get("delay", Content.BALANCE["place_lead"]))
	elif place_mode == "between":
		at = p.pos + (target.pos - p.pos) * 0.5
	elif place_mode == "cluster":
		var zr: float = def.get("radius", float(def.get("width", 120.0)) * 0.5)
		var cands := []
		for e in _query(p.pos, r):
			if not (e.behind and shot_blocked(p.pos, e.pos)):
				cands.append(e)
		if cands.size() > 16:
			cands.sort_custom(func(a, b): return a.pos.distance_squared_to(p.pos) < b.pos.distance_squared_to(p.pos))
			cands.resize(16)
		# the target's own group first: another group must be strictly bigger to win
		cands.erase(target)
		cands.push_front(target)
		var best := 0
		for c in cands:
			var group := _query(c.pos, zr)
			if group.size() > best:
				best = group.size()
				var sum := Vector2.ZERO
				for g in group:
					sum += g.pos
				at = sum / group.size()
	if place_mode != "target" and at.distance_to(p.pos) > r:
		at = p.pos + (at - p.pos).normalized() * r
	return at


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



## True if an intact Brandmauer segment or a corner pillar lies between a and b,
## on any of the four walls (shots can pass holes, GDD §5a).
func shot_blocked(a: Vector2, b: Vector2) -> bool:
	for w in Arena.wall_crossings(a, b):
		if w < 0 or wall[w]:
			return true
	return false


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
		if p.state == 2 or p.state == 3 or (p.state == 1 and not include_downed):
			continue
		var d: float = p.pos.distance_to(pos)
		if d < bd:
			bd = d
			best = p
	return best


# --- Damage to enemies -------------------------------------------------------

func _damage_enemy(e: SimEnemy, amount: float, src: SimPlayer, crit := false, kdir := Vector2.ZERO, knock := 0.0, source := "") -> void:
	if not e.alive or e.presse_t > 0.0:   # Pressekonferenz: invulnerable (D-102)
		return
	if src:
		if e.def["faction"] == "afd" or e.tid == "eidgenossin" or e.tid == "geschichtslehrer":
			if src.char_id == "antifa":
				amount *= 1.4
			if org == "antifa":
				amount *= 1.2
	if e.vuln_t > 0.0:
		amount *= Content.ULTS["fragen_sie_uns"]["vuln_boss" if e.encounter != "" else "vuln"]
	if src:
		amount *= _file_mult(e)   # "Aktenkundig" (D-092)
		# melee weapons hit elites and bosses harder (balancing.md §7, D-121)
		if e.encounter != "" and source != "" 				and Content.WEAPONS.get(str(src.sources.get(source, {}).get("id", "")), {}).get("melee", false):
			amount *= float(Content.BALANCE["melee_vs_boss"])
	if src and e.expose_t > 0.0 and not crit and rng.randf() * 100.0 < Content.WEAPONS["scheinwerfer"]["expose_crit"]:
		crit = true
		amount *= 1.5
	if src and crit and src.flags.has("entlassung"):
		if e.elite or e.encounter != "":
			amount *= Content.RED_BUILD["entlassung_boss"]   # bosses can't be dismissed, but crits hit them harder (D-132)
		elif e.hp < e.max_hp * Content.RED_BUILD["entlassung_hp"]:
			amount = maxf(amount, e.hp + e.shield)
			_event(["say", e.pos, "SAY_ENTLASSEN", ""])
	if src and src.flags.has("crit_build") and source.begins_with("w"):
		amount *= Content.RED_BUILD["crit_extra"] if crit else Content.RED_BUILD["crit_other"]
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
	if e.encounter != "":
		amount = _phase_lock(e, amount)
	var applied := clampf(amount, 0.0, maxf(0.0, e.hp))
	e.hp -= amount
	e.cast_dmg += applied
	e.hit_flash = 0.1
	if knock > 0.0 and not e.elite:
		e.knock += kdir * knock * 4.0
	if src:
		src.damage += amount
		_log_dmg(src, source, applied)
		if crit:
			src.log["crits"] += 1
		if src.stats["lifesteal"] > 0.0 and src.lifesteal_cd <= 0.0 and rng.randf() * 100.0 < src.stats["lifesteal"] * Content.BALANCE["lifesteal_chance"]:
			_heal(src, Content.RED_BUILD["lifesteal_heal"] if src.flags.has("lifesteal_build") else 1.0, "lifesteal")
			src.lifesteal_cd = 0.1
	if _dmg_events < DMG_EVENTS_PER_FRAME and amount > 0.0:
		_dmg_events += 1
		_event(["dmg", e.pos, int(round(amount)), crit, false])
	if e.hp <= 0.0:
		_last_source = source
		_kill_enemy(e, src)
		_last_source = ""


func _kill_enemy(e: SimEnemy, killer: SimPlayer) -> void:
	e.alive = false
	# Kompost: poison jumps to nearby enemies when a poisoned enemy dies.
	var poisoner: SimPlayer = players.get(e.poison_src)
	if e.poison_t > 0.0 and poisoner and poisoner.flags.has("status_build"):
		for o in _query(e.pos, Content.RED_BUILD["status_spread"]):
			if o != e and o.poison_t <= 0.0:
				_apply_poison(o, e.poison, 3.0, e.poison_src, e.poison_key)
	if killer:
		killer.kills += 1
		# Doppelwumms: kills explode twice (the explosions themselves don't chain).
		if killer.flags.has("doppelwumms") and _last_source != "wumms":
			_wumms(killer, e.pos)
			var h := SimHazard.new()
			h.type = Content.idx(Content.HAZARD_ORDER, "explosion")
			h.pos = e.pos
			h.radius = Content.RED_BUILD["wumms_radius"]
			h.life = Content.RED_BUILD["wumms_delay"]
			h.max_life = h.life
			h.owner = killer.id
			h.data = {"wumms": true}
			hazards.append(h)
	if e.def["ai"] == "bomb" or e.no_reward:
		_event(["kill", e.pos, e.type])
		return
	if e.encounter != "":
		_on_encounter_unit_down(e)
	else:
		_event(["kill", e.pos, e.type])
		_event(["sfx", "kill", e.pos])
	# loot
	var value := int(round(float(e.def["pfand"]) * float(Content.BALANCE["pfand_mult"])))
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
	if e.def.has("split") and e.silence_t > 0.0:
		_event(["say", e.pos, "SAY_NOCH_IN_BEARBEITUNG", ""])   # no startups (GDD §11)
	elif e.def.has("split"):
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
		team_level += 1   # stages only; level-up picks come per Späti (balancing.md §4)
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
	k.pos = Arena.clamp_inner(pos, Content.PLAYER_RADIUS)   # drops behind the wall land inside
	k.value = value
	k.life = life
	pickups.append(k)


# --- Run statistics --------------------------------------------------------------

func _add_weapon(p: SimPlayer, id: String, tier: int) -> void:
	var w := {"id": id, "tier": tier, "cd": 0.5, "angle": 0.0, "uid": p.next_wuid}
	p.next_wuid += 1
	p.weapons.append(w)
	p.sources[_wkey(w)] = {"kind": "weapon", "id": id, "tier": tier, "sold": false}


static func _wkey(w: Dictionary) -> String:
	return "w%d" % int(w.get("uid", 0))


func _log_dmg(p: SimPlayer, source: String, amount: float) -> void:
	if amount <= 0.0:
		return
	var key := source if source != "" else "other"
	if not p.sources.has(key):
		p.sources[key] = {"kind": key, "id": key, "tier": 0, "sold": false}
	p.dmg_total[key] = p.dmg_total.get(key, 0.0) + amount
	p.dmg_wave[key] = p.dmg_wave.get(key, 0.0) + amount


## Heals and records how much actually landed (no overheal).
func _heal(p: SimPlayer, amount: float, kind: String) -> void:
	var before := p.hp
	p.hp = minf(p.stats["max_hp"], p.hp + amount)
	p.log[kind] += p.hp - before


func run_stats(p: SimPlayer) -> Dictionary:
	var rows := []
	for key in p.sources:
		var info: Dictionary = p.sources[key]
		rows.append({
			"key": key, "kind": info["kind"], "id": info["id"], "tier": info["tier"], "sold": info["sold"],
			"merged": info.get("merged", false),
			"total": int(round(p.dmg_total.get(key, 0.0))), "wave": int(round(p.dmg_wave.get(key, 0.0))),
		})
	rows.sort_custom(func(a, b): return a["total"] > b["total"])
	var out := p.log.duplicate()
	for k in ["lifesteal", "regen", "sani", "dmg_taken", "dmg_blocked"]:
		out[k] = int(round(out[k]))
	out["damage"] = rows
	out["kills"] = p.kills
	return out


func _wumms(p: SimPlayer, pos: Vector2) -> void:
	var b := Content.RED_BUILD
	var dmg: float = (b["wumms_dmg"] + b["wumms_ranged"] * p.stats["ranged"]) * maxf(0.1, 1.0 + p.stats["damage"] / 100.0)
	for o in _query(pos, Content.RED_BUILD["wumms_radius"]):
		_damage_enemy(o, dmg, p, false, (o.pos - pos).normalized(), 60.0, "wumms")
	_event(["sfx", "explosion", pos])


func _give_pfand(p: SimPlayer, amount: int) -> void:
	p.pfand += amount
	meta_dirty = true


## GDD §13 / D-087: status-immune enemies (Reichsbürger) ignore every slow,
## poison and stun, including the global ones (Antrag gestellt, Streik). Every
## status effect on enemies goes through this one check; damage, knockback and
## damage bonuses are never blocked (D-079).
func _status_immune(e: SimEnemy) -> bool:
	return e.def.get("immune", false)


func _apply_slow(e: SimEnemy, amount: float, t: float) -> void:
	if _status_immune(e) or e.presse_t > 0.0:
		return
	e.slow = maxf(e.slow, minf(amount, _slow_cap(e)))   # bosses: at most 40 % (D-102)
	e.slow_t = maxf(e.slow_t, t)


## Boss rules (D-102, D-107): on encounter units a stun lasts stun_mult as long,
## then "Standfest" makes them immune for a while; every stun that lands
## interrupts the running cast. No stun lands during a Pressekonferenz.
func _apply_stun(e: SimEnemy, t: float) -> void:
	if _status_immune(e):
		return
	if e.encounter != "":
		if e.presse_t > 0.0 or e.standfest_t > 0.0:
			return
		var b := Content.BOSS
		t *= float(b["stun_mult"])
		e.stun_t = maxf(e.stun_t, t)
		e.standfest_t = t + float(b["standfest_l4"] if difficulty >= 4 else b["standfest"])
		_interrupt_cast(e)
		return
	e.stun_t = maxf(e.stun_t, t)


## Highest slow an enemy can get from any source: 1.0 (none) or its encounter's slow_cap.
func _slow_cap(e: SimEnemy) -> float:
	if e.encounter == "":
		return 1.0
	return float(Content.ENCOUNTERS[e.encounter].get("slow_cap", 1.0))


## `key` is the stats key of the weapon that poisons: the ticks are credited to
## player `src` and that weapon for as long as the poison runs (D-088).
func _apply_poison(e: SimEnemy, dps: float, t: float, src: int, key := "") -> void:
	if _status_immune(e):
		return
	e.poison = maxf(e.poison, dps)
	e.poison_t = t
	e.poison_src = src
	e.poison_key = key


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
		"encounters_beaten": encounters_beaten.duplicate(), "wall_intact": holes == 0, "retries": retries,
		"players": res_players, "quotes": quotes,
	}
	_event(["over", won])
	meta_dirty = true


# --- v0.3 status effects (GDD §11 "Status effects on enemies", D-092) ---------
# Every one goes through _status_immune() (D-087).

func _apply_silence(e: SimEnemy, t: float) -> void:
	if _status_immune(e):
		return
	e.silence_t = maxf(e.silence_t, t)


func _apply_reverse(e: SimEnemy, t: float) -> void:
	if _status_immune(e) or e.elite or e.behind:
		return
	e.reverse_t = maxf(e.reverse_t, t)


## Soli-Sticker poison: its own effect next to `poison` (a Tofu doesn't replace it).
func _apply_sticker(e: SimEnemy, dps: float, src: int, key: String) -> void:
	if _status_immune(e):
		return
	var def: Dictionary = Content.WEAPONS["soli_sticker"]
	var fresh := e.sticker_t <= 0.0
	e.sticker_dps = dps if fresh else maxf(e.sticker_dps, dps)
	e.sticker_t = def["sticker_time"]
	e.sticker_src = src
	e.sticker_key = key
	if fresh:
		e.sticker_cd = def["spread_cd"]   # a re-hit doesn't delay the next hand-over


## "Aktenkundig": +file_vuln damage per stack from every source. Immune enemies
## keep the hit count for the Offengelegt burst, but get no vulnerability (D-092).
func _file_mult(e: SimEnemy) -> float:
	if e.file_n <= 0 or _status_immune(e):
		return 1.0
	return 1.0 + float(Content.WEAPONS["lobbyregister"]["file_vuln"]) * e.file_n


## One Lobbyregister hit: a stack more, or "Offengelegt!" when the file is full.
func _file_hit(e: SimEnemy, src: SimPlayer, key: String, tier: int) -> void:
	var def: Dictionary = Content.WEAPONS["lobbyregister"]
	if e.file_n >= int(def["file"]):
		var burst := _scaled_damage(src, float(def["burst"][tier - 1]), def["burst_scale"], def)
		if src and src.flags.has("status_build"):
			burst /= Content.RED_BUILD["status_direct"]   # counts as status damage: no ×0.7 (GDD §11)
		_event(["pulse", e.pos, e.radius + 30.0, "offengelegt"])
		_event(["say", e.pos, "SAY_OFFENGELEGT", ""])
		_damage_enemy(e, burst, src, false, Vector2.ZERO, 0.0, key)
		e.file_n = 0
		e.file_t = 0.0
		return
	e.file_n += 1
	e.file_t = def["file_time"]


## base + Σ coef·stat, × Wut, × dmg_mult, × red-build factor (like weapon_damage).
func _scaled_damage(p: SimPlayer, base: float, scale: Dictionary, def: Dictionary) -> float:
	if p == null:
		return base
	var d := base
	for s in scale:
		d += p.stats[s] * float(scale[s])
	d *= maxf(0.1, 1.0 + (p.stats["damage"] + dyn_damage(p)) / 100.0) * p.dmg_mult
	return maxf(1.0, d * _build_mult(p, def))


## On-hit effects of the v0.3 status shots (Kleine Anfrage, Lobbyregister, Soli-Sticker).
func _v3_on_hit(e: SimEnemy, def: Dictionary, src: SimPlayer, key: String) -> void:
	var tier := 1
	for w in src.weapons:
		if _wkey(w) == key:
			tier = int(w["tier"])
	if def.has("silence"):
		_apply_silence(e, def["silence"])
	if def.has("file") and e.alive:
		_file_hit(e, src, key, tier)
	if def.has("sticker") and e.alive:
		var dps := _scaled_damage(src, float(def["sticker"][tier - 1]), def["sticker_scale"], def)
		if src.flags.has("status_build"):
			dps *= Content.RED_BUILD["status"] / Content.RED_BUILD["status_direct"]   # poison ×2 (Kompost)
		_apply_sticker(e, dps, src.id, key)


## True for enemies with a special ability (Kleine Anfrage aims at them first).
static func has_ability(e: SimEnemy) -> bool:
	return e.def["ai"] in ["voter", "ranged", "charger", "zone", "lob", "sylt", "boss"] \
		or e.def.has("aura") or e.def.has("push_up") or e.def.has("split")


## Kleine Anfrage's target: a voting JU-Schnösel first, then the nearest enemy
## with an ability that isn't "In Bearbeitung" yet. null = use the normal target.
func _ability_target(pos: Vector2, r: float) -> SimEnemy:
	var best: SimEnemy = null
	var bd := INF
	for e in enemies:
		if not e.alive or e.silence_t > 0.0 or _status_immune(e) or not has_ability(e):
			continue
		if (e.behind and shot_blocked(pos, e.pos)) or e.pos.distance_to(pos) - e.radius > r:
			continue
		var d: float = e.pos.distance_to(pos) - (10000.0 if e.def["ai"] == "voter" and e.state == 1 else 0.0)
		if d < bd:
			bd = d
			best = e
	return best


## Elites and bosses "In Bearbeitung": their ability timers run at half speed
## (GDD §11). Only undoes half of a normal tick, never a reset.
static func _half_tick(before: float, after: float, dt: float) -> float:
	if after != before and absf(after - before) <= dt * 1.001 + 0.000001:
		return before + (after - before) * 0.5
	return after


# --- v0.3 summon weapons (GDD §11, D-094) ----------------------------------------

## The weapon a summon came from (by stats key), {} once sold or combined.
func _summon_weapon(s: SimSummon) -> Dictionary:
	var owner: SimPlayer = players.get(s.owner)
	if owner:
		for w in owner.weapons:
			if _wkey(w) == s.source:
				return w
	return {}


## Live damage of a summon's weapon (stats and items as they are now), × Tarifrunde.
func _summon_dmg(s: SimSummon) -> float:
	var w := _summon_weapon(s)
	if w.is_empty():
		return s.dmg * _team_dmg()
	return weapon_damage(players[s.owner], w) * _team_dmg()


func _find_summon(type_id: String, key: String) -> SimSummon:
	var t := Content.idx(Content.SUMMON_ORDER, type_id)
	for s in summons:
		if s.alive and s.type == t and s.source == key:
			return s
	return null


func _new_summon(p: SimPlayer, w: Dictionary, type_id: String, pos: Vector2, life: float, dmg: float) -> SimSummon:
	var s := SimSummon.new()
	s.type = Content.idx(Content.SUMMON_ORDER, type_id)
	s.pos = pos
	s.owner = p.id
	s.life = life * (Content.RED_BUILD["summon_life"] if life > 0.0 and p.flags.has("summon_build") else 1.0)
	s.dmg = dmg
	s.tier = int(w["tier"])
	s.weapon_index = p.weapons.find(w)
	s.source = _wkey(w)
	summons.append(s)
	return s


## Menschenkette: one lamppost summon per copy owns the chain; 5 `kette` hazards
## are only its picture (the host moves them every tick).
func _place_chain(p: SimPlayer, w: Dictionary, def: Dictionary, dir: Vector2, target_pos: Vector2, dmg: float) -> void:
	var reach: float = def["lamp_reach"]
	if target_pos != Vector2.INF:
		reach = minf(reach, p.pos.distance_to(target_pos))
	var lamp_at := Arena.clamp_inner(p.pos + dir * maxf(80.0, reach), 12.0)
	var s := _find_summon("laterne", _wkey(w))
	if s:
		s.pos = lamp_at
		s.life = def["life"] * (Content.RED_BUILD["summon_life"] if p.flags.has("summon_build") else 1.0)
		s.data["life0"] = s.life
		s.dmg = dmg
		return
	s = _new_summon(p, w, "laterne", lamp_at, def["life"], dmg)
	s.data = {"segs": [], "hidden": false, "life0": s.life, "torn": true}
	for k in 5:
		var h := SimHazard.new()
		h.type = Content.idx(Content.HAZARD_ORDER, "kette")
		h.pos = p.pos
		h.radius = 0.0
		h.life = s.life
		h.max_life = s.life
		h.owner = p.id
		h.data = {"src": s.source, "ctl": s, "hidden": true}
		hazards.append(h)
		s.data["segs"].append(h)
	_step_chain(s, 0.0)


func _step_chain(s: SimSummon, _dt: float) -> void:
	var def: Dictionary = Content.WEAPONS["menschenkette"]
	var owner: SimPlayer = players.get(s.owner)
	if owner == null or owner.state == 2:
		s.alive = false
		return
	var a := owner.pos
	var partner: SimPlayer = null
	var best: float = def["length"]
	for o in players.values():
		if o != owner and o.state == 0 and o.pos.distance_to(a) <= best:
			best = o.pos.distance_to(a)
			partner = o
	var b: Vector2 = partner.pos if partner else s.pos
	var torn: bool = owner.state == 1 or a.distance_to(b) > float(def["length"])
	s.data["hidden"] = partner != null   # the lamppost is drawn only while the chain hangs on it
	s.data["torn"] = torn
	var segs: Array = s.data["segs"]
	for k in segs.size():
		var h: SimHazard = segs[k]
		h.pos = a.lerp(b, (k + 0.5) / segs.size())
		h.radius = a.distance_to(b) / (2.0 * segs.size()) + 4.0
		h.life = maxf(0.01, s.life)
		h.max_life = maxf(h.life, float(s.data.get("life0", h.life)))
		h.data["hidden"] = torn
	if torn:
		return
	# one hit per enemy per tick, however many links it touches (D-094)
	var key := "kette" + s.source
	var mid := (a + b) * 0.5
	var dmg := -1.0
	for e in _query(mid, a.distance_to(b) * 0.5 + def["width"]):
		if e.behind or e.hit_cd.get(key, 0.0) > time:
			continue
		var c := Geometry2D.get_closest_point_to_segment(e.pos, a, b)
		if c.distance_to(e.pos) > def["width"] + e.radius:
			continue
		e.hit_cd[key] = time + float(def["tick"])
		if dmg < 0.0:
			dmg = _summon_dmg(s)
		var away: Vector2 = (e.pos - c).normalized()
		if away == Vector2.ZERO:
			away = (b - a).orthogonal().normalized()
		_damage_enemy(e, dmg, owner, false, away, def["knock"], s.source)


## Pappkamerad: placed toward the target; the old one bursts when replaced.
func _place_decoy(p: SimPlayer, w: Dictionary, def: Dictionary, dir: Vector2, target_pos: Vector2, dmg: float) -> void:
	var old := _find_summon("pappkamerad", _wkey(w))
	if old:
		_decoy_burst(old)
		old.alive = false
	var reach: float = def["range"]
	if target_pos != Vector2.INF:
		reach = minf(reach, p.pos.distance_to(target_pos) * 0.5)
	var s := _new_summon(p, w, "pappkamerad", Arena.clamp_inner(p.pos + dir * reach, 20.0), def["life"], dmg)
	s.max_hp = (def["hp_base"] + def["hp_wave"] * wave + def["hp_summon"] * p.stats["summon"]) \
		* (Content.RED_BUILD["summon"] if p.flags.has("summon_build") else 1.0)
	s.hp = s.max_hp


func _hurt_decoy(s: SimSummon, amount: float) -> void:
	if not s.alive:
		return
	s.hp -= amount
	if s.hp <= 0.0:
		_decoy_burst(s)
		s.alive = false


func _decoy_burst(s: SimSummon) -> void:
	var def: Dictionary = Content.WEAPONS["pappkamerad"]
	var owner: SimPlayer = players.get(s.owner)
	var dmg := _summon_dmg(s)
	for e in _query(s.pos, def["burst_r"]):
		if not e.behind:
			_damage_enemy(e, dmg, owner, false, (e.pos - s.pos).normalized(), 60.0, s.source)
	_event(["pulse", s.pos, def["burst_r"], "konfetti"])
	_event(["sfx", "explosion", s.pos])


## The decoy that lures enemy `e`, or null (GDD §11: non-elites within `lure`).
func _lure_for(e: SimEnemy) -> SimSummon:
	if _decoys.is_empty() or e.elite or e.behind or not e.def["ai"] in ["chase", "ranged", "charger", "zone", "lob", "bomb"]:
		return null
	var r: float = Content.WEAPONS["pappkamerad"]["lure"]
	var best: SimSummon = null
	var bd := r
	for s in _decoys:
		var d: float = s.pos.distance_to(e.pos)
		if s.alive and d <= bd:
			bd = d
			best = s
	return best


## Where an enemy heads: a luring Pappkamerad, else its target player. INF = nobody.
func _target_pos(e: SimEnemy) -> Vector2:
	var d := _lure_for(e)
	if d:
		return d.pos
	var p := _target_player(e)
	return p.pos if p else Vector2.INF


## Demo-Sanis: the weapon's cooldown is the Sani's pulse (heal + shove); the
## first shot of a wave sends her out.
func _sani_fire(p: SimPlayer, w: Dictionary, def: Dictionary, dmg: float) -> void:
	var s := _find_summon("sani", _wkey(w))
	if s == null:
		_new_summon(p, w, "sani", p.pos + Vector2(-40, 10), -1.0, dmg)
		return
	s.dmg = dmg
	var heal: float = (float(def["heal"][int(w["tier"]) - 1]) + p.stats["summon"] * float(def["heal_scale"]["summon"])) \
		* (Content.RED_BUILD["summon"] if p.flags.has("summon_build") else 1.0)
	var patient: SimPlayer = null
	for o in players.values():
		if o.state == 0 and o.hp < o.stats["max_hp"] and o.pos.distance_to(s.pos) <= _weapon_range(p, def):
			if patient == null or o.hp / o.stats["max_hp"] < patient.hp / patient.stats["max_hp"]:
				patient = o
	var acted := false
	if patient:
		var before := patient.hp
		patient.hp = minf(patient.stats["max_hp"], patient.hp + heal)
		p.log["sani"] += patient.hp - before
		acted = true
	for e in _query(s.pos, def["shove_r"]):
		if e.behind:
			continue
		_damage_enemy(e, _summon_dmg(s), p, false, (e.pos - s.pos).normalized(), def["knock"], s.source)
		acted = true
	if acted:
		_event(["pulse", s.pos, def["shove_r"], "sani"])


## Lauti: casting again refreshes the running truck.
func _place_lauti(p: SimPlayer, w: Dictionary, def: Dictionary, dmg: float) -> void:
	var s := _find_summon("lauti", _wkey(w))
	var as_mult := maxf(0.2, 1.0 + p.stats["attack_speed"] / 100.0)
	if s:
		s.life = def["life"] * (Content.RED_BUILD["summon_life"] if p.flags.has("summon_build") else 1.0)
		s.dmg = dmg
		s.fire_cd = def["pulse_cd"] / as_mult
		return
	s = _new_summon(p, w, "lauti", p.pos + Vector2.RIGHT.rotated(p.aim) * def["range"], def["life"], dmg)
	s.fire_cd = def["pulse_cd"] / as_mult
	s.cd = 0.2   # first pulse right away
	s.data = {"ang": p.aim}


func _step_v3_summon(s: SimSummon, dt: float) -> void:
	var owner: SimPlayer = players.get(s.owner)
	match Content.SUMMON_ORDER[s.type]:
		"laterne":
			_step_chain(s, dt)
		"sani":
			if owner == null or owner.state == 2:
				s.alive = false
				return
			# follows 40 px behind (away from where the player aims), stays with an away figure
			var goal: Vector2 = owner.pos - Vector2.RIGHT.rotated(owner.aim) * 40.0 + Vector2(0, 8)
			s.pos = clamp_player(s.pos.move_toward(goal, 260.0 * dt))
		"lauti":
			if owner == null or owner.state == 2:
				s.alive = false
				return
			var def: Dictionary = Content.WEAPONS["lauti"]
			s.data["ang"] = fmod(float(s.data.get("ang", 0.0)) + float(def["orbit_speed"]) * dt, TAU)
			s.pos = Arena.clamp_inner(owner.pos + Vector2.RIGHT.rotated(s.data["ang"]) * def["range"], 18.0)
			s.cd -= dt
			if s.cd <= 0.0:
				s.cd = s.fire_cd
				var dmg := -1.0
				var near := _query(s.pos, def["pulse_r"]).filter(func(e): return not (e.behind and shot_blocked(s.pos, e.pos)))
				if near.size() > int(def["max_hits"]):
					# the nearest few only (crowd cap, D-091)
					near.sort_custom(func(a, b): return a.pos.distance_squared_to(s.pos) < b.pos.distance_squared_to(s.pos))
					near.resize(int(def["max_hits"]))
				for e in near:
					if dmg < 0.0:
						dmg = _summon_dmg(s)
					_damage_enemy(e, dmg, owner, false, (e.pos - s.pos).normalized(), def["knock"], s.source)
				_event(["pulse", s.pos, def["pulse_r"], "lauti"])


## A Demo-Sani of anyone stands next to `pos` (revive +50 %, GDD §11).
func _sani_near(pos: Vector2) -> bool:
	var t := Content.idx(Content.SUMMON_ORDER, "sani")
	for s in summons:
		if s.alive and s.type == t and s.pos.distance_to(pos) <= REVIVE_RANGE + 20.0:
			return true
	return false


# --- Summons -----------------------------------------------------------------

func _step_summons(dt: float) -> void:
	var oma_t := Content.idx(Content.SUMMON_ORDER, "oma")
	var info_t := Content.idx(Content.SUMMON_ORDER, "infostand")
	var genosse_t := Content.idx(Content.SUMMON_ORDER, "genosse")
	var overall_t := Content.idx(Content.SUMMON_ORDER, "overall")
	for s in summons:
		if not s.alive:
			continue
		if s.life > 0.0:
			s.life -= dt
			if s.life <= 0.0:
				if s.type == Content.idx(Content.SUMMON_ORDER, "pappkamerad"):
					_decoy_burst(s)
				s.alive = false
				continue
		if s.type >= Content.idx(Content.SUMMON_ORDER, "laterne"):
			_step_v3_summon(s, dt)
		elif s.type == info_t:
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
					pr.source = s.source
					pr.life = s.reach / 520.0 * 1.2
					var bounces = Content.WEAPONS["infostand"].get("bounce", 0)
					pr.bounce = int(bounces[clampi(s.tier, 1, 4) - 1]) if bounces is Array else int(bounces)
					projectiles.append(pr)
		elif s.type == genosse_t:
			_step_genosse(s, dt)
		elif s.type == overall_t:
			_step_overall(s, dt)
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
				_apply_stun(e, u["stun"])
				_damage_enemy(e, dmg, p, false, (e.pos - p.pos).normalized(), u["knock"], "ult")
		"urlaubsantrag":
			p.ult_t = u["time"]
			p.stunned = u["time"]
			p.iframes = u["time"]
		"antrag_gestellt", "tarifrunde":
			effects[ult] = u["time"]
		"strassenblockade":
			var x: float = Arena.INNER.position.x + 35.0
			while x < Arena.INNER.end.x:
				var h := SimHazard.new()
				h.type = Content.idx(Content.HAZARD_ORDER, "kleber")
				h.pos = Vector2(x, p.pos.y)
				h.radius = u["radius"]
				h.life = u["time"]
				h.max_life = u["time"]
				h.slow = u["slow"]
				h.dps = u["dps"] * (1.0 + p.stats["status"] * 0.1) * power
				h.owner = p.id
				h.data = {"src": "ult"}
				hazards.append(h)
				x += u["spacing"]
		"critical_mass":
			p.dash_dir = p.input.normalized() if p.input.length() > 0.1 else Vector2.RIGHT.rotated(p.aim)
			p.dash_t = u["dash_time"]
			p.boost_t = u["dash_time"] + u["boost_time"]
			p.iframes = maxf(p.iframes, p.boost_t)  # invulnerable for dash + boost (GDD §9a)
		"schwarzer_block":
			for i in int(u["count"]):
				var s := SimSummon.new()
				s.type = Content.idx(Content.SUMMON_ORDER, "genosse")
				s.pos = clamp_player(p.pos + Vector2.RIGHT.rotated(TAU * i / u["count"]) * 50.0)
				s.owner = p.id
				s.life = u["time"]
				s.dmg = u["dmg"] * (1.0 + p.stats["summon"] * 0.1) * power * (Content.RED_BUILD["summon"] if p.flags.has("summon_build") else 1.0)
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
					_apply_stun(e, u["stun"])
					e.vuln_t = u["vuln_time"]   # double damage is no status effect (D-087)
	p.log["ults"] += 1
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
			_damage_enemy(e, dmg, p, false, p.dash_dir, 120.0, "ult")


## Weißer Overall: runs to its assigned enemy, hits once, leaves.
func _step_overall(s: SimSummon, dt: float) -> void:
	var t: SimEnemy = null
	for e in enemies:
		if e.alive and e.id == int(s.cd):
			t = e
			break
	if t == null:
		t = _nearest_enemy(s.pos, 400.0)
		if t == null:
			s.alive = false
			return
		s.cd = float(t.id)
	s.pos = s.pos.move_toward(t.pos, 340.0 * dt)
	if s.pos.distance_to(t.pos) <= t.radius + 10.0:
		var owner: SimPlayer = players.get(s.owner)
		var dmg := s.dmg * _team_dmg()
		var def: Dictionary = Content.WEAPONS["weisser_overall"]
		var at := s.pos
		_damage_enemy(t, dmg, owner, false, (t.pos - at).normalized(), 80.0, s.source)
		# Blockade-Knäuel (D-115): everyone else within splash_r takes splash × the damage
		for o in _query(at, def["splash_r"]):
			if o != t:
				_damage_enemy(o, dmg * def["splash"], owner, false, (o.pos - at).normalized(), 80.0, s.source)
		_event(["swing", at, 0.0, def["splash_r"], 360.0, "overall"])   # the tangle, drawn like a 360° swing
		s.alive = false


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
		_damage_enemy(e, s.dmg * _team_dmg(), owner, false, away, 90.0, "ult")


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
			# no Hausausweis while "In Bearbeitung" or with 3+ "Aktenkundig" stacks (GDD §11)
			if e.silence_t > 0.0 or (e.file_n >= 3 and not _status_immune(e)):
				continue
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
	_decoys = summons.filter(func(s): return s.alive and s.type == Content.idx(Content.SUMMON_ORDER, "pappkamerad"))
	_stuck.clear()
	for e in enemies:
		if e.alive and e.sticker_t > 0.0:
			_stuck[e.sticker_src] = int(_stuck.get(e.sticker_src, 0)) + 1
	for e in enemies:
		if not e.alive:
			continue
		e.hit_flash = maxf(0.0, e.hit_flash - dt)
		if dt > 0.0:
			e.vel = e.vel.lerp((e.pos - e.last_pos) / dt, 0.25)
		e.last_pos = e.pos
		if e.poison_t > 0.0:
			e.poison_t -= dt
			_damage_poison(e, e.poison * dt)
			if not e.alive:
				continue
		if e.sticker_t > 0.0:
			_step_sticker(e, dt)
			if not e.alive:
				continue
		if e.encounter != "":
			_step_boss_rules(e, dt)
			if e.presse_t > 0.0:
				# Pressekonferenz (D-102, D-106): invulnerable, walks to the middle; timers,
				# a running vulnerability and the target timer all pause
				e.presse_t = maxf(0.0, e.presse_t - dt)
				_move_toward(e, Arena.CENTER, e.speed, dt)
				_separate(e)
				e.pos = Arena.clamp_inner(e.pos, e.radius)
				_contact(e)
				continue
		if e.slow_t > 0.0:
			e.slow_t -= dt
			if e.slow_t <= 0.0:
				e.slow = 0.0
		e.vuln_t = maxf(0.0, e.vuln_t - dt)
		e.expose_t = maxf(0.0, e.expose_t - dt)
		e.silence_t = maxf(0.0, e.silence_t - dt)
		e.reverse_t = maxf(0.0, e.reverse_t - dt)
		if e.file_t > 0.0:
			e.file_t -= dt
			if e.file_t <= 0.0:
				e.file_n = 0
		if e.stun_t > 0.0:
			e.stun_t -= dt
			continue
		var slow_mult: float = 1.0 - e.slow
		var immune := _status_immune(e)   # global slow and Streik freeze too (D-087)
		if effects.has("antrag_gestellt") and not immune:
			slow_mult *= 1.0 - Content.ULTS["antrag_gestellt"]["slow"]
		if frozen and not immune:
			if e.elite:
				slow_mult *= 0.5
			else:
				continue
		# bosses and minibosses: slow from all sources together at most slow_cap (D-102, D-107)
		var spd: float = e.speed * maxf(slow_mult, 1.0 - _slow_cap(e)) * (1.2 if e.buffed else 1.0)
		if e.knock.length() > 1.0:
			e.pos += e.knock * dt
			e.knock = e.knock.move_toward(Vector2.ZERO, 2400.0 * dt)
		if e.behind:
			_move_behind_wall(e, spd, dt)
		elif e.reverse_t > 0.0:
			# "Rolle rückwärts": backwards away from the nearest player at 70 % speed,
			# abilities paused, contact damage stays (GDD §11)
			var rp := _nearest_player(e.pos)
			if rp:
				var away: Vector2 = (e.pos - rp.pos).normalized()
				e.pos += away * spd * 0.7 * dt
		else:
			# Phase tempo (balancing.md §7, D-106): movement and basic attacks run
			# faster per phase; signature abilities use _real_dt (real time).
			var ai_dt: float = dt * e.tempo
			_real_dt = dt
			var slow_abilities: bool = e.elite and e.silence_t > 0.0   # "In Bearbeitung" on elites (GDD §11)
			var t1: float = e.timer
			var t2: float = e.timer2
			var t3: float = e.timer3
			var st0: int = e.state
			match e.def["ai"]:
				"chase": _ai_chase(e, spd, ai_dt)
				"ranged": _ai_ranged(e, spd, ai_dt)
				"voter": _ai_voter(e, spd, ai_dt)
				"charger": _ai_charger(e, spd, ai_dt)
				"zone": _ai_zone(e, spd, ai_dt)
				"lob": _ai_lob(e, spd, ai_dt)
				"bomb": _ai_bomb(e, spd, ai_dt)
				"flyer": _ai_flyer(e, spd, ai_dt)
				"sylt": _ai_sylt(e, spd, ai_dt)
				"boss": _ai_boss(e, spd, ai_dt)
			if slow_abilities and e.alive:
				e.timer = _half_tick(t1, e.timer, ai_dt)
				e.timer3 = _half_tick(t3, e.timer3, ai_dt)
				if st0 == 0 and e.state == 0:
					e.timer2 = _half_tick(t2, e.timer2, ai_dt)
		if not e.alive:
			continue
		_separate(e)
		if e.def["ai"] != "flyer":
			if e.behind:
				e.pos = Vector2(clampf(e.pos.x, e.radius, ARENA.x - e.radius), clampf(e.pos.y, e.radius, ARENA.y - e.radius))
			else:
				e.pos = Arena.clamp_inner(e.pos, e.radius)   # inside the four walls
		_contact(e)
		if not _decoys.is_empty():
			_contact_decoy(e)
	_update_boss_cast()


## Soli-Sticker: ticks like poison (credited to who stuck it, D-088) and passes a
## fresh sticker to one sticker-free neighbour per spread_cd, up to the cap.
func _step_sticker(e: SimEnemy, dt: float) -> void:
	var def: Dictionary = Content.WEAPONS["soli_sticker"]
	e.sticker_t -= dt
	_damage_dot(e, e.sticker_dps * dt, e.sticker_src, e.sticker_key)
	if not e.alive:
		return
	e.sticker_cd -= dt
	if e.sticker_cd <= 0.0 and e.sticker_t > 0.0:
		e.sticker_cd = def["spread_cd"]
		if int(_stuck.get(e.sticker_src, 0)) >= int(def["sticker_max"]):
			return
		for o in _query(e.pos, e.radius + def["spread_range"]):
			if o != e and o.sticker_t <= 0.0 and o.sticker_free_at <= time and o.behind == e.behind and not _status_immune(o):
				_apply_sticker(o, e.sticker_dps, e.sticker_src, e.sticker_key)
				_stuck[e.sticker_src] = int(_stuck.get(e.sticker_src, 0)) + 1
				break
	if e.sticker_t <= 0.0:
		e.sticker_dps = 0.0
		e.sticker_t = 0.0
		e.sticker_free_at = time + float(def["sticker_time"])   # no ping-pong between two enemies


## Lured enemies hit the Pappkamerad instead of a player (GDD §11).
func _contact_decoy(e: SimEnemy) -> void:
	var d := _lure_for(e)
	if d == null or e.def["ai"] == "bomb" or e.pos.distance_to(d.pos) > e.radius + 18.0:
		return
	if e.hit_cd.get("papp", 0.0) <= time:
		e.hit_cd["papp"] = time + 0.5
		_hurt_decoy(d, e.dmg * (1.5 if e.buffed else 1.0))


## Damage over time (poison ticks, zones): no hit flash, no numbers. Credited to
## player `src_id` and stats key `key` (D-088).
func _damage_dot(e: SimEnemy, amount: float, src_id: int, key: String) -> void:
	if not e.alive or e.presse_t > 0.0:   # Pressekonferenz: invulnerable (D-102)
		return
	var src: SimPlayer = players.get(src_id)
	if src:
		amount *= _file_mult(e)   # "Aktenkundig" hits every source, DoT too (D-092)
	if e.encounter != "":
		amount = _phase_lock(e, amount)
	var applied := clampf(amount, 0.0, maxf(0.0, e.hp))
	e.hp -= amount
	e.cast_dmg += applied
	if src:
		src.damage += amount
		_log_dmg(src, key, applied)
	if e.hp <= 0.0:
		_kill_enemy(e, src)


## The poison running on `e`, credited to whoever applied it.
func _damage_poison(e: SimEnemy, amount: float) -> void:
	_damage_dot(e, amount, e.poison_src, e.poison_key)


## A player zone's damage, credited to the zone's owner and weapon. Never touch
## the enemy's poison_src/poison_key for this: that steals a running poison (D-088).
func _damage_zone(e: SimEnemy, h: SimHazard, amount: float) -> void:
	_damage_dot(e, amount, h.owner, h.data.get("src", ""))


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
				if p.flags.has("fertigputz") and not e.elite:
					e.knock += (e.pos - p.pos).normalized() * Content.RED_BUILD["fertigputz_knock"]
				if e.def.has("push_up") and e.silence_t <= 0.0:
					# "Remigration": shoved toward the nearest wall (GDD §5a)
					p.knock = Arena.toward_wall(p.pos) * float(e.def["push_up"]) * 2.0


func _move_toward(e: SimEnemy, goal: Vector2, spd: float, dt: float) -> void:
	var d := goal - e.pos
	if d.length() > 1.0:
		e.dir = d.normalized()
		e.pos += e.dir * minf(spd * dt, d.length())


## AfD enemies behind the wall walk along the staging line (around the corners)
## to the nearest hole on any side, then step through it (GDD §5a).
func _move_behind_wall(e: SimEnemy, spd: float, dt: float) -> void:
	if Arena.is_inside(e.pos, e.radius):
		e.behind = false   # through a hole (or knocked in): joins the fight
		return
	var ring := Arena.STAGING_RECT
	var s := Arena.perimeter_param(ring, e.pos)
	var best := -1
	var bd := INF
	for i in WALL_SEGMENTS:
		if not wall[i]:
			var d := absf(Arena.perimeter_delta(ring, s, Arena.perimeter_param(ring, Arena.seg_staging(i))))
			if d < bd:
				bd = d
				best = i
	if best < 0:
		# no hole anywhere: pace along the wall, grumbling
		if e.target == Vector2.ZERO or e.pos.distance_to(e.target) < 10.0:
			e.target = Arena.perimeter_point(ring, s + rng.randf_range(-250.0, 250.0))
		_walk_ring(e, Arena.perimeter_param(ring, e.target), spd * 0.5, dt)
		return
	spd *= float(Arena.WALL["staging_speed"])
	if bd > Arena.seg_len(best) * 0.3:
		_walk_ring(e, Arena.perimeter_param(ring, Arena.seg_staging(best)), spd, dt)
	else:
		_move_toward(e, Arena.seg_inner(best, e.radius + 12.0), spd, dt)
		if Arena.is_inside(e.pos, e.radius):
			e.behind = false


## One step along the staging line toward perimeter position goal_s.
func _walk_ring(e: SimEnemy, goal_s: float, spd: float, dt: float) -> void:
	var ring := Arena.STAGING_RECT
	var s := Arena.perimeter_param(ring, e.pos)
	var d := Arena.perimeter_delta(ring, s, goal_s)
	_move_toward(e, Arena.perimeter_point(ring, s + signf(d) * minf(absf(d), 40.0)), spd, dt)


## Who an enemy attacks. Encounter units pick a random living, present player
## every target_min..target_max s (D-103; may repeat) and at once when their
## target goes down or away (D-107). Everyone else: the nearest player.
func _target_player(e: SimEnemy) -> SimPlayer:
	if e.encounter == "":
		return _nearest_player(e.pos)
	var cur: SimPlayer = players.get(e.target_id)
	if cur == null or cur.state != 0 or e.target_t <= 0.0:
		var alive: Array = players.values().filter(func(p): return p.state == 0)
		if alive.is_empty():
			return null
		cur = alive[rng.randi_range(0, alive.size() - 1)]
		e.target_id = cur.id
		var b := Content.BOSS
		e.target_t = rng.randf_range(float(b["target_min"]), float(b["target_max"]))
	return cur


func _ai_chase(e: SimEnemy, spd: float, dt: float) -> void:
	var tp := _target_pos(e)
	if tp != Vector2.INF:
		_move_toward(e, tp, spd, dt)


func _keep_distance(e: SimEnemy, tp: Vector2, keep: float, spd: float, dt: float) -> void:
	var d := e.pos.distance_to(tp)
	if d > keep + 40.0:
		_move_toward(e, tp, spd, dt)
	elif d < keep - 40.0:
		_move_toward(e, e.pos + (e.pos - tp).normalized() * 50.0, spd, dt)


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
	var tp := _target_pos(e)
	if tp == Vector2.INF:
		return
	_keep_distance(e, tp, e.def["keep"], spd, dt)
	if e.silence_t <= 0.0:   # "In Bearbeitung": no throwing
		e.timer -= dt
	if e.timer <= 0.0 and e.pos.distance_to(tp) < e.def["keep"] + 160.0:
		e.timer = e.def["fire_cd"]
		var dmg: float = e.def["proj_dmg"] * e.dmg / e.def["dmg"]
		var pr := _enemy_shot(e, e.def["proj"], (tp - e.pos).normalized(), e.def["proj_speed"], dmg)
		pr.split = 1
		pr.split_t = 0.8


func _ai_voter(e: SimEnemy, spd: float, dt: float) -> void:
	if e.state == 2:
		_ai_chase(e, spd, dt)
		return
	if e.seg < 0 or not wall[e.seg]:
		e.seg = -1
		var bd := INF
		for i in WALL_SEGMENTS:   # nearest intact segment on any of the four walls
			if wall[i]:
				var d := e.pos.distance_to(Arena.seg_inner(i, 0.0))
				if d < bd:
					bd = d
					e.seg = i
		if e.seg < 0:
			e.state = 2
			return
		e.state = 0
	var spot := Arena.seg_inner(e.seg, e.radius + 4.0)
	if e.state == 0:
		_move_toward(e, spot, spd, dt)
		if e.pos.distance_to(spot) < 8.0:
			e.state = 1
			e.timer2 = 0.0
	elif e.state == 1:
		if e.silence_t <= 0.0:   # "In Bearbeitung": the vote timer pauses
			e.timer2 += dt
		# holes open faster with more players and later waves (GDD §5a)
		if e.timer2 >= float(e.def["vote_time"]) / Arena.vote_speed(num_players(), wave):
			wall[e.seg] = false
			e.state = 2
			_event(["say", e.pos, "SAY_JU_VOTE", ""])
			_event(["sfx", "vote", e.pos])
			meta_dirty = true


func _ai_charger(e: SimEnemy, spd: float, dt: float) -> void:
	var tp := _target_pos(e)
	match e.state:
		0:
			if tp == Vector2.INF:
				return
			_move_toward(e, tp, spd, dt)
			if e.silence_t <= 0.0:   # "In Bearbeitung": no new charge
				e.timer -= dt
			if e.timer <= 0.0 and e.pos.distance_to(tp) < 320.0:
				e.state = 1
				e.timer2 = 0.8
				e.target = (tp - e.pos).normalized()
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
	var tp := _target_pos(e)
	if tp != Vector2.INF:
		_keep_distance(e, tp, e.def["keep"], spd, dt)
	if e.silence_t <= 0.0:   # "In Bearbeitung": no Mietzone
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
	var tp := _target_pos(e)
	if tp == Vector2.INF:
		return
	_keep_distance(e, tp, e.def["keep"], spd, dt)
	if e.silence_t <= 0.0:   # "In Bearbeitung": no lobbing
		e.timer -= dt
	if e.timer <= 0.0 and e.pos.distance_to(tp) < 520.0:
		e.timer = e.def["fire_cd"]
		_lob(e.pos, tp, e.def["proj_dmg"] * e.dmg / e.def["dmg"], "golfball")


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
	for s in _decoys:
		if s.alive and s.pos.distance_to(pos) < radius + 16.0:
			_hurt_decoy(s, dmg)   # bombs and lobs aimed at the Pappkamerad hit it
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


# --- Boss rules (GDD §14 "Boss rules", D-102 to D-112) --------------------------
# Every encounter unit: phase lock with a Pressekonferenz at each phase change,
# random targets, stun resistance (Standfest) and interruptible casts. All numbers
# live in Content.BOSS and Content.ENCOUNTERS.

## Per tick, before the unit acts: Standfest and target timers, phase changes.
func _step_boss_rules(e: SimEnemy, dt: float) -> void:
	e.standfest_t = maxf(0.0, e.standfest_t - dt)
	if e.presse_t > 0.0:
		return
	e.target_t -= dt
	var ph := _enc_phase_for(_enc_frac(e.encounter))
	if ph > e.phase:
		_enter_phase(e.encounter, e.phase + 1)


## Total HP fraction of an encounter (all its units together, D-106).
func _enc_frac(enc_id: String) -> float:
	var hp := 0.0
	var mx := 0.0
	for u in enemies:
		if u.alive and u.encounter == enc_id:
			hp += maxf(0.0, u.hp)
			mx += u.max_hp
	if _enc_max_hp > 0.0:
		mx = maxf(mx, _enc_max_hp)
	return hp / mx if mx > 0.0 else 0.0


## The phase (0..2) an HP fraction belongs to; a fraction exactly on a boundary
## (where the phase lock stops it) already counts as the next phase.
static func _enc_phase_for(frac: float) -> int:
	var ph := 0
	for at in Content.BOSS["phase_at"]:
		if frac <= float(at) + 0.0001:
			ph += 1
	return ph


## Phase lock (D-102): damage to an encounter unit can't take the encounter's total
## HP below the next phase boundary; the rest is lost. Returns the damage to apply.
func _phase_lock(e: SimEnemy, amount: float) -> float:
	var bounds: Array = Content.BOSS["phase_at"]
	if amount <= 0.0 or e.phase >= bounds.size():
		return amount
	var hp := 0.0
	var mx := 0.0
	for u in enemies:
		if u.alive and u.encounter == e.encounter:
			hp += maxf(0.0, u.hp)
			mx += u.max_hp
	if _enc_max_hp > 0.0:
		mx = maxf(mx, _enc_max_hp)
	var allowed := hp - float(bounds[e.phase]) * mx
	return clampf(amount, 0.0, maxf(0.0, allowed))


## Phase change of an encounter: every unit holds a Pressekonferenz (D-102, D-106).
func _enter_phase(enc_id: String, ph: int) -> void:
	var b := Content.BOSS
	var presse: float = b["presse_time_l4"] if difficulty >= 4 else b["presse_time"]
	var tempo: Array = b["phase_tempo"]
	var at := Arena.CENTER
	for u in enemies:
		if not u.alive or u.encounter != enc_id:
			continue
		_cancel_cast(u)
		u.phase = ph
		u.state = 0
		u.tempo = float(tempo[mini(ph, tempo.size() - 1)])
		u.presse_t = presse
		u.stun_t = 0.0
		u.slow = 0.0
		u.slow_t = 0.0
		u.knock = Vector2.ZERO
		u.target_t = 0.0
		u.data["phase_start"] = true
		at = u.pos
	var q := Quotes.random_for("boss_ruf:" + enc_id, rng)
	if q != "":
		shown_quotes[q] = true
	_event(["boss_phase", enc_id, ph])
	_event(["say", at, "SAY_ENRAGE", ""])
	if Content.ENCOUNTERS[enc_id].get("ult_per_phase", false):
		# the final boss: every player's ultimate is ready again (D-102)
		for p in players.values():
			if p.state != 2:
				p.ult_ready = true
	meta_dirty = true


## Old phase rule for bosses outside an encounter (tools, tests): by own HP, no lock.
func _boss_phase(e: SimEnemy) -> void:
	if e.encounter != "":
		return
	var f := e.hp / e.max_hp
	var ph := 0 if f > 0.66 else (1 if f > 0.33 else 2)
	if ph != e.phase:
		e.phase = ph
		e.state = 0


## Ability time of this tick: real time (no phase tempo), half speed while
## "In Bearbeitung" (GDD §11: elites and bosses run their abilities at half speed).
func _ab_dt(e: SimEnemy) -> float:
	return _real_dt * (0.5 if e.silence_t > 0.0 else 1.0)


## A telegraph's warning time at this Umfrage level (B8, D-107): × telegraph_mult,
## never below telegraph_floor of the base time.
func _telegraph(base: float) -> float:
	var b := Content.BOSS
	var m: Array = b["telegraph_mult"]
	return base * maxf(float(m[clampi(difficulty, 0, m.size() - 1)]), float(b["telegraph_floor"]))


## A value that runs linearly from Umfrage 10 % (level 0) to 35 % (level 5).
func _by_level(pair: Array) -> float:
	return lerpf(float(pair[0]), float(pair[1]), clampf(difficulty / 5.0, 0.0, 1.0))


func _start_cast(e: SimEnemy, id: String, time: float) -> void:
	e.cast = id
	e.cast_t = 0.0
	e.cast_time = maxf(0.01, time)
	e.cast_dmg = 0.0


func _end_cast(e: SimEnemy) -> void:
	e.cast = ""
	e.cast_t = 0.0
	e.cast_time = 0.0


func _cast_progress(e: SimEnemy) -> float:
	return clampf(e.cast_t / e.cast_time, 0.0, 1.0) if e.cast_time > 0.0 else 0.0


## A stun broke the running cast (D-102, D-107): "UNTERBROCHEN".
func _interrupt_cast(e: SimEnemy) -> void:
	if e.cast == "":
		return
	var id := e.cast
	_event(["interrupt", e.pos, id])
	if id == "abstimmung":
		_vote_fail(e)   # "or if he gets stunned" (D-104)
		return
	_cancel_cast(e)


## Ends the running cast and whatever belongs to it (telegraphs, a vote on its way).
func _cancel_cast(e: SimEnemy) -> void:
	match e.cast:
		"wende":
			e.timer2 = 0.0
			e.data["wende_done"] = true   # the next one keeps the 10 s rhythm
		"kahlschlag":
			e.data["kahl_cd"] = _kahl_every()
		"ansturm":
			# the whole Ansturm-Kette breaks off (D-143)
			e.state = 0
			e.data["kette_cd"] = Content.BOSS["kette_every"]
		"reichweite":
			e.data["reich_cd"] = _by_level(Content.BOSS["reich_every_p3" if e.phase >= 2 else "reich_every"])
	_end_cast(e)
	_clear_cast_hazards(e)
	e.data.erase("vote_segs")


func _clear_cast_hazards(e: SimEnemy) -> void:
	for h in hazards:
		if h.alive and h.data.get("cast", false) and int(h.data.get("enemy", -1)) == e.id:
			h.alive = false


func _cast_hazards(e: SimEnemy, type: int) -> Array:
	return hazards.filter(func(h): return h.alive and h.type == type and int(h.data.get("enemy", -1)) == e.id)


## Mirrors the encounter's running cast into boss_cast* (HUD, snapshot, balance bot).
func _update_boss_cast() -> void:
	boss_cast = ""
	boss_cast_t = 0.0
	boss_cast_left = 0.0
	for e in enemies:
		if e.alive and e.encounter != "" and e.cast != "":
			boss_cast = e.cast
			boss_cast_t = _cast_progress(e)
			boss_cast_left = maxf(0.0, e.cast_time - e.cast_t)
			return


## True while a stun would land on some encounter unit (no Pressekonferenz, no
## Standfest); for the balance bot (D-112).
func boss_can_stun() -> bool:
	for e in enemies:
		if e.alive and e.encounter != "" and e.presse_t <= 0.0 and e.standfest_t <= 0.0 and not _status_immune(e):
			return true
	return false


## A random point inside the arena, `margin` px from the walls (GDD §5a).
func _arena_point(margin: float) -> Vector2:
	var r := Arena.INNER.grow(-margin)
	return Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))


# --- Bosses ------------------------------------------------------------------

func _ai_boss(e: SimEnemy, spd: float, dt: float) -> void:
	match e.tid:
		"geschichtslehrer": _boss_lehrer(e, spd, dt)
		"sauerlaender": _boss_sauerlaender(e, spd, dt)
		"eidgenossin": _boss_eidgenossin(e, spd, dt)


func _ring(e: SimEnemy, proj: String, count: int, speed: float, dmg: float, offset := 0.0) -> void:
	for i in count:
		_enemy_shot(e, proj, Vector2.RIGHT.rotated(offset + TAU * i / count), speed, dmg, 5.0)


func _spread(e: SimEnemy, proj: String, target: Vector2, count: int, arc: float, speed: float, dmg: float) -> void:
	var base := (target - e.pos).angle()
	for i in count:
		var a := base + (float(i) / maxf(1, count - 1) - 0.5) * arc if count > 1 else base
		_enemy_shot(e, proj, Vector2.RIGHT.rotated(a), speed, dmg, 5.0)


## Der Geschichtslehrer: book rings; "Wende um 180 Grad" first 4 s into the fight,
## then every 10 s, after a 1.5 s countdown (cast "wende", GDD §14, D-104, D-112).
## e.timer2 counts real time up to the next countdown.
func _boss_lehrer(e: SimEnemy, spd: float, dt: float) -> void:
	_boss_phase(e)
	_ai_chase(e, spd, dt)
	e.timer -= dt
	if e.timer <= 0.0:
		e.timer = 3.0 - e.phase * 0.5
		_ring(e, "buch", 10 + e.phase * 2, 220.0, e.dmg * 0.6, rng.randf() * TAU)
	var b := Content.BOSS
	if e.cast == "wende":
		e.cast_t += _ab_dt(e)
		if e.cast_t >= e.cast_time:
			_end_cast(e)
			_wende(e)
		return
	e.timer2 += _real_dt
	var first := not e.data.has("wende_done")
	if e.timer2 >= float(b["wende_first"] if first else b["wende_every"]) - float(b["wende_warn"]):
		e.timer2 = 0.0
		_start_cast(e, "wende", b["wende_warn"])
		_event(["say", e.pos, "SAY_LEHRER_WENDE", ""])


func _wende(e: SimEnemy) -> void:
	var b := Content.BOSS
	var dur: float = b["wende_time_l4"] if difficulty >= 4 else b["wende_time"]
	var axis := rng.randi_range(1, 2) if difficulty >= int(b["wende_axis_from"]) else 0   # Teilwende from 25 %
	e.data["wende_done"] = true
	for p in players.values():
		if p.state == 0:
			p.reversed = dur
			p.reverse_axis = axis
	if e.phase >= 1:
		# phase 2: his flying book rings turn around and come back through the arena
		var t_buch := Content.idx(Content.PROJ_ORDER, "buch")
		for pr in projectiles:
			if pr.alive and pr.owner == 0 and pr.type == t_buch:
				pr.vel = -pr.vel
				pr.life = maxf(pr.life, float(b["wende_book_life"]))
	_event(["wende", dur, axis])
	_event(["sfx", "wende", Vector2.INF])


## Der Sauerländer: Bierdeckel / Sondervermögen / Zirkuszelt, plus "Abstimmung,
## egal mit wem" in every phase and "Kahlschlag" from phase 2 (D-104, D-109, D-110).
func _boss_sauerlaender(e: SimEnemy, spd: float, dt: float) -> void:
	_boss_phase(e)
	if e.encounter != "":
		if _vote_step(e, spd, dt):
			return
		if _kahlschlag_step(e):
			return
	var p := _target_player(e)
	match e.phase:
		0:
			if e.target == Vector2.ZERO or e.pos.distance_to(e.target) < 12.0:
				e.target = _arena_point(120.0)   # the whole arena (GDD §5a; was the old 1600 × 898 field)
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
				_money_rain(e)
		2:
			_ai_chase(e, spd * 1.2, dt)
			e.timer -= dt
			if e.timer <= 0.0:
				e.timer = 3.0
				for i in 3:
					var pr := _enemy_shot(e, "zirkusball", Vector2.RIGHT.rotated(rng.randf() * TAU), 300.0, e.dmg * 0.7, 6.0)
					pr.wall_bounce = true
					pr.radius = 14.0


## Sondervermögen: 8 notes anywhere in the arena (GDD §5a; was the old field).
func _money_rain(e: SimEnemy) -> void:
	for i in 8:
		_drop(Content.idx(Content.PICKUP_ORDER, "geldschein"), _arena_point(60.0), 2, 4.0)
	_event(["say", e.pos, "SAY_SONDERVERMOEGEN", ""])


# --- Sauerländer: "Abstimmung, egal mit wem" (D-104, D-109) -----------------------

## Runs the vote; true while it takes over the turn (walking there, voting).
func _vote_step(e: SimEnemy, spd: float, dt: float) -> bool:
	var b := Content.BOSS
	var d := e.data
	if d.get("phase_start", false):
		d.erase("phase_start")
		d["vote_cd"] = 0.0   # every phase change starts a vote
	var segs: Array = d.get("vote_segs", [])
	if segs.is_empty():
		d["vote_cd"] = float(d.get("vote_cd", b["vote_every"])) - _ab_dt(e)
		if d["vote_cd"] > 0.0 or e.cast != "":
			return false
		d["vote_cd"] = b["vote_every"]
		segs = _vote_pick(e.pos)
		if segs.is_empty():
			return false   # no intact segment left anywhere
		d["vote_segs"] = segs
		d["vote_walk"] = 0.0
		_vote_open(e, segs)
		_event(["say", e.pos, "SAY_VOTE_START", ""])
		return true
	if e.cast != "abstimmung":
		# hurry to the segment; the vote starts on arrival (after vote_walk_max s at the latest)
		var spot := _vote_spot(segs, e.radius + 40.0)   # his feet stay clear of the wall
		_move_toward(e, spot, spd * float(b["vote_walk"]), dt)
		d["vote_walk"] = float(d["vote_walk"]) + _real_dt
		if e.pos.distance_to(spot) < 6.0 or d["vote_walk"] >= float(b["vote_walk_max"]):
			_start_cast(e, "abstimmung", _by_level(b["vote_time"]))
		return true
	e.cast_t += _ab_dt(e)
	var left := 1.0 - _cast_progress(e)
	for h in hazards:
		if h.alive and h.data.get("cast", false) and int(h.data.get("enemy", -1)) == e.id:
			h.life = maxf(0.001, left)
	if plenum_occupied(e) >= plenum_needed() or e.cast_dmg >= _by_level(b["vote_dmg"]) * e.max_hp:
		_vote_fail(e)
	elif e.cast_t >= e.cast_time:
		_vote_pass(e)
	return true


## Segments to vote on: the side with the fewest holes that still has an intact
## segment (ties: the side nearest to `from`), its intact segment nearest to
## `from`; from vote_double_from also an intact neighbour on the same side.
func _vote_pick(from: Vector2) -> Array:
	var best_side := -1
	var best_holes := 1 << 20
	var best_d := INF
	for side in 4:
		var holes := 0
		var intact := 0
		for k in int(Arena.SIDE_COUNT[side]):
			if wall[int(Arena.SIDE_FIRST[side]) + k]:
				intact += 1
			else:
				holes += 1
		if intact == 0:
			continue
		var mid := int(Arena.SIDE_FIRST[side]) + int(Arena.SIDE_COUNT[side]) / 2
		var dd := from.distance_to(Arena.seg_inner(mid, 0.0))
		if holes < best_holes or (holes == best_holes and dd < best_d):
			best_side = side
			best_holes = holes
			best_d = dd
	if best_side < 0:
		return []
	var first := int(Arena.SIDE_FIRST[best_side])
	var last := first + int(Arena.SIDE_COUNT[best_side]) - 1
	var seg := -1
	var sd := INF
	for i in range(first, last + 1):
		if wall[i] and from.distance_to(Arena.seg_inner(i, 0.0)) < sd:
			sd = from.distance_to(Arena.seg_inner(i, 0.0))
			seg = i
	var out := [seg]
	if difficulty >= int(Content.BOSS["vote_double_from"]):
		var nb := -1
		for i in [seg - 1, seg + 1]:
			if i >= first and i <= last and wall[i]:
				if nb < 0 or from.distance_to(Arena.seg_inner(i, 0.0)) < from.distance_to(Arena.seg_inner(nb, 0.0)):
					nb = i
		if nb >= 0:
			out.append(nb)
	return out


## Where he stands to vote: `d` px in front of the voted segment(s).
static func _vote_spot(segs: Array, d: float) -> Vector2:
	var c := Vector2.ZERO
	for s in segs:
		c += Arena.seg_inner(int(s), d)
	return c / maxf(1.0, segs.size())


## The Plenum circles in front of the voted segment(s): one per player, in a row
## along the wall, shifted as a whole to stay inside the arena.
static func plenum_spots(segs: Array, n: int) -> Array:
	var b := Content.BOSS
	var r: float = b["plenum_radius"]
	var base := _vote_spot(segs, float(b["plenum_dist"]))
	var inward := Arena.inward(int(segs[0]))
	var along := Vector2(-inward.y, inward.x)
	var pts := []
	for i in n:
		pts.append(base + along * (i - (n - 1) * 0.5) * float(b["plenum_spacing"]))
	var shift := Vector2.ZERO
	for q in pts:
		var c := Arena.clamp_inner(q, r + 10.0)
		if (c - q).length() > shift.length():
			shift = c - q
	for i in pts.size():
		pts[i] = Arena.clamp_inner(pts[i] + shift, r + 10.0)
	return pts


func _vote_open(e: SimEnemy, segs: Array) -> void:
	for s in segs:
		var h := SimHazard.new()
		h.type = Content.idx(Content.HAZARD_ORDER, "abstimmung")
		h.pos = Arena.seg_center(int(s))   # in the wall: the view finds the segment with Arena.wall_at
		h.radius = Arena.seg_len(int(s)) * 0.5
		h.data = {"cast": true, "enemy": e.id, "seg": int(s)}
		hazards.append(h)
	for c in plenum_spots(segs, num_players()):
		var h := SimHazard.new()
		h.type = Content.idx(Content.HAZARD_ORDER, "plenum")
		h.pos = c
		h.radius = Content.BOSS["plenum_radius"]
		h.data = {"cast": true, "enemy": e.id}
		hazards.append(h)


## Plenum circles of e's vote with at least one living player inside.
func plenum_occupied(e: SimEnemy) -> int:
	var n := 0
	for h in _cast_hazards(e, Content.idx(Content.HAZARD_ORDER, "plenum")):
		for p in players.values():
			if p.state == 0 and p.pos.distance_to(h.pos) <= h.radius:
				n += 1
				break
	return n


## Circles that must be occupied at the same time: all of them with 1–2 players,
## players − 1 from 3 players on (D-104).
func plenum_needed() -> int:
	var n := num_players()
	return n if n <= 2 else n - 1


func _vote_fail(e: SimEnemy) -> void:
	_end_cast(e)
	_clear_cast_hazards(e)
	e.data.erase("vote_segs")
	e.data["vote_cd"] = Content.BOSS["vote_every"]
	e.stun_t = maxf(e.stun_t, float(Content.BOSS["vote_fail_stun"]))   # his own stagger: no halving, no Standfest (D-107)
	_event(["say", e.pos, "SAY_VOTE_FAIL", ""])
	_event(["sfx", "streik", e.pos])


func _vote_pass(e: SimEnemy) -> void:
	var segs: Array = e.data.get("vote_segs", [])
	_end_cast(e)
	_clear_cast_hazards(e)
	e.data.erase("vote_segs")
	e.data["vote_cd"] = Content.BOSS["vote_every"]
	for s in segs:
		wall[int(s)] = false   # a hole that stays until it's repaired in the Späti
	var b := Content.BOSS
	var count := int(b["vote_adds"]) + int(b["vote_adds_per_player"]) * num_players()
	for i in count:
		if enemies.size() >= Content.MAX_ENEMIES or segs.is_empty():
			break
		var s := int(segs[i % segs.size()])
		var inward := Arena.inward(s)
		var along := Vector2(-inward.y, inward.x)
		var pos := Arena.seg_staging(s) + along * rng.randf_range(-40.0, 40.0)
		spawn_enemy(_random_afd(), pos)   # behind the wall: they come straight through the hole
	_event(["say", e.pos, "SAY_VOTE_PASS", ""])
	_event(["sfx", "vote", e.pos])
	meta_dirty = true


## A random AfD enemy type of this wave, by spawn weight.
func _random_afd() -> String:
	var pool := []
	var total := 0
	for tid in Content.ENEMY_ORDER:
		var d: Dictionary = Content.ENEMIES[tid]
		if d["faction"] == "afd" and d["weight"] > 0 and d["from_wave"] <= maxi(wave, 1):
			pool.append(tid)
			total += int(d["weight"])
	if pool.is_empty():
		return "besorgter_buerger"
	var r := rng.randi_range(0, total - 1)
	for tid in pool:
		r -= int(Content.ENEMIES[tid]["weight"])
		if r < 0:
			return tid
	return pool[0]


# --- Sauerländer: "Kahlschlag" (D-104, D-110) ----------------------------------------

func _kahl_every() -> float:
	var b := Content.BOSS
	return float(b["kahl_every_l3"] if difficulty >= 3 else b["kahl_every"])


## A cone that wipes the players' summons and zones; true while he winds up.
func _kahlschlag_step(e: SimEnemy) -> bool:
	var b := Content.BOSS
	if e.phase < int(b["kahl_from_phase"]):
		return false
	var d := e.data
	var t_kahl := Content.idx(Content.HAZARD_ORDER, "kahlschlag")
	if e.cast == "kahlschlag":
		e.cast_t += _ab_dt(e)
		for h in _cast_hazards(e, t_kahl):
			var fire_at: float = h.data["fire_at"]
			h.life = clampf(1.0 - e.cast_t / fire_at, 0.001, 1.0)
			if e.cast_t >= fire_at:
				h.alive = false
				_kahlschlag_hit(e, h.pos, h.ang)
		if e.cast_t >= e.cast_time:
			_end_cast(e)
			d["kahl_cd"] = _kahl_every()
		return true
	d["kahl_cd"] = float(d.get("kahl_cd", _kahl_every())) - _ab_dt(e)
	if d["kahl_cd"] > 0.0 or e.cast != "":
		return false
	var p := _target_player(e)
	if p == null:
		return false
	var warn := _telegraph(b["kahl_warn"])
	var ang := (p.pos - e.pos).angle()
	_kahl_cone(e, ang, warn)
	var total := warn
	if difficulty >= int(b["kahl_double_from"]):
		var turn := deg_to_rad(float(b["kahl_second_turn"])) * (1.0 if rng.randf() < 0.5 else -1.0)
		total = warn + float(b["kahl_second_delay"])
		_kahl_cone(e, ang + turn, total)
	_start_cast(e, "kahlschlag", total)
	return true


func _kahl_cone(e: SimEnemy, ang: float, fire_at: float) -> void:
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "kahlschlag")
	h.pos = e.pos
	h.radius = Content.BOSS["kahl_reach"]
	h.ang = ang
	h.data = {"cast": true, "enemy": e.id, "fire_at": fire_at}
	hazards.append(h)


## Lasting zones of the players' side that Kahlschlag wipes (D-110).
const KAHL_ZONES := ["kleber", "sitzblockade", "ziegel", "kreide"]


func _kahlschlag_hit(e: SimEnemy, origin: Vector2, ang: float) -> void:
	var b := Content.BOSS
	var half := deg_to_rad(float(b["kahl_arc"])) * 0.5
	var reach: float = b["kahl_reach"]
	for p in players.values():
		if p.state == 0 and in_cone(origin, ang, half, reach, p.pos, Content.PLAYER_RADIUS):
			damage_player(p, e.dmg * float(b["kahl_dmg"]))
	for s in summons:
		# every summon a player owns (not the Oma, not the turbines)
		if s.alive and s.owner > 0 and in_cone(origin, ang, half, reach, s.pos, 12.0):
			s.alive = false
	var zones := []
	for id in KAHL_ZONES:
		zones.append(Content.idx(Content.HAZARD_ORDER, id))
	for h in hazards:
		if h.alive and h.type in zones and in_cone(origin, ang, half, reach, h.pos, h.radius * 0.5):
			h.alive = false
	var hit := SimHazard.new()
	hit.type = Content.idx(Content.HAZARD_ORDER, "kahlschlag_hit")
	hit.pos = origin
	hit.radius = reach
	hit.ang = ang
	hit.life = 0.5
	hit.max_life = 0.5
	hazards.append(hit)
	_event(["say", e.pos, "SAY_KAHLSCHLAG", ""])
	_event(["sfx", "explosion", origin + Vector2.RIGHT.rotated(ang) * reach * 0.5])


## Is `pos` (a circle of radius `pad`) inside the cone at `origin`, direction `ang`,
## half-angle `half`, length `reach`?
static func in_cone(origin: Vector2, ang: float, half: float, reach: float, pos: Vector2, pad: float) -> bool:
	var d := pos - origin
	var l := d.length()
	if l > reach + pad:
		return false
	if l <= pad:
		return true
	return absf(angle_difference(ang, d.angle())) <= half + asin(minf(1.0, pad / l))


## Die Remigrantin, the final exam (GDD §14 "Final boss", D-140 to D-145):
## P1 Windmühlen der Schande (Ansturm-Kette, falling turbines, wing fans),
## P2 Remigration (Die Brandmauer hält, push rings, wing fans, Reichweite),
## P3 Steuerparadies (gold-bar shield fed by Briefkastenfirmen, gold bars, push
## rings, Reichweite); Wahlabend speeds everything up in long fights.
func _boss_eidgenossin(e: SimEnemy, spd: float, dt: float) -> void:
	_boss_phase(e)
	var b := Content.BOSS
	var k := _wahlabend(e)
	var p := _target_player(e)
	match e.phase:
		0:
			_ansturm_kette(e, p, spd * k, dt)
			e.timer3 -= dt * k
			if e.timer3 <= 0.0 and p and e.state == 0:
				e.timer3 = float(b["wing_every"][0])
				_wings(e, p)
		1:
			# Die Brandmauer hält (D-104, D-111): the Abschiebezone only in front of holes
			var z := _absch_zone()
			if z == null:
				z = SimHazard.new()
				z.type = Content.idx(Content.HAZARD_ORDER, "abschiebezone")
				z.pos = Vector2(Arena.CENTER.x, Arena.INNER.position.y + 35.0)   # marker; the band follows the wall
				z.dps = e.dmg * 0.4
				z.data = {"warn": true, "enemy": e.id}
				hazards.append(z)
				if not wall.has(false):
					_event(["say", e.pos, "SAY_REMIG_LUECKE", ""])   # no hole: the old band along every wall
			z.radius = band_width()
			if e.cast != "reichweite" and p:
				_move_toward(e, p.pos, spd * 0.5 * k, dt)
			if z.data.get("warn", false):
				# 2 s warning at phase start (B8): no damage, no push rings yet
				if e.cast != "remigration":
					_start_cast(e, "remigration", _telegraph(b["remig_warn"]))
				e.cast_t += _ab_dt(e)
				z.life = maxf(0.001, 1.0 - _cast_progress(e))
				if e.cast_t >= e.cast_time:
					_end_cast(e)
					z.data["warn"] = false
					z.life = z.max_life
					e.data["ring_cd"] = 0.0
					e.data["reich_cd"] = float(b["reich_first"])
				return
			e.data["ring_cd"] = float(e.data.get("ring_cd", 0.0)) - _ab_dt(e) * k
			if e.data["ring_cd"] <= 0.0:
				e.data["ring_cd"] = _by_level(b["ring_every"])
				_push_ring(e.pos, e.dmg * 0.3, true)
			e.timer3 -= dt * k
			if e.timer3 <= 0.0 and p and e.cast == "":
				e.timer3 = float(b["wing_every"][1])
				_wings(e, p)
			_reichweite_step(e, b["reich_every"], k)
		2:
			# Steuerparadies: gold-bar shield at the top, fed by the Briefkastenfirmen (D-142)
			if e.state == 0:
				e.state = 1
				e.shield_max = e.max_hp * float(b["shield"])
				e.shield = e.shield_max
				var z := _absch_zone()
				if z and z.data.get("warn", false):
					z.data["warn"] = false   # the band stays into phase 3 (D-111)
					z.life = z.max_life
				e.data["reich_cd"] = float(b["reich_first"])
				e.data["boxes"] = []
				e.data["box_back"] = 0.0
				for i in brief_count():
					_spawn_briefkasten(e, i)
				_event(["say", e.pos, "SAY_BRIEFKASTEN", ""])
			_briefkasten_step(e)
			if e.cast != "reichweite":
				_move_toward(e, Vector2(Arena.CENTER.x, Arena.INNER.position.y + 128.0), spd * k, dt)
			e.timer -= dt * k
			if e.timer <= 0.0 and p and e.cast == "":
				e.timer = float(b["gold_every"])
				_spread(e, "goldbarren", p.pos, 5, 1.0, 280.0, e.dmg * 0.5)
			e.timer2 -= _ab_dt(e) * k
			if e.timer2 <= 0.0:
				e.timer2 = float(b["p3_ring_every"])
				_push_ring(e.pos, e.dmg * 0.3)
			_reichweite_step(e, b["reich_every_p3"], k)


func _wings(e: SimEnemy, p: SimPlayer) -> void:
	var b := Content.BOSS
	var n: int = b["wing_count_l3"] if difficulty >= 3 else b["wing_count"]
	_spread(e, "fluegel", p.pos, n, 0.7 + 0.1 * (n - 3), 260.0, e.dmg * 0.6)


# --- Remigrantin P1: Ansturm-Kette (D-143) -----------------------------------------

## Charges per chain: 2 (3 from Umfrage 30 %), +1 from 3 players.
func kette_len() -> int:
	var b := Content.BOSS
	var n: int = b["kette_len_l4"] if difficulty >= 4 else b["kette_len"]
	return n + (1 if num_players() >= int(b["kette_coop_from"]) else 0)


## e.state: 0 walking, 1 wind-up (cast "ansturm", lane telegraph), 2 charging, 3 gap
## before the next charge of the chain. Each charge aims at a random living player,
## or at a turbine standing next to that player (Don Quixote).
func _ansturm_kette(e: SimEnemy, p: SimPlayer, spd: float, dt: float) -> void:
	var b := Content.BOSS
	var d := e.data
	match e.state:
		0:
			if p:
				_move_toward(e, p.pos, spd * 0.7, dt)
			d["kette_cd"] = float(d.get("kette_cd", 1.5)) - _ab_dt(e) * _wahl_k(e)
			if d["kette_cd"] <= 0.0 and p:
				d["kette_left"] = kette_len()
				_ansturm_windup(e, p)
		1:
			# wind-up (cast "ansturm"); a stun interrupts the whole chain (_cancel_cast)
			e.cast_t += _ab_dt(e)
			for h in _cast_hazards(e, Content.idx(Content.HAZARD_ORDER, "ansturm_bahn")):
				h.life = maxf(0.001, 1.0 - _cast_progress(e))
			if e.cast_t >= e.cast_time:
				_end_cast(e)
				_clear_cast_hazards(e)
				e.state = 2
				d["dash_left"] = float(b["ansturm_len"])
				d["dash_hit"] = {}
		2:
			var step := float(b["ansturm_speed"]) * _real_dt
			var start := e.pos
			e.pos = Arena.clamp_inner(e.pos + e.target * step, e.radius)
			d["dash_left"] = float(d["dash_left"]) - step
			var hit: Dictionary = d["dash_hit"]
			for q in players.values():
				if q.state == 0 and not hit.has(q.id) and q.pos.distance_to(e.pos) < e.radius + Content.PLAYER_RADIUS + 6.0:
					hit[q.id] = true
					damage_player(q, e.dmg * float(b["ansturm_dmg"]))
			var t_turb := Content.idx(Content.SUMMON_ORDER, "turbine")
			for s in summons:
				if s.alive and s.type == t_turb and s.pos.distance_to(e.pos) < e.radius + 28.0:
					s.alive = false
					_topple(e, s.pos, e.target)
			if d["dash_left"] <= 0.0 or e.pos.distance_to(start) < step * 0.5:
				# chain on (after a short gap) or back to walking
				d["kette_left"] = int(d.get("kette_left", 1)) - 1
				if int(d["kette_left"]) > 0:
					e.state = 3
					d["gap"] = float(b["kette_gap"])
				else:
					e.state = 0
					d["kette_cd"] = float(b["kette_every"])
		3:
			d["gap"] = float(d.get("gap", 0.0)) - _ab_dt(e)
			if d["gap"] <= 0.0:
				var alive: Array = players.values().filter(func(o): return o.state == 0)
				if alive.is_empty():
					e.state = 0
					d["kette_cd"] = float(b["kette_every"])
				else:
					_ansturm_windup(e, alive[rng.randi_range(0, alive.size() - 1)])


func _ansturm_windup(e: SimEnemy, p: SimPlayer) -> void:
	var b := Content.BOSS
	var aim := p.pos
	var t_turb := Content.idx(Content.SUMMON_ORDER, "turbine")
	var best := float(b["turbine_pull"])
	for s in summons:
		if s.alive and s.type == t_turb and s.pos.distance_to(p.pos) < best:
			best = s.pos.distance_to(p.pos)
			aim = s.pos
	e.target = (aim - e.pos).normalized() if aim.distance_to(e.pos) > 1.0 else Vector2.RIGHT.rotated(rng.randf() * TAU)
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "ansturm_bahn")
	h.pos = e.pos
	h.radius = float(b["ansturm_len"]) + e.radius
	h.ang = e.target.angle()
	h.data = {"cast": true, "enemy": e.id}
	hazards.append(h)
	_start_cast(e, "ansturm", _telegraph(b["ansturm_warn"]))
	e.state = 1


## A turbine she ran into falls in the charge direction: 1 s warning, then the
## rotor line hurts for 3 s (D-143).
func _topple(e: SimEnemy, at: Vector2, dir: Vector2) -> void:
	var b := Content.BOSS
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "rotor")
	h.pos = at
	h.radius = b["rotor_len"]
	h.ang = dir.angle()
	h.life = 1.0
	h.max_life = 1.0
	h.data = {"enemy": e.id, "t": 0.0, "warn": _telegraph(b["rotor_warn"]), "time": float(b["rotor_time"]),
		"dmg": e.dmg * float(b["rotor_dmg"])}
	hazards.append(h)
	_event(["say", at, "SAY_WINDMUEHLE", ""])
	_event(["sfx", "explosion", at])


## Is a circle (pos, pad) inside the lane from `origin` along `ang`, `length` long
## and 2 × half_w wide?
static func in_lane(origin: Vector2, ang: float, length: float, half_w: float, pos: Vector2, pad: float) -> bool:
	var local := (pos - origin).rotated(-ang)
	return local.x >= -pad and local.x <= length + pad and absf(local.y) <= half_w + pad


# --- Remigrantin P2/P3: Reichweite (D-141) ---------------------------------------

## Depth of the safe strip in front of intact segments.
func reich_depth() -> float:
	return float(Content.BOSS["reich_safe"])


## Safe from the Reichweite wave here? (Arena.reich_safe with the current wall.)
func reich_safe(pos: Vector2) -> bool:
	return Arena.reich_safe(pos, _wall_mask(), reich_depth())


## The nearest safe point (for the balance bot), or INF if none is left.
func reich_safe_spot(pos: Vector2) -> Vector2:
	var mask := Arena.reich_mask(_wall_mask())
	var best := Vector2.INF
	var bd := INF
	var depth := reich_depth() * 0.5
	for seg in WALL_SEGMENTS:
		if not (mask & (1 << seg)):
			continue
		var c := Arena.seg_inner(seg, depth)
		var inward := Arena.inward(seg)
		var along := Vector2(-inward.y, inward.x)
		var half := Arena.seg_len(seg) * 0.5 - 24.0
		var t := clampf((pos - c).dot(along), -half, half)
		var q := c + along * t
		if pos.distance_to(q) < bd:
			bd = pos.distance_to(q)
			best = q
	return best


func _reichweite_step(e: SimEnemy, every: Array, k: float) -> void:
	var b := Content.BOSS
	if e.cast == "reichweite":
		e.cast_t += _ab_dt(e)
		for h in _cast_hazards(e, Content.idx(Content.HAZARD_ORDER, "reichweite")):
			h.life = maxf(0.001, 1.0 - _cast_progress(e))
			h.pos = e.pos
		if e.cast_t >= e.cast_time:
			_end_cast(e)
			_clear_cast_hazards(e)
			_reichweite_hit(e)
			e.data["reich_cd"] = _by_level(every)
		return
	e.data["reich_cd"] = float(e.data.get("reich_cd", b["reich_first"])) - _ab_dt(e) * k
	if e.data["reich_cd"] > 0.0 or e.cast != "":
		return
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "reichweite")
	h.pos = e.pos
	h.radius = Arena.INNER.size.length()
	h.data = {"cast": true, "enemy": e.id}
	hazards.append(h)
	_start_cast(e, "reichweite", _telegraph(b["reich_warn"]))
	_event(["say", e.pos, "SAY_REICHWEITE", ""])
	if b["reich_ring"]:
		_push_ring(e.pos, e.dmg * 0.3, true)   # combined pattern: shoved toward a hole first


func _reichweite_hit(e: SimEnemy) -> void:
	var safe_one: SimPlayer = null
	for p in players.values():
		if p.state != 0:
			continue
		if reich_safe(p.pos):
			safe_one = p if safe_one == null else safe_one
		else:
			damage_player(p, e.dmg * float(Content.BOSS["reich_dmg"]))
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "reichweite_hit")
	h.pos = e.pos
	h.radius = Arena.INNER.size.length()
	h.life = 0.6
	h.max_life = 0.6
	hazards.append(h)
	_event(["sfx", "explosion", e.pos])
	if safe_one:
		_event(["say", safe_one.pos, "SAY_BRANDMAUER_STEHT", ""])   # the players answer


## For the balance bot and its metrics: is pos inside one of her danger hazards
## (lane, falling or lying rotor, the Reichweite wave outside the safe strips)?
func danger_at(h: SimHazard, pos: Vector2) -> bool:
	var b := Content.BOSS
	var tn: String = Content.HAZARD_ORDER[h.type]
	match tn:
		"ansturm_bahn":
			return in_lane(h.pos, h.ang, h.radius, float(b["lane_w"]) * 0.5, pos, Content.PLAYER_RADIUS)
		"rotor":
			return in_lane(h.pos, h.ang, h.radius, float(b["rotor_w"]) * 0.5, pos, Content.PLAYER_RADIUS)
		"reichweite":
			return not reich_safe(pos)
	return false


# --- Remigrantin P3: Briefkastenfirmen (D-142) -----------------------------------

## Where letterboxes stand: the four corners first, then the middles of the sides
## (never the top middle, her chalet), brief_inset px from the walls.
func _brief_spots() -> Array:
	var r := Arena.INNER.grow(-float(Content.BOSS["brief_inset"]))
	return [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y),
		Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Vector2(r.get_center().x, r.end.y)]


func _spawn_briefkasten(e: SimEnemy, slot := -1) -> void:
	var spots := _brief_spots()
	var pos: Vector2 = spots[slot] if slot >= 0 and slot < spots.size() else Vector2.INF
	if pos == Vector2.INF:
		# a new address: a free spot, away from the other boxes
		var free := []
		for s in spots:
			var ok := true
			for id in e.data["boxes"]:
				var o := _enemy_by_id(int(id))
				if o and o.alive and o.pos.distance_to(s) < 200.0:
					ok = false
			if ok:
				free.append(s)
		if free.is_empty():
			free = spots
		pos = free[rng.randi_range(0, free.size() - 1)]
	var box := spawn_enemy("briefkasten", pos)
	box.max_hp = e.max_hp * float(Content.BOSS["brief_hp"])
	box.hp = box.max_hp
	box.no_reward = true
	box.data["box_of"] = e.id
	e.data["boxes"].append(box.id)


func _enemy_by_id(id: int) -> SimEnemy:
	for o in enemies:
		if o.id == id:
			return o
	return null


## Living letterboxes recharge her shield (brief_regen of her max HP per second
## each). When the last one falls her shield breaks; brief_back s later all of them
## open again at new addresses and the shield regrows from zero (D-142).
func _briefkasten_step(e: SimEnemy) -> void:
	var b := Content.BOSS
	var keep := []
	for id in e.data["boxes"]:
		var o := _enemy_by_id(int(id))
		if o and o.alive:
			keep.append(id)
	var had: int = e.data["boxes"].size()
	e.data["boxes"] = keep
	if keep.size() > 0:
		if e.shield_max > 0.0:
			e.shield = minf(e.shield_max, e.shield + keep.size() * float(b["brief_regen"]) * e.max_hp * _ab_dt(e))
		return
	if had > 0:
		# the last letterbox is gone: the Steuerparadies cracks
		e.shield = 0.0
		e.data["box_back"] = _by_level(b["brief_back"])
		_event(["say", e.pos, "SAY_SHIELD_BROKEN", ""])
		meta_dirty = true
	e.data["box_back"] = float(e.data.get("box_back", 0.0)) - _ab_dt(e)
	if e.data["box_back"] <= 0.0:
		for i in brief_count():
			_spawn_briefkasten(e)
		_event(["say", e.pos, "SAY_BRIEFKASTEN_NEU", ""])


## Letterboxes per round: 3 solo, 4 from 2 players (one per corner, D-142).
func brief_count() -> int:
	var b := Content.BOSS
	return int(b["brief_count"]) + (int(b["brief_coop"]) if num_players() >= 2 else 0)


## Number of living letterboxes (HUD, bot, tests).
func briefkasten_alive() -> int:
	var t := Content.idx(Content.ENEMY_ORDER, "briefkasten")
	var n := 0
	for o in enemies:
		if o.alive and o.type == t:
			n += 1
	return n


# --- Wahlabend (D-144) ------------------------------------------------------------

## Advances her fight clock and returns the Wahlabend tempo factor: from wahl_from s
## (wahl_from_l4 from Umfrage 30 %) one step every wahl_every s, each step +wahl_step.
func _wahlabend(e: SimEnemy) -> float:
	var b := Content.BOSS
	e.data["fight_t"] = float(e.data.get("fight_t", 0.0)) + _real_dt
	var from: float = b["wahl_from_l4"] if difficulty >= 4 else b["wahl_from"]
	var t: float = e.data["fight_t"]
	var step := 0
	if t >= from:
		step = mini(int(b["wahl_max"]), 1 + int((t - from) / float(b["wahl_every"])))
	if step != int(e.data.get("wahl", 0)):
		e.data["wahl"] = step
		_event(["say", e.pos, "SAY_HOCHRECHNUNG", ""])
		_event(["hochrechnung", step])
		meta_dirty = true
	return _wahl_k(e)


func _wahl_k(e: SimEnemy) -> float:
	return 1.0 + float(Content.BOSS["wahl_step"]) * int(e.data.get("wahl", 0))


func _absch_zone() -> SimHazard:
	var t := Content.idx(Content.HAZARD_ORDER, "abschiebezone")
	for h in hazards:
		if h.alive and h.type == t:
			return h
	return null


## Width of the band in front of the holes (D-104): 110 px, 150 px from Umfrage
## 25 %, minus 10 px per extra player.
func band_width() -> float:
	var b := Content.BOSS
	var w: float = b["band_l3"] if difficulty >= 3 else b["band"]
	return maxf(20.0, w - float(b["band_per_player"]) * (num_players() - 1))


## Is pos inside the Abschiebezone? With holes: within `width` of a wall segment
## that is open or next to an open one on the same wall; without: the old band
## along every wall (GDD §14, D-111). The view draws the same with Arena.band_mask.
func in_band(pos: Vector2, width: float) -> bool:
	if not wall.has(false):
		return Arena.edge_dist(pos) < float(Arena.WALL["abschiebe_band"])
	if Arena.edge_dist(pos) >= width:
		return false
	var seg := Arena.facing_seg(pos)
	return seg >= 0 and (Arena.band_mask(_wall_mask()) & (1 << seg)) != 0


func _wall_mask() -> int:
	var mask := 0
	for i in WALL_SEGMENTS:
		if wall[i]:
			mask |= 1 << i
	return mask


## The front of the hole nearest to pos, or INF without holes.
func _nearest_hole(pos: Vector2) -> Vector2:
	var best := Vector2.INF
	var bd := INF
	for i in WALL_SEGMENTS:
		if not wall[i]:
			var q := Arena.seg_inner(i, 0.0)
			if pos.distance_to(q) < bd:
				bd = pos.distance_to(q)
				best = q
	return best


## to_hole: "Die Brandmauer hält" (D-111) shoves each player toward the hole
## nearest to them; otherwise everyone goes toward the wall nearest to her.
func _push_ring(pos: Vector2, dmg: float, to_hole := false) -> void:
	var h := SimHazard.new()
	h.type = Content.idx(Content.HAZARD_ORDER, "push_ring")
	h.pos = pos
	h.radius = 0.0
	h.life = 2.5
	h.max_life = 2.5
	# every ring drives everyone toward the same wall: the one nearest to her (GDD §5a)
	h.data = {"dmg": dmg, "hit": {}, "dir": Arena.toward_wall(Arena.clamp_inner(pos, 0.0)), "to_hole": to_hole}
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
			# bounce off the inner faces of the four walls
			var inner := Arena.INNER
			if (pr.pos.x < inner.position.x and pr.vel.x < 0.0) or (pr.pos.x > inner.end.x and pr.vel.x > 0.0):
				pr.vel.x = -pr.vel.x
			if (pr.pos.y < inner.position.y and pr.vel.y < 0.0) or (pr.pos.y > inner.end.y and pr.vel.y > 0.0):
				pr.vel.y = -pr.vel.y
		elif pr.pos.x < -50 or pr.pos.x > ARENA.x + 50 or pr.pos.y < -50 or pr.pos.y > ARENA.y + 50:
			pr.alive = false
			continue
		if pr.harmless:
			continue
		# intact wall segments and corner pillars block shots, on every side
		var ws := Arena.wall_at(pr.pos)
		if ws == -2 or (ws >= 0 and wall[ws]):
			pr.alive = false
			continue
		if pr.owner == 0:
			for s in summons:
				if s.alive and s.type == turbine_t and s.pos.distance_to(pr.pos) < 34.0:
					pr.alive = false
					break
			for s in _decoys:
				if s.alive and s.pos.distance_to(pr.pos) < 18.0 + pr.radius:
					_hurt_decoy(s, pr.dmg)   # shots at the Pappkamerad (GDD §11)
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
		_damage_enemy(e, pr.dmg, src, pr.crit, pr.vel.normalized(), 20.0, pr.source)
		if def.has("poison") and src:
			var tier := 1
			for w in src.weapons:
				if w["id"] == pr.weapon:
					tier = w["tier"]
			_apply_poison(e, def["poison"][tier - 1] * (1.0 + src.stats["status"] * 0.1) * (Content.RED_BUILD["status"] if src.flags.has("status_build") else 1.0), def["poison_time"], src.id, pr.source)
		if src and (def.has("silence") or def.has("file") or def.has("sticker")):
			_v3_on_hit(e, def, src, pr.source)
		if def.has("splash"):
			for o in _query(pr.pos, def["splash"]):
				if o != e:
					_damage_enemy(o, pr.dmg * 0.5, src, false, Vector2.ZERO, 0.0, pr.source)
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
			# bounce_range / bounce_falloff (Infostand, D-115): jump only that far, lose damage per
			# jump, and end when nobody is in reach; without them the old rule (Gendersternchen)
			var next := _nearest_enemy(pr.pos, def.get("bounce_range", 260.0), pr.hit_ids)
			if next:
				pr.vel = (next.pos - pr.pos).normalized() * pr.vel.length()
				pr.life = maxf(pr.life, 0.6)
				pr.dmg *= 1.0 - float(def.get("bounce_falloff", 0.0))
				return
			if def.has("bounce_range"):
				pr.alive = false
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
	var t_brei := Content.idx(Content.HAZARD_ORDER, "brei_marker")
	var t_ziegel := Content.idx(Content.HAZARD_ORDER, "ziegel")
	var t_kreide := Content.idx(Content.HAZARD_ORDER, "kreide")
	var t_kette := Content.idx(Content.HAZARD_ORDER, "kette")
	var t_paragraf := Content.idx(Content.HAZARD_ORDER, "paragraf")
	var t_sitz := Content.idx(Content.HAZARD_ORDER, "sitzblockade")
	var t_absch := Content.idx(Content.HAZARD_ORDER, "abschiebezone")
	var t_ring := Content.idx(Content.HAZARD_ORDER, "push_ring")
	var t_rotor := Content.idx(Content.HAZARD_ORDER, "rotor")
	var ziegel_hit := {}   # "owner/weapon/wall/enemy" already damaged this tick (D-089)
	var boss_ids := {}     # living enemies that own cast telegraphs
	for e in enemies:
		if e.alive and e.elite:
			boss_ids[e.id] = true
	for h in hazards:
		if not h.alive:
			continue
		if h.data.get("cast", false):
			# boss telegraphs (Abstimmung, Plenum, Kahlschlag): their cast sets life, they
			# go with their boss (D-108)
			if not boss_ids.has(int(h.data.get("enemy", -1))):
				h.alive = false
			continue
		if h.type == t_absch:
			# Abschiebezone (D-111): harmless while it is announced, then a lasting band
			if h.data.get("warn", false):
				if not boss_ids.has(int(h.data.get("enemy", -1))):
					h.data["warn"] = false
				continue
			h.life = h.max_life
			for p in players.values():
				if p.state == 0 and p.iframes <= 0.0 and in_band(p.pos, h.radius):
					damage_player(p, h.dps * 0.5)
			continue
		if h.type == t_rotor:
			# a fallen turbine (D-143): life 1 -> 0.5 while it falls (warning), 0.5 -> 0
			# while the rotor line lies there and hurts
			var rt: float = float(h.data["t"]) + dt
			h.data["t"] = rt
			var warn: float = h.data["warn"]
			var lie: float = h.data["time"]
			if rt < warn:
				h.life = 1.0 - 0.5 * rt / warn
			elif rt < warn + lie:
				h.life = 0.5 * (1.0 - (rt - warn) / lie)
				var half: float = float(Content.BOSS["rotor_w"]) * 0.5
				for p in players.values():
					if p.state == 0 and p.iframes <= 0.0 and in_lane(h.pos, h.ang, h.radius, half, p.pos, Content.PLAYER_RADIUS):
						damage_player(p, h.data["dmg"])
			else:
				h.alive = false
			continue
		h.life -= dt
		if h.type == t_ring:
			h.radius = (1.0 - h.life / h.max_life) * 900.0
			for p in players.values():
				if p.state == 0 and not h.data["hit"].has(p.id) and absf(p.pos.distance_to(h.pos) - h.radius) < 24.0:
					h.data["hit"][p.id] = true
					var away = (p.pos - h.pos).normalized()
					var wdir: Vector2 = h.data.get("dir", Arena.toward_wall(p.pos))
					if h.data.get("to_hole", false):
						var hole := _nearest_hole(p.pos)
						if hole != Vector2.INF and hole.distance_to(p.pos) > 1.0:
							wdir = (hole - p.pos).normalized()
					p.knock = (wdir * 0.75 + away * 0.25).normalized() * 700.0
					damage_player(p, h.data["dmg"])
		elif h.type == t_kleber:
			for e in _query(h.pos, h.radius):
				_apply_slow(e, h.slow, 0.3)  # status immunity only stops the slow (D-079)
				_damage_zone(e, h, h.dps * dt)
		elif h.type == t_miet:
			for p in players.values():
				if p.state == 0 and not p.flags.has("mietendeckel") and p.pos.distance_to(h.pos) < h.radius:
					p.mietzone_acc += dt
					if p.mietzone_acc >= 0.5:
						p.mietzone_acc = 0.0
						if p.pfand > 0:
							p.pfand -= 1
							meta_dirty = true
		elif h.type == t_ker:
			for p in players.values():
				if p.state != 0:
					continue
				var inside = p.pos.distance_to(h.pos) < h.radius + Content.PLAYER_RADIUS
				if inside and p.iframes <= 0.0:
					damage_player(p, h.dps * 0.5)
		elif h.type == t_brei and h.life <= 0.0:
			var owner: SimPlayer = players.get(h.owner)
			for e in _query(h.pos, h.radius):
				_damage_enemy(e, h.data["dmg"], owner, h.data.get("crit", false), (e.pos - h.pos).normalized(), 40.0, h.data.get("src", ""))
			var boom := SimHazard.new()
			boom.type = Content.idx(Content.HAZARD_ORDER, "explosion")
			boom.pos = h.pos
			boom.radius = h.radius
			boom.life = 0.4
			boom.max_life = 0.4
			hazards.append(boom)
			_event(["sfx", "explosion", h.pos])
		elif h.type == t_kreide:
			for e in _query(h.pos, h.radius):
				_damage_zone(e, h, h.dps * dt)
		elif h.type == t_kette:
			# Menschenkette links are only the chain's picture; the lamppost summon
			# moves them and deals the damage once per enemy (_step_chain, D-094)
			var ctl: SimSummon = h.data.get("ctl")
			if ctl == null or not ctl.alive or not summons.has(ctl):
				h.alive = false
			continue
		elif h.type == t_ziegel:
			# D-089: an enemy takes each wall's damage once per tick, however
			# many of its five bricks it touches; two walls both hurt.
			var wall_key := "%d/%s/%d" % [h.owner, h.data.get("src", ""), int(h.data.get("wall", 0))]
			for e in _query(h.pos, h.radius):
				_apply_slow(e, h.slow, 0.3)
				var hit_key := "%s/%d" % [wall_key, e.id]
				if ziegel_hit.has(hit_key):
					continue
				ziegel_hit[hit_key] = true
				_damage_zone(e, h, h.dps * dt)
		elif h.type == t_paragraf:
			var target: SimEnemy = null
			for e in enemies:
				if e.alive and e.id == int(h.data.get("enemy", -1)):
					target = e
					break
			if target == null:
				h.alive = false
				continue
			h.pos = target.pos
			if h.life <= 0.0:
				_damage_enemy(target, h.data["dmg"], players.get(h.owner), h.data.get("crit", false), Vector2.ZERO, 0.0, h.data.get("src", ""))
				_event(["say", target.pos, "SAY_NICHTIG", ""])
		elif h.data.get("wumms", false) and h.life <= 0.0:
			var wp: SimPlayer = players.get(h.owner)
			if wp:
				_wumms(wp, h.pos)
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
				_drop(t_passant, _arena_point(80.0), 1)   # anywhere in the arena (GDD §5a)
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
				best.log["pfand_collected"] += k.value
				best.collected_wave += k.value
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
			h.pos = Arena.CENTER + Vector2(rng.randf_range(-400.0, 400.0), rng.randf_range(-200.0, 200.0))   # around the middle (GDD §5a)
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
		var lines: Array = e.def.get("say", [])
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
	_ensure_build_weapon(p)


## balancing.md §5: every Späti offers at least one weapon for the player's build
## (scaling match >= 0.5, or the same weapon as one they hold, to combine).
func _ensure_build_weapon(p: SimPlayer) -> void:
	if p.weapons.is_empty():
		return
	var style := weapon_style(p)
	var owned := {}
	for w in p.weapons:
		owned[w["id"]] = true
	var fits := func(id: String) -> bool: return owned.has(id) or style_match(style, id) >= 0.5
	for o in p.offers:
		if o["kind"] == "weapon" and fits.call(str(o["id"])):
			return
	var candidates := []
	for id in Content.WEAPON_ORDER:
		if fits.call(id):
			candidates.append(id)
	if candidates.is_empty():
		return
	var slot := p.offers.size() - 1
	for i in p.offers.size():
		if p.offers[i]["kind"] == "item":
			slot = i
			break
	p.offers[slot] = _weapon_offer(p, candidates[rng.randi_range(0, candidates.size() - 1)])


## A shop offer for weapon `id`; the tier is rolled by wave and Glück.
func _weapon_offer(p: SimPlayer, id: String) -> Dictionary:
	var luck: float = p.stats["luck"]
	var next_wave := wave + 1
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


func _roll_offer(p: SimPlayer) -> Dictionary:
	var luck: float = p.stats["luck"]
	var next_wave := wave + 1
	if rng.randf() < 0.35:
		return _weapon_offer(p, _pick_weapon(p))
	var pool := []
	var total_w := 0.0
	for id in Content.ITEM_ORDER:
		var d: Dictionary = Content.ITEMS[id]
		if d.get("no_shop", false) or (d.get("coop_only", false) and num_players() <= 1):
			continue
		var w := 0.25 if d.get("hidden", false) else Content.rarity_weight(int(d["rarity"]), next_wave, luck)
		if w <= 0.0:
			continue
		pool.append([id, w])
		total_w += w
	var r2 := rng.randf() * total_w
	var pick: String = pool[0][0]
	for entry in pool:
		r2 -= entry[1]
		if r2 <= 0.0:
			pick = entry[0]
			break
	return {"kind": "item", "id": pick, "tier": 1, "rarity": int(Content.ITEMS[pick]["rarity"]),
		"price": _price(Content.item_price(pick, next_wave)), "sold": false}


## Shop weapon pick favouring the player's style (GDD §6): weight 1 + 2 × how
## well a weapon's scaling matches the scaling of the weapons held.
func _pick_weapon(p: SimPlayer) -> String:
	var style := weapon_style(p)
	var total := 0.0
	var weights := []
	for id in Content.WEAPON_ORDER:
		var w := 1.0 + STYLE_BIAS * style_match(style, id)
		weights.append(w)
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return Content.WEAPON_ORDER[i]
	return Content.WEAPON_ORDER[Content.WEAPON_ORDER.size() - 1]


## Share of each scaling stat (melee/ranged/status/summon) across the weapons
## held; every weapon counts once. {} without weapons.
static func weapon_style(p: SimPlayer) -> Dictionary:
	var style := {}
	for w in p.weapons:
		var scale: Dictionary = Content.WEAPONS[w["id"]].get("scale", {})
		var sum := 0.0
		for s in scale:
			sum += float(scale[s])
		for s in scale:
			style[s] = float(style.get(s, 0.0)) + float(scale[s]) / sum / p.weapons.size()
	return style


## 0..1: how much of weapon `id`'s scaling lies in `style`.
static func style_match(style: Dictionary, id: String) -> float:
	var scale: Dictionary = Content.WEAPONS[id].get("scale", {})
	var sum := 0.0
	for s in scale:
		sum += float(scale[s])
	var m := 0.0
	for s in scale:
		m += float(style.get(s, 0.0)) * float(scale[s]) / sum
	return m


func _price(base: int) -> int:
	var m = 1.0 + _vertrag_def().get("price", 0.0)
	if streik_discount:
		m *= 0.8
	return maxi(1, int(round(base * m)))


## End of a co-op wave: whoever picked up far more Pfand than the poorer players
## gives part of it to the poorest (balancing.md §5a).
func _apply_reichensteuer() -> void:
	var collected := {}
	for p in players.values():
		p.tax_wave = 0
		if p.state != 2:
			collected[p.id] = p.collected_wave
	if collected.size() < 2:
		return
	var delta := reichensteuer(collected)
	for id in delta:
		var d := int(delta[id])
		if d == 0:
			continue
		var p: SimPlayer = players[id]
		p.pfand = maxi(0, p.pfand + d)
		p.tax_wave = d
		if d < 0:
			p.log["tax_paid"] += -d
			_event(["say", p.pos, "SAY_REICHENSTEUER", ""])
		else:
			p.log["tax_received"] += d
	meta_dirty = true


## Reichensteuer (balancing.md §5a): Pfand change per player id for one wave's
## collected Pfand (`collected`: id -> amount). Candidates pay rate × the part above
## threshold × the average of the poorer players. Richest first: a candidate whom the
## richer payers' pot would lift anyway receives instead of paying. The pot raises
## the poorest first (water filling) and never lifts anyone above a payer's
## remainder / (1 + reich_keep).
static func reichensteuer(collected: Dictionary, benchmark := "") -> Dictionary:
	var b := Content.BALANCE
	var ids := collected.keys()
	var n := ids.size()
	var out := {}
	for id in ids:
		out[id] = 0
	if n < 2:
		return out
	var rates: Dictionary = b["reich_rate"]
	var rate := float(rates.get(n, rates[4]))
	if benchmark == "":
		benchmark = str(b["reich_benchmark"])
	var poorer_only := benchmark == "poorer"
	var cand := {}
	for id in ids:
		# Benchmark: average of the poorer players (or of all others).
		var others := 0.0
		var count := 0
		for o in ids:
			if o != id and (not poorer_only or float(collected[o]) < float(collected[id])):
				others += float(collected[o])
				count += 1
		if count == 0:
			continue
		var excess := float(collected[id]) - float(b["reich_threshold"]) * others / count
		if excess >= float(b["reich_min"]):
			cand[id] = rate * excess
	# Accept payers richest first (ties together); stop at a candidate that the pot of
	# the richer payers would lift anyway: they and everyone poorer receive.
	var values := []
	for id in cand:
		if not values.has(float(collected[id])):
			values.append(float(collected[id]))
	values.sort()
	values.reverse()
	var tax := {}
	for v in values:
		if not tax.is_empty():
			var pot := 0.0
			for g in tax:
				pot += float(tax[g])
			var below := []
			for o in ids:
				if not tax.has(o):
					below.append(float(collected[o]))
			if _water_level(below, pot) >= v:
				break
		for id in cand:
			if float(collected[id]) == v:
				tax[id] = cand[id]
	if tax.is_empty():
		return out
	# A payer never falls below a non-paying player who was poorer.
	for g in tax.keys():
		var under := 0.0
		for o in ids:
			if not tax.has(o) and float(collected[o]) < float(collected[g]):
				under = maxf(under, float(collected[o]))
		tax[g] = minf(float(tax[g]), float(collected[g]) - under)
	var pool := 0.0
	var cap_level := INF
	for g in tax:
		pool += float(tax[g])
		cap_level = minf(cap_level, (float(collected[g]) - float(tax[g])) / (1.0 + float(b["reich_keep"])))
	var receivers := ids.filter(func(i): return not tax.has(i))
	if receivers.is_empty() or pool <= 0.0:
		return out
	var levels := []
	for r in receivers:
		levels.append(float(collected[r]))
	var level := minf(_water_level(levels, pool), cap_level)
	var given := 0
	for r in receivers:
		var add := maxi(0, int(floor(level - float(collected[r]))))
		out[r] = add
		given += add
	# The payers pay exactly what was handed out, in proportion to their tax.
	var givers := tax.keys()
	var paid := 0
	for i in givers.size():
		var share := given - paid if i == givers.size() - 1 else int(floor(given * float(tax[givers[i]]) / pool))
		out[givers[i]] = -share
		paid += share
	return out


## Water filling: the common level the lowest of `values` reach when `pot` is
## poured onto them from the bottom up.
static func _water_level(values: Array, pot: float) -> float:
	if values.is_empty():
		return -INF
	var levels := values.duplicate()
	levels.sort()
	var level: float = levels[0]
	var rem := pot
	for i in levels.size():
		var next: float = levels[i + 1] if i + 1 < levels.size() else INF
		var need := (i + 1) * (next - level)
		if need >= rem:
			return level + rem / (i + 1)
		rem -= need
		level = next
	return level


func _make_levelup_options(p: SimPlayer) -> void:
	p.levelup_options.clear()
	if p.levelups <= 0:
		return
	var stats := Content.STATS.duplicate()
	_shuffle(stats)
	var mults: Array = Content.BALANCE["levelup_rarity_mult"]
	for i in 4:
		# Rarity like the items (balancing.md §4): same weights per wave and Glück.
		var total := 0.0
		var weights := []
		for r in range(1, 5):
			var wgt := Content.rarity_weight(r, wave + 1, p.stats["luck"])
			weights.append(wgt)
			total += wgt
		var roll := rng.randf() * total
		var rarity := 1
		for r in weights.size():
			roll -= weights[r]
			if roll <= 0.0:
				rarity = r + 1
				break
		p.levelup_options.append({"stat": stats[i], "rarity": rarity,
			"amount": Content.LEVELUP_AMOUNTS[stats[i]] * float(mults[rarity - 1])})


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
	if p == null or p.state == 2 or p.state == 3:
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
				var twin := find_twin(p, o["id"], o["tier"], -1)
				if twin < 0 and p.weapons.size() >= p.max_weapons:
					return _deny(p, "DENY_SLOTS_FULL")
				_add_weapon(p, o["id"], o["tier"])
				p.bought_weapons += 1
				if twin >= 0:
					_combine(p, twin, p.weapons.size() - 1)
			else:
				p.items.append(o["id"])
				if o["id"] == "maut_vertrag":
					_give_pfand(p, Content.RED_BUILD["maut_now"])
				if o["id"] == "vogelschiss":
					_grant(p, "ach_vogelschiss")
				_recompute(p)
			p.pfand -= o["price"]
			p.spent += o["price"]
			p.buys += 1
			p.log["pfand_spent"] += o["price"]
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
			if p.sources.has(_wkey(w)):
				p.sources[_wkey(w)]["sold"] = true
			p.weapons.remove_at(i)
			summons = summons.filter(func(s): return not (s.owner == p.id and s.weapon_index == i))
			return true
		"combine":
			var i := int(arg)
			if i < 0 or i >= p.weapons.size():
				return false
			var j := find_twin(p, p.weapons[i]["id"], p.weapons[i]["tier"], i)
			if j < 0:
				return _deny(p, "DENY_NO_TWIN")
			_combine(p, i, j)
			return true
		"discard_item":
			# arg: {"id": item id, "count": n} (count < 0 = all of them). No refund.
			var spec: Dictionary = arg if arg is Dictionary else {}
			var id := str(spec.get("id", ""))
			var count := int(spec.get("count", 1))
			var removed := 0
			for i in range(p.items.size() - 1, -1, -1):
				if p.items[i] == id and (count < 0 or removed < count):
					p.items.remove_at(i)
					removed += 1
			if removed == 0:
				return false
			_recompute(p)
			_event(["sfx", "ui_click", Vector2.INF])
			return true
		"levelup":
			var i := int(arg)
			if p.levelups <= 0 or i < 0 or i >= p.levelup_options.size():
				return false
			var o: Dictionary = p.levelup_options[i]
			p.levelup_stats[o["stat"]] = p.levelup_stats.get(o["stat"], 0.0) + o["amount"]
			p.levelups -= 1
			p.levelup_rerolls = 0
			_recompute(p)
			_make_levelup_options(p)
			return true
		"levelup_reroll":
			if p.levelups <= 0:
				return false
			var price := 0 if p.free_rerolls > 0 else Content.reroll_price(wave, p.levelup_rerolls)
			if p.pfand < price:
				return _deny(p, "DENY_NO_PFAND")
			if p.free_rerolls > 0:
				p.free_rerolls -= 1
			else:
				p.pfand -= price
				p.levelup_rerolls += 1
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
			var i := int(arg)   # -1 = abstain
			if vertrag["options"].is_empty() or i < -1 or i >= vertrag["options"].size():
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
			if bool(arg) and not vertrag["options"].is_empty() and not vertrag["votes"].has(p.id):
				return _deny(p, "DENY_VOTE_FIRST")
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


## Index of another weapon with the same id and tier (< 4) than `skip`, or -1.
static func find_twin(p: SimPlayer, id: String, tier: int, skip: int) -> int:
	if tier >= 4:
		return -1
	for i in p.weapons.size():
		if i != skip and p.weapons[i]["id"] == id and int(p.weapons[i]["tier"]) == tier:
			return i
	return -1


func _combine(p: SimPlayer, a: int, b: int) -> void:
	var w: Dictionary = p.weapons[a]
	for i in [maxi(a, b), mini(a, b)]:
		var old: Dictionary = p.weapons[i]
		if p.sources.has(_wkey(old)):
			p.sources[_wkey(old)]["merged"] = true
		summons = summons.filter(func(s): return s.source != _wkey(old))
		p.weapons.remove_at(i)
	_add_weapon(p, w["id"], int(w["tier"]) + 1)
	_event(["combine", p.id, w["id"], int(w["tier"]) + 1])
	_event(["sfx", "levelup", Vector2.INF])


func _repair_one_hole() -> void:
	for i in WALL_SEGMENTS:
		if not wall[i]:
			wall[i] = true
			meta_dirty = true
			return


func _check_intro_done() -> void:
	if not intro_wait:
		return
	# Away players don't block the boss intro; with nobody present it keeps waiting.
	if _present_count() == 0:
		return
	for p in players.values():
		if (p.state == 0 or p.state == 1) and not intro_done.has(p.id):
			meta_dirty = true
			return
	intro_wait = false
	meta_dirty = true


func _check_all_ready() -> void:
	if phase != Phase.SHOP:
		return
	# Away players don't block the Späti; with nobody present it keeps waiting.
	if _present_count() == 0:
		return
	for p in players.values():
		if (p.state == 0 or p.state == 1) and not p.ready:
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
			"name": p.name, "char": p.char_id, "pfand": p.pfand, "alive": p.state == 0, "away": p.state == 3,
			"stats": p.stats.duplicate(), "weapons": weapons, "max_weapons": p.max_weapons,
			"items": Array(p.items), "offers": p.offers.duplicate(true),
			"reroll_price": Content.reroll_price(wave, p.rerolls_done), "free_rerolls": p.free_rerolls,
			"spend_left": (_spend_limit(p) - p.spent) if _spend_limit(p) >= 0 else -1,
			"levelups": p.levelups, "levelup_options": p.levelup_options.duplicate(true), "buys": p.buys,
			"levelup_reroll_price": Content.reroll_price(wave, p.levelup_rerolls), "tax_wave": p.tax_wave,
			"ready": p.ready, "paid_in": p.paid_in, "taken_out": p.taken_out,
			"kills": p.kills, "damage": int(p.damage),
			"ult": Content.CHARACTERS[p.char_id].get("ult", ""), "ult_ready": p.ult_ready,
			"run_stats": run_stats(p),
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
		if p.reversed > 0.0:
			flags |= ViewState.PF_REVERSED
			if p.reverse_axis == 1: flags |= ViewState.PF_REVERSE_X   # Teilwende (D-108)
			elif p.reverse_axis == 2: flags |= ViewState.PF_REVERSE_Y
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
	var boss_hoch := 0
	for e in enemies:
		if not e.alive:
			continue
		vs.e_id.append(e.id)
		vs.e_type.append(e.type)
		vs.e_pos.append(e.pos)
		vs.e_hp.append(clampf(e.hp / e.max_hp, 0.0, 1.0))
		var f := 0
		if e.elite: f |= ViewState.EF_ELITE
		if e.poison_t > 0.0 or e.sticker_t > 0.0: f |= ViewState.EF_POISONED
		if e.slow_t > 0.0 or e.stun_t > 0.0 or (not _status_immune(e) and (streik_active > 0.0 or effects.has("antrag_gestellt"))): f |= ViewState.EF_SLOWED
		if (e.def["ai"] == "charger" and e.state == 1) or (e.tid == "eidgenossin" and e.phase == 0 and e.state == 1) \
				or e.cast != "":
			f |= ViewState.EF_WINDUP
		if (e.def["ai"] == "charger" and e.state == 3) or (e.def["ai"] == "voter" and e.state == 1):
			f |= ViewState.EF_PARKED
		if e.armored or e.shield > 0.0: f |= ViewState.EF_SHIELDED
		if e.buffed or e.vuln_t > 0.0: f |= ViewState.EF_BUFFED
		if e.hit_flash > 0.0: f |= ViewState.EF_HIT
		vs.e_flags.append(f)
		var f2 := 0
		if not _status_immune(e):   # D-092: nothing shows on immune enemies
			if e.silence_t > 0.0: f2 |= ViewState.EF2_SILENCED
			if e.reverse_t > 0.0: f2 |= ViewState.EF2_REVERSED
			if e.sticker_t > 0.0: f2 |= ViewState.EF2_STICKER
			f2 |= (clampi(e.file_n, 0, ViewState.EF2_FILE_MASK) & ViewState.EF2_FILE_MASK) << ViewState.EF2_FILE_SHIFT
		if e.encounter != "":   # boss rules (D-108)
			if e.presse_t > 0.0: f2 |= ViewState.EF2_PRESSE
			elif e.standfest_t > 0.0 and e.stun_t <= 0.0: f2 |= ViewState.EF2_STANDFEST
		vs.e_flags2.append(f2)
		if e.encounter != "":
			boss_hp += maxf(0.0, e.hp)
			boss_max += e.max_hp
			boss_phase = e.phase
			if e.shield_max > 0.0:
				boss_shield = e.shield / e.shield_max
			boss_hoch = maxi(boss_hoch, int(e.data.get("wahl", 0)))
	if boss_max > 0.0:
		vs.boss = {"enc": Content.idx(Content.ENCOUNTER_ORDER, encounter), "hp": boss_hp / maxf(boss_max, _enc_max_hp),
			"phase": boss_phase, "shield": boss_shield,
			"cast": (1 + Content.BOSS_CASTS.find(boss_cast)) if boss_cast != "" else 0, "cast_t": boss_cast_t, "hoch": boss_hoch}
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
		if h.alive and not h.data.get("hidden", false):
			vs.h_type.append(h.type)
			vs.h_pos.append(h.pos)
			vs.h_rad.append(h.radius)
			vs.h_life.append(clampf(h.life / h.max_life, 0.0, 1.0))
			vs.h_ang.append(h.ang)
	for s in summons:
		if s.alive and not s.data.get("hidden", false):
			vs.s_type.append(s.type)
			vs.s_pos.append(s.pos)
			vs.s_hp.append(clampf(s.hp / s.max_hp, 0.0, 1.0) if s.max_hp > 0.0 else 1.0)
