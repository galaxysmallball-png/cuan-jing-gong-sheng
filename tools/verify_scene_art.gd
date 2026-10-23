extends "res://tools/verify_stone_roof.gd"

var baseline: bool = false


func _initialize() -> void:
	capture = true
	baseline = "--baseline-scene-art" in OS.get_cmdline_user_args()
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE", ProjectSettings.globalize_path("res://previews/scene-art-test-profile.json"))
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_MINIMIZED
	OS.low_processor_usage_mode = false
	capture_viewport = SubViewport.new()
	capture_viewport.size = Vector2i(1280,720)
	capture_viewport.own_world_3d = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(capture_viewport)
	world = load("res://scenes/world.tscn").instantiate()
	capture_viewport.add_child(world)
	party = world.party
	player = party.player
	second = party.second_player
	first = world.cooperation
	bridge = world.bridge
	court = world.courtyard
	ui = world.get_node("PartyUI")
	nearby_ui = world.get_node("NearbyInteractions")
	await _frames(15)
	await _start_default_party()
	await _put(11.7,12.5)
	_clean_frame()
	await _frames(10)
	_shot("01-stele-court")
	world.start_creek_preview()
	bridge.bridge_ready = true
	bridge.gap_stabilized = true
	bridge.step = 6
	bridge.get_node("BridgeAssembly").visible = true
	bridge.get_node("BridgeAssembly").rotation.z = 0
	bridge.get_node("BridgeBody/Collision").disabled = false
	await _put(32.2,33.4)
	_clean_frame()
	await _frames(10)
	_shot("02-moonlit-creek")
	world.start_garden_preview()
	await _frames(210)
	await _put(49.6,50.6)
	court.tablet_placed = true
	court._tablet.visible = true
	court._tablet.position = Vector3(10,1.5,-2.35)
	court._tablet.rotation.z = 0
	court.items_done.fill(true)
	court.lamp_count = 7
	court.court_lit = true
	court.landscape.sync_state()
	# Complete the actual joint chooser before capturing the completed courtyard;
	# otherwise the automatic modal pauses the scene behind the hidden HUD.
	world.experience.visible=true
	await _frames(3)
	if world.experience.overlay.visible:
		for slot in range(2):
			await _click_at(world.experience.choice_buttons[slot][1-slot].get_global_rect().get_center())
			await _click_at(world.experience.confirm_buttons[slot].get_global_rect().get_center())
	if paused: _fail("Completed-court capture remained paused behind a modal"); return
	_clean_frame()
	await _frames(20)
	_shot("03-lantern-court")
	if not baseline:
		var polish: Node3D = world.get_node("SceneArtPolish")
		if polish.find_children("*","CollisionObject3D",true,false).size()!=0:
			_fail("Visual decorations added collision to the established walkways"); return
		if polish.batches.size()>26 or polish.source_parts<700:
			_fail("Scenery detail lacks merged geometry or exceeds its draw budget"); return
		if polish.glows.size()!=12 or get_nodes_in_group("eave_lantern_bays").size()!=9:
			_fail("Lamp atmosphere changed the existing nine architectural lantern groups"); return
		for glow in polish.glows:
			if glow.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				_fail("Soft lamp glow casts opaque quad shadows"); return
		print("SCENE_ART_BUDGET: ",polish.source_parts," authored parts / ",polish.batches.size()," static batches / ",polish.glows.size()," lamp aureoles")
		ui.visible = true
		world.get_node("Guide").visible = true
		nearby_ui.visible = true
		world.experience.visible = true
		court.landscape.canvas.visible=true
		await _frames(4)
		_shot("04-play-interface")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("SCENE_ART_BASELINE_OK" if baseline else "SCENE_ART_OK: three real-GPU views, merged native detail, no decoration colliders, nine existing lantern bays, soft shadow-free light")
	quit(0)


func _clean_frame() -> void:
	world.story.queue.clear()
	world.story.current = {}
	ui.visible = false
	world.get_node("Guide").visible = false
	nearby_ui.visible = false
	world.experience.visible = false
	court.landscape.canvas.visible = false
	court.landscape.dialogue_left=0
	court.landscape.dialogue.visible=false


func _shot(label: String) -> void:
	_save_coop(("art-before-" if baseline else "art-after-")+label)
