extends Node
## Run flow and run controller (docs/specs/architecture.md §7, §8).
## Host/solo/server: steps the Sim, sends snapshots, meta and events.
## Client: sends input, interpolates snapshots and predicts its own movement.

enum Mode { NONE, SOLO, HOST, CLIENT, SERVER }

signal screen_requested(screen: String)
signal meta_changed
signal events(events: Array)
signal run_started
signal run_finished(result: Dictionary)
signal message(text_key: String)

const TICK := 1.0 / 60.0
const SNAPSHOT_EVERY := 3        # physics frames -> 20 Hz
const META_INTERVAL := 0.1
const END_DELAY := 3.0

var mode: Mode = Mode.NONE
var meta := {}
var view: ViewState = ViewState.new()
var config := {}
var blackrock := false
var last_unlocks := {}
var sim: Sim

var _paused := false
var _frame := 0
var _meta_timer := 0.0
var _end_timer := -1.0
var _buffer: SnapshotBuffer
var _seq := 0
var _inputs: Array = []          # client prediction: [{seq, dir, dt}]
var _pred_pos := Vector2.INF
var _last_ack := 0
var _clock := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_input()
	Net.run_start_received.connect(_on_run_start)
	Net.snapshot_received.connect(_on_snapshot)
	Net.meta_received.connect(_on_meta)
	Net.events_received.connect(_on_events)
	Net.input_received.connect(_on_input)
	Net.request_received.connect(_on_request)
	Net.peer_left.connect(_on_peer_left)
	Net.disconnected.connect(_on_disconnected)
	Net.connected.connect(_on_connected)
	Net.connection_failed.connect(_on_connection_failed)
	Net.returned_to_lobby.connect(_on_returned_to_lobby)
	if "--server" in OS.get_cmdline_user_args() or "--server" in OS.get_cmdline_args():
		mode = Mode.SERVER


func _register_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"streik": [KEY_Q], "pause": [KEY_ESCAPE], "ultimate": [KEY_SPACE],
	}
	var pad := {"streik": JOY_BUTTON_Y, "pause": JOY_BUTTON_START, "ultimate": JOY_BUTTON_X}
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.3)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		if pad.has(action):
			var jb := InputEventJoypadButton.new()
			jb.button_index = pad[action]
			InputMap.action_add_event(action, jb)
		if axes.has(action):
			var ja := InputEventJoypadMotion.new()
			ja.axis = axes[action][0]
			ja.axis_value = axes[action][1]
			InputMap.action_add_event(action, ja)


# --- Public API --------------------------------------------------------------

func local_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	return multiplayer.get_unique_id()


func local_meta() -> Dictionary:
	return meta.get("players", {}).get(local_id(), {})


func is_host_side() -> bool:
	return mode == Mode.SOLO or mode == Mode.HOST or mode == Mode.SERVER


func is_running() -> bool:
	return not config.is_empty()


func open_solo() -> void:
	_reset_run()
	mode = Mode.SOLO
	Net.start_solo(_player_name())
	screen_requested.emit("lobby")


func open_host(player_name: String, use_upnp: bool) -> void:
	_reset_run()
	var err := Net.host(player_name, Net.PORT, use_upnp)
	if err != OK:
		message.emit("NET_ERR_HOST")
		return
	mode = Mode.HOST
	screen_requested.emit("lobby")


func open_join(ip: String, port: int, player_name: String) -> void:
	_reset_run()
	mode = Mode.CLIENT
	Net.join(ip, port, player_name)


func start_run() -> void:
	if not is_host_side() or is_running():
		return
	var players := []
	for id in Net.lobby:
		var entry: Dictionary = Net.lobby[id]
		var char_id: String = entry.get("char", "stadtbild")
		players.append({"id": int(id), "name": entry.get("name", ""), "char": char_id})
	if players.is_empty():
		return
	var cfg := {
		"seed": randi(), "players": players, "org": Net.org,
		"difficulty": Net.difficulty, "blackrock": blackrock,
	}
	Net.broadcast_run_start(cfg)


