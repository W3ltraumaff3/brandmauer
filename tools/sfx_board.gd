extends SceneTree
## Listen test for the sound effects (audio.md §8): fixed sequences through
## the real Audio mixer (plan, voices, buses, ducking) over the game music.
##   godot --path . -s res://tools/sfx_board.gd
## Needs a window and sound, so do NOT pass --headless. Reads the volume
## options from the save file and never writes it. A dev tool: German labels
## are hard-coded on purpose (not player-facing).

const ME := 0                   # no Game autoload here: Audio's local id is 0
const MATES := [2, 3, 4]

var _audio: Node
var _queue: Array = []          # [[t, events], ...] sorted by t
var _t := 0.0
var _status: Label
var _music_cat := "gameplay"


func _initialize() -> void:
	for n in ["Loc", "Save"]:
		if root.get_node_or_null(n) == null:
			var node: Node = load("res://src/autoload/%s.gd" % n.to_lower()).new()
			node.name = n
			root.add_child(node)
	root.get_node("Save").persist = false
	_audio = load("res://src/autoload/audio.gd").new()
	_audio.name = "Audio"
	root.add_child(_audio)
	_build.call_deferred()


func _build() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.theme = UITheme.get_theme()
	var bg := ColorRect.new()
	bg.color = UITheme.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var v := UIKit.vbox(10)
	var m := UIKit.margin(v, 24, 16, 24, 16)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(m)
	v.add_child(UIKit.heading("Hörprobe Soundeffekte (audio.md §8)", 32))
	var seq := HFlowContainer.new()
	v.add_child(seq)
	for s in [["1 Pfand-Serie", _seq_pfand], ["2 Gefecht", _seq_fight], ["3 Elite", _seq_elite],
			["4 Späti", _seq_spaeti], ["5 Ereignisse", _seq_events], ["Koop-Pfand", _seq_coop_pfand]]:
		seq.add_child(UIKit.button(s[0], _start.bind(s[1]), 22))
	var mus := HFlowContainer.new()
	v.add_child(mus)
	for cat in ["gameplay", "boss", "spaeti", "menu", ""]:
		mus.add_child(UIKit.button("Musik: " + (cat if cat != "" else "aus"), _music.bind(cat), 18))
	v.add_child(UIKit.label("Einzelne Dateien:", 20))
	var files := HFlowContainer.new()
	files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(files)
	for path in _audio.sfx_files():
		var f := str(path).get_file().get_basename()
		files.add_child(UIKit.compact(UIKit.button(f, _single.bind(f), 15), 1, 6))
	_status = UIKit.label("", 20, UITheme.INK_SOFT)
	v.add_child(_status)
	_music("gameplay")
	process_frame.connect(_tick)
	if "auto" in OS.get_cmdline_user_args():
		_auto()


## -- auto: prints the bus layout, plays every sequence once, then quits.
func _auto() -> void:
	for i in AudioServer.bus_count:
		var fx := []
		for k in AudioServer.get_bus_effect_count(i):
			fx.append(AudioServer.get_bus_effect(i, k).get_class())
		print("bus %s -> %s %s" % [AudioServer.get_bus_name(i), AudioServer.get_bus_send(i), fx])
	for s in [_seq_pfand, _seq_fight, _seq_elite, _seq_spaeti, _seq_events]:
		_start(s)
		while not _queue.is_empty():
			await process_frame
		await create_timer(1.5).timeout
	print("sfx_board: done")
	quit()


func _music(cat: String) -> void:
	_music_cat = cat
	if cat == "":
		_audio.stop_music()
	else:
		_audio.play_music(cat)


## One file as it is, through its bus, without jitter.
func _single(file: String) -> void:
	var id := file
	if file.begins_with("pfand_") and file != "pfand_top":
		id = "pfand"
	elif not _audio.SFX.has(file):
		id = file.substr(0, file.rfind("_"))
	_audio._play({"id": id, "file": file, "gain_db": 0.0, "pitch": 1.0})
	_status.text = file


func _start(build: Callable) -> void:
	_queue = build.call()
	_queue.sort_custom(func(a, b): return a[0] < b[0])
	_t = 0.0


func _tick() -> void:
	if _queue.is_empty():
		return
	_t += 1.0 / maxf(1.0, Engine.get_frames_per_second())
	var batch := []
	while not _queue.is_empty() and _queue[0][0] <= _t:
		var item = _queue.pop_front()[1]
		if item is String:
			_audio.play_sfx(item)   # a local UI sound, like UIApi.sfx
		else:
			batch.append_array(item)
	if not batch.is_empty():
		_audio._on_events(batch)
	_status.text = "%.1f s" % _t if not _queue.is_empty() else "fertig"


func _at(q: Array, t: float, ev: Array) -> void:
	q.append([t, [ev]])


func _seq_pfand() -> Array:
	var q := []
	for i in 14:
		_at(q, 0.12 * i, ["sfx", "pickup", Vector2.INF, ME])
	for i in 5:
		_at(q, 0.12 * 13 + 1.0 + 0.12 * i, ["sfx", "pickup", Vector2.INF, ME])
	return q


func _seq_coop_pfand() -> Array:
	var q := _seq_pfand()
	for i in 20:
		_at(q, 0.05 + 0.15 * i, ["sfx", "pickup", Vector2(150, 0), MATES[i % 3]])
	return q


## 6 s: 4 players firing, hits, 3 crits/s, 2 kills/s; a level-up at 3 s and a
## down at 4.5 s must stay clearly audible.
func _seq_fight() -> Array:
	var q := []
	var t := 0.0
	var i := 0
	while t < 6.0:
		_at(q, t, ["sfx", "shoot", Vector2.INF, ME])
		_at(q, t + 0.02, ["sfx", "shoot" if i % 2 == 0 else "melee", Vector2(120, 40), MATES[i % 3]])
		_at(q, t + 0.04, ["dmg", Vector2.INF, 12, false, false, ME])
		i += 1
		t += 0.08
	for k in 18:
		_at(q, 0.33 * k + 0.1, ["dmg", Vector2.INF, 40, true, false, ME if k % 2 == 0 else MATES[k % 3]])
	for k in 12:
		_at(q, 0.5 * k + 0.2, ["kill", Vector2(80, 0), 0, ME if k % 3 != 2 else MATES[0], false, false])
	_at(q, 1.5, ["sfx", "explosion", Vector2(200, 0), 0])
	_at(q, 3.0, ["levelup", 5])
	_at(q, 4.5, ["down", MATES[1]])
	return q


func _seq_elite() -> Array:
	var q := []
	_at(q, 0.0, ["dmg", Vector2.INF, 80, true, false, ME])
	_at(q, 0.05, ["kill", Vector2.INF, 0, ME, true, false])
	for k in 6:
		_at(q, 0.35 + 0.07 * k, ["sfx", "pickup", Vector2.INF, ME])
	return q


func _seq_spaeti() -> Array:
	var q := []
	var t := 0.0
	for id in ["buy_1", "buy_2", "buy_3", "buy_4", "sell"]:
		q.append([t, id])
		t += 1.3
	for tier in [2, 3, 4]:
		_at(q, t, ["combine", ME, "tofu", tier])
		t += 1.1
	q.append([t, "error"])
	return q


func _seq_events() -> Array:
	var q := []
	var t := 0.0
	for ev in [["wave_start", 2], ["wave_end", 2], ["card", "x"], ["wende", 4.0, 0], ["streik", 8.0], ["revive", 2]]:
		_at(q, t, ev)
		t += 2.0
	return q
