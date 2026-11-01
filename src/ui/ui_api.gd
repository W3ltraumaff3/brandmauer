class_name UIApi
## Defensive bridge from the menus to the autoloads `Game`, `Net` and `Audio`
## (architecture §8). Every access is dynamic, so the UI keeps working (with
## empty states) while an autoload is missing or still a stub.
##
## The `preview_*` overrides are only set by tools/ui_preview.gd.

static var preview_meta: Dictionary = {}
static var preview_lobby: Dictionary = {}
static var preview_local_id := 0
static var preview_mode := ""          # "solo" | "host" | "client" | "server"
static var preview_unlocks: Dictionary = {}
static var preview_net: Dictionary = {}  # org, difficulty, upnp_status, lan_games


static func _root() -> Node:
	var loop := Engine.get_main_loop()
	return (loop as SceneTree).root if loop is SceneTree else null


static func node(autoload_name: String) -> Object:
	var r := _root()
	return r.get_node_or_null(autoload_name) if r else null


static func game() -> Object:
	return node("Game")


static func net() -> Object:
	return node("Net")


static func audio() -> Object:
	return node("Audio")


## Reads a property from an autoload, or `default` if it doesn't exist (yet).
static func prop(obj: Object, key: String, default = null):
	if obj == null:
		return default
	for p in obj.get_property_list():
		if p["name"] == key:
			var v = obj.get(key)
			return default if v == null else v
	return default


## Calls `method` if the object has it. Passes only as many args as it takes.
static func call_opt(obj: Object, method: String, args: Array = [], default = null):
	if obj == null or not obj.has_method(method):
		return default
	var n := obj.get_method_argument_count(method)
	if n < args.size():
		args = args.slice(0, n)
	return obj.callv(method, args)


static func connect_opt(obj: Object, sig: String, callable: Callable) -> void:
	if obj and obj.has_signal(sig) and not obj.is_connected(sig, callable):
		obj.connect(sig, callable)


static func disconnect_opt(obj: Object, sig: String, callable: Callable) -> void:
	if obj and obj.has_signal(sig) and obj.is_connected(sig, callable):
		obj.disconnect(sig, callable)


# --- Game -------------------------------------------------------------------

static func meta() -> Dictionary:
	if not preview_meta.is_empty():
		return preview_meta
	var m = prop(game(), "meta", {})
	return m if m is Dictionary else {}


static func local_id() -> int:
	if preview_local_id != 0:
		return preview_local_id
	var g := game()
	if g and g.has_method("local_id"):
		return int(g.call("local_id"))
	var r := _root()
	if r and r.multiplayer:
		return r.multiplayer.get_unique_id()
	return 1


## Looks a peer up in a Dictionary whose keys may be int or String
## (depending on how the data travelled).
static func by_peer(dict: Dictionary, peer) -> Dictionary:
	if dict.has(peer):
		return dict[peer] if dict[peer] is Dictionary else {}
	for k in dict:
		if str(k) == str(peer):
			return dict[k] if dict[k] is Dictionary else {}
	return {}


static func local_meta() -> Dictionary:
	if preview_meta.is_empty():
		var g := game()
		if g and g.has_method("local_meta"):
			var lm = g.call("local_meta")
			if lm is Dictionary:
				return lm
	return by_peer(meta().get("players", {}), local_id())


## "solo" | "host" | "client" | "server" | "none"
static func mode() -> String:
	if preview_mode != "":
		return preview_mode
	var g := game()
	var m = prop(g, "mode", null)
	if m == null:
		if prop(net(), "dedicated", false):
			return "server"
		return "none"
	var names := ["none", "solo", "host", "client", "server"]
	var enum_map = g.get_script().get_script_constant_map().get("Mode", {}) if g.get_script() else {}
	if enum_map is Dictionary:
		for key in enum_map:
			if int(enum_map[key]) == int(m):
				return String(key).to_lower()
	return names[clampi(int(m), 0, names.size() - 1)]


static func is_solo() -> bool:
	return mode() == "solo"


static func is_host() -> bool:
	if preview_mode != "":
		return preview_mode != "client"
	var n := net()
	if n and n.has_method("is_host"):
		return bool(n.call("is_host"))
	return mode() != "client"


static func request(action: String, arg = null) -> void:
	if not preview_meta.is_empty():
		print("[preview] request ", action, " ", arg)
		return
	call_opt(game(), "request", [action, arg])


static func last_unlocks() -> Dictionary:
	if not preview_unlocks.is_empty():
		return preview_unlocks
	var u = prop(game(), "last_unlocks", {})
	return u if u is Dictionary else {}


# --- Net --------------------------------------------------------------------

static func lobby() -> Dictionary:
	if not preview_lobby.is_empty():
		return preview_lobby
	var l = prop(net(), "lobby", {})
	return l if l is Dictionary else {}


static func net_value(key: String, default):
	if preview_net.has(key):
		return preview_net[key]
	return prop(net(), key, default)


static func port() -> int:
	var n := net()
	var p = prop(n, "active_port", prop(n, "port", null))
	if p != null and int(p) > 0:
		return int(p)
	if n and n.get_script():
		return int(n.get_script().get_script_constant_map().get("PORT", 24713))
	return 24713


# --- Audio ------------------------------------------------------------------

static func sfx(id: String) -> void:
	call_opt(audio(), "play_sfx", [id])


# --- Save (accessed dynamically so the UI also compiles in -s tool scripts) ---

static func save_node():
	return node("Save")


static func save_data() -> Dictionary:
	var d = prop(save_node(), "data", {})
	return d if d is Dictionary else {}


static func option(key: String, default = null):
	var s = save_node()
	return s.option(key, default) if s else default


static func set_option(key: String, value) -> void:
	var s = save_node()
	if s:
		s.set_option(key, value)


static func char_unlocked(id: String) -> bool:
	var s = save_node()
	if s:
		return bool(s.is_char_unlocked(id))
	return not Content.CHARACTERS.get(id, {}).get("locked", true)


static func has_achievement(id: String) -> bool:
	var s = save_node()
	return bool(s.has_achievement(id)) if s else false


static func album_has(quote_id: String) -> bool:
	var s = save_node()
	return bool(s.album_has(quote_id)) if s else false
