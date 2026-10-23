extends "res://tools/verify_nearby_interactions.gd"


func _initialize() -> void:
	capture = "--capture-planar" in OS.get_cmdline_user_args()
	create_timer(160, true).timeout.connect(func(): _fail("Planar transport check timed out"))
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
	await _frames(18)
	await _start_default_party()
	await _frames(35)
	ui._toggle_hint()
	await _frames(3)
	_save_coop("planar-controls-hint")
	ui._close_hint()
	await _frames(3)
	await _put(7.5, 8.8)
	await _press_key(KEY_W, true)
	await _press_key(KEY_UP, true)
	await _frames(8)
	if player.global_position.z > -.45 or second.global_position.z > -.45 or player.global_position.y > .9 or second.global_position.y > .9:
		_fail("W/up still jump or do not move into the ground plane"); return
	await _press_key(KEY_W, false)
	await _press_key(KEY_UP, false)
	await _press_key(KEY_S, true)
	await _press_key(KEY_DOWN, true)
	await _frames(26)
	await _press_key(KEY_S, false)
	await _press_key(KEY_DOWN, false)
	if player.global_position.z < .7 or second.global_position.z < .7 or first.clues.count(true) != 0:
		_fail("S/down do not move toward the screen independently of task actions"); return
	await _frames(35)
	for actor in party.followers:
		if actor.global_position.z < .35: _fail("Follower remains pinned to the old Z=0 lane"); return
	var second_depth: float = second.global_position.z
	var first_depth: float = player.global_position.z
	await _press_key(KEY_W, true)
	await _frames(22)
	await _press_key(KEY_W, false)
	if player.global_position.z > first_depth - .5 or absf(second.global_position.z - second_depth) > .05:
		_fail("1P depth input also moves 2P"); return
	_save_coop("planar-ground-depth")
	await _put(8.5, 9.8)
	await _press_key(KEY_D, true)
	await _press_key(KEY_S, true)
	await _frames(6)
	if Vector2(player.velocity.x, player.velocity.z).length() > player.move_speed + .02:
		_fail("Diagonal travel is faster than straight movement"); return
	await _press_key(KEY_D, false)
	await _press_key(KEY_S, false)
	await _press_key(KEY_SPACE, true)
	await _press_key(KEY_CTRL, true, KEY_LOCATION_RIGHT)
	await _frames(7)
	await _press_key(KEY_SPACE, false)
	await _press_key(KEY_CTRL, false, KEY_LOCATION_RIGHT)
	if player.global_position.y < 1.1 or second.global_position.y < 1.1: _fail("New independent jump keys fail"); return
	await _frames(40)
	ui._open_audio_settings()
	var saved: Vector3 = player.global_position
	await _press_key(KEY_W, true)
	await _frames(10)
	await _press_key(KEY_W, false)
	if player.global_position != saved: _fail("Depth movement leaks through paused settings"); return
	ui._close_audio_settings()
	await _frames(3)
	world.start_creek_preview()
	bridge.bridge_ready = true
	bridge.step = 5
	bridge.helpers_called = true
	bridge._helpers.visible = true
	bridge.get_node("BridgeAssembly").visible = true
	bridge.get_node("BridgeAssembly").rotation.z = 0
	bridge.get_node("BridgeBody/Collision").set_deferred("disabled", false)
	await _put(34, 35.2)
	await _press_key(KEY_S, true)
	await _press_key(KEY_DOWN, true)
	await _frames(35)
	await _press_key(KEY_S, false)
	await _press_key(KEY_DOWN, false)
	if player.global_position.z > .8 or second.global_position.z > .8 or not player.is_on_floor() or not second.is_on_floor():
		_fail("Bridge rails do not keep depth movement on the deck"); return
	_save_coop("planar-bridge-rails")
	party.switch_to(2, 0)
	party.switch_to(1, 1)
	await _put(38.4, 35)
	for i in range(party.followers.size()):
		party.followers[i].global_position = Vector3(35.5 + i, .75, 0)
		party.followers[i].velocity = Vector3.ZERO
	await _frames(65)
	# The completed bridge now funnels its approaches onto the safe deck.
	# Test an actual off-station position on the wide right bank instead.
	player.global_position.x = 39.05
	player.global_position.z = 1.6
	await _press_key(KEY_E, true)
	await _press_key(KEY_P, true)
	await _frames(24)
	if bridge.action_progress > 0 or bridge.rope_held: _fail("Rope task can be done from a different depth"); return
	await _press_key(KEY_E, false)
	await _press_key(KEY_P, false)
	player.global_position.x = 38.4
	player.global_position.z = 0
	await _frames(12)
	await _press_key(KEY_E, true)
	await _press_key(KEY_KP_0, true)
	await _frames(26)
	if bridge.action_progress < .15 or not bridge.rope_held or not bridge.steady_held or not nearby_ui.reading[1].is_empty():
		_fail("E/keypad0 do not cooperate or keypad0 still opens chat: progress=" + str(bridge.action_progress) + " rope=" + str(bridge.rope_held) + " stone=" + str(bridge.steady_held) + " group=" + str(party.nearby_count(35.0))); return
	await _press_key(KEY_W, true)
	await _frames(4)
	if bridge.action_progress > .1: _fail("Moving in depth keeps standing-hold progress"); return
	await _press_key(KEY_W, false)
	await _press_key(KEY_E, false)
	await _press_key(KEY_KP_0, false)
	player.global_position.z = 0
	await _frames(15)
	await _dual_hold()
	if not bridge.gap_stabilized or bridge.step != 6: _fail("Planar controls broke bridge rescue"); return
	await _put(38.9, 39.3)
	await _frames(40)
	var advanced: float = bridge._tablet.position.x
	await _put(33, 34)
	await _frames(40)
	if bridge._tablet.position.x < advanced - .001 or not bridge._tablet.visible:
		_fail("Returning before handoff reverses the transported stone"); return
	await _put(40.7, 40.1)
	await _frames(5)
	if not bridge.tablet_delivered or bridge._tablet.visible or not court._tablet.visible:
		_fail("Right-bank handoff does not transfer the one stone into the courtyard"); return
	_save_coop("planar-right-bank-handoff")
	for positions in [Vector2(27, 29), Vector2(35, 35.8), Vector2(41, 42)]:
		await _put(positions.x, positions.y)
		await _frames(8)
		if bridge._tablet.visible or not bridge.tablet_delivered or not court._tablet.visible:
			_fail("Walking back resurrects or duplicates the delivered stone"); return
	for rope in bridge.landscape.safety_rope:
		if rope.visible: _fail("Delivered stone leaves a ghost transport rope"); return
	await _put(35, 35.5)
	world.restart_current_scene()
	await _frames(8)
	if bridge.tablet_delivered or bridge.bridge_ready or bridge._tablet.visible or court._tablet.visible or absf(bridge._tablet.position.x - 12.5) > .01:
		_fail("Restarting act two does not reset the handoff lifecycle"); return
	print("PLANAR_TRANSPORT_OK: actual WASD/arrows ground depth, normalized diagonals, independent Space/right-Ctrl jumps, depth-aware followers and pause, bridge rails, stationary XZ rescue and keypad0 task/chat separation, monotonic transport, one-way right-bank handoff, repeated return trips without duplicate stone/rope, act-two restart")
	quit(0)
