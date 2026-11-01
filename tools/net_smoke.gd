extends SceneTree
## Headless two-process network smoke test (run via tools/net_smoke.sh):
##   godot --headless --path . -s res://tools/net_smoke.gd -- host
##   godot --headless --path . -s res://tools/net_smoke.gd -- join
##   godot --headless --path . -s res://tools/net_smoke.gd -- join-badversion
## host: listens on SMOKE_PORT (no UPnP), waits for a client, then sends 20
##   snapshots and one meta dict over 2 s; exits 0 once the client has left.
## join: exits 0 only if the handshake succeeded and it received >= 5 valid
##   snapshots plus the meta dict, else 1 (at the latest after 15 s).
## join-badversion: claims another protocol; exits 0 only if rejected with NET_ERR_VERSION.
##
## Reconnect scenario (networking.md §7.4), real Game + Sim on RUN_PORT:
##   godot --headless --path . -s res://tools/net_smoke.gd -- host-run
##   godot --headless --path . -s res://tools/net_smoke.gd -- join-reconnect
## host-run: hosts, starts a real run once the client joined, and exits 0 only if
##   the client went away (sim state 3, player kept), came back with its token on a
##   new peer id (peer_back, same player id, state alive/downed again) and then left.
## join-reconnect: joins, waits for >= 10 run snapshots, drops its connection
##   without telling the host, reconnects with its token and exits 0 only if its
##   player id stayed the same on a new peer id and it got >= 5 snapshots (with its
##   player not away) plus meta after the reconnect.

const SMOKE_PORT := 24813
const RUN_PORT := 24815
const TIMEOUT_S := 15.0
const RUN_TIMEOUT_S := 60.0
const SNAPSHOTS := 20

var net: Node
var game: Node
var role := ""
var elapsed := 0.0
var done := false

# host-run
var run_pid := 0
var run_started := false
var away_seen := false
var back_seen := false
var back_at := -1.0
var back_checked := false
var back_ok := false
var host_errors: Array[String] = []

# join-reconnect
var first_pid := 0
var run_snapshots := 0
var dropped := false
var drop_at := -1.0
var reconnected_ok := false
var after_snapshots := 0
var after_meta_ok := false
var join_errors: Array[String] = []

# host
var client_id := 0
var sent := 0
var send_left := 0.0
var meta_sent := false
var finished_sending_at := -1.0

# join
var handshake_ok := false
var snapshots := 0
var got_meta := false
var fail_reason := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[0] if args.size() > 0 else ""
	call_deferred("_start")


func _start() -> void:
	# Godot 4.7 registers autoloads for -s scripts; older versions did not. Either
	# way Net must live at /root/Net, the RPC path shared by both processes.
	net = root.get_node_or_null("Net")
	if net == null:
		net = load("res://src/autoload/net.gd").new()
		net.name = "Net"
		root.add_child(net)
	game = root.get_node_or_null("Game")
	match role:
		"host-run", "join-reconnect":
			if game == null:
				_finish(1, "the reconnect scenario needs the Game autoload")
				return
			if role == "host-run":
				_start_host_run()
			else:
				_start_join_reconnect()
		"host":
			var err: Error = net.host("SmokeHost", SMOKE_PORT, false)
			if err != OK:
				_finish(1, "host() failed: %d" % err)
				return
			net.lobby_changed.connect(_on_host_lobby_changed)
			net.peer_left.connect(_on_host_peer_left)
			print("[smoke host] listening on %d" % SMOKE_PORT)
		"join", "join-badversion":
			if role == "join-badversion":
				net._test_protocol = 999
			net.connected.connect(_on_connected)
			net.connection_failed.connect(_on_join_failed)
			net.disconnected.connect(_on_disconnected)
			net.snapshot_received.connect(_on_snapshot)
			net.meta_received.connect(_on_meta)
			net.join("127.0.0.1", SMOKE_PORT, "SmokeClient")
		_:
			_finish(1, "usage: -- host | join | join-badversion | host-run | join-reconnect")


func _process(delta: float) -> bool:
	if done:
		return false   # _finish quits once the goodbye went out
	elapsed += delta
	if role == "host-run" or role == "join-reconnect":
		if elapsed > RUN_TIMEOUT_S:
			_finish(1, "timeout (role %s, host errors %s, join errors %s, away %s, back %s, run snapshots %d, after %d, meta %s)"
					% [role, host_errors, join_errors, away_seen, back_seen, run_snapshots, after_snapshots, after_meta_ok])
		elif role == "host-run":
			_host_run_tick()
		else:
			_join_reconnect_tick()
		return false
	if elapsed > TIMEOUT_S:
		_finish(1, "timeout (role %s, sent %d, received %d, handshake %s, meta %s, reason '%s')"
				% [role, sent, snapshots, handshake_ok, got_meta, fail_reason])
		return false
	if role == "host":
		_host_tick(delta)
	elif role == "join" and handshake_ok and snapshots >= 5 and got_meta:
		_finish(0, "received %d snapshots and meta" % snapshots)
	return false


