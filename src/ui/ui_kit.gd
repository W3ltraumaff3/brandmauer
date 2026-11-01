class_name UIKit
## Small widget factory for the menus (all built in code). Uses only UITheme
## colors and fonts. Real quotes go through `clipping()` / `type_label()`
## (typewriter + source), never through the handwritten font.

const TILTS := [-1.4, 0.9, -0.6, 1.5, -1.1, 0.5, 1.2, -1.6, 0.7]


static func label(text: String, size := 22, color := UITheme.INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Wrapping label. Needs a width from its container.
static func para(text: String, size := 20, color := UITheme.INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 40
	return l


## Typewriter label: only for real quotes, sources and "documents".
static func type_label(text: String, size := 17, color := UITheme.INK, bold := false) -> Label:
	var l := para(text, size, color)
	l.add_theme_font_override("font", UITheme.typewriter(bold))
	return l


static func heading(text: String, size := 34, color := UITheme.INK) -> Label:
	return label(text, size, color)


static func button(text: String, callback: Callable = Callable(), size := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	if callback.is_valid():
		b.pressed.connect(callback)
	return b


## Smaller vertical padding for buttons in dense lists.
static func compact(b: Button, pad := 1, side := 8) -> Button:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := UITheme.get_theme().get_stylebox(state, "Button").duplicate() as StyleBox
		sb.content_margin_top = pad
		sb.content_margin_bottom = pad + 2
		sb.content_margin_left = side
		sb.content_margin_right = side
		b.add_theme_stylebox_override(state, sb)
	return b


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margin(child: Control, l := 16, t := 16, r := 16, b := 16) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	if child:
		m.add_child(child)
	return m


static func spacer(h := true) -> Control:
	var c := Control.new()
	if h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## Rotates a control around its center (doodle feel). Containers reset the
## rotation of their children when they sort, so it is re-applied afterwards.
static func tilt(c: Control, degrees: float) -> Control:
	c.set_meta("tilt", degrees)
	var apply := func() -> void:
		c.pivot_offset = c.size * 0.5
		c.rotation_degrees = c.get_meta("tilt", 0.0)
	var hook := func() -> void:
		var p := c.get_parent()
		if p is Container and not (p as Container).sort_children.is_connected(apply):
			(p as Container).sort_children.connect(apply)
	c.resized.connect(apply)
	c.tree_entered.connect(hook)
	apply.call()
	return c


## Shrinks a label's font until `text` fits into `max_width` (single line).
static func fit_label(l: Label, max_width: float, min_size := 12) -> Label:
	var font := l.get_theme_font("font") if l.has_theme_font_override("font") else UITheme.hand()
	var fs := l.get_theme_font_size("font_size") if l.has_theme_font_size_override("font_size") else 22
	while fs > min_size and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_width:
		fs -= 1
	l.add_theme_font_size_override("font_size", fs)
	return l


static func tilt_for(i: int, scale := 1.0) -> float:
	return TILTS[posmod(i, TILTS.size())] * scale


## Paper card (PanelContainer) with a hand-drawn border, optionally tilted.
static func card(bg := UITheme.PAPER, border := UITheme.INK, degrees := 0.0, width := 2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.box(bg, border, width))
	if degrees != 0.0:
		tilt(p, degrees)
	return p


static func card_with(child: Control, bg := UITheme.PAPER, border := UITheme.INK, degrees := 0.0) -> PanelContainer:
	var p := card(bg, border, degrees)
	p.add_child(child)
	return p


## Full-rect layout helper for screens.
static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## tr() that returns "" when the key has no translation.
static func trk(key: String) -> String:
	var t := TranslationServer.translate(key)
	return "" if t == key else String(t)


## Name/description of a content entry by convention (architecture §2), e.g.
## content_text("CHAR", "oma", "NAME"). Falls back to the prettified id.
const WUT_TAGEBUCH_ENTRIES := 40
static var _diary_offset := -1


static func content_text(kind: String, id: String, suffix := "NAME") -> String:
	var key := "%s_%s_%s" % [kind, id.to_upper(), suffix]
	var t := trk(key)
	if t != "" and key == "ITEM_WUT_TAGEBUCH_DESC":
		return t % wut_tagebuch_entry()
	if t != "":
		return t
	return pretty(id) if suffix == "NAME" else ""


static func stat_name(stat: String) -> String:
	var t := trk("STAT_" + stat.to_upper())
	return t if t != "" else pretty(stat)


static func ach_text(ach_id: String, suffix := "NAME") -> String:
	var t := trk(ach_id.to_upper() + "_" + suffix)
	return t if t != "" else (pretty(ach_id.trim_prefix("ach_")) if suffix == "NAME" else "")


static func pretty(id: String) -> String:
	return id.replace("_", " ").capitalize()


static func currency(meta: Dictionary) -> String:
	var key := "CURRENCY_AKTIEN" if meta.get("blackrock", false) else "CURRENCY_PFAND"
	var t := trk(key)
	return t if t != "" else tr_ui(key)


static func tr_ui(key: String) -> String:
	return String(TranslationServer.translate(key))


static func roman(n: int) -> String:
	return ["I", "II", "III", "IV", "V"][clampi(n, 1, 5) - 1]


static func signed(v: float) -> String:
	var s := fmt_num(v)
	return ("+" + s) if v > 0 else s


static func fmt_num(v: float) -> String:
	if is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")


## Random quote id for `use`, preferring quotes up to `max_len` characters
## (we never shorten a real quote, so long ones are skipped instead).
static func pick_quote(use: String, max_len := 9999) -> String:
	var ids := Quotes.ids_for(use)
	var fitting := []
	for id in ids:
		if String(Quotes.get_quote(id).get("zitat", "")).length() <= max_len:
			fitting.append(id)
	if fitting.is_empty():
		fitting = ids
	if fitting.is_empty():
		return ""
	return fitting[randi() % fitting.size()]


## Newspaper clipping with a real quote: typewriter font plus source line.
## `header` is our own (handwritten) caption above the clipping.
static func clipping(quote_id: String, header := "", degrees := -1.2, quote_size := 17) -> Control:
	var q := Quotes.get_quote(quote_id)
	var box := vbox(4)
	if header != "":
		box.add_child(label(header, 20, UITheme.INK_SOFT))
	var paper := card(Color.WHITE.lerp(UITheme.PAPER, 0.35), UITheme.INK_SOFT, degrees, 1)
	var inner := vbox(6)
	paper.add_child(inner)
	if q.is_empty():
		inner.add_child(type_label(tr_ui("QUOTE_MISSING"), quote_size, UITheme.GREY))
	else:
		inner.add_child(type_label("„%s“" % q.get("zitat", ""), quote_size, UITheme.INK))
		var src := type_label("— " + Quotes.source_label(q), quote_size - 3, UITheme.INK_SOFT, true)
		src.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		inner.add_child(src)
		var ctx := Quotes.context_label(q)
		if ctx != "":
			var cl := type_label(ctx, quote_size - 4, UITheme.GREY)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			inner.add_child(cl)
	box.add_child(paper)
	return box


## Small doodle "stamp" label (rotated, bordered), e.g. GESPERRT.
static func stamp(text: String, color := UITheme.RED, degrees := -8.0, size := 22) -> Control:
	var p := card(Color(0, 0, 0, 0), color, degrees, 3)
	var l := label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Screen title row with a back button on the left.
static func title_bar(title: String, back: Callable) -> HBoxContainer:
	var h := hbox(18)
	var b := button("← " + tr_ui("UI_BACK"), back, 22)
	h.add_child(b)
	var t := heading(title, 40)
	h.add_child(t)
	return h


static func clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()


## Focus the first focusable button below `root` (gamepad/keyboard).
static func focus_first(root: Node) -> void:
	var f := _first_focusable(root)
	if f:
		focus_later(f)


## Grab focus next frame, but only if the control still exists and is shown
## (screens may be swapped within the same frame).
static func focus_later(c: Control) -> void:
	var cb := func():
		if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree():
			c.grab_focus()
	cb.call_deferred()


static func _first_focusable(n: Node) -> Control:
	for ch in n.get_children():
		if ch is Control and (ch as Control).visible:
			var c := ch as Control
			if c.focus_mode == Control.FOCUS_ALL and not (c is BaseButton and (c as BaseButton).disabled):
				return c
			var deep := _first_focusable(c)
			if deep:
				return deep
	return null


## The Wut-Tagebuch shows a new entry each Späti visit (stable within one visit).
static func wut_tagebuch_entry() -> String:
	if _diary_offset < 0:
		_diary_offset = randi() % WUT_TAGEBUCH_ENTRIES
	var wave := int(UIApi.meta().get("wave", 0))
	return trk("WUT_TAGEBUCH_%d" % ((wave + _diary_offset) % WUT_TAGEBUCH_ENTRIES + 1))
