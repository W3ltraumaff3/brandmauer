extends TestCase
## Net logic that needs no sockets: solo lobby, validation, handshake checks,
## LAN parsing, dedicated auto-start (src/autoload/net.gd).

const NetScript := preload("res://src/autoload/net.gd")
const FAKE_GAME_SRC := """extends Node
var mode := 0
var meta := {}
var config := {}
var started := 0
var back := 0
func start_run() -> void:
	started += 1
func back_to_lobby() -> void:
	back += 1
"""

var net: Node
var fake_game: Node
var _signals := {}


func before_each() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	net = NetScript.new()
	net.name = "NetUnderTest"
	net.quiet = true
	root.add_child(net)
	var s := GDScript.new()
	s.source_code = FAKE_GAME_SRC
	s.reload()
	fake_game = Node.new()
	fake_game.set_script(s)
	net._game_override = fake_game
	_signals = {}
	for sig in ["lobby_changed", "returned_to_lobby", "run_start_received", "lan_games_changed"]:
		_signals[sig] = 0
		net.connect(sig, _count.bind(sig))


func after_each() -> void:
	net.leave()
	net.get_parent().remove_child(net)
	net.free()
	fake_game.free()


func _count(a = null, b = null) -> void:
	# Signals carry 0 or 1 args; the bound name is the last argument.
	var sig: String = b if b != null else a
	_signals[sig] += 1


func test_solo_lobby() -> void:
	net.start_solo("  Alice | B  ")
	assert_true(net.is_host(), "solo is host")
	assert_true(net.multiplayer.is_server(), "offline peer acts as server")
	assert_eq(net.multiplayer.get_unique_id(), 1, "solo peer id")
	assert_eq(net.lobby.keys(), [1], "only peer 1")
	assert_eq(net.lobby[1]["name"], "Alice / B", "name sanitized")
	assert_eq(net.lobby[1]["char"], "stadtbild", "default char")
	assert_false(net.lobby[1]["ready"], "not ready")
	assert_eq(_signals["lobby_changed"], 1, "lobby_changed emitted")


func test_set_char_validates() -> void:
	net.start_solo("A")
	net.set_char("oma")
	assert_eq(net.lobby[1]["char"], "oma", "valid char")
	net.set_char("does_not_exist")
	assert_eq(net.lobby[1]["char"], "oma", "invalid char ignored")


func test_ready_org_difficulty() -> void:
	net.start_solo("A")
	net.set_ready(true)
	assert_true(net.lobby[1]["ready"], "ready")
	net.set_org("omas")
	assert_eq(net.org, "omas", "valid org")
	net.set_org("nope")
	assert_eq(net.org, "omas", "invalid org ignored")
	net.set_difficulty(99)
	assert_eq(net.difficulty, 5, "difficulty clamped")
	net.set_difficulty(-3)
	assert_eq(net.difficulty, 0, "difficulty clamped low")


func test_not_host_after_leave() -> void:
	net.start_solo("A")
	net.leave()
	assert_false(net.is_host(), "no mode after leave")
	assert_true(net.lobby.is_empty(), "lobby cleared")
	net.set_org("antifa")
	assert_eq(net.org, "gewerkschaft", "set_org ignored when not host")


func test_check_join() -> void:
	net.start_solo("A")
	var v: String = NetScript.game_version()
	assert_eq(net.check_join(NetScript.PROTOCOL_VERSION, v), "", "accepted")
	assert_eq(net.check_join(NetScript.PROTOCOL_VERSION + 1, v), "NET_ERR_VERSION", "protocol")
	assert_eq(net.check_join(NetScript.PROTOCOL_VERSION, v + "x"), "NET_ERR_VERSION", "game version")
	assert_eq(net.check_join("1", v), "NET_ERR_VERSION", "wrong type")
	for i in 3:
		net.lobby[100 + i] = {"name": "x", "char": "stadtbild", "ready": false}
	assert_eq(net.check_join(NetScript.PROTOCOL_VERSION, v), "NET_ERR_FULL", "full")
	net.lobby.erase(100)
	fake_game.config = {"seed": 1}
	assert_eq(net.check_join(NetScript.PROTOCOL_VERSION, v), "NET_ERR_RUNNING", "run active")


