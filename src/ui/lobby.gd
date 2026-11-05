class_name Lobby
extends UIScreen
## Lobby for solo, host and client: players, character choice, Organisation,
## Umfrage level, ready/start. Reads Net.lobby/org/difficulty, live via
## Net.lobby_changed.

var _players_box: VBoxContainer
var _char_buttons := {}         # char_id -> Button
var _detail: VBoxContainer
var _detail_id := ""
var _org_pick: OptionButton
var _org_label: Label
var _org_desc: Label
var _diff_pick: OptionButton
var _diff_label: Label
var _diff_desc: Label
var _retry_check: CheckBox
var _wave_retry_check: CheckBox
var _continue_btn: Button
var _start_armed := false        # a saved run exists: "Los" asks for a second press (D-162)
var _conn_box: VBoxContainer
var _ready_btn: Button
var _start_btn: Button
var _wait_label: Label
var _mode_label: Label
var _detail_scroll: ScrollContainer
## LB / RB areas (D-124): left column and bottom row; the grid is _char_buttons.
var _settings_area: Control
var _bottom_area: Control


func _init() -> void:
	super()
	closable = false
	auto_focus = false


func build() -> void:
	var top := UIKit.hbox(16)
	top.add_child(UIKit.heading(tr("LOBBY_TITLE"), 42))
	_mode_label = UIKit.label("", 22, UITheme.INK_SOFT)
	_mode_label.size_flags_vertical = SIZE_SHRINK_END
	top.add_child(_mode_label)
	top.add_child(UIKit.spacer())
	if UIApi.is_host() and not UIApi.is_solo():
		_conn_box = UIKit.vbox(-4)
		_conn_box.size_flags_vertical = SIZE_SHRINK_CENTER
		top.add_child(UIKit.card_with(_conn_box, UITheme.PAPER_DARK, UITheme.INK_SOFT, 0.8))
	body.add_child(top)

	var main := UIKit.hbox(16)
	main.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(main)
	_settings_area = _build_left()
	main.add_child(_settings_area)
	main.add_child(_build_grid())
	main.add_child(_build_detail())

	var bottom := UIKit.hbox(14)
	_bottom_area = bottom
	bottom.add_child(UIKit.button("← " + tr("LOBBY_BACK"), _on_back, 22))
	bottom.add_child(UIKit.spacer())
	_wait_label = UIKit.label(tr("LOBBY_WAIT_HOST"), 20, UITheme.INK_SOFT)
	_wait_label.size_flags_vertical = SIZE_SHRINK_CENTER
	bottom.add_child(_wait_label)
	_ready_btn = UIKit.button(tr("LOBBY_READY"), _on_ready, 24)
	_ready_btn.toggle_mode = true
	_ready_btn.custom_minimum_size.x = 170
	bottom.add_child(_ready_btn)
	# The saved run of the host (GDD §17 "Weiterspielen").
	_continue_btn = UIKit.button("", _on_continue, 24)
	_continue_btn.name = "continue"
	_continue_btn.visible = false
	UIKit.ready_look(_continue_btn, true)
	bottom.add_child(_continue_btn)
	_start_btn = UIKit.button(tr("LOBBY_START"), _on_start, 28)
	_start_btn.custom_minimum_size.x = 220
	UIKit.tilt(_start_btn, -1.0)
	bottom.add_child(_start_btn)
	body.add_child(bottom)

	var net := UIApi.net()
	UIApi.connect_opt(net, "lobby_changed", refresh)
	UIApi.connect_opt(net, "returned_to_lobby", refresh)
	var mine := _my_entry()
	if str(mine.get("char", "")) == "" and not UIApi.lobby().is_empty():
		UIApi.call_opt(net, "set_char", [Content.CHAR_ORDER[0]])
	refresh()
	var focus_id := str(mine.get("char", Content.CHAR_ORDER[0]))
	if _char_buttons.has(focus_id):
		UIKit.focus_later((_char_buttons[focus_id] as Button))


func _exit_tree() -> void:
	var net := UIApi.net()
	UIApi.disconnect_opt(net, "lobby_changed", refresh)
	UIApi.disconnect_opt(net, "returned_to_lobby", refresh)


# --- Build ------------------------------------------------------------------

