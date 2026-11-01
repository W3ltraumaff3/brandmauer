extends SceneTree
## Lists connected controllers as Godot sees them and samples their axes and
## buttons for 2 s (for controller bug reports):
##   godot --path . -s res://tools/joypad_info.gd

func _initialize() -> void:
	await process_frame
	await process_frame
	var pads := Input.get_connected_joypads()
	print("connected joypads: %s" % [pads])
	for d in pads:
		print("  device %d: name=%s known=%s" % [d, Input.get_joy_name(d), Input.is_joy_known(d)])
	var max_axis := {}
	var buttons := {}
	for f in 120:
		await process_frame
		for d in pads:
			for a in JOY_AXIS_MAX:
				var v := absf(Input.get_joy_axis(d, a))
				if v > max_axis.get(Vector2i(d, a), 0.0):
					max_axis[Vector2i(d, a)] = v
			for b in JOY_BUTTON_MAX:
				if Input.is_joy_button_pressed(d, b):
					buttons[Vector2i(d, b)] = true
	for k in max_axis:
		if max_axis[k] > 0.05:
			print("  device %d axis %d at rest up to %.2f" % [k.x, k.y, max_axis[k]])
	for k in buttons:
		print("  device %d button %d pressed" % [k.x, k.y])
	var vec := Input.get_vector("move_left", "move_right", "move_up", "move_down") if InputMap.has_action("move_left") else Vector2.ZERO
	print("move vector at rest: %s" % vec)
	quit()
