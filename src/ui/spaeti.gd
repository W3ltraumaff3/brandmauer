class_name SpaetiPanel
extends Control
## The Späti between waves (GDD §6). Overlay added by the run screen while
## meta.phase == 1. Shows the local player's slice of Game.meta and sends
## requests via Game.request (architecture §4, §5).

## Set by tools/ui_preview.gd; if not empty it replaces Game.meta.
var preview_meta: Dictionary = {}

var _root_box: VBoxContainer
var _refresh_queued := false
var _focus_name := ""
var _quote_id := ""
var _last_hash := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	if theme == null:
		theme = UITheme.get_theme()  # also themed under a CanvasLayer
	var bg := PaperBg.new()
	bg.ruled = false
	add_child(bg)
	_root_box = UIKit.vbox(8)
	var m := UIKit.margin(_root_box, 24, 14, 24, 14)
	UIKit.full(m)
	add_child(m)
	_quote_id = UIKit.pick_quote("ladebildschirm", 150)
	var g := UIApi.game()
	UIApi.connect_opt(g, "meta_changed", _queue_refresh)
	UIApi.connect_opt(g, "events", _on_events)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	_rebuild()
	for n in ["levelup_0", "buy_0", "ready"]:
		var b := _root_box.find_child(n, true, false) as BaseButton
		if b and not b.disabled:
			UIKit.focus_later(b)
			return
	UIKit.focus_first(_root_box)


func _exit_tree() -> void:
	var g := UIApi.game()
	UIApi.disconnect_opt(g, "meta_changed", _queue_refresh)
	UIApi.disconnect_opt(g, "events", _on_events)
	if get_viewport() and get_viewport().gui_focus_changed.is_connected(_on_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)


func _meta() -> Dictionary:
	return preview_meta if not preview_meta.is_empty() else UIApi.meta()


func _me() -> Dictionary:
	if not preview_meta.is_empty():
		return UIApi.by_peer(preview_meta.get("players", {}), UIApi.local_id())
	return UIApi.local_meta()


func _on_focus_changed(c: Control) -> void:
	if c and is_ancestor_of(c):
		_focus_name = c.name


func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_do_refresh.call_deferred()


func _do_refresh() -> void:
	_refresh_queued = false
	if is_inside_tree() and _state_hash() != _last_hash:
		_rebuild()


## Only what the panel shows; avoids rebuilding (and losing hover/tooltips)
## when meta changes in ways the Späti doesn't display.
func _state_hash() -> int:
	var meta := _meta()
	var ready := []
	for peer in meta.get("players", {}):
		var p = meta["players"][peer]
		ready.append([str(peer), p.get("ready", false), p.get("name", "")] if p is Dictionary else [])
	return hash([_me(), meta.get("wave"), meta.get("kasse"), meta.get("vertrag"), meta.get("wall_holes"),
		meta.get("repair_price"), meta.get("blackrock"), ready])


func _on_events(events: Array) -> void:
	for e in events:
		if e is Array and e.size() >= 2 and e[0] == "deny" and str(e[1]) == str(UIApi.local_id()):
			UIApi.sfx("error")


# --- Build ------------------------------------------------------------------

func _rebuild() -> void:
	var keep := _focus_name
	_last_hash = _state_hash()
	UIKit.clear(_root_box)
	var meta := _meta()
	var me := _me()
	if me.is_empty():
		var c := CenterContainer.new()
		c.size_flags_vertical = SIZE_EXPAND_FILL
		c.add_child(UIKit.label(tr("SPAETI_EMPTY"), 28, UITheme.INK_SOFT))
		_root_box.add_child(c)
		return
	_root_box.add_child(_header(meta, me))
	var main := UIKit.hbox(12)
	main.size_flags_vertical = SIZE_EXPAND_FILL
	_root_box.add_child(main)
	main.add_child(_stats_card(me))
	var mid := UIKit.vbox(10)
	mid.size_flags_horizontal = SIZE_EXPAND_FILL
	main.add_child(mid)
	mid.add_child(_shop_card(meta, me))
	mid.add_child(_weapons_card(meta, me))
	mid.add_child(_items_card(me))
	main.add_child(_side_column(meta, me))
	_root_box.add_child(_bottom(meta, me))
	if keep != "":
		var target := _root_box.find_child(keep, true, false) as Control
		if target and target.focus_mode != FOCUS_NONE and not (target is BaseButton and target.disabled):
			UIKit.focus_later(target)
		else:
			UIKit.focus_first(_root_box)


