extends SceneTree
## Headless test runner:
##   godot --headless --path . -s res://tests/godot/run_tests.gd [-- filter]
## Runs every tests/godot/test_*.gd (TestCase subclasses). Exit code 1 on failure.

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


func _run() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var total := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at(DIR))
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		if filter != "" and not file.contains(filter):
			continue
		var script: GDScript = load(DIR.path_join(file))
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
