extends SceneTree

var world: Node3D
var player: CharacterBody3D
var party: Node3D
var first: Node3D
var bridge: Node3D
var court: Node3D
var ui: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	world.get_node("Party").local_coop = false
	root.add_child(world)
	world.chapter_films.enabled=false
	current_scene = world
	player = world.get_node("Player")
	party = world.get_node("Party")
	first = world.get_node("Spaces/Space01/Cooperation")
	bridge = world.get_node("Spaces/Space02/BridgeCooperation")
	court = world.get_node("Spaces/Space03/CourtyardCooperation")
	ui = world.get_node("PartyUI")
	await _frames(30)
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	if party.all_bodies().size() != 4 or party.started or absf(player.position.x - player.spawn_position.x) > 0.01:
		_fail("Birth party or title control freeze failed"); return
	await _tap("ui_accept")
	if ui.screen!=ui.Screen.FILM or not ui.opening_film.active:
		_fail("Starting journey does not show the opening story film"); return
	await _tap("skip_intro")
	if ui.screen != ui.Screen.DRAW or not paused or party.started:
		_fail("Start does not open the frozen eight-card draw"); return
	await _tap("skip_intro")
	await _tap("ui_accept")
	if not party.started or ui.screen != ui.Screen.GAME:
		_fail("Confirming the drawn role does not enter the game"); return
	# Gameplay fixtures below use the original identities; the draw has its own
	# full input/animation/assignment verification in verify_opening_draw.gd.
	party.reset_positions(true)
	await _frames(60)
	for id in range(4):
		var target_position: Vector3 = party.role_body(id).global_position
		party.switch_to(id)
		if party.active_id != id or player.global_position.distance_to(target_position) > 0.01:
			_fail("Single-player character switching loses the selected person's position"); return
	for id in range(4):
		await _select(id)
		if party.active_id != id or not _unique_ids():
			_fail("Switching loses or duplicates a character"); return
	await _tap("cycle_character")
	if party.active_id != 0:
		_fail("Tab does not cycle the character"); return
	await _tap("open_archive")
	if not paused or ui.screen != ui.Screen.ARCHIVE:
		_fail("Archive does not pause the game"); return
	var paused_position: Vector3 = player.global_position
	Input.action_press("move_right")
	for frame in range(8): await process_frame
	Input.action_release("move_right")
	if player.global_position.distance_to(paused_position) > 0.01:
		_fail("Archive allows the player to keep moving"); return
	await _tap("open_archive")
	if paused or ui.screen != ui.Screen.GAME:
		_fail("Archive does not resume the game"); return

	if not await _walk(18.3): _fail("Cannot approach the closed door"); return
	Input.action_press("move_right")
	await _frames(120)
	Input.action_release("move_right")
	if player.global_position.x >= 19: _fail("Closed door can be bypassed"); return
	if not await _at(0, 13.5): _fail("Cannot approach the memory board"); return
	await _tap("interact")
	if first.inspected_id != -1 or first.inspector.cover.visible:
		_fail("E or proximity opens an image without clicking a stone"); return
	if first._board.get_viewport() == world.get_viewport():
		_fail("The old floating puzzle board still occupies the game world"); return
	await _click_stone(1)
	if first.inspected_id != 1 or first.puzzle_active or not first.inspector.cover.visible \
		or first.inspector.image.texture != first.inspector.faces[1].material_override.get_shader_parameter("albedo_texture"):
		_fail("The large stone does not enlarge its own inscription image"); return
	await _click_at(first.inspector.close_button.get_global_rect().get_center())
	if first.inspected_id >= 0 or player.interaction_locked:
		_fail("The image close button does not restore walking"); return
	await _click_stone(0)
	if not first.puzzle_active or not player.interaction_locked:
		_fail("Clicking the small stone does not open its picture and puzzle"); return
	if first.inspector.image.texture != first.inspector.faces[0].material_override.get_shader_parameter("albedo_texture"):
		_fail("The small stone and enlarged picture use different images"); return
	if not await preload("res://tools/rubbing_test_driver.gd").complete(self,first.inspector.rubbing):
		_fail("Single-player physical rubbing cannot finish"); return
	Input.action_press("interact")
	await _frames(12)
	Input.action_release("interact")
	await _frames(3)
	if first.action_progress > 0.0: _fail("Interrupted reading is retained"); return
	for id in range(4):
		await _select(id)
		await _hold()
		if first.step != id + 1: _fail("A character cannot contribute a clue"); return
	if first.observed or first.gate_open:
		_fail("Four E holds still bypass the card puzzle"); return
	await _tap("open_archive")
	await _key(KEY_Q)
	if first.selected_tile >= 0: _fail("Paused archive permits card input"); return
	await _tap("open_archive")
	first.inspector.transform = Transform2D.IDENTITY.scaled(Vector2(0.8, 0.8))
	await _click_tile(0)
	await _click_slot(0)
	if first.slots[0] != 0:
		_fail("Scaled image viewer maps clicks to the wrong puzzle position"); return
	first.inspector.transform = Transform2D.IDENTITY
	await _key(KEY_ENTER)
	await _key(KEY_Q)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	if first.slots[1] != 0: _fail("Keyboard selection and placement fail"); return
	await _key(KEY_ENTER)
	await _key(KEY_BACKSPACE)
	if first.selected_tile >= 0 or first.slots[1] != -1:
		_fail("Taking a card back loses or duplicates its placement"); return
	await _key(KEY_ESCAPE)
	if player.interaction_locked: _fail("Leaving the board keeps movement locked"); return
	if not await _walk(13.5): _fail("Cannot move after leaving the board"); return
	await _click_stone(0)
	await _frames(60)
	# A full set of cards in the wrong orientation must leave the gate closed.
	for id in range(6):
		await _click_tile(id)
		await _click_slot(id)
	if first.observed: _fail("Rotated cards satisfy the puzzle"); return
	await _click_tile(0)
	await _click_slot(1)
	if first.slots[1] != 0 or first.slots.find(1) >= 0:
		_fail("Replacing a card duplicates or loses a piece"); return
	# Correctly oriented cards in the wrong order must also leave the gate closed.
	for id in range(6):
		await _click_tile(id)
		for rotation in range(posmod(-first.turns[id], 4)):
			await _key(KEY_Q)
		await _click_slot(5 - id)
	if first.observed: _fail("Reversed order satisfies the puzzle"); return
	# Drag an already placed piece to a different position, then repair the board.
	var drag := InputEventMouseButton.new()
	drag.position = first.inspector.puzzle_screen_position(first._tiles[0].global_position)
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.pressed = true
	world.get_viewport().push_input(drag, true)
	await _frames(2)
	drag = InputEventMouseButton.new()
	drag.position = first.inspector.puzzle_screen_position(first._slot_nodes[0].global_position)
	drag.button_index = MOUSE_BUTTON_LEFT
	drag.pressed = false
	world.get_viewport().push_input(drag, true)
	await _frames(2)
	if first.slots[0] != 0: _fail("Drag release does not place the selected card"); return
	await _finish_observation()
	await _frames(150)
	if not first.observed or not first.gate_open or player.interaction_locked:
		_fail("Solving the cards does not open the door and restore movement"); return
	await _click_stone(0)
	if first.inspected_id != 0 or first.puzzle_active:
		_fail("The completed small stone cannot be reopened as a picture"); return
	await _key(KEY_ESCAPE)
	if not await _collect_journey_stage(0): return
	if not await _at(2, 22.5): _fail("Cannot enter the old-base clue"); return
	await _hold()
	if bridge.step != 1: _fail("Route finding does not unlock materials"); return
	if not await _walk(23.1): _fail("Cannot reach wood"); return
	await _hold()
	if not bridge.timber_prepared: _fail("Route finder cannot prepare the timber"); return
	var wood_x: float = bridge.crate.position.x
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	if absf(bridge.crate.position.x - wood_x) > 0.01:
		_fail("Wood moves without holding E"); return
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(1200):
		await physics_frame
		if bridge.material_delivered: break
	Input.action_release("interact")
	Input.action_release("move_right")
	await _frames(45)
	if not bridge.material_delivered: _fail("Wood cannot be delivered"); return
	if not await _at(0, 27.0): _fail("Cannot read the route clue"); return
	await _hold()
	if bridge.step != 2: _fail("Route reading does not advance"); return
	if not await _at(1, 30.5): _fail("Cannot place Stone at the pier"); return
	await _hold()
	if bridge.step != 3: _fail("Pier preparation does not advance"); return
	if not await _at(3, 22.5): _fail("Cannot return Yang to the village clue"); return
	await _hold()
	if not bridge.helpers_called or bridge.step != 4:
		_fail("Contacting villagers does not deliver support"); return
	if not await _collect_journey_stage(1): return
	if not await _walk(31.3): _fail("Cannot check the gap"); return
	var falls: int = player.fall_recovery_count
	Input.action_press("jump")
	Input.action_press("move_right")
	await _frames(2)
	Input.action_release("jump")
	for frame in range(300):
		await physics_frame
		if player.fall_recovery_count > falls: break
	Input.action_release("move_right")
	await _frames(45)
	if player.fall_recovery_count <= falls or not first.gate_open:
		_fail("Gap recovery fails or destroys the earlier chapter"); return
	if not await _walk(30.5): _fail("Cannot regroup before building"); return
	await _frames(180)
	if party.nearby_count(30.5) != 4:
		_fail("Three followers cannot regroup at the bridge"); return
	await _hold()
	await _frames(200)
	if not bridge.bridge_ready or bridge.step != 5:
		_fail("All-four construction does not provide a bridge"); return
	if not await _at(1, 50.0): _fail("Party cannot cross the physical bridge"); return
	await _hold()
	if court.tablet_placed: _fail("Courtyard bypasses the bridge safety task"); return
	if not await _walk(35.0): _fail("Cannot return to steady the tablet"); return
	await _frames(150)
	await _hold()
	if not bridge.gap_stabilized: _fail("Group cannot steady the tablet"); return
	if not await _at(1, 50.0): _fail("Cannot install the tablet"); return
	await _hold()
	if court.get("tablet_raising")==true: await _frames(ceili(court.RAISE_SECONDS*60)+5)
	if not court.tablet_placed: _fail("Stone cannot install the tablet"); return
	if not await _at(2, 46.2): _fail("Cannot check first-lamp role"); return
	await _hold()
	if court.lamp_count != 0: _fail("Wrong occupation lights the first lamp"); return
	for index in range(7):
		if not await _complete_courtyard_item(index): _fail("Cannot place the courtyard item"); return
		if court.lamp_count != index + 1:
			_fail("Seven item placements do not advance in order"); return
	await _frames(180)
	if not court.court_lit or not await _walk(58.0):
		_fail("Seven lights do not reach the ending"); return
	await _frames(60)
	if not world.ending_reached or world.completed_actions.size() != 3 or party.nearby_count(58.0) != 4:
		_fail("Ending does not retain the whole party and three records"); return
	if absf(court.warm_light.light_energy - 2.8) > 0.01:
		_fail("User's 2.8 courtyard brightness was lost"); return
	await _tap("restart_lesson")
	await _frames(180)
	if first.step != 0 or bridge.step != 0 or court.lamp_count != 0 or world.ending_reached or not _unique_ids() \
		or first.puzzle_active or player.interaction_locked or first.slots != [-1, -1, -1, -1, -1, -1]:
		_fail("Reset leaves old tasks, light, or duplicated actors"); return
	if not await _walk(13.5): _fail("Cannot revisit the reset puzzle"); return
	await _click_stone(0)
	if not await preload("res://tools/rubbing_test_driver.gd").complete(self,first.inspector.rubbing):
		_fail("Reset journey cannot repeat its rubbing"); return
	await _key(KEY_ENTER)
	await _key(KEY_Q)
	await _tap("restart")
	if first.puzzle_active or player.interaction_locked or first.turns[0] != 1:
		_fail("R does not leave the board while retaining card progress"); return
	if not await _walk(13.5): _fail("Cannot return after R"); return
	await _click_stone(0)
	await _tap("restart_lesson")
	if first.puzzle_active or player.interaction_locked or first.turns != first.INITIAL_TURNS:
		_fail("T during interaction leaves a lock or rotated card"); return
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	world = load("res://scenes/world.tscn").instantiate()
	world.get_node("Party").local_coop = false
	root.add_child(world)
	current_scene = world
	ui = world.get_node("PartyUI")
	party = world.get_node("Party")
	await _start_default_party()
	if not party.started or ui.screen != ui.Screen.GAME:
		_fail("Skipping the introduction does not begin the game"); return
	print("PARTY_GAME_OK: two clickable inscribed models, matching enlarged images, close button and Esc, separate puzzle viewport, card input and correction, clues, archive, following, bridge, seven lamps, reset")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	quit(0)


