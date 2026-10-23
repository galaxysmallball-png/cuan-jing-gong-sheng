extends SceneTree


func _initialize() -> void:
	var config := ConfigFile.new()
	if config.load("res://project.godot") != OK: quit(1); return
	var bindings := {"move_forward": [KEY_W], "move_back": [KEY_S], "jump": [KEY_SPACE], "interact": [KEY_E],
		"p2_move_forward": [KEY_UP], "p2_move_back": [KEY_DOWN], "p2_jump": [KEY_CTRL], "p2_interact": [KEY_P, KEY_KP_0]}
	for action in bindings:
		var events: Array[InputEvent] = []
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if action == "p2_jump": event.location = KEY_LOCATION_RIGHT
			events.append(event)
		config.set_value("input", action, {"deadzone": .2, "events": events})
	if config.save("res://project.godot") != OK: quit(1); return
	print("PLANAR_CONTROLS_CONFIGURED: WASD/Space/E and arrows/right Ctrl/P or keypad0")
	quit(0)
