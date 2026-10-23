extends "res://tools/verify_cooperative_experience.gd"

var watchdog: SceneTreeTimer

func _initialize() -> void:
	capture=true
	watchdog=create_timer(240,true)
	watchdog.timeout.connect(func(): _fail("Twin steles/art check timed out"))
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
	world.chapter_films.enabled=false
	party=world.party
	player=party.player
	second=party.second_player
	first=world.cooperation
	bridge=world.bridge
	court=world.courtyard
	ui=world.get_node("PartyUI")
	nearby_ui=world.get_node("NearbyInteractions")
	await _frames(15)
	await _tap("ui_accept")
	await _tap("skip_intro")
	var draw: Control=ui.opening_draw
	await _opening_audio_frames(20)
	if not paused or world.sfx.events.count("opening_card_flip")<2 or world.sfx.draw_spin.playing:
		_fail("Original opening flip sequence is missing or new continuous effect is still playing"); return
	var flips: int=world.sfx.events.count("opening_card_flip")
	await _opening_audio_frames(100)
	if world.sfx.events.count("opening_card_flip")<=flips:
		_fail("Card crossings do not trigger original flips"); return
	world.sfx.toggle_mute()
	flips=world.sfx.events.count("opening_card_flip")
	await _opening_audio_frames(15)
	if world.sfx.events.count("opening_card_flip")!=flips:
		_fail("Original opening sounds ignore mute"); return
	world.sfx.toggle_mute()
	draw.reveal_now()
	await _frames(2)
	if world.sfx.draw_spin.playing or not "opening_card_pick" in world.sfx.events:
		_fail("Skipping does not finish with original card pick"); return
	draw.replay()
	await _opening_audio_frames(20)
	if world.sfx.events.count("opening_card_flip")<=flips or world.sfx.draw_spin.playing:
		_fail("Replay does not restore original opening flips"); return
	draw.reveal_now()
	await _tap("ui_accept")
	party.reset_positions(true)
	await _frames(5)
	await _put(12.5,13)
	await _click_stone(0)
	if first.inspector.background_paper.texture.resource_path!="res://assets/interface/parcel_paper.png": _fail("Stele background is not the supplied paper"); return
	_save_coop("twin-paper-rubbing")
	if not await _complete_rubbing(): return
	for slot in range(2):
		for role in party.roles_for_player(slot):
			party.switch_to(role,slot)
			await _tap("interact" if slot==0 else "p2_interact")
	for id in range(6):
		await _click_tile(id)
		for turn in range(posmod(-first.turns[id],4)): await _key(KEY_Q)
		await _click_slot(id)
	if first.observed or first.gate_open or first.slots!=[0,1,2,3,4,5] or not first.feedback.contains("大爨"): _fail("Small stele still bypasses the large stele"); return
	_save_coop("twin-paper-small-waits-for-large")
	await _click_at(first.inspector.lore_button.get_global_rect().get_center())
	await _click_at(first.inspector.lore.start.get_global_rect().get_center())
	if first.inspector.lore.active or first.comparison_complete: _fail("Small stele can grant large-stele seal"); return
	first.close_puzzle()
	await _frames(2)
	await _click_stone(1)
	if not _fits(first.inspector.lore.body) or not _fits(first.inspector.stage_guide): return
	_save_coop("twin-paper-large-introduction")
	await _click_at(first.inspector.lore.start.get_global_rect().get_center())
	await _click_at(first.inspector.lore.choices[0].get_global_rect().get_center())
	if first.inspector.lore.question!=0 or first.comparison_complete: _fail("Incorrect large-stele answer grants progress"); return
	for answer in [1,0,2]: await _click_at(first.inspector.lore.choices[answer].get_global_rect().get_center())
	await _frames(125)
	if not first.gate_open or not first.observed or not first.large_stele_checked or first.clues.count(true)!=4: _fail("Actual large-stele quiz does not complete saved small-stele solution"); return
	await _tap("restart")
	if not first.comparison_complete or not first.large_stele_checked: _fail("Respawn loses the required seal"); return
	await _tap("restart_lesson")
	if first.comparison_complete or first.large_stele_checked or first.observed: _fail("New journey retains the seal"); return
	# Reverse order: large first may never replace rubbing or four human clues.
	await _put(12.5,13)
	await _click_stone(1)
	await _click_at(first.inspector.lore.start.get_global_rect().get_center())
	for answer in [1,0,2]: await _click_at(first.inspector.lore.choices[answer].get_global_rect().get_center())
	if first.observed or first.step!=0 or first.inspector.rubbing.completed: _fail("Large stele supplies small-stele clues or rubbing"); return
	first.close_puzzle()
	world.start_creek_preview()
	await _frames(10)
	await _detail_view("twin-old-bridge-stonework",Vector3(22.2,1.5,7),Vector3(22.4,.6,-1.4),4.5)
	await _detail_view("twin-bound-log-sled",Vector3(24.1,1.6,5),Vector3(24,.3,0),3.2)
	await _detail_view("twin-carved-rock-route",Vector3(27,1.9,7),Vector3(27,1.5,-1.4),4.0)
	await _detail_view("twin-natural-waterfall",Vector3(37.0,4.6,7),Vector3(37.0,4.0,-5.7),4.8)
	if world.scene_details.route_surface.get_node_or_null("WeatheredRouteOutcrop")==null or not world.scene_details.route_surface.get_node("WeatheredRouteOutcrop").get_meta("recessed_route",false): _fail("Route still uses a boxed plaque and raised rods"); return
	if world.scene_atmosphere.waterfall.get_meta("top_width")!=.18 or world.scene_atmosphere.waterfall.get_meta("left_drift")!=.95: _fail("Waterfall loses its tapered leftward shape"); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+10)
	var bottom: float=_tablet_bottom(court._tablet,Transform3D.IDENTITY)
	if bottom<.70 or absf(court._arrival_sled.position.y-court.FRAME_REST_Y)>.01: _fail("Flat stele still intersects the stepped plinth: "+str(bottom)); return
	await _detail_view("twin-flat-stele-clearance",Vector3(50,2.8,7),Vector3(50,1,-1.8),5.0)
	court._raise_tablet()
	for frame in range(ceili(court.RAISE_SECONDS*60)+4):
		await _frames(1)
		if _tablet_bottom(court._tablet,Transform3D.IDENTITY)<.64: _fail("Stele drops inside the steps during hoisting"); return
	if not court.tablet_placed: _fail("Stele never seats after the clearance fix"); return
	world.folk.open_item("shared_tea")
	await _frames(4)
	world.folk._start_activity()
	var tea: RefCounted=world.folk.board.native
	# The full 21-item test uses real input; these poses expose the new glaze / tea art.
	tea.phase=1
	tea.cups.assign([.52,.22,0.0])
	tea.refresh_hint()
	world.folk.board.queue_redraw()
	await _frames(4)
	_save_coop("twin-glazed-tea-cups")
	world.folk.close()
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("TWIN_STELES_ART_OK: supplied floral paper, dark ink, real small-only solution blocked, physical large-only seal quiz / wrong answer / both orders / R preservation / T reset, retained four clues and rubbing, original card crossing flips / pick / mute / skip / replay, rebuilt creek props and natural fissure, flat and all hoist-frame clearance")
	quit(0)

func _tablet_bottom(node: Node3D, relative: Transform3D) -> float:
	var next: Transform3D=relative*node.transform
	var value: float=(next*node.get_aabb()).position.y if node is MeshInstance3D else 100.0
	for child in node.get_children():
		if child is Node3D: value=minf(value,_tablet_bottom(child,next))
	return value


func _opening_audio_frames(count: int) -> void:
	for frame in range(count):
		await process_frame
		OS.delay_msec(18)
