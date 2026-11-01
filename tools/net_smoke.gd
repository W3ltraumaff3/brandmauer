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

const SMOKE_PORT := 24813
const TIMEOUT_S := 15.0
const SNAPSHOTS := 20

var net: Node
var role := ""
var elapsed := 0.0
var done := false

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
	match role:
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
			_finish(1, "usage: -- host | join | join-badversion")


func _process(delta: float) -> bool:
	if done:
		return true
	elapsed += delta
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


func _finish(code: int, msg: String) -> void:
	if done:
		return
	done = true
	print("[smoke %s] %s -> exit %d" % [role, msg, code])
	net.leave()
	quit(code)
