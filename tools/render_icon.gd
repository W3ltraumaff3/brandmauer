extends SceneTree
## Renders icon.svg to PNGs for the Windows icon:
##   godot --headless --path . -s res://tools/render_icon.gd -- <out_dir>

func _initialize() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var svg := FileAccess.get_file_as_bytes("res://icon.svg")
	for size in [16, 32, 48, 256]:
		var img := Image.new()
		img.load_svg_from_buffer(svg, size / 128.0)
		img.save_png(out.path_join("icon_%d.png" % size))
	quit()
