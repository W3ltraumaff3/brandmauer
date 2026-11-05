extends Node
## Local meta progression and options (GDD §17). Each machine keeps its own save;
## a host never stores a client's progress.

const PATH := "user://brandmauer_save.json"

var data := {}
## Tests and tools set this to false so they never touch the player's save.
var persist := true


func _ready() -> void:
	load_save()


func _defaults() -> Dictionary:
	return {
		"version": 1,
		"achievements": {},
		"album": [],
		"max_umfrage": 0,
		"stats": {"runs": 0, "wins": 0, "best_wave": 0},
		"options": {"master": 0.7, "music": 0.5, "sfx": 0.8, "teammate_sfx": 0.5, "window_mode": "windowed", "bubble_opacity": 0.7, "own_fx_opacity": 1.0, "name": "Genoss:in"},
	}


func load_save() -> void:
	data = _defaults()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text()) if f else null
	if parsed is Dictionary:
		for key in parsed:
			if data.has(key) and data[key] is Dictionary and parsed[key] is Dictionary:
				data[key].merge(parsed[key], true)
			else:
				data[key] = parsed[key]
	# Old `fullscreen` bool -> `window_mode` (architecture §11).
	if parsed is Dictionary and parsed.get("options") is Dictionary:
		var old: Dictionary = parsed["options"]
		if old.has("fullscreen") and not old.has("window_mode"):
			data["options"]["window_mode"] = "fullscreen" if bool(old["fullscreen"]) else "windowed"
	data["options"].erase("fullscreen")
	# Old default name before the switch to colon gendering.
	if data["options"].get("name", "") == "Genoss*in":
		data["options"]["name"] = "Genoss:in"


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


## Client session of a running co-op run, for rejoining after a crash
## (networking.md §7.5). Kept in memory only when `persist` is off.
const REJOIN_PATH := "user://rejoin.json"
const REJOIN_MAX_AGE_S := 6 * 3600

var _rejoin_mem := {}


## {ip, port, token, player}; the version and time stamp are added here.
func set_rejoin(session: Dictionary) -> void:
	var d := session.duplicate()
	d["version"] = str(ProjectSettings.get_setting("application/config/version", ""))
	d["saved_at"] = int(Time.get_unix_time_from_system())
	_rejoin_mem = d
	if not persist:
		return
	var f := FileAccess.open(REJOIN_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


## The saved session if it belongs to this game version and is recent, else {}.
func rejoin_info() -> Dictionary:
	var d = _rejoin_mem
	if persist and FileAccess.file_exists(REJOIN_PATH):
		var f := FileAccess.open(REJOIN_PATH, FileAccess.READ)
		d = JSON.parse_string(f.get_as_text()) if f else null
	if not (d is Dictionary) or (d as Dictionary).is_empty():
		return {}
	var age := int(Time.get_unix_time_from_system()) - int(d.get("saved_at", 0))
	if str(d.get("version", "")) != str(ProjectSettings.get_setting("application/config/version", "")) \
			or age < 0 or age > REJOIN_MAX_AGE_S or str(d.get("token", "")) == "" or str(d.get("ip", "")) == "":
		return {}
	return {"ip": str(d["ip"]), "port": int(d.get("port", 0)), "token": str(d["token"]), "player": int(d.get("player", 0))}


func clear_rejoin() -> void:
	_rejoin_mem = {}
	if persist and FileAccess.file_exists(REJOIN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(REJOIN_PATH))


## Run save (GDD §17 "Weiterspielen", D-162): the latest Sim checkpoint of the run
## this machine hosts. Binary store_var without objects, written to a temp file
## first so a crash mid-write never leaves half a save. Memory only when `persist` is off.
const RUN_PATH := "user://run_save.bin"

var _run_mem := {}


func write_run(cp: Dictionary) -> void:
	_run_mem = cp.duplicate(true)
	if not persist:
		return
	var tmp := RUN_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_var(cp, false)
	f.close()
	var to := ProjectSettings.globalize_path(RUN_PATH)
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), to) != OK:
		DirAccess.remove_absolute(to)
		DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), to)


## The saved run, or {} if there is none or it doesn't fit this build.
func run_save() -> Dictionary:
	var d = _run_mem
	if persist:
		d = null
		if FileAccess.file_exists(RUN_PATH):
			var f := FileAccess.open(RUN_PATH, FileAccess.READ)
			d = f.get_var(false) if f else null
	if not (d is Dictionary) or int((d as Dictionary).get("format", -1)) != Sim.CHECKPOINT_FORMAT:
		return {}
	if Sim.checkpoint_summary(d).get("players", []).is_empty():
		return {}
	return d


func has_run_save() -> bool:
	return not run_save().is_empty()


func clear_run() -> void:
	_run_mem = {}
	if persist and FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))


func is_char_unlocked(id: String) -> bool:
	var c: Dictionary = Content.CHARACTERS.get(id, {})
	if c.is_empty():
		return false
	if not c.get("locked", false):
		return true
	return has_achievement(c.get("unlock", ""))


func has_achievement(id: String) -> bool:
	return data["achievements"].has(id)


func album_has(quote_id: String) -> bool:
	return quote_id in data["album"]


func option(key: String, default = null):
	return data["options"].get(key, default)


func set_option(key: String, value) -> void:
	data["options"][key] = value
	save()


## Applies a run result (architecture §6) for this machine's own player.
func apply_result(result: Dictionary, my_peer: int) -> Dictionary:
	var out := {"new_achievements": [], "new_quotes": [], "new_chars": []}
	var locked_before := []
	for id in Content.CHAR_ORDER:
		if not is_char_unlocked(id):
			locked_before.append(id)
	var stats: Dictionary = data["stats"]
	stats["runs"] += 1
	stats["best_wave"] = maxi(stats["best_wave"], int(result.get("wave", 0)))
	if result.get("won", false):
		stats["wins"] += 1
		var diff := int(result.get("difficulty", 0))
		data["max_umfrage"] = maxi(data["max_umfrage"], mini(diff + 1, Content.DIFFICULTY_PERCENT.size() - 1))
	var mine: Dictionary = result.get("players", {}).get(my_peer, {})
	for ach in mine.get("achievements", []):
		if not has_achievement(ach):
			data["achievements"][ach] = true
			out["new_achievements"].append(ach)
	for q in result.get("quotes", []):
		if not album_has(q):
			data["album"].append(q)
			out["new_quotes"].append(q)
	for id in locked_before:
		if is_char_unlocked(id):
			out["new_chars"].append(id)
	save()
	return out
