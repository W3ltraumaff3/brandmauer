class_name InputGlyphs
extends Node
## Prompt labels for the input device in use (GDD §19b): "[X]" once a gamepad
## was used last, "[Leertaste]" after keyboard or mouse input. One instance sits
## at the end of the root (ensure()) so its _input sees every event first.
##
##   InputGlyphs.label("ultimate")     -> "[X]" / "[Leertaste]"
##   InputGlyphs.key("streik")         -> "Y" / "Q"   (no brackets)
##   InputGlyphs.bind(label, "text", func() -> String: return ...)  # live update
##
## Also registers the extra UI actions the gamepad needs (ensure_actions()).

## Device or button style switched; prompts should refresh.
signal changed

enum Device { KEYBOARD, MOUSE, PAD }

## Godot's joypad mapping is positional (button 0 = bottom face button).
const PAD_NAMES := {
	"xbox": {
		JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
		JOY_BUTTON_BACK: "View", JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_SHOULDER: "LB",
		JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	},
	"ps": {
		JOY_BUTTON_A: "✕", JOY_BUTTON_B: "○", JOY_BUTTON_X: "□", JOY_BUTTON_Y: "△",
		JOY_BUTTON_BACK: "Share", JOY_BUTTON_START: "Options", JOY_BUTTON_LEFT_SHOULDER: "L1",
		JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	},
	"nintendo": {
		JOY_BUTTON_A: "B", JOY_BUTTON_B: "A", JOY_BUTTON_X: "Y", JOY_BUTTON_Y: "X",
		JOY_BUTTON_BACK: "−", JOY_BUTTON_START: "+", JOY_BUTTON_LEFT_SHOULDER: "L",
		JOY_BUTTON_RIGHT_SHOULDER: "R", JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	},
}
## Keys with a translated name (everything else uses the OS key name).
const KEY_NAMES := {KEY_SPACE: "INPUT_KEY_SPACE", KEY_ESCAPE: "INPUT_KEY_ESC", KEY_ENTER: "INPUT_KEY_ENTER",
	KEY_KP_ENTER: "INPUT_KEY_ENTER", KEY_PAGEUP: "INPUT_KEY_PAGEUP", KEY_PAGEDOWN: "INPUT_KEY_PAGEDOWN"}

static var instance: InputGlyphs
static var device := Device.KEYBOARD
## "xbox" | "ps" | "nintendo" (from Input.get_joy_name of the last pad used).
static var pad_style := "xbox"


func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	track(event)


func _exit_tree() -> void:
	if instance == self:
		instance = null


## The shared instance; created (and added to the root, deferred) on first use.
static func ensure() -> InputGlyphs:
	if instance != null and is_instance_valid(instance):
		return instance
	ensure_actions()
	instance = InputGlyphs.new()
	instance.name = "InputGlyphs"
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		(loop as SceneTree).root.add_child.call_deferred(instance)
	return instance


static func using_pad() -> bool:
	return device == Device.PAD


static func using_mouse() -> bool:
	return device == Device.MOUSE


## Records which device the event came from. Ignores tiny stick/mouse jitter.
static func track(event: InputEvent) -> void:
	var d := device
	var style := pad_style
	if event is InputEventJoypadButton:
		if not (event as InputEventJoypadButton).pressed:
			return
		d = Device.PAD
		style = style_for(Input.get_joy_name(event.device))
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < 0.5:
			return
		d = Device.PAD
		style = style_for(Input.get_joy_name(event.device))
	elif event is InputEventKey:
		if not (event as InputEventKey).pressed:
			return
		d = Device.KEYBOARD
	elif event is InputEventMouseButton:
		if not (event as InputEventMouseButton).pressed:
			return
		d = Device.MOUSE
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() < 4.0:
			return
		d = Device.MOUSE
	else:
		return
	set_device(d, style)


static func set_device(d: Device, style := "") -> void:
	if style == "":
		style = pad_style
	if d == device and style == pad_style:
		return
	device = d
	pad_style = style
	if instance != null and is_instance_valid(instance):
		instance.changed.emit()


