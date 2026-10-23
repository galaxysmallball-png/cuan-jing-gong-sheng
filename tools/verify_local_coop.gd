extends "res://tools/verify_party_game.gd"

var second: CharacterBody3D
var capture_viewport: SubViewport
var capture: bool = false


func _run() -> void:
	capture = capture or "--capture-coop" in OS.get_cmdline_user_args()
	if capture:
		if DisplayServer.get_name() == "headless":
			_fail("Co-op preview requires a real renderer"); return
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280, 720)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world = load("res://scenes/world.tscn").instantiate()
	if capture:
		capture_viewport.add_child(world)
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
	if not party.local_coop or party.human_players().size() != 2 or party.followers.size() != 2 or not _unique_ids():
		_fail("Default game is not two human controllers plus two followers"); return
	# Exercise the physical key mapping, rather than only named actions.
	for binding in [[KEY_A, "move_left"], [KEY_D, "move_right"], [KEY_W, "move_forward"], [KEY_S, "move_back"], [KEY_SPACE, "jump"], [KEY_E, "interact"],
		[KEY_LEFT, "p2_move_left"], [KEY_RIGHT, "p2_move_right"], [KEY_UP, "p2_move_forward"], [KEY_DOWN, "p2_move_back"], [KEY_KP_ENTER, "p2_jump"], [KEY_P, "p2_interact"]]:
		var event := InputEventKey.new()
		event.physical_keycode = binding[0]
		if binding[0] == KEY_CTRL: event.location = KEY_LOCATION_RIGHT
		if not InputMap.event_is_action(event, binding[1]):
			_fail("Missing keyboard binding: " + str(binding)); return
		if binding[0] in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN] and InputMap.event_is_action(event, "move_left"):
			_fail("The arrow keys still drive 1P"); return
	_save_coop("title")
	await _press_key(KEY_D, true)
	await _press_key(KEY_RIGHT, true)
	await _frames(45)
	await _press_key(KEY_D, false)
	await _press_key(KEY_RIGHT, false)
	if absf(player.position.x - 5.0) > 0.01 or absf(second.position.x - 4.05) > 0.01:
		_fail("Title screen does not freeze both controllers"); return
	await _start_default_party()
	await _frames(60)
	if party.followers[0].global_position.distance_to(second.global_position) < 0.6:
		_fail("A follower stands inside the second player at the starting point"); return
	_save_coop("birth")
	var first_x: float = player.global_position.x
	var second_x: float = second.global_position.x
	await _press_key(KEY_D, true)
	await _press_key(KEY_LEFT, true)
	await _frames(35)
	await _press_key(KEY_D, false)
	await _press_key(KEY_LEFT, false)
	if player.global_position.x < first_x + 1.5 or second.global_position.x > second_x - 1.5:
		_fail("WASD and arrow keys cannot move two players in opposite directions"); return
	first_x = player.global_position.x
	await _press_key(KEY_RIGHT, true)
	await _frames(25)
	await _press_key(KEY_RIGHT, false)
	if absf(player.global_position.x - first_x) > 0.01:
		_fail("2P input also moves 1P"); return
	await _press_key(KEY_SPACE, true)
	await _press_key(KEY_KP_ENTER, true)
	await _frames(8)
	await _press_key(KEY_SPACE, false)
	await _press_key(KEY_KP_ENTER, false)
	if player.global_position.y < 1.2 or second.global_position.y < 1.2:
		_fail("Two simultaneous jumps are not independent"); return
	await _frames(55)
	if party.switch_to(party.second_id, 0) or party.switch_to(party.active_id, 1):
		_fail("One controller can steal the other player's identity"); return
	var target: Vector3 = party.role_body(3).global_position
	await _tap("p2_cycle_character")
	if party.second_id != 3 or second.global_position.distance_to(target) > 0.01 or not _unique_ids():
		_fail("2P switching does not preserve its owned companion and four distinct positions"); return
	await _tap("cycle_character")
	if party.active_id != 2:
		_fail("1P cycling leaves its two owned roles"); return
	var previous: int = party.second_id
	await _press_key(KEY_SHIFT, true, KEY_LOCATION_LEFT)
	await _press_key(KEY_SHIFT, false, KEY_LOCATION_LEFT)
	if party.second_id != previous:
		_fail("Left Shift unexpectedly changes 2P's role"); return
	await _press_key(KEY_SHIFT, true, KEY_LOCATION_RIGHT)
	await _press_key(KEY_SHIFT, false, KEY_LOCATION_RIGHT)
	if party.second_id == previous or not _unique_ids():
		_fail("Right Shift does not cycle 2P's character"); return
	await _tap("restart_lesson")
	await _frames(50)
	await _press_key(KEY_D, true)
	await _press_key(KEY_A, false)
	await _press_key(KEY_LEFT, true)
	await _frames(400)
	await _press_key(KEY_D, false)
	await _press_key(KEY_LEFT, false)
	await _frames(90)
	if absf(player.global_position.x - second.global_position.x) > party.MAX_PLAYER_DISTANCE + 0.02:
		_fail("Players can leave each other's shared camera"); return
	var camera: Camera3D = world.get_node("SideCamera")
	for body in [player, second]:
		var screen_position: Vector2 = camera.unproject_position(body.global_position)
		if not Rect2(Vector2(5, 5), Vector2(1270, 710)).has_point(screen_position):
			_fail("Shared camera loses one of the two players"); return
	_save_coop("separated")
	await _tap("restart_lesson")
	await _frames(50)
	if not await _duo_walk(13.5, 13.0): _fail("Both players cannot approach the two steles"); return
	await _frames(45)
	_save_coop("courtyard-steles")
	await _click_stone(1)
	await _press_key(KEY_D, true)
	await _press_key(KEY_RIGHT, true)
	first_x = player.global_position.x
	second_x = second.global_position.x
	await _frames(25)
	await _press_key(KEY_D, false)
	await _press_key(KEY_RIGHT, false)
	if absf(player.global_position.x - first_x) > 0.01 or absf(second.global_position.x - second_x) > 0.01:
		_fail("Image inspection does not freeze both players"); return
	await _key(KEY_ESCAPE)
	await _click_stone(0)
	if not await _complete_rubbing(): return
	await _press_key(KEY_E, true)
	await _press_key(KEY_P, true)
	await _frames(110)
	await _press_key(KEY_E, false)
	await _press_key(KEY_P, false)
	if first.step != 2 or not first.clues[0] or not first.clues[1] or first.selected_tile != -1 or first.cursor_slot != 0:
		_fail("Simultaneous clues fail or 2P's down key also manipulates the board"); return
	party.switch_to(2, 0)
	party.switch_to(3, 1)
	await _dual_hold()
	if first.step != 4 or first.gate_open:
		_fail("Remaining roles cannot share clues or clues alone bypass the puzzle"); return
	_save_coop("puzzle")
	await _key(KEY_L)
	await _key(KEY_K)
	if first.cursor_tile != 1 or first.cursor_slot != 1:
		_fail("IJKL board controls do not work"); return
	await _key(KEY_BACKSPACE)
	await _finish_observation()
	await _frames(150)
	if not first.gate_open or player.interaction_locked or second.interaction_locked:
		_fail("Solving the board does not restore both controllers and open the gate"); return
	await _tap("open_archive")
	first_x = player.global_position.x
	second_x = second.global_position.x
	Input.action_press("move_right")
	Input.action_press("p2_move_right")
	for frame in range(10): await process_frame
	Input.action_release("move_right")
	Input.action_release("p2_move_right")
	if not paused or absf(player.global_position.x - first_x) > 0.01 or absf(second.global_position.x - second_x) > 0.01:
		_fail("Archive does not pause both players"); return
	await _tap("open_archive")
	# 1P is the route finder; 2P pushes the materials and later does the stonework.
	if not await _collect_duo_stage(0): return
	if not await _duo_walk(22.5, 23.0): _fail("Cannot enter the second space together"); return
	_save_coop("creek-entry")
	await _hold()
	if bridge.step != 1: _fail("1P cannot find the bridge-base clue"); return
	if not await _duo_walk(23.1, 23.0): _fail("Cannot approach the flood-felled fir"); return
	await _dual_hold(false, true)
	if bridge.timber_prepared: _fail("A role without route-finding skills can prepare the fir"); return
	await _hold()
	if not bridge.timber_prepared: _fail("The route finder cannot prepare and bind the timber"); return
	Input.action_press("p2_interact")
	Input.action_press("p2_move_right")
	for frame in range(1200):
		await physics_frame
		if bridge.material_delivered: break
	Input.action_release("p2_interact")
	Input.action_release("p2_move_right")
	await _frames(50)
	if not bridge.material_delivered: _fail("2P cannot push and deliver the wood with ↓ + →"); return
	party.switch_to(0, 0)
	party.switch_to(1, 1)
	if not await _duo_walk(27.0, 30.5): _fail("Cannot divide the route and pier tasks"); return
	await _hold()
	if bridge.step != 2: _fail("1P cannot read the route"); return
	await _dual_hold(false, true)
	if bridge.step != 3: _fail("2P cannot complete the stoneworker task"); return
	party.switch_to(3, 1)
	if not await _duo_walk(30.5, 22.5): _fail("Yang's owner cannot return to call villagers while the other waits"); return
	await _dual_hold(false, true)
	if bridge.step != 4: _fail("Yang's owner cannot call support"); return
	await _dual_hold(true, false)
	if bridge.building or bridge.bridge_ready:
		_fail("A single player can build while the other is absent"); return
	party.switch_to(1, 1)
	if not await _collect_duo_stage(1): return
	if not await _duo_walk(30.5, 31.3): _fail("Cannot test the broken bridge"); return
	var falls: int = second.fall_recovery_count
	Input.action_press("p2_jump")
	Input.action_press("p2_move_right")
	await _frames(3)
	Input.action_release("p2_jump")
	for frame in range(300):
		await physics_frame
		if second.fall_recovery_count > falls: break
	Input.action_release("p2_move_right")
	await _frames(50)
	if second.fall_recovery_count <= falls or not first.gate_open:
		_fail("2P falling does not recover safely with progress intact"); return
	if not await _duo_walk(30.5, 30.3): _fail("Cannot regroup all four characters"); return
	await _frames(180)
	_save_coop("creek-build")
	await _dual_hold()
	await _frames(200)
	if not bridge.bridge_ready: _fail("Two players and their followers cannot build the bridge"); return
	party.switch_to(2, 0)
	if not await _duo_walk(38.4, 35.0): _fail("Cannot split the right-bank rope and bridge-centre support roles"); return
	await _frames(120)
	_save_coop("bridge")
	await _dual_hold(false, true)
	if bridge.gap_stabilized or bridge.action_progress > 0:
		_fail("Supporting the tablet alone bypasses the other player's rope task"); return
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(45)
	_save_coop("creek-rescue")
	if bridge.action_progress <= 0 or bridge.gap_stabilized:
		_fail("Two distinct rescue roles cannot contribute together"); return
	Input.action_release("p2_interact")
	var before_release: float = bridge.action_progress
	await _frames(3)
	if bridge.action_progress >= before_release:
		_fail("Releasing the stone support does not reduce rescue progress"); return
	Input.action_release("interact")
	await _dual_hold()
	if not bridge.gap_stabilized: _fail("The two players cannot jointly rescue the slipping tablet"); return
	_save_coop("creek-safe")
	if not await _duo_walk(50.3, 49.7): _fail("Both players cannot reach the courtyard"); return
	await _dual_hold(false, true)
	if court.tablet_placed: _fail("One person can install the tablet alone"); return
	await _dual_hold()
	if court.get("tablet_raising")==true: await _frames(ceili(court.RAISE_SECONDS*60)+5)
	if not court.tablet_placed: _fail("Both players cannot install the tablet"); return
	for index in range(7):
		var role: int = court.LAMP_ROLES[index] if index < 4 else party.active_id
		var slot: int = party.owner_of(role)
		if not party.switch_to(role, slot): _fail("Cannot select a lamp's role"); return
		if index >= 4:
			if not await _duo_walk(43.5, 43.9): _fail("Cannot collect the village oil lamps"); return
			await _dual_hold(slot == 0, slot == 1)
		var x: float = 40 + court.ITEM_POSITIONS[index]
		if not await _duo_walk(x, x + 0.3): _fail("Cannot reach the next lamp together"); return
		await _dual_hold(slot == 0, slot == 1)
		if court.lamp_count != index + 1: _fail("One of the dual-controller lamp tasks failed"); return
	await _frames(180)
	if not await _duo_walk(58.0, 56.9): _fail("Cannot approach the ending"); return
	await _frames(60)
	if world.ending_reached: _fail("Ending fires before both players arrive"); return
	if not await _duo_walk(58.0, 58.8): _fail("2P cannot join the ending"); return
	await _frames(120)
	if not world.ending_reached or party.nearby_count(58.0) != 4 or absf(court.warm_light.light_energy - 2.8) > 0.01:
		_fail("Ending does not include the whole party or preserve the warm light"); return
	_save_coop("ending")
	await _tap("restart")
	await _frames(60)
	if not first.gate_open or not court.court_lit or not _unique_ids() or absf(second.global_position.x - 4.05) > 0.01:
		_fail("R fails to reset both players while preserving progress"); return
	await _click_stone(0)
	await _tap("restart_lesson")
	await _frames(60)
	if first.step != 0 or bridge.step != 0 or bridge.timber_prepared or bridge.steady_held or bridge.rope_held or court.lamp_count != 0 or world.ending_reached \
		or player.interaction_locked or second.interaction_locked or party.active_id != 0 or party.second_id != 1 or not _unique_ids():
		_fail("T fails to clear both players, all tasks and interaction locks"); return
	print("LOCAL_COOP_OK: physical WASD/arrows, independent roles, two followers, camera, clues, fir preparation, 2P material delivery and fall recovery, bridge construction, simultaneous stoneworker support and route-finder rope rescue, seven lamps, ending, pause and reset")
	if capture: print("LOCAL_COOP_RENDER_OK: title, birth, separated players, puzzle, bridge and ending")
	quit(0)


