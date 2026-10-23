extends "res://tools/verify_local_coop.gd"


func _run() -> void:
	capture = true
	root.mode = Window.MODE_MINIMIZED
	OS.low_processor_usage_mode = false
	capture_viewport = SubViewport.new()
	capture_viewport.size = Vector2i(1280,720)
	capture_viewport.own_world_3d = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(capture_viewport)
	world = load("res://scenes/world.tscn").instantiate()
	capture_viewport.add_child(world)
	party = world.get_node("Party")
	player = world.get_node("Player")
	second = party.second_player
	ui = world.get_node("PartyUI")
	await _frames(30)
	ui.secondary.pressed.emit()
	await _frames(3)
	for index in range(4):
		_save_coop("ethnic-intro-%d" % (index + 1))
		await _tap("ui_accept")
	await _tap("skip_intro")
	await _tap("ui_accept")
	party.reset_positions(true)
	await _frames(40)
	_save_coop("ethnic-party")
	party.switch_to(3,0)
	if not await _duo_walk(12.6,11.5):
		_fail("Cannot frame the party near the steles"); return
	await _frames(30)
	_save_coop("ethnic-names")
	world.start_creek_preview()
	await _frames(60)
	_save_coop("ethnic-creek")
	world.start_garden_preview()
	await _frames(60)
	_save_coop("ethnic-garden")
	print("ETHNIC_LABELS_CAPTURE_OK: four introductions, both selectors/HUDs, player/follower names, creek and garden guidance")
	quit(0)
