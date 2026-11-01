class_name UIScreen
extends Control
## Base for full-screen menus: paper background, margin, vertical body.
## Overlay screens (Album, Optionen, …) emit `closed` and free themselves;
## Escape / gamepad B closes them.

signal closed

## Close on ui_cancel (overlays). Top-level screens leave this off.
var closable := true
## Focus the first button after build(); off if build() grabs focus itself.
var auto_focus := true
var body: VBoxContainer
var background: PaperBg


func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	background = PaperBg.new()
	if theme == null:
		theme = UITheme.get_theme()  # also themed under a CanvasLayer
	add_child(background)
	body = UIKit.vbox(10)
	var m := UIKit.margin(body, 40, 22, 40, 22)
	UIKit.full(m)
	add_child(m)
	build()
	if auto_focus:
		UIKit.focus_first(self)


## Override: fill `body`.
func build() -> void:
	pass


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if closable and is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
