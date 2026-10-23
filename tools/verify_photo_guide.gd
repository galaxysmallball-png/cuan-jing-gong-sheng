extends "res://tools/verify_grand_court.gd"


func _initialize() -> void:
	capture = "--capture-photo-guide" in OS.get_cmdline_user_args()
	create_timer(180,true).timeout.connect(func(): _fail("Photo and guidance check timed out"))
	call_deferred("_run")


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
	await _frames(20)
	await _start_default_party()
	await _put(13.5,13)
	await _click_stone(1)
	await _frames(3)
	if not first.inspector.stage_guide.text.contains("选看") or first.puzzle_active: _fail("Large stele is still confused with main puzzle"); return
	await _near_key(KEY_ESCAPE)
	await _click_stone(0)
	await _frames(3)
	if not first.inspector.stage_guide.text.contains("②") or not world.objective().text.contains("四人交流"): _fail("First-level guidance lacks current stage"); return
	if ui.goal_panel.visible: _fail("Redundant objective covers first-level portrait dialogue"); return
	_save_coop("photo-guide-first-start")
	await _mouse_hold(first.inspector.share_buttons[0],true)
	Input.action_press("p2_interact")
	await _frames(110)
	await _mouse_hold(first.inspector.share_buttons[0],false)
	Input.action_release("p2_interact")
	await _frames(3)
	if first.step!=2 or not first.clues[0] or not first.clues[1]: _fail("Mouse hold and 2P key do not share clues independently"); return
	await _click_at(first.inspector.cycle_buttons[0].get_global_rect().get_center())
	await _click_at(first.inspector.cycle_buttons[1].get_global_rect().get_center())
	if party.active_id!=2 or party.second_id!=3: _fail("New per-player switch buttons do not respect owned roles"); return
	await _mouse_hold(first.inspector.share_buttons[1],true)
	Input.action_press("interact")
	await _frames(110)
	await _mouse_hold(first.inspector.share_buttons[1],false)
	Input.action_release("interact")
	await _frames(4)
	if first.step!=4 or not first.inspector.stage_guide.text.contains("③"): _fail("Four clues do not guide the transition to placing"); return
	var guide: Label = first.inspector.stage_guide
	if guide.get_theme_font("font").get_string_size(guide.text,HORIZONTAL_ALIGNMENT_LEFT,-1,guide.get_theme_font_size("font_size")).x > guide.size.x:
		_fail("First-level action guide clips horizontally"); return
	for label in first.inspector.clue_headers:
		if label.get_line_count()>label.get_visible_line_count(): _fail("Player clue header clips"); return
	if world.story.frame.get_rect().intersects(first.inspector.share_buttons[0].get_parent().get_rect()):
		_fail("Portrait dialogue covers player clue controls"); return
	_save_coop("photo-guide-first-clues-ready")
	for id in range(6): first.select_tile(id); first.place_selected(id)
	if first.observed or not first.feedback.contains("方向") or not first.feedback.contains("2"):
		_fail("Wrong orientation has no specific correction"); return
	await _frames(4)
	_save_coop("photo-guide-first-correction")
	for id in range(6):
		first.select_tile(id)
		while first.turns[id]!=0: first.rotate_selected()
		first.place_selected(id)
	await _frames(125)
	if not first.gate_open or first.puzzle_active or player.interaction_locked: _fail("Improved first-level flow does not open the gate"); return
	var checked: int = 0
	for stage in range(3):
		if stage==1:
			world.start_creek_preview()
			bridge.step = 4
			bridge.helpers_called = true
			bridge._helpers.visible = true
		elif stage==2:
			world.start_garden_preview()
			court.tablet_placed = true
			for i in range(4): court.items_done[i]=true
			court.lamp_count = 4
			court.landscape.sync_state()
		await _frames(40)
		for id in world.folk.items:
			if world.folk.items[id].chapter!=stage: continue
			world.folk.open_item(id)
			await _frames(3)
			if world.folk.active_id!=id or not world.folk.reference_button.visible:
				_fail("No photo toggle for cultural object: "+id); return
			await _click_at(world.folk.reference_button.get_global_rect().get_center())
			await _frames(2)
			if not world.folk.reference_image.visible or world.folk.reference_image.texture==null or world.folk.preview_area.visible:
				_fail("Real photograph does not replace 3D: "+id); return
			if not world.folk.reference_credit.text.contains("来源") or not world.folk.reference_credit.text.contains("授权"):
				_fail("Photo lacks attribution and source: "+id); return
			if world.folk.reference_credit.get_line_count()>world.folk.reference_credit.get_visible_line_count():
				_fail("Photo attribution clips: "+id+" "+str(world.folk.reference_credit.get_line_count())+"/"+str(world.folk.reference_credit.get_visible_line_count())); return
			if id in ["bai_tiedye","miao_batik","dai_brocade","cloth_loom","garden_item_2","donkey","baby_carrier"]: _save_coop("photo-guide-object-"+id)
			if world.folk.next_reference.visible:
				var previous: Texture2D = world.folk.reference_image.texture
				await _click_at(world.folk.next_reference.get_global_rect().get_center())
				if world.folk.reference_index!=1 or world.folk.reference_image.texture==previous: _fail("Multi-photo item does not turn: "+id); return
			await _click_at(world.folk.reference_button.get_global_rect().get_center())
			if world.folk.reference_image.visible or not world.folk.preview_area.visible: _fail("Cannot return to 3D: "+id); return
			await _near_key(KEY_ESCAPE)
			checked+=1
	if checked!=21: _fail("Not all 21 cultural items were checked: "+str(checked)); return
	court.court_lit=true
	var records: Array[String] = ["checked"]
	court.show_record(records)
	await _frames(4)
	if not court.landscape.record_cover_open or not court.landscape.record_cover.visible or court.landscape.record_cover.texture!=court.landscape.SCROLL_COVER:
		_fail("Supplied new scroll cover is absent"); return
	_save_coop("photo-guide-scroll-cover")
	await _near_key(KEY_ENTER)
	if court.landscape.record_cover_open or court.landscape.record_page!=0: _fail("Cover skips the first mural"); return
	for page in range(4):
		if court.landscape.record_page!=page or court.landscape.record_art.texture!=court.landscape.SCROLL_IMAGES[page]:
			_fail("New cover loses original mural "+str(page)); return
		if page<3: await _near_key(KEY_RIGHT)
	_save_coop("photo-guide-scroll-final-mural")
	await _near_key(KEY_ESCAPE)
	await _put(35,36)
	await _frames(5)
	var fall: MeshInstance3D = world.scene_atmosphere.waterfall
	if not fall.mesh is ArrayMesh or fall.get_meta("bottom_width")<fall.get_meta("top_width")*5:
		_fail("Waterfall is not a narrow-to-wide mesh"); return
	world.story.current={}
	world.story.queue.clear()
	await _frames(3)
	_save_coop("photo-guide-tapered-waterfall")
	print("PHOTO_GUIDE_OK: staged first-level goal, optional large stele, actual mouse holds and independent owned-role buttons, specific rotation correction and successful gate, all 21 objects toggle bundled attributed photos and back to 3D, multi-photo switching, supplied scroll cover and all four original murals, tapered waterfall mesh")
	quit(0)


func _mouse_hold(button: Button, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.position=button.get_global_rect().get_center()
	event.pressed=down
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	world.get_viewport().push_input(event,true)
	await _frames(2)