func _unique_ids() -> bool:
	var ids: Array[int] = []
	for body in party.all_bodies(): ids.append(body.character_id)
	ids.sort()
	return ids == [0, 1, 2, 3]


func _press_key(code: int, pressed: bool, location: int = KEY_LOCATION_UNSPECIFIED) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.location = location
	event.pressed = pressed
	Input.parse_input_event(event)
	await _frames(2)


func _dual_hold(first_player: bool = true, second_player: bool = true) -> void:
	if first_player and second_player and bridge.step==5 and not bridge.gap_stabilized:
		await _support_and_pulse()
		return
	if first_player: Input.action_press("interact")
	if second_player: Input.action_press("p2_interact")
	await _frames(105)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(4)
	await _complete_shared_design()


func _duo_walk(first_target: float, second_target: float) -> bool:
	for frame in range(2400):
		var done: bool = true
		for pair in [[player, first_target], [second, second_target]]:
			var body: CharacterBody3D = pair[0]
			var distance: float = pair[1] - body.global_position.x
			Input.action_release(body.action("move_left"))
			Input.action_release(body.action("move_right"))
			Input.action_release(body.action("move_forward"))
			Input.action_release(body.action("move_back"))
			if absf(body.global_position.z) > .10:
				done = false
				Input.action_press(body.action("move_forward" if body.global_position.z > 0 else "move_back"))
			elif absf(distance) > 0.09:
				done = false
				Input.action_press(body.action("move_right" if distance > 0 else "move_left"))
		if done:
			await _frames(5)
			return true
		await physics_frame
	for body in [player, second]:
		Input.action_release(body.action("move_left"))
		Input.action_release(body.action("move_right"))
		Input.action_release(body.action("move_forward"))
		Input.action_release(body.action("move_back"))
	print("DUO_WALK_FAILED: ", player.global_position, " / ", second.global_position, " -> ", first_target, " / ", second_target)
	return false


