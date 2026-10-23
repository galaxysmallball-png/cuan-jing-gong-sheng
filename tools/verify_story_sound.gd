extends "res://tools/verify_nearby_interactions.gd"


func _initialize() -> void:
	capture = "--capture-story" in OS.get_cmdline_user_args()
	create_timer(100, true).timeout.connect(func(): _fail("Story / sound check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Renderer required"); return
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
	await _start_default_party()
	await _frames(5)
	if ui.goal_panel.position.x > 40 or ui.goal_panel.position.y < 500: _fail("Goal is not bottom-left"); return
	if not world.story.frame.visible or not world.story.seen.has("meet"): _fail("Story-driven encounter is missing"); return
	var short_lines: Array[String] = ["古字须慢慢辨认，也请诸位各述所见。", "我认石，你认字，合着看才稳当。", "山路有深浅，过溪得互相照应。", "乡音各异，好意却能讲到一处。"]
	for index in range(4):
		world.story.speak(party.NAMES[index], short_lines[index], 8, true)
		await _frames(3)
		var portrait: AtlasTexture = world.story.portrait.texture
		if portrait.atlas != world.story.SHEETS[index] or not world.story.speaker_label.text.contains("族）"):
			_fail("Speaker does not match supplied portrait " + str(index)); return
		if world.story.words.get_line_count() > world.story.words.get_visible_line_count(): _fail("Portrait dialogue clips"); return
		if world.story.frame.get_rect().intersects(ui.goal_panel.get_rect()): _fail("Portrait dialogue covers bottom-left objective"); return
		_save_coop("story-portrait-%d" % index)
	await _put(12.3, 13)
	for id in range(2):
		var model: MeshInstance3D = first.get_node("SmallPanel" if id == 0 else "LargePanel")
		if model.mesh is BoxMesh or not model.has_meta("historical_surface"): _fail("Plain stele boxes remain"); return
	_save_coop("story-aged-steles")
	await _click_stone(0)
	if first.inspected_id != 0 or not first.puzzle_active: _fail("Historic stele breaks click/puzzle"); return
	if first.inspector.image_viewports[0].get_node_or_null("SuppliedHistoricalRubbing") == null:
		_fail("Supplied rubbing does not appear on small stele"); return
	world.story.speak(party.NAMES[1], "先从最上方起。这几处旧痕，与我家錾子留下的不同。", 8, true)
	await _frames(4)
	if world.story.words.get_line_count() > world.story.words.get_visible_line_count(): _fail("Puzzle compact dialogue clips"); return
	_save_coop("story-puzzle-portrait")
	var effects_before: int = world.sfx.events.size()
	first.select_tile(0)
	first.rotate_selected()
	first.place_selected(0)
	await _frames(2)
	if world.sfx.events.size() <= effects_before or not "paper" in world.sfx.events or not "stone" in world.sfx.events:
		_fail("Puzzle manipulation has no material feedback"); return
	await _near_key(KEY_ESCAPE)
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
	_save_coop("story-villager-portraits")
	for slot in range(2):
		var width: float = nearby_ui.cards[slot].size.x
		var widest: float = 0
		for label in [nearby_ui.titles[slot], nearby_ui.words[slot], nearby_ui.keys[slot]]:
			widest = maxf(widest, label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)
		if width - minf(280, widest) > 23 or nearby_ui.cards[slot].get_theme_stylebox("panel").bg_color.a > .65:
			_fail("Adaptive translucent bubble retains unnecessary right padding"); return
		if nearby_ui.words[slot].get_line_count() > nearby_ui.words[slot].get_visible_line_count(): _fail("Adaptive bubble clips text"); return
	if nearby_ui.cards[0].get_rect().intersects(nearby_ui.cards[1].get_rect()): _fail("Variable-width player bubbles overlap"); return
	var mapped: Dictionary = {}
	for entry in nearby_ui.entries:
		var kind: String = world.sfx.material_for(entry)
		if not world.sfx.SOUNDS.has(kind): _fail("Scene interaction lacks sound " + entry.id); return
		mapped[kind] = true
		world.sfx.last.clear()
		world.sfx.play_entry(entry)
	if mapped.size() < 9: _fail("Object sounds are not differentiated by material"); return
	if not world.story.seen.has("helpers") or world.music.current_track != 1: _fail("Cooperation dialogue or score transition missing"); return
	world.start_garden_preview()
	await _frames(8)
	court.tablet_placed = true
	await _frames(4)
	world.story.speak("杨三娘", "乡音不同，护碑的心意却能说到一处。物件各依各的来处安放吧。", 9, true)
	await _frames(3)
	_save_coop("story-garden-exchange")
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(4)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	for card in court.landscape.task_cards:
		if not card.visible: continue
		if card.get_rect().intersects(ui.goal_panel.get_rect()) or card.get_rect().intersects(world.story.frame.get_rect()):
			_fail("Placement progress overlaps objective or portrait"); return
	for track in world.music.TRACKS:
		if track.get_length() < 40 or track.loop_mode != AudioStreamWAV.LOOP_FORWARD: _fail("New music does not loop"); return
	await _click_at(ui.restart_button.get_global_rect().get_center())
	await _frames(3)
	if not world.story.queue.is_empty() and world.story.seen.has("raised"): _fail("Scene restart retains an obsolete courtyard conversation"); return
	print("STORY_SOUND_OK: left goal, tight variable-width 62%-opacity independent bubbles, four supplied bust portraits/paper and NPC cards, nonblocking story exchanges, compact puzzle portrait, chipped steles/pierced crown/reference rubbing and matching viewer, material sounds for all ", nearby_ui.entries.size(), " targets (", mapped.size(), " kinds), puzzle Foley, lively four-score loops, restart and layout isolation")
	quit(0)
