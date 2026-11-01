extends Node
## Transport, handshake, lobby, UPnP, LAN discovery and every RPC
## (docs/specs/networking.md, docs/specs/architecture.md §8).
## All RPCs live on this autoload, so the node path (/root/Net) is the same on
## every peer. Solo uses OfflineMultiplayerPeer (peer 1, no socket).

const PORT := 24713                 # game port (UDP); LAN discovery uses PORT + 1
const LAN_PORT := PORT + 1
const PROTOCOL_VERSION := 1
const MAX_PLAYERS := 4
const DEFAULT_CHAR := "stadtbild"
const HANDSHAKE_TIMEOUT_S := 8.0
const REJECT_LINGER_S := 1.0        # host: time a rejected peer gets to read the reason
const LAN_INTERVAL_S := 1.0
const LAN_EXPIRE_S := 4.0
const LAN_MAGIC := "BRANDMAUER"
const AUTOSTART_DELAY_S := 3.0
const NAME_MAX_LEN := 20
const UPNP_DESC := "Brandmauer"

## ENet transfer channels. Separate channels so unreliable snapshots never
## block reliable traffic (ENet orders per channel).
const CHANNELS := 4
const CH_LOBBY := 0                 # handshake + lobby (reliable)
const CH_RUN := 1                   # run start, meta, events, requests (reliable)
const CH_SNAPSHOT := 2              # snapshots (unreliable_ordered)
const CH_INPUT := 3                 # inputs (unreliable_ordered)

enum Mode { NONE, SOLO, HOST, SERVER, CONNECTING, CLIENT }

signal lobby_changed                # lobby dict, org, difficulty or upnp_status changed
signal connected                    # client: handshake accepted
signal connection_failed(reason: String)
signal disconnected(reason: String) # we lost the server, or it kicked us
signal peer_left(peer: int)         # host: a client left
signal lan_games_changed            # discovered LAN games changed
signal run_start_received(config: Dictionary)
signal snapshot_received(bytes: PackedByteArray)
signal meta_received(meta: Dictionary)
signal events_received(events: Array)
signal input_received(peer: int, seq: int, dir: Vector2)
signal request_received(peer: int, action: String, arg)
signal returned_to_lobby

var lobby := {}        # peer_id -> {"name": String, "char": String, "ready": bool}
var org := "gewerkschaft"
var difficulty := 0
var dedicated := false
var lan_games := []    # [{"name", "ip", "port", "players"}]
var upnp_status := ""  # "" | "ok" | "failed: ..."
var lan_listening := false          # start_lan_discovery() bound its socket
var active_port := PORT             # port of the running host / server
var quiet := false                  # silence headless status output (tests)

var _mode := Mode.NONE
var _session := 0
var _local_name := ""
var _server_name := "Brandmauer"
var _handshake_deadline := 0.0
var _pending := {}                  # host: peer -> {"deadline": float, "rejected": bool}
var _closing: Array[MultiplayerPeer] = []
var _upnp: UPNP = null
var _upnp_port := 0
var _upnp_jobs: Array[Dictionary] = []
var _lan_tx: PacketPeerUDP = null
var _lan_tx_left := 0.0
var _lan_rx: PacketPeerUDP = null
var _lan_seen := {}                 # "ip:port" -> {"entry": Dictionary, "seen": float}
var _countdown := -1.0
var _shut_down := false
var _test_protocol := -1            # smoke test: pretend to be another protocol version
var _game_override: Node = null     # tests: stands in for /root/Game


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sm := multiplayer as SceneMultiplayer
	if sm != null:
		sm.server_relay = false     # clients only ever talk to the host
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if args.has("--server"):
		await get_tree().process_frame
		var opts := parse_server_args(args)
		org = opts["org"]
		difficulty = opts["umfrage"]
		_server_name = opts["name"]
		if start_dedicated(opts["port"]) != OK:
			get_tree().quit(1)