func _section(title: String, parent: Container, degrees := 0.0) -> VBoxContainer:
	var c := UIKit.card(UITheme.PAPER, UITheme.INK, degrees)
	var v := UIKit.vbox(4)
	v.add_child(UIKit.label(title, 22, UITheme.RED))
	c.add_child(v)
	parent.add_child(c)
	return v


func _build_left() -> Control:
	var col := UIKit.vbox(10)
	col.custom_minimum_size.x = 320
	_players_box = UIKit.vbox(2)
	_section(tr("LOBBY_PLAYERS"), col, -0.8).add_child(_players_box)

	var org := _section(tr("LOBBY_ORG"), col, 0.6)
	if UIApi.is_host():
		_org_pick = OptionButton.new()
		for id in Content.ORG_ORDER:
			_org_pick.add_item(UIKit.content_text("ORG", id))
		_org_pick.name = "org_pick"
		_org_pick.item_selected.connect(_on_org)
		org.add_child(_org_pick)
	else:
		_org_label = UIKit.label("", 24)
		org.add_child(_org_label)
	_org_desc = UIKit.para("", 16, UITheme.INK_SOFT)
	org.add_child(_org_desc)

	var diff := _section(tr("LOBBY_DIFF"), col, -0.5)
	if UIApi.is_host():
		# Every Umfrage level from the start (balancing.md §3).
		_diff_pick = OptionButton.new()
		for i in Content.DIFFICULTY_PERCENT.size():
			_diff_pick.add_item(_diff_name(i), i)
		_diff_pick.name = "diff_pick"
		_diff_pick.item_selected.connect(_on_diff)
		diff.add_child(_diff_pick)
	else:
		_diff_label = UIKit.label("", 24)
		diff.add_child(_diff_label)
	_diff_desc = UIKit.para("", 16, UITheme.INK_SOFT)
	diff.add_child(_diff_desc)
	# Boss-Wiederholung (balancing.md §8): the host decides, everyone sees it.
	_retry_check = CheckBox.new()
	_retry_check.name = "boss_retry"
	_retry_check.text = tr("LOBBY_BOSS_RETRY")
	_retry_check.tooltip_text = tr("LOBBY_BOSS_RETRY_TIP")
	_retry_check.add_theme_font_size_override("font_size", 18)
	_retry_check.disabled = not UIApi.is_host()
	_retry_check.toggled.connect(func(on: bool) -> void: UIApi.call_opt(UIApi.net(), "set_boss_retry", [on]))
	diff.add_child(_retry_check)
	# Wellen-Wiederholung (balancing.md §8a, D-163).
	_wave_retry_check = CheckBox.new()
	_wave_retry_check.name = "wave_retry"
	_wave_retry_check.text = tr("LOBBY_WAVE_RETRY")
	_wave_retry_check.tooltip_text = tr("LOBBY_WAVE_RETRY_TIP")
	_wave_retry_check.add_theme_font_size_override("font_size", 18)
	_wave_retry_check.disabled = not UIApi.is_host()
	_wave_retry_check.toggled.connect(func(on: bool) -> void: UIApi.call_opt(UIApi.net(), "set_wave_retry", [on]))
	diff.add_child(_wave_retry_check)
	return col


