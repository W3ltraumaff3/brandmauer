extends TestCase
## The Brandmauer as a rectangle of four walls (GDD §5a, D-082): spawns behind
## every side, holes on every side, line of sight through holes on every side,
## players stay inside, and the wall pressure scales with the team size.

const SIDES := [Arena.TOP, Arena.RIGHT, Arena.BOTTOM, Arena.LEFT]


func _sim(n: int, seed := 11) -> Sim:
	var players := []
	for i in n:
		players.append({"id": i + 1, "name": "P%d" % (i + 1), "char": "oma"})
	var s := Sim.new()
	s.start_run({"seed": seed, "players": players, "org": "gewerkschaft", "difficulty": 0, "skip_intro": true})
	return s


func _middle(side: int) -> int:
	return int(Arena.SIDE_FIRST[side]) + int(Arena.SIDE_COUNT[side]) / 2


## Spawn share per side of `count` AfD spawn positions.
func _side_shares(s: Sim, count: int) -> Array[float]:
	var n: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for i in count:
		var p := s._spawn_pos("besorgter_buerger")
		assert_true(not Arena.is_inside(p, 0.0) and Arena.wall_at(p) == -1, "AfD spawn behind the wall, not in it: %s" % p)
		n[Arena.staging_side(p)] += 1.0 / count
	return n


func test_geometry_is_a_closed_rectangle() -> void:
	assert_eq(Arena.WALL_SEGMENTS, 2 * Arena.SEG_H + 2 * Arena.SEG_V, "segments on four sides")
	assert_true(Arena.INNER.size.x * Arena.INNER.size.y >= 1600.0 * 898.0, "inner arena at least as large as before")
	for i in Arena.WALL_SEGMENTS:
		var r := Arena.seg_rect(i)
		assert_eq(Arena.wall_at(r.get_center()), i, "segment %d maps back to itself" % i)
		assert_true(r.size.x >= Arena.WALL_THICK - 0.01 and r.size.y >= Arena.WALL_THICK - 0.01, "segment %d has thickness" % i)
	for pr in Arena.pillars():
		assert_eq(Arena.wall_at(pr.get_center()), -2, "corner pillar")
	# walking the wall centre line all the way round never finds a gap in the geometry
	var mid := Rect2(Vector2.ONE * Arena.WALL_MID, Arena.SIZE - Vector2.ONE * 2.0 * Arena.WALL_MID)
	var k := 0.0
	while k < Arena.perimeter(mid):
		assert_true(Arena.wall_at(Arena.perimeter_point(mid, k)) != -1, "wall closed at %s" % Arena.perimeter_point(mid, k))
		k += 7.0


func test_start_holes_one_per_player_one_per_side() -> void:
	for n in [1, 2, 3, 4]:
		var s := _sim(n)
		assert_eq(s.wall.count(false), n, "%d player(s): %d start hole(s)" % [n, n])
		var sides := {}
		for i in Arena.WALL_SEGMENTS:
			if not s.wall[i]:
				sides[Arena.side_of(i)] = true
		assert_eq(sides.size(), n, "start holes on different sides")
	assert_false(_sim(1).wall[_middle(Arena.TOP)], "solo: the top hole stays")


func test_enemies_spawn_behind_all_four_sides() -> void:
	for n in [1, 4]:
		var shares := _side_shares(_sim(n), 600)
		for side in SIDES:
			assert_true(shares[side] > 0.05, "%d player(s): AfD spawns behind side %d (%.2f)" % [n, side, shares[side]])
	# Union/Kapital appear just inside the wall, on every side too
	var s := _sim(1)
	var seen := {}
	for i in 300:
		var p := s._spawn_pos("ju_schnoesel")
		assert_true(Arena.is_inside(p, 0.0), "inner spawn inside")
		seen[Arena.nearest_side(p)] = true
	assert_eq(seen.size(), 4, "inner spawns on all four sides")


func test_spawn_spread_scales_with_player_count() -> void:
	var solo := _side_shares(_sim(1), 800)
	var four := _side_shares(_sim(4), 800)
	assert_true(solo.max() > 0.4, "solo: most spawns behind the one hole's wall (%.2f)" % solo.max())
	assert_true(four.max() < 0.35, "4 players: spread over all walls (%.2f)" % four.max())
	assert_true(four.max() < solo.max(), "more players, wider spread")
	# holes elsewhere pull spawns there
	var s := _sim(1)
	s.wall[_middle(Arena.LEFT)] = false
	s.wall[_middle(Arena.LEFT) + 1] = false
	var shares := _side_shares(s, 800)
	assert_true(shares[Arena.LEFT] > shares[Arena.RIGHT] * 2.0, "a wall with holes gets more spawns")