func _process(delta: float) -> void:
	_poll_upnp_jobs(false)
	_tick_handshake(_now())
	_tick_lan(delta)
	_tick_countdown(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_shutdown()


# --- Public API (architecture.md §8) ------------------------------------------

func start_solo(player_name: String) -> void:
	leave()
	_mode = Mode.SOLO
	_session += 1
	_local_name = _clean_name(player_name, 1)
	lobby = {1: _new_entry(_local_name)}
	lobby_changed.emit()


func host(player_name: String, port := PORT, use_upnp := true) -> Error:
	leave()
	var err := _create_server(port)
	if err != OK:
		return err
	_mode = Mode.HOST
	_local_name = _clean_name(player_name, 1)
	lobby = {1: _new_entry(_local_name)}
	_start_lan_broadcast()
	if use_upnp:
		_start_upnp(port)
	_log("Hosting on port %d" % port)
	lobby_changed.emit()
	return OK


func start_dedicated(port := PORT) -> Error:
	leave()
	var err := _create_server(port)
	if err != OK:
		_log("Cannot listen on UDP port %d (error %d)" % [port, err])
		return err
	_mode = Mode.SERVER
	dedicated = true
	lobby = {}
	_start_lan_broadcast()
	if not (OS.get_cmdline_user_args() + OS.get_cmdline_args()).has("--no-upnp"):
		_start_upnp(port)
	_log("Dedicated server '%s' listening on UDP port %d (protocol %d, version %s)"
			% [_server_name, port, PROTOCOL_VERSION, game_version()])
	_log_lobby()
	lobby_changed.emit()
	return OK


func join(ip: String, port: int, player_name: String) -> void:
	leave()
	_local_name = _clean_name(player_name, 0)
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), port, CHANNELS)
	if err != OK:
		_emit_failed_later.call_deferred(_session, "NET_ERR_CONNECT")
		return
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	_mode = Mode.CONNECTING
	_session += 1
	_handshake_deadline = _now() + HANDSHAKE_TIMEOUT_S


## Closes the peer, removes the UPnP mapping and clears the lobby. Safe to call
## from inside any Net signal handler.
func leave() -> void:
	_mode = Mode.NONE
	_session += 1
	_stop_lan_broadcast()
	_remove_upnp()
	_drop_peer()
	dedicated = false
	lobby = {}
	_pending.clear()
	_countdown = -1.0
	upnp_status = ""


func is_host() -> bool:
	return _mode == Mode.SOLO or _mode == Mode.HOST or _mode == Mode.SERVER


func set_char(char_id: String) -> void:
	match _mode:
		Mode.SOLO, Mode.HOST:
			_apply_char(1, char_id)
		Mode.CLIENT:
			_rpc_set_char.rpc_id(1, char_id)


func set_ready(is_ready: bool) -> void:
	match _mode:
		Mode.SOLO, Mode.HOST:
			_apply_ready(1, is_ready)
		Mode.CLIENT:
			_rpc_set_ready.rpc_id(1, is_ready)


func set_org(org_id: String) -> void:
	if not is_host() or not Content.ORG_ORDER.has(org_id) or org_id == org:
		return
	org = org_id
	_lobby_updated()


func set_difficulty(level: int) -> void:
	if not is_host():
		return
	level = clampi(level, 0, Content.DIFFICULTY_PERCENT.size() - 1)
	if level == difficulty:
		return
	difficulty = level
	_lobby_updated()


func start_lan_discovery() -> void:
	if _lan_rx != null:
		return
	var rx := PacketPeerUDP.new()
	var err := rx.bind(LAN_PORT, "*")
	if err != OK:
		lan_listening = false
		_log("LAN discovery unavailable, UDP port %d busy (error %d)" % [LAN_PORT, err])
		return
	_lan_rx = rx
	lan_listening = true


