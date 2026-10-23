extends "res://tools/verify_cooperative_experience.gd"

var checkpoint: String="startup"
var watchdog: SceneTreeTimer


func _initialize() -> void:
	capture=true
	watchdog=create_timer(200,true)
	watchdog.timeout.connect(_timed_out)
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
	await _frames(15)
	await _start_default_party()
	await _put(5.8,6.3)
	await _click_prop("bai_tiedye")
	await _near_key(KEY_ESCAPE)
	ui.notify_keepsake("邓书年的拓片")
	await _frames(5)
	var book: CanvasLayer=world.achievements
	if not book.toast.visible or book.toast_button.visible or book.toast.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
		_fail("Achievement notification still uses a separate side button"); return
	if book.toast_text.horizontal_alignment!=ui.satchel_notice.horizontal_alignment or book.toast_text.vertical_alignment!=ui.satchel_notice.vertical_alignment or book.toast_text.get_theme_font("font")!=ui.satchel_notice.get_theme_font("font") or book.toast_text.get_theme_font_size("font_size")!=ui.satchel_notice.get_theme_font_size("font_size"):
		_fail("Achievement and item notifications do not share typography / centering"); return
	if book.toast.get_global_rect().intersects(ui.satchel_notice_frame.get_global_rect()) or not _fits(book.toast_text): _fail("Notification stacking overlaps or clips"); return
	_save_coop("carried-matching-receipts")
	for id in book.Content.ITEMS: book.record_item(id)
	await _frames(4)
	if not _fits(book.toast_text) or book.toast.get_rect().end.x>1257 or book.toast.size.x>570: _fail("Multiple achievements overflow the fitted paper"); return
	_save_coop("carried-long-achievement-receipt")
	await _near_key(KEY_C)
	if ui.screen!=ui.Screen.ACHIEVEMENTS or not paused: _fail("C no longer opens the notification's book"); return
	await _near_key(KEY_ESCAPE)
	world.start_creek_preview()
	bridge.bridge_ready=true
	bridge.gap_stabilized=true
	bridge.step=6
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	await _put(39.81,40.2)
	await _frames(18)
	if not bridge.tablet_delivered or not court.tablet_arriving or not is_instance_valid(court.carry_rig) or bridge._tablet.visible:
		_fail("Real handoff does not start four-person carrying"); return
	_save_coop("carried-gather-and-lift")
	var owners: Array[int]=[party.active_id,party.second_id]
	await _press_key(KEY_TAB,true)
	await _press_key(KEY_TAB,false)
	if [party.active_id,party.second_id]!=owners: _fail("Changing roles breaks the carrying formation"); return
	await _frames(45)
	var rig: Node3D=court.carry_rig
	if rig.carriers.size()!=4 or rig.grips.size()!=4 or rig.slings.size()!=8: _fail("Some bearers have no connected grip / sling"); return
	for body in rig.carriers:
		if body.is_physics_processing() or not party._visual(body).transport_pose or party._visual(body).detailed_model.current_state!="carry":
			_fail("A real character does not use the staged carrying animation"); return
	_save_coop("carried-four-people-walking")
	var positions: Array[Vector3]=[]
	for body in rig.carriers: positions.append(body.global_position)
	var before: Vector3=court._tablet.position
	await _near_key(KEY_H)
	await _frames(12)
	if not paused or court._tablet.position!=before: _fail("Help does not pause the carried stone"); return
	for index in range(4):
		if rig.carriers[index].global_position!=positions[index]: _fail("A carrier keeps walking while paused"); return
	await _near_key(KEY_ESCAPE)
	await _frames(ceili(court.ARRIVAL_SECONDS*60*.86)-63)
	_save_coop("carried-lowering-at-plinth")
	await _frames(ceili(court.ARRIVAL_SECONDS*60*.14)+15)
	if court.tablet_arriving or is_instance_valid(court.carry_rig) or absf(court._tablet.position.y-court.FLAT_REST_Y)>.01:
		_fail("Carried stone does not settle flat and release its rig"); return
	for body in party.all_bodies():
		if not body.is_physics_processing() or party._visual(body).transport_pose: _fail("A carrier remains disabled after delivery"); return
	if not player.controls_enabled or not second.controls_enabled or party.movement_locked(): _fail("Delivery fails to return both controls"); return
	party.switch_to(1,1)
	await _put(50.3,49.7)
	await _dual_hold()
	await _frames(ceili(court.RAISE_SECONDS*60)+12)
	if not court.tablet_placed or not court._tablet.basis.is_equal_approx(Basis.IDENTITY): _fail("Flat carried stone cannot join the supported raising animation"); return
	_save_coop("carried-stone-raised-after-delivery")
	checkpoint="restart current act during carry"
	world.restart_current_scene()
	await _frames(25)
	checkpoint="T reset during carry"
	await _tap("restart_lesson")
	await _frames(8)
	if court.tablet_arriving or is_instance_valid(court.carry_rig) or court._tablet.visible: _fail("T during carrying leaves a ghost load / rig"); return
	for body in party.all_bodies():
		if not body.is_physics_processing() or party._visual(body).transport_pose: _fail("Reset during carrying strands a disabled character"); return
	world.start_garden_preview()
	checkpoint="second preview"
	await _frames(30)
	checkpoint="R reset during carry"
	await _tap("restart")
	await _frames(5)
	if court.tablet_arriving or party.movement_locked() or not player.controls_enabled: _fail("R during carrying cannot safely restore control"); return
	if absf(player.global_position.x-5.0)>.03 or absf(second.global_position.x-4.05)>.03:
		_fail("The carry formation overwrites R's respawn positions"); return
	checkpoint="walk after R"
	if not await _duo_walk(5.8,6.3): _fail("Characters cannot move after interrupted carrying"); return
	watchdog.timeout.disconnect(_timed_out)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("CARRIED_ARRIVAL_OK: shared centered / fitted notification paper and typography, no side button / C retained / stacked long receipts, actual bridge handoff, four real characters with carry gait / hand grips / eight slings and flat load, pause and role isolation, lower / restore control / supported raise, mid-carry T and R cleanup")
	quit(0)


func _timed_out() -> void:
	_fail("Carried arrival test timed out: "+checkpoint)