func test_holes_can_open_on_every_side() -> void:
	for side in SIDES:
		var s := _sim(1)
		for i in Arena.WALL_SEGMENTS:
			s.wall[i] = true
		var e := s.spawn_enemy("ju_schnoesel", Arena.seg_inner(_middle(side), 150.0))
		e.behind = false
		var opened := -1
		for f in 1200:
			s._ai_voter(e, e.speed, 1.0 / 60.0)
			if s.wall.count(false) > 0:
				opened = s.wall.find(false)
				break
		assert_true(opened >= 0, "JU votes a hole on side %d" % side)
		assert_eq(Arena.side_of(opened), side, "the hole is on the wall he stood at")


func test_holes_open_faster_with_more_players_and_later_waves() -> void:
	assert_true(Arena.vote_speed(4, 1) > Arena.vote_speed(1, 1), "more players vote faster")
	assert_true(Arena.vote_speed(1, 20) > Arena.vote_speed(1, 1), "later waves vote faster")
	var frames := []
	for n in [1, 4]:
		var s := _sim(n)
		for i in Arena.WALL_SEGMENTS:
			s.wall[i] = true
		var e := s.spawn_enemy("ju_schnoesel", Arena.seg_inner(3, 40.0))
		e.behind = false
		var f := 0
		while s.wall.count(false) == 0 and f < 2000:
			s._ai_voter(e, e.speed, 1.0 / 60.0)
			f += 1
		frames.append(f)
	assert_true(frames[1] < frames[0], "4 players open the hole sooner (%d < %d frames)" % [frames[1], frames[0]])


func test_line_of_sight_through_holes_on_every_side() -> void:
	for side in SIDES:
		var s := _sim(1)
		for i in Arena.WALL_SEGMENTS:
			s.wall[i] = true
		var m := _middle(side)
		var inside := Arena.seg_inner(m, 200.0)
		var behind := Arena.seg_staging(m)
		assert_true(s.shot_blocked(inside, behind), "side %d: intact wall blocks" % side)
		s.wall[m + 1] = false
		assert_true(s.shot_blocked(inside, behind), "side %d: a hole next to it doesn't help" % side)
		s.wall[m] = false
		assert_false(s.shot_blocked(inside, behind), "side %d: the hole lets the shot through" % side)
		# auto-aim sees an enemy behind the wall only through the hole
		var e := s.spawn_enemy("besorgter_buerger", behind)
		s._build_grid()
		assert_true(s._nearest_enemy(inside, 400.0) == e, "side %d: target through the hole" % side)
		s.wall[m] = true
		assert_true(s._nearest_enemy(inside, 400.0) == null, "side %d: no target through intact wall" % side)


func test_projectiles_stop_at_intact_walls_on_every_side() -> void:
	for side in SIDES:
		var m := _middle(side)
		for open in [false, true]:
			var s := _sim(1)
			s.enemies.clear()
			for i in Arena.WALL_SEGMENTS:
				s.wall[i] = true
			s.wall[m] = not open
			var pr := Sim.SimProj.new()
			pr.owner = 1
			pr.pos = Arena.seg_inner(m, 30.0)
			pr.vel = -Arena.inward(m) * 600.0
			pr.life = 2.0
			s.projectiles.append(pr)
			s._build_grid()
			for f in 12:
				s._step_projectiles(1.0 / 60.0)
			assert_eq(pr.alive, open, "side %d, hole %s: projectile %s" % [side, open, "passes" if open else "stops"])


func test_players_cannot_leave_the_four_walls() -> void:
	var r := Content.PLAYER_RADIUS
	for k in 16:
		var dir := Vector2.RIGHT.rotated(TAU * k / 16.0)
		var p := Sim.move_player(Arena.CENTER, dir, 5000.0, 1.0)
		assert_true(Arena.is_inside(p, r - 0.01), "player stays inside going %s: %s" % [dir, p])
	assert_true(Arena.is_inside(Sim.clamp_player(Vector2(-500, 5000)), r - 0.01), "clamp from far outside")
	# a player standing in front of an open hole still can't walk out through it
	var hole := Sim.move_player(Arena.seg_inner(_middle(Arena.LEFT), 5.0), Vector2.LEFT, 500.0, 1.0)
	assert_true(Arena.is_inside(hole, r - 0.01), "no way out through a hole")


