extends "res://tools/inspect_scene_art.gd"

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
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	await _detail_view("stele-thickness-flat",Vector3(50,2.7,5.8),Vector3(50,1.25,-1.8),5)
	court._raise_tablet()
	await _frames(ceili(court.RAISE_SECONDS*60)+8)
	var before: bool="--before" in OS.get_cmdline_user_args()
	var tag: String="edge-before" if before else "edge-after"
	await _detail_view(tag+"-garden",Vector3(50,5.2,14),Vector3(50,2.4,-2),23)
	await _detail_view(tag+"-right",Vector3(59.8,3.2,12),Vector3(59.8,.7,-1),7)
	if not before:
		if court._tablet.mesh.get_aabb().size.z<.4:
			_fail("Carried stele has insufficient stone thickness"); return
		await _detail_view("stele-thickness-standing",Vector3(52.4,3,3.5),Vector3(50,1.8,-2.35),4.8)
		var edge: Node3D=court.landscape.get_node("CourtyardRightReturn")
		if edge.find_children("*","CollisionObject3D",true,false).size()!=0:
			_fail("Visual courtyard continuation introduces a gameplay collider"); return
		if edge.get_node("ContinuousDeck").get_aabb().size.x<6 or get_nodes_in_group("layered_bank_details").size()!=4:
			_fail("Courtyard deck or joined foundation is incomplete"); return
		# Use the game's normal maximum camera position as well as the audit view.
		player.global_position=Vector3(58,.8,0)
		second.global_position=Vector3(58.6,.8,0)
		await _frames(90)
		await _save_coop("edge-after-game-camera")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("COURTYARD_EDGE_OK "+tag)
	quit(0)
