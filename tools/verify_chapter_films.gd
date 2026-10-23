extends "res://tools/verify_cooperative_experience.gd"

func _initialize() -> void:
	capture=true
	call_deferred("_run")

func _run() -> void:
	root.mode=Window.MODE_MINIMIZED
	capture_viewport=SubViewport.new()
	capture_viewport.size=Vector2i(1280,720)
	capture_viewport.own_world_3d=true
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
	await _click_at(ui.primary.get_global_rect().get_center())
	await _frames(10)
	if ui.screen!=ui.Screen.FILM or ui.opening_film.player.stream.file!=ui.opening_film.FILM_PATH:
		_fail("Original overall opening is lost"); return
	await _click_at(ui.opening_film.skip_button.get_global_rect().get_center())
	await _key(KEY_ESCAPE)
	await _key(KEY_ENTER)
	await _frames(8)
	if not await _wait_film(0,40.22,"chapter-first"): return
	if not party.started or not player.controls_enabled or not second.controls_enabled:
		_fail("First chapter film does not restore assigned player controls"); return
	# The real scene boundary triggers act two. No explicit play helper is called.
	first.observed=true
	first.gate_open=true
	first.get_node("Gate").position.y=8
	player.global_position=Vector3(20.2,.8,0)
	second.global_position=Vector3(20.0,.8,0)
	await _frames(8)
	if not await _wait_film(1,25.47,"chapter-second"): return
	player.global_position.x=19.9
	second.global_position.x=19.8
	await _frames(5)
	if ui.screen==ui.Screen.FILM: _fail("Returning over a boundary repeats the film"); return
	# Delivery and the entire real carry must run before the third video.
	bridge.gap_stabilized=true
	bridge.deliver_tablet()
	await _frames(8)
	if not bridge.tablet_delivered or not court.tablet_arriving or ui.screen==ui.Screen.FILM or world.chapter_films.played[2]:
		_fail("Third film still runs before carrying the stone"); return
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+10)
	if court.tablet_arriving or court.tablet_placed or ui.screen==ui.Screen.FILM:
		_fail("Transport does not finish with a flat stele awaiting the lift"); return
	var owner: int=party.owner_of(1)
	party.switch_to(1,owner)
	await _put(50.3,49.7)
	await _dual_hold()
	if not court.tablet_raising or ui.screen==ui.Screen.FILM:
		_fail("Actual cooperative hold cannot start lifting before the film"); return
	await _frames(ceili(court.RAISE_SECONDS*60)-14)
	if ui.screen==ui.Screen.FILM or court.tablet_placed or not court.tablet_raising:
		_fail("Third film interrupts the final supported lift"); return
	_save_coop("third-film-before-settling")
	await _frames(22)
	if not court.tablet_placed or court.tablet_raising or court.tablet_arriving or absf(court._tablet.rotation.z)>.001:
		_fail("Third film does not wait for the upright settled stone"); return
	if not await _wait_film(2,33.95,"chapter-third"): return
	if not court.tablet_placed or not player.controls_enabled or not second.controls_enabled or player.interaction_locked:
		_fail("Third video does not resume the settled courtyard"); return
	_save_coop("third-film-after-settling")
	await _frames(6)
	if ui.screen==ui.Screen.FILM: _fail("Settled stone repeats the film"); return
	var record_lines: Array[String]=["同行"]
	# Read the real long scroll; closing it early must not launch the ending film.
	court.court_lit=true
	world.ending_reached=true
	court.show_record(record_lines)
	court.close_record()
	await _frames(3)
	if world.chapter_films.played[3] or ui.screen==ui.Screen.FILM:
		_fail("Ending starts before the long scroll is finished"); return
	court.show_record(record_lines)
	court.landscape.turn_record(1)
	for page in range(court.landscape.record_last_page()): court.landscape.turn_record(1)
	await _frames(4)
	await _click_at(court.landscape.next_button.get_global_rect().get_center())
	if court.record_open: _fail("Final long-scroll button does not close the scroll"); return
	if not await _wait_film(3,63.95,"chapter-epilogue"): return
	court.show_record(record_lines)
	court.landscape.turn_record(1)
	for page in range(court.landscape.record_last_page()): court.landscape.turn_record(1)
	court.close_record()
	await _frames(3)
	if ui.screen==ui.Screen.FILM: _fail("Re-reading a scroll forces the ending again"); return
	print("CHAPTER_FILM_TAIL reset")
	await _tap("restart_lesson")
	await _frames(4)
	if ui.screen!=ui.Screen.FILM or world.chapter_films.current_film!=0 or world.chapter_films.played[3]:
		_fail("A new journey does not reset chapter film history"); return
	await _click_at(ui.opening_film.skip_button.get_global_rect().get_center())
	print("CHAPTER_FILM_TAIL shutdown")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	if not await _preview_entries(): return
	print("CHAPTER_FILMS_OK: original opening and first two entry films, third film only after actual four-person carry and completed upright lift, full scroll then epilogue, early close/no repeat/new journey reset")
	quit(0)

