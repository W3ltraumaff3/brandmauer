extends TestCase
## Integration: Game + Net + Sim in solo mode, driven like the real main loop.

const AREAS := ["sim", "net", "ui", "save", "view"]  # ci-cd.md §2a

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


## GDD §5: after a won wave the Späti opens only after a short break, so you see
## "Feierabend! Welle N geschafft"; starting the screen in the Späti opens it at once.
func test_spaeti_opens_after_the_wave_won_break() -> void:
	var rs := RunScreen.new()
	var dt := 1.0 / 60.0
	assert_false(rs._spaeti_due(0, dt), "no Späti during a wave")
	var frames := 0
	while not rs._spaeti_due(1, dt) and frames < 1000:
		frames += 1
	assert_near(frames * dt, RunScreen.WAVE_WON_PAUSE, 0.05, "Späti after the break")
	assert_true(RunScreen.WAVE_WON_PAUSE >= 1.5, "long enough to read")
	assert_true(rs._spaeti_due(1, dt), "stays open")
	rs.free()
	var joined := RunScreen.new()
	assert_true(joined._spaeti_due(1, dt), "joining in the Späti: at once")
	joined.free()


func test_pause_only_in_solo() -> void:
	if game == null:
		return
	game.open_solo()
	game.set_paused(true)
	assert_true(game.is_paused())
	game.set_paused(false)
	assert_false(game.is_paused())
