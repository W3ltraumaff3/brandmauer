extends SceneTree
## Regression check (v0.2.1): at every Späti visit of a full run, the Bereit button
## must stay visible and fully on screen at 1280×720, however many items you own.
##   godot --headless --path . -s res://tools/spaeti_layout_check.gd
## A bot plays all 20 waves buying everything it can (maximum inventory), then an
## extreme case with 80 items is checked as well. Exit code 1 on any failure.

const VIEW := Vector2(1280, 720)

var _fails: Array[String] = []
var _checked := 0


func _initialize() -> void:
	var save_node := root.get_node_or_null("Save")
	if save_node:
		save_node.persist = false
	root.size = Vector2i(VIEW)
	call_deferred("_run")


func _run() -> void:
	var sim := Sim.new()
	sim.start_run({"seed": 5, "players": [{"id": 1, "name": "Bot", "char": "lastenrad"}],
		"org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	var p: Sim.SimPlayer = sim.players[1]
	p.levelup_stats["damage"] = 3000.0
	sim._recompute(p)
	var steps := 0
	while sim.phase != Sim.Phase.OVER and steps < 200000:
		if sim.phase == Sim.Phase.SHOP:
			p.pfand += 500   # rich bot: buys as much as possible
			for attempt in 6:
				for i in p.offers.size():
					sim.request(1, "buy", i)
				sim.request(1, "reroll")
			if not sim.vertrag["options"].is_empty():
				sim.request(1, "vote", -1)
			await _check(sim.build_meta(), "wave %d (%d items, %d weapons)" % [sim.wave, p.items.size(), p.weapons.size()])
			sim.request(1, "ready", true)
		else:
			p.iframes = 10.0
			sim.step(1.0 / 60.0)
			sim.take_events()
		steps += 1
	# Extreme case: far more items than a normal run.
	var meta := sim.build_meta()
	var items: Array = []
	for i in 80:
		items.append(Content.ITEM_ORDER[i % Content.ITEM_ORDER.size()])
	meta["players"][1]["items"] = items
	meta["phase"] = Sim.Phase.SHOP
	await _check(meta, "extreme: 80 items")
	await _check_scroll_kept()
	print("Späti layout: %d visits checked, %d failed" % [_checked, _fails.size()])
	for f in _fails:
		printerr("  FAIL ", f)
	quit(1 if not _fails.is_empty() or _checked < 10 else 0)


## Regression (v0.2.3): a rebuild (Pfand changed, a vote came in …) must not throw
## the scrolled side column or item list back to the top.
func _check_scroll_kept() -> void:
	var Preview := load("res://tools/ui_preview.gd")
	var meta: Dictionary = Preview._combine_meta()
	meta["kasse_enabled"] = true
	var items: Array = []
	for i in 60:
		items.append(Content.ITEM_ORDER[i % Content.ITEM_ORDER.size()])
	meta["players"][1]["items"] = items
	var frame := Control.new()
	frame.size = VIEW
	root.add_child(frame)
	var panel := SpaetiPanel.new()
	panel.preview_meta = meta
	frame.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		await process_frame
	var want := {}
	for n in ["side_scroll", "items_scroll"]:
		var s := panel.find_child(n, true, false) as ScrollContainer
		var bar := s.get_v_scroll_bar() if s else null
		if s == null or bar.max_value - bar.page < 20.0:
			_fails.append("scroll: %s missing or not scrollable" % n)
			continue
		s.scroll_vertical = int(bar.max_value - bar.page)
		want[n] = s.scroll_vertical
	await process_frame
	var changed := meta.duplicate(true)
	changed["players"][1]["pfand"] = int(changed["players"][1]["pfand"]) + 7
	panel.preview_meta = changed
	panel._queue_refresh()
	for i in 4:
		await process_frame
	for n in want:
		var s := panel.find_child(n, true, false) as ScrollContainer
		if s == null or absi(s.scroll_vertical - int(want[n])) > 2:
			_fails.append("scroll: %s jumped from %d to %d after a rebuild" % [n, want[n], s.scroll_vertical if s else -1])
	_checked += 1
	frame.queue_free()
	await process_frame


## Names the sections whose minimum height pushes the layout (for the failure message).
func _tallest(panel: Control) -> String:
	var out := []
	for sec in ["sec_offers", "sec_weapons", "sec_items", "sec_kasse", "sec_wall", "sec_vertrag", "sec_stats"]:
		var c := panel.find_child(sec, true, false) as Control
		if c:
			out.append("%s=%d" % [sec, int(c.get_combined_minimum_size().y)])
	out.append("panel=%d" % int(panel.get_combined_minimum_size().y))
	return ", ".join(out)


func _check(meta: Dictionary, label: String) -> void:
	_checked += 1
	# Fixed 1280×720 frame (the headless root window has a different size).
	var frame := Control.new()
	frame.size = VIEW
	root.add_child(frame)
	var panel := SpaetiPanel.new()
	panel.preview_meta = meta
	frame.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 3:
		await process_frame
	var ready_btn := panel.find_child("ready", true, false) as Control
	var screen := Rect2(Vector2.ZERO, VIEW)
	if ready_btn == null:
		_fails.append("%s: no Bereit button" % label)
	elif not ready_btn.is_visible_in_tree():
		_fails.append("%s: Bereit hidden" % label)
	else:
		var r := ready_btn.get_global_rect()
		if not screen.encloses(r.grow(-1.0)):
			_fails.append("%s: Bereit off screen at %s (%s)" % [label, r, _tallest(panel)])
	frame.queue_free()
	await process_frame
