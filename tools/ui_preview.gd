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
	_save_node().persist = false   # never touch the player's save or rejoin file
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
	UINav.install(root)  # focus tooltips + glyph tracking, as main.gd does
	await process_frame
	_fake_save()

	await _shot("01_main_menu", MainMenu.new())
	await _shot_menu_overlay("02_host_dialog", HostDialog.new())
	UIApi.preview_net = {"lan_games": [
		{"name": "Oma Inge", "ip": "192.168.178.23", "port": 24713, "players": 2},
		{"name": "Kiezkollektiv", "ip": "192.168.178.40", "port": 24713, "players": 1}]}
	await _shot_menu_overlay("03_join_dialog", JoinDialog.new())

	UIApi.preview_local_id = 1
	UIApi.preview_mode = "solo"
	UIApi.preview_lobby = {1: {"name": "Genoss:in", "char": "oma", "ready": false}}
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
	m3["vertrag"] = {"options": [], "votes": {}, "active": "buerokratieabbau", "waves_left": 3}
	m3["wall_holes"] = 0
	m3["players"] = {1: m3["players"][1]}
	m3["players"][1]["offers"] = m3["players"][1]["offers"].slice(0, 3)
	m3["blackrock"] = false
	m3["players"][1]["spend_left"] = -1
	sp3.preview_meta = m3
	await _shot("09_spaeti_solo", sp3)
	var sp4 := SpaetiPanel.new()
	sp4.preview_meta = _fake_meta(false)
	await _shot("09b_spaeti_stats", sp4, func() -> void: sp4.open_stats())
	var sp5 := SpaetiPanel.new()
	var m5 := _fake_meta(false)
	m5["blackrock"] = false
	var many: Array = m5["players"][1]["run_stats"]["damage"]
	for id in ["doener", "kleber", "farbbeutel", "transparent", "infostand", "pfandflasche", "megafon", "tofu",
			"stricknadeln", "grundgesetz", "gendersternchen"]:
		many.append({"key": "w:" + id + "4", "kind": "weapon", "id": id, "tier": 4, "sold": true, "total": 17, "wave": 0})
	sp5.preview_meta = m5
	await _shot("09c_spaeti_stats_scroll", sp5, func() -> void: sp5.open_stats())
	# GDD §6c / D-152: solo strip without names; four players with an away one.
	var sps := SpaetiPanel.new()
	var ms := _fake_meta(false)
	ms["players"] = {1: ms["players"][1]}
	ms["num_players"] = 1
	sps.preview_meta = ms
	await _shot("09e_spaeti_stats_solo", sps, func() -> void: sps.open_stats())
	var sp4p := SpaetiPanel.new()
	var m4p := _fake_meta(false)
	m4p["players"][4] = _player("Murat vom Späti", "gewerkschaft", true, 3)
	m4p["players"][4]["away"] = true
	m4p["players"][3]["run_stats"]["damage"][0]["wave"] = 1400   # Lea's best: Stricknadeln II
	m4p["players"][3]["run_stats"]["last_wave"]["kills"] = 131    # and the most kills
	m4p["num_players"] = 4
	sp4p.preview_meta = m4p
	await _shot("09f_spaeti_stats_coop4", sp4p, func() -> void: sp4p.open_stats())
	var sp6 := SpaetiPanel.new()
	sp6.preview_meta = _fake_meta(false)
	await _shot("09d_spaeti_options", sp6, func() -> void: sp6.open_options())
	# GDD §6 character portrait in the header at Zusammenhalt stage 0 and 4
	for st in [0, 4]:
		for ch in ["oma", "lastenrad"]:
			var spp := SpaetiPanel.new()
			var mp := _fake_meta(false)
			mp["team"] = {"level": [1, 16][st / 4], "xp": [7.0, 40.0][st / 4], "need": [16.0, 106.0][st / 4], "stage": st}
			mp["players"][1]["char"] = ch
			spp.preview_meta = mp
			await _shot("42_spaeti_portrait_%s_s%d" % [ch, st], spp)
	# GDD §6: unmistakable "Bereit" state (local player ready, others still shopping).
	var srd := SpaetiPanel.new()
	var mrd := _fake_meta(false)
	mrd["players"][1]["ready"] = true
	srd.preview_meta = mrd
	await _shot("43_spaeti_ready", srd)
	# networking.md §7.5: "Zurück ins Spiel" in the main menu after a crash.
	_save_node().set_rejoin({"ip": "192.168.178.23", "port": 24713, "token": "preview", "player": 2})
	await _shot("44_main_menu_rejoin", MainMenu.new())
	_save_node().clear_rejoin()

	# Playtest feedback: rarity cards, twins, discard, confirmations, vote gating.
	var sr := SpaetiPanel.new()
	sr.preview_meta = _rarity_meta()
	await _shot("20_spaeti_rarity", sr)
	var sc := SpaetiPanel.new()
	sc.preview_meta = _combine_meta()
	await _shot("21_spaeti_combine_vote", sc)
	var sd := SpaetiPanel.new()
	sd.preview_meta = _rarity_meta()
	await _shot("22_spaeti_discard", sd, func() -> void: sd._ask_discard("solibutton"))
	var sd1 := SpaetiPanel.new()
	sd1.preview_meta = _rarity_meta()
	await _shot("22b_spaeti_discard_one", sd1, func() -> void: sd1._ask_discard("tarnkappe"))
	var ss := SpaetiPanel.new()
	ss.preview_meta = _combine_meta()
	await _shot("23_spaeti_confirm_sell", ss, func() -> void: ss._ask_sell(1))
	var sk := SpaetiPanel.new()
	sk.preview_meta = _combine_meta()
	await _shot("24_spaeti_confirm_combine", sk, func() -> void: sk._ask_combine(0))
	var sm := SpaetiPanel.new()
	sm.preview_meta = _combine_meta()
	await _shot("25_spaeti_stats_merged", sm, func() -> void: sm.open_stats())
	var sa := SpaetiPanel.new()
	var ma := _combine_meta()
	ma["vertrag"]["votes"] = {1: -1, 2: -1, 3: 0}
	sa.preview_meta = ma
	await _shot("26_spaeti_abstained", sa)

	UIApi.preview_mode = "solo"
	var end_solo := EndScreen.new()
	var mso := _fake_end_meta(true)
	mso["num_players"] = 1
	mso["players"] = {1: mso["players"][1]}
	mso["result"]["players"] = {1: mso["result"]["players"][1]}
	end_solo.preview_meta = mso
	await _shot("27_end_solo", end_solo)

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
	await _controller_shots()
	print("ui_preview: done -> ", _out)
	quit()


