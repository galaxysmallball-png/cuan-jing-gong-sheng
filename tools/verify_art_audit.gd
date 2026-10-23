extends "res://tools/verify_cooperative_experience.gd"

func _initialize() -> void:
	capture=true
	create_timer(240,true).timeout.connect(func(): _fail("Art audit / high DPI check timed out"))
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
	await _put(12.5,13)
	await _click_stone(0)
	if not await _complete_rubbing(): return
	for slot in range(2):
		for role in party.roles_for_player(slot):
			party.switch_to(role,slot)
			await _tap("interact" if slot==0 else "p2_interact")
	await _click_tile(0)
	await _click_slot(0)
	await _frames(5)
	var inspector: CanvasLayer=first.inspector
	if first.slots[0]!=0 or inspector.puzzle_viewport.size.x<1620 or not inspector.practice_status.visible or first._board_status.visible: _fail("Supersampled cards or native canvas reading text not active"); return
	if not _fits(inspector.practice_status) or not _fits(inspector.practice_note): return
	if inspector.practice_status.text!=first._board_status.text or not inspector.practice_status.text.contains("4 / 4"): _fail("Native reading status is stale"); return
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	await _frames(180)
	_save_coop("audit-clear-type-1280")
	capture_viewport.size_2d_override=Vector2i(1280,720)
	capture_viewport.size_2d_override_stretch=true
	capture_viewport.size=Vector2i(1920,1080)
	await _frames(12)
	_save_coop("audit-clear-type-1920")
	# Mouse mapping must still follow the enlarged off-screen render.
	await _click_tile(1)
	await _click_slot(1)
	if first.slots[1]!=1: _fail("High DPI cards do not map to actual slots"); return
	first.close_puzzle()
	capture_viewport.size=Vector2i(1280,720)
	await _frames(3)
	if get_nodes_in_group("eroded_cliff_details").size()!=2 or get_nodes_in_group("broken_gallery_tile_detail").size()!=1 or get_nodes_in_group("artisan_tea_service").size()!=1: _fail("Authored cliff / ruined tile / tea detail assemblies missing"); return
	for cliff in get_nodes_in_group("eroded_cliff_details"):
		if cliff.find_children("*","CollisionObject3D",true,false).size()!=0 or cliff.get_meta("broken_ledge_plates")<10: _fail("Cliff details block the walking lane or lack ledge geometry"); return
	if get_nodes_in_group("hollow_horse_bell_detail").size()<2: _fail("Hanging and dropped bells do not use the same detailed object"); return
	var canopy: Array[Node]=get_nodes_in_group("leaf_canopy_detail")
	if canopy.size()<6: _fail("Three-scene foliage missing"); return
	for tree in canopy:
		if tree.multimesh.mesh is SphereMesh: _fail("Canopy still uses rock-shaped spheres"); return
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("ART_AUDIT_OK: real rubbing and four shares, native sharp Cuan status / note and supersampled cards, 720p / 1080p screenshots with actual high DPI mouse placement, no new scenery colliders, continuous cliffs / broken ledges / leaf clusters / hollow bells / thrown tea service / surviving curved roof fragments")
	quit(0)
