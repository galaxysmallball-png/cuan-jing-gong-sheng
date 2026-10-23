extends "res://tools/verify_local_coop.gd"


func _run() -> void:
	if capture:
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280,720)
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
	await _key(KEY_B)
	if paused or ui.satchel.visible:
		_fail("The title screen opens the travel inventory"); return
	await _start_default_party()
	await _frames(35)
	await _click_at(ui.satchel_button.get_global_rect().get_center())
	if not paused or ui.screen != ui.Screen.SATCHEL or not ui.satchel.visible or not _notes_match():
		_fail("The empty satchel is inaccessible or reveals uncollected clues"); return
	_save_coop("satchel-empty")
	var start: Vector3 = player.global_position
	await _press_key(KEY_D,true)
	await _frames(20)
	await _press_key(KEY_D,false)
	if player.global_position.distance_to(start) > 0.01:
		_fail("Reading the satchel does not pause movement"); return
	await _click_at(ui.satchel.close_button.get_global_rect().get_center())
	if paused or ui.screen != ui.Screen.GAME:
		_fail("Satchel close button leaves the game paused"); return
	if not await _duo_walk(12.6,11.5):
		_fail("Cannot approach the first puzzle"); return
	await _click_stone(0)
	await _dual_hold(true,false)
	if first.clues != [true,false,false,false]:
		_fail("Could not collect just the first role's clue"); return
	await _click_tile(2)
	await _click_slot(0)
	await _click_tile(1)
	var before_slots: Array = first.slots.duplicate()
	var before_turns: Array = first.turns.duplicate()
	var held_tile: int = first.selected_tile
	await _frames(550)
	if first._feedback_seconds > 0 or ui._notice_seconds > 0:
		_fail("The clue toast never expires"); return
	await _key(KEY_B)
	if not paused or not ui.satchel.visible or not _notes_match():
		_fail("The collected clue vanishes after its toast expires"); return
	_save_coop("satchel-one-note")
	for key in [KEY_Q,KEY_J,KEY_K,KEY_ENTER,KEY_BACKSPACE,KEY_TAB,KEY_4,KEY_F2,KEY_R,KEY_T]:
		await _key(key)
	if not paused or ui.screen != ui.Screen.SATCHEL or first.slots != before_slots or first.turns != before_turns \
		or first.selected_tile != held_tile or first.step != 1 or party.active_id != 0:
		_fail("Satchel input leaks to the puzzle, roles, archive or reset"); return
	await _key(KEY_ESCAPE)
	if paused or not first.puzzle_active or not player.interaction_locked or first.slots != before_slots or first.selected_tile != held_tile:
		_fail("Closing the satchel also closes or resets the puzzle"); return
	_save_coop("satchel-resume-puzzle")
	await _click_at(ui.satchel_button.get_global_rect().get_center())
	if not paused:
		_fail("The inventory mouse entry is covered by the puzzle"); return
	await _key(KEY_B)
	if paused or ui.satchel.visible:
		_fail("B immediately reopens the satchel after closing it"); return
	await _tap("restart")
	await _frames(35)
	await _key(KEY_B)
	if not _notes_match() or first.clues.count(true) != 1:
		_fail("R discards learned notes"); return
	await _key(KEY_ESCAPE)
	await _click_stone(0)
	await _dual_hold(false,true)
	party.switch_to(2,0)
	party.switch_to(3,1)
	await _dual_hold()
	await _key(KEY_B)
	if not _notes_match() or first.clues.count(true) != 4:
		_fail("Notes are lost or duplicated when both players switch roles"); return
	_save_coop("satchel-all-notes")
	await _key(KEY_ESCAPE)
	for id in range(6):
		await _click_tile(id)
		for rotation in range(posmod(-first.turns[id],4)):
			await _key(KEY_Q)
		await _click_slot(id)
	await _frames(120)
	if not first.gate_open:
		_fail("Reviewing notes blocks completion of the original puzzle"); return
	if not await _duo_walk(21.5,20.55):
		_fail("Cannot continue after reviewing the notes"); return
	await _key(KEY_B)
	if not _notes_match() or first.clues.count(true) != 4:
		_fail("Entering the next scene loses the clue notes"); return
	_save_coop("satchel-after-crossing")
	await _key(KEY_ESCAPE)
	await _tap("restart_lesson")
	await _frames(40)
	await _key(KEY_B)
	if not _notes_match() or first.clues.count(true) != 0:
		_fail("T fails to clear the old journey's notes"); return
	_save_coop("satchel-reset")
	await _key(KEY_ESCAPE)
	await _tap("open_archive")
	await _key(KEY_B)
	if not paused or ui.screen != ui.Screen.ARCHIVE or ui.satchel.visible:
		_fail("Satchel opens inside another pause screen"); return
	await _tap("open_archive")
	print("FIELD_SATCHEL_OK: spoiler-free empty notes, collected clue survives expired toast, mouse/B entry, shared role collection, paused input isolation, Esc returns to held puzzle, R/scene retention, T clearing and archive isolation")
	quit(0)


func _notes_match() -> bool:
	for role in range(4):
		var words: String = first.CLUES[role].get_slice("：",1)
		if first.clues[role] != ui.satchel.contents[role].text.contains(words):
			return false
	return true
