extends SceneTree
## End-to-end: real main scene, UI and rendering; a cheating bot plays a whole
## solo run (all 20 waves, every encounter) at 8x speed. Fails on any script error.
##   godot --path . -s res://tools/e2e_playthrough.gd [-- shots=<dir>]

class ErrorCounter extends Logger:
	var count := 0
	var lines: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING or file.contains("string_name.cpp"):
			return
		count += 1
		if lines.size() < 20:
			lines.append("%s (%s:%d %s)" % [rationale if rationale != "" else code, file, line, function])


var _errors := ErrorCounter.new()
var _game: Node
var _shots := ""
var _frame := 0
var _shot_waves := {}
var _done := false


func _initialize() -> void:
	OS.add_logger(_errors)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			_shots = a.substr(6)
	root.add_child(load("res://scenes/main.tscn").instantiate())
	_game = root.get_node("Game")
	Engine.time_scale = 8.0
	Engine.max_physics_steps_per_frame = 16
	call_deferred("_start")


func _start() -> void:
	_game.open_solo()
	root.get_node("Net").set_char("gewerkschaft")
	await process_frame
	_shot("lobby")
	_game.start_run()


func _process(_delta: float) -> bool:
	_frame += 1
	if _done:
		return true
	var sim: Sim = _game.sim
	if sim == null:
		if _frame > 30000:
			_finish("timeout without run")
		return false
	if sim.phase == Sim.Phase.WAVE:
		for p in sim.players.values():
			p.iframes = 10.0
			if p.levelup_stats.get("damage", 0.0) < 1500.0:
				p.levelup_stats["damage"] = 1500.0
				sim._recompute(p)
			var target := Vector2(800, 600)
			for e in sim.enemies:
				if e.alive and e.elite:
					target = e.pos
			Input.action_release("move_left")
			p.input = (target - p.pos).normalized() if target.distance_to(p.pos) > 80.0 else Vector2.ZERO
		if sim.wave in [5, 10, 15, 20] and not _shot_waves.has(sim.wave) and sim.wave_time > 3.0:
			_shot_waves[sim.wave] = true
			_shot("wave%d" % sim.wave)
	elif sim.phase == Sim.Phase.SHOP:
		if not _shot_waves.has("shop"):
			_shot_waves["shop"] = true
			_shot("spaeti")
		_game.request("buy", 0)
		_game.request("levelup", 0)
		_game.request("vote", 1)
		_game.request("ready", true)
	elif sim.phase == Sim.Phase.OVER and _frame % 60 == 0 and root.get_node("Main").get_child_count() > 0:
		if _game.config.is_empty() or _game.last_unlocks.size() > 0:
			_shot("end")
			_finish("")
	return false


func _shot(name: String) -> void:
	if _shots == "":
		return
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shots)
	img.save_png(_shots.path_join("e2e_%s.png" % name))


func _finish(reason: String) -> void:
	_done = true
	var sim: Sim = _game.sim
	var res: Dictionary = sim.result if sim else {}
	print("E2E result: won=%s wave=%s encounters=%s errors=%d %s" % [
		res.get("won", false), res.get("wave", 0), res.get("encounters_beaten", []), _errors.count, reason])
	for l in _errors.lines:
		printerr("  ", l)
	var ok: bool = reason == "" and res.get("won", false) and _errors.count == 0
	quit(0 if ok else 1)
