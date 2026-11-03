class_name StatsPanel
extends Control
## Run statistics overlay on top of the Späti (GDD §6c, architecture §10,
## D-152). On top "Letzte Woche": the key values of the last wave, one row per
## player for comparison; below, smaller, "Ganze Runde": the local player's
## damage by source and run totals. Owned by SpaetiPanel, which calls
## `show_stats` only when its own fingerprint changed, so nothing is rebuilt
## per frame. Closed with the button or ui_cancel (Esc / gamepad B).

signal closed

const BAR_W := 110
const SHEET_W := 1150
## Free space kept above and below the sheet.
const SCREEN_MARGIN := 22.0
## "Letzte Woche" number columns: run_stats.last_wave key, header key.
const WAVE_COLS := [["damage", "STATS_COL_DAMAGE"], ["kills", "STATS_KILLS"], ["pfand", "STATS_PFAND_COLLECTED"],
	["dmg_taken", "STATS_COL_TAKEN"], ["healed", "STATS_COL_HEALED"]]

var _body: VBoxContainer
var _subtitle: Label
var _close_btn: Button
var _sheet: PanelContainer
var _main: HBoxContainer
var _dmg_card: Control
var _scroll: ScrollContainer
var _grid: GridContainer


func _ready() -> void:
	UIKit.full(self)
	mouse_filter = MOUSE_FILTER_STOP
	UINav.modal_open(self)
	var dim := ColorRect.new()
	dim.color = Color(UITheme.INK, 0.45)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	UIKit.full(dim)
	add_child(dim)

	# Sized to its content and centered; the damage table scrolls only when
	# it would not fit the screen (see _fit_scroll).
	var center := CenterContainer.new()
	UIKit.full(center)
	add_child(center)
	_sheet = UIKit.card(UITheme.PAPER, UITheme.INK, 0.0, 3)
	_sheet.custom_minimum_size.x = SHEET_W
	center.add_child(_sheet)
	var v := UIKit.vbox(6)
	_sheet.add_child(v)

	var head := UIKit.hbox(16)
	var t := UIKit.heading(tr("STATS_TITLE"), 36)
	UIKit.tilt(t, -2.0)
	head.add_child(t)
	_subtitle = UIKit.label("", 19, UITheme.INK_SOFT)
	_subtitle.size_flags_vertical = SIZE_SHRINK_CENTER
	head.add_child(_subtitle)
	head.add_child(UIKit.spacer())
	_close_btn = UIKit.compact(UIKit.button("← " + tr("STATS_CLOSE"), close, 20), 1, 12)
	_close_btn.name = "stats_close"
	InputGlyphs.bind(_close_btn, "text", func() -> String:
		return "← %s  %s" % [tr("STATS_CLOSE"), InputGlyphs.label("ui_cancel")])
	_close_btn.size_flags_vertical = SIZE_SHRINK_CENTER
	# Only focusable control: keep keyboard/gamepad focus inside the overlay.
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_close_btn.set_focus_neighbor(side, NodePath("."))
	_close_btn.focus_next = NodePath(".")
	_close_btn.focus_previous = NodePath(".")
	head.add_child(_close_btn)
	v.add_child(head)

	_body = UIKit.vbox(0)
	_body.size_flags_vertical = SIZE_EXPAND_FILL
	v.add_child(_body)
	UIKit.focus_later(_close_btn)


func close() -> void:
	if is_queued_for_deletion():
		return
	UINav.modal_close(self)
	UIApi.sfx("ui_click")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		# The run screen polls the "pause" action (also Esc) in _process;
		# release it so closing the statistics doesn't also open the pause menu.
		if InputMap.has_action("pause"):
			Input.action_release("pause")
		close()


## The damage table scrolls with the stick / D-pad (the close button is the
## only focusable control).
func _process(delta: float) -> void:
	UINav.stick_scroll(_scroll, delta, true, 500.0)


func focus_close() -> void:
	if _close_btn:
		UIKit.focus_later(_close_btn)