func _on_host_lobby_changed() -> void:
	if client_id != 0:
		return
	for id in net.lobby:
		if id != 1:
			client_id = id
			print("[smoke host] client %d joined as %s" % [id, net.lobby[id]["name"]])


func _host_tick(delta: float) -> void:
	if client_id == 0:
		return
	if sent < SNAPSHOTS:
		send_left -= delta
		if send_left <= 0.0:
			send_left = 0.1
			net.send_snapshot(Snapshot.encode(_fake_view(sent)))
			sent += 1
			if sent == SNAPSHOTS / 2 and not meta_sent:
				meta_sent = true
				net.send_meta({"wave": 7, "phase": 0, "players": {1: {"name": "SmokeHost"}}})
		if sent == SNAPSHOTS:
			finished_sending_at = elapsed
			print("[smoke host] sent %d snapshots and meta" % sent)
	elif elapsed - finished_sending_at > 4.0:
		_finish(0, "done (client did not disconnect)")


func _fake_view(i: int) -> ViewState:
	var vs := ViewState.new()
	vs.time = i * 0.1
	vs.wave = 7
	vs.wave_time_left = 30.0 - vs.time
	vs.players.append({"id": 1, "char": 0, "pos": Vector2(800 + i, 500), "hp": 15.0, "max_hp": 15.0,
			"state": 0, "aim": 0.5, "flags": 0, "followers": 0, "weapons": PackedByteArray([0, 1]), "seq": i})
	for e in 150:
		vs.e_id.append(e + 1)
		vs.e_type.append(e % Content.ENEMY_ORDER.size())
		vs.e_pos.append(Vector2(e * 10 % 1600, e * 7 % 1000 + i))
		vs.e_hp.append(1.0)
		vs.e_flags.append(0)
	return vs


func _on_host_peer_left(_peer: int) -> void:
	if sent >= SNAPSHOTS:
		_finish(0, "client left, done")


func _on_connected() -> void:
	handshake_ok = true
	print("[smoke join] handshake ok")


func _on_disconnected(reason: String) -> void:
	fail_reason = reason


func _on_meta(meta: Dictionary) -> void:
	got_meta = meta.get("wave", 0) == 7


func _on_snapshot(bytes: PackedByteArray) -> void:
	var vs := Snapshot.decode(bytes)
	if vs != null and vs.e_id.size() == 150 and vs.wave == 7:
		snapshots += 1


func _on_join_failed(reason: String) -> void:
	if role == "join-badversion":
		_finish(0 if reason == "NET_ERR_VERSION" else 1, "rejected with %s" % reason)
	else:
		_finish(1, "connection failed: %s" % reason)


# --- Reconnect scenario: host ---------------------------------------------------------

func _start_host_run() -> void:
	var err: Error = net.host("SmokeHost", RUN_PORT, false)
	if err != OK:
		_finish(1, "host() failed: %d" % err)
		return
	game.mode = game.Mode.HOST
	net.lobby_changed.connect(_on_run_lobby_changed)
	net.peer_away.connect(_on_run_peer_away)
	net.peer_back.connect(_on_run_peer_back)
	net.peer_left.connect(_on_run_peer_left)
	print("[smoke host-run] listening on %d" % RUN_PORT)


func _on_run_lobby_changed() -> void:
	if run_pid != 0:
		return
	for id in net.lobby:
		if id != 1:
			run_pid = id
	if run_pid != 0 and not run_started:
		run_started = true
		print("[smoke host-run] player %d joined, starting the run" % run_pid)
		game.call_deferred("start_run")


func _host_run_tick() -> void:
	# Keep everyone alive, the scenario is about the connection, not the fight.
	if game.sim != null:
		for p in game.sim.players.values():
			p.iframes = 10.0


func _on_run_peer_away(pid: int) -> void:
	away_seen = true
	if pid != run_pid:
		host_errors.append("away: unexpected player %d" % pid)
	var p = game.sim.players.get(pid) if game.sim != null else null
	if p == null or p.state != 3:
		host_errors.append("away: player not in sim state 3")
	if not net.lobby.has(pid):
		host_errors.append("away: player removed from the lobby")
	print("[smoke host-run] player %d away, kept in the run" % pid)


