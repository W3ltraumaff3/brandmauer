class_name RunScreen
extends Node
## The "run" screen (instantiated by main.gd): world, camera, effects, HUD and the
## Späti / pause overlays. Reads Game.view / Game.meta, listens to Game.events.
## Every access to Game is dynamic so this works with a stub or missing autoload.

const SPAETI_PATH := "res://src/ui/spaeti.gd"
const PAUSE_PATH := "res://src/ui/pause_menu.gd"
const ZOOM := 0.92
const WAVE_WON_PAUSE := 2.0          # s of "Feierabend!" over the arena before the Späti (GDD §5)

var world: WorldView
var fx: Fx
var camera: Camera2D
var hud: Hud
var hud_layer: CanvasLayer
var overlay_layer: CanvasLayer

var _spaeti: Node
var _prev_phase := -1
var _shop_wait := 0.0
var _pause: Node
var _shake := 0.0
var _cam_init := false
var _prewarmed := {}


func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func _ready() -> void:
	world = WorldView.new()
	world.name = "World"
	add_child(world)
	fx = Fx.new()
	fx.name = "Fx"
	fx.world = world
	add_child(fx)
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = -60
	camera.limit_top = -90
	camera.limit_right = int(WorldView.ARENA.x) + 60
	camera.limit_bottom = int(WorldView.ARENA.y) + 60
	camera.position = WorldView.ARENA * 0.5
	add_child(camera)
	camera.make_current()
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	hud = Hud.new()
	hud.world = world
	hud_layer.add_child(hud)
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 10
	add_child(overlay_layer)
	var g := WorldView.game_node()
	if g:
		if g.has_signal("events"):
			g.connect("events", _on_events)
	_prewarm(0)


func _exit_tree() -> void:
	var g := WorldView.game_node()
	if g and g.has_signal("events") and g.is_connected("events", _on_events):
		g.disconnect("events", _on_events)


func _prewarm(st: int) -> void:
	if _prewarmed.has(st):
		return
	_prewarmed[st] = true
	world.prewarm(st)


func _on_events(evs: Array) -> void:
	for ev in evs:
		if not (ev is Array) or ev.is_empty():
			continue
		world.handle_event(ev)
		fx.handle_event(ev)
		hud.handle_event(ev)
		match str(ev[0]):
			"stage":
				# bake the next stage's meshes before they are needed
				if ev.size() > 1:
					_prewarm.call_deferred(clampi(int(ev[1]) + 1, 0, 4))
			"sfx":
				if ev.size() > 1 and str(ev[1]) == "explosion":
					_shake = maxf(_shake, 5.0)
			"dmg":
				if ev.size() > 4 and bool(ev[4]):
					var me := _local_player()
					if not me.is_empty() and (me.get("pos", Vector2.INF) as Vector2).distance_to(ev[1]) < 40.0:
						_shake = maxf(_shake, 4.0)
			"exit", "streik":
				_shake = maxf(_shake, 7.0)


func _process(delta: float) -> void:
	var g := WorldView.game_node()
	var paused := g != null and g.has_method("is_paused") and bool(g.call("is_paused"))
	world.set_process(not paused)
	fx.set_process(not paused)
	_update_camera(delta)
	_update_overlays(delta)
	if InputMap.has_action("pause") and Input.is_action_just_pressed("pause"):
		_toggle_pause()
	if InputMap.has_action("streik") and Input.is_action_just_pressed("streik") and not paused:
		var meta := world.get_meta_dict()
		var s = meta.get("streik", {})
		if s is Dictionary and bool(s.get("available", false)) and g and g.has_method("request"):
			g.call("request", "streik")


func _local_player() -> Dictionary:
	var vs := world.get_view()
	if vs == null:
		return {}
	return vs.find_player(world.local_id())


func _update_camera(delta: float) -> void:
	var vs := world.get_view()
	var target := WorldView.ARENA * 0.5
	if vs:
		var me := vs.find_player(world.local_id())
		if not me.is_empty() and int(me.get("state", 0)) == 0:
			target = me.get("pos", target)
		else:
			var found := false
			for p in vs.players:
				if int(p.get("state", 0)) == 0:
					target = p.get("pos", target)
					found = true
					break
			if not found and not me.is_empty() and int(me.get("state", 0)) == 1:
				target = me.get("pos", target)
	if not _cam_init and vs:
		camera.position = target
		camera.reset_smoothing()
		_cam_init = true
	camera.position = target
	if _shake > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = maxf(0.0, _shake - delta * 25.0)
	else:
		camera.offset = Vector2.ZERO


## True once the Späti may open: WAVE_WON_PAUSE after a won wave (wave -> shop),
## at once when the screen starts in the Späti (join, rejoin).
func _spaeti_due(phase: int, delta: float) -> bool:
	if phase == 1 and _prev_phase == 0:
		_shop_wait = WAVE_WON_PAUSE
	_prev_phase = phase
	if phase != 1:
		_shop_wait = 0.0
		return false
	_shop_wait = maxf(0.0, _shop_wait - delta)
	return _shop_wait <= 0.0


func _update_overlays(delta: float) -> void:
	var meta := world.get_meta_dict()
	var vs := world.get_view()
	var phase := int(meta.get("phase", vs.phase if vs else 0))
	if _spaeti_due(phase, delta):
		if _spaeti == null or not is_instance_valid(_spaeti):
			_spaeti = _make(SPAETI_PATH)
			if _spaeti:
				overlay_layer.add_child(_spaeti)
				overlay_layer.move_child(_spaeti, 0)
				if _spaeti is Control:
					UINav.block_if_covered(_spaeti as Control)  # pause menu already open
	elif phase != 1 and _spaeti != null:
		if is_instance_valid(_spaeti):
			_spaeti.queue_free()
		_spaeti = null


func _toggle_pause() -> void:
	if _pause != null and is_instance_valid(_pause):
		if not _pause.is_queued_for_deletion():
			if _pause.has_method("resume_game"):
				_pause.call("resume_game")
			else:
				_pause.queue_free()
		_pause = null
		return
	_pause = _make(PAUSE_PATH)
	if _pause:
		overlay_layer.add_child(_pause)


## Instantiate a UI script by path, or null if it doesn't exist (yet).
func _make(path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var script = load(path)
	if not (script is Script) or not (script as Script).can_instantiate():
		return null
	var n = script.new()
	if n is Control:
		(n as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return n if n is Node else null
