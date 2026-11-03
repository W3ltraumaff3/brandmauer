extends TestCase
## Audio autoload (architecture §8, audio.md): assets exist, pure helpers
## (plan, Pfand streak, voices), headless safety.

const AREAS := ["audio"]  # ci-cd.md §2a

const AudioScript := preload("res://src/autoload/audio.gd")


func test_every_sfx_file_exists() -> void:
	var files := AudioScript.sfx_files()
	assert_eq(files.size(), 48, "files in the sound table (audio.md §2)")
	for path in files:
		assert_true(FileAccess.file_exists(path), "missing sfx file " + path)
		assert_true(ResourceLoader.exists(path), "sfx not imported " + path)


func test_sfx_files_load_as_audio() -> void:
	for path in AudioScript.sfx_files():
		if ResourceLoader.exists(path):
			assert_true(load(path) is AudioStream, "not an AudioStream: " + path)


func test_no_stale_sfx_files() -> void:
	var known := AudioScript.sfx_files()
	for f in DirAccess.get_files_at(AudioScript.SFX_DIR):
		if f.ends_with(".wav"):
			assert_true(AudioScript.SFX_DIR + f in known, "file not in the sound table: " + f)


func test_sound_table_is_complete() -> void:
	for id in AudioScript.SFX:
		var info: Dictionary = AudioScript.SFX[id]
		assert_true(str(info.get("bus", "")) in ["Combat", "Reward", "Event", "UI"], id + " bus")
		assert_true(int(info.get("prio", 0)) in [1, 2, 3, 4, 5], id + " prio")
		assert_true(int(info.get("cap", 0)) >= 1, id + " cap")
		assert_false(info.has("team") and info.has("mates"), id + ": team or mates, not both")
	for ev in AudioScript.EVENT_SFX:
		assert_true(AudioScript.SFX.has(AudioScript.EVENT_SFX[ev]), "event sound " + ev)


func test_playlist_paths_exist() -> void:
	var pl := AudioScript.load_playlist()
	for cat in ["menu", "gameplay", "spaeti", "boss"]:
		assert_true(pl.has(cat), "playlist category " + cat)
		assert_false((pl.get(cat, []) as Array).is_empty(), "empty playlist category " + cat)
	for cat in pl:
		for path in pl[cat]:
			assert_true(ResourceLoader.exists(path), "missing track " + str(path))


func test_music_for_meta() -> void:
	assert_eq(AudioScript.music_for_meta({}), "")
	assert_eq(AudioScript.music_for_meta({"phase": 0, "wave": 3, "encounter": ""}), "gameplay")
	assert_eq(AudioScript.music_for_meta({"phase": 1, "wave": 10, "encounter": ""}), "spaeti")
	assert_eq(AudioScript.music_for_meta({"phase": 0, "wave": 10, "encounter": "x"}), "boss")
	assert_eq(AudioScript.music_for_meta({"phase": 0, "wave": 20, "encounter": "x"}), "boss")
	assert_eq(AudioScript.music_for_meta({"phase": 0, "wave": 7, "encounter": "x"}), "gameplay")
	assert_eq(AudioScript.music_for_meta({"phase": 2, "wave": 20, "encounter": "x"}), "")


func test_distance_gain() -> void:
	assert_near(AudioScript.distance_gain(0.0), 1.0)
	assert_near(AudioScript.distance_gain(AudioScript.HEAR_FULL), 1.0)
	assert_near(AudioScript.distance_gain(AudioScript.HEAR_RANGE), 0.0)
	assert_near(AudioScript.distance_gain(5000.0), 0.0)
	var mid := AudioScript.distance_gain(550.0)
	assert_true(mid > 0.0 and mid < 1.0, "falloff in between")


func _state() -> Dictionary:
	var st := AudioScript.new_state()
	(st["rng"] as RandomNumberGenerator).seed = 11
	return st


func _ids(plays: Array) -> Array:
	return plays.map(func(p): return p["id"])


