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
## Scroll positions (by ScrollContainer name) carried over a rebuild, so lists
## don't jump to the top when something changes.
var _keep_scroll := {}
## Overlays on top of the Späti (children of this node, outside _root_box, so
## a rebuild of the Späti keeps them open).
var _stats: StatsPanel
var _options: Control
## Small modal on top (Verkaufen?/Kombinieren?/Wegwerfen). While it is open,
## _root_box takes no focus, so keyboard/gamepad stay inside the dialog.
var _dialog: UIDialog
## Side column (Kasse, Mauer, Vertrag); scrolls with the right stick (GDD §19b).
var _side_scroll: ScrollContainer

## LB / RB jump between these sections (GDD §19b), in this order.
const SECTIONS := ["sec_offers", "sec_weapons", "sec_items", "sec_kasse", "sec_wall", "sec_vertrag",
	"sec_ready", "sec_stats"]
## D-pad / stick / arrow keys stay inside the focused section (GDD §19b).
const NAV_SIDES := {"ui_left": SIDE_LEFT, "ui_right": SIDE_RIGHT, "ui_up": SIDE_TOP, "ui_down": SIDE_BOTTOM}


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
	InputGlyphs.ensure_actions()
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


func _process(delta: float) -> void:
	if _top_overlay() == null:
		UINav.stick_scroll(_side_scroll, delta)


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
	if c and _root_box and _root_box.is_ancestor_of(c):
		_focus_name = c.name


## Topmost open overlay (Optionen above Statistik), or null.
func _top_overlay() -> Control:
	for o in [_dialog, _options, _stats]:
		if o != null and is_instance_valid(o) and not (o as Node).is_queued_for_deletion():
			return o
	return null


## Esc / gamepad B: close an open overlay first. Without one, the event is left
## alone and the run screen opens the pause menu as usual.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if InputMap.has_action("ui_page_left") and event.is_action_pressed("ui_page_left"):
		_jump_section(-1)
		return
	if InputMap.has_action("ui_page_right") and event.is_action_pressed("ui_page_right"):
		_jump_section(1)
		return
	if _keep_in_section(event):
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	var o := _top_overlay()
	if o == null:
		return
	# Something above the Späti (pause menu) has focus: not ours to close.
	var f := get_viewport().gui_get_focus_owner()
	if f != null and not is_ancestor_of(f):
		return
	get_viewport().set_input_as_handled()
	# The run screen polls the "pause" action (also Esc) in _process; release
	# it so closing an overlay doesn't also open the pause menu.
	if InputMap.has_action("pause"):
		Input.action_release("pause")
	o.call("close")


## LB / RB: focus the first control of the previous / next section that has
## one. Only while no overlay or dialog is open.
func _jump_section(dir: int) -> void:
	if _top_overlay() != null:
		return
	var f := get_viewport().gui_get_focus_owner()
	if f != null and not _root_box.is_ancestor_of(f):
		return  # pause menu or similar on top
	get_viewport().set_input_as_handled()
	var cur := -1
	for i in SECTIONS.size():
		var sec := _root_box.find_child(SECTIONS[i], true, false) as Control
		if sec and f and sec.is_ancestor_of(f):
			cur = i
			break
	if cur < 0:
		cur = -1 if dir > 0 else SECTIONS.size()
	for step in range(1, SECTIONS.size() + 1):
		var sec := _root_box.find_child(SECTIONS[posmod(cur + dir * step, SECTIONS.size())], true, false) as Control
		if sec == null or not sec.is_visible_in_tree():
			continue
		var target := UIKit.first_focusable(sec)
		if target and UINav.can_focus(target):
			UIApi.sfx("ui_click")
			target.grab_focus()
			return


## A direction step that would leave the focused section goes to the nearest
## control of that section in that direction instead, or nowhere. Only LB / RB
## change the section. True if the event was handled here.
func _keep_in_section(event: InputEvent) -> bool:
	var side := -1
	for a in NAV_SIDES:
		if InputMap.has_action(a) and event.is_action_pressed(a, true):
			side = NAV_SIDES[a]
			break
	if side < 0 or _top_overlay() != null:
		return false
	var f := get_viewport().gui_get_focus_owner()
	var sec := _section_of(f)
	if sec == null:
		return false
	var next := f.find_valid_focus_neighbor(side)
	if next != null and sec.is_ancestor_of(next):
		return false  # Godot's own step stays inside
	get_viewport().set_input_as_handled()
	var best := _nearest_in(sec, f, side)
	if best != null:
		best.grab_focus()
	return true


func _section_of(c: Control) -> Control:
	var n: Node = c
	while n != null and n != _root_box:
		if SECTIONS.has(String(n.name)):
			return n as Control
		n = n.get_parent()
	return null


## The focusable control in `sec` closest to `from` in direction `side`
## (sideways offset counts double), or null.
func _nearest_in(sec: Control, from: Control, side: int) -> Control:
	var dir: Vector2 = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN][side]
	var origin := from.get_global_rect().get_center()
	var best: Control = null
	var best_score := INF
	for c in sec.find_children("*", "Control", true, false):
		if c == from or not UINav.can_focus(c):
			continue
		var d := (c as Control).get_global_rect().get_center() - origin
		var along := d.dot(dir)
		if along < 4.0:
			continue
		var score := along + absf(d.dot(dir.orthogonal())) * 2.0
		if score < best_score:
			best_score = score
			best = c as Control
	return best


func open_stats() -> void:
	if _stats != null and is_instance_valid(_stats):
		return
	UIApi.sfx("ui_click")
	_stats = StatsPanel.new()
	_stats.name = "StatsOverlay"
	_stats.closed.connect(_on_overlay_closed.bind("stats"))
	add_child(_stats)
	_stats.show_stats(_meta(), _me())
	if _options != null and is_instance_valid(_options):
		move_child(_options, -1)


func open_options() -> void:
	if _options != null and is_instance_valid(_options):
		return
	UIApi.sfx("ui_click")
	_options = OptionsScreen.new()
	_options.name = "OptionsOverlay"
	_options.connect("closed", _on_overlay_closed.bind("options"))
	add_child(_options)


