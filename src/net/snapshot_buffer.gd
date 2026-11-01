class_name SnapshotBuffer
extends RefCounted
## Client-side interpolation buffer (docs/specs/networking.md §6).
## Snapshots are placed on a timeline by their receive time; sample() renders
## the world `delay` seconds in the past, interpolating enemies (by e_id) and
## players (by id) between the two surrounding snapshots. Projectiles, pickups,
## hazards and summons have no ids and are taken from the newer snapshot.
## Returned ViewStates are shared with the buffer: treat them as read-only.

const MAX_SNAPSHOTS := 10
const MAX_EXTRAPOLATION_S := 0.1

var _snaps: Array[ViewState] = []
var _times := PackedFloat64Array()


func push(vs: ViewState, recv_time_s: float) -> void:
	if vs == null:
		return
	# Out-of-order arrivals (rare with unreliable_ordered) are dropped.
	if not _times.is_empty() and recv_time_s < _times[_times.size() - 1]:
		return
	_snaps.append(vs)
	_times.append(recv_time_s)
	while _snaps.size() > MAX_SNAPSHOTS:
		_snaps.remove_at(0)
		_times.remove_at(0)


func clear() -> void:
	_snaps.clear()
	_times.clear()


func size() -> int:
	return _snaps.size()


func is_empty() -> bool:
	return _snaps.is_empty()


func newest() -> ViewState:
	return null if _snaps.is_empty() else _snaps[_snaps.size() - 1]


## Interpolated ViewState at `now_s - delay`. null if nothing was pushed yet.
func sample(now_s: float, delay := 0.1) -> ViewState:
	var n := _snaps.size()
	if n == 0:
		return null
	if n == 1:
		return _snaps[0]
	var t := now_s - delay
	if t <= _times[0]:
		return _snaps[0]
	var last := n - 1
	if t >= _times[last]:
		# Past the newest snapshot: extrapolate from the last two, at most 100 ms.
		var t_ext := minf(t, _times[last] + MAX_EXTRAPOLATION_S)
		var span := _times[last] - _times[last - 1]
		if span <= 0.000001 or t_ext <= _times[last]:
			return _snaps[last]
		return _blend(_snaps[last - 1], _snaps[last], (t_ext - _times[last - 1]) / span)
	var i := 0
	while i < last - 1 and _times[i + 1] <= t:
		i += 1
	var dt := _times[i + 1] - _times[i]
	var alpha := 1.0 if dt <= 0.000001 else (t - _times[i]) / dt
	return _blend(_snaps[i], _snaps[i + 1], alpha)


## New ViewState based on `b` (newer) with positions blended from `a` (older).
## alpha > 1 extrapolates.
static func _blend(a: ViewState, b: ViewState, alpha: float) -> ViewState:
	var out := ViewState.new()
	out.time = lerpf(a.time, b.time, alpha)
	out.phase = b.phase
	out.wave = b.wave
	out.wave_time_left = b.wave_time_left
	if a.wave == b.wave and a.wave_time_left >= 0.0 and b.wave_time_left >= 0.0:
		out.wave_time_left = maxf(0.0, lerpf(a.wave_time_left, b.wave_time_left, alpha))
	out.stage = b.stage
	out.wall = b.wall

	# Players, matched by id
	for pb in b.players:
		var p: Dictionary = pb.duplicate()
		var pa := a.find_player(int(pb["id"]))
		if not pa.is_empty():
			p["pos"] = (pa["pos"] as Vector2).lerp(pb["pos"], alpha)
			p["aim"] = lerp_angle(float(pa["aim"]), float(pb["aim"]), alpha)
		out.players.append(p)

	# Enemies, matched by e_id
	var index := {}
	for i in a.e_id.size():
		index[a.e_id[i]] = i
	var ne := mini(b.e_id.size(), b.e_pos.size())
	var pos := PackedVector2Array()
	pos.resize(ne)
	for i in ne:
		var j: int = index.get(b.e_id[i], -1)
		pos[i] = b.e_pos[i] if j < 0 or j >= a.e_pos.size() else a.e_pos[j].lerp(b.e_pos[i], alpha)
	out.e_id = b.e_id
	out.e_type = b.e_type
	out.e_pos = pos
	out.e_hp = b.e_hp
	out.e_flags = b.e_flags

	# No ids: newest wins
	out.p_type = b.p_type
	out.p_pos = b.p_pos
	out.p_ang = b.p_ang
	out.k_type = b.k_type
	out.k_pos = b.k_pos
	out.h_type = b.h_type
	out.h_pos = b.h_pos
	out.h_rad = b.h_rad
	out.h_life = b.h_life
	out.s_type = b.s_type
	out.s_pos = b.s_pos
	out.boss = b.boss
	return out
