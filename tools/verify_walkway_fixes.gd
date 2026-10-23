extends "res://tools/verify_scene_atmosphere.gd"


func _initialize() -> void:
	capture = "--capture-walkway" in OS.get_cmdline_user_args()
	create_timer(150,true).timeout.connect(func(): _fail("Walkway fixes timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280,720)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world = load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene = world
	party = world.party
	player = party.player
	second = party.second_player
	first = world.cooperation
	bridge = world.bridge
	court = world.courtyard
	ui = world.get_node("PartyUI")
	nearby_ui = world.get_node("NearbyInteractions")
	await _frames(20)
	var button: Rect2 = ui.sound_button.get_global_rect()
	if button.position.x < 1150 or button.end.x > 1257 or button.position.y > 30:
		_fail("Title sound entry still covers a face: "+str(button)); return
	_save_coop("walkway-title-sound-corner")
	await _click_at(button.get_center())
	if ui.screen != ui.Screen.SETTINGS: _fail("Relocated title sound button does not click"); return
	await _near_key(KEY_ESCAPE)
	await _start_default_party()
	if ui.sound_button.get_global_rect().intersects(ui.satchel_button.get_global_rect()) or ui.sound_button.get_global_rect().intersects(ui.restart_button.get_global_rect()):
		_fail("Rearranged HUD buttons overlap"); return
	world.start_creek_preview()
	await _put(25.7,26.5)
	for i in range(party.followers.size()):
		party.followers[i].global_position = Vector3(22.2+i*.5,.72,0)
		party.followers[i].velocity = Vector3.ZERO
	for frame in range(250):
		await _frames(1)
		if not _grounded_followers(): return
	_clear_dialogue()
	await _frames(3)
	_save_coop("walkway-logs-followers-grounded")
	# A goal inside the log is projected to free ground; then both followers traverse past it.
	await _put(28.2,28.9)
	for frame in range(240):
		await _frames(1)
		if not _grounded_followers(): return
	for actor in party.followers:
		if actor.global_position.x < 26: _fail("Follower sticks behind the logs: "+str(actor.global_position)); return
	await _put(20.6,21.4)
	party.last_direction = -1
	party.second_direction = -1
	for frame in range(270):
		await _frames(1)
		if not _grounded_followers(): return
	for actor in party.followers:
		if actor.global_position.x > 23.35: _fail("Follower cannot return around logs: "+str(actor.global_position)+" goal="+str(party.follower_target_position(actor))); return
	# Jumping against the work material cannot make either human stand on its top.
	await _put(23.1,25)
	for slot in range(2):
		var actor: CharacterBody3D = [player,second][slot]
		Input.action_press(actor.action("move_right" if slot==0 else "move_left"))
		Input.action_press(actor.action("jump"))
		await _frames(3)
		Input.action_release(actor.action("jump"))
		await _frames(55)
		Input.action_release(actor.action("move_right" if slot==0 else "move_left"))
		if actor.global_position.y > .88: _fail("A human stands on the timber"); return
	bridge.bridge_ready = true
	bridge.gap_stabilized = true
	bridge.step = 6
	bridge.get_node("BridgeAssembly").visible = true
	bridge.get_node("BridgeAssembly").rotation.z = 0
	bridge.get_node("BridgeBody/Collision").set_deferred("disabled",false)
	await _frames(5)
	# Four bank/edge combinations, walking and jumping diagonally into each bridge end.
	for direction in [1,-1]:
		for depth in [-1.0,1.7]:
			await _put(30.8 if direction==1 else 39.2,31.0 if direction==1 else 39.0)
			for actor in [player,second]: actor.global_position.z = depth
			for actor in [player,second]:
				Input.action_press(actor.action("move_right" if direction==1 else "move_left"))
				Input.action_press(actor.action("move_back" if depth>0 else "move_forward"))
			for frame in range(180):
				if frame%42==0:
					for actor in [player,second]: Input.action_press(actor.action("jump"))
				if frame%42==3:
					for actor in [player,second]: Input.action_release(actor.action("jump"))
				await _frames(1)
				for actor in [player,second]:
					if actor.global_position.y < .64: _fail("Diagonal bridge entry drops off deck: "+str(actor.global_position)); return
					if actor.global_position.x>31.8 and actor.global_position.x<38.2 and absf(actor.global_position.z)>.71:
						_fail("A bridge corner can still be bypassed"); return
			for actor in [player,second]:
				for action in ["move_left","move_right","move_forward","move_back","jump"]: Input.action_release(actor.action(action))
	await _put(33,34)
	_clear_dialogue()
	await _frames(10)
	_save_coop("walkway-bridge-ends-safe")
	world.start_garden_preview()
	await _put(49.5,51)
	_clear_dialogue()
	await _frames(15)
	var plaques: Array[Node] = get_nodes_in_group("world_plaques")
	for title in ["同源异彩","灯火共庭"]:
		var plaque: Node3D
		for item in plaques:
			if item.get_meta("title")==title: plaque = item
		var box: AABB = world.folk._bounds(plaque)
		if box.size.x<3.5 or box.size.y<.8: _fail("Final plaque still too small: "+title); return
		var rect: Rect2 = _project_box(plaque,box)
		for lamp in world.festival.lanterns + world.festival.grand.sky_lanterns:
			if rect.intersects(_project_box(lamp,world.folk._bounds(lamp))):
				_fail("Lantern still covers enlarged plaque "+title+" lamp="+str(lamp.position)+" rect="+str(rect)); return
	_save_coop("walkway-clear-large-plaques")
	print("WALKWAY_FIXES_OK: title and gameplay sound entry at far top-right, actual click, unobstructed enlarged final plaques, followers route on ground around logs in both directions and with blocked goals, humans cannot stand on timber, diagonal/jumping entry at all four bridge corners without falling")
	quit(0)


func _grounded_followers() -> bool:
	for actor in party.followers:
		if actor.global_position.y>.88 or actor.global_position.y<.64:
			_fail("Follower jumps or falls near timber: "+str(actor.global_position)); return false
	return true


func _project_box(node: Node3D, box: AABB) -> Rect2:
	var rect := Rect2()
	for i in range(8):
		var point: Vector2 = world.camera.unproject_position(node.global_transform*box.get_endpoint(i))
		if i==0: rect = Rect2(point,Vector2.ZERO)
		else: rect = rect.expand(point)
	return rect