func _card(title: String, degrees := 0.0, bg := UITheme.PAPER) -> Array:
	var c := UIKit.card(bg, UITheme.INK, degrees)
	var v := UIKit.vbox(4)
	c.add_child(v)
	if title != "":
		v.add_child(UIKit.label(title, 22, UITheme.RED))
	return [c, v]


func _btn(text: String, node_name: String, cb: Callable, size := 18) -> Button:
	var b := UIKit.button(text, cb, size)
	b.name = node_name
	return b


func _header(meta: Dictionary, me: Dictionary) -> Control:
	var h := UIKit.hbox(18)
	var t := UIKit.heading(tr("SPAETI_TITLE"), 40)
	UIKit.tilt(t, -2.0)
	h.add_child(t)
	var wave_l := UIKit.label(tr("SPAETI_WAVE_DONE") % int(meta.get("wave", 0)), 24, UITheme.INK_SOFT)
	wave_l.size_flags_vertical = SIZE_SHRINK_CENTER
	h.add_child(wave_l)
	h.add_child(UIKit.spacer())
	var spend := int(me.get("spend_left", -1))
	if spend >= 0:
		var sl := UIKit.label(tr("SPAETI_SPEND_LEFT") % [spend, UIKit.currency(meta)], 20, UITheme.RED)
		sl.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(sl)
	var money := UIKit.card(UITheme.YELLOW.lerp(UITheme.PAPER, 0.55), UITheme.INK, 1.5, 3)
	var ml := UIKit.label("%d %s" % [int(me.get("pfand", 0)), UIKit.currency(meta)], 30)
	money.add_child(ml)
	if meta.get("blackrock", false):
		money.tooltip_text = tr("SPAETI_AKTIEN_TIP")
	h.add_child(money)
	return h


func _stats_card(me: Dictionary) -> Control:
	var parts := _card(tr("SPAETI_STATS"), -0.7)
	parts[0].custom_minimum_size.x = 240
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", -1)
	var stats: Dictionary = me.get("stats", {})
	for stat in Content.STATS:
		var v := float(stats.get(stat, Content.BASE_STATS.get(stat, 0.0)))
		var base := float(Content.BASE_STATS.get(stat, 0.0))
		var col := UITheme.INK
		if v > base + 0.001:
			col = UITheme.GREEN
		elif v < base - 0.001:
			col = UITheme.RED
		var n := UIKit.label(UIKit.stat_name(stat), 17)
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.mouse_filter = MOUSE_FILTER_PASS
		n.tooltip_text = UIKit.trk("STAT_%s_DESC" % stat.to_upper())
		grid.add_child(n)
		var vl := UIKit.label(UIKit.fmt_num(v), 17, col, HORIZONTAL_ALIGNMENT_RIGHT)
		grid.add_child(vl)
	parts[1].add_child(grid)
	return parts[0]


func _shop_card(meta: Dictionary, me: Dictionary) -> Control:
	var levelups := int(me.get("levelups", 0))
	var options: Array = me.get("levelup_options", [])
	if levelups > 0 and not options.is_empty():
		var lp := _card(tr("SPAETI_LEVELUP") % levelups, 0.5, UITheme.YELLOW.lerp(UITheme.PAPER, 0.7))
		lp[1].add_child(UIKit.para(tr("SPAETI_LEVELUP_HINT"), 18, UITheme.INK_SOFT))
		var row := UIKit.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_vertical = SIZE_EXPAND_FILL
		for i in options.size():
			var o: Dictionary = options[i]
			var stat := str(o.get("stat", ""))
			var b := _btn("%s\n%s" % [UIKit.stat_name(stat), UIKit.signed(float(o.get("amount", 0.0)))],
				"levelup_%d" % i, _on_levelup.bind(i), 22)
			b.custom_minimum_size = Vector2(150, 110)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.tooltip_text = UIKit.trk("STAT_%s_DESC" % stat.to_upper())
			UIKit.tilt(b, UIKit.tilt_for(i, 1.2))
			row.add_child(b)
		lp[1].add_child(row)
		lp[0].size_flags_vertical = SIZE_EXPAND_FILL
		return lp[0]

	var parts := _card("", 0.4)
	var head := UIKit.hbox(10)
	head.add_child(UIKit.label(tr("SPAETI_OFFERS"), 22, UITheme.RED))
	head.add_child(UIKit.spacer())
	var free := int(me.get("free_rerolls", 0))
	var reroll_text := tr("SPAETI_REROLL_FREE") % free if free > 0 else tr("SPAETI_REROLL") % int(me.get("reroll_price", 0))
	head.add_child(UIKit.compact(_btn(reroll_text, "reroll", _on_reroll, 18), 0, 10))
	parts[1].add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	var offers: Array = me.get("offers", [])
	if offers.is_empty():
		parts[1].add_child(UIKit.para(tr("SPAETI_NO_OFFERS"), 18, UITheme.GREY))
	for i in offers.size():
		grid.add_child(_offer_card(i, offers[i], meta, me))
	parts[1].add_child(grid)
	return parts[0]


