class_name Album
extends UIScreen
## Zitat-Album: every curated, verified quote (Quotes.album_ids()). Unlocked
## cards show the quote in typewriter font with date, context and sources.

var _detail: VBoxContainer
var _ids: Array = []


func build() -> void:
	_ids = Quotes.album_ids()
	var have := 0
	for id in _ids:
		if UIApi.album_has(id):
			have += 1
	var bar := UIKit.title_bar(tr("ALBUM_TITLE"), close)
	bar.add_child(UIKit.spacer())
	var counter := UIKit.label(tr("ALBUM_COUNTER") % [have, _ids.size()], 26, UITheme.RED)
	UIKit.tilt(counter, 2.0)
	bar.add_child(counter)
	body.add_child(bar)

	var row := UIKit.hbox(18)
	row.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 520
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(UIKit.margin(grid, 6, 6, 10, 6))
	for i in _ids.size():
		var id: String = _ids[i]
		var unlocked := UIApi.album_has(id)
		var q := Quotes.get_quote(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(156, 54)
		b.add_theme_font_size_override("font_size", 18)
		b.text = "#%d  %s\n%s" % [i + 1, _surname(str(q.get("sprecher", ""))), str(q.get("datum", "")).left(4)] if unlocked else "#%d  ???" % (i + 1)
		if not unlocked:
			b.add_theme_color_override("font_color", UITheme.GREY)
		b.focus_entered.connect(_show.bind(id, i))
		b.pressed.connect(_show.bind(id, i))
		grid.add_child(b)

	var card := UIKit.card(Color.WHITE.lerp(UITheme.PAPER, 0.4), UITheme.INK, 0.8, 3)
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(card)
	var dscroll := ScrollContainer.new()
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(dscroll)
	_detail = UIKit.vbox(8)
	_detail.size_flags_horizontal = SIZE_EXPAND_FILL
	var dm := UIKit.margin(_detail, 6, 4, 10, 4)
	dm.size_flags_horizontal = SIZE_EXPAND_FILL
	dscroll.add_child(dm)
	if _ids.is_empty():
		_detail.add_child(UIKit.para(tr("ALBUM_EMPTY"), 20, UITheme.GREY))
	else:
		_show(_ids[0], 0)


func _surname(speaker: String) -> String:
	if speaker.contains("("):
		return speaker.get_slice("(", 0).strip_edges().left(16)
	var parts := speaker.split(" ")
	return parts[parts.size() - 1] if parts.size() > 0 else speaker


func _show(id: String, i: int) -> void:
	UIKit.clear(_detail)
	var q := Quotes.get_quote(id)
	_detail.add_child(UIKit.label(tr("ALBUM_CARD") % (i + 1), 18, UITheme.INK_SOFT))
	if not UIApi.album_has(id):
		_detail.add_child(UIKit.heading("???", 48, UITheme.GREY))
		_detail.add_child(UIKit.para(tr("ALBUM_LOCKED"), 20, UITheme.INK_SOFT))
		return
	var who := str(q.get("sprecher", ""))
	if str(q.get("partei", "")) != "":
		who += " (%s)" % q["partei"]
	_detail.add_child(UIKit.heading(who, 30))
	var role := str(q.get("rolle_damals", ""))
	if role != "":
		_detail.add_child(UIKit.para(role, 16, UITheme.INK_SOFT))
	# The quote itself: typewriter only.
	var clip := UIKit.card(Color.WHITE, UITheme.INK_SOFT, -0.8, 1)
	var cv := UIKit.vbox(4)
	clip.add_child(cv)
	cv.add_child(UIKit.type_label("„%s“" % q.get("zitat", ""), 19))
	var src := UIKit.type_label("— " + Quotes.source_label(q), 16, UITheme.INK_SOFT, true)
	src.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cv.add_child(src)
	_detail.add_child(clip)
	var ctx := str(q.get("kontext", ""))
	if ctx != "":
		_detail.add_child(UIKit.label(tr("ALBUM_CONTEXT"), 20, UITheme.RED))
		_detail.add_child(UIKit.type_label(ctx, 15, UITheme.INK))
	var sources: Array = q.get("quellen", [])
	if not sources.is_empty():
		_detail.add_child(UIKit.label(tr("ALBUM_SOURCES"), 20, UITheme.RED))
		for url in sources:
			var link := LinkButton.new()
			link.text = _short_url(str(url))
			link.tooltip_text = str(url)
			link.add_theme_font_override("font", UITheme.typewriter())
			link.add_theme_font_size_override("font_size", 15)
			link.add_theme_color_override("font_color", UITheme.BLUE)
			link.add_theme_color_override("font_hover_color", UITheme.RED)
			link.add_theme_color_override("font_focus_color", UITheme.RED)
			link.focus_mode = FOCUS_ALL
			link.pressed.connect(OS.shell_open.bind(str(url)))
			_detail.add_child(link)


func _short_url(url: String) -> String:
	var s := url.trim_prefix("https://").trim_prefix("http://").trim_prefix("www.")
	return s if s.length() <= 70 else s.left(67) + "…"
