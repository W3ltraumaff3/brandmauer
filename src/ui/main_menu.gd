class_name MainMenu
extends UIScreen
## Main menu: wall logo, mode buttons, player name, a random real quote.
## Easter egg: typing BLACKROCK anywhere turns all Pfand into shares.

const EGG := "BLACKROCK"

var _name_edit: LineEdit
var _typed := ""
var _first_button: Button


func _init() -> void:
	super()
	closable = false


func build() -> void:
	body.add_theme_constant_override("separation", 6)
	var title := WallTitle.new()
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(title)
	var sub := UIKit.label(tr("MENU_SUBTITLE"), 22, UITheme.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(sub)

	# A co-op run this machine left by crashing or losing the connection (networking.md §7.5).
	var rejoin = UIApi.call_opt(UIApi.save_node(), "rejoin_info", [], {})
	if rejoin is Dictionary and not (rejoin as Dictionary).is_empty():
		var rb := UIKit.button(tr("MENU_REJOIN"), _on_rejoin, 30)
		rb.name = "rejoin"
		rb.custom_minimum_size = Vector2(514, 56)
		rb.tooltip_text = tr("MENU_REJOIN_TIP") % ("%s:%d" % [rejoin["ip"], int(rejoin["port"])])
		UIKit.ready_look(rb, true)
		UIKit.tilt(rb, -0.8)
		var rc := CenterContainer.new()
		rc.add_child(rb)
		body.add_child(rc)
		focus_target = rb
		# A failed rejoin keeps this menu open (main.gd); Game shows the reason.
		UIApi.connect_opt(UIApi.net(), "disconnected", _on_rejoin_failed)

	# The saved run of this machine (GDD §17 "Weiterspielen", D-162).
	var cont = UIApi.call_opt(UIApi.game(), "continue_info", [], {})
	if cont is Dictionary and not (cont as Dictionary).is_empty():
		var cb := UIKit.button(tr("MENU_CONTINUE") % int(cont["wave"]), _on_continue, 30)
		cb.name = "continue"
		cb.custom_minimum_size = Vector2(514, 56)
		cb.tooltip_text = continue_tip(cont)
		UIKit.ready_look(cb, true)
		UIKit.tilt(cb, 0.6)
		var cc := CenterContainer.new()
		cc.add_child(cb)
		body.add_child(cc)
		if focus_target == null:
			focus_target = cb

	var row := UIKit.hbox(40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = SIZE_EXPAND | SIZE_SHRINK_CENTER
	body.add_child(row)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 14)
	buttons.add_theme_constant_override("v_separation", 10)
	row.add_child(buttons)
	var entries := [
		["MENU_SOLO", _on_solo], ["MENU_HOST", _on_host],
		["MENU_JOIN", _on_join], ["MENU_ALBUM", _open.bind("album")],
		["MENU_ACHIEVEMENTS", _open.bind("achievements")], ["MENU_OPTIONS", _open.bind("options")],
		["MENU_CREDITS", _open.bind("credits")], ["MENU_BUG", _on_bug], ["MENU_QUIT", _on_quit],
	]
	for i in entries.size():
		var b := UIKit.button(tr(entries[i][0]), entries[i][1], 26)
		b.custom_minimum_size = Vector2(250, 50)
		UIKit.tilt(b, UIKit.tilt_for(i, 0.5))
		if i == 0:
			b.add_theme_font_size_override("font_size", 30)
			_first_button = b
		buttons.add_child(b)

	var side := UIKit.vbox(10)
	side.custom_minimum_size.x = 330
	row.add_child(side)
	var name_card := UIKit.card(UITheme.PAPER, UITheme.INK, 1.2)
	var nv := UIKit.vbox(4)
	name_card.add_child(nv)
	nv.add_child(UIKit.label(tr("MENU_NAME"), 20, UITheme.INK_SOFT))
	_name_edit = LineEdit.new()
	_name_edit.text = str(UIApi.option("name", tr("MENU_DEFAULT_NAME")))
	_name_edit.max_length = 20
	_name_edit.placeholder_text = tr("MENU_DEFAULT_NAME")
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.text_changed.connect(func(t: String) -> void: UIApi.set_option("name", t.strip_edges()))
	nv.add_child(_name_edit)
	side.add_child(name_card)

	var stats: Dictionary = UIApi.save_data().get("stats", {})
	var stat_card := UIKit.card(UITheme.PAPER_DARK, UITheme.INK_SOFT, -1.0)
	var sv := UIKit.vbox(0)
	stat_card.add_child(sv)
	sv.add_child(UIKit.label(tr("MENU_RECORD"), 20, UITheme.INK_SOFT))
	sv.add_child(UIKit.label(tr("MENU_RECORD_LINE").format({
		"runs": stats.get("runs", 0), "wins": stats.get("wins", 0), "wave": stats.get("best_wave", 0)}), 20))
	var umfrage: int = Content.DIFFICULTY_PERCENT[clampi(int(UIApi.save_data().get("max_umfrage", 0)), 0, Content.DIFFICULTY_PERCENT.size() - 1)]
	sv.add_child(UIKit.label(tr("MENU_RECORD_UMFRAGE") % umfrage, 20))
	side.add_child(stat_card)

	var qid := UIKit.pick_quote("startbildschirm", 230)
	if qid == "":
		qid = UIKit.pick_quote("ladebildschirm", 230)
	if qid != "":
		var clip := UIKit.clipping(qid, tr("MENU_QUOTE_HEADER"), -0.6, 16)
		clip.custom_minimum_size.x = 880
		var center := CenterContainer.new()
		center.add_child(clip)
		body.add_child(center)

	var ver := UIKit.label("v" + str(ProjectSettings.get_setting("application/config/version", "0")), 14, UITheme.GREY)
	ver.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	ver.grow_horizontal = GROW_DIRECTION_BEGIN
	ver.grow_vertical = GROW_DIRECTION_BEGIN
	ver.position -= Vector2(12, 6)
	add_child(ver)


func _player_name() -> String:
	var n := _name_edit.text.strip_edges() if _name_edit else ""
	if n == "":
		n = tr("MENU_DEFAULT_NAME")
	UIApi.set_option("name", n)
	return n


func _on_solo() -> void:
	var g := UIApi.game()
	if g == null or not g.has_method("open_solo"):
		ToastLayer.show_text(tr("UI_NOT_READY"))
		return
	UIApi.call_opt(g, "open_solo", [_player_name()])


## "Weiter mit Welle 7 · Umfrage 20 % · Gewerkschaft · Oma (Ben), Antifa (Lea)"
static func continue_tip(info: Dictionary) -> String:
	var who := []
	for sp in info.get("players", []):
		who.append("%s (%s)" % [UIKit.content_text("CHAR", str(sp["char"])), str(sp["name"])])
	var lvl := clampi(int(info.get("difficulty", 0)), 0, Content.DIFFICULTY_PERCENT.size() - 1)
	var where := TranslationServer.translate("MENU_CONTINUE_SHOP" if info.get("resume", "") == "shop" else "MENU_CONTINUE_WAVE")
	return TranslationServer.translate("MENU_CONTINUE_TIP").format({
		"where": where % int(info.get("wave", 1)), "umfrage": Content.DIFFICULTY_PERCENT[lvl],
		"org": UIKit.content_text("ORG", str(info.get("org", ""))), "players": ", ".join(who)})


## One player: straight into the run. Co-op: host dialog, then the lobby ("Fortsetzen").
func _on_continue() -> void:
	_player_name()
	var g := UIApi.game()
	var info = UIApi.call_opt(g, "continue_info", [], {})
	if not (info is Dictionary) or (info as Dictionary).is_empty():
		ToastLayer.show_text(tr("MENU_CONTINUE_FAILED"))
		return
	if (info["players"] as Array).size() == 1:
		if not bool(UIApi.call_opt(g, "open_continue", [], false)):
			ToastLayer.show_text(tr("MENU_CONTINUE_FAILED"))
		return
	var dlg := HostDialog.new()
	dlg.confirmed.connect(_do_continue_host)
	_push(dlg)


func _do_continue_host(upnp: bool) -> void:
	UIApi.call_opt(UIApi.game(), "open_continue_host", [_player_name(), upnp])


func _on_rejoin_failed(_reason: String) -> void:
	_drop_rejoin.call_deferred()


func _drop_rejoin() -> void:
	var b := find_child("rejoin", true, false) as Button
	if b == null or not is_inside_tree():
		return
	b.get_parent().queue_free()
	UIKit.focus_later(_first_button)


func _on_rejoin() -> void:
	if bool(UIApi.call_opt(UIApi.net(), "is_reconnecting", [], false)):
		return  # already on its way (button stays focusable for the gamepad)
	var b := find_child("rejoin", true, false) as Button
	if not bool(UIApi.call_opt(UIApi.game(), "open_rejoin", [], false)):
		ToastLayer.show_text(tr("NET_ERR_SESSION"))
		if b:
			b.get_parent().queue_free()
			UIKit.focus_later(_first_button)
		return
	if b:
		b.text = tr("MENU_REJOIN_CONNECTING")


func _on_host() -> void:
	var dlg := HostDialog.new()
	dlg.confirmed.connect(_do_host)
	_push(dlg)


func _do_host(upnp: bool) -> void:
	var g := UIApi.game()
	if g == null or not g.has_method("open_host"):
		ToastLayer.show_text(tr("UI_NOT_READY"))
		return
	UIApi.call_opt(g, "open_host", [_player_name(), upnp])


func _on_join() -> void:
	var dlg := JoinDialog.new()
	dlg.player_name = _player_name()
	_push(dlg)


func _open(which: String) -> void:
	var s: Control
	match which:
		"album": s = Album.new()
		"achievements": s = AchievementsScreen.new()
		"options": s = OptionsScreen.new()
		"credits": s = CreditsScreen.new()
	if s:
		_push(s)


func _push(overlay: Control) -> void:
	var from := get_viewport().gui_get_focus_owner()
	add_child(overlay)
	overlay.tree_exited.connect(_on_overlay_closed.bind(from))


func _on_overlay_closed(from: Control) -> void:
	if not is_inside_tree():
		return
	if _name_edit:
		_name_edit.text = str(UIApi.option("name", _name_edit.text))
	if from and is_instance_valid(from) and from.is_inside_tree():
		UIKit.focus_later(from)
	elif _first_button:
		UIKit.focus_later(_first_button)


func _on_quit() -> void:
	get_tree().quit()


const BUG_URL := "https://github.com/W3ltraumaff3/brandmauer/issues/new?template=bug_report.yml"


func _on_bug() -> void:
	OS.shell_open(BUG_URL)


func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or k.unicode == 0:
		return
	_typed = (_typed + char(k.unicode).to_upper()).right(EGG.length())
	if _typed == EGG:
		_typed = ""
		var g := UIApi.game()
		if g and UIApi.prop(g, "blackrock", null) != null:
			g.set("blackrock", true)
		ToastLayer.show_text(tr("MENU_BLACKROCK"), 5.0)
