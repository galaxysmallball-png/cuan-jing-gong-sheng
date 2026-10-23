extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/world.tscn")
	var world: Node3D = packed.instantiate()
	root.add_child(world)
	current_scene = world
	var player: CharacterBody3D = world.get_node("Player")
	var cooperation: Node3D = world.get_node("Spaces/Space01/Cooperation")
	var bridge: Node3D = world.get_node("Spaces/Space02/BridgeCooperation")
	var courtyard: Node3D = world.get_node("Spaces/Space03/CourtyardCooperation")
	for frame in range(60):
		await physics_frame
	if not player.is_on_floor():
		_fail("Player did not settle on the first floor")
		return

	Input.action_press("jump")
	var highest_y: float = player.global_position.y
	for frame in range(60):
		await physics_frame
		if frame == 1:
			Input.action_release("jump")
		highest_y = maxf(highest_y, player.global_position.y)
	if highest_y < 1.4 or not player.is_on_floor():
		_fail("Jump and landing check failed")
		return

	# The door must physically stop an unsolved run, including a jump attempt.
	Input.action_press("move_right")
	for frame in range(500):
		await physics_frame
	Input.action_press("jump")
	for frame in range(80):
		await physics_frame
		if frame == 1:
			Input.action_release("jump")
	Input.action_release("move_right")
	if player.global_position.x >= 19.0 or cooperation.gate_open:
		_fail("Closed gate can be bypassed")
		return

	if not await _walk_to(player, 13.5):
		_fail("Cannot reach the observation point")
		return
	Input.action_press("interact")
	for frame in range(120):
		await physics_frame
	Input.action_release("interact")
	if cooperation.observed or cooperation.observation_progress > 0.0:
		_fail("Observation succeeds without the partner's light")
		return

	if not await _walk_to(player, 6.0):
		_fail("Cannot reach the partner")
		return
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for frame in range(600):
		await physics_frame
		if cooperation.partner_ready:
			break
	if not cooperation.partner_ready:
		_fail("Partner does not reach the lighting station")
		return

	if not await _walk_to(player, 13.5):
		_fail("Cannot return to the observation point")
		return
	Input.action_press("interact")
	for frame in range(12):
		await physics_frame
	Input.action_release("interact")
	await physics_frame
	await physics_frame
	if cooperation.observed or cooperation.observation_progress > 0.0:
		_fail("Interrupted observation is incorrectly accepted")
		return

	Input.action_press("interact")
	for frame in range(int(ceil(cooperation.observation_seconds * 60.0)) + 5):
		await physics_frame
	Input.action_release("interact")
	if not cooperation.observed:
		_fail("Cooperative observation did not finish")
		return
	for frame in range(720):
		await physics_frame
		if cooperation.gate_open:
			break
	if not cooperation.gate_open:
		_fail("Partner did not open the gate")
		return

	if not await _walk_to(player, 21.0):
		_fail("Cannot enter the second space")
		return
	var initial_crate_x: float = bridge.crate.global_position.x
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(15):
		await physics_frame
	Input.action_release("interact")
	Input.action_release("move_right")
	if absf(bridge.crate.global_position.x - initial_crate_x) > 0.01:
		_fail("Material moves when the player is too far away")
		return
	if not await _walk_to(player, 23.0):
		_fail("Cannot reach the material box")
		return
	Input.action_press("move_right")
	for frame in range(45):
		await physics_frame
	Input.action_release("move_right")
	if absf(bridge.crate.global_position.x - initial_crate_x) > 0.01:
		_fail("Material moves without holding E")
		return
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(20):
		await physics_frame
	Input.action_release("interact")
	var interrupted_crate_x: float = bridge.crate.global_position.x
	for frame in range(15):
		await physics_frame
	Input.action_release("move_right")
	if interrupted_crate_x <= initial_crate_x + 0.1 or absf(bridge.crate.global_position.x - interrupted_crate_x) > 0.03:
		_fail("Push or release-to-stop behavior failed")
		return

	# Jump past the box to verify that the craftsman cannot work without supplies.
	Input.action_press("jump")
	Input.action_press("move_right")
	for frame in range(55):
		await physics_frame
		if frame == 1:
			Input.action_release("jump")
	Input.action_release("move_right")
	if not await _walk_to(player, 30.0):
		_fail("Cannot reach the craftsman after jumping over the box")
		return
	await _press_interact()
	for frame in range(180):
		await physics_frame
	if bridge.bridge_ready or bridge.stage != bridge.Stage.WAITING:
		_fail("Craftsman builds without delivered material")
		return
	if not await _walk_to(player, 31.3):
		_fail("Cannot reach the broken crossing")
		return
	var recoveries: int = player.fall_recovery_count
	Input.action_press("jump")
	Input.action_press("move_right")
	for frame in range(240):
		await physics_frame
		if frame == 1:
			Input.action_release("jump")
		if player.fall_recovery_count > recoveries:
			break
	Input.action_release("move_right")
	for frame in range(30):
		await physics_frame
	if player.fall_recovery_count != recoveries + 1 or absf(player.global_position.x - 21.0) > 0.2 \
		or bridge.bridge_ready or not cooperation.gate_open:
		_fail("Gap can be bypassed, or local fall recovery loses the first cooperation")
		return

	if not await _deliver_box(player, bridge):
		_fail("Cannot push the material into the delivery position")
		return
	if bridge.bridge_ready:
		_fail("Bridge opens before the craftsman is called")
		return
	if not await _walk_to(player, 30.0):
		_fail("Delivered material still blocks the path")
		return
	await _press_interact()
	for frame in range(180):
		await physics_frame
		if bridge.stage == bridge.Stage.BUILDING:
			break
	if bridge.stage != bridge.Stage.BUILDING or not bridge.bridge_collision.disabled:
		_fail("Craftsman does not start construction, or bridge collision opens too early")
		return

	# Reset during construction: a stale tween must not silently finish the old bridge.
	await _restart()
	for frame in range(240):
		await physics_frame
	if bridge.bridge_ready or bridge.material_delivered or not bridge.bridge_collision.disabled \
		or cooperation.gate_open or absf(bridge.crate.position.x - 4.0) > 0.01:
		_fail("Reset during construction leaves stale completion or materials")
		return
	if not await _repeat_first(player, cooperation):
		_fail("First-space cooperation cannot be replayed after the global reset")
		return
	if not await _deliver_box(player, bridge) or not await _walk_to(player, 30.0):
		_fail("Second-space material cannot be delivered again")
		return
	await _press_interact()
	for frame in range(600):
		await physics_frame
		if bridge.bridge_ready:
			break
	await physics_frame
	await physics_frame
	if not bridge.bridge_ready or bridge.bridge_collision.disabled:
		_fail("Constructed bridge has no usable collision")
		return
	if not await _walk_to(player, 41.0):
		_fail("Cannot walk over the completed bridge into the third space")
		return
	var initial_stand_x: float = courtyard.stand.global_position.x
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(15):
		await physics_frame
	Input.action_release("interact")
	Input.action_release("move_right")
	if absf(courtyard.stand.global_position.x - initial_stand_x) > 0.01:
		_fail("Public lamp stand moves from a distance")
		return
	if not await _walk_to(player, 43.0):
		_fail("Cannot reach the public lamp stand")
		return
	Input.action_press("move_right")
	for frame in range(45):
		await physics_frame
	Input.action_release("move_right")
	if absf(courtyard.stand.global_position.x - initial_stand_x) > 0.01:
		_fail("Public lamp stand moves without holding E")
		return
	await _jump_side("move_right")
	if not await _walk_to(player, 52.0):
		_fail("Cannot reach the light keeper")
		return
	await _press_interact()
	for frame in range(120):
		await physics_frame
	if courtyard.keeper_ready or courtyard.court_lit:
		_fail("Keeper starts without the stand being placed")
		return
	if not await _walk_to(player, 58.0):
		_fail("Cannot check the unfinished courtyard exit")
		return
	await process_frame
	if world.ending_reached or courtyard.get_node("EndingScroll").visible:
		_fail("Walking to the end bypasses the courtyard cooperation")
		return
	if not await _walk_to(player, 49.5):
		_fail("Cannot reach the lighting handle")
		return
	Input.action_press("interact")
	for frame in range(120):
		await physics_frame
	Input.action_release("interact")
	if courtyard.lighting_progress > 0.0 or courtyard.court_lit:
		_fail("Lighting succeeds before stand placement and keeper readiness")
		return
	if not await _walk_to(player, 45.0):
		_fail("Cannot return to the lamp stand")
		return
	await _jump_side("move_left")
	if not await _place_lamp(player, courtyard):
		_fail("Cannot push and place the public lamp stand")
		return
	if not await _walk_to(player, 49.5):
		_fail("Placed lamp stand obstructs the lighting handle")
		return
	Input.action_press("interact")
	for frame in range(120):
		await physics_frame
	Input.action_release("interact")
	if courtyard.lighting_progress > 0.0 or courtyard.court_lit:
		_fail("Lighting succeeds without calling the keeper")
		return
	if not await _call_keeper(player, courtyard):
		_fail("Keeper does not reach the lighting station")
		return
	Input.action_press("interact")
	for frame in range(12):
		await physics_frame
	Input.action_release("interact")
	await physics_frame
	await physics_frame
	if courtyard.lighting_progress > 0.0 or courtyard.court_lit:
		_fail("Interrupted lighting hold is incorrectly accepted")
		return
	await _hold_lighting(courtyard)
	if courtyard.stage != courtyard.Stage.LIGHTING or courtyard.court_lit:
		_fail("Cooperative lighting does not begin, or finishes before the light spread")
		return
	for frame in range(12):
		await physics_frame
	if courtyard.get_node("Fixtures/LampA/Glow").light_energy <= courtyard.get_node("Fixtures/LampC/Glow").light_energy:
		_fail("Courtyard lamps do not light in sequence")
		return

	# Reset while lighting is spreading: no stale light tween or ending may survive.
	await _restart()
	for frame in range(360):
		await physics_frame
	if courtyard.court_lit or courtyard.stand_placed or courtyard.keeper_ready or world.ending_reached \
		or courtyard.get_node("Residents").visible or courtyard.get_node("EndingScroll").visible \
		or absf(courtyard.warm_light.light_energy - 0.45) > 0.01:
		_fail("Lighting reset leaves stale completion, residents, record, or warmth")
		return
	for fixture in courtyard.get_node("Fixtures").get_children():
		if fixture.get_node("Glow").light_energy > 0.01:
			_fail("Lighting reset leaves a lamp on")
			return
	if not await _repeat_first(player, cooperation) or not await _deliver_box(player, bridge) \
		or not await _walk_to(player, 30.0):
		_fail("Previous spaces cannot be replayed after the lighting reset")
		return
	await _press_interact()
	for frame in range(600):
		await physics_frame
		if bridge.bridge_ready:
			break
	await physics_frame
	await physics_frame
	if not bridge.bridge_ready or not await _place_lamp(player, courtyard) \
		or not await _call_keeper(player, courtyard):
		_fail("Courtyard cannot be replayed after resetting the light spread")
		return
	await _hold_lighting(courtyard)
	for frame in range(600):
		await physics_frame
		if courtyard.court_lit:
			break
	if not courtyard.court_lit or not await _walk_to(player, 58.0):
		_fail("Cannot finish lighting and reach the shared courtyard ending")
		return
	await process_frame
	await process_frame
	if world.visited_spaces != [0, 1, 2] or player.global_position.y < 0.4:
		_fail("Three-space sequence or floor continuity failed")
		return
	if not world.ending_reached or world.completed_actions.size() != 3 \
		or not courtyard.get_node("EndingScroll").visible \
		or courtyard.get_node("EndingScroll/Record").text.count("\n") != 2:
		_fail("Ending does not record all three completed cooperations")
		return
	if absf(courtyard.warm_light.light_energy - courtyard.warm_light_energy) > 0.01 \
		or not courtyard.get_node("Residents").visible:
		_fail("Completed courtyard has no warm light or returning residents")
		return
	Input.action_press("restart")
	await physics_frame
	await physics_frame
	Input.action_release("restart")
	if absf(player.global_position.x - 2.0) > 0.1 or not courtyard.court_lit or not world.ending_reached:
		_fail("R fails to preserve the completed journey")
		return

	await _restart()
	if absf(player.global_position.x - 2.0) > 0.1 or cooperation.observed or cooperation.gate_open \
		or bridge.material_delivered or bridge.bridge_ready or not bridge.bridge_collision.disabled \
		or courtyard.stand_placed or courtyard.court_lit or world.ending_reached or not world.completed_actions.is_empty():
		_fail("Lesson reset failed")
		return
	print("COURTYARD_OK: three cooperations, physical paths, prerequisites, interrupted hold, sequential lights, reset and replay, action record")
	quit(0)


