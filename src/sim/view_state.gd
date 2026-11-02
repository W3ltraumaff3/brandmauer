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
const PF_REVERSE_X := 64           # with PF_REVERSED: only left/right flipped (Teilwende, D-108)
const PF_REVERSE_Y := 128          # with PF_REVERSED: only up/down flipped

const EF_ELITE := 1
const EF_POISONED := 2
const EF_SLOWED := 4
const EF_WINDUP := 8
const EF_PARKED := 16
const EF_SHIELDED := 32
const EF_BUFFED := 64
const EF_HIT := 128

## Second enemy flag byte (D-092, D-093): the v0.3 status effects. Never set on
## status-immune enemies.
const EF2_SILENCED := 1            # "In Bearbeitung"
const EF2_REVERSED := 2            # "Rolle rückwärts"
const EF2_FILE_SHIFT := 2          # "Aktenkundig" stacks 0..5 in bits 2..4
const EF2_FILE_MASK := 7
const EF2_STICKER := 32            # Soli-Sticker
## Boss rules (GDD §14, D-108): set on encounter units only.
const EF2_STANDFEST := 64          # immune to stuns for a while (press-spokesperson shield)
const EF2_PRESSE := 128            # Pressekonferenz: invulnerable, golden outline

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
var e_flags2 := PackedByteArray()

var p_type := PackedByteArray()
var p_pos := PackedVector2Array()
var p_ang := PackedFloat32Array()

var k_type := PackedByteArray()
var k_pos := PackedVector2Array()

var h_type := PackedByteArray()
var h_pos := PackedVector2Array()
var h_rad := PackedFloat32Array()
var h_life := PackedFloat32Array()
var h_ang := PackedFloat32Array()      # radians; cone direction (Kahlschlag), 0 for round hazards

var s_type := PackedByteArray()
var s_pos := PackedVector2Array()
var s_hp := PackedFloat32Array()       # 0..1; 1 for summons that can't be hurt

## {} or {enc, hp, phase, shield, cast (0 none, else 1 + index into Content.BOSS_CASTS), cast_t}
var boss := {}


func clear() -> void:
	players.clear()
	e_id.clear(); e_type.clear(); e_pos.clear(); e_hp.clear(); e_flags.clear(); e_flags2.clear()
	p_type.clear(); p_pos.clear(); p_ang.clear()
	k_type.clear(); k_pos.clear()
	h_type.clear(); h_pos.clear(); h_rad.clear(); h_life.clear(); h_ang.clear()
	s_type.clear(); s_pos.clear(); s_hp.clear()
	boss = {}


## Aktenkundig stacks (0..5) from an e_flags2 byte.
static func file_stacks(flags2: int) -> int:
	return (flags2 >> EF2_FILE_SHIFT) & EF2_FILE_MASK


func find_player(id: int) -> Dictionary:
	for p in players:
		if p["id"] == id:
			return p
	return {}


## The boss's running cast id ('' = none) from the boss block (D-108).
func boss_cast() -> String:
	var c := int(boss.get("cast", 0))
	if c <= 0 or c > Content.BOSS_CASTS.size():
		return ""
	return Content.BOSS_CASTS[c - 1]