func test_run_traffic_local() -> void:
	net.start_solo("A")
	var got := []
	net.run_start_received.connect(func(c): got.append(c))
	net.broadcast_run_start({"seed": 42})
	assert_eq(got.size(), 1, "run_start_received emitted locally")
	assert_eq(got[0]["seed"], 42, "config passed")
	# Solo: these must be silent no-ops.
	net.send_snapshot(PackedByteArray([1, 2, 3]))
	net.send_meta({"wave": 1})
	net.send_events([["sfx", "hit", Vector2.ZERO]])
	net.send_input(1, Vector2.RIGHT)
	net.send_request("buy", 0)


func test_return_to_lobby_resets_ready() -> void:
	net.start_solo("A")
	net.set_ready(true)
	net.return_to_lobby()
	assert_false(net.lobby[1]["ready"], "ready reset")
	assert_eq(_signals["returned_to_lobby"], 1, "returned_to_lobby emitted")


func test_lan_packets() -> void:
	net.handle_lan_packet("BRANDMAUER|%d|Bob|24713|2" % NetScript.PROTOCOL_VERSION, "192.168.1.5", 10.0)
	net.handle_lan_packet("BRANDMAUER|%d|Bob|24713|3" % NetScript.PROTOCOL_VERSION, "192.168.1.5", 10.5)
	net.handle_lan_packet("BRANDMAUER|%d|Eve|24800|1" % NetScript.PROTOCOL_VERSION, "192.168.1.5", 10.5)
	net.handle_lan_packet("BRANDMAUER|999|Old|24713|1", "192.168.1.6", 10.5)
	net.handle_lan_packet("garbage", "192.168.1.7", 10.5)
	net.handle_lan_packet("BRANDMAUER|%d|X|notaport|1" % NetScript.PROTOCOL_VERSION, "192.168.1.8", 10.5)
	assert_eq(net.lan_games.size(), 2, "dedup by ip:port, bad packets ignored")
	var bob: Dictionary = net.lan_games[0]
	assert_eq(bob["name"], "Bob", "name")
	assert_eq(bob["players"], 3, "updated player count")
	assert_eq(bob["port"], 24713, "port")
	assert_eq(_signals["lan_games_changed"], 3, "changed emitted on add/update only")
	net.handle_lan_packet("BRANDMAUER|%d|Eve|24800|1" % NetScript.PROTOCOL_VERSION, "192.168.1.5", 13.0)
	net.expire_lan_games(14.6)
	assert_eq(net.lan_games.size(), 1, "Bob expired after 4 s")
	assert_eq(net.lan_games[0]["name"], "Eve", "Eve still there")


func test_lan_announcement_format() -> void:
	net.start_solo("Carla")
	var parts: PackedStringArray = net.lan_announcement().split("|")
	assert_eq(parts.size(), 5, "5 fields")
	assert_eq(parts[0], "BRANDMAUER", "magic")
	assert_eq(int(parts[1]), NetScript.PROTOCOL_VERSION, "protocol")
	assert_eq(parts[2], "Carla", "name")
	assert_eq(int(parts[4]), 1, "players")


func test_parse_server_args() -> void:
	var o: Dictionary = NetScript.parse_server_args(PackedStringArray(["--server", "--port=30000", "--org=antifa",
			"--umfrage=9", "--name=Keller|Server"]))
	assert_eq(o["port"], 30000, "port")
	assert_eq(o["org"], "antifa", "org")
	assert_eq(o["umfrage"], 5, "umfrage clamped")
	assert_eq(o["name"], "Keller/Server", "name sanitized")
	o = NetScript.parse_server_args(PackedStringArray(["--port=abc", "--org=nope", "--umfrage=x"]))
	assert_eq(o["port"], NetScript.PORT, "default port")
	assert_eq(o["org"], "gewerkschaft", "default org")
	assert_eq(o["umfrage"], 0, "default umfrage")


