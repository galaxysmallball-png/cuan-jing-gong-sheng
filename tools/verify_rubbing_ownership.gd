extends "res://tools/verify_cooperative_experience.gd"

const Driver=preload("res://tools/rubbing_test_driver.gd")


func _initialize() -> void:
	capture=true
	create_timer(240,true).timeout.connect(func(): _fail("Rubbing / owner pickup timed out"))
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
	await _frames(15)
	await _start_default_party()
	for index in [0,1]:
		if not await _check_owner(index): return
	await _put(12.5,13)
	await _click_stone(0)
	var rubbing: Control=first.inspector.rubbing
	if not rubbing.visible or rubbing.completed: _fail("First inspection skips hands-on rubbing"); return
	first.select_tile(0)
	if first.selected_tile!=-1: _fail("Unmade rubbing allows glyph placement"); return
	await Driver.tap(self,KEY_E)
	if rubbing.phase!=0 or rubbing.fixed[0] or first.step!=0: _fail("Misaligned paper press or new input leaks into clues"); return
	_save_coop("rubbing-paper-alignment")
	await _near_key(KEY_ESCAPE)
	if player.interaction_locked or second.interaction_locked: _fail("Exiting rubbing leaves movement locked"); return
	await _click_stone(0)
	if not await Driver.complete(self,rubbing,1,_capture_phase): _fail("Two physical controllers cannot align paper"); return
	var before: Array[int]=rubbing.ink.duplicate()
	# Timing outside the band must not ink a cell. Holding also cannot auto-dab.
	while rubbing.pressure(0)>.14: await _frames(1)
	await Driver.key(self,KEY_E,true)
	await _frames(140)
	await Driver.key(self,KEY_E,false)
	if rubbing.ink!=before or first.step!=0: _fail("Wrong / held dab bypasses timing or awards role clues"); return
	await _near_key(KEY_H)
	var clock_before: Array[float]=rubbing.rhythm.duplicate()
	await _frames(10)
	if not paused or rubbing.rhythm!=clock_before: _fail("Help does not freeze the rubbing rhythm"); return
	await _near_key(KEY_ESCAPE)
	while rubbing.pressure(0)<.40 or rubbing.pressure(0)>.60 or rubbing.cooldown[0]>0: await _frames(1)
	await _click_at(rubbing.get_global_transform_with_canvas()*rubbing.patch_rect(0).get_center())
	if rubbing.ink[0]!=1: _fail("Mouse cannot dab the selected paper area"); return
	if not await Driver.complete(self,rubbing,2,_capture_phase): _fail("Both columns cannot be evenly dabbed"); return
	await _press_key(KEY_E,true)
	await _frames(25)
	await _press_key(KEY_E,false)
	if rubbing.peel>.01 or rubbing.phase!=2: _fail("One co-op player can peel for both"); return
	await _press_key(KEY_E,true)
	await _press_key(KEY_P,true)
	await _frames(24)
	if rubbing.peel<.25 or rubbing.peel>.8: _fail("Paper has no intermediate shared lift"); return
	_save_coop("rubbing-shared-peel-progress")
	await _press_key(KEY_E,false)
	await _press_key(KEY_P,false)
	await _near_key(KEY_ESCAPE)
	await _click_stone(0)
	if rubbing.phase!=2 or rubbing.peel!=0 or rubbing.ink.count(2)!=6: _fail("Reopening loses ink or retains abandoned lift"); return
	if not await Driver.complete(self,rubbing,4,_capture_phase): _fail("Shared reveal cannot lead to reading"); return
	if rubbing.visible or not first.inspector.puzzle_container.visible or first.step!=0 or first.gate_open or first.selected_tile!=-1:
		_fail("Taking the print bypasses reading or leaks Enter into a glyph"); return
	party.switch_to(0,0)
	party.switch_to(1,1)
	await Driver.tap(self,KEY_E)
	await Driver.tap(self,KEY_P)
	party.switch_to(2,0)
	party.switch_to(3,1)
	await Driver.tap(self,KEY_E)
	await Driver.tap(self,KEY_P)
	await _finish_observation()
	await _frames(130)
	if not first.gate_open: _fail("Real rubbing / four-role reading / six glyphs cannot open gate"); return
	world.start_creek_preview()
	for index in [2,3]:
		if not await _check_owner(index): return
	bridge.timber_prepared=true
	bridge.material_delivered=true
	bridge.step=2
	bridge.crate.position=Vector3(9.5,.5,-1.9)
	bridge.get_node("MaterialCrate/Collision").disabled=true
	party.switch_to(1,1)
	await _put(28.5,29.2)
	await _frames(8)
	_save_coop("rubbing-new-cut-stone-pier")
	var saved_camera: Transform3D=world.camera.transform
	var saved_size: float=world.camera.size
	world.set_process(false)
	world.camera.position=Vector3(30.5,2.0,8)
	world.camera.look_at(Vector3(30.5,.4,-.8))
	world.camera.size=3.8
	await _frames(4)
	_save_coop("rubbing-pier-masonry-detail")
	world.camera.transform=saved_camera
	world.camera.size=saved_size
	world.set_process(true)
	await _put(29.7,30.5)
	await _dual_hold(false,true)
	if bridge.step!=3 or absf(bridge.landscape.repair_blocks[-1].rotation.z)>.001: _fail("Redressed pier no longer repairs"); return
	await _tap("restart_lesson")
	if first.inspector.rubbing.completed or first.inspector.rubbing.phase!=0 or true in world.keepsakes.collected:
		_fail("New journey does not clear rubbing and owner pickups"); return
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("RUBBING_OWNERSHIP_OK: four owner-only mouse / physical-key / nearby pickups, wrong-role guidance and owned-role switching, paper alignment / timing and held-key rejection / six dabs areas / dual peeling and interruption / help pause / glyph transfer, actual four-role six-glyph gate, dressed masonry pier and repair, full reset")
	quit(0)


