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
var _conn_box: VBoxContainer
var _ready_btn: Button
var _start_btn: Button
var _wait_label: Label
var _mode_label: Label


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
	main.add_child(_build_left())
	main.add_child(_build_grid())
	main.add_child(_build_detail())

	var bottom := UIKit.hbox(14)
	bottom.add_child(UIKit.button("← " + tr("LOBBY_BACK"), _on_back, 22))
	bottom.add_child(UIKit.spacer())
	_wait_label = UIKit.label(tr("LOBBY_WAIT_HOST"), 20, UITheme.INK_SOFT)
	_wait_label.size_flags_vertical = SIZE_SHRINK_CENTER
	bottom.add_child(_wait_label)
	_ready_btn = UIKit.button(tr("LOBBY_READY"), _on_ready, 24)
	_ready_btn.toggle_mode = true
	_ready_btn.custom_minimum_size.x = 170
	bottom.add_child(_ready_btn)
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
		(_char_buttons[focus_id] as Button).grab_focus.call_deferred()


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
		_org_pick.item_selected.connect(_on_org)
		org.add_child(_org_pick)
	else:
		_org_label = UIKit.label("", 24)
		org.add_child(_org_label)
	_org_desc = UIKit.para("", 16, UITheme.INK_SOFT)
	org.add_child(_org_desc)

	var diff := _section(tr("LOBBY_DIFF"), col, -0.5)
	var max_diff := clampi(int(UIApi.save_data().get("max_umfrage", 0)), 0, Content.DIFFICULTY_PERCENT.size() - 1)
	if UIApi.is_host():
		_diff_pick = OptionButton.new()
		for i in Content.DIFFICULTY_PERCENT.size():
			_diff_pick.add_item(_diff_name(i), i)
			if i > max_diff:
				_diff_pick.set_item_disabled(i, true)
				_diff_pick.set_item_text(i, _diff_name(i) + "  " + tr("LOBBY_DIFF_LOCKED"))
		_diff_pick.item_selected.connect(_on_diff)
		diff.add_child(_diff_pick)
	else:
		_diff_label = UIKit.label("", 24)
		diff.add_child(_diff_label)
	_diff_desc = UIKit.para("", 16, UITheme.INK_SOFT)
	diff.add_child(_diff_desc)
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
		b.custom_minimum_size = Vector2(136, 140)
		b.toggle_mode = true
		b.clip_text = true
		b.text = ""
		b.pressed.connect(_on_char.bind(id))
		b.focus_entered.connect(_show_detail.bind(id))
		b.mouse_entered.connect(_show_detail.bind(id))
		b.mouse_exited.connect(_show_selected)
		UIKit.tilt(b, UIKit.tilt_for(i, 0.7))
		var doodle := CharDoodle.new()
		doodle.char_id = id
		doodle.locked = not unlocked
		doodle.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		doodle.offset_bottom = -28
		doodle.offset_top = 4
		b.add_child(doodle)
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
	return c


func _build_detail() -> Control:
	var c := UIKit.card(UITheme.PAPER, UITheme.INK, -0.6)
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c.add_child(scroll)
	_detail = UIKit.vbox(6)
	_detail.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_detail)
	return c


# --- Data -------------------------------------------------------------------

func _my_entry() -> Dictionary:
	return UIApi.by_peer(UIApi.lobby(), UIApi.local_id())


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
	_diff_desc.text = UIKit.trk("DIFF_%d_DESC" % diff)

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
	_start_btn.visible = host
	_start_btn.disabled = not (solo or all_ready) or my_char == ""
	_wait_label.visible = not host
	if host and not solo and not all_ready:
		_wait_label.visible = true
		_wait_label.text = tr("LOBBY_WAIT_READY")
	elif not host:
		_wait_label.text = tr("LOBBY_WAIT_HOST")


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
	_diff_desc.text = UIKit.trk("DIFF_%d_DESC" % i)


func _on_ready() -> void:
	UIApi.call_opt(UIApi.net(), "set_ready", [_ready_btn.button_pressed])
	_ready_btn.text = tr("LOBBY_READY_ON") if _ready_btn.button_pressed else tr("LOBBY_READY")


func _on_start() -> void:
	UIApi.call_opt(UIApi.game(), "start_run")


func _on_back() -> void:
	var g := UIApi.game()
	if g and g.has_method("quit_to_menu"):
		g.call("quit_to_menu")
	else:
		ToastLayer.show_text(tr("UI_NOT_READY"))
