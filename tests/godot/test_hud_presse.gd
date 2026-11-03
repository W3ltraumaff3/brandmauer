extends TestCase
## Pressekonferenz banner (GDD §14, D-158): above the boss bar at the bottom,
## not as an overlay over the arena, where it covered the boss walking to the
## middle.

const AREAS := ["view"]  # ci-cd.md §2a


func test_phase_change_shows_no_banner_over_the_arena() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	hud.handle_event(["boss_phase", "geschichtslehrer", 1])
	var kinds := hud._overlays.map(func(o): return o["kind"])
	var enc := str(hud._presse.get("enc", ""))
	var ph := int(hud._presse.get("phase", -1))
	hud.free()
	assert_false("presse" in kinds, "no Pressekonferenz overlay at the top: %s" % [kinds])
	assert_eq(enc, "geschichtslehrer", "the boss bar banner knows the encounter")
	assert_eq(ph, 1, "and the phase")
