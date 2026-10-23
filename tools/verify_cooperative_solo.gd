extends "res://tools/verify_cooperative_experience.gd"

var watchdog: SceneTreeTimer


func _initialize() -> void:
	capture="--capture-cooperative-solo" in OS.get_cmdline_user_args()
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",ProjectSettings.globalize_path("res://previews/cooperative-solo-profile.json"))
	watchdog=create_timer(180,true)
	watchdog.timeout.connect(_timed_out)
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode=Window.MODE_MINIMIZED
		capture_viewport=SubViewport.new()
		capture_viewport.size=Vector2i(1280,720)
		capture_viewport.own_world_3d=true
		capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	world.get_node("Party").local_coop=false
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene=world
	party=world.party
	player=party.player
	first=world.cooperation
	bridge=world.bridge
	court=world.courtyard
	ui=world.get_node("PartyUI")
	await _frames(15)
	await _start_default_party()
	var experience: CanvasLayer = world.experience
	if experience.coach_words.text.contains("2P") or party.human_players().size()!=1:
		_fail("Solo tutorial refers to a nonexistent second controller"); return
	if not _fits(experience.coach_words): return
	_save_coop("cooperation-solo-guide")
	world.start_garden_preview()
	if not await _at(1,50): _fail("Solo player cannot reach the stele"); return
	await _hold()
	await _frames(190)
	if not court.tablet_placed: _fail("Solo stoneworker cannot raise the stele"); return
	for index in range(3):
		if not await _complete_courtyard_item(index): _fail("Solo keepsake cannot be placed"); return
	if not await _at(3,52.8): _fail("Solo player cannot place the final keepsake"); return
	Input.action_press("interact")
	await _frames(105)
	Input.action_release("interact")
	await _frames(4)
	if not experience.overlay.visible or not experience.design_headers[1].text.contains("右幅"):
		_fail("Solo two-part composition does not open"); return
	await _near_key(KEY_A)
	await _near_key(KEY_E)
	if experience.solo_side!=1 or not experience.confirmed[0] or experience.design_done:
		_fail("Solo confirmation does not advance to the second cloth"); return
	await _near_key(KEY_D)
	_save_coop("cooperation-solo-design")
	await _near_key(KEY_E)
	if not experience.design_done or paused or experience.choices!=[0,1]:
		_fail("Solo keyboard cannot finish both cloth contributions"); return
	if not court.composition_ready() or party.human_players().size()!=1:
		_fail("Solo composition depends on another physical player"); return
	world.restart_current_scene()
	if experience.design_done or party.movement_locked(): _fail("Solo restart retains design or an input lock"); return
	watchdog.timeout.disconnect(_timed_out)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("COOPERATIVE_SOLO_OK: single-controller tutorial, real single stoneworker/keepsake flow, A/D/E sequential left/right design, no phantom second player, both patterns persist and lamps unlock, restart cleanup")
	quit(0)


func _timed_out() -> void:
	_fail("Solo composition check timed out")