## GDD §19b: focus frames, the focus info box, gamepad vs. keyboard glyphs.
func _controller_shots() -> void:
	var pad := InputGlyphs.Device.PAD
	var kb := InputGlyphs.Device.KEYBOARD
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	UIApi.preview_lobby = {1: {"name": "Genoss:in", "char": "oma", "ready": false}}
	UIApi.preview_net = {"org": "omas", "difficulty": 1}
	InputGlyphs.set_device(pad, "xbox")
	var sp := SpaetiPanel.new()
	sp.preview_meta = _fake_meta(false)
	await _shot("30_pad_spaeti_buy_tip", sp, func() -> void: _focus(sp, "buy_2"))
	var sp2 := SpaetiPanel.new()
	sp2.preview_meta = _rarity_meta()
	await _shot("31_pad_spaeti_stat_tip", sp2, func() -> void: _focus(sp2, "stat_crit"))
	var sp3 := SpaetiPanel.new()
	sp3.preview_meta = _rarity_meta()
	await _shot("32_pad_spaeti_item_tip", sp3, func() -> void: _focus(sp3, "item_1"))
	var sp4 := SpaetiPanel.new()
	sp4.preview_meta = _combine_meta()
	await _shot("33_pad_confirm_sell", sp4, func() -> void: sp4._ask_sell(1))
	UIApi.preview_mode = "solo"
	var lobby := Lobby.new()
	await _shot("34_pad_lobby_glyphs", lobby)
	await _shot("35_pad_options_slider", OptionsScreen.new())
	await _shot("36_pad_achievements", AchievementsScreen.new())
	InputGlyphs.set_device(pad, "ps")
	await _shot("37_ps_pause", PauseMenu.new())
	var sp5 := SpaetiPanel.new()
	sp5.preview_meta = _combine_meta()
	await _shot("38_ps_confirm_combine", sp5, func() -> void: sp5._ask_combine(0))
	InputGlyphs.set_device(kb, "xbox")
	var lobby2 := Lobby.new()
	await _shot("39_kb_lobby_glyphs", lobby2)
	var sp6 := SpaetiPanel.new()
	sp6.preview_meta = _combine_meta()
	await _shot("40_kb_confirm_sell", sp6, func() -> void: sp6._ask_sell(1))
	await _shot("41_kb_pause", PauseMenu.new())


func _focus(screen: Node, node_name: String) -> void:
	var c := screen.find_child(node_name, true, false) as Control
	if c:
		c.grab_focus()


func _fake_save() -> void:
	var save := _save_node()
	var ids := Quotes.album_ids()
	save.data["album"] = ids.slice(0, mini(24, ids.size()))
	save.data["achievements"] = {"ach_doep": true, "ach_180": true, "ach_kassenwart": true}
	save.data["max_umfrage"] = 2
	save.data["stats"] = {"runs": 12, "wins": 3, "best_wave": 20}
	save.data["options"]["name"] = "Genoss:in"


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


static func _player(pname: String, ch: String, ready: bool, pfand: int) -> Dictionary:
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
		"ult": str(Content.CHARACTERS.get(ch, {}).get("ult", "")), "ult_ready": false,
		"run_stats": _fake_run_stats(pfand),
	}