## (Re)builds the content from the local player's meta slice.
func show_stats(meta: Dictionary, me: Dictionary) -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	_subtitle.text = tr("STATS_SUBTITLE") % int(meta.get("wave", 0))
	var rs: Dictionary = me.get("run_stats", {}) if me.get("run_stats", {}) is Dictionary else {}
	_scroll = null
	_grid = null
	_body.add_theme_constant_override("separation", 10)
	_body.add_child(_wave_card(meta, me))

	# "Ganze Runde": secondary, on darker paper and in smaller type.
	var run := UIKit.card(UITheme.PAPER_DARK.lerp(UITheme.PAPER, 0.45), UITheme.INK_SOFT, 0.0, 2)
	run.name = "run_card"
	run.size_flags_vertical = SIZE_EXPAND_FILL
	_body.add_child(run)
	var rv := UIKit.vbox(2)
	rv.size_flags_vertical = SIZE_EXPAND_FILL
	run.add_child(rv)
	rv.add_child(UIKit.label(tr("STATS_RUN_TITLE"), 20, UITheme.INK_SOFT))
	_main = UIKit.hbox(22)
	_main.size_flags_vertical = SIZE_EXPAND_FILL
	rv.add_child(_main)
	_dmg_card = _damage_card(rs, me)
	_main.add_child(_dmg_card)
	_main.add_child(_totals_list(meta, rs))
	_fit_scroll()


## Gives the damage table its natural height, capped so the whole sheet fits
## the viewport (e.g. 1280×720); beyond that the table scrolls.
func _fit_scroll() -> void:
	if _scroll == null or _grid == null or not is_inside_tree():
		return
	_scroll.custom_minimum_size.y = 0
	var want := _grid.get_combined_minimum_size().y
	var outside := _sheet.get_combined_minimum_size().y - _main.get_combined_minimum_size().y
	var cap := get_viewport_rect().size.y - 2.0 * SCREEN_MARGIN - outside - _dmg_card.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = clampf(want, 60.0, maxf(60.0, cap))


## Players of the meta in a stable order (by id), so every screen of a co-op
## round lists them the same way.
static func player_ids(meta: Dictionary) -> Array:
	var players = meta.get("players", {})
	if not (players is Dictionary):
		return []
	var ids: Array = players.keys()
	ids.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
	return ids


## run_stats.last_wave of a player meta entry; damage falls back to the sum of
## the per-source `wave` column (architecture §10).
static func last_wave(p: Dictionary) -> Dictionary:
	var rs = p.get("run_stats", {})
	if not (rs is Dictionary):
		return {}
	var lw = rs.get("last_wave", {})
	var out: Dictionary = (lw as Dictionary).duplicate() if lw is Dictionary else {}
	if not out.has("damage"):
		var sum := 0
		for r in (rs.get("damage", []) if rs.get("damage", []) is Array else []):
			if r is Dictionary:
				sum += int(r.get("wave", 0))
		out["damage"] = sum
	return out


## The row with the most damage in the last wave, or {} if nothing hit.
static func best_wave_source(rs: Dictionary) -> Dictionary:
	var best := {}
	var rows = rs.get("damage", [])
	if not (rows is Array):
		return best
	for r in rows:
		if r is Dictionary and int(r.get("wave", 0)) > int(best.get("wave", 0)):
			best = r
	return best


