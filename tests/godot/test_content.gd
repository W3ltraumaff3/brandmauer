extends TestCase
## Content data is complete: every id has translated texts, quotes exist,
## references between tables are valid.


func _translated(key: String) -> bool:
	return TranslationServer.translate(key) != key


func test_all_content_names_translated() -> void:
	var missing := []
	var keys := []
	for id in Content.STATS:
		keys.append("STAT_" + id.to_upper())
	for id in Content.CHAR_ORDER:
		keys.append_array(["CHAR_%s_NAME" % id.to_upper(), "CHAR_%s_DESC" % id.to_upper()])
	for id in Content.WEAPON_ORDER:
		keys.append_array(["WEAPON_%s_NAME" % id.to_upper(), "WEAPON_%s_DESC" % id.to_upper()])
	for id in Content.ITEM_ORDER:
		keys.append_array(["ITEM_%s_NAME" % id.to_upper(), "ITEM_%s_DESC" % id.to_upper()])
	for id in Content.ENEMY_ORDER:
		keys.append("ENEMY_%s_NAME" % id.to_upper())
	for id in Content.ENCOUNTER_ORDER:
		keys.append("ENC_%s_NAME" % id.to_upper())
	for id in Content.ORG_ORDER:
		keys.append_array(["ORG_%s_NAME" % id.to_upper(), "ORG_%s_DESC" % id.to_upper()])
	for id in Content.VERTRAG_ORDER:
		keys.append_array(["VERTRAG_%s_NAME" % id.to_upper(), "VERTRAG_%s_DESC" % id.to_upper()])
	for id in Content.ACHIEVEMENT_ORDER:
		keys.append_array(["ACH_%s_NAME" % id.to_upper(), "ACH_%s_DESC" % id.to_upper()])
	for i in Content.DIFFICULTY_PERCENT.size():
		keys.append("DIFF_%d" % i)
	for i in 5:
		keys.append("STAGE_%d" % i)
	for id in Content.ENEMY_ORDER:
		for k in Content.ENEMIES[id].get("say", []):
			keys.append(k)
	for k in keys:
		if not _translated(k):
			missing.append(k)
	assert_true(missing.is_empty(), "untranslated: %s" % [missing])


func test_sim_say_keys_translated() -> void:
	var src := FileAccess.get_file_as_string("res://src/sim/sim.gd")
	var re := RegEx.create_from_string("\"((SAY|DENY|NET_ERR)_[A-Z_0-9]+)\"")
	var missing := []
	for m in re.search_all(src):
		if not _translated(m.get_string(1)) and not m.get_string(1) in missing:
			missing.append(m.get_string(1))
	assert_true(missing.is_empty(), "untranslated sim keys: %s" % [missing])


func test_references_valid() -> void:
	for id in Content.CHAR_ORDER:
		assert_true(Content.WEAPONS.has(Content.CHARACTERS[id]["weapon"]), "start weapon of " + id)
	for id in Content.WEAPON_ORDER:
		var d: Dictionary = Content.WEAPONS[id]
		if d.has("proj"):
			assert_true(d["proj"] in Content.PROJ_ORDER, "proj of " + id)
		for s in d["scale"]:
			assert_has(Content.STATS, s, "scale stat of " + id)
	for id in Content.ITEM_ORDER:
		for s in Content.ITEMS[id].get("mods", {}):
			assert_has(Content.STATS, s, "mod of " + id)
	for id in Content.ENCOUNTER_ORDER:
		for u in Content.ENCOUNTERS[id]["units"]:
			assert_true(Content.ENEMIES.has(u), "unit " + u)
		assert_has(Content.ACHIEVEMENT_ORDER, Content.ENCOUNTERS[id]["achievement"])
	assert_eq(Content.WAVE_LENGTHS.size(), Content.WAVE_COUNT)
	assert_eq(Content.STATS.size(), 18, "18 stats (GDD §8)")
	assert_eq(Content.WEAPON_ORDER.size(), 31, "12 MVP + 8 (v0.2) + 3 + 8 (v0.3) weapons")


func test_curated_quotes_are_verified_and_cover_encounters() -> void:
	var ids := Quotes.album_ids()
	assert_true(ids.size() >= 30, "curated quotes: %d" % ids.size())
	for id in ids:
		assert_eq(Quotes.get_quote(id).get("status", ""), "verifiziert", id)
	for enc in ["geschichtslehrer", "sauerlaender", "eidgenossin"]:
		assert_false(Quotes.ids_for("boss_karte:" + enc).is_empty(), "boss card for " + enc)
	assert_false(Quotes.ids_for("ladebildschirm").is_empty(), "loading screen quotes")
	assert_true(Quotes.source_label(Quotes.get_quote(ids[0])).contains(","), "source label")
