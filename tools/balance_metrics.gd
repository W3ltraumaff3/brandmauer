extends RefCounted
## Weapon delivery metrics for tools/balance_sim.gd (docs/specs/balancing.md §2),
## observed from the sim state every frame; the game code is not touched.
## Per player and weapon id:
##   casts       cooldown resets (shots fired, puddles/walls/stands placed, marks laid)
##   first_s/n   summed time from a cast to the weapon's next damage, and how often
##   shots/hits  player projectiles spawned (incl. summon shots such as Infostand
##               leaflets) and how many of them damaged at least one enemy
##   zones       damaging player zones placed (Kleber puddle, Kreide mark, each wall
##               brick), zone_life (s alive), zone_busy (s with >= 1 enemy inside),
##               zone_enemy_s (enemy-seconds inside)
##   summons     summons placed, summon_s (s alive), summon_busy (s with an enemy in reach)

const SAMPLE_EVERY := 2       # frames between zone/summon samples

var _cd := {}        # "pid/wkey" -> cooldown before the step
var _pending := {}   # "pid/wkey" -> sim time of a cast still waiting for its first damage
var _dmg := {}       # "pid/wkey" -> damage total before the step
var _proj := {}      # instance id -> [projectile, pid, wkey, hit]
var _zones := {}     # instance id -> [hazard, pid, wkey]
var _sums := {}      # instance id -> [summon, pid, wkey]
var _frame := 0
var out := {}        # pid -> {weapon id: {...}}


func _rec(p, key: String) -> Dictionary:
	var wid: String = str(p.sources.get(key, {}).get("id", key))
	if not out.has(p.id):
		out[p.id] = {}
	if not out[p.id].has(wid):
		out[p.id][wid] = {"casts": 0, "first_s": 0.0, "first_n": 0, "shots": 0, "hits": 0, "zones": 0,
			"zone_life": 0.0, "zone_busy": 0.0, "zone_enemy_s": 0.0, "summons": 0, "summon_s": 0.0, "summon_busy": 0.0}
	return out[p.id][wid]


func before_step(s) -> void:
	for p in s.players.values():
		for w in p.weapons:
			_cd["%d/%s" % [p.id, Sim._wkey(w)]] = float(w["cd"])


func after_step(s, dt: float) -> void:
	_frame += 1
	for p in s.players.values():
		for w in p.weapons:
			var key := Sim._wkey(w)
			var k := "%d/%s" % [p.id, key]
			if str(Content.WEAPONS.get(w["id"], {}).get("kind", "")) != "orbit":
				# a cast resets the cooldown to the weapon's cd; "no target" only sets 0.05
				if _cd.has(k) and float(w["cd"]) > float(_cd[k]) + 0.1:
					_rec(p, key)["casts"] += 1
					if not _pending.has(k):
						_pending[k] = s.time
			var d := float(p.dmg_total.get(key, 0.0))
			if d > float(_dmg.get(k, 0.0)) + 0.001 and _pending.has(k):
				var r := _rec(p, key)
				r["first_s"] += s.time - float(_pending[k])
				r["first_n"] += 1
				_pending.erase(k)
			_dmg[k] = d
	# projectiles
	for pr in s.projectiles:
		if pr.owner > 0 and not pr.harmless and pr.source != "":
			var id: int = pr.get_instance_id()
			if not _proj.has(id):
				var pl = s.players.get(pr.owner)
				if pl == null:
					continue
				_proj[id] = [pr, pl, pr.source, false]
				_rec(pl, pr.source)["shots"] += 1
	# The sim clears projectiles, hazards and summons at a wave's start and end without
	# marking them dead: whatever is no longer in its list is gone (else a cleared puddle
	# kept "living" and sampling enemies for the rest of the run).
	var live := {}
	for pr in s.projectiles:
		live[pr.get_instance_id()] = true
	for id in _proj.keys():
		var e: Array = _proj[id]
		if not e[3] and not e[0].hit_ids.is_empty():
			e[3] = true
			_rec(e[1], e[2])["hits"] += 1
		if not e[0].alive or not live.has(id):
			_proj.erase(id)
	if _frame % SAMPLE_EVERY != 0:
		return
	var step := dt * SAMPLE_EVERY
	live.clear()
	for h in s.hazards:
		live[h.get_instance_id()] = true
	for sm in s.summons:
		live[sm.get_instance_id()] = true
	# zones
	for h in s.hazards:
		if h.alive and h.owner > 0 and h.dps > 0.0:
			var id: int = h.get_instance_id()
			if not _zones.has(id):
				var pl = s.players.get(h.owner)
				if pl == null:
					continue
				var src := str(h.data.get("src", ""))
				_zones[id] = [h, pl, src if src != "" else "zone"]
				_rec(pl, _zones[id][2])["zones"] += 1
	for id in _zones.keys():
		var z: Array = _zones[id]
		if not z[0].alive or not live.has(id):
			_zones.erase(id)
			continue
		var n: int = s._query(z[0].pos, z[0].radius).size()
		var r := _rec(z[1], z[2])
		r["zone_life"] += step
		if n > 0:
			r["zone_busy"] += step
			r["zone_enemy_s"] += step * n
	# summons
	for sm in s.summons:
		if sm.alive and sm.owner > 0 and sm.source != "":
			var id: int = sm.get_instance_id()
			if not _sums.has(id):
				var pl = s.players.get(sm.owner)
				if pl == null:
					continue
				_sums[id] = [sm, pl, sm.source]
				_rec(pl, sm.source)["summons"] += 1
	for id in _sums.keys():
		var e: Array = _sums[id]
		if not e[0].alive or not live.has(id):
			_sums.erase(id)
			continue
		var r := _rec(e[1], e[2])
		r["summon_s"] += step
		if not s._query(e[0].pos, e[0].reach).is_empty():
			r["summon_busy"] += step


## Rounded per-player result for the JSON line.
func result(pid: int) -> Dictionary:
	var res := {}
	for wid in out.get(pid, {}):
		var r: Dictionary = out[pid][wid]
		var o := {}
		for k in r:
			o[k] = snappedf(r[k], 0.1) if r[k] is float else r[k]
		res[wid] = o
	return res
