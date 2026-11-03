extends TestCase
## Späti focus after a buy (GDD §19b, D-126): the next unsold offer, wrapping
## from the last to the first, then Neu würfeln; never the header. Reservieren
## by pad / keyboard also on offers you can't buy (D-153).
## The same flow with real gamepad input: tools/gamepad_nav_check.gd.

const AREAS := ["ui"]  # ci-cd.md §2a

const Preview := preload("res://tools/ui_preview.gd")

var _sp: SpaetiPanel
var _meta: Dictionary


func before_each() -> void:
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	_meta = Preview._rarity_meta()
	_sp = SpaetiPanel.new()
	_sp.preview_meta = _meta
	(Engine.get_main_loop() as SceneTree).root.add_child(_sp)


func after_each() -> void:
	_sp.free()
	UIApi.preview_mode = ""
	UIApi.preview_local_id = 0


func _buy(i: int) -> Control:
	_meta["players"][1]["offers"][i]["sold"] = true
	_sp._rebuild()
	return _sp._refocus_target("buy_%d" % i, "sec_offers")


func test_buy_moves_to_the_next_offer() -> void:
	var t := _buy(1)
	assert_true(t != null and t.name == "buy_2", "after buy_1: %s" % (t.name if t else "null"))


func test_buy_on_the_last_offer_wraps_to_the_first() -> void:
	var t := _buy(3)
	assert_true(t != null and t.name == "buy_0", "after buy_3: %s" % (t.name if t else "null"))


func test_sold_offers_are_skipped() -> void:
	_meta["players"][1]["offers"][0]["sold"] = true
	var t := _buy(3)
	assert_true(t != null and t.name == "buy_1", "after buy_3 with buy_0 sold: %s" % (t.name if t else "null"))


func test_all_sold_goes_to_reroll() -> void:
	for i in 3:
		_meta["players"][1]["offers"][i]["sold"] = true
	var t := _buy(3)
	assert_true(t != null and t.name == "reroll", "all sold: %s" % (t.name if t else "null"))


## Reservieren (D-148): a lock toggle on every unsold offer, pressed while locked, never
## in the gamepad focus chain; lock_offer acts on the focused Kaufen button.
func test_lock_buttons_show_the_lock_state() -> void:
	_meta["players"][1]["offers"][1]["locked"] = true
	_meta["players"][1]["offers"][2]["sold"] = true
	_sp._rebuild()
	var l0 := _sp.find_child("lock_0", true, false) as Button
	var l1 := _sp.find_child("lock_1", true, false) as Button
	assert_true(l0 != null and not l0.button_pressed, "unlocked offer: lock button up")
	assert_true(l1 != null and l1.button_pressed and l1.text == tr("SPAETI_LOCKED"), "locked offer: pressed, Gesperrt")
	assert_eq(l0.focus_mode, Control.FOCUS_NONE, "not in the focus chain")
	assert_true(_sp.find_child("lock_2", true, false) == null, "no lock on a sold offer")
	assert_true(InputMap.has_action("lock_offer"), "lock_offer action registered")
	(_sp.find_child("buy_3", true, false) as Control).grab_focus()
	assert_eq(_sp._focused_offer(), 3, "lock_offer targets the focused offer")


func _press_lock() -> void:
	var ev := InputEventAction.new()
	ev.action = "lock_offer"
	ev.pressed = true
	_sp._input(ev)


## Bug (D-153): an offer you can't afford had a disabled, unfocusable Kaufen, so
## pad Y / key L could never reserve it. Now it keeps focus, looks disabled, and
## pressing it is denied with the reason instead of buying.
func test_an_offer_you_cant_afford_can_be_reserved() -> void:
	_meta["players"][1]["pfand"] = 0
	_sp._rebuild()
	var b := _sp.find_child("buy_1", true, false) as Button
	assert_true(b != null and not b.disabled and UINav.can_focus(b), "blocked Kaufen stays focusable")
	assert_eq(b.get_theme_stylebox("normal"), b.get_theme_stylebox("disabled"), "but looks disabled")
	b.grab_focus()
	assert_eq(_sp._focused_offer(), 1, "focus on the blocked offer")
	UIApi.sfx_log = []
	_press_lock()
	b.pressed.emit()
	var log: Array = UIApi.sfx_log
	UIApi.sfx_log = null
	assert_eq(log, ["ui_click", "error"], "lock_offer reserves it; Kaufen is denied: %s" % [log])


## Klimageld (D-155): the Späti says whether it was paid when the contract ended.
func test_the_spaeti_shows_the_klimageld_result() -> void:
	_meta["vertrag"] = {"options": [], "votes": {}, "active": "", "waves_left": 0, "drafted": 0, "klimageld": 36}
	_sp._rebuild()
	var l := _sp.find_child("klimageld", true, false) as Label
	assert_true(l != null and l.text == tr("SPAETI_KLIMAGELD_PAID") % 36, "paid: %s" % (l.text if l else "null"))
	_meta["vertrag"]["klimageld"] = 0
	_meta["vertrag"]["options"] = ["digitalpakt", "cannabis", "maskendeals"]
	_sp._rebuild()
	l = _sp.find_child("klimageld", true, false) as Label
	assert_true(l != null and l.text == tr("SPAETI_KLIMAGELD_DELAYED"), "verschoben, in the vote card")
	_meta["vertrag"]["klimageld"] = -1
	_sp._rebuild()
	assert_true(_sp.find_child("klimageld", true, false) == null, "nothing without a Klimageld contract")


## The focused card shows the key on its reserve button, except with the mouse.
func test_the_focused_card_shows_the_lock_key() -> void:
	var before := InputGlyphs.device
	InputGlyphs.set_device(InputGlyphs.Device.PAD)
	_sp._rebuild()
	(_sp.find_child("buy_2", true, false) as Control).grab_focus()
	var l0 := _sp.find_child("lock_0", true, false) as Button
	var l2 := _sp.find_child("lock_2", true, false) as Button
	var key := InputGlyphs.label("lock_offer")
	var pad_text := l2.text
	var other := l0.text
	InputGlyphs.set_device(InputGlyphs.Device.MOUSE)
	var mouse_text := l2.text
	InputGlyphs.set_device(before)
	assert_eq(pad_text, "%s %s" % [key, tr("SPAETI_LOCK")], "focused card: key + Reservieren")
	assert_eq(other, tr("SPAETI_LOCK"), "other cards: no key")
	assert_eq(mouse_text, tr("SPAETI_LOCK"), "mouse: no key")


func test_a_usable_control_keeps_its_focus() -> void:
	_sp._rebuild()
	var t := _sp._refocus_target("buy_2", "sec_offers")
	assert_true(t != null and t.name == "buy_2", "unchanged: %s" % (t.name if t else "null"))
