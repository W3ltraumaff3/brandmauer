extends Node
## Music and sound effects (architecture §8, audio.md).
##
## Music: one playlist per category (assets/music/playlist.json), played in
## shuffled order and crossfaded between two players. SFX: events are turned
## into plays by the pure plan_events() (audio.md §4), then pick_voice() finds
## a voice by priority, cap and gap (§3.2). Buses and ducking: §3.1. Under a
## headless DisplayServer (dedicated server, tests) every call is a cheap no-op.

const PLAYLIST_PATH := "res://assets/music/playlist.json"
const SFX_DIR := "res://assets/sfx/"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const CROSSFADE := 1.0          # seconds
const POOL_SIZE := 24
const COMBAT_MAX := 12          # prio-1 sounds together use at most this many voices
const HEAR_FULL := 200.0        # px: full volume up to here
const HEAR_RANGE := 900.0       # px: silent from here on
const BOSS_WAVES := [10, 15, 20]
const MIN_LINEAR := 0.0001      # -80 dB, used instead of -inf
const PFAND_NOTES := 11         # pfand_0 … pfand_10, a major pentatonic (§4.1)
const PFAND_GAP_MS := 35        # a pickup closer than this merges into the last note
const PFAND_RESET_MS := 600     # a pause longer than this starts the streak over
const LEVELUP_STEPS := 3        # team level-ups rise 2 semitones each, up to 3 steps (§4.5)
const DUCK_THRESHOLD_DB := -14.0
const DUCK_RATIO := 3.0         # combat under an event sound: about −6 dB
const MUSIC_DUCK_RATIO := 1.6   # music under an event sound: about −3 dB

## Sound table (audio.md §2). bus: SFX sub-bus; prio 1 combat … 5 big event;
## cap: voices at once; gap: ms between two starts; pitch: ± fraction; vol: ± dB;
## mates: extra dB when a teammate caused it (absent = teammates don't hear it);
## team: everyone hears it at full volume; var: rendered variants <id>_<n>.wav.
const SFX := {
	"shoot": {"bus": "Combat", "prio": 1, "cap": 3, "gap": 25, "pitch": 0.08, "vol": 1.5, "mates": -12.0, "var": 3},
	"melee": {"bus": "Combat", "prio": 1, "cap": 3, "gap": 25, "pitch": 0.08, "vol": 1.5, "mates": -12.0, "var": 3},
	"hit": {"bus": "Combat", "prio": 1, "cap": 3, "gap": 35, "pitch": 0.08, "vol": 1.5, "var": 3},
	"crit": {"bus": "Combat", "prio": 2, "cap": 2, "gap": 70, "pitch": 0.03, "mates": -12.0},
	"kill": {"bus": "Combat", "prio": 2, "cap": 3, "gap": 40, "vol": 1.0, "mates": -12.0, "var": 3},
	"kill_elite": {"bus": "Event", "prio": 4, "cap": 1, "mates": -6.0},
	"explosion": {"bus": "Combat", "prio": 2, "cap": 2, "gap": 60, "pitch": 0.06, "vol": 1.0, "var": 2},
	"pfand": {"bus": "Reward", "prio": 2, "cap": 4, "gap": PFAND_GAP_MS, "mates": -8.0},
	"pfand_top": {"bus": "Reward", "prio": 4, "cap": 1},
	"hurt": {"bus": "Event", "prio": 3, "cap": 1, "gap": 150, "pitch": 0.04, "mates": -9.0},
	"down": {"bus": "Event", "prio": 5, "cap": 2, "team": true},
	"revive": {"bus": "Event", "prio": 4, "cap": 2, "team": true},
	"levelup": {"bus": "Event", "prio": 4, "cap": 1, "team": true},
	"wave_start": {"bus": "Event", "prio": 5, "cap": 1, "team": true},
	"wave_end": {"bus": "Event", "prio": 5, "cap": 1, "team": true},
	"boss_intro": {"bus": "Event", "prio": 5, "cap": 1, "team": true},
	"wende": {"bus": "Event", "prio": 4, "cap": 1, "team": true},
	"streik": {"bus": "Event", "prio": 4, "cap": 2, "pitch": 0.02, "team": true},
	"vote": {"bus": "UI", "prio": 3, "cap": 2, "gap": 60, "pitch": 0.04, "mates": -6.0},
	"buy_1": {"bus": "Reward", "prio": 4, "cap": 1},
	"buy_2": {"bus": "Reward", "prio": 4, "cap": 1},
	"buy_3": {"bus": "Reward", "prio": 4, "cap": 1},
	"buy_4": {"bus": "Reward", "prio": 4, "cap": 1},
	"sell": {"bus": "UI", "prio": 3, "cap": 1},
	"combine_2": {"bus": "Reward", "prio": 4, "cap": 1},
	"combine_3": {"bus": "Reward", "prio": 4, "cap": 1},
	"combine_4": {"bus": "Reward", "prio": 4, "cap": 1},
	"ui_click": {"bus": "UI", "prio": 3, "cap": 2, "gap": 30, "pitch": 0.02},
	"error": {"bus": "UI", "prio": 3, "cap": 1, "gap": 100},
}

