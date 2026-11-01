class_name Snapshot
## ViewState <-> bytes (docs/specs/networking.md §6, architecture.md §3).
## Little endian, versioned, quantized, struct-of-arrays (compresses well with
## ENet's range coder). Everything is a full snapshot, no deltas.
##
## Quantization (max error after a round trip):
##   positions  int16, rounded           -> 0.5 px
##   fractions  u8 0..255 (hp, life, ..) -> 1/510
##   angles     s8, TAU/256 per step     -> TAU/512
##   radii      u16, rounded             -> 0.5 px
##   ids        int32 (exact); player seq u32; player hp / max_hp, time, wave_time_left float32

const VERSION := 1

const MAX_PLAYERS := 8
const MAX_WEAPONS := 16
const MAX_ENEMIES := 300
const MAX_PROJECTILES := 400
const MAX_PICKUPS := 300
const MAX_HAZARDS := 64
const MAX_SUMMONS := 64

const POS_STEP := 1.0
const FRAC_STEP := 1.0 / 255.0
const ANGLE_STEP := TAU / 256.0


static func encode(vs: ViewState) -> PackedByteArray:
	var b := StreamPeerBuffer.new()
	b.big_endian = false
	b.put_u8(VERSION)
	b.put_float(vs.time)
	b.put_u8(clampi(vs.phase, 0, 255))
	b.put_u8(clampi(vs.wave, 0, 255))
	b.put_float(vs.wave_time_left)
	b.put_u8(clampi(vs.stage, 0, 255))
	b.put_u16(vs.wall & 0xFFFF)

	# Players
	var np := mini(vs.players.size(), MAX_PLAYERS)
	b.put_u8(np)
	for i in np:
		var p: Dictionary = vs.players[i]
		b.put_32(int(p.get("id", 0)))
		b.put_u8(clampi(int(p.get("char", 0)), 0, 255))
		_put_pos(b, p.get("pos", Vector2.ZERO))
		b.put_float(float(p.get("hp", 0.0)))
		b.put_float(float(p.get("max_hp", 0.0)))
		b.put_u8(clampi(int(p.get("state", 0)), 0, 255))
		b.put_u8(_angle(float(p.get("aim", 0.0))))
		b.put_u8(int(p.get("flags", 0)) & 0xFF)
		b.put_u16(clampi(int(p.get("followers", 0)), 0, 0xFFFF))
		b.put_u32(clampi(int(p.get("seq", 0)), 0, 0xFFFFFFFF))
		var w: PackedByteArray = p.get("weapons", PackedByteArray())
		var nw := mini(w.size(), MAX_WEAPONS)
		b.put_u8(nw)
		if nw > 0:
			b.put_data(w.slice(0, nw))

	# Enemies
	var ne := mini(MAX_ENEMIES, mini(mini(vs.e_id.size(), vs.e_type.size()),
			mini(vs.e_pos.size(), mini(vs.e_hp.size(), vs.e_flags.size()))))
	b.put_u16(ne)
	for i in ne:
		b.put_32(vs.e_id[i])
	_put_bytes(b, vs.e_type, ne)
	_put_positions(b, vs.e_pos, ne)
	_put_fracs(b, vs.e_hp, ne)
	_put_bytes(b, vs.e_flags, ne)

	# Projectiles
	var nproj := mini(MAX_PROJECTILES, mini(vs.p_type.size(), mini(vs.p_pos.size(), vs.p_ang.size())))
	b.put_u16(nproj)
	_put_bytes(b, vs.p_type, nproj)
	_put_positions(b, vs.p_pos, nproj)
	var ang := PackedByteArray()
	ang.resize(nproj)
	for i in nproj:
		ang[i] = _angle(vs.p_ang[i])
	b.put_data(ang)

	# Pickups
	var nk := mini(MAX_PICKUPS, mini(vs.k_type.size(), vs.k_pos.size()))
	b.put_u16(nk)
	_put_bytes(b, vs.k_type, nk)
	_put_positions(b, vs.k_pos, nk)

	# Hazards
	var nh := mini(MAX_HAZARDS, mini(mini(vs.h_type.size(), vs.h_pos.size()), mini(vs.h_rad.size(), vs.h_life.size())))
	b.put_u16(nh)
	_put_bytes(b, vs.h_type, nh)
	_put_positions(b, vs.h_pos, nh)
	for i in nh:
		b.put_u16(clampi(roundi(vs.h_rad[i]), 0, 0xFFFF))
	_put_fracs(b, vs.h_life, nh)

	# Summons
	var ns := mini(MAX_SUMMONS, mini(vs.s_type.size(), vs.s_pos.size()))
	b.put_u16(ns)
	_put_bytes(b, vs.s_type, ns)
	_put_positions(b, vs.s_pos, ns)

	# Boss
	if vs.boss.is_empty():
		b.put_u8(0)
	else:
		b.put_u8(1)
		b.put_u8(clampi(int(vs.boss.get("enc", 0)), 0, 255))
		b.put_u8(_frac(float(vs.boss.get("hp", 0.0))))
		b.put_u8(clampi(int(vs.boss.get("phase", 0)), 0, 255))
		b.put_u8(_frac(float(vs.boss.get("shield", 0.0))))
	return b.data_array