func _on_overlay_closed(which: String) -> void:
	if which == "stats":
		_stats = null
	else:
		_options = null
	var top := _top_overlay()
	if top is StatsPanel:
		(top as StatsPanel).focus_close()
		return
	if top != null:
		UIKit.focus_first(top)
		return
	var b := _root_box.find_child(which, true, false) as Control
	if b:
		UIKit.focus_later(b)
	else:
		UIKit.focus_first(_root_box)


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
		if not (e is Array) or e.size() < 2 or str(e[1]) != str(UIApi.local_id()):
			continue
		if e[0] == "deny":
			UIApi.sfx("error")
			if e.size() >= 3:
				ToastLayer.show_text(tr(str(e[2])))
		elif e[0] == "combine" and e.size() >= 4:
			# ["combine", peer, weapon_id, new_tier] (architecture §11)
			ToastLayer.show_text(tr("SPAETI_COMBINED") % [UIKit.content_text("WEAPON", str(e[2])), UIKit.roman(int(e[3]))])


## Index of another weapon with the same id and tier (< IV) than `skip`, or -1
## (mirrors Sim.find_twin).
static func find_twin(weapons: Array, id: String, tier: int, skip := -1) -> int:
	if tier >= 4:
		return -1
	for i in weapons.size():
		var w = weapons[i]
		if i != skip and w is Dictionary and str(w.get("id", "")) == id and int(w.get("tier", 1)) == tier:
			return i
	return -1


## Buying this weapon offer would merge it with an owned twin (architecture §11).
static func offer_combines(o: Dictionary, me: Dictionary) -> bool:
	if str(o.get("kind", "item")) != "weapon":
		return false
	return find_twin(me.get("weapons", []), str(o.get("id", "")), int(o.get("tier", 1))) >= 0


## Why the local player can't buy this offer right now ("" = buyable).
static func buy_block_reason(o: Dictionary, me: Dictionary) -> String:
	if o.get("sold", false):
		return ""
	var price := int(o.get("price", 0))
	if str(o.get("kind", "item")) == "weapon" and not offer_combines(o, me):
		var weapons: Array = me.get("weapons", [])
		if weapons.size() >= int(me.get("max_weapons", Content.MAX_WEAPONS)):
			return "DENY_SLOTS_FULL"
	var spend := int(me.get("spend_left", -1))
	if spend >= 0 and price > spend:
		return "DENY_SPEND_LIMIT"
	if price > int(me.get("pfand", 0)):
		return "DENY_NO_PFAND"
	return ""


# --- Build ------------------------------------------------------------------

func _rebuild() -> void:
	var keep := _focus_name
	_last_hash = _state_hash()
	# A restore still pending (two rebuilds in one frame) wins over the fresh, unscrolled lists.
	if _keep_scroll.is_empty():
		for s in _root_box.find_children("*", "ScrollContainer", true, false):
			_keep_scroll[String(s.name)] = (s as ScrollContainer).scroll_vertical
	UIKit.clear(_root_box)
	var meta := _meta()
	var me := _me()
	if me.is_empty():
		var c := CenterContainer.new()
		c.size_flags_vertical = SIZE_EXPAND_FILL
		c.add_child(UIKit.label(tr("SPAETI_EMPTY"), 28, UITheme.INK_SOFT))
		_root_box.add_child(c)
		_keep_scroll.clear()
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
	_restore_scroll.call_deferred()
	UINav.sync_disabled(_root_box)
	if _stats != null and is_instance_valid(_stats):
		_stats.show_stats(meta, me)
	if _top_overlay() != null:
		return  # focus stays in the overlay
	if keep != "":
		var target := _root_box.find_child(keep, true, false) as Control
		if target and UINav.can_focus(target):
			UIKit.focus_later(target)
		else:
			UIKit.focus_first(_root_box)


## Puts the lists back where they were before the rebuild. Waits for the new
## content to be laid out first: before that, the scroll range is still 0.
func _restore_scroll() -> void:
	if _keep_scroll.is_empty() or not is_inside_tree():
		return
	var keep := _keep_scroll.duplicate()
	_apply_scroll(keep)  # usually laid out already (no visible jump) ...
	await get_tree().process_frame
	_apply_scroll(keep)  # ... else one frame later
	if _keep_scroll == keep:
		_keep_scroll.clear()


