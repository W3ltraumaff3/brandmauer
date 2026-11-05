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
var _resume := {}                # host: checkpoint for the next run start (continue_run)
var _saved_seq := -1             # Sim.checkpoint_seq last written to the run save


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
	Net.peer_away.connect(_on_peer_away)
	Net.peer_back.connect(_on_peer_back)
	Net.run_resent.connect(_on_run_resent)
	Net.reconnected.connect(_on_reconnected)
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
		"lock_offer": [KEY_L],   # Späti: Reservieren the focused offer (D-148, D-153); Y is Streik only in waves
	}
	var pad := {"streik": JOY_BUTTON_Y, "pause": JOY_BUTTON_START, "ultimate": JOY_BUTTON_X, "lock_offer": JOY_BUTTON_Y}
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
		# device = -1: accept every controller, not only device 0 (other HID devices, e.g.
		# analog keyboards, can take device 0 and the real pad becomes 1).
		if pad.has(action):
			var jb := InputEventJoypadButton.new()
			jb.device = -1
			jb.button_index = pad[action]
			InputMap.action_add_event(action, jb)
		if axes.has(action):
			var ja := InputEventJoypadMotion.new()
			ja.device = -1
			ja.axis = axes[action][0]
			ja.axis_value = axes[action][1]
			InputMap.action_add_event(action, ja)


# --- Public API --------------------------------------------------------------

## Our player id (Sim/meta/view key). After a reconnect this is still the peer
## id of the first join, not the current ENet peer id (networking.md §7.4).
func local_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	return Net.local_player_id()


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


## Main menu "Zurück ins Spiel" (networking.md §7.5): back into the co-op run
## this machine left by crashing or losing the connection.
func open_rejoin() -> bool:
	var info := Save.rejoin_info()
	if info.is_empty():
		return false
	_reset_run()
	mode = Mode.CLIENT
	Net.rejoin(info["ip"], info["port"], info["token"], info["player"])
	return true


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
		"difficulty": Net.difficulty, "blackrock": blackrock, "boss_retry": Net.boss_retry,
		"wave_retry": Net.wave_retry,
	}
	Net.broadcast_run_start(cfg)


# --- Run save: continue a run (GDD §17 "Weiterspielen", D-162) ----------------

## Summary of the saved run for menu and lobby (Sim.checkpoint_summary), or {}.
func continue_info() -> Dictionary:
	return Sim.checkpoint_summary(Save.run_save())


## Main menu "Weiterspielen" for a one-player save: straight into the run.
## A co-op save goes through open_continue_host and the lobby instead.
func open_continue() -> bool:
	var info := continue_info()
	if info.is_empty() or (info["players"] as Array).size() != 1:
		return false
	open_solo()
	Net.set_char(str(info["players"][0]["char"]))
	if continue_run():
		return true
	return false


## Co-op save: host lobby with the host's saved character picked; "Fortsetzen" there.
func open_continue_host(player_name: String, use_upnp: bool) -> void:
	open_host(player_name, use_upnp)
	if mode != Mode.HOST:
		return
	for sp in continue_info().get("players", []):
		if int(sp["id"]) == 1:
			Net.set_char(str(sp["char"]))


## Host: starts the saved run with the players in the lobby (resume_mapping).
func continue_run() -> bool:
	if not is_host_side() or mode == Mode.SERVER or is_running():
		return false
	var cp := Save.run_save()
	var mapping := resume_mapping(Net.lobby, cp)
	if mapping.is_empty():
		return false
	var chars := {}
	for sp in Sim.checkpoint_summary(cp)["players"]:
		chars[int(sp["id"])] = str(sp["char"])
	var players := []
	for id in Net.lobby:
		var from := int(mapping[int(id)])
		players.append({"id": int(id), "name": Net.lobby[id].get("name", ""), "char": chars[from], "from": from})
	var cfg: Dictionary = (cp.get("config", {}) as Dictionary).duplicate(true)
	cfg["players"] = players
	_resume = cp
	Net.broadcast_run_start(cfg)
	return true


## Lobby: whether "Fortsetzen" can start the saved run with the current lobby.
func can_continue() -> bool:
	return is_host_side() and not resume_mapping(Net.lobby, Save.run_save()).is_empty()


## Lobby player id -> saved player id: same character and name first, then the
## same character, then any free one in order. {} when the lobby is empty or has
## more players than the save has characters.
static func resume_mapping(lobby: Dictionary, cp: Dictionary) -> Dictionary:
	var saved: Array = Sim.checkpoint_summary(cp).get("players", [])
	if lobby.is_empty() or lobby.size() > saved.size():
		return {}
	var out := {}
	var used := {}
	for pass_i in 3:
		for id in lobby:
			if out.has(int(id)):
				continue
			var entry: Dictionary = lobby[id]
			for sp in saved:
				if used.has(sp["id"]):
					continue
				var same_char: bool = sp["char"] == str(entry.get("char", ""))
				var same_name: bool = sp["name"] == str(entry.get("name", ""))
				if pass_i == 2 or (same_char and (same_name or pass_i == 1)):
					out[int(id)] = sp["id"]
					used[sp["id"]] = true
					break
	return out