func test_dedicated_autostart() -> void:
	net._mode = NetScript.Mode.SERVER
	net.dedicated = true
	net.lobby = {
		200: {"name": "A", "char": "stadtbild", "ready": false},
		201: {"name": "B", "char": "oma", "ready": false},
	}
	net._apply_ready(200, true)
	assert_true(net._countdown < 0.0, "not everyone ready")
	net._apply_ready(201, true)
	assert_near(net._countdown, 3.0, 0.001, "countdown armed")
	net._tick_countdown(1.5)
	net._apply_ready(201, false)
	assert_true(net._countdown < 0.0, "un-ready cancels")
	net._apply_ready(201, true)
	net._tick_countdown(1.5)
	net.lobby[202] = {"name": "C", "char": "stadtbild", "ready": false}   # someone joins
	net._lobby_updated()
	assert_true(net._countdown < 0.0, "join cancels")
	net.lobby.erase(202)
	net._lobby_updated()
	for i in 3:
		net._tick_countdown(1.0)
	assert_eq(fake_game.started, 1, "Game.start_run called after 3 s")
	fake_game.config = {"seed": 1}
	net._lobby_updated()
	assert_true(net._countdown < 0.0, "no countdown while a run is active")
	net.return_to_lobby()
	assert_false(net.lobby[200]["ready"], "ready reset after the run")


func test_dedicated_empty_lobby_ends_run() -> void:
	net._mode = NetScript.Mode.SERVER
	net.dedicated = true
	net.lobby = {300: {"name": "A", "char": "stadtbild", "ready": true}}
	fake_game.config = {"seed": 1}
	var left := []
	var away := []
	net.peer_left.connect(func(p): left.append(p))
	net.peer_away.connect(func(p): away.append(p))
	net._on_peer_disconnected(300)
	assert_eq(away, [300], "mid-run: peer_away, not removed")
	assert_true(net.lobby.has(300), "kept during the grace period")
	assert_eq(fake_game.back, 0, "run keeps waiting")
	net._tick_away(NetScript._now() + NetScript.GRACE_S + 1.0)
	assert_eq(left, [300], "peer_left after the grace period")
	assert_true(net.lobby.is_empty(), "removed from lobby")
	assert_eq(fake_game.back, 1, "Game.back_to_lobby called when the server is empty")


func test_disconnect_in_lobby_removes_at_once() -> void:
	net._mode = NetScript.Mode.SERVER
	net.lobby = {300: {"name": "A", "char": "stadtbild", "ready": false}}
	var left := []
	net.peer_left.connect(func(p): left.append(p))
	net._on_peer_disconnected(300)
	assert_eq(left, [300], "no run: removed at once")
	assert_false(net.is_away(300), "no grace period in the lobby")


func test_player_peer_mapping() -> void:
	net._mode = NetScript.Mode.SERVER
	net.lobby = {300: {"name": "A", "char": "stadtbild", "ready": false},
			400: {"name": "B", "char": "oma", "ready": false}}
	assert_eq(net.player_for_peer(300), 300, "first join: player id = peer id")
	assert_eq(net.player_for_peer(999), 0, "unknown peer")
	net._peer_of[300] = 777          # reconnected with a new peer id
	assert_eq(net.player_for_peer(777), 300, "new peer maps to the old player")
	assert_eq(net.player_for_peer(300), 0, "old peer no longer maps")
	assert_eq(net.peer_for_player(300), 777, "sends go to the new peer")
	assert_eq(net.peer_for_player(400), 400, "others unchanged")
	net._peer_of[300] = 0            # away
	assert_eq(net.peer_for_player(300), 0, "away: no peer")
	assert_eq(net.player_for_peer(777), 0, "away: the dead peer maps to nobody")