func _jump_side(action: String) -> void:
	Input.action_press("jump")
	Input.action_press(action)
	for frame in range(55):
		await physics_frame
		if frame == 1:
			Input.action_release("jump")
	Input.action_release(action)


func _place_lamp(player: CharacterBody3D, courtyard: Node3D) -> bool:
	if not await _walk_to(player, courtyard.stand.global_position.x - 1.05):
		return false
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(1200):
		await physics_frame
		if courtyard.stand_placed:
			break
	Input.action_release("interact")
	Input.action_release("move_right")
	for frame in range(45):
		await physics_frame
	return courtyard.stand_placed


func _call_keeper(player: CharacterBody3D, courtyard: Node3D) -> bool:
	if not await _walk_to(player, 52.0):
		return false
	await _press_interact()
	for frame in range(600):
		await physics_frame
		if courtyard.keeper_ready:
			break
	return courtyard.keeper_ready and await _walk_to(player, 49.5)


func _hold_lighting(courtyard: Node3D) -> void:
	Input.action_press("interact")
	for frame in range(int(ceil(courtyard.lighting_hold_seconds * 60.0)) + 5):
		await physics_frame
	Input.action_release("interact")


func _press_interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	await physics_frame


func _restart() -> void:
	Input.action_press("restart_lesson")
	await physics_frame
	await physics_frame
	Input.action_release("restart_lesson")
	await physics_frame
	await physics_frame