func _apply_scroll(keep: Dictionary) -> void:
	for n in keep:
		var s := _root_box.find_child(n, true, false) as ScrollContainer
		if s:
			s.scroll_vertical = int(keep[n])


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
	# The flavour line gives way first (ellipsis, full text as tooltip), so the
	# header never gets wider than the screen (gamepad hint + spend limit + portrait).
	wave_l.size_flags_horizontal = SIZE_EXPAND_FILL
	wave_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	wave_l.custom_minimum_size.x = 90
	wave_l.mouse_filter = MOUSE_FILTER_PASS
	wave_l.tooltip_text = wave_l.text
	h.add_child(wave_l)
	h.add_child(_portrait(meta, me))
	var spend := int(me.get("spend_left", -1))
	if spend >= 0:
		var sl := UIKit.label(tr("SPAETI_SPEND_LEFT") % [spend, UIKit.currency(meta)], 20, UITheme.RED)
		sl.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(sl)
	# Reichensteuer of the last wave (balancing.md §5a)
	var tax := int(me.get("tax_wave", 0))
	if tax != 0:
		var tl := UIKit.label((tr("SPAETI_TAX_PAID") if tax < 0 else tr("SPAETI_TAX_RECEIVED")) % [absi(tax), UIKit.currency(meta)],
			17, UITheme.INK_SOFT if tax < 0 else UITheme.GREEN)
		tl.name = "tax_wave"
		tl.size_flags_vertical = SIZE_SHRINK_CENTER
		UIKit.fit_label(tl, 220, 12)
		h.add_child(tl)
	var pad_hint := UIKit.label("", 17, UITheme.INK_SOFT)
	pad_hint.name = "section_hint"
	pad_hint.size_flags_vertical = SIZE_SHRINK_CENTER
	InputGlyphs.bind(pad_hint, "text", func() -> String:
		return InputGlyphs.fmt("SPAETI_SECTIONS_HINT", ["ui_page_left", "ui_page_right"]))
	InputGlyphs.show_on_pad(pad_hint)
	h.add_child(pad_hint)
	var stats_b := UIKit.compact(_btn(tr("SPAETI_STATS_BUTTON"), "stats", open_stats, 20), 2, 12)
	InputGlyphs.bind(stats_b, "tooltip_text", func() -> String:
		return InputGlyphs.fmt("SPAETI_STATS_BUTTON_TIP", ["ui_cancel"]))
	stats_b.size_flags_vertical = SIZE_SHRINK_CENTER
	UIKit.tilt(stats_b, 1.2)
	h.add_child(stats_b)
	var opt_b := UIKit.compact(_btn(tr("MENU_OPTIONS"), "options", open_options, 20), 2, 12)
	opt_b.size_flags_vertical = SIZE_SHRINK_CENTER
	UIKit.tilt(opt_b, -0.8)
	h.add_child(opt_b)
	var money := UIKit.card(UITheme.YELLOW.lerp(UITheme.PAPER, 0.55), UITheme.INK, 1.5, 3)
	var ml := UIKit.label("%d %s" % [int(me.get("pfand", 0)), UIKit.currency(meta)], 30)
	money.add_child(ml)
	if meta.get("blackrock", false):
		money.tooltip_text = tr("SPAETI_AKTIEN_TIP")
	h.add_child(money)
	return h


## Small, calm character portrait in the header (GDD §6): the local character as
## drawn in the arena at the current Zusammenhalt stage, the stage name and a
## thin bar to the next level. No panel, no weapons; it sits in the header's
## free space and never makes the header taller.
func _portrait(meta: Dictionary, me: Dictionary) -> Control:
	var team = meta.get("team", {})
	if not (team is Dictionary):
		team = {}
	var st := clampi(int(team.get("stage", 0)), 0, 4)
	var lvl := int(team.get("level", 0))
	var xp := float(team.get("xp", 0.0))
	var need := maxf(float(team.get("need", 1.0)), 1.0)
	var box := UIKit.hbox(4)
	box.name = "portrait"
	box.size_flags_vertical = SIZE_SHRINK_CENTER
	box.mouse_filter = MOUSE_FILTER_PASS
	box.tooltip_text = "%s · %s\n%d / %d" % [tr("HUD_ZUSAMMENHALT"), tr("HUD_LEVEL") % lvl, int(xp), int(need)]
	var pic := CharPortrait.new()
	pic.char_id = str(me.get("char", ""))
	pic.stage = st
	pic.max_scale = 0.85
	pic.custom_minimum_size = Vector2(56, 50)
	box.add_child(pic)
	var col := UIKit.vbox(2)
	col.size_flags_vertical = SIZE_SHRINK_CENTER
	col.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(col)
	var stage_col := Doodle.desat(Color(0.85, 0.35, 0.1), st).darkened(0.2)
	var name_l := UIKit.label(tr("STAGE_%d" % st), 18, stage_col)
	name_l.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(name_l)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(92, 7)
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	var k := clampf(xp / need, 0.0, 1.0)
	bar.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, bar.size)
		bar.draw_rect(r, Color(1, 1, 1, 0.6))
		bar.draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), Color(0.95, 0.65, 0.15))
		bar.draw_polyline(Doodle.rect_pts(r, 2, 0.6), UITheme.INK, 1.2))
	col.add_child(bar)
	return box


