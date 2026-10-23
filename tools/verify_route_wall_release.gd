extends "res://tools/verify_cooperative_experience.gd"

func _initialize() -> void:
	capture=true
	call_deferred("_run")

func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	capture_viewport=SubViewport.new()
	capture_viewport.size=Vector2i(1280,720)
	capture_viewport.own_world_3d=true
	capture_viewport.msaa_3d=Viewport.MSAA_4X
	capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
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
	world.start_creek_preview()
	bridge.step=1
	bridge.landscape.sync_state()
	world.story.queue.clear()
	world.story.remaining=0
	world.story.frame.visible=false
	await _put(26.8,27.4)
	await _frames(90)
	_clear_story()
	await _frames(4)
	var before: bool="--before" in OS.get_cmdline_user_args()
	var suffix: String="before" if before else "after"
	_save_coop("route-wall-"+suffix)
	# Use the real game camera for close visual inspection of the changed geometry.
	world.set_process(false)
	world.camera.size=6.3
	world.camera.position=Vector3(27.1,4,16)
	world.camera.look_at(Vector3(27.1,1.6,0),Vector3.UP)
	await _frames(5)
	_save_coop("route-wall-detail-"+suffix)
	if not before:
		var label: Label3D=bridge.landscape.stage_labels[2]
		var box: AABB=label.get_aabb()
		var bounds:=Rect2(world.camera.unproject_position(label.to_global(box.position)),Vector2.ZERO)
		for i in range(8): bounds=bounds.expand(world.camera.unproject_position(label.to_global(box.get_endpoint(i))))
		for card in nearby_ui.cards:
			if card.visible and card.get_rect().intersects(bounds):
				_fail("Interaction card covers the route title"); return
	world.set_process(true)
	await _put(19.6,20.2)
	await _frames(90)
	_clear_story()
	await _frames(4)
	_save_coop("gate-background-"+suffix)
	world.set_process(false)
	world.camera.size=6.0
	world.camera.position=Vector3(20.5,4,16)
	world.camera.look_at(Vector3(20.5,1.6,0),Vector3.UP)
	await _frames(5)
	_save_coop("gate-background-detail-"+suffix)
	if not before:
		var wall: Node3D=world.scene_details.route_surface
		var face: MeshInstance3D=wall.get_node("WeatheredRouteOutcrop")
		if face.mesh.get_faces().size()<1000 or wall.position.z> -2.3:
			_fail("Route face is still a flat foreground slab"); return
		var label: Label3D=bridge.landscape.stage_labels[2]
		if not label.no_depth_test or label.position.y<3.1:
			_fail("Route label is still subject to stone occlusion"); return
		if get_nodes_in_group("continuous_mountain_ridge").size()!=4:
			_fail("Background still uses overlapping chapter ridge panels"); return
		# Actual light-source sightline must pass in front of the route surface.
		var flame: MeshInstance3D=bridge.landscape.flames[1]
		if flame.global_position.z<=wall.global_position.z+face.get_aabb().end.z+.1:
			_fail("Left flame is still behind the route rock"); return
		world.set_process(true)
		await _put(27,27.5)
		party.switch_to(0,0)
		Input.action_press("interact")
		await _frames(110)
		Input.action_release("interact")
		if bridge.step<2: _fail("Rock art adjustment breaks the old-route interaction"); return
		print("ROUTE_WALL_RELEASE_OK: sculpted recessed route, unobscured label and left flame, four continuous mountain layers, original route task playable")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	quit(0)

func _clear_story() -> void:
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	world.story.frame.visible=false