## Button style from the controller name (Godot/SDL joypad names).
static func style_for(joy_name: String) -> String:
	var n := joy_name.to_lower()
	for k in ["playstation", "dualshock", "dualsense", "ps3", "ps4", "ps5", "sony"]:
		if n.contains(k):
			return "ps"
	for k in ["nintendo", "switch", "joy-con", "pro controller"]:
		if n.contains(k):
			return "nintendo"
	return "xbox"


## Button/key name for `action` on the current device, without brackets.
## "move" is a pseudo action (stick / W A S D). "" if nothing is bound.
static func key(action: String, pad := -1) -> String:
	var use_pad := using_pad() if pad < 0 else pad == 1
	if action == "move":
		return _tr("INPUT_PAD_LSTICK" if use_pad else "INPUT_KEYS_MOVE")
	if not InputMap.has_action(action):
		return ""
	var events := InputMap.action_get_events(action)
	if use_pad:
		for e in events:
			if e is InputEventJoypadButton:
				var names: Dictionary = PAD_NAMES.get(pad_style, PAD_NAMES["xbox"])
				var idx := (e as InputEventJoypadButton).button_index
				return str(names.get(idx, "%d" % idx))
		for e in events:
			if e is InputEventJoypadMotion:
				var axis := (e as InputEventJoypadMotion).axis
				return _tr("INPUT_PAD_RSTICK" if axis == JOY_AXIS_RIGHT_X or axis == JOY_AXIS_RIGHT_Y else "INPUT_PAD_LSTICK")
		return ""
	for e in events:
		if e is InputEventKey:
			var k := e as InputEventKey
			var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			if KEY_NAMES.has(code):
				return _tr(KEY_NAMES[code])
			if k.physical_keycode != KEY_NONE and DisplayServer.get_name() != "headless":
				code = DisplayServer.keyboard_get_keycode_from_physical(code)
			return OS.get_keycode_string(code)
	return ""


## "[X]" / "[Leertaste]", or "" if the action has no binding on this device.
static func label(action: String, pad := -1) -> String:
	var k := key(action, pad)
	return "[%s]" % k if k != "" else ""


## tr(fmt_key) with the labels of `actions` filled in (one %s per action).
static func fmt(fmt_key: String, actions: Array) -> String:
	var labels := []
	for a in actions:
		labels.append(label(str(a)))
	return _tr(fmt_key) % labels


## Sets target.property = builder.call() now and whenever the device changes.
## The binding is a child node, so it disappears with the target.
static func bind(target: Node, property: String, builder: Callable) -> void:
	target.set(property, builder.call())
	var b := _Binding.new()
	b.name = "GlyphBinding_" + property
	b.property = property
	b.builder = builder
	target.add_child(b)


## Shows `c` only while a gamepad is in use (e.g. "[LB] [RB] Abschnitt").
static func show_on_pad(c: CanvasItem) -> void:
	bind(c, "visible", func() -> bool: return InputGlyphs.using_pad())


## Registers the gamepad bindings Godot's default ui_* actions lack:
## A = ui_accept, B = ui_cancel, LB/RB = ui_page_left/right (Späti sections),
## right stick = ui_scroll_up/down. Safe to call repeatedly.
static func ensure_actions() -> void:
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)
	_add_button("ui_page_left", JOY_BUTTON_LEFT_SHOULDER)
	_add_button("ui_page_right", JOY_BUTTON_RIGHT_SHOULDER)
	_add_axis("ui_scroll_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_axis("ui_scroll_down", JOY_AXIS_RIGHT_Y, 1.0)


static func _add_button(action: String, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


static func _add_axis(action: String, axis: JoyAxis, value: float) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.25)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)


static func _tr(k: String) -> String:
	return String(TranslationServer.translate(k))


class _Binding extends Node:
	var property := ""
	var builder: Callable

	func _enter_tree() -> void:
		var g := InputGlyphs.ensure()
		if not g.changed.is_connected(_refresh):
			g.changed.connect(_refresh)
		_refresh()

	func _exit_tree() -> void:
		var g := InputGlyphs.instance
		if g != null and is_instance_valid(g) and g.changed.is_connected(_refresh):
			g.changed.disconnect(_refresh)

	func _refresh() -> void:
		var t := get_parent()
		if t != null and builder.is_valid():
			t.set(property, builder.call())
