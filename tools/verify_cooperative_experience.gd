extends "res://tools/verify_stone_roof.gd"


func _initialize() -> void:
	capture="--capture-cooperative-experience" in OS.get_cmdline_user_args()
	OS.set_environment("CUAN_ACHIEVEMENT_PROFILE",ProjectSettings.globalize_path("res://previews/cooperative-experience-profile.json"))
	create_timer(200,true).timeout.connect(func(): _fail("Cooperative experience check timed out"))
	call_deferred("_run")


func _run() -> void:
	if capture:
		root.mode=Window.MODE_MINIMIZED
		OS.low_processor_usage_mode=false
		capture_viewport=SubViewport.new()
		capture_viewport.size=Vector2i(1280,720)
		capture_viewport.own_world_3d=true
		capture_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d=Viewport.MSAA_4X
		root.add_child(capture_viewport)
	world=load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else: root.add_child(world); current_scene=world
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
	var experience: CanvasLayer = world.experience
	await _frames(3)
	if not experience.coach.visible or experience.coach_stage!="walk": _fail("Contextual first-move teaching is missing"); return
	if not _fits(experience.coach_words) or not _fits(ui.goal_panel.body): return
	var count_width: float = ui.goal_panel.count.get_theme_font("font").get_string_size(ui.goal_panel.count.text,HORIZONTAL_ALIGNMENT_LEFT,-1,ui.goal_panel.count.get_theme_font_size("font_size")).x
	if count_width>ui.goal_panel.count.size.x: _fail("Goal progress text clips beside its title"); return
	_save_coop("cooperation-first-move-guide")
	experience.coach_hidden=true
	await _frames(2)
	await _click_at(experience.coach_tab.get_global_rect().get_center())
	if experience.coach_hidden: _fail("Tutorial cannot be restored after hiding it"); return
	await _put(12.5,13)
	await _click_stone(0)
	if not await _complete_rubbing(): return
	await _press_key(KEY_E,true)
	await _frames(2)
	if first.step!=1 or not first.clues[0]: _fail("One keypress does not share a clue immediately"); return
	party.switch_to(2,0)
	await _frames(12)
	if first.clues[2]: _fail("Held share key collects another role without a new press"); return
	await _press_key(KEY_E,false)
	await _press_key(KEY_P,true)
	await _press_key(KEY_P,false)
	party.switch_to(3,1)
	await _dual_hold()
	if first.step!=4 or not first.CLUES[0].contains("1、3、5") or not first.CLUES[3].contains("2、4、6"):
		_fail("Alternating clues are not complementary or cannot be shared"); return
	_save_coop("cooperation-alternating-clues")
	await _finish_observation()
	await _frames(125)
	if not first.gate_open: _fail("Complementary clues cannot complete the main puzzle"); return
	world.start_creek_preview()
	bridge.material_delivered=true
	bridge.timber_prepared=true
	bridge.helpers_called=true
	bridge.bridge_ready=true
	bridge.step=5
	bridge.get_node("BridgeAssembly").visible=true
	bridge.get_node("BridgeAssembly").rotation.z=0
	bridge.get_node("BridgeBody/Collision").disabled=false
	party.switch_to(2,0)
	party.switch_to(1,1)
	await _put(38.4,35)
	for index in range(party.followers.size()):
		party.followers[index].global_position=Vector3(35.7+index*.6,.75,.15)
		party.followers[index].velocity=Vector3.ZERO
	await _frames(100)
	if party.nearby_count(35)!=4: _fail("Rope challenge fixture lacks the four grounded companions"); return
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(210)
	if bridge.gap_stabilized or bridge.rope_tension<.95 or not experience.rope_panel.visible:
		_fail("Constant holding bypasses tension regulation or the gauge is missing"); return
	_save_coop("cooperation-rope-too-tight")
	ui._open_audio_settings()
	var saved_tension: float = bridge.rope_tension
	var saved_progress: float = bridge.action_progress
	await _frames(18)
	if bridge.rope_tension!=saved_tension or bridge.action_progress!=saved_progress: _fail("Rope challenge runs under paused settings"); return
	ui._close_audio_settings()
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(85)
	await _press_key(KEY_P,true)
	var saved_green: bool = false
	for frame in range(420):
		if bridge.gap_stabilized: break
		if bridge.rope_tension<.48 and not Input.is_action_pressed("interact"): await _press_key(KEY_E,true)
		elif bridge.rope_tension>.60 and Input.is_action_pressed("interact"): await _press_key(KEY_E,false)
		await _frames(1)
		if bridge.action_progress>.8 and not saved_green:
			_save_coop("cooperation-rope-green-band")
			saved_green=true
	await _press_key(KEY_E,false)
	await _press_key(KEY_P,false)
	if not bridge.gap_stabilized or not saved_green:
		_fail("Physical rope rescue failed: progress=%s tension=%s held=%s post=%s nearby=%s role1=%s role2=%s"%[bridge.action_progress,bridge.rope_tension,bridge.steady_held,bridge.rope_at_post,party.nearby_count(35),party.role_body(1).global_position,party.role_body(2).global_position]); return
	world.start_garden_preview()
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	await _put(50.3,49.7)
	await _dual_hold()
	await _frames(ceili(court.RAISE_SECONDS*60)+8)
	if not court.tablet_placed: _fail("New rescue does not allow supported courtyard raising"); return
	party.switch_to(0,0)
	party.switch_to(1,1)
	await _put(46.2,49.0)
	await _dual_hold()
	party.switch_to(2,0)
	party.switch_to(3,1)
	await _put(51.7,52.8)
	Input.action_press("interact")
	Input.action_press("p2_interact")
	await _frames(105)
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(5)
	if not experience.overlay.visible or not paused or ui.screen!=ui.Screen.ARRANGE or court.lamp_count!=4:
		_fail("Four personal keepsakes do not lead to joint courtyard composition"); return
	_save_coop("cooperation-design-two-voices")
	for node in experience.design_panel.find_children("*","Label",true,false):
		if not _fits(node): return
	var positions: Array[Vector3] = [player.global_position,second.global_position]
	for code in [KEY_R,KEY_T,KEY_B,KEY_C,KEY_H]: await _near_key(code)
	if not experience.overlay.visible or player.global_position!=positions[0] or second.global_position!=positions[1] or not court.tablet_placed:
		_fail("Design modal leaks movement/reset/other overlays"); return
	await _near_key(KEY_ESCAPE)
	await _frames(5)
	if experience.overlay.visible or paused or experience.design_done: _fail("Canceling design traps the game or finishes it"); return
	await _click_at(experience.coach_action.get_global_rect().get_center())
	await _near_key(KEY_A)
	await _near_key(KEY_RIGHT)
	await _near_key(KEY_RIGHT)
	if experience.choices!=[0,2]: _fail("Each controller cannot select its own pattern"); return
	for cloth in get_nodes_in_group("shared_court_cloths"):
		var index: int = cloth.get_meta("cloth_index")
		var mat: ShaderMaterial = cloth.material_override
		if index==0 and mat.get_shader_parameter("motif")!=2: _fail("Left choice does not appear on real cloth"); return
		if index==6 and mat.get_shader_parameter("motif")!=1: _fail("Right choice does not appear on real cloth"); return
		if index==3 and (mat.get_shader_parameter("motif")!=2 or mat.get_shader_parameter("partner_motif")!=1):
			_fail("Central cloth does not interleave both contributions"); return
	await _near_key(KEY_E)
	if experience.design_done or not experience.overlay.visible: _fail("One player confirms for both"); return
	_save_coop("cooperation-design-first-confirmed")
	await _near_key(KEY_P)
	await _frames(6)
	if not experience.design_done or paused or not court.composition_ready() or not world.archive_text().contains(experience.design_summary()):
		_fail("Joint design does not persist in scene / archive or unlock lamps"); return
	await _detail_view("cooperation-shared-cloth",Vector3(50,5.8,9),Vector3(50,4.9,-4),23)
	world.restart_current_scene()
	# Restart replays the four-person arrival; control is intentionally held
	# until that transition is complete.
	await _frames(ceili(court.ARRIVAL_SECONDS*60)+8)
	if experience.design_done or true in experience.confirmed or experience.overlay.visible or paused or party.movement_locked():
		_fail("Courtyard restart leaves shared design, pause or locks"); return
	for cloth in get_nodes_in_group("shared_court_cloths"):
		if cloth.material_override.get_shader_parameter("partner_motif")!=-1: _fail("Restart leaves woven preview ink"); return
	print("COOPERATIVE_EXPERIENCE_OK: contextual dismissible/restorable teaching, immediate per-role share with held-key isolation and alternating evidence, constant rope holding cannot win, actual physical-key tension regulation with pause-safe support, four keepsakes lead to two independent courtyard choices, modal input/cancel/reopen, real seven-cloth changes and dual-motif center, both confirmations, archive result, lamp unlock and restart cleanup")
	quit(0)


func _fits(label: Label) -> bool:
	if label.get_line_count()>label.get_visible_line_count():
		_fail("Cooperation text clips: "+label.text); return false
	return true
