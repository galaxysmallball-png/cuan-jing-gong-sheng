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
	root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	capture_viewport.add_child(world)
	world.chapter_films.enabled=false
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
	if ui.screen!=ui.Screen.FILM or not paused or not ui.opening_film.player.is_playing():
		_fail("Title start does not play the supplied film"); return
	var film: Control=ui.opening_film
	var at: Vector3=player.global_position
	await _frames(180)
	_save_coop("opening-film-early")
	if film.player.get_stream_position()<1 or film.player.get_video_texture().get_width()<1000:
		_fail("Film is not decoding actual supplied video frames"); return
	if player.global_position!=at or not world.music.cinematic_active or not capture_viewport.disable_3d:
		_fail("Film does not freeze gameplay / isolate scene score"); return
	await _click_at(film.pause_button.get_global_rect().get_center())
	var time: float=film.player.get_stream_position()
	await _frames(30)
	if not film.player.paused or absf(film.player.get_stream_position()-time)>.05:
		_fail("Film pause does not freeze playback"); return
	await _key(KEY_M)
	if film.player.volume!=0: _fail("Film ignores music mute"); return
	await _key(KEY_M)
	await _key(KEY_SPACE)
	await _frames(600)
	_save_coop("opening-film-middle")
	# Wait for the real decoder's finished signal, without invoking a completion helper.
	var deadline: int=Time.get_ticks_msec()+65000
	while ui.screen==ui.Screen.FILM and Time.get_ticks_msec()<deadline:
		await _frames(1)
		OS.delay_msec(10)
	print("NATURAL_FILM_STATE ",ui.screen," active=",film.active," time=",film.player.get_stream_position())
	if ui.screen!=ui.Screen.DRAW or film.visible or film.active or film.player.stream!=null or world.music.cinematic_active or capture_viewport.disable_3d:
		_fail("Natural film completion does not enter draw and release movie resources"); return
	ui._cancel_draw()
	await _frames(3)
	await _click_at(ui.primary.get_global_rect().get_center())
	await _frames(15)
	if ui.screen!=ui.Screen.FILM or film.player.get_stream_position()>2:
		_fail("Starting a new journey does not replay film from beginning"); return
	await _click_at(film.skip_button.get_global_rect().get_center())
	await _frames(3)
	if ui.screen!=ui.Screen.DRAW or film.active: _fail("Actual skip button does not enter draw"); return
	await _key(KEY_ESCAPE)
	await _key(KEY_ENTER)
	await _frames(5)
	if not party.started or paused or ui.screen!=ui.Screen.GAME:
		_fail("Film skip / draw confirmation does not restore game controls"); return
	_save_coop("opening-film-after-draw")
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("OPENING_FILM_OK: actual supplied film decoded, aspect fit, pause/resume/mute, natural finished signal, replay, mouse skip, card confirmation, controls restored")
	quit(0)
