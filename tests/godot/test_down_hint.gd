extends TestCase
## Downed hint (GDD §16, D-157): solo (or co-op with everyone down) nobody revives you and going down ends the
## run, so the HUD must not promise that "die anderen" bring you back, and the
## world draws no revive ring / "Hilf mir hoch!" (both use Hud.can_be_revived).

const AREAS := ["view", "sim"]  # ci-cd.md §2a


func _sim(chars: Array) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": 7, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	return s


func test_solo_down_gets_its_own_line() -> void:
	var s := _sim(["buergergeld"])
	var p: Sim.SimPlayer = s.players[1]
	p.stats["dodge"] = 0.0
	s.damage_player(p, 9999.0)
	assert_eq(p.state, 1, "solo: down (the HUD shows the hint)")
	assert_eq(s.phase, Sim.Phase.OVER, "solo: nobody revives, the run is over")
	assert_eq(Hud.down_hint_key(s.build_meta()), "HUD_YOU_DOWN_SOLO")
	assert_false(Hud.can_be_revived(s.build_meta()), "no revive marker")


func test_coop_down_keeps_the_revive_line() -> void:
	var s := _sim(["oma", "antifa"])
	var a: Sim.SimPlayer = s.players[1]
	a.stats["dodge"] = 0.0
	s.damage_player(a, 9999.0)
	assert_eq(a.state, 1, "co-op: down")
	assert_eq(s.phase, Sim.Phase.WAVE, "co-op: the others can revive")
	assert_eq(Hud.down_hint_key(s.build_meta()), "HUD_YOU_DOWN")
	assert_true(Hud.can_be_revived(s.build_meta()), "revive marker")


## Co-op, the last one goes down: the run is over, nobody comes back either.
func test_coop_everyone_down_gets_the_third_line() -> void:
	var s := _sim(["oma", "antifa"])
	for id in [1, 2]:
		var p: Sim.SimPlayer = s.players[id]
		p.stats["dodge"] = 0.0
		p.iframes = 0.0
		s.damage_player(p, 9999.0)
	assert_eq(s.phase, Sim.Phase.OVER, "everyone down: run over")
	assert_eq(Hud.down_hint_key(s.build_meta()), "HUD_YOU_DOWN_ALL")
	assert_false(Hud.can_be_revived(s.build_meta()), "no revive marker")
	var all := str(TranslationServer.translate("HUD_YOU_DOWN_ALL"))
	assert_true(all != "HUD_YOU_DOWN_ALL" and not all.contains("holen dich"), "own line: " + all)


func test_coop_partner_gone_counts_as_solo() -> void:
	# the sim decides by num_players(): with the partner removed, going down ends the run
	var s := _sim(["oma", "antifa"])
	s.remove_player(2)
	var a: Sim.SimPlayer = s.players[1]
	a.stats["dodge"] = 0.0
	s.damage_player(a, 9999.0)
	assert_eq(s.phase, Sim.Phase.OVER, "last one left: run over")
	assert_eq(Hud.down_hint_key(s.build_meta()), "HUD_YOU_DOWN_SOLO")
	assert_false(Hud.can_be_revived(s.build_meta()), "no revive marker")


func test_texts() -> void:
	var solo := str(TranslationServer.translate("HUD_YOU_DOWN_SOLO"))
	assert_true(solo != "HUD_YOU_DOWN_SOLO", "solo line translated")
	assert_false(solo.contains("die anderen"), "solo line promises no teammates: " + solo)
	assert_eq(str(TranslationServer.translate("HUD_YOU_DOWN")), "Kurz durchatmen – die anderen holen dich zurück!", "co-op line unchanged")
