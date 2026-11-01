class_name CreditsScreen
extends UIScreen
## Credits as an official notice in Amtsdeutsch (satire, our own text, so
## handwritten font), followed by the required asset attributions read from
## res://CREDITS.md at runtime.

const CREDITS_PATH := "res://CREDITS.md"
const SCROLL_SPEED := 600.0

var _scroll: ScrollContainer


func build() -> void:
	body.add_child(UIKit.title_bar(tr("CREDITS_TITLE"), close))
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll.add_child(center)
	var col := UIKit.vbox(22)
	col.custom_minimum_size.x = 900
	center.add_child(UIKit.margin(col, 10, 10, 10, 30))

	col.add_child(_bescheid())

	var att := UIKit.card(UITheme.PAPER, UITheme.INK, 0.5)
	var av := UIKit.vbox(6)
	att.add_child(av)
	av.add_child(UIKit.heading(tr("CREDITS_ATTRIBUTION"), 30, UITheme.RED))
	av.add_child(UIKit.para(tr("CREDITS_ATTRIBUTION_INTRO"), 18, UITheme.INK_SOFT))
	var rows := parse_credits(CREDITS_PATH)
	if rows.is_empty():
		av.add_child(UIKit.para(tr("CREDITS_MISSING"), 18, UITheme.RED))
	for r in rows:
		av.add_child(_attribution_row(r))
	col.add_child(att)

	var quotes := UIKit.para(tr("CREDITS_QUOTES"), 20, UITheme.INK)
	quotes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(quotes)
	var end := UIKit.label(tr("CREDITS_END"), 26, UITheme.RED, HORIZONTAL_ALIGNMENT_CENTER)
	UIKit.tilt(end, -2.0)
	col.add_child(end)


func _bescheid() -> Control:
	var doc := UIKit.card(Color.WHITE.lerp(UITheme.PAPER, 0.3), UITheme.INK, -0.7, 2)
	var v := UIKit.vbox(10)
	doc.add_child(UIKit.margin(v, 18, 12, 18, 16))
	var head := UIKit.hbox(10)
	var authority := UIKit.vbox(0)
	authority.size_flags_horizontal = SIZE_EXPAND_FILL
	authority.add_child(UIKit.label(tr("CREDITS_AUTHORITY"), 22))
	authority.add_child(UIKit.label(tr("CREDITS_AUTHORITY_SUB"), 17, UITheme.INK_SOFT))
	head.add_child(authority)
	var az := UIKit.vbox(0)
	az.add_child(UIKit.label(tr("CREDITS_AZ"), 17, UITheme.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT))
	az.add_child(UIKit.label(tr("CREDITS_DATE"), 17, UITheme.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT))
	head.add_child(az)
	v.add_child(head)
	v.add_child(UIKit.heading(tr("CREDITS_BESCHEID"), 40))
	v.add_child(UIKit.para(tr("CREDITS_SUBJECT"), 22))
	for key in ["CREDITS_P1", "CREDITS_P2", "CREDITS_P3", "CREDITS_P4", "CREDITS_P5"]:
		v.add_child(UIKit.para(tr(key), 20))
	v.add_child(UIKit.label(tr("CREDITS_RECHTSBEHELF"), 22, UITheme.RED))
	v.add_child(UIKit.para(tr("CREDITS_RECHTSBEHELF_TEXT"), 18, UITheme.INK_SOFT))
	var sign := UIKit.hbox(10)
	var sv := UIKit.vbox(0)
	sv.size_flags_horizontal = SIZE_EXPAND_FILL
	sv.add_child(UIKit.label(tr("CREDITS_SIGNED"), 20))
	sv.add_child(UIKit.label(tr("CREDITS_SIGNED_SUB"), 16, UITheme.INK_SOFT))
	sign.add_child(sv)
	sign.add_child(UIKit.stamp(tr("CREDITS_STAMP"), UITheme.RED, -12.0, 30))
	v.add_child(sign)
	return doc


func _attribution_row(r: Dictionary) -> Control:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.add_theme_font_size_override("normal_font_size", 18)
	rt.add_theme_color_override("default_color", UITheme.INK)
	var src := str(r.get("source", ""))
	var url := str(r.get("source_url", ""))
	var src_bb := "[url=%s][color=#%s]%s[/color][/url]" % [url, UITheme.BLUE.to_html(false), _esc(src)] if url != "" else _esc(src)
	rt.text = "• [b]%s[/b] — %s — %s — %s" % [_esc(str(r.get("title", ""))), _esc(str(r.get("author", ""))),
		_esc(str(r.get("license", ""))), src_bb]
	rt.meta_clicked.connect(func(m) -> void: OS.shell_open(str(m)))
	return rt


func _esc(s: String) -> String:
	return s.replace("[", "[lb]")


## Parses the asset table of CREDITS.md into
## [{title, author, license, source, source_url, file}].
static func parse_credits(path: String) -> Array:
	var out := []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var header := []
	for line in f.get_as_text().split("\n"):
		var l := line.strip_edges()
		if not l.begins_with("|"):
			header = [] if l == "" else header
			continue
		var cells := []
		for c in l.trim_prefix("|").trim_suffix("|").split("|"):
			cells.append(c.strip_edges())
		if header.is_empty():
			for c in cells:
				header.append(c.to_lower())
			continue
		if cells.size() > 0 and cells[0].begins_with("---"):
			continue
		var row := {}
		for i in mini(cells.size(), header.size()):
			row[header[i]] = cells[i]
		var src_text := str(row.get("source", ""))
		out.append({
			"file": _md_text(str(row.get("file", ""))),
			"title": _md_text(str(row.get("title", ""))),
			"author": _md_text(str(row.get("author", ""))),
			"license": _md_text(str(row.get("license", ""))),
			"source": _md_text(src_text),
			"source_url": _md_url(src_text),
		})
	return out


static func _md_text(s: String) -> String:
	var re := RegEx.create_from_string("\\[([^\\]]*)\\]\\(([^)]*)\\)")
	return re.sub(s, "$1", true)


static func _md_url(s: String) -> String:
	var re := RegEx.create_from_string("\\[([^\\]]*)\\]\\(([^)]*)\\)")
	var m := re.search(s)
	return m.get_string(2) if m else ""


func _process(delta: float) -> void:
	if _scroll == null:
		return
	var axis := Input.get_axis("ui_up", "ui_down")
	if absf(axis) > 0.1:
		_scroll.scroll_vertical += int(axis * SCROLL_SPEED * delta)