## Pfand streak (audio.md §4.1)
func test_pfand_streak_climbs_merges_holds_and_resets() -> void:
	var st := _state()
	assert_eq(AudioScript.pfand_step(st, 1000), 0, "first pickup: root")
	assert_eq(AudioScript.pfand_step(st, 1100), 1)
	assert_eq(AudioScript.pfand_step(st, 1200), 2)
	assert_eq(AudioScript.pfand_step(st, 1210), -1, "10 ms later: merged")
	assert_eq(AudioScript.pfand_step(st, 1300), 3, "a merge doesn't skip a step")
	assert_eq(AudioScript.pfand_step(st, 2000), 0, "700 ms pause: starts over")
	var t := 2000
	var n := 0
	for i in 15:
		t += 100
		n = AudioScript.pfand_step(st, t)
	assert_eq(n, AudioScript.PFAND_NOTES - 1, "15 quick pickups hold the top")


func test_pfand_top_once_per_streak_and_teammates_dont_climb() -> void:
	var st := _state()
	var t := 1000
	var files := []
	var tops := 0
	for i in 14:
		t += 100
		var plays := AudioScript.plan_events([["sfx", "pickup", Vector2.ZERO, 1]], 1, st, t)
		tops += _ids(plays).count("pfand_top")
		files.append(plays[0]["file"])
	assert_eq(files.slice(0, 11), ["pfand_0", "pfand_1", "pfand_2", "pfand_3", "pfand_4", "pfand_5", "pfand_6",
		"pfand_7", "pfand_8", "pfand_9", "pfand_10"], "the scale")
	assert_eq(tops, 1, "pfand_top once per streak")
	var mate := AudioScript.plan_events([["sfx", "pickup", Vector2.ZERO, 2]], 1, st, t + 50)
	assert_eq(mate[0]["file"], "pfand_0", "a teammate's pickup: the root, no streak")
	assert_near(float(mate[0]["gain_db"]), -8.0 + linear_to_db(0.5), 0.01, "mates −8 dB at the default option")
	assert_eq(int(st["pf_step"]), AudioScript.PFAND_NOTES - 1, "your streak unchanged")
	st["mates"] = 0.0
	assert_true(AudioScript.plan_events([["sfx", "pickup", Vector2.ZERO, 2]], 1, st, t + 900).is_empty(),
		"option 0: teammates are silent")


## Hit and crit (audio.md §4.2)
func test_hits_and_crits() -> void:
	var st := _state()
	assert_eq(_ids(AudioScript.plan_events([["dmg", Vector2.ZERO, 5, false, false, 1]], 1, st, 0)), ["hit"], "your hit")
	assert_true(AudioScript.plan_events([["dmg", Vector2.ZERO, 5, false, false, 2]], 1, st, 0).is_empty(),
		"a teammate's plain hit is silent")
	var c := AudioScript.plan_events([["dmg", Vector2.ZERO, 5, true, false, 2]], 1, st, 0)
	assert_eq(_ids(c), ["crit"], "a teammate's crit")
	assert_near(float(c[0]["gain_db"]), -12.0 + linear_to_db(0.5), 0.01, "at −12 dB plus the option")
	assert_true(AudioScript.plan_events([["dmg", Vector2.ZERO, 5, false, true, 1]], 1, st, 0).is_empty(),
		"damage to a player: no hit")
	var both := AudioScript.plan_events([["dmg", Vector2.ZERO, 5, false, false, 1],
		["dmg", Vector2.ZERO, 9, true, false, 1]], 1, st, 0)
	assert_eq(_ids(both), ["crit"], "crit and hit in one batch: crit only")


func test_kill_variants_quiet_kills_and_world_distance() -> void:
	var st := _state()
	var last := ""
	for i in 20:
		var k := AudioScript.plan_events([["kill", Vector2.ZERO, 0, 1, false, false]], 1, st, i)
		assert_true(str(k[0]["file"]) != last, "never the same variant twice in a row")
		last = str(k[0]["file"])
	assert_true(AudioScript.plan_events([["kill", Vector2.ZERO, 0, 1, false, true]], 1, st, 0).is_empty(),
		"bombs and no-reward kills are quiet")
	st["listener"] = Vector2.ZERO
	assert_true(AudioScript.plan_events([["sfx", "explosion", Vector2(2000, 0), 0]], 1, st, 0).is_empty(),
		"a far explosion is out of range")
	var own := AudioScript.plan_events([["sfx", "shoot", Vector2(2000, 0), 1]], 1, st, 0)
	assert_eq(own.size(), 1, "your own sound ignores the distance")


