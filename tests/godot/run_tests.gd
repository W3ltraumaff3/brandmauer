extends SceneTree
## Headless test runner:
##   godot --headless --path . -s res://tests/godot/run_tests.gd [-- filter]
##   godot ... -s res://tests/godot/run_tests.gd -- areas=sim,ui [files=test_x.gd,…]
## Runs every tests/godot/test_*.gd (TestCase subclasses). Exit code 1 on failure.
## With areas= / files= (ci-cd.md §2a, picked by tools/affected_tests.py) only
## the files whose AREAS overlap, the named files and files without AREAS run.

const DIR := "res://tests/godot"


## Counts engine/script errors so a crashing test can't pass silently.
class ErrorCounter extends Logger:
	var count := 0
	var last := ""

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		count += 1
		last = "%s (%s:%d %s)" % [rationale if rationale != "" else code, file, line, function]


var _errors := ErrorCounter.new()


func _initialize() -> void:
	# Autoloads are not registered for -s scripts; give tests the ones they need.
	for name in ["Loc", "Save"]:
		if root.get_node_or_null(name) == null:
			var node: Node = load("res://src/autoload/%s.gd" % name.to_lower()).new()
			node.name = name
			root.add_child(node)
	OS.add_logger(_errors)
	var save_node := root.get_node_or_null("Save")
	if save_node:
		save_node.persist = false
	call_deferred("_run")


static func _all_scripts(dirs: Array) -> Array[String]:
	var out: Array[String] = []
	for d in dirs:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				out.append(str(d).path_join(f))
		for sub in DirAccess.get_directories_at(d):
			out.append_array(_all_scripts([str(d).path_join(sub)]))
	return out


## A test file runs for an area selection if it was named, declares no AREAS
## (unknown coverage: always run) or shares an area with the selection.
static func runs_for(file_areas, areas: PackedStringArray, is_named: bool) -> bool:
	if is_named or not (file_areas is Array):
		return true
	for a in file_areas:
		if areas.has(str(a)):
			return true
	return false


func _run() -> void:
	var filter := ""
	var areas := PackedStringArray()
	var named := PackedStringArray()
	var by_area := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("areas="):
			by_area = true
			areas = a.trim_prefix("areas=").split(",", false)
		elif a.begins_with("files="):
			by_area = true
			named = a.trim_prefix("files=").split(",", false)
		elif filter == "":
			filter = a
	var total := 0
	var failed := 0
	# Every script of the project must compile (one broken line, e.g. `:=` on a
	# Variant, silently takes a whole script and all its callers down).
	if filter == "" or by_area:
		for path in _all_scripts(["res://src", "res://tools", DIR]):
			total += 1
			var s := load(path) as GDScript
			if s == null or not s.can_instantiate():
				failed += 1
				printerr("  FAIL %s does not compile (see the parse error above)" % path)
		print("  ok   every script compiles (%d checked)" % total)
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		if filter != "" and not by_area and not file.contains(filter):
			continue
		var script: GDScript = load(DIR.path_join(file))
		# A test file that doesn't compile has no methods: count it, never skip it.
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			printerr("  FAIL %s: does not compile (see the parse error above)" % file)
			continue
		if by_area and not runs_for(script.get_script_constant_map().get("AREAS"), areas, named.has(file)):
			continue
		for m in script.get_script_method_list():
			var mname: String = m["name"]
			if not mname.begins_with("test_"):
				continue
			var t: TestCase = script.new()
			t._current = "%s::%s" % [file, mname]
			var errors_before := _errors.count
			t.before_each()
			t.call(mname)
			t.after_each()
			if _errors.count > errors_before:
				t.fail("%d engine/script error(s), last: %s" % [_errors.count - errors_before, _errors.last])
			total += 1
			if t.failures.is_empty():
				print("  ok   ", t._current)
			else:
				failed += 1
				for f in t.failures:
					printerr("  FAIL ", f)
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)
