class_name EndScreen
extends UIScreen
## Run summary (GDD §4 "End"): result, per-player table with Steuermoral,
## and what this machine unlocked (Game.last_unlocks).

## Set by tools/ui_preview.gd; if not empty it replaces Game.meta.
var preview_meta: Dictionary = {}


func _init() -> void:
	super()
	closable = false


func _meta() -> Dictionary:
	return preview_meta if not preview_meta.is_empty() else UIApi.meta()


func build() -> void:
	var meta := _meta()
	var r: Dictionary = meta.get("result", {})
	var won := bool(r.get("won", false))
	var title := UIKit.heading(tr("END_WON") if won else tr("END_LOST"), 50, UITheme.GREEN if won else UITheme.RED)
	UIKit.tilt(title, -1.5)
	body.add_child(title)
	if r.is_empty():
		body.add_child(UIKit.para(tr("END_NO_RESULT"), 20, UITheme.GREY))
	var t := float(r.get("time", 0.0))
	var diff := clampi(int(r.get("difficulty", meta.get("difficulty", 0))), 0, Content.DIFFICULTY_PERCENT.size() - 1)
	body.add_child(UIKit.label(tr("END_SUMMARY").format({
		"wave": int(r.get("wave", meta.get("wave", 0))),
		"time": "%d:%02d" % [int(t) / 60, int(t) % 60],
		"umfrage": Content.DIFFICULTY_PERCENT[diff],
	}), 24, UITheme.INK_SOFT))
	var encs: Array = r.get("encounters_beaten", [])
	if not encs.is_empty():
		var names := []
		for e in encs:
			names.append(UIKit.content_text("ENC", str(e)))
		body.add_child(UIKit.para(tr("END_PROMOTED") % ", ".join(names), 20))
	if bool(r.get("wall_intact", false)):
		body.add_child(UIKit.label(tr("END_WALL_INTACT"), 20, UITheme.GREEN))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := UIKit.vbox(14)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(col)
	body.add_child(scroll)
	col.add_child(_table(meta, r))
	var unlocks := _unlocks()
	if unlocks:
		col.add_child(unlocks)

	var buttons := UIKit.hbox(16)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	if UIApi.is_host():
		buttons.add_child(UIKit.button(tr("END_TO_LOBBY"), _on_lobby, 26))
	buttons.add_child(UIKit.button(tr("END_TO_MENU"), _on_menu, 26))
	body.add_child(buttons)


func _table(meta: Dictionary, r: Dictionary) -> Control:
	var card := UIKit.card(UITheme.PAPER, UITheme.INK, 0.4)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 4)
	card.add_child(grid)
	for key in ["END_COL_NAME", "END_COL_CHAR", "END_COL_KILLS", "END_COL_DAMAGE", "END_COL_IN", "END_COL_OUT", "END_COL_MORAL"]:
		grid.add_child(UIKit.label(tr(key), 19, UITheme.RED))
	var rp: Dictionary = r.get("players", {})
	var mp: Dictionary = meta.get("players", {})
	var peers := rp.keys() if not rp.is_empty() else mp.keys()
	peers.sort_custom(func(a, b) -> bool: return int(a) < int(b))
	for peer in peers:
		var p := UIApi.by_peer(rp, peer)
		var m := UIApi.by_peer(mp, peer)
		var pname := str(m.get("name", UIApi.by_peer(UIApi.lobby(), peer).get("name", "?")))
		var me := str(peer) == str(UIApi.local_id())
		grid.add_child(UIKit.label(pname + (" " + tr("LOBBY_YOU") if me else ""), 20))
		grid.add_child(UIKit.label(UIKit.content_text("CHAR", str(p.get("char", m.get("char", "")))), 20))
		grid.add_child(UIKit.label(str(int(p.get("kills", m.get("kills", 0)))), 20))
		grid.add_child(UIKit.label(str(int(p.get("damage", m.get("damage", 0)))), 20))
		var paid := int(p.get("paid_in", m.get("paid_in", 0)))
		var taken := int(p.get("taken_out", m.get("taken_out", 0)))
		grid.add_child(UIKit.label(str(paid), 20))
		grid.add_child(UIKit.label(str(taken), 20))
		var grade := steuermoral_grade(p.get("steuermoral", null), paid, taken)
		var gl := UIKit.label(tr("END_GRADE") % [grade, tr("END_MORAL_%d" % grade)], 18,
			UITheme.GREEN if grade <= 2 else (UITheme.INK if grade <= 4 else UITheme.RED))
		if paid == 0 and taken == 0:
			gl.text = tr("END_MORAL_NONE")
			gl.add_theme_color_override("font_color", UITheme.INK_SOFT)
		grid.add_child(gl)
	if peers.is_empty():
		grid.add_child(UIKit.label("–", 20, UITheme.GREY))
	return card


## German school grade 1 (best) .. 6. Uses the Sim's steuermoral if it is a
## 0..1 share of paid-in money, else computes that share from in/out.
static func steuermoral_grade(value, paid: int, taken: int) -> int:
	var share := 0.5
	if value != null and float(value) >= 0.0 and float(value) <= 1.0:
		share = float(value)
	elif paid + taken > 0:
		share = float(paid) / float(paid + taken)
	if share >= 0.85: return 1
	if share >= 0.65: return 2
	if share >= 0.45: return 3
	if share >= 0.25: return 4
	if share >= 0.1: return 5
	return 6


func _unlocks() -> Control:
	var u := UIApi.last_unlocks()
	var achs: Array = u.get("new_achievements", [])
	var chars: Array = u.get("new_chars", [])
	var quotes: Array = u.get("new_quotes", [])
	if achs.is_empty() and chars.is_empty() and quotes.is_empty():
		return UIKit.label(tr("END_NO_UNLOCKS"), 20, UITheme.INK_SOFT)
	var row := UIKit.hbox(16)
	if not achs.is_empty() or not chars.is_empty():
		var c := UIKit.card(UITheme.YELLOW.lerp(UITheme.PAPER, 0.7), UITheme.INK, -1.0)
		c.custom_minimum_size.x = 380
		var v := UIKit.vbox(4)
		c.add_child(v)
		if not achs.is_empty():
			v.add_child(UIKit.label(tr("END_NEW_ACH"), 22, UITheme.RED))
			for a in achs:
				v.add_child(UIKit.label(UIKit.ach_text(str(a)), 20))
				v.add_child(UIKit.para(UIKit.ach_text(str(a), "DESC"), 16, UITheme.INK_SOFT))
		if not chars.is_empty():
			v.add_child(UIKit.label(tr("END_NEW_CHARS"), 22, UITheme.RED))
			for ch in chars:
				v.add_child(UIKit.label(UIKit.content_text("CHAR", str(ch)), 20))
		row.add_child(c)
	if not quotes.is_empty():
		var qv := UIKit.vbox(6)
		qv.size_flags_horizontal = SIZE_EXPAND_FILL
		qv.add_child(UIKit.label(tr("END_NEW_QUOTES") % quotes.size(), 22, UITheme.RED))
		for i in mini(quotes.size(), 2):
			qv.add_child(UIKit.clipping(str(quotes[i]), "", UIKit.tilt_for(i, 0.7), 15))
		if quotes.size() > 2:
			qv.add_child(UIKit.label(tr("END_MORE_QUOTES") % (quotes.size() - 2), 18, UITheme.INK_SOFT))
		row.add_child(qv)
	return row


func _on_lobby() -> void:
	UIApi.call_opt(UIApi.game(), "back_to_lobby")


func _on_menu() -> void:
	UIApi.call_opt(UIApi.game(), "quit_to_menu")
