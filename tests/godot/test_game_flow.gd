extends TestCase
## Integration: Game + Net + Sim in solo mode, driven like the real main loop.

var game: Node
var net: Node


func before_each() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	game = root.get_node_or_null("Game")
	net = root.get_node_or_null("Net")


func after_each() -> void:
	if game:
		game.quit_to_menu()


func test_solo_run_through_first_wave() -> void:
	if game == null or net == null:
		fail("Game/Net autoloads missing")
		return
	game.open_solo()
	assert_eq(game.mode, game.Mode.SOLO)
	assert_true(net.lobby.has(1), "local player in lobby")
	net.set_char("oma")
	game.start_run()
	assert_true(game.is_running(), "run started")
	assert_eq(game.meta.get("players", {}).get(1, {}).get("char", ""), "oma")
	for i in 60 * 31:
		game.sim.players[1].iframes = 10.0
		game._physics_process(1.0 / 60.0)
	assert_eq(int(game.meta["phase"]), Sim.Phase.SHOP, "shop after wave 1")
	assert_true(game.view.players.size() == 1, "view has player")
	game.request("ready", true)
	assert_eq(game.sim.wave, 2, "ready starts wave 2")


func test_pause_only_in_solo() -> void:
	if game == null:
		return
	game.open_solo()
	game.set_paused(true)
	assert_true(game.is_paused())
	game.set_paused(false)
	assert_false(game.is_paused())