## Returns null if the bytes are truncated, malformed or of another version.
static func decode(bytes: PackedByteArray) -> ViewState:
	var b := StreamPeerBuffer.new()
	b.big_endian = false
	b.data_array = bytes
	if not _need(b, 15) or b.get_u8() != VERSION:
		return null
	var vs := ViewState.new()
	vs.time = b.get_float()
	vs.phase = b.get_u8()
	vs.wave = b.get_u8()
	vs.wave_time_left = b.get_float()
	vs.stage = b.get_u8()
	vs.wall = b.get_u16()

	var np := b.get_u8()
	for i in np:
		if not _need(b, 27):
			return null
		var p := {}
		p["id"] = b.get_32()
		p["char"] = b.get_u8()
		p["pos"] = _get_pos(b)
		p["hp"] = b.get_float()
		p["max_hp"] = b.get_float()
		p["state"] = b.get_u8()
		p["aim"] = _unangle(b.get_u8())
		p["flags"] = b.get_u8()
		p["followers"] = b.get_u16()
		p["seq"] = b.get_u32()
		var nw := b.get_u8()
		if not _need(b, nw):
			return null
		p["weapons"] = _get_bytes(b, nw)
		vs.players.append(p)

	if not _need(b, 2):
		return null
	var ne := b.get_u16()
	if not _need(b, ne * 11):
		return null
	vs.e_id.resize(ne)
	for i in ne:
		vs.e_id[i] = b.get_32()
	vs.e_type = _get_bytes(b, ne)
	vs.e_pos = _get_positions(b, ne)
	vs.e_hp = _get_fracs(b, ne)
	vs.e_flags = _get_bytes(b, ne)

	if not _need(b, 2):
		return null
	var nproj := b.get_u16()
	if not _need(b, nproj * 6):
		return null
	vs.p_type = _get_bytes(b, nproj)
	vs.p_pos = _get_positions(b, nproj)
	var ang := _get_bytes(b, nproj)
	vs.p_ang.resize(nproj)
	for i in nproj:
		vs.p_ang[i] = _unangle(ang[i])

	if not _need(b, 2):
		return null
	var nk := b.get_u16()
	if not _need(b, nk * 5):
		return null
	vs.k_type = _get_bytes(b, nk)
	vs.k_pos = _get_positions(b, nk)

	if not _need(b, 2):
		return null
	var nh := b.get_u16()
	if not _need(b, nh * 8):
		return null
	vs.h_type = _get_bytes(b, nh)
	vs.h_pos = _get_positions(b, nh)
	vs.h_rad.resize(nh)
	for i in nh:
		vs.h_rad[i] = float(b.get_u16())
	vs.h_life = _get_fracs(b, nh)

	if not _need(b, 2):
		return null
	var ns := b.get_u16()
	if not _need(b, ns * 5 + 1):
		return null
	vs.s_type = _get_bytes(b, ns)
	vs.s_pos = _get_positions(b, ns)

	if b.get_u8() == 1:
		if not _need(b, 4):
			return null
		vs.boss = {
			"enc": b.get_u8(),
			"hp": b.get_u8() * FRAC_STEP,
			"phase": b.get_u8(),
			"shield": b.get_u8() * FRAC_STEP,
		}
	return vs


# --- helpers -----------------------------------------------------------------

static func _need(b: StreamPeerBuffer, n: int) -> bool:
	return b.get_available_bytes() >= n


static func _q16(v: float) -> int:
	if is_nan(v):
		return 0
	return clampi(roundi(clampf(v, -32768.0, 32767.0)), -32768, 32767)


static func _frac(v: float) -> int:
	if is_nan(v):
		return 0
	return roundi(clampf(v, 0.0, 1.0) * 255.0)


static func _angle(a: float) -> int:
	if not is_finite(a):
		return 0
	return roundi(a / ANGLE_STEP) & 0xFF


static func _unangle(q: int) -> float:
	# Signed so the result lies in [-PI, PI) like atan2 / Vector2.angle().
	return float(q - 256 if q >= 128 else q) * ANGLE_STEP


static func _put_pos(b: StreamPeerBuffer, v: Vector2) -> void:
	b.put_16(_q16(v.x))
	b.put_16(_q16(v.y))


static func _get_pos(b: StreamPeerBuffer) -> Vector2:
	var x := b.get_16()
	return Vector2(x, b.get_16())


static func _put_positions(b: StreamPeerBuffer, arr: PackedVector2Array, n: int) -> void:
	for i in n:
		var v := arr[i]
		b.put_16(_q16(v.x))
		b.put_16(_q16(v.y))


static func _get_positions(b: StreamPeerBuffer, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(n)
	for i in n:
		var x := b.get_16()
		out[i] = Vector2(x, b.get_16())
	return out


static func _put_bytes(b: StreamPeerBuffer, arr: PackedByteArray, n: int) -> void:
	if n > 0:
		b.put_data(arr.slice(0, n))


static func _get_bytes(b: StreamPeerBuffer, n: int) -> PackedByteArray:
	if n <= 0:
		return PackedByteArray()
	return b.get_data(n)[1]


static func _put_fracs(b: StreamPeerBuffer, arr: PackedFloat32Array, n: int) -> void:
	var q := PackedByteArray()
	q.resize(n)
	for i in n:
		q[i] = _frac(arr[i])
	_put_bytes(b, q, n)


static func _get_fracs(b: StreamPeerBuffer, n: int) -> PackedFloat32Array:
	var q := _get_bytes(b, n)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = q[i] * FRAC_STEP
	return out
