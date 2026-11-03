extends TestCase
## Statistik panel: "Letzte Woche" on top with a row per player, run totals
## below (GDD §6c, architecture §10, D-152).

const AREAS := ["ui", "sim"]  # ci-cd.md §2a

const Preview := preload("res://tools/ui_preview.gd")


func before_each() -> void:
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1


func after_each() -> void:
	UIApi.preview_mode = ""
	UIApi.preview_local_id = 0


func _sim(chars: Array) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": 7, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	return s


func _play_wave(s: Sim) -> void:
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 20000:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(1.0 / 60.0)
		guard += 1


func test_last_wave_counts_only_the_current_wave() -> void:
	var s := _sim(["oma"])
	var p: Sim.SimPlayer = s.players[1]
	_play_wave(s)
	var lw1: Dictionary = s.run_stats(p)["last_wave"]
	assert_true(lw1["kills"] > 0, "wave 1 kills")
	assert_eq(lw1["kills"], p.kills, "first wave: wave kills = run kills")
	var wave_sum := 0
	for r in s.run_stats(p)["damage"]:
		wave_sum += int(r["wave"])
	assert_near(float(lw1["damage"]), float(wave_sum), float(s.run_stats(p)["damage"].size()), "damage = wave column")
	for k in ["damage", "kills", "pfand", "dmg_taken", "healed"]:
		assert_true(lw1[k] is int, k + " is int")

	s._begin_wave(2)
	var lw2: Dictionary = s.run_stats(p)["last_wave"]
	for k in ["damage", "kills", "pfand", "dmg_taken", "healed"]:
		assert_eq(lw2[k], 0, k + " resets when the next wave starts")
	var taken_before: float = p.log["dmg_taken"]
	p.iframes = 0.0
	s.damage_player(p, 5.0)
	var st := s.run_stats(p)
	assert_true(st["last_wave"]["dmg_taken"] > 0, "hit counted in this wave")
	assert_eq(st["last_wave"]["dmg_taken"], int(round(p.log["dmg_taken"] - taken_before)))
	assert_true(st["kills"] > st["last_wave"]["kills"], "run kills keep the first wave")
	assert_true(s.build_meta()["players"][1]["run_stats"].has("last_wave"), "last_wave is in meta")


func test_coop_compares_every_player_and_highlights_the_local_one() -> void:
	var meta := Preview._fake_meta(false)   # players 1..3, local 1
	meta["players"][3]["run_stats"]["last_wave"]["kills"] = 999
	var panel := StatsPanel.new()
	var card := panel._wave_card(meta, meta["players"][1])
	for id in [1, 2, 3]:
		assert_true(card.find_child("wn_%d" % id, true, false) != null, "row for player %d" % id)
		assert_true(card.find_child("wv_%d_damage" % id, true, false) != null, "damage of player %d" % id)
	var me := card.find_child("wn_1", true, false) as Label
	assert_true(me.text.contains(tr("STATS_YOU")), "own row marked (du)")
	assert_eq(me.get_theme_color("font_color"), UITheme.RED, "own name in red")
	var mark := card.find_child("wave_grid", true, false).get_parent() as StatsPanel.RowMark
	assert_true(mark != null and mark.cell == me, "own row tinted")
	var lea_kills := card.find_child("wv_3_kills", true, false)
	assert_eq(lea_kills.text, StatsPanel.fmt_int(999))
	assert_true(lea_kills.find_child("top", false, false) != null, "highest kills underlined")
	assert_true(card.find_child("wv_1_kills", true, false).find_child("top", false, false) == null,
		"lower kills not underlined")
	card.free()
	panel.free()


func test_solo_shows_one_strip_without_names_or_underlines() -> void:
	var meta := Preview._fake_meta(false)
	meta["players"] = {1: meta["players"][1]}
	var panel := StatsPanel.new()
	var card := panel._wave_card(meta, meta["players"][1])
	var grid := card.find_child("wave_grid", true, false) as GridContainer
	assert_eq(grid.columns, StatsPanel.WAVE_COLS.size() + 1, "no name column")
	assert_true(card.find_child("wn_1", true, false) == null, "no name cell")
	assert_eq(card.find_children("top", "", true, false).size(), 0, "nothing to compare, nothing underlined")
	assert_eq((card.find_child("wv_1_damage", true, false) as Label).text, StatsPanel.fmt_int(
		int(meta["players"][1]["run_stats"]["last_wave"]["damage"])))
	card.free()
	panel.free()


func test_best_source_of_the_wave_and_damage_fallback() -> void:
	var rs := {"damage": [
		{"key": "a", "kind": "weapon", "id": "tofu", "tier": 1, "total": 900, "wave": 10},
		{"key": "b", "kind": "weapon", "id": "megafon", "tier": 2, "total": 100, "wave": 60}]}
	assert_eq(StatsPanel.best_wave_source(rs)["id"], "megafon", "most damage this wave, not overall")
	assert_eq(StatsPanel.best_source(rs)["id"], "tofu")
	assert_eq(StatsPanel.last_wave({"run_stats": rs})["damage"], 70, "without last_wave: sum of the wave column")
	assert_eq(StatsPanel.best_wave_source({"damage": [{"kind": "ram", "total": 5, "wave": 0}]}), {}, "nothing hit")
