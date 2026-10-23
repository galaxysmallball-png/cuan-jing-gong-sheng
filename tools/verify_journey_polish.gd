extends "res://tools/verify_nearby_interactions.gd"


func _initialize() -> void:
	capture = "--capture-journey" in OS.get_cmdline_user_args()
	create_timer(100, true).timeout.connect(func(): _fail("Journey polish check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Real renderer required"); return
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280, 720)
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
	await _frames(10)
	if ui.goal_panel.visible or ui.restart_button.visible: _fail("Gameplay panels leak onto the cover"); return
	await _start_default_party()
	await _frames(20)
	if not world.room_label.text.begins_with("第一关") or not ui.goal_panel.visible or ui.goal_panel.position.x > 40 or ui.goal_panel.position.y < 500:
		_fail("Goal panel or level number missing"); return
	if not ui.goal_panel.PAPER.resource_path.ends_with("objective_paper.png"): _fail("Goal lacks supplied parchment"); return
	if not Rect2(Vector2.ZERO, ui.goal_panel.size).encloses(ui.goal_panel.get_child(0).get_rect()) or not ui.goal_panel.clip_contents:
		_fail("Goal background overflows the compact panel"); return
	_save_coop("journey-first-goal")
	await _put(12.3, 12.8)
	await _focus_id(0, "stele_0")
	if nearby_ui.cards[0].size.x > 230 or nearby_ui.cards[0].size.y > 48: _fail("Folded bubble is not smaller"); return
	_save_coop("journey-small-bubble")
	await _click_at(ui.hint_button.get_global_rect().get_center())
	var help: Panel = ui.hint_panel.get_child(1)
	if help.get_rect().end.y > 630 or not ui.goal_panel.visible: _fail("Controls exceed the view or hide the separate goal"); return
	for child in help.get_children():
		if child is Label and child.text.contains("此刻所往"): _fail("Controls duplicate the separate objective area"); return
	_save_coop("journey-controls-and-goal")
	await _near_key(KEY_ESCAPE)
	party.switch_to(2, 0)
	party.switch_to(3, 1)
	var ownership = party.owned_roles.duplicate(true)
	first.clues[0] = true
	first.open_inspection(0)
	await _frames(3)
	await _click_at(ui.restart_button.get_global_rect().get_center())
	if first.puzzle_active or first.gate_open or true in first.clues or party.movement_locked() or party.active_id != 2 or party.second_id != 3 or party.owned_roles != ownership:
		_fail("First-level restart loses roles or leaves puzzle/notes"); return
	world.start_creek_preview()
	await _frames(12)
	if world.music.current_track != 1 or not world.room_label.text.begins_with("第二关"): _fail("Creek soundtrack or number wrong"); return
	_save_coop("journey-second-goal")
	bridge.timber_prepared = true
	bridge.material_delivered = true
	bridge.crate.position = Vector3(9.5, .5, -1.9)
	bridge.crate.get_node("Collision").set_deferred("disabled", true)
	bridge.helpers_called = true
	bridge._helpers.visible = true
	bridge.step = 4
	bridge._start_build()
	await _frames(135)
	party.switch_to(1, 1)
	await _put(38.4, 35)
	await _frames(320)
	if not bridge.bridge_ready or bridge.gap_stabilized or bridge._tablet.position.y > 1.2 or bridge._tablet.mesh is BoxMesh:
		_fail("Carried stele remains a floating box"); return
	if bridge._tablet.get_node_or_null("BoundWoodenLitter/Inscription") == null or bridge._tablet.get_node("BoundWoodenLitter").get_child_count() < 30:
		_fail("Litter, binding and inscription missing"); return
	for index in range(2):
		var helper: Node3D = bridge._helpers.get_child(index)
		if absf(helper.global_position.x - bridge._tablet.global_position.x) > 1.6:
			_fail("Villagers do not escort the carried stele"); return
	_save_coop("journey-bridge-litter")
	var camera: Camera3D = world.camera
	if camera.size > 10.2: _fail("Bridge escort lacks a readable camera focus"); return
	var saved_transform: Transform3D = camera.global_transform
	var saved_size: float = camera.size
	camera.size = 6.5
	camera.global_position = Vector3(35.3, 3.8, 14)
	camera.look_at(Vector3(35.3, 1.1, 0), Vector3.UP)
	_save_coop("journey-bridge-detail")
	camera.global_transform = saved_transform
	camera.size = saved_size
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(45)
	if bridge.action_progress <= 0 or bridge.gap_stabilized:
		print("RESCUE_DEBUG ", bridge.steady_held, " ", bridge.rope_held, " count=", party.nearby_count(35), " ids=", party.active_id, "/", party.second_id)
		for actor in party.all_bodies(): print(actor.character_id, " at ", actor.global_position, " ground=", actor.is_on_floor(), " v=", actor.velocity)
		_fail("Rescue no longer needs a joint hold"); return
	_save_coop("journey-bridge-pull")
	Input.action_release("p2_interact")
	await _frames(4)
	if bridge.action_progress != 0: _fail("Release does not interrupt rope rescue"); return
	Input.action_press("p2_interact")
	await _frames(110)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	if not bridge.gap_stabilized: _fail("Refined transport blocks rescue completion"); return
	_save_coop("journey-bridge-safe")
	await _click_at(ui.restart_button.get_global_rect().get_center())
	await _frames(6)
	if not first.gate_open or not first.observed or first.clues.count(true) != 4 or bridge.step != 0 or bridge.bridge_ready or bridge.helpers_called or bridge.material_delivered or player.global_position.x < 20 or second.global_position.x < 20 or party.owned_roles != ownership:
		_fail("Second-level restart clears prior chapter or retains current bridge"); return
	world.start_garden_preview()
	await _frames(15)
	if world.music.current_track != 2 or not world.room_label.text.begins_with("第三关"): _fail("Garden soundtrack or number wrong"); return
	_save_coop("journey-third-goal")
	court.tablet_placed = true
	court.items_done[0] = true
	court.lamp_count = 1
	court.oil_carriers[0] = party.active_id
	await _click_at(ui.restart_button.get_global_rect().get_center())
	await _frames(8)
	if not first.gate_open or not bridge.gap_stabilized or court.tablet_placed or court.lamp_count != 0 or true in court.items_done or court.oil_carriers != [-1, -1, -1] or player.global_position.x < 40 or party.owned_roles != ownership:
		_fail("Third-level restart does not isolate the current courtyard"); return
	for index in range(3):
		world.current_space = index
		var goal: Dictionary = world.objective()
		ui.goal_panel.show_goal(goal.text, goal.progress)
		await _frames(1)
		if ui.goal_panel.body.get_line_count() > ui.goal_panel.body.get_visible_line_count(): _fail("Goal text is clipped"); return
	await _frames(8)
	var music: Node = world.music
	var transitions: int = music.transitions
	await _frames(40)
	if music.transitions != transitions or not music.decks[music.active_deck].playing: _fail("Music restarts every frame or never plays"); return
	await _click_at(ui.music_button.get_global_rect().get_center())
	if not music.muted or music.decks[0].volume_db > -79 or music.decks[1].volume_db > -79: _fail("Music toggle fails to mute both crossfade decks"); return
	await _click_at(ui.music_button.get_global_rect().get_center())
	if music.muted: _fail("Music cannot resume"); return
	for track in music.TRACKS:
		if track.get_length() < 40 or track.loop_mode != AudioStreamWAV.LOOP_FORWARD: _fail("Soundtrack loop missing or too short"); return
	court.court_lit = true
	var records: Array[String] = ["Done"]
	court.show_record(records)
	await _frames(8)
	if music.current_track != 3 or not music.decks[music.active_deck].playing or ui.goal_panel.visible or ui.restart_button.visible:
		_fail("Finale music or clean ending failed"); return
	_save_coop("journey-finale")
	await _near_key(KEY_M)
	if not music.muted: _fail("Ending music cannot be muted without leaving the scroll"); return
	await _near_key(KEY_M)
	if music.muted or not court.record_open: _fail("Ending music toggle interrupts reading"); return
	await _near_key(KEY_ESCAPE)
	print("JOURNEY_POLISH_OK: paper goal bottom-left and compact controls, three level numbers, smaller arrow bubbles, each-level mouse restart preserves previous chapters and assigned roles, puzzle restart, beveled inscribed bound litter, villager escorts, joint rescue/cancellation, four distinct looping scores with playback/scene changes/crossfades/mute/finale, clean ending")
	quit(0)
