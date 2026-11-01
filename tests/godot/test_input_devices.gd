extends TestCase
## Regression (v0.2.2): controller bindings must work for every connected pad, not only
## device 0. Analog keyboards (e.g. Keychron HE) also register as joypads and can take
## device 0, which made a PlayStation controller on device 1 do nothing at all.

const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "ultimate", "streik", "pause",
	"ui_accept", "ui_cancel", "ui_page_left", "ui_page_right"]


func before_each() -> void:
	var game := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Game")
	if game:
		game._register_input()
	InputGlyphs.ensure_actions()


func test_joypad_bindings_accept_all_devices() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), action + " registered")
		var pad_events := 0
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				pad_events += 1
				assert_eq(ev.device, -1, "%s is bound to one device only" % action)
		assert_true(pad_events > 0, action + " has a controller binding")


func test_any_device_triggers_actions() -> void:
	for device in [0, 1, 2, 5]:
		var x := InputEventJoypadButton.new()
		x.device = device
		x.button_index = JOY_BUTTON_X
		x.pressed = true
		assert_true(InputMap.event_is_action(x, "ultimate"), "X on pad %d triggers the ultimate" % device)
		var a := InputEventJoypadButton.new()
		a.device = device
		a.button_index = JOY_BUTTON_A
		a.pressed = true
		assert_true(InputMap.event_is_action(a, "ui_accept"), "A on pad %d confirms in menus" % device)
		var stick := InputEventJoypadMotion.new()
		stick.device = device
		stick.axis = JOY_AXIS_LEFT_X
		stick.axis_value = 1.0
		assert_true(InputMap.event_is_action(stick, "move_right"), "stick on pad %d moves" % device)
