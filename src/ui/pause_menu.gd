class_name PauseMenu
extends Control
## Pause overlay for the run screen. Pauses only in solo (Game.set_paused);
## in co-op the run keeps going behind it.

signal closed

var _card_box: VBoxContainer
var _quit_btn: Button
var _quit_armed := false
var _solo := false
var _closing := false


func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	if theme == null:
		theme = UITheme.get_theme()  # also themed under a CanvasLayer
	_solo = UIApi.is_solo()
	if _solo:
		UIApi.call_opt(UIApi.game(), "set_paused", [true])
	var dim := ColorRect.new()
	var c := UITheme.INK
	c.a = 0.55
	dim.color = c
	add_child(UIKit.full(dim))
	var center := CenterContainer.new()
	add_child(UIKit.full(center))
	var card := UIKit.card(UITheme.PAPER, UITheme.INK, -1.2, 3)
	card.custom_minimum_size.x = 420
	center.add_child(card)
	_card_box = UIKit.vbox(12)
	card.add_child(UIKit.margin(_card_box, 18, 10, 18, 14))
	var title := UIKit.heading(tr("PAUSE_TITLE") if _solo else tr("PAUSE_TITLE_COOP"), 40, UITheme.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_box.add_child(title)
	var hint := UIKit.para(tr("PAUSE_HINT") if _solo else tr("PAUSE_HINT_COOP"), 18, UITheme.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_box.add_child(hint)
	var resume := UIKit.button(tr("PAUSE_RESUME"), resume_game, 26)
	_card_box.add_child(resume)
	_card_box.add_child(UIKit.button(tr("MENU_OPTIONS"), _on_options, 24))
	_quit_btn = UIKit.button(tr("PAUSE_GIVE_UP") if _solo else tr("PAUSE_LEAVE"), _on_quit, 24)
	_card_box.add_child(_quit_btn)
	resume.grab_focus.call_deferred()


func resume_game() -> void:
	if _closing:
		return
	_closing = true
	if _solo:
		UIApi.call_opt(UIApi.game(), "set_paused", [false])
	closed.emit()
	queue_free()


func _on_options() -> void:
	var o := OptionsScreen.new()
	add_child(o)
	o.tree_exited.connect(_on_options_closed)


func _on_options_closed() -> void:
	if is_inside_tree():
		(_card_box.get_child(3) as Button).grab_focus()


func _on_quit() -> void:
	if not _quit_armed:
		_quit_armed = true
		_quit_btn.text = tr("PAUSE_CONFIRM")
		_quit_btn.add_theme_color_override("font_color", UITheme.RED)
		return
	if _solo:
		UIApi.call_opt(UIApi.game(), "set_paused", [false])
	UIApi.call_opt(UIApi.game(), "quit_to_menu")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		get_viewport().set_input_as_handled()
		resume_game()