## "Letzte Woche": one row per player (just the values in solo), the local
## row tinted, the highest value of each column underlined (GDD §6c, D-152).
func _wave_card(meta: Dictionary, me: Dictionary) -> Control:
	var c := UIKit.card(Color.WHITE.lerp(UITheme.PAPER, 0.4), UITheme.INK, 0.0)
	c.name = "wave_card"
	var v := UIKit.vbox(4)
	c.add_child(v)
	v.add_child(UIKit.label(tr("STATS_WAVE_TITLE"), 25, UITheme.RED))
	var players: Dictionary = meta.get("players", {}) if meta.get("players", {}) is Dictionary else {}
	var ids := player_ids(meta)
	var local = null
	for id in ids:
		if is_same(players[id], me):
			local = id
	if local == null:
		for id in ids:
			if str(id) == str(UIApi.local_id()):
				local = id
	if ids.is_empty():
		ids = [local if local != null else 0]
		players = {ids[0]: me}
		local = ids[0]
	var coop := ids.size() > 1
	var fs := 21 if coop else 28
	# Co-op: a table (numbers right-aligned); solo: evenly spread, centered tiles.
	var num_align := HORIZONTAL_ALIGNMENT_RIGHT if coop else HORIZONTAL_ALIGNMENT_CENTER
	var text_align := HORIZONTAL_ALIGNMENT_LEFT if coop else HORIZONTAL_ALIGNMENT_CENTER

	var grid := GridContainer.new()
	grid.name = "wave_grid"
	grid.columns = WAVE_COLS.size() + (2 if coop else 1)
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	if coop:
		grid.add_child(UIKit.label("", 16))
	var cur := UIKit.currency(meta)
	for col in WAVE_COLS:
		var key := str(col[1])
		var text := tr(key) % cur if key == "STATS_PFAND_COLLECTED" else tr(key)
		grid.add_child(_wave_cell(UIKit.label(text, 16, UITheme.INK_SOFT, num_align), coop))
	var bh := UIKit.label(tr("STATS_COL_BEST"), 16, UITheme.INK_SOFT, text_align)
	bh.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_child(bh)

	var top := {}
	for col in WAVE_COLS:
		var m := 0
		for id in ids:
			m = maxi(m, int(last_wave(players[id]).get(col[0], 0)))
		top[col[0]] = m
	var mark := RowMark.new()
	for id in ids:
		var p: Dictionary = players[id] if players[id] is Dictionary else {}
		var lw := last_wave(p)
		var mine := local != null and str(id) == str(local)
		var away := bool(p.get("away", false))
		if coop:
			var who := str(p.get("name", "?")) + (" " + tr("STATS_YOU") if mine else "")
			var n := UIKit.label(who, fs, UITheme.GREY if away else (UITheme.RED if mine else UITheme.INK))
			n.name = "wn_%s" % str(id)
			n.clip_text = true
			n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			n.custom_minimum_size.x = 150
			grid.add_child(n)
			if mine:
				mark.cell = n
		for col in WAVE_COLS:
			var val := int(lw.get(col[0], 0))
			var color := UITheme.INK
			if away or val == 0:
				color = UITheme.GREY
			elif col[0] == "dmg_taken":
				color = UITheme.RED
			elif col[0] == "pfand" or col[0] == "healed":
				color = UITheme.GREEN
			var l := UIKit.label(fmt_int(val), fs, color, num_align)
			l.name = "wv_%s_%s" % [str(id), col[0]]
			if coop and val > 0 and val == int(top[col[0]]):
				var u := Underline.new()
				u.name = "top"
				l.add_child(u)
			grid.add_child(_wave_cell(l, coop))
		var rs: Dictionary = p.get("run_stats", {}) if p.get("run_stats", {}) is Dictionary else {}
		var best := best_wave_source(rs)
		var bl := UIKit.label("–", fs - 2, UITheme.GREY, text_align)
		if not best.is_empty():
			var done := bool(best.get("sold", false)) or bool(best.get("merged", false))
			bl.text = source_name(best, ult_id(p))
			if str(best.get("kind", "")) == "weapon" and not done and not away:
				bl.add_theme_color_override("font_color", UIKit.tier_color(int(best.get("tier", 1))))   # GDD §6a
			else:
				bl.add_theme_color_override("font_color", UITheme.GREY if done or away else UITheme.INK)
		bl.name = "wb_%s" % str(id)
		bl.size_flags_horizontal = SIZE_EXPAND_FILL
		bl.clip_text = true
		bl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bl.custom_minimum_size.x = 120
		grid.add_child(bl)
	mark.add_child(grid)
	grid.sort_children.connect(mark.queue_redraw)
	v.add_child(mark)
	return c


## Solo spreads the number columns evenly; co-op keeps them tight.
static func _wave_cell(l: Label, coop: bool) -> Label:
	if not coop:
		l.size_flags_horizontal = SIZE_EXPAND_FILL
	return l