## Pause menu "Aufgeben": the run is over for good.
func give_up() -> void:
	if is_host_side():
		Save.clear_run()
		_saved_seq = -1
		sim = null
	quit_to_menu()


## Host side: keeps the run save up to date. A new Sim checkpoint is written as
## it comes; in the Späti (shop_now) the current state is. A decided run has none.
func _sync_run_save(shop_now := false) -> void:
	if sim == null or (mode != Mode.SOLO and mode != Mode.HOST):
		return
	if sim.phase == Sim.Phase.OVER:
		if _saved_seq != -2:
			_saved_seq = -2
			Save.clear_run()
		return
	if shop_now and sim.phase == Sim.Phase.SHOP:
		_saved_seq = sim.checkpoint_seq
		Save.write_run(sim.make_checkpoint("shop"))
	elif sim.checkpoint_seq != _saved_seq:
		_saved_seq = sim.checkpoint_seq
		Save.write_run(sim.checkpoint)


func request(action: String, arg = null) -> void:
	if not is_running():
		return
	if is_host_side():
		if sim and mode != Mode.SERVER:
			sim.request(local_id(), action, arg)
			_flush_events()
			_sync_run_save(true)
	else:
		Net.send_request(action, arg)


## Sends the player's targeting preference (Save option "target_mode") to the host.
func send_target_mode() -> void:
	if is_running():
		request("target_mode", int(Save.option("target_mode", 0)))


func back_to_lobby() -> void:
	if is_host_side():
		Net.return_to_lobby()


## keep_rejoin: the run goes on without us (lost connection), so the saved
## session stays for "Zurück ins Spiel". Every deliberate exit drops it.
func quit_to_menu(keep_rejoin := false) -> void:
	if not keep_rejoin:
		Save.clear_rejoin()
	_sync_run_save(true)
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
		# Lost mid-run: the host keeps our character, so a rejoin stays possible.
		quit_to_menu(reason == "NET_ERR_LOST" and is_running())


func _on_run_start(cfg: Dictionary) -> void:
	var resume := _resume
	_reset_run()
	config = cfg
	view = ViewState.new()
	if is_host_side():
		sim = Sim.new()
		if resume.is_empty():
			sim.start_run(cfg)
		else:
			sim.resume_run(cfg, resume)
		_sync_run_save()
		sim.build_view(view)
		meta = sim.build_meta()
		_flush_events()
	else:
		_buffer = SnapshotBuffer.new()
		meta = {}
		var session := Net.session_info()
		if mode == Mode.CLIENT and not session.is_empty():
			Save.set_rejoin(session)
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
		_sync_run_save(true)


func _on_peer_left(peer: int) -> void:
	if sim:
		sim.remove_player(peer)
		_flush_events()


## Host: a client's connection dropped mid-run; its character waits (grace period).
func _on_peer_away(peer: int) -> void:
	if sim:
		sim.set_away(peer, true)
		_flush_events()


## Host: an away client reconnected; resend meta so it catches up at once.
func _on_peer_back(peer: int) -> void:
	if sim:
		sim.set_away(peer, false)
		sim.meta_dirty = true
		_meta_timer = 0.0
		_flush_events()


## Host: a client rejoined from the menu and got the run config; it needs a
## full meta after that (one sent before the config is dropped by its run start).
func _on_run_resent(_peer: int) -> void:
	if sim:
		sim.meta_dirty = true
		_meta_timer = 0.0


## Closing the window is a deliberate leave (Net says goodbye): no rejoin.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.clear_rejoin()
		_sync_run_save(true)   # closing in the Späti keeps it as it is


## Client: back in the run after a lost connection. Drop stale snapshots and
## predicted inputs the host never saw; the next snapshot takes over.
func _on_reconnected() -> void:
	if is_host_side():
		return
	if not is_running():
		Net.request_run()  # rejoined from the menu: the host sends the run config
		return
	_buffer = SnapshotBuffer.new()
	_inputs.clear()
	_pred_pos = Vector2.INF
	send_target_mode()


func _on_returned_to_lobby() -> void:
	Save.clear_rejoin()
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
	_resume = {}
	_saved_seq = -1


func _process(_dt: float) -> void:
	if not is_running() or mode == Mode.SERVER or _paused:
		return
	# Boss card: the world waits until every player pressed W/A/S/D or Space.
	if bool(meta.get("intro_wait", false)):
		if local_id() in meta.get("intro_done", []):
			return
		for action in ["move_left", "move_right", "move_up", "move_down", "ultimate"]:
			if Input.is_action_just_pressed(action):
				request("continue_intro")
				return
		return
	if int(meta.get("phase", -1)) == Sim.Phase.WAVE and Input.is_action_just_pressed("ultimate"):
		request("ultimate")


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
	_sync_run_save()
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
		dir = Sim.reverse_dir(dir, Sim.reverse_axis_of(flags))   # Teilwende: one axis only (D-108)
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
	Save.clear_rejoin()
	last_unlocks = Save.apply_result(result, local_id())
	run_finished.emit(result)
	screen_requested.emit("end")


func _player_name() -> String:
	return str(Save.option("name", "Genoss:in"))
