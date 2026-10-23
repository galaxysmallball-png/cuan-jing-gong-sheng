extends "res://tools/verify_local_coop.gd"

var nearby_ui: CanvasLayer
var checked: int = 0


func _initialize() -> void:
	capture = "--capture-nearby" in OS.get_cmdline_user_args()
	create_timer(100, true).timeout.connect(func(): _fail("Nearby interaction check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		if DisplayServer.get_name() == "headless": _fail("Capture requires a real renderer"); return
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
	if nearby_ui.cards[0].visible or not nearby_ui.nearby(0).is_empty(): _fail("Title leaks proximity prompts"); return
	await _start_default_party()
	await _put(first.get_node("SmallPanel").global_position.x, first.get_node("LargePanel").global_position.x)
	await _focus_id(0, "stele_0")
	await _focus_id(1, "stele_1")
	if not nearby_ui.cards[0].visible or not nearby_ui.cards[1].visible: _fail("Both players do not get a local prompt"); return
	_save_coop("nearby-two-steles")
	await _near_key(KEY_F)
	if first.inspected_id != 0 or not party.movement_locked(): _fail("Approach + F does not open the actual stele"); return
	await _frames(2)
	if nearby_ui.cards[0].visible: _fail("Prompts cover the inspected puzzle"); return
	await _near_key(KEY_ESCAPE)
	await _near_key(KEY_SLASH)
	if first.inspected_id != 1: _fail("Second player's slash cannot inspect the large stele"); return
	await _near_key(KEY_ESCAPE)
	await _near_key(KEY_B)
	await _near_key(KEY_F)
	if ui.screen != ui.Screen.SATCHEL or first.inspected_id != -1 or nearby_ui.cards[0].visible:
		_fail("Satchel allows proximity input through"); return
	await _near_key(KEY_B)
	ui._open_archive()
	nearby_ui.activate(0)
	await _frames(2)
	if nearby_ui.cards[0].visible or first.inspected_id != -1: _fail("Archive allows proximity input through"); return
	ui._close_archive()
	# Fixtures seed prerequisites; F and slash must never advance construction.
	world.start_creek_preview()
	bridge.step = 4
	bridge.helpers_called = true
	bridge._helpers.visible = true
	bridge._a_cai.position = Vector3(9, 0, -2)
	bridge._a_qiang.position = Vector3(10, 0, -2)
	await _put(29, 30)
	await _focus_id(0, "a_cai")
	await _focus_id(1, "a_qiang")
	await _near_key(KEY_F)
	await _near_key(KEY_SLASH)
	if nearby_ui.reading != ["a_cai", "a_qiang"] or bridge.building or bridge.bridge_ready:
		_fail("Independent villager chats fail or silently finish a task"); return
	if not nearby_ui.titles[0].text.contains("苗族") or not nearby_ui.titles[1].text.contains("壮族"):
		_fail("Villager bubbles omit ethnicity"); return
	_save_coop("nearby-creek-villagers")
	await _near_key(KEY_F)
	if nearby_ui.pages[0] != 1 or nearby_ui.pages[1] != 0: _fail("One player advances the other's dialogue"); return
	await _near_key(KEY_F)
	for remaining in range(6):
		if nearby_ui.reading[0].is_empty(): break
		await _near_key(KEY_F)
	if not nearby_ui.reading[0].is_empty(): _fail("Compact paginated dialogue cannot be closed"); return
	# Both bubbles may share a head, but their cards must not overlap.
	await _focus_id(0, "a_qiang")
	await _frames(3)
	if nearby_ui.cards[0].get_rect().intersects(nearby_ui.cards[1].get_rect()): _fail("Nearby bubbles overlap"); return
	await _put(21, 21.4)
	if "a_cai" in nearby_ui.focus or "a_qiang" in nearby_ui.reading: _fail("Leaving the NPC retains its bubble"); return
	world.start_garden_preview()
	court.tablet_placed = true
	for index in range(4): court.items_done[index] = true
	court.lamp_count = 4
	court.landscape.sync_state()
	await _frames(150)
	await _put(42.5, 46.2)
	await _focus_id(0, "pu_mo")
	await _focus_id(1, "yu_nan")
	await _near_key(KEY_F)
	await _near_key(KEY_SLASH)
	if nearby_ui.reading != ["pu_mo", "yu_nan"] or court.oil_carriers != [-1, -1, -1]:
		_fail("Garden chats take lamps or miss the villagers"); return
	_save_coop("nearby-garden-villagers")
	await _focus_id(0, "lamp_table")
	await _near_key(KEY_F)
	if not nearby_ui.words[0].text.contains("领取") or court.oil_carriers != [-1, -1, -1]: _fail("Lamp examination changes ownership"); return
	_save_coop("nearby-lamp-table")
	# Every visible registered prop can actually be selected in its walking lane.
	bridge.bridge_ready = true
	bridge.gap_stabilized = true
	bridge.get_node("BridgeBody/Collision").disabled = false
	bridge._tablet.visible = true
	court.landscape.scroll.visible = true
	for entry in nearby_ui.entries:
		if not nearby_ui._available(entry): continue
		var x: float = clampf(nearby_ui._point(entry).x, 1, 59)
		await _put(x, x + 0.2)
		if not await _focus_id(0, entry.id): return
		checked += 1
		nearby_ui.reading[0] = entry.id
		for page in range(nearby_ui._lines(entry, 0).size()):
			nearby_ui.pages[0] = page
			await _frames(2)
			if nearby_ui.words[0].get_line_count() > nearby_ui.words[0].get_visible_line_count():
				_fail("Bubble text clipped: " + entry.id + " / " + nearby_ui.words[0].text); return
	if checked < 35: _fail("Too few scene props are reachable: " + str(checked)); return
	await _put(43.7, 43.5)
	await _focus_id(0, "lamp_table")
	await _near_key(KEY_F)
	await _near_key(KEY_R)
	if nearby_ui.reading != ["", ""] or court.lamp_count != 4: _fail("R loses progress or retains a stale conversation"); return
	await _near_key(KEY_T)
	await _frames(3)
	if bridge.helpers_called or court.get_node("Residents").visible or court.lamp_count != 0 or nearby_ui.reading != ["", ""]:
		_fail("T retains stale villagers, lamps or conversation"); return
	# Single-player fallback has no phantom second bubble or slash action.
	party.local_coop = false
	await _put(9.3, 9.5)
	await _frames(3)
	if nearby_ui.cards[1].visible: _fail("Single-player shows a phantom second bubble"); return
	print("NEARBY_INTERACTIONS_OK: four villagers, independent keyboard chats, reachable props=", checked,
		", stele viewer, target cycling, no overlap, no clipping, leave/hide, satchel/archive/puzzle isolation, no task side effects, R/T, single-player")
	quit(0)


func _put(x1: float, x2: float) -> void:
	player.global_position = Vector3(x1, 0.75, 0)
	second.global_position = Vector3(x2, 0.75, 0)
	player.velocity = Vector3.ZERO
	second.velocity = Vector3.ZERO
	world._update_camera(0, true)
	await _frames(5)


func _focus_id(slot: int, id: String) -> bool:
	for attempt in range(nearby_ui.entries.size() + 1):
		nearby_ui._choose(slot)
		if nearby_ui.focus[slot] == id:
			await _frames(2)
			return true
		await _near_key(KEY_G if slot == 0 else KEY_PERIOD)
	_fail("Cannot select nearby target " + id + " at " + str(party.human_players()[slot].global_position))
	return false


func _near_key(code: int) -> void:
	# A pushed SubViewport UI event does not update Input's polled action state.
	# R/T are polled by the chapters, while the same key event clears the bubbles.
	if code in [KEY_R, KEY_T]: Input.action_press("restart" if code == KEY_R else "restart_lesson")
	await _key(code)
	if code in [KEY_R, KEY_T]: Input.action_release("restart" if code == KEY_R else "restart_lesson")
	await _frames(2)
