extends "res://tools/verify_grand_court.gd"


func _initialize() -> void:
	capture = "--capture-atmosphere" in OS.get_cmdline_user_args()
	create_timer(150,true).timeout.connect(func(): _fail("Scene atmosphere test timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		if DisplayServer.get_name()=="headless": _fail("Visual capture needs the GPU"); return
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
	await _start_default_party()
	await _put(9.5,10.4)
	_clear_dialogue()
	await _frames(10)
	_save_coop("atmosphere-sunset-court")
	await _click_at(ui.sound_button.get_global_rect().get_center())
	await _frames(3)
	var rect: Rect2 = ui.audio_settings.panel.get_global_rect()
	if rect.position.x < 890 or rect.position.y > 90 or rect.end.x > 1257 or rect.end.y > 355:
		_fail("Sound panel is not compact in the upper-right: "+str(rect)); return
	for slider in [ui.music_slider,ui.effects_slider]:
		if not rect.encloses(slider.get_global_rect()): _fail("Sound slider spills outside paper"); return
	var music_before: float = world.music.volume
	await _drag_music(.38)
	await _drag_slider(.85,.66)
	if absf(world.music.volume-.38)>.06 or absf(world.sfx.volume-.66)>.06:
		_fail("Upper-right sliders no longer work"); return
	_save_coop("atmosphere-upper-right-sound")
	await _near_key(KEY_ESCAPE)
	world.music.set_volume(music_before)
	world.start_creek_preview()
	await _put(28.8,29.7)
	_clear_dialogue()
	await _frames(10)
	_save_coop("atmosphere-moonlit-trail")
	bridge.bridge_ready = true
	bridge.gap_stabilized = true
	bridge.step = 6
	bridge.get_node("BridgeAssembly").visible = true
	bridge.get_node("BridgeAssembly").rotation.z = 0
	bridge.get_node("BridgeBody/Collision").set_deferred("disabled",false)
	await _frames(5)
	# Both edges: hold toward the rope throughout take-off, landing and repeated jumps.
	for side in [-1,1]:
		await _put(34.2,35.5)
		for body in [player,second]: body.global_position.z = side*.55
		for cycle in range(3):
			Input.action_press("move_back" if side==1 else "move_forward")
			Input.action_press("p2_move_back" if side==1 else "p2_move_forward")
			Input.action_press("jump")
			Input.action_press("p2_jump")
			await _frames(3)
			Input.action_release("jump")
			Input.action_release("p2_jump")
			for frame in range(55):
				await _frames(1)
				for body in [player,second]:
					if absf(body.global_position.z)>.80 or (body.is_on_floor() and body.global_position.y>.88):
						_fail("A player reached the rope top: "+str(body.global_position)); return
		for action in ["move_back","move_forward","p2_move_back","p2_move_forward"]: Input.action_release(action)
	# Followers enter from both banks at a non-central depth without climbing ropes.
	for direction in [1,-1]:
		await _put(39.5 if direction==1 else 30.5,40.3 if direction==1 else 29.7)
		party.last_direction = direction
		party.second_direction = direction
		for body in [player,second]: body.global_position.z = 1.5
		for i in range(party.followers.size()):
			var follower: CharacterBody3D = party.followers[i]
			follower.global_position = Vector3(30.8 if direction==1 else 39.2,.72,1.4-i*.2)
			follower.velocity = Vector3.ZERO
			follower.detour_x = NAN
		for frame in range(260):
			await _frames(1)
			for follower in party.followers:
				if follower.global_position.x>31.75 and follower.global_position.x<38.25 and follower.is_on_floor() and follower.global_position.y>.88:
					_fail("A follower climbed a bridge rope: "+str(follower.global_position)); return
		for follower in party.followers:
			if absf(follower.global_position.x-party.follower_target(follower))>.4:
				_fail("Follower stuck at bridge end: "+str(follower.global_position)+" target="+str(party.follower_target_position(follower))); return
	await _put(35,36.1)
	_clear_dialogue()
	await _frames(12)
	_save_coop("atmosphere-bridge-safe-deck")
	world.start_garden_preview()
	await _put(49.5,51)
	_clear_dialogue()
	await _frames(12)
	_save_coop("atmosphere-lamp-court")
	court.tablet_placed = true
	# The stele only shows once act two hands it over; the shortcut has to state
	# that explicitly or the finale capture shows an empty guard frame.
	bridge.tablet_delivered = true
	court._tablet.visible = true
	court.items_done.fill(true)
	court.lamp_count = 7
	court.court_lit = true
	court._tablet.position = Vector3(10,1.5,-2.35)
	court._tablet.rotation.z = 0
	court.landscape.sync_state()
	await _frames(60)
	_clear_dialogue()
	await _frames(5)
	_save_coop("atmosphere-shared-finale")
	if world.scene_atmosphere.waterfall==null or world.scene_atmosphere.town_lights.multimesh.instance_count!=180:
		_fail("Concept scenery missing waterfall or distant lit town"); return
	if world.scene_atmosphere.static_meshes.size()>40: _fail("Static scenery is not batched"); return
	print("SCENE_ATMOSPHERE_OK: upper-right paper sound panel and physical independent sliders, repeated jumps toward both bridge rails, depth-offset followers across both ends without climbing or stalling, three concept-inspired landscapes, animated cliff waterfall, 180 distant town lights, batched native scenery")
	quit(0)


func _clear_dialogue() -> void:
	world.story.queue.clear()
	world.story.current = {}
