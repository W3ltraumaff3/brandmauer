extends TestCase
## Snapshot encode/decode round trips (src/net/snapshot.gd).

const POS_EPS := 0.5 + 0.0001
const FRAC_EPS := 0.5 / 255.0 + 0.0001
const ANGLE_EPS := TAU / 512.0 + 0.0001


static func make_view(rng: RandomNumberGenerator, enemies: int, projectiles: int, pickups: int,
		hazards: int, summons: int, players: int) -> ViewState:
	var vs := ViewState.new()
	vs.time = rng.randf_range(0.0, 1200.0)
	vs.phase = 0
	vs.wave = rng.randi_range(1, 20)
	vs.wave_time_left = rng.randf_range(0.0, 60.0)
	vs.stage = rng.randi_range(0, 4)
	vs.wall = rng.randi_range(0, 4095)
	for i in players:
		var w := PackedByteArray()
		for k in rng.randi_range(1, 6):
			w.append(rng.randi_range(0, Content.WEAPON_ORDER.size() - 1))
		vs.players.append({
			"id": 1 if i == 0 else rng.randi_range(2, 2147483647),
			"char": rng.randi_range(0, Content.CHAR_ORDER.size() - 1),
			"pos": _rand_pos(rng), "hp": rng.randf_range(0.0, 40.0), "max_hp": rng.randf_range(15.0, 40.0),
			"state": rng.randi_range(0, 2), "aim": rng.randf_range(-PI, PI), "flags": rng.randi_range(0, 31),
			"followers": rng.randi_range(0, 30), "weapons": w, "seq": rng.randi_range(0, 2000000000) * 2,
		})
	for i in enemies:
		vs.e_id.append(rng.randi_range(1, 2147483647))
		vs.e_type.append(rng.randi_range(0, Content.ENEMY_ORDER.size() - 1))
		vs.e_pos.append(_rand_pos(rng))
		vs.e_hp.append(rng.randf())
		vs.e_flags.append(rng.randi_range(0, 255))
	for i in projectiles:
		vs.p_type.append(rng.randi_range(0, Content.PROJ_ORDER.size() - 1))
		vs.p_pos.append(_rand_pos(rng))
		vs.p_ang.append(rng.randf_range(-PI, PI))
	for i in pickups:
		vs.k_type.append(rng.randi_range(0, Content.PICKUP_ORDER.size() - 1))
		vs.k_pos.append(_rand_pos(rng))
	for i in hazards:
		vs.h_type.append(rng.randi_range(0, Content.HAZARD_ORDER.size() - 1))
		vs.h_pos.append(_rand_pos(rng))
		vs.h_rad.append(rng.randf_range(10.0, 300.0))
		vs.h_life.append(rng.randf())
	for i in summons:
		vs.s_type.append(rng.randi_range(0, Content.SUMMON_ORDER.size() - 1))
		vs.s_pos.append(_rand_pos(rng))
	return vs


static func _rand_pos(rng: RandomNumberGenerator) -> Vector2:
	return Vector2(rng.randf_range(0.0, 1600.0), rng.randf_range(0.0, 1000.0))


func _assert_pos(a: Vector2, b: Vector2, what: String) -> void:
	if absf(a.x - b.x) > POS_EPS or absf(a.y - b.y) > POS_EPS:
		fail("%s: %s vs %s" % [what, a, b])


func _compare(src: ViewState, dec: ViewState) -> void:
	assert_true(dec != null, "decoded")
	if dec == null:
		return
	assert_near(dec.time, src.time, 0.001, "time")
	assert_eq(dec.phase, src.phase, "phase")
	assert_eq(dec.wave, src.wave, "wave")
	assert_near(dec.wave_time_left, src.wave_time_left, 0.001, "wave_time_left")
	assert_eq(dec.stage, src.stage, "stage")
	assert_eq(dec.wall, src.wall, "wall")
	assert_eq(dec.players.size(), src.players.size(), "players")
	for i in mini(dec.players.size(), src.players.size()):
		var a: Dictionary = src.players[i]
		var b: Dictionary = dec.players[i]
		for key in ["id", "char", "state", "flags", "followers", "seq"]:
			assert_eq(b[key], a[key], "player " + key)
		assert_near(b["hp"], a["hp"], 0.001, "player hp")
		assert_near(b["max_hp"], a["max_hp"], 0.001, "player max_hp")
		_assert_pos(b["pos"], a["pos"], "player pos")
		assert_near(absf(angle_difference(b["aim"], a["aim"])), 0.0, ANGLE_EPS, "player aim")
		assert_eq(b["weapons"], a["weapons"], "player weapons")
	var ne := src.e_id.size()
	assert_eq(dec.e_id.size(), ne, "enemy count")
	if dec.e_id.size() != ne:
		return
	assert_eq(dec.e_id, src.e_id, "e_id")
	assert_eq(dec.e_type, src.e_type, "e_type")
	assert_eq(dec.e_flags, src.e_flags, "e_flags")
	for i in ne:
		_assert_pos(dec.e_pos[i], src.e_pos[i], "e_pos")
		assert_near(dec.e_hp[i], src.e_hp[i], FRAC_EPS, "e_hp")
	assert_eq(dec.p_type, src.p_type, "p_type")
	for i in src.p_type.size():
		_assert_pos(dec.p_pos[i], src.p_pos[i], "p_pos")
		assert_near(absf(angle_difference(dec.p_ang[i], src.p_ang[i])), 0.0, ANGLE_EPS, "p_ang")
	assert_eq(dec.k_type, src.k_type, "k_type")
	for i in src.k_type.size():
		_assert_pos(dec.k_pos[i], src.k_pos[i], "k_pos")
	assert_eq(dec.h_type, src.h_type, "h_type")
	for i in src.h_type.size():
		_assert_pos(dec.h_pos[i], src.h_pos[i], "h_pos")
		assert_near(dec.h_rad[i], src.h_rad[i], POS_EPS, "h_rad")
		assert_near(dec.h_life[i], src.h_life[i], FRAC_EPS, "h_life")
	assert_eq(dec.s_type, src.s_type, "s_type")
	for i in src.s_type.size():
		_assert_pos(dec.s_pos[i], src.s_pos[i], "s_pos")
	assert_eq(dec.boss.is_empty(), src.boss.is_empty(), "boss presence")
	if not src.boss.is_empty() and not dec.boss.is_empty():
		assert_eq(dec.boss["enc"], src.boss["enc"], "boss enc")
		assert_eq(dec.boss["phase"], src.boss["phase"], "boss phase")
		assert_near(dec.boss["hp"], src.boss["hp"], FRAC_EPS, "boss hp")
		assert_near(dec.boss["shield"], src.boss["shield"], FRAC_EPS, "boss shield")


