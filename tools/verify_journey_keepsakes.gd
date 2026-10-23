extends "res://tools/verify_cooperative_experience.gd"

var legacy_path: String
var legacy_data: String='{"version":1,"collected":{"bai_tiedye":"2026-10-18"},"unlocked":{"first_meeting":"2026-10-18"}}'


func _initialize() -> void:
	capture=true
	legacy_path=ProjectSettings.globalize_path("res://previews/keepsakes-legacy-profile.json")
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",legacy_path)
	var file:=FileAccess.open(legacy_path,FileAccess.WRITE)
	file.store_string(legacy_data)
	file.close()
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
	_load_test_world()
	await _frames(15)
	var book: CanvasLayer=world.achievements
	if not book.collected.is_empty() or not book.unlocked.is_empty(): _fail("Fresh launch restored legacy achievements"); return
	await _start_default_party()
	var inventory: Node3D=world.keepsakes
	if inventory.collected.count(true)!=0 or inventory.pickups.size()!=4: _fail("Full journey starts with collected keepsakes"); return
	for index in range(4):
		if not inventory.pickups[index].is_visible_in_tree() or court.landscape.objects[index].visible:
			_fail("Keepsakes do not begin scattered outside the courtyard"); return
	await _put(8.8,10.6)
	_save_coop("keepsakes-act-one-dropped")
	# A click from beyond pickup distance must not put an item into the bag.
	await _click_at(world.camera.unproject_position(inventory.POSITIONS[1]+Vector3(0,.42,0)))
	if inventory.collected[1]: _fail("Distant mouse click collected a keepsake"); return
	await _put(9.2,10.6)
	await _frames(12)
	await _click_at(world.camera.unproject_position(inventory.POSITIONS[0]+Vector3(0,.44,0)))
	await _frames(3)
	if not inventory.collected[0] or inventory.pickups[0].visible: _fail("Actual mouse pickup did not remove and store the rubbing"); return
	if not ui.satchel_notice.text.contains("拓片") or not ui._notice_keepsake: _fail("Pickup has no bag receipt"); return
	await _near_key(KEY_B)
	if not paused or not ui.satchel.showing_keepsakes or not ui.satchel.progress_label.text.contains("1 / 4"):
		_fail("B from pickup receipt does not open the keepsake bag"); return
	for label: Label in ui.satchel.contents+ui.satchel.titles+ui.satchel.origins:
		if not _fits(label): return
	_save_coop("keepsakes-bag-one-found")
	await _near_key(KEY_ESCAPE)
	await _pickup_key(KEY_E)
	if inventory.collected.count(true)!=1: _fail("Repeated pickup produced duplicates"); return
	await _put(17.4,17.95)
	await _frames(12)
	await _pickup_key(KEY_P)
	if not inventory.collected[1]: _fail("Stoneworker's P cannot collect her own chisel"); return
	# Actual cultural-item interaction still records this journey's achievements.
	world.folk.open_item("bai_tiedye")
	await _frames(3)
	world.folk.close()
	if book.collected.size()!=1 or not book.unlocked.has("first_meeting"): _fail("Session achievements no longer unlock"); return
	await _tap("restart")
	if inventory.collected.count(true)!=2 or book.collected.size()!=1: _fail("Returning to spawn cleared journey progress"); return
	world.start_creek_preview()
	party.switch_to(2,0)
	await _put(23.0,22.4)
	await _frames(12)
	await _pickup_key(KEY_E)
	party.switch_to(3,1)
	await _put(29.8,28.8)
	await _frames(12)
	await _pickup_key(KEY_P)
	if inventory.collected.count(true)!=4: _fail("The second chapter's bell and thread cannot both be picked up"); return
	_save_coop("keepsakes-act-two-found")
	world.restart_current_scene()
	await _frames(10)
	if inventory.collected!=[true,true,false,false] or book.collected.size()!=1:
		_fail("Restart act two should retain earlier items / achievements and respawn act-two items"); return
	for index in [2,3]:
		await _put(inventory.POSITIONS[index].x,inventory.POSITIONS[index].x-.7)
		var owner: int=party.owner_of(index)
		party.switch_to(index,owner)
		await _frames(12)
		await _pickup_key(KEY_E if owner==0 else KEY_P)
	if inventory.collected.count(true)!=4: _fail("Respawned act-two keepsakes cannot be recovered"); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	party.switch_to(1,1)
	await _put(50.3,49.7)
	await _dual_hold()
	await _frames(180)
	if not court.tablet_placed: _fail("Collected keepsakes block the earlier supported stele raise"); return
	# A legitimate missed-item state is injected after the preview's skipped-
	# chapter seeding, then recovered by physically walking back over the bridge.
	inventory.collected[1]=false
	inventory.pickups[1].visible=true
	await _put(46.2,49.0)
	await _dual_hold(false,true)
	if court.items_done[1] or court.item_progress[1]>0: _fail("An uncollected chisel can still be placed"); return
	if not court.player_task(second).text.contains("第一关") or not court.get_hint().contains("尚未拾齐"):
		_fail("Missing item does not identify its earlier chapter"); return
	await _near_key(KEY_B)
	if not ui.satchel.showing_keepsakes: await _click_at(ui.satchel.keepsake_button.get_global_rect().get_center())
	if ui.satchel.statuses[1].text!="待拾": _fail("Satchel falsely labels the missing chisel as carried"); return
	_save_coop("keepsakes-bag-missing-location")
	await _near_key(KEY_ESCAPE)
	if not await _duo_walk(17.4,17.95): _fail("Cannot return across the completed bridge to recover the missed item"); return
	await _pickup_key(KEY_P)
	if not inventory.collected[1]: _fail("Returning to an earlier chapter cannot recover its missing item"); return
	party.switch_to(0,0)
	if not await _duo_walk(46.2,49.0): _fail("Recovered item cannot be brought back to the court"); return
	await _dual_hold()
	if not court.items_done[0] or not court.items_done[1]: _fail("Carried paper / chisel cannot be placed by their owners"); return
	party.switch_to(2,0)
	party.switch_to(3,1)
	await _put(51.7,52.8)
	await _dual_hold()
	await _frames(5)
	await _complete_shared_design()
	if court.lamp_count!=4 or not court.personal_items_done() or not world.experience.design_done:
		_fail("Four recovered items do not lead to the existing joint composition"); return
	for object in court.landscape.objects:
		if not object.visible: _fail("Placed keepsake is invisible in the courtyard"); return
	_save_coop("keepsakes-four-placed")
	world.restart_current_scene()
	await _frames(8)
	if inventory.collected.count(true)!=4 or true in court.items_done or book.collected.size()!=1:
		_fail("Restart act three loses carried items or retains old placements"); return
	await _tap("restart_lesson")
	await _frames(8)
	if true in inventory.collected or not book.collected.is_empty() or not book.unlocked.is_empty() or ui._notice_seconds>0:
		_fail("T does not clear the full journey's items / achievements / old receipt"); return
	world.folk.open_item("bai_tiedye")
	await _frames(2)
	world.folk.close()
	if not book.unlocked.has("first_meeting"): _fail("New journey cannot earn the first achievement again"); return
	if FileAccess.get_file_as_string(legacy_path)!=legacy_data: _fail("Session-only achievements still write persistent profile data"); return
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	_load_test_world()
	await _frames(10)
	if not world.achievements.collected.is_empty() or not world.achievements.unlocked.is_empty() or true in world.keepsakes.collected:
		_fail("Fresh game instance restored the previous journey"); return
	await _click_at(ui.achievement_button.get_global_rect().get_center())
	_save_coop("keepsakes-new-launch-empty-book")
	await _near_key(KEY_ESCAPE)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("JOURNEY_KEEPSAKES_OK: legacy save ignored / never rewritten, actual mouse and both keyboard pickups, bag states / locations, no duplicate or remote pickups, missing item cannot place, physical return over bridge and onward placement, owner roles and joint design retained, R and per-chapter reset rules, T and fresh game reset, re-earned achievements")
	quit(0)


func _pickup_key(code: int) -> void:
	await _press_key(code,true)
	await _frames(3)
	await _press_key(code,false)
	await _frames(3)


func _load_test_world() -> void:
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
