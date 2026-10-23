extends "res://tools/verify_cooperative_experience.gd"

var watchdog: SceneTreeTimer


func _initialize() -> void:
	capture=true
	watchdog=create_timer(200,true)
	watchdog.timeout.connect(_timeout)
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
	await _frames(12)
	await _start_default_party()
	await _clear_story()
	var guide: CanvasLayer=world.guidance
	if guide.get_child_count()!=2 or not guide.find_children("*","Button",true,false).is_empty(): _fail("Route strip or direct-switch UI still exists"); return
	for slot in range(2):
		if guide.cards[slot].visible or guide.names[slot].horizontal_alignment!=HORIZONTAL_ALIGNMENT_CENTER or guide.tasks[slot].horizontal_alignment!=HORIZONTAL_ALIGNMENT_CENTER:
			_fail("Idle next-step panels remain or compact work text is not centered"); return
	await _put(12.5,13)
	await _click_stone(0)
	if not await _complete_rubbing(): return
	await _click_tile(1)
	if first.selected_tile!=1: _fail("Mouse cannot take a glyph"); return
	await _click_at(first.inspector.puzzle_container.get_global_transform_with_canvas()*Vector2(235,370))
	if first.selected_tile!=-1 or first.slots.find(1)>=0: _fail("Second click on blank board cannot put the carried glyph down"); return
	await _click_tile(1)
	await _click_slot(2)
	if first.selected_tile!=-1 or first.slots[2]!=1: _fail("Mouse second click cannot place in a socket"); return
	first.inspector.transform=Transform2D.IDENTITY.scaled(Vector2(.8,.8))
	await _click_tile(1)
	await _click_at(first.inspector.puzzle_container.get_global_transform_with_canvas()*Vector2(230,370))
	if first.selected_tile!=-1 or first.slots.find(1)>=0: _fail("Scaled viewer cannot drop the glyph on second click"); return
	first.inspector.transform=Transform2D.IDENTITY
	await _click_tile(1)
	await _click_slot(1)
	_save_coop("clean-mouse-glyph-return-and-place")
	await _near_key(KEY_ESCAPE)
	await _put(9.2,17.4)
	for index in range(2):
		await _tap("interact" if index==0 else "p2_interact")
		if not world.keepsakes.collected[index] or not world.story.current.get("line","").begins_with("我的") or world.story.current.line.contains(world.keepsakes.TITLES[index]):
			_fail("Keepsake speaker describes their own object in third person"); return
		if ui.satchel_notice.text.contains("按") or ui.satchel_notice.text.contains("查看"): _fail("Obtained item still says which key to view"); return
	_save_coop("clean-first-person-chisel")
	world.achievements.record_item("bai_tiedye")
	await _frames(4)
	if world.achievements.toast_text.text.contains("按 C") or world.achievements.toast_button.visible: _fail("Achievement notification still offers view instructions / side action"); return
	await _clear_story()
	_save_coop("clean-receipts-without-view-keys")
	world.start_creek_preview()
	party.switch_to(2,0)
	party.switch_to(3,1)
	await _put(23,28.8)
	for index in [2,3]:
		await _tap("interact" if index==2 else "p2_interact")
		if not world.keepsakes.collected[index] or not world.story.current.get("line","").begins_with("我的"):
			_fail("Route keepsake dialogue is not first person"); return
	await _clear_story()
	await _put(22.5,23.5)
	await _press_key(KEY_E,true)
	await _frames(24)
	await _clear_story()
	if not guide.cards[0].visible or guide.cards[1].visible: _fail("Valid worker has no compact progress or other player has an idle prompt"); return
	var bounds: Rect2=guide.cards[0].get_rect()
	if bounds.position.x<930 or bounds.end.x>1257 or bounds.end.y>699 or bounds.size.x>320 or bounds.size.y>80:
		_fail("Work progress is not compact / in the lower right"); return
	for label in [guide.names[0],guide.tasks[0]]:
		if not _fits(label): return
	_save_coop("clean-small-centered-work-progress")
	await _press_key(KEY_E,false)
	await _frames(5)
	if guide.cards[0].visible or guide.cards[1].visible: _fail("Released work leaves the deleted next-step panels"); return
	party.switch_to(1,1)
	bridge.step=2
	bridge.material_delivered=true
	bridge.timber_prepared=true
	bridge.get_node("MaterialCrate/Collision").set_deferred("disabled",true)
	await _put(29.6,30.5)
	await _press_key(KEY_UP,true)
	await _frames(70)
	var hit_pier: bool=false
	for index in range(second.get_slide_collision_count()):
		if second.get_slide_collision(index).get_collider().is_in_group("bridgehead_pier_barrier"): hit_pier=true
	if not hit_pier or second.global_position.z<-.07: _fail("Walking toward the stone pier still enters the masonry"); return
	await _press_key(KEY_KP_ENTER,true)
	await _frames(3)
	await _press_key(KEY_KP_ENTER,false)
	for frame in range(65):
		await _frames(1)
		if second.global_position.z<-.07: _fail("Jump bypasses the pier's rear boundary"); return
	await _press_key(KEY_UP,false)
	await _frames(20)
	if not second.is_on_floor() or second.global_position.y>.85: _fail("Character stands on the stone pier instead of the lane"); return
	await _clear_story()
	await _detail_view("clean-pier-solid-front",Vector3(30.5,3.0,7),Vector3(30.5,.8,-.5),6.1)
	await _put(29.6,30.5)
	await _press_key(KEY_P,true)
	await _frames(102)
	await _press_key(KEY_P,false)
	if bridge.step!=3: _fail("New pier blocker prevents the valid masonry task"); return
	party.switch_to(3,1)
	await _put(27,22.5)
	await _dual_hold(false,true)
	if not bridge.helpers_called: _fail("Actual Yang contact no longer brings the villagers"); return
	for frame in range(180):
		await _frames(1)
		for villager in [bridge._a_cai,bridge._a_qiang]:
			if villager.position.z<1.0: _fail("Incoming villager walks behind the cloth / stone pier"); return
	for villager in [bridge._a_cai,bridge._a_qiang]:
		if villager.position.x<8.9: _fail("Villager cannot reach the front of the supplies"); return
	await _put(29.6,30.5)
	await _clear_story()
	_save_coop("clean-idle-scene-without-route-or-panels")
	await _detail_view("clean-villagers-front-of-goods",Vector3(29.2,2.8,9),Vector3(29.2,1,-.2),7.4)
	bridge.bridge_ready=true
	bridge.step=5
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	await _frames(170)
	for villager in [bridge._a_cai,bridge._a_qiang]:
		if villager.position.z<.4 or villager.position.z>.7: _fail("Bearers leave the front bridge deck lane"); return
	await _near_key(KEY_H)
	var positions: Array[Vector3]=[bridge._a_cai.position,bridge._a_qiang.position]
	await _frames(12)
	if bridge._a_cai.position!=positions[0] or bridge._a_qiang.position!=positions[1] or guide.cards[0].visible: _fail("Pause does not freeze villagers / hide compact progress"); return
	await _near_key(KEY_ESCAPE)
	await _tap("restart_lesson")
	await _frames(10)
	if bridge.helpers_called or bridge._helpers.visible or get_nodes_in_group("bridgehead_pier_barrier").size()!=1: _fail("Reset duplicates blockers or leaves villagers behind"); return
	watchdog.timeout.disconnect(_timeout)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("CLEAN_HUD_PIER_OK: no route / next-step / direct-switch controls, centered lower-right active work only, no view-key receipts, actual mouse second-click return / socket and scaled viewport, four owner pickups speak first person, real pier walk / jump collision and task access, villagers approach / stop in front and remain on bridge deck, pause and reset")
	quit(0)


func _clear_story() -> void:
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	await _frames(3)


func _timeout() -> void:
	_fail("Clean UI / stone pier check timed out")