func stop_lan_discovery() -> void:
	if _lan_rx != null:
		_lan_rx.close()
		_lan_rx = null
	lan_listening = false
	_lan_seen.clear()
	if not lan_games.is_empty():
		lan_games = []
		lan_games_changed.emit()


## Host: sends the run config to every client and emits run_start_received locally.
func broadcast_run_start(config: Dictionary) -> void:
	if not is_host():
		return
	_countdown = -1.0
	for id in _client_ids():
		_rpc_run_start.rpc_id(id, config)
	run_start_received.emit(config)


func send_snapshot(bytes: PackedByteArray) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	for id in _client_ids():
		_rpc_snapshot.rpc_id(id, bytes)


func send_meta(meta: Dictionary) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	for id in _client_ids():
		_rpc_meta.rpc_id(id, meta)


func send_events(events: Array) -> void:
	if (_mode != Mode.HOST and _mode != Mode.SERVER) or events.is_empty():
		return
	for id in _client_ids():
		_rpc_events.rpc_id(id, events)


## Client -> host. On the host, Game applies its own input directly.
func send_input(seq: int, dir: Vector2) -> void:
	if _mode == Mode.CLIENT:
		_rpc_input.rpc_id(1, seq, dir)


## Client -> host. On the host, Game applies its own requests directly.
func send_request(action: String, arg) -> void:
	if _mode == Mode.CLIENT:
		_rpc_request.rpc_id(1, action, arg)


## Host: everyone back to the lobby, ready flags reset.
func return_to_lobby() -> void:
	if not is_host():
		return
	_countdown = -1.0
	for id in lobby:
		lobby[id]["ready"] = false
	for id in _client_ids():
		_rpc_returned.rpc_id(id)
	returned_to_lobby.emit()
	_lobby_updated()


# --- Helpers (public, also used by tests) -------------------------------------

static func game_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


## Parses --port=N, --org=<id>, --umfrage=<0-5>, --name=<text>; invalid values fall back.
static func parse_server_args(args: PackedStringArray) -> Dictionary:
	var opts := {"port": PORT, "org": "gewerkschaft", "umfrage": 0, "name": "Brandmauer"}
	for a in args:
		var v := a.get_slice("=", 1)
		if a.begins_with("--port=") and v.is_valid_int() and int(v) > 0 and int(v) < 65536:
			opts["port"] = int(v)
		elif a.begins_with("--org=") and Content.ORG_ORDER.has(v):
			opts["org"] = v
		elif a.begins_with("--umfrage=") and v.is_valid_int():
			opts["umfrage"] = clampi(int(v), 0, Content.DIFFICULTY_PERCENT.size() - 1)
		elif a.begins_with("--name=") and v.strip_edges() != "":
			opts["name"] = _clean_name(v, 0)
	return opts


## "" if a client may join, else a translation key.
func check_join(protocol, version) -> String:
	if typeof(protocol) != TYPE_INT or protocol != PROTOCOL_VERSION or str(version) != game_version():
		return "NET_ERR_VERSION"
	if _run_active():
		return "NET_ERR_RUNNING"
	if lobby.size() >= MAX_PLAYERS:
		return "NET_ERR_FULL"
	return ""


# --- Host side ---------------------------------------------------------------

func _create_server(port: int) -> Error:
	var peer := ENetMultiplayerPeer.new()
	# A little slack above MAX_PLAYERS so a client of a full lobby still gets a reason.
	var err := peer.create_server(port, MAX_PLAYERS + 2, CHANNELS)
	if err != OK:
		return err
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	active_port = port
	_session += 1
	return OK


func _on_peer_connected(id: int) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	_pending[id] = {"deadline": _now() + HANDSHAKE_TIMEOUT_S, "rejected": false}
	_set_peer_timeout(id)


