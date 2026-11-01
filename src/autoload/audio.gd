extends Node
## Music and sound effects (architecture §8).
##
## Music: one playlist per category (assets/music/playlist.json), played in
## shuffled order and crossfaded between two players. SFX: a round-robin pool
## with light pitch jitter, anti-spam and distance attenuation around the
## local player. Under a headless DisplayServer (dedicated server, tests)
## every call is a cheap no-op.

const PLAYLIST_PATH := "res://assets/music/playlist.json"
const SFX_DIR := "res://assets/sfx/"
const SFX_IDS: Array[String] = [
	"hit", "crit", "kill", "shoot", "melee", "pickup", "levelup", "buy", "hurt", "down",
	"revive", "wave_start", "wave_end", "boss_intro", "wende", "streik", "vote", "explosion",
	"ui_click", "error",
]
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const CROSSFADE := 1.0          # seconds
const POOL_SIZE := 12
const PITCH_JITTER := 0.05      # ±5 %
const SPAM_WINDOW_MS := 50
const SPAM_MAX := 4             # same id at most this often per window
const KILL_THROTTLE_MS := 70    # extra throttle for the "kill" event
const HEAR_FULL := 200.0        # px: full volume up to here
const HEAR_RANGE := 900.0       # px: silent from here on
const BOSS_WAVES := [10, 15, 20]
const MIN_LINEAR := 0.0001      # -80 dB, used instead of -inf

## Event name -> SFX id for events that map 1:1 (architecture §5).
const EVENT_SFX := {
	"wave_start": "wave_start", "wave_end": "wave_end", "levelup": "levelup", "down": "down",
	"revive": "revive", "wende": "wende", "streik": "streik", "card": "boss_intro",
}

var enabled := false            # false under a headless DisplayServer
var playlist := {}              # category -> Array of res:// paths
var category := ""              # current music category ("" = none)
var music_volume := 0.7
var sfx_volume := 0.8

var _music: Array[AudioStreamPlayer] = []
var _active := 0                # index into _music of the audible player
var _queue: Array = []          # remaining shuffled tracks of the current category
var _last_track := ""
var _fade: Tween
var _pool: Array[AudioStreamPlayer] = []
var _next_slot := 0
var _cache := {}                # path -> AudioStream (or null if missing)
var _recent := {}               # sfx id -> Array[int] of play times (ms)
var _last_kill_ms := -1000000
var _screen := ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	enabled = DisplayServer.get_name() != "headless"
	if not enabled:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep music running while the game is paused
	_rng.randomize()
	playlist = load_playlist()
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
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
	var save = get_node_or_null("/root/Save")
	if save and save.has_method("option"):
		set_volumes(float(save.option("music", music_volume)), float(save.option("sfx", sfx_volume)))
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


## Positional (distance-attenuated around the local player) only if pos != INF.
func play_sfx(id: String, pos := Vector2.INF) -> void:
	if not enabled:
		return
	var vol := 1.0
	if pos != Vector2.INF:
		var listener := _listener_pos()
		if listener != Vector2.INF:
			vol = distance_gain(pos.distance_to(listener))
			if vol <= 0.0:
				return
	if not allow_sfx(id, Time.get_ticks_msec()):
		return
	var stream := _load(SFX_DIR + id + ".wav")
	if stream == null:
		return
	var p := _pool[_next_slot]
	_next_slot = (_next_slot + 1) % _pool.size()
	p.stream = stream
	p.volume_db = linear_to_db(vol)
	p.pitch_scale = 1.0 + _rng.randf_range(-PITCH_JITTER, PITCH_JITTER)
	p.play()


## Linear 0..1 per bus.
func set_volumes(music: float, sfx: float) -> void:
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	if not enabled:
		return
	_apply_bus(MUSIC_BUS, music_volume)
	_apply_bus(SFX_BUS, sfx_volume)


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


## Anti-spam: records and returns true unless `id` already played SPAM_MAX
## times in the last SPAM_WINDOW_MS.
func allow_sfx(id: String, now_ms: int) -> bool:
	var times: Array = _recent.get(id, [])
	while not times.is_empty() and now_ms - int(times[0]) >= SPAM_WINDOW_MS:
		times.pop_front()
	if times.size() >= SPAM_MAX:
		_recent[id] = times
		return false
	times.append(now_ms)
	_recent[id] = times
	return true


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
	for e in events:
		if not (e is Array) or e.is_empty():
			continue
		var ev := str(e[0])
		if ev == "sfx":
			if e.size() > 1:
				play_sfx(str(e[1]), e[2] if e.size() > 2 and e[2] is Vector2 else Vector2.INF)
		elif ev == "kill":
			var now := Time.get_ticks_msec()
			if now - _last_kill_ms >= KILL_THROTTLE_MS:
				_last_kill_ms = now
				play_sfx("kill", e[1] if e.size() > 1 and e[1] is Vector2 else Vector2.INF)
		elif EVENT_SFX.has(ev):
			play_sfx(EVENT_SFX[ev])


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
	var me := -1
	if game.has_method("local_id"):
		me = int(game.local_id())
	for p in players:
		if p is Dictionary and int(p.get("id", -2)) == me and p.get("pos") is Vector2:
			return p["pos"]
	return Vector2.INF


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _cache[path]


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, MIN_LINEAR)))
