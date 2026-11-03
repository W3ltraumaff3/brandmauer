extends TestCase
## Späti offers (GDD §6, §12): every defined weapon and item can be offered (D-150),
## the offer mix prefers items (D-149) and Reservieren keeps an offer, price included,
## into the next Späti (D-148).

const AREAS := ["sim", "content"]  # ci-cd.md §2a

const POLITICS := ["erinnerungsluecke", "treuhandkonto", "aufhoeren_zu_produzieren", "wahlversprechen",
	"maut_vertrag", "ber_eroeffnungstermin", "puma", "zweiter_wahlgang"]


func _sim(chars := ["oma"], seed := 7) -> Sim:
	var players := []
	for i in chars.size():
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": chars[i]})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	return s


func _to_shop(s: Sim) -> void:
	var guard := 0
	while s.phase == Sim.Phase.WAVE and guard < 20000:
		for p in s.players.values():
			p.iframes = 10.0
		s.step(1.0 / 60.0)
		guard += 1


func _weapons(offers: Array) -> int:
	var n := 0
	for o in offers:
		if o["kind"] == "weapon":
			n += 1
	return n


## Regression (D-150): the shop lists are hand-kept; a definition missing from them
## was never offered (eight politics items since v0.2).
func test_every_definition_is_in_its_shop_list() -> void:
	for id in Content.ITEMS:
		assert_has(Content.ITEM_ORDER, id, "item %s in ITEM_ORDER" % id)
	for id in Content.WEAPONS:
		assert_has(Content.WEAPON_ORDER, id, "weapon %s in WEAPON_ORDER" % id)
	assert_eq(Content.ITEM_ORDER.size(), Content.ITEMS.size(), "no duplicates in ITEM_ORDER")
	assert_eq(Content.WEAPON_ORDER.size(), Content.WEAPONS.size(), "no duplicates in WEAPON_ORDER")


func test_every_weapon_and_shop_item_is_offered() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s.wave = 15
	var seen := {}
	for i in 8000:
		var o: Dictionary = s._roll_offer(p, 0)
		seen[o["id"]] = true
	for id in Content.WEAPON_ORDER:
		assert_true(seen.has(id), "weapon %s offered" % id)
	for id in Content.ITEM_ORDER:
		var d: Dictionary = Content.ITEMS[id]
		if d.get("no_shop", false) or d.get("coop_only", false):
			continue
		assert_true(seen.has(id), "item %s offered" % id)
	for id in POLITICS:
		assert_true(seen.has(id), "politics item %s offered" % id)


## D-149: the build weapon first, then 35 % for a second weapon, 25 % for a third,
## never a fourth; so at least one item in every Späti of 4 offers.
func test_offer_mix_prefers_items() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	var counts := [0, 0, 0, 0, 0]
	var n := 3000
	for i in n:
		s.wave = 1 + i % 19
		s._make_offers(p)
		assert_eq(p.offers.size(), 4, "4 offers")
		var w := _weapons(p.offers)
		counts[w] += 1
		var fit := false
		for o in p.offers:
			fit = fit or (o["kind"] == "weapon" and s._fits_build(p, o["id"]))
		assert_true(fit, "a weapon for the build (roll %d)" % i)
		if w > 3 or not fit:
			break
	assert_eq(counts[0], 0, "never without a weapon")
	assert_eq(counts[4], 0, "never four weapons")
	# exact: 1 → 0.65³ = 27.5 %, 3 → 21.0 %, 2 → the rest (51.5 %)
	assert_near(counts[1] / float(n), 0.275, 0.04, "only the build weapon")
	assert_near(counts[3] / float(n), 0.210, 0.04, "three weapons")


func test_lock_toggles_and_sold_offers_cannot_be_locked() -> void:
	var s := _sim()
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	assert_true(s.request(1, "lock", 1))
	assert_true(p.offers[1]["locked"], "locked")
	assert_true(s.request(1, "lock", 1))
	assert_false(p.offers[1]["locked"], "unlocked again")
	p.pfand = 100000
	assert_true(s.request(1, "buy", 0))
	assert_false(s.request(1, "lock", 0), "a sold offer can't be locked")
	assert_false(s.request(1, "lock", 9), "no such offer")


func test_reroll_keeps_locked_offers() -> void:
	var s := _sim()
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	p.pfand = 100000
	s.request(1, "lock", 2)
	var kept: Dictionary = p.offers[2].duplicate()
	for i in 20:
		assert_true(s.request(1, "reroll"))
		assert_eq(p.offers[2], kept, "slot 2 unchanged after reroll %d" % i)
	assert_eq(p.offers.size(), 4, "still 4 offers")


## D-148: same slot, same offer, the old price; the lock is used up by the new visit.
func test_locked_offer_reaches_the_next_spaeti_at_its_old_price() -> void:
	var s := _sim()
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	var first_wave := s.wave
	s.request(1, "lock", 3)
	var kept: Dictionary = p.offers[3].duplicate()
	s.request(1, "ready", true)
	assert_eq(s.phase, Sim.Phase.WAVE, "next wave runs")
	_to_shop(s)
	assert_eq(s.wave, first_wave + 1, "next Späti")
	var o: Dictionary = p.offers[3]
	for k in ["kind", "id", "tier", "price"]:
		assert_eq(o[k], kept[k], "%s kept" % k)
	assert_false(o["locked"], "the lock is used up")
	var fresh := Content.item_price(o["id"], s.wave + 1) if o["kind"] == "item" \
		else Content.weapon_price(o["id"], o["tier"], s.wave + 1)
	assert_true(o["price"] < fresh, "old price %d below the new %d" % [o["price"], fresh])
	# relocked, it carries over again at the same old price
	s.request(1, "lock", 3)
	s.request(1, "ready", true)
	_to_shop(s)
	assert_eq(p.offers[3]["price"], kept["price"], "still the price of the first Späti")


func test_locked_offers_count_for_the_mix_and_the_build_weapon() -> void:
	var s := _sim()
	var p: Sim.SimPlayer = s.players[1]
	s.wave = 10
	var own: String = p.weapons[0]["id"]   # fits the build, so no build weapon is added
	for i in 300:
		s._make_offers(p)
		for j in 3:
			p.offers[j] = s._weapon_offer(p, own)
			p.offers[j]["locked"] = true
		s._make_offers(p)
		assert_eq(_weapons(p.offers.slice(0, 3)), 3, "locked weapons kept")
		assert_eq(p.offers[3]["kind"], "item", "three weapons on the shelf: the free slot is an item")
		for j in 3:
			p.offers[j]["locked"] = false


## D-150: Maut-Vertrag's Pfand follows the price factor of the Späti.
func test_maut_pays_out_by_price_factor() -> void:
	var s := _sim()
	_to_shop(s)
	var p: Sim.SimPlayer = s.players[1]
	s.wave = 9
	p.offers[0] = {"kind": "item", "id": "maut_vertrag", "tier": 1, "rarity": 3, "price": 10, "sold": false, "locked": false}
	p.pfand = 10
	assert_true(s.request(1, "buy", 0))
	assert_eq(p.pfand, int(round(60 * Content.price_mult(10))), "60 × price factor")