func request(action: String, arg = null) -> void:
	if not is_running():
		return
	if is_host_side():
		if sim and mode != Mode.SERVER:
			sim.request(local_id(), action, arg)
			_flush_events()
	else:
		Net.send_request(action, arg)


## Sends the player's targeting preference (Save option "target_mode") to the host.
func send_target_mode() -> void:
	if is_running():
		request("target_mode", int(Save.option("target_mode", 0)))


func back_to_lobby() -> void:
	if is_host_side():
		Net.return_to_lobby()


func quit_to_menu() -> void:
	_reset_run()
	Net.leave()
	mode = Mode.NONE
	_paused = false
	get_tree().paused = false
	screen_requested.emit("menu")


func is_paused() -> bool:
	return _paused


func set_paused(p: bool) -> void:
	_paused = p and mode == Mode.SOLO


# --- Net callbacks -----------------------------------------------------------

func _on_connected() -> void:
	if mode == Mode.CLIENT:
		screen_requested.emit("lobby")


func _on_connection_failed(_reason: String) -> void:
	# The join dialog shows the reason itself.
	mode = Mode.NONE
	screen_requested.emit("menu")


func _on_disconnected(reason: String) -> void:
	if mode == Mode.CLIENT:
		message.emit(reason)
		quit_to_menu()


func _on_run_start(cfg: Dictionary) -> void:
	_reset_run()
	config = cfg
	view = ViewState.new()
	if is_host_side():
		sim = Sim.new()
		sim.start_run(cfg)
		sim.build_view(view)
		meta = sim.build_meta()
		_flush_events()
	else:
		_buffer = SnapshotBuffer.new()
		meta = {}
	meta_changed.emit()
	run_started.emit()
	if mode != Mode.SERVER:
		send_target_mode()
	if mode != Mode.SERVER:
		screen_requested.emit("run")
	else:
		print("[Brandmauer] Run gestartet: %d Spieler" % cfg.get("players", []).size())


func _on_snapshot(bytes: PackedByteArray) -> void:
	if is_host_side() or _buffer == null:
		return
	var vs := Snapshot.decode(bytes)
	if vs == null:
		return
	_buffer.push(vs, _clock)
	var me := vs.find_player(local_id())
	if not me.is_empty():
		_last_ack = int(me.get("seq", 0))
		_reconcile(me)


func _on_meta(m: Dictionary) -> void:
	if is_host_side():
		return
	var old_phase := int(meta.get("phase", -1))
	meta = m
	meta_changed.emit()
	if int(m.get("phase", -1)) == Sim.Phase.OVER and old_phase != Sim.Phase.OVER:
		_end_timer = END_DELAY


func _on_events(evs: Array) -> void:
	if not is_host_side():
		events.emit(evs)


func _on_input(peer: int, seq: int, dir: Vector2) -> void:
	if sim:
		sim.set_input(peer, dir, seq)


func _on_request(peer: int, action: String, arg) -> void:
	if sim:
		sim.request(peer, action, arg)
		_flush_events()


func _on_peer_left(peer: int) -> void:
	if sim:
		sim.remove_player(peer)


func _on_returned_to_lobby() -> void:
	_reset_run()
	if mode == Mode.SERVER:
		return
	screen_requested.emit("lobby")


# --- Run loop ----------------------------------------------------------------

func _reset_run() -> void:
	config = {}
	sim = null
	_buffer = null
	meta = {}
	view = ViewState.new()
	_inputs.clear()
	_pred_pos = Vector2.INF
	_end_timer = -1.0
	_seq = 0
	_last_ack = 0


func _process(_dt: float) -> void:
	# Boss card: the world waits until every player pressed W/A/S/D or Space.
	if not is_running() or mode == Mode.SERVER or not bool(meta.get("intro_wait", false)):
		return
	if local_id() in meta.get("intro_done", []):
		return
	for action in ["move_left", "move_right", "move_up", "move_down", "ultimate"]:
		if Input.is_action_just_pressed(action):
			request("continue_intro")
			return


func _physics_process(dt: float) -> void:
	_clock += dt
	if not is_running():
		return
	if is_host_side():
		_host_tick(dt)
	else:
		_client_tick(dt)
	if _end_timer > 0.0:
		_end_timer -= dt
		if _end_timer <= 0.0:
			_show_end()