## Level-up rises within a wave (audio.md §4.5)
func test_levelup_rises_within_a_wave() -> void:
	var st := _state()
	var pitches := []
	for i in 5:
		pitches.append(float(AudioScript.plan_events([["levelup", 2 + i]], 1, st, 0)[0]["pitch"]))
	assert_near(pitches[0], 1.0, 0.001)
	assert_near(pitches[1], pow(2.0, 2.0 / 12.0), 0.001)
	assert_near(pitches[2], pow(2.0, 4.0 / 12.0), 0.001)
	assert_near(pitches[4], pow(2.0, 6.0 / 12.0), 0.001, "stays at the third step")
	var p := AudioScript.plan_events([["wave_start", 3], ["levelup", 9]], 1, st, 0)
	assert_eq(_ids(p), ["wave_start", "levelup"])
	assert_near(float(p[1]["pitch"]), 1.0, 0.001, "starts over with the wave")


func test_tonal_sounds_are_never_detuned() -> void:
	var st := _state()
	for id in ["levelup", "wave_end", "buy_4", "combine_3", "pfand", "kill_elite", "revive", "down"]:
		for i in 5:
			assert_near(float(AudioScript.plan_one(id, Vector2.INF, 0, 1, st)["pitch"]), 1.0, 0.0001, id)


## Voices (audio.md §3.2)
func _voices(n: int, id: String, prio: int, start := 0) -> Array:
	var v := []
	for i in n:
		v.append({"id": id, "prio": prio, "start": start + i, "busy": true})
	return v


func test_pick_voice_gap_cap_share_and_stealing() -> void:
	var v := _voices(2, "shoot", 1, 100)
	v.append({"id": "", "prio": 0, "start": -1000000, "busy": false})
	assert_eq(AudioScript.pick_voice(v, "shoot", 110), -1, "inside the gap: dropped")
	assert_eq(AudioScript.pick_voice(v, "shoot", 200), 2, "a free voice")
	v[2] = {"id": "shoot", "prio": 1, "start": 150, "busy": true}
	v.append({"id": "", "prio": 0, "start": -1000000, "busy": false})
	assert_eq(AudioScript.pick_voice(v, "shoot", 300), 0, "cap reached: restart the oldest shot")
	# a firefight: 24 busy voices, half of them combat
	var full := _voices(12, "melee", 1, 0)
	full.append_array(_voices(12, "levelup", 4, 50))
	full[12]["id"] = "wave_end"
	assert_eq(AudioScript.pick_voice(full, "hit", 500), 0, "combat share full: the oldest combat voice")
	var events := _voices(24, "down", 5, 0)
	assert_eq(AudioScript.pick_voice(events, "shoot", 500), -1, "a shot never steals from an event")
	var mixed := _voices(20, "shoot", 1, 0)
	mixed.append_array(_voices(4, "ui_click", 3, 10))
	for i in 20:
		mixed[i]["id"] = "s%d" % i   # distinct ids so no cap applies
	var lv := AudioScript.pick_voice(mixed, "levelup", 500)
	assert_true(lv >= 0 and int(mixed[lv]["prio"]) == 1, "a level-up steals the oldest low-prio voice: %d" % lv)
	assert_eq(lv, 0, "the oldest")


func test_calls_are_safe_headless() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var a: Node = AudioScript.new()
	tree.root.add_child(a)  # runs _ready
	if DisplayServer.get_name() == "headless":
		assert_false(a.enabled, "disabled when headless")
	a.play_music("gameplay")
	a.play_music("gameplay")
	a.play_music("nonexistent")
	a.stop_music()
	for id in AudioScript.SFX:
		a.play_sfx(id)
		a.play_sfx(id, Vector2(100, 100), 2)
	a.play_sfx("does_not_exist")
	a.set_volumes(0.5, 0.0)
	a.set_teammate_volume(0.25)
	assert_near(a.music_volume, 0.5)
	assert_near(a.sfx_volume, 0.0)
	assert_near(a.teammate_volume, 0.25)
	a._on_events([["sfx", "hit", Vector2.ZERO], ["kill", Vector2.ZERO, 0], ["card", "x"], ["bogus"], [],
		["sfx", "pickup", Vector2.ZERO, 1], ["dmg", Vector2.ZERO, 3, true, false, 1], ["combine", 1, "tofu", 2]])
	a._on_screen_requested("run")
	a._on_meta_changed()
	a.queue_free()
