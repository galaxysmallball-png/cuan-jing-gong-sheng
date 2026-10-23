extends "res://tools/verify_cooperative_experience.gd"


func _initialize() -> void:
	capture=true
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
	await _put(5.5,6.2)
	await _frames(20)
	var old_y: float=second.global_position.y
	await _press_key(KEY_CTRL,true,KEY_LOCATION_RIGHT)
	await _frames(8)
	await _press_key(KEY_CTRL,false,KEY_LOCATION_RIGHT)
	if second.global_position.y>old_y+.03: _fail("Right Ctrl still jumps"); return
	await _press_key(KEY_KP_ENTER,true)
	await _frames(8)
	await _press_key(KEY_KP_ENTER,false)
	if second.global_position.y<old_y+.18: _fail("Right-side keypad Enter cannot jump"); return
	await _frames(60)
	await _put(12.5,13)
	await _click_stone(1)
	var lore: Control=first.inspector.lore
	await _click_at(lore.start.get_global_rect().get_center())
	for answer in [1,0,2]: await _click_at(lore.choices[answer].get_global_rect().get_center())
	await _frames(3)
	if not first.comparison_complete or true in first.clues or first.gate_open: _fail("Big-stele reading replaces role clues"); return
	if lore.NOTE.contains("晋、故") or lore.NOTE.contains("淡字") or not lore.NOTE.contains("纪年题签"):
		_fail("Big-stele reward repeats the small-stele answer"); return
	_save_coop("feedback-distinct-big-stele-reward")
	await _near_key(KEY_ESCAPE)
	await _click_stone(0)
	for index in range(6):
		if first._slot_labels[index].text!=str(index+1): _fail("Big stele reveals small-stele slot answers"); return
	await _near_key(KEY_ESCAPE)
	world.start_creek_preview()
	bridge.timber_prepared=true
	bridge.material_delivered=true
	bridge.step=2
	bridge.crate.position=Vector3(9.5,.5,-1.9)
	bridge.get_node("MaterialCrate/Collision").disabled=true
	party.switch_to(1,1)
	await _put(29.1,29.8)
	await _frames(15)
	if not bridge.landscape.repair_pier.is_visible_in_tree() or bridge.landscape.repair_blocks.size()!=7:
		_fail("Bridgehead repair target is still invisible before strengthening"); return
	var cap: MeshInstance3D=bridge.landscape.repair_blocks[-1]
	if cap.global_position.y<.7: _fail("Bridgehead cap is buried below the walkway"); return
	_save_coop("feedback-visible-broken-pier")
	await _put(29.7,30.5)
	Input.action_press("p2_interact")
	await _frames(48)
	if absf(cap.rotation.z)>=.14 or absf(cap.rotation.z)<.01: _fail("Pier has no intermediate repair pose"); return
	_save_coop("feedback-pier-repair-progress")
	await _frames(60)
	Input.action_release("p2_interact")
	await _frames(4)
	if bridge.step!=3 or absf(cap.rotation.z)>.001: _fail("Actual stoneworker hold does not strengthen the visible pier"); return
	party.switch_to(3,1)
	await _put(22.9,22.5)
	await _dual_hold(false,true)
	if not bridge.helpers_called: _fail("Cannot call A-Qiang through the actual task"); return
	await _frames(235)
	bridge.bridge_ready=true
	bridge.step=5
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	await _put(30.5,31.1)
	await _frames(100)
	var book: CanvasLayer=world.achievements
	ui._open_achievements()
	book.select_group("壮族")
	await _click_at(book.cards[0].get_global_rect().get_center())
	if not book.detail_locked.text.contains("肩上") or not _fits(book.detail_locked): _fail("Locked beam card lacks readable pickup instructions"); return
	_save_coop("feedback-zhuang-collection-directions")
	await _near_key(KEY_ESCAPE)
	var folk: CanvasLayer=world.folk
	for id in ["a_qiang_beam","a_qiang_knife"]:
		await _frames(5)
		if bridge._a_qiang.get_node("Character").current_state!="carry" or not nearby_ui._available(folk.items[id]):
			_fail("Carried beam remains unavailable in its visible pose"); return
		var target: Vector3=folk.picker_bodies[id].global_position
		await _click_at(world.camera.unproject_position(target))
		if not folk.overlay.visible or folk.active_id!=id or not book.collected.has(id):
			_save_coop("feedback-click-failure")
			var screen_at: Vector2=world.camera.unproject_position(folk.picker_bodies[id].global_position)
			var from: Vector3=world.camera.project_ray_origin(screen_at)
			var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+world.camera.project_ray_normal(screen_at)*100,8))
			_fail("Actual mouse click cannot collect A-Qiang's "+id+" active="+folk.active_id+" screen="+str(screen_at)+" blocked="+str(ui.blocks_world_click(screen_at))+" hit="+str(hit.get("collider"))); return
		_save_coop("feedback-collected-"+id)
		await _near_key(KEY_ESCAPE)
	world.click_interactions.last_person=""
	await _click_at(world.camera.unproject_position(bridge._a_qiang.global_position+Vector3(0,1.80,.12)))
	if world.click_interactions.last_person!="a_qiang" or folk.overlay.visible:
		_fail("Focused tool picking steals the NPC's face dialogue"); return
	world.start_garden_preview()
	await _frames(210)
	await _put(54.0,54.8)
	await _click_prop("shared_tea")
	await _click_at(folk.start_activity_button.get_global_rect().get_center())
	for id in ["shared_tea","tea_jar","fire_basin","yu_nan_brocade","garden_item_2"]:
		if id!="shared_tea":
			folk.board.begin_profile(folk.Activities.for_item(id),world.sfx)
			folk.board.start()
		while folk.board.playing_demo:
			await _frames(1)
			if folk.board.lit>=0: _fail("Listening demonstration highlights the answer instrument"); return
		if folk.board.message.contains(folk.board._sequence_text()) or folk.board.message.contains("→"):
			_fail("Listening text still prints its answer"); return
		if id=="shared_tea":
			_save_coop("feedback-ear-only-listening")
			await _board_click(folk.board.option_position((folk.board.recipe[0]+1)%3))
			if folk.board.message.contains("上方提示"): _fail("Wrong listening reply suggests a hidden answer hint"); return
			await _click_at(folk.listen_button.get_global_rect().get_center())
			while folk.board.playing_demo: await _frames(1)
		for note in folk.board.recipe: await _board_click(folk.board.option_position(note))
		if not folk.board.won: _fail("Ear-only listening activity cannot still be completed"); return
	await _near_key(KEY_ESCAPE)
	await _put(49.6,50.6)
	court.tablet_placed=true
	court._tablet.rotation.z=0
	court.items_done.fill(true)
	court.lamp_count=7
	await _frames(4)
	await _complete_shared_design()
	court._finish_court()
	await _frames(180)
	var art: Node3D=court.landscape
	if art.world_scroll_paper.material_override.albedo_texture!=art.SCROLL_COVER or not art.chronicle_label.visible:
		_fail("World scroll is missing the supplied cover or its independent chronology reward"); return
	var colors: Array[Color]=[]
	for index in [0,60,120,180]: colors.append(world.festival.grand.celebration.multimesh.get_instance_color(index))
	if colors[0].is_equal_approx(colors[1]) or colors[1].is_equal_approx(colors[2]) or colors[2].is_equal_approx(colors[3]):
		_fail("Background fireworks still share one colour"); return
	for layer in [ui,nearby_ui,world.experience,world.achievements,world.story]: layer.visible=false
	world.get_node("Guide").visible=false
	art.canvas.visible=false
	world.story.queue.clear()
	world.story.current={}
	await _frames(3)
	_save_coop("feedback-multicolour-finale")
	var camera_transform: Transform3D=world.camera.transform
	var old_size: float=world.camera.size
	world.set_process(false)
	world.camera.global_position=Vector3(56.8,3.2,9)
	world.camera.look_at(Vector3(56.8,2.2,-1.4))
	world.camera.size=4.0
	await _frames(3)
	_save_coop("feedback-ornate-world-scroll")
	world.camera.transform=camera_transform
	world.camera.size=old_size
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("FEEDBACK_POLISH_OK: keypad Enter physical jump / Ctrl removed, independent two-stele chronology / no glyph answers, visible repair target and intermediate masonry, actual carried beam / knife mouse collection and directions, five ear-only activities without answer text or flashing, supplied world-scroll cover and chronology tag, four simultaneous spark colours")
	quit(0)
