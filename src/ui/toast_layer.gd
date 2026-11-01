class_name ToastLayer
extends CanvasLayer
## Toasts at the top of the screen, above every screen (main.gd owns it).
## Anyone can call `ToastLayer.show_text(text)`.

static var instance: ToastLayer

var _box: VBoxContainer


func _init() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS


func _ready() -> void:
	instance = self
	var root := Control.new()
	# CanvasLayer breaks theme inheritance from the window, so set it here.
	root.theme = UITheme.get_theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_box = UIKit.vbox(8)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.offset_top = 14
	_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(_box)


func _exit_tree() -> void:
	if instance == self:
		instance = null


static func show_text(text: String, seconds := 3.5) -> void:
	if instance:
		instance.toast(text, seconds)
	else:
		print("[toast] ", text)


func toast(text: String, seconds := 3.5) -> void:
	var card := UIKit.card(Color("fffbe9"), UITheme.RED, UIKit.tilt_for(_box.get_child_count(), 0.6), 3)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UIKit.label(text, 24, UITheme.INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 420
	card.add_child(l)
	card.custom_minimum_size.x = 460
	_box.add_child(card)
	while _box.get_child_count() > 4:
		_box.get_child(0).free()
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.2)
	tw.tween_interval(seconds)
	tw.tween_property(card, "modulate:a", 0.0, 0.5)
	tw.tween_callback(card.queue_free)
