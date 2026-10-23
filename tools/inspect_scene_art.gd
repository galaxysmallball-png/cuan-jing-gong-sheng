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
	await _frames(12)
	await _start_default_party()
	var tag: String="before-audit" if "--before" in OS.get_cmdline_user_args() else "after-audit"
	await _detail_view(tag+"-court",Vector3(10,4.5,14),Vector3(10,2,-2),22)
	await _detail_view(tag+"-court-left-rocks",Vector3(1,3.8,11),Vector3(1,2.8,-5),7)
	world.start_creek_preview()
	await _frames(8)
	await _detail_view(tag+"-creek",Vector3(30,4.8,14),Vector3(30,1.2,-2),23)
	await _detail_view(tag+"-creek-cliffs",Vector3(24.5,4.2,10),Vector3(24.5,2.7,-6),8)
	await _detail_view(tag+"-worksite",Vector3(24.5,2.4,8),Vector3(24.5,.65,-1),7)
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	court._raise_tablet()
	await _frames(ceili(court.RAISE_SECONDS*60)+8)
	await _detail_view(tag+"-garden",Vector3(50,5.2,14),Vector3(50,2.4,-2),23)
	await _detail_view(tag+"-garden-tea",Vector3(54.2,2.3,6),Vector3(54.2,.8,-1.3),4.8)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("SCENE_ART_INSPECTION_OK "+tag)
	quit(0)
