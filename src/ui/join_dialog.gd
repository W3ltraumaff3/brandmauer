class_name JoinDialog
extends UIDialog
## "Koop beitreten": IP/port by hand, or click a game found in the LAN.

var player_name := ""

var _ip: LineEdit
var _port: SpinBox
var _lan_list: VBoxContainer
var _status: Label
var _join_btn: Button
var _cancel_btn: Button


func _init() -> void:
	width = 660.0


func build() -> void:
	auto_focus = false
	content.add_child(UIKit.heading(tr("JOIN_TITLE"), 36))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	grid.add_child(UIKit.label(tr("JOIN_IP"), 22))
	_ip = LineEdit.new()
	_ip.name = "ip"
	_ip.text = str(UIApi.option("last_ip", "127.0.0.1"))
	_ip.placeholder_text = "192.168.0.23"
	_ip.size_flags_horizontal = SIZE_EXPAND_FILL
	_ip.text_submitted.connect(func(_t: String) -> void: _on_join())
	grid.add_child(_ip)
	grid.add_child(UIKit.label(tr("JOIN_PORT"), 22))
	_port = SpinBox.new()
	_port.name = "port"
	_port.min_value = 1024
	_port.max_value = 65535
	_port.value = int(UIApi.option("last_port", UIApi.port()))
	_port.custom_minimum_size.x = 160
	grid.add_child(_port)
	content.add_child(grid)

	content.add_child(UIKit.label(tr("JOIN_LAN"), 22, UITheme.INK_SOFT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var lan_card := UIKit.card(UITheme.PAPER_DARK, UITheme.INK_SOFT, 0.0, 1)
	lan_card.add_child(scroll)
	_lan_list = UIKit.vbox(6)
	_lan_list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_lan_list)
	content.add_child(lan_card)

	_status = UIKit.para("", 20, UITheme.RED)
	content.add_child(_status)

	var row := UIKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_END
	_cancel_btn = UIKit.button(tr("UI_CANCEL"), close)
	_cancel_btn.name = "cancel"
	row.add_child(_cancel_btn)
	_join_btn = UIKit.button(tr("JOIN_GO"), _on_join)
	_join_btn.name = "join"
	row.add_child(_join_btn)
	content.add_child(row)

	var net := UIApi.net()
	UIApi.connect_opt(net, "lan_games_changed", _refresh_lan)
	UIApi.connect_opt(net, "connection_failed", _on_failed)
	UIApi.connect_opt(net, "disconnected", _on_failed)
	UIApi.call_opt(net, "start_lan_discovery")
	_refresh_lan()
	UIKit.focus_later(_join_btn)


func _exit_tree() -> void:
	var net := UIApi.net()
	UIApi.disconnect_opt(net, "lan_games_changed", _refresh_lan)
	UIApi.disconnect_opt(net, "connection_failed", _on_failed)
	UIApi.disconnect_opt(net, "disconnected", _on_failed)
	UIApi.call_opt(net, "stop_lan_discovery")


func _refresh_lan() -> void:
	UIKit.clear(_lan_list)
	var games = UIApi.net_value("lan_games", [])
	if not games is Array or games.is_empty():
		_lan_list.add_child(UIKit.para(tr("JOIN_LAN_EMPTY"), 18, UITheme.GREY))
		return
	for g in games:
		if not g is Dictionary:
			continue
		var text := tr("JOIN_LAN_ENTRY").format({
			"name": str(g.get("name", "?")), "players": int(g.get("players", 0)),
			"ip": str(g.get("ip", "")), "port": int(g.get("port", UIApi.port()))})
		var b := UIKit.button(text, _join_lan.bind(g), 20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		_lan_list.add_child(b)


func _join_lan(g: Dictionary) -> void:
	_ip.text = str(g.get("ip", ""))
	_port.value = int(g.get("port", UIApi.port()))
	_on_join()


func _on_join() -> void:
	var ip := _ip.text.strip_edges()
	if ip == "":
		_status.text = tr("JOIN_NO_IP")
		UIApi.sfx("error")
		return
	var g := UIApi.game()
	if g == null or not g.has_method("open_join"):
		_status.text = tr("UI_NOT_READY")
		return
	UIApi.set_option("last_ip", ip)
	UIApi.set_option("last_port", int(_port.value))
	_status.add_theme_color_override("font_color", UITheme.INK_SOFT)
	_status.text = tr("JOIN_CONNECTING")
	_join_btn.disabled = true
	if _join_btn.has_focus():
		_cancel_btn.grab_focus()  # focus never rests on a disabled button
	UINav.sync_disabled(_join_btn)
	UIApi.call_opt(g, "open_join", [ip, int(_port.value), player_name])


func _on_failed(reason: String = "") -> void:
	if not is_inside_tree():
		return
	_join_btn.disabled = false
	UINav.sync_disabled(_join_btn)
	UIKit.focus_later(_join_btn)
	_status.add_theme_color_override("font_color", UITheme.RED)
	_status.text = tr(reason) if reason != "" else tr("JOIN_FAILED")
