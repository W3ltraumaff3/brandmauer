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
		["MENU_CREDITS", _open.bind("credits")], ["MENU_QUIT", _on_quit],
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
