class_name UINav
## Gamepad/keyboard navigation helpers (GDD §19b): modal focus trapping,
## focus checks, OptionButtons that step with left/right, stick scrolling.
## install() adds the global pieces (InputGlyphs, FocusTips) once.


## Adds InputGlyphs (device tracking + extra actions) and the FocusTips layer.
## main.gd calls this at startup; tools call it on their SceneTree root.
static func install(parent: Node) -> void:
	InputGlyphs.ensure()
	if FocusTips.instance == null or not is_instance_valid(FocusTips.instance):
		var ft := FocusTips.new()
		ft.name = "FocusTips"
		FocusTips.instance = ft
		parent.add_child.call_deferred(ft)


## A control the user may move focus to: shown, enabled, focusable.
static func can_focus(c) -> bool:
	if c == null or not is_instance_valid(c) or not (c is Control):
		return false
	var ctl := c as Control
	if not ctl.is_inside_tree() or not ctl.is_visible_in_tree():
		return false
	if ctl.get_focus_mode_with_override() == Control.FOCUS_NONE:
		return false
	return not (ctl is BaseButton and (ctl as BaseButton).disabled)


# --- Modals -------------------------------------------------------------------

## Keeps focus inside `m` (dialog / overlay) while it is open: every Control
## beside it and beside its ancestors stops taking focus. Remembers the
## focused control so it gets focus back on close (unless the opener restores
## focus itself). Call from the modal's _ready, before it grabs focus.
static func modal_open(m: Control) -> void:
	if m.has_meta("nav_blocked"):
		return
	var vp := m.get_viewport()
	var from: Control = vp.gui_get_focus_owner() if vp else null
	var blocked := []
	var n: Node = m
	var root: Node = m.get_tree().root
	while n != null and n != root:
		var p := n.get_parent()
		if p == null:
			break
		for s in p.get_children():
			if s == n or not (s is Control):
				continue
			var sc := s as Control
			if sc.focus_behavior_recursive == Control.FOCUS_BEHAVIOR_DISABLED:
				continue
			blocked.append([sc, sc.focus_behavior_recursive])
			sc.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		n = p
	m.set_meta("nav_blocked", blocked)
	m.set_meta("nav_from", from)
	m.tree_exiting.connect(modal_close.bind(m), CONNECT_ONE_SHOT)


## Gives focus back to what the modal blocked. Called by the modal's close()
## (so the opener can refocus right away) and again on tree_exiting.
static func modal_close(m: Control) -> void:
	if not is_instance_valid(m) or not m.has_meta("nav_blocked"):
		return
	var blocked: Array = m.get_meta("nav_blocked")
	m.remove_meta("nav_blocked")
	blocked.reverse()
	for entry in blocked:
		var s = entry[0]
		if is_instance_valid(s):
			(s as Control).focus_behavior_recursive = entry[1]
	var from = m.get_meta("nav_from", null)
	var from_id: int = (from as Object).get_instance_id() if is_instance_valid(from) else 0
	var fallback := m.get_parent()
	var fallback_id: int = fallback.get_instance_id() if fallback is Control or fallback is CanvasLayer else 0
	var tree := m.get_tree()
	if tree == null:
		return
	# Next frame, at its end: the opener (and any new screen) had its chance to
	# set focus itself. Ids, not references: both may be freed by then.
	tree.process_frame.connect(func() -> void: _restore_focus.call_deferred(tree, from_id, fallback_id),
		CONNECT_ONE_SHOT)


static func _restore_focus(tree: SceneTree, from_id: int, fallback_id: int) -> void:
	var owner := tree.root.gui_get_focus_owner()
	if owner != null and can_focus(owner):
		return
	var from: Object = instance_from_id(from_id) if from_id != 0 else null
	if can_focus(from):
		(from as Control).grab_focus()
		return
	var fallback: Object = instance_from_id(fallback_id) if fallback_id != 0 else null
	if fallback is Node and (fallback as Node).is_inside_tree():
		var f := UIKit.first_focusable(fallback as Node)
		if can_focus(f):
			f.grab_focus()


## A node added next to an open modal (e.g. the Späti appearing behind the
## pause menu) must not take focus either; it is released with that modal.
static func block_if_covered(c: Control) -> void:
	var p := c.get_parent()
	if p == null:
		return
	for s in p.get_children():
		if s == c or not (s is Control) or not s.has_meta("nav_blocked") or (s as Node).is_queued_for_deletion():
			continue
		var blocked: Array = s.get_meta("nav_blocked")
		blocked.append([c, c.focus_behavior_recursive])
		c.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		return


# --- Widgets ------------------------------------------------------------------

## Disabled buttons below `root` stop taking focus (and get it back when they
## are enabled again). Call after building or toggling `disabled`.
static func sync_disabled(root: Node) -> void:
	if root is BaseButton:
		var b := root as BaseButton
		if b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.set_meta("nav_focus_mode", b.focus_mode)
			b.focus_mode = Control.FOCUS_NONE
		elif not b.disabled and b.has_meta("nav_focus_mode"):
			b.focus_mode = int(b.get_meta("nav_focus_mode"))
			b.remove_meta("nav_focus_mode")
	for ch in root.get_children():
		sync_disabled(ch)


## Left/right (D-pad, stick, arrow keys) step through the items, skipping
## disabled ones; A / Enter still opens the list.
static func step_option(ob: OptionButton) -> void:
	ob.gui_input.connect(func(ev: InputEvent) -> void:
		var d := 0
		if ev.is_action_pressed("ui_left", true):
			d = -1
		elif ev.is_action_pressed("ui_right", true):
			d = 1
		if d == 0 or ob.item_count == 0:
			return
		ob.accept_event()
		var i := ob.selected
		for _n in ob.item_count:
			i = posmod(i + d, ob.item_count)
			if not ob.is_item_disabled(i):
				break
		if i != ob.selected and not ob.is_item_disabled(i):
			ob.select(i)
			ob.item_selected.emit(i)
			UIApi.sfx("ui_click"))


## Scrolls `s` with the right stick (and with up/down when `ui_axis`, for
## screens without anything else to navigate). Call from _process.
static func stick_scroll(s: ScrollContainer, delta: float, ui_axis := false, speed := 700.0) -> void:
	if s == null or not is_instance_valid(s) or not s.is_visible_in_tree():
		return
	var a := 0.0
	if InputMap.has_action("ui_scroll_up") and InputMap.has_action("ui_scroll_down"):
		a = Input.get_axis("ui_scroll_up", "ui_scroll_down")
	if ui_axis and absf(a) < 0.1:
		a = Input.get_axis("ui_up", "ui_down")
	if absf(a) > 0.1:
		s.scroll_vertical += int(a * speed * delta)