func _stats_card(me: Dictionary) -> Control:
	var parts := _card(tr("SPAETI_STATS"), -0.7)
	parts[0].name = "sec_stats"
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
		n.name = "stat_" + stat
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.mouse_filter = MOUSE_FILTER_PASS
		n.tooltip_text = UIKit.trk("STAT_%s_DESC" % stat.to_upper())
		# Gamepad/keyboard: focusable so the description shows (FocusTips).
		n.focus_mode = FOCUS_ALL
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
		lp[0].name = "sec_offers"
		lp[1].add_child(UIKit.para(tr("SPAETI_LEVELUP_HINT"), 18, UITheme.INK_SOFT))
		lp[0].tooltip_text = tr("SPAETI_LEVELUP_TOOLTIP")
		var row := UIKit.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_vertical = SIZE_EXPAND_FILL
		for i in options.size():
			var o: Dictionary = options[i]
			var stat := str(o.get("stat", ""))
			var stat_label := UIKit.stat_name(stat)
			# Shrink long names (Durchschlagskraft, Ziviler Ungehorsam …) until they fit on one line.
			var fs := 22
			while fs > 13 and UITheme.hand().get_string_size(stat_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 132.0:
				fs -= 1
			var b := _btn("%s\n%s" % [stat_label, UIKit.signed(float(o.get("amount", 0.0)))],
				"levelup_%d" % i, _on_levelup.bind(i), fs)
			b.custom_minimum_size = Vector2(150, 110)
			b.autowrap_mode = TextServer.AUTOWRAP_OFF
			# Rarity like the items, by color only (balancing.md §4).
			var rcol: Color = Content.RARITY_COLORS.get(int(o.get("rarity", 1)), UITheme.INK)
			b.add_theme_stylebox_override("normal", UITheme.box(rcol.lerp(UITheme.PAPER, 0.88), rcol, 3))
			b.add_theme_color_override("font_color", rcol.darkened(0.25))
			b.tooltip_text = UIKit.trk("STAT_%s_DESC" % stat.to_upper())
			UIKit.tilt(b, UIKit.tilt_for(i, 1.2))
			row.add_child(b)
		lp[1].add_child(row)
		# Level-up reroll (GDD §6): free rerolls first, then its own rising price.
		var lfree := int(me.get("free_rerolls", 0))
		var lprice := int(me.get("levelup_reroll_price", 0))
		var lr_row := UIKit.hbox(0)
		lr_row.alignment = BoxContainer.ALIGNMENT_CENTER
		var lr := UIKit.compact(_btn(tr("SPAETI_REROLL_FREE") % lfree if lfree > 0 else tr("SPAETI_REROLL") % [lprice, UIKit.currency(meta)],
			"levelup_reroll", _on_levelup_reroll, 18), 0, 10)
		lr.tooltip_text = tr("SPAETI_LEVELUP_REROLL_TIP")
		lr_row.add_child(lr)
		lp[1].add_child(lr_row)
		lp[0].size_flags_vertical = SIZE_EXPAND_FILL
		return lp[0]

	var parts := _card("", 0.4)
	parts[0].name = "sec_offers"
	var head := UIKit.hbox(10)
	head.add_child(UIKit.label(tr("SPAETI_OFFERS"), 22, UITheme.RED))
	head.add_child(UIKit.spacer())
	var free := int(me.get("free_rerolls", 0))
	var reroll_text := tr("SPAETI_REROLL_FREE") % free if free > 0 else tr("SPAETI_REROLL") % [int(me.get("reroll_price", 0)), UIKit.currency(_meta())]
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
	# Slots removed by the Koalitionsvertrag (Bürokratieabbau) stay visible as stamped cards.
	var vertrag: Dictionary = meta.get("vertrag", {})
	var cut := -int(Content.VERTRAG.get(str(vertrag.get("active", "")), {}).get("offers", 0))
	if not offers.is_empty():
		for i in cut:
			grid.add_child(_cut_slot_card(str(vertrag.get("active", ""))))
	parts[1].add_child(grid)
	return parts[0]


func _cut_slot_card(vertrag_id: String) -> Control:
	var c := UIKit.card(UITheme.PAPER_DARK, UITheme.GREY, 1.2)
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(300, 112)
	var v := UIKit.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var stamp := UIKit.label(tr("SPAETI_SLOT_CUT"), 24, UITheme.RED)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.rotation_degrees = -4.0
	v.add_child(stamp)
	var why := UIKit.para(tr("SPAETI_SLOT_CUT_WHY") % UIKit.content_text("VERTRAG", vertrag_id), 15, UITheme.INK_SOFT)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(why)
	c.tooltip_text = UIKit.content_text("VERTRAG", vertrag_id, "DESC")
	return c


func _offer_card(i: int, o: Dictionary, meta: Dictionary, me: Dictionary) -> Control:
	var weapon := str(o.get("kind", "item")) == "weapon"
	var id := str(o.get("id", ""))
	var kind := "WEAPON" if weapon else "ITEM"
	var sold := bool(o.get("sold", false))
	var price := int(o.get("price", 0))
	# Items: border and tag in their rarity color (GDD §12); red = build item.
	var rarity := 0 if weapon else UIKit.item_rarity(id, o)
	var rcol := UIKit.rarity_color(rarity) if rarity > 0 else UITheme.INK
	var bg := Color.WHITE.lerp(UITheme.PAPER, 0.5)
	if rarity == 4:
		bg = bg.lerp(rcol, 0.1)
	var c := UIKit.card(bg, rcol, UIKit.tilt_for(i, 0.6), 2 if rarity <= 1 else 3)
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
	if weapon:
		top.add_child(UIKit.label(tr("SPAETI_WEAPON_TIER") % UIKit.roman(int(o.get("tier", 1))), 16, UITheme.BLUE))
	else:
		top.add_child(UIKit.label(tr("SPAETI_ITEM"), 16, rcol))
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
	var block := buy_block_reason(o, me)
	bottom.add_child(UIKit.label("%d %s" % [price, UIKit.currency(meta)], 19, UITheme.INK if block == "" else UITheme.RED))
	if block != "":
		var why := UIKit.label(tr(block + "_SHORT"), 14, UITheme.RED)
		why.tooltip_text = tr(block)
		why.mouse_filter = MOUSE_FILTER_PASS
		bottom.add_child(why)
	elif not sold and offer_combines(o, me):
		var hint := UIKit.label(tr("SPAETI_OFFER_COMBINES") % UIKit.roman(int(o.get("tier", 1)) + 1), 15, UITheme.GREEN)
		hint.name = "combines_%d" % i
		hint.tooltip_text = tr("SPAETI_OFFER_COMBINES_TIP")
		hint.mouse_filter = MOUSE_FILTER_PASS
		bottom.add_child(hint)
	bottom.add_child(UIKit.spacer())
	var b := UIKit.compact(_btn(tr("SPAETI_SOLD") if sold else tr("SPAETI_BUY"), "buy_%d" % i, _on_buy.bind(i), 18), 0, 10)
	b.disabled = sold or block != ""
	# Name and description, also for gamepad players (shown on focus).
	b.tooltip_text = "%s\n%s" % [UIKit.content_text(kind, id), UIKit.content_text(kind, id, "DESC")]
	if block != "":
		b.tooltip_text += "\n" + tr(block)
	elif not sold and offer_combines(o, me):
		b.tooltip_text += "\n" + tr("SPAETI_OFFER_COMBINES_TIP")
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
	parts[0].name = "sec_weapons"
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 2)
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
		# A twin (same id and tier < IV) can be merged into the next tier.
		var twin := find_twin(weapons, id, tier, i)
		if twin >= 0:
			var cb := UIKit.compact(_btn(tr("SPAETI_COMBINE") % UIKit.roman(tier + 1), "combine_%d" % i,
				_ask_combine.bind(i), 15), 0, 6)
			cb.add_theme_color_override("font_color", UITheme.GREEN)
			cb.tooltip_text = "%s\n%s" % [tr("SPAETI_COMBINE_TIP"), n.tooltip_text]
			row.add_child(cb)
		var refund := _sell_refund(meta, w)
		var b := UIKit.compact(_btn(tr("SPAETI_SELL") % refund, "sell_%d" % i, _ask_sell.bind(i), 15), 0, 6)
		b.disabled = weapons.size() <= 1
		b.tooltip_text = "%s %s\n%s" % [UIKit.content_text("WEAPON", id), UIKit.roman(tier), n.tooltip_text]
		row.add_child(b)
		grid.add_child(row)
	if weapons.is_empty():
		parts[1].add_child(UIKit.para(tr("SPAETI_NO_WEAPONS"), 17, UITheme.GREY))
	parts[1].add_child(grid)
	return parts[0]


