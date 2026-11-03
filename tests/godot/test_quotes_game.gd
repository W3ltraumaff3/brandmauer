extends TestCase
## The game file research/zitate_spiel.json (D-159, architecture.md "Quotes"):
## Quotes loads only that file, every entry carries the fields the game reads,
## and the game reaches exactly the quotes the old loader (zitate_de.json plus
## auswahl.json) reached: start and loading screen, Album, unlock cards, boss calls.

const AREAS := ["content"]  # ci-cd.md §2a

const RESEARCH_PATH := "res://research/zitate_de.json"
const SELECTION_PATH := "res://research/auswahl.json"


func _json(path: String) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		fail("cannot open " + path)
		return []
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Array else []


## The loader before D-159, run over the research files (repo only, not exported).
func _old_loader() -> Dictionary:
	var quotes := {}
	for q in _json(RESEARCH_PATH):
		if q.get("status", "") == "verifiziert":
			quotes[q["id"]] = q
	var album := []
	var uses := {}
	for sel in _json(SELECTION_PATH):
		var id: String = sel["id"]
		if not quotes.has(id):
			continue
		album.append(id)
		for use in sel.get("verwendung", []):
			if not uses.has(use):
				uses[use] = []
			uses[use].append(id)
	return {"quotes": quotes, "album": album, "uses": uses}


func test_loads_only_the_game_file() -> void:
	assert_eq(Quotes.QUOTES_PATH, "res://research/zitate_spiel.json")
	assert_true(FileAccess.file_exists(Quotes.QUOTES_PATH), "game file exists")


func test_every_entry_has_exactly_the_fields_the_game_reads() -> void:
	assert_false(Quotes.album_ids().is_empty(), "quotes loaded")
	for id in Quotes.album_ids():
		var q := Quotes.get_quote(id)
		for field in Quotes.FIELDS:
			assert_true(q.has(field), "%s has %s" % [id, field])
		assert_eq(q.size(), Quotes.FIELDS.size(), "no extra fields in " + id)
		assert_false(q.has("status") or q.has("notizen"), "no research fields in " + id)
		assert_true(str(q.get("zitat", "")).strip_edges() != "", "quote text " + id)


func test_same_quotes_reachable_as_before() -> void:
	var old := _old_loader()
	assert_eq(Quotes.album_ids(), old["album"], "Album: same ids, same order")
	var game_uses := {}
	for id in Quotes.album_ids():
		for use in Quotes.get_quote(id)["verwendung"]:
			game_uses[use] = true
	assert_eq(game_uses.size(), old["uses"].size(), "same set of uses")
	for use in old["uses"]:
		assert_eq(Quotes.ids_for(use), old["uses"][use], use)
	for id in old["album"]:
		var q := Quotes.get_quote(id)
		var o: Dictionary = old["quotes"][id]
		for field in Quotes.FIELDS:
			if field != "verwendung":
				assert_eq(q.get(field), o.get(field), "%s.%s" % [id, field])
		assert_eq(Quotes.source_label(q), Quotes.source_label(o), "source label " + id)
		assert_eq(Quotes.context_label(q), Quotes.context_label(o), "context line " + id)


func test_every_shipped_quote_is_verified_in_the_research() -> void:
	var status := {}
	for q in _json(RESEARCH_PATH):
		status[q["id"]] = q.get("status", "")
	for id in Quotes.album_ids():
		assert_eq(status.get(id, ""), "verifiziert", id)


func test_quote_ids_named_in_content_are_shipped() -> void:
	var named := []
	for id in Content.CHARACTERS:
		named.append(str(Content.CHARACTERS[id].get("quote", "")))
	for id in Content.ENCOUNTERS:
		named.append(str(Content.ENCOUNTERS[id].get("quote", "")))
	for qid in named:
		if qid != "":
			assert_false(Quotes.get_quote(qid).is_empty(), "content quote %s is in the game file" % qid)
