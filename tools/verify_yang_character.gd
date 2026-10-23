extends "res://tools/verify_shi_character.gd"


func _run() -> void:
	art_scene_path = "res://scenes/characters/yang_sanniang_character.tscn"
	art_name = "杨三娘"
	art_key = "yang"
	portrait_center = 1.40
	face_center = 1.53
	neck_center = 1.38
	show_apron_detail = true
	studio_subtitle = "深色头巾 / 蓝衣棕马甲 / 扁担竹篮 / 布卷与干果 / 货郎腰具"
	accessory_detail_title = "腰间布囊、铜罗盘与小杆秤"
	accessory_center = 0.87
	studio_spacing = 1.43
	studio_size = 2.78
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
	if capture:
		capture_viewport.add_child(world)
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
	if not _both_models() or not _unique_ids():
		_fail("Four distinct detailed models are not attached to their roles"); return
	await _start_default_party()
	party.switch_to(3,0)
	if not await _duo_walk(12.6,11.5):
		_fail("Yang cannot walk to the stele courtyard"); return
	await _frames(30)
	var visual: Node3D = party._visual(player)
	var model: Node3D = visual.detailed_model
	if model.name != "YangSanniang" or model.skeleton.get_bone_count() != 27 or model.animation_player.get_animation_list().size() < 6:
		_fail("Yang's distinct model, 27-bone rig or six clips are missing"); return
	for bone_name in ["veil", "skirt.L", "skirt.R", "skirt.back", "pouch", "charms", "yoke", "cargo.L", "cargo.R"]:
		if model.skeleton.find_bone(bone_name) < 0:
			_fail("Missing Yang accessory bone: " + bone_name); return
	var yoke: int = model.skeleton.find_bone("yoke")
	for bone_name in ["cargo.L", "cargo.R"]:
		if model.skeleton.get_bone_parent(model.skeleton.find_bone(bone_name)) != yoke:
			_fail("Cargo is not parented to the stowable shoulder pole"); return
	if not _faces_front(visual):
		_fail("1P Yang cannot face forward"); return
	_save_coop("yang-in-game")
	await _press_key(KEY_A,true)
	await _frames(40)
	await _press_key(KEY_A,false)
	await _frames(25)
	if not _faces_back(visual):
		_fail("1P Yang cannot expose her actual back"); return
	_save_coop("yang-in-game-back")
	await _frames(20)
	if not _faces_back(visual):
		_fail("Yang turns to the front after stopping"); return
	await _press_key(KEY_W,true)
	await _frames(9)
	await _press_key(KEY_W,false)
	if player.global_position.y <= 1.0:
		_fail("Yang cannot jump"); return
	_save_coop("yang-jump")
	await _frames(60)
	party.switch_to(0,0)
	party.switch_to(3,1)
	await _frames(4)
	visual = party._visual(second)
	if not _both_models() or not _faces_back(visual):
		_fail("2P Yang loses her identity or heading"); return
	await _press_key(KEY_RIGHT,true)
	await _frames(30)
	await _press_key(KEY_RIGHT,false)
	await _frames(20)
	if not _faces_front(visual):
		_fail("2P Yang cannot turn forward"); return
	_save_coop("yang-player2")
	await _press_key(KEY_LEFT,true)
	await _frames(30)
	await _press_key(KEY_LEFT,false)
	await _frames(20)
	if not _faces_back(visual):
		_fail("2P Yang cannot turn back"); return
	party.switch_to(1,1)
	var follower: CharacterBody3D = party.role_body(3)
	follower.set_physics_process(false)
	follower.velocity = Vector3.ZERO
	await _frames(5)
	if not _both_models() or not _faces_back(party._visual(follower)):
		_fail("Yang loses her detailed model or heading as a follower"); return
	_save_coop("yang-follower")
	follower.set_physics_process(true)
	party.switch_to(3,0)
	await _frames(4)
	model = party._visual(player).detailed_model
	for state in ["push", "carry", "jump"]:
		model.pose(0.15,0,1.5,state != "jump",state == "push",state == "carry")
		if model.current_state != state or not _cargo_stowed(model):
			_fail("Yang's cargo obstructs " + state); return
	model.pose(0.15,0,0,true,false,false,true)
	if model.current_state != "inspect" or _cargo_stowed(model):
		_fail("Yang cannot inspect while keeping her cargo"); return
	model.pose(0,0,0,true,false,false)
	if _cargo_stowed(model):
		_fail("Yang's cargo does not return to idle"); return
	await _click_stone(1)
	await _key(KEY_ESCAPE)
	if player.interaction_locked:
		_fail("Yang art blocks the stele viewer"); return
	await _tap("restart_lesson")
	await _frames(35)
	if not _both_models() or not _unique_ids() or party.active_id != 0 or party.second_id != 1 or party.role_directions[3] != 1.0:
		_fail("Reset loses detailed models, roles or Yang's initial heading"); return
	print("YANG_CHARACTER_OK: four distinct models, 27 bones/six clips, 1P/2P/follower, front/back and held heading, jumping, cargo hierarchy/stow/restore, stele inspection and reset")
	quit(0)


func _cargo_stowed(model: Node3D) -> bool:
	var index: int = model.skeleton.find_bone("yoke")
	return index >= 0 and model.skeleton.get_bone_pose_scale(index).length() < 0.01