func _items_card(me: Dictionary) -> Control:
	var parts := _card(tr("SPAETI_ITEMS"), 0.3)
	parts[0].name = "sec_items"
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
	for j in order.size():
		var id := str(order[j])
		var count := int(counts[id])
		var text := UIKit.content_text("ITEM", id)
		if count > 1:
			text += " ×%d" % count
		# Chip = button tinted by rarity; click opens the Wegwerfen dialog.
		var rarity := UIKit.item_rarity(id)
		var rcol := UIKit.rarity_color(rarity)
		var chip := _btn(text, "item_%d" % j, _ask_discard.bind(id), 16)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			chip.add_theme_stylebox_override(state, _chip_box(rcol, state))
		chip.add_theme_color_override("font_color", UITheme.INK)
		var tip_head := "%s\n%s\n" % [UIKit.content_text("ITEM", id), UIKit.content_text("ITEM", id, "DESC")]
		InputGlyphs.bind(chip, "tooltip_text", func() -> String:
			return tip_head + (InputGlyphs.fmt("SPAETI_ITEM_PAD_TIP", ["ui_accept"]) if InputGlyphs.using_pad()
				else tr("SPAETI_ITEM_CLICK_TIP")))
		flow.add_child(chip)
	# Long item lists scroll inside the card instead of pushing the Bereit bar off screen.
	var scroll := ScrollContainer.new()
	scroll.name = "items_scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 40
	flow.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(flow)
	parts[1].size_flags_vertical = SIZE_EXPAND_FILL
	parts[1].add_child(scroll)
	return parts[0]


## Owned-item chip: rarity-tinted paper, rarity border (thicker on hover/focus).
func _chip_box(rcol: Color, state := "normal") -> StyleBox:
	if state == "focus":
		var f := UITheme.focus_box(5)
		_tight(f)
		return f
	var hot := state == "hover" or state == "pressed"
	var bg := rcol.lerp(UITheme.PAPER, 0.62 if hot else 0.8)
	var s := UITheme.box(bg, rcol.darkened(0.15), 2 if hot else 1, 4)
	_tight(s)
	return s


func _tight(s: StyleBoxFlat) -> void:
	s.content_margin_left = 7
	s.content_margin_right = 7
	s.content_margin_top = 0
	s.content_margin_bottom = 2


## What selling this weapon pays (the Sim prices it for the coming wave).
static func _sell_refund(meta: Dictionary, w: Dictionary) -> int:
	var id := str(w.get("id", ""))
	if not Content.WEAPONS.has(id):
		return 0
	return Content.sell_price(id, int(w.get("tier", 1)), int(meta.get("wave", 1)) + 1)


func _side_column(meta: Dictionary, me: Dictionary) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "side_scroll"
	scroll.custom_minimum_size.x = 320
	_side_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := UIKit.vbox(10)
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(col)

	# Koalitionskasse (co-op only).
	var cur := UIKit.currency(meta)
	var kasse_on := bool(meta.get("kasse_enabled", false))
	var k := _card(tr("SPAETI_KASSE") % [int(meta.get("kasse", 0)), cur], 0.8)
	k[0].name = "sec_kasse"
	var kr := UIKit.hbox(8)
	var bin := _btn(tr("SPAETI_KASSE_IN") % int(meta.get("kasse_in", 10)), "kasse_in", _on_kasse_in, 17)
	var bout := _btn(tr("SPAETI_KASSE_OUT") % [int(meta.get("kasse_out", 20)), int(meta.get("kasse_payout", 15))], "kasse_out", _on_kasse_out, 17)
	bin.size_flags_horizontal = SIZE_EXPAND_FILL
	bout.size_flags_horizontal = SIZE_EXPAND_FILL
	kr.add_child(bin)
	kr.add_child(bout)
	k[1].add_child(kr)
	k[1].add_child(UIKit.label(tr("SPAETI_KASSE_MINE") % [int(me.get("paid_in", 0)), int(me.get("taken_out", 0))], 16, UITheme.INK_SOFT))
	# Mouseover explanation on the whole card and its buttons.
	var kasse_tip := tr("SPAETI_KASSE_TOOLTIP")
	for c in [k[0], bin, bout]:
		c.tooltip_text = kasse_tip
	if kasse_on:
		col.add_child(k[0])
	else:
		k[0].queue_free()

	# Brandmauer.
	var holes := int(meta.get("wall_holes", 0))
	var w := _card(tr("SPAETI_WALL"), -0.6)
	w[0].name = "sec_wall"
	if holes > 0:
		var holes_text := tr("SPAETI_WALL_HOLE_ONE") if holes == 1 else tr("SPAETI_WALL_HOLES") % holes
		w[1].add_child(UIKit.label(holes_text, 18, UITheme.RED))
		var rb := _btn(tr("SPAETI_REPAIR") % [int(meta.get("repair_price", 0)), cur], "repair", _on_repair, 18)
		w[1].add_child(rb)
		if kasse_on:
			var kb := _btn(tr("SPAETI_REPAIR_KASSE") % [int(meta.get("repair_price_kasse", 0)), cur], "repair_kasse", _on_repair_kasse, 16)
			kb.tooltip_text = tr("SPAETI_REPAIR_KASSE_TOOLTIP")
			w[1].add_child(kb)
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
		a[0].name = "sec_vertrag"
		var vname := UIKit.content_text("VERTRAG", str(vertrag["active"]))
		var left := int(vertrag.get("waves_left", 0))
		var active_text := tr("SPAETI_VERTRAG_ACTIVE_ONE") % vname if left == 1 else tr("SPAETI_VERTRAG_ACTIVE") % [vname, left]
		a[1].add_child(UIKit.para(active_text, 17))
		a[1].add_child(UIKit.para(UIKit.content_text("VERTRAG", str(vertrag["active"]), "DESC"), 15, UITheme.INK_SOFT))
		col.add_child(a[0])
	return scroll


