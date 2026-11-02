extends RefCounted
## Movement, targeting, ultimate and Streik logic of the balance bot
## (tools/balance_sim.gd, docs/specs/balancing.md §2). Every behaviour can be
## switched off for A/B runs on the same seeds.

## Weapon kinds that don't aim at a target (or whose `range` isn't a firing range):
## they don't set the kiting distance. Kinds without a `range` key are skipped too;
## a weapon can set `kite_range` to override both.
const NO_AIM_KINDS := ["trail", "orbit", "aura", "follower", "patrol", "tether", "decoy", "heal"]
## Kinds that only work while the player moves (Klimakleber walks part of the time).
const MOVE_KINDS := ["trail"]
const STILL_CYCLE := 3.0     # s: Klimakleber stand/walk cycle with MOVE_KINDS weapons
## v2 dodging: enemy telegraphs/zones the bot steps out of.
const DODGE_V2 := ["lob_marker", "kerosin"]
## v3: enemy (owner 0) hazards and how much standing in them costs. Unknown enemy
## hazard types that deal damage (`dps` or `data.dmg`) count as DANGER_DEFAULT.
const DANGER := {"lob_marker": 7.0, "kerosin": 5.0, "mietzone": 2.0}
const DANGER_DEFAULT := 5.0
## Owner-0 hazards that are only pictures of player effects (never dangerous).
const HARMLESS := ["kleber", "farbklecks", "brei_marker", "ziegel", "paragraf", "kreide", "kette",
	"sitzblockade", "explosion", "abstimmung", "kahlschlag_hit"]
## "Stand here" zones (GDD §14 telegraph standard): hazard type names containing these.
const STAND_HERE := ["plenum"]
## The final boss's own telegraphs (D-141, D-143): the sim says where they hurt
## (Sim.danger_at); cost of standing in each. Reichweite also pulls toward the
## nearest safe strip in front of the intact Brandmauer.
const OWN_DANGER := {"ansturm_bahn": 7.0, "rotor": 6.0, "reichweite": 9.0}
const ULT_NEAR := 300.0
const ULT_CROWD := 6
const ULT_BOSS_NEAR := 400.0
const BOSS_WAVES := [5, 10, 15, 20]
const DIRS := 12
const NEAR_MAX := 40          # enemies considered per decision

var move := true              # v3 planner (false: v2 kiting)
var dodge := true
var spread := true
var target := true
var pickup := true
var ult := "smart"            # 0 | 1 (v2) | boss | smart
var streik := true
var cast_ult := false         # hold a stun ult for a boss cast (needs cast fields in the sim)
## Planner tunables (tune=key:value,... on the command line): decision interval in
## frames, lookahead s, contact margin px and weight, comfort share of the wanted
## distance, wanted distance share of the reach, wall, approach and standing weights.
var tune := {"decide": 4, "look": 0.35, "contact_r": 65.0, "contact_w": 4.0, "comfy": 0.9, "want": 0.75,
	"wall_w": 1.2, "approach_w": 0.8, "stand": 1.2}

var _frame := 0
var _cache := {}              # pid -> Vector2 input
var _last := {}               # pid -> Vector2 last chosen direction
var _mode := {}               # pid -> target mode sent
var _types := {}              # hazard type index -> name
var _cands: Array[Vector2] = []
var _boss_seen := {}          # pid -> [wave, sim time a boss first came into ult reach]
const CAST_HOLD := 20.0       # s: longest a stun ult waits for a breakable boss cast


func _init() -> void:
	for i in Content.HAZARD_ORDER.size():
		_types[i] = Content.HAZARD_ORDER[i]
	_cands.append(Vector2.ZERO)
	for k in DIRS:
		_cands.append(Vector2.RIGHT.rotated(TAU * k / DIRS))


func tick() -> void:
	_frame += 1


## Kiting distance: the shortest range among weapons that aim at a target. Trail,
## orbit and other no-target kinds (or defs without `range`) don't count, else a
## Straßenkreide (range 60) would turn every bot into a melee bot.
static func kite_reach(s, p) -> float:
	var reach := 999.0
	for w in p.weapons:
		var def: Dictionary = Content.WEAPONS.get(w["id"], {})
		if def.has("kite_range"):
			reach = minf(reach, float(def["kite_range"]))
		elif def.has("range") and not str(def.get("kind", "")) in NO_AIM_KINDS:
			reach = minf(reach, s._weapon_range(p, def))
	return reach


