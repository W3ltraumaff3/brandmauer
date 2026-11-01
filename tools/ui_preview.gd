extends SceneTree
## Renders every menu screen with fake data and saves PNG screenshots.
##   godot --path . -s res://tools/ui_preview.gd [-- <out_dir>] [-- only=<name>]
## Needs rendering, so do NOT pass --headless. Never writes the save file.

const DEFAULT_OUT := "C:/Users/Weltr/AppData/Local/Temp/claude/c--PythonProjekte-Rogue-Like-AnticapAntiFa/67c50bb6-ac99-4e3a-8940-ad9037ff683c/scratchpad/ui/"

var _out := DEFAULT_OUT
var _only := ""


func _initialize() -> void:
	# Autoloads are not registered for -s scripts; add the ones the UI needs.
	for n in ["Loc", "Save"]:
		if root.get_node_or_null(n) == null:
			var node: Node = load("res://src/autoload/%s.gd" % n.to_lower()).new()
			node.name = n
			root.add_child(node)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			_only = a.trim_prefix("only=")
		elif a != "":
			_out = a.trim_suffix("/") + "/"
	_run.call_deferred()


func _save_node() -> Node:
	return root.get_node("Save")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.theme = UITheme.get_theme()
	DirAccess.make_dir_recursive_absolute(_out)
	var toasts := ToastLayer.new()
	root.add_child(toasts)
	_fake_save()

	await _shot("01_main_menu", MainMenu.new())
	await _shot_menu_overlay("02_host_dialog", HostDialog.new())
	UIApi.preview_net = {"lan_games": [
		{"name": "Oma Inge", "ip": "192.168.178.23", "port": 24713, "players": 2},
		{"name": "Kiezkollektiv", "ip": "192.168.178.40", "port": 24713, "players": 1}]}
	await _shot_menu_overlay("03_join_dialog", JoinDialog.new())

	UIApi.preview_local_id = 1
	UIApi.preview_mode = "solo"
	UIApi.preview_lobby = {1: {"name": "Genoss*in", "char": "oma", "ready": false}}
	UIApi.preview_net = {"org": "omas", "difficulty": 1}
	await _shot("04_lobby_solo", Lobby.new())

	UIApi.preview_mode = "host"
	UIApi.preview_lobby = {
		1: {"name": "Kiezkollektiv-Kai", "char": "stadtbild", "ready": true},
		2: {"name": "Oma Inge", "char": "oma", "ready": true},
		3: {"name": "Lastenrad-Lea", "char": "lastenrad", "ready": false},
		4: {"name": "Murat vom Späti", "char": "gewerkschaft", "ready": true}}
	UIApi.preview_net = {"org": "gewerkschaft", "difficulty": 2, "upnp_status": "failed: no gateway found"}
	await _shot("05_lobby_host", Lobby.new())

	UIApi.preview_mode = "client"
	UIApi.preview_local_id = 3
	UIApi.preview_net = {"org": "antifa", "difficulty": 1}
	var lobby_client := Lobby.new()
	await _shot("06_lobby_client_locked", lobby_client, func() -> void: lobby_client._show_detail("toechter"))

	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	var sp := SpaetiPanel.new()
	sp.preview_meta = _fake_meta(true)
	await _shot("07_spaeti_levelup", sp)
	var sp2 := SpaetiPanel.new()
	sp2.preview_meta = _fake_meta(false)
	await _shot("08_spaeti_shop", sp2)
	var sp3 := SpaetiPanel.new()
	var m3 := _fake_meta(false)
	m3["vertrag"] = {"options": [], "votes": {}, "active": "aufruestung", "waves_left": 3}
	m3["wall_holes"] = 0
	m3["players"] = {1: m3["players"][1]}
	m3["blackrock"] = false
	m3["players"][1]["spend_left"] = -1
	sp3.preview_meta = m3
	await _shot("09_spaeti_solo", sp3)

	UIApi.preview_mode = "solo"
	await _shot("10_pause", PauseMenu.new())

	UIApi.preview_mode = "host"
	var end := EndScreen.new()
	end.preview_meta = _fake_end_meta(true)
	UIApi.preview_unlocks = {"new_achievements": ["ach_aufsichtsrat"], "new_chars": ["toechter"],
		"new_quotes": ["merz-17", "merz-12", "hoecke-02"]}
	await _shot("11_end_won", end)
	UIApi.preview_mode = "client"
	UIApi.preview_unlocks = {}
	var end2 := EndScreen.new()
	end2.preview_meta = _fake_end_meta(false)
	await _shot("12_end_lost", end2)

	await _shot("13_album", Album.new())
	var album := Album.new()
	await _shot("14_album_locked", album, func() -> void:
		var ids := Quotes.album_ids()
		album._show(ids[ids.size() - 1], ids.size() - 1))
	await _shot("15_achievements", AchievementsScreen.new())
	await _shot("16_options", OptionsScreen.new())
	await _shot("17_credits", CreditsScreen.new())
	var credits := CreditsScreen.new()
	await _shot("18_credits_attrib", credits, func() -> void: credits._scroll.scroll_vertical = 100000)
	var menu := MainMenu.new()
	await _shot("19_toast", menu, func() -> void:
		ToastLayer.show_text(TranslationServer.translate("MENU_BLACKROCK"))
		ToastLayer.show_text(TranslationServer.translate("DENY_SPEND_LIMIT")), 40)
	print("ui_preview: done -> ", _out)
	quit()