## The local player's vote: -1 = abstained, -2 = not voted yet.
static func my_vote(meta: Dictionary) -> int:
	var vertrag: Dictionary = meta.get("vertrag", {})
	var votes: Dictionary = vertrag.get("votes", {})
	for peer in votes:
		if str(peer) == str(UIApi.local_id()):
			return int(votes[peer])
	return -2


## A Koalitionsvertrag vote is open and the local player hasn't voted or
## abstained: the Sim refuses "ready" (DENY_VOTE_FIRST).
static func vote_pending(meta: Dictionary) -> bool:
	var vertrag: Dictionary = meta.get("vertrag", {})
	var opts: Array = vertrag.get("options", [])
	return not opts.is_empty() and my_vote(meta) == -2


func _vertrag_card(meta: Dictionary, _me: Dictionary, vertrag: Dictionary, opts: Array) -> Control:
	var pending := vote_pending(meta)
	var v := _card(tr("SPAETI_VERTRAG"), 0.5, UITheme.YELLOW.lerp(UITheme.PAPER, 0.6) if pending else UITheme.BLUE.lerp(UITheme.PAPER, 0.85))
	v[0].name = "sec_vertrag"
	if pending:
		# Highlight: the vote blocks "Bereit".
		v[0].add_theme_stylebox_override("panel", UITheme.box(UITheme.YELLOW.lerp(UITheme.PAPER, 0.6), UITheme.RED, 4))
		var p := UIKit.label(tr("SPAETI_VERTRAG_PENDING"), 19, UITheme.RED)
		UIKit.tilt(p, -1.5)
		v[1].add_child(p)
	v[1].add_child(UIKit.para(tr("SPAETI_VERTRAG_HINT"), 16, UITheme.RED))
	var votes: Dictionary = vertrag.get("votes", {})
	var players: Dictionary = meta.get("players", {})
	var mine := my_vote(meta)
	for i in opts.size():
		var id := str(opts[i])
		var row := UIKit.vbox(0)
		var h := UIKit.hbox(6)
		var n := UIKit.label(UIKit.content_text("VERTRAG", id), 19)
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(n)
		var b := _btn(tr("SPAETI_VOTED") if mine == i else tr("SPAETI_VOTE"), "vote_%d" % i, _on_vote.bind(i), 16)
		b.tooltip_text = "%s\n%s" % [UIKit.content_text("VERTRAG", id), UIKit.content_text("VERTRAG", id, "DESC")]
		b.toggle_mode = true
		b.set_pressed_no_signal(mine == i)
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
	# Abstain (vote -1): counts as "voted", but doesn't pick an option.
	var ah := UIKit.hbox(8)
	var ab := UIKit.compact(_btn(tr("SPAETI_ABSTAINED") if mine == -1 else tr("SPAETI_ABSTAIN"), "vote_abstain",
		_on_vote.bind(-1), 16), 1, 10)
	ab.toggle_mode = true
	ab.set_pressed_no_signal(mine == -1)
	ab.tooltip_text = tr("SPAETI_ABSTAIN_TIP")
	ah.add_child(ab)
	var abstained := []
	for peer in votes:
		if int(votes[peer]) == -1:
			abstained.append(str(UIApi.by_peer(players, peer).get("name", "?")))
	if not abstained.is_empty():
		var al := UIKit.para(tr("SPAETI_ABSTAINED_BY") % ", ".join(abstained), 14, UITheme.INK_SOFT)
		al.size_flags_horizontal = SIZE_EXPAND_FILL
		al.size_flags_vertical = SIZE_SHRINK_CENTER
		ah.add_child(al)
	v[1].add_child(ah)
	return v[0]


func _bottom(meta: Dictionary, me: Dictionary) -> Control:
	var h := UIKit.hbox(14)
	h.name = "sec_ready"
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
		var ctx := Quotes.context_label(q)
		qv.add_child(UIKit.type_label("„%s“ — %s%s" % [q.get("zitat", ""), Quotes.source_label(q), (" · " + ctx) if ctx != "" else ""], 13, UITheme.INK))
		h.add_child(qv)
	else:
		h.add_child(UIKit.spacer())
	var ready := bool(me.get("ready", false))
	var rb := _btn(tr("SPAETI_READY_ON") if ready else tr("SPAETI_READY"), "ready", _on_ready, 28)
	rb.toggle_mode = true
	rb.set_pressed_no_signal(ready)
	rb.custom_minimum_size = Vector2(210, 56)
	UIKit.tilt(rb, -1.5)
	UIKit.ready_look(rb, ready)
	if ready:
		rb.tooltip_text = tr("READY_TAKE_BACK_TIP")
		var waiting := []
		for peer in players:
			var p: Dictionary = players[peer]
			if str(peer) != str(UIApi.local_id()) and not bool(p.get("ready", false)) and not bool(p.get("away", false)):
				waiting.append(str(p.get("name", "?")))
		var you := UIKit.vbox(0)
		you.name = "ready_status"
		you.size_flags_vertical = SIZE_SHRINK_CENTER
		you.add_child(UIKit.label(tr("READY_YOU"), 20, UITheme.GREEN, HORIZONTAL_ALIGNMENT_RIGHT))
		if not waiting.is_empty():
			you.add_child(UIKit.label(tr("READY_WAITING_FOR") % ", ".join(waiting), 16, UITheme.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT))
		h.add_child(you)
	elif vote_pending(meta):
		# The Sim refuses "ready" until the local player voted or abstained.
		rb.disabled = true
		rb.tooltip_text = tr("SPAETI_READY_VOTE_FIRST")
		var why := UIKit.label(tr("SPAETI_READY_VOTE_FIRST"), 17, UITheme.RED, HORIZONTAL_ALIGNMENT_RIGHT)
		why.name = "ready_hint"
		why.size_flags_vertical = SIZE_SHRINK_CENTER
		UIKit.tilt(why, -1.0)
		h.add_child(why)
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
	var block := buy_block_reason(offers[i], me)
	if block != "":
		_deny()
		ToastLayer.show_text(tr(block))
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


