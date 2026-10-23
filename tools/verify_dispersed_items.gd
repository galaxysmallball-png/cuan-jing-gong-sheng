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
	await _put(21,21.8)
	await _quiet()
	_save_coop("dispersed-caravan-world")
	await _click_prop("caravan_pack")
	if world.folk.active_id!="caravan_pack": _fail("Caravan pack is no longer clickable at the creek entrance"); return
	world.folk.close()
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	var pu_mo: Node3D=court.get_node("Residents/ResidentA/Character")
	var old_props: Node3D=preload("res://scripts/skinned_prop_mesh.gd").extract(pu_mo,["teapot","firepan","pouch"])
	if old_props.get_child_count()!=0: _fail("Legacy tiny props still remain on Pu Mo"); return
	old_props.free()
	var positions: Array[Vector3]=[]
	for id in ["fire_basin","tea_jar","flint_pouch"]:
		var entry: Dictionary=world.folk.items[id]
		if not entry.anchor.has_meta("standalone_artifact") or not entry.anchor.find_children("*","Label3D",true,false).is_empty():
			_fail("Small artifact retains an automatic visible name"); return
		for other in positions:
			if entry.anchor.global_position.distance_to(other)<3.5: _fail("Artifacts are still clustered"); return
		positions.append(entry.anchor.global_position)
		await _put(entry.anchor.global_position.x-1.3,entry.anchor.global_position.x-.6)
		await _quiet()
		_save_coop("dispersed-"+id+"-world")
		# Click its real enlarged mesh hit area, with a regular live game camera.
		var body: Node3D=world.folk.picker_bodies[id]
		var screen: Vector2=world.camera.unproject_position(body.global_position)
		if not Rect2(Vector2.ZERO,Vector2(1280,720)).has_point(screen): _fail("Artifact lies outside the real camera: "+id); return
		await _click_at(screen)
		await _frames(4)
		if world.folk.active_id!=id or not world.achievements.collected.has(id): _fail("Visible artifact click misses: "+id); return
		var count: int=world.folk._meshes(world.folk.preview_model).size()
		if count==0 or world.folk._bounds(world.folk.preview_model).size.y<.30: _fail("Isolated artifact preview is missing: "+id); return
		world.folk.close()
		ui._open_achievements()
		var book: CanvasLayer=world.achievements
		book.select_group("彝族")
		book.selected_id=id
		book._show_item()
		if book.locate_button.tooltip_text.contains("身边") or book.locate_button.tooltip_text.contains("随身"):
			_fail("Collection location still points at Pu Mo's body"); return
		await _click_at(book.locate_button.get_global_rect().get_center())
		await _frames(4)
		if world.folk.marked_id!=id or not world.folk.location_marker.visible: _fail("Artifact location marker is broken: "+id); return
		world.folk.marked_id=""
	if world.folk.items.size()!=21: _fail("Dispersing props changes the collection total"); return
	await _tap("restart_lesson")
	await _frames(5)
	if not world.achievements.collected.is_empty(): _fail("New journey retains collected artifact state"); return
	for i in range(3):
		var id: String=["fire_basin","tea_jar","flint_pouch"][i]
		if world.folk.items[id].anchor.global_position!=positions[i]: _fail("Reset loses the displayed artifact"); return
	print("DISPERSED_ITEMS_OK: three dispersed objects without idle labels, removed old on-person copies, true mouse picking and isolated models, updated collection landmarks and locator, 21 identities, reset safety; caravan pack retained at creek entrance")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	quit(0)

func _quiet() -> void:
	await _frames(20)
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	world.story.frame.visible=false
	await _frames(4)