func _collect_duo_stage(chapter: int) -> bool:
	var roles_before: Array[int]=[party.active_id,party.second_id]
	for index in range(4):
		if world.keepsakes.CHAPTERS[index]!=chapter: continue
		var x: float=world.keepsakes.POSITIONS[index].x
		var owner: int=party.owner_of(index)
		party.switch_to(index,owner)
		if not await _duo_walk(x,x-.65): _fail("Both players cannot walk to the keepsake"); return false
		await _frames(4)
		await _tap("interact" if owner==0 else "p2_interact")
		if not world.keepsakes.collected[index]: _fail("Co-op keepsake pickup did not register"); return false
	for slot in range(2): party.switch_to(roles_before[slot],slot)
	return true


func _complete_rubbing() -> bool:
	if not await preload("res://tools/rubbing_test_driver.gd").complete(self,first.inspector.rubbing):
		_fail("Physical controls cannot complete the preparatory rubbing"); return false
	return true


func _save_coop(stage: String) -> void:
	if not capture: return
	DirAccess.make_dir_recursive_absolute("res://previews")
	RenderingServer.force_draw(false)
	var result: Image = capture_viewport.get_texture().get_image()
	if result == null or result.is_empty() or result.save_png("res://previews/coop-" + stage + ".png") != OK:
		_fail("Could not save co-op preview")


func _fail(message: String) -> void:
	for action in ["move_left", "move_right", "jump", "interact", "p2_move_left", "p2_move_right", "p2_jump", "p2_interact"]:
		Input.action_release(action)
	paused = false
	push_error(message)
	quit(1)