func _check_owner(index: int) -> bool:
	var inventory: Node3D=world.keepsakes
	var owner: int=party.owner_of(index)
	var wrong: int=2 if index==0 else 0 if index==2 else 3 if index==1 else 1
	party.switch_to(wrong,owner)
	await _put(inventory.POSITIONS[index].x,inventory.POSITIONS[index].x-.6)
	await _frames(10)
	await Driver.tap(self,KEY_E if owner==0 else KEY_P)
	await _click_at(world.camera.unproject_position(inventory.POSITIONS[index]+Vector3(0,.44,0)))
	nearby_ui.pinned[owner]="keepsake_%d"%index
	await Driver.tap(self,KEY_F if owner==0 else KEY_SLASH)
	if inventory.collected[index] or not inventory.pickups[index].visible:
		_fail("Wrong character collected another person's item through keyboard / click / nearby entry"); return false
	if index==0: _save_coop("rubbing-wrong-owner-reminder")
	if owner==0: await Driver.tap(self,KEY_TAB)
	else:
		await _press_key(KEY_SHIFT,true,KEY_LOCATION_RIGHT)
		await _press_key(KEY_SHIFT,false,KEY_LOCATION_RIGHT)
	var body: CharacterBody3D=party.human_players()[owner]
	if body.character_id!=index: _fail("Owned companion switching cannot select the item's owner"); return false
	await _put(inventory.POSITIONS[index].x,inventory.POSITIONS[index].x-.6)
	await _frames(10)
	if index%2==0:
		await _click_at(world.camera.unproject_position(inventory.POSITIONS[index]+Vector3(0,.44,0)))
	else: await Driver.tap(self,KEY_P)
	if not inventory.collected[index] or inventory.pickups[index].visible:
		_save_coop("rubbing-owner-click-failure")
		_fail("The correct owner cannot pick up their own item index="+str(index)+" role="+str(body.character_id)+" at="+str(body.global_position)+" floor="+str(body.is_on_floor())+" speed="+str(party.planar_speed(body))+" allowed="+str(inventory._allowed())); return false
	return true


func _capture_phase(phase: int) -> void:
	_save_coop("rubbing-phase-%d"%phase)