## Share of a Klimakleber cycle spent walking: weapons that only work while moving
## (Straßenkreide) / all weapons. 0 = stands still whenever it's calm.
static func walk_share(p) -> float:
	if p.weapons.is_empty():
		return 0.0
	var moving := 0
	for w in p.weapons:
		if str(Content.WEAPONS.get(w["id"], {}).get("kind", "")) in MOVE_KINDS:
			moving += 1
	return float(moving) / p.weapons.size()


static func _standing_phase(s, p) -> bool:
	return fmod(s.time + p.id * 0.7, STILL_CYCLE) >= walk_share(p) * STILL_CYCLE


func input(s, p) -> Vector2:
	if not move:
		return _kite_v2(s, p)
	if _frame % int(tune["decide"]) == 0 or not _cache.has(p.id):
		_cache[p.id] = _plan(s, p)
	var v: Vector2 = _cache[p.id]
	# Wende / Rolle rückwärts: a human presses the other way, on the flipped axis only
	# (Teilwende, D-112). Sim.reverse_dir is its own inverse.
	if p.reversed > 0.0:
		return Sim.reverse_dir(v, int(p.get("reverse_axis"))) if "reverse_axis" in p else -v
	return v


# --- v3 planner ---------------------------------------------------------------

## Scores standing still and DIRS directions by where they lead in look seconds:
## contact and crowd danger, enemy projectiles on the path, enemy telegraphs and
## zones, walls and corners, open holes, keeping the weapons' range, teammates
## (spread out, revive), pickups and, for Klimakleber, the standing bonus.
func _plan(s, p) -> Vector2:
	var speed: float = s.player_speed(p)
	var reach := kite_reach(s, p)
	var want := clampf(reach * float(tune["want"]), 70.0, 320.0)
	var look: float = tune["look"]
	var contact_r: float = tune["contact_r"]
	var contact_w: float = tune["contact_w"]
	var pos: Vector2 = p.pos
	# nearby enemies (nearest NEAR_MAX)
	var near := []
	for e in s.enemies:
		if e.alive and not e.behind:
			var d: float = e.pos.distance_squared_to(pos)
			if d < 500.0 * 500.0:
				near.append([d, e])
	if near.size() > NEAR_MAX:
		near.sort_custom(func(a, b): return a[0] < b[0])
		near.resize(NEAR_MAX)
	var ep := PackedVector2Array()
	var er := PackedFloat32Array()
	var ew := PackedFloat32Array()
	var boss = null
	var nearest_i := -1
	var nearest_d := INF
	for x in near:
		var e = x[1]
		# where it will be at the end of the lookahead: enemies chase the player
		var to: Vector2 = pos - e.pos
		var gap: float = maxf(0.0, to.length() - e.radius - Content.PLAYER_RADIUS)
		ep.append(e.pos + to.normalized() * minf(float(e.speed) * look, gap) if to.length() > 0.1 else e.pos)
		if x[0] < nearest_d:
			nearest_d = x[0]
			nearest_i = ep.size() - 1
		er.append(e.radius)
		ew.append(1.6 if e.elite else 1.0)
		if e.encounter != "" and (boss == null or x[0] < boss.pos.distance_squared_to(pos)):
			boss = e
	# what the range term aims at: the boss when we focus it, else the nearest enemy
	var focus = boss if (target and boss != null) else null
	# Briefkastenfirmen (D-142): a decent player goes for the letterboxes feeding her shield
	var box = _nearest_box(s, pos) if target else null
	if box != null:
		focus = box
	# enemy projectiles that could reach us
	var projs := []
	for pr in s.projectiles:
		if pr.alive and pr.owner == 0 and not pr.harmless and pr.pos.distance_squared_to(pos) < 320.0 * 320.0:
			projs.append(pr)
	# enemy hazards
	var zones := []       # [pos, radius, cost]
	var stand := []       # [pos, radius]
	var rings := []
	var cones := []       # [origin, angle, half angle, reach] (Kahlschlag)
	var lanes := []       # her hazards checked with s.danger_at (lane, rotor, Reichweite)
	var safe_spot = null  # Reichweite: nearest safe point in front of the intact wall
	var band := -1.0
	if dodge:
		for h in s.hazards:
			if not h.alive or h.owner != 0:
				continue
			var tname: String = _types.get(h.type, "")
			if tname == "push_ring":
				if not h.data.get("hit", {}).has(p.id):
					rings.append(h)
			elif tname == "abschiebezone":
				band = h.radius if s.has_method("in_band") else float(Arena.WALL.get("abschiebe_band", 70.0))
			elif OWN_DANGER.has(tname) and s.has_method("danger_at"):
				lanes.append([h, OWN_DANGER[tname]])
				if tname == "reichweite" and safe_spot == null:
					var sp: Vector2 = s.reich_safe_spot(pos)
					if sp != Vector2.INF:
						safe_spot = sp
			elif tname == "kahlschlag":
				cones.append([h.pos, float(h.get("ang")), deg_to_rad(float(Content.BOSS.get("kahl_arc", 90.0))) * 0.5,
					h.radius])
			elif _is_stand_here(tname):
				stand.append([h.pos, h.radius])
			elif DANGER.has(tname):
				zones.append([h.pos, h.radius, DANGER[tname]])
			elif not tname in HARMLESS and (h.dps > 0.0 or h.data.has("dmg")):
				zones.append([h.pos, h.radius, DANGER_DEFAULT])
	# Plenum circles ("stand here", D-104): the first `needed` living bots (by id)
	# each take their own circle, in a fixed order, so the vote fails.
	var my_spot = null
	if not stand.is_empty():
		stand.sort_custom(func(a, b): return a[0].x < b[0].x or (a[0].x == b[0].x and a[0].y < b[0].y))
		var ids := []
		for o in s.players.values():
			if o.state == 0:
				ids.append(o.id)
		ids.sort()
		var k := ids.find(p.id)
		var needed: int = s.plenum_needed() if s.has_method("plenum_needed") else stand.size()
		if k >= 0 and k < needed:
			my_spot = stand[k % stand.size()]
	# open holes (AfD enemies stream in there)
	var holes := []
	for seg in s.wall.size():
		if not s.wall[seg]:
			holes.append(Arena.seg_inner(seg, 30.0))
	var mates := []
	var downed := []
	for o in s.players.values():
		if o.id == p.id:
			continue
		if o.state == 0:
			mates.append(o.pos)
		elif o.state == 1:
			downed.append(o.pos)
	var pick = null
	var pick_w := 0.0
	if pickup:
		var pr_reach: float = Content.PLAYER_BASE_PICKUP + p.stats["pickup"]
		for k in s.pickups:
			if not k.alive:
				continue
			var w := _pickup_value(s, p, k)
			if w <= 0.0:
				continue
			var d: float = k.pos.distance_to(pos)
			var lim := 450.0 if w >= 1.5 else 300.0
			if d > pr_reach * 0.6 and d < lim and w * (1.0 - d / lim) > pick_w:
				pick_w = w * (1.0 - d / lim)
				pick = k
	var klima: bool = p.char_id == "klimakleber"
	var standing := klima and _standing_phase(s, p)
	var last: Vector2 = _last.get(p.id, Vector2.ZERO)
	var best := Vector2.ZERO
	var best_sc := -INF
	for dir in _cands:
		var q: Vector2 = Arena.clamp_inner(pos + dir * speed * look, Content.PLAYER_RADIUS)
		var mid: Vector2 = (pos + q) * 0.5
		var sc := 0.0
		# enemies: contact danger, crowding, keeping range
		var dn := INF
		for i in ep.size():
			var d: float = q.distance_to(ep[i]) - er[i] - Content.PLAYER_RADIUS
			dn = minf(dn, d)
			if d < contact_r:
				sc -= contact_w * ew[i] * (contact_r - d) / contact_r
			var comfy: float = want * float(tune["comfy"])
			if d < comfy:
				sc -= 0.6 * ew[i] * (comfy - d) / comfy
		var aim_d := dn
		if focus != null:
			aim_d = q.distance_to(focus.pos) - focus.radius - Content.PLAYER_RADIUS
		if aim_d < INF and aim_d > want * 1.15:
			sc -= float(tune["approach_w"]) * minf(1.0, (aim_d - want * 1.15) / 300.0)
		# strafe around the nearest enemy instead of running straight at or away from it
		if dir != Vector2.ZERO and nearest_i >= 0 and dn < want * 1.5:
			sc += 0.25 * absf(dir.cross((ep[nearest_i] - pos).normalized()))
		# enemy projectiles along the path
		for pr in projs:
			for t in [look * 0.4, look * 0.8]:
				var pp: Vector2 = pr.pos + pr.vel * t
				var qq: Vector2 = pos + dir * speed * t
				if pp.distance_to(qq) < pr.radius + Content.PLAYER_RADIUS + 6.0:
					sc -= 5.0
					break
		# telegraphs and zones (current and mid-path position)
		for z in zones:
			var r: float = z[1] + Content.PLAYER_RADIUS + 10.0
			if q.distance_to(z[0]) < r or mid.distance_to(z[0]) < r:
				sc -= z[2]
		if my_spot != null:
			var dsp: float = q.distance_to(my_spot[0])
			sc += 4.0 * (1.0 - minf(1.0, dsp / 600.0)) + (3.0 if dsp < float(my_spot[1]) - 6.0 else 0.0)
		if band > 0.0:
			var in_b: bool = s.in_band(q, band + 25.0) if s.has_method("in_band") else Arena.edge_dist(q) < band + 25.0
			if in_b:
				sc -= 6.0
		for x in lanes:
			if s.danger_at(x[0], q) or s.danger_at(x[0], mid):
				sc -= x[1]
		if safe_spot != null:
			var dsp: float = q.distance_to(safe_spot)
			sc += 8.0 * (1.0 - minf(1.0, dsp / 1200.0)) + (3.0 if s.reich_safe(q) else 0.0)
		for c in cones:
			if Sim.in_cone(c[0], c[1], c[2], c[3] + 20.0, q, Content.PLAYER_RADIUS + 10.0) \
					or Sim.in_cone(c[0], c[1], c[2], c[3] + 20.0, mid, Content.PLAYER_RADIUS + 10.0):
				sc -= 8.0
		for h in rings:
			# the ring front at the end of the lookahead; being crossed costs, and
			# being near a wall when it hits costs more (it knocks toward the wall)
			var r_now: float = (1.0 - h.life / h.max_life) * 900.0
			var r_end: float = (1.0 - maxf(0.0, h.life - look) / h.max_life) * 900.0
			var dq: float = q.distance_to(h.pos)
			if dq > r_now - 24.0 and dq < r_end + 24.0:
				sc -= 2.0
			sc -= 1.0 * maxf(0.0, (220.0 - Arena.edge_dist(q)) / 220.0)
		# walls and corners
		var ed := Arena.edge_dist(q)
		if ed < 150.0:
			sc -= float(tune["wall_w"]) * (150.0 - ed) / 150.0
		var dx := minf(q.x - Arena.INNER.position.x, Arena.INNER.end.x - q.x)
		var dy := minf(q.y - Arena.INNER.position.y, Arena.INNER.end.y - q.y)
		if dx < 240.0 and dy < 240.0:
			sc -= 1.0 * (240.0 - maxf(dx, dy)) / 240.0
		for hp in holes:
			if q.distance_to(hp) < 130.0:
				sc -= 0.5
		sc -= 0.15 * q.distance_to(Arena.CENTER) / 900.0
		# teammates: spread out, revive the downed
		if spread:
			for m in mates:
				var d: float = q.distance_to(m)
				if d < 180.0:
					sc -= 0.8 * (180.0 - d) / 180.0
		for dpos in downed:
			sc += 2.0 * (1.0 - minf(1.0, q.distance_to(dpos) / 700.0))
		if pick != null:
			sc += pick_w * 1.2 * (1.0 - minf(1.0, q.distance_to(pick.pos) / 450.0))
		if box != null:
			# close enough that the letterbox is the closest target (target mode "closest")
			sc += 8.0 * (1.0 - minf(1.0, maxf(0.0, q.distance_to(box.pos) - want * 0.6) / 1600.0))
		# Klimakleber: the standing bonus, or walking for trail weapons
		if klima:
			if dir == Vector2.ZERO:
				sc += float(tune["stand"]) if standing else -0.5
		# smooth movement
		if dir != Vector2.ZERO:
			sc += 0.25 * dir.dot(last)
		if sc > best_sc:
			best_sc = sc
			best = dir
	_last[p.id] = best
	return best