func _damage_card(rs: Dictionary, me: Dictionary) -> Control:
	var box := UIKit.vbox(2)
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(UIKit.label(tr("STATS_DAMAGE"), 18, UITheme.RED))
	var rows: Array = rs.get("damage", []) if rs.get("damage", []) is Array else []
	var sum := 0
	for r in rows:
		if r is Dictionary:
			sum += int(r.get("total", 0))
	if rows.is_empty():
		box.add_child(UIKit.para(tr("STATS_NO_DAMAGE"), 17, UITheme.GREY))
		return box

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 1)
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	var heads := [["STATS_COL_SOURCE", HORIZONTAL_ALIGNMENT_LEFT], ["STATS_COL_WAVE", HORIZONTAL_ALIGNMENT_RIGHT],
		["STATS_COL_TOTAL", HORIZONTAL_ALIGNMENT_RIGHT], ["STATS_COL_SHARE", HORIZONTAL_ALIGNMENT_LEFT]]
	for h in heads:
		var hl := UIKit.label(tr(str(h[0])), 15, UITheme.INK_SOFT, h[1])
		grid.add_child(hl)
	for i in rows.size():
		if not (rows[i] is Dictionary):
			continue
		var r: Dictionary = rows[i]
		# Sold or combined into a higher tier: a finished row, greyed out.
		var sold := bool(r.get("sold", false)) or bool(r.get("merged", false))
		var col := UITheme.GREY if sold else UITheme.INK
		var total := int(r.get("total", 0))
		var weapon := str(r.get("kind", "")) == "weapon"
		var n := UIKit.label(source_name(r, ult_id(me)), 17,
			UIKit.tier_color(int(r.get("tier", 1))) if weapon and not sold else col)   # GDD §6a
		n.name = "src_%d" % i
		n.size_flags_horizontal = SIZE_EXPAND_FILL
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		n.custom_minimum_size.x = 150
		if str(r.get("kind", "")) == "weapon":
			n.mouse_filter = MOUSE_FILTER_PASS
			n.tooltip_text = UIKit.content_text("WEAPON", str(r.get("id", "")), "DESC")
		grid.add_child(n)
		grid.add_child(UIKit.label(fmt_int(int(r.get("wave", 0))), 17, col, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(UIKit.label(fmt_int(total), 17, col, HORIZONTAL_ALIGNMENT_RIGHT))
		var share := float(total) / float(sum) if sum > 0 else 0.0
		var cell := UIKit.hbox(8)
		var bar := ShareBar.new()
		bar.share = share
		bar.color = UITheme.GREY if sold else kind_color(str(r.get("kind", "")))
		bar.jitter_seed = i
		bar.custom_minimum_size = Vector2(BAR_W, 16)
		bar.size_flags_vertical = SIZE_SHRINK_CENTER
		cell.add_child(bar)
		var pl := UIKit.label(fmt_share(share), 16, col, HORIZONTAL_ALIGNMENT_RIGHT)
		pl.custom_minimum_size.x = 48
		cell.add_child(pl)
		grid.add_child(cell)

	# Scrolls only when the table is taller than the space it gets.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(grid)
	_scroll = scroll
	_grid = grid
	box.add_child(scroll)
	return box


## Run totals of the local player as one compact list, no captions (D-152).
func _totals_list(meta: Dictionary, rs: Dictionary) -> Control:
	var cur := UIKit.currency(meta)
	var grid := _value_grid()
	grid.name = "totals"
	grid.custom_minimum_size.x = 330
	_value_row(grid, tr("STATS_HEALED_BY") % UIKit.stat_name("lifesteal"), rs.get("lifesteal", 0), UITheme.GREEN, "lifesteal")
	_value_row(grid, tr("STATS_HEALED_BY") % UIKit.stat_name("hp_regen"), rs.get("regen", 0), UITheme.GREEN, "hp_regen")
	if int(rs.get("sani", 0)) > 0:   # Demo-Sanis (GDD §6c, §11)
		_value_row(grid, tr("STATS_HEALED_BY") % tr("WEAPON_DEMO_SANIS_NAME"), rs.get("sani", 0), UITheme.GREEN)
	_value_row(grid, tr("STATS_DMG_TAKEN"), rs.get("dmg_taken", 0), UITheme.RED)
	_value_row(grid, tr("STATS_BLOCKED_BY") % UIKit.stat_name("armor"), rs.get("dmg_blocked", 0), UITheme.BLUE, "armor")
	_value_row(grid, tr("STATS_DODGES") % UIKit.stat_name("dodge"), rs.get("dodges", 0), UITheme.BLUE, "dodge")
	_value_row(grid, tr("STATS_KILLS"), rs.get("kills", 0))
	_value_row(grid, tr("STATS_CRITS"), rs.get("crits", 0))
	_value_row(grid, tr("STATS_ULTS"), rs.get("ults", 0))
	_value_row(grid, tr("STATS_PFAND_COLLECTED") % cur, rs.get("pfand_collected", 0), UITheme.GREEN)
	_value_row(grid, tr("STATS_PFAND_INCOME") % cur, rs.get("pfand_income", 0), UITheme.GREEN)
	_value_row(grid, tr("STATS_PFAND_SPENT") % cur, rs.get("pfand_spent", 0), UITheme.RED)
	return grid


func _value_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", -3)
	grid.size_flags_vertical = SIZE_SHRINK_BEGIN
	return grid


func _value_row(grid: GridContainer, text: String, value, color := UITheme.INK, stat := "") -> void:
	var n := UIKit.label(text, 16)
	n.size_flags_horizontal = SIZE_EXPAND_FILL
	if stat != "":
		n.mouse_filter = MOUSE_FILTER_PASS
		n.tooltip_text = UIKit.trk("STAT_%s_DESC" % stat.to_upper())
	grid.add_child(n)
	var num := int(value) if (value is int or value is float) else 0
	grid.add_child(UIKit.label(fmt_int(num), 17, color if num > 0 else UITheme.GREY, HORIZONTAL_ALIGNMENT_RIGHT))


# --- Shared helpers (also used by the end screen) ----------------------------

## The ultimate id of a player meta entry (falls back to the character's).
static func ult_id(p: Dictionary) -> String:
	var u := str(p.get("ult", ""))
	if u == "":
		var ch: Dictionary = Content.CHARACTERS.get(str(p.get("char", "")), {})
		u = str(ch.get("ult", ""))
	return u


## Display name of a run_stats damage row (architecture §10).
static func source_name(r: Dictionary, ult: String) -> String:
	var kind := str(r.get("kind", "other"))
	if kind == "weapon":
		var s := "%s %s" % [UIKit.content_text("WEAPON", str(r.get("id", ""))), UIKit.roman(int(r.get("tier", 1)))]
		if bool(r.get("sold", false)):
			s += " " + UIKit.tr_ui("STATS_SOLD")
		elif bool(r.get("merged", false)):
			s += " " + UIKit.tr_ui("STATS_MERGED")
		return s
	if kind == "ram":
		return UIKit.tr_ui("STATS_SRC_RAM")
	if kind == "ult" and ult != "":
		return UIKit.content_text("ULT", ult)
	return UIKit.tr_ui("STATS_SRC_OTHER")


## The row with the highest total, or {} if nothing dealt damage.
static func best_source(rs: Dictionary) -> Dictionary:
	var best := {}
	var rows = rs.get("damage", [])
	if not (rows is Array):
		return best
	for r in rows:
		if r is Dictionary and int(r.get("total", 0)) > int(best.get("total", 0)):
			best = r
	return best


static func kind_color(kind: String) -> Color:
	if kind == "ram":
		return UITheme.YELLOW
	if kind == "ult":
		return UITheme.BLUE
	if kind == "weapon":
		return UITheme.RED
	return UITheme.GREY


## 45210 -> "45.210" (German thousands separator).
static func fmt_int(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func fmt_share(share: float) -> String:
	if share > 0.0 and share < 0.01:
		return "<1 %"
	return "%d %%" % int(round(share * 100.0))


## Hand-drawn share bar: hatched fill plus a slightly wobbly ink outline.
class ShareBar extends Control:
	var share := 0.0
	var color := UITheme.RED
	var jitter_seed := 0

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var r := Rect2(Vector2(1, 2), size - Vector2(3, 4))
		var w := r.size.x * clampf(share, 0.0, 1.0)
		if w >= 1.0:
			draw_rect(Rect2(r.position, Vector2(w, r.size.y)), color.lerp(UITheme.PAPER, 0.35))
			var x := r.position.x + 2.0
			var dark := color.darkened(0.3)
			while x < r.position.x + w - 1.0:
				var x2 := minf(x + 5.0, r.position.x + w)
				draw_line(Vector2(x, r.end.y - 1), Vector2(x2, r.position.y + 1), dark, 1.2)
				x += 6.0
		var j := func(k: int) -> Vector2:
			var a := float((jitter_seed * 7 + k * 13) % 5) * 0.35 - 0.7
			var b := float((jitter_seed * 11 + k * 5) % 5) * 0.3 - 0.6
			return Vector2(a, b)
		var pts := PackedVector2Array([
			r.position + j.call(0), Vector2(r.end.x, r.position.y) + j.call(1),
			r.end + j.call(2), Vector2(r.position.x, r.end.y) + j.call(3), r.position + j.call(0) + Vector2(1.5, 0.5)])
		draw_polyline(pts, UITheme.INK, 1.6, true)


## Holds the "Letzte Woche" grid and tints the local player's row behind it
## (the row of `cell`, full width).
class RowMark extends MarginContainer:
	var cell: Control
	var color := Color(UITheme.YELLOW, 0.3)

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		if cell == null or not is_instance_valid(cell) or cell.get_parent() == null:
			return
		var y := (cell.get_parent() as Control).position.y + cell.position.y
		draw_rect(Rect2(Vector2(-6, y - 1), Vector2(size.x + 12, cell.size.y + 2)), color)


## Hand-drawn red underline under a right-aligned number: the highest value of
## its "Letzte Woche" column (co-op only).
class Underline extends Control:
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		resized.connect(queue_redraw)

	func _draw() -> void:
		var l := get_parent() as Label
		if l == null:
			return
		var f := l.get_theme_font("font")
		var w := minf(size.x, f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			l.get_theme_font_size("font_size")).x)
		var y := size.y - 3.0
		draw_polyline(PackedVector2Array([Vector2(size.x - w - 2.0, y + 0.8), Vector2(size.x - w * 0.5, y - 0.6),
			Vector2(size.x + 1.0, y + 0.6)]), UITheme.RED, 2.4, true)
