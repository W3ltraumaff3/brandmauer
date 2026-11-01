extends TestCase
## Client interpolation buffer (src/net/snapshot_buffer.gd).


static func _view(t: float, enemies: Dictionary, player_x: float, seq := 0) -> ViewState:
	var vs := ViewState.new()
	vs.time = t
	vs.wave = 3
	vs.wave_time_left = 30.0 - t
	for id in enemies:
		vs.e_id.append(id)
		vs.e_type.append(0)
		vs.e_pos.append(enemies[id])
		vs.e_hp.append(1.0)
		vs.e_flags.append(0)
	vs.players.append({"id": 1, "char": 0, "pos": Vector2(player_x, 0), "hp": 10.0, "max_hp": 15.0,
			"state": 0, "aim": 0.0, "flags": 0, "followers": 0, "weapons": PackedByteArray(), "seq": seq})
	vs.p_type.append(int(t * 10))
	vs.p_pos.append(Vector2(t, t))
	vs.p_ang.append(0.0)
	return vs


func _x(vs: ViewState, id: int) -> float:
	var i := vs.e_id.find(id)
	return vs.e_pos[i].x if i >= 0 else NAN


func test_empty_and_single() -> void:
	var buf := SnapshotBuffer.new()
	assert_true(buf.sample(1.0) == null, "empty buffer gives null")
	var a := _view(0.0, {5: Vector2(0, 0)}, 0.0)
	buf.push(a, 10.0)
	assert_true(buf.sample(10.0) == a, "single snapshot returned as is")
	assert_true(buf.sample(50.0) == a, "single snapshot, far future")


func test_interpolates_matched_enemies_and_players() -> void:
	var buf := SnapshotBuffer.new()
	buf.push(_view(0.0, {5: Vector2(0, 0), 6: Vector2(10, 0)}, 0.0, 3), 10.0)
	buf.push(_view(0.1, {5: Vector2(100, 0), 7: Vector2(500, 0)}, 50.0, 4), 10.1)
	var vs := buf.sample(10.15, 0.1)   # t = 10.05, halfway
	assert_near(_x(vs, 5), 50.0, 0.001, "enemy 5 lerped")
	assert_near(_x(vs, 7), 500.0, 0.001, "new enemy takes newer pos")
	assert_eq(vs.e_id.find(6), -1, "enemy gone in newer snapshot is dropped")
	assert_near((vs.players[0]["pos"] as Vector2).x, 25.0, 0.001, "player lerped")
	assert_eq(vs.players[0]["seq"], 4, "seq from newer snapshot")
	assert_eq(vs.p_type[0], 1, "projectiles from newer snapshot")
	assert_near(vs.time, 0.05, 0.0001, "time lerped")


func test_picks_correct_interval() -> void:
	var buf := SnapshotBuffer.new()
	for i in 5:
		buf.push(_view(i * 0.05, {1: Vector2(i * 10.0, 0)}, 0.0), 1.0 + i * 0.05)
	var vs := buf.sample(1.175 + 0.1)  # between snapshot 3 (x=30) and 4 (x=40)
	assert_near(_x(vs, 1), 35.0, 0.01, "interval 3..4")
	vs = buf.sample(0.5)               # before the oldest
	assert_near(_x(vs, 1), 0.0, 0.001, "clamped to oldest")


func test_extrapolates_at_most_100ms() -> void:
	var buf := SnapshotBuffer.new()
	buf.push(_view(0.0, {5: Vector2(0, 0)}, 0.0), 0.0)
	buf.push(_view(0.1, {5: Vector2(100, 0)}, 0.0), 0.1)
	var vs := buf.sample(0.15 + 0.1)   # 50 ms past newest
	assert_near(_x(vs, 5), 150.0, 0.01, "extrapolated 50 ms")
	vs = buf.sample(5.0 + 0.1)         # far past newest
	assert_near(_x(vs, 5), 200.0, 0.01, "extrapolation capped at 100 ms")


func test_keeps_last_ten_and_drops_out_of_order() -> void:
	var buf := SnapshotBuffer.new()
	for i in 15:
		buf.push(_view(i * 0.05, {}, 0.0), i * 0.05)
	assert_eq(buf.size(), SnapshotBuffer.MAX_SNAPSHOTS, "capacity")
	buf.push(_view(0.0, {}, 0.0), 0.1)
	assert_eq(buf.size(), SnapshotBuffer.MAX_SNAPSHOTS, "out-of-order dropped")
	assert_near(buf.newest().time, 0.7, 0.0001, "newest kept")
	buf.clear()
	assert_true(buf.is_empty(), "cleared")


func test_same_receive_time() -> void:
	var buf := SnapshotBuffer.new()
	buf.push(_view(0.0, {5: Vector2(0, 0)}, 0.0), 1.0)
	buf.push(_view(0.05, {5: Vector2(50, 0)}, 0.0), 1.0)
	var vs := buf.sample(1.2)
	assert_near(_x(vs, 5), 50.0, 0.001, "zero-width interval uses newest")