func _offer_card(i: int, o: Dictionary, meta: Dictionary, me: Dictionary) -> Control:
	var weapon := str(o.get("kind", "item")) == "weapon"
	var id := str(o.get("id", ""))
	var kind := "WEAPON" if weapon else "ITEM"
	var sold := bool(o.get("sold", false))
	var price := int(o.get("price", 0))
	var c := UIKit.card(Color.WHITE.lerp(UITheme.PAPER, 0.5), UITheme.INK, UIKit.tilt_for(i, 0.6))
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(300, 112)
	var v := UIKit.vbox(2)
	c.add_child(v)
	var top := UIKit.hbox(6)
	var n := UIKit.label(UIKit.content_text(kind, id), 20)
	n.size_flags_horizontal = SIZE_EXPAND_FILL
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(n)
	var tag := tr("SPAETI_WEAPON_TIER") % UIKit.roman(int(o.get("tier", 1))) if weapon else tr("SPAETI_ITEM")
	top.add_child(UIKit.label(tag, 16, UITheme.BLUE if weapon else UITheme.INK_SOFT))
	v.add_child(top)
	var d := UIKit.para(UIKit.content_text(kind, id, "DESC"), 14, UITheme.INK_SOFT)
	d.size_flags_vertical = SIZE_EXPAND_FILL
	d.max_lines_visible = 2
	d.custom_minimum_size.y = 42
	d.add_theme_constant_override("line_spacing", -3)
	d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	d.mouse_filter = MOUSE_FILTER_PASS
	d.tooltip_text = d.text
	v.add_child(d)
	var bottom := UIKit.hbox(6)
	var affordable := price <= int(me.get("pfand", 0))
	bottom.add_child(UIKit.label("%d %s" % [price, UIKit.currency(meta)], 19, UITheme.INK if affordable else UITheme.RED))
	bottom.add_child(UIKit.spacer())
	var b := UIKit.compact(_btn(tr("SPAETI_SOLD") if sold else tr("SPAETI_BUY"), "buy_%d" % i, _on_buy.bind(i), 18), 0, 10)
	b.disabled = sold
	bottom.add_child(b)
	v.add_child(bottom)
	if sold:
		c.modulate = Color(1, 1, 1, 0.55)
		var x := CrossOut.new()
		UIKit.full(x)
		c.add_child(x)
	return c


func _weapons_card(meta: Dictionary, me: Dictionary) -> Control:
	var weapons: Array = me.get("weapons", [])
	var parts := _card(tr("SPAETI_WEAPONS") % [weapons.size(), int(me.get("max_weapons", Content.MAX_WEAPONS))], -0.3)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 2)
	var wave := int(meta.get("wave", 1))
	for i in weapons.size():
		var w: Dictionary = weapons[i]
		var id := str(w.get("id", ""))
		var tier := int(w.get("tier", 1))
		var row := UIKit.hbox(6)
		row.size_flags_horizontal = SIZE_EXPAND_FILL
		var n := UIKit.label("%s %s" % [UIKit.content_text("WEAPON", id), UIKit.roman(tier)], 18)
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		n.mouse_filter = MOUSE_FILTER_PASS
		n.tooltip_text = UIKit.content_text("WEAPON", id, "DESC")
		row.add_child(n)
		var refund := Content.sell_price(id, tier, wave) if Content.WEAPONS.has(id) else 0
		var b := UIKit.compact(_btn(tr("SPAETI_SELL") % refund, "sell_%d" % i, _on_sell.bind(i), 15), 0, 6)
		b.disabled = weapons.size() <= 1
		row.add_child(b)
		grid.add_child(row)
	if weapons.is_empty():
		parts[1].add_child(UIKit.para(tr("SPAETI_NO_WEAPONS"), 17, UITheme.GREY))
	parts[1].add_child(grid)
	return parts[0]