func _fake_save() -> void:
	var save := _save_node()
	var ids := Quotes.album_ids()
	save.data["album"] = ids.slice(0, mini(24, ids.size()))
	save.data["achievements"] = {"ach_doep": true, "ach_180": true, "ach_kassenwart": true}
	save.data["max_umfrage"] = 2
	save.data["stats"] = {"runs": 12, "wins": 3, "best_wave": 20}
	save.data["options"]["name"] = "Genoss*in"


func _shot(file: String, screen: Control, after: Callable = Callable(), settle := 6) -> void:
	if _only != "" and not file.contains(_only):
		screen.free()
		return
	root.add_child(screen)
	for i in 4:
		await process_frame
	if after.is_valid():
		after.call()
	for i in settle:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(_out + file + ".png")
	print("saved ", file)
	screen.queue_free()
	await process_frame


func _shot_menu_overlay(file: String, overlay: Control) -> void:
	if _only != "" and not file.contains(_only):
		overlay.free()
		return
	var menu := MainMenu.new()
	root.add_child(menu)
	await process_frame
	await _shot(file, overlay)
	menu.queue_free()
	await process_frame


func _player(pname: String, ch: String, ready: bool, pfand: int) -> Dictionary:
	var stats := Content.BASE_STATS.duplicate()
	stats["max_hp"] = 27.0
	stats["damage"] = 15.0
	stats["speed"] = -20.0
	stats["armor"] = 4.0
	stats["luck"] = 6.0
	stats["income"] = -2.0
	stats["attack_speed"] = 10.0
	return {
		"name": pname, "char": ch, "pfand": pfand, "alive": true, "stats": stats,
		"weapons": [{"id": "stricknadeln", "tier": 2}, {"id": "gendersternchen", "tier": 1},
			{"id": "grundgesetz", "tier": 3}, {"id": "tofu", "tier": 1}, {"id": "infostand", "tier": 1}],
		"max_weapons": 6,
		"items": ["thermoskanne", "solibutton", "solibutton", "bierdeckel", "schuldenbremse", "anruf_bei_mama",
			"deutschlandticket_abo", "spaeti_sonnenbrille", "gewerkschaftsweste"],
		"offers": [
			{"kind": "weapon", "id": "megafon", "tier": 2, "price": 43, "sold": false},
			{"kind": "item", "id": "bierdeckel", "tier": 1, "price": 7, "sold": true},
			{"kind": "item", "id": "gewerkschaftsweste", "tier": 1, "price": 33, "sold": false},
			{"kind": "weapon", "id": "pfandflasche", "tier": 1, "price": 25, "sold": false}],
		"reroll_price": 9, "free_rerolls": 0, "spend_left": 40,
		"levelups": 0, "levelup_options": [],
		"ready": ready, "paid_in": 30, "taken_out": 10, "kills": 412, "damage": 9123,
	}


func _fake_meta(levelup: bool) -> Dictionary:
	var me := _player("Genoss*in", "oma", false, 87)
	if levelup:
		me["levelups"] = 2
		me["levelup_options"] = [{"stat": "max_hp", "amount": 3.0}, {"stat": "status", "amount": 2.0},
			{"stat": "luck", "amount": 6.0}, {"stat": "attack_speed", "amount": 5.0}]
	return {
		"wave": 7, "phase": 1, "org": "gewerkschaft", "difficulty": 1, "blackrock": not levelup,
		"kasse": 60, "wall_holes": 3, "repair_price": 29,
		"streik": {"available": false, "active": 0.0},
		"vertrag": {"options": ["tempolimit", "aufruestung", "sanktionen"], "votes": {1: 0, 2: 1, 3: 0}, "active": "", "waves_left": 0},
		"encounter": "", "team": {"level": 6, "xp": 3.0, "need": 46.0, "stage": 2}, "num_players": 3,
		"players": {
			1: me,
			2: _player("Oma Inge", "oma", true, 12),
			3: _player("Lastenrad-Lea", "lastenrad", false, 140)},
		"result": {},
	}


func _fake_end_meta(won: bool) -> Dictionary:
	var m := _fake_meta(false)
	m["phase"] = 2
	m["players"][4] = _player("Murat vom Späti", "gewerkschaft", true, 3)
	m["result"] = {
		"won": won, "wave": 20 if won else 13, "time": 1104.0 if won else 640.0, "difficulty": 2,
		"encounters_beaten": ["sylt_clique", "geschichtslehrer", "sauerlaender", "eidgenossin"] if won else ["sylt_clique", "geschichtslehrer"],
		"wall_intact": false,
		"players": {
			1: {"char": "oma", "kills": 1203, "damage": 45210, "paid_in": 120, "taken_out": 10, "steuermoral": 0.92},
			2: {"char": "stadtbild", "kills": 980, "damage": 39001, "paid_in": 40, "taken_out": 40, "steuermoral": 0.5},
			3: {"char": "lastenrad", "kills": 1500, "damage": 51000, "paid_in": 0, "taken_out": 90, "steuermoral": 0.0},
			4: {"char": "gewerkschaft", "kills": 640, "damage": 20000, "paid_in": 0, "taken_out": 0, "steuermoral": 0.5}},
		"quotes": [],
	}
	return m