func test_behind_enemies_walk_around_to_a_hole_on_another_side() -> void:
	var s := _sim(1)
	for i in Arena.WALL_SEGMENTS:
		s.wall[i] = true
	var hole := _middle(Arena.LEFT)
	s.wall[hole] = false
	var e := s.spawn_enemy("besorgter_buerger", Arena.staging_point(Arena.BOTTOM, 0.3))
	assert_true(e.behind, "starts behind the wall")
	var f := 0
	while e.behind and f < 60 * 60:
		s._move_behind_wall(e, e.speed, 1.0 / 60.0)
		assert_true(Arena.wall_at(e.pos) == -1 or Arena.wall_at(e.pos) == hole, "never walks through bricks (%s)" % e.pos)
		f += 1
	assert_false(e.behind, "came in through the hole")
	assert_true(Arena.is_inside(e.pos, 0.0), "inside the arena")
	assert_true(e.pos.distance_to(Arena.seg_inner(hole, 0.0)) < Arena.SEG_LEN_V, "entered at the left hole")


func test_wall_effects_work_on_every_side() -> void:
	for side in SIDES:
		var m := _middle(side)
		var near := Arena.seg_inner(m, 30.0)
		assert_eq(Arena.nearest_side(near), side, "nearest wall")
		assert_true(Arena.toward_wall(near).dot(-Arena.inward(m)) > 0.99, "Remigration push goes toward wall %d" % side)
		assert_true(Arena.edge_dist(near) < float(Arena.WALL["abschiebe_band"]), "Abschiebezone covers side %d" % side)
		# Antifa-Ortsgruppe: standing at a hole repairs it, on any wall
		var s := _sim(1)
		s.wall[m] = false
		var p: Sim.SimPlayer = s.players[1]
		p.pos = near
		for f in 200:
			s._antifa_repair(p, 1.0 / 60.0)
		assert_true(s.wall[m], "side %d: hole repaired by standing at it" % side)
	assert_false(Arena.edge_dist(Arena.CENTER) < float(Arena.WALL["abschiebe_band"]), "centre is safe")


## The Remigrantin's push rings drive everyone toward the wall nearest to HER
## (in "Steuerparadies" she sits at the top, so players are pushed up to her,
## not away into the far corners where the shield can't be reached).
func test_push_ring_drives_toward_the_wall_nearest_to_the_boss() -> void:
	var s := _sim(1)
	var p: Sim.SimPlayer = s.players[1]
	var boss_pos := Vector2(Arena.CENTER.x, Arena.INNER.position.y + 128.0)
	p.pos = Arena.CENTER + Vector2(0, 300)         # nearest wall to the player: bottom
	s._push_ring(boss_pos, 1.0)
	p.iframes = 10.0
	for f in 300:   # the ring grows over the player
		if p.knock != Vector2.ZERO:
			break
		s._step_hazards(1.0 / 60.0)
	assert_true(p.knock.y < -300.0, "pushed up toward her wall, not down to the bottom (%s)" % p.knock)


## Enemies shot behind the wall drop their Pfand (and Stullen) just inside the
## wall, so the shooter can pick it up during the wave, on every side.
func test_drops_behind_the_wall_land_inside_on_every_side() -> void:
	for side in SIDES:
		var s := _sim(1)
		var p: Sim.SimPlayer = s.players[1]
		var e := s.spawn_enemy("besorgter_buerger", Arena.staging_point(side, 0.5))
		e.behind = true
		s.pickups.clear()
		s._kill_enemy(e, p)
		var bottles := s.pickups.filter(func(k): return k.alive and k.type == Content.idx(Content.PICKUP_ORDER, "pfand"))
		assert_false(bottles.is_empty(), "side %d: the kill drops Pfand" % side)
		for k in bottles:
			assert_true(Arena.is_inside(k.pos, 0.0), "side %d: Pfand lands inside the walls (%s)" % [side, k.pos])
		# The player can walk there and collect it.
		var before := p.pfand
		p.pos = Arena.clamp_inner(bottles[0].pos, Content.PLAYER_RADIUS)
		for i in 10:
			p.iframes = 10.0
			s.step(1.0 / 60.0)
		assert_true(p.pfand > before, "side %d: Pfand collected" % side)