func test_realistic_round_trip_and_size() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var vs := make_view(rng, 200, 300, 100, 20, 6, 4)
	vs.boss = {"enc": 2, "hp": 0.73, "phase": 1, "shield": 0.2}
	var bytes := Snapshot.encode(vs)
	var deflated := bytes.compress(FileAccess.COMPRESSION_DEFLATE).size()
	print("    snapshot 200e/300p/100k/20h/6s/4pl: %d bytes raw (%d deflate, for reference)" % [bytes.size(), deflated])
	assert_true(bytes.size() < 6144, "snapshot under 6 KB (%d)" % bytes.size())
	_compare(vs, Snapshot.decode(bytes))


func test_many_random_round_trips() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for n in 20:
		var vs := make_view(rng, rng.randi_range(0, 50), rng.randi_range(0, 50), rng.randi_range(0, 20),
				rng.randi_range(0, 5), rng.randi_range(0, 3), rng.randi_range(0, 4))
		if rng.randf() < 0.5:
			vs.boss = {"enc": rng.randi_range(0, 3), "hp": rng.randf(), "phase": rng.randi_range(0, 3),
					"shield": rng.randf()}
		_compare(vs, Snapshot.decode(Snapshot.encode(vs)))


func test_empty_view() -> void:
	var vs := ViewState.new()
	vs.wave_time_left = -1.0
	var bytes := Snapshot.encode(vs)
	var dec := Snapshot.decode(bytes)
	_compare(vs, dec)
	assert_true(dec.boss.is_empty(), "no boss")
	assert_near(dec.wave_time_left, -1.0, 0.0001, "boss wave time left")


func test_caps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var vs := make_view(rng, 500, 600, 400, 100, 100, 10)
	var dec := Snapshot.decode(Snapshot.encode(vs))
	assert_eq(dec.e_id.size(), Snapshot.MAX_ENEMIES, "enemy cap")
	assert_eq(dec.p_type.size(), Snapshot.MAX_PROJECTILES, "projectile cap")
	assert_eq(dec.k_type.size(), Snapshot.MAX_PICKUPS, "pickup cap")
	assert_eq(dec.h_type.size(), Snapshot.MAX_HAZARDS, "hazard cap")
	assert_eq(dec.s_type.size(), Snapshot.MAX_SUMMONS, "summon cap")
	assert_eq(dec.players.size(), Snapshot.MAX_PLAYERS, "player cap")
	assert_eq(dec.e_id[299], vs.e_id[299], "kept the first enemies")


func test_clamps_out_of_range_values() -> void:
	var vs := ViewState.new()
	vs.e_id.append(5)
	vs.e_type.append(1)
	vs.e_pos.append(Vector2(-90000.0, 90000.0))
	vs.e_hp.append(1.7)
	vs.e_flags.append(0)
	vs.p_type.append(0)
	vs.p_pos.append(Vector2(10.4, 10.6))
	vs.p_ang.append(TAU * 3.0 + 0.5)
	var dec := Snapshot.decode(Snapshot.encode(vs))
	assert_eq(dec.e_pos[0], Vector2(-32768, 32767), "position clamped to int16")
	assert_near(dec.e_hp[0], 1.0, 0.0001, "fraction clamped")
	assert_eq(dec.p_pos[0], Vector2(10, 11), "rounded")
	assert_near(absf(angle_difference(dec.p_ang[0], 0.5)), 0.0, ANGLE_EPS, "angle wrapped")


func test_malformed_input_returns_null() -> void:
	assert_true(Snapshot.decode(PackedByteArray()) == null, "empty")
	assert_true(Snapshot.decode(PackedByteArray([99, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])) == null,
			"wrong version")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var bytes := Snapshot.encode(make_view(rng, 30, 30, 10, 3, 2, 2))
	for cut in [1, 10, 20, 60, 200, bytes.size() - 1]:
		assert_true(Snapshot.decode(bytes.slice(0, cut)) == null, "truncated at %d" % cut)
