extends "res://tools/verify_local_coop.gd"


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
	_save_coop("garden-title")
	ui.garden_preview.pressed.emit()
	await _frames(60)
	if not first.gate_open or not bridge.gap_stabilized or court.tablet_placed or court.lamp_count != 0 or world.ending_reached:
		_fail("Third-act shortcut does not seed just the previous chapters"); return
	_save_coop("garden-entry")
	if not await _duo_walk(50.3, 49.7): _fail("Cannot reach the stele pedestal"); return
	await _dual_hold(false, true)
	if court.tablet_placed: _fail("One person can raise the stele alone in co-op"); return
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(45)
	if court.landscape.task_bars[0].value <= 0 or court.landscape.task_bars[1].value <= 0:
		_fail("Both players cannot see their joint raising progress"); return
	if court.landscape.task_bars[0].size.y > 6 or court.landscape.task_bars[1].size.y > 6:
		_fail("Task progress bars grow outside their cards"); return
	_save_coop("garden-place-progress")
	Input.action_release("p2_interact")
	await _frames(4)
	if court.action_progress > 0 or court.landscape.task_bars[0].value > 0 or court.landscape.task_bars[1].value > 0:
		_fail("Releasing one lifter does not cancel both shared progress displays"); return
	Input.action_release("interact")
	await _dual_hold()
	await _frames(60)
	if not court.tablet_placed: _fail("Stoneworker plus helper cannot raise the stele together"); return
	_save_coop("garden-stele")
	if not await _duo_walk(48.5, 46.2): _fail("Cannot check wrong-role placement"); return
	await _dual_hold(false, true)
	if court.lamp_count != 0: _fail("Wrong role can mount the rubbing"); return
	if not await _duo_walk(46.2, 49.7): _fail("Cannot divide the first two objects"); return
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(45)
	if court.landscape.task_bars[0].value <= 0 or court.landscape.task_bars[1].value <= 0:
		_fail("Parallel object progress is not shown for both players"); return
	_save_coop("garden-object-progress")
	Input.action_release("interact")
	await _frames(4)
	if court.landscape.task_bars[0].value > 0 or court.landscape.task_bars[1].value <= 0:
		_fail("Cancelling one object also clears the other player's independent progress"); return
	Input.action_release("p2_interact")
	await _frames(4)
	await _dual_hold()
	if court.lamp_count != 2 or not court.items_done[0] or not court.items_done[1]:
		_fail("Two personal objects cannot be completed at the same time"); return
	_save_coop("garden-items")
	party.switch_to(2, 0)
	party.switch_to(3, 1)
	if not await _duo_walk(51.7, 52.8): _fail("Cannot reach bell and ribbon"); return
	await _dual_hold()
	if not court.personal_items_done() or court.lamp_count != 4:
		_fail("Bell and ribbon cannot be completed in parallel"); return
	await _frames(120)
	_save_coop("garden-four")
	if not await _duo_walk(42.2, 45.0): _fail("Cannot check empty oil destinations"); return
	await _dual_hold()
	if court.lamp_count != 4: _fail("Oil lamps appear without being carried from the villagers"); return
	if not await _duo_walk(43.5, 43.9): _fail("Cannot reach the villagers' table"); return
	await _dual_hold()
	if court.oil_carriers != [2, 3, -1]: _fail("Simultaneous lamp claims duplicate or lose a lamp"); return
	_save_coop("garden-carry")
	party.switch_to(0, 0)
	await _frames(3)
	if court.oil_carriers[0] != 2 or not court.landscape.carried[0].visible:
		_fail("Changing role loses the carried lamp's identity"); return
	party.switch_to(2, 0)
	if not await _duo_walk(42.2, 45.0): _fail("Cannot deliver two different lamps"); return
	await _dual_hold()
	if court.lamp_count != 6 or not court.items_done[4] or not court.items_done[5]:
		_fail("Two carried lamps cannot be placed independently"); return
	if not await _duo_walk(55.5, 53.0): _fail("Cannot check missing final lamp"); return
	await _dual_hold()
	if court.lamp_count != 6 or court.court_lit: _fail("Unclaimed final lamp can finish the courtyard"); return
	if not await _duo_walk(43.7, 48.0): _fail("Cannot collect the final lamp"); return
	await _dual_hold(true, false)
	if court.oil_carriers[2] != 2: _fail("Any role cannot collect the final oil lamp"); return
	if not await _duo_walk(55.5, 54.0): _fail("Cannot deliver pavilion-side lamp"); return
	await _dual_hold(true, false)
	await _frames(180)
	if not court.court_lit or court.lamp_count != 7 or absf(court.warm_light.light_energy - 2.8) > 0.01:
		_fail("Seven objects do not light the courtyard and open the scroll"); return
	_save_coop("garden-lit")
	if not await _duo_walk(58.0, 56.9): _fail("Cannot approach final gallery"); return
	await _frames(30)
	if world.ending_reached: _fail("Ending opens before both people arrive"); return
	if not await _duo_walk(58.0, 58.8): _fail("Both people cannot join the scroll"); return
	await _frames(90)
	if not world.ending_reached or not court.record_open or not party.movement_locked():
		_fail("The finished journey does not open the scroll and freeze both players"); return
	_save_coop("garden-ending")
	if not court.landscape.record_cover_open: _fail("New scroll cover is missing"); return
	await _key(KEY_ENTER)
	if court.landscape.record_cover_open or court.landscape.record_page!=0: _fail("Cover does not enter the first mural"); return
	await _key(KEY_A)
	if court.landscape.record_page != 0: _fail("Keyboard can move before the first scroll page"); return
	await _key(KEY_RIGHT)
	if court.landscape.record_page != 1: _fail("Scroll cannot turn to the actual records"); return
	await _frames(3)
	_save_coop("garden-record")
	await _key(KEY_LEFT)
	if court.landscape.record_page != 0: _fail("2P cannot turn back a scroll page"); return
	court.landscape.next_button.pressed.emit()
	if court.landscape.record_page != 1: _fail("Mouse button cannot turn the scroll"); return
	await _key(KEY_D)
	if court.landscape.record_page != 2: _fail("Scroll cannot turn to the ending quote"); return
	await _frames(3)
	_save_coop("garden-quote")
	await _key(KEY_RIGHT)
	if court.landscape.record_page != 3: _fail("Scroll cannot reach the fourth mural"); return
	await _frames(3)
	_save_coop("garden-lights")
	await _key(KEY_RIGHT)
	if court.landscape.record_page != 3 or not court.record_open:
		_fail("Arrow navigation leaves the last scroll page or restores movement unexpectedly"); return
	await _tap("open_archive")
	if not paused: _fail("Archive cannot pause the ending scroll"); return
	await _key(KEY_LEFT)
	if court.landscape.record_page != 3: _fail("Paused archive still accepts scroll navigation"); return
	await _tap("open_archive")
	await _key(KEY_ENTER)
	await _frames(6)
	if court.record_open or party.movement_locked(): _fail("Enter cannot close the final page cleanly"); return
	await _key(KEY_ENTER)
	if not court.record_open: _fail("Enter cannot reopen the scroll after keyboard completion"); return
	await _key(KEY_ESCAPE)
	if court.record_open or party.movement_locked(): _fail("Esc leaves the ending controls locked"); return
	await _frames(12)
	_save_coop("garden-complete")
	await _key(KEY_ENTER)
	if not court.record_open: _fail("Enter cannot reopen the completed scroll"); return
	await _tap("restart")
	await _frames(30)
	if court.record_open or not court.court_lit or party.movement_locked(): _fail("R loses progress or leaves the scroll locked"); return
	await _tap("restart_lesson")
	await _frames(60)
	if court.lamp_count != 0 or court.tablet_placed or court.court_lit or court.record_open or court.oil_carriers != [-1, -1, -1] \
		or true in court.items_done or first.gate_open or bridge.gap_stabilized or world.ending_reached or party.movement_locked():
		_fail("T does not clear all courtyard items, lamp ownership and previous preview progress"); return
	print("GARDEN_PREVIEW_OK: direct entry, joint raising and cancelled progress, independent object progress, lamp pickup and delivery, retained carrier identity, seven lights, both-player ending, mouse and keyboard scroll with page bounds, archive input blocking, Esc, Enter, R and T")
	quit(0)
