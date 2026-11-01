class_name ViewState
extends RefCounted
## Everything needed to draw one frame (docs/specs/architecture.md §3).
## Built from the Sim on the host, decoded from snapshots on clients.

const PF_REVERSED := 1
const PF_STUNNED := 2
const PF_STILL := 4
const PF_INVULNERABLE := 8
const PF_REVIVING := 16
const PF_ULT := 32

const EF_ELITE := 1
const EF_POISONED := 2
const EF_SLOWED := 4
const EF_WINDUP := 8
const EF_PARKED := 16
const EF_SHIELDED := 32
const EF_BUFFED := 64
const EF_HIT := 128

var time := 0.0
var phase := 0
var wave := 0
var wave_time_left := 0.0
var stage := 0
var wall := 0

var players: Array[Dictionary] = []

var e_id := PackedInt32Array()
var e_type := PackedByteArray()
var e_pos := PackedVector2Array()
var e_hp := PackedFloat32Array()
var e_flags := PackedByteArray()

var p_type := PackedByteArray()
var p_pos := PackedVector2Array()
var p_ang := PackedFloat32Array()

var k_type := PackedByteArray()
var k_pos := PackedVector2Array()

var h_type := PackedByteArray()
var h_pos := PackedVector2Array()
var h_rad := PackedFloat32Array()
var h_life := PackedFloat32Array()

var s_type := PackedByteArray()
var s_pos := PackedVector2Array()

var boss := {}


func clear() -> void:
	players.clear()
	e_id.clear(); e_type.clear(); e_pos.clear(); e_hp.clear(); e_flags.clear()
	p_type.clear(); p_pos.clear(); p_ang.clear()
	k_type.clear(); k_pos.clear()
	h_type.clear(); h_pos.clear(); h_rad.clear(); h_life.clear()
	s_type.clear(); s_pos.clear()
	boss = {}


func find_player(id: int) -> Dictionary:
	for p in players:
		if p["id"] == id:
			return p
	return {}