## Semantic events whose sound everyone hears (architecture §5). The sim sends
## no extra "sfx" for these (audio.md §6: one sound path per event).
const EVENT_SFX := {
	"wave_start": "wave_start", "wave_end": "wave_end", "down": "down",
	"revive": "revive", "wende": "wende", "streik": "streik", "card": "boss_intro",
}

var enabled := false            # false under a headless DisplayServer
var playlist := {}              # category -> Array of res:// paths
var category := ""              # current music category ("" = none)
var music_volume := 0.5
var sfx_volume := 0.8
var teammate_volume := 0.5      # option "Geräusche der Mitspieler:innen" (§5)

var _music: Array[AudioStreamPlayer] = []
var _active := 0                # index into _music of the audible player
var _queue: Array = []          # remaining shuffled tracks of the current category
var _last_track := ""
var _fade: Tween
var _pool: Array[AudioStreamPlayer] = []
var _voices: Array = []         # per pool slot: {"id", "prio", "start", "busy"}
var _cache := {}                # path -> AudioStream (or null if missing)
var _state := {}                # plan state: Pfand streak, level-up step, variants, rng
var _screen := ""


func _ready() -> void:
	enabled = DisplayServer.get_name() != "headless"
	if not enabled:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep music running while the game is paused
	_state = new_state()
	(_state["rng"] as RandomNumberGenerator).randomize()
	playlist = load_playlist()
	_setup_buses()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = MUSIC_BUS
		p.volume_db = linear_to_db(MIN_LINEAR)
		p.finished.connect(_on_music_finished.bind(i))
		add_child(p)
		_music.append(p)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)
		_voices.append({"id": "", "prio": 0, "start": -1000000, "busy": false})
	var save = get_node_or_null("/root/Save")
	if save and save.has_method("option"):
		set_volumes(float(save.option("music", music_volume)), float(save.option("sfx", sfx_volume)))
		set_master_volume(float(save.option("master", master_volume)))
		set_teammate_volume(float(save.option("teammate_sfx", teammate_volume)))
	else:
		set_volumes(music_volume, sfx_volume)
	# Game is autoloaded after us, so hook its signals once the tree is complete.
	call_deferred("_connect_game")


# ------------------------------------------------------------------ public API


## "menu" | "gameplay" | "spaeti" | "boss". Same category keeps playing.
func play_music(cat: String) -> void:
	if not enabled:
		return
	if cat == category and _music[_active].playing:
		return
	category = cat
	_queue.clear()
	_next_track()


func stop_music() -> void:
	if not enabled:
		return
	category = ""
	_queue.clear()
	_crossfade(null)


## A local sound (UI) or one at pos caused by peer (0 = world). Positional only
## if pos != INF and someone else caused it.
func play_sfx(id: String, pos := Vector2.INF, peer := 0) -> void:
	if not enabled:
		return
	_state["listener"] = _listener_pos()
	_state["mates"] = teammate_volume
	var play := plan_one(id, pos, peer, _local_id(), _state)
	if not play.is_empty():
		_play(play)