func _on_peer_disconnected(id: int) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	_pending.erase(id)
	if not lobby.has(id):
		return
	_log("%s left" % lobby[id]["name"])
	lobby.erase(id)
	peer_left.emit(id)
	_lobby_updated()
	if _mode == Mode.SERVER and lobby.is_empty() and _run_active():
		var game := _game()
		if game != null and game.has_method("back_to_lobby"):
			_log("Everyone left, ending the run")
			game.call("back_to_lobby")


func _tick_handshake(now: float) -> void:
	if _mode == Mode.CONNECTING and now > _handshake_deadline:
		_fail_connect("NET_ERR_TIMEOUT")
		return
	if _pending.is_empty():
		return
	for id in _pending.keys():
		if now > float(_pending[id]["deadline"]):
			_pending.erase(id)
			var peer := multiplayer.multiplayer_peer
			if peer is ENetMultiplayerPeer and multiplayer.get_peers().has(id):
				peer.disconnect_peer(id)


func _apply_char(peer: int, char_id: String) -> void:
	if not lobby.has(peer) or not Content.CHAR_ORDER.has(char_id) or lobby[peer]["char"] == char_id:
		return
	lobby[peer]["char"] = char_id
	_lobby_updated()


func _apply_ready(peer: int, is_ready: bool) -> void:
	if not lobby.has(peer) or lobby[peer]["ready"] == is_ready:
		return
	lobby[peer]["ready"] = is_ready
	_lobby_updated()


## Host: push the lobby to all clients and notify locally.
func _lobby_updated() -> void:
	for id in _client_ids():
		_rpc_lobby.rpc_id(id, lobby, org, difficulty)
	_log_lobby()
	_update_autostart()
	lobby_changed.emit()


func _client_ids() -> Array[int]:
	var ids: Array[int] = []
	if _mode == Mode.HOST or _mode == Mode.SERVER:
		var peers := multiplayer.get_peers()
		for id in lobby:
			if id != 1 and peers.has(id):
				ids.append(id)
	return ids


func _new_entry(player_name: String) -> Dictionary:
	return {"name": player_name, "char": DEFAULT_CHAR, "ready": false}


static func _clean_name(raw, peer: int) -> String:
	var s := str(raw).replace("|", "/").replace("\n", " ").replace("\t", " ").strip_edges().left(NAME_MAX_LEN)
	if s == "" and peer != 0:
		s = "P%d" % (peer if peer < 100 else peer % 1000)
	return s


func _game() -> Node:
	if _game_override != null:
		return _game_override
	var tree := Engine.get_main_loop() as SceneTree
	return null if tree == null else tree.root.get_node_or_null("/root/Game")


func _run_active() -> bool:
	var game := _game()
	if game == null:
		return false
	var cfg = game.get("config")
	return cfg is Dictionary and not (cfg as Dictionary).is_empty()


func _all_ready() -> bool:
	if lobby.is_empty():
		return false
	for id in lobby:
		if not lobby[id]["ready"]:
			return false
	return true


# --- Dedicated auto-start ------------------------------------------------------

func _update_autostart() -> void:
	if _mode != Mode.SERVER:
		return
	var go := _all_ready() and not _run_active()
	if go and _countdown < 0.0:
		_countdown = AUTOSTART_DELAY_S
		_log("All players ready, run starts in %d s" % int(AUTOSTART_DELAY_S))
	elif not go and _countdown >= 0.0:
		_countdown = -1.0
		_log("Countdown cancelled")


func _tick_countdown(delta: float) -> void:
	if _countdown < 0.0:
		return
	_countdown -= delta
	if _countdown > 0.0:
		return
	_countdown = -1.0
	if _mode != Mode.SERVER or not _all_ready() or _run_active():
		return
	var game := _game()
	if game != null and game.has_method("start_run"):
		_log("Starting run with %d player(s)" % lobby.size())
		game.call("start_run")
	else:
		_log("No Game node, cannot start the run")


# --- Client side ---------------------------------------------------------------

