extends SceneTree
## Gamepad navigation check (GDD §19b). Opens every menu screen with the fake
## data of tools/ui_preview.gd, drives it with simulated gamepad input
## (Input.parse_input_event: D-pad, A, B, LB/RB, sticks) and asserts that
## focus is never lost, never rests on a hidden or disabled control, stays
## inside open dialogs, and that B closes dialogs and restores focus.
##   godot --path . -s res://tools/gamepad_nav_check.gd [--headless]
## Prints one line per screen; exit code 1 if anything failed.

const Preview := preload("res://tools/ui_preview.gd")
const DIRS := {"u": JOY_BUTTON_DPAD_UP, "d": JOY_BUTTON_DPAD_DOWN, "l": JOY_BUTTON_DPAD_LEFT, "r": JOY_BUTTON_DPAD_RIGHT}

var _rows := []
var _screen := ""
var _errors: Array[String] = []
var _notes: Array[String] = []
var _visited := {}


func _initialize() -> void:
	for n in ["Loc", "Save"]:
		if root.get_node_or_null(n) == null:
			var node: Node = load("res://src/autoload/%s.gd" % n.to_lower()).new()
			node.name = n
			root.add_child(node)
	var save := root.get_node_or_null("Save")
	if save and "persist" in save:
		save.set("persist", false)
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	root.theme = UITheme.get_theme()
	root.add_child(ToastLayer.new())
	UINav.install(root)
	await _frames(3)
	root.gui_focus_changed.connect(_on_focus_changed)
	_fake_save()

	await _check_glyphs()
	await _check_main_menu()
	await _check_menu_overlays()
	await _check_lobby("lobby (solo)", "solo", {1: {"name": "Genoss:in", "char": "oma", "ready": false}})
	await _check_lobby("lobby (host, not all ready)", "host", {
		1: {"name": "Kai", "char": "stadtbild", "ready": true},
		2: {"name": "Oma Inge", "char": "oma", "ready": false}})
	await _check_spaeti_levelup()
	await _check_spaeti_shop()
	await _check_spaeti_overlays()
	await _check_pause_over_spaeti()
	await _check_end()

	var failed := 0
	print("\n=== gamepad_nav_check ===")
	for r in _rows:
		print("%s  %-34s %s" % ["PASS" if r[1] else "FAIL", r[0], r[2]])
		if not r[1]:
			failed += 1
	print("%d screens, %d failed" % [_rows.size(), failed])
	quit(1 if failed > 0 else 0)


# --- Harness ------------------------------------------------------------------

func _fake_save() -> void:
	var save := root.get_node("Save")
	var ids := Quotes.album_ids()
	save.data["album"] = ids.slice(0, mini(24, ids.size()))
	save.data["achievements"] = {"ach_doep": true, "ach_180": true}
	save.data["max_umfrage"] = 2


func _begin(screen_name: String) -> void:
	_screen = screen_name
	_errors.clear()
	_notes.clear()
	_visited.clear()


func _end() -> void:
	var detail := "; ".join(_errors) if not _errors.is_empty() else "; ".join(_notes)
	_rows.append([_screen, _errors.is_empty(), detail])


func _fail(msg: String) -> void:
	if _errors.size() < 6:
		_errors.append(msg)


func _note(msg: String) -> void:
	_notes.append(msg)


func _on_focus_changed(c: Control) -> void:
	if _screen != "" and c != null and not UINav.can_focus(c):
		_fail("focus landed on hidden/disabled %s" % c.name)


func _frames(n := 2) -> void:
	for i in n:
		await process_frame


func _button(b: JoyButton, frames := 2) -> void:
	for pressed in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.device = 0
		ev.button_index = b
		ev.pressed = pressed
		ev.pressure = 1.0 if pressed else 0.0
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await process_frame
	await _frames(frames)