func _on_run_peer_back(pid: int) -> void:
	back_seen = true
	if not away_seen:
		host_errors.append("back without away")
	if pid != run_pid:
		host_errors.append("back: unexpected player %d" % pid)
	var p = game.sim.players.get(pid) if game.sim != null else null
	if p == null or (p.state != 0 and p.state != 1):
		host_errors.append("back: sim state %s" % (str(p.state) if p != null else "missing"))
	var peer: int = net.peer_for_player(pid)
	if peer == 0 or peer == pid:
		host_errors.append("back: peer mapping not updated (%d)" % peer)
	if net.player_for_peer(peer) != pid:
		host_errors.append("back: new peer doesn't map to the player")
	print("[smoke host-run] player %d back on peer %d" % [pid, peer])


func _on_run_peer_left(pid: int) -> void:
	if pid != run_pid:
		return
	var ok := away_seen and back_seen and host_errors.is_empty()
	_finish(0 if ok else 1, "client left (away %s, back %s, errors %s)" % [away_seen, back_seen, host_errors])


# --- Reconnect scenario: client --------------------------------------------------------

func _start_join_reconnect() -> void:
	net.connected.connect(_on_rc_connected)
	net.reconnected.connect(_on_rc_reconnected)
	net.connection_lost.connect(func(): print("[smoke join-reconnect] connection lost, reconnecting"))
	net.disconnected.connect(func(reason): _finish(1, "disconnected for good: %s" % reason))
	net.connection_failed.connect(func(reason): _finish(1, "connection failed: %s" % reason))
	net.snapshot_received.connect(_on_rc_snapshot)
	net.meta_received.connect(_on_rc_meta)
	game.open_join("127.0.0.1", RUN_PORT, "SmokeClient")


func _on_rc_connected() -> void:
	first_pid = net.local_player_id()
	if first_pid != net.multiplayer.get_unique_id():
		join_errors.append("first join: player id %d != peer id" % first_pid)
	print("[smoke join-reconnect] joined as player %d" % first_pid)


func _on_rc_snapshot(bytes: PackedByteArray) -> void:
	var vs := Snapshot.decode(bytes)
	if vs == null or first_pid == 0:
		return
	var me := vs.find_player(first_pid)
	if not reconnected_ok:
		if not me.is_empty():
			run_snapshots += 1
	elif me.is_empty():
		join_errors.append("own player missing after the reconnect")
	elif int(me["state"]) == 2 or int(me["state"]) == 3:
		join_errors.append("own player in state %d after the reconnect" % int(me["state"]))
	else:
		after_snapshots += 1


func _on_rc_meta(meta: Dictionary) -> void:
	if not reconnected_ok:
		return
	var ps = meta.get("players", {})
	var pm = ps.get(first_pid, {}) if ps is Dictionary else {}
	if pm is Dictionary and not pm.is_empty() and not bool(pm.get("away", true)):
		after_meta_ok = true


func _join_reconnect_tick() -> void:
	if not dropped and run_snapshots >= 10:
		dropped = true
		drop_at = elapsed
		print("[smoke join-reconnect] %d run snapshots, dropping the connection" % run_snapshots)
		net.debug_drop_connection()
		if not net.is_reconnecting():
			_finish(1, "not reconnecting after the drop")
			return
		# A real outage takes a while: let the host notice before the first retry.
		net._retry_at = net._now() + 1.0
	if dropped and not reconnected_ok:
		if not game.is_running():
			join_errors.append("run state lost while reconnecting")
		elif game.view == null or game.view.find_player(first_pid).is_empty():
			join_errors.append("no last state to render while reconnecting")
		if not join_errors.is_empty():
			_finish(1, "errors while reconnecting: %s" % join_errors)
			return
	if reconnected_ok and after_snapshots >= 5 and after_meta_ok:
		_finish(0 if join_errors.is_empty() else 1, "reconnected after %.1f s, %d snapshots + meta afterwards, errors %s"
				% [elapsed - drop_at, after_snapshots, join_errors])


func _on_rc_reconnected() -> void:
	var peer: int = net.multiplayer.get_unique_id()
	if peer == first_pid:
		join_errors.append("reconnect reused the old peer id")
	if net.local_player_id() != first_pid or game.local_id() != first_pid:
		join_errors.append("player id changed: net %d, game %d, expected %d" % [net.local_player_id(), game.local_id(), first_pid])
	if not game.is_running():
		join_errors.append("run lost on reconnect")
	reconnected_ok = true
	print("[smoke join-reconnect] reconnected after %.1f s as player %d on peer %d" % [elapsed - drop_at, first_pid, peer])


func _finish(code: int, msg: String) -> void:
	if done:
		return
	done = true
	print("[smoke %s] %s -> exit %d" % [role, msg, code])
	net.leave()
	# Net keeps the peer open briefly after a goodbye (bye / host_closed); let it go out.
	await create_timer(0.5).timeout
	quit(code)