func _on_levelup_reroll() -> void:
	var me := _me()
	if int(me.get("free_rerolls", 0)) <= 0 and int(me.get("levelup_reroll_price", 0)) > int(me.get("pfand", 0)):
		_deny()
		return
	UIApi.sfx("ui_click")
	UIApi.request("levelup_reroll")


## Opens a dialog on top of the Späti; `focus_back` names the control that
## gets focus again when it closes.
func _open_dialog(d: UIDialog, focus_back: String) -> void:
	if _dialog != null and is_instance_valid(_dialog):
		_dialog.close()
	UIApi.sfx("ui_click")
	_dialog = d
	_dialog.name = "DialogOverlay"
	_dialog.closed.connect(_on_dialog_closed.bind(d, focus_back))
	_root_box.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	add_child(_dialog)


func _on_dialog_closed(d: UIDialog, focus_back: String) -> void:
	if _dialog != d:
		return
	_dialog = null
	_root_box.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	var top := _top_overlay()
	if top is StatsPanel:
		(top as StatsPanel).focus_close()
		return
	if top != null:
		UIKit.focus_first(top)
		return
	var b := _root_box.find_child(focus_back, true, false) as Control
	if b and b.focus_mode != FOCUS_NONE and not (b is BaseButton and (b as BaseButton).disabled):
		UIKit.focus_later(b)
	else:
		UIKit.focus_first(_root_box)


func _weapon_label(w: Dictionary, tier := 0) -> String:
	return "%s %s" % [UIKit.content_text("WEAPON", str(w.get("id", ""))), UIKit.roman(tier if tier > 0 else int(w.get("tier", 1)))]


## "Megafon II verkaufen für 31 Pfand?" (confirm first, then request "sell").
func _ask_sell(i: int) -> void:
	var weapons: Array = _me().get("weapons", [])
	if i < 0 or i >= weapons.size() or weapons.size() <= 1:
		_deny()
		return
	var w: Dictionary = weapons[i]
	var d := ConfirmDialog.new()
	d.title_text = tr("SPAETI_SELL_CONFIRM_TITLE")
	d.body_text = tr("SPAETI_SELL_CONFIRM") % [_weapon_label(w), _sell_refund(_meta(), w), UIKit.currency(_meta())]
	d.note_text = tr("SPAETI_SELL_CONFIRM_NOTE")
	d.ok_text = tr("SPAETI_SELL_CONFIRM_OK")
	d.confirmed.connect(_on_sell.bind(i, str(w.get("id", "")), int(w.get("tier", 1))))
	_open_dialog(d, "sell_%d" % i)


func _on_sell(i: int, id: String, tier: int) -> void:
	# The list may have changed while the dialog was open.
	var weapons: Array = _me().get("weapons", [])
	if i >= weapons.size() or str(weapons[i].get("id", "")) != id or int(weapons[i].get("tier", 1)) != tier:
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("sell", i)


## "Zwei Megafon II zu Megafon III kombinieren?"
func _ask_combine(i: int) -> void:
	var weapons: Array = _me().get("weapons", [])
	if i < 0 or i >= weapons.size():
		_deny()
		return
	var w: Dictionary = weapons[i]
	var tier := int(w.get("tier", 1))
	if find_twin(weapons, str(w.get("id", "")), tier, i) < 0:
		_deny()
		ToastLayer.show_text(tr("DENY_NO_TWIN"))
		return
	var d := ConfirmDialog.new()
	d.title_text = tr("SPAETI_COMBINE_CONFIRM_TITLE")
	d.body_text = tr("SPAETI_COMBINE_CONFIRM") % [_weapon_label(w), _weapon_label(w, tier + 1)]
	d.note_text = tr("SPAETI_COMBINE_CONFIRM_NOTE")
	d.ok_text = tr("SPAETI_COMBINE_CONFIRM_OK")
	d.confirmed.connect(_on_combine.bind(i, str(w.get("id", "")), tier))
	_open_dialog(d, "combine_%d" % i)


func _on_combine(i: int, id: String, tier: int) -> void:
	var weapons: Array = _me().get("weapons", [])
	if i >= weapons.size() or str(weapons[i].get("id", "")) != id or int(weapons[i].get("tier", 1)) != tier:
		_deny()
		return
	UIApi.request("combine", i)


## Click on an owned item: how many to throw away (no refund).
func _ask_discard(id: String) -> void:
	var owned := 0
	var j := 0
	var seen := {}
	var focus_back := ""
	for it in _me().get("items", []):
		if str(it) == id:
			owned += 1
		if not seen.has(str(it)):
			if str(it) == id:
				focus_back = "item_%d" % j
			seen[str(it)] = true
			j += 1
	if owned <= 0:
		_deny()
		return
	var d := DiscardDialog.new()
	d.item_id = id
	d.owned = owned
	d.discard.connect(_on_discard.bind(id))
	_open_dialog(d, focus_back)


func _on_discard(count: int, id: String) -> void:
	UIApi.request("discard_item", {"id": id, "count": count})


func _on_kasse_in() -> void:
	if int(_me().get("pfand", 0)) <= 0:
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("kasse_in")


func _on_kasse_out() -> void:
	if int(_meta().get("kasse", 0)) < int(_meta().get("kasse_out", 20)):
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


func _on_repair_kasse() -> void:
	if int(_meta().get("repair_price_kasse", 0)) > int(_meta().get("kasse", 0)):
		_deny()
		return
	UIApi.sfx("buy")
	UIApi.request("repair_wall_kasse")