func _on_connected_to_server() -> void:
	if _mode != Mode.CONNECTING:
		return
	_set_peer_timeout(1)
	var protocol := PROTOCOL_VERSION if _test_protocol < 0 else _test_protocol
	_rpc_00_hello.rpc_id(1, protocol, game_version(), _local_name)


func _on_connection_failed() -> void:
	if _mode == Mode.CONNECTING:
		_fail_connect("NET_ERR_CONNECT")


func _on_server_disconnected() -> void:
	if _mode == Mode.CLIENT:
		leave()
		disconnected.emit("NET_ERR_LOST")
	elif _mode == Mode.CONNECTING:
		_fail_connect("NET_ERR_CONNECT")


func _fail_connect(reason: String) -> void:
	leave()
	connection_failed.emit(reason)


func _emit_failed_later(session: int, reason: String) -> void:
	if session == _session:
		connection_failed.emit(reason)


func _set_peer_timeout(id: int) -> void:
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer == null:
		return
	var pp := peer.get_peer(id)
	if pp != null:
		pp.set_timeout(32, 3000, 10000)   # notice a dead connection within ~10 s


## Detaches the current peer at once and closes it on the next idle frame, so it
## is never closed or freed while it is dispatching the signal/RPC that got us here.
func _drop_peer() -> void:
	var old := multiplayer.multiplayer_peer
	if old is OfflineMultiplayerPeer:
		return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	if old != null:
		_closing.append(old)
		_finish_close.call_deferred()


func _finish_close() -> void:
	for p in _closing:
		p.close()
	_closing.clear()


# --- RPCs ----------------------------------------------------------------------
# The handshake RPCs sort first by name so their RPC ids stay stable across game
# versions (Godot numbers RPCs by sorted method name). Never rename them, change
# their arguments, or add RPCs whose names sort before them.

@rpc("any_peer", "call_remote", "reliable", CH_LOBBY)
func _rpc_00_hello(protocol, version, player_name) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	var id := multiplayer.get_remote_sender_id()
	if lobby.has(id) or not _pending.has(id) or _pending[id]["rejected"]:
		return
	var reason := check_join(protocol, version)
	if reason != "":
		_pending[id] = {"deadline": _now() + REJECT_LINGER_S, "rejected": true}
		_rpc_01_reject.rpc_id(id, reason)
		_log("Rejected peer %d: %s (mode %s, phase %s)" % [id, reason, _game_mode_str(), _game_phase_str()])
		return
	_pending.erase(id)
	lobby[id] = _new_entry(_clean_name(player_name, id))
	_log("%s joined (peer %d)" % [lobby[id]["name"], id])
	_rpc_02_welcome.rpc_id(id)
	_lobby_updated()


@rpc("authority", "call_remote", "reliable", CH_LOBBY)
func _rpc_01_reject(reason) -> void:
	if _mode == Mode.CONNECTING:
		_fail_connect(str(reason))


@rpc("authority", "call_remote", "reliable", CH_LOBBY)
func _rpc_02_welcome() -> void:
	if _mode != Mode.CONNECTING:
		return
	_mode = Mode.CLIENT
	connected.emit()


@rpc("authority", "call_remote", "reliable", CH_LOBBY)
func _rpc_lobby(new_lobby: Dictionary, new_org: String, new_difficulty: int) -> void:
	if _mode != Mode.CLIENT:
		return
	lobby = new_lobby
	org = new_org
	difficulty = new_difficulty
	lobby_changed.emit()


@rpc("any_peer", "call_remote", "reliable", CH_LOBBY)
func _rpc_set_char(char_id: String) -> void:
	if _mode == Mode.HOST or _mode == Mode.SERVER:
		_apply_char(multiplayer.get_remote_sender_id(), char_id)


@rpc("any_peer", "call_remote", "reliable", CH_LOBBY)
func _rpc_set_ready(is_ready: bool) -> void:
	if _mode == Mode.HOST or _mode == Mode.SERVER:
		_apply_ready(multiplayer.get_remote_sender_id(), is_ready)