func _items_card(me: Dictionary) -> Control:
	var parts := _card(tr("SPAETI_ITEMS"), 0.3)
	parts[0].size_flags_vertical = SIZE_EXPAND_FILL
	var items: Array = me.get("items", [])
	if items.is_empty():
		parts[1].add_child(UIKit.para(tr("SPAETI_NO_ITEMS"), 17, UITheme.GREY))
		return parts[0]
	var counts := {}
	var order := []
	for id in items:
		if not counts.has(id):
			order.append(id)
		counts[id] = counts.get(id, 0) + 1
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	for id in order:
		var text := UIKit.content_text("ITEM", id)
		if counts[id] > 1:
			text += " ×%d" % counts[id]
		var chip := UIKit.card(UITheme.PAPER_DARK, UITheme.INK_SOFT, 0.0, 1)
		chip.add_theme_stylebox_override("panel", _chip_box())
		chip.tooltip_text = "%s\n%s" % [UIKit.content_text("ITEM", id), UIKit.content_text("ITEM", id, "DESC")]
		chip.add_child(UIKit.label(text, 16))
		flow.add_child(chip)
	parts[1].add_child(flow)
	return parts[0]


func _chip_box() -> StyleBoxFlat:
	var s := UITheme.box(UITheme.PAPER_DARK, UITheme.INK_SOFT, 1, 4)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 0
	s.content_margin_bottom = 2
	return s


func _side_column(meta: Dictionary, me: Dictionary) -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 320
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := UIKit.vbox(10)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(col)

	# Koalitionskasse.
	var cur := UIKit.currency(meta)
	var k := _card(tr("SPAETI_KASSE") % [int(meta.get("kasse", 0)), cur], 0.8)
	var kr := UIKit.hbox(8)
	var bin := _btn(tr("SPAETI_KASSE_IN"), "kasse_in", _on_kasse_in, 17)
	var bout := _btn(tr("SPAETI_KASSE_OUT"), "kasse_out", _on_kasse_out, 17)
	bin.size_flags_horizontal = SIZE_EXPAND_FILL
	bout.size_flags_horizontal = SIZE_EXPAND_FILL
	kr.add_child(bin)
	kr.add_child(bout)
	k[1].add_child(kr)
	k[1].add_child(UIKit.label(tr("SPAETI_KASSE_MINE") % [int(me.get("paid_in", 0)), int(me.get("taken_out", 0))], 16, UITheme.INK_SOFT))
	col.add_child(k[0])

	# Brandmauer.
	var holes := int(meta.get("wall_holes", 0))
	var w := _card(tr("SPAETI_WALL"), -0.6)
	if holes > 0:
		var holes_text := tr("SPAETI_WALL_HOLE_ONE") if holes == 1 else tr("SPAETI_WALL_HOLES") % holes
		w[1].add_child(UIKit.label(holes_text, 18, UITheme.RED))
		var rb := _btn(tr("SPAETI_REPAIR") % [int(meta.get("repair_price", 0)), cur], "repair", _on_repair, 18)
		w[1].add_child(rb)
	else:
		w[1].add_child(UIKit.label(tr("SPAETI_WALL_OK"), 18, UITheme.GREEN))
	col.add_child(w[0])

	# Koalitionsvertrag.
	var vertrag: Dictionary = meta.get("vertrag", {})
	var opts: Array = vertrag.get("options", [])
	if not opts.is_empty():
		col.add_child(_vertrag_card(meta, me, vertrag, opts))
	elif str(vertrag.get("active", "")) != "":
		var a := _card(tr("SPAETI_VERTRAG"), 0.5)
		a[1].add_child(UIKit.para(tr("SPAETI_VERTRAG_ACTIVE") % [
			UIKit.content_text("VERTRAG", str(vertrag["active"])), int(vertrag.get("waves_left", 0))], 17))
		a[1].add_child(UIKit.para(UIKit.content_text("VERTRAG", str(vertrag["active"]), "DESC"), 15, UITheme.INK_SOFT))
		col.add_child(a[0])
	return scroll


