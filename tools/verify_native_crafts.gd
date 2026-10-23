extends "res://tools/verify_cooperative_experience.gd"

const Driver=preload("res://tools/native_craft_test_driver.gd")
var watchdog: SceneTreeTimer
var checkpoint: String="startup"


func _initialize() -> void:
	capture=true
	watchdog=create_timer(350,true)
	watchdog.timeout.connect(_timeout)
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
	var modes: Dictionary={}
	var finished: int=0
	for stage in range(3):
		if stage==1:
			world.start_creek_preview()
			bridge.helpers_called=true
			bridge.step=4
			bridge._helpers.visible=true
			bridge._a_cai.position=Vector3(9,0,1.1)
			bridge._a_qiang.position=Vector3(10,0,1.1)
		elif stage==2:
			world.start_garden_preview()
			await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
			court._raise_tablet()
			await _frames(ceili(court.RAISE_SECONDS*60)+8)
			world.experience.design_done=true
			for i in range(4): court.items_done[i]=true
			court.lamp_count=4
			court.landscape.sync_state()
		await _frames(20)
		for id in world.folk.items:
			if world.folk.items[id].chapter!=stage: continue
			checkpoint=id
			var folk: CanvasLayer=world.folk
			folk.open_item(id)
			await _frames(5)
			if not folk.overlay.visible or folk.active_id!=id or not folk.activity_story.visible: _fail("Missing item story: "+id); return
			if folk.play_again.text!="继续任务": _fail("Unfinished item incorrectly offers story replay: "+id); return
			if folk._meshes(folk.preview_model).is_empty() or folk._bounds(folk.preview_model).size.length()<.04: _fail("Focused object model is empty: "+id); return
			if folk.description_scroll.get_global_rect().end.y>=folk.board.get_global_rect().position.y or not folk.description_scroll.clip_contents:
				_fail("Object explanation is covered by the mini-game: "+id); return
			if folk.activity_story_body.get_line_count()>folk.activity_story_body.get_visible_line_count(): _fail("Per-character craft story clips: "+id); return
			if folk.photo_catalog.items[id].is_empty(): _fail("Object lost its real photo reference: "+id); return
			await _click_at(folk.start_activity_button.get_global_rect().get_center())
			var board: Control=folk.board
			var progress_native: RefCounted=board.native
			await _click_at(folk.play_again.get_global_rect().get_center())
			if not board.running or folk.activity_story.visible or board.native!=progress_native or folk.play_again.text!="继续任务": _fail("Continue resets the unfinished activity: "+id); return
			modes[board.mode]=true
			var clues: Array=first.clues.duplicate()
			var lights: int=court.lamp_count
			if board.mode>=4:
				for wrong in range(5): board.choose(wrong)
				if board.won or board.answered!=0: _fail("Old numbered sequence bypasses a spatial craft: "+id); return
				if id=="miao_batik":
					await Driver.drag_path(self,board,[Vector2(85,125),Vector2(170,200)])
					if board.native.phase!=0: _fail("Wax tracing accepts an off-outline shortcut"); return
				if id in ["bai_tiedye","miao_batik","a_cai_hoe","a_cai_basket","baby_carrier","a_qiang_beam","shared_tea","fire_basin","garden_item_3"]: _save_coop("native-craft-start-"+id)
			if not await Driver.complete(self,board): _fail("Actual mouse craft cannot complete: "+id+" / "+board.message+" phase="+str(board.native.phase if board.native else -1)); return
			await _frames(10)
			finished+=1
			if not folk.completed_items.has(id) or first.clues!=clues or court.lamp_count!=lights: _fail("Optional craft loses record or modifies main tasks: "+id); return
			if folk.play_again.text!="重听故事": _fail("Completed item does not offer story replay: "+id); return
			if id in ["bai_tiedye","miao_batik","dai_brocade","a_cai_hoe","a_qiang_beam","garden_item_3"]: _save_coop("native-craft-finished-"+id)
			await _click_at(folk.play_again.get_global_rect().get_center())
			if board.running or board.won or not folk.activity_story.visible: _fail("Retry retains a craft's completed state: "+id); return
			await _near_key(KEY_ESCAPE)
	if finished!=21 or modes.size()!=12: _fail("New crafts still reuse the same four mechanisms"); return
	checkpoint="Dispersed court prop locators"
	await _clear_story()
	for id in ["tea_jar","fire_basin","flint_pouch"]:
		var anchor: Node3D=world.folk.items[id].anchor
		await _put(anchor.global_position.x-1.2,anchor.global_position.x-.6)
		await _clear_story()
		ui._open_achievements()
		var book: CanvasLayer=world.achievements
		book.select_group("彝族")
		book.selected_id=id
		book._show_item()
		await _frames(4)
		if not book.locate_button.visible or book.locate_button.tooltip_text.contains("身边") or book.locate_button.tooltip_text.contains("随身") or not anchor.has_meta("standalone_artifact"): _fail("Dispersed prop retains the old hidden-on-person location"); return
		await _click_at(book.locate_button.get_global_rect().get_center())
		await _frames(5)
		var target: Node3D=world.folk.picker_bodies[id].get_child(0)
		await _click_at(world.camera.unproject_position(target.global_position))
		await _frames(4)
		if world.folk.active_id!=id: _fail("Actual Pu Mo prop cannot be selected: "+id+" got="+world.folk.active_id); return
		_save_coop("native-pumo-click-"+id)
		await _near_key(KEY_ESCAPE)
	checkpoint="courtyard guest props"
	for id in ["a_cai_hoe","a_cai_basket","baby_carrier","a_qiang_knife","a_qiang_beam"]:
		var entry: Dictionary=world.folk.court_aliases[id]
		await _put(entry.anchor.global_position.x-.35,entry.anchor.global_position.x+.35)
		await _frames(5)
		var target: Node3D=world.folk.picker_bodies[id+"@court"].get_child(0)
		await _click_at(world.camera.unproject_position(target.global_position))
		await _frames(5)
		if world.folk.active_id!=id or not world.folk.overlay.visible or world.folk.items.size()!=21 or world.folk.active_entry(id).anchor!=entry.anchor:
			_fail("Courtyard guest prop cannot use the same 21-item collection: "+id); return
		_save_coop("native-court-guest-"+id)
		await _near_key(KEY_ESCAPE)
	# The three missing Miao props are separately located and physically clickable.
	bridge.reset_lesson()
	court.reset_lesson()
	world.start_creek_preview()
	bridge.helpers_called=true
	bridge.step=4
	bridge._helpers.visible=true
	bridge._a_cai.position=Vector3(9,0,1.1)
	bridge._a_qiang.position=Vector3(10,0,1.1)
	await _put(29.6,30.5)
	await _clear_story()
	for id in ["a_cai_hoe","a_cai_basket","baby_carrier"]:
		world.achievements.collected.erase(id)
		ui._open_achievements()
		var book: CanvasLayer=world.achievements
		book.select_group("苗族")
		book.selected_id=id
		book._show_item()
		await _frames(4)
		if not book.detail_locked.text.contains("阿彩") or not book.detail_locked.text.contains("点") or not book.locate_button.visible:
			_fail("Missing Miao object has no exact landmark / locator: "+id); return
		_save_coop("native-locate-"+id)
		await _click_at(book.locate_button.get_global_rect().get_center())
		await _frames(5)
		if paused or ui.screen!=ui.Screen.GAME or world.folk.marked_id!=id or book.collected.has(id): _fail("Locator claims collection / fails to return to play"); return
		var collider: Node3D=world.folk.picker_bodies[id].get_child(0)
		await _click_at(world.camera.unproject_position(collider.global_position))
		await _frames(5)
		if world.folk.active_id!=id or not world.folk.overlay.visible or not book.collected.has(id):
			_fail("Actual separate Miao prop click fails: "+id+" got "+world.folk.active_id+" pos="+str(world.camera.unproject_position(collider.global_position))+" selected="+world.folk.attached_at(world.camera.unproject_position(collider.global_position))); return
		await _near_key(KEY_ESCAPE)
	# During carrying, the hoe is visibly put beside her, keeping its picker valid.
	bridge.bridge_ready=true
	bridge.step=5
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	await _frames(40)
	var model: Node3D=bridge._a_cai.get_node("Character")
	if model.current_state!="carry" or not model.hoe_detail.is_visible_in_tree() or not nearby_ui._available(world.folk.items.a_cai_hoe): _fail("Hoe disappears permanently when villagers lift"); return
	await _detail_view("native-forged-hoe-and-separated-props",Vector3(29.6,2.9,8),Vector3(29.6,1.2,.9),5.1)
	await _click_at(world.camera.unproject_position(world.folk.picker_bodies.a_cai_hoe.get_child(0).global_position))
	if world.folk.active_id!="a_cai_hoe": _fail("Parked hoe cannot be clicked during transport"); return
	await _near_key(KEY_ESCAPE)
	await _tap("restart_lesson")
	await _frames(8)
	if not world.folk.marked_id.is_empty() or not world.achievements.collected.is_empty(): _fail("New journey retains locator / achievements"); return
	watchdog.timeout.disconnect(_timeout)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("NATIVE_CRAFTS_OK: all 21 story-gated activities completed with actual mouse input across 12 distinct mechanisms; tied resist / wax trace with rejected shortcut / terrace water routing / alternating weaving / safe carrier tension / rotated joinery / controlled tea pouring / crossed knot / spark-air-fire sharing, ear-only music and unequal cargo retained, photos and main-task isolation / replay, clipped scroll-safe explanation, exact Miao locations and actual separate hoe / basket / carrier clicks, visible forged hoe stow and picker / new journey cleanup")
	quit(0)


func _clear_story() -> void:
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	await _frames(3)


func _timeout() -> void:
	_fail("Native craft check timed out at "+checkpoint)