func _deliver_box(player: CharacterBody3D, bridge: Node3D) -> bool:
	if not await _walk_to(player, bridge.crate.global_position.x - 1.05):
		return false
	Input.action_press("interact")
	Input.action_press("move_right")
	for frame in range(1200):
		await physics_frame
		if bridge.material_delivered:
			break
	Input.action_release("interact")
	Input.action_release("move_right")
	for frame in range(45):
		await physics_frame
	return bridge.material_delivered


func _repeat_first(player: CharacterBody3D, cooperation: Node3D) -> bool:
	if not await _walk_to(player, 6.0):
		return false
	await _press_interact()
	for frame in range(600):
		await physics_frame
		if cooperation.partner_ready:
			break
	if not cooperation.partner_ready or not await _walk_to(player, 13.5):
		return false
	Input.action_press("interact")
	for frame in range(int(ceil(cooperation.observation_seconds * 60.0)) + 5):
		await physics_frame
	Input.action_release("interact")
	for frame in range(720):
		await physics_frame
		if cooperation.gate_open:
			return true
	return false


func _walk_to(player: CharacterBody3D, target_x: float) -> bool:
	var action: String = "move_right" if target_x > player.global_position.x else "move_left"
	Input.action_press(action)
	for frame in range(2400):
		await physics_frame
		if player.global_position.y < 0.4:
			Input.action_release(action)
			return false
		if absf(player.global_position.x - target_x) < 0.08:
			Input.action_release(action)
			await physics_frame
			return true
	Input.action_release(action)
	return false


func _fail(message: String) -> void:
	for action in ["jump", "move_left", "move_right", "interact", "restart_lesson"]:
		Input.action_release(action)
	push_error(message)
	quit(1)