## The nearest letterbox of the final boss (D-142), or null.
static func _nearest_box(s, pos: Vector2):
	var t := Content.ENEMY_ORDER.find("briefkasten")
	if t < 0:
		return null
	var best = null
	var bd := INF
	for e in s.enemies:
		if e.alive and e.type == t and e.pos.distance_to(pos) < bd:
			bd = e.pos.distance_to(pos)
			best = e
	return best


static func _is_stand_here(name: String) -> bool:
	for k in STAND_HERE:
		if name.contains(k):
			return true
	return false


## How much a pickup is worth going for (0 = ignore).
static func _pickup_value(s, p, k) -> float:
	var name: String = Content.PICKUP_ORDER[k.type] if k.type < Content.PICKUP_ORDER.size() else ""
	match name:
		"pfand":
			return 0.5
		"geldschein":
			return 1.6     # the Sauerländer heals from every bill left lying
		"stulle":
			return 1.0 if p.hp < p.stats["max_hp"] * 0.7 else 0.1
		"passant":
			return 0.6 if p.char_id == "stadtbild" else 0.0
	return 0.0


# --- v2 kiting (move=0) ---------------------------------------------------------

func _kite_v2(s, p) -> Vector2:
	var reach := kite_reach(s, p)
	var flee := 90.0 if reach < 200.0 else 260.0
	var push := Vector2.ZERO
	var nearest: Vector2 = Vector2.INF
	for e in s.enemies:
		if e.alive and not e.behind and (nearest == Vector2.INF or e.pos.distance_to(p.pos) < nearest.distance_to(p.pos)):
			nearest = e.pos
	var approach := Vector2.ZERO
	if nearest != Vector2.INF and nearest.distance_to(p.pos) > reach * 0.8:
		approach = (nearest - p.pos).normalized() * 0.6
	for e in s.enemies:
		if not e.alive or e.behind:
			continue
		var d: Vector2 = p.pos - e.pos
		var l := d.length()
		if l < flee and l > 0.1:
			push += d / l * (flee - l) / flee * 1.5
	for pr in s.projectiles:
		if pr.owner == 0 and pr.pos.distance_to(p.pos) < 120.0:
			push += (p.pos - pr.pos).normalized() * 0.8
	if dodge:
		for h in s.hazards:
			if h.alive and h.owner == 0 and _types.get(h.type, "") in DODGE_V2:
				var d: Vector2 = p.pos - h.pos
				var r: float = h.radius + Content.PLAYER_RADIUS + 12.0
				var l := d.length()
				if l < r:
					push += (d / l if l > 0.1 else Vector2.RIGHT) * (0.6 + 0.9 * (1.0 - l / r))
	for o in s.players.values():
		if o.state == 1 and o.pos.distance_to(p.pos) < 500.0:
			push += (o.pos - p.pos).normalized() * 0.7
	if p.char_id == "klimakleber" and push.length() < 0.25 \
			and (nearest == Vector2.INF or nearest.distance_to(p.pos) <= reach * 1.5):
		if _standing_phase(s, p):
			return Vector2.ZERO
		var to_c: Vector2 = Arena.CENTER - p.pos
		push += (to_c.orthogonal().normalized() if to_c.length() > 1.0 else Vector2.RIGHT) * 0.6
	push += approach
	push += (Arena.CENTER - p.pos) / 900.0
	if push.length() < 0.3:
		for k in s.pickups:
			if k.alive and k.pos.distance_to(p.pos) < 300.0:
				push += (k.pos - p.pos).normalized() * 0.5
				break
	return push.normalized() if push.length() > 0.05 else Vector2.ZERO