func _build_grid() -> Control:
	var c := UIKit.card(UITheme.PAPER_DARK, UITheme.INK, 0.4)
	var v := UIKit.vbox(6)
	c.add_child(v)
	v.add_child(UIKit.label(tr("LOBBY_CHARS"), 22, UITheme.RED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for i in Content.CHAR_ORDER.size():
		var id: String = Content.CHAR_ORDER[i]
		var unlocked := UIApi.char_unlocked(id)
		var b := Button.new()
		b.name = "char_" + id
		b.custom_minimum_size = Vector2(136, 140)
		b.toggle_mode = true
		b.clip_text = true
		b.text = ""
		b.pressed.connect(_on_char.bind(id))
		b.focus_entered.connect(_show_detail.bind(id))
		b.mouse_entered.connect(_show_detail.bind(id))
		b.mouse_exited.connect(_show_selected)
		UIKit.tilt(b, UIKit.tilt_for(i, 0.7))
		# the real arena drawing at stage 4 (GDD §6), so lobby and arena look alike
		var portrait := CharPortrait.new()
		portrait.char_id = id
		portrait.stage = 4
		portrait.locked = not unlocked
		portrait.max_scale = 1.45
		portrait.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		portrait.offset_bottom = -28
		portrait.offset_top = 6
		portrait.offset_left = 6
		portrait.offset_right = -6
		b.add_child(portrait)
		var name_l := UIKit.label(UIKit.content_text("CHAR", id), 17, UITheme.INK if unlocked else UITheme.GREY, HORIZONTAL_ALIGNMENT_CENTER)
		UIKit.fit_label(name_l, 124, 12)
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_l.mouse_filter = MOUSE_FILTER_IGNORE
		name_l.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
		name_l.offset_top = -30
		name_l.offset_left = 4
		name_l.offset_right = -4
		b.add_child(name_l)
		if not unlocked:
			var st := UIKit.stamp(tr("LOBBY_LOCKED"), UITheme.RED, -14.0, 18)
			st.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
			st.position.y = 22
			b.add_child(st)
			b.tooltip_text = UIKit.ach_text(str(Content.CHARACTERS[id].get("unlock", "")), "DESC")
		_char_buttons[id] = b
		grid.add_child(b)
	_link_char_grid(grid)
	return c


## Explicit grid navigation: the cards are tilted, which confuses Godot's geometric
## focus search. Right at a row end wraps to the next row's first card, left at a row
## start wraps to the previous row's last card; up/down move by one row.
func _link_char_grid(grid: GridContainer) -> void:
	var cards: Array = grid.get_children()
	var cols := grid.columns
	for i in cards.size():
		var b := cards[i] as Control
		if i + 1 < cards.size():
			b.focus_neighbor_right = b.get_path_to(cards[i + 1])
		else:
			b.focus_neighbor_right = b.get_path_to(b)
		if i > 0:
			b.focus_neighbor_left = b.get_path_to(cards[i - 1])
		if i + cols < cards.size():
			b.focus_neighbor_bottom = b.get_path_to(cards[i + cols])
		elif i + cols < cols * ceili(cards.size() / float(cols)):
			b.focus_neighbor_bottom = b.get_path_to(cards[cards.size() - 1])
		if i - cols >= 0:
			b.focus_neighbor_top = b.get_path_to(cards[i - cols])
		b.focus_next = b.focus_neighbor_right
		if i > 0:
			b.focus_previous = b.focus_neighbor_left


func _build_detail() -> Control:
	var c := UIKit.card(UITheme.PAPER, UITheme.INK, -0.6)
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c.add_child(scroll)
	_detail_scroll = scroll
	_detail = UIKit.vbox(6)
	_detail.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_detail)
	return c


# --- Data -------------------------------------------------------------------

func _my_entry() -> Dictionary:
	return UIApi.by_peer(UIApi.lobby(), UIApi.local_id())


## Flavor line plus the real multipliers from Content.BALANCE (never stale).
func _diff_text(i: int) -> String:
	var m := Content.difficulty_mult(i)
	var stats := tr("LOBBY_DIFF_NORMAL") if i == 0 else tr("LOBBY_DIFF_STATS") % [
		roundi((float(m["hp"]) - 1.0) * 100.0), roundi((float(m["dmg"]) - 1.0) * 100.0), roundi((float(m["spawn"]) - 1.0) * 100.0)]
	return "%s %s" % [UIKit.trk("DIFF_%d_DESC" % i), stats]


func _diff_name(i: int) -> String:
	var t := UIKit.trk("DIFF_%d" % i)
	return t if t != "" else tr("LOBBY_DIFF_FALLBACK") % Content.DIFFICULTY_PERCENT[i]


func refresh() -> void:
	if not is_inside_tree():
		return
	var lobby := UIApi.lobby()
	var me := _my_entry()
	var my_char := str(me.get("char", ""))
	var host := UIApi.is_host()
	var solo := UIApi.is_solo()
	match UIApi.mode():
		"solo": _mode_label.text = tr("LOBBY_MODE_SOLO")
		"host": _mode_label.text = tr("LOBBY_MODE_HOST")
		"client": _mode_label.text = tr("LOBBY_MODE_CLIENT")
		_: _mode_label.text = ""

	# Players.
	UIKit.clear(_players_box)
	if lobby.is_empty():
		_players_box.add_child(UIKit.para(tr("LOBBY_NOBODY"), 18, UITheme.GREY))
	var all_ready := not lobby.is_empty()
	var peers := lobby.keys()
	peers.sort_custom(func(a, b) -> bool: return int(a) < int(b))
	for peer in peers:
		var p: Dictionary = lobby[peer] if lobby[peer] is Dictionary else {}
		var ready := bool(p.get("ready", false))
		all_ready = all_ready and ready
		var row := UIKit.hbox(6)
		var is_me := str(peer) == str(UIApi.local_id())
		var n := UIKit.label(str(p.get("name", "?")) + (" " + tr("LOBBY_YOU") if is_me else ""), 20)
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(n)
		var ch := str(p.get("char", ""))
		row.add_child(UIKit.label(UIKit.content_text("CHAR", ch) if ch != "" else "–", 17, UITheme.INK_SOFT))
		if not solo:
			row.add_child(UIKit.label(tr("LOBBY_IS_READY") if ready else tr("LOBBY_NOT_READY"), 17,
				UITheme.GREEN if ready else UITheme.GREY))
		_players_box.add_child(row)

	# Characters.
	for id in _char_buttons:
		(_char_buttons[id] as Button).set_pressed_no_signal(id == my_char)
	_show_selected()

	# Organisation.
	var org := str(UIApi.net_value("org", Content.ORG_ORDER[0]))
	var org_i := maxi(Content.ORG_ORDER.find(org), 0)
	if _org_pick:
		_org_pick.select(org_i)
	if _org_label:
		_org_label.text = UIKit.content_text("ORG", org)
	_org_desc.text = UIKit.content_text("ORG", org, "DESC")

	# Difficulty.
	var diff := clampi(int(UIApi.net_value("difficulty", 0)), 0, Content.DIFFICULTY_PERCENT.size() - 1)
	if _diff_pick:
		_diff_pick.select(diff)
	if _diff_label:
		_diff_label.text = _diff_name(diff)
	_diff_desc.text = _diff_text(diff)
	if _retry_check:
		_retry_check.set_pressed_no_signal(bool(UIApi.net_value("boss_retry", false)))
	if _wave_retry_check:
		_wave_retry_check.set_pressed_no_signal(bool(UIApi.net_value("wave_retry", false)))

	# Connection info (host in co-op).
	if _conn_box:
		UIKit.clear(_conn_box)
		var ips := _local_ips()
		_conn_box.add_child(UIKit.label(tr("LOBBY_IPS") % (", ".join(ips) if not ips.is_empty() else "–")
			+ "  ·  " + tr("LOBBY_PORT") % UIApi.port(), 17))
		var upnp := str(UIApi.net_value("upnp_status", ""))
		var upnp_text := tr("LOBBY_UPNP_OFF")
		var upnp_col := UITheme.INK_SOFT
		if upnp == "" and bool(UIApi.option("upnp", true)):
			upnp_text = tr("LOBBY_UPNP_PENDING")
		elif upnp == "ok":
			upnp_text = tr("LOBBY_UPNP_OK")
			upnp_col = UITheme.GREEN
		elif upnp.begins_with("failed"):
			upnp_text = tr("LOBBY_UPNP_FAILED") % upnp.trim_prefix("failed").trim_prefix(":").strip_edges()
			upnp_col = UITheme.RED
		var ul := UIKit.label(upnp_text, 16, upnp_col)
		ul.tooltip_text = upnp
		ul.mouse_filter = MOUSE_FILTER_PASS
		_conn_box.add_child(UIKit.fit_label(ul, 560, 12))

	# Ready / start.
	_ready_btn.visible = not solo
	_ready_btn.set_pressed_no_signal(bool(me.get("ready", false)))
	_ready_btn.text = tr("LOBBY_READY_ON") if _ready_btn.button_pressed else tr("LOBBY_READY")
	UIKit.ready_look(_ready_btn, _ready_btn.button_pressed)
	_ready_btn.tooltip_text = tr("READY_TAKE_BACK_TIP") if _ready_btn.button_pressed else ""
	_start_btn.visible = host
	_start_btn.disabled = not (solo or all_ready) or my_char == ""
	UINav.sync_disabled(_start_btn)
	var saved: Dictionary = UIApi.call_opt(UIApi.game(), "continue_info", [], {}) if host else {}
	_continue_btn.visible = not saved.is_empty()
	if not saved.is_empty():
		var fits := bool(UIApi.call_opt(UIApi.game(), "can_continue", [], false))
		_continue_btn.text = tr("LOBBY_CONTINUE") % int(saved["wave"])
		_continue_btn.disabled = not (solo or all_ready) or not fits
		_continue_btn.tooltip_text = MainMenu.continue_tip(saved) + " · " + (tr("LOBBY_CONTINUE_TIP") if fits
			else tr("LOBBY_CONTINUE_TOO_MANY") % (saved["players"] as Array).size())
		UINav.sync_disabled(_continue_btn)
	_start_btn.tooltip_text = tr("LOBBY_START_OVERWRITE_TIP") % int(saved["wave"]) if not saved.is_empty() else ""
	if saved.is_empty() and _start_armed:
		_start_armed = false
		_start_btn.text = tr("LOBBY_START")
		_start_btn.remove_theme_color_override("font_color")
	_wait_label.visible = not host
	if host and not solo and not all_ready:
		_wait_label.visible = true
		_wait_label.text = tr("LOBBY_WAIT_READY")
	elif not host:
		_wait_label.text = tr("LOBBY_WAIT_HOST")
	_link_bottom_row()


## Up from the bottom row goes to the character grid (not the narrow left
## column), so A on "Bereit"/"Los" is one stick flick away from the choice.
func _link_bottom_row() -> void:
	var mine := str(_my_entry().get("char", Content.CHAR_ORDER[0]))
	var target: Button = _char_buttons.get(mine, _char_buttons.get(Content.CHAR_ORDER[0])) as Button
	if target == null:
		return
	for b in [_ready_btn, _continue_btn, _start_btn]:
		(b as Control).focus_neighbor_top = (b as Control).get_path_to(target)


## LB / RB: jump to the previous / next area that has a usable control (D-124).
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var dir := 0
	if InputMap.has_action("ui_page_left") and event.is_action_pressed("ui_page_left"):
		dir = -1
	elif InputMap.has_action("ui_page_right") and event.is_action_pressed("ui_page_right"):
		dir = 1
	if dir == 0:
		return
	# Something above the lobby (an open picker list, a dialog) has focus: not ours.
	var f := get_viewport().gui_get_focus_owner()
	if f == null or not is_ancestor_of(f):
		return
	get_viewport().set_input_as_handled()
	var areas := [_settings_area, null, _bottom_area]   # null: the character grid
	var cur := 1
	for i in areas.size():
		var a: Control = areas[i]
		if a != null and a.is_ancestor_of(f):
			cur = i
	for step in range(1, areas.size()):
		var target := _area_target(areas[posmod(cur + dir * step, areas.size())])
		if target != null:
			UIApi.sfx("ui_click")
			target.grab_focus()
			return


func _area_target(area: Control) -> Control:
	if area == null:
		var mine := str(_my_entry().get("char", Content.CHAR_ORDER[0]))
		return _char_buttons.get(mine, _char_buttons.get(Content.CHAR_ORDER[0])) as Control
	if area == _bottom_area:
		for b in [_ready_btn, _continue_btn, _start_btn]:
			if UINav.can_focus(b):
				return b
	for c in area.find_children("*", "Control", true, false):
		if UINav.can_focus(c):
			return c
	return null


func _local_ips() -> Array:
	var out := []
	for a in IP.get_local_addresses():
		if a.contains(":") or a.begins_with("127.") or a.begins_with("169.254."):
			continue
		out.append(a)
	return out


# --- Detail -----------------------------------------------------------------

func _show_selected() -> void:
	var id := str(_my_entry().get("char", ""))
	if id == "":
		id = _detail_id if _detail_id != "" else Content.CHAR_ORDER[0]
	_show_detail(id)


func _show_detail(id: String) -> void:
	if not Content.CHARACTERS.has(id) or _detail == null:
		return
	_detail_id = id
	UIKit.clear(_detail)
	var c: Dictionary = Content.CHARACTERS[id]
	var unlocked := UIApi.char_unlocked(id)
	_detail.add_child(UIKit.heading(UIKit.content_text("CHAR", id), 30, UITheme.INK if unlocked else UITheme.GREY))
	if not unlocked:
		var how := UIKit.ach_text(str(c.get("unlock", "")), "DESC")
		_detail.add_child(UIKit.para(tr("LOBBY_UNLOCK_HOW") % how, 18, UITheme.RED))
	_detail.add_child(UIKit.para(UIKit.content_text("CHAR", id, "DESC"), 18))

	var w := str(c.get("weapon", ""))
	if w != "":
		var wl := UIKit.label(tr("LOBBY_START_WEAPON") % UIKit.content_text("WEAPON", w), 19, UITheme.RED)
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(wl)
		var wd := UIKit.content_text("WEAPON", w, "DESC")
		if wd != "":
			_detail.add_child(UIKit.para(wd, 16, UITheme.INK_SOFT))

	var ult := str(c.get("ult", ""))
	if ult != "":
		var ul := UIKit.label(tr("LOBBY_ULT") % UIKit.content_text("ULT", ult), 19, UITheme.RED)
		ul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_detail.add_child(ul)
		var ud := UIKit.content_text("ULT", ult, "DESC")
		if ud != "":
			_detail.add_child(UIKit.para(ud, 16, UITheme.INK_SOFT))
		var hint := UIKit.label("", 14, UITheme.GREY)
		InputGlyphs.bind(hint, "text", func() -> String: return InputGlyphs.fmt("LOBBY_ULT_HINT", ["ultimate"]))
		_detail.add_child(hint)

	var mods: Dictionary = c.get("mods", {})
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 12)
	for stat in mods:
		var v := float(mods[stat])
		flow.add_child(UIKit.label("%s %s" % [UIKit.signed(v), UIKit.stat_name(stat)], 17, UITheme.GREEN if v > 0 else UITheme.RED))
	if c.has("start_pfand"):
		flow.add_child(UIKit.label(tr("LOBBY_EXTRA_PFAND") % int(c["start_pfand"]), 17, UITheme.GREEN))
	if c.has("free_rerolls"):
		flow.add_child(UIKit.label(tr("LOBBY_EXTRA_REROLLS") % int(c["free_rerolls"]), 17, UITheme.GREEN))
	if c.has("max_weapons"):
		flow.add_child(UIKit.label(tr("LOBBY_EXTRA_SLOTS") % int(c["max_weapons"]), 17, UITheme.GREEN))
	if flow.get_child_count() > 0:
		_detail.add_child(flow)

	var qids := Quotes.ids_for("freischalt_karte:" + id)
	if not qids.is_empty():
		var clip := UIKit.clipping(qids[0], tr("LOBBY_ANSWER_TO"), 1.0, 15)
		_detail.add_child(clip)


