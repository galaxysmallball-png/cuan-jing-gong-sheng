extends "res://tools/verify_stone_roof.gd"


func _initialize() -> void:
	capture="--capture-lantern-bays" in OS.get_cmdline_user_args()
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",ProjectSettings.globalize_path("res://previews/lantern-bays-steles-profile.json"))
	create_timer(200,true).timeout.connect(func(): _fail("Lantern bays / two steles check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode=Window.MODE_MINIMIZED
		OS.low_processor_usage_mode=false
		capture_viewport=SubViewport.new()
		capture_viewport.size=Vector2i(1280,720)
		capture_viewport.own_world_3d=true
		capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d=Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene=world
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
	await _put(12.5,13)
	await _click_stone(1)
	var lore: Control = first.inspector.lore
	if not lore.visible or first.puzzle_active or not lore.body.text.contains("458"):
		_fail("Large stele does not open its own factual introduction"); return
	_save_coop("bays-large-stele-introduction")
	await _click_at(lore.tabs[0].get_global_rect().get_center())
	if not lore.body.text.contains("405") or not lore.body.text.contains("1778"):
		_fail("Small stele introduction missing date or provenance"); return
	_save_coop("bays-small-stele-introduction")
	await _click_at(lore.tabs[2].get_global_rect().get_center())
	await _click_at(lore.start.get_global_rect().get_center())
	await _click_at(lore.choices[0].get_global_rect().get_center())
	if first.comparison_complete or lore.question!=0: _fail("Wrong historical answer grants reward"); return
	_save_coop("bays-stele-question")
	for answer in [1,0,2]: await _click_at(lore.choices[answer].get_global_rect().get_center())
	await _frames(3)
	if not first.comparison_complete or first.clues.count(true)>0 or first.gate_open:
		_fail("Large stele reward is missing or auto-completes main clues"); return
	if not ui.satchel_notice.visible or ui.satchel_notice.horizontal_alignment!=HORIZONTAL_ALIGNMENT_CENTER or ui.satchel_notice_frame.size.x>570:
		_fail("Receipt is not compact and centered"); return
	for node in ui.get_children():
		if node is Button and node.text=="查看包裹 · B": _fail("Removed receipt button still exists"); return
	_save_coop("bays-centered-clue-receipt")
	await _near_key(KEY_B)
	await _click_at(ui.satchel.comparison_button.get_global_rect().get_center())
	if not paused or not ui.satchel.comparison_sheet.visible or not ui.satchel.comparison_text.text.contains("相隔53年"):
		_fail("New two-stele note cannot be reviewed in the parcel"); return
	_save_coop("bays-comparison-note")
	await _near_key(KEY_B)
	await _near_key(KEY_ESCAPE)
	await _click_stone(0)
	if first._slot_labels[0].text!="1" or not first.puzzle_active:
		_fail("Large stele still reveals the companions' small-stele answer"); return
	await _click_at(first.inspector.lore_button.get_global_rect().get_center())
	Input.action_press("interact")
	await _frames(110)
	Input.action_release("interact")
	if first.clues.count(true)>0: _fail("Reading small-stele lore leaks into held clue collection"); return
	await _click_at(first.inspector.lore_button.get_global_rect().get_center())
	await _dual_hold()
	party.switch_to(2,0)
	party.switch_to(3,1)
	await _dual_hold()
	for id in range(6):
		await _click_tile(id)
		for rotation in range(posmod(-first.turns[id],4)): await _near_key(KEY_Q)
		await _click_slot(id)
	await _frames(120)
	if not first.gate_open or not first.comparison_complete: _fail("Comparison reference breaks normal small-stele completion"); return
	await _near_key(KEY_ESCAPE)
	world.restart_current_scene()
	if first.comparison_complete: _fail("Restart leaves a stale two-stele reward"); return
	world.start_garden_preview()
	await _frames(210)
	await _put(49.5,51)
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	world.story.frame.visible=false
	await _frames(15)
	var bays: Array[Node] = get_nodes_in_group("eave_lantern_bays")
	if bays.size()!=9 or world.festival.lanterns.size()!=13 or world.festival.grand.sky_lanterns.size()!=8:
		_fail("Lanterns are not split among porch, gallery, gate and tower bays"); return
	for bay in bays:
		if bay.get_meta("beam_start").distance_to(bay.get_meta("beam_end"))>2.2:
			_fail("A lantern string still spans multiple buildings"); return
	_save_coop("bays-separated-lanterns-unlit")
	await _detail_view("bays-dark-footing",Vector3(51,-.4,13),Vector3(51,-1.8,3.7),15)
	party.switch_to(1,1)
	await _put(50.3,49.7)
	await _dual_hold()
	await _frames(180)
	if not court.tablet_placed: _fail("Art check cannot raise the delivered stele"); return
	court.items_done.fill(true)
	court.lamp_count=7
	court.court_lit=true
	court.landscape.sync_state()
	await _frames(30)
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	world.story.frame.visible=false
	_save_coop("bays-separated-lanterns-lit")
	await _detail_view("bays-roof-structure",Vector3(50,5.8,9),Vector3(50,4.9,-4),23)
	print("LANTERN_BAYS_STELES_OK: nine short beam/eave-mounted lantern groups with open roof/plaque gaps, dark descending rock foundations, factual large/small stele tabs, real mouse three-question comparison with wrong-answer protection, earned parcel note and small-stele reference without main-task bypass, compact centered receipt with no side button, B review, lore hold isolation and restart cleanup")
	quit(0)