# --- targeting, Streik, ultimates -----------------------------------------------

## target=1: focus bosses and elites (most HP) when one is in reach and few adds
## crowd the player; otherwise the closest enemy (the default).
func choose_target(s, p) -> void:
	if not target or _frame % int(tune["decide"]) != 0:
		return
	var reach := kite_reach(s, p)
	var boss_in := false
	var adds := 0
	for e in s.enemies:
		if not e.alive or e.behind:
			continue
		var d: float = e.pos.distance_to(p.pos)
		if e.encounter != "" and d < minf(reach, 600.0) * 1.3:
			boss_in = true
		elif d < 150.0:
			adds += 1
	var mode: int = Sim.Target.MOST_HP if boss_in and adds < 4 else Sim.Target.CLOSEST
	if _nearest_box(s, p.pos) != null:
		mode = Sim.Target.CLOSEST   # the letterboxes first (D-142)
	if _mode.get(p.id, -1) != mode:
		_mode[p.id] = mode
		s.request(p.id, "target_mode", mode)


## Gewerkschaft's Streik (org ability): during a boss fight or a big crowd.
func use_streik(s) -> void:
	if not streik or not s.streik_available or s.phase != Sim.Phase.WAVE:
		return
	var crowd: bool = s.enemies.size() >= 25
	if s._encounter_alive() or crowd:
		for p in s.players.values():
			if p.state == 0 and s.request(p.id, "streik"):
				return


