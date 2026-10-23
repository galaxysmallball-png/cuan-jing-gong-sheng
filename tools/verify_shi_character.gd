extends "res://tools/verify_deng_character.gd"


func _run() -> void:
	art_scene_path = "res://scenes/characters/shi_aduo_character.tscn"
	art_name = "石阿朵"
	art_key = "shi"
	portrait_center = 1.31
	face_center = 1.48
	neck_center = 1.34
	show_apron_detail = true
	if capture:
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1600,1000)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
		await _render_studio()
		capture_viewport.size = Vector2i(1280,720)
	world = load("res://scenes/world.tscn").instantiate()
	if capture: capture_viewport.add_child(world)
	else:
		root.add_child(world)
		current_scene = world
	player = world.get_node("Player")
	party = world.get_node("Party")
	second = party.second_player
	ui = world.get_node("PartyUI")
	first = world.get_node("Spaces/Space01/Cooperation")
	bridge = world.get_node("Spaces/Space02/BridgeCooperation")
	court = world.get_node("Spaces/Space03/CourtyardCooperation")
	await _frames(30)
	if not _both_models(): _fail("Deng and Shi are not attached to their distinct roles"); return
	await _start_default_party()
	if not await _duo_walk(12.6,11.5): _fail("The two detailed characters cannot reach the courtyard"); return
	await _frames(30)
	var visual: Node3D = party._visual(second)
	var model: Node3D = visual.detailed_model
	if model.skeleton.get_bone_count() < 25 or model.animation_player.get_animation_list().size() < 6:
		_fail("Shi's actual skeleton or six clips are missing"); return
	if not _faces_front(visual): _fail("2P Shi cannot face forward"); return
	_save_coop("shi-in-game")
	await _press_key(KEY_LEFT,true)
	await _frames(40)
	await _press_key(KEY_LEFT,false)
	await _frames(25)
	if not _faces_back(visual): _fail("2P Shi cannot show her back"); return
	_save_coop("shi-in-game-back")
	await _frames(20)
	if not _faces_back(visual): _fail("Shi loses her heading while stopped"); return
	await _press_key(KEY_UP,true)
	await _frames(9)
	await _press_key(KEY_UP,false)
	if second.global_position.y < 1.0: _fail("Shi cannot jump"); return
	_save_coop("shi-jump")
	await _frames(60)
	party.switch_to(2,0)
	party.switch_to(0,1)
	var follower: CharacterBody3D = party.role_body(1)
	follower.set_physics_process(false)
	follower.velocity = Vector3.ZERO
	await _frames(5)
	if not _both_models() or not _faces_back(party._visual(follower)):
		_fail("Shi loses her model or heading as a follower"); return
	_save_coop("shi-follower")
	follower.set_physics_process(true)
	party.switch_to(1,0)
	await _frames(4)
	visual = party._visual(player)
	model = visual.detailed_model
	if not _both_models() or not _faces_back(visual): _fail("1P Shi loses her identity or heading"); return
	await _press_key(KEY_D,true)
	await _frames(30)
	await _press_key(KEY_D,false)
	await _frames(20)
	if not _faces_front(visual): _fail("1P cannot turn Shi back to the front"); return
	_save_coop("shi-player1")
	model.pose(0.15,0,1.5,true,true,false)
	if model.current_state != "push" or not _tools_stowed(model): _fail("Shi pushes with her hand tools still exposed"); return
	model.pose(0.15,0,0,true,false,true)
	if model.current_state != "carry" or not _tools_stowed(model): _fail("Shi carries with her hand tools still exposed"); return
	model.pose(0.1,0,0,true,false,false,true)
	if model.current_state != "inspect": _fail("Shi cannot inspect with her tools"); return
	model.pose(0,0,0,true,false,false)
	if _tools_stowed(model): _fail("Shi's mallet and chisel do not return after carrying"); return
	await _click_stone(1)
	await _key(KEY_ESCAPE)
	if player.interaction_locked: _fail("The new art blocks inscription inspection"); return
	await _tap("restart_lesson")
	await _frames(35)
	if not _both_models() or not _unique_ids() or party.active_id != 0 or party.second_id != 1:
		_fail("Reset loses the two detailed characters or unique identities"); return
	print("SHI_CHARACTER_OK: both distinct models, 25-bone rig and six clips, 2P/1P/follower ownership, front/back turning and retained heading, jumping, tool stowing/restoration, inspection and reset")
	quit(0)


func _both_models() -> bool:
	var names: Dictionary = {0: "DengShunian", 1: "ShiAduo", 2: "LaoQing", 3: "YangSanniang"}
	for body in party.all_bodies():
		var visual: Node3D = party._visual(body)
		if body.character_id in names:
			if visual.detailed_model == null or visual.detailed_model.name != names[body.character_id] or visual.get_node("Torso").visible:
				return false
		elif visual.detailed_model != null or not visual.get_node("Torso").visible:
			return false
	return true


func _tools_stowed(model: Node3D) -> bool:
	for bone_name in ["tool.L", "tool.R"]:
		var index: int = model.skeleton.find_bone(bone_name)
		if index < 0 or model.skeleton.get_bone_pose_scale(index).length() > 0.01: return false
	return true
