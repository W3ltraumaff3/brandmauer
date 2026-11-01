class_name AchievementsScreen
extends UIScreen
## All achievements (Content.ACHIEVEMENT_ORDER), unlocked or still open.


func build() -> void:
	var have := 0
	for id in Content.ACHIEVEMENT_ORDER:
		if UIApi.has_achievement(id):
			have += 1
	var bar := UIKit.title_bar(tr("ACHS_TITLE"), close)
	bar.add_child(UIKit.spacer())
	var counter := UIKit.label(tr("ACHS_COUNTER") % [have, Content.ACHIEVEMENT_ORDER.size()], 26, UITheme.RED)
	UIKit.tilt(counter, 2.0)
	bar.add_child(counter)
	body.add_child(bar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 16)
	var gm := UIKit.margin(grid, 10, 10, 14, 10)
	gm.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(gm)

	var unlocks_char := {}
	for cid in Content.CHARACTERS:
		var u := str(Content.CHARACTERS[cid].get("unlock", ""))
		if u != "":
			unlocks_char[u] = cid

	var i := 0
	for id in Content.ACHIEVEMENT_ORDER:
		var done := UIApi.has_achievement(id)
		var c := UIKit.card(UITheme.PAPER if done else UITheme.PAPER_DARK, UITheme.GREEN if done else UITheme.GREY,
			UIKit.tilt_for(i, 0.8), 3 if done else 2)
		c.size_flags_horizontal = SIZE_EXPAND_FILL
		c.name = "ach_%d" % i
		# Focusable so the stick walks the list; FocusTips draws the frame.
		c.focus_mode = FOCUS_ALL
		if i == 0:
			focus_target = c
		var h := UIKit.hbox(12)
		c.add_child(h)
		var v := UIKit.vbox(2)
		v.size_flags_horizontal = SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UIKit.label(UIKit.ach_text(id), 26, UITheme.INK if done else UITheme.INK_SOFT))
		v.add_child(UIKit.para(UIKit.ach_text(id, "DESC"), 18, UITheme.INK_SOFT))
		if unlocks_char.has(id):
			v.add_child(UIKit.label(tr("ACHS_UNLOCKS_CHAR") % UIKit.content_text("CHAR", unlocks_char[id]), 18, UITheme.BLUE))
		var st := UIKit.stamp(tr("ACHS_DONE") if done else tr("ACHS_OPEN"), UITheme.GREEN if done else UITheme.GREY, -10.0 if done else 6.0, 20)
		st.size_flags_vertical = SIZE_SHRINK_CENTER
		h.add_child(st)
		grid.add_child(c)
		i += 1
