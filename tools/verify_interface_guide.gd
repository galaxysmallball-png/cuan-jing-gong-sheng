extends "res://tools/verify_cooperative_experience.gd"

var watchdog: SceneTreeTimer
var guide: CanvasLayer


func _initialize() -> void:
	capture=true
	watchdog=create_timer(180,true)
	watchdog.timeout.connect(func(): _fail("Interface / guidance check timed out"))
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
	guide=world.guidance
	await _frames(12)
	if guide.rail.visible or guide.cards[0].visible or ui.goal_panel.visible: _fail("Gameplay guidance leaks onto cover"); return
	await _start_default_party()
	await _clear_story()
	if not guide.rail.visible or not guide.cards[0].visible or not guide.cards[1].visible or not guide.tasks[0].text.contains("小爨"):
		_fail("First-act route or per-player starting guidance is missing"); return
	if not _check_layout(): return
	_save_coop("guide-first-act")
	await _put(6.3,7.2)
	await _frames(4)
	if not world.experience.first_walk_finished or not world.experience.coach_hidden or world.experience.coach.visible:
		_fail("Learned first movement does not collapse repeated teaching"); return
	await _click_at(world.experience.coach_tab.get_global_rect().get_center())
	if world.experience.coach_hidden or not world.experience.coach.visible: _fail("Compact teaching cannot be reopened"); return
	await _near_key(KEY_H)
	if not paused or ui.screen!=ui.Screen.HELP or guide.rail.visible or guide.cards[0].visible or ui.goal_panel.visible:
		_fail("Help does not pause / replace gameplay panels"); return
	if not ui.hint_panel.current_goal.text.contains(world.objective().text.get_slice("\n",0)) or not ui.hint_panel.pairs.text.contains("专属"):
		_fail("Help lacks current objective / actual role assignments"); return
	for label in ui.hint_panel.find_children("*","Label",true,false):
		if label.is_visible_in_tree() and not _fits(label): return
	_save_coop("guide-help-current-goal")
	await _near_key(KEY_ESCAPE)
	world.start_creek_preview()
	await _frames(20)
	await _clear_story()
	if not guide.stages[0].text.begins_with("✓") or not guide.stages[1].text.begins_with("●"):
		_fail("Route marks visited scenes as completed instead of actual chapter progress"); return
	if guide.suggestions[0].role!=2 or not guide.actions[0].text.contains("老箐") or not guide.actions[1].disabled:
		_fail("Watermark task does not explain which owner can switch to Lao"); return
	var other_role: int=party.second_id
	var inventory: Array=world.keepsakes.collected.duplicate()
	await _click_at(guide.actions[0].get_global_rect().get_center())
	if party.active_id!=2 or party.second_id!=other_role or world.keepsakes.collected!=inventory or bridge.step!=0:
		_fail("Guidance switch steals the other player's role or completes a task / pickup"); return
	await _put(22.5,23.4)
	await _press_key(KEY_E,true)
	await _frames(22)
	await _clear_story()
	if not guide.bars[0].visible or guide.bars[0].value<=0 or not guide.states[0].text.contains("%"):
		_fail("Real valid long hold has no per-player percent"); return
	if guide.bars[1].visible: _fail("Other owner's progress is credited to a noncontributing role"); return
	if not _check_layout(): return
	_save_coop("guide-creek-owner-and-hold")
	await _press_key(KEY_E,false)
	await _frames(8)
	if guide.bars[0].visible: _fail("Released hold leaves a false progress bar"); return
	player.global_position=Vector3(23,.75,.8)
	player.velocity=Vector3.ZERO
	await _frames(8)
	if world.keepsakes.in_reach(2,player) or not guide._pickup(player,2).text.contains("向里靠近"):
		_fail("Keepsake prompt ignores the item's real depth / pickup radius"); return
	bridge.step=5
	bridge.bridge_ready=true
	bridge.helpers_called=true
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	await _put(38.4,35)
	await _frames(80)
	await _clear_story()
	if not guide.tasks[0].text.contains("收绳") or not guide.tasks[1].text.contains("顶住"):
		_fail("Rescue guidance does not distinguish rope regulation from steady support"); return
	if not _check_layout(): return
	_save_coop("guide-rope-roles")
	world.start_garden_preview()
	await _frames(220)
	await _clear_story()
	world.keepsakes.collected[0]=false
	court.tablet_placed=true
	court.items_done.fill(false)
	party.switch_to(0,0)
	await _put(47,48)
	await _clear_story()
	if not guide.tasks[0].text.contains("拓片") or guide.suggestions[0].target!=world.keepsakes.POSITIONS[0].x:
		_fail("Missing keepsake does not guide back to its actual original location"); return
	if not _check_layout(): return
	_save_coop("guide-court-missing-keepsake")
	world.keepsakes.collected.fill(true)
	court.items_done[0]=true
	await _frames(4)
	if guide.suggestions[0].role!=2: _fail("Finished current role does not suggest the owner's unfinished reserve"); return
	court.items_done.fill(true)
	court.items_done[4]=false
	court.items_done[5]=false
	court.items_done[6]=false
	world.experience.design_done=true
	court.oil_carriers.assign([-1,-1,-1])
	await _put(43.7,44.1)
	await _clear_story()
	if not guide.tasks[0].text.contains("按一下") or not guide.tasks[0].text.contains("领取"):
		_fail("Lamp pickup is incorrectly described as a long hold"); return
	_save_coop("guide-take-lamp-once")
	world.story.speak("杨三娘","先听同伴把话说完，再接着动手。",3,true)
	await _frames(3)
	if not world.story.frame.visible or guide.cards[0].visible or guide.cards[1].visible:
		_fail("Guidance footers overlap the active dialogue"); return
	await _clear_story()
	if not guide.cards[0].visible: _fail("Dialogue leaves guidance permanently hidden"); return
	if not ui.blocks_world_click(guide.actions[0].get_global_rect().get_center()): _fail("Footer click can fall through to scene objects"); return
	await _tap("restart_lesson")
	await _frames(8)
	await _clear_story()
	if not guide.tasks[0].text.contains("小爨") or world.experience.first_walk_finished:
		_fail("Fresh run keeps stale chapter / learned movement guidance"); return
	party.local_coop=false
	await _frames(3)
	if guide.cards[1].visible: _fail("Second-player guidance leaks into solo mode"); return
	await _near_key(KEY_H)
	if ui.hint_panel.second_controls.visible or ui.hint_panel.second_heading.text!="单人同行": _fail("Solo help still teaches a nonexistent second controller"); return
	await _near_key(KEY_ESCAPE)
	watchdog.timeout.disconnect(watchdog.timeout.get_connections()[0].callable)
	_stop_test_audio(world)
	world.queue_free()
	await process_frame
	await process_frame
	await _drain_test_audio()
	print("INTERFACE_GUIDE_OK: actual completion route, per-player first/creek/court next tasks, actual owner switch without pickup or task side effects, valid long-hold percent and release, separate rescue roles, missing keepsake return target, single-press lamp wording, help current goal / roles / solo, teaching collapse/reopen/reset, modal and story priority, no visible text clipping or panel collisions / world-click leakage")
	quit(0)


func _clear_story() -> void:
	world.story.queue.clear()
	world.story.current={}
	world.story.remaining=0
	await _frames(3)


func _check_layout() -> bool:
	var bounds:=Rect2(Vector2.ZERO,Vector2(1280,720))
	for card in guide.cards:
		if not card.visible: continue
		if not bounds.encloses(card.get_rect()) or card.get_rect().intersects(ui.goal_panel.get_rect()): _fail("Per-player footer clips or covers current objective"); return false
	for slot in range(2):
		if guide.cards[slot].visible and guide.tasks[slot].get_rect().intersects(guide.actions[slot].get_rect()): _fail("Footer wording overlaps its switch button"); return false
	for label in guide.find_children("*","Label",true,false):
		if label.is_visible_in_tree() and not _fits(label): return false
	for slot in range(2):
		if nearby_ui.cards[slot].visible:
			for panel in [guide.rail,world.experience.coach,world.experience.coach_tab,world.experience.rope_panel]:
				if panel.visible and panel.get_rect().intersects(nearby_ui.cards[slot].get_rect()): _fail("Approach card overlaps fixed teaching or route UI"); return false
	return true
