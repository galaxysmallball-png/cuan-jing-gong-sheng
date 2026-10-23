extends "res://tools/verify_cooperative_experience.gd"

var watchdog: SceneTreeTimer


func _initialize() -> void:
	capture=true
	watchdog=create_timer(200,true)
	watchdog.timeout.connect(_timeout)
	call_deferred("_run")


func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	OS.low_processor_usage_mode=false
	capture_viewport=SubViewport.new()
	capture_viewport.size=Vector2i(1280,720)
	capture_viewport.own_world_3d=true
	capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	capture_viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	capture_viewport.add_child(world)
	party=world.party
	player=party.player
	second=party.second_player
	first=world.cooperation
	bridge=world.bridge
	court=world.courtyard
	ui=world.get_node("PartyUI")
	nearby_ui=world.get_node("NearbyInteractions")
	await _frames(12)
	await _start_default_party()
	world.start_garden_preview()
	await _frames(205)
	if not court.tablet_arriving or court.ARRIVAL_SECONDS!=6.4 or not is_instance_valid(court.carry_rig): _fail("Carrying still rushes across the courtyard"); return
	var rig: Node3D=court.carry_rig
	for body in rig.carriers:
		if party._visual(body).transport_speed>2.7: _fail("Slower arrival retains rushed gait"); return
	_save_coop("performance-slower-four-person-carry")
	await _frames(ceili(court.ARRIVAL_SECONDS*60)-205+12)
	party.switch_to(1,1)
	await _put(50.3,49.7)
	await _dual_hold()
	await _frames(80)
	if not court.tablet_raising or not is_instance_valid(court.raise_rig): _fail("Actual two-player hold skips supported raising"); return
	var hoist: Node3D=court.raise_rig
	if hoist.actors.size()!=4 or hoist.hand_lines.size()!=8: _fail("Final lifting is missing actual haulers and hand lines"); return
	var hand_before: Array[Vector3]=[]
	for role in range(4):
		var body: CharacterBody3D=hoist.actors[role]
		var model: Node3D=party._visual(body).detailed_model
		if body.is_physics_processing() or model.current_state!="push" or model.work_kind!=("stone" if role<2 else "rope"):
			_fail("A real bearer fails to take a lifting / rope working pose"); return
		hand_before.append(model.skeleton.get_bone_global_pose(model.skeleton.find_bone("hand.R")).origin)
	await _frames(13)
	for role in range(4):
		var skeleton: Skeleton3D=party._visual(hoist.actors[role]).detailed_model.skeleton
		if hand_before[role].distance_to(skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).origin)<.004:
			_fail("A hoisting character has no real hand animation"); return
	for line in hoist.hand_lines:
		if not line.visible or line.scale.y<.05: _fail("A working hand has no attached line"); return
	await _detail_view("performance-four-people-raising",Vector3(50,3.3,9),Vector3(50,1.6,-1.4),8.2)
	var pose: Transform3D=court._tablet.transform
	var actor_pose: Vector3=hoist.actors[0].global_position
	await _near_key(KEY_H)
	await _frames(12)
	if not paused or court._tablet.transform!=pose or hoist.actors[0].global_position!=actor_pose: _fail("Hoist / people move under help pause"); return
	await _near_key(KEY_ESCAPE)
	await _frames(ceili(court.RAISE_SECONDS*60)+8)
	if not court.tablet_placed or court.tablet_raising or party.movement_locked(): _fail("Supported lifting does not complete / restore control"); return
	for body in party.all_bodies():
		var visual: Node3D=party._visual(body)
		if not body.is_physics_processing() or visual.transport_pose or not visual.transport_work_kind.is_empty(): _fail("Hoist strands actual bodies after seating"); return
	if get_nodes_in_group("crafted_stele_alcove").size()!=1: _fail("Crafted shrine details are missing"); return
	await _detail_view("performance-crafted-stele-alcove",Vector3(50,3.3,9),Vector3(50,1.9,-2),8.0)
	var sfx: Node=world.sfx
	for sound: AudioStream in sfx.SOUNDS.values():
		if not sound.resource_path.contains("folk_cues_20261020"): _fail("An old buzzing interaction cue remains"); return
	for sound: AudioStream in sfx.HOLDS.values():
		if not sound.resource_path.contains("folk_cues_20261020"): _fail("An old low droning hold remains"); return
	# Exercise a real valid masonry hold and the independent mute / pause controls.
	world.start_creek_preview()
	bridge.step=2
	bridge.material_delivered=true
	bridge.timber_prepared=true
	party.switch_to(1,1)
	await _put(29.6,30.5)
	await _press_key(KEY_P,true)
	await _frames(20)
	if "stone" not in sfx.active_holds or not sfx.hold_players[0].playing: _fail("Real stone work produces no new continuous cue"); return
	sfx.toggle_mute()
	if sfx.hold_players[0].playing: _fail("Mute does not stop new hold audio"); return
	sfx.toggle_mute()
	await _frames(3)
	await _press_key(KEY_P,false)
	await _frames(4)
	if not sfx.active_holds.is_empty(): _fail("Released work retains its hold cue"); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	court._raise_tablet()
	await _frames(70)
	await _tap("restart")
	await _frames(6)
	if court.tablet_raising or party.movement_locked() or absf(player.global_position.x-5)>.03: _fail("R during hoisting overwrites respawn / leaves a locked actor"); return
	for body in party.all_bodies():
		if not body.is_physics_processing() or party._visual(body).transport_pose: _fail("R leaves an animated actor disabled"); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	court._raise_tablet()
	await _frames(70)
	await _tap("restart_lesson")
	await _frames(10)
	if court.tablet_raising or court._tablet.visible: _fail("T retains a ghost stele / lifting rig"); return
	for body in party.all_bodies():
		if not body.is_physics_processing() or party._visual(body).transport_pose: _fail("T leaves an actor in a hoist pose"); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	court.court_lit=true
	await _frames(5)
	var music: Node=world.music
	if music.current_track!=3 or music.scroll_arrangement: _fail("Courtyard finale enters the scroll arrangement too early"); return
	court.show_record(world.completed_actions)
	await _frames(105)
	if not music.scroll_arrangement or music.decks[music.active_deck].stream!=music.SCROLL_TRACK or music.weights[music.active_deck]<.99:
		_fail("Actual scroll opening does not crossfade into the higher / festive score"); return
	_save_coop("performance-scroll-celebration")
	court.close_record()
	await _frames(105)
	if music.scroll_arrangement or music.decks[music.active_deck].stream!=music.TRACKS[3]: _fail("Closing the scroll fails to restore the courtyard arrangement"); return
	court._finish_court()
	await _frames(170)
	if not court.court_lit or not court.landscape.scroll.visible or not music.scroll_arrangement:
		_fail("World scroll reveal fails to retain the celebratory arrangement through its unfurling"); return
	watchdog.timeout.disconnect(_timeout)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("COURT_PERFORMANCE_OK: actual slow 6.4s four-person arrival and matched gait, two-player triggered 4.8s hoist with four real moving actors / eight hand lines / support and pull clips, pause / finish / R / T cleanup, crafted native shrine, all new folk cue / hold streams with real work / mute / release, actual scroll crossfade and return")
	quit(0)


func _timeout() -> void:
	_fail("Court performance check timed out")
