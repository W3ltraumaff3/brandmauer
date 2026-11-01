class_name UIDialog
extends Control
## Modal dialog: dims the screen, shows a tilted paper card in the middle.
## Override build() and fill `content`.

signal closed

var content: VBoxContainer
var card: PanelContainer
var width := 520.0
## Set to false in build() if the dialog grabs focus itself.
var auto_focus := true


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	if theme == null:
		theme = UITheme.get_theme()  # also themed under a CanvasLayer
	var dim := ColorRect.new()
	var c := UITheme.INK
	c.a = 0.55
	dim.color = c
	UIKit.full(dim)
	add_child(dim)
	var center := CenterContainer.new()
	UIKit.full(center)
	add_child(center)
	card = UIKit.card(UITheme.PAPER, UITheme.INK, -0.8, 3)
	card.custom_minimum_size.x = width
	center.add_child(card)
	content = UIKit.vbox(12)
	card.add_child(UIKit.margin(content, 14, 10, 14, 10))
	build()
	if auto_focus:
		UIKit.focus_first(content)


func build() -> void:
	pass


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
