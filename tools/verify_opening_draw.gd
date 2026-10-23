extends "res://tools/verify_local_coop.gd"

const Draw = preload("res://scripts/opening_card_draw.gd")


func _initialize() -> void:
	create_timer(45, true).timeout.connect(func(): _fail("Opening draw test timed out"))
	call_deferred("_run")


func _run() -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = 2601017
	var observed: Dictionary = {}
	for repeat in range(1200):
		var picked: Array[int] = Draw.choose_roles(2, generator)
		if picked.size() != 2 or picked[0] == picked[1] or picked.any(func(id: int): return id < 0 or id >= 4):
			_fail("The eight-card presentation can select a villager or repeat a role"); return
		observed[str(picked)] = true
	if observed.size() != 12: _fail("Not all distinct protagonist pairs can be drawn"); return
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Draw previews require a real renderer"); return
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280, 720)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
	await _create_world(true)
	var drawing: Control = ui.opening_draw
	if drawing.cards.size() != 8 or drawing.visible or drawing.viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_fail("Eight distinct cards are missing, or the hidden carousel keeps rendering"); return
	for index in range(8):
		var quad: QuadMesh = drawing.fronts[index].mesh
		var texture: Texture2D = drawing.CARD_TEXTURES[index]
		if drawing.cards[index].name != drawing.CARD_KEYS[index] or not is_equal_approx(quad.size.x / quad.size.y, texture.get_width() / float(texture.get_height())):
			_fail("Original card identity/aspect ratio was altered"); return
	var invalid: Array[int] = [4, 0]
	var duplicate: Array[int] = [0, 0]
	var empty: Array[int] = []
	if drawing.begin(invalid) or drawing.begin(duplicate) or drawing.begin(empty) or party.assign_opening_roles(invalid) or party.assign_opening_roles(duplicate):
		_fail("Invalid role results can enter the draw or the party"); return
	if not _unique_ids() or party.active_id != 0 or party.second_id != 1:
		_fail("Rejected assignments partially change the party"); return
	await _key(KEY_ENTER)
	if ui.screen != ui.Screen.DRAW or not paused or party.started or player.controls_enabled or second.controls_enabled:
		_fail("Starting the draw does not freeze the unstarted game"); return
	var role_pair: Array[int] = drawing.result_roles.duplicate()
	var first_position: Vector3 = player.global_position
	var second_position: Vector3 = second.global_position
	var angle: float = drawing.orbit_angle
	await _frames(24)
	_save_coop("opening-draw-spin")
	for index in range(8):
		if absf(Vector2(drawing.cards[index].position.x, drawing.cards[index].position.z).length() - drawing.RADIUS) > 0.001:
			_fail("Cards do not orbit the common vertical axis"); return
	if drawing.orbit_angle <= angle or drawing.continue_button.visible:
		_fail("Cards do not spin or entry is enabled before selection"); return
	for key in [KEY_D, KEY_RIGHT, KEY_B, KEY_F2, KEY_T, KEY_R, KEY_4]: await _press_key(key, true)
	await _frames(15)
	for key in [KEY_D, KEY_RIGHT, KEY_B, KEY_F2, KEY_T, KEY_R, KEY_4]: await _press_key(key, false)
	if ui.screen != ui.Screen.DRAW or not paused or player.global_position != first_position or second.global_position != second_position or party.active_id != 0 or party.second_id != 1 or ui.satchel.visible:
		_fail("Draw input leaks to movement, role change, reset, satchel or archive"); return
	for frame in range(380):
		await physics_frame
		if drawing.phase == drawing.Phase.SECOND_SPIN: break
	if drawing.phase != drawing.Phase.SECOND_SPIN or drawing._selected != [role_pair[0]]:
		_fail("The first selected card does not leave the carousel before 2P draws"); return
	_save_coop("opening-draw-first-pick")
	for frame in range(300):
		await physics_frame
		if drawing.is_ready(): break
	if not drawing.is_ready() or drawing.result_roles != role_pair or not drawing.continue_button.visible:
		_fail("Natural slowdown does not reach the preselected role results"); return
	if drawing.cards.filter(func(card: Node3D): return card.visible).size() != 2:
		_fail("The result view shows unselected or villager cards"); return
	for slot in range(2):
		if not drawing.slot_names[slot].text.contains(party.NAMES[role_pair[slot]]):
			_fail("The draw result lacks the correct ethnicity label"); return
	_save_coop("opening-draw-result")
	await _key(KEY_ESCAPE)
	if ui.screen != ui.Screen.DRAW or party.started: _fail("Esc confirms the result without entry consent"); return
	await _click_at(drawing.replay_button.get_global_rect().get_center())
	if drawing.phase != drawing.Phase.FIRST_SPIN or drawing.result_roles != role_pair: _fail("Replay rerolls the selected characters"); return
	await _press_key(KEY_ENTER, true)
	await _frames(12)
	await _press_key(KEY_ENTER, false)
	if not drawing.is_ready() or ui.screen != ui.Screen.DRAW or party.started:
		_fail("Holding Enter skips both the animation and the result confirmation"); return
	await _click_at(drawing.cancel_button.get_global_rect().get_center())
	await _frames(20)
	if ui.screen != ui.Screen.TITLE or paused or drawing.visible or party.started or drawing.viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_fail("Returning to title leaves a paused/running draw or starts the game later"); return
	await _click_at(ui.primary.get_global_rect().get_center())
	await _key(KEY_ESCAPE)
	role_pair = drawing.result_roles.duplicate()
	if ui.screen != ui.Screen.DRAW or not drawing.is_ready(): _fail("Mouse start and Esc animation skip fail"); return
	await _key(KEY_ENTER)
	await _frames(20)
	if not party.started or paused or ui.screen != ui.Screen.GAME or drawing.visible or drawing.viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_fail("Confirming the results does not restore gameplay and stop the carousel renderer"); return
	if party.active_id != role_pair[0] or party.second_id != role_pair[1] or not _unique_ids() or not player.controls_enabled or not second.controls_enabled:
		_fail("Drawn identities are not atomically assigned to two players plus two followers"); return
	if party.switch_to(role_pair[1], 0) or party.switch_to(4, 0): _fail("A controller can steal a role or choose a villager after drawing"); return
	_save_coop("opening-draw-in-game")
	await _press_key(KEY_D, true)
	await _press_key(KEY_RIGHT, true)
	await _frames(30)
	await _press_key(KEY_D, false)
	await _press_key(KEY_RIGHT, false)
	if player.global_position.x <= first_position.x + 0.5 or second.global_position.x <= second_position.x + 0.5:
		_fail("Drawn roles cannot move independently after entry"); return
	await _tap("restart")
	await _frames(15)
	if party.active_id != role_pair[0] or party.second_id != role_pair[1]: _fail("R discards the drawn identities"); return
	await _key(KEY_B)
	if ui.screen != ui.Screen.SATCHEL or not paused: _fail("Drawn party cannot use the satchel"); return
	await _key(KEY_ESCAPE)
	await _tap("restart_lesson")
	await _frames(20)
	if paused or ui.screen != ui.Screen.GAME or party.active_id != 0 or party.second_id != 1 or not _unique_ids() or drawing.visible:
		_fail("T changes the original restart behavior or reopens the draw"); return
	world.queue_free()
	await process_frame
	await process_frame
	await _create_world(false)
	drawing = ui.opening_draw
	await _click_at(ui.secondary.get_global_rect().get_center())
	if ui.screen != ui.Screen.INTRO or ui.intro_index != 0: _fail("Optional character biographies are unavailable"); return
	for index in range(8):
		if ui.intro_index != index: _fail("Optional introductions lost a character or villager"); return
		await _tap("ui_accept")
	if ui.screen != ui.Screen.DRAW or drawing.result_roles.size() != 1: _fail("Single-player biographies do not lead to a one-card draw"); return
	await _key(KEY_ESCAPE)
	if not drawing.is_ready() or drawing.slot_names[1].visible: _fail("Single-player results show an extra player"); return
	_save_coop("opening-draw-single-result")
	var single: int = drawing.result_roles[0]
	await _click_at(drawing.continue_button.get_global_rect().get_center())
	await _frames(15)
	var all_ids: Array[int] = []
	for body in party.all_bodies(): all_ids.append(body.character_id)
	all_ids.sort()
	if party.active_id != single or party.followers.size() != 3 or all_ids != [0, 1, 2, 3] or paused or not party.started:
		_fail("Single-player draw loses a follower or assigns a villager"); return
	print("OPENING_DRAW_OK: eight original full-ratio cards, vertical orbit/slowdown/two sequential reveals, protagonist-only pairs (all 12), no duplicate/invalid atomic assignment, paused input isolation, natural finish/skip/held Enter/replay/cancel, actual assigned 1P/2P/followers, movement/R/T/satchel, optional biographies and single-player fallback")
	quit(0)


func _create_world(coop: bool) -> void:
	world = load("res://scenes/world.tscn").instantiate()
	world.get_node("Party").local_coop = coop
	if capture: capture_viewport.add_child(world)
	else:
		root.add_child(world)
		current_scene = world
	player = world.get_node("Player")
	party = world.get_node("Party")
	second = party.second_player
	ui = world.get_node("PartyUI")
	first = world.get_node("Spaces/Space01/Cooperation")
	bridge = world.get_node("Spaces/Space02/BridgeCooperation")
	court = world.get_node("Spaces/Space03/CourtyardCooperation")
	await _frames(30)
