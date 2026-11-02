extends TestCase
## Weapon tiers I–IV in the item rarity colors (GDD §6a, D-147).

const AREAS := ["ui"]  # ci-cd.md §2a

const Preview := preload("res://tools/ui_preview.gd")

var _sp: SpaetiPanel


func before_each() -> void:
	UIApi.preview_mode = "host"
	UIApi.preview_local_id = 1
	_sp = SpaetiPanel.new()
	_sp.preview_meta = Preview._combine_meta()
	(Engine.get_main_loop() as SceneTree).root.add_child(_sp)
	_sp._rebuild()


func after_each() -> void:
	_sp.free()
	UIApi.preview_mode = ""
	UIApi.preview_local_id = 0


func _font(c: Control) -> Color:
	return c.get_theme_color("font_color") if c != null else Color.TRANSPARENT


func _find(n: String) -> Control:
	return _sp.find_child(n, true, false) as Control


func test_tier_colors_follow_the_rarity_order() -> void:
	for t in 4:
		assert_eq(UIKit.tier_color(t + 1), Content.RARITY_COLORS[t + 1], "tier %d" % (t + 1))


func test_owned_weapons_are_colored_by_tier() -> void:
	# _combine_meta: Megafon II, Stricknadeln II, Megafon II, Grundgesetz III, Tofu I, Infostand IV
	var tiers := [2, 2, 2, 3, 1, 4]
	for i in tiers.size():
		assert_eq(_font(_find("weapon_%d" % i)), UIKit.tier_color(tiers[i]), "weapon_%d" % i)


func test_combine_shows_the_color_of_the_next_tier() -> void:
	assert_eq(_font(_find("combine_0")), UIKit.tier_color(3), "Kombinieren Megafon II → III")
	assert_eq(_font(_find("combines_0")), UIKit.tier_color(3), "offer Megafon II kombiniert zu III")


func test_weapon_offer_tag_has_its_tier_color() -> void:
	# Tier I (Tofu, Pfandflasche): green; the old tag was always blue.
	var tag := tr("SPAETI_WEAPON_TIER") % "I"
	var found := 0
	for l in _sp.find_children("*", "Label", true, false):
		if (l as Label).text == tag:
			found += 1
			assert_eq(_font(l), UIKit.tier_color(1), "offer tag Waffe I")
	assert_eq(found, 2, "offer tags Waffe I shown")


func test_stats_rows_are_colored_by_tier_and_grey_when_sold() -> void:
	var meta := Preview._combine_meta()
	var me: Dictionary = meta["players"][1]
	var panel := StatsPanel.new()
	var card := panel._damage_card(me["run_stats"], me)
	# _fake_run_stats: 0 Stricknadeln II, 1 Grundgesetz III, 2 ult, 3 Megafon I (sold)
	assert_eq(_font(card.find_child("src_0", true, false)), UIKit.tier_color(2), "Stricknadeln II")
	assert_eq(_font(card.find_child("src_1", true, false)), UIKit.tier_color(3), "Grundgesetz III")
	assert_eq(_font(card.find_child("src_2", true, false)), UITheme.INK, "ult stays ink")
	assert_eq(_font(card.find_child("src_3", true, false)), UITheme.GREY, "sold stays grey")
	card.free()
	panel.free()