@rpc("authority", "call_remote", "reliable", CH_RUN)
func _rpc_run_start(config: Dictionary) -> void:
	if _mode == Mode.CLIENT:
		run_start_received.emit(config)


@rpc("authority", "call_remote", "reliable", CH_RUN)
func _rpc_meta(meta: Dictionary) -> void:
	if _mode == Mode.CLIENT:
		meta_received.emit(meta)


@rpc("authority", "call_remote", "reliable", CH_RUN)
func _rpc_events(events: Array) -> void:
	if _mode == Mode.CLIENT:
		events_received.emit(events)


@rpc("authority", "call_remote", "reliable", CH_RUN)
func _rpc_returned() -> void:
	if _mode == Mode.CLIENT:
		returned_to_lobby.emit()


@rpc("authority", "call_remote", "unreliable_ordered", CH_SNAPSHOT)
func _rpc_snapshot(bytes: PackedByteArray) -> void:
	if _mode == Mode.CLIENT:
		snapshot_received.emit(bytes)


@rpc("any_peer", "call_remote", "unreliable_ordered", CH_INPUT)
func _rpc_input(seq: int, dir: Vector2) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	var id := multiplayer.get_remote_sender_id()
	if lobby.has(id) and dir.is_finite():
		input_received.emit(id, seq, dir.limit_length(1.0))


@rpc("any_peer", "call_remote", "reliable", CH_RUN)
func _rpc_request(action: String, arg) -> void:
	if _mode != Mode.HOST and _mode != Mode.SERVER:
		return
	var id := multiplayer.get_remote_sender_id()
	if lobby.has(id):
		request_received.emit(id, action, arg)


# --- LAN discovery -------------------------------------------------------------

func _start_lan_broadcast() -> void:
	var tx := PacketPeerUDP.new()
	tx.set_broadcast_enabled(true)
	if tx.set_dest_address("255.255.255.255", LAN_PORT) != OK:
		_log("LAN announce unavailable")
		return
	_lan_tx = tx
	_lan_tx_left = 0.0


func _stop_lan_broadcast() -> void:
	if _lan_tx != null:
		_lan_tx.close()
		_lan_tx = null


func lan_announcement() -> String:
	var shown := _server_name if _mode == Mode.SERVER else _local_name
	return "%s|%d|%s|%d|%d" % [LAN_MAGIC, PROTOCOL_VERSION, shown, active_port, lobby.size()]


func _tick_lan(delta: float) -> void:
	if _lan_tx != null:
		_lan_tx_left -= delta
		if _lan_tx_left <= 0.0:
			_lan_tx_left = LAN_INTERVAL_S
			_lan_tx.put_packet(lan_announcement().to_utf8_buffer())
	if _lan_rx != null:
		var now := _now()
		while _lan_rx.get_available_packet_count() > 0:
			var pkt := _lan_rx.get_packet()
			handle_lan_packet(pkt.get_string_from_utf8(), _lan_rx.get_packet_ip(), now)
		expire_lan_games(now)


## Parses one announcement; updates lan_games (dedup by ip:port).
func handle_lan_packet(text: String, ip: String, now: float) -> void:
	var parts := text.split("|")
	if parts.size() != 5 or parts[0] != LAN_MAGIC or ip == "":
		return
	if not parts[1].is_valid_int() or int(parts[1]) != PROTOCOL_VERSION:
		return
	if not parts[3].is_valid_int() or not parts[4].is_valid_int():
		return
	var port := int(parts[3])
	if port <= 0 or port > 65535:
		return
	var entry := {"name": parts[2].left(NAME_MAX_LEN), "ip": ip, "port": port, "players": int(parts[4])}
	var key := "%s:%d" % [ip, port]
	var changed: bool = not _lan_seen.has(key) or _lan_seen[key]["entry"] != entry
	_lan_seen[key] = {"entry": entry, "seen": now}
	if changed:
		_rebuild_lan_games()