func test_check_resume_needs_valid_token_and_running_run() -> void:
	net._mode = NetScript.Mode.SERVER
	net.lobby = {300: {"name": "A", "char": "stadtbild", "ready": false}}
	net._tokens = {300: "secret"}
	var v: String = NetScript.game_version()
	var out := {}
	assert_eq(net.check_resume(NetScript.PROTOCOL_VERSION, v, "secret", out), "NET_ERR_SESSION", "no run: no resume")
	fake_game.config = {"seed": 1}
	assert_eq(net.check_join(NetScript.PROTOCOL_VERSION, v), "NET_ERR_RUNNING", "plain join still refused mid-run")
	assert_eq(net.check_resume(NetScript.PROTOCOL_VERSION, v, "wrong", out), "NET_ERR_SESSION", "bad token")
	assert_eq(net.check_resume(NetScript.PROTOCOL_VERSION, v, "", out), "NET_ERR_SESSION", "empty token")
	assert_eq(net.check_resume(NetScript.PROTOCOL_VERSION, v, 5, out), "NET_ERR_SESSION", "wrong type")
	assert_eq(net.check_resume(NetScript.PROTOCOL_VERSION + 1, v, "secret", out), "NET_ERR_VERSION", "version")
	assert_true(out.is_empty(), "no player on failure")
	assert_eq(net.check_resume(NetScript.PROTOCOL_VERSION, v, "secret", out), "", "valid token mid-run")
	assert_eq(out.get("player", 0), 300, "maps to the old player")
	assert_eq(NetScript._new_token().length(), 32, "128-bit hex token")
	assert_true(NetScript._new_token() != NetScript._new_token(), "tokens are random")


func test_return_to_lobby_drops_away_players() -> void:
	net._mode = NetScript.Mode.SERVER
	net.lobby = {300: {"name": "A", "char": "stadtbild", "ready": true},
			400: {"name": "B", "char": "oma", "ready": true}}
	net._tokens = {300: "a", 400: "b"}
	fake_game.config = {"seed": 1}
	net._on_peer_disconnected(400)
	assert_true(net.is_away(400), "away")
	net.return_to_lobby()
	assert_false(net.lobby.has(400), "away player dropped")
	assert_false(net._tokens.has(400), "token invalidated")
	assert_true(net.lobby.has(300), "present player stays")
	assert_eq(fake_game.back, 0, "no recursive back_to_lobby")


func test_client_reconnect_state_machine() -> void:
	var lost := []
	var gone := []
	net.connection_lost.connect(func(): lost.append(true))
	net.disconnected.connect(func(r): gone.append(r))
	# No token (or no run): losing the host ends the session at once, as before.
	net._mode = NetScript.Mode.CLIENT
	net._on_server_disconnected()
	assert_eq(gone, ["NET_ERR_LOST"], "no token: straight to the menu")
	assert_true(lost.is_empty(), "no reconnect without a token")
	# Mid-run with a token: reconnect in the background, keep the player id.
	gone.clear()
	net._mode = NetScript.Mode.CLIENT
	net._token = "secret"
	net._player_id = 4242
	net._server_ip = "127.0.0.1"
	net._server_port = 24713
	fake_game.config = {"seed": 1}
	net._on_server_disconnected()
	assert_eq(lost.size(), 1, "connection_lost emitted")
	assert_true(net.is_reconnecting(), "reconnecting")
	assert_true(gone.is_empty(), "not disconnected yet")
	assert_eq(net.local_player_id(), 4242, "player id kept while reconnecting")
	assert_near(net.reconnect_time_left(), NetScript.RECONNECT_S, 0.5, "60 s budget")
	# The budget runs out: give up with NET_ERR_LOST.
	net._tick_reconnect(NetScript._now() + NetScript.RECONNECT_S + 1.0)
	assert_eq(gone, ["NET_ERR_LOST"], "gave up")
	assert_false(net.is_reconnecting(), "no longer reconnecting")
	assert_eq(net._token, "", "session forgotten")


func test_bye_and_reconnect_flags_are_solo_safe() -> void:
	net.start_solo("A")
	assert_false(net.is_reconnecting(), "solo never reconnects")
	assert_eq(net.reconnect_time_left(), 0.0, "no timer in solo")
	assert_eq(net.local_player_id(), 1, "solo player id")
	net.debug_drop_connection()      # no-op outside client mode
	assert_true(net.is_host(), "still solo")
	net._tick_away(NetScript._now() + 999.0)
	net._tick_reconnect(NetScript._now() + 999.0)
	assert_eq(net.lobby.keys(), [1], "nothing removed")