func _local_dir() -> Vector2:
	if mode == Mode.SERVER or get_tree().paused:
		return Vector2.ZERO
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _host_tick(dt: float) -> void:
	if sim == null:
		return
	if mode != Mode.SERVER:
		sim.set_input(local_id(), _local_dir())
	if not _paused:
		var was_over := sim.phase == Sim.Phase.OVER
		sim.step(TICK)
		if sim.phase == Sim.Phase.OVER and not was_over:
			_end_timer = END_DELAY
	_flush_events()
	sim.build_view(view)
	_frame += 1
	if mode != Mode.SOLO and _frame % SNAPSHOT_EVERY == 0:
		Net.send_snapshot(Snapshot.encode(view))
	_meta_timer -= dt
	if sim.meta_dirty and _meta_timer <= 0.0:
		_meta_timer = META_INTERVAL
		sim.meta_dirty = false
		meta = sim.build_meta()
		if mode != Mode.SOLO:
			Net.send_meta(meta)
		meta_changed.emit()


func _flush_events() -> void:
	if sim == null:
		return
	var evs := sim.take_events()
	if evs.is_empty():
		return
	if mode != Mode.SOLO:
		Net.send_events(evs)
	events.emit(evs)
	# Requests change meta; make shop interactions feel instant.
	if sim.meta_dirty and sim.phase != Sim.Phase.WAVE:
		sim.meta_dirty = false
		meta = sim.build_meta()
		_meta_timer = META_INTERVAL
		if mode != Mode.SOLO:
			Net.send_meta(meta)
		meta_changed.emit()


func _client_tick(dt: float) -> void:
	if _buffer == null:
		return
	var dir := _local_dir()
	_seq += 1
	Net.send_input(_seq, dir)
	var sampled: ViewState = _buffer.sample(_clock)
	if sampled == null:
		return
	view = sampled
	var me := view.find_player(local_id())
	if me.is_empty() or int(me["state"]) != 0 or int(meta.get("phase", 0)) != Sim.Phase.WAVE:
		_inputs.clear()
		_pred_pos = Vector2.INF
		return
	var flags := int(me.get("flags", 0))
	if flags & ViewState.PF_REVERSED:
		dir = -dir
	if flags & ViewState.PF_STUNNED:
		dir = Vector2.ZERO
	_inputs.append({"seq": _seq, "dir": dir})
	if _inputs.size() > 120:
		_inputs.pop_front()
	if _pred_pos == Vector2.INF:
		_pred_pos = me["pos"]
	_pred_pos = Sim.move_player(_pred_pos, dir, _local_speed(), TICK)
	me["pos"] = _pred_pos


func _local_speed() -> float:
	var stats: Dictionary = local_meta().get("stats", {})
	return Content.PLAYER_BASE_SPEED * maxf(0.3, 1.0 + float(stats.get("speed", 0.0)) / 100.0)


## Server state for our player arrived: replay unacknowledged inputs on top.
func _reconcile(me: Dictionary) -> void:
	if _pred_pos == Vector2.INF:
		return
	_inputs = _inputs.filter(func(i): return i["seq"] > _last_ack)
	var pos: Vector2 = me["pos"]
	for i in _inputs:
		pos = Sim.move_player(pos, i["dir"], _local_speed(), TICK)
	# Smooth small corrections, snap large ones (knockback, teleports).
	if pos.distance_to(_pred_pos) > 80.0:
		_pred_pos = pos
	else:
		_pred_pos = _pred_pos.lerp(pos, 0.35)


func _show_end() -> void:
	var result: Dictionary = meta.get("result", {})
	if mode == Mode.SERVER:
		print("[Brandmauer] Run beendet: %s, Welle %d" % ["Sieg" if result.get("won", false) else "Niederlage", result.get("wave", 0)])
		get_tree().create_timer(5.0).timeout.connect(func(): Net.return_to_lobby())
		return
	last_unlocks = Save.apply_result(result, local_id())
	run_finished.emit(result)
	screen_requested.emit("end")


func _player_name() -> String:
	return str(Save.option("name", "Genoss:in"))