# --- Actions ----------------------------------------------------------------

## The character detail scrolls with the right stick.
func _process(delta: float) -> void:
	UINav.stick_scroll(_detail_scroll, delta)


func _on_char(id: String) -> void:
	if not UIApi.char_unlocked(id):
		UIApi.sfx("error")
		(_char_buttons[id] as Button).set_pressed_no_signal(false)
		_show_detail(id)
		return
	UIApi.sfx("ui_click")
	UIApi.call_opt(UIApi.net(), "set_char", [id])
	if UIApi.preview_lobby.has(UIApi.local_id()):
		UIApi.preview_lobby[UIApi.local_id()]["char"] = id
	refresh()


func _on_org(i: int) -> void:
	UIApi.call_opt(UIApi.net(), "set_org", [Content.ORG_ORDER[i]])
	_org_desc.text = UIKit.content_text("ORG", Content.ORG_ORDER[i], "DESC")


func _on_diff(i: int) -> void:
	UIApi.call_opt(UIApi.net(), "set_difficulty", [i])
	_diff_desc.text = _diff_text(i)


func _on_ready() -> void:
	UIApi.call_opt(UIApi.net(), "set_ready", [_ready_btn.button_pressed])
	_ready_btn.text = tr("LOBBY_READY_ON") if _ready_btn.button_pressed else tr("LOBBY_READY")
	UIKit.ready_look(_ready_btn, _ready_btn.button_pressed)


func _on_start() -> void:
	# A new run replaces the saved one: second press (D-162).
	if not _start_armed and not (UIApi.call_opt(UIApi.game(), "continue_info", [], {}) as Dictionary).is_empty():
		_start_armed = true
		_start_btn.text = tr("LOBBY_START_OVERWRITE")
		_start_btn.add_theme_color_override("font_color", UITheme.RED)
		return
	UIApi.call_opt(UIApi.game(), "start_run")


func _on_continue() -> void:
	if not bool(UIApi.call_opt(UIApi.game(), "continue_run", [], false)):
		ToastLayer.show_text(tr("MENU_CONTINUE_FAILED"))


func _on_back() -> void:
	var g := UIApi.game()
	if g and g.has_method("quit_to_menu"):
		g.call("quit_to_menu")
	else:
		ToastLayer.show_text(tr("UI_NOT_READY"))