func expire_lan_games(now: float) -> void:
	var removed := false
	for key in _lan_seen.keys():
		if now - float(_lan_seen[key]["seen"]) > LAN_EXPIRE_S:
			_lan_seen.erase(key)
			removed = true
	if removed:
		_rebuild_lan_games()


func _rebuild_lan_games() -> void:
	var keys := _lan_seen.keys()
	keys.sort()
	lan_games = []
	for key in keys:
		lan_games.append(_lan_seen[key]["entry"])
	lan_games_changed.emit()


# --- UPnP (threaded) -----------------------------------------------------------

func _start_upnp(port: int) -> void:
	upnp_status = ""
	var t := Thread.new()
	if t.start(_upnp_worker.bind(port)) != OK:
		upnp_status = "failed: thread"
		return
	_upnp_jobs.append({"thread": t, "session": _session, "port": port})


## Runs on a worker thread. Returns [UPNP or null, status].
func _upnp_worker(port: int) -> Array:
	var upnp := UPNP.new()
	var err := upnp.discover(2000, 2, "InternetGatewayDevice")
	if err != UPNP.UPNP_RESULT_SUCCESS:
		return [null, "failed: discover (%d)" % err]
	var gw := upnp.get_gateway()
	if gw == null or not gw.is_valid_gateway():
		return [null, "failed: no gateway"]
	err = upnp.add_port_mapping(port, port, UPNP_DESC, "UDP")
	if err != UPNP.UPNP_RESULT_SUCCESS:
		return [null, "failed: mapping (%d)" % err]
	return [upnp, "ok"]


## Collects finished UPnP jobs. wait=true blocks for all (shutdown) and removes every mapping.
func _poll_upnp_jobs(wait: bool) -> void:
	if _upnp_jobs.is_empty():
		return
	for job in _upnp_jobs.duplicate():
		var t: Thread = job["thread"]
		if not wait and t.is_alive():
			continue
		var res: Array = t.wait_to_finish()
		_upnp_jobs.erase(job)
		var u: UPNP = res[0]
		var port: int = job["port"]
		if not wait and job["session"] == _session and (_mode == Mode.HOST or _mode == Mode.SERVER):
			_upnp = u
			_upnp_port = port
			upnp_status = res[1]
			_log("UPnP: %s" % upnp_status)
			lobby_changed.emit()
		elif u != null and not (_upnp != null and _upnp_port == port):
			u.delete_port_mapping(port, "UDP")


func _remove_upnp() -> void:
	if _upnp != null:
		_upnp.delete_port_mapping(_upnp_port, "UDP")
		_upnp = null


func _shutdown() -> void:
	if _shut_down:
		return
	_shut_down = true
	leave()
	_finish_close()
	_poll_upnp_jobs(true)
	stop_lan_discovery()


# --- Misc ------------------------------------------------------------------------

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _log(msg: String) -> void:
	if not quiet and DisplayServer.get_name() == "headless":
		print("[Net] ", msg)


func _log_lobby() -> void:
	if not dedicated or quiet:
		return
	var names := PackedStringArray()
	for id in lobby:
		var e: Dictionary = lobby[id]
		names.append("%s (%s%s)" % [e["name"], e["char"], ", ready" if e["ready"] else ""])
	_log("Lobby %d/%d | org %s | Umfrage %d | %s"
			% [lobby.size(), MAX_PLAYERS, org, difficulty, ", ".join(names) if names.size() > 0 else "-"])


func _game_mode_str() -> String:
	var game := _game()
	return "-" if game == null else str(game.get("mode"))


func _game_phase_str() -> String:
	var game := _game()
	if game == null:
		return "-"
	var meta = game.get("meta")
	return str(meta.get("phase", -1)) if meta is Dictionary else "-1"