func _stop_test_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		node.stop()
	for child in node.get_children(): _stop_test_audio(child)


func _drain_test_audio() -> void:
	# The fast Dummy-driver test can finish before the audio mixing thread drains.
	var until_ms: int = Time.get_ticks_msec()+100
	while Time.get_ticks_msec()<until_ms: await process_frame


func _unique_ids() -> bool:
	var ids: Array[int] = [party.active_id]
	for actor in party.followers: ids.append(actor.character_id)
	ids.sort()
	return ids == [0, 1, 2, 3]


func _key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		world.get_viewport().push_input(event, true)
		await _frames(2)


func _click_at(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		world.get_viewport().push_input(event, true)
		await _frames(2)


func _click_tile(id: int) -> void:
	await _click_at(first.inspector.puzzle_screen_position(first._tiles[id].global_position))


func _click_slot(index: int) -> void:
	await _click_at(first.inspector.puzzle_screen_position(first._slot_nodes[index].global_position))


func _click_stone(id: int) -> void:
	await _click_at(first.inspector.stone_screen_position(id))


func _finish_observation() -> void:
	if not first.comparison_complete:
		first.close_puzzle()
		await _frames(2)
		await _click_stone(1)
		await _frames(2)
		await _click_at(first.inspector.lore.start.get_global_rect().get_center())
		for answer in [1,0,2]:
			await _click_at(first.inspector.lore.choices[answer].get_global_rect().get_center())
		first.close_puzzle()
		await _frames(2)
		await _click_stone(0)
	for id in range(6):
		await _click_tile(id)
		for rotation in range(posmod(-first.turns[id], 4)):
			await _key(KEY_Q)
		await _click_slot(id)


func _frames(count: int) -> void:
	for frame in range(count): await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await process_frame
	await process_frame
	await process_frame
	Input.action_release(action)
	await process_frame
	await process_frame


func _start_default_party() -> void:
	world.chapter_films.enabled=false
	await _tap("ui_accept")
	if ui.screen==ui.Screen.FILM: await _tap("skip_intro")
	await _tap("skip_intro")
	await _tap("ui_accept")
	party.reset_positions(true)
	await _frames(3)


func _select(id: int) -> void:
	await _tap("select_%d" % (id + 1))
	await _frames(3)


func _at(id: int, x: float) -> bool:
	await _select(id)
	return await _walk(x)


func _hold() -> void:
	Input.action_press("interact")
	await _frames(150 if bridge.step==5 else 105)
	Input.action_release("interact")
	await _frames(4)
	await _complete_shared_design()


func _collect_journey_stage(chapter: int) -> bool:
	var previous_role: int=party.active_id
	for index in range(4):
		if world.keepsakes.CHAPTERS[index]!=chapter: continue
		await _select(index)
		if not await _walk(world.keepsakes.POSITIONS[index].x): _fail("Cannot walk to dropped keepsake"); return false
		await _tap("interact")
		if not world.keepsakes.collected[index]: _fail("Actual pickup key did not store the keepsake"); return false
	await _select(previous_role)
	return true


func _complete_shared_design() -> void:
	if world.get("experience")==null or not world.experience.overlay.visible: return
	for slot in range(2):
		await _click_at(world.experience.choice_buttons[slot][2-slot*2].get_global_rect().get_center())
		await _click_at(world.experience.confirm_buttons[slot].get_global_rect().get_center())
	await _frames(4)


func _support_and_pulse() -> void:
	var supporter: CharacterBody3D = party.role_body(1)
	var rope_actor: CharacterBody3D = party.role_body(2)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	for frame in range(480):
		if bridge.gap_stabilized: break
		Input.action_press(supporter.action("interact"))
		if bridge.rope_tension<.48: Input.action_press(rope_actor.action("interact"))
		elif bridge.rope_tension>.60: Input.action_release(rope_actor.action("interact"))
		await _frames(1)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(4)


func _complete_courtyard_item(index: int) -> bool:
	var role: int = court.LAMP_ROLES[index] if index < 4 else 3
	if index >= 4:
		if not await _at(role, 40 + court.SUPPLY_X): return false
		await _hold()
	if not await _at(role, 40 + court.ITEM_POSITIONS[index]): return false
	await _hold()
	return court.items_done[index]


func _walk(x: float) -> bool:
	var action: String = "move_right" if x > player.global_position.x else "move_left"
	Input.action_press(action)
	for frame in range(3000):
		await physics_frame
		if court.tablet_arriving:
			Input.action_release(action)
			continue
		var next_action: String="move_right" if x>player.global_position.x else "move_left"
		if next_action!=action:
			Input.action_release(action)
			action=next_action
		Input.action_press(action)
		# A human steers around the visible pier instead of walking sideways
		# through its new solid masonry. Exercise the real depth key as well.
		var passes_pier: bool=minf(x,player.global_position.x)<31.9 and maxf(x,player.global_position.x)>29.1
		if passes_pier and player.global_position.z<.18: Input.action_press("move_back")
		else: Input.action_release("move_back")
		if player.global_position.y < 0.4:
			Input.action_release(action)
			Input.action_release("move_back")
			return false
		if absf(player.global_position.x - x) < 0.09:
			Input.action_release(action)
			Input.action_release("move_back")
			await _frames(4)
			return true
	Input.action_release(action)
	Input.action_release("move_back")
	print("WALK_FAILED: ", player.global_position, " target ", x, " chapter ", bridge.step)
	return false


func _fail(message: String) -> void:
	for action in ["move_right", "move_left", "jump", "interact"]: Input.action_release(action)
	paused = false
	push_error(message)
	quit(1)
