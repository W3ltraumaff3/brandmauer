extends TestCase
## Option "Eigene Effekte" (GDD §19a, D-086): what counts as the players' side,
## the clamp, and the Fx layer that fades as a group.


func test_projectiles_classified() -> void:
	# every weapon projectile is the players', every enemy projectile is not
	for id in Content.WEAPONS:
		var proj := str(Content.WEAPONS[id].get("proj", ""))
		if proj != "":
			assert_true(WorldView.is_own_proj(proj), "weapon projectile %s should fade" % proj)
	for id in Content.ENEMIES:
		var proj := str(Content.ENEMIES[id].get("proj", ""))
		if proj != "":
			assert_false(WorldView.is_own_proj(proj), "enemy projectile %s must stay opaque" % proj)
	for proj in WorldView.ENEMY_PROJ:
		assert_has(Content.PROJ_ORDER, proj)
	assert_true(WorldView.is_own_proj("spiegel"), "Mietspiegel orbiters fade")


func test_hazards_classified() -> void:
	for id in WorldView.OWN_HAZARDS:
		assert_has(Content.HAZARD_ORDER, id)
	for id in ["mietzone", "kerosin", "lob_marker", "abschiebezone", "push_ring", "explosion"]:
		assert_false(WorldView.is_own_hazard(id), "%s must stay opaque" % id)
	for id in ["kleber", "kreide", "ziegel", "brei_marker", "sitzblockade"]:
		assert_true(WorldView.is_own_hazard(id), "%s should fade" % id)


func test_opacity_clamped() -> void:
	var w := WorldView.new()
	w.own_fx_override = 0.0
	w.read_own_fx()
	assert_near(w.own_fx, WorldView.OWN_FX_MIN)
	w.own_fx_override = 0.55
	w.read_own_fx()
	assert_near(w.own_fx, 0.55)
	w.own_fx_override = 3.0
	w.read_own_fx()
	assert_near(w.own_fx, 1.0)
	w.free()


func test_fx_own_layer_shares_and_fades() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	var w := WorldView.new()
	w.own_fx_override = 0.4
	root.add_child(w)
	var fx := Fx.new()
	fx.world = w
	root.add_child(fx)
	var own := fx._own_layer
	assert_true(own != null, "Fx creates its own-effects layer")
	assert_true(own.show_behind_parent, "own layer draws below numbers and bubbles")
	fx.handle_event(["swing", Vector2(100, 100), 0.0, 120.0, 25.0, "doener"])
	fx.handle_event(["ult", 1, "tarifrunde", Vector2(100, 100)])
	fx.handle_event(["dmg", Vector2(100, 100), 7])
	assert_eq(own._swings.size(), 1, "swing reaches the own layer")
	assert_eq(own._ults.size(), 1, "ult reaches the own layer")
	assert_true(is_same(own._swings, fx._swings), "arrays are shared, not copied")
	assert_eq(own._numbers.size(), 0, "damage numbers stay on the main layer")
	w.read_own_fx()
	own._process(0.016)
	assert_near(own.modulate.a, 0.4)
	assert_near(fx.modulate.a, 1.0)
	fx.free()
	w.free()
