extends "res://tools/verify_deng_character.gd"


func _run() -> void:
	art_scene_path = "res://scenes/characters/a_cai_character.tscn"
	art_name = "阿彩（苗族）"
	art_key = "a-cai"
	portrait_center = 1.43
	face_center = 1.53
	neck_center = 1.38
	show_apron_detail = true
	studio_subtitle = "红蓝花带盘头 / 蜡染领袖 / 红腰带与百褶裙 / 背婴布 / 竹篓与小锄"
	accessory_detail_title = "背婴布蜡染花纹与熟睡的婴儿"
	accessory_center = 1.29
	accessory_rotation = PI
	studio_spacing = 1.15
	studio_size = 2.5
	if capture:
		if DisplayServer.get_name() == "headless": _fail("A Cai previews require GPU rendering"); return
		root.mode = Window.MODE_MINIMIZED
		OS.low_processor_usage_mode = false
		capture_viewport = SubViewport.new()
		capture_viewport.size = Vector2i(1600, 1000)
		capture_viewport.own_world_3d = true
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		capture_viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(capture_viewport)
		await _render_studio()
		capture_viewport.size = Vector2i(1280, 720)
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
	var npc: Node3D = bridge._a_cai
	var model: Node3D = npc.get_node("Character")
	if npc.is_visible_in_tree() or model.skeleton.get_bone_count() != 26 or model._clips.size() != 6:
		_fail("A Cai appears before being called or is missing her rig/clips"); return
	if npc.get_node("NameLabel").text != "阿彩（苗族）" or party.NAMES.size() != 4 or not _unique_ids():
		_fail("NPC label or four selectable party roles changed"); return
	for bone_name in ["carrier", "baby", "basket", "sash", "hoe", "skirt.L", "skirt.R", "skirt.back"]:
		if model.skeleton.find_bone(bone_name) < 0: _fail("Missing A Cai attachment: " + bone_name); return
	var hoe: int = model.skeleton.find_bone("hoe")
	var baby: int = model.skeleton.find_bone("baby")
	if model.skeleton.get_bone_parent(baby) != model.skeleton.find_bone("carrier"):
		_fail("The sleeping baby is not attached to the carrier"); return
	for state in ["idle", "walk", "push", "carry", "jump", "inspect"]:
		model.pose(0.2, 0, 2.0 if state == "walk" else 0.0, state != "jump", state == "push", state == "carry", state == "inspect")
		if model.current_state != state: _fail("A Cai clip cannot be selected: " + state); return
		var stowed: bool = model.skeleton.get_bone_pose_scale(hoe).length() < 0.01
		if stowed != (state in ["push", "carry", "jump"]) or model.skeleton.get_bone_pose_scale(baby).length() < 1.0:
			_fail("Hoe stow or stable carrier fails for " + state); return
	# Focused integration fixture: upstream wood/pier tasks are covered by verify_local_coop.
	ui.chapter_preview.pressed.emit()
	await _frames(50)
	bridge.step = 3
	bridge.timber_prepared = true
	bridge.material_delivered = true
	bridge.crate.position = Vector3(9.5, 0.5, -1.9)
	bridge.get_node("MaterialCrate/Collision").set_deferred("disabled", true)
	party.switch_to(3, 0)
	if not await _duo_walk(22.5, 23.0): _fail("Cannot call A Cai from the creek entrance"); return
	await _hold()
	if not bridge.helpers_called or bridge.step != 4 or not npc.is_visible_in_tree():
		_fail("Yang's actual interaction does not call A Cai"); return
	if model.current_state != "walk": _fail("A Cai slides without her walking clip"); return
	_save_coop("a-cai-approach")
	await _frames(350)
	if npc.position.distance_to(Vector3(9, 0, -2)) > 0.01 or model.current_state != "idle" or bridge.bridge_ready:
		_fail("A Cai fails to stop, or bypasses player bridge assembly"); return
	if not await _duo_walk(30.5, 30.3): _fail("Players cannot regroup near A Cai"); return
	await _frames(160)
	_save_coop("a-cai-in-game")
	Input.action_press("interact")
	Input.action_press("p2_interact")
	for frame in range(160):
		await physics_frame
		if bridge.building: break
	Input.action_release("interact")
	Input.action_release("p2_interact")
	await _frames(20)
	if not bridge.building or model.current_state != "carry" or model.skeleton.get_bone_pose_scale(hoe).length() >= 0.01:
		_fail("A Cai assembly state: building=%s clip=%s hoe=%s step=%s progress=%s nearby=%s" % [bridge.building, model.current_state, model.skeleton.get_bone_pose_scale(hoe), bridge.step, bridge.action_progress, party.nearby_count(30.5)]); return
	if not bridge._dialogue_label.text.begins_with("阿彩（苗族）："):
		_fail("A Cai's short assembly line lacks her ethnicity label"); return
	_save_coop("a-cai-build")
	await _frames(150)
	if not bridge.bridge_ready or bridge.gap_stabilized or model.current_state != "idle" or model.skeleton.get_bone_pose_scale(hoe).length() < 1:
		_fail("A Cai does not restore idle/tool, or skips tablet rescue"); return
	await _tap("restart_lesson")
	await _frames(40)
	if npc.is_visible_in_tree() or bridge.helpers_called or npc.position.distance_to(Vector3(1, 0, -2)) > 0.01 or model.current_state != "idle":
		_fail("Restart leaves A Cai or her animation in the previous chapter state"); return
	print("A_CAI_CHARACTER_OK: 26 bones/six clips, named Miao villager, four original roles, stable baby hierarchy, hoe stow/restore, actual call/approach/idle/assembly/reset, no automatic bridge or rescue completion")
	quit(0)
