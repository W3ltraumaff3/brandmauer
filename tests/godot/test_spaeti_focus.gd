extends TestCase
## Späti focus after a buy (GDD §19b, D-126): the next buyable offer, wrapping
## from the last to the first, then Neu würfeln; never the header.
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


func test_a_usable_control_keeps_its_focus() -> void:
	_sp._rebuild()
	var t := _sp._refocus_target("buy_2", "sec_offers")
	assert_true(t != null and t.name == "buy_2", "unchanged: %s" % (t.name if t else "null"))