func _on_vote(i: int) -> void:
	UIApi.sfx("vote")
	UIApi.request("vote", i)


func _on_ready() -> void:
	var want := not bool(_me().get("ready", false))
	if want and vote_pending(_meta()):
		_deny()
		ToastLayer.show_text(tr("DENY_VOTE_FIRST"))
		return
	UIApi.sfx("ui_click")
	UIApi.request("ready", want)


## Doodle confirmation (Verkaufen?/Kombinieren?). Focus starts on "Abbrechen";
## Esc / gamepad B cancels.
class ConfirmDialog extends UIDialog:
	signal confirmed

	var title_text := ""
	var body_text := ""
	var note_text := ""
	var ok_text := ""

	func build() -> void:
		auto_focus = false
		width = 500.0
		card.custom_minimum_size.x = width
		var t := UIKit.heading(title_text, 32, UITheme.RED)
		UIKit.tilt(t, -1.5)
		content.add_child(t)
		content.add_child(UIKit.para(body_text, 24))
		if note_text != "":
			content.add_child(UIKit.para(note_text, 17, UITheme.INK_SOFT))
		var row := UIKit.hbox(14)
		row.alignment = BoxContainer.ALIGNMENT_END
		var cancel := UIKit.button(tr("UI_CANCEL"), close, 22)
		cancel.name = "cancel"
		var ok := UIKit.button(ok_text, _on_ok, 22)
		ok.name = "ok"
		row.add_child(cancel)
		row.add_child(ok)
		content.add_child(row)
		SpaetiPanel.chain_focus([cancel, ok])
		UIKit.focus_later(cancel)

	func _on_ok() -> void:
		confirmed.emit()
		close()


## "Wegwerfen": pick how many (−/+), or all. No Pfand back (GDD §12).
class DiscardDialog extends UIDialog:
	signal discard(count: int)

	var item_id := ""
	var owned := 1
	var _count := 1
	var _count_label: Label
	var _go: Button

	func build() -> void:
		auto_focus = false
		var rarity := UIKit.item_rarity(item_id)
		var t := UIKit.heading(tr("SPAETI_DISCARD_TITLE") % UIKit.content_text("ITEM", item_id), 30, UITheme.RED)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIKit.tilt(t, -1.2)
		content.add_child(t)
		var sub := UIKit.label(("×%d" % owned) if owned > 1 else "", 17, UIKit.rarity_color(rarity))
		content.add_child(sub)
		var nav: Array = []
		if owned > 1:
			var row := UIKit.hbox(10)
			row.add_child(UIKit.label(tr("SPAETI_DISCARD_HOW_MANY"), 21))
			row.add_child(UIKit.spacer())
			var minus := UIKit.compact(UIKit.button("−", _step.bind(-1), 24), 0, 14)
			minus.name = "minus"
			_count_label = UIKit.label("", 24, UITheme.INK, HORIZONTAL_ALIGNMENT_CENTER)
			_count_label.custom_minimum_size.x = 86
			var plus := UIKit.compact(UIKit.button("+", _step.bind(1), 24), 0, 14)
			plus.name = "plus"
			row.add_child(minus)
			row.add_child(_count_label)
			row.add_child(plus)
			content.add_child(row)
			nav = [minus, plus]
		var stamp := UIKit.stamp(tr("SPAETI_DISCARD_NO_REFUND"), UITheme.RED, -3.0, 20)
		stamp.size_flags_horizontal = SIZE_SHRINK_CENTER
		content.add_child(stamp)
		var buttons := UIKit.hbox(10)
		buttons.alignment = BoxContainer.ALIGNMENT_END
		var cancel := UIKit.button(tr("UI_CANCEL"), close, 21)
		cancel.name = "cancel"
		buttons.add_child(cancel)
		_go = UIKit.button("", _on_go, 21)
		_go.name = "discard"
		buttons.add_child(_go)
		var row_buttons: Array = [cancel, _go]
		if owned > 1:
			var all := UIKit.button(tr("SPAETI_DISCARD_ALL") % owned, _on_all, 21)
			all.name = "discard_all"
			buttons.add_child(all)
			row_buttons.append(all)
		content.add_child(buttons)
		SpaetiPanel.chain_focus(row_buttons)
		if not nav.is_empty():
			SpaetiPanel.chain_focus(nav)
			for b in nav:
				(b as Control).focus_neighbor_bottom = (b as Control).get_path_to(cancel)
			for b in row_buttons:
				(b as Control).focus_neighbor_top = (b as Control).get_path_to(nav[0])
		_refresh()
		UIKit.focus_later(cancel)

	func _step(d: int) -> void:
		_count = clampi(_count + d, 1, owned)
		UIApi.sfx("ui_click")
		_refresh()

	func _refresh() -> void:
		if _count_label:
			_count_label.text = "%d / %d" % [_count, owned]
		_go.text = tr("SPAETI_DISCARD") if owned <= 1 else tr("SPAETI_DISCARD_N") % _count

	func _on_go() -> void:
		discard.emit(_count)
		close()

	func _on_all() -> void:
		discard.emit(-1)
		close()


## Left/right focus wraps within `controls`; up/down stays in the row
## (dialogs keep gamepad focus inside themselves).
static func chain_focus(controls: Array) -> void:
	var n := controls.size()
	for k in n:
		var c: Control = controls[k]
		c.focus_neighbor_left = c.get_path_to(controls[posmod(k - 1, n)])
		c.focus_neighbor_right = c.get_path_to(controls[posmod(k + 1, n)])
		c.focus_neighbor_top = NodePath(".")
		c.focus_neighbor_bottom = NodePath(".")
		c.focus_previous = c.focus_neighbor_left
		c.focus_next = c.focus_neighbor_right


## Two scribbled strokes across a sold offer.
class CrossOut extends Control:
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var m := 10.0
		draw_line(Vector2(m, m), size - Vector2(m, m), UITheme.RED, 4.0)
		draw_line(Vector2(size.x - m, m + 4), Vector2(m + 3, size.y - m), UITheme.RED, 3.0)
