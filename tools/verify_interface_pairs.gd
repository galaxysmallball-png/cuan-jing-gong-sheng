extends "res://tools/verify_nearby_interactions.gd"

const PartyScript = preload("res://scripts/party.gd")


func _initialize() -> void:
	capture = "--capture-interface" in OS.get_cmdline_user_args()
	create_timer(70, true).timeout.connect(func(): _fail("Interface / role pairs test timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Real renderer required for interface images"); return
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
	await _frames(6)
	if not ui.title_art.visible or ui.title_art.texture.resource_path != "res://assets/interface/title_cover.png" \
		or ui.heading.visible or ui.detail.visible or world.room_label.visible or ui.hud.visible:
		_fail("The cover is obscured by legacy headings or HUD"); return
	_save_coop("interface-title")
	# Every possible drawn pair gets two disjoint owned roles, preserving rescue.
	var combinations: int = 0
	for a in range(4):
		for b in range(4):
			if a == b: continue
			var chosen: Array[int] = [a, b]
			var pairs: Array[PackedInt32Array] = PartyScript.pairs_for(chosen)
			if pairs.size() != 2 or pairs[0].size() != 2 or pairs[1].size() != 2: _fail("Pair ownership has a wrong size"); return
			var flattened: Array[int] = []
			for pair in pairs:
				for role in pair: flattened.append(role)
			flattened.sort()
			if flattened != [0, 1, 2, 3] or ((1 in pairs[0]) == (2 in pairs[0])): _fail("A draw duplicates roles or makes the bridge impossible"); return
			party.started = false
			if not party.assign_opening_roles(chosen): _fail("A valid drawn pair was rejected"); return
			party.started = true
			party.set_controls(true)
			for slot in range(2):
				for role in range(4):
					var before: Array[int] = [party.active_id, party.second_id]
					var result: bool = party.switch_to(role, slot)
					if result != (role in pairs[slot]) or not _unique_ids(): _fail("A player can access an unowned active or inactive role"); return
					if not result and before != [party.active_id, party.second_id]: _fail("Rejected ownership changes identities"); return
				var current: int = party.active_id if slot == 0 else party.second_id
				party.cycle(slot)
				if (party.active_id if slot == 0 else party.second_id) == current: _fail("Owned companion cannot be reached by cycling"); return
				party.cycle(slot)
				if (party.active_id if slot == 0 else party.second_id) != current: _fail("Cycling visits more than two owned roles"); return
			combinations += 1
	party.started = false
	party.reset_positions(true)
	party.set_controls(false)
	ui.primary.pressed.emit()
	await _frames(55)
	if not ui.opening_draw.visible or ui.opening_draw.get_node("DrawBackground").texture.resource_path != "res://assets/interface/card_draw_background.png":
		_fail("The supplied mountain image is missing from the draw"); return
	_save_coop("interface-draw")
	await _near_key(KEY_ESCAPE)
	_save_coop("interface-draw-pairs")
	await _near_key(KEY_ENTER)
	await _frames(6)
	if not party.started or ui.hud.visible or world.tip_label.visible or not ui.hint_button.visible:
		_fail("Gameplay still exposes the old persistent key legend"); return
	for child in ui.get_children():
		if child is Button and child not in [ui.satchel_button, ui.restart_button, ui.sound_button, ui.achievement_button] and child.position.x > 550 and child.position.y < 120:
			_fail("The upper-right role grid still exists"); return
	var owned_before: Array[PackedInt32Array] = party.owned_roles.duplicate(true)
	await _put(12.25, 12.6)
	await _focus_id(0, "stele_0")
	if nearby_ui.cards[0].size.x > 280 or nearby_ui.cards[0].size.y > 70 or nearby_ui.words[0].visible:
		_fail("Collapsed interaction bubble is not compact"); return
	_save_coop("interface-clean-game")
	await _click_at(ui.hint_button.get_global_rect().get_center())
	if ui.screen != ui.Screen.HELP or not paused or not ui.hint_panel.visible or not ui.hint_panel.pairs.text.contains("专属"):
		_fail("The top-left hint button does not reveal controls and owned roles"); return
	_save_coop("interface-hint")
	var at: Vector3 = player.global_position
	await _near_key(KEY_F)
	await _near_key(KEY_TAB)
	if player.global_position != at or first.inspected_id != -1 or party.owned_roles != owned_before:
		_fail("The hint panel leaks inputs to the world"); return
	await _near_key(KEY_ESCAPE)
	if paused or ui.screen != ui.Screen.GAME: _fail("Closing hints leaves the game paused"); return
	await _focus_id(0, "stele_0")
	await _near_key(KEY_F)
	await _click_at(ui.hint_button.get_global_rect().get_center())
	if ui.screen != ui.Screen.HELP or not first.puzzle_active: _fail("Hints cannot be read from the puzzle"); return
	await _near_key(KEY_ESCAPE)
	if paused or not first.puzzle_active or not player.interaction_locked: _fail("Closing hints also closes the underlying puzzle"); return
	await _near_key(KEY_ESCAPE)
	Input.action_press("restart")
	await _near_key(KEY_R)
	Input.action_release("restart")
	if party.owned_roles != owned_before: _fail("R changes role ownership"); return
	Input.action_press("restart_lesson")
	await _near_key(KEY_T)
	Input.action_release("restart_lesson")
	if party.owned_roles != PartyScript.pairs_for([0, 1]): _fail("T leaves ownership inconsistent with reset roles"); return
	# Capture the smaller parchment dialogue in the actual NPC scene.
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
	_save_coop("interface-small-dialogue")
	for slot in range(2):
		if nearby_ui.words[slot].get_line_count() > nearby_ui.words[slot].get_visible_line_count(): _fail("Small dialogue truncates text"); return
	print("INTERFACE_PAIRS_OK: original cover/draw images, compact parchment bubbles, top-left mouse hints/puzzle return, clean HUD, all ", combinations,
		" draw pairs with two exclusive roles each, active/inactive rejection, cycling, rescue compatibility, R/T")
	quit(0)
