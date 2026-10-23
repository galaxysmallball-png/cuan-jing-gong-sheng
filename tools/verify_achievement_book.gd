extends "res://tools/verify_photo_guide.gd"

var book: CanvasLayer
var profile: String


func _initialize() -> void:
	capture="--capture-achievements" in OS.get_cmdline_user_args()
	profile=ProjectSettings.globalize_path("res://previews/achievement-verification-profile.json")
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",profile)
	var file := FileAccess.open(profile,FileAccess.WRITE)
	file.store_string('{"version":1,"collected":{},"unlocked":{}}')
	file.close()
	create_timer(180,true).timeout.connect(func(): _fail("Achievement check timed out"))
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
	book=world.achievements
	await _frames(20)
	if book.Content.ITEMS.size()!=world.folk.items.size() or book.collected.size()!=0: _fail("New profile or cultural catalog mismatch"); return
	for id in world.folk.items:
		if not book.Content.ITEMS.has(id) or not book.Content.GROUPS.has(book.Content.ITEMS[id].group): _fail("Cultural item lacks story-associated group: "+id); return
	if ui.achievement_button.get_global_rect().intersects(ui.sound_button.get_global_rect()): _fail("Achievement entry overlaps sound"); return
	await _click_at(ui.achievement_button.get_global_rect().get_center())
	await _frames(3)
	if ui.screen!=ui.Screen.ACHIEVEMENTS or not paused or party.started or not book.overlay.visible: _fail("Title album does not pause safely"); return
	_save_coop("achievements-empty-book")
	await _near_key(KEY_RIGHT)
	if book.page!=1: _fail("Album keyboard pagination fails"); return
	await _near_key(KEY_ESCAPE)
	if ui.screen!=ui.Screen.TITLE or paused or party.started: _fail("Album cannot return to title"); return
	await _start_default_party()
	print("ACHIEVEMENT_STEP: started")
	await _put(5.9,6.6)
	await _click_prop("bai_tiedye")
	await _frames(4)
	if not book.collected.has("bai_tiedye") or book.collected.size()!=1 or not book.unlocked.has("first_meeting"):
		_fail("Actual scene click does not collect and unlock first achievement"); return
	var first_stamp: String = book.collected.bai_tiedye
	if book.record_item("bai_tiedye") or book.record_item("nonexistent") or book.collected.size()!=1 or book.collected.bai_tiedye!=first_stamp:
		_fail("Duplicate or unknown items alter the collection"); return
	_save_coop("achievements-object-auto-collected")
	await _click_at(world.folk.achievement_entry.get_global_rect().get_center())
	await _frames(3)
	if ui.screen!=ui.Screen.ACHIEVEMENTS or not world.folk.overlay.visible or not paused: _fail("Cannot open album above object window"); return
	await _click_at(book.tabs["白族"].get_global_rect().get_center())
	await _click_at(book.cards[0].get_global_rect().get_center())
	await _frames(3)
	if not book.detail_photo.visible or book.detail_photo.texture==null or not book.detail_credit.text.contains("来源"): _fail("Collected item lacks replayable photograph"); return
	_save_coop("achievements-bai-collected-photo")
	await _near_key(KEY_ESCAPE)
	if ui.screen!=ui.Screen.INSPECT or not paused or not world.folk.overlay.visible: _fail("Album unpauses underlying object window"); return
	await _near_key(KEY_ESCAPE)
	await _near_key(KEY_C)
	var before: Vector3 = player.global_position
	Input.action_press("move_right")
	await _frames(15)
	Input.action_release("move_right")
	if player.global_position.distance_to(before)>.01: _fail("Moving input leaks through paused album"); return
	await _near_key(KEY_ESCAPE)
	await _put(12.5,13)
	await _click_stone(0)
	await _near_key(KEY_C)
	await _near_key(KEY_Q)
	await _near_key(KEY_ESCAPE)
	if ui.screen!=ui.Screen.GAME or first.inspected_id!=0 or paused or not player.interaction_locked: _fail("Album does not restore small-stele inspection"); return
	await _near_key(KEY_ESCAPE)
	var total: int = 1
	print("ACHIEVEMENT_STEP: initial entries")
	for stage in range(3):
		print("ACHIEVEMENT_STEP: stage ",stage)
		if stage==1:
			world.start_creek_preview()
			bridge.step=4
			bridge.helpers_called=true
			bridge._helpers.visible=true
		elif stage==2:
			if book.unlocked.has("woven_encounters") or book.unlocked.has("seven_together"): _fail("Cross-ethnic achievements unlock before the missing ethnic encounters"); return
			world.start_garden_preview()
			print("ACHIEVEMENT_STEP: garden preview entered")
			await _frames(210)
			court.tablet_placed=true
			for index in range(4): court.items_done[index]=true
			court.lamp_count=4
			court.landscape.sync_state()
			await _frames(3)
			await _complete_shared_design()
			print("ACHIEVEMENT_STEP: garden design completed")
		await _frames(35)
		for id in world.folk.items:
			if world.folk.items[id].chapter!=stage or id=="bai_tiedye": continue
			if stage==2: print("ACHIEVEMENT_STEP: object ",id)
			world.folk.open_item(id)
			await _frames(3)
			total+=1
			if not book.collected.has(id) or book.collected.size()!=total: _fail("Real object introduction does not collect exactly once: "+id); return
			await _near_key(KEY_ESCAPE)
	if total!=21 or book.unlocked.size()!=8 or book.connected_groups()!=7: _fail("Full collection does not unlock all eight cross-ethnic achievements"); return
	for badge in book.Content.BADGES:
		var progress: Vector2i = book.badge_progress(badge)
		if progress.x!=progress.y: _fail("Achievement condition mismatch: "+badge.id); return
	print("ACHIEVEMENT_STEP: before scene restart")
	world.restart_current_scene()
	print("ACHIEVEMENT_STEP: scene restart")
	await _frames(4)
	if book.collected.size()!=21 or book.unlocked.size()!=8: _fail("Restarting the current scene wipes this journey's collection"); return
	await _near_key(KEY_C)
	await _click_at(book.tabs["全部"].get_global_rect().get_center())
	await _frames(4)
	_save_coop("achievements-seven-cultures-connected")
	for group in book.Content.GROUPS:
		await _click_at(book.tabs[group].get_global_rect().get_center())
		var ids: Array[String] = book.visible_ids.duplicate()
		if ids.size()!=book.group_total(group): _fail("Ethnic filtering loses objects: "+group); return
		for id in ids:
			book.selected_id=id
			book._show_item()
			await _frames(3)
			if not book.detail_photo.visible or book.detail_photo.texture==null: _fail("Collected photograph unavailable after leaving its scene: "+id); return
			if book.detail_note.get_line_count()>book.detail_note.get_visible_line_count(): _fail("Album cultural connection text clips: "+id); return
			if book.detail_credit.get_content_height()>book.detail_credit.size.y: _fail("Album photograph credit clips: "+id); return
			if book.photo_next.visible:
				var photo: Texture2D = book.detail_photo.texture
				await _click_at(book.photo_next.get_global_rect().get_center())
				if book.detail_photo.texture==photo: _fail("Album multi-photo switching fails: "+id); return
	await _click_at(book.tabs["交融成就"].get_global_rect().get_center())
	await _click_at(book.cards[2].get_global_rect().get_center())
	await _frames(4)
	if book.selected_id!="woven_encounters" or not book.detail_required.text.contains("白族") or not book.detail_required.text.contains("苗族") or not book.detail_required.text.contains("傣族"):
		_fail("Cross-ethnic achievement hides how cultures connect"); return
	for index in range(4):
		if book.card_bars[index].size.y>6 or book.card_bars[index].get_global_rect().intersects(book.card_titles[index].get_global_rect()):
			_fail("Achievement progress track covers its title"); return
	_save_coop("achievements-woven-encounters")
	book._required_link("item:miao_batik")
	await _frames(3)
	if book.selected_group!="苗族" or book.selected_id!="miao_batik" or not book.detail_photo.visible: _fail("Achievement condition link cannot open collected ethnic item"); return
	await _click_at(book.tabs["交融成就"].get_global_rect().get_center())
	await _near_key(KEY_RIGHT)
	await _click_at(book.cards[2].get_global_rect().get_center())
	await _frames(4)
	if book.selected_id!="seven_together": _fail("Second achievement page fails"); return
	_save_coop("achievements-seven-together")
	for badge in book.Content.BADGES:
		book.selected_id=badge.id
		book._show_badge()
		await _frames(2)
		if book.detail_note.get_line_count()>book.detail_note.get_visible_line_count() or book.detail_required.get_content_height()>book.detail_required.size.y:
			_fail("Achievement narrative or conditions clip: "+badge.id); return
	await _near_key(KEY_ESCAPE)
	var restored: CanvasLayer = load("res://scripts/achievement_book.gd").new()
	print("ACHIEVEMENT_STEP: album inspected")
	restored.reset_session()
	if restored.collected.size()!=0 or restored.unlocked.size()!=0: _fail("Fresh achievement instance carries earlier progress"); return
	restored.free()
	await _tap("restart_lesson")
	print("ACHIEVEMENT_STEP: T reset")
	await _frames(4)
	if not book.collected.is_empty() or not book.unlocked.is_empty(): _fail("T does not start a fresh achievement journey"); return
	print("ACHIEVEMENT_BOOK_OK: actual entries and modal restoration, scene click collection, no duplicates, all 21 items and eight badges, all photos replay, filtering and conditions, text layout, current-scene retention and fresh-instance / T reset")
	quit(0)
