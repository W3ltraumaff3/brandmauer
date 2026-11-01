extends TestCase
## Controller support helpers (GDD §19b) and the menu frame cap (GDD §4).
## The full screen-by-screen navigation check is tools/gamepad_nav_check.gd.


func after_each() -> void:
	InputGlyphs.set_device(InputGlyphs.Device.KEYBOARD, "xbox")


func test_keyboard_labels() -> void:
	InputGlyphs.set_device(InputGlyphs.Device.KEYBOARD, "xbox")
	_ensure_game_actions()
	assert_eq(InputGlyphs.label("ultimate"), "[Leertaste]")
	assert_eq(InputGlyphs.label("streik"), "[Q]")
	assert_eq(InputGlyphs.label("pause"), "[Esc]")
	assert_eq(InputGlyphs.label("ui_accept"), "[Enter]")
	assert_eq(InputGlyphs.label("ui_cancel"), "[Esc]")
	assert_eq(InputGlyphs.key("move"), "W, A, S, D")
	assert_eq(InputGlyphs.label("no_such_action"), "")


func test_pad_labels() -> void:
	InputGlyphs.ensure_actions()
	_ensure_game_actions()
	InputGlyphs.set_device(InputGlyphs.Device.PAD, "xbox")
	assert_true(InputGlyphs.using_pad())
	assert_eq(InputGlyphs.label("ultimate"), "[X]")
	assert_eq(InputGlyphs.label("streik"), "[Y]")
	assert_eq(InputGlyphs.label("pause"), "[Start]")
	assert_eq(InputGlyphs.label("ui_accept"), "[A]")
	assert_eq(InputGlyphs.label("ui_cancel"), "[B]")
	assert_eq(InputGlyphs.label("ui_page_left"), "[LB]")
	assert_eq(InputGlyphs.label("ui_page_right"), "[RB]")
	assert_eq(InputGlyphs.key("move"), "Linker Stick")
	InputGlyphs.set_device(InputGlyphs.Device.PAD, "ps")
	assert_eq(InputGlyphs.label("ultimate"), "[□]")
	assert_eq(InputGlyphs.label("ui_accept"), "[✕]")
	assert_eq(InputGlyphs.label("ui_page_right"), "[R1]")
	assert_eq(InputGlyphs.fmt("LOBBY_ULT_HINT", ["ultimate"]), "[□] · einmal pro Sitzungswoche")


func test_style_from_controller_name() -> void:
	assert_eq(InputGlyphs.style_for("PS4 Controller"), "ps")
	assert_eq(InputGlyphs.style_for("DualSense Wireless Controller"), "ps")
	assert_eq(InputGlyphs.style_for("Nintendo Switch Pro Controller"), "nintendo")
	assert_eq(InputGlyphs.style_for("Xbox Series Controller"), "xbox")
	assert_eq(InputGlyphs.style_for(""), "xbox")


func test_device_tracking() -> void:
	var jb := InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_A
	jb.pressed = true
	InputGlyphs.track(jb)
	assert_true(InputGlyphs.using_pad(), "pad button")
	var jitter := InputEventJoypadMotion.new()
	jitter.axis_value = 0.2
	var mm := InputEventMouseMotion.new()
	mm.relative = Vector2(1, 0)
	InputGlyphs.track(mm)
	InputGlyphs.track(jitter)
	assert_true(InputGlyphs.using_pad(), "tiny mouse/stick jitter is ignored")
	var k := InputEventKey.new()
	k.physical_keycode = KEY_W
	k.pressed = true
	InputGlyphs.track(k)
	assert_false(InputGlyphs.using_pad(), "key switches back")
	mm.relative = Vector2(20, 0)
	InputGlyphs.track(mm)
	assert_true(InputGlyphs.using_mouse(), "mouse")


func test_extra_actions_registered_once() -> void:
	InputGlyphs.ensure_actions()
	var n := InputMap.action_get_events("ui_accept").size()
	InputGlyphs.ensure_actions()
	assert_eq(InputMap.action_get_events("ui_accept").size(), n, "idempotent")
	assert_true(_has_button("ui_accept", JOY_BUTTON_A), "A = ui_accept")
	assert_true(_has_button("ui_cancel", JOY_BUTTON_B), "B = ui_cancel")
	assert_true(_has_button("ui_page_left", JOY_BUTTON_LEFT_SHOULDER), "LB")
	assert_true(_has_button("ui_page_right", JOY_BUTTON_RIGHT_SHOULDER), "RB")
	assert_true(InputMap.has_action("ui_scroll_down"), "right stick scroll")


func test_focus_tip_wrap() -> void:
	var font := UITheme.hand()
	var text := "Wer hat hier was geleistet? Schaden, Heilung, Kohle. Und noch ein recht langer Satz.\nZweite Zeile"
	var wrapped := FocusTips.wrap_text(text, font, 17, 200.0)
	assert_true(wrapped.split("\n").size() >= 3, "wrapped")
	for line in wrapped.split("\n"):
		assert_true(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x <= 200.0, "fits: " + line)
	assert_eq(wrapped.replace("\n", " "), text.replace("\n", " "), "no words lost")


func test_fps_cap_per_screen() -> void:
	var main_script: GDScript = load("res://src/main.gd")
	assert_eq(main_script.fps_for("run"), 144)
	for s in ["menu", "lobby", "end"]:
		assert_eq(main_script.fps_for(s), 60, s)


func test_sync_disabled_buttons_leave_focus_chain() -> void:
	var box := VBoxContainer.new()
	var b := Button.new()
	box.add_child(b)
	b.disabled = true
	UINav.sync_disabled(box)
	assert_eq(b.focus_mode, Control.FOCUS_NONE, "disabled: not focusable")
	b.disabled = false
	UINav.sync_disabled(box)
	assert_eq(b.focus_mode, Control.FOCUS_ALL, "enabled again")
	box.free()


func _has_button(action: String, button: JoyButton) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return true
	return false


## The game actions come from Game._register_input(); without the Game
## autoload (-s test runs) register the same bindings here.
func _ensure_game_actions() -> void:
	var keys := {"streik": [KEY_Q, JOY_BUTTON_Y], "pause": [KEY_ESCAPE, JOY_BUTTON_START], "ultimate": [KEY_SPACE, JOY_BUTTON_X]}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var k := InputEventKey.new()
		k.physical_keycode = keys[action][0]
		InputMap.action_add_event(action, k)
		var jb := InputEventJoypadButton.new()
		jb.button_index = keys[action][1]
		InputMap.action_add_event(action, jb)
