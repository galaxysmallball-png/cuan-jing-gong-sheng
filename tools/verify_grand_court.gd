extends "res://tools/verify_folk_play.gd"


func _initialize() -> void:
	capture = "--capture-grand" in OS.get_cmdline_user_args()
	create_timer(150, true).timeout.connect(func(): _fail("Grand court check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1280, 720)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world = load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene = world
	party = world.party
	player = party.player
	second = party.second_player
	first = world.cooperation
	bridge = world.bridge
	court = world.courtyard
	ui = world.get_node("PartyUI")
	nearby_ui = world.get_node("NearbyInteractions")
	await _frames(15)
	if not ui.sound_button.visible or ui.effects_slider.is_visible_in_tree() or ui.music_button.is_visible_in_tree():
		_fail("Sound controls still clutter the title/HUD"); return
	await _click_at(ui.sound_button.get_global_rect().get_center())
	if ui.screen != ui.Screen.SETTINGS or not paused or not ui.audio_settings.visible: _fail("Sound entry does not open modal settings"); return
	await _drag_slider(.85, .30)
	await _drag_music(.25)
	await _frames(10)
	if absf(world.sfx.volume - .30) > .08 or absf(world.music.volume - .25) > .05:
		_fail("Independent physical slider dragging failed"); return
	if world.music.decks[world.music.active_deck].volume_db > -19:
		_fail("Music slider changes label but not actual audio level"); return
	await _click_at(ui.music_button.get_global_rect().get_center())
	await _frames(2)
	if not world.music.muted or world.sfx.muted: _fail("Music toggle also mutes effects"); return
	await _click_at(ui.effects_button.get_global_rect().get_center())
	await _frames(2)
	if not world.sfx.muted: _fail("Effects toggle fails in settings"); return
	_save_coop("grand-audio-settings")
	world.music.toggle_mute()
	world.sfx.toggle_mute()
	await _drag_music(0)
	await _frames(2)
	if world.music.decks[world.music.active_deck].volume_db != -80: _fail("Music zero is audible"); return
	await _drag_music(.8)
	await _near_key(KEY_ESCAPE)
	if ui.screen != ui.Screen.TITLE or paused or ui.audio_settings.visible: _fail("Sound settings do not restore title"); return
	await _start_default_party()
	await _put(10.1, 10.8)
	await _click_prop("scholar_tools")
	if not world.folk.overlay.visible or world.folk.preview_model.find_child("HollowBambooTube", true, false) == null or world.folk._meshes(world.folk.preview_model).size() < 50:
		_fail("Scholar object still lacks an actual hollow tube, scrolls and satchel"); return
	_save_coop("grand-scholar-model")
	await _click_at(world.folk.reference_button.get_global_rect().get_center())
	if not world.folk.reference_image.visible or world.folk.preview_area.visible: _fail("Museum reference photograph is not accessible"); return
	if world.folk.reference_image.size.x > 431 or world.folk.reference_image.size.y > 341: _fail("Museum image spills beyond its preview: " + str(world.folk.reference_image.size) + " min=" + str(world.folk.reference_image.get_combined_minimum_size()) + " expand=" + str(world.folk.reference_image.expand_mode)); return
	_save_coop("grand-scholar-reference")
	await _near_key(KEY_ESCAPE)
	world.start_creek_preview()
	await _put(21, 21.7)
	var clicks: CanvasLayer = world.click_interactions
	await _click_at(world.camera.unproject_position(clicks.pickers.yangqitian_history.global_position))
	await _frames(3)
	if not clicks.overlay.visible or not paused or ui.screen != ui.Screen.HISTORY or not clicks.history_text.text.contains("1778") or not clicks.history_text.text.contains("405"):
		_fail("Actual sign click does not introduce Yangqitian history"); return
	if clicks.history_text.get_line_count() > clicks.history_text.get_visible_line_count(): _fail("Sign history text clips"); return
	if clicks.history_text.size.x > 675: _fail("History expands beyond its paper"); return
	_save_coop("grand-yangqitian-history")
	await _near_key(KEY_ESCAPE)
	if paused or ui.screen != ui.Screen.GAME or bridge.step != 0: _fail("History close changes gameplay state"); return
	bridge.step = 4
	bridge.helpers_called = true
	bridge._helpers.visible = true
	bridge._a_cai.position = Vector3(9, 0, -2)
	bridge._a_qiang.position = Vector3(10.5, 0, -2)
	await _put(29, 30)
	for id in ["a_cai", "a_qiang"]:
		await _click_person(id)
		if clicks.last_person != id or world.story.current.speaker != clicks.entries[id].title or world.story.queue.size() < 2:
			_fail("Villager body click lacks a full portrait conversation: " + id); return
		_save_coop("grand-dialogue-" + id)
		await _near_key(KEY_V)
		if world.story.current.speaker != party.NAMES[party.human_players()[clicks.last_slot].character_id]: _fail("Player does not answer villager"); return
	if bridge.bridge_ready or bridge.building: _fail("Talking auto-completes bridge"); return
	world.start_garden_preview()
	party.switch_to(1, 1)
	await _put(49, 49.7)
	await _frames(20)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(40)
	for card in court.landscape.task_cards:
		if not card.visible or card.position.y < 600 or not card.get_theme_stylebox("panel") is StyleBoxTexture:
			_fail("Player progress cards have not moved down onto supplied paper"); return
		if card.get_rect().intersects(ui.goal_panel.get_rect()) or (world.story.frame.visible and card.get_rect().intersects(world.story.frame.get_rect())):
			_fail("Visible task progress overlaps goal or portrait"); return
	_save_coop("grand-paper-progress")
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(3)
	court.tablet_placed = true
	for i in range(4): court.items_done[i] = true
	court.lamp_count = 4
	court.landscape.sync_state()
	await _frames(140)
	for id in ["pu_mo", "yu_nan", "a_cai_court", "a_qiang_court"]:
		var x: float = clicks.entries[id].anchor.global_position.x
		await _put(x, x + .7)
		await _click_person(id)
		if clicks.last_person != id or world.story.current.speaker != clicks.entries[id].title: _fail("Court villager body is not clickable: " + id); return
		_save_coop("grand-dialogue-" + id)
	if court.oil_carriers != [-1, -1, -1]: _fail("Talking takes lamps"); return
	court.items_done.fill(true)
	court.lamp_count = 7
	court.court_lit = true
	court._tablet.position = Vector3(10, 1.50, -2.35)
	court._tablet.rotation.z = 0
	court.landscape.sync_state()
	await _put(50, 52)
	await _frames(45)
	world.story.queue.clear()
	world.story.current = {}
	await _frames(3)
	if world.festival.grand.sky_lanterns.size() < 8 or not world.festival.grand.celebration.visible or world.festival.lanterns.size() < 12:
		_fail("Grand ending lacks skyline and golden celebration"); return
	_save_coop("grand-finale-court")
	await _click_at(ui.sound_button.get_global_rect().get_center())
	await _near_key(KEY_T)
	if ui.screen != ui.Screen.SETTINGS or not court.court_lit: _fail("Settings allow reset key to reach game"); return
	await _near_key(KEY_ESCAPE)
	world.restart_current_scene()
	await _frames(5)
	if world.festival.grand.celebration.visible or absf(world.music.volume - .8) > .04 or world.sfx.volume > .4:
		_fail("Restart loses audio preferences or leaves victory effect"); return
	print("GRAND_COURT_OK: modal sound controls and real independent music/effects gains, pause/input isolation, museum photo and detailed scholar model, actual sign ray click and sourced non-clipping history, six villager appearances with portrait dialogue and player replies, no task side effects, lowered paper progress, tiered roof skyline and golden ending, restart preserves volume")
	quit(0)


func _drag_music(value: float) -> void:
	var rect: Rect2 = ui.music_slider.get_global_rect()
	await _click_at(rect.position + Vector2(8 + (rect.size.x - 16) * value, rect.size.y / 2))


func _click_person(id: String) -> void:
	await _frames(3)
	var body: Node3D = world.click_interactions.pickers[id]
	await _click_at(world.camera.unproject_position(body.global_position))
	await _frames(4)
