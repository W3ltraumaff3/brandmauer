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
		"options": {"music": 0.7, "sfx": 0.8, "window_mode": "windowed", "bubble_opacity": 0.7, "name": "Genoss:in"},
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