## Fake run_stats (architecture §10): 5 weapons (one sold), ram, ult, other.
## `salt` varies the numbers per player.
static func _fake_run_stats(salt: int) -> Dictionary:
	var f := 1.0 + float(salt % 7) * 0.13
	var rows := [
		{"key": "w:stricknadeln", "kind": "weapon", "id": "stricknadeln", "tier": 2, "sold": false, "total": int(3120 * f), "wave": int(611 * f)},
		{"key": "w:grundgesetz", "kind": "weapon", "id": "grundgesetz", "tier": 3, "sold": false, "total": int(2480 * f), "wave": int(904 * f)},
		{"key": "ult", "kind": "ult", "id": "", "tier": 0, "sold": false, "total": int(1650 * f), "wave": int(220 * f)},
		{"key": "w:megafon", "kind": "weapon", "id": "megafon", "tier": 1, "sold": true, "total": int(1210 * f), "wave": 0},
		{"key": "w:gendersternchen", "kind": "weapon", "id": "gendersternchen", "tier": 1, "sold": false, "total": int(890 * f), "wave": int(305 * f)},
		{"key": "ram", "kind": "ram", "id": "", "tier": 0, "sold": false, "total": int(540 * f), "wave": int(75 * f)},
		{"key": "w:tofu", "kind": "weapon", "id": "tofu", "tier": 1, "sold": false, "total": int(312 * f), "wave": int(140 * f)},
		{"key": "other", "kind": "other", "id": "", "tier": 0, "sold": false, "total": 23, "wave": 4},
	]
	return {
		"damage": rows, "lifesteal": int(214 * f), "regen": int(96 * f), "dmg_taken": int(731 * f),
		"dmg_blocked": int(388 * f), "dodges": int(41 * f), "crits": int(1337 * f), "kills": int(412 * f),
		"pfand_collected": int(268 * f), "pfand_income": 54, "pfand_spent": int(301 * f), "ults": 6,
		"last_wave": {"damage": int(2259 * f), "kills": int(58 * f), "pfand": int(31 * f), "dmg_taken": int(84 * f),
			"healed": int(47 * f)},
	}


static func _fake_meta(levelup: bool) -> Dictionary:
	var me := _player("Genoss:in", "oma", false, 87)
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


## Offers in all four item rarities (GDD §12), owned items of every rarity.
static func _rarity_meta() -> Dictionary:
	var m := _fake_meta(false)
	m["blackrock"] = false
	var me: Dictionary = m["players"][1]
	me["spend_left"] = -1
	me["pfand"] = 140
	me["offers"] = [
		{"kind": "item", "id": "thermoskanne", "tier": 1, "price": 12, "sold": false, "rarity": 1},
		{"kind": "item", "id": "mietendeckel", "tier": 1, "price": 28, "sold": false, "rarity": 2},
		{"kind": "item", "id": "tarifvertrag", "tier": 1, "price": 52, "sold": false, "rarity": 3},
		{"kind": "item", "id": "tarnkappe", "tier": 1, "price": 85, "sold": false, "rarity": 4}]
	me["items"] = ["thermoskanne", "solibutton", "solibutton", "solibutton", "bierdeckel", "schuldenbremse",
		"faxgeraet", "tarnkappe", "anruf_bei_mama", "spaeti_sonnenbrille", "gewerkschaftsweste", "volkskueche"]
	m["vertrag"]["votes"] = {1: 2, 2: 1, 3: 0}
	return m


## Full weapon slots with a twin (Megafon II ×2), a weapon offer that would
## auto-combine, and an open vote the local player hasn't answered yet.
static func _combine_meta() -> Dictionary:
	var m := _fake_meta(false)
	m["blackrock"] = false
	var me: Dictionary = m["players"][1]
	me["spend_left"] = -1
	me["weapons"] = [{"id": "megafon", "tier": 2}, {"id": "stricknadeln", "tier": 2}, {"id": "megafon", "tier": 2},
		{"id": "grundgesetz", "tier": 3}, {"id": "tofu", "tier": 1}, {"id": "infostand", "tier": 4}]
	me["offers"] = [
		{"kind": "weapon", "id": "megafon", "tier": 2, "price": 43, "sold": false},
		{"kind": "weapon", "id": "tofu", "tier": 1, "price": 18, "sold": false},
		{"kind": "weapon", "id": "pfandflasche", "tier": 1, "price": 25, "sold": false},
		{"kind": "item", "id": "kompost", "tier": 1, "price": 85, "sold": false, "rarity": 4}]
	m["vertrag"]["votes"] = {2: 1, 3: -1}
	var rows: Array = me["run_stats"]["damage"]
	rows.append({"key": "w:megafon1a", "kind": "weapon", "id": "megafon", "tier": 1, "sold": false, "merged": true, "total": 640, "wave": 0})
	return m


static func _fake_end_meta(won: bool) -> Dictionary:
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
