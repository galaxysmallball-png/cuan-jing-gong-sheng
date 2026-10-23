extends "res://tools/verify_nearby_interactions.gd"


func _initialize() -> void:
	capture = "--capture-folk" in OS.get_cmdline_user_args()
	create_timer(140, true).timeout.connect(func(): _fail("Folk play check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
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
	await _frames(12)
	ui._open_audio_settings()
	await _frames(2)
	await _drag_slider(.85, .25)
	if world.sfx.volume < .15 or world.sfx.volume > .35 or not ui.effects_level.text.contains("%"):
		_fail("Actual slider dragging does not adjust effects"); return
	await _drag_slider(.25, .85)
	ui._close_audio_settings()
	await _frames(3)
	await _start_default_party()
	await _frames(30)
	world.sfx.last.clear()
	world.sfx.events.clear()
	Input.action_press("jump")
	await _frames(4)
	Input.action_release("jump")
	if not "jump" in world.sfx.events: _fail("Actual grounded jump is silent"); return
	var louder: bool = false
	for sound in world.sfx.players:
		if sound.stream == world.sfx.SOUNDS.jump and sound.volume_db > -16: louder = true
	if not louder: _fail("Jump/effects remain too quiet"); return
	await _frames(45)
	await _put(12.3, 12.9)
	await _click_stone(0)
	Input.action_press("interact")
	await _frames(4)
	var held_stream: AudioStream = world.sfx.hold_players[0].stream
	for block in range(14):
		await _frames(5)
		if not world.sfx.hold_players[0].playing or world.sfx.hold_players[0].stream != held_stream or "paper" not in world.sfx.active_holds:
			_fail("Work sound stops or restarts during the full hold"); return
	if ui.goal_panel.visible or float(world.interaction_progress().get("ratio",0.0)) < .5 or not first.inspector.share_buttons[0].text.contains("%"):
		_fail("First-level clue controls lack live hold percentage or duplicate objective covers the portrait"); return
	_save_coop("folk-first-hold-percent")
	Input.action_release("interact")
	await _frames(4)
	if world.sfx.hold_players[0].playing or ui.goal_panel.action_bar.value != 0: _fail("Release leaves sound or percent running"); return
	await _near_key(KEY_ESCAPE)
	await _put(5.9, 6.6)
	for label in nearby_ui.keys:
		if label.visible or not label.text.is_empty(): _fail("Examination footer still appears"); return
	await _click_prop("bai_tiedye")
	if not world.folk.overlay.visible or not paused or ui.screen != ui.Screen.INSPECT or world.folk.active_id != "bai_tiedye":
		_fail("Direct click on ethnic object does not open floating introduction"); return
	if world.folk.preview_model == null or world.folk._meshes(world.folk.preview_model).size() < 10:
		_fail("Object introduction lacks actual 3D object imagery"); return
	await _click_at(world.folk.start_activity_button.get_global_rect().get_center())
	for i in world.folk.board.recipe: await _board_click(world.folk.board.option_position(i))
	if not world.folk.games_done[0] or true in first.clues: _fail("Stamp play fails or auto-completes the main puzzle"); return
	_save_coop("folk-stamp-popup")
	await _near_key(KEY_ESCAPE)
	world.start_creek_preview()
	await _put(22, 22.7)
	await _click_prop("caravan_pack")
	await _click_at(world.folk.start_activity_button.get_global_rect().get_center())
	await _board_click(Vector2(163, 60))
	await _board_click(Vector2(466, 60))
	if not world.folk.games_done[1] or bridge.step != 0: _fail("Weight puzzle fails or bypasses bridge tasks"); return
	_save_coop("folk-balance-popup")
	await _near_key(KEY_ESCAPE)
	world.start_garden_preview()
	await _put(53, 54)
	await _click_prop("shared_tea")
	await _click_at(world.folk.start_activity_button.get_global_rect().get_center())
	await _frames(190)
	await _board_click(Vector2(270, 112))
	if world.folk.board.answered != 0 or world.folk.games_done[2]: _fail("Wrong music note is accepted"); return
	for note in world.folk.board.recipe: await _board_click(world.folk.board.option_position(note))
	if not world.folk.games_done[2] or court.tablet_placed: _fail("Ensemble play fails or bypasses the seven lamps"); return
	_save_coop("folk-music-popup")
	await _near_key(KEY_ESCAPE)
	party.switch_to(1, 1)
	await _put(court.global_position.x+court.PLACEMENT_X-.3, court.global_position.x+court.PLACEMENT_X+.3)
	await _frames(18)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(45)
	if world.sfx.active_holds != ["stone"] or ui.goal_panel.action_bar.value < .3:
		_fail("Joint raising lacks full work sound or percentage"); return
	_save_coop("folk-joint-progress")
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(4)
	court.tablet_placed = true
	party.switch_to(0, 0)
	await _put(46.2, 49)
	await _frames(18)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(35)
	if world.sfx.active_holds.size() != 2 or ui.goal_panel.action_label.text.count("%") != 2:
		_fail("Parallel object tasks lose distinct ongoing sounds or percentages"); return
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(4)
	court.items_done.fill(true)
	court.lamp_count = 7
	court.court_lit = true
	court._tablet.position = Vector3(court.PLACEMENT_X, 1.50, -2.35)
	court._tablet.rotation.z = 0
	court.landscape.sync_state()
	await _put(50, 52)
	await _frames(20)
	if world.festival.lanterns.size() < 12 or not world.festival.guests[0].visible or not world.festival.guests[1].visible:
		_fail("Final court lacks a rich lantern array or all communities present"); return
	if ui.goal_panel.action_bar.value != 1 or not ui.goal_panel.action_label.text.contains("100%"):
		_fail("A completed scene must show 100 percent"); return
	_save_coop("folk-festival-court")
	var inspected: int = 0
	for id in world.folk.items:
		var entry: Dictionary = world.folk.items[id]
		if not nearby_ui._available(entry) or not world.folk._preview_source(entry).is_visible_in_tree(): continue
		world.folk.open_item(id)
		await _frames(2)
		if not world.folk.overlay.visible or world.folk.description.get_line_count() > world.folk.description.get_visible_line_count() or world.folk._meshes(world.folk.preview_model).is_empty():
			_fail("A cultural object's introduction clips or has no visible model: " + id); return
		inspected += 1
		world.folk.close()
		await _frames(2)
	if inspected < 15: _fail("Too few cultural objects have floating introductions"); return
	var count: int = world.folk.seen.size()
	world.restart_current_scene()
	await _frames(4)
	if world.folk.games_done != [true, true, false] or world.folk.seen.size() >= count or world.sfx.volume < .7:
		_fail("Current-scene restart clears prior crafts or loses volume setting"); return
	print("FOLK_PLAY_OK: physical volume slider and louder grounded jump, continuous full-hold paper/stone audio without restarts, live percentages and cancellation, no examination footer, direct object ray picking and real 3D floating introduction, stamp/weight/ensemble games with wrong-answer handling and no main-task bypass, parallel work sounds, grand lantern court and eight characters, restart isolation")
	quit(0)


func _board_click(at: Vector2) -> void:
	await _click_at(world.folk.board.get_global_rect().position + at)


func _click_prop(id: String) -> void:
	var body: Node3D = world.folk.picker_bodies[id]
	await _click_at(world.camera.unproject_position(body.global_position))
	await _frames(4)


func _drag_slider(from: float, to: float) -> void:
	var rect: Rect2 = ui.effects_slider.get_global_rect()
	var start: Vector2 = rect.position + Vector2(rect.size.x * from, rect.size.y * .5)
	var finish: Vector2 = rect.position + Vector2(rect.size.x * to, rect.size.y * .5)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	world.get_viewport().push_input(press, true)
	await _frames(2)
	var motion := InputEventMouseMotion.new()
	motion.position = finish
	motion.relative = finish - start
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	world.get_viewport().push_input(motion, true)
	await _frames(2)
	press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = finish
	press.pressed = false
	world.get_viewport().push_input(press, true)
	await _frames(3)
