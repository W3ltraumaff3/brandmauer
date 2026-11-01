class_name FocusTips
extends CanvasLayer
## Gamepad/keyboard helper layer (GDD §19b), added once by UINav.install():
## - shows the focused control's tooltip in a small doodle box next to it
##   (not after mouse input: the mouse gets Godot's hover tooltips),
## - draws the doodle focus frame for controls without a focus style of their
##   own (sliders, cards, labels),
## - scrolls the focused control into view inside ScrollContainers,
## - keeps focus off disabled or hidden controls.

const MAX_W := 380.0
const FONT_SIZE := 17

static var instance: FocusTips

var _root: Control
var _box: PanelContainer
var _label: Label
var _frame: Control
var _target: Control
var _last_good: Control
var _xform := Transform2D.IDENTITY


func _init() -> void:
	layer = 99
	process_mode = PROCESS_MODE_ALWAYS


func _ready() -> void:
	instance = self
	_root = Control.new()
	_root.name = "FocusTipsRoot"
	_root.theme = UITheme.get_theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.focus_mode = Control.FOCUS_NONE
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.draw.connect(_draw_frame)
	_root.add_child(_frame)
	_box = PanelContainer.new()
	_box.name = "FocusTip"
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UITheme.box(Color("fffbe9"), UITheme.INK, 2, 5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	_box.add_theme_stylebox_override("panel", sb)
	_label = UIKit.label("", FONT_SIZE, UITheme.INK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_label)
	_box.visible = false
	_root.add_child(_box)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	InputGlyphs.ensure().changed.connect(_update)


func _exit_tree() -> void:
	if instance == self:
		instance = null


## Text of the info box currently shown ("" if hidden). For tests.
func shown_text() -> String:
	return _label.text if _box.visible else ""


func _on_focus_changed(c: Control) -> void:
	if c == null or not is_instance_valid(c):
		return
	if not UINav.can_focus(c):
		# Never rest on a disabled or hidden control: go back to the last good one.
		if _last_good != null and is_instance_valid(_last_good) and _last_good != c and UINav.can_focus(_last_good):
			_last_good.grab_focus.call_deferred()
		else:
			c.release_focus()
		return
	_last_good = c
	_target = c
	_scroll_into_view.call_deferred(c)
	_update()


func _scroll_into_view(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or InputGlyphs.using_mouse():
		return
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(c)
		p = p.get_parent()


func _process(_delta: float) -> void:
	if _target == null:
		return
	if not is_instance_valid(_target) or not _target.is_visible_in_tree() or not _target.has_focus():
		_target = null
		_box.visible = false
		_frame.queue_redraw()
		return
	var x := _target.get_global_transform_with_canvas()
	if x != _xform:
		_xform = x
		_place()
		_frame.queue_redraw()


func _update() -> void:
	if _target != null and not is_instance_valid(_target):
		_target = null
	_frame.queue_redraw()
	var t := _tip_text(_target)
	if t == "" or InputGlyphs.using_mouse():
		_box.visible = false
		return
	# Wrapped here (not autowrap): an autowrap label only knows its height
	# after a layout pass, which made the box jump.
	_label.text = wrap_text(t, UITheme.hand(), FONT_SIZE, MAX_W)
	_box.visible = true
	_box.reset_size()
	_xform = _target.get_global_transform_with_canvas()
	_place()


## Greedy word wrap of `text` to `max_w` pixels; keeps existing line breaks.
static func wrap_text(text: String, font: Font, size: int, max_w: float) -> String:
	var out := PackedStringArray()
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" ", false):
			var test := word if line == "" else line + " " + word
			if line != "" and font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w:
				out.append(line)
				line = word
			else:
				line = test
		out.append(line)
	return "\n".join(out)


func _tip_text(c) -> String:
	if c == null or not is_instance_valid(c) or not (c is Control):
		return ""
	return (c as Control).tooltip_text.strip_edges()


## Below the control, or above it when there is no room; inside the screen.
func _place() -> void:
	if not _box.visible or _target == null:
		return
	var r := _screen_rect(_target)
	var vp := _root.get_viewport_rect().size
	_box.reset_size()
	var s := _box.size
	var pos := Vector2(r.position.x + 6.0, r.end.y + 8.0)
	if pos.y + s.y > vp.y - 6.0:
		pos.y = r.position.y - s.y - 8.0
	pos.x = clampf(pos.x, 6.0, maxf(6.0, vp.x - s.x - 6.0))
	pos.y = clampf(pos.y, 6.0, maxf(6.0, vp.y - s.y - 6.0))
	_box.position = pos


static func _screen_rect(c: Control) -> Rect2:
	var x := c.get_global_transform_with_canvas()
	var r := Rect2(x * Vector2.ZERO, Vector2.ZERO)
	for p in [Vector2(c.size.x, 0), c.size, Vector2(0, c.size.y)]:
		r = r.expand(x * (p as Vector2))
	return r


## Controls whose own drawing shows no focus get the frame from here.
static func needs_frame(c: Control) -> bool:
	return c is Slider or c is Label or c is PanelContainer or c.has_meta("nav_frame")


func _draw_frame() -> void:
	if _target == null or not is_instance_valid(_target) or not needs_frame(_target) or not _target.is_inside_tree():
		return
	_frame.draw_set_transform_matrix(_target.get_global_transform_with_canvas())
	var sb := UITheme.focus_box()
	sb.draw(_frame.get_canvas_item(), Rect2(Vector2.ZERO, _target.size))
	_frame.draw_set_transform_matrix(Transform2D.IDENTITY)
