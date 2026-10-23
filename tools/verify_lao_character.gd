extends "res://tools/verify_shi_character.gd"


func _run() -> void:
	art_scene_path = "res://scenes/characters/lao_qing_character.tscn"
	art_name = "老箐"
	art_key = "lao"
	portrait_center = 1.43
	face_center = 1.58
	neck_center = 1.41
	show_apron_detail = true
	studio_subtitle = "束发头巾 / 深色披毡 / 粗布挎袋 / 马铃与藤杖 / 编织草鞋"
	accessory_detail_title = "披毡、腰带、马铃与藤杖"
	accessory_center = 0.98
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
	await _frames(25)
	if not _both_models(): _fail("Three distinct detailed models are not attached to their roles"); return
	await _start_default_party()
	party.switch_to(2,0)
	if not await _duo_walk(12.6,11.5): _fail("Lao cannot walk to the stele courtyard"); return
	await _frames(30)
	var visual: Node3D = party._visual(player)
	var model: Node3D = visual.detailed_model
	if model.name != "LaoQing" or model.skeleton.get_bone_count() != 25 or model.animation_player.get_animation_list().size() < 6:
		_fail("Lao's distinct model, 25-bone rig or six clips are missing"); return
	for bone_name in ["cloak_back", "cloak.L", "cloak.R", "pouch", "charms", "ribbon", "tool.L"]:
		if model.skeleton.find_bone(bone_name) < 0: _fail("Missing Lao accessory bone: "+bone_name); return
	if not _faces_front(visual): _fail("1P Lao cannot face forward"); return
	_save_coop("lao-in-game")
	await _press_key(KEY_A,true)
	await _frames(40)
	await _press_key(KEY_A,false)
	await _frames(25)
	if not _faces_back(visual): _fail("1P Lao cannot expose his actual back"); return
	_save_coop("lao-in-game-back")
	await _frames(20)
	if not _faces_back(visual): _fail("Lao turns to the front after stopping"); return
	await _press_key(KEY_W,true)
	await _frames(9)
	await _press_key(KEY_W,false)
	if player.global_position.y <= 1.0: _fail("Lao cannot jump"); return
	_save_coop("lao-jump")
	await _frames(60)
	party.switch_to(0,0)
	party.switch_to(2,1)
	await _frames(4)
	visual = party._visual(second)
	if not _both_models() or not _faces_back(visual): _fail("2P Lao loses his identity or heading"); return
	await _press_key(KEY_RIGHT,true)
	await _frames(30)
	await _press_key(KEY_RIGHT,false)
	await _frames(20)
	if not _faces_front(visual): _fail("2P Lao cannot turn forward"); return
	_save_coop("lao-player2")
	await _press_key(KEY_LEFT,true)
	await _frames(30)
	await _press_key(KEY_LEFT,false)
	await _frames(20)
	if not _faces_back(visual): _fail("2P Lao cannot turn back"); return
	party.switch_to(1,1)
	var follower: CharacterBody3D = party.role_body(2)
	follower.set_physics_process(false)
	follower.velocity = Vector3.ZERO
	await _frames(5)
	if not _both_models() or not _faces_back(party._visual(follower)):
		_fail("Lao loses his detailed model or heading as a follower"); return
	_save_coop("lao-follower")
	follower.set_physics_process(true)
	party.switch_to(2,0)
	await _frames(4)
	model = party._visual(player).detailed_model
	for state in ["push", "carry", "jump"]:
		model.pose(0.15,0,1.5,state!="jump",state=="push",state=="carry")
		if model.current_state != state or not _staff_stowed(model): _fail("Lao's staff obstructs "+state); return
	model.pose(0.15,0,0,true,false,false,true)
	if model.current_state != "inspect" or _staff_stowed(model): _fail("Lao cannot inspect while keeping his staff"); return
	model.pose(0,0,0,true,false,false)
	if _staff_stowed(model): _fail("Lao's staff does not return to idle"); return
	await _click_stone(1)
	await _key(KEY_ESCAPE)
	if player.interaction_locked: _fail("Lao art blocks the stele viewer"); return
	await _tap("restart_lesson")
	await _frames(35)
	if not _both_models() or not _unique_ids() or party.active_id!=0 or party.second_id!=1 or party.role_directions[2]!=1.0:
		_fail("Reset loses detailed models, roles or Lao's initial heading"); return
	print("LAO_CHARACTER_OK: three distinct models, 25 bones/six clips, 1P/2P/follower, front/back and held heading, jumping, staff stow/restore, stele inspection and reset")
	quit(0)


func _staff_stowed(model: Node3D) -> bool:
	var index: int = model.skeleton.find_bone("tool.L")
	return index >= 0 and model.skeleton.get_bone_pose_scale(index).length() < 0.01
