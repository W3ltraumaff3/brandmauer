extends TestCase
## Audio autoload (architecture §8): assets exist, pure helpers, headless safety.

const AREAS := ["audio"]  # ci-cd.md §2a

const AudioScript := preload("res://src/autoload/audio.gd")


func test_every_sfx_id_has_a_file() -> void:
	assert_eq(AudioScript.SFX_IDS.size(), 20, "SFX id count")
	for id in AudioScript.SFX_IDS:
		var path: String = AudioScript.SFX_DIR + id + ".wav"
		assert_true(FileAccess.file_exists(path), "missing sfx file " + path)
		assert_true(ResourceLoader.exists(path), "sfx not imported " + path)


func test_sfx_files_load_as_audio() -> void:
	for id in AudioScript.SFX_IDS:
		var path: String = AudioScript.SFX_DIR + id + ".wav"
		if ResourceLoader.exists(path):
			assert_true(load(path) is AudioStream, "not an AudioStream: " + path)


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


func test_anti_spam() -> void:
	var a: Node = AudioScript.new()
	for i in AudioScript.SPAM_MAX:
		assert_true(a.allow_sfx("hit", 1000 + i), "allowed #%d" % i)
	assert_false(a.allow_sfx("hit", 1010), "blocked within window")
	assert_true(a.allow_sfx("crit", 1010), "other ids unaffected")
	assert_true(a.allow_sfx("hit", 1000 + AudioScript.SPAM_WINDOW_MS + 1), "allowed after window")
	a.free()


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
	for id in AudioScript.SFX_IDS:
		a.play_sfx(id)
		a.play_sfx(id, Vector2(100, 100))
	a.play_sfx("does_not_exist")
	a.set_volumes(0.5, 0.0)
	assert_near(a.music_volume, 0.5)
	assert_near(a.sfx_volume, 0.0)
	a._on_events([["sfx", "hit", Vector2.ZERO], ["kill", Vector2.ZERO, 0], ["card", "x"], ["bogus"], []])
	a._on_screen_requested("run")
	a._on_meta_changed()
	a.queue_free()