func _vertrag_card(meta: Dictionary, _me: Dictionary, vertrag: Dictionary, opts: Array) -> Control:
	var v := _card(tr("SPAETI_VERTRAG"), 0.5, UITheme.BLUE.lerp(UITheme.PAPER, 0.85))
	v[1].add_child(UIKit.para(tr("SPAETI_VERTRAG_HINT"), 16, UITheme.RED))
	var votes: Dictionary = vertrag.get("votes", {})
	var players: Dictionary = meta.get("players", {})
	var my_vote := -1
	for peer in votes:
		if str(peer) == str(UIApi.local_id()):
			my_vote = int(votes[peer])
	for i in opts.size():
		var id := str(opts[i])
		var row := UIKit.vbox(0)
		var h := UIKit.hbox(6)
		var n := UIKit.label(UIKit.content_text("VERTRAG", id), 19)
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(n)
		var b := _btn(tr("SPAETI_VOTED") if my_vote == i else tr("SPAETI_VOTE"), "vote_%d" % i, _on_vote.bind(i), 16)
		b.toggle_mode = true
		b.set_pressed_no_signal(my_vote == i)
		h.add_child(b)
		row.add_child(h)
		row.add_child(UIKit.para(UIKit.content_text("VERTRAG", id, "DESC"), 14, UITheme.INK_SOFT))
		var names := []
		for peer in votes:
			if int(votes[peer]) == i:
				names.append(str(UIApi.by_peer(players, peer).get("name", "?")))
		if not names.is_empty():
			row.add_child(UIKit.para(tr("SPAETI_VOTES_BY") % ", ".join(names), 14, UITheme.BLUE))
		v[1].add_child(row)
	return v[0]


func _bottom(meta: Dictionary, me: Dictionary) -> Control:
	var h := UIKit.hbox(14)
	var others := UIKit.vbox(0)
	others.custom_minimum_size.x = 230
	var players: Dictionary = meta.get("players", {})
	if players.size() > 1:
		for peer in players:
			if str(peer) == str(UIApi.local_id()):
				continue
			var p: Dictionary = players[peer]
			var ready := bool(p.get("ready", false))
			others.add_child(UIKit.label("%s: %s" % [str(p.get("name", "?")), tr("LOBBY_IS_READY") if ready else tr("SPAETI_STILL_SHOPPING")],
				16, UITheme.GREEN if ready else UITheme.INK_SOFT))
	h.add_child(others)
	if _quote_id != "":
		var q := Quotes.get_quote(_quote_id)
		var qv := UIKit.vbox(0)
		qv.size_flags_horizontal = SIZE_EXPAND_FILL
		qv.add_child(UIKit.label(tr("SPAETI_QUOTE"), 15, UITheme.INK_SOFT))
		qv.add_child(UIKit.type_label("„%s“ — %s" % [q.get("zitat", ""), Quotes.source_label(q)], 13, UITheme.INK))
		h.add_child(qv)
	else:
		h.add_child(UIKit.spacer())
	var ready := bool(me.get("ready", false))
	var rb := _btn(tr("SPAETI_READY_ON") if ready else tr("SPAETI_READY"), "ready", _on_ready, 28)
	rb.toggle_mode = true
	rb.set_pressed_no_signal(ready)
	rb.custom_minimum_size = Vector2(210, 56)
	UIKit.tilt(rb, -1.5)
	h.add_child(rb)
	return h


# --- Actions ----------------------------------------------------------------

func _deny() -> void:
	UIApi.sfx("error")


func _on_levelup(i: int) -> void:
	UIApi.sfx("levelup")
	UIApi.request("levelup", i)


func _on_buy(i: int) -> void:
	var me := _me()
	var offers: Array = me.get("offers", [])
	if i >= offers.size() or offers[i].get("sold", false):
		_deny()
		return
	var price := int(offers[i].get("price", 0))
	var spend := int(me.get("spend_left", -1))
	if price > int(me.get("pfand", 0)) or (spend >= 0 and price > spend):
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("buy", i)


func _on_reroll() -> void:
	var me := _me()
	if int(me.get("free_rerolls", 0)) <= 0 and int(me.get("reroll_price", 0)) > int(me.get("pfand", 0)):
		_deny()
		return
	UIApi.sfx("ui_click")
	UIApi.request("reroll")


func _on_sell(i: int) -> void:
	UIApi.sfx("buy")
	UIApi.request("sell", i)


func _on_kasse_in() -> void:
	if int(_me().get("pfand", 0)) <= 0:
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("kasse_in")


func _on_kasse_out() -> void:
	if int(_meta().get("kasse", 0)) <= 0:
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("kasse_out")


func _on_repair() -> void:
	if int(_meta().get("repair_price", 0)) > int(_me().get("pfand", 0)):
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("repair_wall")


func _on_vote(i: int) -> void:
	UIApi.sfx("vote")
	UIApi.request("vote", i)


func _on_ready() -> void:
	UIApi.sfx("ui_click")
	UIApi.request("ready", not bool(_me().get("ready", false)))


## Two scribbled strokes across a sold offer.
class CrossOut extends Control:
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var m := 10.0
		draw_line(Vector2(m, m), size - Vector2(m, m), UITheme.RED, 4.0)
		draw_line(Vector2(size.x - m, m + 4), Vector2(m + 3, size.y - m), UITheme.RED, 3.0)
