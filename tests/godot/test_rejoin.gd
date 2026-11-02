extends TestCase
## Rejoin after a crash (networking.md §7.5): the saved session (Save, memory
## only in tests) and when Game keeps or drops it.

const AREAS := ["net", "save"]  # ci-cd.md §2a

var game: Node
var save: Node
const SESSION := {"ip": "10.0.0.5", "port": 24713, "token": "secret", "player": 4242}


func before_each() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	game = root.get_node_or_null("Game")
	save = root.get_node_or_null("Save")
	if save:
		save.clear_rejoin()


func after_each() -> void:
	if save:
		save.clear_rejoin()
	if game:
		game.quit_to_menu()


func test_session_is_valid_only_for_this_version_and_recent() -> void:
	if save == null:
		fail("Save autoload missing")
		return
	assert_false(save.persist, "tests never write the real rejoin file")
	assert_true(save.rejoin_info().is_empty(), "nothing saved")
	save.set_rejoin(SESSION)
	assert_eq(save.rejoin_info(), SESSION, "saved session")
	save._rejoin_mem["version"] = "0.0.1-old"
	assert_true(save.rejoin_info().is_empty(), "other game version")
	save.set_rejoin(SESSION)
	save._rejoin_mem["saved_at"] = int(Time.get_unix_time_from_system()) - save.REJOIN_MAX_AGE_S - 10
	assert_true(save.rejoin_info().is_empty(), "too old")
	save.set_rejoin(SESSION)
	save.clear_rejoin()
	assert_true(save.rejoin_info().is_empty(), "cleared")


func test_lost_connection_keeps_the_session_deliberate_exits_drop_it() -> void:
	if game == null or save == null:
		fail("Game/Save autoloads missing")
		return
	# Lost mid-run: the host keeps the character, so "Zurück ins Spiel" stays.
	save.set_rejoin(SESSION)
	game.mode = game.Mode.CLIENT
	game.config = {"seed": 1}
	game._on_disconnected("NET_ERR_LOST")
	assert_eq(save.rejoin_info(), SESSION, "kept after NET_ERR_LOST mid-run")
	# A failed rejoin from the menu (no run yet) drops it.
	game.mode = game.Mode.CLIENT
	game._on_disconnected("NET_ERR_LOST")
	assert_true(save.rejoin_info().is_empty(), "dropped after a failed rejoin")
	# Deliberate exits.
	for exit in ["quit", "host_closed", "session", "lobby", "window"]:
		save.set_rejoin(SESSION)
		game.mode = game.Mode.CLIENT
		game.config = {"seed": 1}
		match exit:
			"quit": game.quit_to_menu()
			"host_closed": game._on_disconnected("NET_ERR_HOST_CLOSED")
			"session": game._on_disconnected("NET_ERR_SESSION")
			"lobby": game._on_returned_to_lobby()
			"window": game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		assert_true(save.rejoin_info().is_empty(), "dropped on " + exit)
	game.quit_to_menu()


func test_open_rejoin_needs_a_session() -> void:
	if game == null or save == null:
		fail("Game/Save autoloads missing")
		return
	assert_false(game.open_rejoin(), "nothing to rejoin")
	save.set_rejoin(SESSION)
	assert_true(game.open_rejoin(), "rejoins")
	assert_eq(game.mode, game.Mode.CLIENT, "as a client")
	var net: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Net")
	assert_true(net.is_reconnecting(), "resume handshake running")
	assert_eq(game.local_id(), 4242, "with the saved player id")
