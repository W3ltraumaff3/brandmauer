extends SceneTree
## Reports the compile error of one script:
##   godot --headless --path . -s res://tools/check_script.gd -- res://src/sim/sim.gd

func _initialize() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var script := GDScript.new()
	script.source_code = FileAccess.get_file_as_string(path)
	script.resource_path = path
	var err := script.reload()
	print("%s: %s" % [path, "OK" if err == OK else error_string(err)])
	quit(0 if err == OK else 1)
