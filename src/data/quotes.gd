class_name Quotes
## Real, verified quotes (docs/specs/content-guidelines.md §4).
## research/zitate_de.json holds the research; research/auswahl.json the curated
## selection and where each quote is used in the game.

const QUOTES_PATH := "res://research/zitate_de.json"
const SELECTION_PATH := "res://research/auswahl.json"

static var _quotes := {}
static var _uses := {}
static var _album: Array = []
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	for q in _read_json(QUOTES_PATH):
		if q.get("status", "") == "verifiziert":
			_quotes[q["id"]] = q
	for sel in _read_json(SELECTION_PATH):
		var id: String = sel["id"]
		if not _quotes.has(id):
			continue
		_album.append(id)
		for use in sel.get("verwendung", []):
			if not _uses.has(use):
				_uses[use] = []
			_uses[use].append(id)


static func _read_json(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Quotes: cannot open %s" % path)
		return []
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Array else []


static func get_quote(id: String) -> Dictionary:
	_load()
	return _quotes.get(id, {})


static func ids_for(use: String) -> Array:
	_load()
	return _uses.get(use, [])


static func album_ids() -> Array:
	_load()
	return _album


static func random_for(use: String, rng: RandomNumberGenerator = null) -> String:
	var ids := ids_for(use)
	if ids.is_empty():
		return ""
	var i := rng.randi_range(0, ids.size() - 1) if rng else randi_range(0, ids.size() - 1)
	return ids[i]


static func source_label(q: Dictionary) -> String:
	if q.is_empty():
		return ""
	var date: String = q.get("datum", "")
	var parts := date.split("-")
	var nice := date
	if parts.size() == 3:
		nice = "%s.%s.%s" % [parts[2], parts[1], parts[0]]
	elif parts.size() == 2:
		nice = "%s/%s" % [parts[1], parts[0]]
	return "%s, %s" % [q.get("sprecher", ""), nice]