func _preview_entries() -> bool:
	for index in [1,2]:
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
		var button: Button=ui.chapter_preview if index==1 else ui.garden_preview
		await _click_at(button.get_global_rect().get_center())
		await _frames(5)
		if index==1:
			if ui.screen!=ui.Screen.FILM or world.chapter_films.current_film!=index or not capture_viewport.disable_3d:
				_fail("Second chapter preview loses its entry film"); return false
			await _click_at(ui.opening_film.skip_button.get_global_rect().get_center())
		else:
			if ui.screen==ui.Screen.FILM or not court.tablet_arriving or world.chapter_films.played[2]:
				_fail("Third chapter preview still plays a film before carrying and lifting"); return false
		await _frames(ceili(court.ARRIVAL_SECONDS*60)+8 if index==2 else 8)
		if ui.screen!=ui.Screen.GAME or capture_viewport.disable_3d or world.current_space!=index:
			_fail("Direct chapter movie does not resume its matching chapter"); return false
		if index==2:
			party.switch_to(1,party.owner_of(1))
			await _put(50.3,49.7)
			await _dual_hold()
			await _frames(ceili(court.RAISE_SECONDS*60)+8)
			if not court.tablet_placed or ui.screen!=ui.Screen.FILM or world.chapter_films.current_film!=2:
				_fail("Third chapter preview does not play film after raising"); return false
			await _click_at(ui.opening_film.skip_button.get_global_rect().get_center())
			await _frames(4)
			if ui.screen!=ui.Screen.GAME or not player.controls_enabled: _fail("Preview does not resume after upright film"); return false
		_stop_test_audio(world)
		world.queue_free()
		await process_frame
		await process_frame
		await _drain_test_audio()
	print("CHAPTER_PREVIEW_ENTRIES_OK")
	return true

func _wait_film(index: int,seconds: float,title: String) -> bool:
	if ui.screen!=ui.Screen.FILM or world.chapter_films.current_film!=index:
		_fail("Wrong chapter video: "+title); return false
	var at: Vector3=player.global_position
	await _frames(180)
	_save_coop(title)
	if ui.opening_film.player.get_video_texture().get_width()!=1260 or absf(ui.opening_film.frame.ratio-1.75)>.001:
		_fail("Supplied chapter video does not decode / preserve aspect: "+title); return false
	var deadline: int=Time.get_ticks_msec()+int((seconds+20)*1000)
	if "--fast-films" in OS.get_cmdline_user_args():
		await _click_at(ui.opening_film.skip_button.get_global_rect().get_center())
	while ui.screen==ui.Screen.FILM and Time.get_ticks_msec()<deadline:
		await _frames(1)
		OS.delay_msec(10)
	if ui.screen!=ui.Screen.GAME or paused or ui.opening_film.active or world.music.cinematic_active:
		_fail("Natural ending fails to resume chapter: "+title); return false
	if index!=2 and player.global_position.distance_to(at)>.1:
		_fail("Players moved behind a chapter film: "+title); return false
	print("CHAPTER_FILM_SKIP_OK " if "--fast-films" in OS.get_cmdline_user_args() else "CHAPTER_FILM_NATURAL_OK ",title)
	return true