## Overall volume (Master bus), linear 0..1.
var master_volume := 0.7


func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	if enabled:
		_apply_bus("Master", master_volume)


## Linear 0..1 per bus.
func set_volumes(music: float, sfx: float) -> void:
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	if not enabled:
		return
	_apply_bus(MUSIC_BUS, music_volume)
	_apply_bus(SFX_BUS, sfx_volume)


## Teammates' sounds, linear 0..1 (audio.md §5); 0 mutes them.
func set_teammate_volume(v: float) -> void:
	teammate_volume = clampf(v, 0.0, 1.0)


# ------------------------------------------------------ pure helpers (tested)


static func load_playlist() -> Dictionary:
	var f := FileAccess.open(PLAYLIST_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## Music category for a meta dict (architecture §4), or "" for "no change".
static func music_for_meta(meta: Dictionary) -> String:
	if not meta.has("phase"):
		return ""
	match int(meta["phase"]):
		0:
			if str(meta.get("encounter", "")) != "" and int(meta.get("wave", 0)) in BOSS_WAVES:
				return "boss"
			return "gameplay"
		1:
			return "spaeti"
	return ""


## Linear gain for a sound at distance d from the listener: 1 up to HEAR_FULL,
## falling to 0 at HEAR_RANGE (squared, so far sounds get quiet quickly).
static func distance_gain(d: float) -> float:
	var t := clampf((d - HEAR_FULL) / (HEAR_RANGE - HEAR_FULL), 0.0, 1.0)
	return (1.0 - t) * (1.0 - t)


## Every file the table needs, as res:// paths.
static func sfx_files() -> Array[String]:
	var out: Array[String] = []
	for id in SFX:
		if id == "pfand":
			for n in PFAND_NOTES:
				out.append(SFX_DIR + "pfand_%d.wav" % n)
		elif int(SFX[id].get("var", 1)) > 1:
			for n in int(SFX[id]["var"]):
				out.append(SFX_DIR + "%s_%d.wav" % [id, n])
		else:
			out.append(SFX_DIR + id + ".wav")
	return out


## Fresh plan state; tests seed state["rng"].
static func new_state() -> Dictionary:
	return {"rng": RandomNumberGenerator.new(), "pf_step": 0, "pf_last": -1000000, "pf_topped": false,
		"lv_k": 0, "last_var": {}, "listener": Vector2.INF, "mates": 0.5}


## Pfand streak (§4.1): the note index for a pickup at now_ms, or -1 when it
## merges into the last note. Climbs one step per pickup, holds at the top and
## starts over after a pause.
static func pfand_step(state: Dictionary, now_ms: int) -> int:
	var since := now_ms - int(state.get("pf_last", -1000000))
	if since < PFAND_GAP_MS:
		return -1
	if since > PFAND_RESET_MS:
		state["pf_step"] = 0
		state["pf_topped"] = false
	else:
		state["pf_step"] = mini(int(state["pf_step"]) + 1, PFAND_NOTES - 1)
	state["pf_last"] = now_ms
	return int(state["pf_step"])


## One play {"id", "file", "gain_db", "pitch"} for a sound, or {} if it isn't
## heard here: teammates' sounds follow the table's mates/team columns and the
## option, positional ones the distance to the listener.
static func plan_one(id: String, pos: Vector2, peer: int, local_id: int, state: Dictionary,
		note := -1) -> Dictionary:
	if not SFX.has(id):
		return {}
	var info: Dictionary = SFX[id]
	var g := 0.0
	var mate := peer != 0 and peer != local_id
	if mate and not info.get("team", false):
		var mv := float(state.get("mates", 0.5))
		if not info.has("mates") or mv <= 0.001:
			return {}
		g += float(info["mates"]) + linear_to_db(mv)
	if peer != local_id and pos != Vector2.INF:
		var listener: Vector2 = state.get("listener", Vector2.INF)
		if listener != Vector2.INF:
			var dg := distance_gain(pos.distance_to(listener))
			if dg <= 0.0:
				return {}
			g += linear_to_db(dg)
	var rng: RandomNumberGenerator = state["rng"]
	var file := id
	if id == "pfand":
		file = "pfand_%d" % (note if note >= 0 else 4)
	elif int(info.get("var", 1)) > 1:
		var n := int(info["var"])
		var last := int((state["last_var"] as Dictionary).get(id, -1))
		var v := rng.randi_range(0, n - 1)
		if v == last:
			v = (v + 1 + rng.randi_range(0, n - 2)) % n
		state["last_var"][id] = v
		file = "%s_%d" % [id, v]
	var pj := float(info.get("pitch", 0.0))
	var vj := float(info.get("vol", 0.0))
	return {"id": id, "file": file, "gain_db": g + (rng.randf_range(-vj, vj) if vj > 0.0 else 0.0),
		"pitch": 1.0 + (rng.randf_range(-pj, pj) if pj > 0.0 else 0.0)}


## All plays for one event batch (audio.md §4), heard by local_id. Updates the
## Pfand streak and level-up step in state.
static func plan_events(events: Array, local_id: int, state: Dictionary, now_ms: int) -> Array:
	var out: Array = []
	var crit := false
	for e in events:
		if not (e is Array) or e.is_empty():
			continue
		var ev := str(e[0])
		var pos: Vector2 = e[2] if ev == "sfx" and e.size() > 2 and e[2] is Vector2 else Vector2.INF
		match ev:
			"sfx":
				if e.size() < 2:
					continue
				var peer := int(e[3]) if e.size() > 3 else 0
				var id := str(e[1])
				if id == "pickup":
					if peer == local_id:
						var n := pfand_step(state, now_ms)
						if n < 0:
							continue
						_add(out, plan_one("pfand", pos, peer, local_id, state, n))
						if n == PFAND_NOTES - 1 and not state["pf_topped"]:
							state["pf_topped"] = true
							_add(out, plan_one("pfand_top", pos, peer, local_id, state))
					else:
						_add(out, plan_one("pfand", pos, peer, local_id, state, 0))
				elif SFX.has(id) and SFX[id]["bus"] == "UI" and peer == local_id and pos == Vector2.INF:
					continue   # your own Späti request: the UI already played it (B5)
				else:
					_add(out, plan_one(id, pos, peer, local_id, state))
			"dmg":
				# [pos, amount, crit, to_player, peer]; your own hurt comes from the sim
				if e.size() < 4 or (e.size() > 4 and bool(e[4])):
					continue
				var peer := int(e[5]) if e.size() > 5 else 0
				var p: Vector2 = e[1] if e[1] is Vector2 else Vector2.INF
				if bool(e[3]):
					var c := plan_one("crit", p, peer, local_id, state)
					if not c.is_empty():
						crit = true
						out.append(c)
				elif peer == local_id:
					_add(out, plan_one("hit", p, peer, local_id, state))
			"kill":
				# [pos, type, killer, elite, quiet]
				if e.size() > 5 and bool(e[5]):
					continue
				var p: Vector2 = e[1] if e.size() > 1 and e[1] is Vector2 else Vector2.INF
				var peer := int(e[3]) if e.size() > 3 else 0
				var elite: bool = e.size() > 4 and bool(e[4])
				_add(out, plan_one("kill_elite" if elite else "kill", p, peer, local_id, state))
			"levelup":
				var play := plan_one("levelup", Vector2.INF, 0, local_id, state)
				if not play.is_empty():
					play["pitch"] = pow(2.0, 2.0 * int(state["lv_k"]) / 12.0)
					out.append(play)
				state["lv_k"] = mini(int(state["lv_k"]) + 1, LEVELUP_STEPS)
			"combine":
				# [peer, weapon id, new tier]: only for the player who combined
				if e.size() > 3 and int(e[1]) == local_id:
					_add(out, plan_one("combine_%d" % clampi(int(e[3]), 2, 4), Vector2.INF, 0, local_id, state))
			_:
				if ev == "wave_start":
					state["lv_k"] = 0
				if EVENT_SFX.has(ev):
					_add(out, plan_one(EVENT_SFX[ev], Vector2.INF, 0, local_id, state))
	if crit:
		out = out.filter(func(p): return p["id"] != "hit")   # a crit beats a plain hit
	return out


static func _add(out: Array, play: Dictionary) -> void:
	if not play.is_empty():
		out.append(play)


## The voice for a new sound of `id` (audio.md §3.2), or -1 to drop it.
## voices: [{"id", "prio", "start", "busy"}]. Gap, then cap (restart the
## oldest of the same id), then the combat share, then a free voice, then
## steal the lowest prio that is <= the new one, oldest first.
static func pick_voice(voices: Array, id: String, now_ms: int) -> int:
	var info: Dictionary = SFX.get(id, {})
	var prio := int(info.get("prio", 1))
	var newest := -1000000
	var same: Array[int] = []
	var combat: Array[int] = []
	for i in voices.size():
		var v: Dictionary = voices[i]
		if v["id"] == id:
			newest = maxi(newest, int(v["start"]))
			if v["busy"]:
				same.append(i)
		if v["busy"] and int(v["prio"]) == 1:
			combat.append(i)
	if now_ms - newest < int(info.get("gap", 0)):
		return -1
	if same.size() >= int(info.get("cap", 1)):
		return _oldest(voices, same)
	if prio == 1 and combat.size() >= COMBAT_MAX:
		return _oldest(voices, combat)
	for i in voices.size():
		if not voices[i]["busy"]:
			return i
	var best := -1
	for i in voices.size():
		var v: Dictionary = voices[i]
		if int(v["prio"]) > prio:
			continue
		if best < 0 or int(v["prio"]) < int(voices[best]["prio"]) \
				or (int(v["prio"]) == int(voices[best]["prio"]) and int(v["start"]) < int(voices[best]["start"])):
			best = i
	return best


static func _oldest(voices: Array, idx: Array[int]) -> int:
	var best := idx[0]
	for i in idx:
		if int(voices[i]["start"]) < int(voices[best]["start"]):
			best = i
	return best


# -------------------------------------------------------------------- music


func _next_track() -> void:
	var tracks: Array = playlist.get(category, [])
	if tracks.is_empty():
		_crossfade(null)
		return
	if _queue.is_empty():
		_queue = tracks.duplicate()
		_queue.shuffle()
		# Don't repeat the track that just ended when the shuffle wraps around.
		if _queue.size() > 1 and _queue[0] == _last_track:
			_queue.push_back(_queue.pop_front())
	var path: String = _queue.pop_front()
	_last_track = path
	var stream := _load(path)
	if stream == null:
		push_warning("Audio: missing music track %s" % path)
		return
	if "loop" in stream:
		stream.set("loop", false)  # we move on via `finished` instead
	_crossfade(stream)


## Fades the active player out and (if stream != null) the other one in.
func _crossfade(stream: AudioStream) -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	var old := _music[_active]
	var from := db_to_linear(old.volume_db) if old.playing else 0.0
	var new: AudioStreamPlayer = null
	if stream != null:
		_active = 1 - _active
		new = _music[_active]
		new.stop()
		new.stream = stream
		new.volume_db = linear_to_db(MIN_LINEAR)
		new.play()
	var step := func(t: float) -> void:
		if new != null:
			new.volume_db = linear_to_db(maxf(t, MIN_LINEAR))
		old.volume_db = linear_to_db(maxf(from * (1.0 - t), MIN_LINEAR))
	_fade = create_tween()
	_fade.tween_method(step, 0.0, 1.0, CROSSFADE)
	_fade.tween_callback(old.stop)


func _on_music_finished(index: int) -> void:
	if index == _active and category != "":
		_next_track()


# ---------------------------------------------------------------- game hooks


func _connect_game() -> void:
	var game = get_node_or_null("/root/Game")
	if game == null:
		return
	if game.has_signal("events"):
		game.connect("events", _on_events)
	if game.has_signal("screen_requested"):
		game.connect("screen_requested", _on_screen_requested)
	if game.has_signal("meta_changed"):
		game.connect("meta_changed", _on_meta_changed)


func _on_events(events: Array) -> void:
	if not enabled:
		return
	_state["listener"] = _listener_pos()
	_state["mates"] = teammate_volume
	for play in plan_events(events, _local_id(), _state, Time.get_ticks_msec()):
		_play(play)


func _on_screen_requested(screen: String) -> void:
	_screen = screen
	match screen:
		"menu", "lobby":
			play_music("menu")
		"run":
			play_music("gameplay")


func _on_meta_changed() -> void:
	if _screen in ["menu", "lobby"]:
		return  # stale meta after leaving a run
	var game = get_node_or_null("/root/Game")
	var meta = game.get("meta") if game else null
	if meta is Dictionary:
		var cat := music_for_meta(meta)
		if cat != "":
			play_music(cat)


# ------------------------------------------------------------------ helpers


func _play(play: Dictionary) -> void:
	var stream := _load(SFX_DIR + str(play["file"]) + ".wav")
	if stream == null:
		return
	var id := str(play["id"])
	var now := Time.get_ticks_msec()
	for i in _pool.size():
		_voices[i]["busy"] = _pool[i].playing
	var slot := pick_voice(_voices, id, now)
	if slot < 0:
		return
	var p := _pool[slot]
	p.stop()
	p.stream = stream
	p.bus = "SFX_" + str(SFX[id]["bus"])
	p.volume_db = float(play["gain_db"])
	p.pitch_scale = float(play["pitch"])
	p.play()
	_voices[slot] = {"id": id, "prio": int(SFX[id]["prio"]), "start": now, "busy": true}


func _local_id() -> int:
	var game = get_node_or_null("/root/Game")
	return int(game.local_id()) if game and game.has_method("local_id") else 0


func _listener_pos() -> Vector2:
	var game = get_node_or_null("/root/Game")
	if game == null:
		return Vector2.INF
	var view = game.get("view")
	if view == null:
		return Vector2.INF
	var players = view.get("players")
	if not (players is Array) or players.is_empty():
		return Vector2.INF
	var me := _local_id()
	for p in players:
		if p is Dictionary and int(p.get("id", -2)) == me and p.get("pos") is Vector2:
			return p["pos"]
	return Vector2.INF


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _cache[path]


## Master → Music, SFX (limiter) → SFX_Combat/Reward/Event/UI; combat and music
## duck under SFX_Event (audio.md §3.1).
func _setup_buses() -> void:
	_ensure_bus(MUSIC_BUS, "Master")
	_ensure_bus(SFX_BUS, "Master")
	for sub in ["Combat", "Reward", "Event", "UI"]:
		_ensure_bus("SFX_" + sub, SFX_BUS)
	var sfx := AudioServer.get_bus_index(SFX_BUS)
	if AudioServer.get_bus_effect_count(sfx) == 0 and ClassDB.class_exists("AudioEffectHardLimiter"):
		var lim = ClassDB.instantiate("AudioEffectHardLimiter")
		lim.set("ceiling_db", -1.0)
		lim.set("release", 0.1)
		AudioServer.add_bus_effect(sfx, lim)
	_add_duck("SFX_Combat", DUCK_RATIO)
	_add_duck(MUSIC_BUS, MUSIC_DUCK_RATIO)


func _add_duck(bus_name: String, ratio: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1 or AudioServer.get_bus_effect_count(idx) > 0:
		return
	var c := AudioEffectCompressor.new()
	c.threshold = DUCK_THRESHOLD_DB
	c.ratio = ratio
	c.attack_us = 2000.0     # Godot's maximum
	c.release_ms = 300.0
	c.sidechain = &"SFX_Event"
	AudioServer.add_bus_effect(idx, c)


func _ensure_bus(bus_name: String, send: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send)


func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, MIN_LINEAR)))