## Holds a stick axis for `frames` frames, then centers it.
func _axis(axis: JoyAxis, value: float, frames := 1) -> void:
	for v in [value, 0.0]:
		var ev := InputEventJoypadMotion.new()
		ev.device = 0
		ev.axis = axis
		ev.axis_value = v
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await _frames(frames if v != 0.0 else 2)


## Holds a D-pad button for `frames` frames (for polled scrolling).
func _hold(b: JoyButton, frames: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await _frames(frames)
	var up := InputEventJoypadButton.new()
	up.button_index = b
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await _frames(2)


func _focus() -> Control:
	return root.gui_get_focus_owner()


func _check_focus(where: String, inside: Node = null) -> Control:
	var f := _focus()
	if f == null:
		_fail("%s: focus lost" % where)
		return null
	if not UINav.can_focus(f):
		_fail("%s: focus on hidden/disabled %s" % [where, f.name])
	if inside != null and not inside.is_ancestor_of(f):
		_fail("%s: focus escaped to %s" % [where, f.name])
	_visited[f.get_instance_id()] = true
	return f


## Walks the D-pad sequence ("u", "d", "l", "r"); returns how many different
## controls had focus.
func _walk(seq: String, inside: Node) -> int:
	_visited.clear()
	_check_focus("walk start", inside)
	for ch in seq:
		await _button(DIRS[ch])
		_check_focus("walk '%s'" % ch, inside)
	return _visited.size()


func _expect_focus(where: String, expected: Control) -> void:
	var f := _check_focus(where)
	if expected != null and f != expected:
		_fail("%s: focus on %s, expected %s" % [where, f.name if f else "null", expected.name])


func _find(n: Node, node_name: String) -> Control:
	return n.find_child(node_name, true, false) as Control


func _find_text(n: Node, text: String) -> Button:
	for c in n.find_children("*", "Button", true, false):
		if (c as Button).text == text:
			return c as Button
	return null


func _gone(n) -> bool:
	return not is_instance_valid(n) or (n as Node).is_queued_for_deletion() or not (n as Node).is_inside_tree()


## B (ui_cancel) must close `overlay` and give focus back to `back_to`.
func _close_with_b(overlay: Node, back_to: Control, where := "B") -> void:
	await _button(JOY_BUTTON_B, 3)
	if not _gone(overlay):
		_fail("%s did not close %s" % [where, overlay.name])
		return
	await _frames(2)
	_expect_focus("after %s" % where, back_to)


func _free(n: Node) -> void:
	if is_instance_valid(n):
		n.queue_free()
	await _frames(3)


# --- Glyphs ---------------------------------------------------------------------

func _check_glyphs() -> void:
	_begin("input glyphs")
	await _button(JOY_BUTTON_X, 1)
	if not InputGlyphs.using_pad():
		_fail("gamepad input not detected")
	# Pin the Xbox style: a real PlayStation pad plugged into this PC would otherwise switch the labels.
	InputGlyphs.set_device(InputGlyphs.Device.PAD, "xbox")
	var pad := [InputGlyphs.label("ultimate"), InputGlyphs.label("streik"), InputGlyphs.label("pause"),
		InputGlyphs.label("ui_accept"), InputGlyphs.label("ui_cancel"), InputGlyphs.label("ui_page_left"),
		InputGlyphs.label("ui_page_right")]
	if pad != ["[X]", "[Y]", "[Start]", "[A]", "[B]", "[LB]", "[RB]"]:
		_fail("pad labels %s" % [pad])
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SHIFT
	key.keycode = KEY_SHIFT
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await _frames(1)
	var kb := [InputGlyphs.label("ultimate"), InputGlyphs.label("streik"), InputGlyphs.label("pause"),
		InputGlyphs.label("ui_accept"), InputGlyphs.label("ui_cancel")]
	if InputGlyphs.using_pad():
		_fail("keyboard input not detected")
	if kb != ["[Leertaste]", "[Q]", "[Esc]", "[Enter]", "[Esc]"]:
		_fail("keyboard labels %s" % [kb])
	key.pressed = false
	Input.parse_input_event(key)
	InputGlyphs.set_device(InputGlyphs.Device.PAD, "ps")
	var ps := [InputGlyphs.label("ultimate"), InputGlyphs.label("ui_accept"), InputGlyphs.label("ui_cancel")]
	if ps != ["[□]", "[✕]", "[○]"]:
		_fail("PlayStation labels %s" % [ps])
	if InputGlyphs.style_for("PS5 Controller") != "ps" or InputGlyphs.style_for("Xbox Series Controller") != "xbox":
		_fail("style_for")
	InputGlyphs.set_device(InputGlyphs.Device.PAD, "xbox")
	_note("pad %s / keyboard %s / PS %s" % [" ".join(pad), " ".join(kb), " ".join(ps)])
	_end()


# --- Main menu ------------------------------------------------------------------

func _check_main_menu() -> void:
	_begin("main menu")
	var menu := MainMenu.new()
	root.add_child(menu)
	await _frames(4)
	_expect_focus("open", _find_text(menu, TranslationServer.translate("MENU_SOLO")))
	var n := await _walk("rdddlluurrdlrrdd", menu)
	_note("%d controls reached" % n)
	if n < 5:
		_fail("only %d controls reached" % n)
	await _button(JOY_BUTTON_B)  # top-level screen: B does nothing, focus stays
	_check_focus("B on main menu", menu)
	# Mouse still works: click "Optionen" opens the overlay.
	var ob := _find_text(menu, TranslationServer.translate("MENU_OPTIONS"))
	await _click(ob)
	var overlay := menu.get_child(menu.get_child_count() - 1)
	if not (overlay is OptionsScreen):
		_fail("mouse click did not open Optionen")
	else:
		_note("mouse click opens Optionen")
		(overlay as OptionsScreen).close()
		await _frames(3)
	await _free(menu)
	_end()


func _click(b: Control) -> void:
	var pos := b.get_global_rect().get_center()
	var mm := InputEventMouseMotion.new()
	mm.position = pos
	mm.global_position = pos
	mm.relative = Vector2(10, 0)
	Input.parse_input_event(mm)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await process_frame
	await _frames(3)
	await _button(JOY_BUTTON_DPAD_UP, 0)  # back to pad mode (no-op on overlays)


## Every overlay/dialog of the main menu: open with A, navigate, close with B.
func _check_menu_overlays() -> void:
	var cases := [
		["host dialog", "MENU_HOST", "lrlrud", ""],
		["join dialog", "MENU_JOIN", "uuuudddlrrd", "ip"],
		["options", "MENU_OPTIONS", "dddddduuuuuuu", ""],
		["album", "MENU_ALBUM", "ddddddddddrrlluu", ""],
		["achievements", "MENU_ACHIEVEMENTS", "ddrdlluu", ""],
		["credits", "MENU_CREDITS", "ud", ""],
	]
	UIApi.preview_net = {"lan_games": [
		{"name": "Oma Inge", "ip": "192.168.178.23", "port": 24713, "players": 2},
		{"name": "Kiezkollektiv", "ip": "192.168.178.40", "port": 24713, "players": 1}]}
	for c in cases:
		_begin(str(c[0]))
		var menu := MainMenu.new()
		root.add_child(menu)
		await _frames(4)
		var opener := _find_text(menu, TranslationServer.translate(str(c[1])))
		opener.grab_focus()
		await _frames(1)
		await _button(JOY_BUTTON_A, 3)
		var overlay := menu.get_child(menu.get_child_count() - 1)
		if not (overlay is UIScreen or overlay is UIDialog):
			_fail("A did not open it")
			await _free(menu)
			_end()
			continue
		var first := _check_focus("open", overlay)
		_note("first focus: %s" % (first.name if first else "-"))
		var n := await _walk(str(c[2]), overlay)
		_note("%d controls reached" % n)
		await _overlay_extras(str(c[0]), overlay)
		if str(c[3]) != "":
			# B also closes while a text field has focus.
			var le := _find(overlay, str(c[3]))
			if le:
				le.grab_focus()
				await _frames(1)
		await _close_with_b(overlay, opener)
		await _free(menu)
		_end()
	UIApi.preview_net = {}


func _overlay_extras(which: String, overlay: Node) -> void:
	match which:
		"options":
			var music := _find(overlay, "music") as HSlider
			music.grab_focus()
			await _frames(1)
			var v0 := music.value
			await _button(JOY_BUTTON_DPAD_RIGHT)
			var v1 := music.value
			await _axis(JOY_AXIS_LEFT_X, -1.0)
			var v2 := music.value
			if not (v1 > v0 and v2 < v1):
				_fail("slider: D-pad %.2f->%.2f, stick ->%.2f" % [v0, v1, v2])
			else:
				_note("slider D-pad/stick ok")
			_expect_focus("slider stays focused", music)
			var tm := _find(overlay, "target_mode") as OptionButton
			tm.grab_focus()
			await _frames(1)
			var s0 := tm.selected
			await _button(JOY_BUTTON_DPAD_RIGHT)
			var s1 := tm.selected
			await _button(JOY_BUTTON_DPAD_LEFT)
			if s1 == s0 or tm.selected != s0:
				_fail("option button stepping %d->%d->%d" % [s0, s1, tm.selected])
			else:
				_note("option button stepping ok")
			UIApi.set_option("target_mode", 0)
		"album":
			var scroll := _find(overlay, "card_0").get_parent().get_parent().get_parent() as ScrollContainer
			var before := scroll.scroll_vertical if scroll else 0
			(_find(overlay, "card_0") as Control).grab_focus()
			await _frames(1)
			for i in 20:
				await _button(JOY_BUTTON_DPAD_DOWN, 1)
			_check_focus("album deep", overlay)
			if scroll and scroll.scroll_vertical <= before:
				_fail("list did not scroll with focus")
			else:
				_note("list follows focus (scroll %d)" % (scroll.scroll_vertical if scroll else -1))
			# Right stick scrolls the detail of a long, unlocked quote.
			var d := (overlay as Album)._detail_scroll
			var long_i := 0
			var ids := Quotes.album_ids()
			for i in mini(ids.size(), 24):
				if String(Quotes.get_quote(ids[i]).get("kontext", "")).length() > String(Quotes.get_quote(ids[long_i]).get("kontext", "")).length():
					long_i = i
			(_find(overlay, "card_%d" % long_i) as Control).grab_focus()
			await _frames(3)
			var bar := d.get_v_scroll_bar()
			await _axis(JOY_AXIS_RIGHT_Y, 1.0, 12)
			_check_focus("after right stick", overlay)
			if bar.max_value > bar.page + 1.0 and d.scroll_vertical <= 0:
				_fail("right stick did not scroll the detail")
			else:
				_note("detail right-stick scroll %d (max %d)" % [d.scroll_vertical, int(bar.max_value - bar.page)])
		"credits":
			var sc := (overlay as CreditsScreen)._scroll
			await _hold(JOY_BUTTON_DPAD_DOWN, 20)
			if sc.scroll_vertical <= 0:
				_fail("D-pad did not scroll the credits")
			else:
				_note("D-pad scrolls (%d px)" % sc.scroll_vertical)
			var s0 := sc.scroll_vertical
			await _axis(JOY_AXIS_RIGHT_Y, 1.0, 10)
			if sc.scroll_vertical <= s0:
				_fail("right stick did not scroll the credits")
		"join dialog":
			var ip := _find(overlay, "ip")
			ip.grab_focus()
			await _frames(1)
			await _button(JOY_BUTTON_DPAD_DOWN)
			var f := _check_focus("down from IP field", overlay)
			if f == ip:
				_fail("IP field traps the D-pad")
			var port := _find(overlay, "port") as SpinBox
			if port:
				port.get_line_edit().grab_focus()
				await _frames(1)
				await _button(JOY_BUTTON_DPAD_DOWN)
				var f2 := _check_focus("down from port", overlay)
				if f2 == port.get_line_edit():
					_note("port field: D-pad up/down changes the number (left/right leave)")
					await _button(JOY_BUTTON_DPAD_RIGHT)
					await _button(JOY_BUTTON_DPAD_DOWN)
					_check_focus("leave port", overlay)


# --- Lobby ------------------------------------------------------------------------

func _check_lobby(title: String, mode: String, lobby: Dictionary) -> void:
	_begin(title)
	UIApi.preview_mode = mode
	UIApi.preview_local_id = 1
	UIApi.preview_lobby = lobby
	UIApi.preview_net = {"org": "omas", "difficulty": 1}
	var l := Lobby.new()
	root.add_child(l)
	await _frames(4)
	var mine := str(UIApi.by_peer(lobby, 1).get("char", ""))
	_expect_focus("open", _find(l, "char_" + mine))
	await _check_char_grid(l)
	var n := await _walk("lllrrrrruuuddddddlllll", l)
	_note("%d controls reached" % n)
	# Picker: A opens the list, D-pad + A picks, B closes it.
	var pick := _find(l, "diff_pick") as OptionButton
	if pick:
		pick.grab_focus()
		await _frames(1)
		var s0 := pick.selected
		await _button(JOY_BUTTON_A, 3)
		if not pick.get_popup().visible:
			_fail("A did not open the Umfrage list")
		else:
			await _button(JOY_BUTTON_DPAD_UP, 2)
			await _button(JOY_BUTTON_A, 3)
			if pick.get_popup().visible:
				_fail("A did not pick in the list")
			if pick.selected == s0:
				_fail("D-pad + A did not change the Umfrage")
			else:
				_note("picker %d -> %d via list" % [s0, pick.selected])
			await _button(JOY_BUTTON_A, 3)
			await _button(JOY_BUTTON_B, 3)
			if pick.get_popup().visible:
				_fail("B did not close the list")
		await _frames(2)
		_check_focus("after picker", l)
	var start := _find_text(l, TranslationServer.translate("LOBBY_START"))
	if start and start.disabled:
		_note("start disabled -> skipped")
	await _free(l)
	_end()


## Character grid (GDD §19b): directions mean directions, read like text. Right at
## a row end goes to the next row's first card, left at a row start to the previous
## row's last card, up/down move by one row.
func _check_char_grid(l: Node) -> void:
	var ids := Content.CHAR_ORDER
	var cols := 3
	var wrong := 0
	for i in ids.size():
		var want := {"r": i + 1, "l": i - 1, "d": i + cols, "u": i - cols}
		for dir in want:
			var j: int = want[dir]
			if j < 0 or j >= ids.size():
				continue
			(_find(l, "char_" + ids[i]) as Control).grab_focus()
			await _frames(1)
			await _button(DIRS[dir], 1)
			var f := _focus()
			if f == null or f.name != "char_" + ids[j]:
				wrong += 1
				_fail("grid: '%s' from %s -> %s, expected %s" % [dir, ids[i], f.name if f else "null", ids[j]])
	if wrong == 0:
		_note("char grid directions ok")


# --- Späti --------------------------------------------------------------------------

func _spaeti(meta: Dictionary) -> SpaetiPanel:
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	var sp := SpaetiPanel.new()
	sp.preview_meta = meta
	root.add_child(sp)
	await _frames(5)
	return sp


func _check_spaeti_levelup() -> void:
	_begin("Späti (level-up)")
	var sp := await _spaeti(Preview._fake_meta(true))
	_expect_focus("open", _find(sp, "levelup_0"))
	var n := await _walk("rrrlllldddduuuurrrr", sp)
	_note("%d controls reached" % n)
	await _check_sections_closed(sp)
	await _free(sp)
	_end()


func _section_of(sp: Node, c: Control) -> String:
	var p: Node = c
	while p != null and p != sp:
		if String(p.name).begins_with("sec_"):
			return String(p.name).trim_prefix("sec_")
		p = p.get_parent()
	return "?"


func _check_spaeti_shop() -> void:
	_begin("Späti (shop, vote pending)")
	var shop := Preview._combine_meta()
	shop["kasse_enabled"] = true  # co-op: Koalitionskasse section
	var sp := await _spaeti(shop)
	var f := _check_focus("open", sp)
	_note("first focus %s" % (f.name if f else "-"))
	var n := await _walk("rrrrddddllllllddddrrrrrrrruuuuuuuuuulll", sp)
	_note("%d controls reached" % n)
	await _check_sections_closed(sp)
	# Bereit is disabled until the vote: must never get focus.
	var ready := _find(sp, "ready") as Button
	if ready and ready.disabled and ready.focus_mode != Control.FOCUS_NONE:
		_fail("disabled Bereit is focusable")
	# RB / LB cycle the sections.
	var order := []
	for i in 9:
		await _button(JOY_BUTTON_RIGHT_SHOULDER)
		var g := _check_focus("RB", sp)
		if g:
			order.append(_section_of(sp, g))
	await _button(JOY_BUTTON_LEFT_SHOULDER)
	var back := _check_focus("LB", sp)
	order.append("LB:" + (_section_of(sp, back) if back else "?"))
	_note("RB: " + " > ".join(order))
	for want in ["offers", "weapons", "items", "kasse", "wall", "vertrag", "stats"]:
		var sec := _find(sp, "sec_" + want)
		if sec != null and UIKit.first_focusable(sec) != null and not order.has(want):
			_fail("RB never reached %s" % want)
	# Tooltip on focus.
	var buy := _find(sp, "buy_0") as Control
	buy.grab_focus()
	await _frames(3)
	var tip := FocusTips.instance.shown_text() if FocusTips.instance else ""
	if tip == "":
		_fail("no focus tooltip on buy_0")
	else:
		_note("tooltip: '%s'" % tip.get_slice("\n", 0))
	var stat := _find(sp, "stat_crit") as Control
	stat.grab_focus()
	await _frames(3)
	if (FocusTips.instance.shown_text() if FocusTips.instance else "") == "":
		_fail("no focus tooltip on a stat")
	await _free(sp)
	_end()


## D-pad never leaves a Späti section (GDD §19b): from every focusable control of
## every section, each direction keeps focus inside that section.
func _check_sections_closed(sp: Node) -> void:
	var tested := 0
	var moved := 0
	for sec_name in SpaetiPanel.SECTIONS:
		var sec := _find(sp, sec_name)
		if sec == null or not sec.is_visible_in_tree():
			continue
		for c in sec.find_children("*", "Control", true, false):
			if not UINav.can_focus(c):
				continue
			for dir in DIRS:
				(c as Control).grab_focus()
				await _frames(1)
				await _button(DIRS[dir], 1)
				tested += 1
				var f := _focus()
				if f != c:
					moved += 1
				if f == null or _section_of(sp, f) != sec_name.trim_prefix("sec_"):
					_fail("'%s' from %s left %s (-> %s)" % [dir, c.name, sec_name, f.name if f else "null"])
	_note("%d section steps stayed inside (%d moved)" % [tested, moved])


func _check_spaeti_overlays() -> void:
	var cases := [
		["Späti sell confirmation", "sell_1", "ConfirmDialog", "lrlrud"],
		["Späti combine confirmation", "combine_0", "ConfirmDialog", "rlud"],
		["Späti discard dialog (x2)", "item_0", "DiscardDialog", "urrldrrlu"],
		["Späti discard dialog (x1)", "item_1", "DiscardDialog", "lrud"],
		["Späti statistics", "stats", "StatsPanel", "udlr"],
		["Späti options", "options", "OptionsScreen", "dddduuuu"],
	]
	for c in cases:
		_begin(str(c[0]))
		var meta := Preview._combine_meta()
		meta["players"][1]["items"] = ["solibutton", "solibutton", "thermoskanne"]
		var sp := await _spaeti(meta)
		var opener := _find(sp, str(c[1]))
		opener.grab_focus()
		await _frames(1)
		await _button(JOY_BUTTON_A, 3)
		var overlay := sp.get_child(sp.get_child_count() - 1)
		if overlay.get_class() == "" or not overlay.get_script() or not _is_kind(overlay, str(c[2])):
			_fail("A did not open %s (got %s)" % [c[2], overlay.name])
			await _free(sp)
			_end()
			continue
		_check_focus("open", overlay)
		var n := await _walk(str(c[3]), overlay)
		_note("%d controls reached" % n)
		# LB/RB must not move focus out of an open dialog.
		await _button(JOY_BUTTON_RIGHT_SHOULDER)
		_check_focus("RB in dialog", overlay)
		if str(c[2]) == "StatsPanel":
			await _hold(JOY_BUTTON_DPAD_DOWN, 10)
			_check_focus("scroll", overlay)
		if str(c[0]) == "Späti combine confirmation":
			# A on "Abbrechen" also closes (and restores focus).
			_find(overlay, "cancel").grab_focus()
			await _frames(1)
			await _button(JOY_BUTTON_A, 3)
			if not _gone(overlay):
				_fail("A on Abbrechen did not close")
			await _frames(2)
			_expect_focus("after Abbrechen", _find(sp, str(c[1])))
		else:
			await _close_with_b(overlay, _find(sp, str(c[1])))
		await _free(sp)
		_end()


func _is_kind(n: Node, kind: String) -> bool:
	match kind:
		"ConfirmDialog": return n is SpaetiPanel.ConfirmDialog
		"DiscardDialog": return n is SpaetiPanel.DiscardDialog
		"StatsPanel": return n is StatsPanel
		"OptionsScreen": return n is OptionsScreen
	return false


## Pause menu above the Späti in one layer, as in the run screen.
func _check_pause_over_spaeti() -> void:
	_begin("pause menu (over Späti)")
	UIApi.preview_mode = "solo"
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var sp := SpaetiPanel.new()
	sp.preview_meta = Preview._fake_meta(false)
	layer.add_child(sp)
	await _frames(5)
	var before := _check_focus("Späti before pause", sp)
	var pause := PauseMenu.new()
	pause.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(pause)
	await _frames(4)
	_check_focus("open", pause)
	var n := await _walk("dddddduuuuuuurlrl", pause)
	_note("%d controls reached" % n)
	await _button(JOY_BUTTON_RIGHT_SHOULDER)
	_check_focus("RB under pause", pause)
	# Optionen inside the pause menu: B closes only the options.
	var ob := _find_text(pause, TranslationServer.translate("MENU_OPTIONS"))
	ob.grab_focus()
	await _frames(1)
	await _button(JOY_BUTTON_A, 3)
	var opts := pause.get_child(pause.get_child_count() - 1)
	if not (opts is OptionsScreen):
		_fail("A did not open Optionen")
	else:
		_check_focus("options open", opts)
		await _close_with_b(opts, ob, "B in options")
	if _gone(pause):
		_fail("B in options also closed the pause menu")
	await _close_with_b(pause, before, "B (resume)")
	await _free(layer)
	_end()


# --- End screen --------------------------------------------------------------------

func _check_end() -> void:
	_begin("end screen")
	UIApi.preview_mode = "host"
	var e := EndScreen.new()
	e.preview_meta = Preview._fake_end_meta(true)
	root.add_child(e)
	await _frames(4)
	_expect_focus("open", _find(e, "to_lobby"))
	var n := await _walk("rlrluddr", e)
	_note("%d controls reached" % n)
	await _button(JOY_BUTTON_B)
	_check_focus("B on end screen", e)
	await _free(e)
	_end()