func want_ult(s, p) -> bool:
	if ult == "0" or not p.ult_ready:
		return false
	if ult == "smart":
		return _want_ult_smart(s, p)
	var boss_near := false
	var near := 0
	for e in s.enemies:
		if not e.alive or e.behind:
			continue
		var d: float = e.pos.distance_to(p.pos)
		if e.encounter != "" and d < ULT_BOSS_NEAR:
			boss_near = true
		if d < ULT_NEAR:
			near += 1
	if ult == "boss":
		return boss_near
	return boss_near or near >= ULT_CROWD or (near > 0 and p.hp < p.stats["max_hp"] * 0.4)


## smart: heal ults when hurt, the dash when surrounded, damage and control ults
## saved for the boss in boss waves (unless HP gets low) and used on crowds
## otherwise; with cast_ult a stun ult waits for a boss cast once the sim has casts.
func _want_ult_smart(s, p) -> bool:
	var id: String = Content.CHARACTERS[p.char_id].get("ult", "")
	var u: Dictionary = Content.ULTS.get(id, {})
	var hp_share: float = p.hp / maxf(1.0, p.stats["max_hp"])
	var close := 0
	var near := 0
	var boss = null
	for e in s.enemies:
		if not e.alive or e.behind:
			continue
		var d: float = e.pos.distance_to(p.pos)
		if d < 150.0:
			close += 1
		if d < 260.0:
			near += 1
		if e.encounter != "" and d < float(u.get("radius", 300.0)) + e.radius:
			boss = e
	if u.has("heal_per_s") or u.has("regen"):
		var downed := false
		for o in s.players.values():
			if o.state == 1:
				downed = true
		return (hp_share < 0.45 and near > 0) or (downed and u.has("revive_hp"))
	if u.has("dash_time"):
		return close >= 8 or (hp_share < 0.35 and close > 0) or (boss != null and s.wave in BOSS_WAVES)
	var boss_wave: bool = s.wave in BOSS_WAVES or s.encounter != ""
	if boss != null:
		# D-102: every stun interrupts a boss cast. Hold a stun ult for a cast that a stun
		# can break (no Pressekonferenz, no Standfest), but not longer than CAST_HOLD s.
		if cast_ult and u.has("stun") and "boss_cast" in s:
			if not _boss_seen.has(p.id) or float(_boss_seen[p.id][0]) != float(s.wave):
				_boss_seen[p.id] = [s.wave, s.time]
			var can: bool = s.boss_can_stun() if s.has_method("boss_can_stun") else true
			var waited: float = s.time - float(_boss_seen[p.id][1])
			return (str(s.boss_cast) != "" and can) or hp_share < 0.3 or waited > CAST_HOLD
		return true
	if boss_wave:
		return hp_share < 0.3 and near > 0
	return near >= ULT_CROWD or (hp_share < 0.4 and near > 0)
