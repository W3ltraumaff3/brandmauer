extends Node
## Entry point (scenes/main.tscn). Applies the shared theme, owns the toast
## layer and switches screens on Game.screen_requested:
## "menu" | "lobby" | "run" | "end". A dedicated server only shows a status line.
## Caps the frame rate: 144 FPS in a run, 60 in menus (GDD §4 Performance), and
## installs the gamepad helpers (UINav: InputGlyphs, FocusTips; GDD §19b).

const FPS_RUN := 144
const FPS_MENU := 60

const RUN_SCREEN_PATH := "res://src/view/run_screen.gd"

var _current: Node
var _current_name := ""
var _toasts: ToastLayer
var _status: Label


func _ready() -> void:
	get_tree().root.theme = UITheme.get_theme()
	_toasts = ToastLayer.new()
	add_child(_toasts)
	OptionsScreen.apply_window_mode(OptionsScreen.saved_window_mode())
	var g := UIApi.game()
	UIApi.connect_opt(g, "screen_requested", show_screen)
	UIApi.connect_opt(g, "message", _on_message)
	UIApi.connect_opt(UIApi.net(), "lobby_changed", _update_status)
	if _is_dedicated():
		_show_server_status()
	else:
		UINav.install(self)
		show_screen("menu")


func _is_dedicated() -> bool:
	return bool(UIApi.prop(UIApi.net(), "dedicated", false)) or UIApi.mode() == "server"


func show_screen(screen: String) -> void:
	if _is_dedicated():
		_show_server_status()
		_update_status()
		return
	if screen == "menu" and _current_name == "menu" and is_instance_valid(_current):
		return  # keep open dialogs (e.g. a failed join shows its reason)
	var next: Node
	match screen:
		"menu":
			next = MainMenu.new()
			UIApi.call_opt(UIApi.audio(), "play_music", ["menu"])
		"lobby":
			next = Lobby.new()
		"run":
			next = _make_run_screen()
		"end":
			next = EndScreen.new()
		_:
			push_warning("main: unknown screen '%s'" % screen)
			return
	Engine.max_fps = fps_for(screen)
	_swap(next, screen)


## Frame cap per screen (GDD §4): 144 during a run (incl. the Späti), 60 for
## the menu, lobby and end screen.
static func fps_for(screen: String) -> int:
	return FPS_RUN if screen == "run" else FPS_MENU


func _swap(next: Node, screen: String) -> void:
	if _current and is_instance_valid(_current):
		_current.queue_free()
		remove_child(_current)
	_current = next
	_current_name = screen
	next.name = screen.capitalize().replace(" ", "")
	add_child(next)
	move_child(_toasts, -1)


func _make_run_screen() -> Node:
	if ResourceLoader.exists(RUN_SCREEN_PATH):
		var script = load(RUN_SCREEN_PATH)
		if script is Script and (script as Script).can_instantiate():
			var n = script.new()
			if n is Node:
				return n
	push_warning("main: %s missing, showing placeholder" % RUN_SCREEN_PATH)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := PaperBg.new()
	c.add_child(bg)
	c.add_child(UIKit.label(tr("MAIN_RUN_MISSING"), 28, UITheme.INK_SOFT))
	return c


func _on_message(text_key: String) -> void:
	ToastLayer.show_text(tr(text_key))


# --- Dedicated server ---------------------------------------------------------

func _show_server_status() -> void:
	if _status:
		return
	if _current and is_instance_valid(_current):
		_current.queue_free()
		_current = null
	_status = UIKit.label("", 22, UITheme.INK)
	_status.position = Vector2(16, 16)
	add_child(_status)
	_update_status()


func _update_status() -> void:
	if _status == null:
		return
	var lobby := UIApi.lobby()
	var ready := 0
	for p in lobby.values():
		if p is Dictionary and p.get("ready", false):
			ready += 1
	_status.text = tr("MAIN_SERVER_STATUS").format({
		"port": UIApi.port(), "players": lobby.size(), "ready": ready,
		"upnp": str(UIApi.net_value("upnp_status", "")),
	})
	print(_status.text)
