extends "res://tools/verify_nearby_interactions.gd"

const Content = preload("res://scripts/culture_content.gd")
const Signs = preload("res://scripts/world_signs.gd")


func _initialize() -> void:
	capture = "--capture-culture" in OS.get_cmdline_user_args()
	create_timer(100, true).timeout.connect(func(): _fail("Culture / scroll check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Real renderer required"); return
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
	await _frames(8)
	_save_coop("culture-title")
	await _click_at(ui.culture_button.get_global_rect().get_center())
	if ui.screen != ui.Screen.CULTURE or party.started: _fail("Culture entry starts gameplay"); return
	for index in range(4):
		await _frames(3)
		if ui.culture_index != index or ui.reading_room.card.visible or ui.reading_room.source_links.text.count("[url=") < 2:
			_fail("Culture page or precise source links missing"); return
		if ui.reading_room.body.get_content_height() > ui.reading_room.body.size.y:
			_fail("Culture text overflows on page " + str(index)); return
		if ui.reading_room.source_links.get_content_height() > ui.reading_room.source_links.size.y:
			_fail("Culture source links overflow on page " + str(index)); return
		_save_coop("culture-page-%d" % (index + 1))
		await _key(KEY_ENTER)
	if ui.screen != ui.Screen.TITLE: _fail("Culture final page cannot return to cover"); return
	await _click_at(ui.secondary.get_global_rect().get_center())
	for index in range(8):
		await _frames(3)
		if ui.screen != ui.Screen.INTRO or ui.intro_index != index or ui.reading_room.card.texture != ui.opening_draw.CARD_TEXTURES[index]:
			_fail("Biography does not use original card " + str(index)); return
		if not ui.reading_room.name_label.text.contains("族）") or ui.reading_room.body.get_content_height() > ui.reading_room.body.size.y:
			_fail("Biography ethnicity or full readable text missing " + str(index) + " height=" + str(ui.reading_room.body.get_content_height())); return
		if ui.previous_page.get_rect().intersects(ui.secondary.get_rect()): _fail("Biography buttons overlap after culture"); return
		_save_coop("culture-person-%d" % (index + 1))
		if index < 7: await _key(KEY_ENTER)
	await _key(KEY_LEFT)
	if ui.intro_index != 6: _fail("Biography backward navigation fails"); return
	await _click_at(ui.return_title.get_global_rect().get_center())
	await _start_default_party()
	await _put(17.3, 17.8)
	_save_coop("culture-plaque-road")
	var signs := get_nodes_in_group("world_plaques")
	var expected_signs: Array[String] = ["古道","杨旗田","往城中","灯火共庭","同源异彩"]
	if signs.size() != expected_signs.size(): _fail("Named plaque collection is incomplete"); return
	for sign in signs:
		var title: String = sign.get_meta("title")
		if title not in expected_signs: _fail("Unexpected plaque title: "+title); return
		expected_signs.erase(title)
		if sign.get_node("Lettering").font != Signs.LETTERING: _fail("Modern UI font remains on a plaque"); return
		for letter in title:
			if not Signs.LETTERING.has_char(letter.unicode_at(0)): _fail("Plaque font lacks " + letter); return
	world.start_creek_preview()
	bridge.helpers_called = true
	bridge._helpers.visible = true
	bridge.step = 4
	bridge._a_cai.position = Vector3(9, 0, -2)
	bridge._a_qiang.position = Vector3(10, 0, -2)
	await _put(29, 30)
	await _focus_id(0, "a_cai")
	await _focus_id(1, "a_qiang")
	await _near_key(KEY_F)
	await _near_key(KEY_SLASH)
	for slot in range(2):
		var card: Panel = nearby_ui.cards[slot]
		if not nearby_ui.arrowheads[slot].visible or card.get_theme_stylebox("panel").bg_color.a > 0.8:
			_fail("Higher transparency or arrow pointer is missing"); return
		var target: Vector2 = nearby_ui.tails[slot].points[1]
		if card.position.y + card.size.y > target.y - 65:
			_fail("Bubble still covers the interaction target"); return
	_save_coop("culture-high-dialogue")
	nearby_ui.clear()
	if nearby_ui.arrowheads[0].visible: _fail("Clearing interaction leaves a stale arrow"); return
	world.start_garden_preview()
	court.court_lit = true
	var records: Array[String] = ["Test journey complete"]
	court.show_record(records)
	await _frames(5)
	if not court.landscape.record_cover_open or court.landscape.record_cover.texture != court.landscape.SCROLL_COVER:
		_fail("New supplied scroll cover is missing"); return
	_save_coop("culture-scroll-cover")
	await _key(KEY_ENTER)
	for index in range(4):
		var art: Node3D = court.landscape
		if art.record_page != index or not art.record.visible or art.record_art.texture != art.SCROLL_IMAGES[index]:
			_fail("Ending mural order or page missing"); return
		if art.record_text.get_line_count() > art.record_text.get_visible_line_count(): _fail("Bright mural hides or clips ending text"); return
		if art.record_text.get_theme_color("font_color").get_luminance() < 0.8 or art.record_text.get_parent().get_theme_stylebox("panel").bg_color.a < 0.9:
			_fail("Ending contrast does not survive bright background"); return
		if ui.hint_button.visible or ui.satchel_button.visible: _fail("Gameplay buttons clutter the long scroll"); return
		_save_coop("culture-scroll-%d" % (index + 1))
		if index < 3: await _key(KEY_RIGHT)
	await _frames(100)
	await _key(KEY_RIGHT)
	if court.landscape.record_page != 3 or not court.record_open: _fail("Last page does not wait for the player"); return
	await _tap("open_archive")
	await _frames(3)
	if not paused or ui.screen != ui.Screen.ARCHIVE or ui.layer <= court.landscape.record.get_parent().layer:
		_fail("Archive is hidden behind the scroll"); return
	_save_coop("culture-scroll-archive")
	await _key(KEY_LEFT)
	if court.landscape.record_page != 3: _fail("Paused archive navigates underlying scroll"); return
	await _tap("open_archive")
	await _key(KEY_ENTER)
	if court.record_open or party.movement_locked(): _fail("Final page cannot return to courtyard"); return
	print("CULTURE_SCROLL_OK: four sourced entry pages, original paper, eight original-card biographies with full text and navigation, all five modern Cuan plaques with font coverage, raised translucent independent arrow bubbles, supplied cover and four murals/rollers/bright-art contrast, final-page stay, archive layering and input isolation, return controls")
	quit(0)
